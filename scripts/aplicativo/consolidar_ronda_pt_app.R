#!/usr/bin/env Rscript
# ===================================================================
# Consolidar ronda para pt_app desde cualquier origen soportado
#
# Soporta participantes procesados internamente o importados desde calaire-app.
#
# Uso:
#   Rscript scripts/aplicativo/consolidar_ronda_pt_app.R [ronda] [participantes] [referencia] [salida]
#
# Ejemplos:
#   Rscript scripts/aplicativo/consolidar_ronda_pt_app.R 1
#   Rscript scripts/aplicativo/consolidar_ronda_pt_app.R 1 \
#     data/processed/ronda_1_participantes_from_calaire.csv \
#     data/processed/ronda_1_referencia.csv \
#     data/processed/ronda_1_completa.csv
# ===================================================================

args <- commandArgs(trailingOnly = TRUE)
ronda <- if (length(args) >= 1) args[1] else "1"
processed_dir <- "data/processed"
participants_path_arg <- if (length(args) >= 2 && nzchar(args[2])) args[2] else NA_character_
reference_path_arg <- if (length(args) >= 3 && nzchar(args[3])) args[3] else NA_character_
output_path <- if (length(args) >= 4 && nzchar(args[4])) {
  args[4]
} else {
  file.path(processed_dir, paste0("ronda_", ronda, "_completa.csv"))
}

default_unit <- "µmol/mol"

first_existing_path <- function(paths) {
  existing <- paths[file.exists(paths)]
  if (length(existing) == 0) {
    return(NA_character_)
  }
  existing[1]
}

resolve_existing_path <- function(requested_path, fallback_paths) {
  candidates <- c(requested_path, fallback_paths)
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  first_existing_path(unique(candidates))
}

read_csv_checked <- function(path, label) {
  if (is.na(path) || !file.exists(path)) {
    stop("No existe archivo de ", label, ": ", path, call. = FALSE)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

normalize_level <- function(level, unit) {
  level_chr <- as.character(level)
  has_unit <- grepl("-", level_chr, fixed = TRUE)
  ifelse(has_unit | is.na(level_chr) | level_chr == "", level_chr, paste0(level_chr, "-", unit))
}

ensure_col <- function(df, col, value = NA) {
  if (!col %in% names(df)) {
    df[[col]] <- value
  }
  df
}

copy_if_missing <- function(df, target, source) {
  if (!target %in% names(df) && source %in% names(df)) {
    df[[target]] <- df[[source]]
  }
  df
}

normalize_pt_df <- function(df, tipo, source_default) {
  df <- copy_if_missing(df, "participant_id", "instrument")
  df <- copy_if_missing(df, "instrument", "participant_id")
  df <- copy_if_missing(df, "mean_h1", "d1")
  df <- copy_if_missing(df, "mean_h2", "d2")
  df <- copy_if_missing(df, "mean_h3", "d3")
  df <- copy_if_missing(df, "u_value", "ux")
  df <- copy_if_missing(df, "u_exp", "ux_exp")
  df <- copy_if_missing(df, "k_factor", "k")

  required <- c("pollutant", "level", "participant_id", "mean_value", "u_value")
  missing_required <- setdiff(required, names(df))
  if (length(missing_required) > 0) {
    stop(
      "Faltan columnas obligatorias para ", tipo, ": ",
      paste(missing_required, collapse = ", "),
      call. = FALSE
    )
  }

  df <- ensure_col(df, "unit", default_unit)
  df$level <- normalize_level(df$level, df$unit)
  df <- ensure_col(df, "source", source_default)
  df <- ensure_col(df, "run", NA)
  df <- ensure_col(df, "instrument", df$participant_id)
  df <- ensure_col(df, "sd_value", NA_real_)
  df <- ensure_col(df, "u_exp", NA_real_)
  df <- ensure_col(df, "k_factor", NA_real_)
  df <- ensure_col(df, "n_hours", rowSums(!is.na(df[c("mean_h1", "mean_h2", "mean_h3")])) )
  df <- ensure_col(df, "hour_starts", NA_character_)
  df$tipo <- tipo
  df
}

participants_path <- resolve_existing_path(
  participants_path_arg,
  c(
    file.path(processed_dir, paste0("ronda_", ronda, "_participantes_from_calaire.csv")),
    file.path(processed_dir, paste0("ronda_", ronda, "_participantes.csv")),
    file.path(processed_dir, paste0("ronda_", ronda, "_p_ronda.csv")),
    file.path(processed_dir, "p1_ronda.csv")
  )
)

reference_path <- resolve_existing_path(
  reference_path_arg,
  c(
    file.path(processed_dir, paste0("ronda_", ronda, "_referencia.csv")),
    file.path(processed_dir, paste0("ronda_", ronda, "_r.csv")),
    file.path(processed_dir, "referencia_ronda.csv")
  )
)

part_df <- normalize_pt_df(
  read_csv_checked(participants_path, "participantes"),
  tipo = "participante",
  source_default = "ronda_participante"
)
ref_df <- normalize_pt_df(
  read_csv_checked(reference_path, "referencia"),
  tipo = "referencia",
  source_default = "ronda_referencia"
)

n_lab_df <- aggregate(
  participant_id ~ pollutant + level,
  data = unique(part_df[c("pollutant", "level", "participant_id")]),
  FUN = length
)
names(n_lab_df)[names(n_lab_df) == "participant_id"] <- "n_lab"

part_df <- merge(part_df, n_lab_df, by = c("pollutant", "level"), all.x = TRUE, sort = FALSE)
if ("n_lab.x" %in% names(part_df)) {
  part_df$n_lab <- ifelse(is.na(part_df$n_lab.x), part_df$n_lab.y, part_df$n_lab.x)
  part_df$n_lab.x <- NULL
  part_df$n_lab.y <- NULL
}
ref_df <- merge(ref_df, n_lab_df, by = c("pollutant", "level"), all.x = TRUE, sort = FALSE)
if ("n_lab.x" %in% names(ref_df)) {
  ref_df$n_lab <- ifelse(is.na(ref_df$n_lab.x), ref_df$n_lab.y, ref_df$n_lab.x)
  ref_df$n_lab.x <- NULL
  ref_df$n_lab.y <- NULL
}

all_cols <- union(names(part_df), names(ref_df))
for (col in all_cols) {
  if (!col %in% names(part_df)) part_df[[col]] <- NA
  if (!col %in% names(ref_df)) ref_df[[col]] <- NA
}

out <- rbind(part_df[all_cols], ref_df[all_cols])
preferred_cols <- c(
  "pollutant", "level", "source", "run", "unit", "instrument",
  "mean_h1", "mean_h2", "mean_h3", "mean_value", "sd_value", "u_value",
  "u_exp", "k_factor", "n_hours", "hour_starts", "participant_id", "tipo",
  "n_lab"
)
out <- out[c(intersect(preferred_cols, names(out)), setdiff(names(out), preferred_cols))]

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(out, output_path, row.names = FALSE, na = "NA")

cat("✓ Consolidado pt_app generado:\n")
cat("  Ronda:         ", ronda, "\n")
cat("  Participantes: ", participants_path, "\n")
cat("  Referencia:    ", reference_path, "\n")
cat("  Salida:        ", output_path, "\n")
cat("  Filas:         ", nrow(out), "\n")
cat("  Participantes: ", sum(out$tipo == "participante"), "\n")
cat("  Referencia:    ", sum(out$tipo == "referencia"), "\n")
