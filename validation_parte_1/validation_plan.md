# Validation Update Plan - Algorithm A Winsorization Method

## Executive Summary

Update validation spreadsheet to reflect algorithm change from Huber-weighting to Winsorization method for robust statistics (ISO 13528:2022 Annex C.3).

## Change Summary

| Aspect | OLD (Huber Weighting) | NEW (Winsorization) |
|--------|----------------------|---------------------|
| Outlier handling | Down-weight by `w = 1/u²` | Clamp values to `x* ± δ` |
| Location update | `x* = Σ(wi×xi)/Σwi` | `x* = mean(winsorized)` |
| Scale update | `s* = √(Σwi(xi-x*)²/Σwi)` | `s* = 1.134×√(Σ(xi*-x*)²/(p-1))` |
| Convergence | `Δ < tol` (1e-03) | 3rd significant figure match |
| Reference | ISO 13528 Annex C (general) | ISO 13528 Annex C.3 (specific) |

## Implementation Tasks

### 1. Update create_algorithm_a_sheet() Function

**File**: `validation/generate_validation_spreadsheets.R` (lines 366-583)

#### Changes Required

##### A. Parameters Section (lines 383-398)
**Remove:**
- "Huber constant (c)" and tolerance parameter

**Add:**
- MAD scale factor = 1.483 (makes MAD consistent for normal distribution)
- Winsorization factor = 1.5 (δ = 1.5 × s*)
- Scale adjustment factor = 1.134 (applied in s* calculation)

##### B. Initial Estimates (lines 417-444)
**Keep:**
- x*₀ = median(xi)
- s*₀ = 1.483 × MAD

**Add:**
- δ₀ = 1.5 × s*₀
- Lower bound = x*₀ - δ₀
- Upper bound = x*₀ + δ₀

##### C. Iteration 1 Detail (lines 446-506)

**OLD columns:**
- i, xi, ui, |ui|, wi, wi×xi, wi×(xi-x*₁)²

**NEW columns:**
- i, xi, x*₀ - δ₀, x*₀ + δ₀, xi* (winsorized)

**Formulas:**
```
δ = 1.5 × s*₀
Lower bound = x*₀ - δ
Upper bound = x*₀ + δ
xi* = clamp(xi, lower, upper) = IF(xi < lower, lower, IF(xi > upper, upper, xi))
```

**Update calculations:**
```
x*₁ = mean(xi*) = AVERAGE(xi*)
s*₁ = 1.134 × sqrt(Σ(xi* - x*₁)² / (p-1))
```

##### D. Convergence Check (lines 508-518)

**OLD:**
```excel
IF(AND(Δx < 0.001, Δs < 0.001), "YES", "NO")
```

**NEW:**
```excel
IF(AND(SIGNIF(x*,3)=SIGNIF(x_new,3), SIGNIF(s*,3)=SIGNIF(s_new,3)), "YES", "NO")
```

Use Excel formula:
```excel
=IF(AND(ROUND(x*_old,3-INT(LOG10(ABS(x*_old))))=ROUND(x*_new,3-INT(LOG10(ABS(x*_new)))),ROUND(s*_old,3-INT(LOG10(ABS(s*_old))))=ROUND(s*_new,3-INT(LOG10(ABS(s*_new))))),"YES","NO")
```

Or simpler approximation:
```excel
=IF(AND(ROUND(x*_old,-INT(LOG10(ABS(x*_old)))+2)=ROUND(x*_new,-INT(LOG10(ABS(x*_new)))+2),ROUND(s*_old,-INT(LOG10(ABS(s*_old)))+2)=ROUND(s*_new,-INT(LOG10(ABS(s*_new)))+2)),"YES","NO")
```

##### E. Iteration History Table (lines 520-542)

**Remove:**
- Δ column

**Add:**
- Keep: iteration, x*, s*, Converged
- Note: Converged shows YES/NO for each iteration

##### F. Formula Reference (lines 561-580)

**Update formulas to:**
```
Step 0: x*₀ = median(xi)
Step 0: s*₀ = 1.483 × MAD(xi)
Each iteration:
  δ = 1.5 × s*
  xi* = clamp(xi, x* - δ, x* + δ)
  x*_new = mean(xi*)
  s*_new = 1.134 × √(Σ(xi* - x*_new)² / (p-1))
Convergence: x* and s* stable to 3rd significant figure
```

### 2. Add Edge Cases Sheet

**Purpose**: Validate behavior with special datasets

**Cases to cover:**
1. **Identical values** (zero dispersion)
   - All xi = 10.0
   - Expected: x* = 10.0, s* = 0, converged = TRUE

2. **Fewer than 3 participants**
   - 2 values only
   - Expected: error message, assigned_value = NA

3. **Single outlier at extreme**
   - [10.1, 10.2, 10.0, 10.3, 100.0]
   - Expected: 100.0 winsorized to x* + δ

4. **No outliers**
   - [10.1, 10.2, 9.9, 10.0, 10.3]
   - Expected: x* ≈ mean, s* ≈ SD, minimal winsorization

### 3. Update Documentation

**File**: `validation/GUIA_VALIDACION_CALCULOS.md`

**Add section:**
```markdown
## Algorithm A (Winsorization Method)

The implementation follows ISO 13528:2022 Annex C.3, which uses a winsorization
approach instead of Huber weighting.

### Steps:
1. Initialize: x* = median(xi), s* = 1.483 × MAD
2. For each iteration:
   - δ = 1.5 × s*
   - Winsorize: xi* = clamp(xi, x* - δ, x* + δ)
   - Update: x* = mean(xi*), s* = 1.134 × √(Σ(xi* - x*)²/(p-1))
   - Check convergence: 3rd significant figure unchanged
```

### 4. Verification Steps

After implementation, verify:

```r
# Test with SO2 60-nmol/mol data
devtools::load_all("ptcalc")
summary_data <- read.csv("data/summary_n4.csv")
example <- summary_data[summary_data$pollutant == "so2" & summary_data$level == "60-nmol/mol", ]
values <- example$mean_value[!is.na(example$mean_value)]

result <- ptcalc::run_algorithm_a(values)

# Verify:
# 1. Initial x* matches median(values)
# 2. Initial s* matches 1.483 * MAD(values)
# 3. Final x*, s* match spreadsheet after regeneration
# 4. Winsorized values are correctly clamped
```

## File Modifications

| File | Action | Lines |
|------|--------|-------|
| `validation/generate_validation_spreadsheets.R` | Update `create_algorithm_a_sheet()` | 366-583 |
| `validation/generate_validation_spreadsheets.R` | Add `create_edge_cases_sheet()` | New |
| `validation/generate_validation_spreadsheets.R` | Update `main()` to call new sheet | 834-876 |
| `validation/GUIA_VALIDACION_CALCULOS.md` | Add Algorithm A (Winsorization) section | Append |

## Testing Checklist

- [ ] Spreadsheet generates without errors
- [ ] Algorithm A formulas are correct (winsorization method)
- [ ] Convergence check uses 3rd significant figures
- [ ] s* calculation includes 1.134 factor
- [ ] Edge cases sheet validates correctly
- [ ] Regenerated spreadsheet matches R output
- [ ] Documentation is updated

## References

- ISO 13528:2022 Annex C.3 - Algorithm A (Winsorization)
- `ptcalc/R/pt_robust_stats.R` - Current implementation
- `es/03_estadisticas_robustas_pt.md` - Spanish documentation
