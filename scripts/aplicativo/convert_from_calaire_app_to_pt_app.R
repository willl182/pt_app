#!/usr/bin/env Rscript
# ===================================================================
# Convertir exportación de calaire-app al formato interno de pt_app
#
# Uso:
#   Rscript scripts/aplicativo/convert_from_calaire_app_to_pt_app.R [entrada] [salida]
#
# Ejemplo:
#   Rscript scripts/aplicativo/convert_from_calaire_app_to_pt_app.R \
#     data/from_calaire-app/1-pt.csv \
#     data/processed/ronda_1_participantes_from_calaire.csv
# ===================================================================

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[1] else "data/from_calaire-app/1-pt.csv"
output_path <- if (length(args) >= 2) args[2] else "data/processed/ronda_1_participantes_from_calaire.csv"

default_unit <- if (length(args) >= 3) args[3] else "µmol/mol"

stop_if_missing <- function(path) {
  if (!file.exists(path)) {
    stop("No existe el archivo de entrada: ", path, call. = FALSE)
  }
}

add_missing_column <- function(df, column, value = NA) {
  if (!column %in% names(df)) {
    df[[column]] <- value
  }
  df
}

first_existing <- function(df, aliases) {
  found <- intersect(aliases, names(df))
  if (length(found) == 0) {
    return(NA_character_)
  }
  found[1]
}

copy_alias <- function(df, target, aliases, required = FALSE) {
  source <- first_existing(df, aliases)
  if (is.na(source)) {
    if (required) {
      stop(
        "No se encontró ninguna columna para '", target, "'. Alias aceptados: ",
        paste(aliases, collapse = ", "),
        call. = FALSE
      )
    }
    df[[target]] <- NA
  } else {
    df[[target]] <- df[[source]]
  }
  df
}

normalize_level <- function(level, unit) {
  level_chr <- as.character(level)
  has_unit <- grepl("-", level_chr, fixed = TRUE)
  ifelse(has_unit | is.na(level_chr) | level_chr == "", level_chr, paste0(level_chr, "-", unit))
}

stop_if_missing(input_path)
raw_df <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)

required <- c("pollutant", "run", "level", "participant_id", "mean_value")
missing_required <- setdiff(required, names(raw_df))
if (length(missing_required) > 0) {
  stop(
    "Faltan columnas obligatorias en ", input_path, ": ",
    paste(missing_required, collapse = ", "),
    call. = FALSE
  )
}

out <- raw_df
out <- copy_alias(out, "mean_h1", c("mean_h1", "d1", "Dato 1", "dato_1"))
out <- copy_alias(out, "mean_h2", c("mean_h2", "d2", "Dato 2", "dato_2"))
out <- copy_alias(out, "mean_h3", c("mean_h3", "d3", "Dato 3", "dato_3"))
out <- copy_alias(out, "u_value", c("u_value", "ux", "u(x)", "u_xi", "u_i"), required = TRUE)
out <- copy_alias(out, "u_exp", c("u_exp", "ux_exp", "u(x) exp", "U_xi", "Uxi"))
out <- copy_alias(out, "k_factor", c("k_factor", "k"))

if (!"unit" %in% names(out)) {
  out$unit <- default_unit
}
out$level <- normalize_level(out$level, out$unit)

if (!"source" %in% names(out)) {
  out$source <- "calaire_app"
}
if (!"instrument" %in% names(out)) {
  out$instrument <- out$participant_id
}
if (!"tipo" %in% names(out)) {
  out$tipo <- "participante"
}
if (!"n_hours" %in% names(out)) {
  out$n_hours <- rowSums(!is.na(out[c("mean_h1", "mean_h2", "mean_h3")]))
}
if (!"hour_starts" %in% names(out)) {
  out$hour_starts <- NA_character_
}

if (!"n_lab" %in% names(out)) {
  n_lab_df <- aggregate(
    participant_id ~ pollutant + level,
    data = unique(out[c("pollutant", "level", "participant_id")]),
    FUN = length
  )
  names(n_lab_df)[names(n_lab_df) == "participant_id"] <- "n_lab"
  out <- merge(out, n_lab_df, by = c("pollutant", "level"), all.x = TRUE, sort = FALSE)
}

ordered_cols <- c(
  "pollutant", "level", "source", "run", "unit", "instrument",
  "mean_h1", "mean_h2", "mean_h3", "mean_value", "sd_value", "u_value",
  "u_exp", "k_factor", "n_hours", "hour_starts", "participant_id", "tipo",
  "n_lab"
)
out <- out[intersect(ordered_cols, names(out))]

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(out, output_path, row.names = FALSE, na = "NA")

cat("✓ Archivo convertido para pt_app:\n")
cat("  Entrada:", input_path, "\n")
cat("  Salida: ", output_path, "\n")
cat("  Filas:  ", nrow(out), "\n")
cat("  Columnas:", paste(names(out), collapse = ", "), "\n")
