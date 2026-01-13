# 17. Troubleshooting Guide

| Property | Value |
|----------|-------|
| **Document Type** | FAQ / Error Solutions |
| **Primary File** | `cloned_app.R` |
| **Related Docs** | `01_carga_datos.md`, `15_architecture.md` |

---

## Quick Diagnostics

Before diving into specific errors, run these checks:

```r
# Check R version (requires >= 4.0)
R.version.string

# Check required packages
required_packages <- c("shiny", "bslib", "dplyr", "ggplot2", "rmarkdown")
sapply(required_packages, function(pkg) packageVersion(pkg))

# Check ptcalc package is loadable
library(ptcalc)
```

---

## Common Error Messages and Solutions

### Data Loading Errors

#### "El archivo debe contener columnas 'value', 'pollutant' y 'level'"

**Cause**: The uploaded CSV file is missing required columns.

**Solution**: Ensure your CSV has these exact column names (case-sensitive):

```csv
pollutant,level,value,replicate
SO2,low,0.052,1
SO2,low,0.055,2
```

**Checklist**:
- [ ] Column names are lowercase
- [ ] No extra spaces in column names
- [ ] File is comma-separated (not semicolon or tab)
- [ ] File encoding is UTF-8

---

#### "Error parsing CSV file" or garbled characters

**Cause**: File encoding mismatch or incorrect delimiter.

**Solution**:

1. **Check encoding**: Save file as UTF-8
   ```r
   # Read with explicit encoding
   data <- read.csv("file.csv", fileEncoding = "UTF-8")
   ```

2. **Check delimiter**: Ensure comma separation
   ```r
   # For semicolon-separated files
   data <- read.csv2("file.csv")
   ```

3. **Remove BOM**: Some Excel exports include a BOM character
   ```r
   # Read with BOM handling
   data <- read.csv("file.csv", fileEncoding = "UTF-8-BOM")
   ```

---

#### File upload appears stuck / no progress

**Cause**: File too large or browser timeout.

**Solution**:
1. Check file size (default Shiny limit is 5MB)
2. Increase limit if needed:
   ```r
   options(shiny.maxRequestSize = 30*1024^2)  # 30 MB
   ```
3. Split large files into smaller batches

---

### Analysis Errors

#### "No hay suficientes replicas (se requieren al menos 2)"

**Cause**: Homogeneity analysis requires at least 2 replicates per sample.

**Solution**: Verify your data has multiple replicates:

```csv
pollutant,level,replicate,value
SO2,low,1,0.052
SO2,low,2,0.055    <- Need at least 2 replicates
SO2,low,3,0.053    <- More is better
```

---

#### "No hay suficientes items (se requieren al menos 2)"

**Cause**: Homogeneity requires at least 2 items (samples/units).

**Solution**: Ensure your data represents multiple items being tested, not just multiple measurements of the same item.

---

#### "Algorithm A did not converge"

**Cause**: The iterative Algorithm A failed to reach convergence.

**Solutions**:
1. Check for extreme outliers in your data
2. Verify you have at least 3 participants
3. Check for data entry errors (very large or very small values)

```r
# Check data distribution
summary(data$value)
boxplot(data$value)
```

---

#### "No hay datos de referencia disponibles"

**Cause**: Reference-based scoring methods require a participant with `participant_id = "ref"`.

**Solution**: Ensure your data includes reference values:

```csv
pollutant,level,value,participant_id
SO2,low,0.050,ref          <- Reference participant
SO2,low,0.052,lab001
SO2,low,0.048,lab002
```

---

#### "Calcule los puntajes primero / Run scores first"

**Cause**: Trying to view results before running the calculation.

**Solution**: Click the appropriate "Ejecutar" / "Run" button first. The app uses a trigger-cache pattern that requires explicit user action.

---

### Score Calculation Errors

#### "sigma_pt is zero or negative"

**Cause**: The proficiency standard deviation cannot be calculated.

**Solutions**:
1. Check that you have sufficient variation in your data
2. Verify sigma_pt_1 formula inputs are valid
3. Ensure at least 3 participants for robust statistics

---

#### Missing scores for some pollutant/level combinations

**Cause**: Not all combinations exist in all uploaded files.

**Solution**: 
1. Verify each file contains the expected combinations
2. Check for typos in pollutant or level names
3. Ensure consistent naming across files

```r
# Check available combinations
unique(data[, c("pollutant", "level")])
```

---

### Report Generation Errors

#### "Error generating Word document"

**Cause**: RMarkdown or pandoc issues.

**Solutions**:

1. **Check pandoc installation**:
   ```r
   rmarkdown::pandoc_available()
   rmarkdown::pandoc_version()
   ```

2. **Install/update pandoc**: Download from [pandoc.org](https://pandoc.org/installing.html)

3. **Check temporary directory permissions**:
   ```r
   tempdir()
   file.access(tempdir(), mode = 2)  # Should return 0
   ```

---

#### Report downloads but is empty or corrupted

**Cause**: Error during rendering that wasn't caught.

**Solutions**:
1. Check R console for error messages
2. Verify all required data is present
3. Try generating HTML report first (fewer dependencies)

---

### UI/Display Issues

#### Plots not rendering / blank output

**Cause**: ggplot2 error or missing data.

**Solutions**:
1. Check browser developer console (F12) for JavaScript errors
2. Verify data exists for the selected combination
3. Try refreshing the page

---

#### Layout broken / overlapping elements

**Cause**: Browser zoom level or narrow window.

**Solutions**:
1. Reset browser zoom to 100%
2. Widen browser window
3. Adjust layout width settings in the app

---

#### Dropdowns show no options

**Cause**: Data not loaded or parsing failed.

**Solution**: Check that files uploaded successfully (green checkmark) before expecting dropdowns to populate.

---

## Data Format Issues

### Expected CSV Structure

#### Homogeneity Data (`hom_file`)

```csv
pollutant,level,replicate,value
SO2,low,1,0.0523
SO2,low,2,0.0528
SO2,low,3,0.0521
SO2,high,1,0.1562
SO2,high,2,0.1558
```

| Column | Required | Description |
|--------|----------|-------------|
| `pollutant` | Yes | Gas/analyte name |
| `level` | Yes | Concentration level |
| `replicate` | Yes | Replicate number |
| `value` | Yes | Measured value |

---

#### Stability Data (`stab_file`)

```csv
pollutant,level,time,value
SO2,low,0,0.0520
SO2,low,7,0.0518
SO2,low,14,0.0515
```

| Column | Required | Description |
|--------|----------|-------------|
| `pollutant` | Yes | Gas/analyte name |
| `level` | Yes | Concentration level |
| `time` | Yes | Time point (days) |
| `value` | Yes | Measured value |

---

#### Summary Data (`summary_files`)

```csv
pollutant,level,n_lab,value,participant_id,u_x
SO2,low,1,0.0523,lab001,0.002
SO2,low,1,0.0520,ref,0.001
SO2,high,1,0.1565,lab001,0.005
```

| Column | Required | Description |
|--------|----------|-------------|
| `pollutant` | Yes | Gas/analyte name |
| `level` | Yes | Concentration level |
| `n_lab` | Yes | Lab number (for multiple labs) |
| `value` | Yes | Reported value |
| `participant_id` | Yes | Participant identifier ("ref" for reference) |
| `u_x` | Optional | Participant's reported uncertainty |

---

### Common Data Issues Checklist

- [ ] Column names are exact (case-sensitive)
- [ ] No leading/trailing spaces in values
- [ ] Decimal separator is period (.) not comma
- [ ] No empty rows at end of file
- [ ] Consistent pollutant/level naming across files
- [ ] UTF-8 encoding

---

## Performance Issues

### Application is slow to load

**Causes and Solutions**:

1. **Large data files**: Split into smaller files
2. **Many participants**: Performance scales with participant count
3. **Google Fonts loading**: May be slow on first load

```r
# For offline use, use system fonts instead:
theme = bs_theme(
  base_font = "Arial",
  code_font = "Consolas"
)
```

---

### Calculations take too long

**Cause**: Processing many pollutant/level combinations.

**Solutions**:
1. Process fewer combinations at once
2. Ensure your R session has enough memory:
   ```r
   memory.limit()  # Windows
   gc()  # Force garbage collection
   ```

---

### Browser becomes unresponsive

**Cause**: JavaScript rendering large tables or plots.

**Solutions**:
1. Use Chrome or Firefox (better performance than some browsers)
2. Close other browser tabs
3. Reduce number of participants displayed at once

---

## Browser Compatibility

### Supported Browsers

| Browser | Version | Status |
|---------|---------|--------|
| Chrome | 90+ | Full support |
| Firefox | 88+ | Full support |
| Edge | 90+ | Full support |
| Safari | 14+ | Full support |
| IE 11 | - | Not supported |

---

### Known Browser Issues

#### Safari: Download filename incorrect

**Workaround**: Safari may not respect the suggested filename. Rename the file after downloading.

---

#### Firefox: Slow table rendering

**Workaround**: For very large tables, try Chrome which has faster table rendering.

---

#### Mobile browsers: Layout issues

**Note**: The application is designed for desktop use. Mobile browsers may have layout issues. Use a desktop browser for best experience.

---

## Getting Help

### Information to Include in Bug Reports

When reporting issues, include:

1. **R session info**:
   ```r
   sessionInfo()
   ```

2. **Error message**: Copy the exact error text

3. **Steps to reproduce**: What actions led to the error?

4. **Sample data**: A minimal CSV that reproduces the issue (anonymized if needed)

5. **Browser and OS**: Which browser and operating system?

---

### Debug Mode

Enable verbose logging for troubleshooting:

```r
options(shiny.trace = TRUE)
options(shiny.fullstacktrace = TRUE)

shiny::runApp("cloned_app.R")
```

Check the R console for detailed error messages.

---

## Quick Fixes Reference

| Problem | Quick Fix |
|---------|-----------|
| File won't upload | Check file size < 5MB, use UTF-8 encoding |
| Missing columns error | Verify exact column names (case-sensitive) |
| Calculation won't run | Click the Run button first |
| No reference values | Add `participant_id = "ref"` row to data |
| Report generation fails | Check pandoc is installed |
| Blank plots | Verify data exists for selection |
| Slow performance | Reduce data size, close other tabs |

---

## See Also

- `01_carga_datos.md` - Data format details
- `15_architecture.md` - System architecture
- `16_customization.md` - Customization options
