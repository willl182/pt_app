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

.or_default <- function(x, default) {
  if (is.null(x) || length(x) == 0L) default else x
}

MIN_CHUNK_MINUTES <- 45L

.runtime_chunks <- function(runtime_min) {
  if (length(runtime_min) == 0L) return(list())
  split(seq_along(runtime_min), floor((runtime_min - runtime_min[1]) / 60))
}

.nominal_value <- function(values) {
  values <- values[!is.na(values)]
  if (length(values) == 0L) return(NA_real_)
  unique_values <- unique(values)
  counts <- vapply(unique_values, function(value) sum(values == value), integer(1))
  unique_values[which.max(counts)]
}

read_raw_round_file <- function(path, tz = "America/Bogota") {
  raw <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  required <- c("date time", "runtime", "level")
  missing <- setdiff(required, names(raw))
  if (length(missing) > 0L) stop("Missing required columns: ", paste(missing, collapse = ", "))

  generator_cols <- grep("^[A-Za-z0-9]+_gen$", names(raw), value = TRUE)
  if (length(generator_cols) != 1L) stop("Expected exactly one *_gen column")
  pollutant <- sub("_gen$", "", generator_cols)
  instrument_cols <- grep(paste0("^", pollutant, "_[A-Z0-9]+$"), names(raw), value = TRUE)
  instrument_cols <- setdiff(instrument_cols, generator_cols)
  if (length(instrument_cols) == 0L) stop("No instrument columns found for pollutant '", pollutant, "'")

  runtime_parts <- strsplit(trimws(raw$runtime), ":", fixed = TRUE)
  valid_runtime <- lengths(runtime_parts) == 2L
  runtime_min <- rep(NA_integer_, nrow(raw))
  runtime_min[valid_runtime] <- vapply(runtime_parts[valid_runtime], function(x) {
    hours <- suppressWarnings(as.integer(x[1]))
    minutes <- suppressWarnings(as.integer(x[2]))
    if (is.na(hours) || is.na(minutes) || hours < 0L || minutes < 0L || minutes > 59L) return(NA_integer_)
    60L * hours + minutes
  }, integer(1))
  if (anyNA(runtime_min)) stop("Invalid runtime value in ", path)

  wall_clock <- trimws(raw[["date time"]])
  is_24_hour <- grepl(" 24:[0-5][0-9]$", wall_clock)
  normalized_clock <- wall_clock
  normalized_clock[is_24_hour] <- sub(" 24:", " 00:", wall_clock[is_24_hour])
  timestamp <- as.POSIXct(normalized_clock, format = "%m/%d/%y %H:%M", tz = tz)
  if (any(is_24_hour)) timestamp[is_24_hour] <- timestamp[is_24_hour] + 24 * 60 * 60

  out <- data.frame(
    timestamp = timestamp,
    runtime_min = runtime_min,
    level = trimws(as.character(raw$level)),
    gen_value = suppressWarnings(as.numeric(raw[[generator_cols]])),
    stringsAsFactors = FALSE
  )
  for (col in instrument_cols) out[[col]] <- suppressWarnings(as.numeric(raw[[col]]))

  attr(out, "pollutant") <- tolower(pollutant)
  attr(out, "instrument_cols") <- instrument_cols
  attr(out, "instrument_serials") <- sub(paste0("^", pollutant, "_"), "", instrument_cols)
  attr(out, "file") <- normalizePath(path, mustWork = FALSE)
  out
}

.raw_round_blocks <- function(raw_df) {
  if (nrow(raw_df) == 0L) return(integer(0))
  level <- as.character(raw_df$level)
  cumsum(c(TRUE, level[-1] != level[-length(level)]))
}

assess_hourly_capacity <- function(raw_df, max_hours = 3L) {
  required <- c("runtime_min", "level", "gen_value")
  missing <- setdiff(required, names(raw_df))
  if (length(missing) > 0L) stop("Missing required columns: ", paste(missing, collapse = ", "))
  if (length(max_hours) != 1L || is.na(max_hours) || max_hours < 1L) stop("max_hours must be at least 1")
  max_hours <- as.integer(max_hours)

  block_id <- .raw_round_blocks(raw_df)
  keep <- !is.na(raw_df$level) & tolower(raw_df$level) != "estab"
  ids <- unique(block_id[keep])
  if (length(ids) == 0L) return(data.frame())

  results <- lapply(ids, function(id) {
    rows <- raw_df[block_id == id, , drop = FALSE]
    rows <- rows[order(rows$runtime_min), , drop = FALSE]
    chunks <- .runtime_chunks(rows$runtime_min)
    chunk_sizes <- vapply(chunks, length, integer(1))
    n_minutes <- nrow(rows)
    runtime_span <- max(rows$runtime_min) - min(rows$runtime_min) + 1L
    n_full_hours <- sum(chunk_sizes >= 60L)
    residual_minutes <- if (length(chunk_sizes) > 0L && chunk_sizes[length(chunk_sizes)] < 60L) {
      chunk_sizes[length(chunk_sizes)]
    } else {
      0L
    }
    residual_valid <- residual_minutes >= MIN_CHUNK_MINUTES
    n_computable <- sum(chunk_sizes >= MIN_CHUNK_MINUTES)
    gen_nominal <- .nominal_value(rows$gen_value)
    is_zero <- !is.na(gen_nominal) && abs(gen_nominal) < .Machine$double.eps^0.5
    minimum_hours <- if (is_zero) 1L else 2L
    block_limit <- if (is_zero) 1L else max_hours

    data.frame(
      file = .or_default(attr(raw_df, "file"), NA_character_),
      pollutant = .or_default(attr(raw_df, "pollutant"), NA_character_),
      run = id,
      level = rows$level[1],
      gen_nominal = gen_nominal,
      n_minutes = n_minutes,
      runtime_span = runtime_span,
      runtime_start = min(rows$runtime_min),
      runtime_end = max(rows$runtime_min),
      n_full_hours = n_full_hours,
      residual_minutes = residual_minutes,
      residual_valid = residual_valid,
      n_computable_hours = n_computable,
      n_reported_hours = min(n_computable, block_limit),
      meets_min_hours = n_computable >= minimum_hours,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, results)
}

compute_hourly_averages_runtime <- function(raw_df, max_hours = 3L,
                                            source = "ronda3_raw") {
  required <- c("timestamp", "runtime_min", "level", "gen_value")
  missing <- setdiff(required, names(raw_df))
  if (length(missing) > 0L) stop("Missing required columns: ", paste(missing, collapse = ", "))
  if (length(max_hours) != 1L || is.na(max_hours) || max_hours < 1L) stop("max_hours must be at least 1")
  max_hours <- as.integer(max_hours)

  pollutant <- .or_default(attr(raw_df, "pollutant"), NA_character_)
  instrument_cols <- attr(raw_df, "instrument_cols")
  if (is.null(instrument_cols)) instrument_cols <- grep(paste0("^", pollutant, "_[A-Za-z0-9]+$"), names(raw_df), value = TRUE)
  if (length(instrument_cols) == 0L) stop("No instrument columns available")

  block_id <- .raw_round_blocks(raw_df)
  keep_ids <- unique(block_id[!is.na(raw_df$level) & tolower(raw_df$level) != "estab"])
  results <- list()

  for (id in keep_ids) {
    block <- raw_df[block_id == id, , drop = FALSE]
    block <- block[order(block$runtime_min), , drop = FALSE]
    if (nrow(block) == 0L) next

    # Retain chunks with at least 45 observed clock-minute rows. Instrument
    # validity (at least 45 non-NA values) is evaluated separately below.
    chunks <- .runtime_chunks(block$runtime_min)
    gen_nominal <- .nominal_value(block$gen_value)
    is_zero <- !is.na(gen_nominal) && abs(gen_nominal) < .Machine$double.eps^0.5
    block_limit <- if (is_zero) 1L else max_hours
    chunks <- chunks[seq_len(min(length(chunks), block_limit))]
    chunks <- chunks[vapply(chunks, length, integer(1)) >= MIN_CHUNK_MINUTES]
    if (length(chunks) == 0L) next
    below_min_hours <- length(chunks) < if (is_zero) 1L else 2L

    for (chunk_idx in chunks) {
      hr_rows <- block[chunk_idx, , drop = FALSE]
      h_ts <- hr_rows$timestamp[1]
      hour_start <- if (is.na(h_ts)) NA_character_ else format(h_ts, "%Y-%m-%d %H:%M:%S")
      date <- if (is.na(h_ts)) NA_character_ else format(h_ts, "%Y-%m-%d")
      generated_mean <- if (all(is.na(hr_rows$gen_value))) NA_real_ else mean(hr_rows$gen_value, na.rm = TRUE)
      generated_sd <- if (sum(!is.na(hr_rows$gen_value)) > 1L) sd(hr_rows$gen_value, na.rm = TRUE) else NA_real_

      for (col in instrument_cols) {
        vals <- hr_rows[[col]]
        n_valid <- sum(!is.na(vals))
        valid_hour <- n_valid >= MIN_CHUNK_MINUTES
        flags <- character(0)
        if (n_valid < 60L) flags <- c(flags, paste0("n=", n_valid))
        if (!valid_hour) flags <- c(flags, "less_than_75pct")
        if (below_min_hours) flags <- c(flags, "below_min_hours")
        mean_v <- if (valid_hour) mean(vals, na.rm = TRUE) else NA_real_
        sd_v <- if (valid_hour && n_valid > 1L) sd(vals, na.rm = TRUE) else NA_real_
        u_v <- if (valid_hour && n_valid > 1L) sd_v / sqrt(n_valid) else NA_real_

        results[[length(results) + 1L]] <- data.frame(
          source = source, run = id, date = date, hour_start = hour_start,
          runtime_start = min(hr_rows$runtime_min), runtime_end = max(hr_rows$runtime_min),
          pollutant = pollutant, level = block$level[1],
          generated_nominal = round(gen_nominal, 3),
          generated_mean = round(generated_mean, 3), generated_sd = round(generated_sd, 3),
          instrument = sub(paste0("^", pollutant, "_"), "", col), source_column = col,
          mean_value = round(mean_v, 3), sd_value = round(sd_v, 3), u_value = round(u_v, 3),
          n = n_valid, unit = "nmol/mol", valid_hour = valid_hour,
          validation_flags = paste(flags, collapse = "|"), stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(results) == 0L) return(data.frame())
  do.call(rbind, results)
}

process_raw_round_files <- function(paths, tz = "America/Bogota", max_hours = 3L,
                                    print_assessment = TRUE) {
  assessments <- list()
  hourly <- list()
  for (path in paths) {
    raw <- read_raw_round_file(path, tz = tz)
    assessment <- assess_hourly_capacity(raw, max_hours = max_hours)
    if (print_assessment) print(assessment, row.names = FALSE)
    assessments[[length(assessments) + 1L]] <- assessment
    hourly[[length(hourly) + 1L]] <- compute_hourly_averages_runtime(raw, max_hours = max_hours)
  }
  assessments <- assessments[vapply(assessments, nrow, integer(1)) > 0L]
  hourly <- hourly[vapply(hourly, nrow, integer(1)) > 0L]
  list(
    assessment = if (length(assessments)) do.call(rbind, assessments) else data.frame(),
    hourly = if (length(hourly)) do.call(rbind, hourly) else data.frame()
  )
}
