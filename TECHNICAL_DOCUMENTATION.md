# Technical Documentation: `app.R` and `report_template.Rmd`

This document provides a comprehensive technical guide to the implementation, installation, and statistical calculations used in the **PT Data Analysis Application**.

## Table of Contents
1. [Overview](#overview)
2. [Installation and Requirements](#installation-and-requirements)
3. [Documentation: `app.R`](#documentation-appr)
    - [Architecture](#architecture)
    - [Detailed Statistical Calculations](#detailed-statistical-calculations)
        - [1. Homogeneity Assessment (ANOVA)](#1-homogeneity-assessment-anova)
        - [2. Stability Assessment](#2-stability-assessment)
        - [3. Algorithm A (Robust Statistics)](#3-algorithm-a-robust-statistics)
        - [4. Consensus Values (MADe and nIQR)](#4-consensus-values-made-and-niqr)
        - [5. Performance Scores](#5-performance-scores)
4. [Documentation: `reports/report_template.Rmd`](#documentation-reportsreport_templatermd)
    - [Parameters](#parameters)
    - [Internal Logic and Replication](#internal-logic-and-replication)

---

## Overview

The application is a tool for Proficiency Testing (PT) schemes, specifically designed for air quality matrix analysis. It automates the statistical procedures defined in **ISO 13528:2022**, including:
- **Homogeneity Testing**: Verifying that sample items are sufficiently identical.
- **Stability Testing**: Verifying that sample items remain stable over the course of the proficiency test.
- **Performance Evaluation**: Calculating z-scores, z'-scores, zeta-scores, and $E_n$ numbers for participants using various reference or consensus values.

The core logic is contained in `app.R` (Shiny application) and `reports/report_template.Rmd` (Dynamic report generation).

---

## Installation and Requirements

### System Requirements
- **R**: Version 4.0.0 or higher recommended.
- **R Tools**: Rtools (on Windows) or essential build tools (on Linux/macOS) may be required for compiling some packages.

### Required R Packages
The following libraries must be installed. You can install them using the R console:

```r
install.packages(c(
  "shiny",        # Web application framework
  "tidyverse",    # Data manipulation (dplyr, tidyr, ggplot2)
  "vroom",        # Fast data reading
  "DT",           # Interactive data tables
  "rhandsontable",# Excel-like editable tables
  "shinythemes",  # CSS themes for Shiny
  "outliers",     # Statistical tests for outliers (Grubbs)
  "patchwork",    # Composition of ggplots
  "bsplus",       # Bootstrap extras (collapsible panels)
  "plotly",       # Interactive plotting
  "rmarkdown",    # Report generation
  "knitr",        # Dynamic report generation
  "kableExtra"    # Enhanced tables for reports
))
```

### Running the Application

1.  **Standard Execution**:
    Navigate to the project directory in your terminal and run:
    ```bash
    Rscript run_app.R
    ```
    Or from within an R console:
    ```r
    shiny::runApp()
    ```

2.  **Syntax Verification (No Server)**:
    If a full R server environment is not available, you can verify the syntax of the application using the provided stub script:
    ```bash
    ./Rscript -e "source('app.R')"
    ```

---

## Documentation: `app.R`

### Architecture

The application follows the standard Shiny **UI/Server** architecture but is structured to handle complex modular workflows.

#### 1. User Interface (`ui`)
The UI is built using `fluidPage` with a `navlistPanel` layout, dividing the app into three main operational modules:
-   **Carga de datos**: Handles file uploads (`homogeneity.csv`, `stability.csv`, `summary_n*.csv`).
-   **Análisis de homogeneidad y estabilidad**: Workflows for checking sample quality.
-   **Valor asignado / Puntajes**: Workflows for determining reference values ($x_{pt}$) and evaluating participant performance.
-   **Generación de informes**: Configuration interface for the RMarkdown report.

#### 2. Server Logic (`server`)
The server function manages the application state using **Reactive Expressions**. Key architectural components include:

-   **Data Ingestion**: `hom_data_full()`, `stab_data_full()`, and `pt_prep_data()` read and validate CSV inputs.
-   **State Management**: `reactiveValues` (e.g., `rv`) and `reactiveVal` (e.g., `analysis_trigger`) are used to manage caching and execution flow, preventing unnecessary re-calculations.
-   **Modular Calculation Functions**: Core statistical logic is encapsulated in helper functions defined within the server scope (or `R/utils.R` if refactored) to ensure consistency.

---

### Detailed Statistical Calculations

This section documents the exact formulas implemented in the code.

#### 1. Homogeneity Assessment (ANOVA)
**Implementation**: Function `compute_homogeneity_metrics`

The app performs an analysis of variance (ANOVA) -like calculation to separate within-item and between-item variance.

*   **Inputs**: $g$ items (groups), $m$ replicates per item.
*   **Item Statistics**:
    For each item $i$:
    *   $\bar{x}_i = \text{mean of replicates for item } i$
    *   $w_i = \max(x_{i, \cdot}) - \min(x_{i, \cdot})$ (Range of replicates)

*   **General Mean**:
    $$ \bar{x}_{pt} = \frac{1}{g} \sum_{i=1}^{g} \bar{x}_i $$

*   **Variance of Means ($s_{\bar{x}}^2$)**:
    $$ s_{\bar{x}}^2 = \frac{1}{g-1} \sum_{i=1}^{g} (\bar{x}_i - \bar{x}_{pt})^2 $$

*   **Within-sample Standard Deviation ($s_w$)**:
    Calculated based on ranges (specifically designed for $m=2$, but generalized in code):
    $$ s_w = \sqrt{ \frac{\sum w_i^2}{2g} } $$

*   **Between-sample Standard Deviation ($s_s$)**:
    $$ s_s = \sqrt{ \left| s_{\bar{x}}^2 - \frac{s_w^2}{2} \right| } $$
    *Note: The code uses the absolute value (`abs`) before the square root to handle cases where within-variance exceeds total variance, effectively preventing NaNs but diverging slightly from standard ANOVA where this would be set to 0.*

*   **Criteria Check**:
    *   Target deviation: $\sigma_{pt} = 1.483 \times \text{MADe}$ (Median Absolute Deviation of the first sample replicates).
    *   Criterion: $0.3 \times \sigma_{pt}$
    *   Pass Condition: $s_s \le 0.3 \sigma_{pt}$

#### 2. Stability Assessment
**Implementation**: Function `compute_stability_metrics`

Stability is assessed by comparing the general mean of the homogeneity check ($y_1$) with the general mean of the stability check ($y_2$).

*   **Difference**:
    $$ \Delta = |y_1 - y_2| $$

*   **Criterion**:
    $$ \text{Limit} = 0.3 \times \sigma_{pt} $$
    *(Using the $\sigma_{pt}$ derived from the homogeneity study)*.

*   **Pass Condition**:
    $$ \Delta \le 0.3 \sigma_{pt} $$

*   **T-Test**:
    A standard Student's t-test is also performed between the raw result vectors of the homogeneity study and the stability study to check for statistical significance ($p < 0.05$).

#### 3. Algorithm A (Robust Statistics)
**Implementation**: Function `run_algorithm_a`

This algorithm iteratively calculates a robust mean ($x^*$) and robust standard deviation ($s^*$) according to ISO 13528.

*   **Initialization**:
    *   $x^* = \text{median}(x_i)$
    *   $s^* = 1.483 \times \text{median}(|x_i - x^*|)$

*   **Iteration**:
    1.  Calculate standardized residuals: $\delta_i = \frac{x_i - x^*}{1.5 s^*}$
    2.  Calculate weights $w_i$:
        $$ w_i = \begin{cases} 1 & \text{if } |\delta_i| \le 1 \\ \frac{1}{\delta_i^2} & \text{if } |\delta_i| > 1 \end{cases} $$
    3.  Update Mean:
        $$ x^*_{new} = \frac{\sum w_i x_i}{\sum w_i} $$
    4.  Update SD:
        $$ s^*_{new} = 1.134 \times \sqrt{ \frac{\sum w_i (x_i - x^*_{new})^2}{\sum w_i} } $$
        *(Note: The actual implementation in `app.R` uses `s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)`. The factor 1.134 typically seen in ISO 13528 for converting to expectation of Gaussian SD is implicit or handled differently in this specific codebase version; check specific version. In the provided `app.R` code, the factor 1.134 is **NOT** present in the update step line 616, making it a weighted RMS calculation).*

*   **Convergence**: Stops when relative change in $x^*$ and $s^*$ is $< 0.001$.

#### 4. Consensus Values (MADe and nIQR)
These are robust estimators used as alternatives for the assigned value.

*   **MADe (Median Absolute Deviation)**:
    $$ \text{MADe} = 1.483 \times \text{median}(|x_i - \text{median}(x)|) $$
    Used as $\sigma_{pt}$ in Method 2a.

*   **nIQR (Normalized Interquartile Range)**:
    $$ \text{nIQR} = 0.7413 \times (Q_3 - Q_1) $$
    Used as $\sigma_{pt}$ in Method 2b.

#### 5. Performance Scores
**Implementation**: Function `compute_scores_metrics` / `compute_combo_scores`

Calculated for each participant result $x_i$:

*   **z-score**:
    $$ z = \frac{x_i - x_{pt}}{\sigma_{pt}} $$

*   **z'-score (z-prime)**:
    Accounts for uncertainty in the assigned value $u(x_{pt})$.
    $$ z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}} $$

*   **zeta-score ($\zeta$)**:
    Accounts for participant's own uncertainty $u(x_i)$.
    $$ \zeta = \frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}} $$

*   **$E_n$ score**:
    Uses expanded uncertainties $U = k \cdot u$.
    $$ E_n = \frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}} $$

---

## Documentation: `reports/report_template.Rmd`

The RMarkdown file generates the final PDF/Word report. It is designed to be **autonomous**, meaning it often re-implements calculation logic rather than relying solely on the Shiny app's memory state, ensuring reproducibility.

### Parameters
The report accepts a `params` list passed from the Shiny app:
-   **Data**: `hom_data`, `stab_data`, `summary_data`, `participants_data`.
-   **Configuration**: `metric` (z, z', etc.), `method` (1, 2a, 2b, 3), `k_factor`.
-   **Context**: `pollutant`, `level`, `n_lab` (scheme ID).
-   **Pre-calculated Objects**: `xpt_summary`, `homogeneity_summary`, `heatmaps`, etc. (The report uses a mix of raw data processing and pre-calculated summary tables passed from the app).

### Internal Logic and Replication
To ensure the report renders correctly even if isolated, `report_template.Rmd` contains its own definition of key statistical functions in the `setup` chunk:
1.  **`run_algorithm_a`**: Re-defined locally to match the app's logic.
2.  **`compute_homogeneity`**: Re-defined locally.
3.  **`calculate_niqr`**: Re-defined locally.

### Report Sections
1.  **Identification**: Displays scheme info, coordinators, and participant list.
2.  **Methodology**: Describes the generation of items (O3, SO2, etc.) and statistical methods used.
3.  **Homogeneity & Stability**: Presents tables generated via the `homogeneity_summary` and `stability_summary` parameters.
4.  **Results**:
    -   Displays performance summaries.
    -   Renders **Heatmaps** (passed as ggplot objects in `params$heatmaps`).
    -   Displays individual participant charts (Matrix Plots).
5.  **Annexes**: Detailed tables for assigned values and individual participant performance.

### Customization
To modify the report format (e.g., logo, header):
-   Edit the YAML header in `reports/report_template.Rmd`.
-   Modify the text sections directly in the Markdown body.
-   Adjust `knitr` chunk options for plot sizing (`fig.width`, `fig.height`).
