# Homogeneity and Stability Assessment

## 1. Overview
This module evaluates whether the proficiency test items (samples) are sufficiently homogeneous and stable to be used in the scheme, following ISO 13528:2022 guidelines.

**File:** `ptcalc/R/pt_homogeneity.R`

---

## 2. Homogeneity Analysis (ANOVA)

We use a one-way Analysis of Variance (ANOVA) to separate the total variation into "between-sample" ($s_s$) and "within-sample" ($s_w$) components.

### 2.1 ANOVA Table Construction
Given $g$ samples (items) measured in $m$ replicates (usually $m=2$).

| Source of Variation | Degrees of Freedom (DF) | Sum of Squares (SS) | Mean Squares (MS) | Expectation |
|:---|:---|:---|:---|:---|
| **Between Samples** | $g - 1$ | $SS_{between} = m \sum (\bar{x}_i - \bar{\bar{x}})^2$ | $MS_{between} = SS_{between} / (g-1)$ | $s_w^2 + m \cdot s_s^2$ |
| **Within Samples** | $g(m - 1)$ | $SS_{within} = \sum \sum (x_{ij} - \bar{x}_i)^2$ | $MS_{within} = SS_{within} / (g(m-1))$ | $s_w^2$ |
| **Total** | $gm - 1$ | | | |

### 2.2 Variance Components Derivation

1.  **Within-sample standard deviation ($s_w$):**
    $$s_w = \sqrt{MS_{within}}$$
    *Simplified for m=2:* $s_w = \sqrt{\sum w_t^2 / (2g)}$ where $w_t$ is the range of replicates for item $t$.

2.  **Between-sample standard deviation ($s_s$):**
    The estimate is derived by subtracting the within-sample variance contribution from the between-sample mean square.
    $$s_s = \sqrt{\max(0, \frac{MS_{between} - MS_{within}}{m})}$$
    *Note: If $MS_{between} < MS_{within}$, the estimate is 0.*

---

## 3. ISO 13528 Assessment Criteria

To pass homogeneity, the between-sample variance ($s_s$) must be small relative to the standard deviation for proficiency assessment ($\sigma_{pt}$).

### 3.1 Criteria Formulas

1.  **Standard Criterion ($c$):**
    $$c = 0.3 \times \sigma_{pt}$$
    If $s_s \le c$, the items are homogeneous.

2.  **Expanded Criterion ($c'$ or `c_expanded`):**
    Used when $s_s > c$ but the measurement method variance ($s_w$) is high, making it hard to distinguish sample differences from method noise.
    $$c' = \sqrt{c^2 + 1.88 \cdot s_w^2}$$
    *Note: The factor 1.88 varies based on $g, m$, but is often approximated or calculated using $\chi^2$ tables in the app.*

### 3.2 Decision Tree

```mermaid
graph TD
    A[Start Evaluation] --> B{s_s <= c?}
    B -- Yes --> C[PASS: Homogeneous]
    B -- No --> D{s_s <= c_expanded?}
    D -- Yes --> E[PASS: Homogeneous (conditionally)]
    D -- No --> F[FAIL: Not Homogeneous]
    
    style C fill:#d4edda,stroke:#28a745
    style E fill:#fff3cd,stroke:#ffc107
    style F fill:#f8d7da,stroke:#dc3545
```

### 3.3 Numerical Example
*   $\sigma_{pt} = 0.1$
*   $s_s = 0.04$
*   $s_w = 0.02$

1.  Calculate $c$: $0.3 \times 0.1 = 0.03$.
2.  Check: Is $0.04 \le 0.03$? **No.**
3.  Calculate $c'$: $\sqrt{0.03^2 + 1.88(0.02^2)} = \sqrt{0.0009 + 0.000752} = \sqrt{0.001652} \approx 0.0406$.
4.  Check: Is $0.04 \le 0.0406$? **Yes.**
5.  **Result:** PASS (using expanded criterion).

---

## 4. Stability Assessment

Stability checks if the samples changed during the proficiency testing period.

### 4.1 Stability Check
We compare the general mean of homogeneity samples ($\bar{y}_{hom}$) with the mean of stability samples ($\bar{y}_{stab}$).
$$| \bar{y}_{hom} - \bar{y}_{stab} | \le 0.3 \times \sigma_{pt} + 2 u(\bar{y}_{hom})$$
*(Simplified check often used: difference should be small relative to $\sigma_{pt}$)*

### 4.2 Uncertainty Calculations
The app calculates uncertainties associated with the material characterization.

*   **Uncertainty of Homogeneity ($u_{hom}$):**
    $$u_{hom} = s_s$$
    
*   **Uncertainty of Stability ($u_{stab}$):**
    $$u_{stab} = \sqrt{u(\bar{y}_{stab})^2 + u(\bar{y}_{hom})^2}$$
    Often estimated conservatively as the difference itself if significant, or 0 if negligible.

*   **Combined Uncertainty ($u_{char}$):**
    $$u_{char} = \sqrt{u_{hom}^2 + u_{stab}^2}$$
    This contributes to the uncertainty of the assigned value ($u_{xpt}$).
