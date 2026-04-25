# Hourly averages for estabilidad/homogeneidad blocks.
# Valid hour: exactly 60 unique minutes (00-59) with no NA in the source column.
# mean_h = mean(x), sd_h = sd(x), u_h = sd_h / sqrt(60)

compute_hourly_averages <- function(clean_data, design, tz = "America/Bogota") {
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

      full_hour <- length(unique(mins)) == 60 &&
        identical(sort(unique(mins)), as.integer(0:59)) &&
        n_valid == 60

      flags <- character(0)
      if (nrow(hr_rows) != 60)  flags <- c(flags, paste0("n=", nrow(hr_rows)))
      if (!full_hour)            flags <- c(flags, "partial_or_na")

      if (full_hour) {
        mean_v <- mean(vals)
        sd_v   <- sd(vals)
        u_v    <- sd_v / sqrt(60)
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

# Hourly averages for ronda data (two instruments per pollutant, level auto-assigned).
# Instruments: co_calaire_ppm, co_invitado1_ppm, so2_calaire_ppb, so2_invitado1_ppb.
# Level is determined per-pollutant per-hour from the generator column and niveles_calaire.csv.
# Valid hour: exactly 60 unique minutes (00-59), no NA in instrument column, single level.
compute_hourly_averages_ronda <- function(clean_data, levels_table, tz = "America/Bogota") {
  instruments <- list(
    list(pollutant = "co",  col = "co_calaire_ppm",    gen_col = "co_gen_ppm",
         unit = "ppm", instrument = "co_calaire",    participant_id = "CALAIRE"),
    list(pollutant = "co",  col = "co_invitado1_ppm",   gen_col = "co_gen_ppm",
         unit = "ppm", instrument = "co_invitado1",   participant_id = "Invitado1"),
    list(pollutant = "so2", col = "so2_calaire_ppb",   gen_col = "so2_gen_ppb",
         unit = "ppb", instrument = "so2_calaire",   participant_id = "CALAIRE"),
    list(pollutant = "so2", col = "so2_invitado1_ppb",  gen_col = "so2_gen_ppb",
         unit = "ppb", instrument = "so2_invitado1",  participant_id = "Invitado1")
  )

  valid_rows <- clean_data[!is.na(clean_data$timestamp), , drop = FALSE]
  if (nrow(valid_rows) == 0) return(data.frame())

  valid_rows$hour_start <- as.POSIXct(
    format(valid_rows$timestamp, "%Y-%m-%d %H:00:00", tz = tz),
    format = "%Y-%m-%d %H:%M:%S", tz = tz
  )

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
  for (h_ts in sort(unique(valid_rows$hour_start))) {
    h_ts_p  <- as.POSIXct(h_ts, origin = "1970-01-01", tz = tz)
    hr_rows <- valid_rows[valid_rows$hour_start == h_ts_p, , drop = FALSE]
    mins    <- as.integer(format(hr_rows$timestamp, "%M", tz = tz))
    full_minutes <- length(unique(mins)) == 60 &&
      identical(sort(unique(mins)), as.integer(0:59))

    for (inst in instruments) {
      pollutant <- inst$pollutant
      col       <- inst$col
      gen_col   <- inst$gen_col

      if (!col %in% names(hr_rows) || !gen_col %in% names(hr_rows)) next

      vals      <- hr_rows[[col]]
      gen_vals  <- hr_rows[[gen_col]]
      n_valid   <- sum(!is.na(vals))
      lvl       <- assign_level(gen_vals, pollutant)
      gen_clean <- gen_vals[!is.na(gen_vals)]
      gen_mean_v <- if (length(gen_clean) > 0) mean(gen_clean) else NA_real_
      gen_sd_v   <- if (length(gen_clean) > 1) sd(gen_clean)   else NA_real_

      full_hour <- full_minutes && n_valid == 60 && !lvl$mixed && !is.na(lvl$label)

      flags <- character(0)
      if (nrow(hr_rows) != 60)                            flags <- c(flags, paste0("n=", nrow(hr_rows)))
      if (n_valid < nrow(hr_rows))                        flags <- c(flags, paste0("na_vals=", nrow(hr_rows) - n_valid))
      if (lvl$mixed)                                      flags <- c(flags, "mixed_level")
      if (!lvl$mixed && is.na(lvl$label))                 flags <- c(flags, "no_level_match")

      if (full_hour) {
        mean_v <- mean(vals)
        sd_v   <- sd(vals)
        u_v    <- sd_v / sqrt(60)
      } else {
        mean_v <- NA_real_
        sd_v   <- NA_real_
        u_v    <- NA_real_
      }

      results[[length(results) + 1]] <- data.frame(
        source            = "ronda",
        date              = format(h_ts_p, "%Y-%m-%d"),
        hour_start        = format(h_ts_p, "%Y-%m-%d %H:%M:%S"),
        pollutant         = pollutant,
        level             = lvl$label,
        generated_nominal = lvl$nominal,
        generated_mean    = gen_mean_v,
        generated_sd      = gen_sd_v,
        instrument        = inst$instrument,
        participant_id    = inst$participant_id,
        mean_value        = mean_v,
        sd_value          = sd_v,
        u_value           = u_v,
        n                 = n_valid,
        unit              = inst$unit,
        valid_hour        = full_hour,
        validation_flags  = paste(flags, collapse = "|"),
        stringsAsFactors  = FALSE
      )
    }
  }

  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}
