# -----------------------------------------------------------------------------
# Validation Script: General Repository Checks
# -----------------------------------------------------------------------------
# Purpose:
#   * Ensure that all core PT data files exist before running week-specific
#     validations.
#   * Confirm that the expected columns are present in each CSV file.
#   * Collect a lightweight inventory of record counts that can be compared
#     against historical baselines.
#
# Usage:
#   Rscript -e "source('validation/scripts/validate_general_environment.R')"
# -----------------------------------------------------------------------------

validate_file_exists <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("Required file '%s' is missing.", path))
  }
  message(sprintf("[general] Found file: %s", path))
}

validate_columns <- function(path, expected_cols) {
  data <- read.csv(path, nrows = 1, check.names = FALSE)
  missing <- setdiff(expected_cols, names(data))
  if (length(missing) > 0) {
    stop(sprintf(
      "File '%s' is missing columns: %s",
      path,
      paste(missing, collapse = ", ")
    ))
  }
  message(sprintf("[general] Column structure OK for %s", path))
}

inventory_counts <- function(path) {
  data <- read.csv(path, check.names = FALSE)
  message(sprintf("[general] %s -> %d rows, %d columns", path, nrow(data), ncol(data)))
}

# -----------------------------------------------------------------------------
# Files grouped by purpose
# -----------------------------------------------------------------------------
raw_panels <- c('bsw_co.csv', 'bsw_no.csv', 'bsw_no2.csv', 'bsw_o3.csv', 'bsw_so2.csv')
summary_tables <- c('summary_n4.csv', 'summary_n7.csv', 'summary_n10.csv', 'summary_n13.csv')
auxiliary_tables <- c('homogeneity.csv', 'stability.csv', 'input_alg_a.csv')

expected_columns_raw <- c('source_file', 'level')
expected_columns_summary <- c('pollutant', 'level', 'participant_id', 'replicate', 'sample_group', 'mean_value', 'sd_value')
expected_columns_auxiliary <- c('pollutant', 'level', 'replicate', 'sample_id', 'value')

# -----------------------------------------------------------------------------
# 1. Check that every referenced file exists
# -----------------------------------------------------------------------------
for (path in c(raw_panels, summary_tables, auxiliary_tables)) {
  validate_file_exists(path)
}

# -----------------------------------------------------------------------------
# 2. Validate structural columns for each group
# -----------------------------------------------------------------------------
for (path in raw_panels) {
  validate_columns(path, expected_columns_raw)
}

for (path in summary_tables) {
  validate_columns(path, expected_columns_summary)
}

for (path in auxiliary_tables) {
  validate_columns(path, expected_columns_auxiliary)
}

# -----------------------------------------------------------------------------
# 3. Produce an inventory of record counts for regression testing
# -----------------------------------------------------------------------------
for (path in c(raw_panels, summary_tables, auxiliary_tables)) {
  inventory_counts(path)
}

message("[general] Validation checks completed successfully.")
