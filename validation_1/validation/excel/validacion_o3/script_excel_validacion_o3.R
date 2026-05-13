# ===================================================================
# Generador de Excel para validacion O3
# Usa valores congelados en valores_validacion_o3.csv
# ===================================================================

suppressPackageStartupMessages({
  library(openxlsx)
})

find_project_root <- function() {
  cwd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidates <- c(cwd, normalizePath(file.path(cwd, ".."), winslash = "/", mustWork = FALSE))
  for (candidate in candidates) {
    if (file.exists(file.path(candidate, "app.R")) &&
        file.exists(file.path(candidate, "data", "summary_n13.csv"))) {
      return(candidate)
    }
  }
  stop("No se pudo localizar la raiz del proyecto desde: ", cwd)
}

root_dir <- find_project_root()
setwd(root_dir)

output_dir <- file.path("validation_1", "validation", "excel", "validacion_o3")
source_csv <- file.path(output_dir, "valores_validacion_o3.csv")

if (!file.exists(source_csv)) {
  stop(
    "Falta el archivo de valores de validacion: ", source_csv, "\n",
    "Genere/refresque explicitamente con: ",
    "Rscript validation_1/validation/excel/validacion_o3/generar_valores_validacion_o3.R"
  )
}

copy_values <- read.csv(source_csv, stringsAsFactors = FALSE, check.names = FALSE)

target_combos <- data.frame(
  combo_id = c("O3_0", "O3_80", "O3_180"),
  suffix = c("0", "80", "180"),
  stringsAsFactors = FALSE
)

section_sheets <- c(
  "resultado_homogeneidad",
  "resultado_estabilidad",
  "valor_asignado",
  "algoritmo_A",
  "puntajes_EA",
  "informe_global"
)

drop_empty_columns <- function(data) {
  keep <- vapply(data, function(col) any(!is.na(col) & col != ""), logical(1))
  data[, keep, drop = FALSE]
}

write_copy_sheet <- function(wb, sheet, data) {
  addWorksheet(wb, sheet)
  writeData(wb, sheet, data, startRow = 1, startCol = 1, rowNames = FALSE)
  header_style <- createStyle(
    textDecoration = "bold",
    fgFill = "#D9EAF7",
    border = "Bottom"
  )
  value_style <- createStyle(
    fgFill = "#E2F0D9",
    numFmt = "0.000000000000"
  )
  key_row_style <- createStyle(
    textDecoration = "bold",
    fgFill = "#FFF2CC"
  )
  addStyle(
    wb,
    sheet,
    header_style,
    rows = 1,
    cols = seq_len(ncol(data)),
    gridExpand = TRUE
  )
  value_col <- match("app_value", names(data))
  if (!is.na(value_col) && nrow(data) > 0) {
    addStyle(
      wb,
      sheet,
      value_style,
      rows = 2:(nrow(data) + 1),
      cols = value_col,
      gridExpand = TRUE,
      stack = TRUE
    )
  }
  key_col <- if ("parametro" %in% names(data)) {
    "parametro"
  } else if ("metric" %in% names(data)) {
    "metric"
  } else {
    NA_character_
  }
  key_terms <- c(
    "x_pt", "sigma_pt", "u_xpt", "u_xpt_def", "U_xpt",
    "n_iteraciones", "nIQR", "MADe", "ss", "diff_hom_stab",
    "criterio", "resultado", "valor asignado", "desviación robusta",
    "Observaciones winzorizadas", "primera_iteración"
  )
  if (!is.na(key_col) && nrow(data) > 0) {
    key_values <- as.character(data[[key_col]])
    key_rows <- which(grepl(paste(key_terms, collapse = "|"), key_values, ignore.case = TRUE)) + 1
    if (length(key_rows) > 0) {
      addStyle(
        wb,
        sheet,
        key_row_style,
        rows = key_rows,
        cols = seq_len(ncol(data)),
        gridExpand = TRUE,
        stack = TRUE
      )
    }
  }
  setColWidths(wb, sheet, cols = 1:max(1, ncol(data)), widths = "auto")
  freezePane(wb, sheet, firstRow = TRUE)
}

write_combo_workbook <- function(combo_id, suffix) {
  wb <- createWorkbook()
  addWorksheet(wb, "README")
  writeData(wb, "README", data.frame(
    item = c("Fuente", "Combo", "Alcance"),
    value = c(
      "Valores app.R",
      combo_id,
      "O3 niveles 0, 80 y 180; este archivo contiene el nivel indicado"
    )
  ))

  for (section in section_sheets) {
    data <- copy_values[
      copy_values$combo_id == combo_id &
        copy_values$section == section,
      ,
      drop = FALSE
    ]
    data <- drop_empty_columns(data)
    write_copy_sheet(wb, section, data)
  }

  out_path <- file.path(output_dir, paste0("validacion_excel_o3_", suffix, ".xlsx"))
  saveWorkbook(wb, out_path, overwrite = TRUE)
  message("Wrote ", out_path)
}

for (i in seq_len(nrow(target_combos))) {
  write_combo_workbook(target_combos$combo_id[[i]], target_combos$suffix[[i]])
}
