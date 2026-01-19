# Customization Guide

## 1. Theme Customization
The application uses `bslib` for theming, allowing easy switching between Bootswatch themes or custom color palettes.

**Location:** `cloned_app.R` (UI definition)

```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = "#212529",
  primary = "#FDB913", # CALAIRE Yellow
  secondary = "#333333",
  ...
)
```

To change the theme entirely:
1.  Open the "Opciones de diseño" panel in the app sidebar.
2.  Use the `themeSelector` widget to preview themes.
3.  Hardcode the choice in `bs_theme(bootswatch = "cerulean")`.

## 2. Layout Controls
Users can adjust panel widths dynamically. These are controlled by `sliderInput`s in the UI.

*   `nav_width`: Controls the left navigation bar (1-5 units).
*   `analysis_sidebar_width`: Controls the parameters panel in analysis tabs (2-6 units).

## 3. Adding New Pollutants
To support a new pollutant (e.g., "PM2.5"):

1.  **Update CSVs:** Ensure your `homogeneity.csv` and `summary_*.csv` files contain the new pollutant code in the `pollutant` column.
2.  **App Logic:** The app dynamically detects pollutants from the data (`unique(df$pollutant)`), so often **no code change is required**.
3.  **Hardcoded Lists (if any):** Check `uiOutput` definitions if they rely on a fixed list (currently, most are dynamic).

## 4. Extending `ptcalc`
To add a new statistical method (e.g., Hampel estimator):

1.  Create `ptcalc/R/new_method.R`.
2.  Implement `calculate_hampel(x)`.
3.  Add `@export` tag.
4.  Run `devtools::document("ptcalc")` and `devtools::install("ptcalc")`.
5.  Call `ptcalc::calculate_hampel()` in `cloned_app.R`.
