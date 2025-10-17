# ===================================================================
# Homogeneity Analysis Module
#
# This module provides the UI and server logic for conducting
# homogeneity assessments according to ISO 13528:2022.
#
# Author: Jules
# ===================================================================

# -- UI Function
homogeneityUI <- function(id) {
  ns <- NS(id)

  tabPanel("Homogeneity Assessment",
    h4("Conclusion"),
    uiOutput(ns("homog_conclusion")),
    hr(),
    h4("Homogeneity Data Preview (Level and First Sample)"),
    dataTableOutput(ns("homogeneity_preview_table")),
    hr(),
    h4("Robust Statistics Calculations"),
    tableOutput(ns("robust_stats_table")),
    verbatimTextOutput(ns("robust_stats_summary")),
    hr(),
    h4("Variance Components"),
    p("Estimated standard deviations from the manual calculation."),
    tableOutput(ns("variance_components")),
    hr(),
    h4("Per-Item Calculations"),
    p("This table shows calculations for each item (row) in the dataset for the selected level, including the average and range of measurements."),
    tableOutput(ns("details_per_item_table")),
    hr(),
    h4("Summary Statistics"),
    p("This table shows the overall statistics for the homogeneity assessment."),
    tableOutput(ns("details_summary_stats_table"))
  )
}

# -- Server Function
homogeneityServer <- function(id, hom_data_full, selected_pollutant, selected_level) {
  moduleServer(id, function(input, output, session) {

    # R1: Reactive for Homogeneity Data
    raw_data <- reactive({
      req(selected_pollutant())
      hom_data_full %>%
        filter(pollutant == selected_pollutant()) %>%
        select(-pollutant) %>%
        pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
    })

    # R3: Homogeneity Execution
    homogeneity_run <- eventReactive(c(selected_pollutant(), selected_level()), {
      req(raw_data(), selected_level())

      homogeneity_data <- raw_data()
      target_level <- selected_level()

      homogeneity_level_data <- homogeneity_data %>%
        filter(level == target_level) %>%
        select(starts_with("sample_"))

      g <- nrow(homogeneity_level_data)
      m <- ncol(homogeneity_level_data)

      if (m < 2) return(list(error = "Not enough replicate runs (at least 2 required)."))
      if (g < 2) return(list(error = "Not enough items (at least 2 required)."))

      intermediate_df <- if (m == 2) {
        s1 <- homogeneity_level_data[[1]]
        s2 <- homogeneity_level_data[[2]]
        homogeneity_level_data %>%
          mutate(Item = row_number(), average = (s1 + s2) / 2, range = abs(s1 - s2)) %>%
          select(Item, everything())
      } else {
        homogeneity_level_data %>%
          mutate(
            Item = row_number(),
            average = rowMeans(., na.rm = TRUE),
            range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
          ) %>%
          select(Item, everything())
      }

      hom_data_long <- homogeneity_level_data %>%
        mutate(Item = factor(row_number())) %>%
        pivot_longer(cols = -Item, names_to = "replicate", values_to = "Result")

      first_sample_results <- homogeneity_level_data %>% pull(1)

      # Robust stats
      median_val <- median(first_sample_results, na.rm = TRUE)
      mad_e_val <- mad_e_manual(first_sample_results)
      niqr_val <- nIQR_manual(first_sample_results)
      alg_a_res <- algorithm_A(first_sample_results)

      # Manual ANOVA
      item_stats <- hom_data_long %>%
        group_by(Item) %>%
        summarise(mean = mean(Result, na.rm = TRUE), .groups = 'drop')

      grand_mean <- mean(item_stats$mean, na.rm = TRUE)
      ss_between <- m * sum((item_stats$mean - grand_mean)^2)
      ss_within <- sum(
        (hom_data_long %>% group_by(Item) %>% mutate(mean_item = mean(Result)) %>% ungroup() %>%
           mutate(dev_sq = (Result - mean_item)^2))$dev_sq
      )

      ms_b <- ss_between / (g - 1)
      ms_w <- ss_within / (g * (m - 1))

      s_s <- if (ms_b < ms_w) 0 else sqrt((ms_b - ms_w) / m)
      s_w <- sqrt(ms_w)

      # Use MADe as the default sigma_pt
      sigma_pt <- mad_e_val
      c_criterion <- 0.3 * sigma_pt

      conclusion <- if (s_s <= c_criterion) {
        sprintf("ss (%.4f) <= 0.3 * sigma_pt (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", s_s, c_criterion)
      } else {
        sprintf("ss (%.4f) > 0.3 * sigma_pt (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", s_s, c_criterion)
      }

      conclusion_class <- if (s_s <= c_criterion) "alert alert-success" else "alert alert-warning"

      list(
        ss = s_s, sw = s_w, conclusion = conclusion, conclusion_class = conclusion_class,
        g = g, m = m, sigma_pt = sigma_pt, c_criterion = c_criterion,
        median_val = median_val, mad_e = mad_e_val, niqr = niqr_val, alg_a = alg_a_res,
        item_means = item_stats$mean, general_mean = grand_mean,
        intermediate_df = intermediate_df, first_sample_results = first_sample_results,
        error = NULL
      )
    })

    # Outputs
    output$homog_conclusion <- renderUI({
      res <- homogeneity_run()
      req(res)
      if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
      } else {
        div(class = res$conclusion_class, HTML(res$conclusion))
      }
    })

    output$homogeneity_preview_table <- renderDataTable({
      req(raw_data(), selected_level())
      df <- raw_data() %>% filter(level == selected_level())
      datatable(df, options = list(scrollX = TRUE, pageLength = 5))
    })

    output$robust_stats_table <- renderTable({
      res <- homogeneity_run()
      req(res, is.null(res$error))
      data.frame(
        Estimator = c("Median", "MADe", "nIQR", "Algorithm A (mean)", "Algorithm A (sd)"),
        Value = c(res$median_val, res$mad_e, res$niqr, res$alg_a$robust_mean, res$alg_a$robust_sd)
      )
    })

    output$variance_components <- renderTable({
      res <- homogeneity_run()
      req(res, is.null(res$error))
      data.frame(
        Component = c("Between-Sample SD (ss)", "Within-Sample SD (sw)", "Criterion (0.3 * sigma_pt)"),
        Value = c(res$ss, res$sw, res$c_criterion)
      )
    })

    output$details_per_item_table <- renderTable({
      res <- homogeneity_run()
      req(res, is.null(res$error))
      res$intermediate_df
    }, spacing = "l", digits = 5)

    output$details_summary_stats_table <- renderTable({
      res <- homogeneity_run()
      req(res, is.null(res$error))
      data.frame(
        Parameter = c("General Mean", "Number of Items (g)", "Number of Replicates (m)", "Selected sigma_pt (MADe)"),
        Value = c(res$general_mean, res$g, res$m, res$sigma_pt)
      )
    })

    return(homogeneity_run) # Return the reactive to be used by other modules
  })
}