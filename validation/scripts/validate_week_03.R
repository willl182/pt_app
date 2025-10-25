# -----------------------------------------------------------------------------
# Week 03 Validation Script: Advanced Calculation Inputs
# -----------------------------------------------------------------------------
# Objectives:
#   1. Cross-check that the homogeneity and Algorithm A inputs share the same
#      structure and value distributions.
#   2. Validate that stability measurements are confined to two replicates and
#      do not drift outside expected ranges relative to the other datasets.
#   3. Produce differential summaries between homogeneity.csv and
#      input_alg_a.csv to surface accidental edits.
#
# Usage:
#   Rscript -e "source('validation/scripts/validate_week_03.R')"
# -----------------------------------------------------------------------------

read_data <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("Dataset %s is missing", path))
  }
  read.csv(path, check.names = FALSE)
}

summarise_range <- function(values, label, field) {
  stats <- c(
    min = min(values, na.rm = TRUE),
    max = max(values, na.rm = TRUE),
    mean = mean(values, na.rm = TRUE)
  )
  message(sprintf(
    "[week03] %s %s -> min: %.6f, max: %.6f, mean: %.6f",
    label, field, stats['min'], stats['max'], stats['mean']
  ))
}

check_replicates <- function(data, label) {
  reps <- sort(unique(data$replicate))
  message(sprintf("[week03] %s replicates present: %s", label, paste(reps, collapse = ', ')))
  if (!all(reps %in% c(1, 2))) {
    warning(sprintf("[week03] Unexpected replicate found in %s", label))
  }
}

homogeneity <- read_data('homogeneity.csv')
stability <- read_data('stability.csv')
alg_a <- read_data('input_alg_a.csv')

# 1. Basic range and replicate checks
summarise_range(homogeneity$value, 'homogeneity.csv', 'value')
check_replicates(homogeneity, 'homogeneity.csv')

summarise_range(stability$value, 'stability.csv', 'value')
check_replicates(stability, 'stability.csv')

summarise_range(alg_a$value, 'input_alg_a.csv', 'value')
check_replicates(alg_a, 'input_alg_a.csv')

# 2. Differential comparison between homogeneity and Algorithm A inputs
shared_cols <- c('pollutant', 'level', 'replicate', 'sample_id')
merged <- merge(
  homogeneity,
  alg_a,
  by = shared_cols,
  suffixes = c('_hom', '_alg'),
  all = TRUE
)

if (nrow(merged) == 0) {
  warning("[week03] Merge between homogeneity and input_alg_a resulted in zero rows.")
} else {
  merged$delta <- merged$value_hom - merged$value_alg
  delta_abs <- abs(merged$delta)
  summarise_range(delta_abs, 'homogeneity vs input_alg_a', 'abs(delta)')
  inconsistent <- subset(merged, delta_abs > 1e-9)
  if (nrow(inconsistent) > 0) {
    warning(sprintf("[week03] %d records differ between homogeneity and input_alg_a", nrow(inconsistent)))
  } else {
    message("[week03] No differences detected between homogeneity and input_alg_a.")
  }
}

# 3. Compare stability against baseline distribution
stability_ranges <- aggregate(value ~ pollutant + level, data = stability, FUN = function(x) c(min = min(x), max = max(x)))
message("[week03] Stability min/max by pollutant-level computed for manual review.")
print(stability_ranges)

message("[week03] Week 03 validation completed.")
