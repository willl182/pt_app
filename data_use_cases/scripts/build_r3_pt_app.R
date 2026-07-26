#!/usr/bin/env Rscript

required_columns <- function(df, columns, label) {
  missing <- setdiff(columns, names(df))
  if (length(missing) > 0) {
    stop(
      "Faltan columnas obligatorias en ", label, ": ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
}

read_csv_input <- function(path, label) {
  if (!file.exists(path)) {
    stop("No existe archivo de ", label, ": ", path, call. = FALSE)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

format_nominal <- function(x, digits = 1L) {
  if (any(!is.finite(x))) {
    stop("gen_nominal no finito", call. = FALSE)
  }
  if (any(x < 0)) {
    stop(
      "gen_nominal negativo: ",
      paste(unique(x[x < 0]), collapse = ", "),
      call. = FALSE
    )
  }

  formatC(round(x, digits), format = "fg", drop0trailing = TRUE)
}

build_nominal_map <- function(capacity) {
  required_columns(
    capacity,
    c("pollutant", "run", "level", "gen_nominal"),
    "capacidad horaria"
  )

  nominal_map <- unique(capacity[c("pollutant", "run", "level", "gen_nominal")])
  key <- paste(nominal_map$pollutant, nominal_map$run, sep = "\r")
  duplicated_keys <- unique(key[duplicated(key) | duplicated(key, fromLast = TRUE)])
  if (length(duplicated_keys) > 0) {
    stop(
      "Mapa nominal ambiguo para pollutant/run: ",
      paste(gsub("\r", "/", duplicated_keys, fixed = TRUE), collapse = ", "),
      call. = FALSE
    )
  }

  nominal_map
}

join_nominal_levels <- function(summary, capacity) {
  required_columns(
    summary,
    c(
      "source", "run", "pollutant", "level", "unit", "instrument",
      "mean_value", "u_value"
    ),
    "resumen de niveles"
  )

  nominal_map <- build_nominal_map(capacity)
  nominal_map <- nominal_map[c("pollutant", "run", "level", "gen_nominal")]
  names(nominal_map)[names(nominal_map) == "level"] <- ".level_capacity"

  summary$.row_order <- seq_len(nrow(summary))
  joined <- merge(
    summary,
    nominal_map,
    by = c("pollutant", "run"),
    all.x = TRUE,
    sort = FALSE
  )
  joined <- joined[order(joined$.row_order), , drop = FALSE]

  orphan <- is.na(joined$gen_nominal)
  if (any(orphan)) {
    orphan_keys <- unique(paste(joined$pollutant[orphan], joined$run[orphan], sep = "/"))
    stop(
      "Sin nivel nominal para pollutant/run: ",
      paste(orphan_keys, collapse = ", "),
      call. = FALSE
    )
  }

  ordinal_mismatch <- as.character(joined$level) != as.character(joined$.level_capacity)
  if (any(ordinal_mismatch, na.rm = TRUE)) {
    mismatch_keys <- unique(paste(
      joined$pollutant[ordinal_mismatch],
      joined$run[ordinal_mismatch],
      sep = "/"
    ))
    stop(
      "Nivel ordinal no coincide con capacidad para pollutant/run: ",
      paste(mismatch_keys, collapse = ", "),
      call. = FALSE
    )
  }

  joined$level <- paste0(format_nominal(joined$gen_nominal), "-", joined$unit)
  joined$.level_capacity <- NULL
  joined$gen_nominal <- NULL
  joined$.row_order <- NULL
  joined
}

split_r3_roles <- function(data) {
  reference_row <- grepl("^4u", data$instrument, ignore.case = TRUE)
  reference_serials <- unique(data$instrument[reference_row])

  if (length(reference_serials) != 1L) {
    stop(
      "Se esperaba exactamente 1 serial de referencia con prefijo 4U; encontrados: ",
      length(reference_serials),
      call. = FALSE
    )
  }

  participants <- data[!reference_row, , drop = FALSE]
  reference <- data[reference_row, , drop = FALSE]

  if (nrow(participants) == 0L) {
    stop(
      "No se encontraron filas de participante (todos los seriales tienen prefijo 4U)",
      call. = FALSE
    )
  }

  participants$participant_id <- participants$instrument
  participants$source <- "ronda_participante"
  participants$tipo <- "participante"

  reference$serial <- reference$instrument
  reference$instrument <- "calaire_ref"
  reference$participant_id <- "calaire_ref"
  reference$source <- "ronda"
  reference$tipo <- "referencia"

  list(participants = participants, reference = reference)
}

validate_r3_output <- function(complete, expected_levels = 5L, expected_n_lab = NULL) {
  required_columns(
    complete,
    c("participant_id", "pollutant", "level", "mean_value", "u_value", "tipo", "n_lab"),
    "consolidado R3"
  )

  bad_level <- is.na(complete$level) |
    !grepl("^[0-9]+(\\.[0-9]+)?-", complete$level)
  if (any(bad_level)) {
    stop(
      "Niveles no nominales: ",
      paste(unique(complete$level[bad_level]), collapse = ", "),
      call. = FALSE
    )
  }

  expected_types <- c("participante", "referencia")
  missing_types <- setdiff(expected_types, unique(complete$tipo))
  if (length(missing_types) > 0L) {
    stop(
      "Tipos ausentes en consolidado R3: ",
      paste(missing_types, collapse = ", "),
      call. = FALSE
    )
  }

  level_rows <- unique(complete[c("pollutant", "tipo", "level")])
  counts <- table(
    factor(level_rows$pollutant, levels = unique(complete$pollutant)),
    factor(level_rows$tipo, levels = expected_types)
  )
  wrong <- counts != expected_levels
  if (any(wrong)) {
    wrong_indexes <- which(wrong, arr.ind = TRUE)
    details <- apply(wrong_indexes, 1, function(i) {
      paste0(rownames(counts)[i[1]], "/", colnames(counts)[i[2]], "=", counts[i[1], i[2]])
    })
    stop(
      "Conteo de niveles inesperado (se esperaban ", expected_levels,
      " por contaminante y tipo): ", paste(details, collapse = ", "),
      call. = FALSE
    )
  }

  n_participants <- length(unique(
    complete$participant_id[complete$tipo == "participante"]
  ))
  if (is.null(expected_n_lab)) expected_n_lab <- n_participants
  if (any(is.na(complete$n_lab)) || !all(complete$n_lab == expected_n_lab)) {
    stop("n_lab distinto de ", expected_n_lab, call. = FALSE)
  }

  na_rows <- is.na(complete$mean_value) | is.na(complete$u_value)
  if (any(na_rows)) {
    stop(
      "NA en mean_value/u_value: ", sum(na_rows), " filas",
      call. = FALSE
    )
  }

  ref <- complete[complete$tipo == "referencia", , drop = FALSE]
  nominal <- as.numeric(sub("-.*$", "", ref$level))
  comparable <- is.finite(nominal) & nominal > 0 & is.finite(ref$mean_value)
  rel_dev <- rep(NA_real_, nrow(ref))
  rel_dev[comparable] <- abs(ref$mean_value[comparable] - nominal[comparable]) /
    nominal[comparable]
  flagged <- comparable & rel_dev > 0.05
  if (any(flagged)) {
    warning(
      "Nivel nominal se aparta >5% de la referencia medida: ",
      paste0(
        ref$pollutant[flagged], " ", ref$level[flagged],
        " (ref=", round(ref$mean_value[flagged], 2), ")",
        collapse = "; "
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

build_r3_pt_app <- function(summary_path, capacity_path, participants_path, reference_path) {
  summary <- read_csv_input(summary_path, "resumen de niveles")
  capacity <- read_csv_input(capacity_path, "capacidad horaria")
  nominal <- join_nominal_levels(summary, capacity)
  split <- split_r3_roles(nominal)

  dir.create(dirname(participants_path), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(reference_path), recursive = TRUE, showWarnings = FALSE)
  write.csv(split$participants, participants_path, row.names = FALSE, na = "")
  write.csv(split$reference, reference_path, row.names = FALSE, na = "")

  invisible(split)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  processed_dir <- "data_use_cases/data/processed"
  summary_path <- if (length(args) >= 1L) args[1] else file.path(processed_dir, "r3_resumen_niveles.csv")
  capacity_path <- if (length(args) >= 2L) args[2] else file.path(processed_dir, "r3_capacidad_horaria.csv")
  participants_path <- if (length(args) >= 3L) args[3] else file.path(processed_dir, "ronda_3_p_ronda.csv")
  reference_path <- if (length(args) >= 4L) args[4] else file.path(processed_dir, "ronda_3_r.csv")

  result <- build_r3_pt_app(
    summary_path,
    capacity_path,
    participants_path,
    reference_path
  )

  cat("Intermedios R3 generados:\n")
  cat("  Participantes: ", participants_path, " (", nrow(result$participants), " filas)\n", sep = "")
  cat("  Referencia:    ", reference_path, " (", nrow(result$reference), " filas)\n", sep = "")
}
