# Normalize make.names() column names to standard identifiers.
.participant_label_token <- function(x) {
  token <- tolower(trimws(as.character(x)))
  token <- gsub("[^[:alnum:]]+", "_", token)
  token <- gsub("^_+|_+$", "", token)
  token
}

.normalize_col_names <- function(raw_names) {
  n <- make.names(trimws(raw_names), unique = TRUE)
  result <- n

  patterns <- list(
    date              = "^[Dd]ate",
    time              = "^[Tt]ime",
    co_tapi_ppm       = "^[Cc][Oo]\\.TAPI|^[Cc][Oo]-TAPI",
    co_gen_ppm        = "^[Cc][Oo]\\.ppm$|^[Cc][Oo]\\.generado|^[Cc][Oo]\\.gen$|^[Cc][Oo]_?gen$",
    co_calaire_ppm    = "^[Cc][Oo]\\.CALAIRE|^[Cc][Oo]_?ref$|^[Cc][Oo]\\.ref$",
    co_part_p1        = "^[Cc][Oo]_?p1$|^[Cc][Oo]\\.p1$|^[Cc][Oo]_?part_?1$",
    co_invitado1_ppm  = "^[Cc][Oo]\\.\\.Invitado|^[Cc][Oo]\\.Invitado",
    so2_ppb           = "^[Ss][Oo]2$",
    so2_gen_ppb       = "^[Ss][Oo]2\\.ppb$|^[Ss][Oo]2\\.Generado|^[Ss][Oo]2\\.gen$|^[Ss][Oo]2_?gen$",
    so2_calaire_ppb   = "^[Ss][Oo]2\\.CALAIRE|^[Ss][Oo]2_?ref$|^[Ss][Oo]2\\.ref$",
    so2_part_p1       = "^[Ss][Oo]2_?p1$|^[Ss][Oo]2\\.p1$|^[Ss][Oo]2_?part_?1$",
    so2_invitado1_ppb = "^[Ss][Oo]2\\.\\.Invitado|^[Ss][Oo]2\\.Invitado",
    no_gen_ppb        = "^[Nn][Oo]_?gen$|^[Nn][Oo]\\.gen$",
    no_calaire_ppb    = "^[Nn][Oo]_?ref$|^[Nn][Oo]\\.ref$|^[Nn][Oo]\\.CALAIRE",
    no_part_p1        = "^[Nn][Oo]_?p1$|^[Nn][Oo]\\.p1$|^[Nn][Oo]_?part_?1$",
    no2_gen_ppb       = "^[Nn][Oo]2_?gen$|^[Nn][Oo]2\\.gen$",
    no2_calaire_ppb   = "^[Nn][Oo]2_?ref$|^[Nn][Oo]2\\.ref$|^[Nn][Oo]2\\.CALAIRE",
    no2_part_p1       = "^[Nn][Oo]2_?p1$|^[Nn][Oo]2\\.p1$|^[Nn][Oo]2_?part_?1$",
    nox_gen_ppb       = "^[Nn]ox_?gen$|^[Nn]ox\\.gen$|^[Nn][Oo]x_?gen$|^[Nn][Oo]x\\.gen$",
    nox_calaire_ppb   = "^[Nn]ox_?ref$|^[Nn]ox\\.ref$|^[Nn]ox\\.CALAIRE|^[Nn][Oo]x_?ref$|^[Nn][Oo]x\\.ref$|^[Nn][Oo]x\\.CALAIRE",
    nox_part_p1       = "^[Nn]ox_?p1$|^[Nn]ox\\.p1$|^[Nn]ox_?part_?1$|^[Nn][Oo]x_?p1$|^[Nn][Oo]x\\.p1$|^[Nn][Oo]x_?part_?1$",
    o3_gen_ppb        = "^[Oo]3_?gen$|^[Oo]3\\.gen$",
    o3_calaire_ppb    = "^[Oo]3_?ref$|^[Oo]3\\.ref$|^[Oo]3\\.CALAIRE",
    o3_part_p1        = "^[Oo]3_?p1$|^[Oo]3\\.p1$|^[Oo]3_?part_?1$"
  )

  for (target in names(patterns)) {
    matches <- grepl(patterns[[target]], n, ignore.case = FALSE)
    result[matches] <- target
  }

  participant_patterns <- c(
    co = "ppm",
    so2 = "ppb",
    no = "ppb",
    no2 = "ppb",
    nox = "ppb",
    o3 = "ppb"
  )
  reserved_labels <- c(
    "gen", "generado", "generator", "ref", "referencia", "calaire",
    "tapi", "ppm", "ppb", "nmol", "umol"
  )
  for (pollutant in names(participant_patterns)) {
    pattern <- paste0("^", pollutant, "[._]?(p[0-9]+|part[._]?[0-9]+|[A-Za-z][A-Za-z0-9]*)$")
    matches <- grepl(pattern, n, ignore.case = TRUE)
    if (any(matches)) {
      labels <- sub(pattern, "\\1", n[matches], ignore.case = TRUE)
      labels <- sub("^part[._]?", "p", labels, ignore.case = TRUE)
      labels <- .participant_label_token(labels)
      keep <- !labels %in% reserved_labels
      if (any(keep)) {
        idx <- which(matches)[keep]
        result[idx] <- paste0(pollutant, "_part_", labels[keep])
      }
    }
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

  # Detect format: AM/PM (12h) vs 24h, and 2-digit vs 4-digit year
  has_ampm <- grepl("[AP]M$", trimws(time_col), ignore.case = TRUE)
  short_year <- grepl("^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}\\s", ts_str)

  ts <- rep(as.POSIXct(NA_real_, origin = "1970-01-01", tz = tz), length(ts_str))

  # Format combinations
  fmt_24h_4yr <- "%m/%d/%Y %H:%M"
  fmt_24h_2yr <- "%m/%d/%y %H:%M"
  fmt_12h_4yr <- "%m/%d/%Y %I:%M:%S %p"
  fmt_12h_2yr <- "%m/%d/%y %I:%M:%S %p"

  # Parse based on detected format
  for (i in seq_along(ts_str)) {
    if (has_ampm[i]) {
      fmt <- if (short_year[i]) fmt_12h_2yr else fmt_12h_4yr
    } else {
      fmt <- if (short_year[i]) fmt_24h_2yr else fmt_24h_4yr
    }
    ts[i] <- as.POSIXct(ts_str[i], format = fmt, tz = tz)
  }

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
