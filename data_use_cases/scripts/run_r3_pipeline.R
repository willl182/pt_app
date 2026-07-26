#!/usr/bin/env Rscript

run_rscript <- function(script, args = character(), label) {
  status <- system2("Rscript", c(script, args))
  if (!identical(status, 0L)) {
    stop(label, " falló con estado ", status, call. = FALSE)
  }
  invisible(status)
}

run_r3_pipeline <- function(root = ".", expected_levels = 5L) {
  root <- normalizePath(root, mustWork = TRUE)
  scripts_dir <- file.path(root, "data_use_cases", "scripts")
  processed_dir <- file.path(root, "data_use_cases", "data", "processed")

  preprocess_script <- file.path(scripts_dir, "preprocess_r3.R")
  builder_script <- file.path(scripts_dir, "build_r3_pt_app.R")
  consolidator_script <- file.path(root, "scripts", "aplicativo", "consolidar_ronda_pt_app.R")

  summary_path <- file.path(processed_dir, "r3_resumen_niveles.csv")
  capacity_path <- file.path(processed_dir, "r3_capacidad_horaria.csv")
  participants_path <- file.path(processed_dir, "ronda_3_p_ronda.csv")
  reference_path <- file.path(processed_dir, "ronda_3_r.csv")
  output_path <- file.path(processed_dir, "ronda_3_completa.csv")

  run_rscript(preprocess_script, root, "Preprocesamiento R3")
  run_rscript(
    builder_script,
    c(summary_path, capacity_path, participants_path, reference_path),
    "Construcción de intermedios R3"
  )
  run_rscript(
    consolidator_script,
    c("3", participants_path, reference_path, output_path),
    "Consolidación R3"
  )

  source(builder_script)
  complete <- read_csv_input(output_path, "consolidado R3")
  validate_r3_output(complete, expected_levels = expected_levels)

  cat("Pipeline R3 validado: ", output_path, " (", nrow(complete), " filas)\n", sep = "")
  invisible(complete)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  root <- if (length(args) >= 1L) args[1] else "."
  expected_levels <- if (length(args) >= 2L) as.integer(args[2]) else 5L
  if (is.na(expected_levels) || expected_levels < 1L) {
    stop("expected_levels debe ser un entero positivo", call. = FALSE)
  }

  run_r3_pipeline(root, expected_levels)
}
