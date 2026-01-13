# 16. Customization Guide

| Property | Value |
|----------|-------|
| **Document Type** | Configuration Guide |
| **Primary File** | `cloned_app.R` |
| **Related Docs** | `15_architecture.md`, `02_ptcalc_package.md` |

---

## Overview

This guide covers customization options for the PT application, including:

- Theme customization (colors, fonts)
- Layout width controls
- Adding new pollutants and levels
- Extending the `ptcalc` package

---

## Theme Customization (bslib)

The application uses Bootstrap 5 via the `bslib` package. The theme is defined at the top of `cloned_app.R`:

```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",           # White background
  fg = "#212529",           # Dark foreground text
  primary = "#FDB913",      # Yellow/Gold primary color
  secondary = "#333333",    # Dark gray secondary
  success = "#4DB848",      # Green success color
  base_font = font_google("Droid Sans"),
  code_font = font_google("JetBrains Mono")
)
```

### Modifying Theme Colors

To change the color scheme, modify the hex values:

| Variable | Current | Purpose |
|----------|---------|---------|
| `bg` | `#FFFFFF` | Page background color |
| `fg` | `#212529` | Text color |
| `primary` | `#FDB913` | Primary buttons, links, accents |
| `secondary` | `#333333` | Secondary elements |
| `success` | `#4DB848` | Success messages, positive indicators |

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

### Changing Fonts

The application uses Google Fonts. To change fonts:

```r
base_font = font_google("Open Sans"),      # Body text
code_font = font_google("Fira Code")       # Code blocks
```

Popular alternatives:
- Body fonts: `"Roboto"`, `"Lato"`, `"Source Sans Pro"`, `"Nunito"`
- Code fonts: `"Fira Code"`, `"Source Code Pro"`, `"IBM Plex Mono"`

### Runtime Theme Selector

The app includes a collapsible theme selector panel for runtime customization:

```r
checkboxInput("show_layout_options", "Mostrar opciones de diseno", value = FALSE)

# When checked, displays:
conditionalPanel(
  condition = "input.show_layout_options == true",
  themeSelector()  # bslib theme picker widget
)
```

Users can toggle this in the UI to experiment with different themes without modifying code.

---

## Layout Width Controls

The application provides dynamic layout controls via numeric inputs:

### Available Controls

| Input ID | Default | Range | Purpose |
|----------|---------|-------|---------|
| `nav_width` | 2 | 1-5 | Navigation panel width (Bootstrap columns) |
| `analysis_sidebar_width` | 3 | 2-6 | Analysis sidebar width (Bootstrap columns) |

### How Width Calculation Works

The layout uses a 12-column Bootstrap grid:

```r
# In output$main_layout
nav_width <- input$nav_width %||% 2
content_width <- 12 - nav_width

analysis_sidebar_w <- input$analysis_sidebar_width %||% 3
analysis_main_w <- 12 - analysis_sidebar_w
```

### Modifying Default Widths

To change default widths, modify the `numericInput` definitions:

```r
numericInput(
  "nav_width",
  "Ancho del panel de navegacion (1-5):",
  value = 2,          # Change default here
  min = 1,
  max = 5
)

numericInput(
  "analysis_sidebar_width",
  "Ancho del sidebar de analisis (2-6):",
  value = 3,          # Change default here
  min = 2,
  max = 6
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

The application automatically detects pollutants from uploaded data. No code changes are required to add new pollutants.

### Data Requirements

To add a new pollutant (e.g., "PM2.5"), include it in your CSV files:

```csv
pollutant,level,replicate,value,participant_id
PM2.5,low,1,15.2,lab001
PM2.5,low,2,15.5,lab001
PM2.5,high,1,45.3,lab001
PM2.5,high,2,45.1,lab001
```

### Dynamic Selector Population

The app populates pollutant dropdowns dynamically:

```r
# Pollutant choices come from data
pollutant_choices <- reactive({
  req(pt_prep_data())
  unique(pt_prep_data()$pollutant)
})

# UI updates automatically
output$pollutant_selector <- renderUI({
  selectInput("pollutant", "Analito:", choices = pollutant_choices())
})
```

### Considerations for New Pollutants

1. **Naming Convention**: Use consistent naming across all data files
2. **Units**: Ensure units are consistent within each pollutant
3. **Levels**: Each pollutant can have different concentration levels
4. **Reference Values**: Include reference participant data if using reference-based scoring

---

## Adding New Concentration Levels

Similar to pollutants, concentration levels are detected automatically from data.

### Data Format

```csv
pollutant,level,replicate,value
SO2,very_low,1,0.012
SO2,low,1,0.052
SO2,medium,1,0.156
SO2,high,1,0.423
SO2,very_high,1,0.891
```

### Level Ordering

Levels are sorted alphabetically by default. For custom ordering, consider prefixing with numbers:

```csv
level
1_very_low
2_low
3_medium
4_high
5_very_high
```

Or use a factor with explicit levels in your data preparation.

---

## Extending the ptcalc Package

### Package Structure

```
ptcalc/
  DESCRIPTION
  NAMESPACE
  R/
    pt_robust_stats.R
    pt_homogeneity.R
    pt_scores.R
    ptcalc-package.R
  man/
```

### Adding a New Function

1. **Create or modify an R file** in `ptcalc/R/`:

```r
# In ptcalc/R/pt_scores.R

#' Calculate Custom Score
#'
#' @param x Participant value
#' @param x_pt Assigned value
#' @param sigma Custom standard deviation
#' @return Numeric score value
#' @export
calculate_custom_score <- function(x, x_pt, sigma) {
  if (sigma <= 0) {
    stop("sigma must be positive")
  }
  (x - x_pt) / sigma
}
```

2. **Export the function** in `NAMESPACE`:

```r
export(calculate_custom_score)
```

Or use roxygen2 with `@export` tag (recommended).

3. **Document the function** by running:

```r
devtools::document("ptcalc")
```

4. **Reload the package**:

```r
devtools::load_all("ptcalc")
```

### Adding a New Score Type

To add a completely new score type to the application:

1. **Add calculation function** to `ptcalc/R/pt_scores.R`:

```r
#' @export
calculate_my_score <- function(x, x_pt, sigma, u_x) {
  # Your formula here
  (x - x_pt) / sqrt(sigma^2 + u_x^2)
}

#' @export
evaluate_my_score <- function(score) {
  if (abs(score) <= 2) "Satisfactorio"
  else if (abs(score) <= 3) "Cuestionable"
  else "Insatisfactorio"
}
```

2. **Add to app's score computation** in `cloned_app.R`:

```r
# In compute_combo_scores function
if (method == "my_method") {
  scores <- calculate_my_score(values, x_pt, sigma, u_x)
  evaluations <- sapply(scores, evaluate_my_score)
}
```

3. **Add UI controls** for the new score type:

```r
# In score method selector
selectInput("score_method", "Metodo de puntaje:",
  choices = c(
    "z" = "z",
    "z'" = "z_prime",
    "zeta" = "zeta",
    "En" = "en",
    "My Score" = "my_method"  # Add new option
  )
)
```

### Development Workflow

```r
# Make changes to ptcalc/R/*.R files

# Rebuild documentation
devtools::document("ptcalc")

# Reload package (faster than install)
devtools::load_all("ptcalc")

# Run tests
devtools::test("ptcalc")

# Check package
devtools::check("ptcalc")

# When ready, install
devtools::install("ptcalc")
```

---

## Customizing Score Classification Colors

Score heatmaps use predefined color palettes. To customize:

### Default Colors (En Score)

```r
# In ptcalc/R/pt_scores.R
PT_EN_CLASS_COLORS <- c(
  "a1" = "#2E7D32",  # Dark green - Excellent
  "a2" = "#4CAF50",  # Green - Very good
  "a3" = "#8BC34A",  # Light green - Good
  "a4" = "#FFEB3B",  # Yellow - Acceptable
  "a5" = "#FF9800",  # Orange - Marginal
  "a6" = "#F44336",  # Red - Poor
  "a7" = "#B71C1C"   # Dark red - Very poor
)
```

### Modifying Colors

Edit the color values in `ptcalc/R/pt_scores.R`:

```r
PT_EN_CLASS_COLORS <- c(
  "a1" = "#1B5E20",  # Custom dark green
  "a2" = "#388E3C",  # Custom medium green
  "a3" = "#66BB6A",  # Custom light green
  "a4" = "#FDD835",  # Custom yellow
  "a5" = "#FB8C00",  # Custom orange
  "a6" = "#E53935",  # Custom red
  "a7" = "#C62828"   # Custom dark red
)
```

---

## Customizing Report Templates

Report generation uses RMarkdown templates. To customize:

### Template Location

Reports are generated using `downloadHandler` with inline RMarkdown:

```r
output$download_report <- downloadHandler(
  filename = function() {
    paste0("informe_pt_", Sys.Date(), ".docx")
  },
  content = function(file) {
    # Template is defined inline or loaded from file
    rmarkdown::render(template_file, output_file = file, ...)
  }
)
```

### Common Customizations

1. **Header/Footer**: Modify the YAML front matter
2. **Logo**: Add logo image path in template
3. **Styling**: Use custom Word reference document

```yaml
---
title: "Informe de Ensayo de Aptitud"
output:
  word_document:
    reference_doc: custom_template.docx
---
```

---

## UI Text Customization (Internationalization)

The application uses Spanish by default. To modify text:

### Approach 1: Direct Modification

Search and replace text strings in `cloned_app.R`:

```r
# Before
actionButton("run_analysis", "Ejecutar Analisis")

# After (English)
actionButton("run_analysis", "Run Analysis")
```

### Approach 2: Externalize Strings

For full internationalization, create a strings file:

```r
# strings_es.R
strings <- list(
  run_analysis = "Ejecutar Analisis",
  pollutant = "Analito",
  level = "Nivel"
)

# strings_en.R
strings <- list(
  run_analysis = "Run Analysis",
  pollutant = "Pollutant",
  level = "Level"
)

# In app
source("strings_es.R")  # or strings_en.R
actionButton("run_analysis", strings$run_analysis)
```

---

## See Also

- `15_architecture.md` - System architecture details
- `02_ptcalc_package.md` - Package function reference
- `17_troubleshooting.md` - Common issues and solutions
