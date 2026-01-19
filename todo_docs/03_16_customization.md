# Customization Guide

This guide covers various ways to customize the application, including theme changes, layout adjustments, adding new pollutants, and extending the `ptcalc` package with new statistical methods.

---

## Location in Code

| Element | Value |
|---------|-------|
| File | `cloned_app.R` |
| Theme Definition | Lines 40-50 |
| Layout Controls | Lines 58-67 |
| Extension Points | Throughout server function |

---

## Theme Customization

### Current Theme Configuration

The application uses `bslib` for theming with Bootstrap 5:

```r
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bg = "#FFFFFF",           # Background color
    fg = "#212529",           # Foreground text color
    primary = "#FDB913",     # Primary accent (CALAIRE Yellow)
    secondary = "#333333",   # Secondary accent
    success = "#4DB848",     # Success states
    base_font = font_google("Droid Sans"),
    code_font = font_google("JetBrains Mono")
  ),
  ...
)
```

### Color Palette Reference

| Color Variable | Hex Code | Usage |
|----------------|----------|-------|
| `bg` | `#FFFFFF` | Background (white) |
| `fg` | `#212529` | Foreground text (dark gray) |
| `primary` | `#FDB913` | Buttons, links, active elements (yellow) |
| `secondary` | `#333333` | Secondary elements (dark gray) |
| `success` | `#4DB848` | Success messages, valid states (green) |
| `info` (default) | `#0dcaf0` | Info messages (light blue) |
| `warning` (default) | `#ffc107` | Warning messages (amber) |
| `danger` (default) | `#dc3545` | Error messages (red) |

### Changing to Bootswatch Theme

**Option 1: Runtime Theme Selection (Built-in)**

The application includes a theme selector widget:

1. Open the "Opciones de diseño" panel in the app sidebar
2. Check "Mostrar opciones de diseño"
3. Use the `themeSelector` widget to preview different Bootswatch themes
4. Available themes: `cerulean`, `cosmo`, `flatly`, `journal`, `lumen`, `paper`, `readable`, `sandstone`, `simplex`, `spacelab`, `united`, `yeti`

**Option 2: Hardcode Theme**

To permanently set a specific Bootswatch theme:

```r
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bootswatch = "cerulean",  # Add this line
    bg = "#FFFFFF",
    fg = "#212529",
    primary = "#FDB913",
    secondary = "#333333",
    success = "#4DB848"
  ),
  ...
)
```

### Custom Color Palette

To create a completely custom theme:

```r
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    # Define your custom palette
    bg = "#F0F4F8",
    fg = "#1A202C",
    primary = "#3182CE",
    secondary = "#2D3748",
    success = "#38A169",
    info = "#319795",
    warning = "#D69E2E",
    danger = "#E53E3E",
    # Custom fonts
    base_font = font_google("Inter"),
    code_font = font_google("Fira Code")
  ),
  ...
)
```

---

## Layout Controls

### Dynamic Width Sliders

The application provides two layout controls that users can adjust at runtime:

| Control | Input ID | Range | Default | Purpose |
|---------|----------|-------|---------|---------|
| Navigation Width | `nav_width` | 1-5 | 2 | Width of left navigation bar (Bootstrap grid units) |
| Analysis Sidebar Width | `analysis_sidebar_width` | 2-6 | 3 | Width of parameters panel in analysis tabs |

**UI Implementation:**
```r
sliderInput("nav_width", 
  "Ancho del panel de navegación:", 
  min = 1, max = 5, value = 2, width = "250px"
)
sliderInput("analysis_sidebar_width", 
  "Ancho de la barra lateral de análisis:", 
  min = 2, max = 6, value = 3, width = "250px"
)
```

**Bootstrap Grid System Reference:**

| Width | Bootstrap Column | Visual Width (approx.) |
|-------|------------------|------------------------|
| 1 | `col-1` | 8.33% |
| 2 | `col-2` | 16.67% |
| 3 | `col-3` | 25.00% |
| 4 | `col-4` | 33.33% |
| 5 | `col-5` | 41.67% |
| 6 | `col-6` | 50.00% |

### Hardcoding Layout Widths

To set fixed layout widths:

1. Comment out or remove the `sliderInput` elements
2. Use fixed column widths in your layout:

```r
# Example: Fixed 2-column navigation
sidebarLayout(
  sidebarPanel(width = 2, ...),  # Fixed 2-column width
  mainPanel(width = 10, ...)
)
```

---

## Adding New Pollutants

The application is designed to dynamically detect pollutants from uploaded data. Adding a new pollutant typically requires **no code changes**.

### Step-by-Step Guide

#### 1. Prepare Data Files

Ensure your CSV files include the new pollutant:

**homogeneity.csv example:**
```csv
value,pollutant,level
0.0523,SO2,low
0.0489,SO2,low
0.0475,PM10,low   <-- New pollutant
0.0468,PM10,low
```

**summary_n10.csv example:**
```csv
participant_id,pollutant,level,mean_value,sd_value
LAB1,SO2,low,0.0512,0.0023
LAB1,PM10,low,0.0489,0.0018   <-- New pollutant
```

#### 2. Verify Dynamic Detection

The app automatically detects pollutants using:

```r
# From pt_prep_data() reactive
unique_pollutants <- unique(raw_data$pollutant)
```

#### 3. Check for Hardcoded Lists

Rarely, some UI elements may use hardcoded lists. Check for patterns like:

```r
# BAD: Hardcoded pollutant list (avoid)
selectInput("pollutant", "Pollutant:", 
  choices = c("SO2", "NO2", "PM10", "O3")
)

# GOOD: Dynamic pollutant list (prefer)
output$pollutant_selector <- renderUI({
  data <- pt_prep_data()
  selectInput("pollutant", "Pollutant:",
    choices = unique(data$pollutant)
  )
})
```

### Adding Pollutant-Specific Configuration

If you need pollutant-specific settings (e.g., different unit displays), extend the data:

```r
# Add configuration dataframe
pollutant_config <- tibble(
  pollutant = c("SO2", "NO2", "PM10", "O3", "PM2.5"),
  unit = c("ppb", "ppb", "µg/m³", "ppb", "µg/m³"),
  display_name = c("Dióxido de azufre", "Dióxido de nitrógeno", 
                   "Material particulado 10", "Ozono", 
                   "Material particulado 2.5")
)

# Use in UI
output$unit_display <- renderText({
  poll <- input$pollutant_selector
  pollutant_config$unit[pollutant_config$pollutant == poll]
})
```

---

## Adding New Levels

Similar to pollutants, levels are typically detected dynamically from data.

**Example CSV with new level:**
```csv
value,pollutant,level
0.0523,SO2,low
0.0789,SO2,medium   <-- New level
0.1023,SO2,high
```

No code changes required if the app uses:
```r
unique_levels <- unique(raw_data$level)
```

---

## Extending the `ptcalc` Package

To add a new statistical method to the `ptcalc` package:

### Step 1: Create New Function File

Create a new R file in `ptcalc/R/`:

**File:** `ptcalc/R/new_method.R`

```r
#' Calculate Hampel Estimator
#'
#' @param x Numeric vector of values
#' @param k Window size for median calculation (default: 1.4826)
#' @return Numeric value (Hampel estimator)
#' @export
#' @examples
#' x <- c(1, 2, 3, 4, 5)
#' ptcalc::calculate_hampel(x)
calculate_hampel <- function(x, k = 1.4826) {
  n <- length(x)
  
  if (n < 3) {
    stop("Hampel estimator requires at least 3 values")
  }
  
  # Calculate MAD (median absolute deviation)
  median_val <- median(x, na.rm = TRUE)
  mad <- median(abs(x - median_val), na.rm = TRUE)
  
  # Hampel estimator
  hampel <- k * mad
  
  return(hampel)
}
```

### Step 2: Update Package Documentation

Generate roxygen documentation:

```bash
# From pt_app directory
devtools::document("ptcalc")
```

This creates `man/calculate_hampel.Rd` from the `#'` comments.

### Step 3: Install Updated Package

```bash
# Install in development mode
devtools::install("ptcalc")
```

Or reload without installing:

```bash
devtools::load_all("ptcalc")
```

### Step 4: Integrate in Application

**In cloned_app.R:**

```r
# Add to UI if needed
selectInput("estimator", "Estimator:",
  choices = c("Algorithm A", "MADe", "nIQR", "Hampel")
)

# Add to server logic
observeEvent(input$run_analysis, {
  data <- get_filtered_data()
  
  result <- switch(input$estimator,
    "Algorithm A" = ptcalc::algorithm_A(data),
    "MADe" = ptcalc::calculate_made(data),
    "nIQR" = ptcalc::calculate_niqr(data),
    "Hampel" = ptcalc::calculate_hampel(data)  # New method
  )
  
  rv$robust_result <- result
})
```

### Step 5: Add Unit Tests

Create test file: `ptcalc/tests/testthat/test_new_method.R`

```r
test_that("calculate_hampel works correctly", {
  expect_error(ptcalc::calculate_hampel(c(1, 2)), 
    "requires at least 3 values")
  
  result <- ptcalc::calculate_hampel(c(1, 2, 3, 4, 5))
  expect_type(result, "double")
  expect_true(result > 0)
})

test_that("calculate_hampel handles NA values", {
  result <- ptcalc::calculate_hampel(c(1, NA, 3, 4, 5))
  expect_false(is.na(result))
})
```

Run tests:

```bash
devtools::test("ptcalc")
```

---

## Customizing Report Templates

### Report Template Location

Templates are located in: `pt_app/inst/rmarkdown/templates/`

**Directory Structure:**
```
inst/
  rmarkdown/
    templates/
      pt_report/
        template.Rmd
        skeleton/
          resources/
            logo.png
```

### Modifying the RMarkdown Template

**template.Rmd key sections:**

```markdown
---
title: "Informe de Ensayo de Aptitud"
author: "`r params$coordinator`"
date: "`r format(Sys.Date(), '%d/%m/%Y')`"
output: 
  word_document:
    reference_docx: "styles.docx"
params:
  report_id: ""
  participant_id: ""
  data: NULL
---

## 1. Resumen Ejecutivo

```{r executive-summary, echo=FALSE}
# Your custom R code here
summary_data <- params$data %>% 
  summarise(
    n_participants = n_distinct(participant_id),
    n_pollutants = n_distinct(pollutant)
  )

knitr::kable(summary_data)
```

## 2. Resultados por Analito

```{r results-by-pollutant, echo=FALSE, warning=FALSE}
# Custom plots and tables
```
```

### Adding Custom CSS/Word Styles

For Word reports, create a `styles.docx` file in the template directory:

1. Open a blank Word document
2. Set up custom styles (headers, tables, etc.)
3. Save as `styles.docx`
4. Reference in YAML header: `reference_docx: "styles.docx"`

---

## Adding New Score Types

### Step 1: Implement Score Calculation in ptcalc

**File:** `ptcalc/R/scores.R`

```r
#' Calculate Q Score
#'
#' @param x Participant value
#' @param x_pt Assigned value
#' @param sigma Standard deviation
#' @return Q score value
#' @export
calculate_q_score <- function(x, x_pt, sigma) {
  q <- (x - x_pt) / sigma
  return(q)
}
```

### Step 2: Add to UI

**In cloned_app.R UI:**

```r
checkboxGroupInput("score_types", "Score Types:",
  choices = c("z", "z'", "zeta", "En", "Q")  # Add Q
)
```

### Step 3: Add to Server Logic

```r
compute_scores_for_selection <- function(data, assigned_value, sigma_pt, u_xpt) {
  scores <- list()
  
  if ("Q" %in% input$score_types) {
    scores$Q <- ptcalc::calculate_q_score(
      data$mean_value, 
      assigned_value, 
      sigma_pt
    )
  }
  
  return(scores)
}
```

### Step 4: Update Visualization

```r
plot_scores <- function(scores) {
  if ("Q" %in% names(scores)) {
    # Custom Q score plot
    plot_ly(data, x = ~participant_id, y = scores$Q, 
            type = "bar", name = "Q Score")
  }
}
```

---

## Internationalization (i18n)

### Current Language Support

The application is primarily in Spanish. To add English support:

```r
# Create translation dictionary
translations <- list(
  es = list(
    app_title = "Aplicativo para Evaluación de Ensayos de Aptitud",
    load_data = "Carga de Datos",
    calculate = "Calcular"
  ),
  en = list(
    app_title = "Proficiency Test Evaluation Application",
    load_data = "Data Loading",
    calculate = "Calculate"
  )
)

# Use in UI
ui <- fluidPage(
  titlePanel(translations[[input$language]]$app_title),
  tabPanel(translations[[input$language]]$load_data, ...)
)
```

Add language selector:

```r
selectInput("language", "Language:",
  choices = c("Español" = "es", "English" = "en"),
  selected = "es"
)
```

---

## Cross-References

- **Architecture**: See `15_architecture.md` for reactive patterns and state management
- **Package API**: See `02a_ptcalc_api.md` for existing ptcalc function reference
- **Data Formats**: See `01a_data_formats.md` for CSV schema details
- **Reports**: See `12_generacion_informes.md` for report generation workflow
