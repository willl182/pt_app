# ===================================================================
# PT Scores Module
#
# This module provides the UI and server logic for calculating and
# visualizing participant performance scores (z, z', zeta, En).
#
# Author: Jules
# ===================================================================

# -- UI Function
scoresUI <- function(id) {
  ns <- NS(id)

  tabPanel("PT Scores",
    sidebarLayout(
      sidebarPanel(
        width = 4,
        h4("1. Select Data"),
        uiOutput(ns("scores_pollutant_selector")),
        uiOutput(ns("scores_n_selector")),
        uiOutput(ns("scores_level_selector")),
        hr(),
        h4("2. Set Parameters"),
        numericInput(ns("scores_sigma_pt"), "Std. Dev. for PT (sigma_pt):", value = 5, step = 0.1),
        numericInput(ns("scores_u_xpt"), "Std. Uncertainty of Assigned Value (u_xpt):", value = 0.5, step = 0.01),
        numericInput(ns("scores_k"), "Coverage Factor (k) for En-Score:", value = 2, min = 1, step = 1)
      ),
      mainPanel(
        width = 8,
        tabsetPanel(
          id = ns("scores_tabs"),
          tabPanel("Scores Table",
                   h4("Calculated Proficiency Scores"),
                   dataTableOutput(ns("scores_table")),
                   hr(),
                   h4("Summary of Inputs"),
                   verbatimTextOutput(ns("scores_inputs_summary"))
          ),
          tabPanel("Z-Score Plot", plotOutput(ns("z_score_plot"))),
          tabPanel("Z'-Score Plot", plotOutput(ns("z_prime_score_plot"))),
          tabPanel("Zeta-Score Plot", plotOutput(ns("zeta_score_plot"))),
          tabPanel("En-Score Plot", plotOutput(ns("en_score_plot")))
        )
      )
    )
  )
}

# -- Server Function
scoresServer <- function(id, pt_prep_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$scores_pollutant_selector <- renderUI({
      req(pt_prep_data())
      choices <- unique(pt_prep_data()$pollutant)
      selectInput(ns("scores_pollutant"), "Select Pollutant:", choices = choices)
    })

    output$scores_n_selector <- renderUI({
      req(pt_prep_data(), input$scores_pollutant)
      choices <- pt_prep_data() %>%
        filter(pollutant == input$scores_pollutant) %>%
        pull(n_lab) %>%
        unique() %>%
        sort()
      selectInput(ns("scores_n_lab"), "Select PT Scheme (by n):", choices = choices)
    })

    output$scores_level_selector <- renderUI({
      req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab)
      choices <- pt_prep_data() %>%
        filter(pollutant == input$scores_pollutant, n_lab == input$scores_n_lab) %>%
        pull(level) %>%
        unique()
      selectInput(ns("scores_level"), "Select Level:", choices = choices)
    })

    scores_run <- reactive({
      req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab, input$scores_level,
          input$scores_sigma_pt, input$scores_u_xpt, input$scores_k)

      data <- pt_prep_data() %>%
        filter(
          pollutant == input$scores_pollutant,
          n_lab == input$scores_n_lab,
          level == input$scores_level
        )

      if (nrow(data) == 0) return(list(error = "No data for selection."))

      ref_data <- data %>% filter(participant_id == "ref")
      participant_data <- data %>% filter(participant_id != "ref")

      if (nrow(ref_data) == 0) return(list(error = "No reference data found."))

      x_pt <- mean(ref_data$mean_value, na.rm = TRUE)

      final_scores <- participant_data %>%
        rename(result = mean_value, uncertainty_std = sd_value) %>%
        mutate(
          z_score = (result - x_pt) / input$scores_sigma_pt,
          z_prime_score = (result - x_pt) / sqrt(input$scores_sigma_pt^2 + input$scores_u_xpt^2),
          zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + input$scores_u_xpt^2),
          U_xi = input$scores_k * uncertainty_std,
          U_xpt = input$scores_k * input$scores_u_xpt,
          En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
        )

      list(
        scores = final_scores, x_pt = x_pt, error = NULL
      )
    })

    output$scores_table <- renderDataTable({
      res <- scores_run()
      req(res, is.null(res$error))
      datatable(res$scores, options = list(scrollX = TRUE))
    })

    output$scores_inputs_summary <- renderPrint({
      res <- scores_run()
      req(res, is.null(res$error))
      cat(sprintf("Assigned Value (x_pt): %.4f\n", res$x_pt))
      cat(sprintf("Std. Dev. for PT (sigma_pt): %.4f\n", input$scores_sigma_pt))
      cat(sprintf("Std. Unc. of Assigned Value (u_xpt): %.4f\n", input$scores_u_xpt))
      cat(sprintf("Coverage Factor (k): %d", input$scores_k))
    })

    # Plots
    output$z_score_plot <- renderPlot({
      res <- scores_run(); req(res, is.null(res$error))
      ggplot(res$scores, aes(x = reorder(participant_id, z_score), y = z_score)) +
        geom_hline(yintercept = c(-3, -2, 2, 3), linetype = "dashed", color = c("red", "orange", "orange", "red")) +
        geom_point(size = 3, color = "blue") + labs(title = "Z-Scores", x = "Participant", y = "Z-Score") + theme_minimal()
    })
    output$z_prime_score_plot <- renderPlot({
      res <- scores_run(); req(res, is.null(res$error))
      ggplot(res$scores, aes(x = reorder(participant_id, z_prime_score), y = z_prime_score)) +
        geom_hline(yintercept = c(-3, -2, 2, 3), linetype = "dashed", color = c("red", "orange", "orange", "red")) +
        geom_point(size = 3, color = "cyan4") + labs(title = "Z'-Scores", x = "Participant", y = "Z'-Score") + theme_minimal()
    })
    output$zeta_score_plot <- renderPlot({
      res <- scores_run(); req(res, is.null(res$error))
      ggplot(res$scores, aes(x = reorder(participant_id, zeta_score), y = zeta_score)) +
        geom_hline(yintercept = c(-3, -2, 2, 3), linetype = "dashed", color = c("red", "orange", "orange", "red")) +
        geom_point(size = 3, color = "darkgreen") + labs(title = "Zeta-Scores", x = "Participant", y = "Zeta-Score") + theme_minimal()
    })
    output$en_score_plot <- renderPlot({
      res <- scores_run(); req(res, is.null(res$error))
      ggplot(res$scores, aes(x = reorder(participant_id, En_score), y = En_score)) +
        geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "red") +
        geom_point(size = 3, color = "purple") + labs(title = "En-Scores", x = "Participant", y = "En-Score") + theme_minimal()
    })
  })
}