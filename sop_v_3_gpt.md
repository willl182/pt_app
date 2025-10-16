# SOP_V3 — Comprehensive Procedure for Proficiency Testing (PT) Data Analysis in R/Shiny

## 1. Purpose and Scope

This **Standard Operating Procedure (SOP)** defines the complete, unified workflow for the **PT Data Analysis Application**, built using R/Shiny, in compliance with **ISO/IEC 17043:2023** and **ISO 13528:2022**. It integrates the methodological rigor of **SOP_V2_Final**【74†source】 and the comparative sensitivity and analytical structure from **SOP_v_2.5_gem**【73†source】.

This SOP provides a single, comprehensive framework that ensures:
- Accurate and reproducible estimation of **assigned values (xₚₜ)** and **standard deviations for proficiency assessment (σₚₜ)** using **robust statistical methods**.
- Full **homogeneity and stability validation** of PT items for each robust estimator.
- **Comparative analysis** of results obtained by multiple robust methods to ensure reliability.
- **Mandatory performance scoring** (z, z′, ζ, En) and transparent reporting.

---

## 2. System Setup and Requirements

### 2.1 Software Environment
- **R version:** ≥ 4.2  
- **Framework:** Shiny (web-based analytical interface)  
- **Environment:** RStudio (recommended)

### 2.2 Required Packages
```r
install.packages(c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers"
))
```

### 2.3 Directory Structure
```
/data           # Input files: homogeneity.csv, stability.csv, participant_results.csv
/app            # Shiny app scripts (app.R, server.R)
/reports        # Outputs and generated results
```

### 2.4 Launch
Run the application using:
```bash
Rscript run_app.R
```

---

## 3. Workflow Overview
The PT analysis follows a four-stage comparative and validation workflow:

1. **Compute four robust estimators** of xₚₜ and σₚₜ (Median, MADe, nIQR, Algorithm A).  
2. **Conduct homogeneity and stability tests** for each σₚₜ version.  
3. **Compare outcomes** to evaluate sensitivity and robustness across estimators.  
4. **Select and apply the validated xₚₜ and σₚₜ** to calculate participant performance scores.

This structured approach provides analytical transparency, ensuring robustness and reproducibility across PT schemes.

---

## 4. Robust Estimation of xₚₜ and σₚₜ

### 4.1 Methods Overview
| Method | Description | Formula | Notes |
|---------|--------------|----------|-------|
| Median | Robust location estimator | xₚₜ₁ = median(x) | Insensitive to outliers |
| MADe | Median Absolute Deviation (scaled) | σₚₜ₂ = 1.4826·median(|xᵢ−median(x)|) | ISO 13528 §6.5.2 |
| nIQR | Normalized Interquartile Range | σₚₜ₃ = 0.7413·(Q₃−Q₁) | ISO 13528 Annex C |
| Algorithm A | Iterative robust mean and SD | ISO 13528 §7.4 | Preferred estimator for stability |

### 4.2 Example R Implementations
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
    delta <- 1.5*s_star
    x_prime <- pmin(pmax(x, x_star-delta), x_star+delta)
    new_x <- mean(x_prime)
    new_s <- 1.134*sd(x_prime)
    if(abs(new_x - x_star) < 1e-6 && abs(new_s - s_star) < 1e-6) break
    x_star <- new_x; s_star <- new_s
  }
  list(robust_mean = x_star, robust_sd = s_star)
}
```

---

## 5. Homogeneity and Stability Analysis (4×)
### 5.1 Purpose
To ensure that all PT samples are **statistically homogeneous and stable**, supporting valid participant performance comparisons.

### 5.2 Homogeneity Assessment (ISO 13528 Annex B)
Each σₚₜ variant (1–4) is tested using ANOVA-based variance components:

1. Compute item means (x̄ᵢ) and overall mean (x̄̄).  
2. Calculate sum of squares:
   - Between: SSb = m·Σ(x̄ᵢ−x̄̄)²  
   - Within: SSw = ΣΣ(xᵢ,k−x̄ᵢ)²  
3. Mean squares: MSb = SSb/(g−1); MSw = SSw/[g(m−1)]  
4. Between-item SD: sₛ = √((MSb−MSw)/m)

**Acceptance Criteria:**
- Primary: sₛ ≤ 0.3·σₚₜᵢ  
- Expanded (if marginal): MSb ≤ F₁·(0.3σₚₜᵢ)² + F₂·MSw

### 5.3 Stability Assessment
Compare two time points (t₁, t₂):
- Absolute mean difference: |y₁−y₂| ≤ 0.3·σₚₜᵢ  
- Statistical test: t-test, p > 0.05 supports stability.

### 5.4 Comparative Reporting
For each method i = 1:4, produce:
- Homogeneity table (MSb, MSw, sₛ, criteria results)
- Stability table (|y₁−y₂|, t-test p-values, conclusion)

Summarize all results in a comparative matrix for decision-making.

---

## 6. Selection of Operational xₚₜ and σₚₜ
**Decision Criteria:**
1. Homogeneity and stability both confirmed.  
2. σₚₜ neither inflated nor unrealistically small.  
3. Method aligns with previous PT rounds or standard practice (Algorithm A preferred).  

The selected xₚₜ and σₚₜ will be used for participant scoring.

---

## 7. Performance Score Calculations (Mandatory)
After validation, participant results are evaluated using ISO 13528 formulas.

| Score | Formula | Description | Criterion |
|--------|----------|-------------|------------|
| **z** | (xᵢ − xₚₜ)/σₚₜ | Standard deviation-based | |z| ≤ 2 (satisfactory) |
| **z′** | (xᵢ − xₚₜ)/√(σₚₜ² + uₓₚₜ²) | Accounts for xₚₜ uncertainty | 2 < |z| < 3 questionable |
| **ζ** | (xᵢ − xₚₜ)/√(uₓₚₜ² + u(xᵢ)²) | Includes both uncertainties | |ζ| ≥ 3 unsatisfactory |
| **En** | (xᵢ − xₚₜ)/√((k·uₓₚₜ)² + (k·u(xᵢ))²), k=2 | Expanded uncertainty | |En| ≤ 1 satisfactory |

### 7.1 Outputs
- Individual score reports with color-coded thresholds.  
- Graphical summaries: z/z′/ζ/En score charts and boxplots.  
- Aggregated results for QA summaries.

---

## 8. Reporting, Traceability, and QA
- Export numerical and graphical outputs (CSV, PDF, XLSX).  
- Document the selected xₚₜ, σₚₜ, and test results.  
- Record software environment (R version, packages).  
- Validate against reference datasets to ensure reproducibility.

---

## 9. References
1. ISO/IEC 17043:2023 — *Conformity assessment – General requirements for proficiency testing.*  
2. ISO 13528:2022 — *Statistical methods for proficiency testing by interlaboratory comparison.*  
3. Eurachem Guide (2021) — *Selection, Use, and Interpretation of PT Schemes.*  
4. Linsinger, M. G. (2018). *Use of robust statistical methods in proficiency testing.* *Accreditation and Quality Assurance*, 23, 399–403.  
5. AMC Technical Brief No. 6 — *Robust Statistics*, Royal Society of Chemistry.

---

**End of SOP_V3 — Comprehensive Edition (Gem+GPT Integration)**

