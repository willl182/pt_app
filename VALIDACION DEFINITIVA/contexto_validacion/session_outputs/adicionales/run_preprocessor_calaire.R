#!/usr/bin/env Rscript
# Preprocesador de datos CALAIRE para todas las rondas

suppressPackageStartupMessages({
  library(tools)
})

# Cargar funciones de preprocesamiento
source("R/preprocessing/read_calaire_raw.R")
source("R/preprocessing/clean_calaire_raw.R")
source("R/preprocessing/hourly_averages.R")
source("R/preprocessing/moving_hourly_means.R")
source("R/preprocessing/validation.R")
source("R/preprocessing/uncertainty_report.R")
source("R/preprocessing/pipeline_calaire.R")

# Lista de archivos de ronda
raw_files <- list.files("data/raw/", pattern = "datos_ronda_.*\\.csv$", full.names = TRUE)
cat("Archivos encontrados:", length(raw_files), "\n")
print(basename(raw_files))

detect_participant_ids <- function(path) {
  raw <- read_calaire_raw(path)
  cleaned_names <- .normalize_col_names(names(raw$data))
  hits <- grep("_part_[[:alnum:]_]+$", cleaned_names, value = TRUE)
  ids <- sort(unique(sub("^.*_part_([[:alnum:]_]+)$", "\\1", hits)))
  if (length(ids) == 0) {
    "p1"
  } else {
    ids
  }
}

# Procesar cada archivo
for (f in raw_files) {
  fname <- basename(f)
  # Extraer informacion del nombre: datos_ronda_X_p.csv -> ronda_X_p
  parts <- strsplit(gsub("datos_ronda_|\\.csv", "", fname), "_")[[1]]
  ronda <- parts[1]
  tipo <- parts[2]  # p o r
  
  participant_id <- paste0("ronda_", ronda, "_", tipo)
  output_prefix <- participant_id
  cat("\n========================================\n")
  cat("Procesando:", fname, "\n")
  cat("========================================\n")
  
  tryCatch({
    if (tipo == "r") {
      # Es referencia - usar run_pipeline_ronda
      result <- run_pipeline_ronda(
        data_dir = "data/raw",
        metadata_dir = "data/metadata",
        output_dir = "data/processed",
        input_file = fname,
        output_prefix = participant_id
      )
    } else {
      participant_ids <- detect_participant_ids(f)
      for (pid in participant_ids) {
        participant_output_prefix <- if (length(participant_ids) == 1 && pid == "p1") output_prefix else paste0(output_prefix, "_", pid)
        cat("ID:", pid, "\n")
        result <- run_pipeline_participant_ronda(
          data_dir = "data/raw",
          metadata_dir = "data/metadata",
          output_dir = "data/processed",
          participant_id = pid,
          output_prefix = participant_output_prefix,
          input_file = fname
        )
      }
    }
    cat("OK:", participant_id, "\n")
  }, error = function(e) {
    cat("ERROR en", participant_id, ":", e$message, "\n")
  })
}
cat("\n\n=== PREPROCESAMIENTO COMPLETADO ===\n")
