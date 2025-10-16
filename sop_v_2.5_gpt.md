# SOP_V2 — Proficiency Testing Data Analysis in R/Shiny (Final Version)

## 1. Purpose and Scope
This SOP defines the complete statistical workflow for Proficiency Testing (PT) data using the PT Data Analysis Application (R/Shiny), aligned with ISO/IEC 17043:2023 and ISO 13528:2022. It ensures:
- Robust estimation of assigned values (xₚₜ or xₜ) using four robust methods: **Median**, **MADe**, **nIQR**, and **Algorithm A**.
- Execution of **Homogeneity and Stability** tests for each xₚₜ variant.
- Determination of the **operational xₚₜ** and **mandatory participant performance scoring**.

---

## 2. System & Data Setup
### 2.1 Software Requirements
- R ≥ 4.2; RStudio recommended
- Packages: `shiny`, `tidyverse`, `vroom`, `DT`, `rhandsontable`, `shinythemes`, `outliers`

### 2.2 Data Files
- `homogeneity.csv` — replicate data for PT items
- `stability.csv` — results at two time points (t₁, t₂)
- Participant summary files — for score calculations

### 2.3 Launching the App
```bash
Rscript run_app.R
```

---

## 3. Workflow Overview
1. Compute four xₚₜ versions using robust statistical estimators (Median, MADe, nIQR, Algorithm A).
2. For each version, perform **Homogeneity** and **Stability** tests using ISO 13528 Annex B criteria.
3. Compare outcomes and select the validated xₚₜ.
4. Compute **Performance Scores (mandatory)** for all participant data.

---

## 4. Robust Statistical Estimation (Median, MADe, nIQR)
### 4.1 Concept
Robust statistics minimize the impact of outliers. Three initial methods estimate xₚₜ and σₚₜ:
- **Median (xₚₜ₁)** – robust central tendency
- **MADe (σₚₜ₂)** – scaled median absolute deviation (1.4826×MAD)
- **nIQR (σₚₜ₃)** – 0.7413×IQR

### 4.2 R Snippets
```r
mad_e_manual <- function(x){
  x <- x[!is.na(x)]; if(!length(x)) return(NA)
  med <- median(x); 1.4826 * median(abs(x - med))
}

nIQR_manual <- function(x){
  x <- sort(x[!is.na(x)]); n <- length(x); if(n < 2) return(NA)
  q1 <- quantile(x, 0.25); q3 <- quantile(x, 0.75)
  0.7413 * (q3 - q1)
}
```

---

## 5. Algorithm A (ISO 13528)
**Algorithm A** produces the fourth xₚₜ (xₚₜ₄) and σₚₜ₄ using an iterative, winsorized approach.

```r
algorithm_A <- function(x, max_iter=100){
  x <- x[!is.na(x)]
  x_star <- median(x); s_star <- mad(x, constant=1.4826)
  x_prev <- -Inf; s_prev <- -Inf
  for(i in 1:max_iter){
    if(signif(x_star,3)==signif(x_prev,3) && signif(s_star,3)==signif(s_prev,3)) break
    x_prev <- x_star; s_prev <- s_star
    delta <- 1.5*s_star; x_prime <- pmin(pmax(x, x_star-delta), x_star+delta)
    x_star <- mean(x_prime); s_star <- 1.134*sd(x_prime)
  }
  list(robust_mean=x_star, robust_sd=s_star)
}
```

---

## 6. Homogeneity and Stability Testing (4×)
Each xₚₜ variant yields its own σₚₜᵢ, used to perform homogeneity and stability evaluations.

### 6.1 Homogeneity (Variance Components)
- Compute ANOVA components: `MS_b`, `MS_w`.
- Derive between-item SD: `s_s = sqrt((MS_b - MS_w)/m)`.
- Apply primary criterion: `s_s ≤ 0.3 × σₚₜᵢ`.
- If not met, use expanded F-factor rule: `MS_b ≤ F₁(0.3σₚₜᵢ)² + F₂MS_w`.

### 6.2 Stability (Two-Time Comparison)
- Compute mean difference: `|y₁ − y₂|`.
- Criterion: `|y₁ − y₂| ≤ 0.3 × σₚₜᵢ`.

### 6.3 Comparative Evaluation
Perform the above for all four xₚₜ variants and summarize results per pollutant/level in a comparative matrix.

---

## 7. Result Integration and Selection
The operational xₚₜ is selected based on:
- Consistent homogeneity and stability pass results
- Statistically plausible σₚₜ (neither too small nor inflated)
- Agreement with historical PT data

---

## 8. Performance Scores (Mandatory)
After selecting the final xₚₜ and σₚₜ, participant results are evaluated using ISO 13528 scoring methods.

### 8.1 Formulas
| Score | Formula | Description |
|--------|----------|-------------|
| **z** | (xᵢ − xₚₜ) / σₚₜ | Standard PT score |
| **z′** | (xᵢ − xₚₜ) / √(σₚₜ² + uₓₚₜ²) | Adjusted for uncertainty of xₚₜ |
| **ζ** | (xᵢ − xₚₜ) / √(uₓₚₜ² + u(xᵢ)²) | Considers both uncertainties |
| **En** | (xᵢ − xₚₜ) / √((k·uₓₚₜ)² + (k·u(xᵢ))²), k=2 | Expanded uncertainty criterion |

### 8.2 Interpretation Criteria
| Score | Satisfactory | Questionable | Unsatisfactory |
|--------|---------------|--------------|----------------|
| z, z′ | |z| ≤ 2 | 2 < |z| < 3 | |z| ≥ 3 |
| ζ | |ζ| ≤ 2 | 2 < |ζ| < 3 | |ζ| ≥ 3 |
| En | |En| ≤ 1 | — | |En| > 1 |

### 8.3 Outputs
- Participant score tables (z, z′, ζ, En)
- Graphical summaries: score charts, boxplots, density plots
- Aggregated performance metrics per pollutant/level

Performance scoring is **mandatory** and must be reported for all PT participants.

---

## 9. Reporting and QA
- Export all tables/plots (CSV, XLSX, PDF).
- Record the version of R and all package dependencies.
- Include justification for selected xₚₜ in the final report.

---

## 10. References
- ISO/IEC 17043:2023 — Conformity assessment — General requirements for proficiency testing.
- ISO 13528:2022 — Statistical methods for proficiency testing by interlaboratory comparison.
- Eurolab Cook Book No. 8 — Selection and Interpretation of PT Schemes.

---

**End of SOP_V2 (Final, Robust Integrated Version)**

