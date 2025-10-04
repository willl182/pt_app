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

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(

  # 1. Application Title
  titlePanel("Homogeneity and Stability Assessment for PT Items"),

  # 2. Main Layout: Sidebar
  sidebarLayout(

    # 2.1. Input Panel (Sidebar)
    sidebarPanel(
      width = 3,
      h4("1. Provide Data"),
      radioButtons("input_method", "Input method:",
                   choices = c("Upload File" = "upload", "Paste Text" = "paste"),
                   selected = "upload", inline = TRUE),

      conditionalPanel(
        condition = "input.input_method == 'upload'",
        fileInput("datafile", NULL,
                  accept = c(".csv", ".tsv", ".txt"),
                  placeholder = "Select a CSV/TSV file")
      ),

      conditionalPanel(
        condition = "input.input_method == 'paste'",
        textAreaInput("pasted_data", NULL,
                      placeholder = "level,sample_1,sample_2,...\n2-ppm,1.95,1.98,...",
                      rows = 8),
        radioButtons("paste_delim", "Separator:",
                     choices = c("Comma" = ",", "Tab" = "\t", "Semicolon" = ";"),
                     selected = ",", inline = TRUE)
      ),
      hr(),

      h4("2. Select Parameters"),
      # Dynamic UI to select the level
      uiOutput("level_selector"),

      # Homogeneity method selector
      radioButtons("homog_method", "Homogeneity Method:",
                   choices = c("ANOVA" = "anova", "Alternative 2" = "alt2"),
                   selected = "anova", inline = TRUE),

      hr(),

      h4("3. Run Analysis"),
      # Button to run the analysis
      actionButton("run_analysis", "Run Analysis",
                   class = "btn-primary btn-block"),

      hr(),
      p("This app assesses homogeneity and stability of PT items according to ISO 13528:2022 principles.")
    ),

    # 2.2. Main Panel for Results
    mainPanel(
      width = 9,
      # Outputs organized in tabs
      tabsetPanel(
        id = "analysis_tabs",

        # Tab 1: Data Preview
        tabPanel("Data Preview",
                 h4("Uploaded Data Preview"),
                 p("This table shows the first 10 rows of your uploaded data."),
                 dataTableOutput("raw_data_preview"),
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
                 
                 # Conditional Panel for Alt 2 Results
                 conditionalPanel(
                   condition = "input.homog_method == 'alt2'",
                   h4("Robust Statistics Results (Alt. 2)"),
                   p("Results from the robust median-based analysis."),
                   verbatimTextOutput("alt2_homog_results"),
                   hr()
                 ),

                 h4("ANOVA Results"),
                 p("One-way Analysis of Variance (ANOVA) to test for differences between items."),
                 verbatimTextOutput("aov_summary"),
                 hr(),
                 h4("Variance Components"),
                 p("Estimated standard deviations from the ANOVA model."),
                 tableOutput("variance_components")
        ),

        # Tab 3: Calculation Details
        tabPanel("Calculation Details",
                 h4("Intermediate Calculation Steps"),
                 p("This table shows the breakdown of the homogeneity calculation."),
                 tableOutput("calculation_details_table")
        ),

        # Tab 4: Stability Assessment
        tabPanel("Stability Assessment",
                 h4("Conclusion"),
                 uiOutput("stability_conclusion"),
                 hr(),
                 h4("Stability Analysis Details"),
                 p("Comparison of means between two measurement periods (simulated by splitting data)."),
                 verbatimTextOutput("stability_details"),
                 hr(),
                 h4("T-test for Stability"),
                 p("A two-sample t-test to check for statistically significant differences."),
                 verbatimTextOutput("stability_ttest")
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
             tsv = vroom::vroom(input$datafile$datapath, delim = "\t"),
             txt = vroom::vroom(input$datafile$datapath, delim = ","), # Assuming txt is csv
             validate("Invalid file type. Please upload a .csv or .tsv file.")
      )
    } else { # "paste"
      req(input$pasted_data)
      vroom::vroom(I(input$pasted_data), delim = input$paste_delim)
    }
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
    req(raw_data(), input$target_level, input$homog_method)
    data <- raw_data()
    target_level <- input$target_level

    # Prepare data for analysis
    hom_data <- data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_")) %>%
      mutate(replicate = row_number()) %>%
      pivot_longer(
        cols = -replicate,
        names_to = "Item",
        values_to = "Result",
        names_prefix = "sample_"
      ) %>%
      mutate(Item = factor(as.int(Item)))

    g <- n_distinct(hom_data$Item)
    m <- n_distinct(hom_data$replicate)

    if (m < 2) {
        return(list(error = "Not enough replicate runs (at least 2 required) for homogeneity assessment."))
    }

    # Calculate sigma_pt as MADe from the first item
    first_item_results <- hom_data %>%
      filter(Item == 1) %>%
      pull(Result)
    median_val <- median(first_item_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_item_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    sigma_pt <- 1.483 * median_abs_diff

    # Initialize variables to NULL
    alt2_results <- NULL

    # --- Method Selection ---
    if (input$homog_method == "alt2") {
      # Alternative 2: Robust Statistics using only the first item
      n <- length(first_item_results)
      u_sigmapt <- 1.25 * sigma_pt / sqrt(n)
      
      alt2_results <- list(
        assigned_value = median_val,
        made = sigma_pt, # as sigma_pt is now MADe
        u_sigmapt = u_sigmapt,
        n = n
      )
    }

    # --- Manual ANOVA Calculation --- 
    # Calculate mean and variance for each item
    item_stats <- hom_data %>%
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE)
      )

    # Grand mean
    x_bar_bar <- mean(item_stats$mean, na.rm = TRUE)

    # Variance of item means
    s_x_bar_sq <- var(item_stats$mean, na.rm = TRUE)
    sd_of_means <- sqrt(s_x_bar_sq)

    # Mean of item variances (within-sample variance)
    s_w_sq <- mean(item_stats$var, na.rm = TRUE)
    sw <- sqrt(s_w_sq)

    # Between-sample variance
    ss_sq <- max(0, s_x_bar_sq - s_w_sq / m)
    ss <- sqrt(ss_sq)

    # For display purposes, we can create a data frame that mimics the ANOVA table
    anova_summary_df <- data.frame(
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(s_x_bar_sq * m * (g - 1), s_w_sq * g * (m-1)),
      "Mean Sq" = c(s_x_bar_sq * m, s_w_sq),
      check.names = FALSE
    )
    rownames(anova_summary_df) <- c("Item", "Residuals")

    # For the list returned by the reactive
    anova_summary <- anova_summary_df

    # Assessment Criterion (for ANOVA method)
    hom_criterion_value <- 0.3 * sigma_pt
    sigma_allowed_sq <- hom_criterion_value^2
    
    # New criterion c
    c_criterion <- sqrt(sigma_allowed_sq * 1.88 + (sw^2) * 1.01)

    # First comparison: ss vs 0.3 * sigma_pt
    if (ss <= hom_criterion_value) {
      conclusion1 <- sprintf("ss (%.4f) <= 0.3 * sigma_pt (%.4f): CUMPLE", ss, hom_criterion_value)
      conclusion_class <- "alert alert-success"
    } else {
      conclusion1 <- sprintf("ss (%.4f) > 0.3 * sigma_pt (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", ss, hom_criterion_value)
      conclusion_class <- "alert alert-warning"
    }

    # Second comparison: ss vs c
    if (ss <= c_criterion) {
      conclusion2 <- sprintf("ss (%.4f) <= c (%.4f): CUMPLE", ss, c_criterion)
    } else {
      conclusion2 <- sprintf("ss (%.4f) > c (%.4f): NO CUMPLE", ss, c_criterion)
    }

    # Combine conclusions
    conclusion <- paste(conclusion1, conclusion2, sep = "<br>")

    list(
      summary = anova_summary,
      ss = ss,
      sw = sw,
      conclusion = conclusion,
      conclusion_class = conclusion_class,
      g = g,
      m = m,
      alt2 = alt2_results, # Contains results if method is 'alt2', otherwise NULL
      sigma_allowed_sq = sigma_allowed_sq,
      c_criterion = c_criterion,
      sigma_pt = sigma_pt,
      hom_criterion_value = hom_criterion_value,
      item_means = item_stats$mean,
      general_mean = x_bar_bar,
      sd_of_means = sd_of_means,
      error = NULL
    )
  })

  # R4: Stability Execution (Triggered by button)
  stability_run <- eventReactive(input$run_analysis, {
    req(raw_data(), input$target_level, input$sigma_pt)
    data <- raw_data()
    target_level <- input$target_level
    sigma_pt <- input$sigma_pt

    stab_data_all <- data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    n_runs <- nrow(stab_data_all)
    if (n_runs < 2) {
      return(list(
          error = "Not enough replicate runs (at least 2 required) to perform a stability check.",
          conclusion = "",
          details = "",
          ttest = ""
          ))
    }

    # Split data to simulate time points
    split_point <- floor(n_runs / 2)
    data_t1 <- stab_data_all %>% slice(1:split_point) %>% pivot_longer(everything(), values_to = "Result")
    data_t2 <- stab_data_all %>% slice((split_point + 1):n_runs) %>% pivot_longer(everything(), values_to = "Result")

    y1 <- mean(data_t1$Result, na.rm = TRUE)
    y2 <- mean(data_t2$Result, na.rm = TRUE)
    diff_observed <- abs(y1 - y2)

    # Primary Assessment Criterion
    stab_criterion_value <- 0.3 * sigma_pt

    # Dynamic format for decimal places
    fmt <- "%.9f"

    details_text <- sprintf(
      paste("Mean 'Before' (y1):", fmt, "(using first %d runs)\nMean 'After' (y2):", fmt, "(using last %d runs)\nObserved Absolute Difference:", fmt, "\nStability Criterion (0.3 * sigma_pt):", fmt),
      y1, split_point, y2, n_runs - split_point, diff_observed, stab_criterion_value
    )

    if (diff_observed <= stab_criterion_value) {
      conclusion <- "Conclusion (Criterion B.5.1): PT Items are adequately stable."
      conclusion_class <- "alert alert-success"
    } else {
      conclusion <- "Conclusion (Criterion B.5.1): WARNING: PT Items may show unacceptable drift."
      conclusion_class <- "alert alert-warning"
    }

    # T-test
    t_test_result <- t.test(data_t1$Result, data_t2$Result)
    
    if (t_test_result$p.value > 0.05) {
      ttest_conclusion <- "T-test: No statistically significant difference detected (p > 0.05), supporting stability."
    } else {
      ttest_conclusion <- "T-test: Statistically significant difference detected (p <= 0.05), indicating potential instability."
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

  # Reactive expression for plotting data
  plot_data_long <- reactive({
    req(raw_data(), input$target_level)
    raw_data() %>%
      filter(level == input$target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), names_to = "sample", values_to = "result")
  })

  # Output: Histogram
  output$results_histogram <- renderPlot({
    req(plot_data_long())
    ggplot(plot_data_long(), aes(x = result)) +
      geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 20) +
      geom_density(alpha = 0.4, fill = "lightblue") +
      labs(title = paste("Distribution for Level:", input$target_level),
           x = "Result", y = "Density") +
      theme_minimal()
  })

  # Output: Boxplot
  output$results_boxplot <- renderPlot({
    req(plot_data_long())
    ggplot(plot_data_long(), aes(x = result)) +
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      labs(title = paste("Boxplot for Level:", input$target_level),
           x = "Result") +
      theme_minimal() +
      theme(axis.text.y=element_blank(),
            axis.ticks.y=element_blank(),
            axis.title.y=element_blank())
  })

  # Output: Alternative 2 Homogeneity Results
  output$alt2_homog_results <- renderPrint({
    res <- homogeneity_run()
    if (!is.null(res$alt2)) {
      alt_res <- res$alt2
      dp <- 9
      cat(sprintf("Analysis based on n=%d total results:\n\n", alt_res$n))
      cat(sprintf("Assigned Value (Median): %.*f\n", dp, alt_res$assigned_value))
      cat(sprintf("MADe (Robust SD): %.*f\n", dp, alt_res$made))
      cat(sprintf("Uncertainty from Homogeneity (u_hom): %.*f\n", dp, alt_res$u_sigmapt))
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

  # Output: ANOVA Summary
  output$aov_summary <- renderPrint({
    res <- homogeneity_run()
    if (is.null(res$error)) {
        cat(sprintf("Analysis based on g=%d items and m=%d replicates:\n\n", res$g, res$m))
        print(res$summary, digits = 9)
    }
  })

  # Output: Variance Components
  output$variance_components <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
        values <- c(res$sigma_pt, res$hom_criterion_value, res$ss, res$sw, res$sigma_allowed_sq, res$c_criterion)
        data.frame(
          Component = c("Sigma PT",
                        "0.3 * Sigma PT",
                        "Between-Sample SD (ss)", 
                        "Within-Sample SD (sw)", 
                        "Sigma Allowed Sq", 
                        "Criterion c"),
          Value = format(values, digits = 15, scientific = FALSE)
        )
    }
  })

  # Output: Stability Conclusion
  output$stability_conclusion <- renderUI({
    res <- stability_run()
    if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
    } else {
        div(class = res$conclusion_class, res$conclusion)
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

  # Output: Calculation Details Table
  output$calculation_details_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      # Create a data frame for the item means
      item_means_df <- data.frame(
        Parameter = paste("Item", 1:res$g, "Mean"),
        Value = format(res$item_means, digits = 15, scientific = FALSE)
      )
      
      # Create a data frame for the other parameters
      other_params_df <- data.frame(
        Parameter = c("General Mean", 
                      "SD of Means", 
                      "sw", 
                      "ss", 
                      "0.3 * sigma_pt", 
                      "Criterion c"),
        Value = format(c(res$general_mean, res$sd_of_means, res$sw, res$ss, res$hom_criterion_value, res$c_criterion), digits = 15, scientific = FALSE)
      )
      
      # Combine the data frames
      rbind(item_means_df, other_params_df)
    }
  }, spacing = "l")

}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server)
