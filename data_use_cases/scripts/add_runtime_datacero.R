#!/usr/bin/env Rscript

# Crea copias de las corridas XLSX de datacero y agrega runtime sin modificar
# los archivos crudos. Los documentos T700/DOCX quedan excluidos.

if (!requireNamespace("openxlsx", quietly = TRUE)) {
  stop("Se requiere el paquete openxlsx.")
}

args <- commandArgs(trailingOnly = TRUE)
project_dir <- normalizePath(
  if (length(args) >= 1L) args[[1L]] else ".",
  mustWork = TRUE
)
source_dir <- file.path(project_dir, "data_use_cases", "datacero", "datacero")
output_dir <- file.path(project_dir, "data_use_cases", "data", "datacero_runtime")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

format_runtime <- function(row_count) {
  # Todas las corridas tienen cadencia de un minuto. Se usa posición de fila
  # porque algunos archivos mezclan fechas de texto con seriales Excel dañados.
  elapsed_minutes <- seq.int(0L, row_count - 1L)
  sprintf("%02d:%02d", elapsed_minutes %/% 60L, elapsed_minutes %% 60L)
}

files <- sort(list.files(source_dir, pattern = "\\.xlsx$", full.names = TRUE))
if (length(files) == 0L) {
  stop("No se encontraron archivos XLSX en ", source_dir)
}

summary <- vector("list", length(files))

for (i in seq_along(files)) {
  source_file <- files[[i]]
  destination <- file.path(output_dir, basename(source_file))
  workbook <- openxlsx::loadWorkbook(source_file)
  sheets <- openxlsx::sheets(workbook)
  sheet_summary <- character(length(sheets))

  for (j in seq_along(sheets)) {
    sheet <- sheets[[j]]
    data <- openxlsx::read.xlsx(
      source_file,
      sheet = sheet,
      colNames = FALSE,
      skipEmptyRows = FALSE,
      skipEmptyCols = FALSE,
      detectDates = FALSE
    )

    if (nrow(data) < 3L || ncol(data) < 1L) {
      stop("Hoja sin estructura esperada: ", basename(source_file), " / ", sheet)
    }

    data_row_count <- nrow(data) - 2L
    runtime <- format_runtime(data_row_count)
    runtime_column <- ncol(data) + 1L

    openxlsx::writeData(
      workbook,
      sheet = sheet,
      x = "runtime",
      startCol = runtime_column,
      startRow = 1L,
      colNames = FALSE
    )
    openxlsx::writeData(
      workbook,
      sheet = sheet,
      x = "HH:MM",
      startCol = runtime_column,
      startRow = 2L,
      colNames = FALSE
    )
    openxlsx::writeData(
      workbook,
      sheet = sheet,
      x = runtime,
      startCol = runtime_column,
      startRow = 3L,
      colNames = FALSE,
      keepNA = FALSE
    )
    openxlsx::setColWidths(workbook, sheet, cols = runtime_column, widths = 12)

    sheet_summary[[j]] <- sprintf(
      "%s: %d filas, %s a %s",
      sheet,
      length(runtime),
      runtime[[1L]],
      runtime[[length(runtime)]]
    )
  }

  openxlsx::saveWorkbook(workbook, destination, overwrite = TRUE)
  summary[[i]] <- sprintf("%s | %s", basename(source_file), paste(sheet_summary, collapse = "; "))
}

writeLines(
  c(
    sprintf("Archivos generados: %d", length(files)),
    sprintf("Destino: %s", output_dir),
    unlist(summary)
  )
)
