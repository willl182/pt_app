# ===================================================================
# Helpers compartidos para validación
# Funciones comunes usadas por los scripts de etapa
# ===================================================================

# --- Combos O3 × 3 niveles (validación primaria) ---
COMBOS <- list(
  list(pollutant = "o3", level = "0-nmol/mol",  label = "O3_0"),
  list(pollutant = "o3", level = "80-nmol/mol",  label = "O3_80"),
  list(pollutant = "o3", level = "180-nmol/mol", label = "O3_180")
)

# --- IDs de combo ---
make_combo_id <- function(pollutant, level) {
  prefix <- toupper(pollutant)
  level_num <- gsub("-.*", "", level)
  paste0(prefix, "_", level_num)
}

# --- Carga de datos en formato ancho ---
load_wide_data <- function(filepath, pollutant, level) {
  df <- read.csv(filepath, stringsAsFactors = FALSE)
  df <- df[df$pollutant == pollutant & df$level == level, ]
  if (nrow(df) == 0) {
    warning(paste0("Sin datos para ", pollutant, " / ", level))
    return(data.frame())
  }
  # Pivotar a formato ancho: sample_id × replicates
  wide <- reshape(df,
    idvar = "sample_id",
    timevar = "replicate",
    direction = "wide",
    v.names = "value")
  # Renombrar columnas value.1 -> sample_1, value.2 -> sample_2
  names(wide) <- gsub("^value\\.", "sample_", names(wide))
  # Mantener solo columnas relevantes
  keep_cols <- c("sample_id", grep("^sample_\\d+$", names(wide), value = TRUE))
  wide <- wide[, keep_cols, drop = FALSE]
  wide <- wide[order(wide$sample_id), ]
  rownames(wide) <- NULL
  wide
}

# --- Carga de datos de participantes (summary) ---
load_summary_data <- function(filepath, pollutant, level, exclude_ref = TRUE) {
  df <- read.csv(filepath, stringsAsFactors = FALSE)
  df <- df[df$pollutant == pollutant & df$level == level, ]
  if (exclude_ref && "participant_id" %in% names(df)) {
    df <- df[!grepl("^ref$", df$participant_id, ignore.case = TRUE), ]
  }
  df
}

# --- Comparación con tolerancia ---
compare_values <- function(val_app, val_r, val_python, tol = 1e-9) {
  diff_app_r <- if (is.finite(val_app) && is.finite(val_r)) abs(val_app - val_r) else NA_real_
  diff_app_py <- if (is.finite(val_app) && is.finite(val_python)) abs(val_app - val_python) else NA_real_
  diff_r_py <- if (is.finite(val_r) && is.finite(val_python)) abs(val_r - val_python) else NA_real_

  status <- "PASS"
  if (!is.na(diff_app_r) && diff_app_r > tol) status <- "FAIL"
  if (!is.na(diff_app_py) && diff_app_py > tol) status <- "FAIL"
  if (!is.na(diff_r_py) && diff_r_py > tol) status <- "FAIL"
  if (is.na(val_app) && is.na(val_r) && is.na(val_python)) status <- "PASS"

  list(
    diff_app_r = diff_app_r,
    diff_app_python = diff_app_py,
    diff_r_python = diff_r_py,
    status = status
  )
}

# --- Columnas canónicas del CSV ---
CANONICAL_COLS <- c(
  "combo_id", "pollutant", "level", "stage", "section",
  "metric", "r_value", "python_value", "app_value",
  "diff_r_python", "diff_app_r", "diff_app_python",
  "status", "tolerance", "notes"
)

# --- Escribir CSV canónico ---
write_canonical_csv <- function(results, filepath) {
  df <- do.call(rbind, lapply(results, function(row) {
    missing_cols <- setdiff(CANONICAL_COLS, names(row))
    for (col in missing_cols) row[[col]] <- NA
    row <- as.data.frame(row, stringsAsFactors = FALSE)
    row[, CANONICAL_COLS, drop = FALSE]
  }))
  rownames(df) <- NULL
  utils::write.csv(df, filepath, row.names = FALSE)
  cat("  CSV guardado:", filepath, "\n")
  invisible(df)
}

# --- Constantes de estado ---
STATUS_PASS <- "PASS"
STATUS_FAIL <- "FAIL"
STATUS_EDGE <- "EDGE_CASE"
STATUS_KNOWN_DISC <- "KNOWN_DISCREPANCY"
