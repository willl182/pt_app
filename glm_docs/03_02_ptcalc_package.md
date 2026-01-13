# ptcalc Package Documentation

| Item | Details |
|------|---------|
| **Location** | `ptcalc/` |
| **Version** | 0.1.0 |
| **License** | MIT |
| **Standards** | ISO 13528:2022, ISO 17043:2024 |
| **Author** | Wilson Rafael Salas Chavez (wrsalasc@unal.edu.co) |

---

## Overview

`ptcalc` is a pure R package that encapsulates all mathematical functions for proficiency testing calculations. It is designed with **zero Shiny dependencies**, making it suitable for:

- Independent use in R scripts
- Unit testing without UI overhead
- API integration with external systems
- Batch processing workflows

### Directory Structure

```
ptcalc/
├── DESCRIPTION              # Package metadata
├── LICENSE                  # MIT License
├── NAMESPACE                # Exported functions
├── README.md                # Quick reference
├── R/
│   ├── ptcalc-package.R     # Package documentation
│   ├── pt_robust_stats.R    # Robust statistics functions
│   ├── pt_homogeneity.R     # Homogeneity/stability functions
│   └── pt_scores.R          # Score calculation functions
└── man/                     # Roxygen2 generated documentation
    └── *.Rd                 # 21 function help files
```

---

## Design Philosophy

| Principle | Implementation |
|-----------|----------------|
| **Separation of concerns** | Mathematical logic separate from UI/Shiny code |
| **Pure functions** | No side effects, deterministic output |
| **Testability** | Independent functions, easy to unit test |
| **Documentation** | Comprehensive roxygen2 with examples |
| **Standards compliance** | ISO 13528:2022 and ISO 17043:2024 |

---

## Development Workflow

### Load for Development (Active Development)

```r
devtools::load_all("ptcalc")
```

**Use case:** When actively developing the package and need changes reflected immediately in the Shiny app without reinstalling.

**Pros:**
- Instant reload of changes
- No need to rebuild documentation
- Faster iteration cycle

**Cons:**
- Changes not persisted to installed package
- Requires R session restart if namespace issues occur

### Install for Production (Deployed Version)

```r
devtools::install("ptcalc")
# Or
remotes::install_local("ptcalc")
```

**Use case:** When deploying the application or creating a stable release.

**Pros:**
- Persistent installation
- Can be used from any R session
- Documentation fully built

**Cons:**
- Requires reinstallation for changes
- Slower development cycle

### Rebuild Documentation

```r
devtools::document("ptcalc")
```

**When to run:**
- After adding new functions with roxygen2 comments
- After modifying function parameters
- Before committing documentation changes

---

## Exported Functions Summary

### Robust Statistics (pt_robust_stats.R)

| Function | Parameters | Returns |
|----------|------------|---------|
| `calculate_niqr` | `x` (numeric) | nIQR value |
| `calculate_mad_e` | `x` (numeric) | MADe value |
| `run_algorithm_a` | `values`, `ids`, `max_iter`, `tol` | List with assigned_value, robust_sd, iterations, weights, converged, error |

### Homogeneity & Stability (pt_homogeneity.R)

| Function | Parameters | Returns |
|----------|------------|---------|
| `calculate_homogeneity_stats` | `sample_data` (df/matrix) | List with g, m, grand_mean, sample_means, s_x_bar_sq, s_xt, sw, sw_sq, ss_sq, ss, error |
| `calculate_homogeneity_criterion` | `sigma_pt` | Criterion value |
| `calculate_homogeneity_criterion_expanded` | `sigma_pt`, `sw_sq` | Expanded criterion value |
| `evaluate_homogeneity` | `ss`, `c_criterion`, `c_expanded` | List with passes_criterion, passes_expanded, conclusion |
| `calculate_stability_stats` | `stab_sample_data`, `hom_grand_mean` | List with stab_grand_mean, diff_hom_stab, plus homogeneity stats |
| `calculate_stability_criterion` | `sigma_pt` | Criterion value |
| `calculate_stability_criterion_expanded` | `c_criterion`, `u_hom_mean`, `u_stab_mean` | Expanded criterion value |
| `evaluate_stability` | `diff_hom_stab`, `c_criterion`, `c_expanded` | List with passes_criterion, passes_expanded, conclusion |
| `calculate_u_hom` | `ss` | Uncertainty value |
| `calculate_u_stab` | `diff_hom_stab`, `c_criterion` | Uncertainty value |

### Score Calculations (pt_scores.R)

| Function | Parameters | Returns |
|----------|------------|---------|
| `calculate_z_score` | `x`, `x_pt`, `sigma_pt` | z-score value |
| `calculate_z_prime_score` | `x`, `x_pt`, `sigma_pt`, `u_xpt` | z'-score value |
| `calculate_zeta_score` | `x`, `x_pt`, `u_x`, `u_xpt` | zeta-score value |
| `calculate_en_score` | `x`, `x_pt`, `U_x`, `U_xpt` | En-score value |
| `evaluate_z_score` | `z` | Character evaluation ("Satisfactorio", "Cuestionable", "No satisfactorio") |
| `evaluate_z_score_vec` | `z` (vector) | Character vector of evaluations |
| `evaluate_en_score` | `en` | Character evaluation |
| `evaluate_en_score_vec` | `en` (vector) | Character vector of evaluations |
| `classify_with_en` | `score_val`, `en_val`, `U_xi`, `sigma_pt`, `mu_missing`, `score_label` | List with code (a1-a7), label |

### Constants (pt_scores.R)

| Constant | Type | Value |
|----------|------|-------|
| `PT_EN_CLASS_LABELS` | Named vector | Classification labels a1-a7 |
| `PT_EN_CLASS_COLORS` | Named vector | Hex color codes for classifications |

---

## Roxygen2 Documentation Status

### Documentation Coverage

- **Total exported functions:** 21
- **Functions with roxygen2 documentation:** 21 (100%)
- **Functions with examples:** 15 (71%)
- **Standards references included:** Yes (ISO 13528:2022, ISO 17043:2024)

### Generated Documentation Files

The `man/` directory contains 21 `.Rd` files generated from roxygen2 comments. These provide:
- Function descriptions
- Parameter details
- Return value specifications
- Usage examples
- Cross-references to related functions
- Standards citations

### Documentation Quality Standards

Each exported function includes:
1. **Title:** Brief description
2. **Description:** Detailed explanation
3. **@details:** Additional context when needed
4. **@param:** Parameter documentation
5. **@return:** Return value specification
6. **@examples:** Code examples (where applicable)
7. **@seealso:** Related functions
8. **@export:** Required for package export
9. **@references:** ISO standards (where applicable)

---

## Unit Test Coverage

### Current Status

| Category | Coverage Status |
|----------|-----------------|
| Unit tests | Not implemented (tests/ directory empty) |
| Integration tests | Not implemented |
| Test framework | None selected yet |

### Recommended Test Coverage

For future implementation, consider these test areas:

```r
tests/testthat/
├── test-pt_robust_stats.R
├── test-pt_homogeneity.R
├── test-pt_scores.R
└── test-edge-cases.R
```

### Test Cases to Implement

**Robust Statistics:**
- nIQR calculation with known values
- MADe calculation with outliers
- Algorithm A convergence behavior
- Algorithm A edge cases (n < 3, zero variance)

**Homogeneity:**
- ANOVA calculations (ss, sw)
- Criterion evaluations
- Stability comparisons
- Uncertainty calculations

**Scores:**
- z-score formula verification
- Classification thresholds (|z| <= 2, 2 < |z| < 3, |z| >= 3)
- En-score thresholds (|En| <= 1)
- Combined z/En classifications (a1-a7)

---

## Usage in Application

### Loading the Package

In `cloned_app.R`:
```r
devtools::load_all("ptcalc")
```

### Example: Algorithm A in Shiny

```r
algoA_result <- run_algorithm_a(
  values = participant_values,
  ids = participant_ids,
  max_iter = 50,
  tol = 1e-03
)

if (!is.null(algoA_result$error)) {
  showNotification(algoA_result$error, type = "error")
} else {
  rv$assigned_value <<- algoA_result$assigned_value
  rv$robust_sd <<- algoA_result$robust_sd
}
```

### Example: Homogeneity Evaluation

```r
hom_stats <- calculate_homogeneity_stats(homogeneity_data)
criterion <- calculate_homogeneity_criterion(sigma_pt = 0.5)
evaluation <- evaluate_homogeneity(hom_stats$ss, criterion)

print(evaluation$conclusion)
```

---

## Dependencies

| Package | Purpose | Version |
|---------|---------|---------|
| **stats** | Base statistical functions | Built-in |
| **dplyr** | Vectorized case_when operations | >= 1.0.0 |

---

## Mathematical Formulas

### Robust Statistics

**Normalized IQR:**
```
nIQR = 0.7413 × (Q3 - Q1)
```

**Scaled MAD:**
```
MADe = 1.483 × median(|xi - median(x)|)
```

**Algorithm A (simplified):**
```
u = (xi - x*) / (1.5 × s*)
w = 1 if |u| <= 1, else 1/u²
x*new = Σ(wi × xi) / Σwi
s*new = √[Σwi × (xi - x*new)² / Σwi]
```

### Score Calculations

**z-score:**
```
z = (x - x_pt) / σ_pt
```

**z'-score:**
```
z' = (x - x_pt) / √(σ_pt² + u_xpt²)
```

**zeta-score:**
```
ζ = (x - x_pt) / √(u_x² + u_xpt²)
```

**En-score:**
```
En = (x - x_pt) / √(U_x² + U_xpt²)
```

### Homogeneity

**Within-sample SD (m=2):**
```
s_w = √[Σ(range_i²) / (2g)]
```

**Between-sample variance:**
```
s_s² = |s_x̄² - s_w²/m|
```

**Criterion:**
```
c = 0.3 × σ_pt
```

---

## References

1. **ISO 13528:2022** - Statistical methods for use in proficiency testing by interlaboratory comparison
2. **ISO 17043:2024** - Conformity assessment — General requirements for proficiency testing
3. **Huber, P.J. (1964)** - Robust estimation of a location parameter

---

## Next Steps

1. Implement unit tests using testthat
2. Add more examples for functions lacking them
3. Consider publishing to CRAN
4. Add vignettes for common use cases
