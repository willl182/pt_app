# ===================================================================
# Tidy normalization for PT round data
#
# Produces one long table for analyte and concomitant channels.
# ===================================================================

if (!exists("pt_rounds_raw", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "00_ingest.R"))) {
    file.path("scripts", "00_ingest.R")
  } else {
    file.path("data_use_cases", "scripts", "00_ingest.R")
  }
  source(script_path)
}

split_measure_name <- function(column_name) {
  separator <- regexpr("_[^_]+$", column_name)
  data.frame(
    canal = substr(column_name, 1L, separator - 1L),
    serial = substr(column_name, separator + 1L, nchar(column_name)),
    stringsAsFactors = FALSE
  )
}

round_to_long <- function(raw, file_name) {
  metadata <- attr(raw, "metadata")
  measure_columns <- attr(raw, "measure_columns")
  generator_column <- attr(raw, "generator_column")
  conversion_log <- attr(raw, "conversion_log")

  long_parts <- lapply(measure_columns, function(column_name) {
    identifiers <- split_measure_name(column_name)
    role <- if (startsWith(identifiers$serial, "4U")) "ref" else "part"
    non_numeric_lines <- conversion_log$linea[
      conversion_log$columna == column_name
    ]

    data.frame(
      source_file = file_name,
      source_row = raw$source_row,
      ronda = metadata$ronda,
      analito = metadata$analito,
      canal = identifiers$canal,
      es_analito = identifiers$canal == metadata$analito,
      unidad = metadata$unidad,
      ts = raw$ts,
      runtime_min = raw$runtime_min,
      level = as.character(raw$level),
      level_num = suppressWarnings(as.integer(raw$level)),
      nominal = raw[[generator_column]],
      rol = role,
      serial = identifiers$serial,
      participante = if (role == "part") metadata$participante else NA_character_,
      valor = raw[[column_name]],
      flag_no_numerico = raw$source_row %in% non_numeric_lines,
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, long_parts)
  result$err_rel <- ifelse(
    is.finite(result$nominal) & result$nominal != 0 &
      is.finite(result$valor),
    (result$valor - result$nominal) / result$nominal,
    NA_real_
  )
  result
}

run_tidy <- function() {
  consolidated <- do.call(
    rbind,
    Map(round_to_long, pt_rounds_raw, names(pt_rounds_raw))
  )
  rownames(consolidated) <- NULL
  consolidated <- consolidated[order(
    match(consolidated$source_file, ROUND_FILES),
    consolidated$source_row,
    consolidated$canal,
    consolidated$rol
  ), ]

  tidy_dir <- file.path(OUTPUT_DIR, "tidy")
  dir.create(tidy_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    consolidated,
    file.path(tidy_dir, "consolidado.csv"),
    row.names = FALSE,
    na = ""
  )

  assign("pt_consolidated", consolidated, envir = .GlobalEnv)
  invisible(consolidated)
}

run_tidy()
