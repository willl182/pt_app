# Specification: Comprehensive Statistical Engine Refactoring & Integration

## 1. Goal
To decouple the statistical calculation logic from the Shiny UI layer (`app.R`) and the Report Generator (`report_template.Rmd`). This will establish a single source of truth for all statistical operations (homogeneity, stability, consensus values, scores, outliers), ensuring consistency, testability, and maintainability.

## 2. Scope

### 2.1 Homogeneity & Stability
- **Refactoring:** Extract ANOVA, Cochran's test, and stability t-tests from `app.R`.
- **Enhancement:** Explicitly calculate and return uncertainty components ($u_{xpt}$, $u_{stab}$) as part of the result object.
- **Output:** `R/stats_homogeneity_stability.R`

### 2.2 Consensus Values
- **Refactoring:** Extract robust statistical methods currently embedded in the code.
- **Methods:** Algorithm A (ISO 13528), MADe (Median Absolute Deviation), and nIQR (Normalized Interquartile Range).
- **Output:** `R/stats_consensus.R`

### 2.3 Performance Scores
- **Refactoring:** Create dedicated functions for participant scoring metrics.
- **Metrics:**
    - z-score
    - z'-score (z-prime)
    - zeta-score
    - $E_n$ score
- **Output:** `R/stats_scoring.R`

### 2.4 Outlier Detection
- **Refactoring:** Standardize the use of the `outliers` package.
- **Methods:** Grubbs' test (single and potentially double).
- **Output:** `R/stats_outliers.R`

### 2.5 Integration
- **App Update:** Refactor `app.R` to remove inline math and replace it with calls to the functions in `R/`.
- **Report Update:** Refactor `report_template.Rmd` to use the same functions, eliminating code duplication.

## 3. Requirements
- **Consistency:** The results produced by `app.R` and the generated report MUST be identical for the same dataset.
- **ISO Compliance:** All algorithms must strictly adhere to ISO 13528:2022.
- **Error Handling:** Functions must handle missing values (`NA`) and edge cases (e.g., insufficient data points) gracefully, returning informative error messages or warning flags.
- **Modularity:** Each module (`homogeneity`, `consensus`, etc.) should be independent where possible, sharing only common utility functions.

## 4. Deliverables
1.  New R script: `R/stats_homogeneity_stability.R`
2.  New R script: `R/stats_consensus.R`
3.  New R script: `R/stats_scoring.R`
4.  New R script: `R/stats_outliers.R`
5.  Updated `app.R`
6.  Updated `reports/report_template.Rmd`
7.  Verification report (comparison of old vs. new outputs)
