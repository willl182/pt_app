# Shiny Module: Global Report

## 1. Overview
The Global Report module provides a high-level view of the entire proficiency testing scheme, aggregating results across all pollutants and levels into heatmaps and summary tables.

**File Location:** `cloned_app.R` ("Informe global" tab)

---

## 2. Architecture

### 2.1 Data Aggregation Pipeline
1.  **Trigger:** `global_report_data()` reactive.
2.  **Collection:** Iterates through all available pollutants (`CO, NO, NO2...`) and levels.
3.  **Retrieval:** Fetches cached scores from `scores_results_cache`. If a specific combo hasn't been run, it skips it or shows "N/A".
4.  **Filtering:** Removes the reference laboratory (`participant_id == "ref"`) to focus on participant performance.
5.  **Pivot:** Transforms data into a matrix format suitable for heatmaps (Rows: Participants, Cols: Pollutant/Level).

### 2.2 Heatmap Logic
Uses `plotly::plot_ly` (heatmap trace).

*   **X-Axis:** Pollutant + Level (e.g., "SO2-low").
*   **Y-Axis:** Participant ID.
*   **Z-Value:** The score itself (z, z', etc.) or a mapped integer for discrete classification.
*   **Colors:** Custom colorscale matching the official traffic light palette (Green/Yellow/Red).

---

## 3. Key Reactives

### `global_report_summary()`
Generates the text-based summary table.
*   **Columns:** Pollutant, Level, N (Participants), Mean, SD, Pass Rate (%).
*   **Pass Rate Calculation:**
    $$Rate = \frac{\text{Count}(|z| \le 2)}{\text{Total Participants}} \times 100$$

### `global_report_combos()`
Identifies valid combinations of data to populate the dropdown selectors, ensuring users don't try to view empty heatmaps.
