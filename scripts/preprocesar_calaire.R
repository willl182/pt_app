#!/usr/bin/env Rscript
# Preprocesamiento CALAIRE — pipeline completo.
# Uso: Rscript scripts/preprocesar_calaire.R
# Ejecutar desde el directorio raiz de pt_app.

root <- if (nchar(Sys.getenv("PT_APP_ROOT")) > 0) {
  Sys.getenv("PT_APP_ROOT")
} else {
  normalizePath(".")
}

preprocessing_dir <- file.path(root, "R", "preprocessing")
for (f in c(
  "read_calaire_raw.R",
  "clean_calaire_raw.R",
  "hourly_averages.R",
  "moving_hourly_means.R",
  "uncertainty_report.R",
  "validation.R",
  "pipeline_calaire.R"
)) {
  source(file.path(preprocessing_dir, f))
}

args_common <- list(
  data_dir     = file.path(root, "data", "raw"),
  metadata_dir = file.path(root, "data", "metadata"),
  output_dir   = file.path(root, "data", "processed"),
  tz           = "America/Bogota"
)

message("====== Pipeline estabilidad/homogeneidad ======")
result_estab <- do.call(run_pipeline_calaire, args_common)

# Detectar rondas disponibles en data/raw.
# La ronda principal usa datos_ronda.csv -> referencia_ronda.csv.
# Rondas adicionales usan datos_ronda_2a.csv -> referencia_ronda_2a.csv.
ronda_specs <- list()
main_ronda_path <- file.path(root, "data", "raw", "datos_ronda.csv")
if (file.exists(main_ronda_path)) {
  ronda_specs[[length(ronda_specs) + 1]] <- list(
    label = "principal",
    input_file = "datos_ronda.csv",
    output_prefix = "referencia_ronda",
    part_file = "datos_ronda_part.csv",
    participant_id = "part_1"
  )
}

ronda_files <- list.files(
  file.path(root, "data", "raw"),
  pattern = "^datos_ronda_[^_]+\\.csv$"
)
ronda_suffixes <- gsub("^datos_ronda_|\\.csv$", "", ronda_files)

for (suffix in ronda_suffixes) {
  ronda_specs[[length(ronda_specs) + 1]] <- list(
    label = suffix,
    input_file = paste0("datos_ronda_", suffix, ".csv"),
    output_prefix = paste0("referencia_ronda_", suffix),
    part_file = paste0("datos_ronda_", suffix, "_part.csv"),
    participant_id = paste0("part_", suffix)
  )
}

all_success <- result_estab$success

for (spec in ronda_specs) {
  message("====== Pipeline ronda: ", spec$label, " ======")
  result_ronda <- do.call(
    run_pipeline_ronda,
    c(args_common, list(
      input_file = spec$input_file,
      output_prefix = spec$output_prefix
    ))
  )
  all_success <- all_success && result_ronda$success

  # Procesar participante si existe
  part_path <- file.path(root, "data", "raw", spec$part_file)
  if (file.exists(part_path)) {
    message("====== Pipeline participante: ", spec$participant_id, " ======")
    result_part <- do.call(
      run_pipeline_participant_ronda,
      c(args_common, list(
        participant_id = spec$participant_id,
        input_file = spec$part_file
      ))
    )
    all_success <- all_success && result_part$success
  }
}

if (!all_success) {
  message("Pipeline terminado con FAIL. Revise logs en data/metadata/.")
  quit(status = 1)
} else {
  message("Todos los pipelines completados exitosamente.")
  quit(status = 0)
}
