The procedure for determining the homogeneity and stability of proficiency testing (PT) items must adhere to the requirements of ISO/IEC 17043:2023 and the detailed statistical guidance provided in **ISO 13528:2022**. The procedures described below use the Analysis of Variance (ANOVA) approach for homogeneity and mean comparison for stability, as detailed in Annex B of ISO 13528.

R is a statistical language well-suited for these calculations, leveraging functions for descriptive statistics, variance estimation, and hypothesis testing.

***

## Part 1: Homogeneity Assessment Procedure

Homogeneity assessment determines the standard uncertainty due to differences between PT items ($u_{hom}$ or $s_s$). This ensures that inhomogeneity does not adversely affect participant performance evaluation.

### A. Equations for Homogeneity (Based on ISO 13528 Annex B.3)

This procedure relies on decomposing the total variance into variance within samples ($s_w^2$) and variance between samples ($s_s^2$). We assume quantitative results are used.

1.  **PT Item Average ($\bar{x}_t$)**:
    $$\bar{x}_{t}=\frac{1}{m}\sum_{k=1}^{m}x_{t,k}$$
    Where $x_{t,k}$ is the result of replicate $k$ for PT item $t$, and $m$ is the number of replicates per item.

2.  **Within-Sample Variance ($s_t^2$)**:
    $$s_{t}^{2}=\frac{1}{(m-1)}\sum_{k=1}^{m}(x_{k}-\bar{x}_{t})^{2}$$

3.  **General Average ($\bar{x}$)**:
    $$\bar{x}=\frac{1}{g}\sum_{t=1}^{g}\bar{x}_{t}$$
    Where $g$ is the number of PT items tested.

4.  **Within-Sample Variance ($s_w^2$)** (Mean of replicate variances):
    $$s_{w}^{2}=\frac{1}{g}\sum_{t=1}^{g}s_{t}^{2}$$

5.  **Variance of Sample Averages ($s_{\bar{x}}^2$)**:
    $$s_{\bar{x}}^{2}=\frac{1}{(g-1)}\sum_{t=1}^{g}(\bar{x}_{t}-\bar{x})^{2}$$

6.  **Between-Sample Variance Estimate ($s_s^2$)**:
    $$s_{s}^{2}=s_{\bar{x}}^{2}-\frac{1}{m}s_{w}^{2}$$
    The between-sample standard deviation ($s_s$) is $s_s = \sqrt{s_s^2}$. If $s_s^2 < 0$, then $s_s^2$ is set to $0$.

### B. Steps for Homogeneity Assessment (Based on ISO 13528 Annex B.1 and B.2)

1.  **Preparation and Sampling:** Select a number $g$ of proficiency test items in their final packaged form, ideally $g > 10$ (though this number may be reduced if suitable data from previous checks are available). Prepare $m \ge 2$ test portions (replicates) from each selected PT item.
2.  **Measurement:** Obtain a measurement result ($x_{t,k}$) on each of the $g \times m$ test portions, measured in a random order under repeatability conditions. The method used must have a sufficiently small repeatability standard deviation ($s_r$), such that the ratio $s_r / \sigma_{pt} < 0.5$, or more replicates must be used.
3.  **Initial Data Validation (Visual Review/Outliers):**
    *   Examine results by order of measurement to check for trends (drift).
    *   Examine PT item averages by production order for serious trends.
    *   Compare differences between replicates and use Cochran’s test (ISO 5725-2) if necessary to identify statistically significant outliers among replicates.
4.  **Calculate $s_w$ and $s_s$:** Calculate the within-sample variance ($s_w^2$) and the between-sample variance ($s_s^2$) using the formulas in Section A.
5.  **Apply Criterion:** Compare the between-sample standard deviation ($s_s$) with the standard deviation for proficiency assessment ($\sigma_{pt}$). The items are considered adequately homogeneous if:
    $$s_{s} \le 0.3 \sigma_{pt}$$
    Alternatively, if the criterion is defined as the maximum permissible error $\delta_E$, the criterion is $s_{s} \le 0.1 \delta_E$.
6.  **Action on Failure:** If the criterion is not met, the provider must consider options such as including $s_s^2$ in the uncertainty of the assigned value or repeating preparation. If $\sigma_{pt}$ is unknown in advance, an ANOVA F-test at $\alpha=0.05$ may be used to check for statistically significant differences between items.

### C. R Code Implementation for Homogeneity Assessment

This implementation uses the base R function `aov()` (Analysis of Variance) for efficiency, which automatically calculates the necessary Sums of Squares required to derive $s_w^2$ and $s_s^2$.

```R
# Setup: Load necessary libraries (assuming data preparation uses base functions/standard packages)
library(dplyr) # Used for robust data manipulation
library(stats) # Contains aov(), mean(), sqrt(), etc.

# --- 1. Simulate Input Data ---
# Parameters (adjust as needed)
g <- 15          # Number of PT items sampled (ISO 13528 recommends g > 10)
m <- 3           # Number of replicates per item (m >= 2)
sigma_pt <- 10.0 # Standard deviation for proficiency assessment (sigma_pt)

# Simulate results with some random item-to-item variability (ss)
set.seed(42) 
item_base_mean <- 100
# Simulate 'between-sample' means (with a small SD of 0.5)
item_means <- rnorm(g, mean = item_base_mean, sd = 0.5)
# Simulate 'within-sample' noise (sw, assumed repeatability SD = 1.0)
results <- unlist(lapply(item_means, function(mu) rnorm(m, mean = mu, sd = 1.0))) 
hom_data <- data.frame(
  Result = results,
  Item = factor(rep(1:g, each = m))
)

# --- 2. Perform ANOVA to calculate variances ---
# Fit the linear model: Result is dependent on Item (One-way ANOVA)
anova_fit <- aov(Result ~ Item, data = hom_data)
anova_summary <- summary(anova_fit)

# Extract Mean Squares (MS) values from the ANOVA table
# MS_b = Mean Square Between Items (MS for 'Item' row)
MS_b <- anova_summary[]$`Mean Sq` 
# MS_w = Mean Square Within Items (MS for 'Residuals' row, equivalent to sw^2)
MS_w <- anova_summary[]$`Mean Sq` 
# Note: MS_w is the estimate of the within-sample variance (s_w^2)

# --- 3. Calculate Between-Sample Standard Deviation (ss) ---

# Calculate the estimated variance due to differences between samples (ss^2)
# Formula derivation based on expectations of MS in ANOVA: 
# E(MS_b) = m * s_s^2 + s_w^2 
# s_s^2 = (MS_b - MS_w) / m 
ss_sq <- max(0, (MS_b - MS_w) / m) 
ss <- sqrt(ss_sq)

# Calculate Within-Sample Standard Deviation (sw)
sw <- sqrt(MS_w)

cat(sprintf("Results based on g=%d items and m=%d replicates:\n", g, m))
cat(sprintf("Within-Sample SD (sw): %.3f\n", sw))
cat(sprintf("Between-Sample SD (ss): %.3f\n", ss))

# --- 4. Apply Assessment Criterion (ss <= 0.3 * sigma_pt) ---
hom_criterion_value <- 0.3 * sigma_pt

cat(sprintf("Criterion (0.3 * sigma_pt): %.3f\n", hom_criterion_value))

if (ss <= hom_criterion_value) {
  print("Conclusion: The PT items are sufficiently homogeneous (ss <= 0.3 * sigma_pt).")
} else {
  print("Conclusion: WARNING: The PT items are NOT sufficiently homogeneous.")
}

# Optional: Perform the F-test (alternative criterion)
F_value <- anova_summary[]$`F value`
p_value <- anova_summary[]$`Pr(>F)`
cat(sprintf("ANOVA F-test Result: F=%.3f, p-value=%.5f\n", F_value, p_value))
if (p_value < 0.05) {
    print("F-test suggests a statistically significant difference between item means (Potential inhomogeneity).")
}
```

***

## Part 2: Stability Assessment Procedure

Stability assessment ensures that the PT items do not undergo any significant change throughout the conduct of the PT round, including storage and transport. Stability is typically checked by comparing measurement results taken before distribution ($y_1$) and after the expected duration of the round ($y_2$).

### D. Equations for Stability (Based on ISO 13528 Annex B.5)

Stability assessment primarily involves comparing the mean values obtained at two different time points.

1.  **Mean Before Distribution ($y_1$) and Mean After Round ($y_2$)**:
    These are the grand averages of the measurements taken at Time 1 (before distribution) and Time 2 (after the round duration).

2.  **Primary Assessment Criterion (B.5.1)**:
    The proficiency test items are considered adequately stable if the absolute difference between the averages is less than a defined tolerance:
    $$\|y_{1} - y_{2}\| \le 0.3 \sigma_{pt} \text{ or } \le 0.1 \delta_E$$

3.  **Alternative Criterion including Uncertainty (B.5.2)**:
    If the measurement uncertainty contributes significantly, the criterion may be expanded:
    $$\lvert \bar{y}_{1} - \bar{y}_{2} \rvert \le 0.3\sigma_{pt} + 2\sqrt{u^{2}(\bar{y}_{1}) + u^{2}(\bar{y}_{2})}$$
    Where $u(\bar{y}_{1})$ and $u(\bar{y}_{2})$ are the standard uncertainties of the respective means (including measurement system variation and repeatability).

### E. Steps for Stability Assessment (Based on ISO 13528 Annex B.4 and B.5)

1.  **Preparation:** Select a number $2g$ of PT items randomly, where $g \ge 2$. Select one laboratory and a single measurement method with sufficiently small intermediate precision.
2.  **Measurement (Time 1):** Measure $g$ PT items (replicated measurements in random order) before the planned distribution date ($y_1$). Note that results from homogeneity testing may be used instead of a separate set of measurements.
3.  **Measurement (Time 2):** Store the remaining $g$ PT items for the typical duration of the PT round, simulating transport conditions if necessary. Measure these items after the duration ($y_2$).
4.  **Calculate Means:** Calculate the overall average results for $y_1$ and $y_2$.
5.  **Apply Criterion:** Compare the absolute difference ($\|y_1 - y_2\|$) to the criterion $0.3 \sigma_{pt}$.
6.  **Action on Failure/Alternative Test:** If the criterion is not met, the provider must quantify the effect of instability and potentially account for it in the evaluation (e.g., using $z$ scores). Alternatively, a **t-test** for significant difference between the two sets of data may be used, provided it offers equivalent assurance of detecting instability.

### F. R Code Implementation for Stability Assessment

This implementation uses the base R function `t.test()` as an alternative approach for determining if a statistically significant change has occurred, in addition to checking the primary criterion based on $\sigma_{pt}$.

```R
# Setup: Load necessary libraries
library(dplyr)
library(stats) 

# --- 1. Define Parameters and Simulate Stability Data ---
# Parameters (adjust as needed)
g_stab <- 5      # Number of items tested at each time point (g >= 2)
n_rep_stab <- 2  # Replicates per item/time point (m >= 1)
sigma_pt <- 10.0 # Standard deviation for proficiency assessment

# Intermediate precision/repeatability SD of measurement method
# Assumed to be low, e.g., 1.5
sd_method <- 1.5

# Simulate results (assuming no significant drift for this example)
mean_t1 <- 100
mean_t2 <- 100.5 # Example: small drift of 0.5 units
set.seed(123)
results_t1 <- rnorm(g_stab * n_rep_stab, mean = mean_t1, sd = sd_method)
results_t2 <- rnorm(g_stab * n_rep_stab, mean = mean_t2, sd = sd_method)

stab_data <- data.frame(
  Time = factor(rep(c("T1_Before", "T2_After"), each = g_stab * n_rep_stab)),
  Result = c(results_t1, results_t2)
)

# --- 2. Calculate Means and Observed Difference ---
y1 <- mean(stab_data$Result[stab_data$Time == "T1_Before"])
y2 <- mean(stab_data$Result[stab_data$Time == "T2_After"])
diff_observed <- abs(y1 - y2)

# --- 3. Apply Primary Assessment Criterion (B.5.1) ---
stab_criterion_value <- 0.3 * sigma_pt

cat(sprintf("Mean Before (y1): %.3f\n", y1))
cat(sprintf("Mean After (y2): %.3f\n", y2))
cat(sprintf("Observed Absolute Difference: %.3f\n", diff_observed))
cat(sprintf("Stability Criterion (0.3 * sigma_pt): %.3f\n", stab_criterion_value))

if (diff_observed <= stab_criterion_value) {
  print("Conclusion (Criterion B.5.1): PT Items are adequately stable.")
} else {
  print("Conclusion (Criterion B.5.1): WARNING: PT Items show unacceptable drift.")
  # Further investigation or use of expanded uncertainty criterion (B.5.2) needed
}

# --- 4. Alternative Statistical Test (T-test) ---
# A t-test checks if the means are statistically different at a certain confidence level (e.g., alpha=0.05).
# Using a two-sample t-test (Welch test is default in R, handling unequal variances).
t_test_result <- t.test(
  stab_data$Result[stab_data$Time == "T1_Before"], 
  stab_data$Result[stab_data$Time == "T2_After"]
)

cat("\n--- T-test Analysis (Alternative/Supporting Evidence) ---\n")
print(t_test_result)

if (t_test_result$p.value > 0.05) {
  print("Conclusion (T-test): No statistically significant difference detected (p > 0.05), indicating stability.")
} else {
  print("Conclusion (T-test): Statistically significant difference detected (p <= 0.05), indicating potential instability.")
}
```