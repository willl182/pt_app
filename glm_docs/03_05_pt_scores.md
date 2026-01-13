# pt_scores.R: PT Score Calculations

Functions for calculating and evaluating participant performance scores (z, z', ζ, En) according to ISO 13528:2022 Section 10.

---

## Location in Code

| Element | Value |
|----------|-------|
| File | `ptcalc/R/pt_scores.R` |
| Lines | 1 - 275 |

---

## Overview

Proficiency testing (PT) scores quantify how well a participant's result agrees with the assigned value. Different score types are used depending on:

1. Available information (assigned value, sigma_pt, uncertainties)
2. Purpose (screening vs. detailed evaluation)
3. Measurement characteristics

---

## Score Calculation Functions

### `calculate_z_score(x, x_pt, sigma_pt)`

**Standard z-score**

$$z = \frac{x - x_{pt}}{\sigma_{pt}}$$

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | numeric | Participant result |
| `x_pt` | numeric | Assigned value |
| `sigma_pt` | numeric | Target standard deviation for PT |

**Returns:** z-score value

**Reference:** ISO 13528:2022 Section 10.2

**When to use:**
- When σ_pt is specified by the PT scheme
- For initial screening of results
- When participant uncertainties are not available

**Example:**
```r
z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
cat("z-score:", z)  # 1.0 (Satisfactorio)
```

---

### `calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)`

**Robust z'-score**

$$z' = \frac{x - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}}$$

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | numeric | Participant result |
| `x_pt` | numeric | Assigned value |
| `sigma_pt` | numeric | Target standard deviation for PT |
| `u_xpt` | numeric | Standard uncertainty of assigned value |

**Returns:** z'-score value

**Reference:** ISO 13528:2022 Section 10.3

**When to use:**
- When assigned value has significant uncertainty
- When using consensus-derived assigned values
- As alternative to standard z-score when u_xpt is known

**Example:**
```r
zprime <- calculate_z_prime_score(
  x = 10.5, x_pt = 10.0, sigma_pt = 0.5, u_xpt = 0.1
)
cat("z'-score:", zprime)  # 0.98 (Satisfactorio)
```

---

### `calculate_zeta_score(x, x_pt, u_x, u_xpt)`

**Zeta-score (ζ)**

$$\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}}$$

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | numeric | Participant result |
| `x_pt` | numeric | Assigned value |
| `u_x` | numeric | Standard uncertainty of participant's result |
| `u_xpt` | numeric | Standard uncertainty of assigned value |

**Returns:** zeta-score value

**Reference:** ISO 13528:2022 Section 10.4

**When to use:**
- When participant uncertainties are known and credible
- For detailed evaluation incorporating measurement uncertainty
- When σ_pt is not specified or not appropriate

**Example:**
```r
zeta <- calculate_zeta_score(
  x = 10.5, x_pt = 10.0, u_x = 0.2, u_xpt = 0.1
)
cat("zeta-score:", zeta)  # 2.24 (Cuestionable)
```

---

### `calculate_en_score(x, x_pt, U_x, U_xpt)`

**En-score (Normalized error)**

$$En = \frac{x - x_{pt}}{\sqrt{U_x^2 + U_{xpt}^2}}$$

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | numeric | Participant result |
| `x_pt` | numeric | Assigned value |
| `U_x` | numeric | Expanded uncertainty of participant's result |
| `U_xpt` | numeric | Expanded uncertainty of assigned value |

**Returns:** En-score value

**Reference:** ISO 13528:2022 Section 10.5

**When to use:**
- For calibration comparisons
- When both participant and reference have expanded uncertainties (k=2)
- For metrological compatibility assessment

**Example:**
```r
en <- calculate_en_score(
  x = 10.5, x_pt = 10.0, U_x = 0.4, U_xpt = 0.2
)
cat("En-score:", en)  # 1.12 (No satisfactorio)
```

---

## Score Evaluation Functions

### `evaluate_z_score(z)`

**Z-score performance classification**

| |z| | Performance |
|----|------------|
| |z| ≤ 2 | Satisfactorio (Satisfactory) |
| 2 < |z| < 3 | Cuestionable (Questionable) |
| |z| ≥ 3 | No satisfactorio (Unsatisfactory) |

**Returns:** Character string with evaluation category

**Example:**
```r
evaluate_z_score(1.5)   # "Satisfactorio"
evaluate_z_score(2.5)   # "Cuestionable"
evaluate_z_score(3.5)   # "No satisfactorio"
```

### `evaluate_z_score_vec(z)`

**Vectorized z-score evaluation**

**Returns:** Character vector with evaluation categories

**Example:**
```r
scores <- c(1.2, 2.5, -3.1, 0.8)
evaluate_z_score_vec(scores)
# "Satisfactorio" "Cuestionable" "No satisfactorio" "Satisfactorio"
```

### `evaluate_en_score(en)`

**En-score performance classification**

| |En| | Performance |
|----|------------|
| |En| ≤ 1 | Satisfactorio (Satisfactory) |
| |En| > 1 | No satisfactorio (Unsatisfactory) |

**Returns:** Character string with evaluation category

**Example:**
```r
evaluate_en_score(0.8)   # "Satisfactorio"
evaluate_en_score(1.2)   # "No satisfactorio"
```

---

## Score Selection Guide

```mermaid
flowchart TD
    START[Calculate PT score] --> UNC_X{Participant<br/>uncertainty known?}
    
    UNC_X -- Yes --> UNC_XPT{Assigned value<br/>uncertainty known?}
    UNC_XPT -- Yes --> ZETA[Use zeta-score<br/>ζ = x - x_pt / sqrt(u_x² + u_xpt²)]
    UNC_XPT -- No --> ZPRIME[Use z'-score<br/>z' = x - x_pt / sqrt(σ_pt² + u_xpt²)]
    
    UNC_X -- No --> SIGMA_PT{σ_pt specified?}
    SIGMA_PT -- Yes --> Z[Use z-score<br/>z = x - x_pt / σ_pt]
    SIGMA_PT -- No --> CALIBRATION{Calibration<br/>comparison?}
    
    CALIBRATION -- Yes --> EN[Use En-score<br/>En = x - x_pt / sqrt(U_x² + U_xpt²)]
    CALIBRATION -- No --> CONSENSUS{Use consensus<br/>for x_pt?}
    
    CONSENSUS -- Yes --> ZPRIME
    CONSENSUS -- No --> NO_INFO[Insufficient information]
    
    style Z fill:#c8e6c9
    style ZPRIME fill:#fff9c4
    style ZETA fill:#c5e1a5
    style EN fill:#b39ddb
```

### Decision Tree Summary

| Situation | Recommended Score | Formula |
|-----------|------------------|---------|
| **σ_pt specified, no uncertainties** | z-score | $(x - x_{pt}) / \sigma_{pt}$ |
| **σ_pt specified, u_xpt known** | z'-score | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + u_{xpt}^2}$ |
| **u_x and u_xpt known** | zeta-score | $(x - x_{pt}) / \sqrt{u_x^2 + u_{xpt}^2}$ |
| **U_x and U_xpt known (k=2)** | En-score | $(x - x_{pt}) / \sqrt{U_x^2 + U_{xpt}^2}$ |
| **Consensus value** | z'-score (or zeta) | Use u_xpt from consensus |

---

## Uncertainty Propagation

### Combined Uncertainty: u_xpt_def

The uncertainty of the assigned value combines homogeneity and stability contributions:

$$u_{xpt\_def} = \sqrt{u_{hom}^2 + u_{stab}^2}$$

Where:
- $u_{hom} = s_s$ (between-sample standard deviation)
- $u_{stab} = 0$ if stability criterion met, else $D/\sqrt{3}$

**Derivation:**
```r
# From homogeneity study
u_hom <- ss  # calculate_homogeneity_stats()$ss

# From stability study
u_stab <- calculate_u_stab(diff_hom_stab, c_stab)

# Combined (for use in zeta-score)
u_xpt_def <- sqrt(u_hom^2 + u_stab^2)

# Use in zeta-score
zeta <- calculate_zeta_score(x, x_pt, u_x, u_xpt_def)
```

**Numerical Example:**
```r
# Scenario 1: Homogeneity and stability both excellent
u_hom <- 0.016
u_stab <- 0.000  # Stability criterion met
u_xpt_def <- sqrt(0.016^2 + 0.000^2)  # 0.016

# Scenario 2: Stability issue present
u_hom <- 0.016
u_stab <- 0.115  # Stability criterion not met
u_xpt_def <- sqrt(0.016^2 + 0.115^2)  # 0.116
```

### Impact on Scores

**Higher u_xpt → Lower |zeta| (more lenient)**

Because:
$$\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}}$$

If $u_{xpt}$ increases, denominator increases, making $|\zeta|$ smaller.

**Example:**
```r
x <- 10.5
x_pt <- 10.0
u_x <- 0.2

# Low assigned value uncertainty
u_xpt_1 <- 0.05
zeta_1 <- calculate_zeta_score(x, x_pt, u_x, u_xpt_1)  # 2.11 (Cuestionable)

# High assigned value uncertainty
u_xpt_2 <- 0.15
zeta_2 <- calculate_zeta_score(x, x_pt, u_x, u_xpt_2)  # 1.41 (Satisfactorio)
```

---

## Combined Classification (a1-a7)

### Classification Table

| Code | Label | z-score | En-score | U_x condition | Meaning |
|------|-------|----------|-----------|---------------|----------|
| a1 | Totalmente satisfactorio | ≤ 2 | < 1 | $U_x < 2\sigma_{pt}$ | Excellent performance |
| a2 | Satisfactorio pero conservador | ≤ 2 | < 1 | $U_x \geq 2\sigma_{pt}$ | Good, conservative uncertainty |
| a3 | Satisfactorio con MU subestimada | ≤ 2 | ≥ 1 | - | Good but uncertainty too small |
| a4 | Cuestionable pero aceptable | < 3 | < 1 | - | Questionable but compatible |
| a5 | Cuestionable e inconsistente | < 3 | ≥ 1 | - | Questionable and not compatible |
| a6 | No satisfactorio pero MU cubre la desviación | ≥ 3 | < 1 | - | Poor but uncertainty accounts for it |
| a7 | No satisfactorio (crítico) | ≥ 3 | ≥ 1 | - | Poor performance, not compatible |

### Special Codes

| Code | Label | Condition |
|------|-------|-----------|
| `mu_missing_z` | MU ausente - solo z: [performance] | Uncertainty missing, used z-score |
| `mu_missing_zprime` | MU ausente - solo z': [performance] | Uncertainty missing, used z'-score |
| `N/A` | N/A | Insufficient data for classification |

### Classification Function

```r
classify_with_en(
  score_val,    # z-score or z'-score
  en_val,       # En-score
  U_xi,         # Participant's expanded uncertainty
  sigma_pt,     # Target standard deviation
  mu_missing,   # TRUE if uncertainty missing
  score_label   # "z" or "z'"
)
```

**Returns:** List with `code` and `label`

**Example:**
```r
# Fully satisfactory
result1 <- classify_with_en(
  score_val = 1.5, en_val = 0.8, U_xi = 0.6,
  sigma_pt = 0.5, mu_missing = FALSE, score_label = "z"
)
result1$code   # "a1"
result1$label  # "a1 - Totalmente satisfactorio"

# Critical unsatisfactory
result2 <- classify_with_en(
  score_val = 3.5, en_val = 1.5, U_xi = 0.3,
  sigma_pt = 0.5, mu_missing = FALSE, score_label = "z"
)
result2$code   # "a7"
result2$label  # "a7 - No satisfactorio (crítico)"
```

---

## Visual Score Interpretation

### Z-Score Interpretation

```mermaid
xychart-beta
    title "Z-Score Performance Zones"
    x-axis "Deviation (x - x_pt)" [-3, -2, 0, 2, 3]
    y-axis "Performance" [0, 1]
    rect [-3, -2, 0, 1] "No satisfactorio"
    rect [-2, 2, 0, 1] "Satisfactorio"
    rect [2, 3, 0, 1] "Cuestionable"
    rect [3, 3, 0, 1] "No satisfactorio"
    rect [-3, -3, 0, 1] "No satisfactorio"
```

### Example Scenarios

| Scenario | x | x_pt | σ_pt | z | Performance | Interpretation |
|----------|----|----|------|----|------------|----------------|
| Good agreement | 10.1 | 10.0 | 0.5 | 0.2 | Satisfactorio |
| Slight bias | 10.3 | 10.0 | 0.5 | 0.6 | Satisfactorio |
| Questionable | 10.8 | 10.0 | 0.5 | 1.6 | Cuestionable |
| Poor agreement | 11.8 | 10.0 | 0.5 | 3.6 | No satisfactorio |
| Outlier | 15.0 | 10.0 | 0.5 | 10.0 | No satisfactorio |

### En-Score Interpretation

```mermaid
xychart-beta
    title "En-Score Performance Zones"
    x-axis "Deviation / Combined U" [-2, -1, 0, 1, 2]
    y-axis "Performance" [0, 1]
    rect [-2, -1, 0, 1] "No satisfactorio"
    rect [-1, 1, 0, 1] "Satisfactorio"
    rect [1, 2, 0, 1] "No satisfactorio"
    line [0, 0] "Assigned value"
```

---

## Color Palette Reference

### Classification Colors

| Code | Hex Color | Description |
|------|-----------|-------------|
| a1 | `#2E7D32` | Dark green (excellent) |
| a2 | `#66BB6A` | Medium green (good, conservative) |
| a3 | `#9CCC65` | Light green (good but MU low) |
| a4 | `#FFF59D` | Light yellow (acceptable) |
| a5 | `#FBC02D` | Orange (questionable) |
| a6 | `#EF9A9A` | Light red (poor) |
| a7 | `#C62828` | Dark red (critical) |
| `mu_missing_z` | `#90A4AE` | Blue (z-score only) |
| `mu_missing_zprime` | `#78909C` | Teal (z'-score only) |

### Heatmap Color Ranges

| Score Range | Color | Description |
|-------------|--------|-------------|
| |z| ≤ 2 | `#4CAF50` | Green (satisfactory) |
| 2 < |z| < 3 | `#FFC107` | Yellow (questionable) |
| |z| ≥ 3 | `#F44336` | Red (unsatisfactory) |
| |En| ≤ 1 | `#4CAF50` | Green (satisfactory) |
| |En| > 1 | `#F44336` | Red (unsatisfactory) |

---

## Complete Workflow Example

```r
library(ptcalc)

# Data
x <- 10.5              # Participant result
x_pt <- 10.0           # Assigned value
sigma_pt <- 0.5        # Target SD

# Uncertainties
u_x <- 0.2            # Participant's standard uncertainty
u_xpt <- 0.1           # Assigned value standard uncertainty
U_x <- 0.4            # Participant's expanded uncertainty (k=2)
U_xpt <- 0.2           # Assigned value expanded uncertainty (k=2)

# Calculate scores
z <- calculate_z_score(x, x_pt, sigma_pt)
zprime <- calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)
zeta <- calculate_zeta_score(x, x_pt, u_x, u_xpt)
en <- calculate_en_score(x, x_pt, U_x, U_xpt)

# Evaluate
cat("Results:\n")
cat(sprintf("z-score: %.2f - %s\n", z, evaluate_z_score(z)))
cat(sprintf("z'-score: %.2f - %s\n", zprime, evaluate_z_score(zprime)))
cat(sprintf("zeta-score: %.2f - %s\n", zeta, evaluate_z_score(zeta)))
cat(sprintf("En-score: %.2f - %s\n", en, evaluate_en_score(en)))

# Combined classification
classification <- classify_with_en(
  score_val = zprime,
  en_val = en,
  U_xi = U_x,
  sigma_pt = sigma_pt,
  mu_missing = FALSE,
  score_label = "z'"
)
cat(sprintf("Classification: %s\n", classification$label))

# Missing uncertainty case
classification_missing <- classify_with_en(
  score_val = z,
  en_val = en,
  U_xi = NA,
  sigma_pt = sigma_pt,
  mu_missing = TRUE,
  score_label = "z"
)
cat(sprintf("Missing MU: %s\n", classification_missing$label))
```

---

## References

- **ISO 13528:2022** Section 10.2 (z-scores)
- **ISO 13528:2022** Section 10.3 (z'-scores)
- **ISO 13528:2022** Section 10.4 (zeta-scores)
- **ISO 13528:2022** Section 10.5 (En-scores)
- **EURACHEM Guide** (2000) - Quantifying Uncertainty in Analytical Measurement

---

## Cross-References

- **Robust Statistics:** [03_pt_robust_stats.md](03_pt_robust_stats.md) - Robust mean/sd for x_pt
- **Homogeneity:** [04_pt_homogeneity.md](04_pt_homogeneity.md) - u_xpt_def calculation
- **Assigned Value:** [07_valor_asignado.md](cloned_docs/07_valor_asignado.md) - x_pt determination
- **Package Overview:** [02_ptcalc_package.md](cloned_docs/02_ptcalc_package.md) - General package documentation
