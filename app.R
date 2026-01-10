# ===================================================================
# Shiny App for Proficiency Testing Analysis
#
# This app implements the procedures from ISO 17043 and ISO 13528 in an interactive web interface using Shiny.
#
# ===================================================================

# 1. Load necessary libraries
library(shiny)
library(tidyverse)
library(vroom)
library(DT)
library(rhandsontable)
library(shinythemes)
library(outliers)
library(patchwork)
library(bsplus)
library(plotly)
library(rmarkdown)
library(bslib)

# 2. Source the extracted logic
source("R/core_statistics.R")
source("R/data_prep.R")
source("R/homogeneity_stability.R")
source("R/scores.R")

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bg = "#FFFFFF",
    fg = "#212529",
    primary = "#FDB913",
    secondary = "#333333",
    success = "#4DB848",
    base_font = font_google("Droid Sans"),
    code_font = font_google("JetBrains Mono")
  ),

  # 1. Application Title
  titlePanel("Aplicativo para Evaluación de Ensayos de Aptitud"),
  h3("Gases Contaminantes Criterio"),
  h4("Laboratorio Calaire"),

  # Collapsible panel for layout options
  checkboxInput("show_layout_options", "Mostrar opciones de diseño", value = FALSE),
  conditionalPanel(
    condition = "input.show_layout_options == true",
    wellPanel(
      themeSelector(),
      hr(),
      sliderInput("nav_width", "Ancho del panel de navegación:", min = 1, max = 5, value = 2, width = "250px"),
      sliderInput("analysis_sidebar_width", "Ancho de la barra lateral de análisis:", min = 2, max = 6, value = 3, width = "250px")
    )
  ),
  hr(),

  # Dynamic UI for the main layout
  uiOutput("main_layout"),
  hr(),
  p(em("Este aplicativo fue desarrollado en el marco del proyecto «Implementación de Ensayos de Aptitud en la Matriz Aire. Caso Gases Contaminantes Criterio», ejecutado por el Laboratorio CALAIRE de la Universidad Nacional de Colombia en alianza con el Instituto Nacional de Metrología (INM)."), style = "text-align:center; font-size:small;")
)

# ===================================================================
# II. Server Logic
# ===================================================================
server <- function(input, output, session) {

  # --- Helpers for UI ---
  format_num <- function(x) {
    ifelse(is.na(x), NA_character_, sprintf("%.5f", x))
  }

  # --- Carga de datos and Processing ---
  hom_data_full <- reactive({
    req(input$hom_file)
    df <- vroom::vroom(input$hom_file$datapath, show_col_types = FALSE)
    validate(
      need(
        all(c("value", "pollutant", "level") %in% names(df)),
        "Error: El archivo de homogeneidad debe contener las columnas 'value', 'pollutant' y 'level'."
      )
    )
    df
  })

  stab_data_full <- reactive({
    req(input$stab_file)
    df <- vroom::vroom(input$stab_file$datapath, show_col_types = FALSE)
    validate(
      need(
        all(c("value", "pollutant", "level") %in% names(df)),
        "Error: El archivo de estabilidad debe contener las columnas 'value', 'pollutant' y 'level'."
      )
    )
    df
  })

  pt_prep_data <- reactive({
    req(input$summary_files)

    data_list <- lapply(seq_len(nrow(input$summary_files)), function(i) {
      df <- vroom::vroom(input$summary_files$datapath[i], show_col_types = FALSE)
      n <- as.integer(stringr::str_extract(input$summary_files$name[i], "\\d+"))
      df$n_lab <- n
      return(df)
    })

    if (length(data_list) == 0) return(NULL)

    raw_data <- do.call(rbind, data_list)
    if (is.null(raw_data) || nrow(raw_data) == 0) return(NULL)

    validate(
      need(
        all(c("participant_id", "pollutant", "level", "mean_value", "sd_value") %in% names(raw_data)),
        "Error: Los archivos resumen deben contener las columnas requeridas."
      )
    )

    # Simple aggregation if duplicates exist
    raw_data %>%
      group_by(participant_id, pollutant, level, n_lab) %>%
      summarise(
        mean_value = mean(mean_value, na.rm = TRUE),
        sd_value = mean(sd_value, na.rm = TRUE),
        .groups = "drop"
      )
  })

  # --- Triggers & Caches ---
  analysis_trigger <- reactiveVal(NULL)
  algoA_results_cache <- reactiveVal(NULL)
  algoA_trigger <- reactiveVal(NULL)
  consensus_results_cache <- reactiveVal(NULL)
  consensus_trigger <- reactiveVal(NULL)
  scores_results_cache <- reactiveVal(NULL)
  scores_trigger <- reactiveVal(NULL)

  observeEvent(input$run_analysis, { analysis_trigger(Sys.time()) })

  observeEvent(list(input$hom_file, input$stab_file, input$summary_files), {
    analysis_trigger(NULL)
  }, ignoreNULL = FALSE)

  observeEvent(input$summary_files, {
    algoA_results_cache(NULL); algoA_trigger(NULL)
    consensus_results_cache(NULL); consensus_trigger(NULL)
    scores_results_cache(NULL); scores_trigger(NULL)
  }, ignoreNULL = FALSE)

  # --- Homogeneity & Stability Logic ---

  # R1: Reactive for wide Homogeneity data (for preview)
  raw_data <- reactive({
    req(hom_data_full(), input$pollutant_analysis)
    get_wide_data(hom_data_full(), input$pollutant_analysis)
  })

  # R1.6: Reactive for wide Stability data (for preview)
  stability_data_raw <- reactive({
    req(stab_data_full(), input$pollutant_analysis)
    get_wide_data(stab_data_full(), input$pollutant_analysis)
  })

  # Run Homogeneity Calculation
  homogeneity_run <- reactive({
    req(analysis_trigger())
    req(input$pollutant_analysis, input$target_level)
    # Call pure function from R/homogeneity_stability.R
    compute_homogeneity_metrics(input$pollutant_analysis, input$target_level, hom_data_full())
  })

  # Run Stability Calculation (ISO Check)
  homogeneity_run_stability <- reactive({
    req(analysis_trigger())
    req(input$pollutant_analysis, input$target_level)
    hom_results <- homogeneity_run()
    # Call pure function from R/homogeneity_stability.R
    compute_stability_metrics(input$pollutant_analysis, input$target_level, hom_results, stab_data_full())
  })

  # Run Stability T-Test & Conclusion Construction
  stability_run <- reactive({
    req(analysis_trigger())
    hom_results <- homogeneity_run()
    stab_hom_results <- homogeneity_run_stability()

    if (!is.null(hom_results$error)) return(list(error = hom_results$error))
    if (!is.null(stab_hom_results$error)) return(list(error = stab_hom_results$error))

    # Construct details text (UI logic)
    y1 <- hom_results$general_mean
    y2 <- stab_hom_results$stab_general_mean
    diff_observed <- stab_hom_results$diff_hom_stab
    criterion <- stab_hom_results$stab_c_criterion

    fmt <- "%.5f"
    details_text <- sprintf(
      paste("Media homogeneidad (y1):", fmt, "\nMedia estabilidad (y2):", fmt,
            "\nDiferencia absoluta:", fmt, "\nCriterio (0.3*sigma_pt):", fmt),
      y1, y2, diff_observed, criterion
    )

    # Determine conclusion HTML class based on flags
    if (stab_hom_results$passed_criterion) {
      conclusion <- "Conclusión: el ítem es adecuadamente estable."
      conclusion_class <- "alert alert-success"
    } else {
      conclusion <- "Conclusión: ADVERTENCIA: el ítem puede ser inestable."
      conclusion_class <- "alert alert-warning"
    }

    # Perform T-Test using new helper or direct t.test here
    # We need the raw vectors.
    target_level <- input$target_level

    # Helper to extract vector
    get_vec <- function(df, lev) {
      if(is.null(df)) return(numeric(0))
      df %>% filter(level == lev) %>% select(starts_with("sample_")) %>% unlist() %>% as.numeric()
    }

    vec_hom <- get_vec(raw_data(), target_level)
    vec_stab <- get_vec(stability_data_raw(), target_level)

    # Use helper from R/homogeneity_stability.R
    ttest_res <- check_stability_ttest(vec_hom, vec_stab)

    if (isTRUE(ttest_res$significant_diff)) {
       ttest_conclusion <- "Prueba t: se detecta diferencia estadísticamente significativa (p <= 0.05)."
    } else {
       ttest_conclusion <- "Prueba t: no se detecta diferencia estadísticamente significativa (p > 0.05)."
    }

    list(
      conclusion = conclusion,
      conclusion_class = conclusion_class,
      details = details_text,
      ttest_summary = ttest_res,
      ttest_conclusion = ttest_conclusion,
      error = NULL
    )
  })

  # --- Outputs: Homogeneity & Stability ---
  output$homog_conclusion <- renderUI({
    res <- homogeneity_run()
    if (!is.null(res$error)) {
      div(class = "alert alert-danger", res$error)
    } else {
      # Construct HTML here
      msg1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): %s",
                      res$ss, res$c_criterion,
                      ifelse(res$passed_criterion, "CUMPLE CRITERIO", "NO CUMPLE CRITERIO"))
      cls <- ifelse(res$passed_criterion, "alert alert-success", "alert alert-warning")
      
      msg2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): %s",
                      res$ss, res$c_criterion_expanded,
                      ifelse(res$passed_expanded, "CUMPLE CRITERIO EXP", "NO CUMPLE CRITERIO EXP"))
      
      div(class = cls, HTML(paste(msg1, msg2, sep = "<br>")))
    }
  })

  output$homog_conclusion_stability <- renderUI({
    res <- homogeneity_run_stability()
    if (!is.null(res$error)) {
      div(class = "alert alert-danger", res$error)
    } else {
      msg1 <- sprintf("diff (%.4f) <= c_criterion (%.4f): %s",
                      res$diff_hom_stab, res$stab_c_criterion,
                      ifelse(res$passed_criterion, "CUMPLE CRITERIO", "NO CUMPLE CRITERIO"))
      cls <- ifelse(res$passed_criterion, "alert alert-success", "alert alert-warning")
      
      msg2 <- sprintf("diff (%.4f) <= c_expanded (%.4f): %s",
                      res$diff_hom_stab, res$stab_c_criterion_expanded,
                      ifelse(res$passed_expanded, "CUMPLE CRITERIO EXP", "NO CUMPLE CRITERIO EXP"))
      
      div(class = cls, HTML(paste(msg1, msg2, sep = "<br>")))
    }
  })

  # ... (Keep tables/plots for Homog/Stab using res$...)
  # Note: The logic for tables/plots remains similar, accessing elements from `res`.

  output$robust_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        Estadístico = c("Mediana (x_pt)", "MADe (sigma_pt)", "nIQR"),
        Valor = sprintf("%.5f", c(res$median_val, res$sigma_pt, res$n_iqr))
      )
    }
  }, spacing = "l")

  output$variance_components <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        Componente = c("xpt", "sigma_pt", "u_xpt", "ss", "sw", "---", "c", "c_exp"),
        Valor = format_num(c(res$median_val, res$sigma_pt, res$u_xpt, res$ss, res$sw, NA, res$c_criterion, res$c_criterion_expanded))
      )
    }
  })

  output$stability_conclusion_ui <- renderUI({ # Renamed to avoid clash if any
      res <- stability_run()
      if (!is.null(res$error)) div(class = "alert alert-danger", res$error)
      else div(class = res$conclusion_class, HTML(res$conclusion))
  })

  output$stability_details <- renderPrint({
    res <- stability_run()
    if (is.null(res$error)) cat(res$details)
  })

  output$stability_ttest <- renderPrint({
    res <- stability_run()
    if (is.null(res$error)) {
      cat(res$ttest_conclusion, "\n")
      print(c(statistic = res$ttest_summary$statistic, p.value = res$ttest_summary$p_value))
    }
  })

  # --- Algorithm A Module ---
  observeEvent(input$algoA_run, {
    req(pt_prep_data())
    data <- isolate(pt_prep_data())
    combos <- data %>% distinct(pollutant, n_lab, level)
    
    if (nrow(combos) == 0) {
      algoA_results_cache(NULL); algoA_trigger(Sys.time()); return()
    }
    
    results <- list()
    for (i in seq_len(nrow(combos))) {
      p <- combos$pollutant[i]; n <- combos$n_lab[i]; l <- combos$level[i]
      key <- paste(p, n, l, sep = "||")
      
      sub <- data %>% filter(pollutant == p, n_lab == n, level == l)
      parts <- sub %>% filter(participant_id != "ref")
      
      agg <- parts %>% group_by(participant_id) %>% summarise(Resultado = mean(mean_value, na.rm=TRUE), .groups="drop")
      
      # Use extracted function
      algo_res <- run_algorithm_a(agg$Resultado, agg$participant_id, isolate(input$algoA_max_iter))
      algo_res$input_data <- agg
      algo_res$selected <- list(pollutant=p, n_lab=n, level=l)
      
      results[[key]] <- algo_res
    }
    algoA_results_cache(results)
    algoA_trigger(Sys.time())
  })

  algorithm_a_selected <- reactive({
    req(algoA_trigger(), input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    cache <- algoA_results_cache()
    if(is.null(cache)) return(list(error="No results"))
    key <- paste(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level, sep="||")
    if(is.null(cache[[key]])) return(list(error="No results for selection"))
    cache[[key]]
  })

  output$algoA_result_summary <- renderUI({
    res <- algorithm_a_selected()
    if (!is.null(res$error)) return(div(class="alert alert-danger", res$error))

    div(class="alert alert-info", HTML(paste0(
      "<strong>x*:</strong> ", format(res$assigned_value, digits=5), "<br>",
      "<strong>s*:</strong> ", format(res$robust_sd, digits=5), "<br>",
      "<strong>Converged:</strong> ", res$converged
    )))
  })

  # --- Consensus Module ---
  observeEvent(input$consensus_run, {
    req(pt_prep_data())
    data <- isolate(pt_prep_data()) %>% filter(participant_id != "ref")
    combos <- data %>% distinct(pollutant, n_lab, level)

    results <- list()
    for(i in seq_len(nrow(combos))) {
      p <- combos$pollutant[i]; n <- combos$n_lab[i]; l <- combos$level[i]
      key <- paste(p, n, l, sep="||")

      vals <- data %>% filter(pollutant==p, n_lab==n, level==l) %>% pull(mean_value)

      # Use extracted function
      metrics <- compute_consensus_metrics(vals)

      if(!is.null(metrics)) {
        df <- tibble(
          Estadístico = c("Mediana", "MADe", "nIQR"),
          Valor = c(metrics$x_pt_median, metrics$sigma_pt_2a, metrics$sigma_pt_2b)
        )
        results[[key]] <- list(summary = df, input_data = tibble(Valores = vals))
      }
    }
    consensus_results_cache(results)
    consensus_trigger(Sys.time())
  })

  consensus_selected <- reactive({
    req(consensus_trigger(), input$assigned_pollutant, input$assigned_n_lab, input$assigned_level)
    cache <- consensus_results_cache()
    key <- paste(input$assigned_pollutant, input$assigned_n_lab, input$assigned_level, sep="||")
    if(is.null(cache) || is.null(cache[[key]])) return(list(error="No data"))
    cache[[key]]
  })

  output$consensus_summary_table <- renderTable({
    res <- consensus_selected()
    if(!is.null(res$error)) return(NULL)
    res$summary
  })

  # --- Scores Module ---
  observeEvent(input$scores_run, {
    req(pt_prep_data())
    data <- isolate(pt_prep_data())
    combos <- data %>% distinct(pollutant, n_lab, level)

    results <- list()
    for(i in seq_len(nrow(combos))) {
      p <- combos$pollutant[i]; n <- combos$n_lab[i]; l <- combos$level[i]
      key <- paste(p, n, l, sep="||")

      # We need hom/stab data for proper uncertainty calc in scoring (if implemented fully)
      # compute_scores_for_selection requires full hom/stab data
      # Access reactives outside of reactive context? isolate them.
      h_data <- isolate(hom_data_full())
      s_data <- isolate(stab_data_full())

      res <- compute_scores_for_selection(p, n, l, data, h_data, s_data,
                                          max_iter = isolate(input$algoA_max_iter))
      results[[key]] <- res
    }
    scores_results_cache(results)
    scores_trigger(Sys.time())
  })

  get_scores_result <- function(pollutant, n_lab, level) {
    req(scores_trigger())
    cache <- scores_results_cache()
    key <- paste(pollutant, n_lab, level, sep="||")
    if(is.null(cache[[key]])) return(list(error="No scores"))
    cache[[key]]
  }

  scores_results_selected <- reactive({
    req(input$scores_pollutant, input$scores_n_lab, input$scores_level)
    get_scores_result(input$scores_pollutant, input$scores_n_lab, input$scores_level)
  })

  output$scores_overview_table <- renderDataTable({
    res <- scores_results_selected()
    if(!is.null(res$error)) return(datatable(data.frame(Msg=res$error)))
    datatable(res$overview, options=list(scrollX=TRUE))
  })

  # --- Layout ---
  output$main_layout <- renderUI({
    req(input$nav_width, input$analysis_sidebar_width)
    navlistPanel(
      widths = c(input$nav_width, 12 - input$nav_width),
      tabPanel("Carga de datos",
               fileInput("hom_file", "Homogeneidad"),
               fileInput("stab_file", "Estabilidad"),
               fileInput("summary_files", "Resumen PT", multiple=TRUE),
               verbatimTextOutput("data_upload_status")
      ),
      tabPanel("Homogeneidad/Estabilidad",
               sidebarLayout(
                 sidebarPanel(width=input$analysis_sidebar_width,
                              actionButton("run_analysis", "Ejecutar"),
                              uiOutput("pollutant_selector_analysis"),
                              uiOutput("level_selector")),
                 mainPanel(
                   tabsetPanel(
                     tabPanel("Homogeneidad", uiOutput("homog_conclusion"), tableOutput("variance_components")),
                     tabPanel("Estabilidad", uiOutput("homog_conclusion_stability"), uiOutput("stability_conclusion_ui"), verbatimTextOutput("stability_details"), verbatimTextOutput("stability_ttest"))
                   )
                 )
               )
      ),
      tabPanel("Algoritmo A",
               sidebarLayout(
                 sidebarPanel(width=input$analysis_sidebar_width,
                              actionButton("algoA_run", "Calcular"),
                              numericInput("algoA_max_iter", "Iteraciones", 50),
                              uiOutput("assigned_pollutant_selector"),
                              uiOutput("assigned_n_selector"),
                              uiOutput("assigned_level_selector")),
                 mainPanel(uiOutput("algoA_result_summary"), dataTableOutput("algoA_iterations_table"))
               )
      ),
      tabPanel("Consenso",
               sidebarLayout(
                 sidebarPanel(width=input$analysis_sidebar_width,
                              actionButton("consensus_run", "Calcular")),
                 mainPanel(tableOutput("consensus_summary_table"))
               )
      ),
      tabPanel("Puntajes PT",
               sidebarLayout(
                 sidebarPanel(width=input$analysis_sidebar_width,
                              actionButton("scores_run", "Calcular"),
                              uiOutput("scores_pollutant_selector"),
                              uiOutput("scores_n_selector"),
                              uiOutput("scores_level_selector")),
                 mainPanel(dataTableOutput("scores_overview_table"))
               )
      ),
      tabPanel("Generación de informes",
               downloadButton("download_report", "Descargar")
      )
    )
  })

  # --- Selectors ---
  output$pollutant_selector_analysis <- renderUI({
    req(hom_data_full())
    selectInput("pollutant_analysis", "Analito", choices=sort(unique(hom_data_full()$pollutant)))
  })
  output$level_selector <- renderUI({
    req(raw_data())
    selectInput("target_level", "Nivel", choices=unique(raw_data()$level))
  })

  output$assigned_pollutant_selector <- renderUI({
    req(pt_prep_data())
    selectInput("assigned_pollutant", "Analito", choices=unique(pt_prep_data()$pollutant))
  })
  output$assigned_n_selector <- renderUI({
    req(pt_prep_data(), input$assigned_pollutant)
    ch <- pt_prep_data() %>% filter(pollutant==input$assigned_pollutant) %>% pull(n_lab) %>% unique()
    selectInput("assigned_n_lab", "N Lab", choices=ch)
  })
  output$assigned_level_selector <- renderUI({
    req(pt_prep_data(), input$assigned_pollutant, input$assigned_n_lab)
    ch <- pt_prep_data() %>% filter(pollutant==input$assigned_pollutant, n_lab==input$assigned_n_lab) %>% pull(level) %>% unique()
    selectInput("assigned_level", "Nivel", choices=ch)
  })

  output$scores_pollutant_selector <- renderUI({
    req(pt_prep_data())
    selectInput("scores_pollutant", "Analito", choices=unique(pt_prep_data()$pollutant))
  })
  output$scores_n_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant)
    ch <- pt_prep_data() %>% filter(pollutant==input$scores_pollutant) %>% pull(n_lab) %>% unique()
    selectInput("scores_n_lab", "N Lab", choices=ch)
  })
  output$scores_level_selector <- renderUI({
    req(pt_prep_data(), input$scores_pollutant, input$scores_n_lab)
    ch <- pt_prep_data() %>% filter(pollutant==input$scores_pollutant, n_lab==input$scores_n_lab) %>% pull(level) %>% unique()
    selectInput("scores_level", "Nivel", choices=ch)
  })

  # --- Download Handler ---
  output$download_report <- downloadHandler(
    filename = function() "report.docx",
    content = function(file) {
      # Use params to pass data
      params <- list(
        summary_data = pt_prep_data(),
        hom_data = hom_data_full(),
        stab_data = stab_data_full(),
        method = "3", metric = "z", n_lab = 7 # defaults for now
      )
      rmarkdown::render("reports/report_template.Rmd", output_file = file, params = params)
    }
  )
}

shinyApp(ui = ui, server = server, options = list(launch.browser = FALSE))
