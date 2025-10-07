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

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(

  # 1. Application Title
  titlePanel("PT Data Analysis App"),

  # 2. Main Layout: Vertical Navigation
  navlistPanel(
    id = "main_nav",
    "Analysis Modules",

    # Module 1: Homogeneity and Stability
    tabPanel("Homogeneity & Stability Analysis",
      sidebarLayout(
        # 2.1. Input Panel (Sidebar)
        sidebarPanel(
          width = 2, # Adjusted width for the new layout
          h4("1. Cargue de Datos (Provide Data)"),
          radioButtons("input_method", "Input method:",
                       choices = c("Cargar Archivo (Upload File)" = "upload",
                                   "Editar Tabla (Editable Table)" = "table"),
                       selected = "upload", inline = TRUE),

          conditionalPanel(
            condition = "input.input_method == 'upload'",
            tagList(
              fileInput("datafile", "Homogeneity Data",
                        accept = c(".csv", ".tsv", ".txt"),
                        placeholder = "Select a CSV/TSV file"),
            )
          ),

          conditionalPanel(
            condition = "input.input_method == 'table'",
            h5("Homogeneity Data"),
            numericInput("num_rows_hom", "Rows:", 10, min = 1),
            numericInput("num_cols_hom", "Cols:", 3, min = 1),
          ),

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
          width = 10, # Adjusted width for the new layout
          # Outputs organized in tabs
          tabsetPanel(
            id = "analysis_tabs",

            # Tab 1: Data Preview
            tabPanel("Data Preview",
                     h4("Data Input Preview"),
                     conditionalPanel(
                       condition = "input.input_method != 'table'",
                       p("This table shows the first 10 rows of your loaded data."),
                       dataTableOutput("raw_data_preview")
                     ),
                     conditionalPanel(
                       condition = "input.input_method == 'table'",
                       h4("Homogeneity Data"),
                       p("Enter your data in the table below. The first column should be 'level' and subsequent columns should be named 'sample_1', 'sample_2', etc."),
                       rHandsontableOutput("hot_homogeneity"),
                     ),
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

          )
        )
      )
    ),

    # Module 2: PT Preparation
    tabPanel("PT Preparation",
      sidebarLayout(
        sidebarPanel(
          h3("Proficiency Testing Preparation"),
          selectInput("pollutant", "Select Pollutant:",
                      choices = c("CO", "NO", "NO2", "O3", "SO2")),
          # Dynamic UI for the input fields will be rendered here
          uiOutput("pt_preparation_inputs")
        ),
        mainPanel(
          # This area can be used for results or plots later
          h4("Output Area"),
          p("Results and calculations will be displayed here.")
        )
      )
    )
  )
)

# ===================================================================
# II. Server Logic
# ===================================================================
server <- function(input, output, session) {

  # R1: Initial Data Loading and Processing
  raw_data <- reactive({
    if (input$input_method == "upload") {
      req(input$datafile)
      ext <- tools::file_ext(input$datafile$name)
      switch(ext,
             csv = vroom::vroom(input$datafile$datapath, delim = ","),
             tsv = vroom::vroom(input$datafile$datapath, delim = "	"),
             txt = vroom::vroom(input$datafile$datapath, delim = ","), # Assuming txt is csv
             validate("Invalid file type. Please upload a .csv or .tsv file.")
      )
    } else { # "table"
      req(input$hot_homogeneity)
      df <- hot_to_r(input$hot_homogeneity)
      colnames(df) <- c("level", paste0("sample_", 1:(ncol(df)-1)))
      df <- df %>%
        mutate(across(starts_with("sample_"), .fns = ~as.numeric(as.character(.))))
      df
    }
  })

  # R1.5: Render the editable rhandsontable for homogeneity
  output$hot_homogeneity <- renderRHandsontable({
    req(input$num_rows_hom, input$num_cols_hom)
    df <- data.frame(matrix("", nrow = input$num_rows_hom, ncol = input$num_cols_hom), stringsAsFactors = FALSE)
    colnames(df) <- c("level", paste0("sample_", 1:(input$num_cols_hom-1)))
    rhandsontable(df, stretchH = "all")
  })

  # R1.5b: Render the editable rhandsontable for stability
  output$hot_stability <- renderRHandsontable({
    req(input$num_rows_stab, input$num_cols_stab)
    df <- data.frame(matrix("", nrow = input$num_rows_stab, ncol = input$num_cols_stab), stringsAsFactors = FALSE)
    colnames(df) <- c("level", paste0("sample_", 1:(input$num_cols_stab-1)))
    rhandsontable(df, stretchH = "all")
  })


  # R2: Dynamic Generation of the Level Selector
  output$level_selector <- renderUI({
    data <- raw_data()
    if ("level" %in% names(data)) {
      levels <- unique(data$level)
      selectInput("target_level", "2. Select PT Level", choices = levels, selected = levels[1])
    } else {
      p("Column 'level' not found in the uploaded data.")
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
        return(list(error = "Not enough replicate runs (at least 2 required) for homogeneity assessment."))
    }
    if (g < 2) {
        return(list(error = "Not enough items (at least 2 required) for homogeneity assessment."))
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
        return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt."))
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
    hom_ss_sq <- abs(hom_s_xt^2 - ((hom_sw^2) / 2))
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
      hom_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-success"
    } else {
      hom_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
      hom_conclusion_class <- "alert alert-warning"
    }

    # Second comparison: ss vs c_expanded
    if (hom_ss <= hom_c_criterion_expanded) {
      hom_conclusion2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): CUMPLE", hom_ss, hom_c_criterion_expanded)
    } else {
      hom_conclusion2 <- sprintf("ss (%.4f) > c_expanded (%.4f): NO CUMPLE", hom_ss, hom_c_criterion_expanded)
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
    req(stability_data_raw(), input$target_level)
    data <- stability_data_raw()
    target_level <- input$target_level

    # Prepare data for analysis
    level_data <- data %>%
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
        return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt for stability data."))
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
    stab_c_criterion <- 0.3 * stab_sigma_pt
    stab_sigma_allowed_sq <- stab_c_criterion^2

    # Expanded criterion
    stab_c_criterion_expanded <- sqrt(stab_sigma_allowed_sq * 1.88 + (stab_sw^2) * 1.01)

    # First comparison: ss vs c_criterion (0.3 * sigma_pt)
    if (stab_ss <= stab_c_criterion) {
      stab_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE", stab_ss, stab_c_criterion)
      stab_conclusion_class <- "alert alert-success"
    } else {
      stab_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", stab_ss, stab_c_criterion)
      stab_conclusion_class <- "alert alert-warning"
    }

    # Second comparison: ss vs c_expanded
    if (stab_ss <= stab_c_criterion_expanded) {
      stab_conclusion2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): CUMPLE", stab_ss, stab_c_criterion_expanded)
    } else {
      stab_conclusion2 <- sprintf("ss (%.4f) > c_expanded (%.4f): NO CUMPLE", stab_ss, stab_c_criterion_expanded)
    }

    # Combine conclusions
    stab_conclusion <- paste(stab_conclusion1, stab_conclusion2, sep = "<br>")
    list(
      stab_summary = stab_anova_summary,
      stab_ss = stab_ss,
      stab_sw = stab_sw,
      stab_conclusion = stab_conclusion,
      stab_conclusion_class = stab_conclusion_class,
      g = g,
      m = m,
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
    # Ensure we have data and the decimal place input before rendering
    req(raw_data())

    df <- head(raw_data(), 10)

    # Identify numeric columns to format
    numeric_cols <- names(df)[sapply(df, is.numeric)]

    # Create the format string based on user input
    fmt <- "%.9f"

    # Apply formatting to all numeric columns
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
        `First.Sample.Results` = format(res$first_sample_results, digits = 15, scientific = FALSE),
        `Abs.Diff.from.Median` = format(res$abs_diff_from_median, digits = 15, scientific = FALSE)
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
                      "Number of Replicates (n_robust)",
                      "Robust SD (MADe)",
                      "Uncertainty of Assigned Value (u_xpt)",
                      "---",
                      "Criterion c",
                      "Criterion c (expanded)"),
        Value = c(
          format(c(res$general_mean, res$sd_of_means, res$s_x_bar_sq, res$sw, res$s_w_sq, res$ss), digits = 15, scientific = FALSE),
          "",
          format(c(res$median_val, res$median_abs_diff, res$n_robust, res$sigma_pt, res$u_xpt), digits = 15, scientific = FALSE),
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
                        "Uncertainty of Assigned Value (u_xpt)",
                        "Between-Sample SD (ss)",
                        "Within-Sample SD (sw)",
                        "---",
                        "Criterion c",
                        "Criterion c (expanded)"),
          Value = c(
            format(c(res$stab_median_val, res$stab_sigma_pt, res$stab_u_xpt, res$stab_ss, res$stab_sw), digits = 15, scientific = FALSE),
            "",
            format(c(res$stab_c_criterion, res$stab_c_criterion_expanded), digits = 15, scientific = FALSE)
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
                      "SD of Means",
                      "Variance of Means (s_x_bar_sq)",
                      "sw",
                      "Within-Sample Variance (s_w_sq)",
                      "ss",
                      "---",
                      "Assigned Value (xpt)",
                      "Median of Absolute Differences",
                      "Number of Replicates (n_robust)",
                      "Robust SD (MADe)",
                      "Uncertainty of Assigned Value (u_xpt)",
                      "---",
                      "Criterion c",
                      "Criterion c (expanded)"),
        Value = c(
          format(c(res$stab_general_mean, res$stab_sd_of_means, res$stab_s_x_bar_sq, res$stab_sw, res$stab_s_w_sq, res$stab_ss), digits = 15, scientific = FALSE),
          "",
          format(c(res$stab_median_val, res$stab_median_abs_diff, res$n_robust, res$stab_sigma_pt, res$stab_u_xpt), digits = 15, scientific = FALSE),
          "",
          format(c(res$stab_c_criterion, res$stab_c_criterion_expanded), digits = 15, scientific = FALSE)
        )
      )
    }
  }, spacing = "l")

  # R5: Dynamic UI for PT Preparation Module
  output$pt_preparation_inputs <- renderUI({
    req(input$pollutant) # Ensure a pollutant is selected
    tagList(
      h4(paste("Enter Data for", input$pollutant)),
      # 3 empty cells for 3 averages
      numericInput("avg1", "Average 1:", value = NA),
      numericInput("avg2", "Average 2:", value = NA),
      numericInput("avg3", "Average 3:", value = NA),
      hr(),
      # 3 empty cells for uncertainty
      numericInput("unc1", "Uncertainty 1:", value = NA),
      numericInput("unc2", "Uncertainty 2:", value = NA),
      numericInput("unc3", "Uncertainty 3:", value = NA),
      hr(),
      # final cell for coverage factor
      numericInput("k_factor", "Coverage Factor (k):", value = NA)
    )
  })
}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server, options = list(launch.browser = FALSE))
