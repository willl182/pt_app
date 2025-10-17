#' Homogeneity analysis module aligned with ISO 13528:2022 Annex B
#' This module prepares preview tables, robust statistics, and variance
#' component estimates for the selected pollutant/level combination.
#'
#' @param id Module id.
#' @param hom_data Reactive expression that returns the homogeneity data
#'   (data frame with columns pollutant, level, replicate, sample_id, value).
#' @param stability_data Reactive expression that returns the stability data.
#' @param log_action Logging callback defined in the main app.
mod_homogeneity_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("Homogeneity Assessment"),
    bsCollapse(
      id = ns("hom_collapse"),
      bsCollapsePanel(
        title = "Analysis Controls",
        value = TRUE,
        fluidRow(
          column(
            width = 6,
            selectInput(ns("pollutant"), "Select Pollutant:", choices = NULL)
          ),
          column(
            width = 6,
            selectInput(ns("level"), "Select PT Level:", choices = NULL)
          )
        ),
        actionButton(ns("run_analysis"), "Run Homogeneity Analysis", class = "btn btn-primary"),
        helpText("Calculations follow SOP v3.1 (Homogeneity, Section 4) and ISO 13528:2022 Annex B.")
      )
    ),
    tabsetPanel(
      id = ns("hom_tabs"),
      tabPanel(
        title = "Data Preview",
        fluidRow(
          column(12, h4("Homogeneity Dataset"), dataTableOutput(ns("raw_data_preview")))
        ),
        hr(),
        fluidRow(
          column(12, h4("Stability Dataset"), dataTableOutput(ns("stability_data_preview")))
        ),
        hr(),
        h4("Result Distributions"),
        fluidRow(
          column(6, plotOutput(ns("results_histogram"))),
          column(6, plotOutput(ns("results_boxplot")))
        ),
        hr(),
        verbatimTextOutput(ns("validation_message"))
      ),
      tabPanel(
        title = "Homogeneity Results",
        uiOutput(ns("homog_conclusion")),
        hr(),
        h4("Robust Statistics"),
        tableOutput(ns("robust_stats_table")),
        verbatimTextOutput(ns("robust_stats_summary")),
        hr(),
        h4("Variance Components"),
        tableOutput(ns("variance_components")),
        hr(),
        h4("Per-Item Calculations"),
        tableOutput(ns("details_per_item_table")),
        hr(),
        h4("Summary Statistics"),
        tableOutput(ns("details_summary_stats_table"))
      )
    )
  )
}

mod_homogeneity_server <- function(id, hom_data, stability_data, log_action) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Update pollutant selection whenever new data arrive
    observeEvent(hom_data(), {
      df <- hom_data()
      validate(need(nrow(df) > 0, "Homogeneity dataset is empty."))
      updateSelectInput(session, "pollutant", choices = sort(unique(df$pollutant)))
    }, ignoreNULL = FALSE)

    # Update level selection based on pollutant choice
    observeEvent(list(hom_data(), input$pollutant), {
      req(input$pollutant)
      df <- hom_data()
      levels <- df %>%
        filter(.data$pollutant == input$pollutant) %>%
        pull(level) %>%
        unique() %>%
        sort()
      updateSelectInput(session, "level", choices = levels)
    }, ignoreNULL = FALSE)

    # Helper reactive: filtered homogeneity data for selected pollutant/level
    hom_filtered <- reactive({
      req(input$pollutant)
      hom_data() %>%
        filter(.data$pollutant == input$pollutant)
    })

    hom_filtered_level <- reactive({
      req(input$level)
      hom_filtered() %>%
        filter(.data$level == input$level)
    })

    stability_filtered_level <- reactive({
      req(input$pollutant, input$level)
      stability_data() %>%
        filter(.data$pollutant == input$pollutant, .data$level == input$level)
    })

    # Utility that expands replicate columns and prepares descriptive tables
    prepare_wide_table <- function(df) {
      validate(need(nrow(df) > 0, "No records found for the selected combination."))
      df %>%
        mutate(sample_id = factor(.data$sample_id)) %>%
        arrange(.data$sample_id, .data$replicate) %>%
        pivot_wider(
          names_from = replicate,
          values_from = value,
          names_prefix = "sample_"
        ) %>%
        arrange(.data$sample_id)
    }

    # Render previews
    output$raw_data_preview <- renderDataTable({
      df <- hom_filtered_level()
      dt <- prepare_wide_table(df)
      datatable(dt, options = list(pageLength = 10, scrollX = TRUE))
    })

    output$stability_data_preview <- renderDataTable({
      df <- stability_filtered_level()
      validate(need(nrow(df) > 0, "No stability data for selected pollutant/level."))
      dt <- prepare_wide_table(df)
      datatable(dt, options = list(pageLength = 10, scrollX = TRUE))
    })

    # Diagnostic plots follow ISO 13528 guidance for data screening (Annex A)
    output$results_histogram <- renderPlot({
      df <- hom_filtered_level()
      validate(need(nrow(df) > 0, "No homogeneity data available for histogram."))
      ggplot(df, aes(x = value)) +
        geom_histogram(fill = "#0073C2", color = "white", bins = 15) +
        labs(title = "Distribution of replicate measurements", x = "Value", y = "Frequency") +
        theme_minimal()
    })

    output$results_boxplot <- renderPlot({
      df <- hom_filtered_level()
      validate(need(nrow(df) > 0, "No homogeneity data available for boxplot."))
      ggplot(df, aes(x = factor(replicate), y = value)) +
        geom_boxplot(fill = "#00A08A") +
        labs(title = "Replicate comparison", x = "Replicate", y = "Value") +
        theme_minimal()
    })

    output$validation_message <- renderPrint({
      df <- hom_filtered_level()
      g <- df %>% distinct(sample_id) %>% nrow()
      m <- df %>% distinct(replicate) %>% nrow()
      cat(sprintf("Items (g): %d | Replicates (m): %d", g, m))
      if (g < 2) cat("\nWarning: fewer than two PT items (ISO 13528 Annex B requires g >= 2)")
      if (m < 2) cat("\nWarning: fewer than two replicates (ISO 13528 Annex B requires m >= 2)")
    })

    # Compute homogeneity metrics once the user requests analysis
    analysis <- eventReactive(input$run_analysis, {
      log_action(sprintf("Homogeneity analysis requested for %s - %s", input$pollutant, input$level))
      df <- hom_filtered_level()
      validate(need(nrow(df) > 0, "Homogeneity dataset is empty for the selected level."))

      wide_df <- prepare_wide_table(df)
      replicate_cols <- grep("^sample_", names(wide_df), value = TRUE)
      g <- nrow(wide_df)
      m <- length(replicate_cols)

      validate(need(m >= 2, "At least two replicates are required."))
      validate(need(g >= 2, "At least two PT items are required."))

      homogeneity_level_data <- wide_df %>%
        select(all_of(replicate_cols))

      intermediate_df <- if (m == 2) {
        s1 <- homogeneity_level_data[[1]]
        s2 <- homogeneity_level_data[[2]]
        homogeneity_level_data %>%
          mutate(
            Item = dplyr::row_number(),
            average = (s1 + s2) / 2,
            range = abs(s1 - s2)
          ) %>%
          relocate(Item)
      } else {
        homogeneity_level_data %>%
          mutate(Item = dplyr::row_number()) %>%
          mutate(
            average = rowMeans(select(., -Item), na.rm = TRUE),
            range = apply(select(., -Item), 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
          ) %>%
          relocate(Item)
      }

      hom_data_long <- homogeneity_level_data %>%
        mutate(Item = factor(dplyr::row_number())) %>%
        pivot_longer(
          cols = -Item,
          names_to = "replicate",
          values_to = "Result"
        )

      item_stats <- hom_data_long %>%
        group_by(Item) %>%
        summarise(mean = mean(Result, na.rm = TRUE), .groups = "drop")

      grand_mean <- mean(item_stats$mean, na.rm = TRUE)

      ss_between <- m * sum((item_stats$mean - grand_mean)^2, na.rm = TRUE)

      ss_within <- hom_data_long %>%
        group_by(Item) %>%
        summarise(ss = sum((Result - mean(Result, na.rm = TRUE))^2, na.rm = TRUE), .groups = "drop") %>%
        summarise(total = sum(ss, na.rm = TRUE)) %>%
        pull(total)

      df_between <- g - 1
      df_within <- g * (m - 1)
      ms_between <- if (df_between > 0) ss_between / df_between else NA_real_
      ms_within <- if (df_within > 0) ss_within / df_within else NA_real_

      sw <- sqrt(ms_within)
      ss <- if (is.na(ms_between) || is.na(ms_within) || ms_between <= ms_within) {
        0
      } else {
        sqrt((ms_between - ms_within) / m)
      }

      first_sample <- homogeneity_level_data[[1]]
      robust_median <- median(first_sample, na.rm = TRUE)
      robust_made <- mad(first_sample, constant = 1.4826, na.rm = TRUE)
      robust_niqr <- calc_niqr(first_sample)
      alg_a <- algorithm_A(first_sample)

      sigma_pt <- robust_made
      criterion <- 0.3 * sigma_pt
      sigma2_allow <- criterion^2

      f_values <- get_f_factors(g)
      c_threshold <- if (!is.null(f_values)) f_values$F1 * sigma2_allow + f_values$F2 * ms_within else NA_real_

      primary_pass <- !is.na(ss) && ss <= criterion
      secondary_pass <- if (is.na(c_threshold) || is.na(ms_between)) NA else ms_between <= c_threshold

      conclusion_class <- if (!is.na(primary_pass) && primary_pass) "alert alert-success" else "alert alert-warning"
      conclusion_text <- sprintf("s_s = %.4f, Criterion (0.3 * sigma_pt) = %.4f", ss, criterion)
      if (!is.na(secondary_pass)) {
        conclusion_text <- paste0(
          conclusion_text,
          if (secondary_pass) "\nExpanded criterion satisfied (MS_between <= c)." else "\nExpanded criterion NOT satisfied."
        )
      }

      intermediate_table <- wide_df %>%
        mutate(Item = dplyr::row_number()) %>%
        mutate(
          average = rowMeans(select(., all_of(replicate_cols)), na.rm = TRUE),
          range = apply(select(., all_of(replicate_cols)), 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        ) %>%
        select(Item, all_of(replicate_cols), average, range)

      summary_table <- tibble::tibble(
        Metric = c("Items (g)", "Replicates (m)", "Grand mean", "MS_between", "MS_within", "s_w", "s_s", "sigma_pt", "Criterion"),
        Value = c(g, m, grand_mean, ms_between, ms_within, sw, ss, sigma_pt, criterion)
      )

      robust_table <- tibble::tibble(
        Statistic = c("Median (x*)", "MADe (s*)", "nIQR", "Algorithm A mean", "Algorithm A sd", "Iterations"),
        Value = c(robust_median, robust_made, robust_niqr, alg_a$robust_mean, alg_a$robust_sd, alg_a$iterations)
      )

      variance_table <- tibble::tibble(
        Component = c("Between items (s_s)", "Within items (s_w)", "ISO Criterion (0.3 * sigma_pt)", "Expanded Criterion c"),
        Estimate = c(ss, sw, criterion, c_threshold)
      )

      list(
        g = g,
        m = m,
        sigma_pt = sigma_pt,
        criterion = criterion,
        c_criterion = criterion,
        conclusion_class = conclusion_class,
        conclusion_text = conclusion_text,
        variance_table = variance_table,
        intermediate_table = intermediate_table,
        intermediate_df = intermediate_df,
        summary_table = summary_table,
        robust_table = robust_table,
        ms_between = ms_between,
        ms_within = ms_within,
        c_threshold = c_threshold,
        grand_mean = grand_mean,
        general_mean = grand_mean,
        item_means = item_stats$mean,
        first_sample_results = first_sample
      )
    })

    output$homog_conclusion <- renderUI({
      req(analysis())
      res <- analysis()
      div(class = res$conclusion_class, res$conclusion_text)
    })

    output$robust_stats_table <- renderTable({
      req(analysis())
      analysis()$robust_table
    })

    output$robust_stats_summary <- renderPrint({
      req(analysis())
      res <- analysis()
      cat("Robust estimators (ISO 13528 Annex C):\n")
      cat(sprintf("Median (x*): %.6f\n", res$robust_table$Value[res$robust_table$Statistic == "Median (x*)"]))
      cat(sprintf("MADe (s*): %.6f\n", res$robust_table$Value[res$robust_table$Statistic == "MADe (s*)"]))
      cat(sprintf("nIQR: %.6f\n", res$robust_table$Value[res$robust_table$Statistic == "nIQR"]))
      cat(sprintf("Algorithm A converged in %d iterations.\n", res$robust_table$Value[res$robust_table$Statistic == "Iterations"]))
    })

    output$variance_components <- renderTable({
      req(analysis())
      analysis()$variance_table
    })

    output$details_per_item_table <- renderTable({
      req(analysis())
      analysis()$intermediate_table
    }, striped = TRUE, bordered = TRUE, spacing = "s")

    output$details_summary_stats_table <- renderTable({
      req(analysis())
      analysis()$summary_table
    })

    list(
      selection = reactive(list(pollutant = input$pollutant, level = input$level)),
      analysis = analysis
    )
  })
}
