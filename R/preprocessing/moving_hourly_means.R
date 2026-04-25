# Moving hourly means for estabilidad/homogeneidad blocks.
# Each valid block produces exactly 60 moving means of window = 60.
# Requires >= 119 valid (non-NA) data points within the block window.
# mm_i = mean(x[i:(i+59)]) for i = 1:60 (uses first 119 points).

compute_moving_hourly_means <- function(clean_data, design, tz = "America/Bogota") {
  WINDOW   <- 60L
  N_NEEDED <- 119L   # window + window - 1

  results <- list()

  for (i in seq_len(nrow(design))) {
    row <- design[i, ]

    start_ts <- as.POSIXct(row$start_timestamp, format = "%Y-%m-%d %H:%M", tz = tz)
    end_ts   <- as.POSIXct(row$end_timestamp,   format = "%Y-%m-%d %H:%M", tz = tz)
    src_col  <- row$source_column

    if (!src_col %in% names(clean_data)) {
      warning("Column '", src_col, "' not found; skipping design row ", i)
      next
    }

    block <- clean_data[
      !is.na(clean_data$timestamp) &
        clean_data$timestamp >= start_ts &
        clean_data$timestamp <= end_ts,
      ,
      drop = FALSE
    ]
    block <- block[order(block$timestamp), , drop = FALSE]

    # Only rows where the source column is non-NA
    valid_rows <- block[!is.na(block[[src_col]]), , drop = FALSE]
    n_valid    <- nrow(valid_rows)

    if (n_valid < N_NEEDED) {
      results[[length(results) + 1]] <- data.frame(
        source           = row$source,
        pollutant        = row$pollutant,
        instrument       = row$instrument,
        level            = row$level,
        replicate        = row$replicate,
        sample_id        = row$sample_id,
        study_type       = row$study_type,
        run              = i,
        window_index     = NA_integer_,
        window_start     = NA_character_,
        window_end       = NA_character_,
        n_points         = n_valid,
        value            = NA_real_,
        unit             = row$unit,
        valid_mm         = FALSE,
        validation_flags = paste0("insufficient(", n_valid, "<", N_NEEDED, ")"),
        stringsAsFactors = FALSE
      )
      next
    }

    x      <- valid_rows[[src_col]][seq_len(N_NEEDED)]
    ts_seq <- valid_rows$timestamp[seq_len(N_NEEDED)]

    for (k in seq_len(WINDOW)) {
      idx    <- k:(k + WINDOW - 1L)
      mm_val <- mean(x[idx])
      results[[length(results) + 1]] <- data.frame(
        source           = row$source,
        pollutant        = row$pollutant,
        instrument       = row$instrument,
        level            = row$level,
        replicate        = row$replicate,
        sample_id        = row$sample_id,
        study_type       = row$study_type,
        run              = i,
        window_index     = k,
        window_start     = format(ts_seq[k],            "%Y-%m-%d %H:%M:%S"),
        window_end       = format(ts_seq[k + WINDOW - 1L], "%Y-%m-%d %H:%M:%S"),
        n_points         = WINDOW,
        value            = mm_val,
        unit             = row$unit,
        valid_mm         = TRUE,
        validation_flags = "",
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}
