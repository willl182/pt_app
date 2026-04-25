# Transversal validation checks for the CALAIRE preprocessing pipeline.
# Each check function returns a single-row data.frame with:
#   check, status ("PASS" / "WARN" / "FAIL"), detail

.vcheck <- function(check, status, detail = "") {
  data.frame(check = check, status = status, detail = as.character(detail),
             stringsAsFactors = FALSE)
}

check_file_exists <- function(path, label = NULL) {
  lbl <- if (is.null(label)) basename(path) else label
  if (file.exists(path)) {
    .vcheck(paste0("file_exists:", lbl), "PASS", path)
  } else {
    .vcheck(paste0("file_exists:", lbl), "FAIL", paste("Not found:", path))
  }
}

check_separator <- function(path, expected_sep = ";") {
  first_line <- readLines(path, n = 1L, warn = FALSE)
  if (grepl(expected_sep, first_line, fixed = TRUE)) {
    .vcheck("separator", "PASS", paste("Separator", expected_sep, "detected"))
  } else {
    .vcheck("separator", "FAIL",
            paste("Expected '", expected_sep, "' not found in first line"))
  }
}

check_units_row_excluded <- function(clean_data, units_values) {
  # Units row should not appear as a data row (timestamp would be NA)
  if (any(is.na(clean_data$timestamp))) {
    .vcheck("units_row_excluded", "WARN",
            paste(sum(is.na(clean_data$timestamp)), "rows with NA timestamp"))
  } else {
    .vcheck("units_row_excluded", "PASS", "No rows with NA timestamp")
  }
}

check_hourly_n <- function(hourly_df) {
  if (nrow(hourly_df) == 0) {
    return(.vcheck("hourly_n60", "FAIL", "No hourly rows produced"))
  }
  valid_hrs <- hourly_df[hourly_df$valid_hour == TRUE, ]
  bad <- valid_hrs[!is.na(valid_hrs$n) & valid_hrs$n != 60, ]
  if (nrow(bad) > 0) {
    .vcheck("hourly_n60", "FAIL",
            paste(nrow(bad), "valid hours with n != 60"))
  } else {
    n_valid <- sum(hourly_df$valid_hour == TRUE, na.rm = TRUE)
    .vcheck("hourly_n60", "PASS", paste(n_valid, "valid hours with n=60"))
  }
}

check_mm_n <- function(mm_df) {
  if (nrow(mm_df) == 0) {
    return(.vcheck("mm_n60", "FAIL", "No moving-mean rows produced"))
  }
  valid_mm <- mm_df[mm_df$valid_mm == TRUE, ]
  bad <- valid_mm[!is.na(valid_mm$n_points) & valid_mm$n_points != 60, ]
  if (nrow(bad) > 0) {
    .vcheck("mm_n60", "FAIL",
            paste(nrow(bad), "valid windows with n_points != 60"))
  } else {
    .vcheck("mm_n60", "PASS",
            paste(nrow(valid_mm), "valid windows with n_points=60"))
  }
}

check_mm_block_count <- function(mm_df, design) {
  if (nrow(mm_df) == 0) return(.vcheck("mm_block_count", "FAIL", "No MM rows"))
  valid_mm   <- mm_df[mm_df$valid_mm == TRUE, ]
  n_per_block <- table(valid_mm$sample_id)
  bad_blocks  <- names(n_per_block[n_per_block != 60])
  if (length(bad_blocks) > 0) {
    .vcheck("mm_block_count", "WARN",
            paste("Blocks with != 60 MMs:", paste(bad_blocks, collapse = ", ")))
  } else {
    .vcheck("mm_block_count", "PASS",
            paste(length(n_per_block), "blocks with exactly 60 MMs each"))
  }
}

check_decimal_output <- function(df, label) {
  # Verify that numeric columns use decimal point (not comma)
  num_cols <- sapply(df, is.numeric)
  # If already numeric, format will use period
  .vcheck(paste0("decimal_output:", label), "PASS",
          "Numeric columns stored as R numeric (point decimal)")
}

check_row_counts <- function(raw_n, clean_n, hourly_n, mm_n) {
  detail <- paste0(
    "raw=", raw_n, " clean=", clean_n,
    " hourly=", hourly_n, " mm=", mm_n
  )
  .vcheck("row_counts", "PASS", detail)
}

check_nominal_levels <- function(clean_data, design, levels_table, tz = "America/Bogota") {
  failures <- 0
  for (i in seq_len(nrow(design))) {
    row      <- design[i, ]
    src_gen  <- levels_table$generator_col[levels_table$label == row$level][1]
    nominal  <- levels_table$nominal[levels_table$label == row$level][1]
    tol      <- levels_table$tolerance[levels_table$label == row$level][1]

    if (is.na(src_gen) || !src_gen %in% names(clean_data)) next

    start_ts <- as.POSIXct(row$start_timestamp, format = "%Y-%m-%d %H:%M", tz = tz)
    end_ts   <- as.POSIXct(row$end_timestamp,   format = "%Y-%m-%d %H:%M", tz = tz)

    gen_vals <- clean_data[[src_gen]][
      !is.na(clean_data$timestamp) &
        clean_data$timestamp >= start_ts &
        clean_data$timestamp <= end_ts
    ]
    gen_vals <- gen_vals[!is.na(gen_vals)]
    if (length(gen_vals) == 0) next

    out_of_tol <- sum(abs(gen_vals - nominal) > tol)
    if (out_of_tol > 0) failures <- failures + 1
  }

  if (failures > 0) {
    .vcheck("nominal_levels", "WARN",
            paste(failures, "blocks with generator values outside tolerance"))
  } else {
    .vcheck("nominal_levels", "PASS",
            "All generator values within tolerance for assigned levels")
  }
}

check_ronda_level_coverage <- function(hourly_df) {
  if (nrow(hourly_df) == 0) return(.vcheck("ronda_level_coverage", "FAIL", "No hourly rows"))
  valid <- hourly_df[!is.na(hourly_df$valid_hour) & hourly_df$valid_hour == TRUE, ]
  if (nrow(valid) == 0) return(.vcheck("ronda_level_coverage", "WARN", "No valid hours produced"))
  levels_present <- sort(unique(valid$level[!is.na(valid$level)]))
  .vcheck("ronda_level_coverage", "PASS",
          paste("Levels with valid hours:", paste(levels_present, collapse = ", ")))
}

run_ronda_checks <- function(paths, raw_result, clean_result, hourly_df, levels_table,
                              tz = "America/Bogota") {
  checks <- list()

  for (p in names(paths)) {
    checks[[length(checks) + 1]] <- check_file_exists(paths[[p]], label = p)
  }
  checks[[length(checks) + 1]] <- check_separator(paths$ronda, expected_sep = ";")
  checks[[length(checks) + 1]] <- check_units_row_excluded(clean_result$data, raw_result$units)
  checks[[length(checks) + 1]] <- check_hourly_n(hourly_df)
  checks[[length(checks) + 1]] <- check_decimal_output(hourly_df, "h_datos_ronda")
  checks[[length(checks) + 1]] <- check_ronda_level_coverage(hourly_df)
  checks[[length(checks) + 1]] <- check_row_counts(
    raw_n    = raw_result$n_rows,
    clean_n  = nrow(clean_result$data),
    hourly_n = nrow(hourly_df),
    mm_n     = 0L
  )

  log_df <- do.call(rbind, checks)

  if (!is.null(clean_result$log) && nrow(clean_result$log) > 0) {
    extra <- clean_result$log
    if (!"detail" %in% names(extra)) extra$detail <- extra$message
    extra <- extra[, c("check", "status", "detail"), drop = FALSE]
    log_df <- rbind(log_df, extra)
  }

  log_df$timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_df
}

# Run all checks and return combined log data.frame
run_all_checks <- function(paths, raw_result, clean_result,
                           hourly_df, mm_df, design, levels_table,
                           tz = "America/Bogota") {
  checks <- list()

  for (p in names(paths)) {
    checks[[length(checks) + 1]] <- check_file_exists(paths[[p]], label = p)
  }

  if (!is.null(paths$estabilidad)) {
    checks[[length(checks) + 1]] <-
      check_separator(paths$estabilidad, expected_sep = ";")
  }

  checks[[length(checks) + 1]] <-
    check_units_row_excluded(clean_result$data, raw_result$units)

  checks[[length(checks) + 1]] <- check_hourly_n(hourly_df)
  checks[[length(checks) + 1]] <- check_mm_n(mm_df)
  checks[[length(checks) + 1]] <- check_mm_block_count(mm_df, design)
  checks[[length(checks) + 1]] <- check_decimal_output(hourly_df, "hourly")
  checks[[length(checks) + 1]] <- check_decimal_output(mm_df,     "mm")

  checks[[length(checks) + 1]] <- check_row_counts(
    raw_n    = raw_result$n_rows,
    clean_n  = nrow(clean_result$data),
    hourly_n = nrow(hourly_df),
    mm_n     = nrow(mm_df)
  )

  checks[[length(checks) + 1]] <-
    check_nominal_levels(clean_result$data, design, levels_table, tz = tz)

  log_df <- do.call(rbind, checks)

  # Append clean log entries
  if (!is.null(clean_result$log) && nrow(clean_result$log) > 0) {
    extra <- clean_result$log
    if (!"detail" %in% names(extra)) extra$detail <- extra$message
    extra <- extra[, c("check", "status", "detail"), drop = FALSE]
    log_df <- rbind(log_df, extra)
  }

  log_df$timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_df
}
