# Shiny Module: PT Scores

## 1. Overview
This module orchestrates the calculation of all performance scores ($z, z', \zeta, E_n$) and visualizes them. It is the core analytical engine for participant evaluation.

**File Location:** `cloned_app.R` ("Puntajes PT" tab)

---

## 2. Calculation Pipeline

### 2.1 The `compute_scores_metrics` Function
This is a massive wrapper function that:
1.  **Aggregates Inputs:** Collects $x_{pt}$, $\sigma_{pt}$, $u(x_{pt})$ from previous modules.
2.  **Iterates:** Loops through every participant in the selected dataset.
3.  **Calculates:** Calls `ptcalc::calculate_*_score` for each metric.
4.  **Classifies:** Applies the `a1-a7` classification logic.
5.  **Returns:** A standardized dataframe ready for plotting.

### 2.2 Tab Switching Behavior
The UI uses a `tabsetPanel` to show different scores.
*   **Tabs:** z-score, z'-score, zeta-score, En-score.
*   **Optimization:** All scores are calculated at once when "Calcular Puntajes" is clicked. Switching tabs simply reveals different columns of the *already calculated* dataframe, ensuring instant UI response.

---

## 3. Visualization Logic

### 3.1 Plot Generation (`plot_scores`)
Uses `ggplot2` to create standardized performance charts.

*   **X-axis:** Participant ID (ordered).
*   **Y-axis:** Score value.
*   **Zones:**
    *   Green Zone: $\pm 2$
    *   Yellow Zone: $\pm 3$
    *   Red Zone: $> \pm 3$
*   **Features:**
    *   Horizontal lines at limits (+2, -2, +3, -3).
    *   Points colored by status.
    *   Interactive tooltips (via `plotly` conversion).

### 3.2 Caching Strategy
To prevent heavy recalculation every time a user views a plot:
*   `scores_results_cache()` stores the full calculated dataframe.
*   The plots depend on this cache, not the raw calculation function.
*   The cache is invalidated only when new data is uploaded or parameters change significantly.

---

## 4. Code Snippet: Score Classification
```r
# Simplified logic from server
mutate(
  z_class = case_when(
    abs(z) <= 2 ~ "Satisfactory",
    abs(z) > 2 & abs(z) < 3 ~ "Questionable",
    abs(z) >= 3 ~ "Unsatisfactory"
  ),
  # Color mapping for UI
  color = case_when(
    z_class == "Satisfactory" ~ "#4DB848", # Green
    z_class == "Questionable" ~ "#FDB913", # Yellow
    z_class == "Unsatisfactory" ~ "#E03C31" # Red
  )
)
```
