# ===================================================================
#
# PT-Analysis-ISO13528 Shiny Application
#
# Author: Your Name
# Date: 2025-10-08
#
# -- DESCRIPTION --
# This Shiny web application provides a comprehensive platform for conducting
# statistical analysis of proficiency testing (PT) data, specifically focusing
# on homogeneity and stability assessments. The methodologies implemented
# are in strict accordance with the international standard ISO 13528:2022,
# "Statistical methods for use in proficiency testing by interlaboratory
# comparison."
#
# The application is designed to be a practical tool for PT providers,
# allowing them to:
#   - Validate the suitability of PT items through homogeneity testing.
#   - Assess the stability of PT items over time by comparing datasets.
#   - Visualize data distributions using histograms and boxplots to
#     identify potential issues.
#   - Review detailed statistical tables, including variance components
#     (ss, sw), robust statistics, and per-item calculations.
#
# For a detailed explanation of the statistical methods, refer to the
# `sop.md` document in this repository, which outlines the implementation
# of the ISO 13528:2022 procedures.
#
# -- STRUCTURE --
# The application follows a standard Shiny architecture, organized into
# three main parts:
#
#   I.  User Interface (UI):
#       - Defines the layout and appearance of the web application using a
#         fluid, responsive design.
#       - Contains all input controls (e.g., dropdowns for pollutant/level
#         selection, action buttons) and output placeholders (e.g., plots,
#         tables) for displaying results.
#
#   II. Server Logic:
#       - Contains the computational engine of the application. It uses a
#         reactive programming model to link user inputs to data processing
#         and analysis.
#       - Key reactive expressions (e.g., `raw_data`, `homogeneity_run`)
#         are prefixed with 'R#' in the comments for clarity. These
#         expressions automatically re-evaluate when their dependencies
#         (user inputs) change, ensuring the outputs are always up-to-date.
#       - The server function is responsible for all data loading, filtering,
#         statistical calculations, and rendering of the final outputs (plots,
#         tables, text) to be displayed in the UI.
#
#   III. Application Execution:
#       - A single command that combines the UI and Server logic to launch
#         the Shiny application.
#
# ===================================================================


# 1. Load necessary libraries
library(shiny)
library(tidyverse)
library(vroom)
library(DT)
library(rhandsontable)
library(shinythemes)

# ===================================================================
# I. User Interface (UI)
# Defines the visual layout and interactive components of the application.
# The UI is built using a fluidPage layout, which allows it to adapt to
# different screen sizes.
# ===================================================================
ui <- fluidPage(

  # 1. Application Title
  titlePanel("PT Data Analysis App"),

  # 2. Layout Options
  # A collapsible panel providing controls to customize the application's
  # appearance. This includes a theme selector and sliders to adjust the
  # widths of the main navigation and analysis sidebars, offering users
  # a more flexible and personalized interface.
  checkboxInput("show_layout_options", "Show Layout Options", value = FALSE),
  conditionalPanel(
    condition = "input.show_layout_options == true",
    wellPanel(
      # The themeSelector allows users to choose from a variety of pre-built
      # visual themes for the application.
      themeSelector(),
      hr(),
      # Sliders to dynamically adjust the Bootstrap grid widths of the panels.
      sliderInput("nav_width", "Navigation Panel Width:", min = 1, max = 5, value = 2, width = "250px"),
      sliderInput("analysis_sidebar_width", "Analysis Sidebar Width:", min = 2, max = 6, value = 3, width = "250px")
    )
  ),
  hr(),

  # 3. Main Application Layout
  # The entire main layout is rendered dynamically in the server function
  # via `uiOutput("main_layout")`. This powerful feature allows the panel
  # widths to be reactive to the slider inputs above, providing an
  # instantly responsive user experience.
  uiOutput("main_layout")
)

# ===================================================================
# II. Server Logic
# This function contains the core logic for data processing, analysis,
# and rendering of all outputs displayed in the UI.
# ===================================================================
server <- function(input, output, session) {

  # --- Data Loading and Processing ---
  # Data is loaded statically when the application session starts.
  # The primary data sources, `homogeneity.csv` and `stability.csv`,
  # are expected to be in the application's root directory.
  hom_data_full <- read.csv("homogeneity.csv")
  stab_data_full <- read.csv("stability.csv")

  # R0: Dynamic Main Layout
  # This `renderUI` block constructs the main application layout, which
  # consists of a `navlistPanel` for primary navigation and a main content
  # area. Its reactivity to the width sliders (`input$nav_width`,
  # `input$analysis_sidebar_width`) allows the layout to update instantly
  # without a full page refresh.
  output$main_layout <- renderUI({
    # Ensure dependencies on width inputs are registered before proceeding.
    req(input$nav_width, input$analysis_sidebar_width)
    nav_width <- input$nav_width
    content_width <- 12 - nav_width

    analysis_sidebar_w <- input$analysis_sidebar_width
    analysis_main_w <- 12 - analysis_sidebar_w

    # `navlistPanel` creates the main navigation structure on the left side,
    # organizing the application into distinct modules.
    navlistPanel(
      id = "main_nav",
      widths = c(nav_width, content_width),
      "Analysis Modules",

      # == MODULE 1: Homogeneity & Stability Analysis ==
      # This is the primary analysis module of the application.
      tabPanel("Homogeneity & Stability Analysis",
        sidebarLayout(
          # 2.1. Input Panel (Sidebar)
          # This panel contains all user controls for running the analysis,
          # including data selection, parameter setting, and execution.
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Seleccionar Datos (Select Data)"),
            # Dropdown to select the pollutant for analysis. This is the
            # primary filter for the datasets.
            selectInput("pollutant_analysis", "Select Pollutant:",
                        choices = c("co", "no", "no2", "o3", "so2")),
            hr(),
            h4("2. Seleccionar Parámetros (Select Parameters)"),
            # This UI output will dynamically generate a dropdown to select
            # the 'level' based on the chosen pollutant. See R2.
            uiOutput("level_selector"),

            h4("3. Ejecutar Análisis (Run Analysis)"),
            # The main action button that triggers all statistical calculations.
            # The use of `eventReactive` in the server ensures that the
            # analysis only runs when this button is clicked.
            actionButton("run_analysis", "Ejecutar (Run Analysis)",
                         class = "btn-primary btn-block"),
            hr(),
            p("Este aplicativo evalua la homogeneidad y estabilidad del item de ensayo de acuerdo a los princiios de la ISO 13528:2022.")
          ),

          # 2.2. Main Panel for Results
          # This panel is dedicated to displaying all the outputs of the
          # analysis, organized into a series of tabs.
          mainPanel(
            width = analysis_main_w,
            tabsetPanel(
              id = "analysis_tabs",

              # Tab 1: Data Preview
              # Provides an initial look at the loaded data and its
              # distribution, helping users verify their inputs.
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
                         column(width = 6, plotOutput("results_histogram")),
                         column(width = 6, plotOutput("results_boxplot"))
                       ),
                       hr(),
                       h4("Data Validation"),
                       verbatimTextOutput("validation_message")
              ),

              # Tab 2: Homogeneity Assessment
              # Displays the detailed results of the homogeneity calculations,
              # including the final conclusion and supporting statistical tables.
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
              # Displays the results of the stability check, comparing the
              # initial data with the stability data.
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

      # == MODULE 2: PT Preparation (Placeholder) ==
      # This section is a placeholder for a future module intended for
      # PT preparation tasks.
      tabPanel("PT Preparation",
        sidebarLayout(
          sidebarPanel(
            h3("Proficiency Testing Preparation"),
            selectInput("pollutant", "Select Pollutant:",
                        choices = c("co", "no", "no2", "o3", "so2")),
            # Dynamic UI for future input fields.
            uiOutput("pt_preparation_inputs")
          ),
          mainPanel(
            h4("Output Area"),
            p("Results and calculations will be displayed here.")
          )
        )
      )
    )
  })

  # R1: Reactive for Homogeneity Data
  # Purpose: Filters the main homogeneity dataset (`hom_data_full`) based
  #          on the user's selected pollutant (`input$pollutant_analysis`).
  #          It then pivots the data from a long to a wide format, which is
  #          more convenient for subsequent row-wise calculations.
  # Inputs: `input$pollutant_analysis`
  # Outputs: A reactive data frame containing the filtered and widened data.
  raw_data <- reactive({
    req(input$pollutant_analysis)
    hom_data_full %>%
      filter(pollutant == input$pollutant_analysis) %>%
      select(-pollutant) %>%
      pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
  })

  # R1.6: Reactive for Stability Data
  # Purpose: Similar to R1, this filters the stability dataset
  #          (`stab_data_full`) based on the selected pollutant and pivots
  #          it to a wide format.
  # Inputs: `input$pollutant_analysis`
  # Outputs: A reactive data frame for the stability analysis.
  stability_data_raw <- reactive({
    req(input$pollutant_analysis)
    stab_data_full %>%
      filter(pollutant == input$pollutant_analysis) %>%
      select(-pollutant) %>%
      pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
  })

  # R2: Dynamic Generation of the Level Selector
  # Purpose: Creates a dropdown menu (`selectInput`) for the 'level'
  #          parameter. The choices in this dropdown are dynamically
  #          generated from the unique values in the `level` column of the
  #          filtered `raw_data()`.
  # Inputs: `raw_data()`
  # Outputs: A `selectInput` UI element.
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
  # Purpose: This is the core reactive expression for the homogeneity
  #          assessment. It is wrapped in `eventReactive`, so it only
  #          executes when `input$run_analysis` is triggered (i.e., the
  #          button is clicked). It performs all calculations as described
  #          in ISO 13528:2022, Annex B.
  # Inputs: `input$run_analysis`, `raw_data()`, `input$target_level`
  # Outputs: A list containing all calculated results for the homogeneity
  #          assessment (e.g., ss, sw, conclusion, statistical tables).
  homogeneity_run <- eventReactive(input$run_analysis, {
    req(raw_data(), input$target_level)
    homogeneity_data <- raw_data()
    target_level <- input$target_level

    # Filter data for the selected level and select only sample result columns.
    homogeneity_level_data <- homogeneity_data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(homogeneity_level_data) # Number of items
    m <- ncol(homogeneity_level_data) # Number of replicates

    # Basic data validation, as required by the standard.
    if (m < 2) {
        return(list(error = "Not enough replicate runs (at least 2 required) for homogeneity assessment."))
    }
    if (g < 2) {
        return(list(error = "Not enough items (at least 2 required) for homogeneity assessment."))
    }

    # Create an intermediate dataframe for display purposes, showing per-item
    # averages and ranges (or standard deviations if m > 2).
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

    # Pivot data to a long format for easier group-wise statistical calculations.
    hom_data <- homogeneity_level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    # Calculate sigma_pt using the robust Median Absolute Deviation (MADe)
    # method on the results from the first sample column.
    # ISO 13528:2022, Section 6.5.2, recommends robust methods like MADe.
    if (!"sample_1" %in% names(homogeneity_level_data)) {
        return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt."))
    }
    first_sample_results <- homogeneity_level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff # Scaling factor for normality

    # Calculate the uncertainty of the assigned value using the robust method
    # described in ISO 13528:2022, Section 7.7.
    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)


    # --- Manual ANOVA-like Calculation for Homogeneity ---
    # This section calculates the between-sample (ss) and within-sample (sw)
    # standard deviations, which are the key metrics for the assessment.
    # This follows the principles outlined in ISO 13528:2022, Annex B.
    hom_item_stats <- hom_data %>%
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE)
      )

    hom_x_t_bar <- mean(hom_item_stats$mean, na.rm = TRUE) # Grand mean
    hom_s_x_bar_sq <- var(hom_item_stats$mean, na.rm = TRUE) # Variance of item means
    hom_s_xt <- sqrt(hom_s_x_bar_sq)
    hom_wt = abs(hom_item_stats$diff)
    hom_sw <- sqrt(sum(hom_wt^2) / (2 * length(hom_wt))) # Within-sample SD (sw)
    hom_ss_sq <- abs(hom_s_xt^2 - ((hom_sw^2) / 2))     # Between-sample variance (ss^2)
    hom_ss <- sqrt(hom_ss_sq)                           # Between-sample SD (ss)

    # Create a summary dataframe for display, mimicking an ANOVA table structure.
    hom_anova_summary_df <- data.frame(
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(hom_s_x_bar_sq * m * (g - 1), hom_sw^2 * g * (m - 1)),
      "Mean Sq" = c(hom_s_x_bar_sq * m, hom_sw^2),
      check.names = FALSE
    )
    rownames(hom_anova_summary_df) <- c("Item", "Residuals")
    hom_anova_summary <- hom_anova_summary_df

    # --- Homogeneity Assessment Criteria ---
    # The calculated between-sample SD (ss) is compared against the criteria
    # defined in ISO 13528:2022, Annex B.
    hom_sigma_pt <- mad_e
    hom_c_criterion <- 0.3 * hom_sigma_pt # Primary criterion
    hom_sigma_allowed_sq <- hom_c_criterion^2
    # The F-test critical values (1.88, 1.01) are used for the expanded criterion.
    hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)

    # First comparison: ss vs. c_criterion (0.3 * sigma_pt)
    if (hom_ss <= hom_c_criterion) {
      hom_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-success"
    } else {
      hom_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-warning"
    }

    # Second comparison (if the first is not met): ss vs. expanded criterion
    if (hom_ss <= hom_c_criterion_expanded) {
      hom_conclusion2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): CUMPLE", hom_ss, hom_c_criterion_expanded)
    } else {
      hom_conclusion2 <- sprintf("ss (%.4f) > c_expanded (%.4f): NO CUMPLE", hom_ss, hom_c_criterion_expanded)
    }

    # Return a comprehensive list containing all results for other reactives to use.
    list(
      summary = hom_anova_summary,
      ss = hom_ss,
      sw = hom_sw,
      conclusion = paste(hom_conclusion1, hom_conclusion2, sep = "<br>"),
      conclusion_class = hom_conclusion_class,
      g = g, m = m,
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

  # R3.5: Stability Data Homogeneity Execution
  # Purpose: This reactive performs the same homogeneity calculations as
  #          `homogeneity_run`, but on the stability dataset. The key check
  #          for stability is comparing the mean of this dataset to the
  #          mean of the original homogeneity data.
  # Inputs: `input$run_analysis`, `stability_data_raw()`, `homogeneity_run()`
  # Outputs: A list of results for the stability assessment.
  homogeneity_run_stability <- eventReactive(input$run_analysis, {
    req(stability_data_raw(), input$target_level, homogeneity_run())
    hom_results <- homogeneity_run()
    hom_x_t_bar <- hom_results$general_mean # Grand mean from initial data for comparison

    data <- stability_data_raw()
    target_level <- input$target_level

    level_data <- data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) return(list(error = "Not enough replicate runs..."))
    if (g < 2) return(list(error = "Not enough items..."))

    intermediate_df <- if (m == 2) {
      s1 <- level_data[[1]]; s2 <- level_data[[2]]
      level_data %>% mutate(Item=row_number(), average=(s1+s2)/2, range=abs(s1-s2)) %>% select(Item, everything())
    } else {
      level_data %>% mutate(Item=row_number(), average=rowMeans(., na.rm=T), range=apply(., 1, function(x) max(x, na.rm=T)-min(x, na.rm=T))) %>% select(Item, everything())
    }

    stab_data <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(cols = -Item, names_to = "replicate", values_to = "Result")

    if (!"sample_1" %in% names(level_data)) return(list(error = "Column 'sample_1' not found..."))
    first_sample_results <- level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff
    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)

    # Manual ANOVA for stability data
    stab_item_stats <- stab_data %>% group_by(Item) %>% summarise(mean=mean(Result, na.rm=T), var=var(Result, na.rm=T), diff=max(Result, na.rm=T)-min(Result, na.rm=T))
    stab_x_t_bar <- mean(stab_item_stats$mean, na.rm = TRUE)
    diff_hom_stab <- abs(stab_x_t_bar - hom_x_t_bar) # Key stability check
    stab_s_x_bar_sq <- var(stab_item_stats$mean, na.rm = TRUE)
    stab_s_xt <- sqrt(stab_s_x_bar_sq)
    stab_wt = abs(stab_item_stats$diff)
    stab_sw <- sqrt(sum(stab_wt^2) / (2 * length(stab_wt)))
    stab_ss_sq <- abs(stab_s_xt^2 - ((stab_sw^2) / 2))
    stab_ss <- sqrt(stab_ss_sq)

    stab_anova_summary_df <- data.frame("Df"=c(g-1, g*(m-1)), "Sum Sq"=c(stab_s_x_bar_sq*m*(g-1), stab_sw^2*g*(m-1)), "Mean Sq"=c(stab_s_x_bar_sq*m, stab_sw^2), check.names=F)
    rownames(stab_anova_summary_df) <- c("Item", "Residuals")
    stab_anova_summary <- stab_anova_summary_df

    # Stability Assessment Criteria: The primary check compares the absolute
    # difference between the two means against the `0.3 * sigma_pt` criterion,
    # as per ISO 13528:2022, Section 7.3.
    stab_sigma_pt <- mad_e
    stab_c_criterion <- 0.3 * hom_results$sigma_pt

    if (diff_hom_stab <= stab_c_criterion) {
      stab_conclusion1 <- sprintf("|mean_1 - mean_2| (%.4f) <= c_criterion (%.4f): CUMPLE", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-success"
    } else {
      stab_conclusion1 <- sprintf("|mean_1 - mean_2| (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO DE ESTABILIDAD", diff_hom_stab, stab_c_criterion)
      stab_conclusion_class <- "alert alert-warning"
    }

    list(
      stab_summary = stab_anova_summary, stab_ss = stab_ss, stab_sw = stab_sw,
      stab_conclusion = stab_conclusion1,
      stab_conclusion_class = stab_conclusion_class,
      g = g, m = m, diff_hom_stab = diff_hom_stab,
      stab_c_criterion = stab_c_criterion,
      stab_sigma_pt = stab_sigma_pt,
      stab_median_val = median_val, stab_median_abs_diff = median_abs_diff,
      stab_u_xpt = u_xpt, n_robust = n_robust, stab_item_means = stab_item_stats$mean,
      stab_general_mean = stab_x_t_bar, stab_sd_of_means = stab_s_xt,
      stab_s_x_bar_sq = stab_s_x_bar_sq, stab_s_w_sq = stab_sw^2,
      stab_intermediate_df = intermediate_df, error = NULL
    )
  })


  # --- Outputs ---
  # The following blocks render the results from the reactive calculations
  # (`homogeneity_run` and `homogeneity_run_stability`) into the UI
  # placeholders defined in the UI section. Each `render*` function is
  # responsible for creating a specific piece of output (e.g., a table,
  # plot, or text).

  # Output: Data Preview Tables for Homogeneity and Stability
  output$raw_data_preview <- renderDataTable({
    req(raw_data())
    df <- head(raw_data(), 10)
    datatable(df, options = list(scrollX = TRUE, pageLength = 5, lengthMenu = c(5, 10, 15))) %>% formatRound(columns=sapply(df, is.numeric), digits=9)
  })
  output$stability_data_preview <- renderDataTable({
    req(stability_data_raw())
    df <- head(stability_data_raw(), 10)
    datatable(df, options = list(scrollX = TRUE, pageLength = 5, lengthMenu = c(5, 10, 15))) %>% formatRound(columns=sapply(df, is.numeric), digits=9)
  })

  # Output: Validation Message
  # Purpose: Provides simple feedback on the loaded data, checking for the
  #          presence of essential columns like `level` and `sample_*`.
  output$validation_message <- renderPrint({
    data <- raw_data()
    cat("Data loaded successfully.\n")
    cat(paste("Dimensions:", paste(dim(data), collapse = " x "), "\n"))
    required_cols <- c("level")
    has_samples <- any(str_detect(names(data), "sample_"))
    if(!all(required_cols %in% names(data))) {
        cat(paste("ERROR: Missing required column(s):", paste(setdiff(required_cols, names(data)), collapse=", "), "\n"))
    } else {
        cat("Found 'level' column.\n")
    }
    if(!has_samples) {
        cat("ERROR: No columns with 'sample_' prefix found. These are needed for the analysis.\n")
    } else {
        cat("Found 'sample_*' columns.\n")
    }
  })

  # Reactive for plotting data: pivots data to long format suitable for ggplot.
  plot_data_long <- reactive({
    req(raw_data())
    if (!"level" %in% names(raw_data())) return(NULL)
    raw_data() %>%
      select(level, starts_with("sample_")) %>%
      pivot_longer(-level, names_to = "sample", values_to = "result")
  })

  # Output: Histogram and Boxplot
  # Purpose: Visualizes the distribution of the results for the selected level,
  #          as recommended by ISO 13528 for initial data exploration.
  output$results_histogram <- renderPlot({
    plot_data <- plot_data_long(); req(plot_data)
    ggplot(plot_data, aes(x = result)) +
      geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 20) +
      geom_density(alpha = 0.4, fill = "lightblue") +
      facet_wrap(~level, scales = "free") +
      labs(title = "Distribution by Level", x = "Result", y = "Density") + theme_minimal()
  })
  output$results_boxplot <- renderPlot({
    plot_data <- plot_data_long(); req(plot_data)
    ggplot(plot_data, aes(x = "", y = result)) +
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      facet_wrap(~level, scales = "free") +
      labs(title = "Boxplot by Level", x = NULL, y = "Result") + theme_minimal()
  })

  # Output: Homogeneity Preview Table
  # Shows the first sample column for the selected level to give a quick
  # view of the data being used for robust calculations.
  output$homogeneity_preview_table <- renderDataTable({
    req(raw_data(), input$target_level)
    homogeneity_data <- raw_data()
    first_sample_col <- names(homogeneity_data)[grep("sample_", names(homogeneity_data))][1]
    df <- homogeneity_data %>%
      filter(level == input$target_level) %>%
      select(level, all_of(first_sample_col))
    datatable(df) %>% formatRound(columns=sapply(df, is.numeric), digits=9)
  })

  # Output: Robust Statistics Tables
  # Displays the intermediate calculations for the robust stats (MADe),
  # enhancing transparency of the `sigma_pt` calculation.
  output$robust_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        `First.Sample.Results` = format(res$first_sample_results, digits = 9),
        `Abs.Diff.from.Median` = format(res$abs_diff_from_median, digits = 9)
      )
    }
  }, spacing = "l")
  output$robust_stats_summary <- renderPrint({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      cat(paste("Median Value (Assigned Value x_pt):", format(res$median_val, digits = 9), "\n"))
      cat(paste("Median Absolute Difference:", format(res$median_abs_diff, digits = 9), "\n"))
      cat(paste("Robust SD (MADe, sigma_pt):", format(res$sigma_pt, digits = 9), "\n"))
    }
  })

  # Output: Homogeneity Conclusion
  # Displays the final conclusion of the homogeneity assessment in a
  # dynamically colored box (green for pass, orange for warning).
  output$homog_conclusion <- renderUI({
    res <- homogeneity_run()
    if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
    } else {
        div(class = res$conclusion_class, HTML(res$conclusion))
    }
  })

  # Output: Variance Components Table (Homogeneity)
  # Summarizes the key statistical components from the homogeneity test,
  # including assigned value, robust SD, ss, sw, and the criteria.
  output$variance_components <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
        data.frame(
          Component = c("Assigned Value (xpt)", "Robust SD (sigma_pt)", "Uncertainty of Assigned Value (u_xpt)", "Between-Sample SD (ss)", "Within-Sample SD (sw)", "---", "Criterion c (0.3*sigma_pt)", "Criterion c (expanded)"),
          Value = format(c(res$median_val, res$sigma_pt, res$u_xpt, res$ss, res$sw, NA, res$c_criterion, res$c_criterion_expanded), digits = 9)
        )
    }
  })

  # Output: Per-Item and Summary Statistics Tables (Homogeneity)
  # Provides detailed, drill-down tables of all calculated values for
  # full transparency and verification.
  output$details_per_item_table <- renderTable({
    res <- homogeneity_run(); if (is.null(res$error)) res$intermediate_df
  }, spacing = "l", digits = 9)
  output$details_summary_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        Parameter = c("General Mean", "SD of Means", "Variance of Means (s_x_bar_sq)", "sw", "Within-Sample Variance (s_w_sq)", "ss", "---", "Assigned Value (xpt)", "Median of Absolute Differences", "Number of Items (g)", "Number of Replicates (m)", "Robust SD (MADe)", "Uncertainty of Assigned Value (u_xpt)", "---", "Criterion c", "Criterion c (expanded)"),
        Value = format(c(res$general_mean, res$sd_of_means, res$s_x_bar_sq, res$sw, res$s_w_sq, res$ss, NA, res$median_val, res$median_abs_diff, res$g, res$m, res$sigma_pt, res$u_xpt, NA, res$c_criterion, res$c_criterion_expanded), digits = 9)
      )
    }
  }, spacing = "l")

  # --- Outputs for Stability Data Analysis Tab ---
  # These outputs mirror the homogeneity outputs but use the results from
  # the `homogeneity_run_stability()` reactive.
  output$homog_conclusion_stability <- renderUI({
    res <- homogeneity_run_stability()
    if (!is.null(res$error)) div(class = "alert alert-danger", res$error)
    else div(class = res$stab_conclusion_class, HTML(res$stab_conclusion))
  })
  output$variance_components_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
        data.frame(
          Component = c("Assigned Value (xpt)", "Robust SD (sigma_pt)", "Uncertainty of Assigned Value (u_xpt)"),
          Value = format(c(res$stab_median_val, res$stab_sigma_pt, res$stab_u_xpt), digits = 9)
        )
    }
  })
  output$details_per_item_table_stability <- renderTable({
    res <- homogeneity_run_stability(); if (is.null(res$error)) res$stab_intermediate_df
  }, spacing = "l", digits = 9)
  output$details_summary_stats_table_stability <- renderTable({
    res <- homogeneity_run_stability()
    if (is.null(res$error)) {
      data.frame(
        Parameter = c("General Mean", "Absolute Difference from General Mean", "SD of Means", "Variance of Means (s_x_bar_sq)", "sw", "Within-Sample Variance (s_w_sq)", "ss", "---", "Assigned Value (xpt)", "Median of Absolute Differences", "Number of Items (g)", "Number of Replicates (m)", "Robust SD (MADe)", "Uncertainty of Assigned Value (u_xpt)", "---", "Criterion c"),
        Value = format(c(res$stab_general_mean, res$diff_hom_stab, res$stab_sd_of_means, res$stab_s_x_bar_sq, res$stab_sw, res$stab_s_w_sq, res$stab_ss, NA, res$stab_median_val, res$stab_median_abs_diff, res$g, res$m, res$stab_sigma_pt, res$stab_u_xpt, NA, res$stab_c_criterion), digits = 9)
      )
    }
  }, spacing = "l")

  # R5: Dynamic UI for PT Preparation Module (Placeholder)
  # This renders a set of numeric inputs for the future "PT Preparation"
  # module. It's currently a non-functional placeholder.
  output$pt_preparation_inputs <- renderUI({
    req(input$pollutant) # Ensure a pollutant is selected
    tagList(
      h4(paste("Enter Data for", input$pollutant)),
      numericInput("avg1", "Average 1:", value = NA),
      numericInput("avg2", "Average 2:", value = NA),
      numericInput("avg3", "Average 3:", value = NA),
      hr(),
      numericInput("unc1", "Uncertainty 1:", value = NA),
      numericInput("unc2", "Uncertainty 2:", value = NA),
      numericInput("unc3", "Uncertainty 3:", value = NA),
      hr(),
      numericInput("k_factor", "Coverage Factor (k):", value = NA)
    )
  })
}

# ===================================================================
# III. Run the Application
# This command combines the UI and Server components into a runnable
# Shiny application.
# ===================================================================
shinyApp(ui = ui, server = server, options = list(launch.browser = FALSE))