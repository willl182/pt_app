# Validation Guide for PT App (`app.R`)

This document provides a detailed guide for validating the calculations, logic, and functionality of the Shiny application (`app.R`) used for Proficiency Testing (PT) data analysis. It covers data ingestion, statistical calculations (homogeneity, stability, performance scores), and output generation.

## 1. Overview
The application implements statistical procedures primarily based on **ISO 13528:2022** for the analysis of PT schemes. It processes participant data to evaluate:
1.  **Homogeneity**: Variation between sample items.
2.  **Stability**: Consistency of the sample items over time.
3.  **Performance**: Participant scores ($z$, $z'$, $\zeta$, $E_n$) using various consensus and reference values.

## 2. Data Input Validation

The app requires three types of CSV input files. Validation checks should ensure these files meet the expected schema.

### 2.1. Homogeneity Data (`homogeneity.csv`)
*   **Structure**: Wide format.
*   **Required Columns**: `pollutant`, `level`, `sample_1`, `sample_2` (or more replicates).
*   **Validation Logic**:
    *   Must have at least 2 items ($g \ge 2$) and 2 replicates ($m \ge 2$).
    *   `sample_1` is mandatory for $\sigma_{pt}$ calculation (based on the first replicate).

### 2.2. Stability Data (`stability.csv`)
*   **Structure**: Wide format, similar to homogeneity.
*   **Required Columns**: `pollutant`, `level`, `sample_1`, `sample_2` (or more replicates).
*   **Validation Logic**:
    *   Must match the `pollutant` and `level` defined in homogeneity data.
    *   Used to compare the general mean against the homogeneity general mean.

### 2.3. Participant Summary Data (`summary_n*.csv`)
*   **Structure**: Long format (one row per measurement or aggregated).
*   **Required Columns**: `participant_id`, `pollutant`, `level`, `mean_value`, `sd_value`.
*   **Validation Logic**:
    *   `participant_id = "ref"` is reserved for the reference value.
    *   Data is aggregated (mean of means) per participant/level before analysis.

---

## 3. Statistical Calculations & Logic

This section details the formulas and logic implemented in the code (helper functions and server logic).

### 3.1. Robust Statistics Helpers

#### `calculate_niqr(x)`
*   **Purpose**: Calculates the Normalized Interquartile Range (nIQR).
*   **Code Implementation**:
    ```r
    quartiles <- quantile(x, probs = c(0.25, 0.75), type = 7)
    niqr <- 0.7413 * (quartiles[2] - quartiles[1])
    ```
*   **Validation**: Compare against manual calculation: $nIQR = 0.7413 \times (Q_3 - Q_1)$.

#### `run_algorithm_a(values, ids, max_iter)`
*   **Purpose**: Iterative algorithm to calculate robust mean ($x^*$) and robust standard deviation ($s^*$) as per ISO 13528, Algorithm A.
*   **Logic**:
    1.  **Initialization**:
        *   $x^* = \text{median}(x)$
        *   $s^* = 1.483 \times \text{median}(|x - x^*|)$ (MADe)
    2.  **Iteration**:
        *   Calculate $\delta = 1.5 \times s^*$
        *   Clip values: $x_i^* = \begin{cases} x^* - \delta & \text{if } x_i < x^* - \delta \\ x^* + \delta & \text{if } x_i > x^* + \delta \\ x_i & \text{otherwise} \end{cases}$
        *   Update $x^* = \text{mean}(x_i^*)$
        *   Update $s^* = 1.134 \times \text{sd}(x_i^*)$
    3.  **Convergence**: Stops when changes in $x^*$ and $s^*$ are negligible or `max_iter` is reached.
*   **Code Check**: Ensure the weight calculation `weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))` aligns with the clipping logic equivalent.

### 3.2. Homogeneity Assessment (`compute_homogeneity_metrics`)

*   **Inputs**: Replicate data for $g$ items and $m$ replicates.
*   **ANOVA Terms**:
    *   **Item Means**: $\bar{x}_{t} = \text{mean of replicates for item } t$
    *   **General Mean**: $\bar{\bar{x}} = \text{mean of } \bar{x}_{t}$
    *   **Variance of Item Means ($s_{\bar{x}}^2$)**: `var(item_means)`
    *   **Within-item Variance ($s_w^2$)**:
        *   Calculated using ranges for $m=2$: $s_w = \sqrt{\sum w_t^2 / (2g)}$ where $w_t = |x_{t,1} - x_{t,2}|$.
    *   **Between-sample Standard Deviation ($s_{ss}$)**:
        *   $s_{ss}^2 = s_{\bar{x}}^2 - (s_w^2 / m)$
        *   If $s_{\bar{x}}^2 < s_w^2 / m$, then $s_{ss} = 0$.
*   **Criteria**:
    *   $\sigma_{pt}$ (Standard Deviation for Proficiency Assessment):
        *   Calculated as `mad_e` of the *first sample* results across all items.
        *   $\sigma_{pt} = 1.483 \times \text{median}(|x_{i,1} - \text{median}(x_{.,1})|)$.
    *   **Check**: $s_{ss} \le 0.3 \times \sigma_{pt}$.
    *   **Expanded Check**: If the first check fails, use critical value $c$ considering sampling uncertainty (ISO 13528).

### 3.3. Stability Assessment (`compute_stability_metrics`)

*   **Logic**: Compares the general mean of stability samples ($\bar{y}$) with the general mean of homogeneity samples ($\bar{x}$).
*   **Criterion**:
    *   $|\bar{y} - \bar{x}| \le 0.3 \times \sigma_{pt}$
    *   Includes an expanded check similar to homogeneity if the basic check fails.

### 3.4. Performance Scores (`compute_scores_metrics`)

The app calculates four types of scores for each participant $i$:

1.  **z-score**:
    $$z = \frac{x_i - x_{pt}}{\sigma_{pt}}$$
    *   **Evaluation**: $|z| \le 2$ (Satisfactory), $2 < |z| < 3$ (Questionable), $|z| \ge 3$ (Unsatisfactory).

2.  **z'-score (z-prime)**:
    $$z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}}$$
    *   Used when uncertainty of the assigned value $u(x_{pt})$ is significant.

3.  **zeta-score ($\zeta$)**:
    $$\zeta = \frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}}$$
    *   Uses participant's own uncertainty $u(x_i)$ (derived from `sd_value`).

4.  **En-score (Normalized Error)**:
    $$E_n = \frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}}$$
    *   Uses Expanded Uncertainty $U = k \times u$ (default $k=2$).
    *   **Evaluation**: $|E_n| \le 1$ (Satisfactory), $|E_n| > 1$ (Unsatisfactory).

### 3.5. Assigned Values ($x_{pt}$) Options

The app allows selecting different sources for the assigned value:
1.  **Reference**: Value from `participant_id = "ref"`.
2.  **Consensus (Algorithm A)**: Robust mean of all participants.
3.  **Consensus (Median)**: Simple median of all participants.

---

## 4. Validation Steps

To validate the app, perform the following tests:

### 4.1. Unit Tests for Calculations
1.  **Algorithm A**:
    *   Create a small dataset with a known outlier.
    *   Run `run_algorithm_a` manually in R console.
    *   Verify that the outlier has a low weight and the mean is robust.
2.  **Homogeneity**:
    *   Use the example data from ISO 13528 Annex B.
    *   Load it into the app.
    *   Check if $s_{ss}$ and $\sigma_{pt}$ match the standard's examples.

### 4.2. Interface Logic
1.  **Dynamic UI**:
    *   Verify that "Calcular puntajes" button is disabled until data is loaded.
    *   Verify that selecting a different pollutant updates the plots immediately.
2.  **Error Handling**:
    *   Upload a file with missing columns.
    *   Check if the app displays a user-friendly error message (e.g., "Column 'level' not found").

### 4.3. Report Generation
1.  **Consistency**:
    *   Generate the Word report.
    *   Compare the tables in the report with the tables shown in the Shiny app tabs. They must be identical.
2.  **Assets**:
    *   Check `reports/assets/` to ensure images and CSVs are generated correctly.

## 5. Code Structure Reference

*   **`app.R`**: Main application file.
    *   `ui`: Defines layout and inputs.
    *   `server`: Handles reactive logic.
    *   `compute_homogeneity_metrics`: Core homogeneity logic.
    *   `compute_stability_metrics`: Core stability logic.
    *   `run_algorithm_a`: Robust statistics implementation.
*   **`tools/generate_report_assets.R`**:
    *   Mirror of `app.R` logic for batch generation of report artifacts.
    *   **Important**: Any change in `app.R` calculation logic must be replicated here.

## 6. Known Constraints
*   **Minimum Data**: Homogeneity requires at least 2 items and 2 replicates.
*   **Algorithm A**: Requires at least 3 valid participant results.
*   **Reference Value**: A participant with ID `ref` is required for Reference-based scoring.
