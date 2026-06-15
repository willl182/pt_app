#!/usr/bin/env Rscript
# Une las salidas de cualquier ronda en archivos consolidados.
# Uso: Rscript scripts/adicionales/unir_rondas.R [número]
#   Ejemplo: Rscript scripts/adicionales/unir_rondas.R 1
#   Si no se pasa número, procesa todas las rondas detectadas.

args <- commandArgs(trailingOnly = TRUE)
processed_dir <- "data/processed"
default_k <- 2

complete_uncertainty_fields <- function(df) {
  if (is.null(df) || !"u_value" %in% names(df)) {
    return(df)
  }
  if (!"k_factor" %in% names(df)) {
    df$k_factor <- default_k
  }
  df$k_factor <- suppressWarnings(as.numeric(df$k_factor))
  df$k_factor[!is.finite(df$k_factor) | df$k_factor <= 0] <- default_k

  if (!"u_exp" %in% names(df)) {
    df$u_exp <- NA_real_
  }
  u_value <- suppressWarnings(as.numeric(df$u_value))
  u_exp <- suppressWarnings(as.numeric(df$u_exp))
  df$u_exp <- ifelse(is.finite(u_exp), u_exp, u_value * df$k_factor)
  df
}

# Detectar rondas disponibles a partir de archivos de salida de la pipeline.
# Patrón: ronda_<id>_p_ronda.csv / ronda_<id>_p_<participante>_ronda.csv
# (participantes) y ronda_<id>_r.csv (referencia)
p_files <- list.files(processed_dir, pattern = "^ronda_.*_p(_[[:alnum:]_]+)?_ronda\\.csv$", full.names = TRUE)
r_files <- list.files(processed_dir, pattern = "^ronda_.*_r\\.csv$", full.names = TRUE)

# Extraer IDs de ronda: ronda_1_p_ronda.csv -> "1", ronda_2a_p_mf_ronda.csv -> "2a", etc.
extract_ronda_id <- function(filepath, suffix) {
  bn <- basename(filepath)
  gsub(paste0("^ronda_(.+)", suffix, "$"), "\\1", bn)
}

p_ids <- sort(unique(sapply(p_files, function(f) {
  sub("^ronda_([0-9]+[a-z]?)_p(_[[:alnum:]_]+)?_ronda\\.csv$", "\\1", basename(f))
})))
r_ids <- sort(unique(sapply(r_files, extract_ronda_id, suffix = "_r\\.csv")))

# Agrupar por número de ronda base (1, 2, ...)
all_ids <- sort(unique(c(p_ids, r_ids)))
ronda_nums <- unique(gsub("[a-z]*$", "", all_ids))

if (length(args) > 0) {
  ronda_nums <- args[1]
}

combinar_ronda <- function(ronda_num) {
  cat("=== RONDA", ronda_num, "===\n\n")

  # Archivos participante: ronda_<id>_p_ronda.csv o ronda_<id>_p_<participante>_ronda.csv
  # donde <id> empieza con ronda_num.
  part_pattern <- paste0("^ronda_(", ronda_num, "[a-z]?)_p(_[[:alnum:]_]+)?_ronda\\.csv$")
  part_files <- list.files(processed_dir, pattern = part_pattern, full.names = TRUE)

  # Archivos referencia: ronda_<id>_r.csv donde <id> empieza con ronda_num
  ref_pattern <- paste0("^ronda_(", ronda_num, "[a-z]?)_r\\.csv$")
  ref_files <- list.files(processed_dir, pattern = ref_pattern, full.names = TRUE)

  # Para ronda 1, también buscar sin sufijo
  if (length(part_files) == 0) {
    part_pattern <- paste0("^ronda_", ronda_num, "_p(_[[:alnum:]_]+)?_ronda\\.csv$")
    part_files <- list.files(processed_dir, pattern = part_pattern, full.names = TRUE)
  }
  if (length(ref_files) == 0) {
    ref_pattern <- paste0("^ronda_", ronda_num, "_r\\.csv$")
    ref_files <- list.files(processed_dir, pattern = ref_pattern, full.names = TRUE)
  }

  # --- Participantes ---
  cat("--- PARTICIPANTES ---\n")
  part_df <- NULL
  if (length(part_files) > 0) {
    dfs <- lapply(part_files, function(f) {
      cat("  ", basename(f), "\n")
      df <- read.csv(f, stringsAsFactors = FALSE)
      if (!"participant_id" %in% names(df) && "instrument" %in% names(df)) {
        df$participant_id <- df$instrument
      }
      df
    })
    part_df <- do.call(rbind, dfs)
    part_df$tipo <- "participante"
    part_df <- complete_uncertainty_fields(part_df)
  } else {
    cat("  (sin archivos participante)\n")
  }

  # --- Referencia ---
  cat("--- REFERENCIA ---\n")
  ref_df <- NULL
  if (length(ref_files) > 0) {
    dfs <- lapply(ref_files, function(f) {
      cat("  ", basename(f), "\n")
      read.csv(f, stringsAsFactors = FALSE)
    })
    ref_df <- do.call(rbind, dfs)
    ref_df$tipo <- "referencia"
    ref_df <- complete_uncertainty_fields(ref_df)
  } else {
    cat("  (sin archivos referencia)\n")
  }

  if (!is.null(part_df) && all(c("pollutant", "level", "participant_id") %in% names(part_df))) {
    n_lab_df <- aggregate(
      participant_id ~ pollutant + level,
      data = unique(part_df[c("pollutant", "level", "participant_id")]),
      FUN = length
    )
    names(n_lab_df)[names(n_lab_df) == "participant_id"] <- "n_lab"
    part_df <- merge(part_df, n_lab_df, by = c("pollutant", "level"), all.x = TRUE, sort = FALSE)
    if (!is.null(ref_df) && all(c("pollutant", "level") %in% names(ref_df))) {
      ref_df <- merge(ref_df, n_lab_df, by = c("pollutant", "level"), all.x = TRUE, sort = FALSE)
    }
  }

  # --- Guardar participantes ---
  if (!is.null(part_df)) {
    part_out <- file.path(processed_dir, paste0("ronda_", ronda_num, "_participantes.csv"))
    write.csv(part_df, part_out, row.names = FALSE)
    cat("✓", part_out, "(", nrow(part_df), "filas )\n")
  }

  # --- Guardar referencia ---
  if (!is.null(ref_df)) {
    ref_out <- file.path(processed_dir, paste0("ronda_", ronda_num, "_referencia.csv"))
    write.csv(ref_df, ref_out, row.names = FALSE)
    cat("✓", ref_out, "(", nrow(ref_df), "filas )\n")
  }

  # --- Consolidado ---
  if (!is.null(part_df) && !is.null(ref_df)) {
    all_cols <- union(names(part_df), names(ref_df))
    for (col in all_cols) {
      if (!col %in% names(part_df)) part_df[[col]] <- NA
      if (!col %in% names(ref_df))  ref_df[[col]]  <- NA
    }
    part_df <- part_df[, all_cols]
    ref_df  <- ref_df[, all_cols]

    todo <- rbind(part_df, ref_df)
    out_path <- file.path(processed_dir, paste0("ronda_", ronda_num, "_completa.csv"))
    write.csv(todo, out_path, row.names = FALSE)
    cat("✓", out_path, "(", nrow(todo), "filas,", ncol(todo), "columnas )\n")
    cat("  Columnas:", paste(names(todo), collapse = ", "), "\n")
  }

  cat("\n")
}

for (rn in ronda_nums) {
  combinar_ronda(rn)
}

cat("=== FIN ===\n")
