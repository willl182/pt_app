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
  # Build instruments from levels_table: pollutant -> (unit, generator_col)
  # Hardcoded reference column mapping (raw data column names).
  ref_cols <- c(
    co = "co_calaire_ppm", so2 = "so2_calaire_ppb", no = "no_calaire_ppb",
    no2 = "no2_calaire_ppb", nox = "nox_calaire_ppb", o3 = "o3_calaire_ppb"
  )
  instruments <- lapply(seq_len(nrow(levels_table)), function(i) {
    p <- levels_table$pollutant[i]
    list(
      pollutant  = p,
      col        = ref_cols[p],
      gen_col    = levels_table$generator_col[i],
      unit       = levels_table$unit[i],
      instrument = "calaire_ref"
    )
  })

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

  results <- list()
  for (inst in instruments) {
    pollutant <- inst$pollutant
    col       <- inst$col
    gen_col   <- inst$gen_col
    unit      <- inst$unit

    if (!col %in% names(valid_rows) || !gen_col %in% names(valid_rows)) next

    # Use generator values DIRECTLY as nominal (no rounding, no table lookup)
    gen_values <- as.numeric(valid_rows[[gen_col]])
    gen_clean <- ifelse(is.na(gen_values), NA, gen_values)
    # Create labels using exact generator value: "37-nmol/mol", "0-µmol/mol", etc.
    labels <- ifelse(is.na(gen_clean), NA, paste0(gen_clean, "-", unit))
    nominals <- gen_clean

    usable <- !is.na(gen_values) & !is.na(labels)
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

      max_hours <- if (labels[idx[1]] %in% c("0-µmol/mol", "0-nmol/mol")) 1L else 3L
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
          run = rid,
          date = format(h_ts_p, "%Y-%m-%d"),
          hour_start = format(h_ts_p, "%Y-%m-%d %H:%M:%S"),
          pollutant = pollutant,
          level = labels[chunk_idx[1]],
          generated_nominal = nominals[chunk_idx[1]],
          generated_mean = round(mean(gen_vals, na.rm = TRUE), 3),
          generated_sd = round(sd(gen_vals, na.rm = TRUE), 3),
          instrument = inst$instrument,
          mean_value = round(mean_v, 3),
          sd_value = round(sd_v, 3),
          u_value = round(u_v, 3),
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
                                                       participant_id = "p1",
                                                       tz = "America/Bogota",
                                                       pollutants = NULL) {
  # Build instruments from levels_table: pollutant -> (unit, generator_col)
  participant_token <- .participant_label_token(participant_id)
  part_cols <- c(
    co = paste0("co_part_", participant_token),
    so2 = paste0("so2_part_", participant_token),
    no = paste0("no_part_", participant_token),
    no2 = paste0("no2_part_", participant_token),
    nox = paste0("nox_part_", participant_token),
    o3 = paste0("o3_part_", participant_token)
  )
  instruments <- lapply(seq_len(nrow(levels_table)), function(i) {
    p <- levels_table$pollutant[i]
    list(
      pollutant      = p,
      col            = part_cols[p],
      gen_col        = levels_table$generator_col[i],
      unit           = levels_table$unit[i],
      instrument     = participant_id
    )
  })

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

  results <- list()
  for (inst in instruments) {
    pollutant <- inst$pollutant
    col       <- inst$col
    gen_col   <- inst$gen_col
    unit      <- inst$unit

    if (!col %in% names(valid_rows) || !gen_col %in% names(valid_rows)) next

    # Use generator values DIRECTLY as nominal (no rounding, no table lookup)
    gen_values <- as.numeric(valid_rows[[gen_col]])
    gen_clean <- ifelse(is.na(gen_values), NA, gen_values)
    # Create labels using exact generator value: "37-nmol/mol", "0-µmol/mol", etc.
    labels <- ifelse(is.na(gen_clean), NA, paste0(gen_clean, "-", unit))
    nominals <- gen_clean

    usable <- !is.na(gen_values) & !is.na(labels)
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

      max_hours <- if (labels[idx[1]] %in% c("0-µmol/mol", "0-nmol/mol")) 1L else 3L
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
          run = rid,
          date = format(h_ts_p, "%Y-%m-%d"),
          hour_start = format(h_ts_p, "%Y-%m-%d %H:%M:%S"),
          pollutant = pollutant,
          level = labels[chunk_idx[1]],
          generated_nominal = nominals[chunk_idx[1]],
          generated_mean = round(mean(gen_vals, na.rm = TRUE), 3),
          generated_sd = round(sd(gen_vals, na.rm = TRUE), 3),
          instrument = inst$instrument,
          mean_value = round(mean_v, 3),
          sd_value = round(sd_v, 3),
          u_value = round(u_v, 3),
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

  # Si el hourly_df tiene columna 'run', usarla; si no, derivar numericamente
  has_run <- "run" %in% names(valid)

  # Si no hay columna run, asignar run por orden cronologico de niveles
  # dentro de cada (source, pollutant).
  if (!has_run) {
    valid$run <- NA_integer_
    sp_groups <- unique(valid[, c("source", "pollutant"), drop = FALSE])
    for (j in seq_len(nrow(sp_groups))) {
      sg <- sp_groups[j, ]
      idx <- valid$source == sg$source & valid$pollutant == sg$pollutant
      sub <- valid[idx, , drop = FALSE]
      level_order <- unique(sub$level[order(sub$hour_start)])
      valid$run[idx] <- match(sub$level, level_order)
    }
  }

  group_cols <- if (has_run) {
    c("source", "pollutant", "level", "unit", "instrument", "run")
  } else {
    c("source", "pollutant", "level", "unit", "instrument")
  }
  groups <- unique(valid[, group_cols, drop = FALSE])
  results <- vector("list", nrow(groups))

  for (i in seq_len(nrow(groups))) {
    g <- groups[i, ]
    if (has_run) {
      rows <- valid[
        valid$source == g$source &
          valid$pollutant == g$pollutant &
          valid$level == g$level &
          valid$unit == g$unit &
          valid$instrument == g$instrument &
          valid$run == g$run,
        ,
        drop = FALSE
      ]
    } else {
      rows <- valid[
        valid$source == g$source &
          valid$pollutant == g$pollutant &
          valid$level == g$level &
          valid$unit == g$unit &
          valid$instrument == g$instrument,
        ,
        drop = FALSE
      ]
    }
    rows <- rows[order(rows$hour_start), , drop = FALSE]
    n_hours <- nrow(rows)
    # xᵢ: promedio de los promedios horarios, redondeado a 3 decimales.
    final_mean <- round(mean(rows$mean_value), 3)
    final_sd   <- round(if (n_hours > 1) sd(rows$mean_value) else rows$sd_value[1], 3)
    final_u    <- round(if (n_hours > 1) final_sd / sqrt(n_hours) else rows$u_value[1], 3)

    mean_h1 <- round(if (n_hours >= 1) rows$mean_value[1] else NA_real_, 3)
    mean_h2 <- round(if (n_hours >= 2) rows$mean_value[2] else NA_real_, 3)
    mean_h3 <- round(if (n_hours >= 3) rows$mean_value[3] else NA_real_, 3)

    run_val <- if (has_run) g$run else rows$run[1]

    results[[i]] <- data.frame(
      source = g$source,
      run = run_val,
      pollutant = g$pollutant,
      level = g$level,
      unit = g$unit,
      instrument = g$instrument,
      mean_h1 = mean_h1,
      mean_h2 = mean_h2,
      mean_h3 = mean_h3,
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
