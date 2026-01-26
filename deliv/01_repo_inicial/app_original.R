# ===================================================================
# Aplicación Shiny para Análisis de Ensayos de Aptitud
# Implementación ISO 17043:2024 / ISO 13528:2022
#
# Esta aplicación implementa procedimientos de ensayos de aptitud en una
# interfaz web Shiny interactiva.
#
# Las funciones matemáticas se obtienen del paquete ptcalc:
#   - Algoritmo A, nIQR, MADe (estadísticos robustos)
#   - Puntajes z, z', zeta, En (cálculos de puntajes)
#   - Homogeneidad/estabilidad (cálculos ISO 13528)
#
# Autor: UNAL/INM - Laboratorio CALAIRE
# ===================================================================

# 1. Cargar librerías necesarias
library(shiny)
library(tidyverse)
library(vroom)
library(DT)
library(rhandsontable)
library(shinythemes)
library(outliers)
library(patchwork)
library(bsplus)
library(plotly)
library(rmarkdown)
library(bslib)

# -------------------------------------------------------------------
# Cargar paquete ptcalc (cálculos ISO 13528/17043)
# Para desarrollo: usar devtools::load_all()
# Para producción: instalar con devtools::install() y usar library(ptcalc)
# -------------------------------------------------------------------
devtools::load_all("ptcalc")

# ===================================================================
# I. Interfaz de Usuario (UI)
# ===================================================================
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bg = "#FFFFFF",
    fg = "#212529",
    primary = "#FDB913",
    secondary = "#333333",
    success = "#4DB848",
    base_font = font_google("Droid Sans"),
    code_font = font_google("JetBrains Mono")
  ),

  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "appR.css")
  ),

  # 1. Enhanced header with logo
  div(class = "app-header",
    div(class = "header-content",
      div(class = "logo-container",
        tags$img(src = "logo.png", class = "unal-logo", alt = "Universidad Nacional de Colombia")
      ),
      div(class = "title-container",
        h1(class = "app-title", "Aplicativo para Evaluación de Ensayos de Aptitud"),
        h3(class = "app-subtitle", "Gases Contaminantes Criterio"),
        p(class = "app-institution",
          "Laboratorio CALAIRE | Universidad Nacional de Colombia - Sede Medellín",
          tags$br(),
          "Instituto Nacional de Metrología (INM)"
        )
      )
    )
  ),


  # UI dinámica para el diseño principal
  uiOutput("main_layout"),

  # Panel desplegable para opciones de diseño
  checkboxInput("show_layout_options", "Mostrar opciones de diseño", value = FALSE),
  conditionalPanel(
    condition = "input.show_layout_options == true",
    wellPanel(
      themeSelector(),
      hr(),
      sliderInput("nav_width", "Ancho del panel de navegación:", min = 1, max = 5, value = 2, width = "250px"),
      sliderInput("analysis_sidebar_width", "Ancho de la barra lateral de análisis:", min = 2, max = 6, value = 3, width = "250px")
    )
  ),
  hr(),
  
  # Enhanced footer
  tags$footer(class = "app-footer-modern",
    div(class = "footer-content",
      div(class = "footer-section",
        h4("Proyecto"),
        p(em("Este aplicativo fue desarrollado en el marco del proyecto «Implementación de Ensayos de Aptitud en la Matriz Aire. Caso Gases Contaminantes Criterio»"))
      ),
      div(class = "footer-section",
        h4("Instituciones"),
        p("Laboratorio CALAIRE"),
        p("Universidad Nacional de Colombia - Sede Medellín"),
        p("Instituto Nacional de Metrología (INM)")
      ),
      div(class = "footer-section",
        h4("Contacto"),
        p(tags$a(href = "mailto:calaire_med@unal.edu.co", "calaire_med@unal.edu.co")),
        p(tags$a(href = "https://minas.medellin.unal.edu.co/laboratorios/calaire/", 
                 target = "_blank", "minas.medellin.unal.edu.co/laboratorios/calaire"))
      )
    ),
    div(class = "footer-bottom",
      p("© 2026 Universidad Nacional de Colombia. Todos los derechos reservados.")
    )
  )
)

# ===================================================================
# II. Lógica del Servidor
# ===================================================================
server <- function(input, output, session) {
  # --- Carga de datos y Procesamiento ---
  # Esta sección maneja la carga inicial de datos desde archivos subidos por el usuario.
  # Estos reactivos son la base para todos los análisis posteriores.

  hom_data_full <- reactive({
    req(input$hom_file)
    df <- vroom::vroom(input$hom_file$datapath, show_col_types = FALSE)
    validate(
      need(
        all(c("value", "pollutant", "level") %in% names(df)),
        "Error: El archivo de homogeneidad debe contener las columnas 'value', 'pollutant' y 'level'. Verifique que ha subido el archivo correcto."
      )
    )
    df
  })

  stab_data_full <- reactive({
    req(input$stab_file)
    df <- vroom::vroom(input$stab_file$datapath, show_col_types = FALSE)
    validate(
      need(
        all(c("value", "pollutant", "level") %in% names(df)),
        "Error: El archivo de estabilidad debe contener las columnas 'value', 'pollutant' y 'level'. Verifique que ha subido el archivo correcto."
      )
    )
    df
  })

  # Datos de preparación PT
  pt_prep_data <- reactive({
    req(input$summary_files)

    data_list <- lapply(seq_len(nrow(input$summary_files)), function(i) {
      df <- vroom::vroom(input$summary_files$datapath[i], show_col_types = FALSE)
      n <- as.integer(stringr::str_extract(input$summary_files$name[i], "\\d+"))
      df$n_lab <- n
      return(df)
    })

    if (length(data_list) == 0) {
      return(NULL)
    }

    raw_data <- do.call(rbind, data_list)
    if (is.null(raw_data) || nrow(raw_data) == 0) {
      return(NULL)
    }

    validate(
      need(
        all(c("participant_id", "pollutant", "level", "mean_value", "sd_value") %in% names(raw_data)),
        "Error: Los archivos resumen deben contener las columnas 'participant_id', 'pollutant', 'level', 'mean_value' y 'sd_value'. Verifique que ha subido los archivos correctos."
      )
    )

    # Almacenar datos crudos en un valor reactivo para uso en cálculo de sigma_pt_1
    rv$raw_summary_data <- raw_data

    # También almacenar la lista de archivos para cálculos de consenso
    data_list <- lapply(seq_len(nrow(input$summary_files)), function(i) {
      vroom::vroom(input$summary_files$datapath[i], show_col_types = FALSE)
    })
    rv$raw_summary_data_list <- data_list

    # Agregar los datos crudos para obtener un único valor medio por participante/nivel
    raw_data %>%
      group_by(participant_id, pollutant, level, run, n_lab) %>%
      summarise(
        mean_value = mean(mean_value, na.rm = TRUE),
        sd_value = mean(sd_value, na.rm = TRUE),
        .groups = "drop"
      )
  })

  # Valores reactivos para almacenar datos crudos para cálculos específicos
  rv <- reactiveValues(raw_summary_data = NULL, raw_summary_data_list = NULL)

  format_num <- function(x) {
    ifelse(is.na(x), NA_character_, sprintf("%.5f", x))
  }

  # Rastrear cuándo el análisis ha sido ejecutado explícitamente
  analysis_trigger <- reactiveVal(NULL)
  algoA_results_cache <- reactiveVal(NULL)
  algoA_trigger <- reactiveVal(NULL)
  robust_trigger <- reactiveVal(NULL)
  consensus_results_cache <- reactiveVal(NULL)
  consensus_trigger <- reactiveVal(NULL)
  scores_results_cache <- reactiveVal(NULL)
  scores_trigger <- reactiveVal(NULL)

  get_scores_result <- function(pollutant, n_lab, level) {
    if (is.null(scores_trigger())) {
      return(list(error = "Calcule los puntajes para habilitar esta sección."))
    }
    cache <- scores_results_cache()
    if (is.null(cache) || length(cache) == 0) {
      return(list(error = "No se generaron resultados. Ejecute 'Calcular puntajes'."))
    }
    key <- paste(pollutant, as.character(n_lab), level, sep = "||")
    res <- cache[[key]]
    if (is.null(res)) {
      return(list(error = "No se encontraron resultados para la combinación seleccionada. Ejecute nuevamente el cálculo."))
    }
    res
  }

  combine_scores_result <- function(res) {
    if (!is.null(res$error)) {
      return(list(error = res$error, data = tibble()))
    }
    combos <- res$combos
    combined <- purrr::map_dfr(names(combos), function(key) {
      combo <- combos[[key]]
      if (is.null(combo) || !is.null(combo$error)) {
        return(tibble())
      }
      combo$data
    })
    list(error = NULL, data = combined)
  }

  observeEvent(input$run_analysis, {
    analysis_trigger(Sys.time())
  })

  observeEvent(list(input$hom_file, input$stab_file, input$summary_files),
    {
      analysis_trigger(NULL)
    },
    ignoreNULL = FALSE
  )

  observeEvent(input$summary_files,
    {
      algoA_results_cache(NULL)
      algoA_trigger(NULL)
      robust_trigger(NULL)
      consensus_results_cache(NULL)
      consensus_trigger(NULL)
      scores_results_cache(NULL)
      scores_trigger(NULL)
    },
    ignoreNULL = FALSE
  )

  # --- Funciones auxiliares de cálculo compartidas ---
  get_wide_data <- function(df, target_pollutant) {
    filtered <- df %>% filter(pollutant == target_pollutant)
    if (is.null(filtered) || nrow(filtered) == 0) {
      return(NULL)
    }
    if (!"value" %in% names(filtered)) {
      return(NULL)
    }
    filtered %>%
      select(-pollutant) %>%
      pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
  }

  compute_homogeneity_metrics <- function(target_pollutant, target_level) {
    req(hom_data_full())
    wide_df <- get_wide_data(hom_data_full(), target_pollutant)
    if (is.null(wide_df)) {
      return(list(error = sprintf("No se encontraron datos de homogeneidad para el analito '%s'.", target_pollutant)))
    }
    if (!"level" %in% names(wide_df)) {
      return(list(error = "La columna 'level' no se encuentra en los datos cargados."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("El nivel '%s' no existe para el analito '%s'.", target_level, target_pollutant)))
    }

    level_data <- wide_df %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) {
      return(list(error = "No hay suficientes réplicas (se requieren al menos 2) para evaluar la homogeneidad."))
    }
    if (g < 2) {
      return(list(error = "No hay suficientes ítems (se requieren al menos 2) para evaluar la homogeneidad."))
    }

    intermediate_df <- if (m == 2) {
      s1 <- level_data[[1]]
      s2 <- level_data[[2]]
      level_data %>%
        mutate(
          Item = row_number(),
          average = (s1 + s2) / 2,
          range = abs(s1 - s2)
        ) %>%
        select(Item, everything())
    } else {
      level_data %>%
        mutate(
          Item = row_number(),
          average = rowMeans(., na.rm = TRUE),
          range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        ) %>%
        select(Item, everything())
    }

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "No se encontró la columna 'sample_1'. Es obligatoria para calcular sigma_pt."))
    }

    # Calculate sigma_pt from MADe of first sample column (ISO 13528)
    first_sample_results <- level_data %>% pull(sample_1)
    mad_e <- calculate_mad_e(first_sample_results)
    n_iqr <- calculate_niqr(first_sample_results)

    # Calculate u_xpt (standard uncertainty of assigned value)
    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)

    # Calculate homogeneity statistics using ptcalc package (ISO 13528 Section 9.2)
    hom_stats <- calculate_homogeneity_stats(level_data)
    if (!is.null(hom_stats$error)) {
      return(list(error = hom_stats$error))
    }

    # Extract stats for ANOVA summary and return values
    hom_x_t_bar <- hom_stats$general_mean_homog
    hom_s_x_bar_sq <- hom_stats$s_x_bar_sq
    hom_s_xt <- hom_stats$s_xt
    hom_sw <- hom_stats$sw
    hom_ss <- hom_stats$ss

    # Keep intermediate values for display (MADe components)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)

    hom_anova_summary <- data.frame(
      "gl" = c(g - 1, g * (m - 1)),
      "Suma de cuadrados" = c(hom_s_x_bar_sq * m * (g - 1), hom_sw^2 * g * (m - 1)),
      "Media de cuadrados" = c(hom_s_x_bar_sq * m, hom_sw^2),
      check.names = FALSE
    )
    rownames(hom_anova_summary) <- c("Ítem", "Residuos")

    hom_sigma_pt <- mad_e
    hom_c_criterion <- calculate_homogeneity_criterion(hom_sigma_pt)
    hom_sigma_allowed_sq <- hom_c_criterion^2
    hom_c_criterion_expanded <- calculate_homogeneity_criterion_expanded(hom_sigma_pt, hom_sw^2)

    if (hom_ss <= hom_c_criterion) {
      hom_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-success"
    } else {
      hom_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-warning"
    }

    if (hom_ss <= hom_c_criterion_expanded) {
      hom_conclusion2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): CUMPLE CRITERIO EXP HOMOGENEIDAD", hom_ss, hom_c_criterion_expanded)
    } else {
      hom_conclusion2 <- sprintf("ss (%.4f) > c_expanded (%.4f): NO CUMPLE CRITERIO EXP HOMOGENEIDAD", hom_ss, hom_c_criterion_expanded)
    }

    hom_conclusion <- paste(hom_conclusion1, hom_conclusion2, sep = "<br>")

    list(
      summary = hom_anova_summary,
      ss = hom_ss,
      sw = hom_sw,
      conclusion = hom_conclusion,
      conclusion_class = hom_conclusion_class,
      g = g,
      m = m,
      sigma_allowed_sq = hom_sigma_allowed_sq,
      c_criterion = hom_c_criterion,
      c_criterion_expanded = hom_c_criterion_expanded,
      sigma_pt = hom_sigma_pt,
      median_val = median_val,
      median_abs_diff = median_abs_diff,
      n_iqr = n_iqr,
      u_xpt = u_xpt,
      n_robust = n_robust,
      item_means = hom_stats$sample_means,
      general_mean = hom_x_t_bar,
      sd_of_means = hom_s_xt,
      s_x_bar_sq = hom_s_x_bar_sq,
      s_w_sq = hom_sw^2,
      intermediate_df = intermediate_df,
      first_sample_results = first_sample_results,
      abs_diff_from_median = abs_diff_from_median,
      data_wide = wide_df,
      level = target_level,
      pollutant = target_pollutant,
      error = NULL
    )
  }

  compute_stability_metrics <- function(target_pollutant, target_level, hom_results) {
    req(stab_data_full())
    wide_df <- get_wide_data(stab_data_full(), target_pollutant)
    if (is.null(wide_df)) {
      return(list(error = sprintf("No se encontraron datos de estabilidad para el analito '%s'.", target_pollutant)))
    }
    if (!"level" %in% names(wide_df)) {
      return(list(error = "La columna 'level' no se encuentra en el conjunto de datos de estabilidad."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("El nivel '%s' no existe en los datos de estabilidad del analito '%s'.", target_level, target_pollutant)))
    }
    if (!is.null(hom_results$error)) {
      return(list(error = hom_results$error))
    }

    level_data <- wide_df %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) {
      return(list(error = "No hay suficientes réplicas (se requieren al menos 2) para evaluar la homogeneidad en los datos de estabilidad."))
    }
    if (g < 2) {
      return(list(error = "No hay suficientes ítems (se requieren al menos 2) para evaluar la homogeneidad en los datos de estabilidad."))
    }

    intermediate_df <- if (m == 2) {
      s1 <- level_data[[1]]
      s2 <- level_data[[2]]
      level_data %>%
        mutate(
          Item = row_number(),
          average = (s1 + s2) / 2,
          range = abs(s1 - s2)
        ) %>%
        select(Item, everything())
    } else {
      level_data %>%
        mutate(
          Item = row_number(),
          average = rowMeans(., na.rm = TRUE),
          range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        ) %>%
        select(Item, everything())
    }

    stab_data_long <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Resultado"
      )

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "No se encontró la columna 'sample_1'. Es obligatoria para calcular sigma_pt en los datos de estabilidad."))
    }

    # Calculate sigma_pt from MADe of first sample column (ISO 13528)
    first_sample_results <- level_data %>% pull(sample_1)
    mad_e <- calculate_mad_e(first_sample_results)
    stab_n_iqr <- calculate_niqr(first_sample_results)

    # Calculate u_xpt (standard uncertainty of assigned value)
    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)

    # Calculate stability statistics using ptcalc package (ISO 13528 Section 9.3)
    stab_stats <- calculate_stability_stats(
      level_data,
      hom_results$general_mean,
      hom_results$x_pt,
      hom_results$sigma_pt
    )
    if (!is.null(stab_stats$error)) {
      return(list(error = stab_stats$error))
    }

    # Extract stats for ANOVA summary and return values
    stab_x_t_bar <- stab_stats$general_mean
    diff_hom_stab <- abs(stab_x_t_bar - hom_results$general_mean)

    stab_s_x_bar_sq <- stab_stats$s_x_bar_sq
    stab_s_xt <- stab_stats$s_xt
    stab_sw <- stab_stats$sw
    stab_ss <- stab_stats$ss

    # Keep intermediate values for display (MADe components)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)

    stab_anova_summary <- data.frame(
      "gl" = c(g - 1, g * (m - 1)),
      "Suma de cuadrados" = c(stab_s_x_bar_sq * m * (g - 1), stab_sw^2 * g * (m - 1)),
      "Media de cuadrados" = c(stab_s_x_bar_sq * m, stab_sw^2),
      check.names = FALSE
    )
    rownames(stab_anova_summary) <- c("Ítem", "Residuos")

    stab_sigma_pt <- mad_e
    stab_c_criterion <- calculate_stability_criterion(hom_results$sigma_pt)
    stab_sigma_allowed_sq <- stab_c_criterion^2
    
    # Calcular u_hom_mean
    hom_values <- hom_results$data_wide %>%
      select(starts_with("sample_")) %>%
      unlist() %>%
      as.numeric()
    hom_values <- hom_values[!is.na(hom_values)]
    sd_hom_mean <- sd(hom_values)
    n_hom <- length(hom_values)
    u_hom_mean <- sd_hom_mean / sqrt(n_hom)
    
    # Calcular u_stab_mean
    stab_values <- stab_data_long$Resultado
    stab_values <- stab_values[!is.na(stab_values)]
    sd_stab_mean <- sd(stab_values)
    n_stab <- length(stab_values)
    u_stab_mean <- sd_stab_mean / sqrt(n_stab)
    
    stab_c_criterion_expanded <- calculate_stability_criterion_expanded(stab_c_criterion, u_hom_mean, u_stab_mean)

    if (diff_hom_stab <= stab_c_criterion) {
      stab_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-success"
    } else {
      stab_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-warning"
    }

    if (diff_hom_stab <= stab_c_criterion_expanded) {
      stab_conclusion2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): CUMPLE CRITERIO EXP ESTABILIDAD", diff_hom_stab, stab_c_criterion_expanded)
    } else {
      stab_conclusion2 <- sprintf("ss (%.4f) > c_expanded (%.4f): NO CUMPLE CRITERIO EXP ESTABILIDAD", diff_hom_stab, stab_c_criterion_expanded)
    }

    stab_conclusion <- paste(stab_conclusion1, stab_conclusion2, sep = "<br>")

    list(
      stab_summary = stab_anova_summary,
      stab_ss = stab_ss,
      stab_sw = stab_sw,
      stab_conclusion = stab_conclusion,
      stab_conclusion_class = stab_conclusion_class,
      g = g,
      m = m,
      diff_hom_stab = diff_hom_stab,
      stab_sigma_allowed_sq = stab_sigma_allowed_sq,
      stab_c_criterion = stab_c_criterion,
      stab_c_criterion_expanded = stab_c_criterion_expanded,
      stab_sigma_pt = stab_sigma_pt,
      stab_median_val = median_val,
      stab_median_abs_diff = median_abs_diff,
      stab_n_iqr = stab_n_iqr,
      stab_u_xpt = u_xpt,
      n_robust = n_robust,
      stab_item_means = stab_stats$sample_means,
      stab_general_mean = stab_x_t_bar,
      stab_sd_of_means = stab_s_xt,
      stab_s_x_bar_sq = stab_s_x_bar_sq,
      stab_s_w_sq = stab_sw^2,
      stab_intermediate_df = intermediate_df,
      data_wide = wide_df,
      level = target_level,
      pollutant = target_pollutant,
      error = NULL
    )
  }

  compute_scores_metrics <- function(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k, m = NULL) {
    if (is.null(summary_df) || nrow(summary_df) == 0) {
      return(list(error = "No hay datos resumen disponibles para los puntajes PT."))
    }

    data <- summary_df %>%
      filter(
        pollutant == target_pollutant,
        n_lab == target_n_lab,
        level == target_level
      )

    if (nrow(data) == 0) {
      return(list(error = "No se encontraron datos para los criterios seleccionados."))
    }

    ref_data <- data %>% filter(participant_id == "ref")

    if (nrow(ref_data) == 0) {
      return(list(error = "No se encontraron datos de referencia ('ref') para este nivel."))
    }

    x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
    participant_data <- data


    participant_data <- participant_data %>%
      rename(result = mean_value) %>%
      mutate(uncertainty_std = if (!is.null(m) && m > 0) sd_value / sqrt(m) else sd_value)

    final_scores <- participant_data %>%
      mutate(
        x_pt = x_pt,
        sigma_pt = sigma_pt,
        z_score = (result - x_pt) / sigma_pt,
        z_prime_score = (result - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
        zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
        U_xi = k * uncertainty_std,
        U_xpt = k * u_xpt,
        En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
      ) %>%
      mutate(
        z_score_eval = case_when(
          abs(z_score) <= 2 ~ "Satisfactorio",
          abs(z_score) > 2 & abs(z_score) < 3 ~ "Cuestionable",
          abs(z_score) >= 3 ~ "No satisfactorio",
          TRUE ~ "N/A"
        ),
        z_prime_score_eval = case_when(
          abs(z_prime_score) <= 2 ~ "Satisfactorio",
          abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Cuestionable",
          abs(z_prime_score) >= 3 ~ "No satisfactorio",
          TRUE ~ "N/A"
        ),
        zeta_score_eval = case_when(
          abs(zeta_score) <= 2 ~ "Satisfactorio",
          abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Cuestionable",
          abs(zeta_score) >= 3 ~ "No satisfactorio",
          TRUE ~ "N/A"
        ),
        En_score_eval = case_when(
          abs(En_score) <= 1 ~ "Satisfactorio",
          abs(En_score) > 1 ~ "No satisfactorio",
          TRUE ~ "N/A"
        )
      )

    list(
      error = NULL,
      scores = final_scores,
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      k = k,
      pollutant = target_pollutant,
      n_lab = target_n_lab,
      level = target_level
    )
  }

  # Nota: run_algorithm_a ahora se obtiene de R/pt_robust_stats.R

  observeEvent(input$algoA_run, {
    req(pt_prep_data())
    data <- isolate(pt_prep_data())

    combos <- data %>%
      distinct(pollutant, n_lab, level)

    if (nrow(combos) == 0) {
      algoA_results_cache(NULL)
      algoA_trigger(Sys.time())
      return()
    }

    max_iter <- isolate(input$algoA_max_iter)
    results <- list()

    for (i in seq_len(nrow(combos))) {
      pollutant_val <- combos$pollutant[i]
      n_lab_val <- combos$n_lab[i]
      level_val <- combos$level[i]
      key <- algo_key(pollutant_val, n_lab_val, level_val)

      subset_data <- data %>%
        filter(
          pollutant == pollutant_val,
          n_lab == n_lab_val,
          level == level_val
        )

      participants <- subset_data %>%
        filter(participant_id != "ref")

      aggregated <- participants %>%
        group_by(participant_id) %>%
        summarise(Resultado = mean(mean_value, na.rm = TRUE), .groups = "drop")

      if (nrow(aggregated) < 3) {
        algo_res <- list(
          error = "Se requieren al menos tres participantes para ejecutar el Algoritmo A.",
          input_data = aggregated,
          iterations = tibble(),
          winsorized_values = tibble(),
          converged = FALSE,
          n_participants = NA_integer_
        )
      } else {
        algo_res <- run_algorithm_a(
          values = aggregated$Resultado,
          ids = aggregated$participant_id,
          max_iter = max_iter
        )

        if (!is.null(algo_res$error)) {
          if (is.null(algo_res$iterations)) algo_res$iterations <- tibble()
          if (is.null(algo_res$winsorized_values)) algo_res$winsorized_values <- tibble()
          if (is.null(algo_res$converged)) algo_res$converged <- FALSE
          if (is.null(algo_res$n_participants)) algo_res$n_participants <- NA_integer_
        }

        algo_res$input_data <- aggregated
      }

      algo_res$selected <- list(
        pollutant = pollutant_val,
        n_lab = n_lab_val,
        level = level_val
      )

      results[[key]] <- algo_res
    }

    algoA_results_cache(results)
    algoA_trigger(Sys.time())
  })

  # R0: Diseño Principal Dinámico
  output$main_layout <- renderUI({
    req(input$nav_width, input$analysis_sidebar_width)
    nav_width <- input$nav_width
    content_width <- 12 - nav_width

    analysis_sidebar_w <- input$analysis_sidebar_width
    analysis_main_w <- 12 - analysis_sidebar_w

    navlistPanel(
      id = "main_nav",
      widths = c(nav_width, content_width),
      "Módulos de análisis",
      tabPanel(
        title = tagList(icon("upload"), "Carga de datos"),
        value = "carga_datos",
        div(class = "shadcn-card",
          div(class = "shadcn-card-header",
            h3(class = "shadcn-card-title", 
               icon("upload"), " Carga Manual de Archivos de Datos"
            ),
            p(class = "shadcn-card-description",
              "Por favor, cargue los archivos CSV necesarios para el análisis. Asegúrese de que los archivos tengan el formato correcto."
            )
          ),
          div(class = "shadcn-card-content",
            div(class = "upload-grid",
              div(class = "upload-item",
                div(class = "upload-label",
                  icon("file-csv"),
                  span("1. Datos de Homogeneidad")
                ),
                fileInput("hom_file", NULL, accept = ".csv", placeholder = "homogeneity.csv")
              ),
              div(class = "upload-item",
                div(class = "upload-label",
                  icon("file-csv"),
                  span("2. Datos de Estabilidad")
                ),
                fileInput("stab_file", NULL, accept = ".csv", placeholder = "stability.csv")
              ),
              div(class = "upload-item",
                div(class = "upload-label",
                  icon("file-csv"),
                  span("3. Datos Consolidados de participantes")
                ),
                fileInput("summary_files", NULL, accept = ".csv", multiple = TRUE, placeholder = "summary_n*.csv")
              )
            )
          )
        ),
        div(class = "shadcn-card",
          div(class = "shadcn-card-header",
            h4(class = "shadcn-card-title",
               icon("check-circle"), " Estado de los Datos Cargados"
            )
          ),
          div(class = "shadcn-card-content",
            verbatimTextOutput("data_upload_status")
          )
        )
      ),
      tabPanel(
        title = tagList(icon("flask"), "Análisis de homogeneidad y estabilidad"),
        value = "analisis_hom_estab",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Ejecutar análisis"),
            actionButton("run_analysis", "Ejecutar",
              class = "btn-primary btn-block"
            ),
            hr(),
            h4("2. Seleccionar analito"),
            uiOutput("pollutant_selector_analysis"),
            hr(),
            h4("3. Seleccionar nivel"),
            uiOutput("level_selector"),
            hr(),
            p("Este aplicativo evalua la homogeneidad y estabilidad del item de ensayo de acuerdo a los princiios de la ISO 13528:2022."),
          ),
          mainPanel(
            width = analysis_main_w,
            tabsetPanel(
              id = "analysis_tabs",
              tabPanel(
                "Vista previa de datos",
                h4("Vista previa de datos de entrada"),
                p("Esta tabla muestra los datos del analito seleccionado."),
                h5("Datos de homogeneidad"),
                dataTableOutput("raw_data_preview"),
                hr(),
                h5("Datos de estabilidad"),
                dataTableOutput("stability_data_preview"),
                hr(),
                h4("Distribución de datos"),
                p("El histograma y el diagrama de caja muestran la distribución de todos los resultados de las columnas 'sample_*' para el nivel seleccionado."),
                fluidRow(
                  column(width = 6, plotlyOutput("results_histogram")),
                  column(width = 6, plotlyOutput("results_boxplot"))
                ),
                hr(),
                h4("Validación de datos"),
                verbatimTextOutput("validation_message")
              ),
              tabPanel(
                "Evaluación de homogeneidad",
                h4("Conclusión"),
                uiOutput("homog_conclusion"),
                hr(),
                h4("Vista previa de homogeneidad (nivel y primera muestra)"),
                dataTableOutput("homogeneity_preview_table"),
                hr(),
                h4("Cálculos de estadísticos robustos"),
                tableOutput("robust_stats_table"),
                verbatimTextOutput("robust_stats_summary"),
                hr(),
                h4("Componentes de varianza"),
                p("Desviaciones estándar estimadas del cálculo manual."),
                tableOutput("variance_components"),
                hr(),
                h4("Cálculos por ítem"),
                p("Esta tabla muestra los cálculos para cada ítem del conjunto de datos del nivel seleccionado, incluyendo la media y el rango de las mediciones."),
                tableOutput("details_per_item_table"),
                hr(),
                h4("Estadísticos resumidos"),
                p("Esta tabla muestra los estadísticos generales de la evaluación de homogeneidad."),
                tableOutput("details_summary_stats_table")
              ),
              tabPanel(
                "Evaluación de estabilidad",
                h4("Conclusión"),
                uiOutput("homog_conclusion_stability"),
                hr(),
                h4("Componentes de varianza"),
                p("Desviaciones estándar estimadas del cálculo manual para el conjunto de estabilidad."),
                tableOutput("variance_components_stability"),
                hr(),
                h4("Cálculos por ítem"),
                p("Esta tabla muestra los cálculos para cada ítem del conjunto de estabilidad."),
                tableOutput("details_per_item_table_stability"),
                hr(),
                h4("Estadísticos resumidos"),
                p("Esta tabla muestra los estadísticos generales para el conjunto de estabilidad."),
                tableOutput("details_summary_stats_table_stability")
              ),
              tabPanel(
                "Contribuciones a la incertidumbre",
                h4("Resumen Incertidumbre por Homogeneidad"),
                p("Esta tabla muestra el valor de u_hom (calculado como hom_ss) para todos los analitos y niveles disponibles."),
                dataTableOutput("u_hom_table"),
                hr(),
                h4("Resumen Incertidumbre por Estabilidad"),
                p("Esta tabla muestra el valor de Dmax (diferencia absoluta entre medias de homogeneidad y estabilidad) y u_stab para todos los analitos y niveles disponibles."),
                dataTableOutput("u_stab_table")
              )
            )
          )
        )
      ),
      tabPanel(
        title = tagList(icon("chart-bar"), "Valores Atípicos"),
        value = "valores_atipicos",
        h3("Resumen de valores atípicos (Grubbs)"),
        p("Tabla resumen de la prueba de Grubbs para la detección de valores atípicos en los datos de los participantes."),
        dataTableOutput("grubbs_summary_table"),
        hr(),
        h3("Visualización de Datos de Participantes"),
        fluidRow(
          column(
            width = 4,
            uiOutput("outliers_pollutant_selector"),
            uiOutput("outliers_level_selector")
          )
        ),
        fluidRow(
          column(width = 6, plotlyOutput("outliers_histogram")),
          column(width = 6, plotlyOutput("outliers_boxplot"))
        )
      ),
      tabPanel(
        title = tagList(icon("calculator"), "Valor asignado"),
        value = "valor_asignado",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Ejecutar Análisis"),
            actionButton("algoA_run", "Calcular Algoritmo A", class = "btn-primary btn-block"),
            br(),
            actionButton("consensus_run", "Calcular valores consenso", class = "btn-primary btn-block"),
            br(),
            actionButton("run_metrological_compatibility", "Calcular Compatibilidad", class = "btn-primary btn-block"),
            hr(),
            h4("2. Selector de datos"),
            uiOutput("assigned_pollutant_selector"),
            uiOutput("assigned_n_selector"),
            uiOutput("assigned_level_selector"),
            hr(),
            h4("3. Parámetros"),
            numericInput("algoA_max_iter", "Iteraciones máx Algo A:", value = 50, min = 5, max = 500, step = 5),
            hr(),
            helpText("La combinación seleccionada se utiliza en todas las secciones de la derecha.")
          ),
          mainPanel(
            width = 12 - analysis_sidebar_w,
            tabsetPanel(
              id = "assigned_value_tabs",
              tabPanel(
                "Algoritmo A",
                h4("Resultados del Algoritmo A"),
                uiOutput("algoA_result_summary"),
                hr(),
                h4("Datos de Entrada"),
                dataTableOutput("algoA_input_table"),
                hr(),
                h4("Histograma de Resultados"),
                plotlyOutput("algoA_histogram"),
                hr(),
                h4("Iteraciones"),
                dataTableOutput("algoA_iterations_table"),
                # Sección de pesos oculta por solicitud del usuario
                # hr(),
                # h4("Pesos Finales por Participante"),
                # dataTableOutput("algoA_weights_table")
              ),
              tabPanel(
                "Valor consenso",
                h4("Resumen del Valor Consenso"),
                tableOutput("consensus_summary_table"),
                hr(),
                p("Calcula el valor consenso x_pt(2) y las desviaciones robustas sigma_pt_2a (MADe) y sigma_pt_2b (nIQR) para cada combinación disponible."),
                hr(),
                h4("Datos de participantes"),
                dataTableOutput("consensus_input_table")
              ),
              tabPanel(
                "Valor de referencia",
                h4("Resultados de Referencia"),
                p("Visualiza los resultados declarados como referencia en los archivos summary_n*.csv."),
                dataTableOutput("reference_table")
              ),
              tabPanel(
                "Compatibilidad Metrológica",
                h4("Diferencias entre Valor de Referencia y Consenso"),
                p("Esta tabla muestra la compatibilidad metrológica entre el valor de referencia y los valores de consenso calculados."),
                dataTableOutput("metrological_compatibility_table"),
                p(class = "text-muted", "Nota: D_2a = x_pt(Ref) - x_pt(2a); D_2b = x_pt(Ref) - x_pt(2b)")
              )
            )
          )
        )
      ),
      tabPanel(
        title = tagList(icon("star"), "Puntajes PT"),
        value = "puntajes_pt",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Ejecutar Cálculo"),
            actionButton("scores_run", "Calcular puntajes", class = "btn-primary btn-block"),
            hr(),
            h4("2. Seleccionar Datos"),
            uiOutput("scores_pollutant_selector"),
            uiOutput("scores_n_selector"),
            uiOutput("scores_level_selector")
          ),
          mainPanel(
            width = analysis_main_w,
            tabsetPanel(
              id = "scores_tabs",
              tabPanel(
                "Resultados de puntajes",
                h4("Resumen de parámetros"),
                tableOutput("scores_parameter_table"),
                hr(),
                h4("Resumen de puntajes por participante"),
                dataTableOutput("scores_overview_table"),
                hr(),
                h4("Resumen de evaluación de puntajes"),
                tableOutput("scores_evaluation_summary")
              ),
              tabPanel("Puntajes Z", uiOutput("z_scores_panel")),
              tabPanel("Puntajes Z'", uiOutput("zprime_scores_panel")),
              tabPanel("Puntajes Zeta", uiOutput("zeta_scores_panel")),
              tabPanel("Puntajes En", uiOutput("en_scores_panel"))
            )
          )
        )
      ),
      tabPanel(
        title = tagList(icon("table"), "Informe global"),
        value = "informe_global",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Ejecutar cálculo global"),
            helpText("Utilice \"Calcular puntajes\" en la pestaña Puntajes PT para habilitar esta sección."),
            hr(),
            h4("2. Seleccionar combinación"),
            uiOutput("global_report_pollutant_selector"),
            uiOutput("global_report_n_selector"),
            uiOutput("global_report_level_selector"),
            hr(),
            uiOutput("global_report_pt_size_info")
          ),
          mainPanel(
            width = analysis_main_w,
            tabsetPanel(
              id = "global_report_tabs",
              tabPanel(
                 "Resumen global",
                 h4("Resumen x_pt"),
                 dataTableOutput("global_xpt_summary_table"),
                 hr(),
                 h4("Resumen de niveles"),
                 tableOutput("global_level_summary_table"),
                 hr(),
                 h4("Resumen de evaluaciones"),
                 dataTableOutput("global_evaluation_summary_table")
              ),
              tabPanel(
                "Referencia (1)",
                h4("Parámetros principales"),
                tableOutput("global_params_ref"),
                hr(),
                h4("Resultados por participante"),
                dataTableOutput("global_overview_ref"),
                hr(),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_z_ref", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_zprime_ref", height = "350px"))
                ),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_zeta_ref", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_en_ref", height = "350px"))
                )
              ),
              tabPanel(
                "Consenso MADe (2a)",
                h4("Parámetros principales"),
                tableOutput("global_params_consensus_ma"),
                hr(),
                h4("Resultados por participante"),
                dataTableOutput("global_overview_consensus_ma"),
                hr(),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_z_consensus_ma", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_zprime_consensus_ma", height = "350px"))
                ),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_zeta_consensus_ma", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_en_consensus_ma", height = "350px"))
                )
              ),
              tabPanel(
                "Consenso nIQR (2b)",
                h4("Parámetros principales"),
                tableOutput("global_params_consensus_niqr"),
                hr(),
                h4("Resultados por participante"),
                dataTableOutput("global_overview_consensus_niqr"),
                hr(),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_z_consensus_niqr", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_zprime_consensus_niqr", height = "350px"))
                ),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_zeta_consensus_niqr", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_en_consensus_niqr", height = "350px"))
                )
              ),
              tabPanel(
                "Algoritmo A (3)",
                h4("Parámetros principales"),
                tableOutput("global_params_algo"),
                hr(),
                h4("Resultados por participante"),
                dataTableOutput("global_overview_algo"),
                hr(),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_z_algo", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_zprime_algo", height = "350px"))
                ),
                fluidRow(
                  column(6, plotlyOutput("global_heatmap_zeta_algo", height = "350px")),
                  column(6, plotlyOutput("global_heatmap_en_algo", height = "350px"))
                )
              )
            )
          )
        )
      ),
      tabPanel(
        title = tagList(tags$i(class = "fa-regular fa-user"), "Participantes"),
        value = "participantes",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("Seleccionar datos"),
            uiOutput("participants_pollutant_selector"),
            uiOutput("participants_level_selector")
          ),
          mainPanel(
            width = analysis_main_w,
            h3("Resumen detallado por participante"),
            uiOutput("scores_participant_tabs")
          )
        )
      ),
      tabPanel(
        title = tagList(icon("file-pdf"), "Generación de informes"),
        value = "generacion_informes",
        sidebarLayout(
          sidebarPanel(
            width = 3,
            h4("2. Selección de Datos"),
            uiOutput("report_n_selector"),
            uiOutput("report_level_selector"),
            p(class = "text-info", style = "font-size: 0.9em;", "Nota: Se incluirán todos los analitos disponibles."),
            hr(),
            h4("3. Parámetros"),
            selectInput("report_metric", "Métrica:", choices = c("z", "z'", "zeta", "En")),
            selectInput("report_method", "Método:", choices = c("Referencia (1)" = "1", "Consenso MADe (2a)" = "2a", "Consenso nIQR (2b)" = "2b", "Algoritmo A (3)" = "3")),
            selectInput("report_metrological_compatibility", "Compatibilidad Metrológica (Consenso):", choices = c("Consenso MADe (2a)" = "2a", "Consenso nIQR (2b)" = "2b", "Algoritmo A (3)" = "3"), selected = "2a"),
            numericInput("report_k", "Factor de cobertura (k):", value = 2, min = 1, max = 3, step = 0.1),
            hr(),
            h4("Datos de Participantes"),
            fileInput("participants_data_upload", "Tabla de Instrumentación (CSV):", accept = ".csv"),
            helpText("Formato: Codigo_Lab, Analizador_SO2, Analizador_CO, Analizador_O3, Analizador_NO_NO2"),
            hr(),
            h4("Descarga"),
            radioButtons("report_format", "Formato:", choices = c("Word (DOCX)" = "word"), selected = "word"),
            downloadButton("download_report", "Descargar informe", class = "btn-success btn-block")
          ),
          mainPanel(
            width = 9,
            h3("Generación de Informe Final"),
            p("Configure los detalles de identificación y verifique la vista previa."),
            hr(),
            tabsetPanel(
              tabPanel(
                "1. Identificación",
                br(),
                h4("1. Identificación y Contexto"),
                fluidRow(
                  column(
                    6,
                    textInput("report_scheme_id", "ID Esquema EA:", value = "EA-202X-XX"),
                    textInput("report_id", "ID Informe:", value = "INF-202X-XX"),
                    dateInput("report_date", "Fecha de Emisión:", value = Sys.Date()),
                    textInput("report_period", "Periodo del Ensayo:", value = "Mes - Mes Año")
                  ),
                  column(
                    6,
                    textInput("report_coordinator", "Coordinador EA:", value = ""),
                    textInput("report_quality_pro", "Profesional Calidad Aire:", value = ""),
                    textInput("report_ops_eng", "Ingeniero Operativo:", value = ""),
                    textInput("report_quality_manager", "Profesional Gestión Calidad:", value = "")
                  )
                )
              ),
              tabPanel(
                "2. Vista Previa",
                br(),
                h4("Vista Previa del Estado"),
                uiOutput("report_status"),
                verbatimTextOutput("report_preview_summary"),
                hr(),
                h4("Vista Previa del Informe"),
                actionButton("generate_preview", "Generar Vista Previa", class = "btn-primary"),
                uiOutput("preview_loading"),
                uiOutput("pdf_preview_container")
              )
            )
          )
        )
      )
    )
  })

  # ===================================================================
  # III. Módulo de Homogeneidad y Estabilidad
  # ===================================================================

  # R1: Reactivo para Datos de homogeneidad
  raw_data <- reactive({
    req(hom_data_full(), input$pollutant_analysis)
    get_wide_data(hom_data_full(), input$pollutant_analysis)
  })

  # R1.6: Reactivo para Datos de estabilidad
  stability_data_raw <- reactive({
    req(stab_data_full(), input$pollutant_analysis)
    get_wide_data(stab_data_full(), input$pollutant_analysis)
  })

  # R2: Generación Dinámica del Selector de Nivel
  output$level_selector <- renderUI({
    data <- raw_data()
    if ("level" %in% names(data)) {
      levels <- unique(data$level)
      selectInput("target_level", "2. Seleccionar nivel PT", choices = levels, selected = levels[1])
    } else {
      p("La columna 'level' no se encuentra en los datos cargados.")
    }
  })

  output$pollutant_selector_analysis <- renderUI({
    req(hom_data_full())
    choices <- sort(unique(hom_data_full()$pollutant))
    selectInput("pollutant_analysis", "Seleccionar analito:", choices = choices)
  })

  # R3: Ejecución de Homogeneidad (Habilitada después de usar el botón ejecutar)
  homogeneity_run <- reactive({
    req(analysis_trigger())
    req(input$pollutant_analysis, input$target_level)
    compute_homogeneity_metrics(input$pollutant_analysis, input$target_level)
  })

  # R3.5: Ejecución de Homogeneidad de Datos de estabilidad (Habilitada después de usar el botón ejecutar)
  homogeneity_run_stability <- reactive({
    req(analysis_trigger())
    req(input$pollutant_analysis, input$target_level)
    hom_results <- homogeneity_run()
    compute_stability_metrics(input$pollutant_analysis, input$target_level, hom_results)
  })

  # R4: Ejecución de Estabilidad (Habilitada después de usar el botón ejecutar)
  stability_run <- reactive({
    req(analysis_trigger())
    hom_results <- homogeneity_run()
    stab_hom_results <- homogeneity_run_stability()

    # Verificar errores de los reactivos anteriores
    if (!is.null(hom_results$error)) {
      return(list(error = hom_results$error))
    }
    if (!is.null(stab_hom_results$error)) {
      return(list(error = stab_hom_results$error))
    }

    # Obtener las medias de los resultados de las dos ejecuciones de homogeneidad
    y1 <- hom_results$general_mean
    y2 <- stab_hom_results$stab_general_mean
    diff_observed <- abs(y1 - y2)

    # Usar sigma_pt de la ejecución principal de homogeneidad
    sigma_pt <- hom_results$sigma_pt
    stab_criterion_value <- 0.3 * sigma_pt

    # Formato dinámico para decimales
    fmt <- "%.5f"

    details_text <- sprintf(
      paste("Media de los datos de homogeneidad (y1):", fmt, "
Media de los datos de estabilidad (y2):", fmt, "
Diferencia absoluta observada:", fmt, "
Criterio de estabilidad (0.3 * sigma_pt):", fmt),
      y1, y2, diff_observed, stab_criterion_value
    )

    if (diff_observed <= stab_criterion_value) {
      conclusion <- "Conclusión: el ítem es adecuadamente estable."
      conclusion_class <- "alert alert-success"
    } else {
      conclusion <- "Conclusión: ADVERTENCIA: el ítem puede ser inestable."
      conclusion_class <- "alert alert-warning"
    }

    # Para la prueba t, necesitamos los resultados crudos de ambos conjuntos de datos para el nivel seleccionado
    target_level <- input$target_level

    data_t1_results <- raw_data() %>%
      filter(level == target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), values_to = "Resultado") %>%
      pull(Resultado)

    data_t2_results <- stability_data_raw() %>%
      filter(level == target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), values_to = "Resultado") %>%
      pull(Resultado)

    # Prueba t
    t_test_result <- t.test(data_t1_results, data_t2_results)

    if (t_test_result$p.value > 0.05) {
      ttest_conclusion <- "Prueba t: no se detecta diferencia estadísticamente significativa entre los dos conjuntos de datos (p > 0.05), se respalda la estabilidad."
    } else {
      ttest_conclusion <- "Prueba t: se detecta diferencia estadísticamente significativa entre los dos conjuntos de datos (p <= 0.05), indicando posible inestabilidad."
    }

    list(
      conclusion = conclusion,
      conclusion_class = conclusion_class,
      details = details_text,
      ttest_summary = t_test_result,
      ttest_conclusion = ttest_conclusion,
      error = NULL
    )
  })

  u_hom_data <- reactive({
    req(hom_data_full())
    data <- hom_data_full()
    
    combos <- data %>%
      distinct(pollutant, level)
    
    if (nrow(combos) == 0) return(tibble())
    
    results <- list()
    
    for (i in seq_len(nrow(combos))) {
      p_val <- combos$pollutant[i]
      l_val <- combos$level[i]
      
      # Usamos tryCatch para evitar que falle si una combinación tiene error
      res <- tryCatch({
        compute_homogeneity_metrics(p_val, l_val)
      }, error = function(e) list(error = e$message))
      
      if (is.null(res$error)) {
        results[[length(results) + 1]] <- tibble(
          Pollutant = p_val,
          Level = l_val,
          u_hom = res$ss
        )
      } else {
        results[[length(results) + 1]] <- tibble(
          Pollutant = p_val,
          Level = l_val,
          u_hom = NA_real_ # Or some indicator of error
        )
      }
    }
    
    bind_rows(results)
  })

  output$u_hom_table <- renderDataTable({
    req(u_hom_data())
    datatable(u_hom_data(), options = list(pageLength = 10), rownames = FALSE) %>%
      formatRound(columns = "u_hom", digits = 5)
  })

  u_stab_data <- reactive({
    req(hom_data_full(), stab_data_full())
    h_data <- hom_data_full()
    s_data <- stab_data_full()
    
    # Obtener combinaciones comunes
    combos <- h_data %>%
      distinct(pollutant, level) %>%
      inner_join(s_data %>% distinct(pollutant, level), by = c("pollutant", "level"))
    
    if (nrow(combos) == 0) return(tibble())
    
    results <- list()
    
    for (i in seq_len(nrow(combos))) {
      p_val <- combos$pollutant[i]
      l_val <- combos$level[i]
      
      res <- tryCatch({
        hom_res <- compute_homogeneity_metrics(p_val, l_val)
        stab_res <- compute_stability_metrics(p_val, l_val, hom_res)
        
        y1 <- hom_res$general_mean
        y2 <- stab_res$stab_general_mean
        d_max <- abs(y1 - y2)
        u_stab <- d_max / sqrt(3)
        
        list(d_max = d_max, u_stab = u_stab)
      }, error = function(e) list(error = e$message))
      
      if (is.null(res$error)) {
        results[[length(results) + 1]] <- tibble(
          Pollutant = p_val,
          Level = l_val,
          Dmax = res$d_max,
          u_stab = res$u_stab
        )
      } else {
        results[[length(results) + 1]] <- tibble(
          Pollutant = p_val,
          Level = l_val,
          Dmax = NA_real_,
          u_stab = NA_real_
        )
      }
    }
    
    bind_rows(results)
  })

  output$u_stab_table <- renderDataTable({
    req(u_stab_data())
    datatable(u_stab_data(), options = list(pageLength = 10), rownames = FALSE) %>%
      formatRound(columns = c("Dmax", "u_stab"), digits = 5)
  })

  # --- Salidas ---

  # Salida: Vista previa de datos
  output$raw_data_preview <- renderDataTable({
    req(raw_data())
    df <- head(raw_data(), 10)
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    fmt <- "%.9f"
    df <- df %>%
      mutate(across(all_of(numeric_cols), ~ sprintf("%.5f", .x)))
    datatable(df, options = list(scrollX = TRUE))
  })

  output$stability_data_preview <- renderDataTable({
    req(stability_data_raw())
    df <- head(stability_data_raw(), 10)
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    fmt <- "%.9f"
    df <- df %>%
      mutate(across(all_of(numeric_cols), ~ sprintf("%.5f", .x)))
    datatable(df, options = list(scrollX = TRUE))
  })


  # Salida: Mensaje de Validación
  output$validation_message <- renderPrint({
    data <- raw_data()
    cat("Datos cargados correctamente.
")
    cat(paste("Dimensiones:", paste(dim(data), collapse = " x "), "
"))

    required_cols <- c("level")
    has_samples <- any(str_detect(names(data), "sample_"))

    if (!all(required_cols %in% names(data))) {
      cat(paste("ERROR: faltan columnas obligatorias:", paste(setdiff(required_cols, names(data)), collapse = ", "), "
"))
    } else {
      cat("Se encontró la columna 'level'.
")
    }

    if (!has_samples) {
      cat("ERROR: no se encontraron columnas con el prefijo 'sample_'. Son necesarias para el análisis.
")
    } else {
      cat("Se encontraron columnas 'sample_*'.
")
    }
  })

  # Expresión reactiva para datos de gráficos
  plot_data_long <- reactive({
    req(raw_data())
    if (!"level" %in% names(raw_data())) {
      return(NULL)
    }
    raw_data() %>%
      select(level, matches("^sample_\\d+$")) %>%
      pivot_longer(-level, names_to = "sample", values_to = "result") %>%
      filter(!is.na(result))
  })

  # Salida: Histograma
  output$results_histogram <- renderPlotly({
    plot_data <- plot_data_long()
    req(plot_data)
    hist_plot <- ggplot(plot_data, aes(x = result)) +
      geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 20) +
      geom_density(alpha = 0.4, fill = "lightblue") +
      facet_wrap(~level, scales = "free") +
      labs(
        title = "Distribución por nivel",
        x = "Resultado", y = "Densidad"
      ) +
      theme_minimal()
    plotly::ggplotly(hist_plot)
  })

  # Salida: Diagrama de caja
  output$results_boxplot <- renderPlotly({
    plot_data <- plot_data_long()
    req(plot_data)
    box_plot <- ggplot(plot_data, aes(x = "", y = result)) +
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      facet_wrap(~level, scales = "free") +
      labs(
        title = "Diagrama de caja por nivel",
        x = NULL, y = "Resultado"
      ) +
      theme_minimal()
    plotly::ggplotly(box_plot)
  })

  # Salida: Vista previa de datos de homogeneidad
  output$homogeneity_preview_table <- renderDataTable({
    req(raw_data(), input$target_level)
    homogeneity_data <- raw_data()
    # Encontrar la primera columna que empieza con "sample_"
    first_sample_col <- names(homogeneity_data)[grep("sample_", names(homogeneity_data))][1]
    homogeneity_data %>%
      filter(level == input$target_level) %>%
      mutate(across(where(is.numeric), ~ round(.x, 5))) %>%
      select(level, all_of(first_sample_col))
  })

  # Salida: Tabla de Estadísticos Robustos
  output$robust_stats_table <- renderTable(
    {
      res <- homogeneity_run()
      if (is.null(res$error)) {
        data.frame(
          Estadístico = c("Mediana (x_pt)", "Diferencia absoluta mediana", "MADe (sigma_pt)", "nIQR"),
          Valor = sprintf("%.5f", c(res$median_val, res$median_abs_diff, res$sigma_pt, res$n_iqr))
        )
      }
    },
    spacing = "l"
  )

  # Salida: Resumen de Estadísticos Robustos
  output$robust_stats_summary <- renderPrint({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      cat(sprintf("Valor mediano: %.5f\n", res$median_val))
      cat(sprintf("Diferencia absoluta mediana: %.5f\n", res$median_abs_diff))
      cat(sprintf("MADe (sigma_pt): %.5f\n", res$sigma_pt))
      cat(sprintf("nIQR: %.5f\n", res$n_iqr))
    }
  })

  # Salida: Conclusión de Homogeneidad
  output$homog_conclusion <- renderUI({
    res <- homogeneity_run()
    if (!is.null(res$error)) {
      div(class = "alert alert-danger", res$error)
    } else {
      div(class = res$conclusion_class, HTML(res$conclusion))
    }
  })

  # Salida: Componentes de varianza
  output$variance_components <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      df <- data.frame(
        Componente = c(
          "Valor asignado (xpt)",
          "DE robusta (sigma_pt)",
          "Incertidumbre del valor asignado (u_xpt)",
          "DE entre muestras (ss)",
          "DE dentro de la muestra (sw)",
          "---",
          "Criterio c",
          "Criterio c (expandido)"
        ),
        Valor = c(
          format_num(c(res$median_val, res$sigma_pt, res$u_xpt, res$ss, res$sw)),
          "",
          format_num(c(res$c_criterion, res$c_criterion_expanded))
        )
      )
      df
    }
  })

  # Salida: Conclusión de Estabilidad
  output$stability_conclusion <- renderUI({
    res <- stability_run()
    if (!is.null(res$error)) {
      div(class = "alert alert-danger", res$error)
    } else {
      div(class = res$conclusion_class, HTML(res$conclusion))
    }
  })

  # Salida: Detalles de Estabilidad
  output$stability_details <- renderPrint({
    res <- stability_run()
    if (is.null(res$error)) {
      cat(res$details)
    }
  })

  # Salida: Prueba t de Estabilidad
  output$stability_ttest <- renderPrint({
    res <- stability_run()
    if (is.null(res$error)) {
      cat(res$ttest_conclusion, "

")
      print(res$ttest_summary, digits = 9)
    }
  })

  # Salida: Tabla de detalles por ítem
  output$details_per_item_table <- renderTable(
    {
      res <- homogeneity_run()
      if (is.null(res$error)) {
        res$intermediate_df %>% mutate(across(where(is.numeric), ~ round(.x, 5)))
      }
    },
    spacing = "l",
    digits = 5
  )

  # Salida: Tabla de estadísticos resumidos
  output$details_summary_stats_table <- renderTable(
    {
      res <- homogeneity_run()
      if (is.null(res$error)) {
        data.frame(
          Parámetro = c(
            "Media general",
            "DE de medias",
            "Varianza de las medias (s_x_bar_sq)",
            "sw",
            "Varianza dentro de la muestra (s_w_sq)",
            "ss",
            "---",
            "Valor asignado (xpt)",
            "Mediana de diferencias absolutas",
            "Número de ítems (g)",
            "Número de réplicas (m)",
            "DE robusta (MADe)",
            "nIQR",
            "Incertidumbre del valor asignado (u_xpt)",
            "---",
            "Criterio c",
            "Criterio c (expandido)"
          ),
          Valor = c(
            c(format_num(res$general_mean), format_num(res$sd_of_means), format_num(res$s_x_bar_sq), format_num(res$sw), format_num(res$s_w_sq), format_num(res$ss)),
            "",
            c(format_num(res$median_val), format_num(res$median_abs_diff), res$g, res$m, format_num(res$sigma_pt), format_num(res$n_iqr), format_num(res$u_xpt)),
            "",
            c(format_num(res$c_criterion), format_num(res$c_criterion_expanded))
          )
        )
      }
    },
    spacing = "l"
  )

  # --- Salidas para Pestaña de Análisis de Datos de estabilidad ---

  # Salida: Conclusión de Homogeneidad para Datos de estabilidad
  output$homog_conclusion_stability <- renderUI({
    res <- homogeneity_run_stability()
    if (!is.null(res$error)) {
      div(class = "alert alert-danger", res$error)
    } else {
      div(class = res$stab_conclusion_class, HTML(res$stab_conclusion))
    }
  })

  # Salida: Componentes de varianza para Datos de estabilidad
  output$variance_components_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
      df <- data.frame(
        Componente = c(
          "Valor asignado (xpt)",
          "DE robusta (sigma_pt)",
          "Incertidumbre del valor asignado (u_xpt)"
        ),
        Valor = c(
          sprintf("%.5f", res$stab_median_val),
          sprintf("%.5f", res$stab_sigma_pt),
          sprintf("%.5f", res$stab_u_xpt)
        )
      )
      df
    }
  })

  # Salida: Tabla de detalles por ítem para Datos de estabilidad
  output$details_per_item_table_stability <- renderTable(
    {
      res <- homogeneity_run_stability()
      if (is.null(res$error)) {
        res$stab_intermediate_df %>% mutate(across(where(is.numeric), ~ round(.x, 5)))
      }
    },
    spacing = "l",
    digits = 5
  )

  # Salida: Tabla de estadísticos resumidos para Datos de estabilidad
  output$details_summary_stats_table_stability <- renderTable(
    {
      res <- homogeneity_run_stability()
      if (is.null(res$error)) {
        data.frame(
          Parámetro = c(
            "Media general",
            "Diferencia absoluta respecto a la media general",
            "DE de medias",
            "Varianza de las medias (s_x_bar_sq)",
            "sw",
            "Varianza dentro de la muestra (s_w_sq)",
            "ss",
            "---",
            "Valor asignado (xpt)",
            "Mediana de diferencias absolutas",
            "Número de ítems (g)",
            "Número de réplicas (m)",
            "DE robusta (MADe)",
            "nIQR",
            "Incertidumbre del valor asignado (u_xpt)",
            "---",
            "Criterio c",
            "Criterio c (expandido)"
          ),
          Valor = c(
            c(format_num(res$stab_general_mean), format_num(res$diff_hom_stab), format_num(res$stab_sd_of_means), format_num(res$stab_s_x_bar_sq), format_num(res$stab_sw), format_num(res$stab_s_w_sq), format_num(res$stab_ss)),
            "",
            c(format_num(res$stab_median_val), format_num(res$stab_median_abs_diff), res$g, res$m, format_num(res$stab_sigma_pt), format_num(res$stab_n_iqr), format_num(res$stab_u_xpt)),
            "",
            c(format_num(res$stab_c_criterion), format_num(res$stab_c_criterion_expanded))
          )
        )
      }
    },
    spacing = "l"
  )

  # --- Módulo de Puntajes PT ---

  # UI Dinámica para selectores de Puntajes PT
  output$scores_pollutant_selector <- renderUI({
    req(pt_prep_data())
    choices <- unique(pt_prep_data()$pollutant)
    selectInput("scores_pollutant", "Seleccionar analito:", choices = choices)
  })

  output$scores_n_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$scores_pollutant) %>%
      pull(n_lab) %>%
      unique() %>%
      sort()
    selectInput("scores_n_lab", "Seleccionar esquema PT (por n):", choices = choices)
  })

  output$scores_level_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$scores_pollutant, n_lab == input$scores_n_lab) %>%
      pull(level) %>%
      unique()
    selectInput("scores_level", "Seleccionar nivel:", choices = choices)
  })

  score_combo_info <- list(
    ref = list(title = "Referencia (1)", label = "1"),
    consensus_ma = list(title = "Consenso MADe (2a)", label = "2a"),
    consensus_niqr = list(title = "Consenso nIQR (2b)", label = "2b"),
    algo = list(title = "Algoritmo A (3)", label = "3")
  )

  global_combo_specs <- list(
    ref = list(title = "Referencia (1)", label = "1", tab = "z1 - Referencia (1)"),
    consensus_ma = list(title = "Consenso MADe (2a)", label = "2a", tab = "z2a - Consenso MADe (2a)"),
    consensus_niqr = list(title = "Consenso nIQR (2b)", label = "2b", tab = "z2b - Consenso nIQR (2b)"),
    algo = list(title = "Algoritmo A (3)", label = "3", tab = "z3 - Algoritmo A (3)")
  )

  ensure_classification_columns <- function(df) {
    required_cols <- c(
      "classification_z_en",
      "classification_z_en_code",
      "classification_zprime_en",
      "classification_zprime_en_code"
    )
    if (is.null(df)) {
      return(df)
    }
    for (col in required_cols) {
      if (!col %in% names(df)) {
        df[[col]] <- rep(NA_character_, nrow(df))
      }
    }
    df
  }



  compute_combo_scores <- function(participants_df, x_pt, sigma_pt, u_xpt, combo_meta, k = 2, u_hom = 0, u_stab = 0) {
    x_pt_def <- x_pt
    u_xpt_def <- sqrt(u_xpt^2 + u_hom^2 + u_stab^2)
    if (!is.finite(x_pt_def)) {
      return(list(
        error = sprintf("Valor asignado no disponible para %s.", combo_meta$title)
      ))
    }
    if (!is.finite(sigma_pt) || sigma_pt <= 0) {
      return(list(
        error = sprintf("sigma_pt no valido para %s.", combo_meta$title)
      ))
    }
    if (!is.finite(u_xpt_def) || u_xpt_def < 0) {
      u_xpt_def <- 0
    }
    participants_df <- participants_df %>%
      mutate(
        uncertainty_std_missing = !is.finite(uncertainty_std),
        uncertainty_std = ifelse(uncertainty_std_missing, NA_real_, uncertainty_std)
      )

    z_values <- (participants_df$result - x_pt_def) / sigma_pt
    zprime_den <- sqrt(sigma_pt^2 + u_xpt_def^2)
    z_prime_values <- if (zprime_den > 0) {
      (participants_df$result - x_pt_def) / zprime_den
    } else {
      NA_real_
    }
    zeta_den <- sqrt(participants_df$uncertainty_std^2 + u_xpt_def^2)
    zeta_values <- ifelse(zeta_den > 0, (participants_df$result - x_pt_def) / zeta_den, NA_real_)
    U_xi <- k * participants_df$uncertainty_std
    U_xpt <- k * u_xpt_def
    en_den <- sqrt(U_xi^2 + U_xpt^2)
    en_values <- ifelse(en_den > 0, (participants_df$result - x_pt_def) / en_den, NA_real_)

    data <- participants_df %>%
      mutate(
        combination = combo_meta$title,
        combination_label = combo_meta$label,
        x_pt = x_pt_def,
        sigma_pt = sigma_pt,
        u_xpt = u_xpt,
        u_xpt_def = u_xpt_def,
        u_hom = u_hom,
        u_stab = u_stab,
        k_factor = k,
        z_score = z_values,
        z_score_eval = evaluate_z_score_vec(z_score),
        z_prime_score = z_prime_values,
        z_prime_score_eval = evaluate_z_score_vec(z_prime_score),
        zeta_score = zeta_values,
        zeta_score_eval = evaluate_z_score_vec(zeta_score),
        En_score = en_values,
        En_score_eval = evaluate_en_score_vec(En_score),
        U_xi = U_xi,
        U_xpt = U_xpt
      )

    list(
      error = NULL,
      title = combo_meta$title,
      label = combo_meta$label,
      x_pt = x_pt_def,
      x_pt_def = x_pt_def,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      u_xpt_def = u_xpt_def,
      u_hom = u_hom,
      u_stab = u_stab,
      data = data
    )
  }

  plot_scores <- function(df, score_col, title, subtitle, ylab, warn_limits = NULL, action_limits = NULL) {
    score_values <- df[[score_col]]
    if (all(!is.finite(score_values))) {
      return(
        ggplot() +
          theme_void() +
          labs(title = title, subtitle = paste(subtitle, "- sin datos válidos"), y = ylab)
      )
    }
    participant_levels <- sort(unique(df$participant_id))
    gg <- ggplot(df, aes(x = factor(participant_id, levels = participant_levels), y = score_values)) +
      geom_hline(yintercept = 0, linetype = "solid", color = "grey50") +
      geom_point(size = 3, color = "#2C3E50") +
      geom_segment(aes(xend = factor(participant_id, levels = participant_levels), yend = 0), color = "#2C3E50") +
      labs(title = title, subtitle = subtitle, x = "Participante", y = ylab) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    if (!is.null(warn_limits)) {
      gg <- gg +
        geom_hline(yintercept = warn_limits, linetype = "dashed", color = "#E67E22")
    }
    if (!is.null(action_limits)) {
      gg <- gg +
        geom_hline(yintercept = action_limits, linetype = "dashed", color = "#C0392B")
    }
    if (score_col %in% c("z_score", "z_prime_score")) {
      gg <- gg + coord_cartesian(ylim = c(-4, 4))
    }
    gg
  }

  compute_scores_for_selection <- function(target_pollutant, target_n_lab, target_level, summary_data, max_iter = 50, k_factor = 2) {
    subset_data <- summary_data %>%
      filter(
        pollutant == .env$target_pollutant,
        n_lab == .env$target_n_lab,
        level == .env$target_level
      )

    if (nrow(subset_data) == 0) {
      return(list(error = "No se encontraron datos para la combinación seleccionada."))
    }

    hom_res <- tryCatch(
      compute_homogeneity_metrics(target_pollutant, target_level),
      error = function(e) list(error = conditionMessage(e))
    )
    if (!is.null(hom_res$error)) {
      return(list(error = paste("Error obteniendo parámetros de homogeneidad:", hom_res$error)))
    }
    sigma_pt1 <- hom_res$sigma_pt
    u_xpt1 <- hom_res$u_xpt

    participant_data <- subset_data %>%
      filter(participant_id != "ref") %>%
      group_by(participant_id) %>%
      summarise(
        result = mean(mean_value, na.rm = TRUE),
        sd_value = mean(sd_value, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        pollutant = target_pollutant,
        n_lab = target_n_lab,
        level = target_level,
        uncertainty_std = if (!is.null(hom_res$m) && hom_res$m > 0) sd_value / sqrt(hom_res$m) else sd_value
      )

    if (nrow(participant_data) == 0) {
      return(list(error = "No se encontraron participantes (distintos al valor de referencia) para la combinación seleccionada."))
    }

    ref_data <- subset_data %>% filter(participant_id == "ref")
    if (nrow(ref_data) == 0) {
      return(list(error = "No se encontró información del participante de referencia para esta combinación."))
    }
    x_pt1 <- mean(ref_data$mean_value, na.rm = TRUE)

    x_pt1 <- mean(ref_data$mean_value, na.rm = TRUE)

    # Calcular u_hom
    u_hom_val <- hom_res$ss
    
    # Calcular u_stab
    stab_res <- tryCatch(
      compute_stability_metrics(target_pollutant, target_level, hom_res),
      error = function(e) list(error = conditionMessage(e))
    )
    
    u_stab_val <- 0
    if (is.null(stab_res$error)) {
      y1 <- hom_res$general_mean
      y2 <- stab_res$stab_general_mean
      d_max <- abs(y1 - y2)
      u_stab_val <- d_max / sqrt(3)
    }

    values <- participant_data$result
    n_part <- length(values)

    median_val <- median(values, na.rm = TRUE)
    mad_val <- median(abs(values - median_val), na.rm = TRUE)
    sigma_pt_2a <- 1.483 * mad_val
    sigma_pt_2b <- calculate_niqr(values)
    u_xpt2a <- if (is.finite(sigma_pt_2a)) 1.25 * sigma_pt_2a / sqrt(n_part) else NA_real_
    u_xpt2b <- if (is.finite(sigma_pt_2b)) 1.25 * sigma_pt_2b / sqrt(n_part) else NA_real_

    algo_res <- if (n_part >= 3) {
      run_algorithm_a(values = values, ids = participant_data$participant_id, max_iter = max_iter)
    } else {
      list(error = "Se requieren al menos tres participantes para calcular el Algoritmo A.")
    }

    combos <- list()
    combos$ref <- compute_combo_scores(participant_data, x_pt1, sigma_pt1, u_xpt1, score_combo_info$ref, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)
    combos$consensus_ma <- compute_combo_scores(participant_data, median_val, sigma_pt_2a, u_xpt2a, score_combo_info$consensus_ma, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)
    combos$consensus_niqr <- compute_combo_scores(participant_data, median_val, sigma_pt_2b, u_xpt2b, score_combo_info$consensus_niqr, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)

    if (is.null(algo_res$error)) {
      u_xpt3 <- 1.25 * algo_res$robust_sd / sqrt(n_part)
      combos$algo <- compute_combo_scores(participant_data, algo_res$assigned_value, algo_res$robust_sd, u_xpt3, score_combo_info$algo, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)
    } else {
      combos$algo <- list(error = algo_res$error, title = score_combo_info$algo$title, label = score_combo_info$algo$label)
    }

    summary_table <- map_dfr(names(score_combo_info), function(key) {
      meta <- score_combo_info[[key]]
      combo <- combos[[key]]
      if (is.null(combo)) {
        return(NULL)
      }
      if (!is.null(combo$error)) {
        tibble(
          Combinación = meta$title,
          Etiqueta = meta$label,
          `x_pt` = NA_real_,
          `x_pt_def` = NA_real_,
          `sigma_pt` = NA_real_,
          `u(x_pt)` = NA_real_,
          `u(x_pt)_def` = NA_real_,
          Nota = combo$error
        )
      } else {
        tibble(
          Combinación = combo$title,
          Etiqueta = combo$label,
          `x_pt` = combo$x_pt,
          `x_pt_def` = combo$x_pt_def,
          `sigma_pt` = combo$sigma_pt,
          `u(x_pt)` = combo$u_xpt,
          `u(x_pt)_def` = combo$u_xpt_def,
          Nota = ""
        )
      }
    })

    overview_table <- map_dfr(names(score_combo_info), function(key) {
      meta <- score_combo_info[[key]]
      combo <- combos[[key]]
      if (is.null(combo)) {
        return(NULL)
      }
      if (!is.null(combo$error)) {
        tibble(
          Combinación = meta$title,
          Participante = NA_character_,
          Resultado = NA_real_,
          `u(xi)` = NA_real_,
          `Puntaje z` = NA_real_,
          `Evaluación z` = combo$error,
          `Puntaje z'` = NA_real_,
          `Evaluación z'` = "",
          `Puntaje zeta` = NA_real_,
          `Evaluación zeta` = "",
          `Puntaje En` = NA_real_,
          `Puntaje En Eval` = ""
        )
      } else {
        combo$data %>%
          transmute(
            Combinación = combo$title,
            Participante = participant_id,
            Resultado = result,
            `u(xi)` = uncertainty_std,
            `Puntaje z` = z_score,
            `Evaluación z` = z_score_eval,
            `Puntaje z'` = z_prime_score,
            `Evaluación z'` = z_prime_score_eval,
            `Puntaje zeta` = zeta_score,
            `Evaluación zeta` = zeta_score_eval,
            `Puntaje En` = En_score,
            `Puntaje En Eval` = En_score_eval
          )
      }
    })

    list(
      error = NULL,
      combos = combos,
      summary = summary_table,
      overview = overview_table,
      k = k_factor
    )
  }

  observeEvent(input$scores_run, {
    req(pt_prep_data())
    summary_data <- isolate(pt_prep_data())

    combos_df <- summary_data %>%
      distinct(pollutant, n_lab, level)

    if (nrow(combos_df) == 0) {
      scores_results_cache(NULL)
      scores_trigger(Sys.time())
      return()
    }

    max_iter_algo <- if (!is.null(input$algoA_max_iter) && is.finite(input$algoA_max_iter)) input$algoA_max_iter else 50
    results <- list()

    for (i in seq_len(nrow(combos_df))) {
      pollutant_val <- combos_df$pollutant[i]
      n_lab_val <- combos_df$n_lab[i]
      level_val <- combos_df$level[i]
      key <- paste(pollutant_val, as.character(n_lab_val), level_val, sep = "||")

      res <- compute_scores_for_selection(
        target_pollutant = pollutant_val,
        target_n_lab = n_lab_val,
        target_level = level_val,
        summary_data = summary_data,
        max_iter = max_iter_algo,
        k_factor = 2
      )

      results[[key]] <- res
    }

    scores_results_cache(results)
    scores_trigger(Sys.time())
  })

  global_report_data <- reactive({
    if (is.null(scores_trigger())) {
      return(list(
        error = "Calcule los puntajes para habilitar el reporte global.",
        summary = tibble(),
        overview = tibble(),
        combos = tibble(),
        errors = tibble()
      ))
    }

    cache <- scores_results_cache()
    if (is.null(cache) || length(cache) == 0) {
      return(list(
        error = "No se generaron resultados globales. Ejecute 'Calcular puntajes'.",
        summary = tibble(),
        overview = tibble(),
        combos = tibble(),
        errors = tibble()
      ))
    }

    summary_rows <- list()
    overview_rows <- list()
    combo_rows <- list()
    error_rows <- list()

    purrr::iwalk(cache, function(res, key) {
      parts <- strsplit(key, "\\|\\|")[[1]]
      pollutant_val <- parts[1]
      n_lab_val <- suppressWarnings(as.numeric(parts[2]))
      if (is.na(n_lab_val)) {
        n_lab_val <- parts[2]
      }
      level_val <- parts[3]

      if (!is.null(res$error)) {
        error_rows[[length(error_rows) + 1]] <<- tibble(
          pollutant = pollutant_val,
          n_lab = n_lab_val,
          level = level_val,
          source = "scores",
          message = res$error
        )
        return()
      }

      if (!is.null(res$summary) && nrow(res$summary) > 0) {
        summary_rows[[length(summary_rows) + 1]] <<- res$summary %>%
          mutate(
            pollutant = pollutant_val,
            n_lab = n_lab_val,
            level = level_val
          )
      }

      if (!is.null(res$overview) && nrow(res$overview) > 0) {
        overview_rows[[length(overview_rows) + 1]] <<- res$overview %>%
          mutate(
            pollutant = pollutant_val,
            n_lab = n_lab_val,
            level = level_val
          )
      }

      purrr::iwalk(res$combos, function(combo_res, combo_key) {
        if (!is.null(combo_res$error)) {
          error_rows[[length(error_rows) + 1]] <<- tibble(
            pollutant = pollutant_val,
            n_lab = n_lab_val,
            level = level_val,
            source = combo_key,
            message = combo_res$error
          )
          return()
        }
        if (is.null(combo_res$data) || nrow(combo_res$data) == 0) {
          return()
        }
        combo_rows[[length(combo_rows) + 1]] <<- combo_res$data %>%
          mutate(
            pollutant = pollutant_val,
            n_lab = n_lab_val,
            level = level_val,
            combo_key = combo_key
          )
      })
    })

    normalize_n <- function(df) {
      if (is.null(df) || nrow(df) == 0) {
        return(df)
      }
      df %>%
        mutate(
          n_lab = as.character(n_lab),
          n_lab_numeric = suppressWarnings(as.numeric(n_lab))
        )
    }

    list(
      error = NULL,
      summary = normalize_n(if (length(summary_rows) > 0) dplyr::bind_rows(summary_rows) else tibble()),
      overview = normalize_n(if (length(overview_rows) > 0) dplyr::bind_rows(overview_rows) else tibble()),
      combos = normalize_n(if (length(combo_rows) > 0) dplyr::bind_rows(combo_rows) else tibble()),
      errors = normalize_n(if (length(error_rows) > 0) dplyr::bind_rows(error_rows) else tibble())
    )
  })

  scores_results_selected <- reactive({
    req(input$scores_pollutant, input$scores_n_lab, input$scores_level)
    get_scores_result(input$scores_pollutant, input$scores_n_lab, input$scores_level)
  })

  scores_combined_data <- reactive({
    combine_scores_result(scores_results_selected())
  })

  # --- Módulo de Informe global ---
  score_heatmap_palettes <- list(
    z = c(
      "Satisfactorio" = "#00B050",
      "Cuestionable" = "#FFEB3B",
      "No satisfactorio" = "#D32F2F",
      "N/A" = "#BDBDBD"
    ),
    zprime = c(
      "Satisfactorio" = "#00B050",
      "Cuestionable" = "#FFEB3B",
      "No satisfactorio" = "#D32F2F",
      "N/A" = "#BDBDBD"
    ),
    zeta = c(
      "Satisfactorio" = "#00B050",
      "Cuestionable" = "#FFEB3B",
      "No satisfactorio" = "#D32F2F",
      "N/A" = "#BDBDBD"
    ),
    en = c(
      "Satisfactorio" = "#00B050",
      "Cuestionable" = "#D32F2F",
      "No satisfactorio" = "#D32F2F",
      "N/A" = "#BDBDBD"
    )
  )

  global_report_combos <- reactive({
    data <- global_report_data()
    if (!is.null(data$error)) {
      return(tibble())
    }
    combos <- data$combos
    if (is.null(combos) || nrow(combos) == 0) {
      return(tibble())
    }
    combos <- combos %>%
      mutate(
        pollutant = as.character(pollutant),
        n_lab = as.character(n_lab),
        level = as.character(level),
        combination = as.character(combination),
        combination_label = as.character(combination_label),
        participant_id = as.character(participant_id)
      )
    ensure_classification_columns(combos)
  })

  global_report_summary <- reactive({
    data <- global_report_data()
    if (!is.null(data$error)) {
      return(tibble())
    }
    summary_df <- data$summary
    if (is.null(summary_df) || nrow(summary_df) == 0) {
      return(tibble())
    }
    summary_df %>%
      mutate(
        pollutant = as.character(pollutant),
        n_lab = as.character(n_lab),
        level = as.character(level)
      )
  })

  global_report_overview <- reactive({
    data <- global_report_data()
    if (!is.null(data$error)) {
      return(tibble())
    }
    overview_df <- data$overview
    if (is.null(overview_df) || nrow(overview_df) == 0) {
      return(tibble())
    }
    overview_df %>%
      mutate(
        pollutant = as.character(pollutant),
        n_lab = as.character(n_lab),
        level = as.character(level)
      )
  })

  global_pt_size_info <- reactive({
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(tibble())
    }
    combos %>%
      filter(combo_key == "ref") %>%
      group_by(pollutant, n_lab) %>%
      summarise(
        participants = n_distinct(participant_id[participant_id != "ref"]),
        has_ref = any(participant_id == "ref"),
        .groups = "drop"
      )
  })

  global_xpt_summary_data <- reactive({
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(tibble())
    }
    combos %>%
      group_by(pollutant, n_lab, level, combination, combination_label, n_lab_numeric) %>%
      summarise(
        x_pt = dplyr::first(x_pt),
        u_xpt = dplyr::first(u_xpt),
        u_xpt_def = dplyr::first(u_xpt_def),
        sigma_pt = dplyr::first(sigma_pt),
        k_factor = dplyr::first(k_factor),
        .groups = "drop"
      ) %>%
      mutate(
        expanded_uncertainty = k_factor * u_xpt_def
      )
  })

  global_evaluation_summary_data <- reactive({
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(tibble())
    }
    combos %>%
      filter(participant_id != "ref") %>%
      select(
        pollutant, n_lab, level, combination, combination_label,
        z_score_eval, zeta_score_eval, En_score_eval
      ) %>%
      pivot_longer(
        cols = c(z_score_eval, zeta_score_eval, En_score_eval),
        names_to = "score_type",
        values_to = "evaluation"
      ) %>%
      mutate(
        pollutant = as.character(pollutant),
        n_lab = as.character(n_lab),
        level = as.character(level),
        combination = as.character(combination),
        combination_label = as.character(combination_label),
        score_type = sub("_eval$", "", score_type),
        evaluation = factor(evaluation, levels = c("Satisfactorio", "Cuestionable", "No satisfactorio", "N/A"))
      ) %>%
      count(pollutant, n_lab, level, combination, combination_label, score_type, evaluation, .drop = FALSE, name = "Conteo") %>%
      group_by(pollutant, n_lab, level, combination, combination_label, score_type) %>%
      mutate(
        Total = sum(Conteo),
        Porcentaje = ifelse(Total > 0, (Conteo / Total) * 100, 0)
      ) %>%
      ungroup() %>%
      select(-Total) %>%
      mutate(Criterio = paste(score_type, evaluation))
  })

  global_classification_summary_data <- reactive({
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(tibble())
    }
    combos <- ensure_classification_columns(combos)

    combos_filtered <- combos %>%
      filter(participant_id != "ref") %>%
      mutate(
        classification_z_en = ifelse(is.na(classification_z_en) | classification_z_en == "", "N/A", classification_z_en),
        classification_z_en_code = ifelse(is.na(classification_z_en_code) | classification_z_en_code == "", "N/A", classification_z_en_code),
        classification_zprime_en = ifelse(is.na(classification_zprime_en) | classification_zprime_en == "", "N/A", classification_zprime_en),
        classification_zprime_en_code = ifelse(is.na(classification_zprime_en_code) | classification_zprime_en_code == "", "N/A", classification_zprime_en_code)
      )

    if (nrow(combos_filtered) == 0) {
      return(tibble())
    }

    classification_long <- dplyr::bind_rows(
      combos_filtered %>%
        transmute(
          pollutant = as.character(pollutant),
          n_lab = as.character(n_lab),
          level = as.character(level),
          combination = as.character(combination),
          combination_label = as.character(combination_label),
          classification_type = "z + En",
          classification_label = classification_z_en,
          classification_code = classification_z_en_code
        ),
      combos_filtered %>%
        transmute(
          pollutant = as.character(pollutant),
          n_lab = as.character(n_lab),
          level = as.character(level),
          combination = as.character(combination),
          combination_label = as.character(combination_label),
          classification_type = "z' + En",
          classification_label = classification_zprime_en,
          classification_code = classification_zprime_en_code
        )
    )

    classification_long %>%
      mutate(
        classification_label = ifelse(is.na(classification_label) | classification_label == "", "N/A", classification_label),
        classification_code = ifelse(is.na(classification_code) | classification_code == "", "N/A", classification_code)
      ) %>%
      count(
        pollutant,
        n_lab,
        level,
        combination,
        combination_label,
        classification_type,
        classification_label,
        classification_code,
        name = "Conteo"
      ) %>%
      group_by(pollutant, n_lab, level, combination, combination_label, classification_type) %>%
      mutate(
        Total = sum(Conteo),
        Porcentaje = ifelse(Total > 0, (Conteo / Total) * 100, 0)
      ) %>%
      ungroup() %>%
      select(-Total)
  })

  metrological_compatibility_data <- eventReactive(input$run_metrological_compatibility, {
    # 1. Obtener Valores de Referencia
    prep_data <- pt_prep_data()
    if (is.null(prep_data)) return(tibble())
    
    ref_data_full <- prep_data %>%
      filter(participant_id == "ref")
      
    ref_data <- ref_data_full %>%
      group_by(pollutant, n_lab, level) %>%
      summarise(
        x_pt_ref = mean(mean_value, na.rm = TRUE), 
        sd_ref = mean(sd_value, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(n_lab = as.character(n_lab))
    
    # 2. Obtener Valores de Consenso (MADe y nIQR)
    consensus_cache <- consensus_results_cache()
    consensus_rows <- list()
    
    if (!is.null(consensus_cache)) {
      purrr::iwalk(consensus_cache, function(res, key) {
        if (is.null(res$summary)) return()
        parts <- strsplit(key, "\\|\\|")[[1]]
        
        val_row <- res$summary %>% filter(Estadístico == "x_pt(2) - Mediana")
        sigma_2a_row <- res$summary %>% filter(Estadístico == "sigma_pt_2a (MADe)")
        sigma_2b_row <- res$summary %>% filter(Estadístico == "sigma_pt_2b (nIQR)")
        n_row <- res$summary %>% filter(Estadístico == "Participantes")
        
        if (nrow(val_row) > 0) {
          consensus_rows[[length(consensus_rows) + 1]] <<- tibble(
            pollutant = parts[1],
            n_lab = parts[2],
            level = parts[3],
            x_pt_consensus = val_row$Valor,
            sigma_pt_2a = if(nrow(sigma_2a_row) > 0) sigma_2a_row$Valor else NA_real_,
            sigma_pt_2b = if(nrow(sigma_2b_row) > 0) sigma_2b_row$Valor else NA_real_,
            n_participants = if(nrow(n_row) > 0) n_row$Valor else NA_real_
          )
        }
      })
    }
    
    consensus_df <- if (length(consensus_rows) > 0) bind_rows(consensus_rows) else tibble()
    
    # 3. Obtener Valores del Algoritmo A
    algo_cache <- algoA_results_cache()
    algo_rows <- list()
    
    if (!is.null(algo_cache)) {
      purrr::iwalk(algo_cache, function(res, key) {
        if (is.null(res$assigned_value)) return()
        parts <- strsplit(key, "\\|\\|")[[1]]
        
        n_part <- if(!is.null(res$input_data)) nrow(res$input_data) else NA_real_
        
        algo_rows[[length(algo_rows) + 1]] <<- tibble(
          pollutant = parts[1],
          n_lab = parts[2],
          level = parts[3],
          x_pt_algo = res$assigned_value,
          sigma_pt_algo = res$robust_sd,
          n_participants_algo = n_part
        )
      })
    }
    
    algo_df <- if (length(algo_rows) > 0) bind_rows(algo_rows) else tibble()
    
    # 4. Combinar todo
    all_combos <- bind_rows(
      ref_data %>% select(pollutant, n_lab, level),
      if (nrow(consensus_df) > 0) consensus_df %>% select(pollutant, n_lab, level) else tibble(),
      if (nrow(algo_df) > 0) algo_df %>% select(pollutant, n_lab, level) else tibble()
    ) %>% distinct()
    
    if (nrow(all_combos) == 0) return(tibble())
    
    final_df <- all_combos %>%
      left_join(ref_data, by = c("pollutant", "n_lab", "level")) %>%
      left_join(consensus_df, by = c("pollutant", "n_lab", "level")) %>%
      left_join(algo_df, by = c("pollutant", "n_lab", "level"))
      
    # 5. Calcular Criterios por fila
    results_list <- list()
    
    for(i in seq_len(nrow(final_df))) {
      row <- final_df[i, ]
      p <- row$pollutant
      l <- row$level
      
      # Homogeneidad y Estabilidad
      hom_res <- tryCatch(compute_homogeneity_metrics(p, l), error = function(e) list(error=e$message))
      u_hom <- if(is.null(hom_res$error)) hom_res$ss else 0
      m <- if(is.null(hom_res$error) && !is.null(hom_res$m)) hom_res$m else 1
      
      stab_res <- tryCatch(compute_stability_metrics(p, l, hom_res), error = function(e) list(error=e$message))
      u_stab <- 0
      if(is.null(stab_res$error) && is.null(hom_res$error)) {
        d_max <- abs(hom_res$general_mean - stab_res$stab_general_mean)
        u_stab <- d_max / sqrt(3)
      }
      
      # cálculo de u_ref
      # u_ref = u_xi de referencia = k * (sd_ref / sqrt(m))
      # Usamos input$report_k para consistencia con otros informes.
      k_val <- if(!is.null(input$report_k)) input$report_k else 2
      
      u_ref <- if(!is.na(row$sd_ref)) k_val * (row$sd_ref / sqrt(m)) else NA_real_
      
      # Calcular u_xpt_def para cada método
      
      # Método 2a
      u_xpt_2a <- NA_real_
      u_xpt_def_2a <- NA_real_
      crit_2a <- NA_real_
      if(!is.na(row$x_pt_consensus) && !is.na(row$sigma_pt_2a) && !is.na(row$n_participants)) {
        u_xpt_2a <- 1.25 * row$sigma_pt_2a / sqrt(row$n_participants)
        u_xpt_def_2a <- sqrt(u_xpt_2a^2 + u_hom^2 + u_stab^2)
        if(!is.na(u_ref)) crit_2a <- sqrt(u_xpt_def_2a^2 + u_ref^2)
      }
      
      # Método 2b
      u_xpt_2b <- NA_real_
      u_xpt_def_2b <- NA_real_
      crit_2b <- NA_real_
      if(!is.na(row$x_pt_consensus) && !is.na(row$sigma_pt_2b) && !is.na(row$n_participants)) {
        u_xpt_2b <- 1.25 * row$sigma_pt_2b / sqrt(row$n_participants)
        u_xpt_def_2b <- sqrt(u_xpt_2b^2 + u_hom^2 + u_stab^2)
        if(!is.na(u_ref)) crit_2b <- sqrt(u_xpt_def_2b^2 + u_ref^2)
      }
      
      # Método 3
      u_xpt_3 <- NA_real_
      u_xpt_def_3 <- NA_real_
      crit_3 <- NA_real_
      if(!is.na(row$x_pt_algo) && !is.na(row$sigma_pt_algo) && !is.na(row$n_participants_algo)) {
        u_xpt_3 <- 1.25 * row$sigma_pt_algo / sqrt(row$n_participants_algo)
        u_xpt_def_3 <- sqrt(u_xpt_3^2 + u_hom^2 + u_stab^2)
        if(!is.na(u_ref)) crit_3 <- sqrt(u_xpt_def_3^2 + u_ref^2)
      }
      
      row$x_pt_2a <- row$x_pt_consensus
      row$x_pt_2b <- row$x_pt_consensus
      row$x_pt_3 <- row$x_pt_algo
      
      row$Diff_Ref_2a <- if(!is.na(row$x_pt_ref) && !is.na(row$x_pt_2a)) abs(row$x_pt_ref - row$x_pt_2a) else NA_real_
      row$Diff_Ref_2b <- if(!is.na(row$x_pt_ref) && !is.na(row$x_pt_2b)) abs(row$x_pt_ref - row$x_pt_2b) else NA_real_
      row$Diff_Ref_3 <- if(!is.na(row$x_pt_ref) && !is.na(row$x_pt_3)) abs(row$x_pt_ref - row$x_pt_3) else NA_real_
      
      row$Eval_Ref_2a <- if(!is.na(row$Diff_Ref_2a) && !is.na(crit_2a)) {
        if(row$Diff_Ref_2a <= crit_2a) "Compatible" else "No Compatible"
      } else NA_character_
      
      row$Eval_Ref_2b <- if(!is.na(row$Diff_Ref_2b) && !is.na(crit_2b)) {
        if(row$Diff_Ref_2b <= crit_2b) "Compatible" else "No Compatible"
      } else NA_character_
      
      row$Eval_Ref_3 <- if(!is.na(row$Diff_Ref_3) && !is.na(crit_3)) {
        if(row$Diff_Ref_3 <= crit_3) "Compatible" else "No Compatible"
      } else NA_character_
      
      row$Crit_Ref_2a <- crit_2a
      row$Crit_Ref_2b <- crit_2b
      row$Crit_Ref_3 <- crit_3
      
      row$u_ref <- u_ref
      
      results_list[[i]] <- row
    }
    
    final_df <- bind_rows(results_list) %>%
      select(pollutant, n_lab, level, x_pt_ref, u_ref, x_pt_2a, Diff_Ref_2a, Crit_Ref_2a, Eval_Ref_2a, x_pt_2b, Diff_Ref_2b, Crit_Ref_2b, Eval_Ref_2b, x_pt_3, Diff_Ref_3, Crit_Ref_3, Eval_Ref_3) %>%
      arrange(pollutant, n_lab, level)
      
    final_df
  })

  global_level_summary_data <- reactive({
    req(pt_prep_data())
    data <- pt_prep_data()
    if (is.null(data) || nrow(data) == 0) {
      return(tibble())
    }
    data %>%
      mutate(
        pollutant = as.character(pollutant),
        n_lab = as.character(n_lab),
        level = as.character(level)
      ) %>%
      distinct(pollutant, n_lab, level) %>%
      mutate(level_numeric = readr::parse_number(level)) %>%
      arrange(pollutant, n_lab, level_numeric, level) %>%
      group_by(pollutant, n_lab) %>%
      mutate(Run_Order = row_number()) %>%
      ungroup() %>%
      select(
        pollutant,
        n_lab,
        Run_Order,
        level
      )
  })

  output$global_report_pollutant_selector <- renderUI({
    data <- global_report_data()
    if (!is.null(data$error)) {
      return(div(class = "alert alert-info", data$error))
    }
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(helpText("Calcule los puntajes para habilitar esta sección."))
    }
    choices <- combos %>%
      distinct(pollutant) %>%
      arrange(pollutant) %>%
      pull(pollutant)
    selected <- if (!is.null(input$global_report_pollutant) && input$global_report_pollutant %in% choices) {
      input$global_report_pollutant
    } else {
      choices[1]
    }
    selectInput("global_report_pollutant", "Analito:", choices = choices, selected = selected)
  })

  output$global_report_n_selector <- renderUI({
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(NULL)
    }
    req(input$global_report_pollutant)

    combos_filtered <- combos %>%
      filter(pollutant == input$global_report_pollutant, combo_key == "ref")
    if (nrow(combos_filtered) == 0) {
      return(helpText("No hay esquemas PT disponibles para este analito."))
    }

    choices_df <- combos_filtered %>%
      distinct(n_lab, n_lab_numeric) %>%
      arrange(n_lab_numeric, n_lab)

    pt_info <- global_pt_size_info()
    choice_named <- purrr::map_chr(choices_df$n_lab, function(n_val) {
      row <- pt_info %>%
        filter(pollutant == input$global_report_pollutant, n_lab == n_val)
      if (nrow(row) == 0) {
        return(paste0("n = ", n_val))
      }
      ref_txt <- ifelse(row$has_ref[1], " + ref", "")
      paste0("n = ", n_val, " (", row$participants[1], " participantes", ref_txt, ")")
    })

    selected <- if (!is.null(input$global_report_n_lab) && input$global_report_n_lab %in% choices_df$n_lab) {
      input$global_report_n_lab
    } else {
      choices_df$n_lab[1]
    }

    selectInput(
      "global_report_n_lab",
      "Esquema PT (n):",
      choices = stats::setNames(choices_df$n_lab, choice_named),
      selected = selected
    )
  })

  output$global_report_level_selector <- renderUI({
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(NULL)
    }
    req(input$global_report_pollutant, input$global_report_n_lab)

    levels_df <- combos %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        combo_key == "ref"
      ) %>%
      distinct(level) %>%
      mutate(level_numeric = readr::parse_number(level)) %>%
      arrange(level_numeric, level)

    if (nrow(levels_df) == 0) {
      return(helpText("No hay niveles disponibles para esta selección."))
    }

    selected <- if (!is.null(input$global_report_level) && input$global_report_level %in% levels_df$level) {
      input$global_report_level
    } else {
      levels_df$level[1]
    }

    selectInput(
      "global_report_level",
      "Nivel:",
      choices = stats::setNames(levels_df$level, levels_df$level),
      selected = selected
    )
  })

  output$global_report_pt_size_info <- renderUI({
    info <- global_pt_size_info()
    if (nrow(info) == 0) {
      return(NULL)
    }
    req(input$global_report_pollutant, input$global_report_n_lab)
    row <- info %>%
      filter(pollutant == input$global_report_pollutant, n_lab == input$global_report_n_lab)
    if (nrow(row) == 0) {
      return(NULL)
    }
    participants_text <- sprintf(
      "%d participantes%s",
      row$participants[1],
      ifelse(row$has_ref[1], " + ref", "")
    )
    tags$div(
      class = "small text-muted",
      strong("Resumen de tamaño PT:"), br(),
      participants_text
    )
  })

  get_global_summary_row <- function(spec) {
    summary_df <- global_report_summary()
    if (nrow(summary_df) == 0) {
      return(tibble())
    }
    req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
    summary_df %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        level == input$global_report_level,
        Etiqueta == spec$label
      )
  }

  get_global_overview_data <- function(spec) {
    overview_df <- global_report_overview()
    if (nrow(overview_df) == 0) {
      return(tibble())
    }
    req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
    overview_df %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        level == input$global_report_level,
        Combinación == spec$title
      )
  }

  get_combo_levels_order <- function(combos_filtered) {
    combos_filtered %>%
      distinct(level) %>%
      mutate(level_numeric = readr::parse_number(level)) %>%
      arrange(level_numeric, level) %>%
      pull(level)
  }

  render_global_score_heatmap <- function(output_id, combo_key, score_col, eval_col, palette, title_prefix) {
    output[[output_id]] <- renderPlotly({
      combos <- global_report_combos()
      req(nrow(combos) > 0, input$global_report_pollutant, input$global_report_n_lab)
      spec <- global_combo_specs[[combo_key]]
      filtered <- combos %>%
        filter(
          pollutant == input$global_report_pollutant,
          n_lab == input$global_report_n_lab,
          combo_key == combo_key,
          combination_label == spec$label,
          participant_id != "ref"
        )
      if (nrow(filtered) == 0) {
        empty_plot <- ggplot() +
          theme_void() +
          labs(title = paste(title_prefix, "- sin datos disponibles"))
        return(plotly::ggplotly(empty_plot))
      }

      filtered <- filtered %>%
        mutate(run_label = as.character(level))

      participant_levels <- filtered %>%
        distinct(participant_id) %>%
        arrange(participant_id) %>%
        pull(participant_id)

      run_levels <- filtered %>%
        distinct(level, run_label) %>%
        mutate(level_numeric = readr::parse_number(as.character(level))) %>%
        arrange(level_numeric, level, run_label) %>%
        pull(run_label)

      base_grid <- expand.grid(
        participant_id = participant_levels,
        run_label = run_levels,
        stringsAsFactors = FALSE
      ) %>%
        as_tibble()

      value_sym <- rlang::sym(score_col)
      eval_sym <- rlang::sym(eval_col)

      plot_data <- base_grid %>%
        left_join(
          filtered %>%
            transmute(
              participant_id,
              run_label = as.character(level),
              score_value = !!value_sym,
              evaluation = !!eval_sym
            ),
          by = c("participant_id", "run_label")
        ) %>%
        mutate(
          evaluation = ifelse(is.na(evaluation) | evaluation == "", "N/A", evaluation),
          tile_label = ifelse(is.finite(score_value), sprintf("%.2f", score_value), ""),
          participant_id = factor(participant_id, levels = participant_levels),
          run_label = factor(run_label, levels = run_levels),
          evaluation = factor(evaluation, levels = names(palette))
        )

      heatmap_plot <- ggplot(plot_data, aes(x = run_label, y = participant_id, fill = evaluation)) +
        geom_tile(color = "white") +
        geom_text(aes(label = tile_label), size = 3, color = "#1B1B1B") +
        scale_fill_manual(values = palette, drop = FALSE, na.value = "#BDBDBD") +
        labs(
          title = paste(title_prefix, "para", spec$title),
          subtitle = paste("Analito:", input$global_report_pollutant),
          x = "Nivel",
          y = "Participante",
          fill = "Evaluación"
        ) +
        theme_minimal() +
        theme(
          panel.grid = element_blank(),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
      plotly::ggplotly(heatmap_plot)
    })
  }



  purrr::iwalk(global_combo_specs, function(spec, combo_key) {
    output[[paste0("global_params_", combo_key)]] <- renderTable(
      {
        summary_row <- get_global_summary_row(spec)
        if (nrow(summary_row) == 0) {
          return(data.frame(Mensaje = "No hay datos disponibles para esta combinación."))
        }
        if (any(summary_row$Nota != "")) {
          return(summary_row %>% select(Combinación, Nota))
        }
        summary_row %>%
          select(Combinación, `x_pt`, `sigma_pt`, `u(x_pt)`) %>%
          mutate(
            `x_pt` = sprintf("%.5f", `x_pt`),
            `sigma_pt` = sprintf("%.5f", `sigma_pt`),
            `u(x_pt)` = sprintf("%.5f", `u(x_pt)`)
          )
      },
      striped = TRUE,
      spacing = "l",
      rownames = FALSE
    )

    output[[paste0("global_overview_", combo_key)]] <- renderDataTable({
      overview <- get_global_overview_data(spec)
      if (nrow(overview) == 0) {
        return(datatable(data.frame(Mensaje = "No hay datos disponibles para esta combinación.")))
      }
      datatable(
        overview,
        options = list(scrollX = TRUE, pageLength = 12),
        rownames = FALSE
      ) %>%
        formatRound(columns = c("Resultado", "u(xi)", "Puntaje z", "Puntaje z'", "Puntaje zeta", "Puntaje En"), digits = 3)
    })

    render_global_score_heatmap(
      paste0("global_heatmap_z_", combo_key),
      combo_key,
      "z_score",
      "z_score_eval",
      score_heatmap_palettes$z,
      "Mapa de calor puntaje z"
    )

    render_global_score_heatmap(
      paste0("global_heatmap_zprime_", combo_key),
      combo_key,
      "z_prime_score",
      "z_prime_score_eval",
      score_heatmap_palettes$zprime,
      "Mapa de calor puntaje z'"
    )

    render_global_score_heatmap(
      paste0("global_heatmap_zeta_", combo_key),
      combo_key,
      "zeta_score",
      "zeta_score_eval",
      score_heatmap_palettes$zeta,
      "Mapa de calor puntaje zeta"
    )

    render_global_score_heatmap(
      paste0("global_heatmap_en_", combo_key),
      combo_key,
      "En_score",
      "En_score_eval",
      score_heatmap_palettes$en,
      "Mapa de calor Puntaje En"
    )


  })

  output$global_xpt_summary_table <- renderDataTable({
    summary_df <- global_xpt_summary_data()
    if (nrow(summary_df) == 0) {
      return(datatable(data.frame(Mensaje = "No hay información x_pt disponible.")))
    }
    req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
    filtered <- summary_df %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        level == input$global_report_level
      ) %>%
      arrange(combination_label, level)
    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Mensaje = "No hay información x_pt para la selección actual.")))
    }
    datatable(
      filtered %>%
        select(
          Combinación = combination,
          `Etiqueta de combinación` = combination_label,
          Nivel = level,
          `x_pt`,
          `u(x_pt_def)` = u_xpt_def,
          `Incertidumbre expandida` = expanded_uncertainty,
          `sigma_pt`
        ),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = c("x_pt", "u(x_pt_def)", "Incertidumbre expandida", "sigma_pt"), digits = 5)
  })

  output$global_level_summary_table <- renderTable(
    {
      level_df <- global_level_summary_data()
      if (nrow(level_df) == 0) {
        return(data.frame(Mensaje = "No hay información de niveles disponible."))
      }
      req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
      level_df %>%
        filter(
          pollutant == input$global_report_pollutant,
          n_lab == input$global_report_n_lab,
          level == input$global_report_level
        ) %>%
        transmute(
          `Orden de corrida` = Run_Order,
          Nivel = level
        )
    },
    striped = TRUE,
    spacing = "l",
    rownames = FALSE
  )

  output$global_evaluation_summary_table <- renderDataTable({
    summary_df <- global_evaluation_summary_data()
    if (nrow(summary_df) == 0) {
      return(datatable(data.frame(Mensaje = "No hay evaluaciones calculadas.")))
    }
    req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
    filtered <- summary_df %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        level == input$global_report_level
      ) %>%
      arrange(combination_label, level, score_type, evaluation)
    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Mensaje = "No hay evaluaciones para la selección actual.")))
    }
    datatable(
      filtered %>%
        select(
          Combinación = combination,
          Nivel = level,
          Criterio,
          Evaluación = evaluation,
          Conteo,
          Porcentaje
        ),
      options = list(pageLength = 12, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = "Porcentaje", digits = 1)
  })

  output$global_classification_summary_table <- renderDataTable({
    class_df <- global_classification_summary_data()
    if (nrow(class_df) == 0) {
      return(datatable(data.frame(Mensaje = "No hay clasificaciones calculadas.")))
    }
    req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
    filtered <- class_df %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        level == input$global_report_level
      ) %>%
      arrange(combination_label, level, classification_type, classification_code)
    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Mensaje = "No hay clasificaciones para la selección actual.")))
    }
    datatable(
      filtered %>%
        select(
          Combinación = combination,
          Nivel = level,
          `Clasificación` = classification_type,
          `Código` = classification_code,
          `Descripción` = classification_label,
          Conteo,
          Porcentaje
        ),
      options = list(pageLength = 12, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = "Porcentaje", digits = 1)
  })

  participants_available <- reactive({
    if (is.null(scores_trigger())) {
      return(tibble())
    }
    cache <- scores_results_cache()
    if (is.null(cache) || length(cache) == 0) {
      return(tibble())
    }
    purrr::imap_dfr(cache, function(res, key) {
      parts <- strsplit(key, "\\|\\|")[[1]]
      has_valid_data <- FALSE
      if (is.null(res$error) && !is.null(res$combos)) {
        has_valid_data <- any(purrr::map_lgl(res$combos, function(combo) {
          is.null(combo$error) && !is.null(combo$data) && nrow(combo$data) > 0
        }))
      }
      tibble(
        pollutant = parts[1],
        n_lab = parts[2],
        level = parts[3],
        has_data = has_valid_data
      )
    }) %>%
      filter(has_data)
  })

  output$participants_pollutant_selector <- renderUI({
    avail <- participants_available()
    if (nrow(avail) == 0) {
      return(helpText("Calcule los puntajes para habilitar esta sección."))
    }
    choices <- sort(unique(avail$pollutant))
    selected <- if (!is.null(input$participants_pollutant) && input$participants_pollutant %in% choices) {
      input$participants_pollutant
    } else {
      choices[1]
    }
    selectInput("participants_pollutant", "Seleccionar analito:", choices = choices, selected = selected)
  })

  output$participants_level_selector <- renderUI({
    avail <- participants_available()
    if (nrow(avail) == 0) {
      return(NULL)
    }
    req(input$participants_pollutant)
    combos <- avail %>% filter(pollutant == input$participants_pollutant)
    if (nrow(combos) == 0) {
      return(helpText("No hay niveles disponibles para este analito."))
    }
    combos <- combos %>%
      mutate(
        key = paste(pollutant, n_lab, level, sep = "||"),
        label = ifelse(is.na(n_lab) | n_lab == "", paste("Nivel", level), paste0("Nivel ", level, " (n=", n_lab, ")"))
      )
    selected <- if (!is.null(input$participants_level) && input$participants_level %in% combos$key) {
      input$participants_level
    } else {
      combos$key[1]
    }
    selectInput("participants_level", "Seleccionar nivel:", choices = stats::setNames(combos$key, combos$label), selected = selected)
  })

  participants_scores_selected <- reactive({
    avail <- participants_available()
    if (nrow(avail) == 0) {
      return(list(error = "Calcule los puntajes para habilitar esta sección."))
    }
    key <- input$participants_level
    if (is.null(key) || key == "") {
      return(list(error = "Seleccione un analito y nivel."))
    }
    parts <- strsplit(key, "\\|\\|")[[1]]
    if (length(parts) < 3) {
      return(list(error = "Selección inválida."))
    }
    get_scores_result(parts[1], parts[2], parts[3])
  })

  participants_combined_data <- reactive({
    combine_scores_result(participants_scores_selected())
  })

  scores_evaluation_summary <- reactive({
    info <- scores_combined_data()
    if (!is.null(info$error)) {
      return(list(error = info$error, table = tibble()))
    }
    combined <- info$data
    if (nrow(combined) == 0) {
      return(list(error = "No hay datos de puntajes calculados para esta selección.", table = tibble()))
    }
    scores_long <- combined %>%
      select(combination, z_score_eval, zeta_score_eval, En_score_eval) %>%
      pivot_longer(
        cols = c(z_score_eval, zeta_score_eval, En_score_eval),
        names_to = "score_type",
        values_to = "evaluation"
      ) %>%
      mutate(
        score_type = sub("_eval$", "", score_type),
        evaluation = factor(evaluation, levels = c("Satisfactorio", "Cuestionable", "No satisfactorio", "N/A"))
      )

    evaluation_summary <- scores_long %>%
      count(combination, score_type, evaluation, .drop = FALSE, name = "Conteo") %>%
      group_by(combination, score_type) %>%
      mutate(Porcentaje = ifelse(sum(Conteo) > 0, (Conteo / sum(Conteo)) * 100, 0)) %>%
      ungroup() %>%
      mutate(Criterio = paste(score_type, evaluation)) %>%
      select(Combinación = combination, Criterio, Conteo, Porcentaje)

    list(error = NULL, table = evaluation_summary)
  })

  output$scores_parameter_table <- renderTable(
    {
      res <- scores_results_selected()
      if (!is.null(res$error)) {
        return(data.frame(Mensaje = res$error))
      }
      res$summary
    },
    digits = 6,
    striped = TRUE,
    spacing = "l",
    rownames = FALSE
  )

  output$scores_overview_table <- renderDataTable({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(datatable(data.frame(Mensaje = res$error)))
    }
    datatable(res$overview, options = list(scrollX = TRUE, pageLength = 12), rownames = FALSE) %>%
      formatRound(columns = c("Resultado", "u(xi)", "Puntaje z", "Puntaje z'", "Puntaje zeta", "Puntaje En"), digits = 3)
  })

  output$scores_evaluation_summary <- renderTable(
    {
      eval_res <- scores_evaluation_summary()
      if (!is.null(eval_res$error)) {
        return(data.frame(Mensaje = eval_res$error))
      }
      eval_res$table
    },
    digits = 2,
    striped = TRUE,
    spacing = "l",
    rownames = FALSE
  )

  output$z_scores_panel <- renderUI({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(div(class = "alert alert-danger", res$error))
    }
    tagList(lapply(names(score_combo_info), function(key) {
      combo <- res$combos[[key]]
      meta <- score_combo_info[[key]]
      if (is.null(combo)) {
        return(NULL)
      }
      tagList(
        h4(meta$title),
        if (!is.null(combo$error)) {
          div(class = "alert alert-warning", combo$error)
        } else {
          tagList(
            dataTableOutput(paste0("z_table_", key)),
            plotlyOutput(paste0("z_plot_", key), height = "300px")
          )
        },
        hr()
      )
    }))
  })

  output$zprime_scores_panel <- renderUI({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(div(class = "alert alert-danger", res$error))
    }
    tagList(lapply(names(score_combo_info), function(key) {
      combo <- res$combos[[key]]
      meta <- score_combo_info[[key]]
      if (is.null(combo)) {
        return(NULL)
      }
      tagList(
        h4(meta$title),
        if (!is.null(combo$error)) {
          div(class = "alert alert-warning", combo$error)
        } else {
          tagList(
            dataTableOutput(paste0("zprime_table_", key)),
            plotlyOutput(paste0("zprime_plot_", key), height = "300px")
          )
        },
        hr()
      )
    }))
  })

  output$zeta_scores_panel <- renderUI({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(div(class = "alert alert-danger", res$error))
    }
    tagList(lapply(names(score_combo_info), function(key) {
      combo <- res$combos[[key]]
      meta <- score_combo_info[[key]]
      if (is.null(combo)) {
        return(NULL)
      }
      tagList(
        h4(meta$title),
        if (!is.null(combo$error)) {
          div(class = "alert alert-warning", combo$error)
        } else {
          tagList(
            dataTableOutput(paste0("zeta_table_", key)),
            plotlyOutput(paste0("zeta_plot_", key), height = "300px")
          )
        },
        hr()
      )
    }))
  })

  output$en_scores_panel <- renderUI({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(div(class = "alert alert-danger", res$error))
    }
    tagList(lapply(names(score_combo_info), function(key) {
      combo <- res$combos[[key]]
      meta <- score_combo_info[[key]]
      if (is.null(combo)) {
        return(NULL)
      }
      tagList(
        h4(meta$title),
        if (!is.null(combo$error)) {
          div(class = "alert alert-warning", combo$error)
        } else {
          tagList(
            dataTableOutput(paste0("en_table_", key)),
            plotlyOutput(paste0("en_plot_", key), height = "300px")
          )
        },
        hr()
      )
    }))
  })

  for (key in names(score_combo_info)) {
    local({
      combo_key <- key
      output[[paste0("z_table_", combo_key)]] <- renderDataTable({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo)) {
          return(datatable(data.frame(Mensaje = "Combinación no disponible.")))
        }
        if (!is.null(combo$error)) {
          return(datatable(data.frame(Mensaje = combo$error)))
        }
        datatable(
          combo$data %>%
            select(Participante = participant_id, Resultado = result, `u(xi)` = uncertainty_std, `Puntaje z` = z_score, `Evaluación z` = z_score_eval),
          options = list(scrollX = TRUE, pageLength = 10),
          rownames = FALSE
        ) %>%
          formatRound(columns = c("Resultado", "u(xi)", "Puntaje z"), digits = 3)
      })

      output[[paste0("z_plot_", combo_key)]] <- renderPlotly({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo) || !is.null(combo$error)) {
          return(NULL)
        }
        plotly::ggplotly(
          plot_scores(combo$data, "z_score", combo$title, "Límites de advertencia |z|=2, acción |z|=3", "Puntaje z", warn_limits = c(-2, 2), action_limits = c(-3, 3))
        )
      })

      output[[paste0("zprime_table_", combo_key)]] <- renderDataTable({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo)) {
          return(datatable(data.frame(Mensaje = "Combinación no disponible.")))
        }
        if (!is.null(combo$error)) {
          return(datatable(data.frame(Mensaje = combo$error)))
        }
        datatable(
          combo$data %>%
            select(Participante = participant_id, Resultado = result, `u(xi)` = uncertainty_std, `Puntaje z'` = z_prime_score, `Evaluación z'` = z_prime_score_eval),
          options = list(scrollX = TRUE, pageLength = 10),
          rownames = FALSE
        ) %>%
          formatRound(columns = c("Resultado", "u(xi)", "Puntaje z'"), digits = 3)
      })

      output[[paste0("zprime_plot_", combo_key)]] <- renderPlotly({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo) || !is.null(combo$error)) {
          return(NULL)
        }
        plotly::ggplotly(
          plot_scores(combo$data, "z_prime_score", combo$title, "Límites de advertencia |z'|=2, acción |z'|=3", "Puntaje z'", warn_limits = c(-2, 2), action_limits = c(-3, 3))
        )
      })

      output[[paste0("zeta_table_", combo_key)]] <- renderDataTable({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo)) {
          return(datatable(data.frame(Mensaje = "Combinación no disponible.")))
        }
        if (!is.null(combo$error)) {
          return(datatable(data.frame(Mensaje = combo$error)))
        }
        datatable(
          combo$data %>%
            select(Participante = participant_id, Resultado = result, `u(xi)` = uncertainty_std, `Puntaje zeta` = zeta_score, `Evaluación zeta` = zeta_score_eval),
          options = list(scrollX = TRUE, pageLength = 10),
          rownames = FALSE
        ) %>%
          formatRound(columns = c("Resultado", "u(xi)", "Puntaje zeta"), digits = 3)
      })

      output[[paste0("zeta_plot_", combo_key)]] <- renderPlotly({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo) || !is.null(combo$error)) {
          return(NULL)
        }
        plotly::ggplotly(
          plot_scores(combo$data, "zeta_score", combo$title, "Límites de advertencia |ζ|=2, acción |ζ|=3", "Puntaje Zeta", warn_limits = c(-2, 2), action_limits = c(-3, 3))
        )
      })

      output[[paste0("en_table_", combo_key)]] <- renderDataTable({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo)) {
          return(datatable(data.frame(Mensaje = "Combinación no disponible.")))
        }
        if (!is.null(combo$error)) {
          return(datatable(data.frame(Mensaje = combo$error)))
        }
        datatable(
          combo$data %>%
            select(Participante = participant_id, Resultado = result, `u(xi)` = uncertainty_std, `Puntaje En` = En_score, `Puntaje En Eval` = En_score_eval),
          options = list(scrollX = TRUE, pageLength = 10),
          rownames = FALSE
        ) %>%
          formatRound(columns = c("Resultado", "u(xi)", "Puntaje En"), digits = 3)
      })

      output[[paste0("en_plot_", combo_key)]] <- renderPlotly({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo) || !is.null(combo$error)) {
          return(NULL)
        }
        plotly::ggplotly(
          plot_scores(combo$data, "En_score", combo$title, "Límite de acción |En|=1", "Puntaje En", action_limits = c(-1, 1))
        )
      })
    })
  }

  output$scores_participant_tabs <- renderUI({
    info <- participants_combined_data()
    if (!is.null(info$error)) {
      return(helpText(info$error))
    }
    combined <- info$data %>% filter(participant_id != "ref")
    if (nrow(combined) == 0) {
      return(helpText("No hay participantes disponibles para esta selección."))
    }

    participants <- sort(unique(combined$participant_id))

    tab_panels <- lapply(participants, function(pid) {
      safe_id <- gsub("[^A-Za-z0-9]", "_", pid)
      table_id <- paste0("participant_table_", safe_id)
      plot_id <- paste0("participant_plot_", safe_id)

      output[[table_id]] <- renderDataTable({
        info <- participants_combined_data()
        if (!is.null(info$error)) {
          return(datatable(data.frame(Mensaje = info$error)))
        }
        participant_df <- info$data %>%
          filter(participant_id == pid)
        if (nrow(participant_df) == 0) {
          return(datatable(data.frame(Mensaje = "Sin datos para este participante.")))
        }
        table_df <- participant_df %>%
          arrange(combination_label, level) %>%
          transmute(
            Combinación = combination,
            Analito = pollutant,
            `Esquema PT (n)` = n_lab,
            Nivel = level,
            Resultado = result,
            `x_pt` = x_pt,
            `sigma_pt` = sigma_pt,
            `u(x_pt)` = u_xpt,
            `u(x_pt_def)` = u_xpt_def,
            `Puntaje z` = z_score,
            `Evaluación z` = z_score_eval,
            `Puntaje z'` = z_prime_score,
            `Evaluación z'` = z_prime_score_eval,
            `Puntaje zeta` = zeta_score,
            `Evaluación zeta` = zeta_score_eval,
            `Puntaje En` = En_score,
            `Puntaje En Eval` = En_score_eval
          )
        datatable(table_df, options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE) %>%
          formatRound(columns = c("Resultado", "x_pt", "sigma_pt", "u(x_pt)", "u(x_pt_def)", "Puntaje z", "Puntaje z'", "Puntaje zeta", "Puntaje En"), digits = 3)
      })

      output[[plot_id]] <- renderPlotly({
        info <- participants_combined_data()
        if (!is.null(info$error)) {
          return(NULL)
        }
        participant_df <- info$data %>%
          filter(participant_id == pid)
        if (nrow(participant_df) == 0) {
          return(NULL)
        }

        plot_df <- participant_df %>%
          filter(combination_label == "1" | combination_label == min(combination_label)) %>%
          head(n = n_distinct(.$level))

        level_factor <- factor(participant_df$level, levels = sort(unique(participant_df$level)))

        p_values <- ggplot(plot_df, aes(x = factor(level, levels = sort(unique(level))))) +
          geom_point(aes(y = result, color = "Participante"), size = 3) +
          geom_line(aes(y = result, group = 1, color = "Participante")) +
          geom_point(aes(y = x_pt, color = "Referencia"), size = 3) +
          geom_line(aes(y = x_pt, group = 1, color = "Referencia"), linetype = "dashed") +
          scale_color_manual(values = c("Participante" = "#1F78B4", "Referencia" = "#E31A1C")) +
          labs(title = paste("Valores (Referencia) -", pid), x = "Nivel", y = "Valor", color = NULL) +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        p_z <- ggplot(participant_df, aes(x = level_factor, y = z_score, group = combination, color = combination)) +
          geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#C0392B") +
          geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "#E67E22") +
          geom_hline(yintercept = 0, color = "grey50") +
          geom_line(position = position_dodge(width = 0.3)) +
          geom_point(size = 3, position = position_dodge(width = 0.3)) +
          labs(title = "Puntaje Z", x = "Nivel", y = "Z", color = "Combinación") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        p_zeta <- ggplot(participant_df, aes(x = level_factor, y = zeta_score, group = combination, color = combination)) +
          geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#C0392B") +
          geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "#E67E22") +
          geom_hline(yintercept = 0, color = "grey50") +
          geom_line(position = position_dodge(width = 0.3)) +
          geom_point(size = 3, position = position_dodge(width = 0.3)) +
          labs(title = "Puntaje Zeta", x = "Nivel", y = "Zeta", color = "Combinación") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        p_en <- ggplot(participant_df, aes(x = level_factor, y = En_score, group = combination, color = combination)) +
          geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "#C0392B") +
          geom_hline(yintercept = 0, color = "grey50") +
          geom_line(position = position_dodge(width = 0.3)) +
          geom_point(size = 3, position = position_dodge(width = 0.3)) +
          labs(title = "Puntaje En", x = "Nivel", y = "En", color = "Combinación") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        plotly::subplot(
          plotly::ggplotly(p_values),
          plotly::ggplotly(p_z),
          plotly::ggplotly(p_zeta),
          plotly::ggplotly(p_en),
          nrows = 2,
          shareX = FALSE,
          titleX = TRUE,
          titleY = TRUE
        )
      })

      tabPanel(
        title = tagList(icon("user"), pid),
        value = paste0("participant_", safe_id),
        h4("Resumen"),
        dataTableOutput(table_id),
        hr(),
        h4("Gráficos"),
        plotlyOutput(plot_id, height = "600px")
      )
    })

    do.call(tabsetPanel, c(list(id = "scores_participants_tabs"), tab_panels))
  })

  # --- Módulo de Generación de informes ---

  output$report_n_selector <- renderUI({
    req(pt_prep_data())
    choices <- pt_prep_data() %>%
      pull(n_lab) %>%
      unique() %>%
      sort()
    if (length(choices) == 0) {
      return(helpText("No hay esquemas PT disponibles."))
    }
    selectInput("report_n_lab", "Seleccionar esquema PT (por n):", choices = choices)
  })

  output$report_level_selector <- renderUI({
    req(pt_prep_data(), input$report_n_lab)
    pt_levels <- pt_prep_data() %>%
      filter(n_lab == input$report_n_lab) %>%
      pull(level) %>%
      unique()
    hom_levels <- hom_data_full() %>%
      pull(level) %>%
      unique()
    stab_levels <- stab_data_full() %>%
      pull(level) %>%
      unique()
    common_levels <- sort(Reduce(intersect, list(pt_levels, hom_levels, stab_levels)))
    if (length(common_levels) == 0) {
      return(helpText("No hay niveles comunes entre los datos disponibles."))
    }
    selectInput("report_level", "Seleccionar nivel:", choices = common_levels)
  })

  # Reactivo para datos de instrumentación de participantes
  participants_instrumentation <- reactive({
    req(input$participants_data_upload)
    tryCatch(
      {
        df <- read.csv(input$participants_data_upload$datapath, stringsAsFactors = FALSE)
        # Validate required columns
        required_cols <- c("Codigo_Lab", "Analizador_SO2", "Analizador_CO", "Analizador_O3", "Analizador_NO_NO2")
        if (!all(required_cols %in% names(df))) {
          return(NULL)
        }
        df
      },
      error = function(e) {
        NULL
      }
    )
  })

  # Reactivo para Resumen de Grubbs
  grubbs_summary <- reactive({
    req(pt_prep_data())
    data <- pt_prep_data()

    if (nrow(data) == 0) {
      return(NULL)
    }

    # Obtener todas las combinaciones
    combos <- data %>%
      distinct(pollutant, n_lab, level)

    results_list <- list()

    for (i in 1:nrow(combos)) {
      pol <- combos$pollutant[i]
      n <- combos$n_lab[i]
      lev <- combos$level[i]

      subset_data <- data %>%
        filter(pollutant == pol, n_lab == n, level == lev, participant_id != "ref")

      n_eval <- nrow(subset_data)
      p_val <- NA
      outliers_detected <- 0
      outlier_participant <- "NA"
      outlier_value <- "NA"

      if (n_eval >= 3) {
        tryCatch(
          {
            test_res <- outliers::grubbs.test(subset_data$mean_value)
            p_val <- test_res$p.value

            if (p_val < 0.05) {
              outliers_detected <- 1
              # Identificar el valor atípico
               # grubbs.test devuelve el valor en la cadena de hipótesis alternativa usualmente,
               # pero podemos encontrarlo verificando qué valor maximiza la desviación
               # Por simplicidad, podemos verificar mínimo y máximo
              vals <- subset_data$mean_value
              mean_val <- mean(vals)
              sd_val <- sd(vals)
              z_vals <- abs(vals - mean_val) / sd_val
              idx_max <- which.max(z_vals)
              outlier_val_num <- vals[idx_max]
              outlier_participant <- subset_data$participant_id[idx_max]
              outlier_value <- as.character(round(outlier_val_num, 3))
            }
          },
          error = function(e) {
            # Manejar error
          }
        )
      }

      results_list[[i]] <- data.frame(
        Contaminante = pol,
        Nivel = lev,
        Participantes_Evaluados = n_eval,
        Valor_p = ifelse(is.na(p_val), "NA", sprintf("%.4f", p_val)),
        Atipicos_detectados = outliers_detected,
        Participante = outlier_participant,
        Valor_Atipico = outlier_value,
        stringsAsFactors = FALSE
      )
    }

    do.call(rbind, results_list)
  })

  # Reactivo para Resumen Xpt del Informe (Anexo A)
  report_xpt_summary <- reactive({
    req(pt_prep_data(), input$report_method)
    data <- pt_prep_data()
    method <- input$report_method

    if (nrow(data) == 0) {
      return(NULL)
    }

    # Nota: calculate_niqr ahora se obtiene de R/pt_robust_stats.R

    # Obtener todas las combinaciones
    combos <- data %>%
      distinct(pollutant, n_lab, level)

    results_list <- list()

    for (i in 1:nrow(combos)) {
      pol <- combos$pollutant[i]
      n <- combos$n_lab[i]
      lev <- combos$level[i]

      subset_data <- data %>%
        filter(pollutant == pol, n_lab == n, level == lev)

      ref_data <- subset_data %>% filter(participant_id == "ref")
      part_data <- subset_data %>% filter(participant_id != "ref")

      xpt <- NA
      u_xpt <- NA
      sigma_pt <- NA
      source_method <- "Desconocido"

      if (method == "1") { # Referencia
        if (nrow(ref_data) > 0) {
          xpt <- mean(ref_data$mean_value, na.rm = TRUE)
          u_xpt <- mean(ref_data$sd_value, na.rm = TRUE)
          sigma_pt <- mean(ref_data$sd_value, na.rm = TRUE)
          source_method <- "Referencia"
        }
      } else if (method == "2a") { # Consenso MADe
        vals <- part_data$mean_value
        if (length(vals) > 0) {
          xpt <- median(vals, na.rm = TRUE)
          made <- 1.483 * median(abs(vals - xpt), na.rm = TRUE)
          u_xpt <- 1.25 * made / sqrt(length(vals))
          sigma_pt <- made
          source_method <- "Consenso MADe"
        }
      } else if (method == "2b") { # Consenso nIQR
        vals <- part_data$mean_value
        if (length(vals) > 0) {
          xpt <- median(vals, na.rm = TRUE)
          niqr <- calculate_niqr(vals)
          u_xpt <- 1.25 * niqr / sqrt(length(vals))
          sigma_pt <- niqr
          source_method <- "Consenso nIQR"
        }
      } else if (method == "3") { # Algoritmo A
        vals <- part_data$mean_value
        ids <- part_data$participant_id
        if (length(vals) >= 3) {
          # Podemos usar la función run_algorithm_a existente en app.R si es accesible,
          # o la definida dentro del ámbito de este reactivo si la copiamos.
          # Como run_algorithm_a está definida en el ámbito global de server o ui?
          # Parece estar en el ámbito de server. Intentemos usarla.
          # Nota: run_algorithm_a en app.R toma (values, ids).
          res_algo <- run_algorithm_a(vals, ids)
          if (is.null(res_algo$error)) {
            xpt <- res_algo$assigned_value
            sigma_pt <- res_algo$robust_sd
            u_xpt <- 1.25 * sigma_pt / sqrt(length(vals))
            source_method <- "Algoritmo A"
          }
        }
      }

      results_list[[i]] <- data.frame(
        Contaminante = pol,
        Nivel = lev,
        Metodo = source_method,
        x_pt = ifelse(is.na(xpt), NA, xpt),
        u_xpt = ifelse(is.na(u_xpt), NA, u_xpt),
        sigma_pt = ifelse(is.na(sigma_pt), NA, sigma_pt),
        stringsAsFactors = FALSE
      )
    }

    do.call(rbind, results_list)
  })

  # Reactivo para Resumen de Homogeneidad (Anexo B)
  report_homogeneity_summary <- reactive({
    req(hom_data_full())
    data <- pt_prep_data()

    if (nrow(data) == 0) {
      return(NULL)
    }

    # Obtener todas las combinaciones
    combos <- data %>%
      distinct(pollutant, level)

    hom_records <- list()

    for (i in 1:nrow(combos)) {
      pol <- combos$pollutant[i]
      lev <- combos$level[i]

      hom_res <- tryCatch(
        {
          compute_homogeneity_metrics(pol, lev)
        },
        error = function(e) {
          list(error = conditionMessage(e))
        }
      )

      if (!is.null(hom_res$error)) next

      hom_records[[i]] <- data.frame(
        Contaminante = pol,
        Nivel = lev,
        Items = hom_res$g,
        Replicas = hom_res$m,
        sigma_pt = round(hom_res$sigma_pt, 4),
        u_xpt = round(hom_res$u_xpt, 4),
        ss = round(hom_res$ss, 4),
        sw = round(hom_res$sw, 4),
        c_criterio = round(hom_res$c_criterion, 4),
        Cumple_Criterio = ifelse(hom_res$ss <= hom_res$c_criterion, "Sí", "No"),
        Conclusion = hom_res$conclusion,
        stringsAsFactors = FALSE
      )
    }

    if (length(hom_records) > 0) {
      do.call(rbind, hom_records)
    } else {
      NULL
    }
  })

  # Reactivo para Resumen de Estabilidad (Anexo B)
  report_stability_summary <- reactive({
    req(hom_data_full(), stab_data_full())
    data <- pt_prep_data()

    if (nrow(data) == 0) {
      return(NULL)
    }

    # Obtener todas las combinaciones
    combos <- data %>%
      distinct(pollutant, level)

    stab_records <- list()

    for (i in 1:nrow(combos)) {
      pol <- combos$pollutant[i]
      lev <- combos$level[i]

      # Primero obtener resultados de homogeneidad
      hom_res <- tryCatch(
        {
          compute_homogeneity_metrics(pol, lev)
        },
        error = function(e) {
          list(error = conditionMessage(e))
        }
      )

      if (!is.null(hom_res$error)) next

      # Luego obtener resultados de estabilidad
      stab_res <- tryCatch(
        {
          compute_stability_metrics(pol, lev, hom_res)
        },
        error = function(e) {
          list(error = conditionMessage(e))
        }
      )

      if (!is.null(stab_res$error)) next

      stab_records[[i]] <- data.frame(
        Contaminante = pol,
        Nivel = lev,
        Itms = stab_res$g,
        Replicas = stab_res$m,
        sigma_pt = round(stab_res$stab_sigma_pt, 4),
        u_xpt = round(stab_res$stab_u_xpt, 4),
        diff_hom_stab = round(stab_res$diff_hom_stab, 4),
        c_criterio = round(stab_res$stab_c_criterion, 4),
        Cumple_Criterio = ifelse(stab_res$diff_hom_stab <= stab_res$stab_c_criterion, "Sí", "No"),
        Conclusion = stab_res$stab_conclusion,
        stringsAsFactors = FALSE
      )
    }

    if (length(stab_records) > 0) {
      do.call(rbind, stab_records)
    } else {
      NULL
    }
  })

  # --- Funciones auxiliares para Resúmenes de Puntajes del Informe ---

  calculate_method_scores_df <- function(method_code) {
    data <- pt_prep_data()
    if (nrow(data) == 0) {
      return(NULL)
    }

    combos <- data %>% distinct(pollutant, level)
    all_scores <- list()

    for (i in 1:nrow(combos)) {
      pol <- combos$pollutant[i]
      lev <- combos$level[i]

      subset_data <- data %>% filter(pollutant == pol, level == lev)
      ref_data <- subset_data %>% filter(participant_id == "ref")
      part_data <- subset_data %>% filter(participant_id != "ref")

      # Calcular Valor Asignado
      assigned <- list(xpt = NA, u_xpt = NA, sigma = NA)

      if (method_code == "1") {
        assigned <- list(
          xpt = mean(ref_data$mean_value, na.rm = TRUE),
          u_xpt = mean(ref_data$sd_value, na.rm = TRUE),
          sigma = mean(ref_data$sd_value, na.rm = TRUE)
        )
      } else if (method_code == "2a") {
        vals <- part_data$mean_value
        med <- median(vals, na.rm = TRUE)
        made <- 1.483 * median(abs(vals - med), na.rm = TRUE)
        assigned <- list(xpt = med, u_xpt = 1.25 * made / sqrt(length(vals)), sigma = made)
      } else if (method_code == "2b") {
        vals <- part_data$mean_value
        med <- median(vals, na.rm = TRUE)
        niqr <- calculate_niqr(vals)
        assigned <- list(xpt = med, u_xpt = 1.25 * niqr / sqrt(length(vals)), sigma = niqr)
      } else if (method_code == "3") {
        res <- run_algorithm_a(part_data$mean_value, part_data$participant_id)
        assigned <- list(xpt = res$assigned_value, u_xpt = 1.25 * res$robust_sd / sqrt(nrow(part_data)), sigma = res$robust_sd)
      }

      # Determinar Sigma
      hom_res <- tryCatch(compute_homogeneity_metrics(pol, lev), error = function(e) NULL)
      final_sigma <- if (!is.na(assigned$sigma) && !is.null(assigned$sigma)) assigned$sigma else if (!is.null(hom_res)) hom_res$sigma_pt else NA

      if (is.na(final_sigma)) next

      # Calcular Puntajes
      # z = (x - Xpt) / sigma_pt
      # z' = (x - Xpt) / sqrt(sigma_pt^2 + u_Xpt^2)
      # zeta = (x - Xpt) / sqrt(u_xi^2 + u_Xpt^2)
      # En = (x - Xpt) / sqrt(U_xi^2 + U_Xpt^2)

      k <- input$report_k

      scores <- part_data %>%
        mutate(
          x_pt = assigned$xpt,
          u_xpt = assigned$u_xpt,
          sigma_pt = final_sigma,
          z_score = (mean_value - assigned$xpt) / final_sigma,
          z_prime_score = (mean_value - assigned$xpt) / sqrt(final_sigma^2 + assigned$u_xpt^2),
          zeta_score = (mean_value - assigned$xpt) / sqrt(sd_value^2 + assigned$u_xpt^2),
          En_score = (mean_value - assigned$xpt) / sqrt((k * sd_value)^2 + (k * assigned$u_xpt)^2)
        ) %>%
        select(participant_id, pollutant, level, mean_value, sd_value, x_pt, u_xpt, sigma_pt, z_score, z_prime_score, zeta_score, En_score)

      all_scores[[i]] <- scores
    }

    if (length(all_scores) > 0) do.call(rbind, all_scores) else NULL
  }

  summarize_scores <- function(df) {
    if (is.null(df)) {
      return(NULL)
    }

    # Definir categorías
    df <- df %>%
      mutate(
        z_eval = case_when(
          abs(z_score) <= 2 ~ "Satisfactorio",
          abs(z_score) < 3 ~ "Cuestionable",
          TRUE ~ "Insatisfactorio"
        ),
        z_prime_eval = case_when(
          abs(z_prime_score) <= 2 ~ "Satisfactorio",
          abs(z_prime_score) < 3 ~ "Cuestionable",
          TRUE ~ "Insatisfactorio"
        ),
        zeta_eval = case_when(
          abs(zeta_score) <= 2 ~ "Satisfactorio",
          abs(zeta_score) < 3 ~ "Cuestionable",
          TRUE ~ "Insatisfactorio"
        ),
        En_eval = case_when(
          abs(En_score) <= 1 ~ "Satisfactorio",
          TRUE ~ "Insatisfactorio"
        )
      )

    # Crear estructura de tabla resumen
    pollutants <- unique(df$pollutant)

    # Función auxiliar para contar
    count_eval <- function(eval_col, eval_type) {
      counts <- sapply(pollutants, function(p) {
        sum(df$pollutant == p & df[[eval_col]] == eval_type, na.rm = TRUE)
      })
      c(counts, sum(counts))
    }

    # Construir filas
    z_sat <- c("z-score", "Satisfactorio", count_eval("z_eval", "Satisfactorio"))
    z_quest <- c("z-score", "Cuestionable", count_eval("z_eval", "Cuestionable"))
    z_unsat <- c("z-score", "Insatisfactorio", count_eval("z_eval", "Insatisfactorio"))

    zp_sat <- c("z'-score", "Satisfactorio", count_eval("z_prime_eval", "Satisfactorio"))
    zp_quest <- c("z'-score", "Cuestionable", count_eval("z_prime_eval", "Cuestionable"))
    zp_unsat <- c("z'-score", "Insatisfactorio", count_eval("z_prime_eval", "Insatisfactorio"))

    zeta_sat <- c("zeta-score", "Satisfactorio", count_eval("zeta_eval", "Satisfactorio"))
    zeta_quest <- c("zeta-score", "Cuestionable", count_eval("zeta_eval", "Cuestionable"))
    zeta_unsat <- c("zeta-score", "Insatisfactorio", count_eval("zeta_eval", "Insatisfactorio"))

    en_sat <- c("En-score", "Satisfactorio", count_eval("En_eval", "Satisfactorio"))
    en_unsat <- c("En-score", "Insatisfactorio", count_eval("En_eval", "Insatisfactorio"))

    # Combinar
    summary_df <- rbind(z_sat, z_quest, z_unsat, zp_sat, zp_quest, zp_unsat, zeta_sat, zeta_quest, zeta_unsat, en_sat, en_unsat)
    colnames(summary_df) <- c("Indicador", "Evaluación", pollutants, "TOTAL")

    # Agregar columna de Porcentaje
    total_results <- nrow(df)

    summary_df <- as.data.frame(summary_df, stringsAsFactors = FALSE)

    # Convertir conteos a numérico para cálculo de porcentaje
    summary_df$TOTAL <- as.numeric(summary_df$TOTAL)

    summary_df$Percentage <- sprintf("%.2f%%", (summary_df$TOTAL / total_results) * 100)
    colnames(summary_df)[ncol(summary_df)] <- "TOTAL (%)"

    summary_df
  }

  # Reactivos
  score_criteria_summary_1 <- reactive({
    summarize_scores(calculate_method_scores_df("1"))
  })
  score_criteria_summary_2a <- reactive({
    summarize_scores(calculate_method_scores_df("2a"))
  })
  score_criteria_summary_2b <- reactive({
    summarize_scores(calculate_method_scores_df("2b"))
  })
  score_criteria_summary_3 <- reactive({
    summarize_scores(calculate_method_scores_df("3"))
  })

  report_score_summary <- reactive({
    res <- switch(input$report_method,
      "1" = score_criteria_summary_1(),
      "2a" = score_criteria_summary_2a(),
      "2b" = score_criteria_summary_2b(),
      "3" = score_criteria_summary_3()
    )

    if (is.null(res)) {
      return(NULL)
    }

    target_metric <- switch(input$report_metric,
      "z" = "z-score",
      "z'" = "z'-score",
      "zeta" = "zeta-score",
      "En" = "En-score"
    )

    res %>% filter(Indicador == target_metric)
  })

  report_heatmaps <- reactive({
    data <- pt_prep_data()
    if (nrow(data) == 0) {
      return(NULL)
    }

    scores_df <- calculate_method_scores_df(input$report_method)
    if (is.null(scores_df)) {
      return(NULL)
    }

    pollutants <- unique(scores_df$pollutant)
    plot_list <- list()

    for (pol in pollutants) {
      pol_data <- scores_df %>% filter(pollutant == pol)

      metric <- input$report_metric

      if (metric == "En") {
        pol_data$score_val <- pol_data$En_score
        pol_data$eval <- case_when(
          abs(pol_data$En_score) <= 1 ~ "Satisfactorio",
          TRUE ~ "Insatisfactorio"
        )
      } else {
        # Select score based on metric
        pol_data$score_val <- switch(metric,
          "z" = pol_data$z_score,
          "z'" = pol_data$z_prime_score,
          "zeta" = pol_data$zeta_score
        )

        pol_data$eval <- case_when(
          abs(pol_data$score_val) <= 2 ~ "Satisfactorio",
          abs(pol_data$score_val) < 3 ~ "Cuestionable",
          TRUE ~ "Insatisfactorio"
        )
      }

      p <- ggplot(pol_data, aes(x = level, y = participant_id, fill = eval)) +
        geom_tile(color = "white") +
        geom_text(aes(label = round(score_val, 2)), color = "white", size = 3) +
        scale_fill_manual(values = c("Satisfactorio" = "#2E7D32", "Cuestionable" = "#F9A825", "Insatisfactorio" = "#C62828")) +
        labs(title = paste("Mapa de Calor -", toupper(pol)), x = "Nivel", y = "Participante", fill = "Evaluación") +
        theme_minimal()

      plot_list[[pol]] <- p
    }
    plot_list
    plot_list
  })

  report_participant_data <- reactive({
    data <- pt_prep_data()
    if (nrow(data) == 0) {
      return(NULL)
    }

    scores_df <- calculate_method_scores_df(input$report_method)
    if (is.null(scores_df)) {
      return(NULL)
    }

    # Función auxiliar para crear gráfico combinado
    create_combo_plot <- function(df, score_col, title_suffix, limit_lines = c(2, 3), limit_colors = c("orange", "red"), show_legend = TRUE) {
      # Asegurar ordenamiento de niveles
      df <- df %>%
        mutate(level_numeric = readr::parse_number(as.character(level))) %>%
        arrange(level_numeric, level) %>%
        mutate(level_factor = factor(level, levels = unique(level)))

      # Gráfico Superior: Ref vs Participante
      p_val <- ggplot(df, aes(x = level_factor)) +
        geom_point(aes(y = mean_value, color = "Participante"), size = 2) +
        geom_line(aes(y = mean_value, group = 1, color = "Participante")) +
        geom_point(aes(y = x_pt, color = "Referencia"), size = 2) +
        geom_line(aes(y = x_pt, group = 1, color = "Referencia"), linetype = "dashed") +
        scale_color_manual(values = c("Participante" = "blue", "Referencia" = "red")) +
        labs(title = paste("Valores -", title_suffix), x = "Nivel", y = "Valor", color = NULL) +
        theme_minimal()

      # Gráfico Inferior: Puntaje
      p_score <- ggplot(df, aes(x = level_factor, y = .data[[score_col]], group = 1)) +
        geom_hline(yintercept = 0, color = "grey") +
        geom_line(color = "black") +
        geom_point(color = "black", size = 2) +
        labs(title = paste("Score -", title_suffix), x = "Nivel", y = "Score") +
        theme_minimal()

      if (!is.null(limit_lines)) {
        p_score <- p_score +
          geom_hline(yintercept = c(-limit_lines[1], limit_lines[1]), linetype = "dashed", color = limit_colors[1]) +
          geom_hline(yintercept = c(-limit_lines[2], limit_lines[2]), linetype = "dashed", color = limit_colors[2])
      }

      # Combinar gráficos en dos columnas (Valores | Score)
      (p_val | p_score) +
        plot_layout(guides = "collect", widths = c(1, 1)) &
        theme(
          legend.position = if (show_legend) "bottom" else "none",
          legend.margin = margin(t = 0, b = 0),
          legend.box.spacing = unit(0.2, "cm"),
          axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
          plot.margin = margin(t = 2, r = 5, b = 5, l = 5),
          strip.background = element_blank()
        )
    }

    # Obtener todos los participantes (excluyendo ref)
    participants <- unique(scores_df$participant_id)
    participants <- participants[participants != "ref"]

    part_list <- list()

    for (pid in participants) {
      p_data <- scores_df %>% filter(participant_id == pid)

      # 1. Tabla Resumen (Reconstruir)
      table_rows <- list()
      for (i in 1:nrow(p_data)) {
        pol <- p_data$pollutant[i]
        lev <- p_data$level[i]

        # Determinar evaluación basada en la métrica seleccionada para la tabla
        # Determinar evaluación basada en la métrica seleccionada para la tabla
        metric <- input$report_metric
        score_val <- switch(metric,
          "z" = p_data$z_score[i],
          "z'" = p_data$z_prime_score[i],
          "zeta" = p_data$zeta_score[i],
          "En" = p_data$En_score[i]
        )

        eval_val <- if (metric == "En") {
          case_when(abs(score_val) <= 1 ~ "Satisfactorio", TRUE ~ "Insatisfactorio")
        } else {
          case_when(abs(score_val) <= 2 ~ "Satisfactorio", abs(score_val) < 3 ~ "Cuestionable", TRUE ~ "Insatisfactorio")
        }

        table_rows[[i]] <- data.frame(
          Contaminante = pol,
          Nivel = lev,
          Resultado = p_data$mean_value[i],
          Incertidumbre = p_data$sd_value[i],
          Valor_Asignado = p_data$x_pt[i],
          Incertidumbre_VA = p_data$u_xpt[i],
          Score = score_val,
          Evaluacion = eval_val,
          stringsAsFactors = FALSE
        )
      }
      summary_table <- do.call(rbind, table_rows)

      # 2. Gráfico Combinado (Métrica única)
      # El usuario solicitó: "solo incluir ref vs participante Y el puntaje seleccionado"

      pollutants <- unique(p_data$pollutant)
      combined_plots_list <- list()

      metric <- input$report_metric
      score_col <- switch(metric,
        "z" = "z_score",
        "z'" = "z_prime_score",
        "zeta" = "zeta_score",
        "En" = "En_score"
      )

      limit_lines <- if (metric == "En") c(1, 1) else c(2, 3)
      limit_colors <- if (metric == "En") c("red", "red") else c("orange", "red")

      for (i in seq_along(pollutants)) {
        pol <- pollutants[i]
        pol_data <- p_data %>% filter(pollutant == pol)
        is_last <- i == length(pollutants)

        # Crear gráfico combinado único para la métrica seleccionada
        p_combo <- create_combo_plot(
          pol_data,
          score_col,
          paste(metric, "-score", toupper(pol)),
          limit_lines = limit_lines,
          limit_colors = limit_colors,
          show_legend = is_last
        )

        # Agregar título para el panel individual del contaminante si es necesario, o confiar en las etiquetas de los ejes
        # La imagen del usuario muestra títulos como "CO - Values" y "CO - Z-Score" dentro de los gráficos.
        # create_combo_plot ya agrega títulos.

        combined_plots_list[[pol]] <- p_combo
      }

      # Combinar gráficos verticalmente (un contaminante por fila)
      # Usar patchwork para organizarlos en 1 columna
      final_plot <- wrap_plots(combined_plots_list, ncol = 1) +
        plot_annotation(
          title = paste("Performance Summary (Pollutants by Row) - Participant:", pid),
          theme = theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))
        )

      part_list[[pid]] <- list(
        summary_table = summary_table,
        matrix_plot = final_plot
      )
    }
    part_list
  })
  report_preview <- reactive({
    req(
      input$report_n_lab, input$report_level,
      input$report_method, input$report_k
    )
    summary_df <- pt_prep_data()
    if (is.null(summary_df)) {
      return(list(error = "No se encontraron datos resumidos de PT (summary_n*.csv)."))
    }

    # Para vista previa, solo verificamos el primer contaminante
    first_pollutant <- unique(hom_data_full()$pollutant)[1]

    hom_res <- compute_homogeneity_metrics(first_pollutant, input$report_level)
    # El error de homogeneidad no es fatal para la vista previa, pero lo necesitamos para estabilidad

    stab_res <- if (!is.null(hom_res$error)) {
      list(error = "No se pudo calcular estabilidad debido a error en homogeneidad.")
    } else {
      compute_stability_metrics(first_pollutant, input$report_level, hom_res)
    }

    # Calcular valor asignado e incertidumbre basado en el método
    target_data <- summary_df %>%
      filter(
        n_lab == input$report_n_lab,
        level == input$report_level
      )

    if (nrow(target_data) == 0) {
      return(list(error = "No hay datos para la combinación seleccionada."))
    }

    ref_data <- target_data %>% filter(participant_id == "ref")
    part_data <- target_data %>% filter(participant_id != "ref")

    x_pt <- NA_real_
    u_xpt <- NA_real_
    sigma_pt <- NA_real_ # Este será el sigma usado para puntuación

    method <- input$report_method

    if (method == "1") { # Referencia
      if (nrow(ref_data) > 0) {
        x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
        u_xpt <- mean(ref_data$sd_value, na.rm = TRUE) # Asumiendo que sd_value es la incertidumbre para ref
        # Para sigma_pt en método 1, usualmente usar hom_res$sigma_pt o un valor fijo.
        # Aquí por defecto usamos hom_res$sigma_pt si está disponible, sino 0.
        sigma_pt <- if (!is.null(hom_res$sigma_pt)) hom_res$sigma_pt else 0
      } else {
        return(list(error = "No hay datos de referencia para el método seleccionado."))
      }
    } else if (method == "2a") { # Consenso MADe
      vals <- part_data$mean_value
      x_pt <- median(vals, na.rm = TRUE)
      made <- 1.483 * median(abs(vals - x_pt), na.rm = TRUE)
      u_xpt <- 1.25 * made / sqrt(length(vals))
      sigma_pt <- made
    } else if (method == "2b") { # Consenso nIQR
      vals <- part_data$mean_value
      x_pt <- median(vals, na.rm = TRUE)
      niqr_val <- calculate_niqr(vals)
      u_xpt <- 1.25 * niqr_val / sqrt(length(vals))
      sigma_pt <- niqr_val
    } else if (method == "3") { # Algoritmo A
      # Necesitamos ejecutar Algo A aquí o traerlo del caché.
      # Para simplicidad de vista previa, ejecutémoslo al vuelo si los datos son pequeños
      vals <- part_data$mean_value
      ids <- part_data$participant_id
      algo_res <- run_algorithm_a(vals, ids)
      if (!is.null(algo_res$error)) {
        return(list(error = paste("Error en Algoritmo A:", algo_res$error)))
      }
      x_pt <- algo_res$assigned_value
      sigma_pt <- algo_res$robust_sd
      u_xpt <- 1.25 * sigma_pt / sqrt(length(vals))
    }

    scores_res <- compute_scores_metrics(
      summary_df = summary_df,
      target_pollutant = first_pollutant,
      target_n_lab = input$report_n_lab,
      target_level = input$report_level,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      k = input$report_k,
      m = if (!is.null(hom_res$m)) hom_res$m else NULL
    )

    if (!is.null(scores_res$error)) {
      return(list(error = scores_res$error))
    }

    list(
      error = NULL,
      hom = hom_res,
      stab = stab_res,
      scores = scores_res
    )
  })

  output$report_status <- renderUI({
    preview <- report_preview()
    if (is.null(preview$error)) {
      div(class = "alert alert-info", "Datos listos para generar el informe.")
    } else {
      div(class = "alert alert-warning", preview$error)
    }
  })

  output$report_preview_summary <- renderPrint({
    preview <- report_preview()
    if (!is.null(preview$error)) {
      cat(preview$error)
      return()
    }
    hom <- preview$hom
    stab <- preview$stab
    scores <- preview$scores

    cat(sprintf("Analito: %s\n", toupper(hom$pollutant)))
    cat(sprintf("Nivel: %s\n", hom$level))
    cat(sprintf("Esquema PT (n): %s\n", scores$n_lab))
    cat("\n--- Homogeneidad ---\n")
    cat(sprintf("Conclusión: %s\n", gsub("<br>", " | ", hom$conclusion)))
    cat(sprintf("ss = %.4f | c = %.4f | c_exp = %.4f\n", hom$ss, hom$c_criterion, hom$c_criterion_expanded))
    cat(sprintf("MADe = %.4f | nIQR = %.4f\n", hom$sigma_pt, hom$n_iqr))
    cat("\n--- Estabilidad ---\n")
    cat(sprintf("Conclusión: %s\n", stab$stab_conclusion))
    cat(sprintf("|y1 - y2| = %.4f | c = %.4f\n", stab$diff_hom_stab, stab$stab_c_criterion))
    cat("\n--- Puntajes PT ---\n")
    cat(sprintf(
      "x_pt = %.4f | sigma_pt = %.4f | u_xpt = %.4f | k = %s\n",
      scores$x_pt, scores$sigma_pt, scores$u_xpt, scores$k
    ))
    cat(sprintf("Participantes evaluados: %d\n", nrow(scores$scores)))
  })

  # --- Report Preview Logic ---
  preview_file_path <- reactiveVal(NULL)
  preview_loading_state <- reactiveVal(FALSE)

  observeEvent(input$generate_preview, {
    preview_loading_state(TRUE)
    preview_file_path(NULL)
    
    
    tryCatch({
      if (!requireNamespace("rmarkdown", quietly = TRUE)) {
        showNotification("El paquete 'rmarkdown' es requerido.", type = "error")
        preview_loading_state(FALSE)
        return()
      }
      
      template_path <- file.path("reports", "report_template.Rmd")
      if (!file.exists(template_path)) {
        showNotification("No se encontró la plantilla del informe.", type = "error")
        preview_loading_state(FALSE)
        return()
      }
      
      # Create output directory in www for serving - use absolute path
      app_dir <- getwd()
      preview_dir <- file.path(app_dir, "www", "preview")
      if (!dir.exists(preview_dir)) {
        dir.create(preview_dir, recursive = TRUE, showWarnings = FALSE)
      }
      
      # Generate unique filename based on HTML preview
      file_ext <- "html"
      preview_filename <- paste0("preview_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".", file_ext)
      preview_file_abs <- file.path(preview_dir, preview_filename)
      
      temp_dir <- tempdir()
      temp_report <- file.path(temp_dir, "report_template.Rmd")
      file.copy(template_path, temp_report, overwrite = TRUE)
      
      params <- list(
        hom_data = hom_data_full(),
        stab_data = stab_data_full(),
        summary_data = pt_prep_data(),
        metric = input$report_metric,
        method = input$report_method,
        pollutant = NULL,
        level = input$report_level,
        n_lab = input$report_n_lab,
        k_factor = input$report_k,
        scheme_id = input$report_scheme_id,
        report_id = input$report_id,
        issue_date = input$report_date,
        period = input$report_period,
        coordinator = input$report_coordinator,
        quality_pro = input$report_quality_pro,
        ops_eng = input$report_ops_eng,
        quality_manager = input$report_quality_manager,
        participants_data = participants_instrumentation(),
        grubbs_summary = grubbs_summary(),
        xpt_summary = report_xpt_summary(),
        homogeneity_summary = report_homogeneity_summary(),
        stability_summary = report_stability_summary(),
        score_summary = report_score_summary(),
        heatmaps = report_heatmaps(),
        participant_data = report_participant_data(),
        metrological_compatibility = metrological_compatibility_data(),
        metrological_compatibility_method = input$report_metrological_compatibility,
        project_root = app_dir
      )
      
      # Select output format
      output_format <- "html_document"
      
      rmarkdown::render(
        temp_report,
        output_format = output_format,
        output_file = preview_file_abs,
        params = params,
        envir = new.env(parent = globalenv())
      )
      
      # Store relative path for browser
      preview_file_path(paste0("preview/", preview_filename))
      showNotification("Vista previa HTML generada correctamente.", type = "message")
      
    }, error = function(e) {
      error_msg <- e$message
      showNotification(paste("Error generando vista previa:", error_msg), type = "error", duration = 10)
    })
    
    preview_loading_state(FALSE)
  })

  output$preview_loading <- renderUI({
    if (preview_loading_state()) {
      format_text <- "HTML"
      div(class = "alert alert-info", style = "margin-top: 15px;",
        icon("spinner", class = "fa-spin"), paste0(" Generando vista previa ", format_text, "... Por favor espere.")
      )
    }
  })

  output$pdf_preview_container <- renderUI({
    file_path <- preview_file_path()
    if (is.null(file_path)) {
      return(div(class = "text-muted", style = "margin-top: 15px;", 
        "Haga clic en 'Generar Vista Previa' para ver el informe."
      ))
    }
    
    # Embed HTML preview using iframe
    div(class = "well", style = "margin-top: 15px; padding: 0; overflow: hidden; background: white; border: 2px solid #FDB913;",
      tags$iframe(
        src = file_path,
        style = "width: 100%; height: 800px; border: none; display: block;"
      ),
      p(class = "text-muted", style = "margin: 10px;",
        "Si el documento no se visualiza correctamente, ",
        tags$a(href = file_path, target = "_blank", "haga clic aquí para abrirlo en una nueva pestaña.")
      )
    )
  })

  output$download_report <- downloadHandler(
    filename = function() {
      ext <- "docx"

      # Construct filename with parameters: n_lab-metric-method-compatibility
      # Example: Informe_EA_2025-12-02_13-zeta-2a-2a
      fname <- paste0(
        "Informe_EA_", Sys.Date(), "_",
        input$report_n_lab, "-",
        input$report_metric, "-",
        input$report_method, "-",
        input$report_metrological_compatibility
      )

      paste0(fname, ".", ext)
    },
    content = function(file) {
      if (!requireNamespace("rmarkdown", quietly = TRUE)) {
        stop("El paquete 'rmarkdown' es requerido para generar el informe.")
      }

      # Usar la nueva plantilla
      template_path <- file.path("reports", "report_template.Rmd")
      if (!file.exists(template_path)) {
        stop("No se encontró la plantilla en 'reports/report_template.Rmd'.")
      }

      temp_dir <- tempdir()
      temp_report <- file.path(temp_dir, "report_template.Rmd")
      file.copy(template_path, temp_report, overwrite = TRUE)

      # Determine output format
      output_format <- "word_document"

      params <- list(
        hom_data = hom_data_full(),
        stab_data = stab_data_full(),
        summary_data = pt_prep_data(),
        metric = input$report_metric,
        method = input$report_method,
        pollutant = NULL, # NULL means process all pollutants
        level = input$report_level,
        n_lab = input$report_n_lab,
        k_factor = input$report_k,
        # Identification params
        scheme_id = input$report_scheme_id,
        report_id = input$report_id,
        issue_date = input$report_date,
        period = input$report_period,
        coordinator = input$report_coordinator,
        quality_pro = input$report_quality_pro,
        ops_eng = input$report_ops_eng,
        quality_manager = input$report_quality_manager,
        # Datos de instrumentaci\u00f3n de participantes
        participants_data = participants_instrumentation(),
        # Resumen de Grubbs
        grubbs_summary = grubbs_summary(),
        # Resumen Anexo A
        xpt_summary = report_xpt_summary(),
        # Resúmenes Anexo B
        homogeneity_summary = report_homogeneity_summary(),
        stability_summary = report_stability_summary(),
        # Datos Sección 4 y 5
        score_summary = report_score_summary(),
        heatmaps = report_heatmaps(),
        # Datos Anexo C
        participant_data = report_participant_data(),
        # Compatibilidad Metrológica
        metrological_compatibility = metrological_compatibility_data(),
        metrological_compatibility_method = input$report_metrological_compatibility
      )

      # Render directly to the Shiny download file path
      rmarkdown::render(
        temp_report,
        output_format = output_format,
        output_file = file,
        params = params,
        envir = new.env(parent = globalenv())
      )
    }
  )

  # --- Estado de Carga de datos ---
  output$data_upload_status <- renderPrint({
    cat("Estado de los archivos:\n")

    if (!is.null(input$hom_file)) {
      cat(sprintf("- Homogeneidad: '%s' cargado (%d filas).\n", input$hom_file$name, nrow(hom_data_full())))
    } else {
      cat("- Homogeneidad: No cargado.\n")
    }

    if (!is.null(input$stab_file)) {
      cat(sprintf("- Estabilidad: '%s' cargado (%d filas).\n", input$stab_file$name, nrow(stab_data_full())))
    } else {
      cat("- Estabilidad: No cargado.\n")
    }

    if (!is.null(input$summary_files)) {
      cat(sprintf("- Resumen: %d archivo(s) cargado(s) (%d filas en total).\n", nrow(input$summary_files), nrow(pt_prep_data())))
    } else {
      cat("- Resumen: No cargado.\n")
    }
  })

  # --- Módulo de Algoritmo A ---

  output$assigned_pollutant_selector <- renderUI({
    data <- pt_prep_data()
    if (is.null(data) || nrow(data) == 0) {
      return(helpText("Cargue los archivos summary_n*.csv para habilitar esta sección."))
    }
    choices <- sort(unique(data$pollutant))
    selectInput("assigned_pollutant", "Seleccionar analito:", choices = choices)
  })

  output$assigned_n_selector <- renderUI({
    data <- pt_prep_data()
    req(data, input$assigned_pollutant)
    subset <- data %>% filter(pollutant == input$assigned_pollutant)
    if (nrow(subset) == 0) {
      return(helpText("No hay esquemas PT disponibles para este analito."))
    }
    choices <- subset %>%
      pull(n_lab) %>%
      unique() %>%
      sort()
    selectInput("assigned_n_lab", "Seleccionar esquema PT (n):", choices = choices)
  })

  output$assigned_level_selector <- renderUI({
    data <- pt_prep_data()
    req(data, input$assigned_pollutant, input$assigned_n_lab)
    subset <- data %>%
      filter(
        pollutant == input$assigned_pollutant,
        n_lab == input$assigned_n_lab
      )
    if (nrow(subset) == 0) {
      return(helpText("No hay niveles disponibles para esta combinación."))
    }
    choices <- subset %>%
      pull(level) %>%
      unique() %>%
      sort()
    selectInput("assigned_level", "Seleccionar nivel:", choices = choices)
  })

  algo_key <- function(pollutant, n_lab, level) paste(pollutant, n_lab, level, sep = "||")

  # Nota: run_algorithm_a ahora se obtiene de R/pt_robust_stats.R

  algorithm_a_selected <- reactive({
    req(algoA_trigger())
    req(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    cache <- algoA_results_cache()
    if (is.null(cache)) {
      return(list(
        error = "No se generaron resultados. Verifique que existan datos cargados y ejecute nuevamente el Algoritmo A.",
        selected = list(
          pollutant = input$assigned_pollutant,
          n_lab = input$assigned_n_lab,
          level = input$assigned_level
        ),
        input_data = tibble(),
        iterations = tibble(),
        weights = tibble(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }

    key <- algo_key(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    res <- cache[[key]]

    if (is.null(res)) {
      return(list(
        error = "No se encontraron resultados para la combinación seleccionada. Ejecute nuevamente el Algoritmo A.",
        selected = list(
          pollutant = input$assigned_pollutant,
          n_lab = input$assigned_n_lab,
          level = input$assigned_level
        ),
        input_data = tibble(),
        iterations = tibble(),
        weights = tibble(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }

    res
  })

  output$algoA_result_summary <- renderUI({
    res <- algorithm_a_selected()
    req(res)

    if (!is.null(res$error)) {
      return(div(class = "alert alert-danger", res$error))
    }

    convergence_message <- if (isTRUE(res$converged)) {
      "El algoritmo convergió cuando los cambios en x* y s* fueron menores que 0.001 (sin variación en la tercera cifra decimal)."
    } else {
      "El algoritmo alcanzó el número máximo de iteraciones sin estabilizar la tercera cifra decimal de x* y s*."
    }

    assigned_value_fmt <- format(res$assigned_value, digits = 9, scientific = FALSE)
    robust_sd_fmt <- format(res$robust_sd, digits = 9, scientific = FALSE)
    effective_fmt <- format(res$effective_weight, digits = 9, scientific = FALSE)

    div(
      class = "alert alert-info",
      HTML(paste0(
        "<strong>Analito:</strong> ", toupper(res$selected$pollutant), "<br>",
        "<strong>Esquema (n):</strong> ", res$selected$n_lab, "<br>",
        "<strong>Nivel:</strong> ", res$selected$level, "<br>",
        "<strong>Valor asignado (x*):</strong> ", assigned_value_fmt, "<br>",
        "<strong>Desviación robusta (s*):</strong> ", robust_sd_fmt, "<br>",
        "<strong>Suma de pesos efectivos:</strong> ", effective_fmt, "<br>",
        "<em>", convergence_message, "</em>"
      ))
    )
  })

  output$algoA_input_table <- renderDataTable({
    res <- algorithm_a_selected()
    req(res)
    if (!is.null(res$error)) {
      return(datatable(data.frame(Mensaje = res$error)))
    }

    datatable(
      res$input_data %>% rename(Participante = participant_id),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = "Resultado", digits = 6)
  })

  output$algoA_histogram <- renderPlotly({
    res <- algorithm_a_selected()
    req(res)
    if (!is.null(res$error)) {
      return(NULL)
    }

    algo_plot <- ggplot(res$input_data, aes(x = Resultado)) +
      geom_histogram(aes(y = after_stat(density)), bins = 15, fill = "#5DADE2", color = "white", alpha = 0.8) +
      geom_density(color = "#1A5276", size = 1) +
      geom_vline(xintercept = res$assigned_value, color = "red", linetype = "dashed", size = 1) +
      labs(
        title = "Distribución de resultados por participante",
        subtitle = "La línea punteada indica el valor asignado robusto (x*)",
        x = "Resultado (media de cada participante)",
        y = "Densidad"
      ) +
      theme_minimal()
    plotly::ggplotly(algo_plot)
  })

  output$algoA_iterations_table <- renderDataTable({
    res <- algorithm_a_selected()
    req(res)
    if (!is.null(res$error)) {
      return(datatable(data.frame(Mensaje = res$error)))
    }

    if (nrow(res$iterations) == 0) {
      return(datatable(data.frame(Mensaje = "No se registraron iteraciones.")))
    }

    datatable(
      res$iterations,
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = c("x_star", "s_star", "delta"), digits = 9)
  })

  output$algoA_weights_table <- renderDataTable({
    res <- algorithm_a_selected()
    req(res)
    if (!is.null(res$error)) {
      return(datatable(data.frame(Mensaje = res$error)))
    }

    datatable(
      res$weights,
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = c("Resultado", "Peso", "Residuo estandarizado"), digits = 6)
  })

  # --- Módulo de Valor consenso ---

  observeEvent(input$consensus_run, {
    req(pt_prep_data())
    data <- isolate(pt_prep_data()) %>% filter(participant_id != "ref")

    combos <- data %>%
      distinct(pollutant, n_lab, level)

    if (nrow(combos) == 0) {
      consensus_results_cache(NULL)
      consensus_trigger(Sys.time())
      return()
    }

    results <- list()

    for (i in seq_len(nrow(combos))) {
      pollutant_val <- combos$pollutant[i]
      n_lab_val <- combos$n_lab[i]
      level_val <- combos$level[i]
      key <- algo_key(pollutant_val, n_lab_val, level_val)

      subset_data <- data %>%
        filter(
          pollutant == pollutant_val,
          n_lab == n_lab_val,
          level == level_val
        )

      aggregated <- subset_data %>%
        group_by(participant_id) %>%
        summarise(Resultado = mean(mean_value, na.rm = TRUE), .groups = "drop")

      if (nrow(aggregated) == 0) {
        results[[key]] <- list(
          error = "No se encontraron resultados de participantes para esta combinación.",
          summary = data.frame(),
          input_data = aggregated,
          selected = list(
            pollutant = pollutant_val,
            n_lab = n_lab_val,
            level = level_val
          )
        )
        next
      }

      values <- aggregated$Resultado
      x_pt2 <- median(values, na.rm = TRUE)
      mad_val <- median(abs(values - x_pt2), na.rm = TRUE)
      sigma_pt_2a <- 1.483 * mad_val
      sigma_pt_2b <- calculate_niqr(values)
      participants <- length(values)

      summary_df <- tibble::tibble(
        Estadístico = c("x_pt(2) - Mediana", "MADe", "sigma_pt_2a (MADe)", "sigma_pt_2b (nIQR)", "Participantes"),
        Valor = c(x_pt2, mad_val, sigma_pt_2a, sigma_pt_2b, participants)
      )

      results[[key]] <- list(
        error = NULL,
        summary = summary_df,
        input_data = aggregated,
        selected = list(
          pollutant = pollutant_val,
          n_lab = n_lab_val,
          level = level_val
        )
      )
    }

    consensus_results_cache(results)
    consensus_trigger(Sys.time())
  })

  consensus_selected <- reactive({
    if (is.null(consensus_trigger())) {
      return(list(
        error = "Ejecute el cálculo de valores consenso para ver resultados.",
        summary = data.frame(),
        input_data = tibble::tibble()
      ))
    }

    req(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    cache <- consensus_results_cache()
    if (is.null(cache)) {
      return(list(
        error = "No se generaron resultados. Verifique los datos cargados y ejecute nuevamente el cálculo de valores consenso.",
        summary = data.frame(),
        input_data = tibble::tibble()
      ))
    }

    key <- algo_key(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    res <- cache[[key]]

    if (is.null(res)) {
      return(list(
        error = "No se encontraron resultados para la selección actual. Ejecute nuevamente el cálculo de valores consenso.",
        summary = data.frame(),
        input_data = tibble::tibble()
      ))
    }

    res
  })

  output$consensus_summary_table <- renderTable(
    {
      res <- consensus_selected()
      if (!is.null(res$error)) {
        return(data.frame(Mensaje = res$error))
      }
      res$summary
    },
    digits = 6,
    striped = TRUE,
    spacing = "l",
    rownames = FALSE
  )

  output$consensus_input_table <- renderDataTable({
    res <- consensus_selected()
    if (!is.null(res$error)) {
      return(datatable(data.frame(Mensaje = res$error)))
    }

    datatable(
      res$input_data %>% rename(Participante = participant_id),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = "Resultado", digits = 6)
  })

  # --- Módulo de Valor de referencia ---

  reference_table_data <- reactive({
    req(pt_prep_data(), input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    pt_prep_data() %>%
      filter(
        participant_id == "ref",
        pollutant == input$assigned_pollutant,
        n_lab == input$assigned_n_lab,
        level == input$assigned_level
      )
  })

  output$reference_table <- renderDataTable({
    data <- reference_table_data()
    if (nrow(data) == 0) {
      return(datatable(data.frame(Mensaje = "No hay datos de referencia para la selección indicada.")))
    }

    display <- data %>%
      transmute(
        Analito = toupper(pollutant),
        `Esquema (n)` = n_lab,
        Nivel = level,
        `Valor medio` = mean_value,
        `Desviación estándar declarada` = sd_value
      )

    datatable(display, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE) %>%
      formatRound(columns = c("Valor medio", "Desviación estándar declarada"), digits = 6)
  })

  # --- Módulo de Preparación PT ---

  output$global_overview_algo <- renderDataTable({
    overview <- get_global_overview_data(global_combo_specs$algo)
    if (nrow(overview) == 0) {
      return(datatable(data.frame(Mensaje = "No hay datos disponibles para esta combinación.")))
    }
    datatable(
      overview,
      options = list(scrollX = TRUE, pageLength = 12),
      rownames = FALSE
    ) %>%
      formatRound(columns = c("Resultado", "u(xi)", "Puntaje z", "Puntaje z'", "Puntaje zeta", "Puntaje En"), digits = 3)
  })

  output$metrological_compatibility_table <- renderDataTable({
    data <- metrological_compatibility_data()
    if (nrow(data) == 0) {
      return(datatable(data.frame(Mensaje = "No hay datos suficientes para calcular la compatibilidad metrológica (se requiere Referencia y al menos un método de Consenso).")))
    }
    datatable(
      data,
      options = list(pageLength = 10, scrollX = TRUE),
      colnames = c("Contaminante", "N_Lab", "Nivel", "Valor Ref", "u_ref", "Valor 2a", "Dif 2a", "Crit 2a", "Eval 2a", "Valor 2b", "Dif 2b", "Crit 2b", "Eval 2b", "Valor 3", "Dif 3", "Crit 3", "Eval 3"),
      rownames = FALSE,
      caption = "Tabla. Compatibilidad Metrológica: Diferencias entre Valor de Referencia y Consenso"
    ) %>%
      formatRound(columns = c("x_pt_ref", "u_ref", "x_pt_2a", "Diff_Ref_2a", "Crit_Ref_2a", "x_pt_2b", "Diff_Ref_2b", "Crit_Ref_2b", "x_pt_3", "Diff_Ref_3", "Crit_Ref_3"), digits = 5)
  })

  output$grubbs_summary_table <- renderDataTable({
    req(grubbs_summary())
    datatable(
      grubbs_summary(),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    )
  })

  # --- Valores Atípicos: Selectores y Gráficos ---
  output$outliers_pollutant_selector <- renderUI({
    req(pt_prep_data())
    choices <- sort(unique(pt_prep_data()$pollutant))
    selectInput("outliers_pollutant", "Seleccionar contaminante:", choices = choices)
  })

  output$outliers_level_selector <- renderUI({
    req(pt_prep_data(), input$outliers_pollutant)
    filtered <- pt_prep_data() %>% filter(pollutant == input$outliers_pollutant)
    choices <- sort(unique(filtered$level))
    selectInput("outliers_level", "Seleccionar nivel:", choices = choices)
  })

  outliers_plot_data <- reactive({
    req(pt_prep_data(), input$outliers_pollutant, input$outliers_level)
    pt_prep_data() %>%
      filter(
        pollutant == input$outliers_pollutant,
        level == input$outliers_level,
        participant_id != "ref"
      )
  })

  output$outliers_histogram <- renderPlotly({
    req(outliers_plot_data())
    plot_data <- outliers_plot_data()
    
    if (nrow(plot_data) == 0) {
      return(NULL)
    }
    
    hist_plot <- ggplot(plot_data, aes(x = mean_value)) +
      geom_histogram(aes(y = after_stat(density)), color = "black", fill = "steelblue", bins = 15) +
      geom_density(alpha = 0.4, fill = "lightblue") +
      labs(
        title = paste("Histograma -", input$outliers_pollutant, "-", input$outliers_level),
        x = "Valor medio", y = "Densidad"
      ) +
      theme_minimal()
    
    plotly::ggplotly(hist_plot)
  })

  output$outliers_boxplot <- renderPlotly({
    req(outliers_plot_data())
    plot_data <- outliers_plot_data()
    
    if (nrow(plot_data) == 0) {
      return(NULL)
    }
    
    box_plot <- ggplot(plot_data, aes(x = level, y = mean_value)) +
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      geom_jitter(width = 0.1, alpha = 0.5, color = "darkblue") +
      labs(
        title = paste("Boxplot -", input$outliers_pollutant, "-", input$outliers_level),
        x = "Nivel", y = "Valor medio"
      ) +
      theme_minimal()
    
    plotly::ggplotly(box_plot)
  })
} # fin de la función servidor


# ===================================================================
# III. Ejecutar la Aplicación
# ===================================================================
shinyApp(ui = ui, server = server, options = list(launch.browser = FALSE))
