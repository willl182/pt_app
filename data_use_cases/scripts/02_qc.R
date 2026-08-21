# ===================================================================
# Quality-control flags for PT round data
#
# Adds informative flags without deleting observations.
# ===================================================================

NOX_RESIDUAL_THRESHOLD_PPB <- 3

if (!exists("pt_consolidated", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "01_tidy.R"))) {
    file.path("scripts", "01_tidy.R")
  } else {
    file.path("data_use_cases", "scripts", "01_tidy.R")
  }
  source(script_path)
}

hampel_flags <- function(values, window = 7L, threshold = 3) {
  n <- length(values)
  flags <- rep(FALSE, n)
  for (i in seq_len(n)) {
    lower <- max(1L, i - window)
    upper <- min(n, i + window)
    local <- values[lower:upper]
    center <- stats::median(local, na.rm = TRUE)
    scale <- stats::mad(local, center = center, constant = 1, na.rm = TRUE)
    if (is.finite(values[i]) && is.finite(scale) && scale > 0) {
      flags[i] <- abs(values[i] - center) > threshold * scale
    }
  }
  flags
}

add_hampel_by_group <- function(data) {
  key <- interaction(
    data$source_file, data$canal, data$rol, data$level,
    drop = TRUE, lex.order = TRUE
  )
  flags <- rep(FALSE, nrow(data))
  stable <- data$level %in% as.character(1:5)
  for (group_name in levels(key)) {
    index <- which(key == group_name & stable)
    if (length(index) > 0L) {
      ordered <- index[order(data$runtime_min[index])]
      flags[ordered] <- hampel_flags(data$valor[ordered])
    }
  }
  flags
}

calculate_nox_residuals <- function(data) {
  selected <- data[
    data$source_file %in% c("R3_NO.csv", "R3_NO2.csv") &
      data$canal %in% c("no", "no2", "nox"),
  ]
  if (nrow(selected) == 0L) {
    return(data.frame())
  }

  wide <- tidyr::pivot_wider(
    selected[, c("source_file", "source_row", "rol", "canal", "valor")],
    names_from = "canal",
    values_from = "valor"
  )
  wide$nox_residuo <- wide$no + wide$no2 - wide$nox
  wide$flag_no_numerico_residuo <- !is.finite(wide$nox_residuo)
  # Operational screening threshold; retained as a named constant because
  # the analysis plan does not prescribe a normative NOx residual limit.
  wide$flag_nox_residuo <- is.finite(wide$nox_residuo) &
    abs(wide$nox_residuo) > NOX_RESIDUAL_THRESHOLD_PPB
  wide
}

run_qc <- function() {
  qc <- pt_consolidated
  qc$flag_na <- is.na(qc$valor)
  qc$flag_transient <- qc$level == "estab"

  timestamp_key <- interaction(qc$source_file, drop = TRUE)
  gap_rows <- logical(nrow(qc))
  for (group_name in levels(timestamp_key)) {
    index <- which(timestamp_key == group_name)
    unique_rows <- !duplicated(qc$source_row[index])
    row_index <- index[unique_rows]
    row_index <- row_index[order(qc$source_row[row_index])]
    deltas <- c(NA_real_, diff(as.numeric(qc$ts[row_index])) / 60)
    gap_source_rows <- qc$source_row[row_index][is.finite(deltas) & deltas > 2]
    gap_rows[index] <- qc$source_row[index] %in% gap_source_rows
  }
  qc$flag_gap <- gap_rows

  stable <- qc$level %in% as.character(1:5)
  positive_nominal <- is.finite(qc$nominal) & qc$nominal > 0
  zero_nominal <- is.finite(qc$nominal) & qc$nominal == 0
  known_r3_no2_shift <- qc$source_file == "R3_NO2.csv" &
    qc$level == "2" & positive_nominal &
    abs(qc$valor - qc$nominal) > 0.05 * qc$nominal
  qc$flag_gen_mismatch <- qc$es_analito & is.finite(qc$valor) & (
    (stable & positive_nominal &
       abs(qc$valor - qc$nominal) > 0.20 * qc$nominal) |
      (zero_nominal & abs(qc$valor) > 5) |
      known_r3_no2_shift
  )
  qc$flag_outlier <- add_hampel_by_group(qc)

  residuals <- calculate_nox_residuals(qc)
  qc$flag_nox_residuo <- FALSE
  if (nrow(residuals) > 0L) {
    residual_key <- paste(
      residuals$source_file, residuals$source_row, residuals$rol, sep = "|"
    )
    flagged_keys <- residual_key[residuals$flag_nox_residuo]
    qc_key <- paste(qc$source_file, qc$source_row, qc$rol, sep = "|")
    qc$flag_nox_residuo <- qc_key %in% flagged_keys
  }

  flag_columns <- c(
    "flag_na", "flag_gap", "flag_transient", "flag_gen_mismatch",
    "flag_outlier", "flag_no_numerico", "flag_nox_residuo"
  )
  qc_flags <- qc |>
    dplyr::group_by(ronda, analito, level) |>
    dplyr::summarise(
      filas = dplyr::n_distinct(source_row),
      dplyr::across(dplyr::all_of(flag_columns), ~ sum(.x, na.rm = TRUE)),
      .groups = "drop"
    )

  tidy_dir <- file.path(OUTPUT_DIR, "tidy")
  table_dir <- file.path(OUTPUT_DIR, "tables")
  dir.create(tidy_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    qc,
    file.path(tidy_dir, "consolidado_qc.csv"),
    row.names = FALSE,
    na = ""
  )
  utils::write.csv(
    qc_flags,
    file.path(table_dir, "qc_flags.csv"),
    row.names = FALSE,
    na = ""
  )

  assign("pt_qc", qc, envir = .GlobalEnv)
  assign("pt_nox_residuals", residuals, envir = .GlobalEnv)
  invisible(list(data = qc, flags = qc_flags, nox = residuals))
}

run_qc()
