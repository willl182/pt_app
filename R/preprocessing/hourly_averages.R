# Hourly averages for estabilidad/homogeneidad blocks.
# Valid hour: at least 75% of an hour (45 valid minute-level rows) with a
# single design block/source column.
# mean_h = mean(x), sd_h = sd(x), u_h = sd_h / sqrt(n)

compute_hourly_averages <- function(clean_data, design, tz = "America/Bogota",
                                     pollutants = NULL) {
  if (!is.null(pollutants)) {
    pollutants <- tolower(pollutants)
    design <- design[tolower(design$pollutant) %in% pollutants, , drop = FALSE]
  }

  results <- list()

  for (i in seq_len(nrow(design))) {
    row <- design[i, ]

    start_ts <- as.POSIXct(row$start_timestamp, format = "%Y-%m-%d %H:%M", tz = tz)
    end_ts   <- as.POSIXct(row$end_timestamp,   format = "%Y-%m-%d %H:%M", tz = tz)
    src_col  <- row$source_column

    if (!src_col %in% names(clean_data)) {
      warning("Column '", src_col, "' not found in data; skipping design row ", i)
      next
    }

    block <- clean_data[
      !is.na(clean_data$timestamp) &
        clean_data$timestamp >= start_ts &
        clean_data$timestamp <= end_ts,
      ,
      drop = FALSE
    ]

    if (nrow(block) == 0) next

    block$hour_start <- as.POSIXct(
      format(block$timestamp, "%Y-%m-%d %H:00:00", tz = tz),
      format = "%Y-%m-%d %H:%M:%S", tz = tz
    )

    for (h_ts in sort(unique(block$hour_start))) {
      h_ts_p  <- as.POSIXct(h_ts, origin = "1970-01-01", tz = tz)
      hr_rows <- block[block$hour_start == h_ts_p, , drop = FALSE]

      mins    <- as.integer(format(hr_rows$timestamp, "%M", tz = tz))
      vals    <- hr_rows[[src_col]]
      n_valid <- sum(!is.na(vals))

      full_hour <- n_valid >= 45

      flags <- character(0)
      if (n_valid < 60) flags <- c(flags, paste0("n=", n_valid))
      if (!full_hour) flags <- c(flags, "less_than_75pct")

      if (full_hour) {
        mean_v <- mean(vals, na.rm = TRUE)
        sd_v   <- sd(vals, na.rm = TRUE)
        u_v    <- sd_v / sqrt(n_valid)
      } else {
        mean_v <- NA_real_
        sd_v   <- NA_real_
        u_v    <- NA_real_
      }

      results[[length(results) + 1]] <- data.frame(
        source           = row$source,
        date             = format(h_ts_p, "%Y-%m-%d"),
        hour_start       = format(h_ts_p, "%Y-%m-%d %H:%M:%S"),
        pollutant        = row$pollutant,
        instrument       = row$instrument,
        level            = row$level,
        replicate        = row$replicate,
        sample_id        = row$sample_id,
        study_type       = row$study_type,
        source_column    = src_col,
        unit             = row$unit,
        mean_value       = mean_v,
        sd_value         = sd_v,
        u_value          = u_v,
        n                = n_valid,
        valid_hour       = full_hour,
        validation_flags = paste(flags, collapse = "|"),
        stringsAsFactors = FALSE
      )
    }
  }

  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}

# Hourly averages for reference data during the proficiency-testing round.
# Only CALAIRE reference columns are processed; participant/invited-lab columns
# are intentionally ignored. Level is determined per-pollutant per-hour from the
# generator column and niveles_calaire.csv.
# Valid hour: at least 75% of an hour (45 valid minute-level rows), no NA in
# reference column, single level. Non-zero levels keep up to 3 hourly averages;
# level 0 keeps one hourly average.
compute_hourly_averages_ronda <- function(clean_data, levels_table,
                                           tz = "America/Bogota",
                                           pollutants = NULL) {
  instruments <- list(
    list(pollutant = "co",  col = "co_calaire_ppm",  gen_col = "co_gen_ppm",
         unit = "ppm", instrument = "calaire_ref"),
    list(pollutant = "so2", col = "so2_calaire_ppb", gen_col = "so2_gen_ppb",
         unit = "ppb", instrument = "calaire_ref"),
    list(pollutant = "no",  col = "no_calaire_ppb",  gen_col = "no_gen_ppb",
         unit = "ppb", instrument = "calaire_ref"),
    list(pollutant = "no2", col = "no2_calaire_ppb", gen_col = "no2_gen_ppb",
         unit = "ppb", instrument = "calaire_ref"),
    list(pollutant = "nox", col = "nox_calaire_ppb", gen_col = "nox_gen_ppb",
         unit = "ppb", instrument = "calaire_ref"),
    list(pollutant = "o3",  col = "o3_calaire_ppb",  gen_col = "o3_gen_ppb",
         unit = "ppb", instrument = "calaire_ref")
  )

  if (!is.null(pollutants)) {
    pollutants <- tolower(pollutants)
    instruments <- instruments[vapply(
      instruments,
      function(x) x$pollutant %in% pollutants,
      logical(1)
    )]
  }

  valid_rows <- clean_data[!is.na(clean_data$timestamp), , drop = FALSE]
  if (nrow(valid_rows) == 0) return(data.frame())

  assign_level <- function(gen_vals, pollutant) {
    lvl_rows  <- levels_table[levels_table$pollutant == pollutant, ]
    gen_clean <- gen_vals[!is.na(gen_vals)]
    if (length(gen_clean) == 0)
      return(list(label = NA_character_, nominal = NA_real_, mixed = FALSE))
    for (k in seq_len(nrow(lvl_rows))) {
      if (all(abs(gen_clean - lvl_rows$nominal[k]) <= lvl_rows$tolerance[k]))
        return(list(label = lvl_rows$label[k], nominal = lvl_rows$nominal[k], mixed = FALSE))
    }
    list(label = NA_character_, nominal = NA_real_, mixed = TRUE)
  }

  results <- list()
  for (inst in instruments) {
    pollutant <- inst$pollutant
    col       <- inst$col
    gen_col   <- inst$gen_col

    if (!col %in% names(valid_rows) || !gen_col %in% names(valid_rows)) next

    row_levels <- lapply(valid_rows[[gen_col]], assign_level, pollutant = pollutant)
    labels <- vapply(row_levels, `[[`, character(1), "label")
    nominals <- vapply(row_levels, `[[`, numeric(1), "nominal")
    usable <- !is.na(labels)
    rows <- valid_rows[usable, , drop = FALSE]
    labels <- labels[usable]
    nominals <- nominals[usable]
    if (nrow(rows) == 0) next

    run_id <- cumsum(c(TRUE, labels[-1] != labels[-length(labels)]))
    for (rid in unique(run_id)) {
      idx <- which(run_id == rid)
      chunks <- split(idx, ceiling(seq_along(idx) / 60))
      chunks <- chunks[vapply(chunks, length, integer(1)) >= 45]
      if (length(chunks) == 0) next

      max_hours <- if (labels[idx[1]] %in% c("0-ppm", "0-ppb")) 1L else 3L
      chunks <- chunks[seq_len(min(length(chunks), max_hours))]

      for (chunk_idx in chunks) {
        hr_rows <- rows[chunk_idx, , drop = FALSE]
        vals <- hr_rows[[col]]
        gen_vals <- hr_rows[[gen_col]]
        n_valid <- sum(!is.na(vals))
        valid_hour <- n_valid >= 45
        h_ts_p <- hr_rows$timestamp[1]
        flags <- character(0)
        if (n_valid < 60) flags <- c(flags, paste0("n=", n_valid))

        mean_v <- if (valid_hour) mean(vals, na.rm = TRUE) else NA_real_
        sd_v <- if (valid_hour && n_valid > 1) sd(vals, na.rm = TRUE) else NA_real_
        u_v <- if (valid_hour && n_valid > 1) sd_v / sqrt(n_valid) else NA_real_

        results[[length(results) + 1]] <- data.frame(
          source = "ronda",
          date = format(h_ts_p, "%Y-%m-%d"),
          hour_start = format(h_ts_p, "%Y-%m-%d %H:%M:%S"),
          pollutant = pollutant,
          level = labels[chunk_idx[1]],
          generated_nominal = nominals[chunk_idx[1]],
          generated_mean = mean(gen_vals, na.rm = TRUE),
          generated_sd = sd(gen_vals, na.rm = TRUE),
          instrument = inst$instrument,
          mean_value = mean_v,
          sd_value = sd_v,
          u_value = u_v,
          n = n_valid,
          unit = inst$unit,
          valid_hour = valid_hour,
          validation_flags = paste(flags, collapse = "|"),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}

compute_hourly_averages_participant_ronda <- function(clean_data, levels_table,
                                                       participant_id = "part_1",
                                                       tz = "America/Bogota",
                                                       pollutants = NULL) {
  instruments <- list(
    list(pollutant = "co",  col = "co_part_1_ppm",  gen_col = "co_gen_ppm",
         unit = "ppm", instrument = participant_id),
    list(pollutant = "so2", col = "so2_part_1_ppb", gen_col = "so2_gen_ppb",
         unit = "ppb", instrument = participant_id),
    list(pollutant = "no",  col = "no_part_1_ppb",  gen_col = "no_gen_ppb",
         unit = "ppb", instrument = participant_id),
    list(pollutant = "no2", col = "no2_part_1_ppb", gen_col = "no2_gen_ppb",
         unit = "ppb", instrument = participant_id),
    list(pollutant = "nox", col = "nox_part_1_ppb", gen_col = "nox_gen_ppb",
         unit = "ppb", instrument = participant_id),
    list(pollutant = "o3",  col = "o3_part_1_ppb",  gen_col = "o3_gen_ppb",
         unit = "ppb", instrument = participant_id)
  )

  if (!is.null(pollutants)) {
    pollutants <- tolower(pollutants)
    instruments <- instruments[vapply(
      instruments,
      function(x) x$pollutant %in% pollutants,
      logical(1)
    )]
  }

  valid_rows <- clean_data[!is.na(clean_data$timestamp), , drop = FALSE]
  if (nrow(valid_rows) == 0) return(data.frame())

  assign_level <- function(gen_vals, pollutant) {
    lvl_rows  <- levels_table[levels_table$pollutant == pollutant, ]
    gen_clean <- gen_vals[!is.na(gen_vals)]
    if (length(gen_clean) == 0)
      return(list(label = NA_character_, nominal = NA_real_, mixed = FALSE))
    for (k in seq_len(nrow(lvl_rows))) {
      if (all(abs(gen_clean - lvl_rows$nominal[k]) <= lvl_rows$tolerance[k]))
        return(list(label = lvl_rows$label[k], nominal = lvl_rows$nominal[k], mixed = FALSE))
    }
    list(label = NA_character_, nominal = NA_real_, mixed = TRUE)
  }

  results <- list()
  for (inst in instruments) {
    pollutant <- inst$pollutant
    col       <- inst$col
    gen_col   <- inst$gen_col

    if (!col %in% names(valid_rows) || !gen_col %in% names(valid_rows)) next

    row_levels <- lapply(valid_rows[[gen_col]], assign_level, pollutant = pollutant)
    labels <- vapply(row_levels, `[[`, character(1), "label")
    nominals <- vapply(row_levels, `[[`, numeric(1), "nominal")
    usable <- !is.na(labels)
    rows <- valid_rows[usable, , drop = FALSE]
    labels <- labels[usable]
    nominals <- nominals[usable]
    if (nrow(rows) == 0) next

    run_id <- cumsum(c(TRUE, labels[-1] != labels[-length(labels)]))
    for (rid in unique(run_id)) {
      idx <- which(run_id == rid)
      chunks <- split(idx, ceiling(seq_along(idx) / 60))
      chunks <- chunks[vapply(chunks, length, integer(1)) >= 45]
      if (length(chunks) == 0) next

      max_hours <- if (labels[idx[1]] %in% c("0-ppm", "0-ppb")) 1L else 3L
      chunks <- chunks[seq_len(min(length(chunks), max_hours))]

      for (chunk_idx in chunks) {
        hr_rows <- rows[chunk_idx, , drop = FALSE]
        vals <- hr_rows[[col]]
        gen_vals <- hr_rows[[gen_col]]
        n_valid <- sum(!is.na(vals))
        valid_hour <- n_valid >= 45
        h_ts_p <- hr_rows$timestamp[1]
        flags <- character(0)
        if (n_valid < 60) flags <- c(flags, paste0("n=", n_valid))

        mean_v <- if (valid_hour) mean(vals, na.rm = TRUE) else NA_real_
        sd_v <- if (valid_hour && n_valid > 1) sd(vals, na.rm = TRUE) else NA_real_
        u_v <- if (valid_hour && n_valid > 1) sd_v / sqrt(n_valid) else NA_real_

        results[[length(results) + 1]] <- data.frame(
          source = "ronda_participante",
          participant_id = participant_id,
          date = format(h_ts_p, "%Y-%m-%d"),
          hour_start = format(h_ts_p, "%Y-%m-%d %H:%M:%S"),
          pollutant = pollutant,
          level = labels[chunk_idx[1]],
          generated_nominal = nominals[chunk_idx[1]],
          generated_mean = mean(gen_vals, na.rm = TRUE),
          generated_sd = sd(gen_vals, na.rm = TRUE),
          instrument = inst$instrument,
          mean_value = mean_v,
          sd_value = sd_v,
          u_value = u_v,
          n = n_valid,
          unit = inst$unit,
          valid_hour = valid_hour,
          validation_flags = paste(flags, collapse = "|"),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}

summarise_reference_levels <- function(hourly_df) {
  valid <- hourly_df[hourly_df$valid_hour == TRUE, , drop = FALSE]
  if (nrow(valid) == 0) return(data.frame())

  groups <- unique(valid[, c("source", "pollutant", "level", "unit", "instrument"), drop = FALSE])
  results <- vector("list", nrow(groups))

  for (i in seq_len(nrow(groups))) {
    g <- groups[i, ]
    rows <- valid[
      valid$source == g$source &
        valid$pollutant == g$pollutant &
        valid$level == g$level &
        valid$unit == g$unit &
        valid$instrument == g$instrument,
      ,
      drop = FALSE
    ]
    n_hours <- nrow(rows)
    final_mean <- mean(rows$mean_value)
    final_sd <- if (n_hours > 1) sd(rows$mean_value) else NA_real_
    final_u <- if (n_hours > 1) final_sd / sqrt(n_hours) else rows$u_value[1]

    results[[i]] <- data.frame(
      source = g$source,
      pollutant = g$pollutant,
      level = g$level,
      unit = g$unit,
      instrument = g$instrument,
      mean_value = final_mean,
      sd_value = final_sd,
      u_value = final_u,
      n_hours = n_hours,
      hour_starts = paste(rows$hour_start, collapse = "|"),
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, results)
}
