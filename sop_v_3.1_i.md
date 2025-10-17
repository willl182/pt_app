# SOP_V3.1 — Integrated and Comprehensive Standard Operating Procedure for PT Data Analysis in R/Shiny

## 1. Purpose and Scope

This **Standard Operating Procedure (SOP)** describes the complete, reproducible, and comparative workflow for the **PT Data Analysis Application**, developed in **R/Shiny** and compliant with **ISO/IEC 17043:2023** and **ISO 13528:2022**. It integrates the methodological rigor, statistical robustness, and comparative structure of the previous SOP versions (V3 and GEM).

The SOP provides a unified, auditor-ready procedure for:
- Estimating **assigned values (xₚₜ)** and **standard deviations for proficiency assessment (σₚₜ)** using four robust methods: Median, MADe, nIQR, and Algorithm A.
- Conducting **homogeneity and stability testing** for each xₚₜ estimator.
- Performing **comparative evaluation** across methods to determine the most statistically sound xₚₜ.
- Computing and reporting **mandatory participant performance scores**.

---

## 2. System Setup and Environment

### 2.1 Software Requirements
- **R version:** ≥ 4.2  
- **Interface:** RStudio or compatible IDE  
- **Framework:** Shiny (for interactive data analysis)

### 2.2 Required R Packages
```r
install.packages(c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers"
))
```

### 2.3 Directory Structure
```
/data           # Input data (homogeneity.csv, stability.csv, participant_results.csv)
/app            # Shiny app code (app.R, server.R)
/reports        # Output tables, plots, and reports
```

### 2.4 Launching the Application
```bash
Rscript run_app.R
```

---

## 3. Comparative Workflow Overview

The workflow is structured in four major steps designed to ensure full analytical transparency:

1. **Compute Robust Estimators** — Obtain four versions of xₚₜ and σₚₜ using Median, MADe, nIQR, and Algorithm A.
2. **Validate Homogeneity and Stability** — Apply ISO 13528 Annex B criteria for each σₚₜ variant.
3. **Compare and Select** — Evaluate consistency across the four variants and select the most appropriate xₚₜ.
4. **Compute Performance Scores** — Use the final xₚₜ and σₚₜ for z, z′, ζ, and En score calculations.

---

## 4. Step 1 — Robust Estimation of xₚₜ and σₚₜ

### 4.1 Method Overview
| Method | Formula | Description |
|---------|----------|-------------|
| **Median (xₚₜ₁)** | median(x) | Robust measure of location |
| **MADe (σₚₜ₂)** | 1.4826 × median(|xᵢ−median(x)|) | Scaled MAD per ISO 13528 §6.5.2 |
| **nIQR (σₚₜ₃)** | 0.7413 × (Q₃−Q₁) | Normalized interquartile range (Annex C) |
| **Algorithm A (xₚₜ₄, σₚₜ₄)** | Iterative winsorization | ISO 13528 §7.4 algorithm for robust mean/SD |

### 4.2 R Implementation
```r
mad_e_manual <- function(x){
  med <- median(x, na.rm = TRUE)
  1.4826 * median(abs(x - med), na.rm = TRUE)
}

nIQR_manual <- function(x){
  q <- quantile(x, probs = c(0.25, 0.75), na.rm = TRUE)
  0.7413 * (q[2] - q[1])
}

algorithm_A <- function(x, max_iter=100){
  x <- x[!is.na(x)]
  x_star <- median(x); s_star <- mad(x, constant=1.4826)
  for(i in 1:max_iter){
    delta <- 1.5 * s_star
    x_prime <- pmin(pmax(x, x_star - delta), x_star + delta)
    new_x <- mean(x_prime)
    new_s <- 1.134 * sd(x_prime)
    if(abs(new_x - x_star) < 1e-6 && abs(new_s - s_star) < 1e-6) break
    x_star <- new_x; s_star <- new_s
  }
  list(robust_mean=x_star, robust_sd=s_star)
}
```

---

## 5. Step 2 — Homogeneity and Stability Validation (4×)

### 5.1 Homogeneity Assessment (ISO 13528 Annex B)
#### Objective
To ensure between-item variability is acceptably small for PT item uniformity.

#### Formulas
1. Item means: x̄ᵢ = mean(xᵢ₁...xᵢₘ)  
2. Between/Within sums of squares:
   - SSb = m·Σ(x̄ᵢ−x̄̄)²
   - SSw = ΣΣ(xᵢ,k−x̄ᵢ)²
3. Mean squares:
   - MSb = SSb/(g−1)
   - MSw = SSw/[g(m−1)]
4. Between-item SD:
   - sₛ = √((MSb−MSw)/m)

#### Acceptance Criteria
- **Primary:** sₛ ≤ 0.3·σₚₜᵢ  
- **Expanded (if marginal):** MSb ≤ F₁(0.3σₚₜᵢ)² + F₂MSw

### 5.2 Stability Assessment (ISO 13528 Annex B.5)
#### Procedure
- Compute |y₁−y₂|, where y₁, y₂ are mean results at times t₁ and t₂.
- Acceptance Criterion: |y₁−y₂| ≤ 0.3·σₚₜᵢ
- t-test (p > 0.05) supports item stability.

### 5.3 Output
Generate four validation tables (Median, MADe, nIQR, Algorithm A) containing:
- Homogeneity (sₛ, MSb, MSw, pass/fail)
- Stability (|y₁−y₂|, t-test p-value, pass/fail)

---

## 6. Step 3 — Comparative Evaluation and Selection

### 6.1 Comparative Analysis
- Consolidate results into a summary table.
- Assess each method’s pass/fail consistency for both tests.
- Examine σₚₜᵢ values for plausibility and sensitivity.

### 6.2 Decision Rule
Select the **operational xₚₜ** and **σₚₜ** based on:
1. Homogeneity and stability confirmed.  
2. Statistically reasonable σₚₜ.  
3. Consistency with prior PT history.  
4. Algorithm A preferred when all methods yield consistent outcomes.

---

## 7. Step 4 — Performance Score Calculations (Mandatory)

### 7.1 Score Formulas
| Score | Formula | Description | Acceptance |
|--------|----------|-------------|-------------|
| **z** | (xᵢ−xₚₜ)/σₚₜ | Standard PT score | |z| ≤ 2 |
| **z′** | (xᵢ−xₚₜ)/√(σₚₜ²+uₓₚₜ²) | Adjusted for uncertainty of xₚₜ | |z′| ≤ 2 |
| **ζ** | (xᵢ−xₚₜ)/√(uₓₚₜ²+u(xᵢ)²) | Includes both uncertainties | |ζ| ≤ 2 |
| **En** | (xᵢ−xₚₜ)/√((k·uₓₚₜ)²+(k·u(xᵢ))²), k=2 | Expanded uncertainty | |En| ≤ 1 |

### 7.2 Outputs
- Tabular participant results (z, z′, ζ, En).  
- Graphical summaries (histograms, boxplots, score charts).  
- Aggregated pass/fail rates per pollutant and level.

---

## 8. Reporting, Documentation, and QA

### 8.1 Report Components
- Final selected xₚₜ, σₚₜ, and justification.
- Homogeneity and stability tables (all four estimators).
- Participant performance score summaries.
- Environment log: R version, packages, and execution time.

### 8.2 Validation and Traceability
- Verify outputs against ISO 13528 example datasets.
- Document R scripts and Shiny version numbers.
- Retain QA logs in `/reports/validation_logs/`.

---

## 9. References
1. ISO/IEC 17043:2023 — *Conformity assessment – General requirements for proficiency testing.*  
2. ISO 13528:2022 — *Statistical methods for use in proficiency testing by interlaboratory comparison.*  
3. Eurachem Guide (2021) — *Selection, Use, and Interpretation of PT Schemes.*  
4. Linsinger, M. G. (2018). *Use of robust statistical methods in proficiency testing.* *Accreditation and Quality Assurance*, 23, 399–403.  
5. Rousseeuw, P. J., & Croux, C. (1993). *Alternatives to the median absolute deviation.* *Journal of the American Statistical Association*, 88(424), 1273–1283.  
6. AMC Technical Brief No. 6 — *Robust Statistics*. Royal Society of Chemistry.  
7. NIST/SEMATECH e-Handbook of Statistical Methods (Section 1.3.5).  

---

**End of SOP_V3.1 — Integrated Comprehensive Version**

