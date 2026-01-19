# 17. Troubleshooting Guide & FAQ

| Property | Value |
|----------|-------|
| **Document Type** | FAQ / Error Solutions |
| **Primary File** | `app.R` / `cloned_app.R` |
| **Related Docs** | `01_carga_datos.md`, `15_architecture.md`, `02_ptcalc_package.md` |

This document provides solutions to common errors, issues, and problems encountered when using the PT Data Analysis application. It includes troubleshooting for data loading, calculations, performance optimization, and browser compatibility.

---

## Quick Diagnostics

Before diving into specific errors, run these checks in your R console:

```r
# 1. Check R version (requires >= 4.2)
R.version.string

# 2. Check required packages
required_packages <- c("shiny", "tidyverse", "vroom", "DT", "bslib", "plotly", "rmarkdown")
sapply(required_packages, function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    packageVersion(pkg)
  } else {
    "Not Installed"
  }
})

# 3. Check ptcalc package is loadable
library(ptcalc)
```

---

## Common Error Messages

| Error Message | Context | Root Cause | Solution |
|---------------|---------|------------|----------|
| `disconnected from the server` | General application crash | R session out of memory or syntax error | Check R console for stack trace. Increase R memory or reduce input file size. |
| `must contain the columns 'value', 'pollutant', 'level'` | Data loading | CSV header doesn't match expected format | Verify column names exactly match (case-sensitive: `value` ≠ `Value`). |
| `No hay suficientes ítems...` (Not enough items) | Homogeneity analysis | Fewer than 2 groups in ANOVA | Ensure CSV has at least 2 different `level` groups for the selected pollutant. |
| `replacement has length zero` | Calculation | Function returned `NULL` or empty vector | Check for `NA` values in input data or missing columns. |
| `there is no package called 'ptcalc'` | Application startup | ptcalc package not installed | Run `devtools::install("ptcalc")` from project root directory. |
| `Error in algorithm_A(x) : Not enough data` | Algorithm A calculation | Fewer than 3 participants/values | Algorithm A requires ≥ 3 values. Add more participants or use MADe/nIQR. |
| `Algorithm A did not converge` | Iterative calculation | Extreme outliers or bad data | Remove extreme outliers or check for data entry errors. |
| `argument is not numeric or logical` | Score calculation | Data column contains non-numeric values | Check for text like "N/A" instead of `NA`. Convert to numeric. |
| `sigma_pt is zero or negative` | Score calculation | No variation in data | Verify formula inputs and ensure sufficient variation in participant results. |
| `object 'input$...' not found` | Reactive evaluation | Typos in code or missing UI element | Verify input ID matches UI definition. |
| `Error generating Word document` | Report generation | Pandoc/RMarkdown issue | Check pandoc installation with `rmarkdown::pandoc_available()`. |

---

## Data Format Issues

### 1. Column Naming and Structure
The application requires specific column names. Typos or case mismatches are the most common cause of "missing column" errors.

**Required Columns per File Type:**

| File Type | Required Columns |
|-----------|------------------|
| `homogeneity.csv` | `pollutant`, `level`, `replicate`, `value` |
| `stability.csv` | `pollutant`, `level`, `time`, `value` |
| `summary_n*.csv` | `pollutant`, `level`, `participant_id`, `value`, `u_x` (optional), `U_x` (optional) |

**Quick Fix Script (R):**
```r
# Standardize column names
names(df) <- tolower(trimws(names(df)))
names(df) <- gsub(" ", "_", names(df))
```

### 2. Decimal Separators
Use dots (`.`) for decimals, not commas (`,`).

| Incorrect | Correct |
|-----------|---------|
| `0,0523`  | `0.0523` |
| `12,5`    | `12.5`   |

**Solution:** In Excel, format cells as "Number" with `.` as decimal separator before exporting to CSV.

### 3. File Encoding (UTF-8)
Special characters (accents, ñ) cause `invalid multibyte string` errors if not saved in UTF-8.

**Solution:**
- **Excel:** File → Save As → CSV UTF-8 (Comma delimited) (*.csv).
- **R:** `read.csv("file.csv", fileEncoding = "UTF-8")` or `fileEncoding = "UTF-8-BOM"`.

### 4. Missing Values (NA)
Empty cells or strings like "N/A" can crash calculations.

**Solution:**
```r
# Replace common invalid strings with proper NA
df <- df %>% mutate(across(everything(), ~na_if(., ""))) %>% mutate(across(everything(), ~na_if(., "N/A")))
```

---

## Application Startup & Installation

### ptcalc Package Not Found
If you see `there is no package called 'ptcalc'`:

1.  **Install from source:**
    ```bash
    devtools::install("ptcalc")
    ```
2.  **Developer Mode:** If modifying the package, use `devtools::load_all("ptcalc")` in `app.R` instead of `library(ptcalc)`.

### R Version Incompatibility
The application requires R >= 4.2.0. Older versions may fail to install `bslib` or `plotly` dependencies.

---

## Module-Specific Issues

### Homogeneity & Stability
- **"No hay suficientes replicas"**: Homogeneity requires at least 2 replicates per sample.
- **"No hay suficientes items"**: Homogeneity requires at least 2 distinct items/units.
- **Negative variance**: Can occur in `s_within` calculation if data is highly inconsistent. Check for data entry errors.

### Value Assignment & Scoring
- **"No hay datos de referencia disponibles"**: Reference methods require a row where `participant_id = "ref"`.
- **"Calcule los puntajes primero"**: You must click the "Ejecutar" / "Run" button to trigger the calculation cache.
- **Missing combinations**: If scores don't appear for a specific pollutant, check that it exists in both the summary and the reference/assigned value files.

---

## Performance Optimization

### Large Datasets (>100MB)
| Dataset Size | Expected Behavior | Optimization |
|--------------|-------------------|--------------|
| 10-100 MB | Moderate lag | Increase R memory limit |
| > 100 MB | Slow / Crashes | Pre-aggregate data |

**Increase Memory Limit (Windows):**
```r
memory.limit(size = 8000) # Set to 8GB
```

### Slow Plot Rendering
Plotly can be slow with >10,000 points.
- **Solution:** Downsample data for visualization: `data %>% sample_n(min(n(), 5000))`.
- **Static Plots:** Use `ggplot2` without `ggplotly()` for faster rendering of extremely large datasets.

---

## Browser Compatibility & UI Issues

### Supported Browsers
- **Recommended:** Chrome, Firefox, Edge (Chromium).
- **Safari:** Known issues with download filenames (may require manual renaming) and flexbox layout in versions < 15.
- **IE 11:** Not supported.

### UI Display Issues
- **Plots not rendering:** Check browser console (F12) for JavaScript errors. Ensure data exists for the selection.
- **Layout broken:** Reset browser zoom to 100%. Adjust "Layout Width" sliders in the application sidebar.
- **Pop-up Blocking:** Ensure pop-ups are allowed for report generation/downloads.

---

## Debugging Tips

### Enable Detailed Logging
In your R session before running the app:
```r
options(shiny.trace = TRUE)
options(shiny.fullstacktrace = TRUE)
options(shiny.reactlog = TRUE) # Press Ctrl+F3 in browser to see reactive flow
```

### Print Diagnostics
Add `observe({ print(input$pollutant_selector) })` in the server function to track state changes.

---

## Prevention: Best Practices

- [ ] **UTF-8 Encoding:** Always save CSVs as UTF-8.
- [ ] **Check Headers:** Ensure column names match the "Required Columns" table exactly.
- [ ] **Data Cleaning:** Remove empty rows and check for non-numeric characters in value columns.
- [ ] **Small Steps:** Test with a small subset of data if a large file fails.
- [ ] **Click Run:** Remember that the app requires explicit "Run" button clicks for major calculations.

---

## Quick Fixes Reference

| Problem | Quick Fix |
|---------|-----------|
| File won't upload | Check file size (< 30MB), use UTF-8 encoding |
| Missing columns error | Verify exact column names (case-sensitive) |
| Calculation won't run | Click the "Ejecutar" button first |
| No reference values | Add `participant_id = "ref"` row to data |
| Report generation fails | Check if pandoc is installed |
| Blank plots | Verify data exists for selection; check browser zoom |
| Slow performance | Reduce data size; close other browser tabs |

---

## See Also

- `01_carga_datos.md` - Detailed data format specifications.
- `15_architecture.md` - Overview of the system structure.
- `02a_ptcalc_api.md` - Documentation for the underlying calculation functions.
