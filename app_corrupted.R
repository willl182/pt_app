# ===================================================================
# Shiny App for PT Data Analysis (Homogeneity and Stability)
#
# This app implements the procedures from test_homog.R and pt_analysis.R
# in an interactive web interface using Shiny.
#
# Based on the design from ui_test.md.
# ===================================================================

# 1. Load necessary libraries
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

# -------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA_real_)
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

`%||%` <- function(x, y) if (!is.null(x)) x else y

apply_axis_ranges <- function(plotly_obj, ranges) {
  if (is.null(plotly_obj) || is.null(ranges)) {
    return(plotly_obj)
  }

  apply_range <- function(axis_prefix, values) {
    if (is.null(values)) return()
    layout_names <- names(plotly_obj$x$layout)
    axis_names <- layout_names[grepl(paste0("^", axis_prefix), layout_names)]
    if (length(axis_names) == 0) {
      axis_names <- axis_prefix
    }
    for (axis_name in axis_names) {
      axis_conf <- plotly_obj$x$layout[[axis_name]] %||% list()
      axis_conf$range <- values
      plotly_obj$x$layout[[axis_name]] <- axis_conf
    }
  }

  apply_range("xaxis", ranges$x)
  apply_range("yaxis", ranges$y)

  plotly_obj
}

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(

  # 1. Application Title
  titlePanel("Aplicacion de Analisis PT"),
  h4("Laboratorio Calaire"),

  # Collapsible panel for layout options
  checkboxInput("show_layout_options", "Mostrar opciones de diseno", value = FALSE),
  conditionalPanel(
    condition = "input.show_layout_options == true",
    wellPanel(
      themeSelector(),
      hr(),
      sliderInput("nav_width", "Ancho del panel de navegacion:", min = 1, max = 5, value = 2, width = "250px"),
      sliderInput("analysis_sidebar_width", "Ancho de la barra lateral de analisis:", min = 2, max = 6, value = 3, width = "250px")
    )
  ),
  hr(),

  wellPanel(
    h4("Controles globales de ejes"),
    fluidRow(
      column(
        width = 6,
        numericInput("axis_x_min", "Limite inferior del eje X", value = NA),
        numericInput("axis_x_max", "Limite superior del eje X", value = NA)
      ),
      column(
        width = 6,
        numericInput("axis_y_min", "Limite inferior del eje Y", value = NA),
        numericInput("axis_y_max", "Limite superior del eje Y", value = NA)
      )
    ),
    helpText("Defina ambos limites para fijar el rango. Deje los campos en blanco para mantener el escalado automatico.")
  ),
  hr(),

  # Dynamic UI for the main layout
  uiOutput("main_layout"),

  hr(),
  p(em("Este aplicativo fue desarrollado en el marco del proyecto 'Implementacion de Ensayos de Aptitud en la Matriz Aire. Caso Gases Contaminantes Criterio', ejecutado por el Laboratorio CALAIRE de la Universidad Nacional de Colombia en alianza con el Instituto Nacional de Metrologia (INM)."), style="text-align:center; font-size:small;")
)

# ===================================================================
# II. Server Logic
# ===================================================================
server <- function(input, output, session) {

  # --- Data Loading and Processing ---
  # This section handles the initial loading of data from user-uploaded files.
  # These reactives are the foundation for all subsequent analyses.

  hom_data_full <- reactive({
    req(input$hom_file)
    vroom::vroom(input$hom_file$datapath, show_col_types = FALSE)
  })

  stab_data_full <- reactive({
    req(input$stab_file)
    vroom::vroom(input$stab_file$datapath, show_col_types = FALSE)
  })

  # PT Prep data
  pt_prep_data <- reactive({
    req(input$summary_files)

    data_list <- lapply(seq_len(nrow(input$summary_files)), function(i) {
      gl <- vroom::vroom(input$summary_files$datapath[i], show_col_types = FALSE)
      n <- as.integer(stringr::str_extract(input$summary_files$name[i], "\\d+"))
      gl$n_lab <- n
      return(gl)
    })

    if (length(data_list) == 0) return(NULL)

    raw_data <- do.call(rbind, data_list)
    if (is.null(raw_data) || nrow(raw_data) == 0) {
      return(NULL)
    }

    # Store raw data in a reactive value for use in sigma_pt_1 calculation
    rv$raw_summary_data <- raw_data

    # Also store the list of files for consensus calculations
    data_list <- lapply(seq_len(nrow(input$summary_files)), function(i) {
      vroom::vroom(input$summary_files$datapath[i], show_col_types = FALSE)
    })
    rv$raw_summary_data_list <- data_list

    # Aggregate the raw data to get a single mean value per participant/level
    raw_data %>%
      group_by(participant_id, pollutant, level, n_lab) %>%
      summarise(
        mean_value = mean(mean_value, na.rm = TRUE),
        sd_value = mean(sd_value, na.rm = TRUE),
        .groups = 'drop'
      )
  })

  # Reactive values to store raw data for specific calculations
  rv <- reactiveValues(raw_summary_data = NULL, raw_summary_data_list = NULL)

  format_num <- function(x) {
    ifelse(is.na(x), NA_character_, sprintf("%.5f", x))
  }

  get_axis_range <- function(min_val, max_val) {
    if (is.null(min_val) || is.null(max_val)) return(NULL)
    if (any(is.na(c(min_val, max_val)))) return(NULL)
    if (min_val >= max_val) return(NULL)
    c(min_val, max_val)
  }

  axis_ranges <- reactive({
    list(
      x = get_axis_range(input$axis_x_min, input$axis_x_max),
      y = get_axis_range(input$axis_y_min, input$axis_y_max)
    )
  })

  to_plotly <- function(plot_obj, tooltip = NULL) {
    if (is.null(plot_obj)) return(NULL)
    plt <- if (is.null(tooltip)) {
      ggplotly(plot_obj)
    } else {
      ggplotly(plot_obj, tooltip = tooltip)
    }
    apply_axis_ranges(plt, axis_ranges())
  }

  # Track when the analysis has been explicitly executed
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
      return(list(error = "Calcule los puntajes para habilitar esta seccion."))
    }
    cache <- scores_results_cache()
    if (is.null(cache) || length(cache) == 0) {
      return(list(error = "No se generaron Resultados. Ejecute 'Calcular puntajes'."))
    }
    key <- paste(pollutant, as.character(n_lab), level, sep = "||")
    res <- cache[[key]]
    if (is.null(res)) {
      return(list(error = "No se encontraron Resultados para la combinacion seleccionada. Ejecute nuevamente el calculo."))
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

  observeEvent(list(input$hom_file, input$stab_file, input$summary_files), {
    analysis_trigger(NULL)
  }, ignoreNULL = FALSE)

  observeEvent(input$summary_files, {
    algoA_results_cache(NULL)
    algoA_trigger(NULL)
    robust_trigger(NULL)
    consensus_results_cache(NULL)
    consensus_trigger(NULL)
    scores_results_cache(NULL)
    scores_trigger(NULL)
  }, ignoreNULL = FALSE)

  # --- Shared computation helpers ---
  get_wide_data <- function(gl, target_pollutant) {
    filtered <- gl %>% filter(pollutant == target_pollutant)
    if (is.null(filtered) || nrow(filtered) == 0) {
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
      return(list(error = "La columna 'level' no se encontro en los datos cargados."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("El nivel '%s' no se encontro para el analito '%s'.", target_level, target_pollutant)))
    }

    level_data <- wide_df %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) {
      return(list(error = "No hay suficientes replicas (se requieren al menos 2) para evaluar la homogeneidad."))
    }
    if (g < 2) {
      return(list(error = "No hay suficientes items (se requieren al menos 2) para evaluar la homogeneidad."))
    }

    intermediate_df <- if (m == 2) {
      s1 <- level_data[[1]]
      s2 <- level_data[[2]]
      level_data %>%
        mutate(
          item = row_number(),
          average = (s1 + s2) / 2,
          range = abs(s1 - s2)
        ) %>%
        select(item, everything())
    } else {
      level_data %>%
        mutate(
          item = row_number(),
          average = rowMeans(., na.rm = TRUE),
          range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        ) %>%
        select(item, everything())
    }

    hom_data <- level_data %>%
      mutate(item = factor(row_number())) %>%
      pivot_longer(
        cols = -item,
        names_to = "replicate",
        values_to = "Resultado"
      )

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "No se encontro la columna 'sample_1'. Es necesaria para calcular sigma_pt."))
    }

    first_sample_results <- level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff
    n_iqr <- calculate_niqr(first_sample_results)

    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)

    hom_item_stats <- hom_data %>%
      group_by(item) %>%
      summarise(
        mean = mean(result, na.rm = TRUE),
        var = var(result, na.rm = TRUE),
        diff = max(result, na.rm = TRUE) - min(result, na.rm = TRUE),
        .groups = "drop"
      )

    hom_x_t_bar <- mean(hom_item_stats$mean, na.rm = TRUE)
    hom_s_x_bar_sq <- var(hom_item_stats$mean, na.rm = TRUE)
    hom_s_xt <- sqrt(hom_s_x_bar_sq)

    hom_wt <- abs(hom_item_stats$diff)
    hom_sw <- sqrt(sum(hom_wt^2) / (2 * length(hom_wt)))

    hom_ss_sq <- abs(hom_s_xt^2 - ((hom_sw^2) / 2))
    hom_ss <- sqrt(hom_ss_sq)

    hom_anova_summary <- data.frame(
      "gl" = c(g - 1, g * (m - 1)),
      "Suma de cuadrados" = c(hom_s_x_bar_sq * m * (g - 1), hom_sw^2 * g * (m - 1)),
      "Media de cuadrados" = c(hom_s_x_bar_sq * m, hom_sw^2),
      check.names = FALSE
    )
    rownames(hom_anova_summary) <- c("item", "Residuos")

    hom_sigma_pt <- mad_e
    hom_c_criterion <- 0.3 * hom_sigma_pt
    hom_sigma_allowed_sq <- hom_c_criterion^2
    hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)

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
      item_means = hom_item_stats$mean,
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
      return(list(error = "La columna 'level' no se encontro en los datos de estabilidad."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("El nivel '%s' no se encontro en los datos de estabilidad del analito '%s'.", target_level, target_pollutant)))
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
      return(list(error = "No hay suficientes replicas (se requieren al menos 2) para evaluar la homogeneidad de los datos de estabilidad."))
    }
    if (g < 2) {
      return(list(error = "No hay suficientes items (se requieren al menos 2) para evaluar la homogeneidad de los datos de estabilidad."))
    }

    intermediate_df <- if (m == 2) {
      s1 <- level_data[[1]]
      s2 <- level_data[[2]]
      level_data %>%
        mutate(
          item = row_number(),
          average = (s1 + s2) / 2,
          range = abs(s1 - s2)
        ) %>%
        select(item, everything())
    } else {
      level_data %>%
        mutate(
          item = row_number(),
          average = rowMeans(., na.rm = TRUE),
          range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        ) %>%
        select(item, everything())
    }

    stab_data <- level_data %>%
      mutate(item = factor(row_number())) %>%
      pivot_longer(
        cols = -item,
        names_to = "replicate",
        values_to = "Resultado"
      )

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "No se encontro la columna 'sample_1'. Es necesaria para calcular sigma_pt en los datos de estabilidad."))
    }

    first_sample_results <- level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff
    stab_n_iqr <- calculate_niqr(first_sample_results)

    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)

    stab_item_stats <- stab_data %>%
      group_by(item) %>%
      summarise(
        mean = mean(result, na.rm = TRUE),
        var = var(result, na.rm = TRUE),
        diff = max(result, na.rm = TRUE) - min(result, na.rm = TRUE),
        .groups = "drop"
      )

    stab_x_t_bar <- mean(stab_item_stats$mean, na.rm = TRUE)
    diff_hom_stab <- abs(stab_x_t_bar - hom_results$general_mean)

    stab_s_x_bar_sq <- var(stab_item_stats$mean, na.rm = TRUE)
    stab_s_xt <- sqrt(stab_s_x_bar_sq)

    stab_wt <- abs(stab_item_stats$diff)
    stab_sw <- sqrt(sum(stab_wt^2) / (2 * length(stab_wt)))

    stab_ss_sq <- abs(stab_s_xt^2 - ((stab_sw^2) / 2))
    stab_ss <- sqrt(stab_ss_sq)

    stab_anova_summary <- data.frame(
      "gl" = c(g - 1, g * (m - 1)),
      "Suma de cuadrados" = c(stab_s_x_bar_sq * m * (g - 1), stab_sw^2 * g * (m - 1)),
      "Media de cuadrados" = c(stab_s_x_bar_sq * m, stab_sw^2),
      check.names = FALSE
    )
    rownames(stab_anova_summary) <- c("item", "Residuos")

    stab_sigma_pt <- mad_e
    stab_c_criterion <- 0.3 * hom_results$sigma_pt
    stab_sigma_allowed_sq <- stab_c_criterion^2
    stab_c_criterion_expanded <- sqrt(stab_sigma_allowed_sq * 1.88 + (stab_sw^2) * 1.01)

    if (diff_hom_stab <= stab_c_criterion) {
      stab_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-success"
    } else {
      stab_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-warning"
    }

    list(
      stab_summary = stab_anova_summary,
      stab_ss = stab_ss,
      stab_sw = stab_sw,
      stab_conclusion = stab_conclusion1,
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
      stab_item_means = stab_item_stats$mean,
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

  compute_scores_metrics <- function(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k) {
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
      return(list(error = "No se encontro el participante de referencia ('ref') para este nivel."))
    }

    x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
    participant_data <- data

    participant_data <- participant_data %>%
      rename(result = mean_value, uncertainty_std = sd_value)

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

  run_algorithm_a <- function(values, ids, max_iter = 50) {
    mask <- is.finite(values)
    values <- values[mask]
    ids <- ids[mask]

    n <- length(values)
    if (n < 3) {
      return(list(error = "El Algoritmo A requiere al menos 3 Resultados validos."))
    }

    x_star <- median(values, na.rm = TRUE)
    s_star <- 1.483 * median(abs(values - x_star), na.rm = TRUE)

    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      s_star <- sd(values, na.rm = TRUE)
    }

    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      return(list(error = "La dispersion de los datos es insuficiente para ejecutar el Algoritmo A."))
    }

    iteration_records <- list()
    converged <- FALSE

    for (iter in seq_len(max_iter)) {
      u_values <- (values - x_star) / (1.5 * s_star)
      weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))

      weight_sum <- sum(weights)
      if (!is.finite(weight_sum) || weight_sum <= 0) {
        return(list(error = "Los pesos calculados no son validos para el Algoritmo A."))
      }

      x_new <- sum(weights * values) / weight_sum
      s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)

      if (!is.finite(s_new) || s_new < .Machine$double.eps) {
        return(list(error = "El Algoritmo A colapso debido a una desviacion estandar nula."))
      }

      delta_x <- abs(x_new - x_star)
      delta_s <- abs(s_new - s_star)
      delta <- max(delta_x, delta_s)
      iteration_records[[iter]] <- data.frame(
        Iteracion = iter,
        `Valor asignado (x*)` = x_new,
        `Desviacion robusta (s*)` = s_new,
        Cambio = delta,
        check.names = FALSE
      )

      x_star <- x_new
      s_star <- s_new

      if (delta_x < 1e-03 && delta_s < 1e-03) {
        converged <- TRUE
        break
      }
    }

    iteration_df <- if (length(iteration_records) > 0) { bind_rows(iteration_records) } else { tibble() }
    u_final <- (values - x_star) / (1.5 * s_star)
    weights_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))
    weights_df <- tibble( Participante = ids, result = values, Peso = weights_final, `Residuo estandarizado` = u_final )

    list( assigned_value = x_star, robust_sd = s_star, iterations = iteration_df, weights = weights_df,
          converged = converged, effective_weight = sum(weights_final), error = NULL )
  }

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
        summarise(result = mean(mean_value, na.rm = TRUE), .groups = "drop")

      if (nrow(aggregated) < 3) {
        algo_res <- list(
          error = "Se requieren al menos tres participantes para ejecutar el Algoritmo A.",
          input_data = aggregated,
          iterations = tibble(),
          weights = tibble(),
          converged = FALSE,
          effective_weight = NA_real_
        )
      } else {
        algo_res <- run_algorithm_a(
          values = aggregated$result,
          ids = aggregated$participant_id,
          max_iter = max_iter
        )

        if (!is.null(algo_res$error)) {
          if (is.null(algo_res$iterations)) algo_res$iterations <- tibble()
          if (is.null(algo_res$weights)) algo_res$weights <- tibble()
          if (is.null(algo_res$converged)) algo_res$converged <- FALSE
          if (is.null(algo_res$effective_weight)) algo_res$effective_weight <- NA_real_
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

  # R0: Dynamic Main Layout
  output$main_layout <- renderUI({
    req(input$nav_width, input$analysis_sidebar_width)
    nav_width <- input$nav_width
    content_width <- 12 - nav_width

    analysis_sidebar_w <- input$analysis_sidebar_width
    analysis_main_w <- 12 - analysis_sidebar_w

    navlistPanel(
      id = "main_nav",
      widths = c(nav_width, content_width),
      "Modulos de analisis",
      tabPanel("Carga de datos",
        h3("Carga Manual de Archivos de Datos"),
        p("Por favor, cargue los archivos CSV necesarios para el analisis y confirme que tengan el formato correcto."),
        fluidRow(
          column(width = 4,
            wellPanel(
              h4("1. Datos de Homogeneidad"),
              fileInput("hom_file", "Cargar homogeneity.csv", accept = ".csv")
            )
          ),
          column(width = 4,
            wellPanel(
              h4("2. Datos de Estabilidad"),
              fileInput("stab_file", "Cargar stability.csv", accept = ".csv")
            )
          ),
          column(width = 4,
            wellPanel(
              h4("3. Datos Resumen de Participantes"),
              fileInput("summary_files", "Cargar summary_n*.csv", accept = ".csv", multiple = TRUE)
            )
          )
        ),
        hr(),
        h4("Estado de los Datos Cargados"),
        verbatimTextOutput("data_upload_status")
      ),
      tabPanel("Analisis de homogeneidad y estabilidad",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Ejecutar analisis"),
            actionButton("run_analysis", "Ejecutar analisis",
                         class = "btn-primary btn-block"),
            hr(),
            h4("2. Seleccionar analito"),
            uiOutput("pollutant_selector_analysis"),
            hr(),
            h4("3. Seleccionar nivel"),
            uiOutput("level_selector"),
            hr(),
            p("Este aplicativo evalua la homogeneidad y estabilidad del item de ensayo de acuerdo con los principios de la ISO 13528:2022.")
          ),
          mainPanel(
            width = analysis_main_w,
            tabsetPanel(
              id = "analysis_tabs",
              tabPanel("Vista previa de datos",
                       h4("Vista previa de datos de entrada"),
                       p("Esta tabla muestra la informacion para el analito seleccionado."),
                       h5("Datos de homogeneidad"),
                       dataTableOutput("raw_data_preview"),
                       hr(),
                       h5("Datos de estabilidad"),
                       dataTableOutput("stability_data_preview"),
                       hr(),
                       h4("Distribucion de datos"),
                       p("El histograma y el diagrama de caja muestran la distribucion de los Resultados 'sample_*' para el nivel seleccionado."),
                       fluidRow(
                         column(width = 6, plotlyOutput("results_histogram")),
                         column(width = 6, plotlyOutput("results_boxplot"))
                       ),
                       hr(),
                       h4("Validacion de datos"),
                       verbatimTextOutput("validation_message")
              ),
              tabPanel("Evaluacion de homogeneidad",
                       h4("Conclusion"),
                       uiOutput("homog_conclusion"),
                       hr(),
                       h4("Vista de datos de homogeneidad (nivel y primera muestra)"),
                       dataTableOutput("homogeneity_preview_table"),
                       hr(),
                       h4("Calculos estadisticos robustos"),
                       tableOutput("robust_stats_table"),
                       verbatimTextOutput("robust_stats_summary"),
                       hr(),
                       h4("Componentes de varianza"),
                       p("Desviaciones estandar estimadas a partir del calculo manual."),
                       tableOutput("variance_components"),
                       hr(),
                       h4("Calculos por item"),
                       p("Tabla con los calculos por item (fila) del nivel seleccionado, incluyendo promedio y rango."),
                       tableOutput("details_per_item_table"),
                       hr(),
                       h4("Estadisticos resumidos"),
                       p("Tabla con los estadisticos generales de la evaluacion de homogeneidad."),
                       tableOutput("details_summary_stats_table")
              ),
              tabPanel("Evaluacion de estabilidad",
                       h4("Conclusion"),
                       uiOutput("homog_conclusion_stability"),
                       hr(),
                       h4("Componentes de varianza"),
                       p("Desviaciones estandar estimadas para los datos de estabilidad."),
                       tableOutput("variance_components_stability"),
                       hr(),
                       h4("Calculos por item"),
                       p("Tabla con los calculos por item dentro del conjunto de estabilidad."),
                       tableOutput("details_per_item_table_stability"),
                       hr(),
                       h4("Estadisticos resumidos"),
                       p("Tabla con los estadisticos generales del conjunto de estabilidad."),
                       tableOutput("details_summary_stats_table_stability")
              )
            )
          )
        )
      ),
      tabPanel("Valor asignado",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("Selector de datos"),
            uiOutput("assigned_pollutant_selector"),
            uiOutput("assigned_n_selector"),
            uiOutput("assigned_level_selector"),
            hr(),
            helpText("La combinacion seleccionada se utiliza en todas las secciones de la derecha.")
          ),
          mainPanel(
            width = 12 - analysis_sidebar_w,
            bsplus::bs_accordion(id = "assigned_value_section") %>%
              bsplus::bs_set_opts(use_heading_link = TRUE) %>%
              bsplus::bs_append(
                title = "Algoritmo A",
                content = sidebarLayout(
                  sidebarPanel(
                    width = analysis_sidebar_w,
                    h4("1. Ejecutar analisis"),
                    actionButton("algoA_run", "Calcular Algoritmo A", class = "btn-primary btn-block"),
                    hr(),
                    h4("2. Parametros del algoritmo"),
                    numericInput("algoA_max_iter", "Iteraciones maximas:", value = 50, min = 5, max = 500, step = 5),
                    hr(),
                    helpText("Utilice el selector de la izquierda para elegir analito, esquema PT y nivel.")
                  ),
                  mainPanel(
                    width = analysis_main_w,
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
                    hr(),
                    h4("Pesos Finales por Participante"),
                    dataTableOutput("algoA_weights_table")
                  )
                )
              ) %>%
              bsplus::bs_append(
                title = "Valor consenso",
                content = sidebarLayout(
                  sidebarPanel(
                    width = analysis_sidebar_w,
                    h4("Ejecutar calculo"),
                    actionButton("consensus_run", "Calcular valores consenso", class = "btn-primary btn-block"),
                    hr(),
                    helpText("Se utiliza la misma seleccion de datos definida en la izquierda."),
                    hr(),
                    p("Calcula el valor consenso x_pt(2) y las desviaciones robustas sigma_pt_2a (MADe) y sigma_pt_2b (nIQR) para cada combinacion disponible.")
                  ),
                  mainPanel(
                    width = analysis_main_w,
                    h4("Resumen del valor consenso"),
                    tableOutput("consensus_summary_table"),
                    hr(),
                    h4("Datos de participantes"),
                    dataTableOutput("consensus_input_table")
                  )
                )
              ) %>%
              bsplus::bs_append(
                title = "Valor de referencia",
                content = sidebarLayout(
                  sidebarPanel(
                    width = analysis_sidebar_w,
                    h4("Datos de referencia"),
                    helpText("Se muestran los Resultados declarados como referencia para la seleccion actual."),
                    hr(),
                    p("Visualiza los Resultados declarados como referencia en los archivos summary_n*.csv.")
                  ),
                  mainPanel(
                    width = analysis_main_w,
                    h4("Resultados de referencia"),
                    dataTableOutput("reference_table")
                  )
                )
              )
          )
        )
      ),
      tabPanel("Preparacion PT",
        h3("Analisis de esquemas PT"),
        p("Analisis de los Resultados de los participantes para los esquemas PT cargados en los archivos summary."),
        uiOutput("pt_pollutant_tabs")
      ),
      tabPanel("Puntajes PT",
        sidebarLayout(
          sidebarPanel(
            width = 4,
            h4("1. Ejecutar calculo"),
            actionButton("scores_run", "Calcular puntajes", class = "btn-primary btn-block"),
            hr(),
            h4("2. Seleccionar datos"),
            uiOutput("scores_pollutant_selector"),
            uiOutput("scores_n_selector"),
            uiOutput("scores_level_selector")
          ),
          mainPanel(
            width = 8,
            tabsetPanel(
              id = "scores_tabs",
              tabPanel("Resultados de puntajes",
                       h4("Resumen de parametros"),
                       tableOutput("scores_parameter_table"),
                       hr(),
                       h4("Resumen de puntajes por participante"),
                       dataTableOutput("scores_overview_table"),
                       hr(),
                       h4("Resumen de evaluacion de puntajes"),
                       tableOutput("scores_evaluation_summary")
              ),
              tabPanel("Puntajes Z", uiOutput("z_scores_panel")),
              tabPanel("Puntajes Z'", uiOutput("zprime_scores_panel")),
              tabPanel("Puntajes zeta", uiOutput("zeta_scores_panel")),
              tabPanel("Puntajes En", uiOutput("en_scores_panel"))
            )
          )
        )
      ),
      tabPanel("Informe global",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Ejecutar calculo global"),
            helpText("Use \"Calcular puntajes\" en la pestana Puntajes PT para habilitar esta seccion."),
            hr(),
            h4("2. Seleccionar combinacion"),
            uiOutput("global_report_pollutant_selector"),
            uiOutput("global_report_n_selector"),
            uiOutput("global_report_level_selector"),
            hr(),
            uiOutput("global_report_pt_size_info")
          ),
          mainPanel(
            width = analysis_main_w,
            bsplus::bs_accordion(id = "global_report_sections") %>%
              bsplus::bs_set_opts(use_heading_link = TRUE) %>%
              bsplus::bs_append(
                title = "Resumenes globales",
                content = tagList(
                  h4("Resumen x_pt"),
                  dataTableOutput("global_xpt_summary_table"),
                  hr(),
                  h4("Resumen de niveles"),
                  tableOutput("global_level_summary_table"),
                  hr(),
                  h4("Resumen de evaluaciones"),
                  dataTableOutput("global_evaluation_summary_table")
                )
              ) %>%
              bsplus::bs_append(
                title = "Clasificacion de evaluaciones",
                content = tagList(
                  h4("Resumen de clasificacion"),
                  dataTableOutput("global_classification_summary_table"),
                  hr(),
                  h4("Referencia (1)"),
                  fluidRow(
                    column(6, plotlyOutput("global_class_heatmap_z_ref", height = "350px")),
                    column(6, plotlyOutput("global_class_heatmap_zprime_ref", height = "350px"))
                  ),
                  hr(),
                  h4("Consenso MADe (2a)"),
                  fluidRow(
                    column(6, plotlyOutput("global_class_heatmap_z_consensus_ma", height = "350px")),
                    column(6, plotlyOutput("global_class_heatmap_zprime_consensus_ma", height = "350px"))
                  ),
                  hr(),
                  h4("Consenso nIQR (2b)"),
                  fluidRow(
                    column(6, plotlyOutput("global_class_heatmap_z_consensus_niqr", height = "350px")),
                    column(6, plotlyOutput("global_class_heatmap_zprime_consensus_niqr", height = "350px"))
                  ),
                  hr(),
                  h4("Algoritmo A (3)"),
                  fluidRow(
                    column(6, plotlyOutput("global_class_heatmap_z_algo", height = "350px")),
                    column(6, plotlyOutput("global_class_heatmap_zprime_algo", height = "350px"))
                  )
                )
              ) %>%
              bsplus::bs_append(
                title = "Referencia (1)",
                content = tagList(
                  h4("Parametros principales"),
                  tableOutput("global_params_ref"),
                  hr(),
                  h4("Resultados por participante"),
                  dataTableOutput("global_overview_ref"),
                  hr(),
                  fluidRow(
                    column(3, plotlyOutput("global_heatmap_z_ref", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zprime_ref", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zeta_ref", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_en_ref", height = "350px"))
                  )
                )
              ) %>%
              bsplus::bs_append(
                title = "Consenso MADe (2a)",
                content = tagList(
                  h4("Parametros principales"),
                  tableOutput("global_params_consensus_ma"),
                  hr(),
                  h4("Resultados por participante"),
                  dataTableOutput("global_overview_consensus_ma"),
                  hr(),
                  fluidRow(
                    column(3, plotlyOutput("global_heatmap_z_consensus_ma", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zprime_consensus_ma", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zeta_consensus_ma", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_en_consensus_ma", height = "350px"))
                  )
                )
              ) %>%
              bsplus::bs_append(
                title = "Consenso nIQR (2b)",
                content = tagList(
                  h4("Parametros principales"),
                  tableOutput("global_params_consensus_niqr"),
                  hr(),
                  h4("Resultados por participante"),
                  dataTableOutput("global_overview_consensus_niqr"),
                  hr(),
                  fluidRow(
                    column(3, plotlyOutput("global_heatmap_z_consensus_niqr", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zprime_consensus_niqr", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zeta_consensus_niqr", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_en_consensus_niqr", height = "350px"))
                  )
                )
              ) %>%
              bsplus::bs_append(
                title = "Algoritmo A (3)",
                content = tagList(
                  h4("Parametros principales"),
                  tableOutput("global_params_algo"),
                  hr(),
                  h4("Resultados por participante"),
                  dataTableOutput("global_overview_algo"),
                  hr(),
                  fluidRow(
                    column(3, plotlyOutput("global_heatmap_z_algo", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zprime_algo", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_zeta_algo", height = "350px")),
                    column(3, plotlyOutput("global_heatmap_en_algo", height = "350px"))
                  )
                )
              )
          )
        )
      ),
      tabPanel("Participantes",
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
      tabPanel("Generacion de reportes",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Seleccionar Datos"),
            uiOutput("report_pollutant_selector"),
            uiOutput("report_n_selector"),
            uiOutput("report_level_selector"),
            hr(),
            h4("2. Parametros del Informe"),
            numericInput("report_sigma_pt", "Desv. estandar PT (sigma_pt):", value = 5, min = 0, step = 0.1),
            numericInput("report_u_xpt", "Incertidumbre tipica del valor asignado (u_xpt):", value = 0.5, min = 0, step = 0.01),
            numericInput("report_k", "Factor de cobertura (k):", value = 2, min = 1, step = 1),
            hr(),
            radioButtons("report_format", "Formato de salida:", choices = c("HTML" = "html", "PDF" = "pdf", "Word (DOCX)" = "word"), selected = "html"),
            helpText("La exportacion en PDF requiere una instalacion de LaTeX disponible en el sistema."),
            downloadButton("download_report", "Descargar informe", class = "btn-success")
          ),
          mainPanel(
            width = analysis_main_w,
            h4("Resumen previo"),
            uiOutput("report_status"),
            verbatimTextOutput("report_preview_summary"),
            hr(),
            p("El informe consolida los Resultados de homogeneidad, estabilidad y puntajes de desempeno para la combinacion seleccionada.")
          )
        )
      )
    )
  })

  # ===================================================================
  # III. Homogeneity & Stability Module
  # ===================================================================

  # R1: Reactive for Homogeneity Data
  raw_data <- reactive({
    req(hom_data_full(), input$pollutant_analysis)
    get_wide_data(hom_data_full(), input$pollutant_analysis)
  })

  # R1.6: Reactive for Stability Data
  stability_data_raw <- reactive({
    req(stab_data_full(), input$pollutant_analysis)
    get_wide_data(stab_data_full(), input$pollutant_analysis)
  })

  # R2: Dynamic Generation of the Level Selector
  output$level_selector <- renderUI({
    data <- raw_data()
    if ("level" %in% names(data)) {
      levels <- unique(data$level)
      selectInput("target_level", "2. Seleccionar nivel PT", choices = levels, selected = levels[1])
    } else {
      p("La columna 'level' no se encontro en los datos cargados.")
    }
  })

  output$pollutant_selector_analysis <- renderUI({
    req(hom_data_full())
    choices <- sort(unique(hom_data_full()$pollutant))
    selectInput("pollutant_analysis", "Seleccionar analito:", choices = choices)
  })

  # R3: Homogeneity Execution (Enabled after run button is used)
  homogeneity_run <- reactive({
    req(analysis_trigger())
    req(input$pollutant_analysis, input$target_level)
    compute_homogeneity_metrics(input$pollutant_analysis, input$target_level)
  })

  # R3.5: Stability Data Homogeneity Execution (Enabled after run button is used)
  homogeneity_run_stability <- reactive({
    req(analysis_trigger())
    req(input$pollutant_analysis, input$target_level)
    hom_results <- homogeneity_run()
    compute_stability_metrics(input$pollutant_analysis, input$target_level, hom_results)
  })

  # R4: Stability Execution (Enabled after run button is used)
  stability_run <- reactive({
    req(analysis_trigger())
    hom_results <- homogeneity_run()
    stab_hom_results <- homogeneity_run_stability()

    # Check for errors from the upstream reactives
    if (!is.null(hom_results$error)) return(list(error = hom_results$error))
    if (!is.null(stab_hom_results$error)) return(list(error = stab_hom_results$error))

    # Get the means from the results of the two homogeneity runs
    y1 <- hom_results$general_mean
    y2 <- stab_hom_results$stab_general_mean
    diff_observed <- abs(y1 - y2)

    # Use sigma_pt from the primary homogeneity run
    sigma_pt <- hom_results$sigma_pt
    stab_criterion_value <- 0.3 * sigma_pt

    # Dynamic format for decimal places
    fmt <- "%.5f"

    details_text <- sprintf(
      paste("Media de los datos de homogeneidad (y1):", fmt, "
Media de los datos de estabilidad (y2):", fmt, "
Diferencia absoluta observada:", fmt, "
Criterio de estabilidad (0.3 * sigma_pt):", fmt),
      y1, y2, diff_observed, stab_criterion_value
    )

    if (diff_observed <= stab_criterion_value) {
      conclusion <- "Conclusion: El item es estable."
      conclusion_class <- "alert alert-success"
    } else {
      conclusion <- "Conclusion: ADVERTENCIA: El item puede ser inestable."
      conclusion_class <- "alert alert-warning"
    }

    # For the t-test, we need the raw results from both datasets for the selected level
    target_level <- input$target_level
    
    data_t1_results <- raw_data() %>%
      filter(level == target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), values_to = "Resultado") %>%
      pull(result)

    data_t2_results <- stability_data_raw() %>%
      filter(level == target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), values_to = "Resultado") %>%
      pull(result)

    # T-test
    t_test_result <- t.test(data_t1_results, data_t2_results)

    if (t_test_result$p.value > 0.05) {
      ttest_conclusion <- "Prueba t: No se detecto una diferencia estadisticamente significativa entre los dos conjuntos (p > 0.05), lo que respalda la estabilidad."
    } else {
      ttest_conclusion <- "Prueba t: Se detecto una diferencia estadisticamente significativa entre los dos conjuntos (p <= 0.05), lo que indica posible inestabilidad."
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

  # --- Outputs ---

  # Output: Data Preview
  output$raw_data_preview <- renderDataTable({
    req(raw_data())
    gl <- head(raw_data(), 10)
    numeric_cols <- names(gl)[sapply(gl, is.numeric)]
    fmt <- "%.9f"
    gl <- gl %>%
      mutate(across(all_of(numeric_cols), ~ sprintf("%.5f", .x)))
    datatable(gl, options = list(scrollX = TRUE))
  })
  
  output$stability_data_preview <- renderDataTable({
    req(stability_data_raw())
    gl <- head(stability_data_raw(), 10)
    numeric_cols <- names(gl)[sapply(gl, is.numeric)]
    fmt <- "%.9f"
    gl <- gl %>%
      mutate(across(all_of(numeric_cols), ~ sprintf("%.5f", .x)))
    datatable(gl, options = list(scrollX = TRUE))
  })


  # Output: Validation Message
  output$validation_message <- renderPrint({
    data <- raw_data()
    cat("Datos cargados correctamente.
")
    cat(paste("Dimensiones:", paste(dim(data), collapse = " x "), "
"))

    required_cols <- c("level")
    has_samples <- any(str_detect(names(data), "sample_"))

    if(!all(required_cols %in% names(data))) {
        cat(paste("ERROR: Faltan columnas requeridas:", paste(setdiff(required_cols, names(data)), collapse=", "), "
"))
    } else {
        cat("Se encontro la columna 'level'.
")
    }

    if(!has_samples) {
        cat("ERROR: No se encontraron columnas con el prefijo 'sample_'. Se requieren para el analisis.
")
    } else {
        cat("Se encontraron columnas 'sample_*'.
")
    }
  })

  # Reactive expression for plotting data
  plot_data_long <- reactive({
    req(raw_data())
    if (!"level" %in% names(raw_data())) return(NULL)
    raw_data() %>%
      select(level, starts_with("sample_")) %>%
      pivot_longer(-level, names_to = "sample", values_to = "Resultado")
  })

  # Output: Histogram
  output$results_histogram <- renderPlotly({
    plot_data <- plot_data_long()
    req(plot_data)
    p <- ggplot(plot_data, aes(x = result)) +
      geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 20) +
      geom_density(alpha = 0.4, fill = "lightblue") +
      facet_wrap(~level, scales = "free") +
      labs(title = "Distribucion por nivel",
           x = "Resultado", y = "Densidad") +
      theme_minimal()
    to_plotly(p)
  })

  # Output: Boxplot
  output$results_boxplot <- renderPlotly({
    plot_data <- plot_data_long()
    req(plot_data)
    p <- ggplot(plot_data, aes(x = "", y = result)) +
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      facet_wrap(~level, scales = "free") +
      labs(title = "Diagrama de caja por nivel",
           x = NULL, y = "Resultado") +
      theme_minimal()
    to_plotly(p)
  })

  # Output: Homogeneity Data Preview
  output$homogeneity_preview_table <- renderDataTable({
    req(raw_data(), input$target_level)
    homogeneity_data <- raw_data()
    # Find the first column that starts with "sample_"
    first_sample_col <- names(homogeneity_data)[grep("sample_", names(homogeneity_data))][1]
    homogeneity_data %>%
      filter(level == input$target_level) %>%
      mutate(across(where(is.numeric), ~ round(.x, 5))) %>%
      select(level, all_of(first_sample_col))
  })

  # Output: Robust Stats Table
  output$robust_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        Statistic = c("Mediana (x_pt)", "Mediana de diferencias absolutas", "MADe (sigma_pt)", "nIQR"),
        Value = sprintf("%.5f", c(res$median_val, res$median_abs_diff, res$sigma_pt, res$n_iqr))
      )
    }
  }, spacing = "l")

  # Output: Robust Stats Summary
  output$robust_stats_summary <- renderPrint({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      cat(sprintf("Median Value: %.5f\n", res$median_val))
      cat(sprintf("Mediana de diferencias absolutas: %.5f\n", res$median_abs_diff))
      cat(sprintf("MADe (sigma_pt): %.5f\n", res$sigma_pt))
      cat(sprintf("nIQR: %.5f\n", res$n_iqr))
    }
  })

  # Output: Homogeneity Conclusion
  output$homog_conclusion <- renderUI({
    res <- homogeneity_run()
    if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
    } else {
        div(class = res$conclusion_class, HTML(res$conclusion))
    }
  })

  # Output: Variance Components
  output$variance_components <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
        gl <- data.frame(
          Component = c("Valor asignado (xpt)",
                        "Desviacion robusta (sigma_pt)",
                        "Incertidumbre del valor asignado (u_xpt)",
                        "Desviacion estandar entre muestras (ss)",
                        "Desviacion estandar dentro de muestra (sw)",
                        "---",
                        "Criterio c",
                        "Criterio c (ampliado)"),
          Value = c(
          format_num(c(res$median_val, res$sigma_pt, res$u_xpt, res$ss, res$sw)),
          "",
          format_num(c(res$c_criterion, res$c_criterion_expanded))
          )
        )
        gl
    }
  })

  # Output: Stability Conclusion
  output$stability_conclusion <- renderUI({
    res <- stability_run()
    if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
    } else {
        div(class = res$conclusion_class, HTML(res$conclusion))
    }
  })

  # Output: Stability Details
  output$stability_details <- renderPrint({
      res <- stability_run()
      if (is.null(res$error)) {
          cat(res$details)
      }
  })

  # Output: Stability T-test
  output$stability_ttest <- renderPrint({
      res <- stability_run()
      if (is.null(res$error)) {
          cat(res$ttest_conclusion, "

")
          print(res$ttest_summary, digits = 9)
      }
  })

  # Output: Details per item table
  output$details_per_item_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      res$intermediate_df %>% mutate(across(where(is.numeric), ~ round(.x, 5)))
    }
  }, spacing = "l", digits = 5)

  # Output: Details summary stats table
  output$details_summary_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        Parameter = c("Media general",
                      "Desviacion estandar de las medias",
                      "Varianza de las medias (s_x_bar_sq)",
                      "sw",
                      "Varianza dentro de muestra (s_w_sq)",
                      "ss",
                      "---",
                      "Valor asignado (xpt)",
                      "Mediana de diferencias absolutas",
                      "Numero de items (g)",
                      "Numero de replicas (m)",
                      "Desviacion robusta (MADe)",
                      "nIQR",
                      "Incertidumbre del valor asignado (u_xpt)",
                      "---",
                      "Criterio c",
                      "Criterio c (ampliado)"),
        Value = c(
          c(format_num(res$general_mean), format_num(res$sd_of_means), format_num(res$s_x_bar_sq), format_num(res$sw), format_num(res$s_w_sq), format_num(res$ss)),
          "",
          c(format_num(res$median_val), format_num(res$median_abs_diff), res$g, res$m, format_num(res$sigma_pt), format_num(res$n_iqr), format_num(res$u_xpt)),
          "",
          c(format_num(res$c_criterion), format_num(res$c_criterion_expanded))
        )
      )
    }
  }, spacing = "l")

  # --- Outputs for Stability Data Analysis Tab ---

  # Output: Homogeneity Conclusion for Stability Data
  output$homog_conclusion_stability <- renderUI({
    res <- homogeneity_run_stability()
    if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
    } else {
        div(class = res$stab_conclusion_class, HTML(res$stab_conclusion))
    }
  })

  # Output: Variance Components for Stability Data
  output$variance_components_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
        gl <- data.frame(
          Component = c("Valor asignado (xpt)",
                        "Desviacion robusta (sigma_pt)",
                        "Incertidumbre del valor asignado (u_xpt)"),
          Value = c(
            sprintf("%.5f", res$stab_median_val),
            sprintf("%.5f", res$stab_sigma_pt),
            sprintf("%.5f", res$stab_u_xpt)
          )
        )
        gl
    }
  })

  # Output: Details per item table for Stability Data
  output$details_per_item_table_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
      res$stab_intermediate_df %>% mutate(across(where(is.numeric), ~ round(.x, 5)))
    }
  }, spacing = "l", digits = 5)

  # Output: Details summary stats table for Stability Data
  output$details_summary_stats_table_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
      data.frame(
        Parameter = c("Media general",
                      "Diferencia absoluta respecto a la media general",
                      "Desviacion estandar de las medias",
                      "Varianza de las medias (s_x_bar_sq)",
                      "sw",
                      "Varianza dentro de muestra (s_w_sq)",
                      "ss",
                      "---",
                      "Valor asignado (xpt)",
                      "Mediana de diferencias absolutas",
                      "Numero de items (g)",
                      "Numero de replicas (m)",
                      "Desviacion robusta (MADe)",
                      "nIQR",
                      "Incertidumbre del valor asignado (u_xpt)",
                      "---",
                      "Criterio c",
                      "Criterio c (ampliado)"),
        Value = c(
          c(format_num(res$stab_general_mean), format_num(res$diff_hom_stab), format_num(res$stab_sd_of_means), format_num(res$stab_s_x_bar_sq), format_num(res$stab_sw), format_num(res$stab_s_w_sq), format_num(res$stab_ss)),
          "",
          c(format_num(res$stab_median_val), format_num(res$stab_median_abs_diff), res$g, res$m, format_num(res$stab_sigma_pt), format_num(res$stab_n_iqr), format_num(res$stab_u_xpt)),
          "",
          c(format_num(res$stab_c_criterion), format_num(res$stab_c_criterion_expanded))
        )
      )
    }
  }, spacing = "l")

  # --- PT Scores Module ---

  # Dynamic UI for PT Scores selectors
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
    selectInput("scores_n_lab", "Seleccionar esquema PT (n):", choices = choices)
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

  ensure_classification_columns <- function(gl) {
    required_cols <- c(
      "classification_z_en",
      "classification_z_en_code",
      "classification_zprime_en",
      "classification_zprime_en_code"
    )
    if (is.null(gl)) {
      return(gl)
    }
    for (col in required_cols) {
      if (!col %in% names(gl)) {
        gl[[col]] <- rep(NA_character_, nrow(gl))
      }
    }
    gl
  }

  pt_en_class_labels <- c(
    a1 = "a1 - Totalmente satisfactorio",
    a2 = "a2 - Satisfactorio pero conservador",
    a3 = "a3 - Satisfactorio con MU subestimada",
    a4 = "a4 - Cuestionable pero aceptable",
    a5 = "a5 - Cuestionable e inconsistente",
    a6 = "a6 - No satisfactorio pero la MU cubre la desviacion",
    a7 = "a7 - No satisfactorio (critico)"
  )

  pt_en_class_colors <- c(
    a1 = "#2E7D32",
    a2 = "#66BB6A",
    a3 = "#9CCC65",
    a4 = "#FFF59D",
    a5 = "#FBC02D",
    a6 = "#EF9A9A",
    a7 = "#C62828",
    mu_missing_z = "#90A4AE",
    mu_missing_zprime = "#78909C"
  )

  score_eval_z <- function(z) {
    case_when(
      !is.finite(z) ~ "N/A",
      abs(z) <= 2 ~ "Satisfactorio",
      abs(z) > 2 & abs(z) < 3 ~ "Cuestionable",
      abs(z) >= 3 ~ "No satisfactorio"
    )
  }

  classify_with_en <- function(score_val, en_val, U_xi, sigma_pt, mu_missing, score_label) {
    if (!is.finite(score_val)) {
      return(list(code = NA_character_, label = "N/A"))
    }

    if (isTRUE(mu_missing)) {
      base_eval <- score_eval_z(score_val)
      if (base_eval == "N/A") {
        return(list(code = NA_character_, label = "N/A"))
      }
      label_key <- tolower(score_label)
      label_key <- gsub("'", "prime", label_key)
      label_key <- gsub("[^a-z0-9]+", "", label_key)
      code <- paste0("mu_missing_", label_key)
      label <- sprintf("MU faltante - solo %s: %s", score_label, base_eval)
      return(list(code = code, label = label))
    }

    if (!is.finite(en_val) || !is.finite(sigma_pt) || sigma_pt <= 0 || !is.finite(U_xi)) {
      return(list(code = NA_character_, label = "N/A"))
    }

    abs_score <- abs(score_val)
    abs_en <- abs(en_val)
    u_is_conservative <- U_xi >= (2 * sigma_pt)

    if (abs_score <= 2) {
      if (abs_en < 1) {
        code <- if (u_is_conservative) "a2" else "a1"
      } else {
        code <- "a3"
      }
    } else if (abs_score < 3) {
      code <- if (abs_en < 1) "a4" else "a5"
    } else {
      code <- if (abs_en < 1) "a6" else "a7"
    }

    list(code = code, label = pt_en_class_labels[[code]])
  }

  compute_combo_scores <- function(participants_df, x_pt, sigma_pt, u_xpt, combo_meta, k = 2) {
    if (!is.finite(x_pt)) {
      return(list(
        error = sprintf("Valor asignado no disponible para %s.", combo_meta$title)
      ))
    }
    if (!is.finite(sigma_pt) || sigma_pt <= 0) {
      return(list(
        error = sprintf("sigma_pt no valido para %s.", combo_meta$title)
      ))
    }
    if (!is.finite(u_xpt) || u_xpt < 0) {
      u_xpt <- 0
    }
    participants_df <- participants_df %>%
      mutate(
        uncertainty_std_missing = !is.finite(uncertainty_std),
        uncertainty_std = ifelse(uncertainty_std_missing, NA_real_, uncertainty_std)
      )

    z_values <- (participants_df$result - x_pt) / sigma_pt
    zprime_den <- sqrt(sigma_pt^2 + u_xpt^2)
    z_prime_values <- if (zprime_den > 0) {
      (participants_df$result - x_pt) / zprime_den
    } else {
      NA_real_
    }
    zeta_den <- sqrt(participants_df$uncertainty_std^2 + u_xpt^2)
    zeta_values <- ifelse(zeta_den > 0, (participants_df$result - x_pt) / zeta_den, NA_real_)
    U_xi <- k * participants_df$uncertainty_std
    U_xpt <- k * u_xpt
    en_den <- sqrt(U_xi^2 + U_xpt^2)
    en_values <- ifelse(en_den > 0, (participants_df$result - x_pt) / en_den, NA_real_)

    data <- participants_df %>%
      mutate(
        Combination = combo_meta$title,
        Combination_label = combo_meta$label,
        x_pt = x_pt,
        sigma_pt = sigma_pt,
        u_xpt = u_xpt,
        k_factor = k,
        z_score = z_values,
        z_score_eval = score_eval_z(z_score),
        z_prime_score = z_prime_values,
        z_prime_score_eval = score_eval_z(z_prime_score),
        zeta_score = zeta_values,
        zeta_score_eval = score_eval_z(zeta_score),
        En_score = en_values,
        En_score_eval = case_when(
          !is.finite(En_score) ~ "N/A",
          abs(En_score) <= 1 ~ "Satisfactorio",
          abs(En_score) > 1 ~ "No satisfactorio"
        ),
        U_xi = U_xi,
        U_xpt = U_xpt
      ) %>%
      rowwise() %>%
      mutate(
        classification_z_en_res = list(classify_with_en(z_score, En_score, U_xi, sigma_pt, uncertainty_std_missing, "z")),
        classification_z_en = classification_z_en_res$label,
        classification_z_en_code = classification_z_en_res$code,
        classification_zprime_en_res = list(classify_with_en(z_prime_score, En_score, U_xi, sigma_pt, uncertainty_std_missing, "z'")),
        classification_zprime_en = classification_zprime_en_res$label,
        classification_zprime_en_code = classification_zprime_en_res$code
      ) %>%
      ungroup() %>%
      select(-classification_z_en_res, -classification_zprime_en_res)

    list(
      error = NULL,
      title = combo_meta$title,
      label = combo_meta$label,
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      data = data
    )
  }

  plot_scores <- function(gl, score_col, title, subtitle, ylab, warn_limits = NULL, action_limits = NULL) {
    score_values <- gl[[score_col]]
    if (all(!is.finite(score_values))) {
      return(
        ggplot() +
          theme_void() +
          labs(title = title, subtitle = paste(subtitle, "- sin datos validos"), y = ylab)
      )
    }
    participant_levels <- sort(unique(gl$participant_id))
    gg <- ggplot(gl, aes(x = factor(participant_id, levels = participant_levels), y = score_values)) +
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
      return(list(error = "No se encontraron datos para la combinacion seleccionada."))
    }

    participant_data <- subset_data %>%
      filter(participant_id != "ref") %>%
      group_by(participant_id) %>%
      summarise(
        result = mean(mean_value, na.rm = TRUE),
        uncertainty_std = mean(sd_value, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        pollutant = target_pollutant,
        n_lab = target_n_lab,
        level = target_level
      )

    if (nrow(participant_data) == 0) {
      return(list(error = "No se encontraron participantes (distintos al valor de referencia) para la combinacion seleccionada."))
    }

    ref_data <- subset_data %>% filter(participant_id == "ref")
    if (nrow(ref_data) == 0) {
      return(list(error = "No se encontro informacion del participante de referencia para esta combinacion."))
    }
    x_pt1 <- mean(ref_data$mean_value, na.rm = TRUE)

    hom_res <- tryCatch(
      compute_homogeneity_metrics(target_pollutant, target_level),
      error = function(e) list(error = conditionMessage(e))
    )
    if (!is.null(hom_res$error)) {
      return(list(error = paste("Error obteniendo parametros de homogeneidad:", hom_res$error)))
    }
    sigma_pt1 <- hom_res$sigma_pt
    u_xpt1 <- hom_res$u_xpt

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
    combos$ref <- compute_combo_scores(participant_data, x_pt1, sigma_pt1, u_xpt1, score_combo_info$ref, k = k_factor)
    combos$consensus_ma <- compute_combo_scores(participant_data, median_val, sigma_pt_2a, u_xpt2a, score_combo_info$consensus_ma, k = k_factor)
    combos$consensus_niqr <- compute_combo_scores(participant_data, median_val, sigma_pt_2b, u_xpt2b, score_combo_info$consensus_niqr, k = k_factor)

    if (is.null(algo_res$error)) {
      u_xpt3 <- 1.25 * algo_res$robust_sd / sqrt(n_part)
      combos$algo <- compute_combo_scores(participant_data, algo_res$assigned_value, algo_res$robust_sd, u_xpt3, score_combo_info$algo, k = k_factor)
    } else {
      combos$algo <- list(error = algo_res$error, title = score_combo_info$algo$title, label = score_combo_info$algo$label)
    }

    summary_table <- map_dfr(names(score_combo_info), function(key) {
      meta <- score_combo_info[[key]]
      combo <- combos[[key]]
      if (is.null(combo)) return(NULL)
      if (!is.null(combo$error)) {
        tibble(
          Combination = meta$title,
          Etiqueta = meta$label,
          `x_pt` = NA_real_,
          `sigma_pt` = NA_real_,
          `u(x_pt)` = NA_real_,
          Nota = combo$error
        )
      } else {
        tibble(
          Combination = combo$title,
          Etiqueta = combo$label,
          `x_pt` = combo$x_pt,
          `sigma_pt` = combo$sigma_pt,
          `u(x_pt)` = combo$u_xpt,
          Nota = ""
        )
      }
    })

    overview_table <- map_dfr(names(score_combo_info), function(key) {
      meta <- score_combo_info[[key]]
      combo <- combos[[key]]
      if (is.null(combo)) return(NULL)
      if (!is.null(combo$error)) {
        tibble(
          Combination = meta$title,
          Participante = NA_character_,
          result = NA_real_,
          `u(xi)` = NA_real_,
          `Puntaje z` = NA_real_,
          `Puntaje z Eval` = combo$error,
          `Puntaje z'` = NA_real_,
          `Puntaje z' Eval` = "",
          `Puntaje zeta` = NA_real_,
          `Puntaje zeta Eval` = "",
          `Puntaje En` = NA_real_,
          `Puntaje En Eval` = ""
        )
      } else {
        combo$data %>%
          transmute(
            Combination = combo$title,
            Participante = participant_id,
            Resultado = result,
            `u(xi)` = uncertainty_std,
            `Puntaje z` = z_score,
            `Puntaje z Eval` = z_score_eval,
            `Puntaje z'` = z_prime_score,
            `Puntaje z' Eval` = z_prime_score_eval,
            `Puntaje zeta` = zeta_score,
            `Puntaje zeta Eval` = zeta_score_eval,
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
        error = "No se generaron Resultados globales. Ejecute 'Calcular puntajes'.",
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

    normalize_n <- function(gl) {
      if (is.null(gl) || nrow(gl) == 0) {
        return(gl)
      }
      gl %>%
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

  # --- Global Report Module ---
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
        Combination = as.character(Combination),
        Combination_label = as.character(Combination_label),
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
      group_by(pollutant, n_lab, level, Combination, Combination_label, n_lab_numeric) %>%
      summarise(
        x_pt = dplyr::first(x_pt),
        u_xpt = dplyr::first(u_xpt),
        sigma_pt = dplyr::first(sigma_pt),
        k_factor = dplyr::first(k_factor),
        .groups = "drop"
      ) %>%
      mutate(
        expanded_uncertainty = k_factor * u_xpt
      )
  })

  global_evaluation_summary_data <- reactive({
    combos <- global_report_combos()
    if (nrow(combos) == 0) {
      return(tibble())
    }
    combos %>%
      filter(participant_id != "ref") %>%
      select(pollutant, n_lab, level, Combination, Combination_label,
             z_score_eval, zeta_score_eval, En_score_eval) %>%
      pivot_longer(
        cols = c(z_score_eval, zeta_score_eval, En_score_eval),
        names_to = "score_type",
        values_to = "evaluation"
      ) %>%
      mutate(
        pollutant = as.character(pollutant),
        n_lab = as.character(n_lab),
        level = as.character(level),
        Combination = as.character(Combination),
        Combination_label = as.character(Combination_label),
        score_type = sub("_eval$", "", score_type),
        evaluation = factor(evaluation, levels = c("Satisfactorio", "Cuestionable", "No satisfactorio", "N/A"))
      ) %>%
      count(pollutant, n_lab, level, Combination, Combination_label, score_type, evaluation, .drop = FALSE, name = "Conteo") %>%
      group_by(pollutant, n_lab, level, Combination, Combination_label, score_type) %>%
      mutate(
        Total = sum(Conteo),
        Porcentaje = ifelse(Total > 0, (Conteo / Total) * 100, 0)
      ) %>%
      ungroup() %>%
      select(-Total) %>%
      mutate(Criteria = paste(score_type, evaluation))
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
          Combination = as.character(Combination),
          Combination_label = as.character(Combination_label),
          classification_type = "z + En",
          classification_label = classification_z_en,
          classification_code = classification_z_en_code
        ),
      combos_filtered %>%
        transmute(
          pollutant = as.character(pollutant),
          n_lab = as.character(n_lab),
          level = as.character(level),
          Combination = as.character(Combination),
          Combination_label = as.character(Combination_label),
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
        Combination,
        Combination_label,
        classification_type,
        classification_label,
        classification_code,
        name = "Conteo"
      ) %>%
      group_by(pollutant, n_lab, level, Combination, Combination_label, classification_type) %>%
      mutate(
        Total = sum(Conteo),
        Porcentaje = ifelse(Total > 0, (Conteo / Total) * 100, 0)
      ) %>%
      ungroup() %>%
      select(-Total)
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
      return(helpText("Calcule los puntajes para habilitar esta seccion."))
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
      return(helpText("No hay niveles disponibles para esta seleccion."))
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
      strong("Resumen de tamano PT:"), br(),
      participants_text
    )
  })

  get_dfobal_summary_row <- function(spec) {
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

  get_dfobal_overview_data <- function(spec) {
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
        Combination == spec$title
      )
  }

  get_combo_levels_order <- function(combos_filtered) {
    combos_filtered %>%
      distinct(level) %>%
      mutate(level_numeric = readr::parse_number(level)) %>%
      arrange(level_numeric, level) %>%
      pull(level)
  }

  render_dfobal_score_heatmap <- function(output_id, combo_key, score_col, eval_col, palette, title_prefix) {
    output[[output_id]] <- renderPlotly({
      combos <- global_report_combos()
      req(nrow(combos) > 0, input$global_report_pollutant, input$global_report_n_lab)
      spec <- global_combo_specs[[combo_key]]
      filtered <- combos %>%
        filter(
          pollutant == input$global_report_pollutant,
          n_lab == input$global_report_n_lab,
          combo_key == combo_key,
          Combination_label == spec$label,
          participant_id != "ref"
        )
      if (nrow(filtered) == 0) {
        empty_plot <- ggplot() + theme_void() + labs(title = paste(title_prefix, "- sin datos disponibles"))
        return(to_plotly(empty_plot))
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

      ggplot(plot_data, aes(x = run_label, y = participant_id, fill = evaluation)) +
        geom_tile(color = "white") +
        geom_text(aes(label = tile_label), size = 3, color = "#1B1B1B") +
        scale_fill_manual(values = palette, drop = FALSE, na.value = "#BDBDBD") +
        labs(
          title = paste(title_prefix, "para", spec$title),
          subtitle = paste("Analito:", input$global_report_pollutant),
          x = "Nivel",
          y = "Participante",
          fill = "Evaluacion"
        ) +
        theme_minimal() +
        theme(
          panel.grid = element_blank(),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    })
  }

  render_dfobal_classification_heatmap <- function(output_id, combo_key, code_col, label_col, title_prefix) {
    output[[output_id]] <- renderPlotly({
      combos <- global_report_combos()
      req(nrow(combos) > 0, input$global_report_pollutant, input$global_report_n_lab)
      combos <- ensure_classification_columns(combos)
      spec <- global_combo_specs[[combo_key]]
      filtered <- combos %>%
        filter(
          pollutant == input$global_report_pollutant,
          n_lab == input$global_report_n_lab,
          combo_key == combo_key,
          Combination_label == spec$label,
          participant_id != "ref"
        )
      if (nrow(filtered) == 0) {
        empty_plot <- ggplot() + theme_void() + labs(title = paste(title_prefix, "- sin datos disponibles"))
        return(to_plotly(empty_plot))
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

      code_sym <- rlang::sym(code_col)
      label_sym <- rlang::sym(label_col)

      plot_data <- base_grid %>%
        left_join(
          filtered %>%
            transmute(
              participant_id,
              run_label = as.character(level),
              class_code = !!code_sym,
              class_label = !!label_sym
            ),
          by = c("participant_id", "run_label")
        ) %>%
        mutate(
          class_code = ifelse(class_code == "", NA_character_, class_code),
          class_label = ifelse(is.na(class_label) | class_label == "", "N/A", class_label),
          participant_id = factor(participant_id, levels = participant_levels),
          run_label = factor(run_label, levels = run_levels),
          display_code = case_when(
            is.na(class_code) ~ "",
            grepl("^mu_missing", class_code) ~ "MU",
            TRUE ~ toupper(class_code)
          ),
          fill_code = factor(class_code, levels = names(pt_en_class_colors))
        )

      legend_labels <- c(
        pt_en_class_labels,
        `mu_missing_z` = "MU faltante - solo z",
        `mu_missing_zprime` = "MU faltante - solo z'"
      )

      ggplot(plot_data, aes(x = run_label, y = participant_id, fill = fill_code)) +
        geom_tile(color = "white") +
        geom_text(aes(label = display_code), size = 3, color = "#1B1B1B") +
        scale_fill_manual(
          values = pt_en_class_colors,
          breaks = names(pt_en_class_colors),
          labels = legend_labels,
          drop = FALSE,
          na.value = "#EEEEEE"
        ) +
        labs(
          title = paste(title_prefix, "para", spec$title),
          subtitle = paste("Analito:", input$global_report_pollutant),
          x = "Nivel",
          y = "Participante",
          fill = "Clase"
        ) +
        theme_minimal() +
        theme(
          panel.grid = element_blank(),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    })
  }

  purrr::iwalk(global_combo_specs, function(spec, combo_key) {
    output[[paste0("global_params_", combo_key)]] <- renderTable({
      summary_row <- get_dfobal_summary_row(spec)
      if (nrow(summary_row) == 0) {
        return(data.frame(Mensaje = "No hay datos disponibles para esta combinacion."))
      }
      if (any(summary_row$Nota != "")) {
        return(summary_row %>% select(Combination, Nota))
      }
      summary_row %>%
        select(Combination, `x_pt`, `sigma_pt`, `u(x_pt)`) %>%
        mutate(
          `x_pt` = sprintf("%.5f", `x_pt`),
          `sigma_pt` = sprintf("%.5f", `sigma_pt`),
          `u(x_pt)` = sprintf("%.5f", `u(x_pt)`)
        )
    }, striped = TRUE, spacing = "l", rownames = FALSE)

    output[[paste0("global_overview_", combo_key)]] <- renderDataTable({
      overview <- get_dfobal_overview_data(spec)
      if (nrow(overview) == 0) {
        return(datatable(data.frame(Mensaje = "No hay datos disponibles para esta combinacion.")))
      }
      datatable(
        overview,
        options = list(scrollX = TRUE, pageLength = 12),
        rownames = FALSE
      ) %>%
        formatRound(columns = c("Resultado", "u(xi)", "Puntaje z", "Puntaje z'", "Puntaje zeta", "Puntaje En"), digits = 3)
    })

    render_dfobal_score_heatmap(
      paste0("global_heatmap_z_", combo_key),
      combo_key,
      "z_score",
      "z_score_eval",
      score_heatmap_palettes$z,
      "Mapa de calor Puntaje z"
    )

    render_dfobal_score_heatmap(
      paste0("global_heatmap_zprime_", combo_key),
      combo_key,
      "z_prime_score",
      "z_prime_score_eval",
      score_heatmap_palettes$zprime,
      "Mapa de calor Puntaje z'"
    )

    render_dfobal_score_heatmap(
      paste0("global_heatmap_zeta_", combo_key),
      combo_key,
      "zeta_score",
      "zeta_score_eval",
      score_heatmap_palettes$zeta,
      "Mapa de calor Puntaje zeta"
    )

    render_dfobal_score_heatmap(
      paste0("global_heatmap_en_", combo_key),
      combo_key,
      "En_score",
      "En_score_eval",
      score_heatmap_palettes$en,
      "Mapa de calor Puntaje En"
    )

    render_dfobal_classification_heatmap(
      paste0("global_class_heatmap_z_", combo_key),
      combo_key,
      "classification_z_en_code",
      "classification_z_en",
      "Clasificacion z + En"
    )

    render_dfobal_classification_heatmap(
      paste0("global_class_heatmap_zprime_", combo_key),
      combo_key,
      "classification_zprime_en_code",
      "classification_zprime_en",
      "Clasificacion z' + En"
    )
  })

  output$global_xpt_summary_table <- renderDataTable({
    summary_df <- global_xpt_summary_data()
    if (nrow(summary_df) == 0) {
      return(datatable(data.frame(Mensaje = "No hay informacion x_pt disponible.")))
    }
    req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
    filtered <- summary_df %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        level == input$global_report_level
      ) %>%
      arrange(Combination_label, level)
    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Mensaje = "No hay informacion x_pt para la seleccion actual.")))
    }
    datatable(
      filtered %>%
        select(
          Combinacion = Combination,
          `Etiqueta de combinacion` = Combination_label,
          Nivel = level,
          `x_pt`,
          `u(x_pt)` = u_xpt,
          `expanded_uncertainty`,
          `sigma_pt`
        ),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatRound(columns = c("x_pt", "u(x_pt)", "expanded_uncertainty", "sigma_pt"), digits = 5)
  })

  output$global_level_summary_table <- renderTable({
    level_df <- global_level_summary_data()
    if (nrow(level_df) == 0) {
      return(data.frame(Mensaje = "No hay informacion de niveles disponible."))
    }
    req(input$global_report_pollutant, input$global_report_n_lab, input$global_report_level)
    level_df %>%
      filter(
        pollutant == input$global_report_pollutant,
        n_lab == input$global_report_n_lab,
        level == input$global_report_level
      ) %>%
      transmute(
        `Run Order` = Run_Order,
        Level = level
      )
  }, striped = TRUE, spacing = "l", rownames = FALSE)

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
      arrange(Combination_label, level, score_type, evaluation)
    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Mensaje = "No hay evaluaciones para la seleccion actual.")))
    }
    datatable(
      filtered %>%
        select(
          Combinacion = Combination,
          Nivel = level,
          Criterio = Criteria,
          Evaluacion = evaluation,
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
      arrange(Combination_label, level, classification_type, classification_code)
    if (nrow(filtered) == 0) {
      return(datatable(data.frame(Mensaje = "No hay clasificaciones para la seleccion actual.")))
    }
    datatable(
      filtered %>%
        select(
          Combinacion = Combination,
          Nivel = level,
          `Clasificacion` = classification_type,
          `Codigo` = classification_code,
          `Descripcion` = classification_label,
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
      return(helpText("Calcule los puntajes para habilitar esta seccion."))
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
      return(list(error = "Calcule los puntajes para habilitar esta seccion."))
    }
    key <- input$participants_level
    if (is.null(key) || key == "") {
      return(list(error = "Seleccione un analito y nivel."))
    }
    parts <- strsplit(key, "\\|\\|")[[1]]
    if (length(parts) < 3) {
      return(list(error = "Seleccion invalida."))
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
      return(list(error = "No hay datos de puntajes calculados para esta seleccion.", table = tibble()))
    }
    scores_long <- combined %>%
      select(Combination, z_score_eval, zeta_score_eval, En_score_eval) %>%
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
      count(Combination, score_type, evaluation, .drop = FALSE, name = "Conteo") %>%
      group_by(Combination, score_type) %>%
      mutate(Porcentaje = ifelse(sum(Conteo) > 0, (Conteo / sum(Conteo)) * 100, 0)) %>%
      ungroup() %>%
      mutate(Criteria = paste(score_type, evaluation)) %>%
      select(Combinacion = Combination, Criterio = Criteria, Conteo, Porcentaje)

    list(error = NULL, table = evaluation_summary)
  })

  output$scores_parameter_table <- renderTable({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(data.frame(Mensaje = res$error))
    }
    res$summary
  }, digits = 6, striped = TRUE, spacing = "l", rownames = FALSE)

  output$scores_overview_table <- renderDataTable({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(datatable(data.frame(Mensaje = res$error)))
    }
    datatable(res$overview, options = list(scrollX = TRUE, pageLength = 12), rownames = FALSE) %>%
      formatRound(columns = c("Resultado", "u(xi)", "Puntaje z", "Puntaje z'", "Puntaje zeta", "Puntaje En"), digits = 3)
  })

  output$scores_evaluation_summary <- renderTable({
    eval_res <- scores_evaluation_summary()
    if (!is.null(eval_res$error)) {
      return(data.frame(Mensaje = eval_res$error))
    }
    eval_res$table
  }, digits = 2, striped = TRUE, spacing = "l", rownames = FALSE)

  output$z_scores_panel <- renderUI({
    res <- scores_results_selected()
    if (!is.null(res$error)) {
      return(div(class = "alert alert-danger", res$error))
    }
    tagList(lapply(names(score_combo_info), function(key) {
      combo <- res$combos[[key]]
      meta <- score_combo_info[[key]]
      if (is.null(combo)) return(NULL)
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
      if (is.null(combo)) return(NULL)
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
      if (is.null(combo)) return(NULL)
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
      if (is.null(combo)) return(NULL)
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
        if (is.null(combo)) return(datatable(data.frame(Mensaje = "combinacion no disponible.")))
        if (!is.null(combo$error)) {
          return(datatable(data.frame(Mensaje = combo$error)))
        }
        datatable(
          combo$data %>%
            select(Participante = participant_id, Resultado = result, `u(xi)` = uncertainty_std, `Puntaje z` = z_score, `Puntaje z Eval` = z_score_eval),
          options = list(scrollX = TRUE, pageLength = 10),
          rownames = FALSE
        ) %>%
          formatRound(columns = c("Resultado", "u(xi)", "Puntaje z"), digits = 3)
      })

      output[[paste0("z_plot_", combo_key)]] <- renderPlotly({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo) || !is.null(combo$error)) return(NULL)
        p <- plot_scores(combo$data, "z_score", combo$title, "Limites de advertencia |z|=2, accion |z|=3", "Puntaje z", warn_limits = c(-2, 2), action_limits = c(-3, 3))
        to_plotly(p)
      })

      output[[paste0("zprime_table_", combo_key)]] <- renderDataTable({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo)) return(datatable(data.frame(Mensaje = "combinacion no disponible.")))
        if (!is.null(combo$error)) {
          return(datatable(data.frame(Mensaje = combo$error)))
        }
        datatable(
          combo$data %>%
            select(Participante = participant_id, Resultado = result, `u(xi)` = uncertainty_std, `Puntaje z'` = z_prime_score, `Puntaje z' Eval` = z_prime_score_eval),
          options = list(scrollX = TRUE, pageLength = 10),
          rownames = FALSE
        ) %>%
          formatRound(columns = c("Resultado", "u(xi)", "Puntaje z'"), digits = 3)
      })

      output[[paste0("zprime_plot_", combo_key)]] <- renderPlotly({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo) || !is.null(combo$error)) return(NULL)
        p <- plot_scores(combo$data, "z_prime_score", combo$title, "Limites de advertencia |z'|=2, accion |z'|=3", "Puntaje z'", warn_limits = c(-2, 2), action_limits = c(-3, 3))
        to_plotly(p)
      })

      output[[paste0("zeta_table_", combo_key)]] <- renderDataTable({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo)) return(datatable(data.frame(Mensaje = "combinacion no disponible.")))
        if (!is.null(combo$error)) {
          return(datatable(data.frame(Mensaje = combo$error)))
        }
        datatable(
          combo$data %>%
            select(Participante = participant_id, Resultado = result, `u(xi)` = uncertainty_std, `Puntaje zeta` = zeta_score, `Puntaje zeta Eval` = zeta_score_eval),
          options = list(scrollX = TRUE, pageLength = 10),
          rownames = FALSE
        ) %>%
          formatRound(columns = c("Resultado", "u(xi)", "Puntaje zeta"), digits = 3)
      })

      output[[paste0("zeta_plot_", combo_key)]] <- renderPlotly({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo) || !is.null(combo$error)) return(NULL)
        p <- plot_scores(combo$data, "zeta_score", combo$title, "Limites de advertencia |zeta|=2, accion |zeta|=3", "Puntaje zeta", warn_limits = c(-2, 2), action_limits = c(-3, 3))
        to_plotly(p)
      })

      output[[paste0("en_table_", combo_key)]] <- renderDataTable({
        res <- scores_results_selected()
        combo <- res$combos[[combo_key]]
        if (is.null(combo)) return(datatable(data.frame(Mensaje = "combinacion no disponible.")))
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
        if (is.null(combo) || !is.null(combo$error)) return(NULL)
        p <- plot_scores(combo$data, "En_score", combo$title, "Limite de accion |En|=1", "Puntaje En", action_limits = c(-1, 1))
        to_plotly(p)
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
      return(helpText("No hay participantes disponibles para esta seleccion."))
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
          arrange(Combination_label, level) %>%
          transmute(
            Combinacion = combination,
            Analito = pollutant,
            `Esquema PT (n)` = n_lab,
            Nivel = level,
            Resultado = result,
            `x_pt` = x_pt,
            `sigma_pt` = sigma_pt,
            `u(x_pt)` = u_xpt,
            `Puntaje z` = z_score,
            `Puntaje z Eval` = z_score_eval,
            `Puntaje z'` = z_prime_score,
            `Puntaje z' Eval` = z_prime_score_eval,
            `Puntaje zeta` = zeta_score,
            `Puntaje zeta Eval` = zeta_score_eval,
            `Puntaje En` = En_score,
            `Puntaje En Eval` = En_score_eval
          )
        datatable(table_df, options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE) %>%
          formatRound(columns = c("Resultado", "x_pt", "sigma_pt", "u(x_pt)", "Puntaje z", "Puntaje z'", "Puntaje zeta", "Puntaje En"), digits = 3)
      })

      output[[plot_id]] <- renderPlotly({
        info <- participants_combined_data()
        if (!is.null(info$error)) return(NULL)
        participant_df <- info$data %>%
          filter(participant_id == pid)
        if (nrow(participant_df) == 0) return(NULL)

        plot_df <- participant_df %>%
          filter(Combination_label == "1" | Combination_label == min(Combination_label)) %>%
          head(n = n_distinct(.$level))

        level_factor <- factor(participant_df$level, levels = sort(unique(participant_df$level)))

        p_values <- ggplot(plot_df, aes(x = factor(level, levels = sort(unique(level))))) +
          geom_point(aes(y = result, color = "Participante"), size = 3) +
          geom_line(aes(y = result, group = 1, color = "Participante")) +
          geom_point(aes(y = x_pt, color = "Referencia"), size = 3) +
          geom_line(aes(y = x_pt, group = 1, color = "Referencia"), linetype = "dashed") +
          scale_color_manual(values = c("Participante" = "#1F78B4", "Referencia" = "#E31A1C")) +
          labs(title = paste("Valores vs. referencia -", pid), x = "Nivel", y = "Valor", color = NULL) +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        p_z <- ggplot(participant_df, aes(x = level_factor, y = z_score, group = combination, color = combination)) +
          geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#C0392B") +
          geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "#E67E22") +
          geom_hline(yintercept = 0, color = "grey50") +
          geom_line(position = position_dodge(width = 0.3)) +
          geom_point(size = 3, position = position_dodge(width = 0.3)) +
          labs(title = "Puntaje z", x = "Nivel", y = "Z", color = "Combinacion") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        p_zeta <- ggplot(participant_df, aes(x = level_factor, y = zeta_score, group = combination, color = combination)) +
          geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#C0392B") +
          geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "#E67E22") +
          geom_hline(yintercept = 0, color = "grey50") +
          geom_line(position = position_dodge(width = 0.3)) +
          geom_point(size = 3, position = position_dodge(width = 0.3)) +
          labs(title = "Puntaje zeta", x = "Nivel", y = "Zeta", color = "Combinacion") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        p_en <- ggplot(participant_df, aes(x = level_factor, y = En_score, group = combination, color = combination)) +
          geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "#C0392B") +
          geom_hline(yintercept = 0, color = "grey50") +
          geom_line(position = position_dodge(width = 0.3)) +
          geom_point(size = 3, position = position_dodge(width = 0.3)) +
          labs(title = "Puntaje En", x = "Nivel", y = "En", color = "Combinacion") +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "bottom")

        combined <- subplot(
          list(
            ggplotly(p_values),
            style(ggplotly(p_z), showlegend = FALSE),
            style(ggplotly(p_zeta), showlegend = FALSE),
            style(ggplotly(p_en), showlegend = FALSE)
          ),
          nrows = 2,
          shareX = FALSE,
          shareY = FALSE,
          titleY = TRUE
        ) %>%
          layout(legend = list(orientation = "h", x = 0, y = -0.1))

        apply_axis_ranges(combined, axis_ranges())
      })

      tabPanel(pid,
        h4("Resumen"),
        dataTableOutput(table_id),
        hr(),
        h4("Graficos"),
        plotlyOutput(plot_id, height = "600px")
      )
    })

    do.call(tabsetPanel, c(list(id = "scores_participants_tabs"), tab_panels))
  })

  # --- Generacion de reportes Module ---

  output$report_pollutant_selector <- renderUI({
    choices <- sort(unique(hom_data_full()$pollutant))
    selectInput("report_pollutant", "Seleccionar analito:", choices = choices)
  })

  output$report_n_selector <- renderUI({
    req(pt_prep_data(), input$report_pollutant)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$report_pollutant) %>%
      pull(n_lab) %>%
      unique() %>%
      sort()
    if (length(choices) == 0) {
      return(helpText("No hay esquemas PT disponibles para este analito."))
    }
    selectInput("report_n_lab", "Seleccionar esquema PT (n):", choices = choices)
  })

  output$report_level_selector <- renderUI({
    req(pt_prep_data(), input$report_pollutant, input$report_n_lab)
    pt_levels <- pt_prep_data() %>%
      filter(pollutant == input$report_pollutant, n_lab == input$report_n_lab) %>%
      pull(level) %>%
      unique()
    hom_levels <- hom_data_full() %>%
      filter(pollutant == input$report_pollutant) %>%
      pull(level) %>%
      unique()
    stab_levels <- stab_data_full() %>%
      filter(pollutant == input$report_pollutant) %>%
      pull(level) %>%
      unique()
    common_levels <- sort(Reduce(intersect, list(pt_levels, hom_levels, stab_levels)))
    if (length(common_levels) == 0) {
      return(helpText("No hay niveles comunes entre los datos disponibles para esta combinacion."))
    }
    selectInput("report_level", "Seleccionar nivel:", choices = common_levels)
  })

  report_preview <- reactive({
    req(input$report_pollutant, input$report_n_lab, input$report_level,
        input$report_sigma_pt, input$report_u_xpt, input$report_k)
    summary_df <- pt_prep_data()
    if (is.null(summary_df)) {
      return(list(error = "No se encontraron datos resumidos de PT (summary_n*.csv)."))
    }

    hom_res <- compute_homogeneity_metrics(input$report_pollutant, input$report_level)
    if (!is.null(hom_res$error)) {
      return(list(error = hom_res$error))
    }

    stab_res <- compute_stability_metrics(input$report_pollutant, input$report_level, hom_res)
    if (!is.null(stab_res$error)) {
      return(list(error = stab_res$error))
    }

    scores_res <- compute_scores_metrics(
      summary_df = summary_df,
      target_pollutant = input$report_pollutant,
      target_n_lab = input$report_n_lab,
      target_level = input$report_level,
      sigma_pt = input$report_sigma_pt,
      u_xpt = input$report_u_xpt,
      k = input$report_k
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
    cat(sprintf("Conclusion: %s\n", gsub("<br>", " | ", hom$conclusion)))
    cat(sprintf("ss = %.4f | c = %.4f | c_exp = %.4f\n", hom$ss, hom$c_criterion, hom$c_criterion_expanded))
    cat(sprintf("MADe = %.4f | nIQR = %.4f\n", hom$sigma_pt, hom$n_iqr))
    cat("\n--- Estabilidad ---\n")
    cat(sprintf("Conclusion: %s\n", stab$stab_conclusion))
    cat(sprintf("|y1 - y2| = %.4f | c = %.4f\n", stab$diff_hom_stab, stab$stab_c_criterion))
    cat("\n--- Puntajes PT ---\n")
    cat(sprintf("x_pt = %.4f | sigma_pt = %.4f | u_xpt = %.4f | k = %s\n",
                scores$x_pt, scores$sigma_pt, scores$u_xpt, scores$k))
    cat(sprintf("Participantes evaluados: %d\n", nrow(scores$scores)))
  })

  output$download_report <- downloadHandler(
    filename = function() {
      ext <- switch(input$report_format,
                    html = "html",
                    PDF = "PDF",
                    word = "docx")
      paste0("pt_report_", input$report_pollutant, "_", input$report_level, ".", ext)
    },
    content = function(file) {
      if (!requireNamespace("rmarkdown", quietly = TRUE)) {
        stop("El paquete 'rmarkdown' es requerido para generar el informe.")
      }
      preview <- isolate(report_preview())
      if (!is.null(preview$error)) {
        stop(preview$error)
      }

      template_path <- file.path("reports", "pt_report_template.Rmd")
      if (!file.exists(template_path)) {
        stop("No se encontro la plantilla en 'reports/pt_report_template.Rmd'.")
      }

      temp_dir <- tempdir()
      temp_report <- file.path(temp_dir, "pt_report_template.Rmd")
      file.copy(template_path, temp_report, overwrite = TRUE)

      output_format <- switch(input$report_format,
                              html = "html_document",
                              PDF = "PDF_document",
                              word = "word_document")
      ext <- switch(input$report_format,
                    html = "html",
                    PDF = "PDF",
                    word = "docx")
      output_file_name <- paste0("pt_app_report.", ext)

      params <- list(
        pollutant = preview$hom$pollutant,
        n_lab = preview$scores$n_lab,
        level = preview$hom$level,
        sigma_pt_input = input$report_sigma_pt,
        u_xpt_input = input$report_u_xpt,
        k_input = input$report_k,
        hom = preview$hom,
        stab = preview$stab,
        scores = preview$scores,
        generated_at = Sys.time()
      )

      rmarkdown::render(
        temp_report,
        output_format = output_format,
        output_file = output_file_name,
        output_dir = temp_dir,
        params = params,
        envir = new.env(parent = globalenv())
      )

      generated_path <- file.path(temp_dir, output_file_name)
      file.copy(generated_path, file, overwrite = TRUE)
    }
  )

  # --- Data Loading Status ---
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

  # --- Algoritmo A Module ---

  output$assigned_pollutant_selector <- renderUI({
    data <- pt_prep_data()
    if (is.null(data) || nrow(data) == 0) {
      return(helpText("Cargue los archivos summary_n*.csv para habilitar esta seccion."))
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
      return(helpText("No hay niveles disponibles para esta combinacion."))
    }
    choices <- subset %>%
      pull(level) %>%
      unique() %>%
      sort()
    selectInput("assigned_level", "Seleccionar nivel:", choices = choices)
  })

  algo_key <- function(pollutant, n_lab, level) paste(pollutant, n_lab, level, sep = "||")

  run_algorithm_a <- function(values, ids, max_iter = 50) {
    mask <- is.finite(values)
    values <- values[mask]
    ids <- ids[mask]

    n <- length(values)
    if (n < 3) {
      return(list(error = "El Algoritmo A requiere al menos 3 Resultados validos."))
    }

    x_star <- median(values, na.rm = TRUE)
    s_star <- 1.483 * median(abs(values - x_star), na.rm = TRUE)

    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      s_star <- sd(values, na.rm = TRUE)
    }

    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      return(list(error = "La dispersion de los datos es insuficiente para ejecutar el Algoritmo A."))
    }

    iteration_records <- list()
    converged <- FALSE

    for (iter in seq_len(max_iter)) {
      u_values <- (values - x_star) / (1.5 * s_star)
      weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))

      weight_sum <- sum(weights)
      if (!is.finite(weight_sum) || weight_sum <= 0) {
        return(list(error = "Los pesos calculados no son validos para el Algoritmo A."))
      }

      x_new <- sum(weights * values) / weight_sum
      s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)

      if (!is.finite(s_new) || s_new < .Machine$double.eps) {
        return(list(error = "El Algoritmo A colapso debido a una desviacion estandar nula."))
      }

      delta_x <- abs(x_new - x_star)
      delta_s <- abs(s_new - s_star)
      delta <- max(delta_x, delta_s)
      iteration_records[[iter]] <- data.frame(
        Iteracion = iter,
        `Valor asignado (x*)` = x_new,
        `Desviacion robusta (s*)` = s_new,
        Cambio = delta,
        check.names = FALSE
      )

      x_star <- x_new
      s_star <- s_new

      if (delta_x < 1e-03 && delta_s < 1e-03) {
        converged <- TRUE
        break
      }
    }

    iteration_df <- if (length(iteration_records) > 0) {
      bind_rows(iteration_records)
    } else {
      tibble()
    }

    u_final <- (values - x_star) / (1.5 * s_star)
    weights_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))

    weights_df <- tibble(
      Participante = ids,
      result = values,
      Peso = weights_final,
      `Residuo estandarizado` = u_final
    )

    list(
      assigned_value = x_star,
      robust_sd = s_star,
      iterations = iteration_df,
      weights = weights_df,
      converged = converged,
      effective_weight = sum(weights_final),
      error = NULL
    )
  }

  algorithm_a_selected <- reactive({
    req(algoA_trigger())
    req(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    cache <- algoA_results_cache()
    if (is.null(cache)) {
      return(list(
        error = "No se generaron Resultados. Verifique que existan datos cargados y ejecute nuevamente el Algoritmo A.",
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
        error = "No se encontraron Resultados para la combinacion seleccionada. Ejecute nuevamente el Algoritmo A.",
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
      "El algoritmo convergio cuando los cambios en x* y s* fueron menores que 0.001 (sin variacion en la tercera cifra decimal)."
    } else {
      "El algoritmo alcanzo el numero maximo de iteraciones sin estabilizar la tercera cifra decimal de x* y s*."
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
        "<strong>Desviacion robusta (s*):</strong> ", robust_sd_fmt, "<br>",
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

    p <- ggplot(res$input_data, aes(x = result)) +
      geom_histogram(aes(y = after_stat(density)), bins = 15, fill = "#5DADE2", color = "white", alpha = 0.8) +
      geom_density(color = "#1A5276", size = 1) +
      geom_vline(xintercept = res$assigned_value, color = "red", linetype = "dashed", size = 1) +
      labs(
        title = "Distribucion de Resultados por participante",
        subtitle = "La linea punteada indica el valor asignado robusto (x*)",
        x = "Resultado (media de cada participante)",
        y = "Densidad"
      ) +
      theme_minimal()
    to_plotly(p)
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
      formatRound(columns = c("Valor asignado (x*)", "Desviacion robusta (s*)", "Cambio"), digits = 9)
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

  # --- Consensus Value Module ---

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
        summarise(result = mean(mean_value, na.rm = TRUE), .groups = "drop")

      if (nrow(aggregated) == 0) {
        results[[key]] <- list(
          error = "No se encontraron Resultados de participantes para esta combinacion.",
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

      values <- aggregated$result
      x_pt2 <- median(values, na.rm = TRUE)
      mad_val <- median(abs(values - x_pt2), na.rm = TRUE)
      sigma_pt_2a <- 1.483 * mad_val
      sigma_pt_2b <- calculate_niqr(values)
      participants <- length(values)

      summary_df <- tibble::tibble(
        Statistic = c("x_pt(2) - Median", "MADe", "sigma_pt_2a (MADe)", "sigma_pt_2b (nIQR)", "Participantes"),
        Value = c(x_pt2, mad_val, sigma_pt_2a, sigma_pt_2b, participants)
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
        error = "Ejecute el calculo de valores consenso para ver Resultados.",
        summary = data.frame(),
        input_data = tibble::tibble()
      ))
    }

    req(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    cache <- consensus_results_cache()
    if (is.null(cache)) {
      return(list(
        error = "No se generaron Resultados. Verifique los datos cargados y ejecute nuevamente el calculo de valores consenso.",
        summary = data.frame(),
        input_data = tibble::tibble()
      ))
    }

    key <- algo_key(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    res <- cache[[key]]

    if (is.null(res)) {
      return(list(
        error = "No se encontraron Resultados para la seleccion actual. Ejecute nuevamente el calculo de valores consenso.",
        summary = data.frame(),
        input_data = tibble::tibble()
      ))
    }

    res
  })

  output$consensus_summary_table <- renderTable({
    res <- consensus_selected()
    if (!is.null(res$error)) {
      return(data.frame(Mensaje = res$error))
    }
    res$summary
  }, digits = 6, striped = TRUE, spacing = "l", rownames = FALSE)

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

  # --- Reference Value Module ---

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
      return(datatable(data.frame(Mensaje = "No hay datos de referencia para la seleccion indicada.")))
    }

    display <- data %>%
      transmute(
        Analito = toupper(pollutant),
        `Esquema (n)` = n_lab,
        Nivel = level,
        `Valor medio` = mean_value,
        `Desviacion estandar declarada` = sd_value
      )

    datatable(display, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE) %>%
      formatRound(columns = c("Valor medio", "Desviacion estandar declarada"), digits = 6)
  })

  # --- PT Preparation Module ---

  output$pt_pollutant_tabs <- renderUI({
    req(pt_prep_data())
    # Ensure pt_prep_data is not NULL and has rows
    if (is.null(pt_prep_data()) || nrow(pt_prep_data()) == 0) {
      return(p("No se encontraron archivos summary_n*.csv o estan vacios. Agreguelos para continuar."))
    }
    pollutants <- unique(pt_prep_data()$pollutant)
    
    tabs <- lapply(pollutants, function(p) {
      tabPanel(toupper(p),
        sidebarLayout(
          sidebarPanel(
            width = 4,
            h4(paste("Opciones para", toupper(p))),
            uiOutput(paste0("pt_n_selector_", p)),
            uiOutput(paste0("pt_level_selector_", p)),
            hr(),
            h4("Informacion resumen"),
            verbatimTextOutput(paste0("pt_summary_", p))
          ),
          mainPanel(
            width = 8,
            h4("Grafico de Resultados por participante"),
            plotlyOutput(paste0("pt_plot_", p)),
            hr(),
            h4("Tabla de datos"),
            dataTableOutput(paste0("pt_table_", p)),
            hr(),
            h4("Distribucion de Resultados"),
            fluidRow(
              column(width = 6, plotlyOutput(paste0("pt_histogram_", p))),
              column(width = 6, plotlyOutput(paste0("pt_boxplot_", p)))
            ),
            fluidRow(
              column(width = 12, plotlyOutput(paste0("pt_density_", p)))
            ),
            hr(),
            h4("Prueba de Grubbs para valores atipicos"),
            verbatimTextOutput(paste0("pt_grubbs_", p)),
            hr(),
            h4("Grafico de corrida"),
            plotlyOutput(paste0("pt_runchart_", p))
          )
        )
      )
    })
    
    do.call(tabsetPanel, c(list(id = "pt_main_tabs"), tabs))
  })

  observe({
    req(pt_prep_data())
    if (is.null(pt_prep_data()) || nrow(pt_prep_data()) == 0) return()
    
    pollutants <- unique(pt_prep_data()$pollutant)
    
    lapply(pollutants, function(p) {
      local({
        # Need a local copy for the reactive expressions
        pollutant_name <- p
        
        # N (scheme) selector
        output[[paste0("pt_n_selector_", pollutant_name)]] <- renderUI({
          choices <- unique(pt_prep_data()[pt_prep_data()$pollutant == pollutant_name, "n_lab"])
          selectInput(paste0("n_lab_", pollutant_name), "Seleccionar esquema PT (n):", choices = sort(choices))
        })
        
        # Level selector
        output[[paste0("pt_level_selector_", pollutant_name)]] <- renderUI({
          req(input[[paste0("n_lab_", pollutant_name)]])
          choices <- pt_prep_data() %>%
            filter(pollutant == pollutant_name, n_lab == input[[paste0("n_lab_", pollutant_name)]]) %>%
            pull(level) %>%
            unique()
          selectInput(paste0("level_", pollutant_name), "Seleccionar nivel:", choices = choices)
        })
        
        # Filtered data reactive
        filtered_data <- reactive({
          req(pt_prep_data(), input[[paste0("n_lab_", pollutant_name)]], input[[paste0("level_", pollutant_name)]])
          pt_prep_data() %>%
            filter(
              pollutant == pollutant_name,
              n_lab == input[[paste0("n_lab_", pollutant_name)]],
              level == input[[paste0("level_", pollutant_name)]]
            )
        })
        
        # Summary info
        output[[paste0("pt_summary_", pollutant_name)]] <- renderPrint({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          n_participants <- n_distinct(data$participant_id[data$participant_id != "ref"])
          participants <- unique(data$participant_id[data$participant_id != "ref"])
          
          cat("Analito:", pollutant_name, "\n")
          cat("Esquema PT (n_lab):", unique(data$n_lab), "\n")
          cat("Nivel:", unique(data$level), "\n")
          cat("Numero de participantes:", n_participants, "\n")
          cat("Participantes:", paste(participants, collapse = ", "))
        })
        
        # Plot
        output[[paste0("pt_plot_", pollutant_name)]] <- renderPlotly({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          p <- ggplot(data, aes(x = participant_id, y = mean_value, fill = sample_group)) +
            geom_bar(stat = "identity", position = "dodge") +
            geom_errorbar(aes(ymin = mean_value - sd_value, ymax = mean_value + sd_value), width = 0.2, position = position_dodge(0.9)) +
            labs(title = "Promedio por participante (con DE)", x = "Participante", y = "Valor medio") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
          to_plotly(p)
        })
        
        # Table
        output[[paste0("pt_table_", pollutant_name)]] <- renderDataTable({
          data <- filtered_data()
          req(nrow(data) > 0)
          datatable(data, options = list(scrollX = TRUE, pageLength = 5))
        })
        
        # Histogram
        output[[paste0("pt_histogram_", pollutant_name)]] <- renderPlotly({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          ref_value <- data %>%
            filter(participant_id == "ref") %>%
            summarise(mean_ref = mean(mean_value, na.rm = TRUE)) %>%
            pull(mean_ref)
            
          p <- ggplot(participants_data, aes(x = mean_value)) +
            geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 15, boundary = 0) +
            geom_density(alpha = 0.2, fill = "#FF6666") +
            geom_vline(xintercept = ref_value, color = "red", linetype = "dashed", size = 1) +
            labs(title = "Histograma de Resultados", subtitle = "Comparado con el valor de referencia (linea punteada)", x = "Valor medio", y = "Densidad") +
            theme_minimal()
          to_plotly(p)
        })
        
        # Boxplot
        output[[paste0("pt_boxplot_", pollutant_name)]] <- renderPlotly({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          ref_value <- data %>%
            filter(participant_id == "ref") %>%
            summarise(mean_ref = mean(mean_value, na.rm = TRUE)) %>%
            pull(mean_ref)
            
          p <- ggplot(participants_data, aes(x = "", y = mean_value)) +
            geom_boxplot(fill = "lightgreen") +
            geom_hline(yintercept = ref_value, color = "red", linetype = "dashed", size = 1) +
            labs(title = "Diagrama de caja de Resultados", subtitle = "Comparado con el valor de referencia (linea punteada)", x = "", y = "Valor medio") +
            theme_minimal()
          to_plotly(p)
        })
        
        # Density Plot
        output[[paste0("pt_density_", pollutant_name)]] <- renderPlotly({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          ref_value <- data %>%
            filter(participant_id == "ref") %>%
            summarise(mean_ref = mean(mean_value, na.rm = TRUE)) %>%
            pull(mean_ref)
            
          p <- ggplot(participants_data, aes(x = mean_value)) +
            geom_density(fill = "lightblue", alpha = 0.7) +
            geom_vline(xintercept = ref_value, color = "red", linetype = "dashed", size = 1) +
            labs(title = "Densidad de Resultados", subtitle = "Comparado con el valor de referencia (linea punteada)", x = "Valor medio", y = "Densidad") +
            theme_minimal()
          to_plotly(p)
        })
        
        # Prueba de Grubbs para valores atipicos
        output[[paste0("pt_grubbs_", pollutant_name)]] <- renderPrint({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          
          if (length(participants_data$mean_value) < 3) {
            "La prueba de Grubbs requiere al menos 3 datos."
          } else {
            grubbs.test(participants_data$mean_value)
          }
        })

        # Grafico de corrida
        output[[paste0("pt_runchart_", pollutant_name)]] <- renderPlotly({
          data <- filtered_data()
          req(nrow(data) > 0)

          participants_data <- data %>% 
            filter(participant_id != "ref")
            
          center_line <- median(participants_data$mean_value, na.rm = TRUE)
            
          p <- ggplot(participants_data, aes(x = sample_group, y = mean_value, group = 1)) +
            geom_point() +
            geom_line() +
            geom_hline(yintercept = center_line, color = "red", linetype = "dashed") +
            facet_wrap(~ participant_id) +
            labs(title = "Run chart por participante",
                 x = "Grupo de muestra",
                 y = "Valor medio") +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
          to_plotly(p)
        })
      }) # end local
    }) # end lapply
  }) # end observe
}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server, options = list(launch.browser = FALSE))








