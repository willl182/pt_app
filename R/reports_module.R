# R/reports_module.R

# Main Reports Module UI
reports_ui <- function(id) {
  ns <- NS(id)

  # Main UI for the reports section, containing tabs for different reports
  tagList(
    h2("Analysis Reports"),
    p("Select a report type from the tabs below."),
    tabsetPanel(
      id = ns("report_tabs"),

      # Tab 1: Homogeneity and Stability Report
      tabPanel("Homogeneity and Stability Report",
               # Call the UI function from the homogeneity/stability report submodule
               homogeneity_stability_report_ui(ns("homog_stab_report"))
      ),

      # Tab 2: PT Report (Placeholder)
      tabPanel("PT Report",
               # Call the UI function from the PT report submodule
               pt_report_ui(ns("pt_report"))
      )
    )
  )
}

# Main Reports Module Server
reports_server <- function(id, raw_data_hom, raw_data_stab) {
  moduleServer(id, function(input, output, session) {

    # Call the server logic for the homogeneity and stability submodule
    # Pass the reactive data sources down to the submodule
    homogeneity_stability_report_server("homog_stab_report", raw_data_hom, raw_data_stab)

    # Call the server logic for the PT report submodule
    pt_report_server("pt_report")

  })
}