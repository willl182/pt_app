#' Stability analysis module using ISO 13528:2022 Annex B.5 comparisons.
#' This module consumes the homogeneity results (sigma_pt, selection) and
#' performs the difference-in-means stability verification.
mod_stability_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("Stability Assessment"),
    bsCollapse(
      id = ns("stab_panel"),
      bsCollapsePanel(
        title = "Stability Overview",
        value = TRUE,
        helpText("Stability is evaluated once homogeneity results are available. No additional input is required."),
        verbatimTextOutput(ns("stability_summary"))
      )
    ),
    tabsetPanel(
      id = ns("stab_tabs"),
      tabPanel(
        title = "Stability Results",
        uiOutput(ns("stability_conclusion")),
        hr(),
        h4("Variance Components"),
        tableOutput(ns("variance_components_stability")),
        hr(),
        h4("Per-Item Calculations"),
        tableOutput(ns("details_per_item_table_stability")),
        hr(),
        h4("Summary Statistics"),
        tableOutput(ns("details_summary_stats_table_stability"))
      )
    )
  )
}

mod_stability_server <- function(id, stability_data, hom_shared, log_action) {
  moduleServer(id, function(input, output, session) {
    req(stability_data)

    selection <- reactive({
      req(hom_shared$selection())
      hom_shared$selection()
    })

    stability_filtered_level <- reactive({
      req(selection())
      stability_data() %>%
        filter(
          .data$pollutant == selection()$pollutant,
          .data$level == selection()$level
        )
    })

    analysis <- reactive({
      req(hom_shared$analysis())
      hom_results <- hom_shared$analysis()
      df <- stability_filtered_level()
      validate(need(nrow(df) > 0, "No stability data available for the current selection."))

      wide_df <- df %>%
        mutate(sample_id = factor(.data$sample_id)) %>%
        arrange(.data$sample_id, .data$replicate) %>%
        pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_") %>%
        arrange(.data$sample_id)

      replicate_cols <- grep("^sample_", names(wide_df), value = TRUE)
      g <- nrow(wide_df)
      m <- length(replicate_cols)
      validate(need(m >= 2, "At least two replicates are required for stability evaluation."))
      validate(need(g >= 2, "At least two PT items are required for stability evaluation."))

      matrix_values <- as.matrix(wide_df[, replicate_cols])
      item_means <- rowMeans(matrix_values, na.rm = TRUE)
      grand_mean <- mean(matrix_values, na.rm = TRUE)

      ss_between <- m * sum((item_means - grand_mean)^2, na.rm = TRUE)
      ss_within <- sum(apply(matrix_values, 1, function(row) {
        mean_row <- mean(row, na.rm = TRUE)
        sum((row - mean_row)^2, na.rm = TRUE)
      }), na.rm = TRUE)

      df_between <- g - 1
      df_within <- g * (m - 1)
      ms_between <- if (df_between > 0) ss_between / df_between else NA_real_
      ms_within <- if (df_within > 0) ss_within / df_within else NA_real_

      sw <- sqrt(ms_within)
      ss <- if (is.na(ms_between) || ms_between <= ms_within) {
        0
      } else {
        sqrt((ms_between - ms_within) / m)
      }

      diff_mean <- abs(hom_results$grand_mean - grand_mean)
      criterion <- 0.3 * hom_results$sigma_pt
      passes <- diff_mean <= criterion

      conclusion_class <- if (passes) "alert alert-success" else "alert alert-warning"
      conclusion_text <- sprintf(
        "|y1 - y2| = %.6f vs 0.3*sigma_pt = %.6f",
        diff_mean,
        criterion
      )

      log_action(sprintf("Stability assessment performed for %s - %s", selection()$pollutant, selection()$level))

      intermediate_table <- wide_df %>%
        mutate(
          Item = .data$sample_id,
          average = rowMeans(across(all_of(replicate_cols)), na.rm = TRUE),
          range = apply(across(all_of(replicate_cols)), 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        ) %>%
        select(Item, all_of(replicate_cols), average, range)

      summary_table <- tibble::tibble(
        Metric = c("Items (g)", "Replicates (m)", "Grand mean", "MS_between", "MS_within", "s_w", "s_s", "|y1 - y2|", "Criterion"),
        Value = c(g, m, grand_mean, ms_between, ms_within, sw, ss, diff_mean, criterion)
      )

      variance_table <- tibble::tibble(
        Component = c("Between items (s_s)", "Within items (s_w)", "|y1 - y2|", "0.3 * sigma_pt"),
        Estimate = c(ss, sw, diff_mean, criterion)
      )

      list(
        conclusion_class = conclusion_class,
        conclusion_text = conclusion_text,
        variance_table = variance_table,
        intermediate_table = intermediate_table,
        summary_table = summary_table
      )
    })

    output$stability_summary <- renderPrint({
      req(selection())
      cat(sprintf("Current selection: %s - %s", selection()$pollutant, selection()$level))
      cat("\nRun the homogeneity analysis to refresh stability results.")
    })

    output$stability_conclusion <- renderUI({
      if (is.null(hom_shared$analysis())) {
        return(div(class = "alert alert-info", "Run Homogeneity Analysis to see stability results."))
      }
      req(analysis())
      res <- analysis()
      div(class = res$conclusion_class, res$conclusion_text)
    })

    output$variance_components_stability <- renderTable({
      if (is.null(hom_shared$analysis())) {
        return(tibble::tibble(Message = "Run Homogeneity Analysis to see variance components."))
      }
      req(analysis())
      analysis()$variance_table
    })

    output$details_per_item_table_stability <- renderTable({
      if (is.null(hom_shared$analysis())) {
        return(tibble::tibble(Message = "Run Homogeneity Analysis to see per-item calculations."))
      }
      req(analysis())
      analysis()$intermediate_table
    }, striped = TRUE, bordered = TRUE, spacing = "s")

    output$details_summary_stats_table_stability <- renderTable({
      if (is.null(hom_shared$analysis())) {
        return(tibble::tibble(Message = "Run Homogeneity Analysis to see summary statistics."))
      }
      req(analysis())
      analysis()$summary_table
    })
  })
}
