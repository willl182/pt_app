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

# -------------------------------------------------------------------
# Helper Functions
# -------------------------------------------------------------------
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA_real_)
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(

  # 1. Application Title
  titlePanel("PT Data Analysis Application"),
  h4("Laboratorio Calaire"),

  # Collapsible panel for layout options
  checkboxInput("show_layout_options", "Show Layout Options", value = FALSE),
  conditionalPanel(
    condition = "input.show_layout_options == true",
    wellPanel(
      themeSelector(),
      hr(),
      sliderInput("nav_width", "Navigation Panel Width:", min = 1, max = 5, value = 2, width = "250px"),
      sliderInput("analysis_sidebar_width", "Analysis Sidebar Width:", min = 2, max = 6, value = 3, width = "250px")
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

  # --- Shared computation helpers ---
  get_wide_data <- function(df, target_pollutant) {
    filtered <- df %>% filter(pollutant == target_pollutant)
    if (nrow(filtered) == 0) {
      return(NULL)
    }
    filtered %>%
      select(-pollutant) %>%
      pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
  }

  compute_homogeneity_metrics <- function(target_pollutant, target_level) {
    wide_df <- get_wide_data(hom_data_full, target_pollutant)
    if (is.null(wide_df)) {
      return(list(error = sprintf("No homogeneity data found for pollutant '%s'.", target_pollutant)))
    }
    if (!"level" %in% names(wide_df)) {
      return(list(error = "Column 'level' not found in the loaded data."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("Level '%s' not found for pollutant '%s'.", target_level, target_pollutant)))
    }

    level_data <- wide_df %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) {
      return(list(error = "Not enough replicate runs (at least 2 required) for homogeneity assessment."))
    }
    if (g < 2) {
      return(list(error = "Not enough items (at least 2 required) for homogeneity assessment."))
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

    hom_data <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt."))
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
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE),
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
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(hom_s_x_bar_sq * m * (g - 1), hom_sw^2 * g * (m - 1)),
      "Mean Sq" = c(hom_s_x_bar_sq * m, hom_sw^2),
      check.names = FALSE
    )
    rownames(hom_anova_summary) <- c("Item", "Residuals")

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
    wide_df <- get_wide_data(stab_data_full, target_pollutant)
    if (is.null(wide_df)) {
      return(list(error = sprintf("No stability data found for pollutant '%s'.", target_pollutant)))
    }
    if (!"level" %in% names(wide_df)) {
      return(list(error = "Column 'level' not found in the stability dataset."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("Level '%s' not found for stability data of pollutant '%s'.", target_level, target_pollutant)))
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
      return(list(error = "Not enough replicate runs (at least 2 required) for stability data homogeneity assessment."))
    }
    if (g < 2) {
      return(list(error = "Not enough items (at least 2 required) for stability data homogeneity assessment."))
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

    stab_data <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt for stability data."))
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
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE),
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
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(stab_s_x_bar_sq * m * (g - 1), stab_sw^2 * g * (m - 1)),
      "Mean Sq" = c(stab_s_x_bar_sq * m, stab_sw^2),
      check.names = FALSE
    )
    rownames(stab_anova_summary) <- c("Item", "Residuals")

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
      return(list(error = "No summary data available for PT scores."))
    }

    data <- summary_df %>%
      filter(
        pollutant == target_pollutant,
        n_lab == target_n_lab,
        level == target_level
      )

    if (nrow(data) == 0) {
      return(list(error = "No data found for the selected criteria."))
    }

    ref_data <- data %>% filter(participant_id == "ref")
    participant_data <- data %>% filter(participant_id != "ref")

    if (nrow(ref_data) == 0) {
      return(list(error = "No reference data ('ref' participant) found for this level."))
    }
    if (nrow(participant_data) == 0) {
      return(list(error = "No participant data found for this level."))
    }

    x_pt <- mean(ref_data$mean_value, na.rm = TRUE)

    participant_data <- participant_data %>%
      rename(result = mean_value, uncertainty_std = sd_value)

    final_scores <- participant_data %>%
      mutate(
        z_score = (result - x_pt) / sigma_pt,
        z_prime_score = (result - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
        zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
        U_xi = k * uncertainty_std,
        U_xpt = k * u_xpt,
        En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
      ) %>%
      mutate(
        z_score_eval = case_when(
          abs(z_score) <= 2 ~ "Satisfactory",
          abs(z_score) > 2 & abs(z_score) < 3 ~ "Questionable",
          abs(z_score) >= 3 ~ "Unsatisfactory",
          TRUE ~ "N/A"
        ),
        z_prime_score_eval = case_when(
          abs(z_prime_score) <= 2 ~ "Satisfactory",
          abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Questionable",
          abs(z_prime_score) >= 3 ~ "Unsatisfactory",
          TRUE ~ "N/A"
        ),
        zeta_score_eval = case_when(
          abs(zeta_score) <= 2 ~ "Satisfactory",
          abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Questionable",
          abs(zeta_score) >= 3 ~ "Unsatisfactory",
          TRUE ~ "N/A"
        ),
        En_score_eval = case_when(
          abs(En_score) <= 1 ~ "Satisfactory",
          abs(En_score) > 1 ~ "Unsatisfactory",
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
      "Analysis Modules",

      # Module 1: Homogeneity and Stability
      tabPanel("Homogeneity & Stability Analysis",
        sidebarLayout(
          # 2.1. Input Panel (Sidebar)
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Seleccionar Datos (Select Data)"),
            selectInput("pollutant_analysis", "Select Pollutant:",
                        choices = c("co", "no", "no2", "o3", "so2")),
            hr(),
            h4("2. Seleccionar Parámetros (Select Parameters)"),
            # Dynamic UI to select the level
            uiOutput("level_selector"),

            h4("3. Ejecutar Análisis (Run Analysis)"),
            # Button to run the analysis
            actionButton("run_analysis", "Ejecutar (Run Analysis)",
                         class = "btn-primary btn-block"),

            hr(),
            p("Este aplicativo evalua la homogeneidad y estabilidad del item de ensayo de acuerdo a los princiios de la ISO 13528:2022.")
          ),

          # 2.2. Main Panel for Results
          mainPanel(
            width = analysis_main_w,
            # Outputs organized in tabs
            tabsetPanel(
              id = "analysis_tabs",

              # Tab 1: Data Preview
              tabPanel("Data Preview",
                       h4("Data Input Preview"),
                       p("This table shows the data for the selected pollutant."),
                       h5("Homogeneity Data"),
                       dataTableOutput("raw_data_preview"),
                       hr(),
                       h5("Stability Data"),
                       dataTableOutput("stability_data_preview"),
                       hr(),
                       h4("Data Distribution"),
                       p("The histogram and boxplot below show the distribution of all results from the 'sample_*' columns for the selected level."),
                       fluidRow(
                         column(width = 6,
                                plotOutput("results_histogram")
                         ),
                         column(width = 6,
                                plotOutput("results_boxplot")
                         )
                       ),
                       hr(),
                       h4("Data Validation"),
                       verbatimTextOutput("validation_message")
              ),

              # Tab 2: Homogeneity Assessment
              tabPanel("Homogeneity Assessment",
                       h4("Conclusion"),
                       uiOutput("homog_conclusion"),
                       hr(),
                       h4("Homogeneity Data Preview (Level and First Sample)"),
                       dataTableOutput("homogeneity_preview_table"),
                       hr(),
                       h4("Robust Statistics Calculations"),
                       tableOutput("robust_stats_table"),
                       verbatimTextOutput("robust_stats_summary"),
                       hr(),
                       h4("Variance Components"),
                       p("Estimated standard deviations from the manual calculation."),
                       tableOutput("variance_components"),
                       hr(),
                       h4("Per-Item Calculations"),
                       p("This table shows calculations for each item (row) in the dataset for the selected level, including the average and range of measurements."),
                       tableOutput("details_per_item_table"),
                       hr(),
                       h4("Summary Statistics"),
                       p("This table shows the overall statistics for the homogeneity assessment."),
                       tableOutput("details_summary_stats_table")
              ),

              # Tab 3: Stability Assessment
              tabPanel("Stability Asessment",
                       h4("Conclusion"),
                       uiOutput("homog_conclusion_stability"),
                       hr(),
                       h4("Variance Components"),
                       p("Estimated standard deviations from the manual calculation for the stability dataset."),
                       tableOutput("variance_components_stability"),
                       hr(),
                       h4("Per-Item Calculations"),
                       p("This table shows calculations for each item (row) in the stability dataset."),
                       tableOutput("details_per_item_table_stability"),
                       hr(),
                       h4("Summary Statistics"),
                       p("This table shows the overall statistics for the stability dataset."),
                       tableOutput("details_summary_stats_table_stability")
              )
            )
          )
        )
      ),

      # Module 2: PT Preparation
      tabPanel("PT Preparation",
        h3("Proficiency Testing Scheme Analysis"),
        p("Analysis of participant results from different PT schemes, based on summary data files."),
        uiOutput("pt_pollutant_tabs")
      ),

      # Module 3: PT Scores
      tabPanel("PT Scores",
        sidebarLayout(
          sidebarPanel(
            width = 4,
            h4("1. Select Data"),
            uiOutput("scores_pollutant_selector"),
            uiOutput("scores_n_selector"),
            uiOutput("scores_level_selector"),
            hr(),
            h4("2. Set Parameters"),
            p("Parameters based on ISO 13528. Adjust as needed."),
            numericInput("scores_sigma_pt", "Std. Dev. for PT (sigma_pt):", value = 5, step = 0.1),
            numericInput("scores_u_xpt", "Std. Uncertainty of Assigned Value (u_xpt):", value = 0.5, step = 0.01),
            numericInput("scores_k", "Coverage Factor (k) for En-Score:", value = 2, min = 1, step = 1)
          ),
          mainPanel(
            width = 8,
            tabsetPanel(
              id = "scores_tabs",
              tabPanel("Scores Table",
                       h4("Calculated Proficiency Scores"),
                       dataTableOutput("scores_table"),
                       hr(),
                       h4("Summary of Inputs"),
                       verbatimTextOutput("scores_inputs_summary")
              ),
              tabPanel("Z-Score Plot",
                       plotOutput("z_score_plot")
              ),
              tabPanel("Z'-Score Plot",
                       plotOutput("z_prime_score_plot")
              ),
              tabPanel("Zeta-Score Plot",
                       plotOutput("zeta_score_plot")
              ),
              tabPanel("En-Score Plot",
                       plotOutput("en_score_plot")
              )
            )
          )
        )
      ),

      tabPanel("Algoritmo A",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Seleccionar Datos"),
            uiOutput("algoA_pollutant_selector"),
            uiOutput("algoA_n_selector"),
            uiOutput("algoA_level_selector"),
            hr(),
            h4("2. Parámetros del Algoritmo"),
            numericInput("algoA_max_iter", "Iteraciones máximas:", value = 50, min = 5, max = 500, step = 5),
            hr(),
            h4("3. Ejecutar"),
            actionButton("algoA_run", "Calcular Algoritmo A", class = "btn-primary btn-block")
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
            plotOutput("algoA_histogram"),
            hr(),
            h4("Iteraciones"),
            dataTableOutput("algoA_iterations_table"),
            hr(),
            h4("Pesos Finales por Participante"),
            dataTableOutput("algoA_weights_table")
          )
        )
      ),

      tabPanel("Report Generation",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Seleccionar Datos"),
            uiOutput("report_pollutant_selector"),
            uiOutput("report_n_selector"),
            uiOutput("report_level_selector"),
            hr(),
            h4("2. Parámetros del Informe"),
            numericInput("report_sigma_pt", "Std. Dev. for PT (sigma_pt):", value = 5, min = 0, step = 0.1),
            numericInput("report_u_xpt", "Std. Uncertainty of Assigned Value (u_xpt):", value = 0.5, min = 0, step = 0.01),
            numericInput("report_k", "Coverage Factor (k):", value = 2, min = 1, step = 1),
            hr(),
            radioButtons("report_format", "Formato de salida:", choices = c("HTML" = "html", "PDF" = "pdf", "Word (DOCX)" = "word"), selected = "html"),
            helpText("La exportación en PDF requiere una instalación de LaTeX disponible en el sistema."),
            downloadButton("download_report", "Descargar informe", class = "btn-success")
          ),
          mainPanel(
            width = analysis_main_w,
            h4("Resumen previo"),
            uiOutput("report_status"),
            verbatimTextOutput("report_preview_summary"),
            hr(),
            p("El informe consolida los resultados de homogeneidad, estabilidad y puntajes de desempeño para la combinación seleccionada.")
          )
        )
      )
    )
  })

  # R1: Reactive for Homogeneity Data
  raw_data <- reactive({
    req(input$pollutant_analysis)
    get_wide_data(hom_data_full, input$pollutant_analysis)
  })

  # R1.6: Reactive for Stability Data
  stability_data_raw <- reactive({
    req(input$pollutant_analysis)
    get_wide_data(stab_data_full, input$pollutant_analysis)
  })

  # R2: Dynamic Generation of the Level Selector
  output$level_selector <- renderUI({
    data <- raw_data()
    if ("level" %in% names(data)) {
      levels <- unique(data$level)
      selectInput("target_level", "2. Select PT Level", choices = levels, selected = levels[1])
    } else {
      p("Column 'level' not found in the loaded data.")
    }
  })

  # R3: Homogeneity Execution (Triggered by button)
  homogeneity_run <- eventReactive(input$run_analysis, {
    req(input$pollutant_analysis, input$target_level)
    compute_homogeneity_metrics(input$pollutant_analysis, input$target_level)
  })

  # R3.5: Stability Data Homogeneity Execution (Triggered by button)
  homogeneity_run_stability <- eventReactive(input$run_analysis, {
    req(input$pollutant_analysis, input$target_level)
    hom_results <- compute_homogeneity_metrics(input$pollutant_analysis, input$target_level)
    compute_stability_metrics(input$pollutant_analysis, input$target_level, hom_results)
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
      paste("Mean of Homogeneity Data (y1):", fmt, "
Mean of Stability Data (y2):", fmt, "
Observed Absolute Difference:", fmt, "
Stability Criterion (0.3 * sigma_pt):", fmt),
      y1, y2, diff_observed, stab_criterion_value
    )

    if (diff_observed <= stab_criterion_value) {
      conclusion <- "Conclusion: The item is adequately stable."
      conclusion_class <- "alert alert-success"
    } else {
      conclusion <- "Conclusion: WARNING: The item may be unstable."
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
      ttest_conclusion <- "T-test: No statistically significant difference detected between the two datasets (p > 0.05), supporting stability."
    } else {
      ttest_conclusion <- "T-test: Statistically significant difference detected between the two datasets (p <= 0.05), indicating potential instability."
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
    cat("Data loaded successfully.
")
    cat(paste("Dimensions:", paste(dim(data), collapse = " x "), "
"))

    required_cols <- c("level")
    has_samples <- any(str_detect(names(data), "sample_"))

    if(!all(required_cols %in% names(data))) {
        cat(paste("ERROR: Missing required column(s):", paste(setdiff(required_cols, names(data)), collapse=", "), "
"))
    } else {
        cat("Found 'level' column.
")
    }

    if(!has_samples) {
        cat("ERROR: No columns with 'sample_' prefix found. These are needed for the analysis.
")
    } else {
        cat("Found 'sample_*' columns.
")
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
      labs(title = "Distribution by Level",
           x = "Result", y = "Density") +
      theme_minimal()
  })

  # Output: Boxplot
  output$results_boxplot <- renderPlot({
    plot_data <- plot_data_long()
    req(plot_data)
    ggplot(plot_data, aes(x = "", y = result)) +
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      facet_wrap(~level, scales = "free") +
      labs(title = "Boxplot by Level",
           x = NULL, y = "Result") +
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
        Statistic = c("Median (x_pt)", "Median Absolute Difference", "MADe (sigma_pt)", "nIQR"),
        Value = c(
          format(res$median_val, digits = 15, scientific = FALSE),
          format(res$median_abs_diff, digits = 15, scientific = FALSE),
          format(res$sigma_pt, digits = 15, scientific = FALSE),
          format(res$n_iqr, digits = 15, scientific = FALSE)
        )
      )
    }
  }, spacing = "l")

  # Output: Robust Stats Summary
  output$robust_stats_summary <- renderPrint({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      cat(paste("Median Value:", format(res$median_val, digits = 15, scientific = FALSE), "
"))
      cat(paste("Median Absolute Difference:", format(res$median_abs_diff, digits = 15, scientific = FALSE), "
"))
      cat(paste("MADe (sigma_pt):", format(res$sigma_pt, digits = 15, scientific = FALSE), "
"))
      cat(paste("nIQR:", format(res$n_iqr, digits = 15, scientific = FALSE), "
"))
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
          Component = c("Assigned Value (xpt)",
                        "Robust SD (sigma_pt)",
                        "Uncertainty of Assigned Value (u_xpt)",
                        "Between-Sample SD (ss)",
                        "Within-Sample SD (sw)",
                        "---",
                        "Criterion c",
                        "Criterion c (expanded)"),
          Value = c(
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
          cat(res$ttest_conclusion, "

")
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
        Parameter = c("General Mean",
                      "SD of Means",
                      "Variance of Means (s_x_bar_sq)",
                      "sw",
                      "Within-Sample Variance (s_w_sq)",
                      "ss",
                      "---",
                      "Assigned Value (xpt)",
                      "Median of Absolute Differences",
                      "Number of Items (g)",
                      "Number of Replicates (m)",
                      "Robust SD (MADe)",
                      "nIQR",
                      "Uncertainty of Assigned Value (u_xpt)",
                      "---",
                      "Criterion c",
                      "Criterion c (expanded)"),
        Value = c(
          format(c(res$general_mean, res$sd_of_means, res$s_x_bar_sq, res$sw, res$s_w_sq, res$ss), digits = 15, scientific = FALSE),
          "",
          format(c(res$median_val, res$median_abs_diff, res$g, res$m, res$sigma_pt, res$n_iqr, res$u_xpt), digits = 15, scientific = FALSE),
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
          Component = c("Assigned Value (xpt)",
                        "Robust SD (sigma_pt)",
                        "Uncertainty of Assigned Value (u_xpt)"),
          Value = c(
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
        Parameter = c("General Mean",
                      "Absolute Difference from General Mean",
                      "SD of Means",
                      "Variance of Means (s_x_bar_sq)",
                      "sw",
                      "Within-Sample Variance (s_w_sq)",
                      "ss",
                      "---",
                      "Assigned Value (xpt)",
                      "Median of Absolute Differences",
                      "Number of Items (g)",
                      "Number of Replicates (m)",
                      "Robust SD (MADe)",
                      "nIQR",
                      "Uncertainty of Assigned Value (u_xpt)",
                      "---",
                      "Criterion c",
                      "Criterion c (expanded)"),
        Value = c(
          format(c(res$stab_general_mean, res$diff_hom_stab, res$stab_sd_of_means, res$stab_s_x_bar_sq, res$stab_sw, res$stab_s_w_sq, res$stab_ss), digits = 15, scientific = FALSE),
          "",
          format(c(res$stab_median_val, res$stab_median_abs_diff, res$g, res$m, res$stab_sigma_pt, res$stab_n_iqr, res$stab_u_xpt), digits = 15, scientific = FALSE),
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
    selectInput("scores_pollutant", "Select Pollutant:", choices = choices)
  })

  output$scores_n_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$scores_pollutant) %>%
      pull(n_lab) %>%
      unique() %>%
      sort()
    selectInput("scores_n_lab", "Select PT Scheme (by n):", choices = choices)
  })

  output$scores_level_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$scores_pollutant, n_lab == input$scores_n_lab) %>%
      pull(level) %>%
      unique()
    selectInput("scores_level", "Select Level:", choices = choices)
  })

  # Reactive for score calculation
  scores_run <- reactive({
    req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab, input$scores_level,
        input$scores_sigma_pt, input$scores_u_xpt, input$scores_k)
    compute_scores_metrics(
      summary_df = pt_prep_data(),
      target_pollutant = input$scores_pollutant,
      target_n_lab = input$scores_n_lab,
      target_level = input$scores_level,
      sigma_pt = input$scores_sigma_pt,
      u_xpt = input$scores_u_xpt,
      k = input$scores_k
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
          `Participant` = participant_id,
          `Result` = result,
          `u(xi)` = uncertainty_std,
          `z-score` = z_score,
          `z-score Eval` = z_score_eval,
          `z'-score` = z_prime_score,
          `z'-score Eval` = z_prime_score_eval,
          `zeta-score` = zeta_score,
          `zeta-score Eval` = zeta_score_eval,
          `En-score` = En_score,
          `En-score Eval` = En_score_eval
        )
  
      datatable(display_df, options = list(scrollX = TRUE, pageLength = 10), rownames = FALSE) %>%
        formatRound(columns = c('Result', 'u(xi)', 'z-score', 'z\'-score', 'zeta-score', 'En-score'), digits = 3) %>%
        formatStyle(
          'z-score Eval',
          backgroundColor = styleEqual(c("Satisfactory", "Questionable", "Unsatisfactory"), c("#d4edda", "#fff3cd", "#f8d7da"))
        ) %>%
        formatStyle(
          'z\'-score Eval',
          backgroundColor = styleEqual(c("Satisfactory", "Questionable", "Unsatisfactory"), c("#d4edda", "#fff3cd", "#f8d7da"))
        ) %>%
        formatStyle(
          'zeta-score Eval',
          backgroundColor = styleEqual(c("Satisfactory", "Questionable", "Unsatisfactory"), c("#d4edda", "#fff3cd", "#f8d7da"))
        ) %>%
        formatStyle(
          'En-score Eval',
          backgroundColor = styleEqual(c("Satisfactory", "Unsatisfactory"), c("#d4edda", "#f8d7da"))
        )
    })
  # Output: Inputs Summary
  output$scores_inputs_summary <- renderPrint({
    res <- scores_run()
    req(res)
    if (!is.null(res$error)) {
      cat(res$error)
    } else {
      cat(sprintf("Assigned Value (x_pt): %.4f
", res$x_pt))
      cat(sprintf("Standard Deviation for PT (sigma_pt): %.4f
", res$sigma_pt))
      cat(sprintf("Standard Uncertainty of Assigned Value (u_xpt): %.4f
", res$u_xpt))
      cat(sprintf("Coverage Factor (k) for En-score: %d
", res$k))
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
        title = "Z-Scores by Participant",
        subtitle = "Warning limits at |z|=2 (orange), Action limits at |z|=3 (red)",
        x = "Participant",
        y = "Z-Score"
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
        title = "Z'-Scores by Participant",
        subtitle = "Warning limits at |z'|=2 (orange), Action limits at |z'|=3 (red)",
        x = "Participant",
        y = "Z'-Score"
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
        title = "Zeta-Scores by Participant",
        subtitle = "Warning limits at |ζ|=2 (orange), Action limits at |ζ|=3 (red)",
        x = "Participant",
        y = "Zeta-Score (ζ)"
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
        title = "En-Scores by Participant",
        subtitle = "Action limits at |En|=1 (red)",
        x = "Participant",
        y = "En-Score"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  # --- Report Generation Module ---

  output$report_pollutant_selector <- renderUI({
    choices <- sort(unique(hom_data_full$pollutant))
    selectInput("report_pollutant", "Select Pollutant:", choices = choices)
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
    selectInput("report_n_lab", "Select PT Scheme (by n):", choices = choices)
  })

  output$report_level_selector <- renderUI({
    req(pt_prep_data(), input$report_pollutant, input$report_n_lab)
    pt_levels <- pt_prep_data() %>%
      filter(pollutant == input$report_pollutant, n_lab == input$report_n_lab) %>%
      pull(level) %>%
      unique()
    hom_levels <- hom_data_full %>%
      filter(pollutant == input$report_pollutant) %>%
      pull(level) %>%
      unique()
    stab_levels <- stab_data_full %>%
      filter(pollutant == input$report_pollutant) %>%
      pull(level) %>%
      unique()
    common_levels <- sort(Reduce(intersect, list(pt_levels, hom_levels, stab_levels)))
    if (length(common_levels) == 0) {
      return(helpText("No hay niveles comunes entre los datos disponibles para esta combinación."))
    }
    selectInput("report_level", "Select Level:", choices = common_levels)
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
    cat(sprintf("Conclusión: %s\n", gsub("<br>", " | ", hom$conclusion)))
    cat(sprintf("ss = %.4f | c = %.4f | c_exp = %.4f\n", hom$ss, hom$c_criterion, hom$c_criterion_expanded))
    cat(sprintf("MADe = %.4f | nIQR = %.4f\n", hom$sigma_pt, hom$n_iqr))
    cat("\n--- Estabilidad ---\n")
    cat(sprintf("Conclusión: %s\n", stab$stab_conclusion))
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
                    pdf = "pdf",
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
        stop("No se encontró la plantilla en 'reports/pt_report_template.Rmd'.")
      }

      temp_dir <- tempdir()
      temp_report <- file.path(temp_dir, "pt_report_template.Rmd")
      file.copy(template_path, temp_report, overwrite = TRUE)

      output_format <- switch(input$report_format,
                              html = "html_document",
                              pdf = "pdf_document",
                              word = "word_document")
      ext <- switch(input$report_format,
                    html = "html",
                    pdf = "pdf",
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

  # --- Algoritmo A Module ---

  output$algoA_pollutant_selector <- renderUI({
    req(pt_prep_data())
    if (nrow(pt_prep_data()) == 0) {
      return(p("No se encontraron datos para ejecutar el Algoritmo A."))
    }
    choices <- sort(unique(pt_prep_data()$pollutant))
    selectInput("algoA_pollutant", "Seleccionar analito:", choices = choices)
  })

  output$algoA_n_selector <- renderUI({
    req(pt_prep_data(), input$algoA_pollutant)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$algoA_pollutant) %>%
      pull(n_lab) %>%
      unique() %>%
      sort()
    selectInput("algoA_n_lab", "Seleccionar esquema PT (n):", choices = choices)
  })

  output$algoA_level_selector <- renderUI({
    req(pt_prep_data(), input$algoA_pollutant, input$algoA_n_lab)
    choices <- pt_prep_data() %>%
      filter(pollutant == input$algoA_pollutant, n_lab == input$algoA_n_lab) %>%
      pull(level) %>%
      unique()
    selectInput("algoA_level", "Seleccionar nivel:", choices = choices)
  })

  run_algorithm_a <- function(values, ids, max_iter = 50) {
    mask <- is.finite(values)
    values <- values[mask]
    ids <- ids[mask]

    n <- length(values)
    if (n < 3) {
      return(list(error = "El Algoritmo A requiere al menos 3 resultados válidos."))
    }

    x_star <- median(values, na.rm = TRUE)
    s_star <- 1.483 * median(abs(values - x_star), na.rm = TRUE)

    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      s_star <- sd(values, na.rm = TRUE)
    }

    if (!is.finite(s_star) || s_star < .Machine$double.eps) {
      return(list(error = "La dispersión de los datos es insuficiente para ejecutar el Algoritmo A."))
    }

    iteration_records <- list()
    converged <- FALSE

    for (iter in seq_len(max_iter)) {
      u_values <- (values - x_star) / (1.5 * s_star)
      weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))

      weight_sum <- sum(weights)
      if (!is.finite(weight_sum) || weight_sum <= 0) {
        return(list(error = "Los pesos calculados no son válidos para el Algoritmo A."))
      }

      x_new <- sum(weights * values) / weight_sum
      s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)

      if (!is.finite(s_new) || s_new < .Machine$double.eps) {
        return(list(error = "El Algoritmo A colapsó debido a una desviación estándar nula."))
      }

      delta_x <- abs(x_new - x_star)
      delta_s <- abs(s_new - s_star)
      delta <- max(delta_x, delta_s)
      iteration_records[[iter]] <- data.frame(
        Iteración = iter,
        `Valor asignado (x*)` = x_new,
        `Desviación robusta (s*)` = s_new,
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
      Resultado = values,
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

  algorithm_a_results <- eventReactive(input$algoA_run, {
    req(pt_prep_data(), input$algoA_pollutant, input$algoA_n_lab, input$algoA_level,
        input$algoA_max_iter)

    data <- pt_prep_data() %>%
      filter(
        pollutant == input$algoA_pollutant,
        n_lab == input$algoA_n_lab,
        level == input$algoA_level,
        participant_id != "ref"
      )

    if (nrow(data) == 0) {
      return(list(error = "No se encontraron datos de participantes para los criterios seleccionados."))
    }

    aggregated <- data %>%
      group_by(participant_id) %>%
      summarise(Resultado = mean(mean_value, na.rm = TRUE), .groups = "drop")

    if (nrow(aggregated) < 3) {
      return(list(error = "Se requieren al menos tres participantes para ejecutar el Algoritmo A."))
    }

    algo_res <- run_algorithm_a(
      values = aggregated$Resultado,
      ids = aggregated$participant_id,
      max_iter = input$algoA_max_iter
    )

    algo_res$input_data <- aggregated
    algo_res$selected <- list(
      pollutant = input$algoA_pollutant,
      n_lab = input$algoA_n_lab,
      level = input$algoA_level
    )

    algo_res
  }, ignoreNULL = TRUE)

  output$algoA_result_summary <- renderUI({
    res <- algorithm_a_results()
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
    res <- algorithm_a_results()
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

  output$algoA_histogram <- renderPlot({
    res <- algorithm_a_results()
    req(res)
    if (!is.null(res$error)) {
      return(NULL)
    }

    ggplot(res$input_data, aes(x = Resultado)) +
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
  })

  output$algoA_iterations_table <- renderDataTable({
    res <- algorithm_a_results()
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
      formatRound(columns = c("Valor asignado (x*)", "Desviación robusta (s*)", "Cambio"), digits = 9)
  })

  output$algoA_weights_table <- renderDataTable({
    res <- algorithm_a_results()
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

  # --- PT Preparation Module ---

  output$pt_pollutant_tabs <- renderUI({
    req(pt_prep_data())
    # Ensure pt_prep_data is not NULL and has rows
    if (is.null(pt_prep_data()) || nrow(pt_prep_data()) == 0) {
      return(p("No summary data files found or files are empty. Please add summary_n*.csv files."))
    }
    pollutants <- unique(pt_prep_data()$pollutant)
    
    tabs <- lapply(pollutants, function(p) {
      tabPanel(toupper(p),
        sidebarLayout(
          sidebarPanel(
            width = 4,
            h4(paste("Options for", toupper(p))),
            uiOutput(paste0("pt_n_selector_", p)),
            uiOutput(paste0("pt_level_selector_", p)),
            hr(),
            h4("Summary Information"),
            verbatimTextOutput(paste0("pt_summary_", p))
          ),
          mainPanel(
            width = 8,
            h4("Participant Results Plot"),
            plotOutput(paste0("pt_plot_", p)),
            hr(),
            h4("Data Table"),
            dataTableOutput(paste0("pt_table_", p)),
            hr(),
            h4("Results Distribution"),
            fluidRow(
              column(width = 6, plotOutput(paste0("pt_histogram_", p))),
              column(width = 6, plotOutput(paste0("pt_boxplot_", p)))
            ),
            fluidRow(
              column(width = 12, plotOutput(paste0("pt_density_", p)))
            ),
            hr(),
            h4("Grubbs' Test for Outliers"),
            verbatimTextOutput(paste0("pt_grubbs_", p)),
            hr(),
            h4("Run Chart"),
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
          selectInput(paste0("n_lab_", pollutant_name), "Select PT Scheme (by n):", choices = sort(choices))
        })
        
        # Level selector
        output[[paste0("pt_level_selector_", pollutant_name)]] <- renderUI({
          req(input[[paste0("n_lab_", pollutant_name)]])
          choices <- pt_prep_data() %>%
            filter(pollutant == pollutant_name, n_lab == input[[paste0("n_lab_", pollutant_name)]]) %>%
            pull(level) %>%
            unique()
          selectInput(paste0("level_", pollutant_name), "Select Level:", choices = choices)
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
          
          cat("Pollutant:", pollutant_name, "\n")
          cat("PT Scheme (n_lab):", unique(data$n_lab), "\n")
          cat("Level:", unique(data$level), "\n")
          cat("Number of Participants:", n_participants, "\n")
          cat("Participants:", paste(participants, collapse = ", "))
        })
        
        # Plot
        output[[paste0("pt_plot_", pollutant_name)]] <- renderPlot({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          ggplot(data, aes(x = participant_id, y = mean_value, fill = sample_group)) +
            geom_bar(stat = "identity", position = "dodge") +
            geom_errorbar(aes(ymin = mean_value - sd_value, ymax = mean_value + sd_value), width = 0.2, position = position_dodge(0.9)) +
            labs(title = "Participant Mean Values with SD", x = "Participant", y = "Mean Value") +
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
            labs(title = "Histogram of Participant Results", subtitle = "vs. Reference Value (dashed line)", x = "Mean Value", y = "Density") +
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
            labs(title = "Boxplot of Participant Results", subtitle = "vs. Reference Value (dashed line)", x = "", y = "Mean Value") +
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
            labs(title = "Kernel Density of Participant Results", subtitle = "vs. Reference Value (dashed line)", x = "Mean Value", y = "Density") +
            theme_minimal()
        })
        
        # Grubbs' Test for Outliers
        output[[paste0("pt_grubbs_", pollutant_name)]] <- renderPrint({
          data <- filtered_data()
          req(nrow(data) > 0)
          
          participants_data <- data %>% filter(participant_id != "ref")
          
          if (length(participants_data$mean_value) < 3) {
            "Grubbs' test requires at least 3 data points."
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
            labs(title = "Run Chart of Mean Values by Participant",
                 x = "Sample Group",
                 y = "Mean Value") +
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
