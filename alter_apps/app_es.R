# ===================================================================
# Shiny App for PT Data Analysis (Homogeneity and Stability) - Spanish Version
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

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(

  # 1. Application Title
  titlePanel("Aplicativo de Análisis de Datos de Ensayos de Aptitud"),
  h4("Laboratorio Calaire"),

  # Collapsible panel for layout options
  checkboxInput("show_layout_options", "Mostrar Opciones de Diseño", value = FALSE),
  conditionalPanel(
    condition = "input.show_layout_options == true",
    wellPanel(
      themeSelector(),
      hr(),
      sliderInput("nav_width", "Ancho del Panel de Navegación:", min = 1, max = 5, value = 2, width = "250px"),
      sliderInput("analysis_sidebar_width", "Ancho de la Barra Lateral de Análisis:", min = 2, max = 6, value = 3, width = "250px")
    )
  ),
  hr(),

  # Dynamic UI for the main layout
  uiOutput("main_layout"),

  hr(),
  p(em("Este aplicativo fue desarrollado en el marco del proyecto «Implementación de Ensayos de Aptitud en la Matriz Aire. Caso Gases Contaminantes Criterio», ejecutado por el Laboratorio CALAIRE de la Universidad Nacional de Colombia en alianza con el Instituto Nacional de Metrología (INM)."), style="text-align:center; font-size:small;")
)

# ===================================================================
# II. Server Logic
# ===================================================================
server <- function(input, output, session) {

  # --- Data Loading and Processing ---
  hom_data_full <- read.csv("homogeneity.csv")
  stab_data_full <- read.csv("stability.csv")

  # PT Prep data
  pt_prep_data <- reactive({
    files <- c("summary_n4.csv", "summary_n7.csv", "summary_n10.csv", "summary_n13.csv")
    
    data_list <- lapply(files, function(f) {
      if (file.exists(f)) {
        df <- read.csv(f)
        # Extract n from filename
        n <- as.integer(stringr::str_extract(f, "\\d+"))
        df$n_lab <- n
        return(df)
      }
      return(NULL)
    })
    
    # Filter out NULLs if some files don't exist
    data_list <- data_list[!sapply(data_list, is.null)]
    
    if (length(data_list) == 0) {
      return(NULL)
    }
    
    do.call(rbind, data_list)
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
      "Módulos de Análisis",

      # Module 1: Homogeneity and Stability
      tabPanel("Análisis de Homogeneidad y Estabilidad",
        sidebarLayout(
          # 2.1. Input Panel (Sidebar)
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Seleccionar Datos"),
            selectInput("pollutant_analysis", "Seleccionar Contaminante:",
                        choices = c("co", "no", "no2", "o3", "so2")),
            hr(),
            h4("2. Seleccionar Parámetros"),
            # Dynamic UI to select the level
            uiOutput("level_selector"),

            h4("3. Ejecutar Análisis"),
            # Button to run the analysis
            actionButton("run_analysis", "Ejecutar Análisis",
                         class = "btn-primary btn-block"),

            hr(),
            p("Este aplicativo evalúa la homogeneidad y estabilidad del ítem de ensayo de acuerdo a los principios de la ISO 13528:2022.")
          ),

          # 2.2. Main Panel for Results
          mainPanel(
            width = analysis_main_w,
            # Outputs organized in tabs
            tabsetPanel(
              id = "analysis_tabs",

              # Tab 1: Data Preview
              tabPanel("Vista Previa de Datos",
                       h4("Vista Previa de Datos de Entrada"),
                       p("Esta tabla muestra los datos para el contaminante seleccionado."),
                       h5("Datos de Homogeneidad"),
                       dataTableOutput("raw_data_preview"),
                       hr(),
                       h5("Datos de Estabilidad"),
                       dataTableOutput("stability_data_preview"),
                       hr(),
                       h4("Distribución de Datos"),
                       p("El histograma y el diagrama de caja a continuación muestran la distribución de todos los resultados de las columnas 'sample_*' para el nivel seleccionado."),
                       fluidRow(
                         column(width = 6,
                                plotOutput("results_histogram")
                         ),
                         column(width = 6,
                                plotOutput("results_boxplot")
                         )
                       ),
                       hr(),
                       h4("Validación de Datos"),
                       verbatimTextOutput("validation_message")
              ),

              # Tab 2: Homogeneity Assessment
              tabPanel("Evaluación de Homogeneidad",
                       h4("Conclusión"),
                       uiOutput("homog_conclusion"),
                       hr(),
                       h4("Vista Previa de Datos de Homogeneidad (Nivel y Primera Muestra)"),
                       dataTableOutput("homogeneity_preview_table"),
                       hr(),
                       h4("Cálculos de Estadísticas Robustas"),
                       tableOutput("robust_stats_table"),
                       verbatimTextOutput("robust_stats_summary"),
                       hr(),
                       h4("Componentes de Varianza"),
                       p("Desviaciones estándar estimadas a partir del cálculo manual."),
                       tableOutput("variance_components"),
                       hr(),
                       h4("Cálculos por Ítem"),
                       p("Esta tabla muestra los cálculos para cada ítem (fila) en el conjunto de datos para el nivel seleccionado, incluyendo el promedio y el rango de las mediciones."),
                       tableOutput("details_per_item_table"),
                       hr(),
                       h4("Estadísticas de Resumen"),
                       p("Esta tabla muestra las estadísticas generales para la evaluación de la homogeneidad."),
                       tableOutput("details_summary_stats_table")
              ),

              # Tab 3: Stability Assessment
              tabPanel("Evaluación de Estabilidad",
                       h4("Conclusión"),
                       uiOutput("homog_conclusion_stability"),
                       hr(),
                       h4("Componentes de Varianza"),
                       p("Desviaciones estándar estimadas a partir del cálculo manual para el conjunto de datos de estabilidad."),
                       tableOutput("variance_components_stability"),
                       hr(),
                       h4("Cálculos por Ítem"),
                       p("Esta tabla muestra los cálculos para cada ítem (fila) en el conjunto de datos de estabilidad."),
                       tableOutput("details_per_item_table_stability"),
                       hr(),
                       h4("Estadísticas de Resumen"),
                       p("Esta tabla muestra las estadísticas generales para el conjunto de datos de estabilidad."),
                       tableOutput("details_summary_stats_table_stability")
              )
            )
          )
        )
      ),

      # Module 2: PT Preparation
      tabPanel("Preparación de EA",
        h3("Análisis de Esquemas de Ensayos de Aptitud"),
        p("Análisis de los resultados de los participantes de diferentes esquemas de EA, basado en los archivos de resumen."),
        uiOutput("pt_pollutant_tabs")
      ),

      # Module 3: PT Scores
      tabPanel("Puntajes de EA",
        sidebarLayout(
          sidebarPanel(
            width = 4,
            h4("1. Seleccionar Datos"),
            uiOutput("scores_pollutant_selector"),
            uiOutput("scores_n_selector"),
            uiOutput("scores_level_selector"),
            hr(),
            h4("2. Fijar Parámetros"),
            p("Parámetros basados en ISO 13528. Ajustar según sea necesario."),
            numericInput("scores_sigma_pt", "Desv. Est. para EA (sigma_pt):", value = 5, step = 0.1),
            numericInput("scores_u_xpt", "Incertidumbre Est. del Valor Asignado (u_xpt):", value = 0.5, step = 0.01),
            numericInput("scores_k", "Factor de Cobertura (k) para Puntaje En:", value = 2, min = 1, step = 1)
          ),
          mainPanel(
            width = 8,
            tabsetPanel(
              id = "scores_tabs",
              tabPanel("Tabla de Puntajes",
                       h4("Puntajes de Aptitud Calculados"),
                       dataTableOutput("scores_table"),
                       hr(),
                       h4("Resumen de Entradas"),
                       verbatimTextOutput("scores_inputs_summary")
              ),
              tabPanel("Gráfico Puntaje Z",
                       plotOutput("z_score_plot")
              ),
              tabPanel("Gráfico Puntaje Z'",
                       plotOutput("z_prime_score_plot")
              ),
              tabPanel("Gráfico Puntaje Zeta",
                       plotOutput("zeta_score_plot")
              ),
              tabPanel("Gráfico Puntaje En",
                       plotOutput("en_score_plot")
              )
            )
          )
        )
      )
    )
  })

  # R1: Reactive for Homogeneity Data
  raw_data <- reactive({
    req(input$pollutant_analysis)
    hom_data_full %>%
      filter(pollutant == input$pollutant_analysis) %>%
      select(-pollutant) %>%
      pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
  })

  # R1.6: Reactive for Stability Data
  stability_data_raw <- reactive({
    req(input$pollutant_analysis)
    stab_data_full %>%
      filter(pollutant == input$pollutant_analysis) %>%
      select(-pollutant) %>%
      pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
  })

  # R2: Dynamic Generation of the Level Selector
  output$level_selector <- renderUI({
    data <- raw_data()
    if ("level" %in% names(data)) {
      levels <- unique(data$level)
      selectInput("target_level", "2. Seleccionar Nivel de EA", choices = levels, selected = levels[1])
    } else {
      p("Columna 'level' no encontrada en los datos cargados.")
    }
  })

  # R3: Homogeneity Execution (Triggered by button)
  homogeneity_run <- eventReactive(input$run_analysis, {
    req(raw_data(), input$target_level)
    homogeneity_data <- raw_data()
    target_level <- input$target_level

    # Prepare data for analysis
    homogeneity_level_data <- homogeneity_data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(homogeneity_level_data)
    m <- ncol(homogeneity_level_data)

    if (m < 2) {
        return(list(error = "No hay suficientes réplicas (se requieren al menos 2) para la evaluación de homogeneidad."))
    }
    if (g < 2) {
        return(list(error = "No hay suficientes ítems (se requieren al menos 2) para la evaluación de homogeneidad."))
    }

    # Create the intermediate calculations table data
    intermediate_df <- if (m == 2) {
      s1 <- homogeneity_level_data[[1]]
      s2 <- homogeneity_level_data[[2]]
      homogeneity_level_data %>%
        mutate(
          Item = row_number(),
          average = (s1 + s2) / 2,
          range = abs(s1 - s2)
        ) %>%
        select(Item, everything())
    } else {
      homogeneity_level_data %>%
        mutate(
          Item = row_number(),
          average = rowMeans(., na.rm = TRUE),
          range = apply(., 1, function(x) max(x, na.rm=TRUE) - min(x, na.rm=TRUE))
        ) %>%
        select(Item, everything())
    }

    # Now create the long data format for calculations
    hom_data <- homogeneity_level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    # Calculate sigma_pt as MADe from the first sample column ('sample_1')
    if (!"sample_1" %in% names(homogeneity_level_data)) {
        return(list(error = "Columna 'sample_1' no encontrada. Se requiere para calcular sigma_pt."))
    }
    first_sample_results <- homogeneity_level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff

    # Robust statistics (for Alternative Method 2 and for display)
    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)



# --- Manual ANOVA Calculation ---
    # Calculate mean, variance, and range (difference) for each item
    hom_item_stats <- hom_data %>%
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE)
      )

    # Grand mean
    hom_x_t_bar <- mean(hom_item_stats$mean, na.rm = TRUE)

    # Variance of item means
    hom_s_x_bar_sq <- var(hom_item_stats$mean, na.rm = TRUE)
    hom_s_xt <- sqrt(hom_s_x_bar_sq)

    # Mean of item variances (within-sample variance)

    hom_wt = abs(hom_item_stats$diff)
    hom_sw <- sqrt(sum(hom_wt^2) / (2 * length(hom_wt)))

    # Between-sample variance
    # User requested ABS; standard practice is max(0, ...)
    hom_ss_sq <- abs(hom_s_x_bar_sq - ((hom_sw^2) / 2))
    hom_ss <- sqrt(hom_ss_sq)

    # For display purposes, we can create a data frame that mimics the ANOVA table
    hom_anova_summary_df <- data.frame(
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(hom_s_x_bar_sq * m * (g - 1), hom_sw^2 * g * (m - 1)),
      "Mean Sq" = c(hom_s_x_bar_sq * m, hom_sw^2),
      check.names = FALSE
    )

    rownames(hom_anova_summary_df) <- c("Item", "Residuals")

    # For the list returned by the reactive
    hom_anova_summary <- hom_anova_summary_df

    # Assessment Criterion (for ANOVA method)
    hom_sigma_pt <- mad_e
    hom_c_criterion <- 0.3 * hom_sigma_pt
    hom_sigma_allowed_sq <- hom_c_criterion^2

    # Expanded criterion
    hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)

    # First comparison: ss vs c_criterion (0.3 * sigma_pt)
    if (hom_ss <= hom_c_criterion) {
      hom_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-success"
    } else {
      hom_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-warning"
    }

    # Second comparison: ss vs c_expanded
    if (hom_ss <= hom_c_criterion_expanded) {
      hom_conclusion2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion_expanded)
    } else {
      hom_conclusion2 <- sprintf("ss (%.4f) > c_expanded (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion_expanded)
    }

    # Combine conclusions
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
      error = NULL
    )
  })

  # R3.5: Stability Data Homogeneity Execution (Triggered by button)
  homogeneity_run_stability <- eventReactive(input$run_analysis, {
    # Add dependency on homogeneity_run() to get its results
    req(stability_data_raw(), input$target_level, homogeneity_run())
    hom_results <- homogeneity_run()
    hom_x_t_bar <- hom_results$general_mean

    data <- stability_data_raw()
    target_level <- input$target_level

    # Prepare data for analysis
    level_data <- data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) {
        return(list(error = "No hay suficientes réplicas (se requieren al menos 2) para la evaluación de homogeneidad de datos de estabilidad."))
    }
    if (g < 2) {
        return(list(error = "No hay suficientes ítems (se requieren al menos 2) para la evaluación de homogeneidad de datos de estabilidad."))
    }

    # Create the intermediate calculations table data
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
          range = apply(., 1, function(x) max(x, na.rm=TRUE) - min(x, na.rm=TRUE))
        ) %>%
        select(Item, everything())
    }

    # Now create the long data format for calculations
    stab_data <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    # Calculate sigma_pt as MADe from the first sample column ('sample_1')
    if (!"sample_1" %in% names(level_data)) {
        return(list(error = "Columna 'sample_1' no encontrada. Se requiere para calcular sigma_pt para datos de estabilidad."))
    }
    first_sample_results <- level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff

    # Robust statistics (for Alternative Method 2 and for display)
    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)



# --- Manual ANOVA Calculation (for Stability Data) ---
    # Calculate mean, variance, and range (difference) for each item
    stab_item_stats <- stab_data %>%
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE)
      )

    # Grand mean
    stab_x_t_bar <- mean(stab_item_stats$mean, na.rm = TRUE)

    # Absolute difference between the two general means
    diff_hom_stab <- abs(stab_x_t_bar - hom_x_t_bar)
    

    # Variance of item means
    stab_s_x_bar_sq <- var(stab_item_stats$mean, na.rm = TRUE)
    stab_s_xt <- sqrt(stab_s_x_bar_sq)

    # Mean of item variances (within-sample variance)

    stab_wt = abs(stab_item_stats$diff)
    stab_sw <- sqrt(sum(stab_wt^2) / (2 * length(stab_wt)))

    # Between-sample variance
    # User requested ABS; standard practice is max(0, ...)
    stab_ss_sq <- abs(stab_s_xt^2 - ((stab_sw^2) / 2))
    stab_ss <- sqrt(stab_ss_sq)

    # For display purposes, we can create a data frame that mimics the ANOVA table
    stab_anova_summary_df <- data.frame(
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(stab_s_x_bar_sq * m * (g - 1), stab_sw^2 * g * (m - 1)),
      "Mean Sq" = c(stab_s_x_bar_sq * m, stab_sw^2),
      check.names = FALSE
    )

    rownames(stab_anova_summary_df) <- c("Item", "Residuals")

    # For the list returned by the reactive
    stab_anova_summary <- stab_anova_summary_df

    # Assessment Criterion (for ANOVA method)
    stab_sigma_pt <- mad_e
    stab_c_criterion <- 0.3 * hom_results$sigma_pt
    stab_sigma_allowed_sq <- stab_c_criterion^2

    # Expanded criterion
    stab_c_criterion_expanded <- sqrt(stab_sigma_allowed_sq * 1.88 + (stab_sw^2) * 1.01)

    # First comparison: ss vs c_criterion (0.3 * sigma_pt)
    if (diff_hom_stab <= stab_c_criterion) {
      stab_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-success"
    } else {
      stab_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-warning"
    }



    # Combine conclusions
    stab_conclusion <- paste(stab_conclusion1)
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
      stab_u_xpt = u_xpt,
      n_robust = n_robust,
      stab_item_means = stab_item_stats$mean,
      stab_general_mean = stab_x_t_bar,
      stab_sd_of_means = stab_s_xt,
      stab_s_x_bar_sq = stab_s_x_bar_sq,
      stab_s_w_sq = stab_sw^2,
      stab_intermediate_df = intermediate_df,
      error = NULL
    )
  })

  # R4: Stability Execution (Triggered by button)
  stability_run <- eventReactive(input$run_analysis, {
    # Depend on both homogeneity runs
    req(homogeneity_run(), homogeneity_run_stability())
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
    fmt <- "%.9f"

    details_text <- sprintf(
      paste("Media de Datos de Homogeneidad (y1):", fmt, "\nMedia de Datos de Estabilidad (y2):", fmt, "\nDiferencia Absoluta Observada:", fmt, "\nCriterio de Estabilidad (0.3 * sigma_pt):", fmt),
      y1, y2, diff_observed, stab_criterion_value
    )

    if (diff_observed <= stab_criterion_value) {
      conclusion <- "Conclusión: El ítem es adecuadamente estable."
      conclusion_class <- "alert alert-success"
    } else {
      conclusion <- "Conclusión: ADVERTENCIA: El ítem puede ser inestable."
      conclusion_class <- "alert alert-warning"
    }

    # For the t-test, we need the raw results from both datasets for the selected level
    target_level <- input$target_level
    
    data_t1_results <- raw_data() %>%
      filter(level == target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), values_to = "Result") %>%
      pull(Result)

    data_t2_results <- stability_data_raw() %>%
      filter(level == target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), values_to = "Result") %>%
      pull(Result)

    # T-test
    t_test_result <- t.test(data_t1_results, data_t2_results)

    if (t_test_result$p.value > 0.05) {
      ttest_conclusion <- "Prueba T: No se detectó diferencia estadísticamente significativa entre los dos conjuntos de datos (p > 0.05), lo que apoya la estabilidad."
    } else {
      ttest_conclusion <- "Prueba T: Se detectó una diferencia estadísticamente significativa entre los dos conjuntos de datos (p <= 0.05), lo que indica una posible inestabilidad."
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
    df <- head(raw_data(), 10)
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    fmt <- "%.9f"
    df <- df %>%
      mutate(across(all_of(numeric_cols), ~ sprintf(fmt, .x)))
    datatable(df, options = list(scrollX = TRUE))
  })
  
  output$stability_data_preview <- renderDataTable({
    req(stability_data_raw())
    df <- head(stability_data_raw(), 10)
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    fmt <- "%.9f"
    df <- df %>%
      mutate(across(all_of(numeric_cols), ~ sprintf(fmt, .x)))
    datatable(df, options = list(scrollX = TRUE))
  })


  # Output: Validation Message
  output$validation_message <- renderPrint({
    data <- raw_data()
    cat("Datos cargados exitosamente.\n")
    cat(paste("Dimensiones:", paste(dim(data), collapse = " x "), "\n"))

    required_cols <- c("level")
    has_samples <- any(str_detect(names(data), "sample_"))

    if(!all(required_cols %in% names(data))) {
        cat(paste("ERROR: Falta(n) columna(s) requerida(s):", paste(setdiff(required_cols, names(data)), collapse=", "), "\n"))
    } else {
        cat("Se encontró la columna 'level'.\n")
    }

    if(!has_samples) {
        cat("ERROR: No se encontraron columnas con prefijo 'sample_'. Son necesarias para el análisis.\n")
    } else {
        cat("Se encontraron columnas 'sample_*'.\n")
    }
  })

  # Reactive expression for plotting data
  plot_data_long <- reactive({
    req(raw_data())
    if (!"level" %in% names(raw_data())) return(NULL)
    raw_data() %>%
      select(level, starts_with("sample_")) %>%
      pivot_longer(-level, names_to = "sample", values_to = "result")
  })

  # Output: Histogram
  output$results_histogram <- renderPlot({
    plot_data <- plot_data_long()
    req(plot_data)
    ggplot(plot_data, aes(x = result)) + 
      geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 20) +
      geom_density(alpha = 0.4, fill = "lightblue") +
      facet_wrap(~level, scales = "free") +
      labs(title = "Distribución por Nivel",
           x = "Resultado", y = "Densidad") +
      theme_minimal()
  })

  # Output: Boxplot
  output$results_boxplot <- renderPlot({
    plot_data <- plot_data_long()
    req(plot_data)
    ggplot(plot_data, aes(x = "", y = result)) + 
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      facet_wrap(~level, scales = "free") +
      labs(title = "Diagrama de Caja por Nivel",
           x = NULL, y = "Resultado") +
      theme_minimal()
  })

  # Output: Homogeneity Data Preview
  output$homogeneity_preview_table <- renderDataTable({
    req(raw_data(), input$target_level)
    homogeneity_data <- raw_data()
    # Find the first column that starts with "sample_"
    first_sample_col <- names(homogeneity_data)[grep("sample_", names(homogeneity_data))][1]
    homogeneity_data %>%
      filter(level == input$target_level) %>%
      select(level, all_of(first_sample_col))
  })

  # Output: Robust Stats Table
  output$robust_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        `Resultados.Primera.Muestra` = format(res$first_sample_results, digits = 15, scientific = FALSE),
        `Dif.Abs.de.Mediana` = format(res$abs_diff_from_median, digits = 15, scientific = FALSE)
      )
    }
  }, spacing = "l")

  # Output: Robust Stats Summary
  output$robust_stats_summary <- renderPrint({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      cat(paste("Valor de la Mediana:", format(res$median_val, digits = 15, scientific = FALSE), "\n"))
      cat(paste("Mediana de la Diferencia Absoluta:", format(res$median_abs_diff, digits = 15, scientific = FALSE), "\n"))
      cat(paste("MADe (sigma_pt):", format(res$sigma_pt, digits = 15, scientific = FALSE), "\n"))
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
        df <- data.frame(
          Componente = c("Valor Asignado (xpt)",
                        "DE Robusta (sigma_pt)",
                        "Incertidumbre del Valor Asignado (u_xpt)",
                        "DE Entre-Muestras (ss)",
                        "DE Intra-Muestra (sw)",
                        "---",
                        "Criterio c",
                        "Criterio c (expandido)"),
          Valor = c(
            format(c(res$median_val, res$sigma_pt, res$u_xpt, res$ss, res$sw), digits = 15, scientific = FALSE),
            "",
            format(c(res$c_criterion, res$c_criterion_expanded), digits = 15, scientific = FALSE)
          )
        )
        df
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
          cat(res$ttest_conclusion, "\n\n")
          print(res$ttest_summary, digits = 9)
      }
  })

  # Output: Details per item table
  output$details_per_item_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      res$intermediate_df
    }
  }, spacing = "l", digits = 15)

  # Output: Details summary stats table
  output$details_summary_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        Parámetro = c("Media General",
                      "DE de Medias",
                      "Varianza de Medias (s_x_bar_sq)",
                      "sw",
                      "Varianza Intra-Muestra (s_w_sq)",
                      "ss",
                      "---",
                      "Valor Asignado (xpt)",
                      "Mediana de Diferencias Absolutas",
                      "Número de Ítems (g)",
                      "Número de Réplicas (m)",
                      "DE Robusta (MADe)",
                      "Incertidumbre del Valor Asignado (u_xpt)",
                      "---",
                      "Criterio c",
                      "Criterio c (expandido)"),
        Valor = c(
          format(c(res$general_mean, res$sd_of_means, res$s_x_bar_sq, res$sw, res$s_w_sq, res$ss), digits = 15, scientific = FALSE),
          "",
          format(c(res$median_val, res$median_abs_diff, res$g, res$m, res$sigma_pt, res$u_xpt), digits = 15, scientific = FALSE),
          "",
          format(c(res$c_criterion, res$c_criterion_expanded), digits = 15, scientific = FALSE)
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
        df <- data.frame(
          Componente = c("Valor Asignado (xpt)",
                        "DE Robusta (sigma_pt)",
                        "Incertidumbre del Valor Asignado (u_xpt)"),
          Valor = c(
            format(c(res$stab_median_val, res$stab_sigma_pt, res$stab_u_xpt), digits = 15, scientific = FALSE)
          )
        )
        df
    }
  })

  # Output: Details per item table for Stability Data
  output$details_per_item_table_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
      res$stab_intermediate_df
    }
  }, spacing = "l", digits = 15)

  # Output: Details summary stats table for Stability Data
  output$details_summary_stats_table_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
      data.frame(
        Parámetro = c("Media General",
                      "Diferencia Absoluta con Media General",
                      "DE de Medias",
                      "Varianza de Medias (s_x_bar_sq)",
                      "sw",
                      "Varianza Intra-Muestra (s_w_sq)",
                      "ss",
                      "---",
                      "Valor Asignado (xpt)",
                      "Mediana de Diferencias Absolutas",
                      "Número de Ítems (g)",
                      "Número de Réplicas (m)",
                      "DE Robusta (MADe)",
                      "Incertidumbre del Valor Asignado (u_xpt)",
                      "---",
                      "Criterio c",
                      "Criterio c (expandido)"),
        Valor = c(
          format(c(res$stab_general_mean, res$diff_hom_stab, res$stab_sd_of_means, res$stab_s_x_bar_sq, res$stab_sw, res$stab_s_w_sq, res$stab_ss), digits = 15, scientific = FALSE),
          "",
          format(c(res$stab_median_val, res$stab_median_abs_diff, res$g, res$m, res$stab_sigma_pt, res$stab_u_xpt), digits = 15, scientific = FALSE),
          "",
          format(c(res$stab_c_criterion, res$stab_c_criterion_expanded), digits = 15, scientific = FALSE)
        )
      )
    }
  }, spacing = "l")

  # --- PT Scores Module ---

  # Dynamic UI for PT Scores selectors
  output$scores_pollutant_selector <- renderUI({
    req(pt_prep_data())
    choices <- unique(pt_prep_data()$pollutant)
    selectInput("scores_pollutant", "Seleccionar Contaminante:", choices = choices)
  })

  output$scores_n_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$scores_pollutant) %>%
      pull(n_lab) %>%
      unique() %>%
      sort()
    selectInput("scores_n_lab", "Seleccionar Esquema de EA (por n):", choices = choices)
  })

  output$scores_level_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$scores_pollutant, n_lab == input$scores_n_lab) %>%
      pull(level) %>%
      unique()
    selectInput("scores_level", "Seleccionar Nivel:", choices = choices)
  })

  # Reactive for score calculation
  scores_run <- reactive({
    req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab, input$scores_level,
        input$scores_sigma_pt, input$scores_u_xpt, input$scores_k)
    data <- pt_prep_data() %>%
      filter(
        pollutant == input$scores_pollutant,
        n_lab == input$scores_n_lab,
        level == input$scores_level
      )

    if (nrow(data) == 0) {
      return(list(error = "No se encontraron datos para los criterios seleccionados."))
    }

    ref_data <- data %>% filter(participant_id == "ref")
    participant_data <- data %>% filter(participant_id != "ref")

    if (nrow(ref_data) == 0) {
      return(list(error = "No se encontraron datos de referencia ('ref' participante) para este nivel."))
    }
    if (nrow(participant_data) == 0) {
      return(list(error = "No se encontraron datos de participantes para este nivel."))
    }

    # Use the mean of reference values as x_pt
    x_pt <- mean(ref_data$mean_value, na.rm = TRUE)

    # Rename for clarity inside this reactive, matching scores.md
    participant_data <- participant_data %>%
      rename(result = mean_value, uncertainty_std = sd_value)

    sigma_pt_adjusted <- input$scores_sigma_pt
    u_xpt <- input$scores_u_xpt
    k <- input$scores_k

    final_scores <- participant_data %>%
      mutate(
        # z-Score
        z_score = (result - x_pt) / sigma_pt_adjusted,
        # z'-Score
        z_prime_score = (result - x_pt) / sqrt(sigma_pt_adjusted^2 + u_xpt^2),
        # Zeta Score
        zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
        # En-Score
        U_xi = k * uncertainty_std,
        U_xpt = k * u_xpt,
        En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
      ) %>%
      mutate(
        z_score_eval = case_when(
          abs(z_score) <= 2 ~ "Satisfactorio",
          abs(z_score) > 2 & abs(z_score) < 3 ~ "Cuestionable",
          abs(z_score) >= 3 ~ "Insatisfactorio",
          TRUE ~ "N/A"
        ),
        z_prime_score_eval = case_when(
          abs(z_prime_score) <= 2 ~ "Satisfactorio",
          abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Cuestionable",
          abs(z_prime_score) >= 3 ~ "Insatisfactorio",
          TRUE ~ "N/A"
        ),
        zeta_score_eval = case_when(
          abs(zeta_score) <= 2 ~ "Satisfactorio",
          abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Cuestionable",
          abs(zeta_score) >= 3 ~ "Insatisfactorio",
          TRUE ~ "N/A"
        ),
        En_score_eval = case_when(
          abs(En_score) <= 1 ~ "Satisfactorio",
          abs(En_score) > 1 ~ "Insatisfactorio",
          TRUE ~ "N/A"
        )
      )

    list(
      scores = final_scores,
      x_pt = x_pt,
      sigma_pt = sigma_pt_adjusted,
      u_xpt = u_xpt,
      k = k,
      error = NULL
    )
  })

  # Output: Scores Table
  output$scores_table <- renderDataTable({
    res <- scores_run()
    if (!is.null(res$error)) {
      return(datatable(data.frame(Error = res$error)))
    }

    display_df <- res$scores %>%
      select(
        `Participante` = participant_id,
        `Resultado` = result,
        `u(xi)` = uncertainty_std,
        `Puntaje-z` = z_score,
        `Eval P-z` = z_score_eval,
        `Puntaje-z'` = z_prime_score,
        `Eval P-z'` = z_prime_score_eval,
        `Puntaje-zeta` = zeta_score,
        `Eval P-zeta` = zeta_score_eval,
        `Puntaje-En` = En_score,
        `Eval P-En` = En_score_eval
      )

    datatable(display_df, options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE) %>%
      formatRound(columns = c('Resultado', 'u(xi)', 'Puntaje-z', 'Puntaje-z\'', 'Puntaje-zeta', 'Puntaje-En'), digits = 3) %>%
      formatStyle(
        'Eval P-z',
        backgroundColor = styleEqual(c("Satisfactorio", "Cuestionable", "Insatisfactorio"), c("#d4edda", "#fff3cd", "#f8d7da"))
      ) %>%
      formatStyle(
        'Eval P-z\'',
        backgroundColor = styleEqual(c("Satisfactorio", "Cuestionable", "Insatisfactorio"), c("#d4edda", "#fff3cd", "#f8d7da"))
      ) %>%
      formatStyle(
        'Eval P-zeta',
        backgroundColor = styleEqual(c("Satisfactorio", "Cuestionable", "Insatisfactorio"), c("#d4edda", "#fff3cd", "#f8d7da"))
      ) %>%
      formatStyle(
        'Eval P-En',
        backgroundColor = styleEqual(c("Satisfactorio", "Insatisfactorio"), c("#d4edda", "#f8d7da"))
      )
  })
  # Output: Inputs Summary
  output$scores_inputs_summary <- renderPrint({
    res <- scores_run()
    req(res)
    if (!is.null(res$error)) {
      cat(res$error)
    } else {
      cat(sprintf("Valor Asignado (x_pt): %.4f\n", res$x_pt))
      cat(sprintf("Desviación Estándar para EA (sigma_pt): %.4f\n", res$sigma_pt))
      cat(sprintf("Incertidumbre Estándar del Valor Asignado (u_xpt): %.4f\n", res$u_xpt))
      cat(sprintf("Factor de Cobertura (k) para Puntaje En: %d\n", res$k))
    }
  })

  # Output: Z-Score Plot
  output$z_score_plot <- renderPlot({
    res <- scores_run()
    req(res, is.null(res$error))

    ggplot(res$scores, aes(x = reorder(participant_id, z_score), y = z_score)) + 
      geom_hline(yintercept = c(-3, -2, 2, 3), linetype = "dashed", color = c("red", "orange", "orange", "red")) + 
      geom_hline(yintercept = 0, linetype = "solid", color = "grey") + 
      geom_point(size = 3, color = "blue") + 
      geom_segment(aes(xend = reorder(participant_id, z_score), yend = 0), color = "blue") + 
      labs(
        title = "Puntajes Z por Participante",
        subtitle = "Límites de advertencia en |z|=2 (naranja), Límites de acción en |z|=3 (rojo)",
        x = "Participante",
        y = "Puntaje Z"
      ) + 
      theme_minimal() + 
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  # Output: Z'-Score Plot
  output$z_prime_score_plot <- renderPlot({
    res <- scores_run()
    req(res, is.null(res$error))

    ggplot(res$scores, aes(x = reorder(participant_id, z_prime_score), y = z_prime_score)) + 
      geom_hline(yintercept = c(-3, -2, 2, 3), linetype = "dashed", color = c("red", "orange", "orange", "red")) + 
      geom_hline(yintercept = 0, linetype = "solid", color = "grey") + 
      geom_point(size = 3, color = "cyan4") + 
      geom_segment(aes(xend = reorder(participant_id, z_prime_score), yend = 0), color = "cyan4") + 
      labs(
        title = "Puntajes Z' por Participante",
        subtitle = "Límites de advertencia en |z'|=2 (naranja), Límites de acción en |z'|=3 (rojo)",
        x = "Participante",
        y = "Puntaje Z'"
      ) + 
      theme_minimal() + 
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  # Output: Zeta-Score Plot
  output$zeta_score_plot <- renderPlot({
    res <- scores_run()
    req(res, is.null(res$error))

    ggplot(res$scores, aes(x = reorder(participant_id, zeta_score), y = zeta_score)) + 
      geom_hline(yintercept = c(-3, -2, 2, 3), linetype = "dashed", color = c("red", "orange", "orange", "red")) + 
      geom_hline(yintercept = 0, linetype = "solid", color = "grey") + 
      geom_point(size = 3, color = "darkgreen") + 
      geom_segment(aes(xend = reorder(participant_id, zeta_score), yend = 0), color = "darkgreen") + 
      labs(
        title = "Puntajes Zeta por Participante",
        subtitle = "Límites de advertencia en |ζ|=2 (naranja), Límites de acción en |ζ|=3 (rojo)",
        x = "Participante",
        y = "Puntaje Zeta (ζ)"
      ) + 
      theme_minimal() + 
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  # Output: En-Score Plot
  output$en_score_plot <- renderPlot({
    res <- scores_run()
    req(res, is.null(res$error))

    ggplot(res$scores, aes(x = reorder(participant_id, En_score), y = En_score)) + 
      geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "red") + 
      geom_hline(yintercept = 0, linetype = "solid", color = "grey") + 
      geom_point(size = 3, color = "purple") + 
      geom_segment(aes(xend = reorder(participant_id, En_score), yend = 0), color = "purple") + 
      labs(
        title = "Puntajes En por Participante",
        subtitle = "Límites de acción en |En|=1 (rojo)",
        x = "Participante",
        y = "Puntaje En"
      ) + 
      theme_minimal() + 
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  # --- PT Preparation Module ---

  output$pt_pollutant_tabs <- renderUI({
    req(pt_prep_data())
    # Ensure pt_prep_data is not NULL and has rows
    if (is.null(pt_prep_data()) || nrow(pt_prep_data()) == 0) {
      return(p("No se encontraron archivos de resumen o los archivos están vacíos. Por favor, agregue archivos summary_n*.csv."))
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
            h4("Información de Resumen"),
            verbatimTextOutput(paste0("pt_summary_", p))
          ),
          mainPanel(
            width = 8,
            h4("Gráfico de Resultados de Participantes"),
            plotOutput(paste0("pt_plot_", p)),
            hr(),
            h4("Tabla de Datos"),
            dataTableOutput(paste0("pt_table_", p)),
            hr(),
            h4("Distribución de Resultados"),
            fluidRow(
              column(width = 6, plotOutput(paste0("pt_histogram_", p))),
              column(width = 6, plotOutput(paste0("pt_boxplot_", p)))
            ),
            fluidRow(
              column(width = 12, plotOutput(paste0("pt_density_", p)))
            ),
            hr(),
            h4("Prueba de Grubbs para Valores Atípicos"),
            verbatimTextOutput(paste0("pt_grubbs_", p)),
            hr(),
            h4("Gráfico de Rachas"),
            plotOutput(paste0("pt_runchart_", p))
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
          selectInput(paste0("n_lab_", pollutant_name), "Seleccionar Esquema de EA (por n):", choices = sort(choices))
        })
        
        # Level selector
        output[[paste0("pt_level_selector_", pollutant_name)]] <- renderUI({
          req(input[[paste0("n_lab_", pollutant_name)]])
          choices <- pt_prep_data() %>%
            filter(pollutant == pollutant_name, n_lab == input[[paste0("n_lab_", pollutant_name)]]) %>%
            pull(level) %>%
            unique()
          selectInput(paste0("level_", pollutant_name), "Seleccionar Nivel:", choices = choices)
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
          
          cat("Contaminante:", pollutant_name, "\n")
          cat("Esquema de EA (n_lab):", unique(data$n_lab), "\n")
          cat("Nivel:", unique(data$level), "\n")
          cat("Número de Participantes:", n_participants, "\n")
          cat("Participantes:", paste(participants, collapse = ", "))
        })
        
        # Plot
        output[[paste0("pt_plot_", pollutant_name)]] <- renderPlot({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          ggplot(data, aes(x = participant_id, y = mean_value, fill = sample_group)) + 
            geom_bar(stat = "identity", position = "dodge") + 
            geom_errorbar(aes(ymin = mean_value - sd_value, ymax = mean_value + sd_value), width = 0.2, position = position_dodge(0.9)) + 
            labs(title = "Valores Medios de Participantes con DE", x = "Participante", y = "Valor Medio") + 
            theme_minimal() + 
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
        })
        
        # Table
        output[[paste0("pt_table_", pollutant_name)]] <- renderDataTable({
          data <- filtered_data()
          req(nrow(data) > 0)
          datatable(data, options = list(scrollX = TRUE, pageLength = 5))
        })
        
        # Histogram
        output[[paste0("pt_histogram_", pollutant_name)]] <- renderPlot({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          ref_value <- data %>% 
            filter(participant_id == "ref") %>%
            summarise(mean_ref = mean(mean_value, na.rm = TRUE)) %>%
            pull(mean_ref)
            
          ggplot(participants_data, aes(x = mean_value)) + 
            geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 15, boundary = 0) + 
            geom_density(alpha = 0.2, fill = "#FF6666") + 
            geom_vline(xintercept = ref_value, color = "red", linetype = "dashed", size = 1) + 
            labs(title = "Histograma de Resultados de Participantes", subtitle = "vs. Valor de Referencia (línea discontinua)", x = "Valor Medio", y = "Densidad") + 
            theme_minimal()
        })
        
        # Boxplot
        output[[paste0("pt_boxplot_", pollutant_name)]] <- renderPlot({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          ref_value <- data %>% 
            filter(participant_id == "ref") %>%
            summarise(mean_ref = mean(mean_value, na.rm = TRUE)) %>%
            pull(mean_ref)
            
          ggplot(participants_data, aes(x = "", y = mean_value)) + 
            geom_boxplot(fill = "lightgreen") + 
            geom_hline(yintercept = ref_value, color = "red", linetype = "dashed", size = 1) + 
            labs(title = "Diagrama de Caja de Resultados de Participantes", subtitle = "vs. Valor de Referencia (línea discontinua)", x = "", y = "Valor Medio") + 
            theme_minimal()
        })
        
        # Density Plot
        output[[paste0("pt_density_", pollutant_name)]] <- renderPlot({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          ref_value <- data %>% 
            filter(participant_id == "ref") %>%
            summarise(mean_ref = mean(mean_value, na.rm = TRUE)) %>%
            pull(mean_ref)
            
          ggplot(participants_data, aes(x = mean_value)) + 
            geom_density(fill = "lightblue", alpha = 0.7) + 
            geom_vline(xintercept = ref_value, color = "red", linetype = "dashed", size = 1) + 
            labs(title = "Densidad Kernel de Resultados de Participantes", subtitle = "vs. Valor de Referencia (línea discontinua)", x = "Valor Medio", y = "Densidad") + 
            theme_minimal()
        })
        
        # Grubbs' Test for Outliers
        output[[paste0("pt_grubbs_", pollutant_name)]] <- renderPrint({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          
          if (length(participants_data$mean_value) < 3) {
            "La prueba de Grubbs requiere al menos 3 puntos de datos."
          } else {
            grubbs.test(participants_data$mean_value)
          }
        })

        # Run Chart
        output[[paste0("pt_runchart_", pollutant_name)]] <- renderPlot({
          data <- filtered_data()
          req(nrow(data) > 0)

          participants_data <- data %>%
            filter(participant_id != "ref")
            
          center_line <- median(participants_data$mean_value, na.rm = TRUE)
            
          ggplot(participants_data, aes(x = sample_group, y = mean_value, group = 1)) + 
            geom_point() + 
            geom_line() + 
            geom_hline(yintercept = center_line, color = "red", linetype = "dashed") + 
            facet_wrap(~ participant_id) + 
            labs(title = "Gráfico de Rachas de Valores Medios por Participante",
                 x = "Grupo de Muestra",
                 y = "Valor Medio") + 
            theme_minimal() + 
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
        })
      }) # end local
    }) # end lapply
  }) # end observe
}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server, options = list(launch.browser = FALSE))
