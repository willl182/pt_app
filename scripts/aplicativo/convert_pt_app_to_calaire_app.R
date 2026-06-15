#!/usr/bin/env Rscript
# ===================================================================
# Convertir datos procesados de pt_app al formato de carga de calaire-app
#
# Uso:
#   Rscript scripts/aplicativo/convert_pt_app_to_calaire_app.R [entrada] [salida] [modo] [k]
#
# Modos:
#   participants  Exporta solo participantes (por defecto)
#   reference     Exporta solo referencia
#   all           Exporta participantes y referencia
#
# Ejemplos:
#   Rscript scripts/aplicativo/convert_pt_app_to_calaire_app.R \
#     data/processed/ronda_1_completa.csv \
#     data/to_calaire-app/1-pt.csv participants
#
#   Rscript scripts/aplicativo/convert_pt_app_to_calaire_app.R \
#     data/processed/ronda_1_referencia.csv \
#     data/to_calaire-app/1-ref.csv reference
# ===================================================================

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[1] else "data/processed/ronda_1_completa.csv"
output_path <- if (length(args) >= 2) args[2] else "data/to_calaire-app/1-pt.csv"
mode_arg <- if (length(args) >= 3) tolower(args[3]) else "participants"
mode <- switch(
  mode_arg,
  "participant" = "participants",
  "participants" = "participants",
  "pt" = "participants",
  "false" = "participants",
  "f" = "participants",
  "0" = "participants",
  "reference" = "reference",
  "referencia" = "reference",
  "ref" = "reference",
  "all" = "all",
  "both" = "all",
  "todos" = "all",
  "true" = "all",
  "t" = "all",
  "1" = "all",
  "yes" = "all",
  "si" = "all",
  "sí" = "all",
  stop(
    "Modo no reconocido: ", mode_arg,
    ". Use: participants, reference o all.",
    call. = FALSE
  )
)
default_k <- if (length(args) >= 4) suppressWarnings(as.numeric(args[4])) else 2
if (!is.finite(default_k) || default_k <= 0) {
  default_k <- 2
}

stop_if_missing <- function(path) {
  if (!file.exists(path)) {
    stop("No existe el archivo de entrada: ", path, call. = FALSE)
  }
}

first_existing <- function(df, aliases) {
  found <- intersect(aliases, names(df))
  if (length(found) == 0) {
    return(NA_character_)
  }
  found[1]
}

get_column <- function(df, aliases, default = NA) {
  source <- first_existing(df, aliases)
  if (is.na(source)) {
    return(rep(default, nrow(df)))
  }
  df[[source]]
}

strip_level_unit <- function(level) {
  level_chr <- as.character(level)
  sub("-.*$", "", level_chr)
}

numeric_or_na <- function(x) {
  suppressWarnings(as.numeric(x))
}

stop_if_missing(input_path)
raw_df <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)

required <- c("pollutant", "level", "mean_value")
missing_required <- setdiff(required, names(raw_df))
if (length(missing_required) > 0) {
  stop(
    "Faltan columnas obligatorias en ", input_path, ": ",
    paste(missing_required, collapse = ", "),
    call. = FALSE
  )
}

if ("tipo" %in% names(raw_df)) {
  if (mode == "participants") {
    raw_df <- raw_df[is.na(raw_df$tipo) | raw_df$tipo != "referencia", , drop = FALSE]
  } else if (mode == "reference") {
    raw_df <- raw_df[!is.na(raw_df$tipo) & raw_df$tipo == "referencia", , drop = FALSE]
  }
}

if (nrow(raw_df) == 0) {
  stop("No hay filas para exportar con modo: ", mode, call. = FALSE)
}

participant_id <- get_column(raw_df, c("participant_id", "instrument"), default = "ref")
participant_id[is.na(participant_id) | participant_id == ""] <- get_column(
  raw_df[is.na(participant_id) | participant_id == "", , drop = FALSE],
  c("instrument"),
  default = "ref"
)

ux <- numeric_or_na(get_column(raw_df, c("u_value", "u_i", "ux", "u_xi")))
k <- numeric_or_na(get_column(raw_df, c("k_factor", "k"), default = default_k))
k[!is.finite(k) | k <= 0] <- default_k
ux_exp_existing <- numeric_or_na(get_column(raw_df, c("u_exp", "ux_exp", "U_xi", "Uxi")))
ux_exp <- ifelse(is.finite(ux_exp_existing), ux_exp_existing, ux * k)

out <- data.frame(
  pollutant = raw_df$pollutant,
  run = get_column(raw_df, c("run")),
  level = strip_level_unit(raw_df$level),
  participant_id = participant_id,
  replicate = get_column(raw_df, c("replicate"), default = 1),
  sample_group = get_column(raw_df, c("sample_group"), default = "A"),
  d1 = get_column(raw_df, c("mean_h1", "d1")),
  d2 = get_column(raw_df, c("mean_h2", "d2")),
  d3 = get_column(raw_df, c("mean_h3", "d3")),
  mean_value = raw_df$mean_value,
  sd_value = get_column(raw_df, c("sd_value")),
  ux = ux,
  k = k,
  ux_exp = ux_exp,
  stringsAsFactors = FALSE
)

out$run <- as.integer(suppressWarnings(as.numeric(out$run)))
if (any(is.na(out$run))) {
  out$run <- get_column(raw_df, c("run"))
}

out <- out[order(out$pollutant, suppressWarnings(as.numeric(out$run)), out$participant_id), ]
row.names(out) <- NULL

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(out, output_path, row.names = FALSE, na = "")

cat("✓ Archivo convertido para calaire-app:\n")
cat("  Entrada:", input_path, "\n")
cat("  Salida: ", output_path, "\n")
cat("  Filas:  ", nrow(out), "\n")
cat("  Modo:   ", mode, "\n")
cat("  k por defecto si faltaba:", default_k, "\n")
