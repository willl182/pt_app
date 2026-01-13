# ptcalc API Reference

| Item | Details |
|------|---------|
| **Package** | ptcalc |
| **Version** | 0.1.0 |
| **Purpose** | Complete function reference for all exported functions |

---

## Table of Contents

- [Robust Statistics Functions](#robust-statistics-functions)
- [Homogeneity Functions](#homogeneity-functions)
- [Stability Functions](#stability-functions)
- [Score Calculation Functions](#score-calculation-functions)
- [Score Evaluation Functions](#score-evaluation-functions)
- [Combined Classification Functions](#combined-classification-functions)
- [Constants](#constants)

---

## Robust Statistics Functions

### `calculate_niqr(x)`

**Description:** Calculates the Normalized Interquartile Range (nIQR), a robust scale estimator.

**Reference:** ISO 13528:2022, Section 9.4

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | numeric | Yes | Vector of numeric values |

**Returns:**
- `numeric`: The normalized IQR value (0.7413 × IQR)
- `NA_real_`: If fewer than 2 finite values

**Error Conditions:**
- Returns NA if `length(x_clean) < 2`

**Examples:**

```r
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
result <- calculate_niqr(values)
# result ≈ 0.222 (depends on data)
```

---

### `calculate_mad_e(x)`

**Description:** Calculates the Scaled Median Absolute Deviation (MADe), a robust scale estimator highly resistant to outliers.

**Reference:** ISO 13528:2022, Section 9.4

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | numeric | Yes | Vector of numeric values |

**Returns:**
- `numeric`: The scaled MAD value (1.483 × MAD)
- `NA_real_`: If no finite values

**Error Conditions:**
- Returns NA if `length(x_clean) == 0`

**Examples:**

```r
values <- c(10.1, 10.2, 9.9, 10.0, 50.0)  # 50 is outlier
result <- calculate_mad_e(values)
# Result is robust to the outlier
```

---

### `run_algorithm_a(values, ids = NULL, max_iter = 50, tol = 1e-03)`

**Description:** Implements ISO 13528 Algorithm A for computing robust mean (assigned value) and robust standard deviation.

**Reference:** ISO 13528:2022, Annex C

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `values` | numeric | Yes | - | Vector of participant results |
| `ids` | character/integer | No | `NULL` | Optional participant identifiers |
| `max_iter` | integer | No | 50 | Maximum iterations for convergence |
| `tol` | numeric | No | 1e-03 | Convergence tolerance |

**Returns:**

A list containing:

| Field | Type | Description |
|-------|------|-------------|
| `assigned_value` | numeric | Robust mean (x*) |
| `robust_sd` | numeric | Robust standard deviation (s*) |
| `iterations` | data.frame | Iteration history with columns: iteration, x_star, s_star, delta |
| `weights` | data.frame | Final weights with columns: id, value, weight, standardized_residual |
| `converged` | logical | TRUE if converged within max_iter |
| `effective_weight` | numeric | Sum of final weights |
| `error` | character/NULL | Error message if failed, NULL otherwise |

**Error Conditions:**

| Condition | Returns |
|-----------|---------|
| `n < 3` | Error: "Algorithm A requires at least 3 valid observations." |
| Zero dispersion | Error: "Data dispersion is insufficient for Algorithm A." |
| Invalid weights | Error: "Computed weights are invalid for Algorithm A." |
| Zero SD during iteration | Error: "Algorithm A collapsed due to zero standard deviation." |

**Examples:**

```r
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 50.0)  # 50 is outlier
ids <- c("P001", "P002", "P003", "P004", "P005", "P006")

result <- run_algorithm_a(values, ids)

if (is.null(result$error)) {
  cat("Assigned value:", result$assigned_value, "\n")
  cat("Robust SD:", result$robust_sd, "\n")
  cat("Converged:", result$converged, "\n")
  print(result$iterations)
}
```

---

## Homogeneity Functions

### `calculate_homogeneity_stats(sample_data)`

**Description:** Computes ANOVA-based statistics for homogeneity assessment including between-sample (ss) and within-sample (sw) standard deviations.

**Reference:** ISO 13528:2022, Section 9.2

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sample_data` | data.frame/matrix | Yes | Data with samples as rows, replicates as columns |

**Returns:**

A list containing:

| Field | Type | Description |
|-------|------|-------------|
| `g` | integer | Number of samples |
| `m` | integer | Number of replicates per sample |
| `grand_mean` | numeric | Overall mean (x̄̄) |
| `sample_means` | numeric vector | Mean of each sample |
| `s_x_bar_sq` | numeric | Variance of sample means |
| `s_xt` | numeric | Standard deviation of sample means |
| `sw` | numeric | Within-sample standard deviation |
| `sw_sq` | numeric | Within-sample variance |
| `ss_sq` | numeric | Between-sample variance component |
| `ss` | numeric | Between-sample standard deviation |
| `error` | character/NULL | Error message if failed |

**Error Conditions:**

| Condition | Returns |
|-----------|---------|
| `g < 2` | Error: "At least 2 samples required for homogeneity assessment." |
| `m < 2` | Error: "At least 2 replicates per sample required for homogeneity assessment." |

**Examples:**

```r
# Create sample data: 10 items with 2 replicates each
set.seed(42)
sample_data <- matrix(rnorm(20, mean = 10, sd = 0.5), nrow = 10, ncol = 2)

stats <- calculate_homogeneity_stats(sample_data)

cat("Between-sample SD (ss):", stats$ss, "\n")
cat("Within-sample SD (sw):", stats$sw, "\n")
cat("Grand mean:", stats$grand_mean, "\n")
```

---

### `calculate_homogeneity_criterion(sigma_pt)`

**Description:** Calculates the base homogeneity criterion (c = 0.3 × σ_pt).

**Reference:** ISO 13528:2022, Section 9.2.3

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sigma_pt` | numeric | Yes | Standard deviation for proficiency assessment |

**Returns:**
- `numeric`: The criterion value

**Examples:**

```r
criterion <- calculate_homogeneity_criterion(sigma_pt = 0.5)
# criterion = 0.15
```

---

### `calculate_homogeneity_criterion_expanded(sigma_pt, sw_sq)`

**Description:** Calculates the expanded homogeneity criterion accounting for within-sample variance.

**Reference:** ISO 13528:2022, Section 9.2.4

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sigma_pt` | numeric | Yes | Standard deviation for proficiency assessment |
| `sw_sq` | numeric | Yes | Within-sample variance |

**Returns:**
- `numeric`: The expanded criterion value

**Formula:**
```
c_expanded = √(σ_allowed² × 1.88 + s_w² × 1.01)
```

**Examples:**

```r
expanded <- calculate_homogeneity_criterion_expanded(
  sigma_pt = 0.5,
  sw_sq = 0.01
)
```

---

### `evaluate_homogeneity(ss, c_criterion, c_expanded = NULL)`

**Description:** Evaluates whether between-sample standard deviation meets homogeneity criteria.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ss` | numeric | Yes | Between-sample standard deviation |
| `c_criterion` | numeric | Yes | Base homogeneity criterion |
| `c_expanded` | numeric | No | Expanded criterion (optional) |

**Returns:**

A list containing:

| Field | Type | Description |
|-------|------|-------------|
| `passes_criterion` | logical | TRUE if ss ≤ c_criterion |
| `passes_expanded` | logical/NA | TRUE if ss ≤ c_expanded, NA if c_expanded not provided |
| `conclusion` | character | Text description of evaluation |

**Examples:**

```r
evaluation <- evaluate_homogeneity(
  ss = 0.12,
  c_criterion = 0.15
)

if (evaluation$passes_criterion) {
  print("Homogeneity criterion met!")
}
print(evaluation$conclusion)
```

---

## Stability Functions

### `calculate_stability_stats(stab_sample_data, hom_grand_mean)`

**Description:** Computes stability statistics and compares stability sample mean to homogeneity grand mean.

**Reference:** ISO 13528:2022, Section 9.3

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `stab_sample_data` | data.frame/matrix | Yes | Stability sample data |
| `hom_grand_mean` | numeric | Yes | Grand mean from homogeneity study |

**Returns:**

A list containing all fields from `calculate_homogeneity_stats()` plus:

| Field | Type | Description |
|-------|------|-------------|
| `stab_grand_mean` | numeric | Mean of stability samples |
| `diff_hom_stab` | numeric | |stab_mean - hom_mean| |

**Examples:**

```r
stab_data <- matrix(rnorm(6, mean = 10, sd = 0.3), nrow = 3, ncol = 2)
hom_mean <- 10.0

stats <- calculate_stability_stats(stab_data, hom_mean)
cat("Difference:", stats$diff_hom_stab, "\n")
```

---

### `calculate_stability_criterion(sigma_pt)`

**Description:** Calculates the base stability criterion (same as homogeneity criterion).

**Reference:** ISO 13528:2022, Section 9.3.3

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `sigma_pt` | numeric | Yes | Standard deviation for proficiency assessment |

**Returns:**
- `numeric`: The criterion value (0.3 × σ_pt)

---

### `calculate_stability_criterion_expanded(c_criterion, u_hom_mean, u_stab_mean)`

**Description:** Calculates the expanded stability criterion accounting for uncertainties.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `c_criterion` | numeric | Yes | Base stability criterion |
| `u_hom_mean` | numeric | Yes | Uncertainty of homogeneity mean |
| `u_stab_mean` | numeric | Yes | Uncertainty of stability mean |

**Returns:**
- `numeric`: The expanded criterion value

**Formula:**
```
c_stab_expanded = c_criterion + 2 × √(u_hom_mean² + u_stab_mean²)
```

---

### `evaluate_stability(diff_hom_stab, c_criterion, c_expanded = NULL)`

**Description:** Evaluates whether stability difference meets stability criteria.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `diff_hom_stab` | numeric | Yes | |stab_mean - hom_mean| |
| `c_criterion` | numeric | Yes | Base stability criterion |
| `c_expanded` | numeric | No | Expanded criterion (optional) |

**Returns:**

A list containing:

| Field | Type | Description |
|-------|------|-------------|
| `passes_criterion` | logical | TRUE if diff ≤ c_criterion |
| `passes_expanded` | logical/NA | TRUE if diff ≤ c_expanded, NA if not provided |
| `conclusion` | character | Text description of evaluation |

---

### `calculate_u_hom(ss)`

**Description:** Calculates the uncertainty contribution from homogeneity.

**Reference:** ISO 13528:2022, Section 9.5

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ss` | numeric | Yes | Between-sample standard deviation |

**Returns:**
- `numeric`: u_hom = ss

---

### `calculate_u_stab(diff_hom_stab, c_criterion)`

**Description:** Calculates the uncertainty contribution from stability.

**Reference:** ISO 13528:2022, Section 9.5

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `diff_hom_stab` | numeric | Yes | |stab_mean - hom_mean| |
| `c_criterion` | numeric | Yes | Stability criterion |

**Returns:**
- `numeric`: 0 if diff ≤ criterion, else diff/√3

**Formula:**
```
u_stab = 0               if diff_hom_stab ≤ c_criterion
u_stab = diff_hom_stab/√3  otherwise
```

---

## Score Calculation Functions

### `calculate_z_score(x, x_pt, sigma_pt)`

**Description:** Calculates the z-score for a participant result.

**Reference:** ISO 13528:2022, Section 10.2

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | numeric | Yes | Participant result |
| `x_pt` | numeric | Yes | Assigned value |
| `sigma_pt` | numeric | Yes | Standard deviation for proficiency assessment |

**Returns:**
- `numeric`: z = (x - x_pt) / σ_pt
- `NA_real_`: If sigma_pt is invalid

**Error Conditions:**
- Returns NA if sigma_pt is not finite or sigma_pt ≤ 0

**Examples:**

```r
z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
# z = 1.0 (Satisfactorio)
```

---

### `calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)`

**Description:** Calculates the z'-score accounting for uncertainty in the assigned value.

**Reference:** ISO 13528:2022, Section 10.3

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | numeric | Yes | Participant result |
| `x_pt` | numeric | Yes | Assigned value |
| `sigma_pt` | numeric | Yes | Standard deviation for proficiency assessment |
| `u_xpt` | numeric | Yes | Standard uncertainty of assigned value |

**Returns:**
- `numeric`: z' = (x - x_pt) / √(σ_pt² + u_xpt²)
- `NA_real_`: If denominator is invalid

**Error Conditions:**
- Returns NA if denominator is not finite or ≤ 0

**Examples:**

```r
zprime <- calculate_z_prime_score(
  x = 10.5,
  x_pt = 10.0,
  sigma_pt = 0.5,
  u_xpt = 0.1
)
```

---

### `calculate_zeta_score(x, x_pt, u_x, u_xpt)`

**Description:** Calculates the zeta-score using participant's measurement uncertainty.

**Reference:** ISO 13528:2022, Section 10.4

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | numeric | Yes | Participant result |
| `x_pt` | numeric | Yes | Assigned value |
| `u_x` | numeric | Yes | Standard uncertainty of participant result |
| `u_xpt` | numeric | Yes | Standard uncertainty of assigned value |

**Returns:**
- `numeric`: ζ = (x - x_pt) / √(u_x² + u_xpt²)
- `NA_real_`: If denominator is invalid

**Error Conditions:**
- Returns NA if denominator is not finite or ≤ 0

**Examples:**

```r
zeta <- calculate_zeta_score(
  x = 10.5,
  x_pt = 10.0,
  u_x = 0.2,
  u_xpt = 0.1
)
```

---

### `calculate_en_score(x, x_pt, U_x, U_xpt)`

**Description:** Calculates the En-score using expanded uncertainties.

**Reference:** ISO 13528:2022, Section 10.5

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | numeric | Yes | Participant result |
| `x_pt` | numeric | Yes | Assigned value |
| `U_x` | numeric | Yes | Expanded uncertainty of participant result (k=2) |
| `U_xpt` | numeric | Yes | Expanded uncertainty of assigned value (k=2) |

**Returns:**
- `numeric`: En = (x - x_pt) / √(U_x² + U_xpt²)
- `NA_real_`: If denominator is invalid

**Error Conditions:**
- Returns NA if denominator is not finite or ≤ 0

**Examples:**

```r
en <- calculate_en_score(
  x = 10.5,
  x_pt = 10.0,
  U_x = 0.4,
  U_xpt = 0.2
)
```

---

## Score Evaluation Functions

### `evaluate_z_score(z)`

**Description:** Evaluates a z-score according to ISO 13528 criteria.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `z` | numeric | Yes | z-score value |

**Returns:**
- `character`: Evaluation category:
  - `"Satisfactorio"` if |z| ≤ 2
  - `"Cuestionable"` if 2 < |z| < 3
  - `"No satisfactorio"` if |z| ≥ 3
  - `"N/A"` if z is not finite

**Examples:**

```r
evaluate_z_score(1.5)    # "Satisfactorio"
evaluate_z_score(2.5)    # "Cuestionable"
evaluate_z_score(3.5)    # "No satisfactorio"
```

---

### `evaluate_z_score_vec(z)`

**Description:** Vectorized version of `evaluate_z_score()`.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `z` | numeric vector | Yes | Vector of z-score values |

**Returns:**
- `character vector`: Evaluation categories for each input

**Examples:**

```r
scores <- c(1.5, 2.5, 3.5, NA)
evaluations <- evaluate_z_score_vec(scores)
# c("Satisfactorio", "Cuestionable", "No satisfactorio", "N/A")
```

---

### `evaluate_en_score(en)`

**Description:** Evaluates an En-score according to ISO 13528 criteria.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `en` | numeric | Yes | En-score value |

**Returns:**
- `character`: Evaluation category:
  - `"Satisfactorio"` if |En| ≤ 1
  - `"No satisfactorio"` if |En| > 1
  - `"N/A"` if en is not finite

**Examples:**

```r
evaluate_en_score(0.8)   # "Satisfactorio"
evaluate_en_score(1.5)   # "No satisfactorio"
```

---

### `evaluate_en_score_vec(en)`

**Description:** Vectorized version of `evaluate_en_score()`.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `en` | numeric vector | Yes | Vector of En-score values |

**Returns:**
- `character vector`: Evaluation categories for each input

---

## Combined Classification Functions

### `classify_with_en(score_val, en_val, U_xi, sigma_pt, mu_missing, score_label)`

**Description:** Classifies results using combined z-score and En-score evaluation (a1-a7 categories).

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `score_val` | numeric | Yes | z-score or z'-score value |
| `en_val` | numeric | Yes | En-score value |
| `U_xi` | numeric | Yes | Expanded uncertainty of participant result |
| `sigma_pt` | numeric | Yes | Standard deviation for proficiency assessment |
| `mu_missing` | logical | Yes | TRUE if measurement uncertainty is missing |
| `score_label` | character | Yes | Score type label ("z" or "z'") |

**Returns:**

A list containing:

| Field | Type | Description |
|-------|------|-------------|
| `code` | character | Classification code (a1-a7 or mu_missing_*) |
| `label` | character | Human-readable classification label |

**Classification Criteria:**

| Code | z-score | En-score | MU Status | Description |
|------|---------|----------|-----------|-------------|
| a1 | ≤ 2 | < 1 | Conservative | Totalmente satisfactorio |
| a2 | ≤ 2 | < 1 | Not conservative | Satisfactorio pero conservador |
| a3 | ≤ 2 | ≥ 1 | - | Satisfactorio con MU subestimada |
| a4 | 2-3 | < 1 | - | Cuestionable pero aceptable |
| a5 | 2-3 | ≥ 1 | - | Cuestionable e inconsistente |
| a6 | ≥ 3 | < 1 | - | No satisfactorio pero la MU cubre la desviación |
| a7 | ≥ 3 | ≥ 1 | - | No satisfactorio (crítico) |

**Error Conditions:**
- Returns code = NA_character_, label = "N/A" if inputs are invalid

**Examples:**

```r
result <- classify_with_en(
  score_val = 1.5,
  en_val = 0.8,
  U_xi = 0.4,
  sigma_pt = 0.5,
  mu_missing = FALSE,
  score_label = "z"
)

cat("Classification:", result$code, "\n")
cat("Label:", result$label, "\n")
```

---

## Constants

### `PT_EN_CLASS_LABELS`

**Type:** Named character vector

**Description:** Human-readable labels for combined z/En classifications.

**Values:**

| Code | Label |
|------|-------|
| a1 | "a1 - Totalmente satisfactorio" |
| a2 | "a2 - Satisfactorio pero conservador" |
| a3 | "a3 - Satisfactorio con MU subestimada" |
| a4 | "a4 - Cuestionable pero aceptable" |
| a5 | "a5 - Cuestionable e inconsistente" |
| a6 | "a6 - No satisfactorio pero la MU cubre la desviación" |
| a7 | "a7 - No satisfactorio (crítico)" |

**Usage:**
```r
PT_EN_CLASS_LABELS["a1"]
# "a1 - Totalmente satisfactorio"
```

---

### `PT_EN_CLASS_COLORS`

**Type:** Named character vector

**Description:** Hex color codes for combined z/En classifications (used in heatmaps).

**Values:**

| Code | Hex Color | Color Name |
|------|-----------|------------|
| a1 | #2E7D32 | Dark Green |
| a2 | #66BB6A | Medium Green |
| a3 | #9CCC65 | Light Green |
| a4 | #FFF59D | Pale Yellow |
| a5 | #FBC02D | Golden Yellow |
| a6 | #EF9A9A | Light Red |
| a7 | #C62828 | Dark Red |
| mu_missing_z | #90A4AE | Blue Grey |
| mu_missing_zprime | #78909C | Lighter Blue Grey |

**Usage:**
```r
PT_EN_CLASS_COLORS["a1"]
# "#2E7D32"
```

---

## Complete Workflow Example

```r
library(ptcalc)

# Step 1: Calculate robust statistics using Algorithm A
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
algoA <- run_algorithm_a(values)

# Step 2: Assess homogeneity
sample_data <- matrix(c(10.05, 10.03, 10.02, 10.04, 10.01, 10.05), nrow = 3, ncol = 2)
hom_stats <- calculate_homogeneity_stats(sample_data)
criterion <- calculate_homogeneity_criterion(sigma_pt = algoA$robust_sd)
hom_eval <- evaluate_homogeneity(hom_stats$ss, criterion)

# Step 3: Calculate participant score
x <- 10.5
z <- calculate_z_score(x, algoA$assigned_value, algoA$robust_sd)
z_eval <- evaluate_z_score(z)

# Step 4: If participant has measurement uncertainty
U_x <- 0.4
U_xpt <- 0.2
en <- calculate_en_score(x, algoA$assigned_value, U_x, U_xpt)
en_eval <- evaluate_en_score(en)

# Step 5: Combined classification
classification <- classify_with_en(
  score_val = z,
  en_val = en,
  U_xi = U_x,
  sigma_pt = algoA$robust_sd,
  mu_missing = FALSE,
  score_label = "z"
)

cat("Assigned value:", algoA$assigned_value, "\n")
cat("Robust SD:", algoA$robust_sd, "\n")
cat("z-score:", z, "-", z_eval, "\n")
cat("En-score:", en, "-", en_eval, "\n")
cat("Classification:", classification$code, "-", classification$label, "\n")
cat("Homogeneity:", hom_eval$conclusion, "\n")
```

---

## Cross-References

- **02_ptcalc_package.md** - Package overview and design
- **03_pt_robust_stats.md** - Detailed explanation of robust statistics
- **04_pt_homogeneity.md** - Detailed explanation of homogeneity/stability
- **05_pt_scores.md** - Detailed explanation of score calculations
