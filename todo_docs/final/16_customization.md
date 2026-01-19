# 16. Customization Guide

| Property | Value |
|----------|-------|
| **Document Type** | Configuration Guide |
| **Primary File** | `cloned_app.R` |
| **Related Docs** | `15_architecture.md`, `02_ptcalc_package.md`, `02a_ptcalc_api.md`, `01a_data_formats.md` |

---

## Overview

This guide covers various ways to customize the PT application, including:

- Theme customization (colors, fonts, Bootswatch themes)
- Layout width controls (dynamic and fixed)
- Adding new pollutants and concentration levels
- Extending the `ptcalc` package with new statistical methods and score types
- Customizing report templates and score visualization colors
- Internationalization (UI text customization)

---

## Location in Code

| Element | Value |
|---------|-------|
| Main Application File | `cloned_app.R` |
| Theme Definition | Lines 40-50 (approx.) |
| Layout Controls | Lines 58-67 (approx.) |
| Extension Points | Throughout server function and `ptcalc/` package |
| Report Templates | `pt_app/inst/rmarkdown/templates/` or inline in `downloadHandler` |

---

## Theme Customization (bslib)

The application uses Bootstrap 5 via the `bslib` package. The theme is defined at the top of `cloned_app.R`.

### Current Theme Configuration

```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",           # White background
  fg = "#212529",           # Dark foreground text
  primary = "#FDB913",      # Yellow/Gold (CALAIRE Yellow)
  secondary = "#333333",    # Dark gray secondary
  success = "#4DB848",      # Green success color
  base_font = font_google("Droid Sans"),
  code_font = font_google("JetBrains Mono")
)
```

### Color Palette Reference

| Variable | Current | Purpose | Usage |
|----------|---------|---------|-------|
| `bg` | `#FFFFFF` | Page background | Main application background |
| `fg` | `#212529` | Text color | Default body text |
| `primary` | `#FDB913` | Primary accent | Buttons, links, active elements (Yellow) |
| `secondary` | `#333333` | Secondary accent | Nav headers, secondary elements |
| `success` | `#4DB848` | Success color | Positive indicators, valid states |
| `info` | `#0dcaf0` | Info color | (Default) Information alerts |
| `warning`| `#ffc107` | Warning color | (Default) Warning alerts |
| `danger` | `#dc3545` | Error color | (Default) Error messages |

### Modifying Theme Colors

To change the color scheme, modify the hex values in the `bs_theme()` call.

#### Example: Blue Theme
```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = "#212529",
  primary = "#0d6efd",      # Bootstrap blue
  secondary = "#6c757d",    # Bootstrap gray
  success = "#198754",      # Bootstrap green
  base_font = font_google("Roboto"),
  code_font = font_google("Source Code Pro")
)
```

### Bootswatch Themes

You can easily switch to a predefined Bootswatch theme.

**Option 1: Runtime Selection**
The app includes a theme selector widget in the "Opciones de diseño" panel. Check "Mostrar opciones de diseño" to use the `themeSelector` widget.

**Option 2: Hardcode Theme**
```r
theme = bs_theme(
  version = 5,
  bootswatch = "cerulean",  # e.g., "flatly", "cosmo", "yeti"
  primary = "#FDB913"       # You can still override specific colors
)
```

### Changing Fonts

The application uses Google Fonts. Popular alternatives:
- **Body fonts:** `"Open Sans"`, `"Roboto"`, `"Lato"`, `"Source Sans Pro"`, `"Inter"`
- **Code fonts:** `"Fira Code"`, `"Source Code Pro"`, `"JetBrains Mono"`, `"IBM Plex Mono"`

```r
base_font = font_google("Inter"),
code_font = font_google("Fira Code")
```

---

## Layout Width Controls

The application provides dynamic layout controls via numeric or slider inputs in the UI.

### Dynamic Width Sliders

| Control | Input ID | Default | Range | Purpose |
|---------|----------|---------|-------|---------|
| Navigation Width | `nav_width` | 2 | 1-5 | Navigation panel width (Bootstrap columns) |
| Analysis Sidebar | `analysis_sidebar_width` | 3 | 2-6 | Analysis parameters panel width |

### Bootstrap Grid System Reference

The layout uses a 12-column grid. The content width is calculated as `12 - sidebar_width`.

| Width | Bootstrap Column | Visual Width (approx.) |
|-------|------------------|------------------------|
| 1 | `col-1` | 8.33% |
| 2 | `col-2` | 16.67% |
| 3 | `col-3` | 25.00% |
| 4 | `col-4` | 33.33% |

### Hardcoding Layout Widths

To set fixed widths, remove the `sliderInput` elements and use fixed values:
```r
sidebarLayout(
  sidebarPanel(width = 2, ...),
  mainPanel(width = 10, ...)
)
```

### Layout Recommendations

| Screen Size | nav_width | analysis_sidebar_width |
|-------------|-----------|------------------------|
| Small (laptop) | 2 | 4 |
| Medium (desktop) | 2 | 3 |
| Large (wide monitor) | 1 | 2 |

---

## Adding New Pollutants

The application automatically detects pollutants from uploaded data. Usually, **no code changes are required**.

### Data Requirements

Include the new pollutant (e.g., "PM2.5") in your CSV files (`homogeneity.csv`, `summary_*.csv`):

```csv
pollutant,level,replicate,value,participant_id
PM2.5,low,1,15.2,lab001
PM2.5,low,2,15.5,lab001
```

### Dynamic Detection

The app populates dropdowns using reactive expressions:
```r
pollutant_choices <- reactive({
  req(pt_prep_data())
  unique(pt_prep_data()$pollutant)
})
```

### Pollutant-Specific Configuration

If you need specific settings (like units), you can extend a configuration table in the server logic:
```r
pollutant_config <- tibble(
  pollutant = c("SO2", "NO2", "PM10", "PM2.5"),
  unit = c("ppb", "ppb", "µg/m³", "µg/m³")
)
```

---

## Adding New Concentration Levels

Concentration levels are also detected automatically from data.

### Data Format
```csv
pollutant,level,replicate,value
SO2,very_low,1,0.012
SO2,medium,1,0.156
```

### Level Ordering
Levels are sorted alphabetically. To customize order, prefix with numbers (e.g., `1_low`, `2_medium`) or use factors in data preparation.

---

## Extending the ptcalc Package

### Package Structure
```
ptcalc/
  DESCRIPTION
  NAMESPACE
  R/
    pt_robust_stats.R    # Robust statistics (Algorithm A, MADe, nIQR)
    pt_homogeneity.R     # Homogeneity and stability tests
    pt_scores.R          # Scoring (z, z', zeta, En)
```

### Adding a New Statistical Method

1. **Create or modify an R file** in `ptcalc/R/` (e.g., `new_method.R`):
```r
#' Calculate Hampel Estimator
#' @param x Numeric vector
#' @export
calculate_hampel <- function(x) {
  # Implementation
  median_val <- median(x, na.rm = TRUE)
  1.4826 * median(abs(x - median_val), na.rm = TRUE)
}
```

2. **Update Documentation and Install**:
```bash
devtools::document("ptcalc")
devtools::install("ptcalc")
```

### Adding a New Score Type

1. **Implement in `ptcalc/R/pt_scores.R`**:
```r
#' @export
calculate_q_score <- function(x, x_pt, sigma) {
  (x - x_pt) / sigma
}
```

2. **Integrate in `cloned_app.R`**:
- Update `selectInput("score_method", ...)` in UI.
- Update score computation logic in server (e.g., `switch` or `if` blocks).

### Development Workflow
```r
devtools::document("ptcalc") # Rebuild docs
devtools::load_all("ptcalc") # Fast reload for testing
devtools::test("ptcalc")     # Run unit tests
devtools::install("ptcalc")  # Install for app use
```

---

## Customizing Score Classification Colors

Score visualizations (like heatmaps) use predefined color palettes.

### Modifying Colors (e.g., En Score)
Edit `PT_EN_CLASS_COLORS` in `ptcalc/R/pt_scores.R`:
```r
PT_EN_CLASS_COLORS <- c(
  "a1" = "#2E7D32",  # Green - Excellent
  "a4" = "#FFEB3B",  # Yellow - Acceptable
  "a7" = "#B71C1C"   # Red - Poor
)
```

---

## Customizing Report Templates

Report generation uses RMarkdown templates.

### Template Location
Templates are typically in `pt_app/inst/rmarkdown/templates/pt_report/template.Rmd`. Some versions may use inline definitions in `downloadHandler`.

### Modifying the Template
You can edit `template.Rmd` to change the layout, add logos, or modify the executive summary logic.

**Example YAML Header:**
```yaml
---
title: "Informe de Ensayo de Aptitud"
output:
  word_document:
    reference_docx: "styles.docx"  # Use for custom Word styling
params:
  data: NULL
---
```

### Common Customizations
1. **Logo:** Add logo path to the template or `inst/resources`.
2. **Styles:** Modify `styles.docx` to set default fonts and table styles for Word exports.

---

## UI Text Customization (Internationalization)

The application is in Spanish by default.

### Approach 1: Direct Modification
Search and replace strings in `cloned_app.R`:
`actionButton("run", "Ejecutar")` → `actionButton("run", "Run")`

### Approach 2: Externalize Strings
Create a translation dictionary:
```r
translations <- list(
  es = list(calculate = "Calcular"),
  en = list(calculate = "Calculate")
)
# Use in UI/Server: translations[[input$language]]$calculate
```

---

## See Also

- `15_architecture.md`: System architecture and reactive patterns.
- `02a_ptcalc_api.md`: Detailed reference of `ptcalc` functions.
- `01a_data_formats.md`: CSV schema details for pollutants and levels.
- `12_generacion_informes.md`: Report generation workflow.
