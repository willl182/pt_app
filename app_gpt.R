# =====================================================================
# app_gpt.R v1.0
# Author: Will Salas
# References: ISO 13528:2022, SOP v3.1 (homogeneity & stability methodology)
# =====================================================================

suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(shinyBS)
  library(tidyverse)
  library(readr)
  library(DT)
})

`%||%` <- function(a, b) if (!is.null(a)) a else b

# --- Helper Functions -------------------------------------------------

# Manual nIQR calculation per doc_med_made_niqr.md (Section 2.2)
calc_niqr <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) < 2) {
    return(NA_real_)
  }
  qs <- stats::quantile(x, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (qs[[2]] - qs[[1]])
}

# Algorithm A implementation based on doc_algorithm_a.md
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

# F-factor lookup table from doc_homo_stab.md (Annex B expanded criterion)
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

# Load modular components
module_files <- list.files("modules_gpt", pattern = "^mod_.*\\.R$", full.names = TRUE)
purrr::walk(module_files, source)

# Logging helper writes a timestamped entry per user action
log_file <- "app_gpt.log"
log_action <- function(message) {
  entry <- sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), message)
  cat(entry, file = log_file, append = TRUE)
}

# --- User Interface ---------------------------------------------------

ui <- fluidPage(
  theme = shinythemes::shinytheme("flatly"),
  titlePanel("PT Data Analysis Application"),
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

# --- Server -----------------------------------------------------------

server <- function(input, output, session) {
  log_action("App initialized")

  safe_reader <- function(path) {
    if (!file.exists(path)) {
      warning(sprintf("File %s not found", path))
      return(tibble::tibble())
    }
    readr::read_csv(path, show_col_types = FALSE)
  }

  hom_data <- reactiveFileReader(5000, session, "homogeneity.csv", function(path) {
    safe_reader(path) %>% mutate(pollutant = tolower(pollutant))
  })

  stability_data <- reactiveFileReader(5000, session, "stability.csv", function(path) {
    safe_reader(path) %>% mutate(pollutant = tolower(pollutant))
  })

  pt_data <- reactivePoll(5000, session,
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
        safe_reader(file) %>%
          mutate(
            pollutant = tolower(pollutant),
            n_lab = readr::parse_number(basename(file))
          )
      })
    }
  )

  output$main_layout <- renderUI({
    nav_width <- input$nav_width %||% 3
    content_width <- 12 - nav_width
    navlistPanel(
      id = "main_nav",
      widths = c(nav_width, content_width),
      "Analysis Modules",
      tabPanel(
        "Homogeneity & Stability",
        mod_homogeneity_ui("homog"),
        br(),
        mod_stability_ui("stab")
      ),
      tabPanel(
        "PT Preparation",
        mod_ptprep_ui("ptprep")
      ),
      tabPanel(
        "PT Scores",
        mod_scores_ui("scores")
      )
    )
  })

  # Initialize modules
  hom_shared <- mod_homogeneity_server("homog", hom_data, stability_data, log_action)
  mod_stability_server("stab", stability_data, hom_shared, log_action)
  mod_ptprep_server("ptprep", pt_data, log_action)
  mod_scores_server("scores", pt_data, log_action)
}

shinyApp(ui, server)
