#!/usr/bin/env Rscript

# Build one pt_app-compatible data set from the available R1, R2 and R3
# minute data. Existing R3 scripts remain unchanged.

pt_required_columns <- function(df, columns, label) {
  missing <- setdiff(columns, names(df))
  if (length(missing)) {
    stop("Faltan columnas en ", label, ": ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

pt_unit <- function(pollutant) {
  ifelse(tolower(pollutant) == "co", "µmol/mol", "nmol/mol")
}

pt_format_nominal <- function(x) {
  trimws(formatC(round(x, 3L), format = "fg", digits = 12L, drop0trailing = TRUE))
}

read_round_file_compat <- function(path, tz = "America/Bogota") {
  raw <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  if (!"date time" %in% names(raw) && all(c("date", "time") %in% names(raw))) {
    raw[["date time"]] <- paste(trimws(raw$date), trimws(raw$time))
    raw$date <- NULL
    raw$time <- NULL
  }
  measurement <- grepl("^[A-Za-z0-9]+_[A-Za-z0-9]+$", names(raw)) & !grepl("_gen$", names(raw), ignore.case = TRUE)
  names(raw)[measurement] <- vapply(strsplit(names(raw)[measurement], "_", fixed = TRUE), function(parts) {
    paste(parts[1], toupper(parts[2]), sep = "_")
  }, character(1))
  temp <- tempfile(fileext = ".csv")
  on.exit(unlink(temp), add = TRUE)
  write.csv(raw, temp, row.names = FALSE, na = "")
  parsed <- read_raw_round_file(temp, tz = tz)
  attr(parsed, "file") <- normalizePath(path, mustWork = FALSE)
  parsed
}

summarise_round_file <- function(path, source, max_hours = 3L) {
  raw <- read_round_file_compat(path)
  capacity <- assess_hourly_capacity(raw, max_hours = max_hours)
  hourly <- compute_hourly_averages_runtime(raw, max_hours = max_hours, source = source)
  summary <- summarise_reference_levels(hourly)
  nominal <- merge(
    summary,
    unique(capacity[c("pollutant", "run", "level", "gen_nominal")]),
    by = c("pollutant", "run", "level"),
    all.x = TRUE,
    sort = FALSE
  )
  if (anyNA(nominal$gen_nominal)) stop("No se pudo asignar nivel nominal a ", basename(path), call. = FALSE)
  nominal$unit <- pt_unit(nominal$pollutant)
  nominal$level <- paste0(pt_format_nominal(nominal$gen_nominal), "-", nominal$unit)
  nominal$gen_nominal <- NULL
  nominal
}

assign_round_roles <- function(summary, keep_participants = TRUE) {
  is_reference <- grepl("^4u", summary$instrument, ignore.case = TRUE)
  if (!any(is_reference)) stop("La ronda no contiene serial de referencia 4U", call. = FALSE)
  if (keep_participants && !any(!is_reference)) stop("La ronda no contiene participante", call. = FALSE)
  out <- summary[is_reference | keep_participants, , drop = FALSE]
  out$serial <- out$instrument
  out$tipo <- ifelse(grepl("^4u", out$instrument, ignore.case = TRUE), "referencia", "participante")
  out$participant_id <- ifelse(out$tipo == "referencia", "ref", out$instrument)
  out$round_source <- out$source
  out$source <- ifelse(out$tipo == "referencia", "ronda_referencia", "ronda_participante")
  out$reference_role <- NA_character_
  out$simulated <- FALSE
  out
}

read_co_so2_participant <- function(path) {
  if (!file.exists(path)) stop("No existe archivo CO/SO2: ", path, call. = FALSE)
  raw <- read.csv(path, skip = 2L, header = FALSE, stringsAsFactors = FALSE,
                  col.names = c("date_time", "co", "so2"), check.names = FALSE)
  raw$co <- suppressWarnings(as.numeric(sub("_C$", "", trimws(raw$co))))
  raw$so2 <- suppressWarnings(as.numeric(trimws(raw$so2)))
  raw <- raw[is.finite(raw$co) & is.finite(raw$so2), , drop = FALSE]
  if (nrow(raw) < 25L) stop("Muy pocos datos válidos en archivo CO/SO2", call. = FALSE)
  raw
}

# The acquisition is one baseline followed by four contiguous plateaus. K-means
# separates transition minutes without requiring hard-coded concentrations;
# ordered centers provide stable PT level numbers from low to high.
detect_five_plateaus <- function(values) {
  values <- as.numeric(values)
  valid <- is.finite(values)
  if (sum(valid) < 25L) stop("Se requieren al menos 25 mediciones válidas", call. = FALSE)
  initial <- as.numeric(quantile(values[valid], probs = seq(0.05, 0.95, length.out = 5L), names = FALSE))
  fit <- kmeans(values[valid], centers = initial, iter.max = 100L, algorithm = "Lloyd")
  centers <- as.numeric(fit$centers)
  order_map <- order(centers)
  levels <- integer(length(values))
  levels[valid] <- match(fit$cluster, order_map)
  counts <- tabulate(levels[valid], nbins = 5L)
  if (any(counts < 10L)) stop("No se detectaron cinco mesetas estables", call. = FALSE)
  list(level = levels, centers = sort(centers), counts = counts)
}

summarise_co_so2_participant <- function(path) {
  raw <- read_co_so2_participant(path)
  specs <- list(
    co = list(column = "co", unit = "µmol/mol", serial = "UNAL_CO"),
    so2 = list(column = "so2", unit = "nmol/mol", serial = "UNAL_SO2")
  )
  # Both channels were acquired simultaneously. CO has the clearest separation,
  # so its five clusters define common time windows for CO and SO2 and exclude
  # the same transition minutes from both summaries.
  detected <- detect_five_plateaus(raw$co)
  rows <- list()
  for (pollutant in names(specs)) {
    spec <- specs[[pollutant]]
    for (level_index in seq_len(5L)) {
      x <- raw[[spec$column]][detected$level == level_index]
      n <- length(x)
      rows[[length(rows) + 1L]] <- data.frame(
        source = "rr_unal_participante", round_source = "r1_rr", run = level_index, pollutant = pollutant,
        level_index = level_index, unit = spec$unit, instrument = spec$serial,
        mean_h1 = NA_real_, mean_h2 = NA_real_, mean_h3 = NA_real_,
        mean_value = round(mean(x), 3L), sd_value = round(sd(x), 3L),
        u_value = round(sd(x) / sqrt(n), 3L), n_hours = NA_integer_,
        hour_starts = NA_character_, participant_id = "Jaison",
        tipo = "participante", serial = spec$serial,
        reference_role = NA_character_, simulated = FALSE, stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}

add_nominal_levels <- function(participants, r1_references) {
  nominal <- r1_references[c("pollutant", "level")]
  nominal$nominal <- suppressWarnings(as.numeric(sub("-.*$", "", nominal$level)))
  nominal <- nominal[order(nominal$pollutant, nominal$nominal), , drop = FALSE]
  nominal$level_index <- ave(nominal$nominal, nominal$pollutant, FUN = seq_along)
  key <- paste(nominal$pollutant, nominal$level_index)
  participants$level <- nominal$level[match(paste(participants$pollutant, participants$level_index), key)]
  participants$level_index <- NULL
  if (anyNA(participants$level)) stop("No se pudieron mapear mesetas CO/SO2 a niveles R1", call. = FALSE)
  participants
}

harmonize_round_levels <- function(earlier, canonical) {
  pollutants <- intersect(unique(earlier$pollutant), unique(canonical$pollutant))
  for (pollutant in pollutants) {
    old_levels <- unique(earlier$level[earlier$pollutant == pollutant])
    new_levels <- unique(canonical$level[canonical$pollutant == pollutant])
    old_levels <- old_levels[order(as.numeric(sub("-.*$", "", old_levels)))]
    new_levels <- new_levels[order(as.numeric(sub("-.*$", "", new_levels)))]
    if (length(old_levels) != 5L || length(new_levels) != 5L) {
      stop("Se esperaban cinco niveles para armonizar ", pollutant, call. = FALSE)
    }
    idx <- earlier$pollutant == pollutant
    earlier$level[idx] <- new_levels[match(earlier$level[idx], old_levels)]
  }
  earlier
}

make_synthetic_reference <- function(reference1) {
  out <- reference1
  level_index <- ave(seq_len(nrow(out)), out$pollutant, FUN = seq_along)
  direction <- ifelse(level_index %% 2L == 0L, 1, -1)
  scale <- pmax(abs(out$mean_value), 1)
  out$mean_value <- round(out$mean_value + direction * scale * 0.001, 3L)
  out$mean_h1 <- out$mean_value
  out$mean_h2 <- NA_real_
  out$mean_h3 <- NA_real_
  out$sd_value <- round(pmax(out$sd_value, scale * 0.0005), 3L)
  out$u_value <- round(pmax(out$u_value, out$sd_value / sqrt(60)), 3L)
  out$instrument <- paste0("4U_SYNTH_", toupper(out$pollutant))
  out$serial <- out$instrument
  out$participant_id <- "ref"
  out$source <- "r1_referencia_sintetica"
  out$run <- paste0("synthetic_", level_index)
  out$reference_role <- "ref2"
  out$simulated <- TRUE
  out
}

apply_uncertainty_table <- function(out, path) {
  if (!file.exists(path)) stop("No existe tabla de incertidumbres: ", path, call. = FALSE)
  lookup <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8")
  pt_required_columns(
    lookup,
    c("ronda", "contaminante", "nivel", "u_referencia", "U_referencia", "u_participante", "U_participante", "k_factor"),
    "tabla de incertidumbres"
  )

  source_round <- ifelse(
    grepl("^r3_", out$round_source), "R3",
    ifelse(grepl("^r2a_", out$round_source), "R2A",
      ifelse(grepl("^r2b_", out$round_source), "R2B",
        ifelse(grepl("^r2c_", out$round_source), "R2C", "R1")
      )
    )
  )
  out$.uncertainty_round <- source_round
  out$.level_value <- suppressWarnings(as.numeric(sub("-.*$", "", out$level)))
  lookup$.level_value <- suppressWarnings(as.numeric(sub("-.*$", "", lookup$nivel)))

  out$.level_rank <- ave(out$.level_value, paste(out$pollutant, out$.uncertainty_round), FUN = function(x) {
    match(x, sort(unique(x)))
  })
  lookup$.level_rank <- ave(lookup$.level_value, paste(lookup$contaminante, lookup$ronda), FUN = function(x) {
    match(x, sort(unique(x)))
  })

  key_out <- paste(out$.uncertainty_round, out$pollutant, out$.level_rank, sep = "|")
  key_lookup <- paste(lookup$ronda, lookup$contaminante, lookup$.level_rank, sep = "|")
  position <- match(key_out, key_lookup)
  if (anyNA(position)) {
    missing <- unique(key_out[is.na(position)])
    stop("Sin incertidumbre para: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  is_reference <- out$tipo == "referencia"
  out$u_value <- ifelse(is_reference, lookup$u_referencia[position], lookup$u_participante[position])
  out$u_exp <- ifelse(is_reference, lookup$U_referencia[position], lookup$U_participante[position])
  out$k_factor <- lookup$k_factor[position]
  out$uncertainty_round <- out$.uncertainty_round
  out$.uncertainty_round <- NULL
  out$.level_value <- NULL
  out$.level_rank <- NULL
  out
}

validate_generalized_pt <- function(out) {
  pt_required_columns(out, c("participant_id", "pollutant", "level", "mean_value", "u_value", "u_exp", "k_factor", "tipo", "n_lab", "serial"), "salida")
  expected_participants <- c(co = 1L, so2 = 1L, o3 = 2L, no = 2L, no2 = 2L)
  for (pollutant in names(expected_participants)) {
    rows <- out[out$pollutant == pollutant, , drop = FALSE]
    if (length(unique(rows$level)) != 5L) stop("Se esperaban 5 niveles para ", pollutant, call. = FALSE)
    participants <- unique(rows$participant_id[rows$tipo == "participante"])
    references <- unique(rows$serial[rows$tipo == "referencia"])
    if (length(participants) != expected_participants[[pollutant]]) stop("Participantes inesperados para ", pollutant, call. = FALSE)
    if (length(references) != 2L) stop("Referencias inesperadas para ", pollutant, call. = FALSE)
    reference_rows <- rows[rows$tipo == "referencia", , drop = FALSE]
    roles_by_level <- table(reference_rows$level, reference_rows$reference_role)
    if (!all(c("ref1", "ref2") %in% colnames(roles_by_level)) || any(roles_by_level[, c("ref1", "ref2"), drop = FALSE] != 1L)) {
      stop("Se esperaba una ref1 y una ref2 por nivel para ", pollutant, call. = FALSE)
    }
    if (!all(rows$n_lab == expected_participants[[pollutant]])) stop("n_lab inesperado para ", pollutant, call. = FALSE)
  }
  if (any(out$simulated & !(out$pollutant %in% c("co", "so2") & out$reference_role == "ref2"))) {
    stop("Simulación fuera de referencia 2 para CO/SO2", call. = FALSE)
  }
  if (any(!is.finite(out$mean_value)) || any(!is.finite(out$u_value)) ||
      any(!is.finite(out$u_exp)) || any(!is.finite(out$k_factor))) {
    stop("Valores o incertidumbres no finitos", call. = FALSE)
  }
  invisible(TRUE)
}

build_generalized_pt <- function(root = ".", output_path = NULL) {
  source(file.path(root, "R", "preprocessing", "hourly_averages.R"), local = globalenv())
  raw_dir <- file.path(root, "data_use_cases", "data", "raw")
  if (is.null(output_path)) output_path <- file.path(root, "data_use_cases", "data", "processed", "pt_rondas_1_2_3.csv")

  files <- data.frame(
    file = c("R1_CO.csv", "R1_SO2.csv", "R2A_O3.csv", "R2B_NO.csv", "R2C_NO2.csv", "R3_O3.csv", "R3_NO.csv", "R3_NO2.csv"),
    source = c("r1_co", "r1_so2", "r2a_o3", "r2b_no", "r2c_no2", "r3_o3", "r3_no", "r3_no2"),
    keep_participants = c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )
  paths <- file.path(raw_dir, files$file)
  missing <- paths[!file.exists(paths)]
  if (length(missing)) stop("Faltan archivos raw: ", paste(missing, collapse = ", "), call. = FALSE)

  rounds <- lapply(seq_len(nrow(files)), function(i) {
    assign_round_roles(summarise_round_file(paths[i], files$source[i]), files$keep_participants[i])
  })
  for (i in seq_along(rounds)) {
    is_reference <- rounds[[i]]$tipo == "referencia"
    rounds[[i]]$reference_role[is_reference] <- if (i <= 5L) "ref1" else "ref2"
  }
  # R2 and R3 nominal settings differ slightly. Use the latest (R3) nominal
  # labels as the shared five-level grid so both participants are comparable.
  rounds[[3]] <- harmonize_round_levels(rounds[[3]], rounds[[6]])
  rounds[[4]] <- harmonize_round_levels(rounds[[4]], rounds[[7]])
  rounds[[5]] <- harmonize_round_levels(rounds[[5]], rounds[[8]])
  r1_reference <- do.call(rbind, rounds[1:2])
  participant <- add_nominal_levels(
    summarise_co_so2_participant(file.path(root, "data_use_cases", "R_r", "Datos R&R Jaison CO y SO2 JUL 2.txt")),
    r1_reference
  )
  out <- do.call(rbind, c(list(r1_reference, make_synthetic_reference(r1_reference), participant), rounds[3:8]))
  out$n_lab <- unname(c(co = 1L, so2 = 1L, o3 = 2L, no = 2L, no2 = 2L)[out$pollutant])
  out <- apply_uncertainty_table(
    out,
    file.path(root, "data_use_cases", "outputs", "tables", "valores_e_incertidumbres.csv")
  )

  preferred <- c("pollutant", "level", "source", "round_source", "run", "unit", "instrument", "mean_h1", "mean_h2", "mean_h3", "mean_value", "sd_value", "u_value", "u_exp", "k_factor", "uncertainty_round", "n_hours", "hour_starts", "participant_id", "tipo", "n_lab", "serial", "reference_role", "simulated")
  out <- out[c(intersect(preferred, names(out)), setdiff(names(out), preferred))]
  out <- out[order(match(out$pollutant, c("co", "so2", "o3", "no", "no2")), suppressWarnings(as.numeric(sub("-.*$", "", out$level))), out$tipo, out$serial), , drop = FALSE]
  rownames(out) <- NULL
  validate_generalized_pt(out)
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  write.csv(out, output_path, row.names = FALSE, na = "")
  invisible(out)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  root <- if (length(args) >= 1L) args[1] else "."
  output <- if (length(args) >= 2L) args[2] else NULL
  result <- build_generalized_pt(root, output)
  final_path <- if (is.null(output)) file.path(root, "data_use_cases", "data", "processed", "pt_rondas_1_2_3.csv") else output
  cat("Consolidado PT generado: ", final_path, "\n", sep = "")
  cat("Filas: ", nrow(result), "\n", sep = "")
}
