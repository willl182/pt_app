# Test script for homogeneity_stability.R

source("R/homogeneity_stability.R")
library(readr)

cat("Loading test data...\n")
hom_data <- read_csv("data/homogeneity.csv", show_col_types = FALSE)
stab_data <- read_csv("data/stability.csv", show_col_types = FALSE)

# Parameters for test
target_pollutant <- "co"
target_level <- "40-ppb"

cat(sprintf("Testing homogeneity for %s - %s...\n", target_pollutant, target_level))
hom_res <- compute_homogeneity_metrics(hom_data, target_pollutant, target_level)

if (!is.null(hom_res$error)) {
  stop(paste("Homogeneity calculation failed:", hom_res$error))
}

cat("Homogeneity ss:", hom_res$ss, "\n")
cat("Homogeneity critical value:", hom_res$c_criterion, "\n")
cat("Conclusion:", hom_res$conclusion, "\n")

if (hom_res$ss < 0) stop("ss cannot be negative (unless it's set to 0 when variance diff is negative, check logic)")
if (is.na(hom_res$sigma_pt)) stop("sigma_pt is NA")

cat("\nTesting stability for %s - %s...\n", target_pollutant, target_level)
stab_res <- compute_stability_metrics(stab_data, target_pollutant, target_level, hom_res)

if (!is.null(stab_res$error)) {
  stop(paste("Stability calculation failed:", stab_res$error))
}

cat("Stability Difference:", stab_res$diff_hom_stab, "\n")
cat("Stability critical value:", stab_res$stab_c_criterion, "\n")
cat("Conclusion:", stab_res$stab_conclusion, "\n")

if (stab_res$diff_hom_stab < 0) stop("Absolute difference cannot be negative")

cat("\nTests Passed!\n")
