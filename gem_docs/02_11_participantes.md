# Shiny Module: Participants

## 1. Overview
This module creates a dedicated dashboard for each participant, allowing detailed individual analysis. It is dynamically generated based on the list of participants found in the data.

**File Location:** `cloned_app.R` ("Participantes" tab)

---

## 2. Dynamic Tab Generation

### 2.1 The Pattern
The app uses a `uiOutput` -> `renderUI` -> `lapply` pattern to create tabs indefinitely.

```r
output$scores_participant_tabs <- renderUI({
  participants <- unique(data$participant_id)
  
  # Create a tab for each participant
  tabs <- lapply(participants, function(id) {
    tabPanel(
      title = id,
      br(),
      # Specific UI outputs with unique IDs
      dataTableOutput(paste0("participant_table_", id)),
      plotOutput(paste0("participant_plot_", id))
    )
  })
  
  do.call(tabsetPanel, tabs)
})
```

### 2.2 Performance Considerations
*   **Lazy Loading:** While tabs are generated, the content (plots/tables) is only rendered when the tab is active.
*   **Filtering:** Data is filtered per participant *inside* the local render function, ensuring efficiency.

---

## 3. Features per Participant

### 3.1 Individual Results Table
Shows every result for that specific lab across all pollutants and levels, including their reported uncertainty vs. the assigned value.

### 3.2 Trend/Comparison Charts
*   **Bar Chart:** Compares Lab Result vs. Reference Value side-by-side.
*   **Scatter Plot:** Visualizes the lab's z-scores across different items to detect systematic bias (e.g., if all z-scores are positive > 1).
