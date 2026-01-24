# Phase 0: Function Mapping Document

## Overview

This document maps all duplicated statistical functions across the PT application codebase.
Each entry shows the canonical implementation (ptcalc), duplicates in app.R and report_template.Rmd,
and documents parameter/behavior differences that must be resolved during consolidation.

---

## 1. run_algorithm_a (Algorithm A - ISO 13528)

### Canonical Implementation: ptcalc/R/pt_robust_stats.R

| Attribute | Value |
|-----------|-------|
| Lines | 112-246 |
| Signature | `run_algorithm_a(values, ids = NULL, max_iter = 50, tol = 1e-03)` |
| Returns | `list(assigned_value, robust_sd, iterations, weights, converged, effective_weight, error)` |
| Tolerance | **1e-03** |

### Duplicate: report_template.Rmd

| Attribute | Value |
|-----------|-------|
| Lines | 114-145 |
| Signature | `run_algorithm_a(values, max_iter = 50)` |
| Returns | `list(mean, sd, error)` |
| Tolerance | **1e-04** (DIFFERENT!) |

### Differences

| Aspect | ptcalc | report_template.Rmd |
|--------|--------|---------------------|
| Tolerance | 1e-03 | 1e-04 |
| Return names | `assigned_value`, `robust_sd` | `mean`, `sd` |
| Iteration history | Yes (data.frame) | No |
| Weights output | Yes (data.frame with ids) | No |
| Convergence flag | Yes | No |
| IDs parameter | Yes | No |

### Risk Level: HIGH

Different tolerance values may produce different final values for edge cases near convergence threshold.

### Resolution

- Remove `run_algorithm_a` from report_template.Rmd
- Use ptcalc::run_algorithm_a
- Map return values: `$mean` -> `$assigned_value`, `$sd` -> `$robust_sd`
- If report needs simpler output, access only required fields

---

## 2. calculate_niqr (Normalized IQR)

### Canonical Implementation: ptcalc/R/pt_robust_stats.R

| Attribute | Value |
|-----------|-------|
| Lines | 33-40 |
| Signature | `calculate_niqr(x)` |
| Returns | `numeric` (0.7413 * IQR) or `NA_real_` |

### Duplicate: report_template.Rmd

| Attribute | Value |
|-----------|-------|
| Lines | 97-102 |
| Signature | `calculate_niqr(x)` |
| Returns | `numeric` or `NA_real_` |

### Differences

| Aspect | ptcalc | report_template.Rmd |
|--------|--------|---------------------|
| Implementation | Identical | Identical |

### Risk Level: LOW

Implementations are functionally equivalent.

### Resolution

- Remove `calculate_niqr` from report_template.Rmd
- Use ptcalc::calculate_niqr (already loaded)

---

## 3. calculate_homogeneity_stats vs compute_homogeneity_metrics

### Canonical Implementation: ptcalc/R/pt_homogeneity.R

| Attribute | Value |
|-----------|-------|
| Lines | 38-91 |
| Signature | `calculate_homogeneity_stats(sample_data)` |
| Input | Matrix/data.frame (samples x replicates) |
| Returns | `list(g, m, grand_mean, sample_means, s_x_bar_sq, s_xt, sw, sw_sq, ss_sq, ss, error)` |

### Duplicate: app.R

| Attribute | Value |
|-----------|-------|
| Lines | 281-428 |
| Signature | `compute_homogeneity_metrics(target_pollutant, target_level)` |
| Input | Pollutant name, level name (fetches from reactive data) |
| Returns | Large list with UI-specific fields (conclusion, conclusion_class, etc.) |

### Duplicate: report_template.Rmd

| Attribute | Value |
|-----------|-------|
| Lines | 148-178 |
| Signature | `compute_homogeneity(data_full, pol, lev)` |
| Input | Full data frame, pollutant, level |
| Returns | `list(ss, sw, sigma_pt, c_crit, mean, passed)` |

### Key Formulas (all three locations)

```r
# Within-sample SD (m=2 case)
sw <- sqrt(sum(ranges^2) / (2 * g))

# Between-sample variance component
ss_sq <- abs(s_x_bar_sq - (sw^2 / m))
ss <- sqrt(ss_sq)

# Criterion
c_criterion <- 0.3 * sigma_pt
```

### Differences

| Aspect | ptcalc | app.R | report_template.Rmd |
|--------|--------|-------|---------------------|
| Data access | Direct matrix | Shiny reactive | Direct data.frame |
| sigma_pt calc | Not included | MADe from sample_1 | MADe from sample_1 |
| Criterion calc | Separate function | Inline | Inline |
| Expanded criterion | Separate function | Inline | Not included |
| UI metadata | No | Yes (conclusion_class) | No |
| u_xpt calc | No | Yes (L348) | No |

### Risk Level: MEDIUM

Core formulas are identical. Differences are in data access patterns and auxiliary calculations.

### Resolution

1. Create wrapper in app.R that:
   - Prepares matrix from Shiny reactives
   - Calls `ptcalc::calculate_homogeneity_stats()`
   - Adds UI-specific fields (conclusion text, CSS classes)
   - Calculates sigma_pt, u_xpt using ptcalc functions

2. In report_template.Rmd:
   - Remove `compute_homogeneity` function
   - Receive pre-computed values via params from app.R

---

## 4. calculate_stability_stats vs compute_stability_metrics

### Canonical Implementation: ptcalc/R/pt_homogeneity.R

| Attribute | Value |
|-----------|-------|
| Lines | 181-194 |
| Signature | `calculate_stability_stats(stab_sample_data, hom_grand_mean)` |
| Returns | Homogeneity stats + `stab_grand_mean`, `diff_hom_stab` |

### Duplicate: app.R

| Attribute | Value |
|-----------|-------|
| Lines | 430-599 |
| Signature | `compute_stability_metrics(target_pollutant, target_level, hom_results)` |
| Returns | Full stats with UI metadata, expanded criterion, u_hom_mean, u_stab_mean |

### Additional Functions in ptcalc (not used by app.R)

| Function | Lines | Purpose |
|----------|-------|---------|
| `calculate_stability_criterion` | 205-207 | Returns 0.3 * sigma_pt |
| `calculate_stability_criterion_expanded` | 218-220 | c + 2*sqrt(u_hom^2 + u_stab^2) |
| `evaluate_stability` | 232-258 | Returns passes_criterion, conclusion |
| `calculate_u_hom` | 269-271 | Returns ss |
| `calculate_u_stab` | 284-289 | Returns diff/sqrt(3) or 0 |

### Differences

| Aspect | ptcalc | app.R |
|--------|--------|-------|
| u_hom_mean calculation | Not included | L536-543 (sd/sqrt(n) of all hom values) |
| u_stab_mean calculation | Not included | L546-550 (sd/sqrt(n) of all stab values) |
| Expanded criterion formula | c + 2*sqrt(u_hom^2 + u_stab^2) | c + 2*sqrt(u_hom_mean^2 + u_stab_mean^2) |

### Risk Level: MEDIUM

The expanded criterion formula uses different uncertainty inputs (u_hom vs u_hom_mean).
Need to verify which is per ISO 13528.

### Resolution

1. Verify ISO 13528 requirement for expanded stability criterion
2. Add missing utility functions to ptcalc if needed
3. Refactor app.R to use ptcalc::calculate_stability_stats + ptcalc::evaluate_stability

---

## 5. Score Calculations (z, z', zeta, En)

### Canonical Implementation: ptcalc/R/pt_scores.R

| Function | Lines | Signature |
|----------|-------|-----------|
| `calculate_z_score` | 28-33 | `(x, x_pt, sigma_pt)` |
| `calculate_z_prime_score` | 53-59 | `(x, x_pt, sigma_pt, u_xpt)` |
| `calculate_zeta_score` | 79-85 | `(x, x_pt, u_x, u_xpt)` |
| `calculate_en_score` | 106-112 | `(x, x_pt, U_x, U_xpt)` |

All include validation: `if (!is.finite(denominator) || denominator <= 0) return(NA_real_)`

### Duplicate: app.R (inline in compute_combo_scores)

| Calculation | Lines | Code |
|-------------|-------|------|
| z_score | 1875 | `(participants_df$result - x_pt_def) / sigma_pt` |
| z_prime | 1877-1881 | `(participants_df$result - x_pt_def) / zprime_den` |
| zeta | 1882-1883 | `ifelse(zeta_den > 0, (...) / zeta_den, NA_real_)` |
| En | 1886-1887 | `ifelse(en_den > 0, (...) / en_den, NA_real_)` |

### CRITICAL ISSUE: Divide-by-Zero Risk

**app.R lines 1861-1865** (COMMENTED OUT):
```r
#    if (!is.finite(sigma_pt) || sigma_pt <= 0) {
#      return(list(
#        error = sprintf("sigma_pt no valido para %s.", combo_meta$title)
#      ))
#    }
```

Line 1875 directly divides by `sigma_pt` without validation!

### Risk Level: HIGH

If sigma_pt is 0 or NA, z-scores will be Inf or NaN silently.

### Resolution

1. Uncomment sigma_pt validation OR
2. Replace inline calculations with ptcalc::calculate_z_score (which has built-in validation)
3. Preferably do both for defense in depth

---

## 6. Score Evaluations

### Canonical Implementation: ptcalc/R/pt_scores.R

| Function | Lines | Purpose |
|----------|-------|---------|
| `evaluate_z_score` | 124-135 | Single z -> category |
| `evaluate_z_score_vec` | 142-149 | Vector z -> categories |
| `evaluate_en_score` | 160-169 | Single En -> category |
| `evaluate_en_score_vec` | 176-182 | Vector En -> categories |

### Usage in app.R

| Line | Code | Uses ptcalc? |
|------|------|--------------|
| 1901 | `evaluate_z_score_vec(z_score)` | YES |
| 1903 | `evaluate_z_score_vec(z_prime_score)` | YES |
| 1905 | `evaluate_z_score_vec(zeta_score)` | YES |
| 1907-1911 | `En_score_eval = case_when(...)` | NO (hardcoded inline) |

### Inline En Evaluation (app.R:1907-1911)

```r
En_score_eval = case_when(
  !is.finite(En_score) ~ "N/A",
  abs(En_score) <= 1 ~ "Satisfactorio",
  abs(En_score) > 1 ~ "No satisfactorio"
)
```

This is **identical** to `evaluate_en_score_vec` logic.

### Risk Level: LOW

Logic is identical, but inconsistent usage pattern.

### Resolution

Replace inline case_when with:
```r
En_score_eval = evaluate_en_score_vec(En_score)
```

---

## 7. Homogeneity/Stability Criterion Calculations

### Canonical Implementation: ptcalc/R/pt_homogeneity.R

| Function | Lines | Formula |
|----------|-------|---------|
| `calculate_homogeneity_criterion` | 109-111 | `0.3 * sigma_pt` |
| `calculate_homogeneity_criterion_expanded` | 123-127 | `sqrt(c^2 * 1.88 + sw_sq * 1.01)` |
| `calculate_stability_criterion` | 205-207 | `0.3 * sigma_pt` |
| `calculate_stability_criterion_expanded` | 218-220 | `c + 2*sqrt(u_hom^2 + u_stab^2)` |

### Inline in app.R

**Homogeneity (lines 378-380):**
```r
hom_c_criterion <- 0.3 * hom_sigma_pt
hom_sigma_allowed_sq <- hom_c_criterion^2
hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)
```

**Stability (lines 532-552):**
```r
stab_c_criterion <- 0.3 * hom_results$sigma_pt
# ... u_hom_mean and u_stab_mean calculations ...
stab_c_criterion_expanded <- stab_c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
```

### Differences

| Aspect | ptcalc expanded stability | app.R expanded stability |
|--------|---------------------------|--------------------------|
| u_hom input | ss (between-sample SD) | sd(all_values)/sqrt(n) |
| u_stab input | diff_hom_stab/sqrt(3) | sd(stab_values)/sqrt(n) |

### Risk Level: MEDIUM

Different interpretations of uncertainty components. Need ISO 13528 verification.

### Resolution

1. Verify correct formula per ISO 13528:2022 Section 9.3
2. Update ptcalc OR app.R to match standard
3. Replace inline calculations with ptcalc functions

---

## 8. get_wide_data (Data Transformation Helper)

### Locations

| File | Lines | Purpose |
|------|-------|---------|
| app.R | 264-279 | Transform long -> wide for homogeneity/stability |
| report_template.Rmd | 105-111 | Same transformation |

### Code Comparison

Both are nearly identical:
```r
get_wide_data <- function(df, target_pollutant) {
  filtered <- df %>% filter(pollutant == target_pollutant)
  if (nrow(filtered) == 0) return(NULL)
  filtered %>%
    select(-pollutant) %>%
    pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}
```

### Risk Level: LOW

Identical implementations.

### Resolution

- Move to ptcalc as internal utility OR
- Pass pre-transformed data to report via params

---

## Summary: Priority Actions

### HIGH Priority (Risk of Incorrect Results)

1. **Uncomment sigma_pt validation** in app.R:1861-1865 OR replace inline z-score calc with ptcalc functions
2. **Resolve Algorithm A tolerance difference** (1e-03 vs 1e-04)
3. **Verify stability expanded criterion formula** per ISO 13528

### MEDIUM Priority (Consistency)

4. Replace `compute_homogeneity_metrics` core logic with ptcalc::calculate_homogeneity_stats
5. Replace `compute_stability_metrics` core logic with ptcalc::calculate_stability_stats
6. Replace inline criterion calculations with ptcalc functions

### LOW Priority (Code Quality)

7. Replace inline En_score_eval with evaluate_en_score_vec
8. Remove duplicate `calculate_niqr` from report_template.Rmd
9. Remove duplicate `get_wide_data` from report_template.Rmd
10. Remove duplicate `run_algorithm_a` from report_template.Rmd

---

## File Change Summary

| File | Current Lines | Estimated Reduction | Changes |
|------|---------------|---------------------|---------|
| app.R | ~5200 | ~100 lines | Replace inline formulas with ptcalc calls |
| report_template.Rmd | 558 | ~80 lines | Remove local functions, use params |
| ptcalc/ | 812 total | +20 lines | Add missing utilities if needed |

---

## Validation Checklist

After refactoring, verify:

- [ ] z-scores match for reference dataset
- [ ] z'-scores match for reference dataset
- [ ] zeta-scores match for reference dataset
- [ ] En-scores match for reference dataset
- [ ] Homogeneity ss, sw, c_criterion match
- [ ] Stability diff_hom_stab, c_criterion match
- [ ] Algorithm A converges to same values (within tolerance)
- [ ] Report PDF/DOCX generation succeeds
- [ ] All existing tests pass
