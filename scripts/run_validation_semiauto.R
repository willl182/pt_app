#!/usr/bin/env Rscript

# ===================================================================
# Wrapper semiautomatico para ejecutar validation_1 con datos custom
#
# - Respaldar los archivos fijos de validation_1/data/for_validation
# - Copiar los CSV provistos por argumento a los nombres esperados
# - Ejecutar run_validation_all.R
# - Restaurar los archivos originales al final
# ===================================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3) {
  stop(
    "Uso: Rscript scripts/run_validation_semiauto.R ",
    "\"ruta/homogeneity.csv\" \"ruta/stability.csv\" \"ruta/summary.csv\""
  )
}

homogeneity_src <- normalizePath(args[[1]], mustWork = TRUE)
stability_src <- normalizePath(args[[2]], mustWork = TRUE)
summary_src <- normalizePath(args[[3]], mustWork = TRUE)

project_root <- normalizePath(getwd(), mustWork = TRUE)
validation_dir <- file.path(project_root, "validation_1")
target_dir <- file.path(project_root, "data", "for_validation")

expected_files <- c(
  homogeneity = file.path(target_dir, "homogeneity_n4.csv"),
  stability = file.path(target_dir, "stability_n4.csv"),
  summary = file.path(target_dir, "summary_n4.csv")
)
source_files <- c(
  homogeneity = homogeneity_src,
  stability = stability_src,
  summary = summary_src
)
backup_files <- paste0(expected_files, ".backup_semiauto")
names(backup_files) <- names(expected_files)

copy_file <- function(src, dst) {
  dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(src, dst, overwrite = TRUE)
  if (!isTRUE(ok)) {
    stop("No se pudo copiar: ", src, " -> ", dst)
  }
}

restore_files <- function() {
  for (name in names(expected_files)) {
    dst <- expected_files[[name]]
    bak <- backup_files[[name]]
    if (file.exists(bak)) {
      file.copy(bak, dst, overwrite = TRUE)
      file.remove(bak)
    }
  }
}

for (name in names(expected_files)) {
  dst <- expected_files[[name]]
  bak <- backup_files[[name]]
  if (file.exists(dst)) {
    file.copy(dst, bak, overwrite = TRUE)
  }
}

on.exit(restore_files(), add = TRUE)

for (name in names(expected_files)) {
  copy_file(source_files[[name]], expected_files[[name]])
}

setwd(validation_dir)
source("stage_01_robust_stats.R")
run_stage_01_robust_stats()

source("stage_02_homogeneity.R")
run_stage_02()

source("stage_03_stability.R")
run_stage_03()

source("stage_04_uncertainty_chain.R")
run_stage_04()

source("stage_05_scores.R")
DATA_PT_DATA <- "../data/pt_data_n13.csv"
run_stage_05()

cat("\nValidación semiautomática completada.\n")
