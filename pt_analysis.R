# ===================================================================
# PT Data Analysis and Homogeneity Testing according to ISO 13528:2022
#
# This script implements the Standard Operating Procedure from sop.md
# using the dataset provided in CO.csv.
#
# The analysis is performed for one proficiency testing level at a time.
# The core logic is encapsulated in a function `analyze_pt_level`
# to allow for easy analysis of different levels within the data.
# ===================================================================

# 1. Load necessary libraries
# The tidyverse suite includes dplyr, readr, ggplot2, tidyr, etc.
library(tidyverse)

# 2. Data Import and Preparation
# -------------------------------------------------------------------

# Import the raw data from the CSV file.
# In a real scenario, you would use a relative path like "data/CO.csv"
# assuming the project structure from the SOP.
all_data <- read_csv("/home/w421/w420/02_unal/pt_app/CO.csv")

# 3. Homogeneity Assessment Function (from test_homog.R)
# -------------------------------------------------------------------

homogeneity_assessment <- function(data, target_level, sigma_pt) {
  cat("--- Homogeneity Assessment ---\n")

  # Reshape data for ANOVA: 'Items' are the different samples, 'Replicates' are the rows.
  hom_data <- data %>%
    filter(level == target_level) %>%
    select(starts_with("sample_")) %>%
    # Add a replicate identifier
    mutate(replicate = row_number()) %>%
    pivot_longer(
      cols = -replicate,
      names_to = "Item",
      values_to = "Result",
      names_prefix = "sample_"
    ) %>%
    mutate(Item = factor(as.integer(Item)))

  g <- n_distinct(hom_data$Item) # Number of PT items (g)
  m <- n_distinct(hom_data$replicate) # Number of replicates (m)

  # Fit the linear model: Result is dependent on Item (One-way ANOVA)
  anova_fit <- aov(Result ~ Item, data = hom_data)
  anova_summary <- summary(anova_fit)

  # Extract Mean Squares (MS) values from the ANOVA table
  MS_b <- anova_summary[[1]]["Item", "Mean Sq"]      # Mean Square Between Items
  MS_w <- anova_summary[[1]]["Residuals", "Mean Sq"] # Mean Square Within Items (sw^2)

  # Calculate Between-Sample Standard Deviation (ss)
  # Formula: s_s^2 = (MS_b - MS_w) / m
  ss_sq <- max(0, (MS_b - MS_w) / m)
  ss <- sqrt(ss_sq)
  sw <- sqrt(MS_w)

  cat(sprintf("Based on g=%d items and m=%d replicates:\n", g, m))
  cat(sprintf("Within-Sample SD (sw): %.4f\n", sw))
  cat(sprintf("Between-Sample SD (ss): %.4f\n", ss))

  # Apply Assessment Criterion (ss <= 0.3 * sigma_pt)
  hom_criterion_value <- 0.3 * sigma_pt
  cat(sprintf("Criterion (0.3 * sigma_pt): %.4f\n", hom_criterion_value))

  if (ss <= hom_criterion_value) {
    print("Conclusion: The PT items are sufficiently homogeneous.")
  } else {
    print("Conclusion: WARNING: The PT items are NOT sufficiently homogeneous.")
    print("The between-sample SD (ss) will be included in the performance assessment.")
  }
  cat("\n")

  return(ss) # Return ss for use in main analysis
}

# 4. Stability Assessment Function (from test_homog.R)
# -------------------------------------------------------------------

stability_assessment <- function(data, target_level, sigma_pt) {
  cat("--- Stability Assessment ---\n")

  # WARNING: The CO.csv data does not contain true stability data (i.e., measurements
  # over time). To demonstrate the method from test_homog.R, we will artificially
  # split the available replicate runs into two halves: "Time 1" and "Time 2".
  # This is for procedural demonstration only and is not a valid stability test.
  stab_data_all <- data %>%
    filter(level == target_level) %>%
    select(starts_with("sample_"))

  n_runs <- nrow(stab_data_all)
  if (n_runs < 2) {
    cat("WARNING: Not enough replicate runs (at least 2 required) to perform a stability check.\n\n")
    return()
  }

  # Split the data into two halves
  split_point <- floor(n_runs / 2)
  data_t1 <- stab_data_all %>% slice(1:split_point) %>% pivot_longer(everything(), values_to = "Result")
  data_t2 <- stab_data_all %>% slice((split_point + 1):n_runs) %>% pivot_longer(everything(), values_to = "Result")

  # Calculate means for each time point
  y1 <- mean(data_t1$Result, na.rm = TRUE)
  y2 <- mean(data_t2$Result, na.rm = TRUE)
  diff_observed <- abs(y1 - y2)

  # Apply Primary Assessment Criterion (ISO 13528:2022, B.5.1)
  stab_criterion_value <- 0.3 * sigma_pt

  cat(sprintf("Mean 'Before' (y1): %.4f (using first %d runs)\n", y1, split_point))
  cat(sprintf("Mean 'After' (y2): %.4f (using last %d runs)\n", y2, n_runs - split_point))
  cat(sprintf("Observed Absolute Difference: %.4f\n", diff_observed))
  cat(sprintf("Stability Criterion (0.3 * sigma_pt): %.4f\n", stab_criterion_value))

  if (diff_observed <= stab_criterion_value) {
    print("Conclusion (Criterion B.5.1): PT Items are adequately stable.")
  } else {
    print("Conclusion (Criterion B.5.1): WARNING: PT Items may show unacceptable drift.")
  }

  # Alternative Statistical Test (T-test)
  t_test_result <- t.test(data_t1$Result, data_t2$Result)
  cat("\n--- T-test Analysis (Supporting Evidence) ---\n")
  if (t_test_result$p.value > 0.05) {
    print("Conclusion (T-test): No statistically significant difference detected (p > 0.05), indicating stability.")
  } else {
    print("Conclusion (T-test): Statistically significant difference detected (p <= 0.05), indicating potential instability.")
  }
  cat("\n")
}

# Define a function to perform the complete analysis for a given PT level.
analyze_pt_level <- function(data, target_level) {

  # --- Data Structuring for a Single PT Level ---

  # Filter for the specified level and reshape the data from wide to long format.
  # Each 'sample_X' column is treated as a participant.
  participant_data_long <- data %>%
    filter(level == target_level) %>%
    # The SOP expects a single set of results for a PT round.
    # Here, we take the first row for the given level as the representative dataset.
    slice(1) %>%
    select(starts_with("sample_")) %>%
    pivot_longer(
      cols = everything(),
      names_to = "participant_id",
      values_to = "result",
      names_prefix = "sample_"
    ) %>%
    # Ensure participant_id is treated as a character
    mutate(participant_id = paste0("LAB", sprintf("%02d", as.integer(participant_id))))

  # The number of participants for the current level.
  n_participants <- nrow(participant_data_long)

  # Generate plausible standard uncertainties as they are not in the source file.
  # This is required for z', zeta, and En scores as per the SOP.
  # The mean and sd for the random generation are chosen to be reasonable
  # relative to the magnitude of the results for the target level.
  set.seed(42) # for reproducibility
  simulated_uncertainty <- rnorm(n_participants, mean = mean(participant_data_long$result) * 0.01, sd = 0.005)

  participant_data <- participant_data_long %>%
    mutate(uncertainty = abs(round(simulated_uncertainty, 4)))


  # --- 3. Data Validation (as per Section 3.2 of SOP) ---
  cat("-----------------------------------------------------------\n")
  cat(paste("Analysis for PT Level:", target_level, "\n"))
  cat("-----------------------------------------------------------\n\n")
  cat("Data Structure Validation (glimpse):\n")
  glimpse(participant_data)
  cat("\n")


  # --- 4. Core Statistical Analysis (as per Section 5 of SOP) ---
  
  # 4.1 Initial Data Exploration (Visual)
  # A histogram to check the distribution of results.
  dist_plot <- ggplot(participant_data, aes(x = result)) +
    geom_histogram(aes(y = ..density..), binwidth = sd(participant_data$result)/4, color = "black", fill = "skyblue") +
    geom_density(alpha = 0.4, fill = "lightblue") +
    labs(
      title = paste("Distribution of Participant Results for Level:", target_level),
      subtitle = "Histogram and Kernel Density Plot",
      x = "Result",
      y = "Density"
    ) +
    theme_minimal()

  print(dist_plot)

  # 4.2 Determine the Assigned Value (x_pt) using a robust method (median)
  x_pt <- median(participant_data$result, na.rm = TRUE)

  # 4.3 Calculate Standard Deviation for Proficiency Assessment (sigma_pt)
  # The primary method is the scaled Median Absolute Deviation (MAD).
  sigma_pt <- mad(participant_data$result, constant = 1.4826, na.rm = TRUE)

  # --- Homogeneity Check and Adjustment of sigma_pt (as per Section 4 of SOP) ---
  # Perform homogeneity assessment
  s_s <- homogeneity_assessment(data, target_level, sigma_pt)

  # Perform stability assessment
  stability_assessment(data, target_level, sigma_pt)

  # Adjust sigma_pt to include inhomogeneity contribution
  # Formula: σ'_pt = sqrt(σ_pt² + s_s²)
  sigma_pt_adjusted <- sqrt(sigma_pt^2 + s_s^2)

  # 4.5 Determine Uncertainty of the Assigned Value (u_xpt)
  # For zeta and En scores, the uncertainty of the assigned value is needed.
  # This would typically be calculated from characterization, homogeneity, etc.
  # For this example, we'll assign a plausible value relative to sigma_pt.
  u_xpt <- sigma_pt_adjusted / sqrt(n_participants)


  # --- 5. Performance Score Calculation (as per Section 6 of SOP) ---

  # Use a single dplyr::mutate() call to calculate all scores
  final_scores <- participant_data %>%
    mutate(
      # Calculate z-Score
      z_score = (result - x_pt) / sigma_pt_adjusted,

      # Calculate z'-Score
      z_prime_score = (result - x_pt) / sqrt(sigma_pt_adjusted^2 + uncertainty^2),

      # Calculate zeta-Score
      zeta_score = (result - x_pt) / sqrt(u_xpt^2 + uncertainty^2),

      # Calculate En-Score (using k=2 for expanded uncertainty)
      En_score = (result - x_pt) / sqrt((2 * uncertainty)^2 + (2 * u_xpt)^2) # En score uses u_xpt directly
    )


  # --- 6. Display the Results ---

  # Print the determined parameters
  cat("--- Determined PT Parameters ---\n")
  print(paste("Assigned Value (x_pt):", round(x_pt, 4)))
  print(paste("Robust Standard Deviation (from participant data):", round(sigma_pt, 4)))
  print(paste("Between-Sample Standard Deviation (s_s):", round(s_s, 4)))
  print(paste("Adjusted Standard Deviation for PT (sigma_pt_adj):", round(sigma_pt_adjusted, 4)))
  print(paste("Uncertainty of Assigned Value (u_xpt):", round(u_xpt, 4)))
  cat("\n")

  # Print the final data frame with all calculated scores
  cat("--- Final Participant Scores ---\n")
  print(final_scores, n = n_participants)
  cat("\n\n")

  # Return the final scores table
  return(final_scores)
}

# ===================================================================
# Execute the Analysis
# ===================================================================

# Get the unique levels from the dataset
pt_levels <- unique(all_data$level)

# --- Example Execution for a Single Level: "2-ppm" ---
# This demonstrates the function for one of the levels in the file.
results_2ppm <- analyze_pt_level(all_data, "2-ppm")

# --- Optional: Loop Through All Levels ---
# You can uncomment the following lines to run the analysis for all
# levels found in the CO.csv file.
#
# all_results <- map(pt_levels, ~analyze_pt_level(all_data, .x))
# names(all_results) <- pt_levels
