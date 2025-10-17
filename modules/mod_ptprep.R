# ===================================================================
# PT Preparation Module
#
# This module provides the UI and server logic for analyzing and
# visualizing participant results from different PT schemes.
#
# Author: Jules
# ===================================================================

# -- UI Function
ptprepUI <- function(id) {
  ns <- NS(id)

  tabPanel("PT Preparation",
    h3("Proficiency Testing Scheme Analysis"),
    p("Analysis of participant results from different PT schemes, based on summary data files."),
    uiOutput(ns("pt_pollutant_tabs"))
  )
}

# -- Server Function
ptprepServer <- function(id, pt_prep_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$pt_pollutant_tabs <- renderUI({
      req(pt_prep_data())
      if (is.null(pt_prep_data()) || nrow(pt_prep_data()) == 0) {
        return(p("No summary data files found or files are empty."))
      }
      pollutants <- unique(pt_prep_data()$pollutant)

      tabs <- lapply(pollutants, function(p) {
        tabPanel(toupper(p),
          sidebarLayout(
            sidebarPanel(
              width = 4,
              h4(paste("Options for", toupper(p))),
              uiOutput(ns(paste0("pt_n_selector_", p))),
              uiOutput(ns(paste0("pt_level_selector_", p))),
              hr(),
              h4("Summary Information"),
              verbatimTextOutput(ns(paste0("pt_summary_", p)))
            ),
            mainPanel(
              width = 8,
              plotOutput(ns(paste0("pt_plot_", p))),
              hr(),
              dataTableOutput(ns(paste0("pt_table_", p)))
            )
          )
        )
      })
      do.call(tabsetPanel, c(list(id = ns("pt_main_tabs")), tabs))
    })

    observe({
      req(pt_prep_data())
      if (is.null(pt_prep_data()) || nrow(pt_prep_data()) == 0) return()

      pollutants <- unique(pt_prep_data()$pollutant)

      lapply(pollutants, function(p) {
        local({
          pollutant_name <- p

          output[[paste0("pt_n_selector_", pollutant_name)]] <- renderUI({
            choices <- unique(pt_prep_data()[pt_prep_data()$pollutant == pollutant_name, "n_lab"])
            selectInput(ns(paste0("n_lab_", pollutant_name)), "Select PT Scheme (by n):", choices = sort(choices))
          })

          output[[paste0("pt_level_selector_", pollutant_name)]] <- renderUI({
            req(input[[paste0("n_lab_", pollutant_name)]])
            choices <- pt_prep_data() %>%
              filter(pollutant == pollutant_name, n_lab == input[[paste0("n_lab_", pollutant_name)]]) %>%
              pull(level) %>%
              unique()
            selectInput(ns(paste0("level_", pollutant_name)), "Select Level:", choices = choices)
          })

          filtered_data <- reactive({
            req(input[[paste0("n_lab_", pollutant_name)]], input[[paste0("level_", pollutant_name)]])
            pt_prep_data() %>%
              filter(
                pollutant == pollutant_name,
                n_lab == input[[paste0("n_lab_", pollutant_name)]],
                level == input[[paste0("level_", pollutant_name)]]
              )
          })

          output[[paste0("pt_summary_", pollutant_name)]] <- renderPrint({
            data <- filtered_data()
            req(nrow(data) > 0)
            cat(
              "Pollutant:", pollutant_name, "\n",
              "PT Scheme (n_lab):", unique(data$n_lab), "\n",
              "Level:", unique(data$level), "\n",
              "Participants:", n_distinct(data$participant_id[data$participant_id != "ref"])
            )
          })

          output[[paste0("pt_plot_", pollutant_name)]] <- renderPlot({
            data <- filtered_data()
            req(nrow(data) > 0)
            ggplot(data, aes(x = participant_id, y = mean_value, fill = sample_group)) +
              geom_bar(stat = "identity", position = "dodge") +
              geom_errorbar(aes(ymin = mean_value - sd_value, ymax = mean_value + sd_value), width = 0.2, position = position_dodge(0.9)) +
              labs(title = "Participant Mean Values with SD", x = "Participant", y = "Mean Value") +
              theme_minimal()
          })

          output[[paste0("pt_table_", pollutant_name)]] <- renderDataTable({
            data <- filtered_data()
            req(nrow(data) > 0)
            datatable(data, options = list(scrollX = TRUE, pageLength = 5))
          })
        })
      })
    })
  })
}