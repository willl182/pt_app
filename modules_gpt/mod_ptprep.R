#' PT preparation module: renders pollutant-specific tabs with plots/tables.
mod_ptprep_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h3("PT Preparation"),
    uiOutput(ns("pt_pollutant_tabs"))
  )
}

mod_ptprep_server <- function(id, pt_data, log_action) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$pt_pollutant_tabs <- renderUI({
      df <- pt_data()
      validate(need(nrow(df) > 0, "No summary files (summary_n*.csv) detected."))
      pollutants <- sort(unique(df$pollutant))

      tabs <- lapply(pollutants, function(p) {
        tabPanel(
          title = toupper(p),
          sidebarLayout(
            sidebarPanel(
              width = 4,
              h4(sprintf("Options for %s", toupper(p))),
              selectInput(ns(paste0("n_lab_", p)), "Select PT Scheme (n):", choices = NULL),
              selectInput(ns(paste0("level_", p)), "Select Level:", choices = NULL),
              hr(),
              verbatimTextOutput(ns(paste0("summary_", p)))
            ),
            mainPanel(
              width = 8,
              h4("Participant Results Plot"),
              plotOutput(ns(paste0("plot_", p))),
              hr(),
              h4("Data Table"),
              dataTableOutput(ns(paste0("table_", p))),
              hr(),
              h4("Results Distribution"),
              fluidRow(
                column(6, plotOutput(ns(paste0("hist_", p)))),
                column(6, plotOutput(ns(paste0("box_", p))))
              ),
              hr(),
              h4("Kernel Density"),
              plotOutput(ns(paste0("density_", p))),
              hr(),
              h4("Run Chart"),
              plotOutput(ns(paste0("run_", p)))
            )
          )
        )
      })

      do.call(tabsetPanel, c(list(id = ns("pt_tabs")), tabs))
    })

    observe({
      df <- pt_data()
      req(nrow(df) > 0)
      pollutants <- unique(df$pollutant)

      lapply(pollutants, function(pollutant_name) {
        local({
          p <- pollutant_name
          observeEvent(pt_data(), {
            data_p <- pt_data() %>% filter(.data$pollutant == p)
            choices <- sort(unique(data_p$n_lab))
            updateSelectInput(session, paste0("n_lab_", p), choices = choices, selected = choices[1])
          }, ignoreNULL = FALSE)

          observeEvent(list(pt_data(), input[[paste0("n_lab_", p)]]), {
            req(input[[paste0("n_lab_", p)]])
            data_p <- pt_data() %>% filter(.data$pollutant == p, .data$n_lab == input[[paste0("n_lab_", p)]])
            levels <- unique(data_p$level)
            updateSelectInput(session, paste0("level_", p), choices = levels, selected = levels[1])
          }, ignoreNULL = FALSE)

          selected_data <- reactive({
            req(input[[paste0("n_lab_", p)]], input[[paste0("level_", p)]])
            pt_data() %>%
              filter(
                .data$pollutant == p,
                .data$n_lab == input[[paste0("n_lab_", p)]],
                .data$level == input[[paste0("level_", p)]]
              ) %>%
              arrange(participant_id) %>%
              mutate(order_idx = dplyr::row_number())
          })

          output[[paste0("summary_", p)]] <- renderPrint({
            data <- selected_data()
            validate(need(nrow(data) > 0, "No participant data available."))
            log_action(sprintf("PT prep summary accessed for %s | n = %s | level = %s", p, unique(data$n_lab), unique(data$level)))
            n_participants <- dplyr::n_distinct(data$participant_id[data$participant_id != "ref"])
            cat(sprintf("Participants: %d\n", n_participants))
            cat(sprintf("Assigned value (ref mean): %.4f\n", mean(data$mean_value[data$participant_id == "ref"], na.rm = TRUE)))
          })

          output[[paste0("plot_", p)]] <- renderPlot({
            data <- selected_data()
            validate(need(nrow(data) > 0, "No participant data available."))
            ggplot(data, aes(x = participant_id, y = mean_value, fill = sample_group)) +
              geom_col(position = position_dodge()) +
              geom_errorbar(aes(ymin = mean_value - sd_value, ymax = mean_value + sd_value), width = 0.2, position = position_dodge(0.9)) +
              labs(x = "Participant", y = "Mean Value") +
              theme_minimal() +
              theme(axis.text.x = element_text(angle = 45, hjust = 1))
          })

          output[[paste0("table_", p)]] <- renderDataTable({
            data <- selected_data()
            validate(need(nrow(data) > 0, "No participant data available."))
            datatable(data, options = list(scrollX = TRUE, pageLength = 10))
          })

          output[[paste0("hist_", p)]] <- renderPlot({
            data <- selected_data()
            validate(need(nrow(data) > 0, "No participant data available."))
            participants <- data %>% filter(.data$participant_id != "ref")
            ref_value <- data %>% filter(.data$participant_id == "ref") %>% summarise(ref_mean = mean(mean_value, na.rm = TRUE)) %>% pull()
            ggplot(participants, aes(x = mean_value)) +
              geom_histogram(aes(y = after_stat(density)), bins = 15, fill = "#56B4E9", color = "white") +
              geom_vline(xintercept = ref_value, linetype = "dashed", color = "red") +
              labs(x = "Mean Value", y = "Density") +
              theme_minimal()
          })

          output[[paste0("box_", p)]] <- renderPlot({
            data <- selected_data()
            validate(need(nrow(data) > 0, "No participant data available."))
            participants <- data %>% filter(.data$participant_id != "ref")
            ref_value <- data %>% filter(.data$participant_id == "ref") %>% summarise(ref_mean = mean(mean_value, na.rm = TRUE)) %>% pull()
            ggplot(participants, aes(x = "", y = mean_value)) +
              geom_boxplot(fill = "#009E73") +
              geom_hline(yintercept = ref_value, color = "red", linetype = "dashed") +
              labs(y = "Mean Value") +
              theme_minimal()
          })

          output[[paste0("density_", p)]] <- renderPlot({
            data <- selected_data()
            validate(need(nrow(data) > 0, "No participant data available."))
            participants <- data %>% filter(.data$participant_id != "ref")
            ref_value <- data %>% filter(.data$participant_id == "ref") %>% summarise(ref_mean = mean(mean_value, na.rm = TRUE)) %>% pull()
            ggplot(participants, aes(x = mean_value)) +
              geom_density(fill = "#E69F00", alpha = 0.4) +
              geom_vline(xintercept = ref_value, color = "red", linetype = "dashed") +
              labs(x = "Mean Value", y = "Density") +
              theme_minimal()
          })

          output[[paste0("run_", p)]] <- renderPlot({
            data <- selected_data()
            validate(need(nrow(data) > 0, "No participant data available."))
            participants <- data %>% filter(.data$participant_id != "ref")
            ggplot(participants, aes(x = reorder(participant_id, order_idx), y = mean_value, group = sample_group, color = sample_group)) +
              geom_line() +
              geom_point(size = 2) +
              labs(x = "Participant (ordered)", y = "Mean Value") +
              theme_minimal() +
              theme(axis.text.x = element_text(angle = 45, hjust = 1))
          })
        })
      })
    })
  })
}
