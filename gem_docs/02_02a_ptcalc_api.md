# `ptcalc` API Reference

This document provides a comprehensive reference for all exported functions in the `ptcalc` package, organized by domain.

## 1. Robust Statistics (`pt_robust_stats.R`)

### `run_algorithm_a(values, ids = NULL, max_iter = 50, tol = 1e-03)`
Computes robust estimates of location ($x^*$) and scale ($s^*$) using ISO 13528 Algorithm A.

*   **Inputs:**
    *   `values`: Numeric vector of results.
    *   `ids`: Optional vector of identifiers.
    *   `max_iter`: Max iterations (default 50).
    *   `tol`: Convergence tolerance (default 0.001).
*   **Returns:** List (`assigned_value`, `robust_sd`, `weights`, `converged`, etc.).
*   **Example:**
    ```r
    res <- run_algorithm_a(c(10, 10.1, 9.9, 100)) # 100 is outlier
    print(res$assigned_value) # ~10.0
    ```

### `calculate_mad_e(x)`
Calculates Scaled Median Absolute Deviation ($1.483 \times MAD$).
*   **Inputs:** Numeric vector.
*   **Returns:** Numeric value (robust SD).

### `calculate_niqr(x)`
Calculates Normalized Interquartile Range ($0.7413 \times IQR$).
*   **Inputs:** Numeric vector.
*   **Returns:** Numeric value.

---

## 2. Homogeneity & Stability (`pt_homogeneity.R`)

### `calculate_homogeneity_stats(sample_data)`
Performs ANOVA to extract variance components.
*   **Inputs:** Matrix or Dataframe (rows=items, cols=replicates).
*   **Returns:** List (`ss`, `sw`, `grand_mean`, `s_xt`, `g`, `m`).
*   **Error:** Returns list with `$error` string if dimensions < 2x2.

### `calculate_homogeneity_criterion(sigma_pt)`
Returns the standard criterion limit.
*   **Formula:** $0.3 \times \sigma_{pt}$

### `evaluate_homogeneity(ss, c_criterion, c_expanded)`
Evaluates the ANOVA results against criteria.
*   **Returns:** Character string (Conclusion).

### `calculate_stability_stats(stab_sample_data, hom_grand_mean)`
Computes stability metrics compared to homogeneity baseline.
*   **Returns:** List including `diff_hom_stab` (difference in means).

---

## 3. Scoring (`pt_scores.R`)

### `calculate_z_score(x, x_pt, sigma_pt)`
*   **Returns:** $z = (x - x_{pt}) / \sigma_{pt}$

### `calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)`
*   **Returns:** $z' = (x - x_{pt}) / \sqrt{\sigma_{pt}^2 + u_{xpt}^2}$

### `calculate_zeta_score(x, x_pt, u_x, u_xpt)`
*   **Returns:** $\zeta = (x - x_{pt}) / \sqrt{u_x^2 + u_{xpt}^2}$

### `calculate_en_score(x, x_pt, U_x, U_xpt)`
*   **Returns:** $E_n = (x - x_{pt}) / \sqrt{U_x^2 + U_{xpt}^2}$

### `evaluate_z_score(z)` / `evaluate_z_score_vec(z)`
Classifies a score or vector of scores.
*   **Returns:** "Satisfactory" ($|z|\le2$), "Questionable" ($2<|z|<3$), or "Unsatisfactory" ($|z|\ge3$).

### `classify_with_en(...)`
Combines $z'$ and $E_n$ to return a classification code (`a1`-`a7`).
*   **Inputs:** `score_val`, `en_val`.
*   **Returns:** String code (e.g., "a1").
