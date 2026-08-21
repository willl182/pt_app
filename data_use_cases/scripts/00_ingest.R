# ===================================================================
# Unified ingestion for PT rounds R1, R2, and R3
#
# Reads three raw layouts, preserves instrument status literals, and
# normalizes timestamps, runtime, roles, and concomitant channels.
# ===================================================================

find_analysis_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    direct <- file.path(current, "data_use_cases")
    if (dir.exists(file.path(direct, "data", "raw"))) {
      return(direct)
    }
    if (dir.exists(file.path(current, "data", "raw")) &&
        dir.exists(file.path(current, "scripts"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) break
    current <- parent
  }
  stop("No se encontró data_use_cases desde: ", start)
}

ANALYSIS_ROOT <- find_analysis_root()
SCRIPT_DIR <- file.path(ANALYSIS_ROOT, "scripts")
RAW_DIR <- file.path(ANALYSIS_ROOT, "data", "raw")
OUTPUT_DIR <- file.path(ANALYSIS_ROOT, "outputs")

ROUND_FILES <- c(
  "R1_SO2.csv", "R1_CO.csv", "R2A_O3.csv", "R2B_NO.csv",
  "R2C_NO2.csv", "R3_O3.csv", "R3_NO.csv", "R3_NO2.csv"
)

round_metadata <- data.frame(
  file = ROUND_FILES,
  ronda = c("R1", "R1", "R2A", "R2B", "R2C", "R3", "R3", "R3"),
  analito = c("so2", "co", "o3", "no", "no2", "o3", "no", "no2"),
  unidad = c("ppb", "ppm", "ppb", "ppb", "ppb", "ppb", "ppb", "ppb"),
  participante = c("P1", "P1", "P1", "P1", "P1", "P2", "P2", "P2"),
  stringsAsFactors = FALSE
)

parse_runtime_minutes <- function(x) {
  parts <- strsplit(as.character(x), ":", fixed = TRUE)
  valid <- lengths(parts) == 2L
  result <- rep(NA_real_, length(x))
  result[valid] <- vapply(parts[valid], function(value) {
    60 * as.numeric(value[[1]]) + as.numeric(value[[2]])
  }, numeric(1))
  result
}

parse_round_timestamp <- function(date_value, time_value = NULL,
                                  tz = "America/Bogota") {
  if (is.null(time_value)) {
    timestamp_text <- trimws(as.character(date_value))
    split_at <- regexpr(" [0-9]{2}:[0-9]{2}$", timestamp_text)
    date_text <- substr(timestamp_text, 1L, split_at - 1L)
    time_text <- substr(timestamp_text, split_at + 1L, nchar(timestamp_text))
  } else {
    date_text <- trimws(as.character(date_value))
    time_text <- trimws(as.character(time_value))
  }

  is_24 <- time_text == "24:00"
  time_text[is_24] <- "00:00"
  parsed <- as.POSIXct(
    paste(date_text, time_text),
    format = "%m/%d/%y %H:%M",
    tz = tz
  )
  parsed[is_24] <- parsed[is_24] + 24 * 60 * 60
  parsed
}

extract_measure_columns <- function(column_names) {
  excluded <- c("date", "time", "date time", "runtime", "level")
  candidates <- setdiff(column_names, excluded)
  candidates[!grepl("_gen$", candidates)]
}

read_round <- function(path, tz = "America/Bogota") {
  file_name <- basename(path)
  metadata <- round_metadata[round_metadata$file == file_name, , drop = FALSE]
  if (nrow(metadata) != 1L) {
    stop("Archivo no registrado en round_metadata: ", file_name)
  }

  raw <- utils::read.csv(
    path,
    check.names = FALSE,
    colClasses = "character",
    na.strings = "",
    stringsAsFactors = FALSE
  )
  raw$source_row <- seq_len(nrow(raw)) + 1L

  if ("date time" %in% names(raw)) {
    raw$ts <- parse_round_timestamp(raw[["date time"]], tz = tz)
  } else if (all(c("date", "time") %in% names(raw))) {
    raw$ts <- parse_round_timestamp(raw$date, raw$time, tz = tz)
  } else {
    stop("Formato de timestamp no reconocido: ", file_name)
  }

  raw$runtime_min <- parse_runtime_minutes(raw$runtime)
  measure_columns <- extract_measure_columns(names(raw))
  generator_columns <- grep("_gen$", names(raw), value = TRUE)
  if (length(generator_columns) != 1L) {
    stop("Se esperaba una columna *_gen en ", file_name)
  }

  conversion_log <- lapply(measure_columns, function(column_name) {
    original <- raw[[column_name]]
    numeric_value <- suppressWarnings(as.numeric(original))
    bad <- !is.na(original) & is.na(numeric_value)
    raw[[column_name]] <<- numeric_value
    if (!any(bad)) {
      return(NULL)
    }
    data.frame(
      archivo = file_name,
      linea = raw$source_row[bad],
      columna = column_name,
      literal = original[bad],
      stringsAsFactors = FALSE
    )
  })
  conversion_log <- do.call(rbind, conversion_log)
  if (is.null(conversion_log)) {
    conversion_log <- data.frame(
      archivo = character(), linea = integer(), columna = character(),
      literal = character(), stringsAsFactors = FALSE
    )
  }

  raw[[generator_columns]] <- suppressWarnings(
    as.numeric(raw[[generator_columns]])
  )
  attr(raw, "metadata") <- metadata
  attr(raw, "measure_columns") <- measure_columns
  attr(raw, "generator_column") <- generator_columns
  attr(raw, "conversion_log") <- conversion_log
  raw
}

run_ingest <- function() {
  paths <- file.path(RAW_DIR, ROUND_FILES)
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0L) {
    stop("Faltan archivos raw: ", paste(missing, collapse = ", "))
  }

  rounds <- stats::setNames(lapply(paths, read_round), ROUND_FILES)
  conversion_log <- do.call(
    rbind,
    lapply(rounds, function(round) attr(round, "conversion_log"))
  )
  rownames(conversion_log) <- NULL

  dir.create(file.path(OUTPUT_DIR, "tables"), recursive = TRUE,
             showWarnings = FALSE)
  utils::write.csv(
    conversion_log,
    file.path(OUTPUT_DIR, "tables", "ingest_conversiones.csv"),
    row.names = FALSE,
    na = ""
  )

  assign("pt_rounds_raw", rounds, envir = .GlobalEnv)
  assign("pt_conversion_log", conversion_log, envir = .GlobalEnv)
  invisible(list(rounds = rounds, conversion_log = conversion_log))
}

run_ingest()
