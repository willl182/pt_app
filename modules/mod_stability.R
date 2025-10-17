# ===================================================================
# Stability Analysis Module
#
# This module provides the UI and server logic for conducting
# stability assessments according to ISO 13528:2022.
#
# Author: Jules
# ===================================================================

# -- UI Function
stabilityUI <- function(id) {
  ns <- NS(id)

  tabPanel("Stability Assessment",
    h4("Conclusion"),
    uiOutput(ns("stability_conclusion")),
    hr(),
    h4("Stability Details"),
    verbatimTextOutput(ns("stability_details")),
    hr(),
    h4("T-test Summary"),
    verbatimTextOutput(ns("stability_ttest"))
  )
}

# -- Server Function
stabilityServer <- function(id, hom_run, stab_data_full, selected_pollutant, selected_level) {
  moduleServer(id, function(input, output, session) {

    stability_run <- eventReactive(c(selected_pollutant(), selected_level()), {
      hom_results <- hom_run()
      req(hom_results, is.null(hom_results$error), stab_data_full, selected_pollutant(), selected_level())

      stab_data_level <- stab_data_full %>%
        filter(pollutant == selected_pollutant(), level == selected_level())

      if(nrow(stab_data_level) == 0) {
        return(list(error = "No stability data available for this selection."))
      }

      # Calculate mean of stability data
      y2 <- mean(stab_data_level$value, na.rm = TRUE)
      y1 <- hom_results$general_mean

      diff_observed <- abs(y1 - y2)
      stab_criterion_value <- hom_results$c_criterion # 0.3 * sigma_pt from homogeneity

      details_text <- sprintf(
        "Mean of Homogeneity Data (y1): %.4f\nMean of Stability Data (y2): %.4f\nObserved Absolute Difference: %.4f\nStability Criterion (0.3 * sigma_pt): %.4f",
        y1, y2, diff_observed, stab_criterion_value
      )

      conclusion <- if (diff_observed <= stab_criterion_value) {
        "Conclusion: The item is adequately stable."
      } else {
        "Conclusion: WARNING: The item may be unstable."
      }
      conclusion_class <- if (diff_observed <= stab_criterion_value) "alert alert-success" else "alert alert-warning"

      # T-test
      hom_data_long <- hom_results$intermediate_df %>%
        pivot_longer(cols = -Item, names_to = "replicate", values_to = "Result")

      t_test_result <- t.test(hom_data_long$Result, stab_data_level$value)

      ttest_conclusion <- if (t_test_result$p.value > 0.05) {
        "T-test: No statistically significant difference detected (p > 0.05), supporting stability."
      } else {
        "T-test: Statistically significant difference detected (p <= 0.05), indicating potential instability."
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

    output$stability_conclusion <- renderUI({
      res <- stability_run()
      req(res)
      if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
      } else {
        div(class = res$conclusion_class, HTML(res$conclusion))
      }
    })

    output$stability_details <- renderPrint({
      res <- stability_run()
      req(res, is.null(res$error))
      cat(res$details)
    })

    output$stability_ttest <- renderPrint({
      res <- stability_run()
      req(res, is.null(res$error))
      cat(res$ttest_conclusion, "\n\n")
      print(res$ttest_summary)
    })
  })
}