# ===================================================================
# Generador de Excel con formulas para validacion O3
#
# Generador de Excel con formulas para validacion O3
#
# Fase 3+: hojas base con datos crudos, formulas de control y
# comparacion contra snapshot. El libro mantiene el snapshot original
# como referencia y agrega una capa con formulas auditable.
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

normalize_level_key <- function(level) {
  as.numeric(gsub("[^0-9.]+", "", as.character(level)))
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
  ref <- paste0(openxlsx::int2col(col), row)
  if (absolute) {
    ref <- paste0("$", openxlsx::int2col(col), "$", row)
  }
  paste0(quote_sheet(sheet), "!", ref)
}

range_ref <- function(sheet, start_row, start_col, end_row, end_col,
                      absolute = TRUE) {
  start <- paste0(openxlsx::int2col(start_col), start_row)
  end <- paste0(openxlsx::int2col(end_col), end_row)
  if (absolute) {
    start <- paste0("$", openxlsx::int2col(start_col), "$", start_row)
    end <- paste0("$", openxlsx::int2col(end_col), "$", end_row)
  }
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

source_data_by_level <- function(path, pollutant, level) {
  df <- safe_read(path, check_names = FALSE)
  df <- df[df$pollutant == pollutant & df$level == level, , drop = FALSE]
  if (nrow(df) == 0) {
    stop("Sin datos para ", pollutant, " / ", level, " en ", path)
  }
  df <- df[order(df$sample_id, df$replicate), , drop = FALSE]
  sample_ids <- sort(unique(df$sample_id))
  out <- data.frame(sample_id = sample_ids, stringsAsFactors = FALSE)
  for (replicate_id in sort(unique(df$replicate))) {
    rep_data <- df[df$replicate == replicate_id, c("sample_id", "value"), drop = FALSE]
    names(rep_data)[names(rep_data) == "value"] <- paste0("sample_", replicate_id)
    out <- merge(out, rep_data, by = "sample_id", all.x = TRUE, sort = FALSE)
  }
  out[order(out$sample_id), , drop = FALSE]
}

write_formula_data_sheet <- function(wb, sheet, data, styles, kind) {
  addWorksheet(wb, sheet)
  data <- as.data.frame(data, stringsAsFactors = FALSE, check.names = FALSE)
  if (kind == "homogeneity" || kind == "stability") {
    data$promedio_muestra <- ""
    data$rango_absoluto <- ""
    data$abs_diff_from_xpt <- ""
  }
  write_styled_table(wb, sheet, data, styles, start_row = 1, table_name = sheet)
  if (kind == "homogeneity" || kind == "stability") {
    first_data_row <- 2
    last_data_row <- nrow(data) + 1
    for (i in seq_len(nrow(data))) {
      row <- first_data_row + i - 1
      write_formula_cell(
        wb,
        sheet,
        row,
        ncol(data) - 2,
        sprintf("AVERAGE(B%d:C%d)", row, row),
        styles
      )
      write_formula_cell(
        wb,
        sheet,
        row,
        ncol(data) - 1,
        sprintf("ABS(B%d-C%d)", row, row),
        styles
      )
      write_formula_cell(
        wb,
        sheet,
        row,
        ncol(data),
        sprintf("ABS(C%d-MEDIAN($B$2:$B$%d))", row, last_data_row),
        styles
      )
    }
  }
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_participant_sheet <- function(wb, sheet, participants, styles) {
  addWorksheet(wb, sheet)
  participants <- as.data.frame(participants, stringsAsFactors = FALSE, check.names = FALSE)
  participants$u_i_check <- ""
  write_styled_table(wb, sheet, participants, styles, start_row = 1, table_name = sheet)
  first_data_row <- 2
  for (i in seq_len(nrow(participants))) {
    row <- first_data_row + i - 1
    write_formula_cell(
      wb,
      sheet,
      row,
      which(names(participants) == "u_i_check"),
      sprintf("IFERROR(F%d/SQRT(3),\"\")", row),
      styles
    )
  }
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_reference_sheet <- function(wb, sheet, refs, styles) {
  addWorksheet(wb, sheet)
  refs <- as.data.frame(refs, stringsAsFactors = FALSE, check.names = FALSE)
  refs$x_pt_ref <- ""
  refs$u_ref_check <- ""
  write_styled_table(wb, sheet, refs, styles, start_row = 1, table_name = sheet)
  first_data_row <- 2
  for (i in seq_len(nrow(refs))) {
    row <- first_data_row + i - 1
    write_formula_cell(
      wb,
      sheet,
      row,
      which(names(refs) == "x_pt_ref"),
      sprintf("AVERAGE(D%d)", row),
      styles
    )
    write_formula_cell(
      wb,
      sheet,
      row,
      which(names(refs) == "u_ref_check"),
      sprintf("IFERROR(STDEV.S(D%d)/SQRT(COUNT(D%d)),\"\")", row, row),
      styles
    )
  }
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
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
      "Criterio Fase 4"
    ),
    contenido = c(
      combo$combo_id,
      combo$level,
      combo$pollutant,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
      "validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R",
      paste(required_sources, collapse = "\n"),
      "Azul = dato fuente; negro = formula; verde = link interno; amarillo = control.",
      "Homogeneidad y estabilidad generadas con formulas y controles contra snapshot."
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

write_calc_homogeneity <- function(wb, styles, n_rows) {
  sheet <- "calc_homogeneidad"
  addWorksheet(wb, sheet)
  last_row <- n_rows + 1
  sample_1 <- range_ref("datos_homogeneidad", 2, 2, last_row, 2)
  sample_2 <- range_ref("datos_homogeneidad", 2, 3, last_row, 3)
  averages <- range_ref("datos_homogeneidad", 2, 4, last_row, 4)
  ranges <- range_ref("datos_homogeneidad", 2, 5, last_row, 5)
  abs_diffs <- range_ref("datos_homogeneidad", 2, 6, last_row, 6)
  metrics <- data.frame(
    parametro = c(
      "g", "m", "general_mean", "x_pt", "s_x_bar_sq", "sw", "ss_sq",
      "ss", "median_abs_diff", "MADe", "u_sigma_pt", "Q1", "Q3",
      "IQR", "nIQR", "u_sigma_pt_niqr", "criterio_made",
      "criterio_niqr"
    ),
    valor = NA_real_,
    notas = c(
      "Numero de muestras.",
      "Numero de replicas.",
      "Promedio de todos los valores.",
      "Mediana de sample_1.",
      "Varianza de promedios por muestra.",
      "Desviacion dentro de muestra para m = 2.",
      "Componente entre muestras sin truncamiento, usando ABS como ptcalc.",
      "Desviacion entre muestras.",
      "Mediana de |sample_2 - x_pt|.",
      "1.483 * median_abs_diff.",
      "1.25 * MADe / sqrt(g).",
      "Cuartil 25% de sample_1, type 7 equivalente.",
      "Cuartil 75% de sample_1, type 7 equivalente.",
      "Q3 - Q1.",
      "0.7413 * IQR.",
      "1.25 * nIQR / sqrt(g).",
      "0.3 * MADe.",
      "0.3 * nIQR."
    ),
    stringsAsFactors = FALSE
  )
  write_styled_table(wb, sheet, metrics, styles, table_name = "calc_homogeneidad")
  formulas <- c(
    sprintf("COUNT(%s)", sample_1),
    "2",
    sprintf("AVERAGE(%s,%s)", sample_1, sample_2),
    sprintf("MEDIAN(%s)", sample_1),
    sprintf("VAR(%s)", averages),
    sprintf("SQRT(SUMSQ(%s)/(2*B2))", ranges),
    "ABS(B6-(B7^2/B3))",
    "SQRT(B8)",
    sprintf("MEDIAN(%s)", abs_diffs),
    "1.483*B10",
    "IFERROR(1.25*B11/SQRT(B2),0)",
    sprintf("QUARTILE(%s,1)", sample_1),
    sprintf("QUARTILE(%s,3)", sample_1),
    "B14-B13",
    "0.7413*B15",
    "IFERROR(1.25*B16/SQRT(B2),0)",
    "0.3*B11",
    "0.3*B16"
  )
  for (i in seq_along(formulas)) {
    write_formula_cell(wb, sheet, i + 1, 2, formulas[[i]], styles)
  }
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_calc_stability <- function(wb, styles, n_rows) {
  sheet <- "calc_estabilidad"
  addWorksheet(wb, sheet)
  last_row <- n_rows + 1
  sample_1 <- range_ref("datos_estabilidad", 2, 2, last_row, 2)
  sample_2 <- range_ref("datos_estabilidad", 2, 3, last_row, 3)
  averages <- range_ref("datos_estabilidad", 2, 4, last_row, 4)
  ranges <- range_ref("datos_estabilidad", 2, 5, last_row, 5)
  hom_values <- range_ref("datos_homogeneidad", 2, 2, n_rows + 1, 3)
  stab_values <- range_ref("datos_estabilidad", 2, 2, last_row, 3)
  metrics <- data.frame(
    parametro = c(
      "g_stab", "m_stab", "general_mean_stab", "x_pt_stab",
      "s_x_bar_sq_stab", "sw_stab", "ss_sq_stab", "ss_stab",
      "diff_hom_stab", "u_hom_mean", "u_stab_mean",
      "criterio_made", "criterio_made_expandido", "criterio_niqr",
      "criterio_niqr_expandido"
    ),
    valor = NA_real_,
    notas = c(
      "Numero de muestras estabilidad.",
      "Numero de replicas estabilidad.",
      "Promedio de todos los valores de estabilidad.",
      "Mediana de sample_1 estabilidad.",
      "Varianza de promedios estabilidad.",
      "Desviacion dentro de muestra para m = 2.",
      "Componente entre muestras estabilidad.",
      "Desviacion entre muestras estabilidad.",
      "|media estabilidad - media homogeneidad|.",
      "STDEV.S(valores homogeneidad) / sqrt(n).",
      "STDEV.S(valores estabilidad) / sqrt(n).",
      "0.3 * MADe de homogeneidad.",
      "criterio + 2 * incertidumbre de medias.",
      "0.3 * nIQR de homogeneidad.",
      "criterio nIQR + 2 * incertidumbre de medias."
    ),
    stringsAsFactors = FALSE
  )
  write_styled_table(wb, sheet, metrics, styles, table_name = "calc_estabilidad")
  formulas <- c(
    sprintf("COUNT(%s)", sample_1),
    "2",
    sprintf("AVERAGE(%s,%s)", sample_1, sample_2),
    sprintf("MEDIAN(%s)", sample_1),
    sprintf("VAR(%s)", averages),
    sprintf("SQRT(SUMSQ(%s)/(2*B2))", ranges),
    "ABS(B6-(B7^2/B3))",
    "SQRT(B8)",
    "ABS(B4-'calc_homogeneidad'!$B$4)",
    sprintf("IFERROR(STDEV.S(%s)/SQRT(COUNT(%s)),0)", hom_values, hom_values),
    sprintf("IFERROR(STDEV.S(%s)/SQRT(COUNT(%s)),0)", stab_values, stab_values),
    "'calc_homogeneidad'!$B$18",
    "B13+2*SQRT(B11^2+B12^2)",
    "'calc_homogeneidad'!$B$19",
    "B15+2*SQRT(B11^2+B12^2)"
  )
  for (i in seq_along(formulas)) {
    write_formula_cell(wb, sheet, i + 1, 2, formulas[[i]], styles)
  }
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

homogeneity_result_formula <- function(parametro) {
  switch(
    parametro,
    "Muestras (g)" = "'calc_homogeneidad'!$B$2",
    "Réplicas (m)" = "'calc_homogeneidad'!$B$3",
    "x_pt (hom_stab)" = "ROUND('calc_homogeneidad'!$B$5,4)",
    "Median |sample_2 - x_pt|" = "ROUND('calc_homogeneidad'!$B$11,4)",
    "MADe (1.483 × median)" = "ROUND('calc_homogeneidad'!$B$11,4)",
    "u_sigma_pt" = "ROUND('calc_homogeneidad'!$B$12,4)",
    "Q1 (25%)" = "ROUND('calc_homogeneidad'!$B$13,4)",
    "Q3 (75%)" = "ROUND('calc_homogeneidad'!$B$14,4)",
    "IQR (Q3 - Q1)" = "ROUND('calc_homogeneidad'!$B$15,4)",
    "nIQR (0.7413 × IQR)" = "ROUND('calc_homogeneidad'!$B$16,4)",
    "u_sigma_pt (nIQR)" = "ROUND('calc_homogeneidad'!$B$17,4)",
    '""'
  )
}

write_result_section <- function(wb, sheet, snapshot_combo, section, styles) {
  addWorksheet(wb, sheet)
  rows <- snapshot_combo[snapshot_combo$section == section, , drop = FALSE]
  rows <- rows[, c("tabla", "parametro", "app_value"), drop = FALSE]
  rows$calculado <- NA_real_
  rows$delta_abs <- NA_real_
  rows$tolerancia <- 5e-4
  rows$estado <- NA_character_
  write_styled_table(wb, sheet, rows, styles, table_name = sheet)
  for (i in seq_len(nrow(rows))) {
    row <- i + 1
    write_formula_cell(
      wb,
      sheet,
      row,
      4,
      homogeneity_result_formula(rows$parametro[[i]]),
      styles
    )
    write_formula_cell(
      wb,
      sheet,
      row,
      5,
      sprintf("IFERROR(ABS(D%d-C%d),\"\")", row, row),
      styles
    )
    write_formula_cell(
      wb,
      sheet,
      row,
      7,
      sprintf('IF(E%d="","Pendiente",IF(E%d<=F%d,"OK","FALLA"))', row, row, row),
      styles,
      "control"
    )
  }
  conditionalFormatting(
    wb,
    sheet,
    cols = 7,
    rows = 2:(nrow(rows) + 1),
    rule = '=="OK"',
    style = styles$ok
  )
  conditionalFormatting(
    wb,
    sheet,
    cols = 7,
    rows = 2:(nrow(rows) + 1),
    rule = '=="FALLA"',
    style = styles$fail
  )
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_assigned_value_sheet <- function(wb, snapshot_combo, styles) {
  sheet <- "valor_asignado"
  addWorksheet(wb, sheet)
  rows <- snapshot_combo[snapshot_combo$section == sheet, , drop = FALSE]
  rows <- rows[, c(
    "method_key", "method", "x_pt", "sigma_pt", "u_xpt", "u_hom",
    "u_stab", "u_xpt_def", "U_xpt", "n_participants"
  ), drop = FALSE]
  rows$estado <- NA_character_
  write_styled_table(wb, sheet, rows, styles, table_name = sheet)

  participant_values <- range_ref(
    "datos_participantes", 2, 4, nrow(rows) + 8, 4
  )
  n_participants <- "COUNT('datos_participantes'!$D:$D)"
  ref_x_pt <- "'datos_referencia'!$D$2"
  ref_u_xpt <- "'datos_referencia'!$E$2"
  u_hom <- "'calc_homogeneidad'!$B$9"
  u_stab <- "'calc_estabilidad'!$B$10/SQRT(3)"
  algo_x_pt <- "'algoritmo_A_iteraciones'!$B$7"
  algo_s_pt <- "'algoritmo_A_iteraciones'!$B$8"

  calculated <- list(
    ref = list(
      x_pt = ref_x_pt,
      sigma_pt = sprintf("0.02*%s+1", ref_x_pt),
      u_xpt = ref_u_xpt
    ),
    consensus_ma = list(
      x_pt = sprintf("MEDIAN(%s)", participant_values),
      sigma_pt = "'algoritmo_A_iteraciones'!$B$3",
      u_xpt = sprintf("1.25*D3/SQRT(%s)", n_participants)
    ),
    consensus_niqr = list(
      x_pt = sprintf("MEDIAN(%s)", participant_values),
      sigma_pt = sprintf(
        "0.7413*(QUARTILE(%s,3)-QUARTILE(%s,1))",
        participant_values,
        participant_values
      ),
      u_xpt = sprintf("1.25*D4/SQRT(%s)", n_participants)
    ),
    algo = list(
      x_pt = algo_x_pt,
      sigma_pt = algo_s_pt,
      u_xpt = sprintf("1.25*D5/SQRT(%s)", n_participants)
    ),
    expert = list(
      x_pt = ref_x_pt,
      sigma_pt = sprintf("0.02*%s+1", ref_x_pt),
      u_xpt = ref_u_xpt
    )
  )

  for (i in seq_len(nrow(rows))) {
    row <- i + 1
    key <- rows$method_key[[i]]
    write_formula_cell(wb, sheet, row, 3, calculated[[key]]$x_pt, styles)
    write_formula_cell(wb, sheet, row, 4, calculated[[key]]$sigma_pt, styles)
    write_formula_cell(wb, sheet, row, 5, calculated[[key]]$u_xpt, styles)
    write_formula_cell(wb, sheet, row, 6, u_hom, styles)
    write_formula_cell(wb, sheet, row, 7, u_stab, styles)
    write_formula_cell(wb, sheet, row, 8, sprintf("SQRT(E%d^2+F%d^2+G%d^2)", row, row, row), styles)
    write_formula_cell(wb, sheet, row, 9, sprintf("2*H%d", row), styles)
    write_formula_cell(wb, sheet, row, 10, n_participants, styles)
    write_formula_cell(
      wb,
      sheet,
      row,
      11,
      sprintf(
        'IF(SUM(ABS(C%d-%s),ABS(D%d-%s),ABS(E%d-%s),ABS(F%d-%s),ABS(G%d-%s),ABS(H%d-%s),ABS(I%d-%s),ABS(J%d-%s))<=1E-8,"OK","FALLA")',
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 11),
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 12),
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 13),
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 14),
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 15),
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 16),
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 17),
        row, cell_ref("validacion_snapshot", which(snapshot_combo$section == sheet)[[i]] + 1, 18)
      ),
      styles,
      "control"
    )
  }
  conditionalFormatting(wb, sheet, cols = 11, rows = 2:(nrow(rows) + 1), rule = '=="OK"', style = styles$ok)
  conditionalFormatting(wb, sheet, cols = 11, rows = 2:(nrow(rows) + 1), rule = '=="FALLA"', style = styles$fail)
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

sig3_formula <- function(ref) {
  sprintf("IF(OR(NOT(ISNUMBER(%s)),%s=0),%s,ROUND(%s,MAX(3-1-INT(LOG10(ABS(%s))),0)))", ref, ref, ref, ref, ref)
}

write_algorithm_iterations_sheet <- function(wb, combo, participants, styles) {
  sheet <- "algoritmo_A_iteraciones"
  addWorksheet(wb, sheet)
  values_last_row <- nrow(participants) + 10
  value_range <- range_ref(sheet, 11, 2, values_last_row, 2, absolute = FALSE)
  metadata <- data.frame(
    metrica = c(
      "x0_mediana", "s0_MADe", "tolerancia", "n_participantes",
      "iteracion_final", "x_final", "s_final", "n_winsorizadas_final"
    ),
    valor = NA_real_,
    stringsAsFactors = FALSE
  )
  write_styled_table(wb, sheet, metadata, styles, start_row = 1)
  write_formula_cell(wb, sheet, 2, 2, sprintf("MEDIAN(%s)", value_range), styles)
  write_formula_cell(wb, sheet, 3, 2, sprintf("1.483*MEDIAN(C11:C%d)", values_last_row), styles)
  writeData(wb, sheet, 1e-10, startRow = 4, startCol = 2)
  write_formula_cell(wb, sheet, 5, 2, sprintf("COUNT(%s)", value_range), styles)

  participant_block <- participants[, c("participant_id", "mean_value"), drop = FALSE]
  names(participant_block) <- c("participant_id", "xi")
  participant_block$abs_xi_x0 <- NA_real_
  write_styled_table(wb, sheet, participant_block, styles, start_row = 10)
  for (i in seq_len(nrow(participant_block))) {
    row <- i + 10
    write_formula_cell(wb, sheet, row, 3, sprintf("ABS(B%d-$B$2)", row), styles)
  }

  iter_start <- values_last_row + 4
  participant_cols <- seq(7, length.out = nrow(participants))
  first_result_col <- max(participant_cols) + 1
  headers <- c(
    "iteracion", "x_prev", "s_prev", "delta", "limite_inf", "limite_sup",
    paste0("w_", participants$participant_id),
    "x_new", "s_new", "delta_x", "delta_s", "sig3_x_prev",
    "sig3_s_prev", "sig3_x_new", "sig3_s_new", "signif3_converged",
    "guardia_numerica", "fila_seleccionada"
  )
  writeData(wb, sheet, as.data.frame(t(headers), stringsAsFactors = FALSE), startRow = iter_start, colNames = FALSE)
  addStyle(wb, sheet, styles$header, rows = iter_start, cols = seq_along(headers), gridExpand = TRUE, stack = TRUE)
  for (iter in seq_len(50)) {
    row <- iter_start + iter
    prev_row <- row - 1
    writeData(wb, sheet, iter, startRow = row, startCol = 1)
    write_formula_cell(wb, sheet, row, 2, if (iter == 1) "$B$2" else sprintf("%s%d", int2col(first_result_col), prev_row), styles)
    write_formula_cell(wb, sheet, row, 3, if (iter == 1) "$B$3" else sprintf("%s%d", int2col(first_result_col + 1), prev_row), styles)
    write_formula_cell(wb, sheet, row, 4, sprintf("1.5*C%d", row), styles)
    write_formula_cell(wb, sheet, row, 5, sprintf("B%d-D%d", row, row), styles)
    write_formula_cell(wb, sheet, row, 6, sprintf("B%d+D%d", row, row), styles)
    for (j in seq_len(nrow(participants))) {
      data_row <- 10 + j
      write_formula_cell(
        wb,
        sheet,
        row,
        participant_cols[[j]],
        sprintf("MIN(MAX($B$%d,$E%d),$F%d)", data_row, row, row),
        styles
      )
    }
    win_range <- sprintf("%s%d:%s%d", int2col(min(participant_cols)), row, int2col(max(participant_cols)), row)
    write_formula_cell(wb, sheet, row, first_result_col, sprintf("AVERAGE(%s)", win_range), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 1, sprintf("1.134*STDEV(%s)", win_range), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 2, sprintf("ABS(%s%d-B%d)", int2col(first_result_col), row, row), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 3, sprintf("ABS(%s%d-C%d)", int2col(first_result_col + 1), row, row), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 4, sig3_formula(sprintf("B%d", row)), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 5, sig3_formula(sprintf("C%d", row)), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 6, sig3_formula(sprintf("%s%d", int2col(first_result_col), row)), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 7, sig3_formula(sprintf("%s%d", int2col(first_result_col + 1), row)), styles)
    write_formula_cell(wb, sheet, row, first_result_col + 8, sprintf("IF(AND(%s%d=%s%d,%s%d=%s%d),1,0)", int2col(first_result_col + 6), row, int2col(first_result_col + 4), row, int2col(first_result_col + 7), row, int2col(first_result_col + 5), row), styles, "control")
    write_formula_cell(wb, sheet, row, first_result_col + 9, sprintf("IF(AND(%s%d<$B$4,%s%d<$B$4),1,0)", int2col(first_result_col + 2), row, int2col(first_result_col + 3), row), styles, "control")
    write_formula_cell(wb, sheet, row, first_result_col + 10, sprintf("IF(OR(%s%d=1,%s%d=1),1,0)", int2col(first_result_col + 8), row, int2col(first_result_col + 9), row), styles, "control")
  }
  iter_last <- iter_start + 50
  selected_range <- sprintf("%s%d:%s%d", int2col(first_result_col + 10), iter_start + 1, int2col(first_result_col + 10), iter_last)
  write_formula_cell(wb, sheet, 6, 2, sprintf("IFERROR(MATCH(1,%s,0),50)", selected_range), styles, "control")
  write_formula_cell(wb, sheet, 7, 2, sprintf("INDEX(%s%d:%s%d,$B$6)", int2col(first_result_col), iter_start + 1, int2col(first_result_col), iter_last), styles)
  write_formula_cell(wb, sheet, 8, 2, sprintf("INDEX(%s%d:%s%d,$B$6)", int2col(first_result_col + 1), iter_start + 1, int2col(first_result_col + 1), iter_last), styles)
  winsorized_terms <- paste(
    sprintf(
      "--(INDEX(%s%d:%s%d,$B$6)<>$B$%d)",
      int2col(participant_cols),
      iter_start + 1,
      int2col(participant_cols),
      iter_last,
      10 + seq_len(nrow(participants))
    ),
    collapse = "+"
  )
  write_formula_cell(wb, sheet, 9, 2, winsorized_terms, styles)
  freezePane(wb, sheet, firstRow = FALSE)
  invisible(TRUE)
}

algorithm_summary_formula <- function(parametro, combo) {
  if (combo$suffix == "0") {
    return("0")
  }
  switch(
    parametro,
    "Analito" = '"O3"',
    "Esquema (n)" = as.character(combo$n_lab),
    "Nivel" = paste0('"', combo$level, '"'),
    "n participantes" = "'algoritmo_A_iteraciones'!$B$5",
    "x*0 = mediana" = "ROUND('algoritmo_A_iteraciones'!$B$2,4)",
    "s*0 = MADe" = "ROUND('algoritmo_A_iteraciones'!$B$3,4)",
    "x* (valor asignado)" = "ROUND('algoritmo_A_iteraciones'!$B$7,4)",
    "s* (desviación robusta)" = "ROUND('algoritmo_A_iteraciones'!$B$8,4)",
    "Observaciones winzorizadas" = "'algoritmo_A_iteraciones'!$B$9",
    "Observaciones totales" = "'algoritmo_A_iteraciones'!$B$5",
    "n_iteraciones" = "'algoritmo_A_iteraciones'!$B$6",
    "criterio" = '"3 cifras significativas"',
    "guardia_numérica" = "TEXT('algoritmo_A_iteraciones'!$B$4,\"0.0000000000\")",
    "primera_iteración_3ra_cifra" = "'algoritmo_A_iteraciones'!$B$6",
    '""'
  )
}

write_algorithm_summary_sheet <- function(wb, combo, snapshot_combo, styles) {
  sheet <- "algoritmo_A"
  addWorksheet(wb, sheet)
  rows <- snapshot_combo[snapshot_combo$section == sheet, , drop = FALSE]
  rows <- rows[, c("bloque", "parametro", "app_value"), drop = FALSE]
  rows$calculado <- NA_character_
  rows$estado <- NA_character_
  write_styled_table(wb, sheet, rows, styles, table_name = sheet)
  snapshot_rows <- which(snapshot_combo$section == sheet)
  for (i in seq_len(nrow(rows))) {
    row <- i + 1
    write_formula_cell(wb, sheet, row, 4, algorithm_summary_formula(rows$parametro[[i]], combo), styles)
    expected <- cell_ref("validacion_snapshot", snapshot_rows[[i]] + 1, 8)
    write_formula_cell(
      wb,
      sheet,
      row,
      5,
      sprintf(
        'IF(IFERROR(ABS(D%d-%s)<=5E-4,D%d=%s),"OK","FALLA")',
        row,
        expected,
        row,
        expected
      ),
      styles,
      "control"
    )
  }
  conditionalFormatting(wb, sheet, cols = 5, rows = 2:(nrow(rows) + 1), rule = '=="OK"', style = styles$ok)
  conditionalFormatting(wb, sheet, cols = 5, rows = 2:(nrow(rows) + 1), rule = '=="FALLA"', style = styles$fail)
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_validation_final <- function(wb, styles) {
  sheet <- "validacion_final"
  addWorksheet(wb, sheet)
  summary <- data.frame(
    hoja = c(
      "datos_homogeneidad",
      "calc_homogeneidad",
      "resultado_homogeneidad",
      "datos_estabilidad",
      "calc_estabilidad",
      "resultado_estabilidad",
      "datos_participantes",
      "datos_referencia",
      "valor_asignado",
      "algoritmo_A_iteraciones",
      "algoritmo_A",
      "validacion_snapshot",
      "validacion_final"
    ),
    estado = c(
      "Implementado",
      "Implementado",
      NA_character_,
      "Implementado",
      "Implementado",
      NA_character_,
      "Implementado",
      "Implementado",
      NA_character_,
      "Implementado",
      NA_character_,
      "Implementado",
      NA_character_
    ),
    notas = c(
      "Datos de homogeneidad filtrados por combo.",
      "Calculos Excel de homogeneidad con MADe y nIQR.",
      "Tabla visible app.R y comparacion contra snapshot.",
      "Datos de estabilidad filtrados por combo.",
      "Calculos Excel de estabilidad y criterios internos.",
      "Tabla visible app.R repetida segun comportamiento validado.",
      "Participantes excluyendo ref con control u_i.",
      "Referencia con controles de promedio e incertidumbre.",
      "Parametros por metodo con incertidumbres compuestas.",
      "Traza de 50 iteraciones del Algoritmo A.",
      "Resumen visible app.R y comparacion contra snapshot.",
      "Snapshot congelado del combo.",
      "Resumen de comparacion de estado del libro."
    ),
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
  write_formula_cell(
    wb,
    sheet,
    4,
    2,
    'IF(COUNTIF(\'resultado_homogeneidad\'!$G:$G,"FALLA")>0,"FALLA",IF(COUNTIF(\'resultado_homogeneidad\'!$G:$G,"Pendiente")>0,"PENDIENTE","OK"))',
    styles,
    "control"
  )
  write_formula_cell(
    wb,
    sheet,
    7,
    2,
    'IF(COUNTIF(\'resultado_estabilidad\'!$G:$G,"FALLA")>0,"FALLA",IF(COUNTIF(\'resultado_estabilidad\'!$G:$G,"Pendiente")>0,"PENDIENTE","OK"))',
    styles,
    "control"
  )
  write_formula_cell(
    wb,
    sheet,
    10,
    2,
    'IF(COUNTIF(\'valor_asignado\'!$K:$K,"FALLA")>0,"FALLA",IF(COUNTIF(\'valor_asignado\'!$K:$K,"Pendiente")>0,"PENDIENTE","OK"))',
    styles,
    "control"
  )
  write_formula_cell(
    wb,
    sheet,
    12,
    2,
    'IF(COUNTIF(\'algoritmo_A\'!$E:$E,"FALLA")>0,"FALLA",IF(COUNTIF(\'algoritmo_A\'!$E:$E,"Pendiente")>0,"PENDIENTE","OK"))',
    styles,
    "control"
  )
  write_formula_cell(
    wb,
    sheet,
    14,
    2,
    'IF(SUM(C20:C24)>0,"FALLA","OK")',
    styles,
    "control"
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
  error_start <- nrow(summary) + 6
  errors <- data.frame(
    error_excel = formula_errors,
    etiqueta = formula_error_labels,
    conteo = NA_integer_,
    stringsAsFactors = FALSE
  )
  write_styled_table(
    wb,
    sheet,
    errors,
    styles,
    start_row = error_start,
    table_name = "validacion_final_errores"
  )
  result_ranges <- c(
    "'resultado_homogeneidad'!$A:$G",
    "'resultado_estabilidad'!$A:$G",
    "'calc_homogeneidad'!$A:$C",
    "'calc_estabilidad'!$A:$C",
    "'valor_asignado'!$A:$K",
    "'algoritmo_A_iteraciones'!$A:$Z",
    "'algoritmo_A'!$A:$E"
  )
  for (i in seq_len(nrow(errors))) {
    row <- error_start + i
    count_formula <- paste(
      sprintf("COUNTIF(%s,A%d)", result_ranges, row),
      collapse = "+"
    )
    write_formula_cell(wb, sheet, row, 3, count_formula, styles, "control")
  }
  writeData(wb, sheet, "Total errores Excel", startRow = error_start + nrow(errors) + 2, startCol = 1)
  write_formula_cell(
    wb,
    sheet,
    error_start + nrow(errors) + 2,
    2,
    sprintf("SUM(C%d:C%d)", error_start + 1, error_start + nrow(errors)),
    styles,
    "control"
  )
  freezePane(wb, sheet, firstRow = TRUE)
  invisible(TRUE)
}

write_formula_workbook <- function(combo, snapshot) {
  wb <- createWorkbook()
  styles <- make_styles(wb)
  snapshot_combo <- snapshot_for_combo(snapshot, combo$combo_id)
  hom <- source_data_by_level(file.path("data", "homogeneity - homogeneity.csv"), combo$pollutant, combo$level)
  stab <- source_data_by_level(file.path("data", "stability - stability.csv"), combo$pollutant, combo$level)
  participants <- safe_read(file.path("data", "summary_n13.csv"), check_names = FALSE)
  participants <- participants[participants$pollutant == combo$pollutant & participants$level == combo$level & participants$participant_id != "ref", , drop = FALSE]
  participants <- aggregate(cbind(mean_value, sd_value) ~ participant_id, participants, mean, na.rm = TRUE)
  participants$pollutant <- combo$pollutant
  participants$level <- combo$level
  participants <- participants[, c("participant_id", "pollutant", "level", "mean_value", "sd_value"), drop = FALSE]
  if (file.exists(file.path("data", "pt_data_n13.csv"))) {
    pt_data <- safe_read(file.path("data", "pt_data_n13.csv"), check_names = FALSE)
    pt_data <- pt_data[pt_data$pollutant == combo$pollutant & pt_data$level == combo$level, c("participant_id", "u_i"), drop = FALSE]
    participants <- merge(participants, pt_data, by = "participant_id", all.x = TRUE, sort = FALSE)
  } else {
    participants$u_i <- NA_real_
  }
  participants <- participants[order(participants$participant_id), , drop = FALSE]
  refs <- safe_read(file.path("data", "summary_n13.csv"), check_names = FALSE)
  refs <- refs[refs$pollutant == combo$pollutant & refs$level == combo$level & refs$participant_id == "ref", , drop = FALSE]
  if (nrow(refs) > 0) {
    refs <- aggregate(cbind(mean_value, sd_value) ~ pollutant + level + participant_id, refs, mean, na.rm = TRUE)
  }
  if (nrow(refs) == 0) {
    refs <- data.frame(pollutant = combo$pollutant, level = combo$level, participant_id = "ref", mean_value = NA_real_, sd_value = NA_real_)
  }
  write_readme(wb, combo, styles)
  write_formula_data_sheet(wb, "datos_homogeneidad", hom, styles, "homogeneity")
  write_calc_homogeneity(wb, styles, nrow(hom))
  write_result_section(
    wb,
    "resultado_homogeneidad",
    snapshot_combo,
    "resultado_homogeneidad",
    styles
  )
  write_formula_data_sheet(wb, "datos_estabilidad", stab, styles, "stability")
  write_calc_stability(wb, styles, nrow(stab))
  write_result_section(
    wb,
    "resultado_estabilidad",
    snapshot_combo,
    "resultado_estabilidad",
    styles
  )
  write_participant_sheet(wb, "datos_participantes", participants, styles)
  write_reference_sheet(wb, "datos_referencia", refs, styles)
  write_algorithm_iterations_sheet(wb, combo, participants, styles)
  write_assigned_value_sheet(wb, snapshot_combo, styles)
  write_algorithm_summary_sheet(wb, combo, snapshot_combo, styles)
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
    fase = "Fase 5",
    estado = "valor_asignado_algoritmo_a_formulas",
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
