# ===================================================================
# Generador de Excel con formulas para validacion O3
#
# Fase 2: infraestructura tecnica del generador.
# Define helpers de estilos, rangos nombrados y comparacion contra
# snapshot. Las hojas de calculo numerico se completan en fases
# posteriores del plan 260513_1304.
# ===================================================================

suppressPackageStartupMessages({
  library(openxlsx)
})

find_project_root <- function() {
  cwd <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidates <- c(
    cwd,
    normalizePath(file.path(cwd, ".."), winslash = "/", mustWork = FALSE),
    normalizePath(file.path(cwd, "..", ".."), winslash = "/", mustWork = FALSE)
  )
  for (candidate in unique(candidates)) {
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
formulas_dir <- file.path(output_dir, "formulas")
snapshot_csv <- file.path(output_dir, "valores_validacion_o3.csv")

required_sources <- c(
  file.path("data", "homogeneity - homogeneity.csv"),
  file.path("data", "stability - stability.csv"),
  file.path("data", "summary_n13.csv"),
  file.path("data", "pt_data_n13.csv"),
  snapshot_csv
)

target_combos <- data.frame(
  combo_id = c("O3_0", "O3_80", "O3_180"),
  suffix = c("0", "80", "180"),
  pollutant = "o3",
  n_lab = 13,
  level = c("0-nmol/mol", "80-nmol/mol", "180-nmol/mol"),
  stringsAsFactors = FALSE
)

formula_errors <- c("#REF!", "#DIV/0!", "#VALUE!", "#N/A", "#NAME?")
formula_error_labels <- c("REF", "DIV/0", "VALUE", "N/A", "NAME")

safe_read <- function(path, check_names = FALSE) {
  if (!file.exists(path)) {
    stop("No existe el archivo requerido: ", path)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = check_names)
}

check_required_sources <- function(paths) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) {
    stop("Faltan fuentes requeridas:\n", paste("-", missing, collapse = "\n"))
  }
  invisible(TRUE)
}

make_styles <- function(wb) {
  list(
    title = createStyle(textDecoration = "bold", fontSize = 14),
    header = createStyle(
      textDecoration = "bold",
      fgFill = "#D9EAF7",
      border = "Bottom",
      halign = "center"
    ),
    source = createStyle(fgFill = "#D9EAF7"),
    formula = createStyle(fontColour = "#000000", numFmt = "0.000000000000"),
    link = createStyle(fontColour = "#008000", textDecoration = "underline"),
    control = createStyle(fgFill = "#FFF2CC"),
    ok = createStyle(fgFill = "#E2F0D9"),
    fail = createStyle(fgFill = "#F4CCCC"),
    text = createStyle(wrapText = TRUE, valign = "top")
  )
}

sanitize_excel_name <- function(x) {
  out <- gsub("[^A-Za-z0-9_.]", "_", x)
  out <- gsub("_+", "_", out)
  out <- substr(out, 1, 240)
  if (grepl("^[0-9]", out)) {
    out <- paste0("n_", out)
  }
  out
}

quote_sheet <- function(sheet) {
  paste0("'", gsub("'", "''", sheet), "'")
}

cell_ref <- function(sheet, row, col, absolute = TRUE) {
  ref <- openxlsx::getCellRefs(
    data.frame(x = row, y = col),
    absolute = absolute
  )
  paste0(quote_sheet(sheet), "!", ref)
}

range_ref <- function(sheet, start_row, start_col, end_row, end_col,
                      absolute = TRUE) {
  start <- openxlsx::getCellRefs(
    data.frame(x = start_row, y = start_col),
    absolute = absolute
  )
  end <- openxlsx::getCellRefs(
    data.frame(x = end_row, y = end_col),
    absolute = absolute
  )
  paste0(quote_sheet(sheet), "!", start, ":", end)
}

add_named_range <- function(wb, sheet, name, rows, cols) {
  if (length(rows) == 0 || length(cols) == 0) {
    return(invisible(FALSE))
  }
  openxlsx::createNamedRegion(
    wb = wb,
    sheet = sheet,
    name = sanitize_excel_name(name),
    rows = rows,
    cols = cols,
    overwrite = TRUE
  )
  invisible(TRUE)
}

add_table_named_ranges <- function(wb, sheet, data, table_name,
                                   start_row = 1, start_col = 1) {
  if (nrow(data) < 1 || ncol(data) < 1) {
    return(invisible(FALSE))
  }
  rows <- start_row:(start_row + nrow(data))
  cols <- start_col:(start_col + ncol(data) - 1)
  add_named_range(wb, sheet, table_name, rows = rows, cols = cols)
  column_names <- make.unique(names(data), sep = "_")
  for (j in seq_along(column_names)) {
    col_name <- paste(table_name, column_names[[j]], sep = "_")
    add_named_range(
      wb,
      sheet,
      col_name,
      rows = (start_row + 1):(start_row + nrow(data)),
      cols = start_col + j - 1
    )
  }
  invisible(TRUE)
}

write_styled_table <- function(wb, sheet, data, styles, start_row = 1,
                               start_col = 1, table_name = NULL) {
  data[] <- lapply(data, function(col) {
    ifelse(is.na(col), "", col)
  })
  writeData(
    wb,
    sheet,
    data,
    startRow = start_row,
    startCol = start_col,
    rowNames = FALSE,
    keepNA = FALSE
  )
  if (ncol(data) > 0) {
    addStyle(
      wb,
      sheet,
      styles$header,
      rows = start_row,
      cols = start_col:(start_col + ncol(data) - 1),
      gridExpand = TRUE,
      stack = TRUE
    )
  }
  if (nrow(data) > 0 && ncol(data) > 0) {
    addStyle(
      wb,
      sheet,
      styles$text,
      rows = (start_row + 1):(start_row + nrow(data)),
      cols = start_col:(start_col + ncol(data) - 1),
      gridExpand = TRUE,
      stack = TRUE
    )
  }
  if (!is.null(table_name)) {
    add_table_named_ranges(wb, sheet, data, table_name, start_row, start_col)
  }
  setColWidths(
    wb,
    sheet,
    cols = start_col:(start_col + max(1, ncol(data)) - 1),
    widths = "auto"
  )
  invisible(TRUE)
}

write_formula_cell <- function(wb, sheet, row, col, formula, styles,
                               style = "formula") {
  writeFormula(wb, sheet, x = formula, startRow = row, startCol = col)
  addStyle(wb, sheet, styles[[style]], rows = row, cols = col, stack = TRUE)
  invisible(TRUE)
}

snapshot_for_combo <- function(snapshot, combo_id) {
  out <- snapshot[snapshot$combo_id == combo_id, , drop = FALSE]
  if (nrow(out) == 0) {
    stop("Snapshot sin filas para combo_id: ", combo_id)
  }
  rownames(out) <- NULL
  out
}

drop_empty_columns <- function(data) {
  keep <- vapply(data, function(col) {
    any(!is.na(col) & trimws(as.character(col)) != "")
  }, logical(1))
  data[, keep, drop = FALSE]
}

make_validation_rows <- function(keys, calculated_ref, expected_ref,
                                 tolerance = 1e-8) {
  data.frame(
    item = keys,
    calculado = NA_real_,
    esperado_app = NA_real_,
    delta_abs = NA_real_,
    tolerancia = tolerance,
    estado = NA_character_,
    calculated_ref = calculated_ref,
    expected_ref = expected_ref,
    stringsAsFactors = FALSE
  )
}

write_validation_block <- function(wb, sheet, validation_rows, styles,
                                   start_row = 1, start_col = 1,
                                   table_name = NULL) {
  display <- validation_rows[, c(
    "item", "calculado", "esperado_app", "delta_abs", "tolerancia", "estado"
  ), drop = FALSE]
  write_styled_table(
    wb,
    sheet,
    display,
    styles,
    start_row = start_row,
    start_col = start_col,
    table_name = table_name
  )
  if (nrow(validation_rows) == 0) {
    return(invisible(TRUE))
  }
  first_data_row <- start_row + 1
  last_data_row <- start_row + nrow(validation_rows)
  calc_col <- start_col + 1
  expected_col <- start_col + 2
  delta_col <- start_col + 3
  tolerance_col <- start_col + 4
  state_col <- start_col + 5
  for (i in seq_len(nrow(validation_rows))) {
    row <- first_data_row + i - 1
    write_formula_cell(
      wb,
      sheet,
      row,
      calc_col,
      validation_rows$calculated_ref[[i]],
      styles
    )
    write_formula_cell(
      wb,
      sheet,
      row,
      expected_col,
      validation_rows$expected_ref[[i]],
      styles
    )
    delta_formula <- sprintf(
      'IF(OR(ISBLANK(%s),ISBLANK(%s)),"",ABS(%s-%s))',
      paste0(openxlsx::int2col(calc_col), row),
      paste0(openxlsx::int2col(expected_col), row),
      paste0(openxlsx::int2col(calc_col), row),
      paste0(openxlsx::int2col(expected_col), row)
    )
    state_formula <- sprintf(
      'IF(%s="","Pendiente",IF(%s<=%s,"OK","FALLA"))',
      paste0(openxlsx::int2col(delta_col), row),
      paste0(openxlsx::int2col(delta_col), row),
      paste0(openxlsx::int2col(tolerance_col), row)
    )
    write_formula_cell(wb, sheet, row, delta_col, delta_formula, styles)
    write_formula_cell(wb, sheet, row, state_col, state_formula, styles, "control")
  }
  conditionalFormatting(
    wb,
    sheet,
    cols = state_col,
    rows = first_data_row:last_data_row,
    rule = '=="OK"',
    style = styles$ok
  )
  conditionalFormatting(
    wb,
    sheet,
    cols = state_col,
    rows = first_data_row:last_data_row,
    rule = '=="FALLA"',
    style = styles$fail
  )
  invisible(TRUE)
}

write_readme <- function(wb, combo, styles) {
  sheet <- "README"
  addWorksheet(wb, sheet)
  writeData(wb, sheet, "Excel con formulas validacion O3", startRow = 1, startCol = 1)
  addStyle(wb, sheet, styles$title, rows = 1, cols = 1, stack = TRUE)
  readme <- data.frame(
    bloque = c(
      "Combo",
      "Nivel",
      "Analito",
      "Fecha de generacion",
      "Script generador",
      "Fuentes",
      "Convenciones",
      "Criterio Fase 2"
    ),
    contenido = c(
      combo$combo_id,
      combo$level,
      combo$pollutant,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
      "validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R",
      paste(required_sources, collapse = "\n"),
      "Azul = dato fuente; negro = formula; verde = link interno; amarillo = control.",
      "Andamiaje tecnico creado; calculos numericos se implementan en fases posteriores."
    ),
    stringsAsFactors = FALSE
  )
  write_styled_table(wb, sheet, readme, styles, start_row = 3, table_name = "readme")
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_snapshot_sheet <- function(wb, snapshot_combo, styles) {
  sheet <- "validacion_snapshot"
  addWorksheet(wb, sheet)
  data <- drop_empty_columns(snapshot_combo)
  write_styled_table(
    wb,
    sheet,
    data,
    styles,
    start_row = 1,
    table_name = "snapshot"
  )
  addStyle(
    wb,
    sheet,
    styles$source,
    rows = 2:(nrow(data) + 1),
    cols = seq_len(ncol(data)),
    gridExpand = TRUE,
    stack = TRUE
  )
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_validation_final <- function(wb, styles) {
  sheet <- "validacion_final"
  addWorksheet(wb, sheet)
  summary <- data.frame(
    hoja = c(
      "datos_homogeneidad",
      "datos_estabilidad",
      "datos_participantes",
      "datos_referencia",
      "resultado_homogeneidad",
      "resultado_estabilidad",
      "valor_asignado",
      "algoritmo_A",
      "puntajes_EA",
      "informe_global",
      "heatmap_global"
    ),
    estado = "Pendiente",
    notas = "Se implementa en fases posteriores del plan.",
    stringsAsFactors = FALSE
  )
  write_styled_table(
    wb,
    sheet,
    summary,
    styles,
    start_row = 1,
    table_name = "validacion_final_resumen"
  )
  writeData(wb, sheet, "Estado global", startRow = nrow(summary) + 4, startCol = 1)
  write_formula_cell(
    wb,
    sheet,
    nrow(summary) + 4,
    2,
    sprintf(
      'IF(COUNTIF(B2:B%d,"FALLA")>0,"FALLA",IF(COUNTIF(B2:B%d,"Pendiente")>0,"PENDIENTE","OK"))',
      nrow(summary) + 1,
      nrow(summary) + 1
    ),
    styles,
    "control"
  )
  writeData(wb, sheet, "Errores Excel a escanear tras recalculo", startRow = nrow(summary) + 6, startCol = 1)
  writeData(
    wb,
    sheet,
    paste(formula_error_labels, collapse = ", "),
    startRow = nrow(summary) + 6,
    startCol = 2
  )
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_formula_workbook <- function(combo, snapshot) {
  wb <- createWorkbook()
  styles <- make_styles(wb)
  snapshot_combo <- snapshot_for_combo(snapshot, combo$combo_id)

  write_readme(wb, combo, styles)
  write_snapshot_sheet(wb, snapshot_combo, styles)
  write_validation_final(wb, styles)

  out_path <- file.path(
    formulas_dir,
    paste0("validacion_formula_o3_", combo$suffix, ".xlsx")
  )
  saveWorkbook(wb, out_path, overwrite = TRUE)
  message("Wrote ", out_path)
  out_path
}

run_generator <- function() {
  check_required_sources(required_sources)
  dir.create(formulas_dir, recursive = TRUE, showWarnings = FALSE)
  snapshot <- safe_read(snapshot_csv, check_names = FALSE)
  outputs <- character(nrow(target_combos))
  for (i in seq_len(nrow(target_combos))) {
    outputs[[i]] <- write_formula_workbook(target_combos[i, , drop = FALSE], snapshot)
  }
  summary <- data.frame(
    workbook = basename(outputs),
    path = outputs,
    fase = "Fase 2",
    estado = "andamiaje_generado",
    stringsAsFactors = FALSE
  )
  write.csv(
    summary,
    file.path(formulas_dir, "resumen_validacion_formulas_o3.csv"),
    row.names = FALSE
  )
  invisible(summary)
}

is_rscript <- function() {
  identical(tolower(Sys.getenv("R_SCRIPT_MODE")), "true") ||
    any(grepl("^--file=", commandArgs(trailingOnly = FALSE)))
}

if (is_rscript()) {
  run_generator()
}
