# ===================================================================
# Interactive Spreadsheet Application using R Shiny and DT
#
# This application displays the 'mtcars' dataset in an interactive
# table. It allows users to filter the data based on the 'mpg'
# (Miles/(US) gallon) column using a slider.
# ===================================================================

# 1. Load necessary libraries
library(shiny)
library(DT)
library(shinythemes)

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(
  # Apply the 'darkly' theme from shinythemes for a modern look
  theme = shinythemes::shinytheme("darkly"),

  # 1. Application Title
  titlePanel("Interactive Spreadsheet of mtcars Dataset"),

  # 2. Main Layout: Sidebar
  sidebarLayout(

    # 2.1. Input Panel (Sidebar)
    sidebarPanel(
      h4("Filter Options"),
      # Slider input to filter cars by their minimum MPG
      sliderInput("mpg_filter",
                  "Minimum MPG (Miles/(US) gallon):",
                  min = min(mtcars$mpg, na.rm = TRUE),
                  max = max(mtcars$mpg, na.rm = TRUE),
                  value = min(mtcars$mpg, na.rm = TRUE),
                  step = 1)
    ),

    # 2.2. Main Panel for Results
    mainPanel(
      # Display the interactive table
      DT::DTOutput("interactive_table")
    )
  )
)

# ===================================================================
# II. Server Logic
# ===================================================================
server <- function(input, output, session) {

  # R1: Reactive expression to filter the data
  # This expression filters the 'mtcars' dataset based on the 'mpg_filter' slider.
  # It re-evaluates automatically whenever the slider value changes.
  filtered_data <- reactive({
    # Subset the data frame where 'mpg' is greater than or equal to the slider's value
    mtcars[mtcars$mpg >= input$mpg_filter, ]
  })

  # R2: Render the interactive DataTable
  output$interactive_table <- DT::renderDT({
    # Use the reactive 'filtered_data' expression as the data source
    datatable(
      filtered_data(),
      options = list(
        # Enable pagination for better navigation
        pageLength = 10,
        # Allow sorting and searching
        searching = TRUE,
        ordering = TRUE
      ),
      # Enable row selection (single row at a time)
      selection = 'single',
      # Ensure the table has a proper container and is scrollable on smaller screens
      class = 'display nowrap table-bordered table-striped',
      rownames = TRUE # Show row names, which in mtcars are the car models
    )
  },
  # Use client-side processing for the table. This is efficient for small
  # datasets like 'mtcars' as it offloads processing to the user's browser,
  # reducing server load.
  server = FALSE)
}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server)