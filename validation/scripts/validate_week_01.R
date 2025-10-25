# -----------------------------------------------------------------------------
# Week 01 Validation Script: Raw Panel Integrity
# -----------------------------------------------------------------------------
# Objectives:
#   1. Confirm there are no missing values or obvious structural gaps in the
#      BSW panel datasets.
#   2. Flag duplicate level entries per source file to highlight potential
#      copy/paste errors when curating raw measurements.
#   3. Generate range summaries for each numeric column so auditors can
#      compare min/max values week over week.
#
# Usage:
#   Rscript -e "source('validation/scripts/validate_week_01.R')"
# -----------------------------------------------------------------------------

raw_files <- list(
  bsw_co = 'bsw_co.csv',
  bsw_no = 'bsw_no.csv',
  bsw_no2 = 'bsw_no2.csv',
  bsw_o3 = 'bsw_o3.csv',
  bsw_so2 = 'bsw_so2.csv'
)

summarise_numeric_range <- function(data) {
  numeric_cols <- names(data)[sapply(data, is.numeric)]
  ranges <- lapply(numeric_cols, function(col) {
    c(min = min(data[[col]], na.rm = TRUE), max = max(data[[col]], na.rm = TRUE))
  })
  do.call(rbind, ranges)
}

check_missing <- function(data, path) {
  total_missing <- sum(is.na(data) | data == '')
  if (total_missing > 0) {
    warning(sprintf("[week01] File %s has %d missing values", path, total_missing))
  } else {
    message(sprintf("[week01] No missing values detected in %s", path))
  }
}

check_duplicates <- function(data, path) {
  key_cols <- intersect(c('source_file', 'level'), names(data))
  if (length(key_cols) == 0) {
    message(sprintf("[week01] No key columns to test duplicates for %s", path))
    return()
  }
  dup_rows <- duplicated(data[key_cols]) | duplicated(data[key_cols], fromLast = TRUE)
  duplicate_count <- sum(dup_rows)
  message(sprintf(
    "[week01] %s duplicate rows by %s: %d",
    path,
    paste(key_cols, collapse = '+'),
    duplicate_count
  ))
}

for (name in names(raw_files)) {
  path <- raw_files[[name]]
  if (!file.exists(path)) {
    stop(sprintf("Raw dataset %s is missing", path))
  }
  data <- read.csv(path, check.names = FALSE)
  message(sprintf("[week01] ---- %s ----", path))
  check_missing(data, path)
  check_duplicates(data, path)
  numeric_ranges <- summarise_numeric_range(data)
  message(sprintf("[week01] Numeric ranges for %s:\n%s", path, capture.output(print(numeric_ranges))))
}

message("[week01] Raw panel validation completed.")
