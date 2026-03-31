# ===================================================================
# Genera UNA hoja con FORMULAS VIVAS para Algoritmo A
# ISO 13528:2022, Anexo C - Winsorización iterativa
#
# Uso: Rscript validation/generate_algoA_live.R [archivo_csv] [analito] [nivel]
# Default: summary_n13.csv, co, 0-μmol/mol
# Para otra combinacion: duplicar la hoja en Excel y pegar nuevos datos
# ===================================================================

library(openxlsx)
source("R/pt_robust_stats.R")

args <- commandArgs(trailingOnly = TRUE)
input_file <- if (length(args) >= 1) args[1] else "data/summary_n13.csv"
sel_pollutant <- if (length(args) >= 2) args[2] else "co"
sel_level <- if (length(args) >= 3) args[3] else "0-\u00b5mol/mol"

normalize_level_label <- function(x) {
  x <- enc2utf8(x)
  x <- gsub("\u00b5", "\u03bc", x, fixed = TRUE)
  x
}

if (!file.exists(input_file)) stop("Archivo no encontrado: ", input_file)

d <- read.csv(input_file, stringsAsFactors = FALSE)
d_part <- d[d$participant_id != "ref", ]
d_part$level_norm <- normalize_level_label(d_part$level)
sel_level_norm <- normalize_level_label(sel_level)
agg <- aggregate(mean_value ~ pollutant + run + level + participant_id,
                 data = d_part, FUN = mean)
agg$level_norm <- normalize_level_label(agg$level)
sub <- agg[agg$pollutant == sel_pollutant & agg$level_norm == sel_level_norm, ]
sub <- sub[order(sub$participant_id), ]

if (nrow(sub) == 0) {
  cat("Combinaciones disponibles:\n")
  print(unique(agg[, c("pollutant", "level")]))
  stop("No se encontro: ", sel_pollutant, " / ", sel_level)
}

p <- nrow(sub)
MAX_ITER <- 10

cat("Entrada:", input_file, "\n")
cat("Combo:", toupper(sel_pollutant), "/", sel_level, "/ n =", p, "\n")

# --- Helpers ---
col_letter <- function(n) {
  result <- ""
  while (n > 0) {
    n <- n - 1
    result <- paste0(LETTERS[n %% 26 + 1], result)
    n <- n %/% 26
  }
  result
}

# --- Estilos ---
wb <- createWorkbook()

sty_title <- createStyle(fontSize = 12, textDecoration = "bold",
                         fgFill = "#2C3E50", fontColour = "#FFFFFF",
                         halign = "left", border = "TopBottomLeftRight")
sty_header <- createStyle(fontSize = 10, textDecoration = "bold",
                          fgFill = "#5D6D7E", fontColour = "#FFFFFF",
                          halign = "center", border = "TopBottomLeftRight",
                          wrapText = TRUE)
sty_label <- createStyle(fontSize = 10, textDecoration = "bold",
                         fgFill = "#E8EAF6", halign = "left",
                         border = "TopBottomLeftRight")
sty_input <- createStyle(fontSize = 10, fgFill = "#FFF9C4",
                         numFmt = "0.000000000", halign = "right",
                         border = "TopBottomLeftRight")
sty_formula <- createStyle(fontSize = 10, numFmt = "0.000000000",
                           halign = "right", border = "TopBottomLeftRight")
sty_int <- createStyle(fontSize = 10, numFmt = "0", halign = "center",
                       border = "TopBottomLeftRight")
sty_bool <- createStyle(fontSize = 10, halign = "center",
                        border = "TopBottomLeftRight")
sty_winsor <- createStyle(fontSize = 10, numFmt = "0.000000000",
                          halign = "right", border = "TopBottomLeftRight",
                          fgFill = "#E3F2FD")
sty_section <- createStyle(fontSize = 11, textDecoration = "bold",
                           fgFill = "#D5F5E3", border = "TopBottomLeftRight")
sty_note <- createStyle(fontSize = 9, fontColour = "#666666",
                        halign = "left", wrapText = TRUE)

# --- Hoja unica ---
sheet <- "AlgoritmoA"
addWorksheet(wb, sheet)

pcol_start <- 2
pcol_end <- 1 + p
p_range <- paste0(col_letter(pcol_start), "4:", col_letter(pcol_end), "4")

row <- 1

# Titulo
combo_label <- paste0("Algoritmo A (ISO 13528 Anexo C) - ",
                       toupper(sel_pollutant), " / ", sel_level)
writeData(wb, sheet, combo_label, startRow = row, startCol = 1)
mergeCells(wb, sheet, cols = 1:(pcol_end + 2), rows = row)
addStyle(wb, sheet, sty_title, rows = row, cols = 1:(pcol_end + 2), gridExpand = TRUE)
row <- 3

# IDs participantes
writeData(wb, sheet, "Participante", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
for (j in seq_len(p)) {
  writeData(wb, sheet, sub$participant_id[j], startRow = row, startCol = 1 + j)
}
addStyle(wb, sheet, sty_header, rows = row, cols = pcol_start:pcol_end, gridExpand = TRUE)
row <- 4

# Valores xi (EDITABLES - amarillo)
writeData(wb, sheet, "Valor xi", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
for (j in seq_len(p)) {
  writeData(wb, sheet, sub$mean_value[j], startRow = row, startCol = 1 + j)
}
addStyle(wb, sheet, sty_input, rows = row, cols = pcol_start:pcol_end, gridExpand = TRUE)
data_row <- row
row <- 6

# n y tolerancia
writeData(wb, sheet, "n", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeFormula(wb, sheet, paste0("COUNTA(", p_range, ")"), startRow = row, startCol = 2)
addStyle(wb, sheet, sty_int, rows = row, cols = 2)
row <- 7

writeData(wb, sheet, "Tolerancia", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeData(wb, sheet, 1e-06, startRow = row, startCol = 2)
addStyle(wb, sheet, createStyle(numFmt = "0.000000", halign = "right",
         border = "TopBottomLeftRight", fgFill = "#FFF9C4"), rows = row, cols = 2)
tol_cell <- paste0("B", row)
row <- 9

# VALORES INICIALES
writeData(wb, sheet, "VALORES INICIALES (iteracion 0)", startRow = row, startCol = 1)
mergeCells(wb, sheet, cols = 1:(pcol_end + 2), rows = row)
addStyle(wb, sheet, sty_section, rows = row, cols = 1:(pcol_end + 2), gridExpand = TRUE)
row <- 10

# x*_0
writeData(wb, sheet, "x*_0 (mediana)", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeFormula(wb, sheet, paste0("MEDIAN(", p_range, ")"), startRow = row, startCol = 2)
addStyle(wb, sheet, sty_formula, rows = row, cols = 2)
x0_cell <- paste0("B", row)
writeData(wb, sheet, "= MEDIANA(valores)", startRow = row, startCol = pcol_end + 2)
addStyle(wb, sheet, sty_note, rows = row, cols = pcol_end + 2)
row <- 11

# |xi - mediana|
writeData(wb, sheet, "|xi - mediana|", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
for (j in seq_len(p)) {
  writeFormula(wb, sheet,
               paste0("ABS(", col_letter(1 + j), data_row, "-", x0_cell, ")"),
               startRow = row, startCol = 1 + j)
}
addStyle(wb, sheet, sty_formula, rows = row, cols = pcol_start:pcol_end, gridExpand = TRUE)
abs_range <- paste0(col_letter(pcol_start), row, ":", col_letter(pcol_end), row)
row <- 12

# s*_0
writeData(wb, sheet, "s*_0 (MADe)", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeFormula(wb, sheet, paste0("1.483*MEDIAN(", abs_range, ")"),
             startRow = row, startCol = 2)
addStyle(wb, sheet, sty_formula, rows = row, cols = 2)
s0_cell <- paste0("B", row)
writeData(wb, sheet, "= 1.483 * MEDIANA(|xi - mediana|)",
          startRow = row, startCol = pcol_end + 2)
addStyle(wb, sheet, sty_note, rows = row, cols = pcol_end + 2)
row <- 14

# ITERACIONES
fixed_before <- 6
fixed_after <- 6
total_cols <- fixed_before + p + fixed_after

writeData(wb, sheet, "ITERACIONES (winsorizacion ISO 13528 Anexo C)",
          startRow = row, startCol = 1)
mergeCells(wb, sheet, cols = 1:total_cols, rows = row)
addStyle(wb, sheet, sty_section, rows = row, cols = 1:total_cols, gridExpand = TRUE)
row <- 15

# Headers de iteraciones
col_iter   <- 1; col_xprev  <- 2; col_sprev  <- 3
col_delta  <- 4; col_lower  <- 5; col_upper  <- 6
col_w_start <- 7; col_w_end <- 6 + p
col_xnew <- col_w_end + 1; col_snew <- col_w_end + 2
col_dx <- col_w_end + 3; col_ds <- col_w_end + 4
col_dmax <- col_w_end + 5; col_conv <- col_w_end + 6

headers <- c("Iter", "x*_prev", "s*_prev", "delta", "lim_inf", "lim_sup",
             paste0("w_", sub$participant_id),
             "x*_new", "s*_new", "delta_x", "delta_s", "delta_max", "Converge?")
for (h in seq_along(headers)) {
  writeData(wb, sheet, headers[h], startRow = row, startCol = h)
}
addStyle(wb, sheet, sty_header, rows = row, cols = 1:total_cols, gridExpand = TRUE)
header_row <- row
row <- 16

# 10 filas de iteraciones
iter_start <- row
for (it in 1:MAX_ITER) {
  r <- row
  writeData(wb, sheet, it, startRow = r, startCol = col_iter)

  if (it == 1) {
    writeFormula(wb, sheet, x0_cell, startRow = r, startCol = col_xprev)
    writeFormula(wb, sheet, s0_cell, startRow = r, startCol = col_sprev)
  } else {
    writeFormula(wb, sheet, paste0(col_letter(col_xnew), r - 1),
                 startRow = r, startCol = col_xprev)
    writeFormula(wb, sheet, paste0(col_letter(col_snew), r - 1),
                 startRow = r, startCol = col_sprev)
  }

  xp <- paste0(col_letter(col_xprev), r)
  sp <- paste0(col_letter(col_sprev), r)
  dl <- paste0(col_letter(col_delta), r)

  writeFormula(wb, sheet, paste0("1.5*", sp), startRow = r, startCol = col_delta)
  writeFormula(wb, sheet, paste0(xp, "-", dl), startRow = r, startCol = col_lower)
  writeFormula(wb, sheet, paste0(xp, "+", dl), startRow = r, startCol = col_upper)

  lo <- paste0("$", col_letter(col_lower), "$", r)
  hi <- paste0("$", col_letter(col_upper), "$", r)

  for (j in seq_len(p)) {
    v <- paste0(col_letter(1 + j), "$", data_row)
    writeFormula(wb, sheet, paste0("MAX(MIN(", v, ",", hi, "),", lo, ")"),
                 startRow = r, startCol = col_w_start + j - 1)
  }

  wr <- paste0(col_letter(col_w_start), r, ":", col_letter(col_w_end), r)
  xn <- paste0(col_letter(col_xnew), r)
  sn <- paste0(col_letter(col_snew), r)
  dxr <- paste0(col_letter(col_dx), r)
  dsr <- paste0(col_letter(col_ds), r)
  dmr <- paste0(col_letter(col_dmax), r)

  writeFormula(wb, sheet, paste0("AVERAGE(", wr, ")"), startRow = r, startCol = col_xnew)
  writeFormula(wb, sheet, paste0("1.134*STDEV(", wr, ")"), startRow = r, startCol = col_snew)
  writeFormula(wb, sheet, paste0("ABS(", xn, "-", xp, ")"), startRow = r, startCol = col_dx)
  writeFormula(wb, sheet, paste0("ABS(", sn, "-", sp, ")"), startRow = r, startCol = col_ds)
  writeFormula(wb, sheet, paste0("MAX(", dxr, ",", dsr, ")"), startRow = r, startCol = col_dmax)
  writeFormula(wb, sheet, paste0("IF(", dmr, "<", tol_cell, ",\"SI\",\"NO\")"),
               startRow = r, startCol = col_conv)

  row <- row + 1
}
iter_end <- row - 1

# Estilos en bloque
addStyle(wb, sheet, sty_int, rows = iter_start:iter_end, cols = col_iter, gridExpand = TRUE)
addStyle(wb, sheet, sty_formula, rows = iter_start:iter_end,
         cols = c(col_xprev, col_sprev, col_delta, col_lower, col_upper,
                  col_xnew, col_snew, col_dx, col_ds, col_dmax),
         gridExpand = TRUE)
addStyle(wb, sheet, sty_winsor, rows = iter_start:iter_end,
         cols = col_w_start:col_w_end, gridExpand = TRUE)
addStyle(wb, sheet, sty_bool, rows = iter_start:iter_end, cols = col_conv,
         gridExpand = TRUE)

# RESULTADO FINAL
row <- row + 1
writeData(wb, sheet, "RESULTADO FINAL", startRow = row, startCol = 1)
mergeCells(wb, sheet, cols = 1:total_cols, rows = row)
addStyle(wb, sheet, sty_section, rows = row, cols = 1:total_cols, gridExpand = TRUE)
row <- row + 1

last_iter <- iter_end

writeData(wb, sheet, "x* (valor asignado)", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeFormula(wb, sheet, paste0(col_letter(col_xnew), last_iter),
             startRow = row, startCol = 2)
addStyle(wb, sheet, sty_formula, rows = row, cols = 2)
row <- row + 1

writeData(wb, sheet, "s* (desviacion robusta)", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeFormula(wb, sheet, paste0(col_letter(col_snew), last_iter),
             startRow = row, startCol = 2)
addStyle(wb, sheet, sty_formula, rows = row, cols = 2)
sf <- paste0("B", row)
row <- row + 1

writeData(wb, sheet, "u(x_pt) = 1.25*s*/sqrt(n)", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeFormula(wb, sheet, paste0("1.25*", sf, "/SQRT(B6)"), startRow = row, startCol = 2)
addStyle(wb, sheet, sty_formula, rows = row, cols = 2)
row <- row + 1

writeData(wb, sheet, "Convergencia", startRow = row, startCol = 1)
addStyle(wb, sheet, sty_label, rows = row, cols = 1)
writeFormula(wb, sheet, paste0(col_letter(col_conv), last_iter),
             startRow = row, startCol = 2)
addStyle(wb, sheet, sty_bool, rows = row, cols = 2)
row <- row + 2

# Nota de uso
writeData(wb, sheet, paste0(
  "INSTRUCCIONES: Las celdas AMARILLAS (fila 4) son editables. ",
  "Cambie cualquier valor y todas las formulas se recalculan. ",
  "Para otro analito/nivel: duplique esta hoja y pegue nuevos datos en fila 4."
), startRow = row, startCol = 1)
mergeCells(wb, sheet, cols = 1:total_cols, rows = row)
addStyle(wb, sheet, sty_note, rows = row, cols = 1:total_cols, gridExpand = TRUE)

# Anchos
setColWidths(wb, sheet, cols = 1, widths = 24)
setColWidths(wb, sheet, cols = 2:total_cols, widths = 16)

# Guardar
output_file <- "validation/AlgoritmoA_VIVO.xlsx"
saveWorkbook(wb, output_file, overwrite = TRUE)
cat("Guardado en:", output_file, "\n")
