# ===================================================================
# app_gg.R v1.1
#
# Author: Will Salas
#
# GPT-styled Shiny application for Proficiency Testing (PT) data
# analysis with data upload controls and enhanced module interfaces.
# ===================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(tidyverse)
  library(readr)
  library(DT)
})

`%||%` <- function(a, b) if (!is.null(a)) a else b

# -------------------------------------------------------------------
# Helper functions shared with GPT modules
# -------------------------------------------------------------------
calc_niqr <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n < 2) {
    return(NA_real_)
  }
  x_sorted <- sort(x)
  q_pos <- function(p) {
    pos <- p * (n - 1) + 1
    lower <- floor(pos)
    upper <- ceiling(pos)
    frac <- pos - lower
    if (lower == upper) {
      x_sorted[lower]
    } else {
      (1 - frac) * x_sorted[lower] + frac * x_sorted[upper]
    }
  }
  q1 <- q_pos(0.25)
  q3 <- q_pos(0.75)
  0.7413 * (q3 - q1)
}

algorithm_A <- function(x, max_iter = 100) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(list(robust_mean = NA_real_, robust_sd = NA_real_, iterations = 0))
  }
  x_star <- median(x)
  s_star <- mad(x, constant = 1.4826)
  prev_mean <- Inf
  prev_sd <- Inf
  tolerance <- 1e-9
  for (iter in seq_len(max_iter)) {
    if (signif(x_star, 3) == signif(prev_mean, 3) && signif(s_star, 3) == signif(prev_sd, 3)) {
      return(list(robust_mean = x_star, robust_sd = s_star, iterations = iter - 1))
    }
    prev_mean <- x_star
    prev_sd <- s_star
    if (s_star < tolerance) {
      return(list(robust_mean = x_star, robust_sd = 0, iterations = iter))
    }
    delta <- 1.5 * s_star
    x_prime <- pmin(pmax(x, x_star - delta), x_star + delta)
    x_star <- mean(x_prime)
    s_star <- 1.134 * sd(x_prime)
  }
  warning("Algorithm A did not converge within max_iter iterations.")
  list(robust_mean = x_star, robust_sd = s_star, iterations = max_iter)
}

f_factor_table <- tibble::tibble(
  g = 7:20,
  F1 = c(2.10, 2.01, 1.94, 1.88, 1.83, 1.79, 1.75, 1.72, 1.69, 1.67, 1.64, 1.62, 1.60, 1.59),
  F2 = c(1.43, 1.25, 1.11, 1.01, 0.93, 0.86, 0.80, 0.75, 0.71, 0.68, 0.64, 0.62, 0.59, 0.57)
)

get_f_factors <- function(g) {
  res <- f_factor_table %>% filter(.data$g == !!g)
  if (nrow(res) == 0) {
    return(NULL)
  }
  res
}

module_files <- list.files("modules_gpt", pattern = "^mod_.*\\.R$", full.names = TRUE)
purrr::walk(module_files, source)

log_file <- "app_gg.log"
log_action <- function(message) {
  entry <- sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), message)
  cat(entry, file = log_file, append = TRUE)
}

safe_reader <- function(path) {
  if (!file.exists(path)) {
    warning(sprintf("File %s not found", path))
    return(tibble::tibble())
  }
  readr::read_csv(path, show_col_types = FALSE)
}

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(
  theme = shinythemes::shinytheme("flatly"),

  titlePanel("PT Data Analysis Application (app_gg.R v1.1)"),
  h4("Laboratorio CALAIRE"),

  bsCollapse(
    id = "layout_controls",
    bsCollapsePanel(
      title = "Layout & Theme",
      value = FALSE,
      themeSelector(),
      sliderInput("nav_width", "Navigation Panel Width", min = 2, max = 5, value = 3, step = 1)
    )
  ),
  hr(),

  uiOutput("main_layout"),

  hr(),
  p(
    em("Este aplicativo fue desarrollado en el marco del proyecto «Implementación de Ensayos de Aptitud en la Matriz Aire. Caso Gases Contaminantes Criterio», ejecutado por el Laboratorio CALAIRE de la Universidad Nacional de Colombia en alianza con el Instituto Nacional de Metrología (INM)."),
    style = "text-align:center; font-size:small;"
  )
)

# ===================================================================
# II. Server Logic
# ===================================================================
server <- function(input, output, session) {
  log_action("app_gg initialized")

  uploads <- reactiveValues(
    hom_df = NULL,
    stab_df = NULL,
    pt_df = NULL,
    hom_label = "Default file (homogeneity.csv)",
    stab_label = "Default file (stability.csv)",
    pt_label = "Detected summary_n*.csv files"
  )

  observeEvent(input$hom_file, {
    req(input$hom_file)
    df <- readr::read_csv(input$hom_file$datapath, show_col_types = FALSE) %>%
      mutate(pollutant = tolower(pollutant))
    uploads$hom_df <- df
    uploads$hom_label <- sprintf("Uploaded: %s", input$hom_file$name)
    log_action(sprintf("Homogeneity data uploaded (%s)", input$hom_file$name))
  })

  observeEvent(input$stab_file, {
    req(input$stab_file)
    df <- readr::read_csv(input$stab_file$datapath, show_col_types = FALSE) %>%
      mutate(pollutant = tolower(pollutant))
    uploads$stab_df <- df
    uploads$stab_label <- sprintf("Uploaded: %s", input$stab_file$name)
    log_action(sprintf("Stability data uploaded (%s)", input$stab_file$name))
  })

  observeEvent(input$summary_files, {
    req(input$summary_files)
    df_list <- purrr::map2(
      input$summary_files$datapath,
      input$summary_files$name,
      function(path, name) {
        data <- readr::read_csv(path, show_col_types = FALSE)
        if ("pollutant" %in% names(data)) {
          data <- data %>% mutate(pollutant = tolower(pollutant))
        }
        if (!"n_lab" %in% names(data)) {
          n_val <- readr::parse_number(name)
          if (!is.na(n_val)) {
            data$n_lab <- n_val
          }
        }
        data
      }
    )
    uploads$pt_df <- dplyr::bind_rows(df_list)
    uploads$pt_label <- sprintf("Uploaded: %d file(s)", nrow(input$summary_files))
    log_action(sprintf("Summary data uploaded (%d file[s])", nrow(input$summary_files)))
  })

  observeEvent(input$reset_uploads, {
    uploads$hom_df <- NULL
    uploads$stab_df <- NULL
    uploads$pt_df <- NULL
    uploads$hom_label <- "Default file (homogeneity.csv)"
    uploads$stab_label <- "Default file (stability.csv)"
    uploads$pt_label <- "Detected summary_n*.csv files"
    log_action("Uploads reset to default data sources")
  })

  hom_default <- reactiveFileReader(5000, session, "homogeneity.csv", function(path) {
    safe_reader(path) %>% mutate(pollutant = tolower(pollutant))
  })

  stab_default <- reactiveFileReader(5000, session, "stability.csv", function(path) {
    safe_reader(path) %>% mutate(pollutant = tolower(pollutant))
  })

  pt_default <- reactivePoll(5000, session,
    checkFunc = function() {
      files <- list.files(pattern = "^summary_n\\d+\\.csv$", full.names = TRUE)
      if (length(files) == 0) {
        return(0)
      }
      paste(files, file.info(files)$mtime, collapse = "|")
    },
    valueFunc = function() {
      files <- list.files(pattern = "^summary_n\\d+\\.csv$", full.names = TRUE)
      if (length(files) == 0) {
        return(tibble::tibble())
      }
      purrr::map_dfr(files, function(file) {
        data <- safe_reader(file)
        if (nrow(data) == 0) {
          return(tibble::tibble())
        }
        if ("pollutant" %in% names(data)) {
          data <- data %>% mutate(pollutant = tolower(pollutant))
        }
        if (!"n_lab" %in% names(data)) {
          data <- data %>% mutate(n_lab = readr::parse_number(basename(file)))
        }
        data
      })
    }
  )

  hom_data <- reactive({
    uploads$hom_df %||% hom_default()
  })

  stability_data <- reactive({
    uploads$stab_df %||% stab_default()
  })

  pt_data <- reactive({
    uploads$pt_df %||% pt_default()
  })

  output$data_status <- renderPrint({
    cat("Homogeneity source:", uploads$hom_label, "\n")
    cat("Stability source:", uploads$stab_label, "\n")
    cat("Summary data source:", uploads$pt_label, "\n")
  })

  output$hom_preview <- renderDataTable({
    df <- hom_data()
    validate(need(nrow(df) > 0, "No homogeneity records available."))
    datatable(head(df, 20), options = list(scrollX = TRUE, pageLength = 10))
  })

  output$stab_preview <- renderDataTable({
    df <- stability_data()
    validate(need(nrow(df) > 0, "No stability records available."))
    datatable(head(df, 20), options = list(scrollX = TRUE, pageLength = 10))
  })

  output$summary_preview <- renderDataTable({
    df <- pt_data()
    validate(need(nrow(df) > 0, "No summary files detected."))
    datatable(head(df, 20), options = list(scrollX = TRUE, pageLength = 10))
  })

  output$main_layout <- renderUI({
    nav_width <- input$nav_width %||% 3
    content_width <- 12 - nav_width

    navlistPanel(
      id = "main_nav",
      widths = c(nav_width, content_width),
      "Analysis Modules",
      tabPanel(
        "Data Management",
        fluidRow(
          column(
            width = 4,
            h4("Upload Data"),
            fileInput("hom_file", "Homogeneity CSV", accept = ".csv"),
            fileInput("stab_file", "Stability CSV", accept = ".csv"),
            fileInput("summary_files", "Summary Files (summary_n*.csv)", multiple = TRUE, accept = ".csv"),
            actionButton("reset_uploads", "Reset to Default Files", class = "btn btn-secondary"),
            hr(),
            helpText("Upload CSV files to replace the default data sources. Leave empty to use the packaged datasets.")
          ),
          column(
            width = 8,
            h4("Current Data Sources"),
            verbatimTextOutput("data_status"),
            hr(),
            tabsetPanel(
              tabPanel("Homogeneity Preview", dataTableOutput("hom_preview")),
              tabPanel("Stability Preview", dataTableOutput("stab_preview")),
              tabPanel("Summary Preview", dataTableOutput("summary_preview"))
            )
          )
        )
      ),
      tabPanel(
        "Homogeneity & Stability",
        mod_homogeneity_ui("homog"),
        br(),
        mod_stability_ui("stab")
      ),
      tabPanel("PT Preparation", mod_ptprep_ui("ptprep")),
      tabPanel("PT Scores", mod_scores_ui("scores"))
    )
  })

  hom_shared <- mod_homogeneity_server("homog", hom_data, stability_data, log_action)
  mod_stability_server("stab", stability_data, hom_shared, log_action)
  mod_ptprep_server("ptprep", pt_data, log_action)
  mod_scores_server("scores", pt_data, log_action)
}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server)
