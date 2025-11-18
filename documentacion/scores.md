This detailed R script is designed to calculate the proficiency scores $z$, $z'$, $\zeta$ (zeta), and $E_n$-scores based on the formulas presented in the sources, particularly referencing ISO 13528 and ISO/IEC 17043 guidelines for proficiency testing (PT).

Since the input data structure (participant results, assigned values, and uncertainties) is necessary but was not explicitly provided, the script includes a preliminary section to create simulated data for demonstration, consistent with the simulation approach seen in the provided PT data analysis excerpts.

### R Script for Proficiency Score Calculation

The calculations rely on defining variables for the participant's result ($x_i$), the assigned value ($x_{pt}$), the standard deviation for proficiency assessment ($\sigma_{pt}$), and the standard uncertainties of both the participant's result ($u(x_i)$) and the assigned value ($u(x_{pt})$).

```R
# -----------------------------------------------------------------------------
# R Script to Calculate Proficiency Scores: z, z', zeta, and En-scores
# Calculations adhere to formulas found in ISO 13528/ISO Guide 43-1.
# -----------------------------------------------------------------------------

# 1. Load necessary library (for data manipulation/piping)
# The 'dplyr' package is part of the tidyverse suite.
library(dplyr)

# 2. Define or Simulate Input Data

# --- Parameters determined during the PT analysis ---
# In a real scenario, these would be calculated or assigned (e.g., using robust methods like median/MAD)

x_pt <- 100.0  # Assigned Value (X or x_pt)
sigma_pt_robust <- 5.0 # Robust standard deviation for proficiency assessment (sigma_pt)
u_xpt <- 0.5   # Standard Uncertainty of the Assigned Value (u_X or u(x_pt))

# Note: For simplicity and following the example in the sources, 
# we use the robust/adjusted sigma_pt as the final denominator in the z-score/z'-score calculations.
sigma_pt_adjusted <- sigma_pt_robust # Assuming ss (inhomogeneity) is negligible or already incorporated

# --- Simulated Participant Data (10 laboratories) ---

participant_data <- data.frame(
  lab_id = paste0("LAB", 1:10),
  # Participant Result (xi)
  result = c(98.5, 102.1, 107.0, 95.5, 100.0, 103.5, 99.1, 101.4, 94.0, 105.9),
  # Participant Standard Uncertainty (u(xi) or u_x). Must be reported by NRLs.
  uncertainty_std = c(1.5, 2.0, 1.8, 1.0, 2.5, 1.4, 1.6, 1.9, 1.5, 2.2) 
)

# 3. Calculate Performance Scores using dplyr::mutate()

final_scores <- participant_data %>%
  mutate(
    # --- z-Score ---
    # Formula (14): zi = (xi - xpt) / sigma_pt
    # Interpretation: |z| <= 2 satisfactory, 2 < |z| < 3 questionable, |z| >= 3 unsatisfactory
    z_score = (result - x_pt) / sigma_pt_adjusted,
    
    # --- z'-Score ---
    # Formula (15): z'i = (xi - xpt) / sqrt(sigma_pt^2 + u(x_pt)^2)
    # Used when u(x_pt) is considered not negligible.
    z_prime_score = (result - x_pt) / sqrt(sigma_pt_adjusted^2 + u_xpt^2),
    
    # --- Zeta Score (ζ) ---
    # Formula (19): ζi = (xi - xpt) / sqrt(u(x_i)^2 + u(x_pt)^2)
    # Evaluates result agreement relative to combined standard uncertainties.
    zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
    
    # --- En-Score ---
    # Formula (20): En,i = (xi - xpt) / sqrt(U(x_i)^2 + U(x_pt)^2)
    # Uses Expanded Uncertainties (U = k*u). We use k=2 (a common coverage factor).
    # Interpretation: |En| <= 1 satisfactory, |En| > 1 action signal.
    
    # First, calculate Expanded Uncertainties (k=2)
    U_xi = 2 * uncertainty_std,
    U_xpt = 2 * u_xpt,
    
    En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
  )

# 4. Display Results

cat("--- Proficiency Score Calculation Results ---\n")
cat(sprintf("Assigned Value (x_pt): %.2f\n", x_pt))
cat(sprintf("Standard Deviation for PT (sigma_pt_adj): %.2f\n", sigma_pt_adjusted))
cat(sprintf("Standard Uncertainty of Assigned Value (u_xpt): %.2f\n", u_xpt))
cat(sprintf("Coverage Factor (k) used for En-score: 2\n\n"))

print(select(final_scores, lab_id, result, uncertainty_std, z_score, z_prime_score, zeta_score, En_score))

# -----------------------------------------------------------------------------
```

### Detailed Explanation of Proficiency Scores and Formulas

The proficiency scores requested are standard metrics used in interlaboratory comparisons (ILCs) and proficiency testing (PT) schemes, primarily guided by the statistical methods detailed in ISO 13528.

#### 1. $z$-Score

The **$z$-score** standardizes the deviation of a participant's result ($x_i$) from the assigned value ($x_{pt}$) using the standard deviation for proficiency assessment ($\sigma_{pt}$).

*   **Formula:** $z_{i} = \frac{x_{i}-x_{pt}}{\sigma_{pt}}$
*   **Purpose:** The traditional $z$-score evaluates performance relative to a defined target level of acceptable variation ($\sigma_{pt}$). This $\sigma_{pt}$ may be derived from fitness-for-purpose criteria or historical data.
*   **Assessment Criteria:** Results where $|\mathbf{z}| \le 2.0$ are designated satisfactory, $2.0 < |z| < 3.0$ are questionable (warning signal), and $|z| \ge 3.0$ are unsatisfactory (action signal). These limits are justified based on the assumption that competent laboratories' results are normally distributed relative to $\sigma_{pt}$.

#### 2. $z'$-Score (z-prime score)

The **$z'$-score** is a modification of the $z$-score that explicitly accounts for the measurement uncertainty associated with the assigned value ($u(x_{pt})$) in the denominator.

*   **Formula:** ${z_{i}}^{\prime}=\frac{x_{i}-x_{pt}}{\sqrt{{\sigma_{pt}}^{2}+u^{2}(x_{pt})}}$
*   **Purpose:** It is used when the standard uncertainty of the assigned value, $u(x_{pt})$, is considered *not* negligible, typically if $u(x_{pt}) > 0.3 \sigma_{pt}$. Including $u(x_{pt})$ prevents participants from receiving adverse scores due to uncertainty in the reference value itself.
*   **Assessment Criteria:** The assessment criteria for $z'$-scores are typically the same as for $z$-scores ($\pm 2.0$ and $\pm 3.0$).

#### 3. Zeta Score ($\zeta$)

The **zeta score** standardizes the deviation relative to the combined **standard uncertainties** of both the participant's result ($u(x_i)$) and the assigned value ($u(x_{pt})$).

*   **Formula:** $\zeta_{i}=\frac{x_{i}-x_{pt}}{\sqrt{u^{2}(x_{i})+u^{2}(x_{pt})}}$
*   **Purpose:** The $\zeta$ score evaluates whether the participant's result and the assigned value agree within their combined standard uncertainties. This provides a rigorous assessment of the participant's result *and* their claimed uncertainty. An adverse $\zeta$ score (e.g., $|\zeta| > 3$) may indicate bias in the measurement method or an underestimate of the participant's stated uncertainty.
*   **Assessment Criteria:** Often interpreted using the same conventions as the $z$-score ($\pm 2.0$ and $\pm 3.0$).

#### 4. $E_n$-Score

The **$E_n$-score** (Error, normalized) is similar to the $\zeta$ score but utilizes **expanded uncertainties** ($U(x_i)$ and $U(x_{pt})$) instead of standard uncertainties.

*   **Formula:** $E_{n,i}=\frac{x_{i}-x_{pt}}{\sqrt{U^{2}(x_{i})+U^{2}(x_{pt})}}$
*   **Purpose:** This score is conventional for proficiency testing in calibration, but applicable elsewhere, and evaluates if the difference between results remains within the participants' claimed expanded uncertainties and the expanded uncertainty of the assigned value.
*   **Uncertainty Input:** This score requires participants and the PT provider to supply results along with their **expanded measurement uncertainty** ($U$). Expanded uncertainty typically requires multiplying the standard uncertainty ($u$) by a coverage factor ($k$), usually $k=2$ for approximately 95% confidence.
*   **Assessment Criteria:** The conventional assessment criteria are stringent: results are acceptable if $|\mathbf{E}_{\mathbf{n}}| \le 1.0$. A value exceeding 1.0 indicates that the difference between the results is greater than the combined expanded uncertainty, suggesting a possible issue with the measurement or the uncertainty estimation.
