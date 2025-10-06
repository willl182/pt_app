# R/homogeneity_stability_report_module.R

homogeneity_stability_report_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("Homogeneity and Stability Assessment Report"),
    p("This report shows the analysis for each level present in the uploaded data."),
    actionButton(ns("generate_report"), "Generate Report", class = "btn-primary"),
    hr(),
    uiOutput(ns("report_content"))
  )
}

homogeneity_stability_report_server <- function(id, raw_data_hom, raw_data_stab) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    report_data <- eventReactive(input$generate_report, {
      print("--- Generating Report ---")
      req(raw_data_hom(), raw_data_stab())

      hom_data <- raw_data_hom()
      stab_data <- raw_data_stab()

      if (!"level" %in% names(hom_data) || !"level" %in% names(stab_data)) {
        print("Error: 'level' column missing in one or both datasets.")
        return(list(error = "Both datasets must contain a 'level' column."))
      }

      unique_levels <- unique(intersect(hom_data$level, stab_data$level))

      if (length(unique_levels) == 0) {
        print("Error: No common levels found.")
        return(list(error = "No common levels found between the homogeneity and stability datasets."))
      }

      results_list <- list()

      for (current_level in unique_levels) {
        print(paste("--- Analyzing Level:", current_level, "---"))

        tryCatch({
          # --- 1. Homogeneity Analysis ---
          print(paste("Level", current_level, ": Starting homogeneity analysis."))
          hom_level_data <- hom_data %>%
            filter(level == current_level) %>%
            select(starts_with("sample_"))

          g_hom <- nrow(hom_level_data)
          m_hom <- ncol(hom_level_data)

          if (g_hom < 2 || m_hom < 2) {
            print(paste("Level", current_level, ": Skipping, not enough data for homogeneity analysis."))
            next
          }

          hom_long <- hom_level_data %>%
              mutate(Item = factor(row_number())) %>%
              pivot_longer(cols = -Item, names_to = "replicate", values_to = "Result")

          hom_item_stats <- hom_long %>%
              group_by(Item) %>%
              summarise(mean = mean(Result, na.rm = TRUE), diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE))

          hom_x_t_bar <- mean(hom_item_stats$mean, na.rm = TRUE)
          hom_s_x_bar_sq <- var(hom_item_stats$mean, na.rm = TRUE)
          hom_s_xt <- sqrt(hom_s_x_bar_sq)
          hom_wt <- abs(hom_item_stats$diff)
          hom_sw <- sqrt(sum(hom_wt^2) / (2 * length(hom_wt)))
          hom_ss_sq <- abs(hom_s_xt^2 - ((hom_sw^2) / 2))
          hom_ss <- sqrt(hom_ss_sq)

          if (!"sample_1" %in% names(hom_level_data)) {
            print(paste("Level", current_level, ": Error, 'sample_1' column not found for homogeneity data."))
            return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt."))
          }
          first_sample_results_hom <- hom_level_data %>% pull("sample_1")
          median_val_hom <- median(first_sample_results_hom, na.rm = TRUE)
          mad_e_hom <- 1.483 * median(abs(first_sample_results_hom - median_val_hom), na.rm = TRUE)
          hom_sigma_pt <- mad_e_hom
          hom_c_criterion <- 0.3 * hom_sigma_pt
          print(paste("Level", current_level, ": Homogeneity analysis complete."))

          # --- 2. Stability Analysis ---
          print(paste("Level", current_level, ": Starting stability analysis."))
          stab_level_data <- stab_data %>%
            filter(level == current_level) %>%
            select(starts_with("sample_"))

          g_stab <- nrow(stab_level_data)
          m_stab <- ncol(stab_level_data)

          if (g_stab < 2 || m_stab < 2) {
            print(paste("Level", current_level, ": Skipping, not enough data for stability analysis."))
            next
          }

          stab_long <- stab_level_data %>%
              mutate(Item = factor(row_number())) %>%
              pivot_longer(cols = -Item, names_to = "replicate", values_to = "Result")

          stab_item_stats <- stab_long %>%
              group_by(Item) %>%
              summarise(mean = mean(Result, na.rm = TRUE))

          stab_x_t_bar <- mean(stab_item_stats$mean, na.rm = TRUE)
          print(paste("Level", current_level, ": Stability analysis complete."))

          # --- 3. Stability Assessment ---
          print(paste("Level", current_level, ": Starting stability assessment."))
          diff_observed <- abs(hom_x_t_bar - stab_x_t_bar)
          stab_criterion_value <- 0.3 * hom_sigma_pt

          stability_conclusion <- if (diff_observed <= stab_criterion_value) {
            "The item is adequately stable."
          } else {
            "WARNING: The item may be unstable."
          }
          print(paste("Level", current_level, ": Stability assessment complete."))

          # --- 4. Store results ---
          results_list[[as.character(current_level)]] <- list(
            level = current_level,
            hom_data_for_plot = hom_long,
            hom_ss = hom_ss,
            hom_c_criterion = hom_c_criterion,
            hom_conclusion = ifelse(hom_ss <= hom_c_criterion, "CUMPLE", "NO CUMPLE"),
            stab_conclusion = stability_conclusion,
            hom_results_table = data.frame(
                Parameter = c("Between-Sample SD (ss)", "Criterion (0.3 * sigma_pt)"),
                Value = c(hom_ss, hom_c_criterion)
            ),
            stab_results_table = data.frame(
                Parameter = c("Mean Homogeneity", "Mean Stability", "Observed Difference", "Criterion (0.3 * sigma_pt)"),
                Value = c(hom_x_t_bar, stab_x_t_bar, diff_observed, stab_criterion_value)
            )
          )
          print(paste("--- Level", current_level, "analysis successful ---"))

        }, error = function(e) {
          print(paste("Error processing level:", current_level, "-", e$message))
          results_list[[as.character(current_level)]] <<- list(error = paste("Failed to process level:", current_level, ". Error:", e$message))
        })
      }
      print("--- Report generation finished ---")
      return(results_list)
    })

    output$report_content <- renderUI({
      results <- report_data()
      if (is.null(results)) return(p("Click 'Generate Report' to see the results."))
      if (!is.null(results$error)) return(div(class="alert alert-danger", results$error))

      tag_list <- lapply(names(results), function(level_name) {
        level_results <- results[[level_name]]

        if (!is.null(level_results$error)) {
          return(tagList(
            h4(paste("Error for Level:", level_name)),
            div(class="alert alert-danger", level_results$error)
          ))
        }

        hist_id <- ns(paste0("hist_", level_results$level))
        box_id <- ns(paste0("box_", level_results$level))

        output[[paste0("hist_", level_results$level)]] <- renderPlot({
          ggplot(level_results$hom_data_for_plot, aes(x = Result)) +
            geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 20) +
            geom_density(alpha = 0.4, fill = "lightblue") +
            labs(title = paste("Distribution for Level:", level_results$level), x = "Result", y = "Density") +
            theme_minimal()
        })

        output[[paste0("box_", level_results$level)]] <- renderPlot({
          ggplot(level_results$hom_data_for_plot, aes(x = "", y = Result)) +
            geom_boxplot(fill = "lightgreen") +
            labs(title = paste("Boxplot for Level:", level_results$level), y = "Result") +
            theme_minimal()
        })

        tagList(
          h4(paste("Results for Level:", level_results$level)),
          fluidRow(
            column(6, plotOutput(hist_id)),
            column(6, plotOutput(box_id))
          ),
          h5("Homogeneity Assessment"),
          p(paste("Conclusion:", level_results$hom_conclusion)),
          tableOutput(ns(paste0("hom_table_", level_results$level))),
          h5("Stability Assessment"),
          p(paste("Conclusion:", level_results$stab_conclusion)),
          tableOutput(ns(paste0("stab_table_", level_results$level))),
          hr()
        )
      })

      for (level_name in names(results)) {
        if (is.null(results[[level_name]]$error)) {
          local({
            level_results <- results[[level_name]]
            output[[paste0("hom_table_", level_results$level)]] <- renderTable({ level_results$hom_results_table })
            output[[paste0("stab_table_", level_results$level)]] <- renderTable({ level_results$stab_results_table })
          })
        }
      }

      do.call(tagList, tag_list)
    })
  })
}