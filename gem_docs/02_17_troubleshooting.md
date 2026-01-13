# Troubleshooting & FAQ

## 1. Common Error Messages

| Error | Context | Solution |
|:---|:---|:---|
| `disconnected from the server` | General Crash | Check R console for "Out of Memory" or syntax errors in input files. |
| `must contain the columns 'value', 'pollutant'...` | Data Loading | Fix CSV headers. Ensure case sensitivity (`Value` != `value`). |
| `No hay suficientes ítems...` | Homogeneity | You need at least 2 items (groups) to calculate ANOVA. Check your CSV filters. |
| `replacement has length zero` | Calculations | Usually means a calculation resulted in `NULL` or empty vector. Check for `NA`s in input data. |
| `there is no package called 'ptcalc'` | Startup | Run `devtools::install("ptcalc")` from the project root. |

## 2. Data Format Issues
*   **Decimals:** Use dots (`.`) for decimals, not commas (`,`).
*   **Encoding:** Save CSVs as **UTF-8** to avoid issues with special characters in IDs.
*   **Missing Values:** Empty cells may cause crashes in Algorithm A. Use `NA` explicitly if needed, though rows with missing values should generally be removed.

## 3. Performance Tips
*   **Large Datasets:** If loading >100MB files, the app may lag.
    *   **Fix:** Pre-aggregate data or increase R memory limit (`R_MAX_VSIZE`).
*   **Slow Plots:** `ggplot2` + `plotly` can be slow with >10,000 points.
    *   **Fix:** The app currently renders all points. Consider downsampling for extremely large datasets (not common in PT).

## 4. Browser Compatibility
*   **Recommended:** Chrome, Firefox, Edge (Chromium).
*   **Known Issues:** Old Safari versions may not render flexbox layouts correctly.
*   **Pop-ups:** Ensure pop-up blockers allow downloads for the Report Generation feature.
