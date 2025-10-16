# Standard Operating Procedure (SOP) for the PT Data Analysis Application

## 1. Introduction

This **Standard Operating Procedure (SOP)** defines the complete workflow for the **PT Data Analysis Application**, an R/Shiny-based tool for the **statistical analysis of proficiency testing (PT)** data in compliance with **ISO/IEC 17043:2023** and **ISO 13528:2022**.

The purpose of this SOP is to standardize procedures for:
- **Homogeneity and stability validation** of PT items.
- **Robust statistical evaluation** of participant results.
- **Calculation of performance scores** (z, z′, ζ, En) following ISO 13528.
- **Automated reporting** through the Shiny web interface.

The application ensures **traceability, reproducibility, and statistical validity**, developed collaboratively by *Laboratorio CALAIRE, Universidad Nacional de Colombia* and the *Instituto Nacional de Metrología (INM)*.

---

## 2. System Requirements and Environment Setup

### 2.1 Software Requirements
- **R version:** 4.2 or higher
- **Framework:** Shiny (for the web interface)
- **Development Environment:** RStudio (recommended)

### 2.2 Package Installation
Install required libraries before running the app:

```r
install.packages(c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers"
))
```

### 2.3 Directory Structure
Organize files as follows:
```
/data           # CSV input files: homogeneity.csv, stability.csv, summary_n*.csv
/app            # Shiny app scripts (app.R or run_app.R)
/reports        # Output visualizations and reports
```

### 2.4 Launching the Application
Run the following command in R or a terminal:
```bash
Rscript run_app.R
```
The app will open automatically in your web browser.

---

## 3. Application Modules Overview

The PT Data Analysis Application includes **three primary modules**:

1. **Homogeneity & Stability Analysis** — Verifies whether PT items meet statistical fitness for use.
2. **PT Preparation** — Visualizes and summarizes participant results across pollutants and PT levels.
3. **PT Scores** — Calculates performance metrics and generates interactive visual summaries.

Each module implements the methods from ISO 13528:2022 and integrates reactivity for real-time updates.

---

## 4. Homogeneity and Stability Analysis (ISO 13528: Annex B)

### 4.1 Objective
To confirm that PT items are sufficiently **homogeneous and stable**, ensuring valid interlaboratory comparison.

### 4.2 Data Input
The application reads from:
- `homogeneity.csv` — replicate data per PT item.
- `stability.csv` — results from two test dates.

### 4.3 Statistical Methods

#### Homogeneity Test
A **one-way ANOVA** is performed:
\[ s_s = \sqrt{\frac{MS_{between} - MS_{within}}{n}} \]
Criteria for homogeneity:
\[ s_s \leq 0.3 \times \sigma_{pt} \]
If not satisfied, an expanded criterion applies:
\[ s_s \leq \sqrt{1.88(0.3\sigma_{pt})^2 + 1.01s_w^2} \]

#### Stability Test
A **Student’s t-test** compares two time-point means (y₁, y₂):
\[ |y_1 - y_2| \leq 0.3 \times \sigma_{pt} \]
A *p*-value > 0.05 confirms acceptable stability.

### 4.4 Outputs
- ANOVA and t-test tables with variance components.
- Color-coded stability/homogeneity conclusions.
- Histograms, boxplots, and stability plots for visual review.

---

## 5. PT Preparation (Participant Data)

### 5.1 Input and Structure
Data are imported from `summary_n*.csv`. The app auto-detects pollutants and PT levels.

| Column | Type | Description |
|---------|------|--------------|
| pollutant | character | Pollutant code (e.g., CO, NO₂, O₃) |
| level | numeric | Concentration level |
| participant_id | character | Laboratory ID |
| mean_value | numeric | Participant’s reported mean |
| sd_value | numeric | Standard deviation or uncertainty |
| sample_group | character | Batch/run identifier |

### 5.2 Features
- Dynamic tabs for each pollutant.
- Participant mean and SD visualization (bar and density plots).
- Outlier detection via **Grubbs’ test**.
- Run charts and distribution visualizations using **ggplot2**.

---

## 6. Performance Score Calculations (ISO 13528: Clause 9)

### 6.1 Statistical Formulas

| Score | Formula | Notes |
|--------|----------|-------|
| **z** | (xᵢ − xₚₜ) / σₚₜ | Basic standardized deviation |
| **z′** | (xᵢ − xₚₜ) / √(σₚₜ² + uₓₚₜ²) | Includes assigned value uncertainty |
| **ζ** | (xᵢ − xₚₜ) / √(uₓₚₜ² + u(xᵢ)²) | Combines both uncertainties |
| **En** | (xᵢ − xₚₜ) / √((k·uₓₚₜ)² + (k·u(xᵢ))²), k=2 | Expanded uncertainty criterion |

### 6.2 Evaluation Criteria
| Score | Satisfactory | Questionable | Unsatisfactory |
|--------|---------------|--------------|----------------|
| z or z′ | |z| ≤ 2 | 2 < |z| < 3 | |z| ≥ 3 |
| ζ | |ζ| ≤ 2 | 2 < |ζ| < 3 | |ζ| ≥ 3 |
| En | |En| ≤ 1 | — | |En| > 1 |

### 6.3 Outputs
- Interactive **DT tables** displaying calculated scores.
- Color-coded interpretations: green (satisfactory), yellow (warning), red (unsatisfactory).

---

## 7. Outlier Detection and Data Validation

### 7.1 Statistical Test
The app applies **Grubbs’ test** (`outliers::grubbs.test`) to identify extreme single outliers (n ≥ 3). Detected outliers are **flagged but retained** in score evaluation, per ISO 13528 §6.6.

### 7.2 Data Validation Checks
- Automatic NA handling during data import.
- Validation of expected numeric and factor types.
- Summary statistics preview for each dataset.

---

## 8. Visualization and Reporting

### 8.1 Graphical Outputs
- **Z-score plots** with control lines at ±2 and ±3.
- **Z′, ζ, and En plots** with appropriate uncertainty limits.
- **Histograms**, **boxplots**, and **kernel density plots**.
- **Run charts** showing participant trends across PT levels.

### 8.2 Reporting
Reports include:
- Statistical summary tables (xₚₜ, σₚₜ, uₓₚₜ, sₛ, s_w).
- Homogeneity/stability conclusions.
- Participant scores and performance categories.

### 8.3 Export Options
All tables and plots are exportable as **CSV**, **Excel**, or **image** files. Future releases will add automatic **R Markdown/Quarto** PDF and DOCX reporting.

---

## 9. Quality Assurance and Validation

- All formulas adhere to ISO 13528:2022 Annex B & C.
- Statistical routines (ANOVA, MAD, Grubbs, Algorithm A) validated using reference datasets.
- Verification performed by CALAIRE-INM QA specialists.
- Internal reproducibility confirmed through replicated app runs with identical results.

---

## 10. References

1. ISO/IEC 17043:2023 — *Conformity assessment – General requirements for proficiency testing.*
2. ISO 13528:2022 — *Statistical methods for use in proficiency testing by interlaboratory comparison.*
3. Eurolab Cook Book No. 8 — *Selection, Use, and Interpretation of PT Schemes.*
4. Shiny Web Framework Documentation — [https://shiny.posit.co](https://shiny.posit.co)
5. The R Project for Statistical Computing — [https://www.r-project.org](https://www.r-project.org)

---

**End of Document**

