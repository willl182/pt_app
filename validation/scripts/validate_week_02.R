# -----------------------------------------------------------------------------
# Week 02 Validation Script: Summary Table Consistency
# -----------------------------------------------------------------------------
# Objectives:
#   1. Verify that participant counts in summary tables match expectations for
#      each PT scenario (n = 4, 7, 10, 13).
#   2. Ensure sample group buckets (1-10, 11-20, 21-30) are present and
#      correctly populated for every pollutant and level combination.
#   3. Produce descriptive statistics for mean_value and sd_value to spot
#      outliers or unexpected drifts across PT rounds.
#
# Usage:
#   Rscript -e "source('validation/scripts/validate_week_02.R')"
# -----------------------------------------------------------------------------

summary_files <- list(
  n4 = list(path = 'summary_n4.csv', expected_participants = 4),
  n7 = list(path = 'summary_n7.csv', expected_participants = 7),
  n10 = list(path = 'summary_n10.csv', expected_participants = 10),
  n13 = list(path = 'summary_n13.csv', expected_participants = 13)
)

expected_groups <- c('1-10', '11-20', '21-30')

check_participants <- function(data, expected, label) {
  participants <- unique(data$participant_id)
  actual <- length(participants)
  if (actual != expected) {
    warning(sprintf(
      "[week02] %s expected %d participants but found %d",
      label, expected, actual
    ))
  } else {
    message(sprintf("[week02] %s participant count OK (%d)", label, actual))
  }
}

check_groups <- function(data, label) {
  missing_groups <- setdiff(expected_groups, unique(data$sample_group))
  if (length(missing_groups) > 0) {
    warning(sprintf(
      "[week02] %s missing sample groups: %s",
      label,
      paste(missing_groups, collapse = ', ')
    ))
  } else {
    message(sprintf("[week02] %s sample groups complete", label))
  }
}

summarise_numeric <- function(values, label, field) {
  stats <- c(
    min = min(values, na.rm = TRUE),
    max = max(values, na.rm = TRUE),
    mean = mean(values, na.rm = TRUE)
  )
  message(sprintf("[week02] %s %s summary -> min: %.6f, max: %.6f, mean: %.6f",
    label, field, stats['min'], stats['max'], stats['mean']))
}

for (name in names(summary_files)) {
  config <- summary_files[[name]]
  path <- config$path
  expected <- config$expected_participants
  if (!file.exists(path)) {
    stop(sprintf("Summary dataset %s is missing", path))
  }
  data <- read.csv(path, check.names = FALSE)
  label <- sprintf("%s (%s)", path, name)
  message(sprintf("[week02] ---- %s ----", label))
  check_participants(data, expected, label)
  check_groups(data, label)
  summarise_numeric(data$mean_value, label, 'mean_value')
  summarise_numeric(data$sd_value, label, 'sd_value')
}

message("[week02] Summary table validation completed.")
