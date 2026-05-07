#!/usr/bin/env Rscript

source("R/preprocessing/read_calaire_raw.R")
source("R/preprocessing/clean_calaire_raw.R")
source("R/preprocessing/hourly_averages.R")
source("R/preprocessing/pipeline_calaire.R")

result <- run_pipeline_participant_ronda(
  data_dir = "data/raw",
  metadata_dir = "data/metadata",
  output_dir = "data/processed",
  participant_id = "part_1",
  input_file = "datos_ronda_part.csv"
)

if (!isTRUE(result$success)) {
  stop("Pipeline part_1 finalizo con errores.")
}

message("Pipeline part_1 completado exitosamente.")
