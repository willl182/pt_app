# Troubleshooting & FAQ

This document provides solutions to common errors, issues, and problems encountered when using the application. It includes data format issues, performance optimization tips, and browser compatibility notes.

---

## Common Error Messages

| Error Message | Context | Root Cause | Solution |
|---------------|---------|------------|---------|
| `disconnected from the server` | General application crash | R session out of memory or syntax error | Check R console for stack trace. Increase R memory with `R_MAX_VSIZE` or reduce input file size. |
| `must contain the columns 'value', 'pollutant', 'level'` | Data loading | CSV header doesn't match expected format | Verify column names exactly match (case-sensitive: `value` ≠ `Value`). Use `names(df)` in R to check. |
| `No hay suficientes ítems...` (Not enough items) | Homogeneity analysis | Fewer than 2 groups in ANOVA | Ensure CSV has at least 2 different `level` groups with data for the selected pollutant. |
| `replacement has length zero` | Calculation | Function returned `NULL` or empty vector | Check for `NA` values in input data. Verify data columns have sufficient non-missing values. |
| `there is no package called 'ptcalc'` | Application startup | ptcalc package not installed | Run `devtools::install("ptcalc")` from project root directory. |
| `Error in algorithm_A(x) : Not enough data` | Algorithm A calculation | Fewer than 3 participants/values | Algorithm A requires ≥ 3 values. Add more participants or use alternative estimator (MADe/nIQR). |
| `argument is not numeric or logical` | Score calculation | Data column contains non-numeric values | Check for text entries like "N/A" instead of `NA`. Use `df$column <- as.numeric(df$column)` to convert. |
| `object 'input$...' not found` | Reactive evaluation | Input reference doesn't exist | Verify input ID matches UI definition. Check for typos in `input$variable_name`. |

---

## Data Format Issues

### Decimal Separator

**Problem:** Application rejects values with comma decimal separators.

| Incorrect | Correct |
|-----------|---------|
| `0,0523` | `0.0523` |
| `12,5` | `12.5` |

**Solution:** 
1. In Excel/Spreadsheet: Format cells as "Number" with decimal point
2. In R CSV export: Use `write.csv(..., dec = ".")`
3. In text editors: Use Find/Replace: `,` → `.` (be careful with thousand separators)

### File Encoding

**Problem:** Special characters (accents, ñ) display incorrectly or cause errors.

**Symptoms:**
- Participant names show as `Lab1` instead of `Laboratorio 1`
- Error: `invalid multibyte string`

**Solution:**
- Save CSV files as **UTF-8** encoding
- In Excel: File → Save As → CSV UTF-8 (Comma delimited) (*.csv)
- In R: `read.csv("file.csv", fileEncoding = "UTF-8")`

### Missing Values

**Problem:** Empty cells or inconsistent NA representations cause calculation errors.

| Invalid Representations | Valid Representation |
|------------------------|---------------------|
| Empty cell `""` | `NA` |
| `-999` | `NA` |
| `"N/A"` | `NA` |
| `NULL` | `NA` |

**Solution:**
```r
# Replace invalid NAs with proper NA
df <- df %>%
  mutate(across(everything(), ~na_if(., ""))) %>%        # Empty strings to NA
  mutate(across(everything(), ~na_if(., "N/A"))) %>%     # "N/A" to NA
  mutate(across(where(is.character), ~na_if(., "-999"))) # "-999" to NA
```

### Column Naming

**Required Columns per File Type:**

| File Type | Required Columns |
|-----------|------------------|
| `homogeneity.csv` | `value`, `pollutant`, `level` |
| `stability.csv` | `value`, `pollutant`, `level` |
| `summary_n*.csv` | `participant_id`, `pollutant`, `level`, `mean_value`, `sd_value` |

**Common Mistakes:**
- Using Spanish names: `valor` instead of `value`
- Extra spaces: `value ` (trailing space)
- Case mismatch: `Value` instead of `value`

**Quick Fix in R:**
```r
# Standardize column names
names(df) <- tolower(names(df))           # Convert to lowercase
names(df) <- trimws(names(df))           # Remove spaces
names(df) <- gsub(" ", "_", names(df))    # Spaces to underscores
```

---

## Performance Issues

### Large Dataset Handling

**Problem:** Application becomes slow or unresponsive with large files.

| Dataset Size | Expected Behavior | Optimization |
|--------------|-------------------|--------------|
| < 1 MB | Instant (< 1 second) | None needed |
| 1-10 MB | Fast (1-3 seconds) | None needed |
| 10-100 MB | Moderate (3-10 seconds) | Consider aggregation |
| > 100 MB | Slow (> 10 seconds) | Pre-aggregate or increase memory |

**Solutions:**

**1. Increase R Memory Limit**
```r
# In R session before launching app
memory.limit(size = 8000)  # Windows: Set to 8GB
# Linux/Mac: Use ulimit in shell
ulimit -v 8000000
```

**2. Pre-aggregate Data**
```r
# Before loading, aggregate by participant/pollutant/level
df <- df %>%
  group_by(participant_id, pollutant, level) %>%
  summarise(
    mean_value = mean(value, na.rm = TRUE),
    sd_value = sd(value, na.rm = TRUE),
    .groups = "drop"
  )
```

**3. Use Data Types Efficiently**
```r
# Read with optimized types
df <- vroom::vroom("file.csv",
  col_types = cols(
    participant_id = col_character(),
    pollutant = col_factor(),
    level = col_factor(),
    mean_value = col_double(),
    sd_value = col_double()
  )
)
```

### Slow Plot Rendering

**Problem:** Plots with many data points (>10,000) render slowly.

**Symptoms:**
- Plotly charts lag when zooming/panning
- Browser becomes unresponsive during plot generation

**Solutions:**

**1. Downsample for Visualization**
```r
# Reduce to max 5,000 points for plots
plot_data <- data %>%
  sample_n(min(n(), 5000))  # Random sampling
```

**2. Use Static Plots for Large Data**
```r
# Replace plotly with ggplot2 for static images
ggplot(data, aes(x = participant_id, y = score)) +
  geom_point(alpha = 0.3)
```

**3. Implement Virtual Scrolling (Advanced)**
```r
# Use DT with server-side processing
DT::renderDataTable({
  DT::datatable(data, options = list(
    serverSide = TRUE,  # Only render visible rows
    deferRender = TRUE
  ))
})
```

### Cache Issues

**Problem:** Calculations re-run unnecessarily.

**Solution:**
- The application uses `reactiveVal` for caching
- Manually clear cache by reloading page
- Check that cache keys are unique per parameter combination

---

## Browser Compatibility

### Recommended Browsers

| Browser | Version | Status |
|---------|---------|--------|
| Chrome/Chromium | 90+ | **Recommended** ✅ |
| Firefox | 88+ | **Recommended** ✅ |
| Microsoft Edge | 90+ | **Recommended** ✅ |
| Safari | 15+ | Supported ⚠️ |

### Known Issues

| Browser | Issue | Workaround |
|---------|-------|------------|
| Safari < 15 | Flexbox layout issues | Upgrade Safari or use Chrome |
| Internet Explorer | Not supported | Use modern browser |
| Mobile browsers | Small UI elements | Use desktop version |

### Pop-up Blocking

**Problem:** Report downloads fail silently.

**Solution:**
1. Check browser pop-up settings
2. Allow pop-ups for `localhost` or application domain
3. Check browser downloads folder

### PDF/Word Download Issues

**Problem:** Report generation fails or produces corrupted files.

**Troubleshooting:**

| Symptom | Cause | Solution |
|---------|-------|----------|
| Download starts but fails | Missing Pandoc | Install Pandoc: `conda install -c conda-forge pandoc` |
| File opens with garbage text | Wrong file type | Ensure output format matches file extension |
| Report has no data | Empty cache | Re-run calculations before generating report |

---

## Application Startup Issues

### ptcalc Package Not Found

**Error:**
```
Error in library(ptcalc) : there is no package called 'ptcalc'
```

**Solution:**

**Option 1: Install from source**
```bash
cd /path/to/pt_app
devtools::install("ptcalc")
```

**Option 2: Load in development mode**
```r
# In cloned_app.R, change line 35:
# From: library(ptcalc)
# To: devtools::load_all("ptcalc")
```

### Missing Dependencies

**Error:**
```
there is no package called 'bslib'
```

**Solution:**
```r
# Install all required packages
install.packages(c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable",
  "shinythemes", "outliers", "patchwork", "bsplus",
  "plotly", "rmarkdown", "bslib"
))
```

### R Version Incompatibility

**Symptoms:**
- Packages fail to install
- Shiny app won't launch
- Strange error messages about S4 methods

**Solution:**
- Minimum R version: **4.2.0**
- Update R: Download from https://cran.r-project.org/
- After updating, reinstall all packages

---

## Module-Specific Issues

### Homogeneity Module

| Issue | Cause | Solution |
|-------|-------|----------|
| "ANOVA requires ≥ 2 levels" | Only one level in data | Add another level to CSV or filter correctly |
| s_within calculation error | Negative variance | Check data consistency; may need data cleaning |
| F-test fails | Degrees of freedom issue | Verify sample sizes in each level |

### Stability Module

| Issue | Cause | Solution |
|-------|-------|----------|
| "Insufficient data for stability" | < 2 time points | Add more stability measurements |
| t-test error | Zero variance | Check for identical values across time points |

### Value Assignment Module

| Issue | Cause | Solution |
|-------|-------|----------|
| Algorithm A doesn't converge | Extreme outliers | Remove outliers manually or use MADe/nIQR |
| "Not enough participants for consensus" | < 3 participants | Add more participant data |

### Scoring Module

| Issue | Cause | Solution |
|-------|-------|----------|
| "Missing assigned value" | Value assignment not calculated | Run value assignment first |
| z-score is NA | Participant value is NA | Clean participant data before scoring |

---

## Debugging Tips

### Enable Shiny Debug Mode

```r
options(shiny.reactlog = TRUE)

# After running app, open in browser:
# http://localhost:3838/reactlog
```

### Print Reactive Values

```r
# In server function, add diagnostic output:
observe({
  cat("Input pollutant:", input$pollutant_selector, "\n")
  cat("Data rows:", nrow(pt_prep_data()), "\n")
  print(str(pt_prep_data()$pollutant))
})
```

### Check Reactive Dependencies

```r
# Install shinyloadtest
install.packages("shinyloadtest")

# Record app usage
rec <- shinyloadtest::record_session("path/to/app.R")

# Analyze performance
shinyloadtest::show_session(rec)
```

---

## Getting Help

### Internal Resources

1. **Check logs**: View R console for detailed error messages
2. **Review documentation**: See related docs for module-specific help
3. **Validate data**: Ensure CSV files match expected format

### Documentation Cross-References

| Issue | Related Document |
|-------|------------------|
| Data format problems | `01_carga_datos.md`, `01a_data_formats.md` |
| Calculation errors | `03_pt_robust_stats.md`, `04_pt_homogeneity.md`, `05_pt_scores.md` |
| Package issues | `02_ptcalc_package.md`, `02a_ptcalc_api.md` |
| Architecture help | `15_architecture.md` |

### External Resources

- **Shiny Documentation**: https://shiny.rstudio.com/
- **ptcalc Package Issues**: Check `ptcalc/` directory for test files and documentation
- **R Community**: Stack Overflow with tags `[r] [shiny]`

---

## Prevention: Best Practices

### Before Starting Analysis

- [ ] Verify all CSV files use UTF-8 encoding
- [ ] Check column names match exactly
- [ ] Ensure decimal points (not commas)
- [ ] Validate required columns are present
- [ ] Test with small dataset first

### Regular Maintenance

- [ ] Clear browser cache periodically
- [ ] Update R and packages monthly
- [ ] Keep backup of working configuration
- [ ] Document any custom modifications

### Performance Monitoring

```r
# Add to server function
startTime <- Sys.time()
# ... code ...
cat("Calculation time:", Sys.time() - startTime, "\n")
```
