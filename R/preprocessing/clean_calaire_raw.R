# Normalize make.names() column names to standard identifiers.
.normalize_col_names <- function(raw_names) {
  n <- make.names(trimws(raw_names), unique = TRUE)
  result <- n

  patterns <- list(
    date              = "^Date",
    time              = "^Time",
    co_tapi_ppm       = "^CO\\.TAPI|^CO-TAPI",
    co_gen_ppm        = "^CO\\.ppm$|^CO\\.generado|^CO\\.gen$",
    co_calaire_ppm    = "^CO\\.CALAIRE",
    co_invitado1_ppm  = "^CO\\.\\.Invitado|^CO\\.Invitado",
    so2_ppb           = "^SO2$",
    so2_gen_ppb       = "^SO2\\.ppb$|^SO2\\.Generado|^SO2\\.gen$",
    so2_calaire_ppb   = "^SO2\\.CALAIRE",
    so2_invitado1_ppb = "^SO2\\.\\.Invitado|^SO2\\.Invitado"
  )

  for (target in names(patterns)) {
    matches <- grepl(patterns[[target]], n, ignore.case = FALSE)
    result[matches] <- target
  }
  result
}

.log_entry <- function(check, status, message) {
  data.frame(check = check, status = status, message = message,
             stringsAsFactors = FALSE)
}

clean_calaire_raw <- function(raw, tz = "America/Bogota") {
  df  <- raw$data
  log <- list()

  # 1. Trim all character cells
  df[] <- lapply(df, function(x) if (is.character(x)) trimws(x) else x)

  # 2. Empty / blank strings → NA
  df[df == "" | df == " "] <- NA

  # 3. Identify date/time columns before normalization
  orig_names   <- names(df)
  norm_names   <- .normalize_col_names(orig_names)
  is_date      <- norm_names == "date"
  is_time      <- norm_names == "time"
  is_numeric   <- !is_date & !is_time

  # 4. Decimal comma → decimal point in numeric columns
  for (j in which(is_numeric)) {
    original  <- df[[j]]
    converted <- gsub(",", ".", original)
    ambiguous <- grepl("[0-9],[0-9]{3}[.]|[0-9][.][0-9]{3},", converted)
    if (any(ambiguous, na.rm = TRUE)) {
      log[[length(log) + 1]] <- .log_entry(
        "decimal_format", "WARN",
        paste0("Ambiguous decimal format in column '", orig_names[j], "'")
      )
    }
    changed <- !is.na(original) & !is.na(converted) & original != converted
    if (any(changed, na.rm = TRUE)) {
      log[[length(log) + 1]] <- .log_entry(
        "comma_decimal", "PASS",
        paste0("Converted ", sum(changed, na.rm = TRUE),
               " comma decimals in '", orig_names[j], "'")
      )
      df[[j]] <- converted
    }
  }

  # 5. Remove completely empty rows
  all_na <- apply(df, 1, function(r) all(is.na(r)))
  n_removed <- sum(all_na)
  if (n_removed > 0) {
    log[[length(log) + 1]] <- .log_entry(
      "empty_rows", "PASS",
      paste("Removed", n_removed, "completely empty rows")
    )
    df <- df[!all_na, , drop = FALSE]
  }

  # 6. Rename columns to standard names
  names(df) <- norm_names

  # 7. Parse timestamp
  date_col <- if (any(norm_names == "date")) df[["date"]] else stop("No date column")
  time_col <- if (any(norm_names == "time")) df[["time"]] else stop("No time column")
  ts_str   <- paste(date_col, time_col)
  ts       <- as.POSIXct(ts_str, format = "%m/%d/%Y %H:%M", tz = tz)

  n_failed <- sum(is.na(ts))
  if (n_failed > 0) {
    log[[length(log) + 1]] <- .log_entry(
      "timestamp_parse", "WARN",
      paste(n_failed, "timestamps failed to parse")
    )
  } else {
    log[[length(log) + 1]] <- .log_entry(
      "timestamp_parse", "PASS",
      paste("All", nrow(df), "timestamps parsed")
    )
  }
  df$timestamp <- ts

  # 8. Chronological order
  valid_ts <- df$timestamp[!is.na(df$timestamp)]
  if (length(valid_ts) > 1 && is.unsorted(valid_ts)) {
    log[[length(log) + 1]] <- .log_entry(
      "chronological_order", "WARN", "Timestamps not in chronological order"
    )
  } else {
    log[[length(log) + 1]] <- .log_entry(
      "chronological_order", "PASS", "Timestamps in chronological order"
    )
  }

  # 9. Duplicate timestamps
  n_dup <- sum(duplicated(df$timestamp[!is.na(df$timestamp)]))
  if (n_dup > 0) {
    log[[length(log) + 1]] <- .log_entry(
      "duplicate_timestamps", "WARN",
      paste(n_dup, "duplicate timestamps")
    )
  } else {
    log[[length(log) + 1]] <- .log_entry(
      "duplicate_timestamps", "PASS", "No duplicate timestamps"
    )
  }

  # 10. Minute gaps
  if (length(valid_ts) > 1) {
    diffs <- as.numeric(diff(valid_ts), units = "mins")
    n_gaps <- sum(round(diffs) > 1)
    if (n_gaps > 0) {
      log[[length(log) + 1]] <- .log_entry(
        "minute_gaps", "WARN",
        paste(n_gaps, "gaps > 1 min detected")
      )
    } else {
      log[[length(log) + 1]] <- .log_entry(
        "minute_gaps", "PASS", "No minute gaps"
      )
    }
  }

  # 11. Convert numeric columns to numeric type
  num_cols <- setdiff(names(df), c("date", "time", "timestamp"))
  for (j in num_cols) {
    parsed      <- suppressWarnings(as.numeric(df[[j]]))
    n_bad       <- sum(!is.na(df[[j]]) & is.na(parsed))
    if (n_bad > 0) {
      log[[length(log) + 1]] <- .log_entry(
        "non_parseable", "WARN",
        paste(n_bad, "non-parseable values in '", j, "'")
      )
    }
    df[[j]] <- parsed
  }

  # 12. NA counts per column
  na_summary <- sapply(df[, num_cols, drop = FALSE], function(x) sum(is.na(x)))
  log[[length(log) + 1]] <- .log_entry(
    "na_counts", "PASS",
    paste(paste0(names(na_summary), ":", na_summary), collapse = "; ")
  )

  log_df <- do.call(rbind, log)

  list(data = df, log = log_df)
}
