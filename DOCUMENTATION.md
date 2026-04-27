# Documentation for PT Data Analysis Application

This document provides a comprehensive guide to the **PT Data Analysis Application**, an R Shiny application designed for Proficiency Testing (PT) data analysis, specifically for air quality monitoring schemes (ISO 13528:2022). It covers the installation, code structure (`app.R`, `reports/report_template.Rmd`), and detailed statistical calculations.

## 1. Overview

The application allows users to:
1.  **Load Data**: Upload CSV files for homogeneity, stability, and participant summaries.
2.  **Analyze Homogeneity & Stability**: Perform statistical checks (ANOVA, ISO 13528 checks) to ensure items are suitable for PT.
3.  **Determine Assigned Values**: Calculate assigned values ($x_{pt}$) using various methods (Reference, Consensus MADe, Consensus nIQR, Algorithm A).
4.  **Calculate Performance Scores**: Compute $z$, $z'$, $\zeta$, and $E_n$ scores for participants.
5.  **Generate Reports**: Create detailed MS Word or HTML reports summarising the entire PT round.

## 2. Installation and Setup

### Prerequisites

*   **R**: Version 4.0.0 or higher.
*   **RStudio** (recommended).

### Required Libraries

The application requires the following R packages. You can install them using `install.packages()`:

```r
install.packages(c(
  "shiny",
  "tidyverse",
  "vroom",
  "DT",
  "rhandsontable",
  "shinythemes",
  "outliers",
  "patchwork",
  "bsplus",
  "plotly",
  "rmarkdown",
  "knitr",
  "kableExtra"
))
```

### Running the App

1.  Open `app.R` in RStudio.
2.  Click the **Run App** button or execute `shiny::runApp()` in the console.
3.  Ensure the `reports/` directory exists and contains `report_template.Rmd`.

## 3. Code Documentation: `app.R`

The main application file is `app.R`, structured into **UI (User Interface)** and **Server** components.

### 3.1. User Interface (UI)

The UI uses `fluidPage` with a `navlistPanel` layout to organize functionality into specific modules:

*   **Carga de datos**: File inputs for:
    *   `hom_file`: Homogeneity data (`homogeneity.csv`).
    *   `stab_file`: Stability data (`stability.csv`).
    *   `summary_files`: Participant results (`summary_n*.csv`).
*   **Análisis de homogeneidad y estabilidad**: Tools to evaluate if the items are homogeneous and stable.
    *   Selectors for `pollutant` and `level`.
    *   Displays for data previews, histograms, boxplots, and ANOVA results.
*   **Valor asignado**: Comparison of different assigned value methods.
    *   **Algoritmo A**: Iterative robust mean and SD.
    *   **Valor consenso**: Robust stats (MADe, nIQR).
    *   **Valor de referencia**: Reference lab values.
    *   **Compatibilidad Metrológica**: Checks differences between reference and consensus values.
*   **Outlier**: Grubbs test summary.
*   **Puntajes PT**: Calculation of performance scores ($z$, $z'$, $\zeta$, $E_n$) for individual participants.
*   **Informe global**: Aggregated views of all scores and heatmaps across the scheme.
*   **Generación de informes**: Configuration and download of the final report (Word/HTML).

### 3.2. Server Logic

The server function manages the reactive data flow:

1.  **Data Loading (`hom_data_full`, `stab_data_full`, `pt_prep_data`)**:
    *   Reads CSVs using `vroom`.
    *   Validates column names (e.g., `value`, `pollutant`, `level`).
    *   Aggregates participant data (mean, sd) from `summary_files`.

2.  **Homogeneity & Stability (`compute_homogeneity_metrics`, `compute_stability_metrics`)**:
    *   **Homogeneity**: Pivots data to wide format, calculates item means/ranges, performs ANOVA, and compares variances against criteria.
    *   **Stability**: Compares the general mean of stability samples against homogeneity samples and performs a t-test.

3.  **Assigned Value Calculations**:
    *   **Reference**: Direct extraction from `ref` participant data.
    *   **Algorithm A (`run_algorithm_a`)**: Implements ISO 13528 Algorithm A for robust mean/SD.
    *   **Consensus (`calculate_niqr`)**: Helper for normalized Interquartile Range.

4.  **Score Calculation (`compute_scores_metrics`, `compute_scores_for_selection`)**:
    *   Computes scores for all combinations of method and level.
    *   Caches results for performance.

5.  **Reporting (`output$download_report`)**:
    *   Compiles all current reactive states (summaries, heatmaps, plots).
    *   Passes these as `params` to `rmarkdown::render`.

## 4. Code Documentation: `reports/report_template.Rmd`

This R Markdown file defines the structure of the downloadable report.

*   **YAML Header**: Defines document metadata and `params` (placeholders for data passed from Shiny).
*   **Setup Chunk**: Loads libraries and defines helper functions (`run_algorithm_a`, `compute_homogeneity`) to ensure the report can re-calculate or verify values if raw data is passed.
*   **Sections**:
    *   **1. Información del Proveedor**: Project context and participant list.
    *   **2. Descripción del Ensayo**: Details on item production, levels, and assigned value determination.
    *   **3. Criterios de Evaluación**: Definitions of the scores used ($z$, $E_n$, etc.).
    *   **4. Resultados y Discusión**: Summary tables and heatmaps.
    *   **Annexes**: Detailed tables for assigned values, homogeneity/stability, and individual participant reports.

## 5. Statistical Calculations in Detail

The app implements statistical methods primarily from **ISO 13528:2022**.

### 5.1. Homogeneity Assessment

**Goal**: Determine if the variation between proficiency test items ($s_s$) is negligible compared to the standard deviation for proficiency assessment ($\sigma_{pt}$).

1.  **Data Structure**: $g$ items, $m$ replicates per item.
2.  **ANOVA Terms**:
    *   **Item means** $\bar{x}_{t}$ and **ranges** $w_t$.
    *   **General Mean**: $\bar{x}_{pt} = \frac{1}{g} \sum \bar{x}_{t}$.
    *   **Variance of means ($s_{\bar{x}}^2$)**: Variance of the $g$ item means.
    *   **Within-sample standard deviation ($s_w$)**:
        $$s_w = \sqrt{\frac{\sum w_t^2}{2g}} \quad \text{(for m=2)}$$
3.  **Between-sample standard deviation ($s_s$)**:
    $$s_s = \sqrt{\max\left(0, s_{\bar{x}}^2 - \frac{s_w^2}{m}\right)}$$
4.  **Check**:
    *   Calculate critical value $c = 0.3 \times \sigma_{pt}$.
    *   **Pass if** $s_s \le c$.
    *   An expanded criterion $c'$ is also calculated using $\sqrt{c^2 + \text{sampling uncertainty terms}}$.

### 5.2. Stability Assessment

**Goal**: Ensure the property value has not changed significantly during the proficiency testing period.

1.  **Procedure**: Measure items before ($y_1$, homogeneity) and after ($y_2$, stability) distribution.
2.  **Check**:
    $$| \bar{y}_1 - \bar{y}_2 | \le 0.3 \times \sigma_{pt}$$
3.  **t-test**: A standard unpaired t-test is also performed as a secondary check for statistical significance ($p > 0.05$).

### 5.3. Assigned Value ($x_{pt}$) Determination

The app supports multiple methods:

*   **Method 1: Reference Value**: $x_{pt}$ is taken directly from a reference laboratory's measurement.
*   **Method 2a: Consensus (Median + MADe)**:
    *   $x_{pt} = \text{median}(x_i)$
    *   $\sigma_{pt} = 1.483 \times \text{median}(|x_i - \text{median}(x_i)|)$
*   **Method 2b: Consensus (Median + nIQR)**:
    *   $x_{pt} = \text{median}(x_i)$
    *   $\sigma_{pt} = 0.7413 \times (Q_3 - Q_1)$
*   **Method 3: Algorithm A (Robust Mean)**:
    *   Iteratively updates mean ($x^*$) and SD ($s^*$) by down-weighting outliers (values outside $1.5 \times s^*$).
    *   $x_{pt} = x^*$, $\sigma_{pt} = s^*$.

### 5.4. Performance Scores

Scores evaluate participant performance relative to the assigned value.

1.  **z-score**: Basic performance score.
    $$z = \frac{x_i - x_{pt}}{\sigma_{pt}}$$
    *   $|z| \le 2.0$: Satisfactory.
    *   $2.0 < |z| < 3.0$: Questionable.
    *   $|z| \ge 3.0$: Unsatisfactory.

2.  **z'-score (z-prime)**: Accounts for uncertainty in the assigned value $u(x_{pt})$.
    $$z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}}$$
    *   Used when $u(x_{pt})$ is not negligible (i.e., $u(x_{pt}) > 0.3 \sigma_{pt}$).

3.  **zeta-score ($\zeta$)**: Checks agreement within reported uncertainties.
    $$\zeta = \frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}}$$
    *   Requires participants to report standard uncertainty $u(x_i)$.

4.  **$E_n$ score**: Similar to zeta but using expanded uncertainties ($U = k \times u$).
    $$E_n = \frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}}$$
    *   $|E_n| \le 1.0$: Satisfactory.
    *   $|E_n| > 1.0$: Unsatisfactory.

### 5.5. Uncertainty of Assigned Value

For consensus methods, the standard uncertainty $u(x_{pt})$ is estimated as:
$$u(x_{pt}) = 1.25 \times \frac{\sigma_{pt}}{\sqrt{p}}$$
Where $p$ is the number of participants.
