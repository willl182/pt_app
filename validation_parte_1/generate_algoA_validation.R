# ===================================================================
# Genera hoja de cálculo de validación del Algoritmo A (ISO 13528:2022)
# Uso: Rscript validation/generate_algoA_validation.R [archivo_csv]
# Si no se pasa argumento, usa data/summary_n4.csv
# Salida: validation/AlgoritmoA_Validacion_<nombre>.xlsx
# ===================================================================

library(openxlsx)
source("R/pt_robust_stats.R")

# --- 0. Parametro de entrada ---
args <- commandArgs(trailingOnly = TRUE)
input_file <- if (length(args) >= 1) args[1] else "data/summary_n4.csv"
if (!file.exists(input_file)) stop("Archivo no encontrado: ", input_file)
base_name <- tools::file_path_sans_ext(basename(input_file))
output_file <- paste0("validation/AlgoritmoA_Validacion_", base_name, ".xlsx")

cat("Entrada:", input_file, "\n")
cat("Salida:", output_file, "\n")

# --- 1. Leer y agregar datos ---
d <- read.csv(input_file, stringsAsFactors = FALSE)
d_part <- d[d$participant_id != "ref", ]
agg <- aggregate(mean_value ~ pollutant + run + level + participant_id,
                 data = d_part, FUN = mean)
combos <- unique(agg[, c("pollutant", "run", "level")])
combos <- combos[order(combos$pollutant, combos$level), ]

# --- 2. Ejecutar Algoritmo A para cada combo ---
results <- list()
for (i in seq_len(nrow(combos))) {
  sub <- agg[agg$pollutant == combos$pollutant[i] &
             agg$run == combos$run[i] &
             agg$level == combos$level[i], ]
  sub <- sub[order(sub$participant_id), ]
  res <- run_algorithm_a(
    values = sub$mean_value,
    ids = sub$participant_id,
    max_iter = 50,
    tol = 1e-06
  )
  res$input_data <- sub
  res$combo <- combos[i, ]
  results[[i]] <- res
}

# --- 3. Estilos ---
wb <- createWorkbook()

header_style <- createStyle(
  fontSize = 11, fontColour = "#FFFFFF", fgFill = "#2C3E50",
  halign = "center", valign = "center", textDecoration = "bold",
  border = "TopBottomLeftRight", borderColour = "#2C3E50"
)
subheader_style <- createStyle(
  fontSize = 10, fontColour = "#FFFFFF", fgFill = "#5D6D7E",
  halign = "center", textDecoration = "bold",
  border = "TopBottomLeftRight"
)
number_style <- createStyle(numFmt = "0.000000000", halign = "right",
                            border = "TopBottomLeftRight")
int_style <- createStyle(numFmt = "0", halign = "center",
                         border = "TopBottomLeftRight")
text_style <- createStyle(halign = "left", border = "TopBottomLeftRight")
formula_style <- createStyle(
  fontSize = 10, fgFill = "#FFF9C4", halign = "left",
  border = "TopBottomLeftRight", wrapText = TRUE
)
pass_style <- createStyle(fgFill = "#C8E6C9", halign = "center",
                          border = "TopBottomLeftRight")
fail_style <- createStyle(fgFill = "#FFCDD2", halign = "center",
                          border = "TopBottomLeftRight")
section_style <- createStyle(
  fontSize = 11, textDecoration = "bold", fgFill = "#E8EAF6",
  border = "TopBottomLeftRight"
)

# --- 4. Hoja INDICE ---
addWorksheet(wb, "INDICE")
writeData(wb, "INDICE", data.frame(
  Campo = c("Documento", "Fuente de datos", "Referencia normativa",
            "Generado", "Tolerancia convergencia", "Max iteraciones",
            "Descripcion"),
  Valor = c(
    "Validacion Algoritmo A - ISO 13528:2022 Anexo C",
    input_file,
    "ISO 13528:2022, Seccion 9.4 y Anexo C",
    as.character(Sys.time()),
    "1e-06",
    "50",
    paste0("Hoja de calculo para verificar paso a paso el Algoritmo A ",
           "(winsorizado) implementado en PT App. Cada hoja contiene los datos ",
           "de entrada, valores iniciales, iteraciones detalladas por participante, ",
           "valores winsorizado finales y resumen. Cesar puede comparar cada celda ",
           "contra su implementacion en Excel.")
  )
), startRow = 1)
addStyle(wb, "INDICE", header_style, rows = 1, cols = 1:2)
addStyle(wb, "INDICE", text_style, rows = 2:8, cols = 1:2, gridExpand = TRUE)
setColWidths(wb, "INDICE", cols = 1:2, widths = c(30, 80))

# Tabla de hojas
writeData(wb, "INDICE", data.frame(Hoja = character(), Analito = character(),
          Nivel = character(), n = integer(), Convergio = character(),
          x_star = numeric(), s_star = numeric()), startRow = 10)
addStyle(wb, "INDICE", subheader_style, rows = 10, cols = 1:7)

for (i in seq_along(results)) {
  res <- results[[i]]
  writeData(wb, "INDICE", data.frame(
    Hoja = paste0("AlgoA_", i),
    Analito = toupper(res$combo$pollutant),
    Nivel = res$combo$level,
    n = res$n,
    Convergio = if (isTRUE(res$converged)) "SI" else "NO",
    x_star = if (is.null(res$error)) res$assigned_value else NA,
    s_star = if (is.null(res$error)) res$robust_sd else NA
  ), startRow = 10 + i, colNames = FALSE)
  addStyle(wb, "INDICE", number_style, rows = 10 + i, cols = 6:7)
}

# --- 5. Hoja de FORMULAS ---
addWorksheet(wb, "FORMULAS")
formulas_data <- data.frame(
  Paso = c(
    "1. Valores iniciales",
    "", "",
    "2. Delta de winsorizado",
    "3. Winsorizar valores",
    "4. Nuevos estimadores",
    "", "",
    "5. Convergencia",
    "6. Resultado final"
  ),
  Formula = c(
    "x*_0 = mediana(xi)",
    "s*_0 = 1.483 * mediana(|xi - mediana(xi)|)   [MADe]",
    "",
    "delta = 1.5 * s*",
    "x*_i = clamp(xi, x* - delta, x* + delta)",
    "x*_nuevo = mean(x*_i winsorizado)",
    "s*_nuevo = 1.134 * sqrt( sum((x*_i - x*_nuevo)^2) / (p - 1) )",
    "",
    "Parar cuando max(|delta_x*|, |delta_s*|) < tolerancia (1e-06)",
    "x* = valor asignado robusto, s* = desviacion robusta"
  ),
  Referencia_ISO = c(
    "Anexo C, paso 1",
    "Anexo C, paso 1; Sec 9.4",
    "",
    "Anexo C, paso 2",
    "Anexo C, paso 3",
    "Anexo C, paso 4",
    "Anexo C, paso 4",
    "",
    "Anexo C, paso 6",
    "Anexo C, final"
  ),
  Nota = c(
    "Mediana de todos los valores de participantes (excl. ref)",
    "Median Absolute Deviation escalado; factor 1.483 para normalidad",
    "",
    "1.5 es el factor de corte para winsorizado",
    "Valores fuera de [x*-delta, x*+delta] se recortan al limite",
    "Media de los valores winsorizado",
    "Factor 1.134 corrige sesgo por winsorizado; p = num participantes",
    "",
    "Tolerancia = 1e-06 (convergencia estricta)",
    "Usados para calcular u(x_pt) = 1.25 * s* / sqrt(n)"
  )
)
writeData(wb, "FORMULAS", formulas_data, startRow = 1)
addStyle(wb, "FORMULAS", header_style, rows = 1, cols = 1:4)
addStyle(wb, "FORMULAS", formula_style, rows = 2:11, cols = 1:4, gridExpand = TRUE)
setColWidths(wb, "FORMULAS", cols = 1:4, widths = c(25, 60, 20, 55))

# --- 6. Hojas por cada combinacion ---
for (idx in seq_along(results)) {
  res <- results[[idx]]
  sheet_name <- paste0("AlgoA_", idx)
  addWorksheet(wb, sheet_name)

  row <- 1
  combo_label <- paste0(toupper(res$combo$pollutant), " - ", res$combo$level)

  # === SECCION A: Encabezado ===
  writeData(wb, sheet_name, data.frame(
    A = c("Analito", "Nivel", "Corrida", "n participantes"),
    B = c(toupper(res$combo$pollutant), res$combo$level,
          res$combo$run, as.character(res$n))
  ), startRow = row, colNames = FALSE)
  addStyle(wb, sheet_name, section_style, rows = row:(row+3), cols = 1, gridExpand = TRUE)
  addStyle(wb, sheet_name, text_style, rows = row:(row+3), cols = 2, gridExpand = TRUE)
  row <- row + 5

  # === SECCION B: Datos de entrada ===
  writeData(wb, sheet_name, "SECCION 1: DATOS DE ENTRADA (media por participante)",
            startRow = row)
  addStyle(wb, sheet_name, section_style, rows = row, cols = 1)
  row <- row + 1

  input_df <- data.frame(
    Participante = res$input_data$participant_id,
    Valor_xi = res$input_data$mean_value
  )
  writeData(wb, sheet_name, input_df, startRow = row)
  addStyle(wb, sheet_name, subheader_style, rows = row, cols = 1:2)
  n_input <- nrow(input_df)
  addStyle(wb, sheet_name, number_style,
           rows = (row+1):(row+n_input), cols = 2, gridExpand = TRUE)
  addStyle(wb, sheet_name, text_style,
           rows = (row+1):(row+n_input), cols = 1, gridExpand = TRUE)
  row <- row + n_input + 2

  # === SECCION C: Valores iniciales ===
  writeData(wb, sheet_name, "SECCION 2: VALORES INICIALES (iteracion 0)",
            startRow = row)
  addStyle(wb, sheet_name, section_style, rows = row, cols = 1)
  row <- row + 1

  init_df <- data.frame(
    Parametro = c("x*_0 (mediana)", "s*_0 (MADe = 1.483 * MAD)"),
    Valor = c(res$initial_median, res$initial_mad_e),
    Formula = c("MEDIAN(xi)", "1.483 * MEDIAN(|xi - MEDIAN(xi)|)")
  )
  writeData(wb, sheet_name, init_df, startRow = row)
  addStyle(wb, sheet_name, subheader_style, rows = row, cols = 1:3)
  addStyle(wb, sheet_name, text_style, rows = (row+1):(row+2), cols = 1, gridExpand = TRUE)
  addStyle(wb, sheet_name, number_style, rows = (row+1):(row+2), cols = 2, gridExpand = TRUE)
  addStyle(wb, sheet_name, formula_style, rows = (row+1):(row+2), cols = 3, gridExpand = TRUE)
  row <- row + 4

  # === SECCION D: Resumen de iteraciones ===
  writeData(wb, sheet_name, "SECCION 3: RESUMEN DE ITERACIONES",
            startRow = row)
  addStyle(wb, sheet_name, section_style, rows = row, cols = 1)
  row <- row + 1

  if (!is.null(res$iterations) && nrow(res$iterations) > 0) {
    iter_df <- res$iterations
    names(iter_df) <- c("Iter", "x*_prev", "s*_prev", "delta_winsor",
                         "lim_inf", "lim_sup", "n_winsorizado",
                         "x*_new", "s*_new", "delta_x", "delta_s", "delta_max")
    writeData(wb, sheet_name, iter_df, startRow = row)
    addStyle(wb, sheet_name, subheader_style, rows = row, cols = 1:12)
    n_iter <- nrow(iter_df)
    addStyle(wb, sheet_name, int_style,
             rows = (row+1):(row+n_iter), cols = 1, gridExpand = TRUE)
    addStyle(wb, sheet_name, int_style,
             rows = (row+1):(row+n_iter), cols = 7, gridExpand = TRUE)
    addStyle(wb, sheet_name, number_style,
             rows = (row+1):(row+n_iter), cols = c(2:6, 8:12), gridExpand = TRUE)

    # Marcar fila de convergencia
    if (isTRUE(res$converged)) {
      addStyle(wb, sheet_name, pass_style,
               rows = row + n_iter, cols = 12)
    }
    row <- row + n_iter + 2
  } else {
    writeData(wb, sheet_name, "No hubo iteraciones (error o datos insuficientes)",
              startRow = row)
    row <- row + 2
  }

  # === SECCION E: Detalle winsorizado por participante por iteracion ===
  writeData(wb, sheet_name,
            "SECCION 4: DETALLE WINSORIZADO POR PARTICIPANTE POR ITERACION",
            startRow = row)
  addStyle(wb, sheet_name, section_style, rows = row, cols = 1)
  row <- row + 1

  writeData(wb, sheet_name, paste0(
    "delta = 1.5*s*;  winsorizado = clamp(xi, x*-delta, x*+delta);  ",
    "is_winsorized = TRUE si xi fue recortado"
  ), startRow = row)
  addStyle(wb, sheet_name, formula_style, rows = row, cols = 1)
  row <- row + 1

  if (!is.null(res$iteration_detail) && nrow(res$iteration_detail) > 0) {
    detail_df <- res$iteration_detail
    names(detail_df) <- c("Iter", "Participante", "Valor_xi", "Winsorizado",
                           "Es_winsorizado", "x_star", "s_star",
                           "delta", "lim_inf", "lim_sup")
    writeData(wb, sheet_name, detail_df, startRow = row)
    addStyle(wb, sheet_name, subheader_style, rows = row, cols = 1:10)
    n_detail <- nrow(detail_df)
    addStyle(wb, sheet_name, int_style,
             rows = (row+1):(row+n_detail), cols = 1, gridExpand = TRUE)
    addStyle(wb, sheet_name, text_style,
             rows = (row+1):(row+n_detail), cols = 2, gridExpand = TRUE)
    addStyle(wb, sheet_name, text_style,
             rows = (row+1):(row+n_detail), cols = 5, gridExpand = TRUE)
    addStyle(wb, sheet_name, number_style,
             rows = (row+1):(row+n_detail), cols = c(3:4, 6:10), gridExpand = TRUE)

    # Resaltar filas donde is_winsorized = TRUE
    for (r in seq_len(n_detail)) {
      if (isTRUE(detail_df$Es_winsorizado[r])) {
        addStyle(wb, sheet_name, fail_style, rows = row + r, cols = 5)
      }
    }
    row <- row + n_detail + 2
  } else {
    writeData(wb, sheet_name, "Sin detalle disponible", startRow = row)
    row <- row + 2
  }

  # === SECCION F: Valores winsorizado finales ===
  writeData(wb, sheet_name, "SECCION 5: VALORES WINSORIZADO FINALES (tras convergencia)",
            startRow = row)
  addStyle(wb, sheet_name, section_style, rows = row, cols = 1)
  row <- row + 1

  if (!is.null(res$weights) && nrow(res$weights) > 0) {
    w_df <- res$weights
    names(w_df) <- c("Participante", "Valor_xi", "Winsorizado_final",
                      "Es_winsorizado")
    writeData(wb, sheet_name, w_df, startRow = row)
    addStyle(wb, sheet_name, subheader_style, rows = row, cols = 1:4)
    n_w <- nrow(w_df)
    addStyle(wb, sheet_name, text_style,
             rows = (row+1):(row+n_w), cols = 1, gridExpand = TRUE)
    addStyle(wb, sheet_name, number_style,
             rows = (row+1):(row+n_w), cols = 2:3, gridExpand = TRUE)
    addStyle(wb, sheet_name, text_style,
             rows = (row+1):(row+n_w), cols = 4, gridExpand = TRUE)

    # Resaltar filas donde is_winsorized = TRUE
    for (r in seq_len(n_w)) {
      if (isTRUE(w_df$Es_winsorizado[r])) {
        addStyle(wb, sheet_name, fail_style, rows = row + r, cols = 4)
      }
    }
    row <- row + n_w + 2
  }

  # === SECCION G: Resultado final ===
  writeData(wb, sheet_name, "SECCION 6: RESULTADO FINAL", startRow = row)
  addStyle(wb, sheet_name, section_style, rows = row, cols = 1)
  row <- row + 1

  if (is.null(res$error)) {
    final_df <- data.frame(
      Parametro = c(
        "x* (valor asignado robusto)",
        "s* (desviacion robusta)",
        "u(x_pt) = 1.25 * s* / sqrt(n)",
        "Convergencia",
        "Iteraciones usadas",
        "n winsorizado (valores recortados)"
      ),
      Valor = c(
        format(res$assigned_value, digits = 12),
        format(res$robust_sd, digits = 12),
        format(1.25 * res$robust_sd / sqrt(res$n), digits = 12),
        if (res$converged) "SI" else "NO",
        as.character(nrow(res$iterations)),
        as.character(res$n_winsorized)
      )
    )
  } else {
    final_df <- data.frame(
      Parametro = "Error",
      Valor = res$error
    )
  }
  writeData(wb, sheet_name, final_df, startRow = row)
  addStyle(wb, sheet_name, subheader_style, rows = row, cols = 1:2)
  n_final <- nrow(final_df)
  addStyle(wb, sheet_name, text_style,
           rows = (row+1):(row+n_final), cols = 1:2, gridExpand = TRUE)

  # Ancho de columnas
  setColWidths(wb, sheet_name, cols = 1:12,
               widths = c(35, 18, 18, 18, 18, 18, 15, 18, 18, 18, 18, 18))
}

# --- 7. Hoja RESUMEN COMPARATIVO ---
addWorksheet(wb, "RESUMEN")
summary_rows <- lapply(results, function(res) {
  data.frame(
    Analito = toupper(res$combo$pollutant),
    Nivel = res$combo$level,
    n = res$n,
    x_star_0_mediana = res$initial_median,
    s_star_0_MADe = res$initial_mad_e,
    x_star_final = if (is.null(res$error)) res$assigned_value else NA,
    s_star_final = if (is.null(res$error)) res$robust_sd else NA,
    u_xpt = if (is.null(res$error)) 1.25 * res$robust_sd / sqrt(res$n) else NA,
    Iteraciones = if (!is.null(res$iterations) && nrow(res$iterations) > 0) nrow(res$iterations) else 0,
    Convergio = if (isTRUE(res$converged)) "SI" else "NO",
    n_winsorizado = if (is.null(res$error)) res$n_winsorized else NA,
    stringsAsFactors = FALSE
  )
})
summary_df <- do.call(rbind, summary_rows)
writeData(wb, "RESUMEN", summary_df, startRow = 1)
addStyle(wb, "RESUMEN", header_style, rows = 1, cols = 1:11)
n_sum <- nrow(summary_df)
addStyle(wb, "RESUMEN", text_style, rows = 2:(1+n_sum), cols = 1:2, gridExpand = TRUE)
addStyle(wb, "RESUMEN", int_style, rows = 2:(1+n_sum), cols = 3, gridExpand = TRUE)
addStyle(wb, "RESUMEN", number_style, rows = 2:(1+n_sum), cols = 4:8, gridExpand = TRUE)
addStyle(wb, "RESUMEN", int_style, rows = 2:(1+n_sum), cols = 9, gridExpand = TRUE)
addStyle(wb, "RESUMEN", text_style, rows = 2:(1+n_sum), cols = 10, gridExpand = TRUE)
addStyle(wb, "RESUMEN", int_style, rows = 2:(1+n_sum), cols = 11, gridExpand = TRUE)
setColWidths(wb, "RESUMEN", cols = 1:11,
             widths = c(10, 18, 5, 18, 18, 18, 18, 18, 12, 10, 15))

# --- 8. Guardar ---
saveWorkbook(wb, output_file, overwrite = TRUE)
cat("Guardado en:", output_file, "\n")
cat("Hojas:", paste(names(wb), collapse = ", "), "\n")
cat("Combinaciones:", nrow(summary_df), "\n")
