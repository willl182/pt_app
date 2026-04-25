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

message("====== Pipeline ronda ======")
result_ronda <- do.call(run_pipeline_ronda, args_common)

overall_success <- result_estab$success && result_ronda$success
if (!overall_success) {
  message("Pipeline terminado con FAIL. Revise logs en data/metadata/.")
  quit(status = 1)
} else {
  message("Ambos pipelines completados exitosamente.")
  quit(status = 0)
}
