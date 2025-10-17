# ===================================================================
# app_gg.R v1.0
#
# Author: Will Salas
#
# This Shiny application provides a modular and robust framework for
# Proficiency Testing (PT) data analysis, compliant with
# ISO 13528:2022 and SOP_V3.1. It integrates modules for
# homogeneity, stability, PT preparation, and performance scoring.
# ===================================================================

# 1. Load Libraries
library(shiny)
library(tidyverse)
library(vroom)
library(DT)
library(shinythemes)

# 2. Source Modules and Utilities
source("R/utils.R")
source("modules/mod_homogeneity.R")
source("modules/mod_stability.R")
source("modules/mod_ptprep.R")
source("modules/mod_scores.R")

# ===================================================================
# I. User Interface (UI)
# ===================================================================
`%||%` <- function(a, b) if (!is.null(a)) a else b

ui <- fluidPage(
  theme = shinythemes::shinytheme("flatly"),

  # 1. Application Title
  titlePanel("PT Data Analysis Application (app_gg.R v1.0)"),
  h4("Laboratorio CALAIRE"),

  bsCollapse(
    id = "layout_controls",
    bsCollapsePanel(
      title = "Layout & Theme",
      value = FALSE,
      themeSelector(),
      sliderInput("nav_width", "Navigation Panel Width", min = 2, max = 4, value = 3, width = "300px"),
      sliderInput("analysis_sidebar_width", "Analysis Sidebar Width", min = 2, max = 5, value = 3, width = "300px")
    )
  ),
  hr(),

  # Dynamic UI for the main layout
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

  # --- Reactive Data Loading ---
  hom_data_full <- reactiveFileReader(1000, session, "homogeneity.csv", read.csv)
  stab_data_full <- reactiveFileReader(1000, session, "stability.csv", read.csv)

  pt_prep_data <- reactive({
    files <- list.files(pattern = "summary_n.*\\.csv")
    data_list <- lapply(files, function(f) {
      df <- read.csv(f)
      df$n_lab <- as.integer(stringr::str_extract(f, "\\d+"))
      return(df)
    })
    do.call(rbind, data_list)
  })

  # --- Dynamic Main Layout ---
  output$main_layout <- renderUI({
    nav_width <- input$nav_width %||% 3
    content_width <- 12 - nav_width
    analysis_sidebar_w <- input$analysis_sidebar_width %||% 3
    analysis_main_w <- 12 - analysis_sidebar_w

    navlistPanel(
      id = "main_nav",
      widths = c(nav_width, content_width),
      "Analysis Modules",

      # --- Homogeneity & Stability Tab ---
      tabPanel("Homogeneity & Stability",
        sidebarLayout(
          sidebarPanel(
            width = analysis_sidebar_w,
            h4("1. Select Data"),
            selectInput("pollutant_analysis", "Select Pollutant:",
                        choices = c("co", "no", "no2", "o3", "so2")),
            uiOutput("level_selector_ui")
          ),
          mainPanel(
            width = analysis_main_w,
            tabsetPanel(
              id = "analysis_tabs",
              homogeneityUI("homog"),
              stabilityUI("stab")
            )
          )
        )
      ),

      # --- Other Modules ---
      ptprepUI("ptprep"),
      scoresUI("scores")
    )
  })

  # --- Dynamic Level Selector ---
  output$level_selector_ui <- renderUI({
    req(hom_data_full(), input$pollutant_analysis)
    levels <- hom_data_full() %>%
      filter(pollutant == input$pollutant_analysis) %>%
      pull(level) %>%
      unique()
    selectInput("target_level", "2. Select PT Level", choices = levels, selected = levels[1])
  })

  # --- Module Server Instantiation ---
  selected_pollutant <- reactive(input$pollutant_analysis)
  selected_level <- reactive(input$target_level)

  homog_results <- homogeneityServer("homog", hom_data_full(), selected_pollutant, selected_level)
  stabilityServer("stab", homog_results, stab_data_full(), selected_pollutant, selected_level)
  ptprepServer("ptprep", pt_prep_data)
  scoresServer("scores", pt_prep_data)
}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server)
