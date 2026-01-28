# Refactor: Expanded C Criterion for Homogeneity

## Summary

Update the expanded homogeneity criterion calculation to use sample-count-dependent F1/F2 coefficients from ISO tables, replacing the current formula.

## Formula Change

### Old formula
```r
c_expanded = c_criterion * sqrt(1 + (u_sigma_pt/sigma_pt)^2)
# where c_criterion = 0.3 * sigma_pt
```

### New formula
```r
c_exp = F1 * (0.3 * sigma_pt)^2 + F2 * sw^2
```

Where F1 and F2 depend on the number of samples (g):

| g  | F1   | F2   |
|----|------|------|
| 20 | 1.59 | 0.57 |
| 19 | 1.60 | 0.59 |
| 18 | 1.62 | 0.62 |
| 17 | 1.64 | 0.64 |
| 16 | 1.67 | 0.68 |
| 15 | 1.69 | 0.71 |
| 14 | 1.72 | 0.75 |
| 13 | 1.75 | 0.80 |
| 12 | 1.79 | 0.86 |
| 11 | 1.83 | 0.93 |
| 10 | 1.88 | 1.01 |
| 9  | 1.94 | 1.11 |
| 8  | 2.01 | 1.25 |
| 7  | 2.10 | 1.43 |

## Design Decisions

1. **No square root**: Formula is exactly `F1*(0.3*sigma_pt)^2 + F2*sw^2`
2. **Comparison unchanged**: Keep `ss <= c_exp` as-is
3. **F1/F2 hardcoded**: Values embedded in function (not external CSV)
4. **Range clamping**: g clamped to 7-20 (use boundary values for out-of-range)

## Files to Update

| # | File | Change |
|---|------|--------|
| 1 | `ptcalc/R/pt_homogeneity.R` | Core function update |
| 2 | `R/pt_homogeneity.R` | Mirror ptcalc changes |
| 3 | `app.R` | Update calls (~line 392, 408-409) |
| 4 | `tools/generate_report_assets.R` | Update line ~172 |
| 5 | `scripts/demo_homogeneidad_estabilidad.R` | Update line ~190 |
| 6 | `reports/report_template.Rmd` | Update compute_homogeneity() |
| 7 | `deliv/01_repo_inicial/R/pt_homogeneity.R` | Update archived copy |
| 8 | `deliv/03_calculos_pt/R/homogeneity.R` | Update archived copy |

## New Function Signature

```r
calculate_homogeneity_criterion_expanded(sigma_pt, sw, g)
```

### Parameters
- `sigma_pt`: Standard deviation for proficiency assessment (e.g., MADe or nIQR)
- `sw`: Within-sample standard deviation from ANOVA
- `g`: Number of samples (items)

### Returns
- Expanded criterion value
