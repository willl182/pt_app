# Test script for robust_stats.R

source("R/robust_stats.R")

# Test Data (ISO 13528 Annex C example or similar synthetic data)
# Using a simple vector with an outlier
values <- c(10.1, 10.2, 10.3, 10.1, 10.2, 20.0, 10.2, 10.3)
ids <- paste0("Lab", 1:8)

cat("Testing calculate_niqr...\n")
niqr <- calculate_niqr(values)
cat("nIQR:", niqr, "\n")
if (is.na(niqr) || niqr <= 0) stop("nIQR failed")

cat("Testing run_algorithm_a...\n")
res <- run_algorithm_a(values, ids)

if (!is.null(res$error)) {
  stop(paste("Algorithm A failed:", res$error))
}

cat("Assigned Value (x*):", res$assigned_value, "\n")
cat("Robust SD (s*):", res$robust_sd, "\n")
cat("Converged:", res$converged, "\n")

# Expected behavior: The 20.0 outlier should be downweighted, so mean should be close to 10.2
if (abs(res$assigned_value - 10.2) > 0.5) {
  stop("Algorithm A did not handle outlier correctly. Mean is too high.")
}

cat("Test Passed!\n")
