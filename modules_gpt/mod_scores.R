#' PT scoring module: calculates z, z', zeta, and En scores for participants.
mod_scores_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      width = 4,
      h4("Select Data"),
      selectInput(ns("pollutant"), "Pollutant:", choices = NULL),
      selectInput(ns("n_lab"), "PT Scheme (n):", choices = NULL),
      selectInput(ns("level"), "Level:", choices = NULL),
      hr(),
      h4("Parameters"),
      numericInput(ns("sigma_pt"), "sigma_pt", value = 5, min = 0, step = 0.01),
      numericInput(ns("u_xpt"), "u(x_pt)", value = 0.5, min = 0, step = 0.01),
      numericInput(ns("k"), "Coverage factor (k)", value = 2, min = 1, step = 1)
    ),
    mainPanel(
      width = 8,
      tabsetPanel(
        tabPanel("Scores Table", dataTableOutput(ns("scores_table")), hr(), verbatimTextOutput(ns("scores_summary"))),
        tabPanel("Z-Score Plot", plotOutput(ns("z_plot"))),
        tabPanel("Z'-Score Plot", plotOutput(ns("zp_plot"))),
        tabPanel("Zeta-Score Plot", plotOutput(ns("zeta_plot"))),
        tabPanel("En-Score Plot", plotOutput(ns("en_plot")))
      )
    )
  )
}

mod_scores_server <- function(id, pt_data, log_action) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    observeEvent(pt_data(), {
      df <- pt_data()
      validate(need(nrow(df) > 0, "No summary files loaded."))
      updateSelectInput(session, "pollutant", choices = sort(unique(df$pollutant)))
    }, ignoreNULL = FALSE)

    observeEvent(list(pt_data(), input$pollutant), {
      req(input$pollutant)
      df <- pt_data() %>% filter(.data$pollutant == input$pollutant)
      updateSelectInput(session, "n_lab", choices = sort(unique(df$n_lab)))
    }, ignoreNULL = FALSE)

    observeEvent(list(pt_data(), input$pollutant, input$n_lab), {
      req(input$pollutant, input$n_lab)
      df <- pt_data() %>% filter(.data$pollutant == input$pollutant, .data$n_lab == input$n_lab)
      updateSelectInput(session, "level", choices = unique(df$level))
    }, ignoreNULL = FALSE)

    selected_data <- reactive({
      req(input$pollutant, input$n_lab, input$level)
      data <- pt_data() %>%
        filter(
          .data$pollutant == input$pollutant,
          .data$n_lab == input$n_lab,
          .data$level == input$level
        )
      validate(need(nrow(data) > 0, "No participant records for selection."))
      data
    })

    score_results <- reactive({
      data <- selected_data()
      ref <- data %>% filter(.data$participant_id == "ref")
      participants <- data %>% filter(.data$participant_id != "ref")
      validate(need(nrow(ref) > 0, "Missing reference participant (ref)."))
      validate(need(nrow(participants) > 0, "No participant data available."))

      x_pt <- mean(ref$mean_value, na.rm = TRUE)
      sigma_pt <- input$sigma_pt
      u_xpt <- input$u_xpt
      k <- input$k

      log_action(sprintf("Scores computed for %s | n = %s | level = %s", input$pollutant, input$n_lab, input$level))

      scores <- participants %>%
        rename(result = mean_value, u_lab = sd_value) %>%
        mutate(
          z = (result - x_pt) / sigma_pt,
          z_eval = dplyr::case_when(
            abs(z) <= 2 ~ "Satisfactory",
            abs(z) < 3 ~ "Questionable",
            TRUE ~ "Unsatisfactory"
          ),
          zp = (result - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
          zp_eval = dplyr::case_when(
            abs(zp) <= 2 ~ "Satisfactory",
            abs(zp) < 3 ~ "Questionable",
            TRUE ~ "Unsatisfactory"
          ),
          zeta = (result - x_pt) / sqrt(u_lab^2 + u_xpt^2),
          zeta_eval = dplyr::case_when(
            abs(zeta) <= 2 ~ "Satisfactory",
            abs(zeta) < 3 ~ "Questionable",
            TRUE ~ "Unsatisfactory"
          ),
          U_xi = k * u_lab,
          U_xpt = k * u_xpt,
          en = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2),
          en_eval = dplyr::case_when(
            abs(en) <= 1 ~ "Satisfactory",
            TRUE ~ "Unsatisfactory"
          )
        )

      list(scores = scores, x_pt = x_pt, sigma_pt = sigma_pt, u_xpt = u_xpt, k = k)
    })

    output$scores_table <- renderDataTable({
      res <- score_results()
      display <- res$scores %>%
        select(
          Participant = participant_id,
          Result = result,
          `u(xi)` = u_lab,
          `z-score` = z,
          `z-score Eval` = z_eval,
          `z'-score` = zp,
          `z'-score Eval` = zp_eval,
          `zeta-score` = zeta,
          `zeta-score Eval` = zeta_eval,
          `En-score` = en,
          `En-score Eval` = en_eval
        )
      datatable(display, options = list(scrollX = TRUE, pageLength = 10)) %>%
        formatRound(columns = c("Result", "u(xi)", "z-score", "z'-score", "zeta-score", "En-score"), digits = 3) %>%
        formatStyle('z-score Eval', backgroundColor = styleEqual(c("Satisfactory", "Questionable", "Unsatisfactory"), c("#d4edda", "#fff3cd", "#f8d7da"))) %>%
        formatStyle("z'-score Eval", backgroundColor = styleEqual(c("Satisfactory", "Questionable", "Unsatisfactory"), c("#d4edda", "#fff3cd", "#f8d7da"))) %>%
        formatStyle("zeta-score Eval", backgroundColor = styleEqual(c("Satisfactory", "Questionable", "Unsatisfactory"), c("#d4edda", "#fff3cd", "#f8d7da"))) %>%
        formatStyle("En-score Eval", backgroundColor = styleEqual(c("Satisfactory", "Unsatisfactory"), c("#d4edda", "#f8d7da")))
    })

    output$scores_summary <- renderPrint({
      res <- score_results()
      cat(sprintf("Assigned value (x_pt): %.4f\n", res$x_pt))
      cat(sprintf("sigma_pt: %.4f\n", res$sigma_pt))
      cat(sprintf("u(x_pt): %.4f\n", res$u_xpt))
      cat(sprintf("Coverage factor (k): %d\n", res$k))
    })

    plot_scores <- function(data, score_col, title, limits) {
      limit_layers <- purrr::map(limits, ~ geom_hline(yintercept = .x$value, linetype = "dashed", color = .x$color))
      ggplot(data, aes(x = reorder(participant_id, .data[[score_col]]), y = .data[[score_col]])) +
        geom_point(size = 3, color = "#005BBB") +
        geom_segment(aes(xend = reorder(participant_id, .data[[score_col]]), yend = 0), color = "#005BBB") +
        geom_hline(yintercept = 0, linetype = "solid", color = "grey50") +
        limit_layers +
        labs(x = "Participant", y = title) +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
    }

    output$z_plot <- renderPlot({
      res <- score_results()
      plot_scores(res$scores, "z", "Z-Score", list(list(value = 2, color = "orange"), list(value = -2, color = "orange"), list(value = 3, color = "red"), list(value = -3, color = "red")))
    })

    output$zp_plot <- renderPlot({
      res <- score_results()
      plot_scores(res$scores, "zp", "Z'-Score", list(list(value = 2, color = "orange"), list(value = -2, color = "orange"), list(value = 3, color = "red"), list(value = -3, color = "red")))
    })

    output$zeta_plot <- renderPlot({
      res <- score_results()
      plot_scores(res$scores, "zeta", "Zeta-Score", list(list(value = 2, color = "orange"), list(value = -2, color = "orange"), list(value = 3, color = "red"), list(value = -3, color = "red")))
    })

    output$en_plot <- renderPlot({
      res <- score_results()
      plot_scores(res$scores, "en", "En-Score", list(list(value = 1, color = "red"), list(value = -1, color = "red")))
    })
  })
}
