# Shiny Module: Homogeneity & Stability

## 1. Overview
This module implements the user interface and reactive logic for assessing the homogeneity and stability of proficiency test items. It serves as the bridge between the user's input and the statistical functions in `ptcalc`.

**File Location:** `cloned_app.R` (Logic: ~lines 239-486)

---

## 2. UI Component Map

| UI Element | Type | Input ID | Output ID | Related Reactive |
|:---|:---|:---|:---|:---|
| **Run Button** | `actionButton` | `run_analysis` | - | `analysis_trigger()` |
| **Pollutant** | `selectInput` | `pollutant_analysis` | `pollutant_selector_analysis` | `homogeneity_run()` |
| **Level** | `selectInput` | `target_level` | `level_selector` | `homogeneity_run()` |
| **Conclusion Box** | `uiOutput` | - | `homog_conclusion` | `homogeneity_run()` |
| **Results Table** | `tableOutput` | - | `variance_components` | `homogeneity_run()` |
| **Stability Run** | `actionButton` | `run_stability` | - | `stability_trigger()` |

---

## 3. Reactive Logic

### 3.1 `homogeneity_run()`
**Trigger:** `input$run_analysis`

1.  **Input Gathering:** Reads selected pollutant and level.
2.  **Data Fetching:** Calls `get_wide_data(hom_data_full(), ...)` to prepare data.
3.  **Calculation:** Calls `ptcalc::calculate_homogeneity_stats()` to get $s_s$, $s_w$, etc.
4.  **Evaluation:** Calls `ptcalc::evaluate_homogeneity()` to compare $s_s$ against criteria ($c, c'$).
5.  **Return:** A comprehensive list containing statistics, ANOVA table, and pass/fail conclusions.

### 3.2 Error State Handling
If data is missing or invalid (e.g., < 2 items), the reactive returns a list with an `$error` string. The UI renders this error message in a red alert box instead of crashing.

```r
if (g < 2) {
  return(list(error = "No hay suficientes ítems (se requieren al menos 2)..."))
}
```

---

## 4. Visualizations & Outputs

### 4.1 Results Table (`variance_components`)
Displays the core ANOVA results:
*   General Mean ($\bar{x}_{pt}$)
*   Between-samples SD ($s_s$)
*   Within-samples SD ($s_w$)
*   Allowable SD ($\sigma_{pt}$)

### 4.2 Conclusion Box (`homog_conclusion`)
Dynamic HTML output that changes color based on result:
*   **Green:** PASS ($s_s \le c$)
*   **Yellow:** PASS (Conditional, $s_s \le c'$)
*   **Red:** FAIL ($s_s > c'$)

---

## 5. Stability Integration

The stability analysis is an optional step that runs after homogeneity.

*   **Reactive:** `stability_run()`
*   **Dependency:** Requires `homogeneity_run()` to be successful first.
*   **Logic:** Compares the mean of the stability check samples against the homogeneity mean.
*   **Output:** Adds stability uncertainty ($u_{stab}$) to the final uncertainty budget.
