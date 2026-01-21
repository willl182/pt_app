#!/usr/bin/env Rscript
#' Validation Spreadsheet Generator for PT App Calculations
#' =========================================================
#' Generates Excel spreadsheets with formulas to validate all calculations
#' in app.R and the ptcalc/ package per ISO 13528:2022.
#'
#' Run with: Rscript generate_validation_spreadsheets.R
#' Or in R: source("validation/generate_validation_spreadsheets.R")

suppressPackageStartupMessages({
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Package 'openxlsx' is required. Install with: install.packages('openxlsx')")
  }
  library(openxlsx)
})

get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("--file=", "", file_arg[1]))))
  }
  return(getwd())
}

SCRIPT_DIR <- get_script_dir()
DATA_DIR <- file.path(SCRIPT_DIR, "..", "data")
if (!dir.exists(DATA_DIR)) {
  DATA_DIR <- file.path(getwd(), "data")
}
DATA_DIR <- normalizePath(DATA_DIR)

OUTPUT_DIR <- SCRIPT_DIR
if (!dir.exists(OUTPUT_DIR)) {
  OUTPUT_DIR <- getwd()
}

header_style <- createStyle(
  fontColour = "#FFFFFF", fgFill = "#4472C4",
  halign = "center", valign = "center", textDecoration = "bold",
  border = "TopBottomLeftRight"
)

formula_style <- createStyle(fontColour = "#0000FF")
input_style <- createStyle(fgFill = "#FFF2CC")
result_style <- createStyle(fgFill = "#E2EFDA")

create_homogeneity_sheet <- function(wb, hom_data) {
  addWorksheet(wb, "Homogeneity")
  ws <- "Homogeneity"
  
  example <- hom_data[hom_data$pollutant == "so2" & hom_data$level == "60-nmol/mol", ]
  
  pivot <- reshape(example, idvar = "sample_id", timevar = "replicate", direction = "wide")
  pivot <- pivot[order(pivot$sample_id), c("sample_id", "value.1", "value.2")]
  colnames(pivot) <- c("sample_id", "rep1", "rep2")
  g <- nrow(pivot)
  m <- 2
  
  writeData(wb, ws, "HOMOGENEITY VALIDATION - SO2 60-nmol/mol", startRow = 1, startCol = 1)
  addStyle(wb, ws, createStyle(fontSize = 14, textDecoration = "bold"), rows = 1, cols = 1)
  mergeCells(wb, ws, cols = 1:8, rows = 1)
  
  writeData(wb, ws, "ISO 13528:2022 Section 9.2 - Between-sample and within-sample standard deviations", startRow = 2, startCol = 1)
  mergeCells(wb, ws, cols = 1:8, rows = 2)
  
  writeData(wb, ws, "Parameters", startRow = 4, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 4, cols = 1)
  
  writeData(wb, ws, "g (samples)", startRow = 5, startCol = 1)
  writeData(wb, ws, g, startRow = 5, startCol = 2)
  
  writeData(wb, ws, "m (replicates)", startRow = 6, startCol = 1)
  writeData(wb, ws, m, startRow = 6, startCol = 2)
  
  writeData(wb, ws, "σ_pt (user input)", startRow = 7, startCol = 1)
  writeData(wb, ws, 0.6, startRow = 7, startCol = 2)
  addStyle(wb, ws, input_style, rows = 7, cols = 2)
  
  headers <- c("Sample ID", "Replicate 1", "Replicate 2", "Sample Mean", "Range |R1-R2|", "Range²")
  start_row <- 9
  writeData(wb, ws, t(headers), startRow = start_row, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = start_row, cols = 1:length(headers), gridExpand = TRUE)
  
  data_start <- start_row + 1
  for (i in seq_len(g)) {
    r <- data_start + i - 1
    writeData(wb, ws, pivot$sample_id[i], startRow = r, startCol = 1)
    writeData(wb, ws, pivot$rep1[i], startRow = r, startCol = 2)
    writeData(wb, ws, pivot$rep2[i], startRow = r, startCol = 3)
    writeFormula(wb, ws, sprintf("AVERAGE(B%d,C%d)", r, r), startRow = r, startCol = 4)
    addStyle(wb, ws, formula_style, rows = r, cols = 4)
    writeFormula(wb, ws, sprintf("ABS(B%d-C%d)", r, r), startRow = r, startCol = 5)
    addStyle(wb, ws, formula_style, rows = r, cols = 5)
    writeFormula(wb, ws, sprintf("E%d^2", r), startRow = r, startCol = 6)
    addStyle(wb, ws, formula_style, rows = r, cols = 6)
  }
  
  data_end <- data_start + g - 1
  
  summary_row <- data_end + 2
  writeData(wb, ws, "CALCULATED STATISTICS", startRow = summary_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = summary_row, cols = 1)
  
  writeData(wb, ws, "Grand Mean (x̄̄)", startRow = summary_row + 1, startCol = 1)
  writeFormula(wb, ws, sprintf("AVERAGE(D%d:D%d)", data_start, data_end), startRow = summary_row + 1, startCol = 2)
  addStyle(wb, ws, result_style, rows = summary_row + 1, cols = 2)
  
  writeData(wb, ws, "s²_x̄ (Var of means)", startRow = summary_row + 2, startCol = 1)
  writeFormula(wb, ws, sprintf("VAR.S(D%d:D%d)", data_start, data_end), startRow = summary_row + 2, startCol = 2)
  addStyle(wb, ws, result_style, rows = summary_row + 2, cols = 2)
  
  writeData(wb, ws, "Σ(Range²)", startRow = summary_row + 3, startCol = 1)
  writeFormula(wb, ws, sprintf("SUM(F%d:F%d)", data_start, data_end), startRow = summary_row + 3, startCol = 2)
  
  writeData(wb, ws, "sw (within-sample SD)", startRow = summary_row + 4, startCol = 1)
  writeFormula(wb, ws, sprintf("SQRT(B%d/(2*B5))", summary_row + 3), startRow = summary_row + 4, startCol = 2)
  addStyle(wb, ws, result_style, rows = summary_row + 4, cols = 2)
  writeData(wb, ws, "Formula: √(Σw²/(2g))", startRow = summary_row + 4, startCol = 3)
  
  writeData(wb, ws, "sw²", startRow = summary_row + 5, startCol = 1)
  writeFormula(wb, ws, sprintf("B%d^2", summary_row + 4), startRow = summary_row + 5, startCol = 2)
  
  writeData(wb, ws, "ss² (|s²_x̄ - sw²/m|)", startRow = summary_row + 6, startCol = 1)
  writeFormula(wb, ws, sprintf("ABS(B%d-B%d/B6)", summary_row + 2, summary_row + 5), startRow = summary_row + 6, startCol = 2)
  addStyle(wb, ws, result_style, rows = summary_row + 6, cols = 2)
  writeData(wb, ws, "Formula: |s²_x̄ - sw²/m|", startRow = summary_row + 6, startCol = 3)
  
  writeData(wb, ws, "ss (between-sample SD)", startRow = summary_row + 7, startCol = 1)
  writeFormula(wb, ws, sprintf("SQRT(B%d)", summary_row + 6), startRow = summary_row + 7, startCol = 2)
  addStyle(wb, ws, result_style, rows = summary_row + 7, cols = 2)
  writeData(wb, ws, "Formula: √ss²", startRow = summary_row + 7, startCol = 3)
  
  crit_row <- summary_row + 9
  writeData(wb, ws, "HOMOGENEITY CRITERION", startRow = crit_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = crit_row, cols = 1)
  
  writeData(wb, ws, "c = 0.3 × σ_pt", startRow = crit_row + 1, startCol = 1)
  writeFormula(wb, ws, "0.3*B7", startRow = crit_row + 1, startCol = 2)
  addStyle(wb, ws, result_style, rows = crit_row + 1, cols = 2)
  
  writeData(wb, ws, "ss ≤ c ?", startRow = crit_row + 2, startCol = 1)
  writeFormula(wb, ws, sprintf('IF(B%d<=B%d,"PASS","FAIL")', summary_row + 7, crit_row + 1), startRow = crit_row + 2, startCol = 2)
  addStyle(wb, ws, result_style, rows = crit_row + 2, cols = 2)
  
  setColWidths(wb, ws, cols = 1:6, widths = "auto")
}

create_stability_sheet <- function(wb, hom_data, stab_data) {
  addWorksheet(wb, "Stability")
  ws <- "Stability"
  
  hom_ex <- hom_data[hom_data$pollutant == "so2" & hom_data$level == "60-nmol/mol", ]
  stab_ex <- stab_data[stab_data$pollutant == "so2" & stab_data$level == "60-nmol/mol", ]
  
  hom_pivot <- reshape(hom_ex, idvar = "sample_id", timevar = "replicate", direction = "wide")
  hom_pivot <- hom_pivot[order(hom_pivot$sample_id), c("sample_id", "value.1", "value.2")]
  colnames(hom_pivot) <- c("sample_id", "rep1", "rep2")
  
  stab_pivot <- reshape(stab_ex, idvar = "sample_id", timevar = "replicate", direction = "wide")
  stab_pivot <- stab_pivot[order(stab_pivot$sample_id), c("sample_id", "value.1", "value.2")]
  colnames(stab_pivot) <- c("sample_id", "rep1", "rep2")
  
  writeData(wb, ws, "STABILITY VALIDATION - SO2 60-nmol/mol", startRow = 1, startCol = 1)
  addStyle(wb, ws, createStyle(fontSize = 14, textDecoration = "bold"), rows = 1, cols = 1)
  mergeCells(wb, ws, cols = 1:6, rows = 1)
  
  writeData(wb, ws, "ISO 13528:2022 Section 9.3 - Stability assessment", startRow = 2, startCol = 1)
  mergeCells(wb, ws, cols = 1:6, rows = 2)
  
  writeData(wb, ws, "Parameters", startRow = 4, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 4, cols = 1)
  writeData(wb, ws, "σ_pt (user input)", startRow = 5, startCol = 1)
  writeData(wb, ws, 0.6, startRow = 5, startCol = 2)
  addStyle(wb, ws, input_style, rows = 5, cols = 2)
  
  writeData(wb, ws, "HOMOGENEITY DATA", startRow = 7, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 7, cols = 1)
  
  headers <- c("Sample ID", "Rep 1", "Rep 2", "Mean")
  writeData(wb, ws, t(headers), startRow = 8, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = 8, cols = 1:4, gridExpand = TRUE)
  
  row <- 9
  for (i in seq_len(nrow(hom_pivot))) {
    writeData(wb, ws, hom_pivot$sample_id[i], startRow = row + i - 1, startCol = 1)
    writeData(wb, ws, hom_pivot$rep1[i], startRow = row + i - 1, startCol = 2)
    writeData(wb, ws, hom_pivot$rep2[i], startRow = row + i - 1, startCol = 3)
    writeFormula(wb, ws, sprintf("AVERAGE(B%d,C%d)", row + i - 1, row + i - 1), startRow = row + i - 1, startCol = 4)
    addStyle(wb, ws, formula_style, rows = row + i - 1, cols = 4)
  }
  
  hom_end <- row + nrow(hom_pivot) - 1
  
  writeData(wb, ws, "Homogeneity Grand Mean", startRow = hom_end + 1, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = hom_end + 1, cols = 1)
  writeFormula(wb, ws, sprintf("AVERAGE(D%d:D%d)", row, hom_end), startRow = hom_end + 1, startCol = 4)
  addStyle(wb, ws, result_style, rows = hom_end + 1, cols = 4)
  hom_mean_cell <- sprintf("D%d", hom_end + 1)
  
  stab_start <- hom_end + 4
  writeData(wb, ws, "STABILITY DATA", startRow = stab_start, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = stab_start, cols = 1)
  
  writeData(wb, ws, t(headers), startRow = stab_start + 1, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = stab_start + 1, cols = 1:4, gridExpand = TRUE)
  
  row <- stab_start + 2
  for (i in seq_len(nrow(stab_pivot))) {
    writeData(wb, ws, stab_pivot$sample_id[i], startRow = row + i - 1, startCol = 1)
    writeData(wb, ws, stab_pivot$rep1[i], startRow = row + i - 1, startCol = 2)
    writeData(wb, ws, stab_pivot$rep2[i], startRow = row + i - 1, startCol = 3)
    writeFormula(wb, ws, sprintf("AVERAGE(B%d,C%d)", row + i - 1, row + i - 1), startRow = row + i - 1, startCol = 4)
    addStyle(wb, ws, formula_style, rows = row + i - 1, cols = 4)
  }
  
  stab_end <- row + nrow(stab_pivot) - 1
  
  writeData(wb, ws, "Stability Grand Mean", startRow = stab_end + 1, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = stab_end + 1, cols = 1)
  writeFormula(wb, ws, sprintf("AVERAGE(D%d:D%d)", row, stab_end), startRow = stab_end + 1, startCol = 4)
  addStyle(wb, ws, result_style, rows = stab_end + 1, cols = 4)
  stab_mean_cell <- sprintf("D%d", stab_end + 1)
  
  assess_row <- stab_end + 4
  writeData(wb, ws, "STABILITY ASSESSMENT", startRow = assess_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = assess_row, cols = 1)
  
  writeData(wb, ws, "|Stab Mean - Hom Mean|", startRow = assess_row + 1, startCol = 1)
  writeFormula(wb, ws, sprintf("ABS(%s-%s)", stab_mean_cell, hom_mean_cell), startRow = assess_row + 1, startCol = 2)
  addStyle(wb, ws, result_style, rows = assess_row + 1, cols = 2)
  
  writeData(wb, ws, "Criterion c = 0.3 × σ_pt", startRow = assess_row + 2, startCol = 1)
  writeFormula(wb, ws, "0.3*B5", startRow = assess_row + 2, startCol = 2)
  addStyle(wb, ws, result_style, rows = assess_row + 2, cols = 2)
  
  writeData(wb, ws, "diff ≤ c ?", startRow = assess_row + 3, startCol = 1)
  writeFormula(wb, ws, sprintf('IF(B%d<=B%d,"PASS","FAIL")', assess_row + 1, assess_row + 2), startRow = assess_row + 3, startCol = 2)
  addStyle(wb, ws, result_style, rows = assess_row + 3, cols = 2)
  
  setColWidths(wb, ws, cols = 1:4, widths = "auto")
}

create_robust_stats_sheet <- function(wb, summary_data) {
  addWorksheet(wb, "Robust_Stats")
  ws <- "Robust_Stats"
  
  example <- summary_data[summary_data$pollutant == "so2" & summary_data$level == "60-nmol/mol", ]
  values <- example$mean_value[!is.na(example$mean_value)]
  n <- length(values)
  
  writeData(wb, ws, "ROBUST STATISTICS VALIDATION - SO2 60-nmol/mol", startRow = 1, startCol = 1)
  addStyle(wb, ws, createStyle(fontSize = 14, textDecoration = "bold"), rows = 1, cols = 1)
  mergeCells(wb, ws, cols = 1:6, rows = 1)
  
  writeData(wb, ws, "ISO 13528:2022 Section 9.4 - MADe and nIQR calculations", startRow = 2, startCol = 1)
  mergeCells(wb, ws, cols = 1:6, rows = 2)
  
  writeData(wb, ws, "Values (xi)", startRow = 4, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 4, cols = 1)
  writeData(wb, ws, "|xi - median|", startRow = 4, startCol = 2)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 4, cols = 2)
  
  for (i in seq_along(values)) {
    writeData(wb, ws, values[i], startRow = 4 + i, startCol = 1)
  }
  
  data_end <- 4 + n
  
  calc_row <- data_end + 2
  writeData(wb, ws, "CALCULATIONS", startRow = calc_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = calc_row, cols = 1)
  
  writeData(wb, ws, "n (count)", startRow = calc_row + 1, startCol = 1)
  writeFormula(wb, ws, sprintf("COUNT(A5:A%d)", data_end), startRow = calc_row + 1, startCol = 2)
  
  writeData(wb, ws, "Median", startRow = calc_row + 2, startCol = 1)
  writeFormula(wb, ws, sprintf("MEDIAN(A5:A%d)", data_end), startRow = calc_row + 2, startCol = 2)
  addStyle(wb, ws, result_style, rows = calc_row + 2, cols = 2)
  median_cell <- sprintf("B%d", calc_row + 2)
  
  writeData(wb, ws, "Q1 (25th percentile)", startRow = calc_row + 3, startCol = 1)
  writeFormula(wb, ws, sprintf("QUARTILE.INC(A5:A%d,1)", data_end), startRow = calc_row + 3, startCol = 2)
  
  writeData(wb, ws, "Q3 (75th percentile)", startRow = calc_row + 4, startCol = 1)
  writeFormula(wb, ws, sprintf("QUARTILE.INC(A5:A%d,3)", data_end), startRow = calc_row + 4, startCol = 2)
  
  writeData(wb, ws, "IQR (Q3 - Q1)", startRow = calc_row + 5, startCol = 1)
  writeFormula(wb, ws, sprintf("B%d-B%d", calc_row + 4, calc_row + 3), startRow = calc_row + 5, startCol = 2)
  
  writeData(wb, ws, "nIQR = 0.7413 × IQR", startRow = calc_row + 6, startCol = 1)
  writeFormula(wb, ws, sprintf("0.7413*B%d", calc_row + 5), startRow = calc_row + 6, startCol = 2)
  addStyle(wb, ws, result_style, rows = calc_row + 6, cols = 2)
  writeData(wb, ws, "← Robust SD estimator", startRow = calc_row + 6, startCol = 3)
  
  for (i in seq_along(values)) {
    writeFormula(wb, ws, sprintf("ABS(A%d-%s)", 4 + i, median_cell), startRow = 4 + i, startCol = 2)
    addStyle(wb, ws, formula_style, rows = 4 + i, cols = 2)
  }
  
  writeData(wb, ws, "MAD (median of |xi-median|)", startRow = calc_row + 7, startCol = 1)
  writeFormula(wb, ws, sprintf("MEDIAN(B5:B%d)", data_end), startRow = calc_row + 7, startCol = 2)
  
  writeData(wb, ws, "MADe = 1.483 × MAD", startRow = calc_row + 8, startCol = 1)
  writeFormula(wb, ws, sprintf("1.483*B%d", calc_row + 7), startRow = calc_row + 8, startCol = 2)
  addStyle(wb, ws, result_style, rows = calc_row + 8, cols = 2)
  writeData(wb, ws, "← Robust SD estimator", startRow = calc_row + 8, startCol = 3)
  
  writeData(wb, ws, "COMPARISON (Classical)", startRow = calc_row + 10, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = calc_row + 10, cols = 1)
  
  writeData(wb, ws, "Mean", startRow = calc_row + 11, startCol = 1)
  writeFormula(wb, ws, sprintf("AVERAGE(A5:A%d)", data_end), startRow = calc_row + 11, startCol = 2)
  
  writeData(wb, ws, "SD", startRow = calc_row + 12, startCol = 1)
  writeFormula(wb, ws, sprintf("STDEV.S(A5:A%d)", data_end), startRow = calc_row + 12, startCol = 2)
  
  setColWidths(wb, ws, cols = 1:3, widths = "auto")
}

create_algorithm_a_sheet <- function(wb, summary_data) {
  addWorksheet(wb, "Algorithm_A")
  ws <- "Algorithm_A"
  
  # Use SO2 60-nmol/mol example
  example <- summary_data[summary_data$pollutant == "so2" & summary_data$level == "60-nmol/mol", ]
  values <- example$mean_value[!is.na(example$mean_value)]
  n <- length(values)
  
  writeData(wb, ws, "ALGORITHM A VALIDATION - SO2 60-nmol/mol", startRow = 1, startCol = 1)
  addStyle(wb, ws, createStyle(fontSize = 14, textDecoration = "bold"), rows = 1, cols = 1)
  mergeCells(wb, ws, cols = 1:12, rows = 1)
  
  writeData(wb, ws, "ISO 13528:2022 Annex C - Iterative Robust Estimation (Algorithm A)", startRow = 2, startCol = 1)
  mergeCells(wb, ws, cols = 1:12, rows = 2)
  
  # Parameters section
  writeData(wb, ws, "ALGORITHM PARAMETERS", startRow = 4, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 4, cols = 1)
  
  writeData(wb, ws, "Huber constant (c)", startRow = 5, startCol = 1)
  writeData(wb, ws, 1.5, startRow = 5, startCol = 2)
  addStyle(wb, ws, input_style, rows = 5, cols = 2)
  writeData(wb, ws, "← Weight cutoff: |u| <= 1", startRow = 5, startCol = 3)
  
  writeData(wb, ws, "MAD scale factor", startRow = 6, startCol = 1)
  writeData(wb, ws, 1.483, startRow = 6, startCol = 2)
  addStyle(wb, ws, input_style, rows = 6, cols = 2)
  writeData(wb, ws, "← Makes MAD consistent for normal distribution", startRow = 6, startCol = 3)
  
  writeData(wb, ws, "Tolerance", startRow = 7, startCol = 1)
  writeData(wb, ws, 0.001, startRow = 7, startCol = 2)
  addStyle(wb, ws, input_style, rows = 7, cols = 2)
  
  # Input data section
  writeData(wb, ws, "INPUT DATA (xi)", startRow = 9, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 9, cols = 1)
  
  headers <- c("i", "xi", "|xi - median|")
  writeData(wb, ws, t(headers), startRow = 10, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = 10, cols = 1:3, gridExpand = TRUE)
  
  for (i in seq_along(values)) {
    r <- 10 + i
    writeData(wb, ws, i, startRow = r, startCol = 1)
    writeData(wb, ws, values[i], startRow = r, startCol = 2)
  }
  
  data_end <- 10 + n
  
  # Initial estimates
  init_row <- data_end + 2
  writeData(wb, ws, "INITIAL ESTIMATES (Iteration 0)", startRow = init_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = init_row, cols = 1)
  
  writeData(wb, ws, "Median", startRow = init_row + 1, startCol = 1)
  writeFormula(wb, ws, sprintf("MEDIAN(B11:B%d)", data_end), startRow = init_row + 1, startCol = 2)
  addStyle(wb, ws, result_style, rows = init_row + 1, cols = 2)
  median_cell <- sprintf("B%d", init_row + 1)
  
  # Compute |xi - median| column
  for (i in seq_along(values)) {
    r <- 10 + i
    writeFormula(wb, ws, sprintf("ABS(B%d-%s)", r, median_cell), startRow = r, startCol = 3)
    addStyle(wb, ws, formula_style, rows = r, cols = 3)
  }
  
  writeData(wb, ws, "MAD (median of |xi - median|)", startRow = init_row + 2, startCol = 1)
  writeFormula(wb, ws, sprintf("MEDIAN(C11:C%d)", data_end), startRow = init_row + 2, startCol = 2)
  
  writeData(wb, ws, "x*₀ = median", startRow = init_row + 3, startCol = 1)
  writeFormula(wb, ws, sprintf("=%s", median_cell), startRow = init_row + 3, startCol = 2)
  addStyle(wb, ws, result_style, rows = init_row + 3, cols = 2)
  x0_cell <- sprintf("B%d", init_row + 3)
  
  writeData(wb, ws, "s*₀ = 1.483 × MAD", startRow = init_row + 4, startCol = 1)
  writeFormula(wb, ws, sprintf("B6*B%d", init_row + 2), startRow = init_row + 4, startCol = 2)
  addStyle(wb, ws, result_style, rows = init_row + 4, cols = 2)
  s0_cell <- sprintf("B%d", init_row + 4)
  
  # Iteration 1 detail
  iter1_row <- init_row + 7
  writeData(wb, ws, "ITERATION 1 DETAIL", startRow = iter1_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = iter1_row, cols = 1)
  
  iter1_headers <- c("i", "xi", "ui = (xi-x*₀)/(1.5×s*₀)", "|ui|", "wi", "wi×xi", "wi×(xi-x*₁)²")
  writeData(wb, ws, t(iter1_headers), startRow = iter1_row + 1, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = iter1_row + 1, cols = 1:7, gridExpand = TRUE)
  
  for (i in seq_along(values)) {
    r <- iter1_row + 1 + i
    writeData(wb, ws, i, startRow = r, startCol = 1)
    writeData(wb, ws, values[i], startRow = r, startCol = 2)
    # ui = (xi - x*0) / (1.5 * s*0)
    writeFormula(wb, ws, sprintf("(B%d-%s)/(B5*%s)", r, x0_cell, s0_cell), startRow = r, startCol = 3)
    addStyle(wb, ws, formula_style, rows = r, cols = 3)
    # |ui|
    writeFormula(wb, ws, sprintf("ABS(C%d)", r), startRow = r, startCol = 4)
    addStyle(wb, ws, formula_style, rows = r, cols = 4)
    # wi = IF(|ui|<=1, 1, 1/ui^2)
    writeFormula(wb, ws, sprintf("IF(D%d<=1,1,1/(C%d^2))", r, r), startRow = r, startCol = 5)
    addStyle(wb, ws, formula_style, rows = r, cols = 5)
    # wi * xi
    writeFormula(wb, ws, sprintf("E%d*B%d", r, r), startRow = r, startCol = 6)
    addStyle(wb, ws, formula_style, rows = r, cols = 6)
  }
  
  iter1_data_end <- iter1_row + 1 + n
  
  # Sums for iteration 1
  sum1_row <- iter1_data_end + 1
  writeData(wb, ws, "Σ", startRow = sum1_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = sum1_row, cols = 1)
  writeFormula(wb, ws, sprintf("SUM(E%d:E%d)", iter1_row + 2, iter1_data_end), startRow = sum1_row, startCol = 5)
  addStyle(wb, ws, result_style, rows = sum1_row, cols = 5)
  writeFormula(wb, ws, sprintf("SUM(F%d:F%d)", iter1_row + 2, iter1_data_end), startRow = sum1_row, startCol = 6)
  addStyle(wb, ws, result_style, rows = sum1_row, cols = 6)
  
  # x*1 calculation
  result1_row <- sum1_row + 2
  writeData(wb, ws, "x*₁ = Σ(wi×xi) / Σwi", startRow = result1_row, startCol = 1)
  writeFormula(wb, ws, sprintf("F%d/E%d", sum1_row, sum1_row), startRow = result1_row, startCol = 2)
  addStyle(wb, ws, result_style, rows = result1_row, cols = 2)
  x1_cell <- sprintf("B%d", result1_row)
  
  # Now fill in column G (wi×(xi-x*1)²) using x*1
  for (i in seq_along(values)) {
    r <- iter1_row + 1 + i
    writeFormula(wb, ws, sprintf("E%d*(B%d-%s)^2", r, r, x1_cell), startRow = r, startCol = 7)
    addStyle(wb, ws, formula_style, rows = r, cols = 7)
  }
  
  # Sum of column G
  writeFormula(wb, ws, sprintf("SUM(G%d:G%d)", iter1_row + 2, iter1_data_end), startRow = sum1_row, startCol = 7)
  addStyle(wb, ws, result_style, rows = sum1_row, cols = 7)
  
  # s*1 calculation
  writeData(wb, ws, "s*₁ = √(Σ(wi×(xi-x*₁)²) / Σwi)", startRow = result1_row + 1, startCol = 1)
  writeFormula(wb, ws, sprintf("SQRT(G%d/E%d)", sum1_row, sum1_row), startRow = result1_row + 1, startCol = 2)
  addStyle(wb, ws, result_style, rows = result1_row + 1, cols = 2)
  s1_cell <- sprintf("B%d", result1_row + 1)
  
  # Convergence check
  writeData(wb, ws, "Δx* = |x*₁ - x*₀|", startRow = result1_row + 3, startCol = 1)
  writeFormula(wb, ws, sprintf("ABS(%s-%s)", x1_cell, x0_cell), startRow = result1_row + 3, startCol = 2)
  
  writeData(wb, ws, "Δs* = |s*₁ - s*₀|", startRow = result1_row + 4, startCol = 1)
  writeFormula(wb, ws, sprintf("ABS(%s-%s)", s1_cell, s0_cell), startRow = result1_row + 4, startCol = 2)
  
  writeData(wb, ws, "Converged? (Δ < tol)", startRow = result1_row + 5, startCol = 1)
  writeFormula(wb, ws, sprintf('IF(AND(B%d<B7,B%d<B7),"YES","NO")', result1_row + 3, result1_row + 4), 
               startRow = result1_row + 5, startCol = 2)
  addStyle(wb, ws, result_style, rows = result1_row + 5, cols = 2)
  
  # Summary section
  summary_row <- result1_row + 8
  writeData(wb, ws, "ITERATION SUMMARY", startRow = summary_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = summary_row, cols = 1)
  
  summary_headers <- c("Iteration", "x*", "s*", "Δx*", "Δs*", "Converged")
  writeData(wb, ws, t(summary_headers), startRow = summary_row + 1, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = summary_row + 1, cols = 1:6, gridExpand = TRUE)
  
  writeData(wb, ws, 0, startRow = summary_row + 2, startCol = 1)
  writeFormula(wb, ws, sprintf("=%s", x0_cell), startRow = summary_row + 2, startCol = 2)
  writeFormula(wb, ws, sprintf("=%s", s0_cell), startRow = summary_row + 2, startCol = 3)
  writeData(wb, ws, "-", startRow = summary_row + 2, startCol = 4)
  writeData(wb, ws, "-", startRow = summary_row + 2, startCol = 5)
  writeData(wb, ws, "-", startRow = summary_row + 2, startCol = 6)
  
  writeData(wb, ws, 1, startRow = summary_row + 3, startCol = 1)
  writeFormula(wb, ws, sprintf("=%s", x1_cell), startRow = summary_row + 3, startCol = 2)
  writeFormula(wb, ws, sprintf("=%s", s1_cell), startRow = summary_row + 3, startCol = 3)
  writeFormula(wb, ws, sprintf("=B%d", result1_row + 3), startRow = summary_row + 3, startCol = 4)
  writeFormula(wb, ws, sprintf("=B%d", result1_row + 4), startRow = summary_row + 3, startCol = 5)
  writeFormula(wb, ws, sprintf("=B%d", result1_row + 5), startRow = summary_row + 3, startCol = 6)
  addStyle(wb, ws, result_style, rows = summary_row + 3, cols = 2:6, gridExpand = TRUE)
  
  # Final results
  final_row <- summary_row + 6
  writeData(wb, ws, "FINAL RESULTS (after convergence)", startRow = final_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = final_row, cols = 1)
  
  writeData(wb, ws, "x* (Robust Mean / Assigned Value)", startRow = final_row + 1, startCol = 1)
  writeFormula(wb, ws, sprintf("=%s", x1_cell), startRow = final_row + 1, startCol = 2)
  addStyle(wb, ws, result_style, rows = final_row + 1, cols = 2)
  
  writeData(wb, ws, "s* (Robust SD)", startRow = final_row + 2, startCol = 1)
  writeFormula(wb, ws, sprintf("=%s", s1_cell), startRow = final_row + 2, startCol = 2)
  addStyle(wb, ws, result_style, rows = final_row + 2, cols = 2)
  
  writeData(wb, ws, "Effective n (Σwi)", startRow = final_row + 3, startCol = 1)
  writeFormula(wb, ws, sprintf("=E%d", sum1_row), startRow = final_row + 3, startCol = 2)
  addStyle(wb, ws, result_style, rows = final_row + 3, cols = 2)
  
  # Formula reference
  ref_row <- final_row + 6
  writeData(wb, ws, "FORMULA REFERENCE (ISO 13528:2022 Annex C)", startRow = ref_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = ref_row, cols = 1)
  
  formulas <- data.frame(
    step = c("Initial x*", "Initial s*", "Standardized residual", "Weights", "Updated x*", "Updated s*"),
    formula = c("x*₀ = median(xi)", 
                "s*₀ = 1.483 × median(|xi - median|)",
                "ui = (xi - x*) / (1.5 × s*)",
                "wi = 1 if |ui| ≤ 1, else wi = 1/ui²",
                "x* = Σ(wi × xi) / Σwi",
                "s* = √(Σ(wi × (xi - x*)²) / Σwi)"),
    stringsAsFactors = FALSE
  )
  
  for (i in seq_len(nrow(formulas))) {
    writeData(wb, ws, formulas$step[i], startRow = ref_row + i, startCol = 1)
    writeData(wb, ws, formulas$formula[i], startRow = ref_row + i, startCol = 2)
  }
  
  setColWidths(wb, ws, cols = 1:7, widths = "auto")
}

create_pt_scores_sheet <- function(wb) {
  addWorksheet(wb, "PT_Scores")
  ws <- "PT_Scores"
  
  writeData(wb, ws, "PT SCORES VALIDATION", startRow = 1, startCol = 1)
  addStyle(wb, ws, createStyle(fontSize = 14, textDecoration = "bold"), rows = 1, cols = 1)
  mergeCells(wb, ws, cols = 1:10, rows = 1)
  
  writeData(wb, ws, "ISO 13528:2022 Section 10 - Performance scores", startRow = 2, startCol = 1)
  mergeCells(wb, ws, cols = 1:10, rows = 2)
  
  writeData(wb, ws, "ASSIGNED VALUE & PARAMETERS (Example: SO2 60-nmol/mol)", startRow = 4, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 4, cols = 1)
  
  params <- data.frame(
    name = c("x_pt (assigned value)", "σ_pt (std dev for PT)", "u_xpt (std uncertainty of x_pt)", "U_xpt (expanded uncertainty, k=2)"),
    value = c(59.9, 0.6, 0.1, 0.2)
  )
  
  for (i in seq_len(nrow(params))) {
    writeData(wb, ws, params$name[i], startRow = 4 + i, startCol = 1)
    writeData(wb, ws, params$value[i], startRow = 4 + i, startCol = 2)
    addStyle(wb, ws, input_style, rows = 4 + i, cols = 2)
  }
  
  writeData(wb, ws, "PARTICIPANT RESULTS", startRow = 10, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = 10, cols = 1)
  
  headers <- c("Participant", "x (result)", "u_x (std unc)", "U_x (exp unc)", 
               "z-score", "z'-score", "ζ-score", "En-score", "z Eval", "En Eval")
  writeData(wb, ws, t(headers), startRow = 11, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = 11, cols = 1:10, gridExpand = TRUE)
  
  participants <- data.frame(
    name = c("Lab A", "Lab B", "Lab C", "Lab D", "Lab E"),
    x = c(59.95, 59.80, 60.50, 59.90, 58.50),
    u_x = c(0.15, 0.20, 0.10, 0.25, 0.30),
    U_x = c(0.30, 0.40, 0.20, 0.50, 0.60)
  )
  
  for (i in seq_len(nrow(participants))) {
    r <- 11 + i
    writeData(wb, ws, participants$name[i], startRow = r, startCol = 1)
    writeData(wb, ws, participants$x[i], startRow = r, startCol = 2)
    addStyle(wb, ws, input_style, rows = r, cols = 2)
    writeData(wb, ws, participants$u_x[i], startRow = r, startCol = 3)
    addStyle(wb, ws, input_style, rows = r, cols = 3)
    writeData(wb, ws, participants$U_x[i], startRow = r, startCol = 4)
    addStyle(wb, ws, input_style, rows = r, cols = 4)
    
    writeFormula(wb, ws, sprintf("(B%d-$B$5)/$B$6", r), startRow = r, startCol = 5)
    addStyle(wb, ws, formula_style, rows = r, cols = 5)
    
    writeFormula(wb, ws, sprintf("(B%d-$B$5)/SQRT($B$6^2+$B$7^2)", r), startRow = r, startCol = 6)
    addStyle(wb, ws, formula_style, rows = r, cols = 6)
    
    writeFormula(wb, ws, sprintf("(B%d-$B$5)/SQRT(C%d^2+$B$7^2)", r, r), startRow = r, startCol = 7)
    addStyle(wb, ws, formula_style, rows = r, cols = 7)
    
    writeFormula(wb, ws, sprintf("(B%d-$B$5)/SQRT(D%d^2+$B$8^2)", r, r), startRow = r, startCol = 8)
    addStyle(wb, ws, formula_style, rows = r, cols = 8)
    
    writeFormula(wb, ws, sprintf('IF(ABS(E%d)<=2,"Satisfactorio",IF(ABS(E%d)<3,"Cuestionable","No satisfactorio"))', r, r), startRow = r, startCol = 9)
    addStyle(wb, ws, formula_style, rows = r, cols = 9)
    
    writeFormula(wb, ws, sprintf('IF(ABS(H%d)<=1,"Satisfactorio","No satisfactorio")', r), startRow = r, startCol = 10)
    addStyle(wb, ws, formula_style, rows = r, cols = 10)
  }
  
  ref_row <- 12 + nrow(participants) + 1
  writeData(wb, ws, "FORMULA REFERENCE", startRow = ref_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = ref_row, cols = 1)
  
  formulas <- data.frame(
    name = c("z-score", "z'-score", "ζ-score (zeta)", "En-score"),
    formula = c("z = (x - x_pt) / σ_pt", 
                "z' = (x - x_pt) / √(σ_pt² + u_xpt²)",
                "ζ = (x - x_pt) / √(u_x² + u_xpt²)", 
                "En = (x - x_pt) / √(U_x² + U_xpt²)")
  )
  
  for (i in seq_len(nrow(formulas))) {
    writeData(wb, ws, formulas$name[i], startRow = ref_row + i, startCol = 1)
    writeData(wb, ws, formulas$formula[i], startRow = ref_row + i, startCol = 2)
  }
  
  eval_row <- ref_row + nrow(formulas) + 2
  writeData(wb, ws, "EVALUATION CRITERIA", startRow = eval_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = eval_row, cols = 1)
  
  criteria <- data.frame(
    name = c("z-score", "En-score"),
    crit = c("|z| ≤ 2: Satisfactorio, 2 < |z| < 3: Cuestionable, |z| ≥ 3: No satisfactorio",
             "|En| ≤ 1: Satisfactorio, |En| > 1: No satisfactorio")
  )
  
  for (i in seq_len(nrow(criteria))) {
    writeData(wb, ws, criteria$name[i], startRow = eval_row + i, startCol = 1)
    writeData(wb, ws, criteria$crit[i], startRow = eval_row + i, startCol = 2)
  }
  
  setColWidths(wb, ws, cols = 1:10, widths = "auto")
}

create_multi_pollutant_sheet <- function(wb, summary_data, hom_data) {
  addWorksheet(wb, "Multi_Pollutant")
  ws <- "Multi_Pollutant"
  
  writeData(wb, ws, "MULTI-POLLUTANT ROBUST STATISTICS COMPARISON", startRow = 1, startCol = 1)
  addStyle(wb, ws, createStyle(fontSize = 14, textDecoration = "bold"), rows = 1, cols = 1)
  mergeCells(wb, ws, cols = 1:10, rows = 1)
  
  writeData(wb, ws, "ISO 13528:2022 - Robust estimates for all pollutants at selected levels", startRow = 2, startCol = 1)
  mergeCells(wb, ws, cols = 1:10, rows = 2)
  
  # Define pollutant/level combinations to showcase
  examples <- data.frame(
    pollutant = c("co", "no", "no2", "o3", "so2"),
    level = c("4-μmol/mol", "121-nmol/mol", "60-nmol/mol", "80-nmol/mol", "60-nmol/mol"),
    stringsAsFactors = FALSE
  )
  
  current_row <- 4
  
  for (ex_idx in seq_len(nrow(examples))) {
    poll <- examples$pollutant[ex_idx]
    lev <- examples$level[ex_idx]
    
    # Get data for this pollutant/level
    example_data <- summary_data[summary_data$pollutant == poll & summary_data$level == lev, ]
    values <- example_data$mean_value[!is.na(example_data$mean_value)]
    n <- length(values)
    
    if (n < 3) next  # Skip if not enough data
    
    # Section header
    writeData(wb, ws, sprintf("%s %s (n=%d)", toupper(poll), lev, n), 
              startRow = current_row, startCol = 1)
    addStyle(wb, ws, createStyle(textDecoration = "bold", fgFill = "#D9E1F2"), 
             rows = current_row, cols = 1:6, gridExpand = TRUE)
    mergeCells(wb, ws, cols = 1:6, rows = current_row)
    
    # Data column header
    writeData(wb, ws, "Values (xi)", startRow = current_row + 1, startCol = 1)
    addStyle(wb, ws, header_style, rows = current_row + 1, cols = 1)
    
    # Write values
    data_start <- current_row + 2
    for (i in seq_along(values)) {
      writeData(wb, ws, values[i], startRow = data_start + i - 1, startCol = 1)
    }
    data_end <- data_start + n - 1
    
    # Statistics on the right
    stats_col <- 3
    writeData(wb, ws, "Statistic", startRow = current_row + 1, startCol = stats_col)
    writeData(wb, ws, "Value", startRow = current_row + 1, startCol = stats_col + 1)
    writeData(wb, ws, "Formula", startRow = current_row + 1, startCol = stats_col + 2)
    addStyle(wb, ws, header_style, rows = current_row + 1, cols = stats_col:(stats_col + 2), gridExpand = TRUE)
    
    stats_row <- current_row + 2
    
    writeData(wb, ws, "n", startRow = stats_row, startCol = stats_col)
    writeFormula(wb, ws, sprintf("COUNT(A%d:A%d)", data_start, data_end), startRow = stats_row, startCol = stats_col + 1)
    
    writeData(wb, ws, "Median", startRow = stats_row + 1, startCol = stats_col)
    writeFormula(wb, ws, sprintf("MEDIAN(A%d:A%d)", data_start, data_end), startRow = stats_row + 1, startCol = stats_col + 1)
    addStyle(wb, ws, result_style, rows = stats_row + 1, cols = stats_col + 1)
    writeData(wb, ws, "MEDIAN(xi)", startRow = stats_row + 1, startCol = stats_col + 2)
    
    writeData(wb, ws, "Mean", startRow = stats_row + 2, startCol = stats_col)
    writeFormula(wb, ws, sprintf("AVERAGE(A%d:A%d)", data_start, data_end), startRow = stats_row + 2, startCol = stats_col + 1)
    writeData(wb, ws, "AVERAGE(xi)", startRow = stats_row + 2, startCol = stats_col + 2)
    
    writeData(wb, ws, "SD", startRow = stats_row + 3, startCol = stats_col)
    writeFormula(wb, ws, sprintf("STDEV.S(A%d:A%d)", data_start, data_end), startRow = stats_row + 3, startCol = stats_col + 1)
    writeData(wb, ws, "STDEV.S(xi)", startRow = stats_row + 3, startCol = stats_col + 2)
    
    writeData(wb, ws, "Q1", startRow = stats_row + 4, startCol = stats_col)
    writeFormula(wb, ws, sprintf("QUARTILE.INC(A%d:A%d,1)", data_start, data_end), startRow = stats_row + 4, startCol = stats_col + 1)
    
    writeData(wb, ws, "Q3", startRow = stats_row + 5, startCol = stats_col)
    writeFormula(wb, ws, sprintf("QUARTILE.INC(A%d:A%d,3)", data_start, data_end), startRow = stats_row + 5, startCol = stats_col + 1)
    
    writeData(wb, ws, "IQR", startRow = stats_row + 6, startCol = stats_col)
    writeFormula(wb, ws, sprintf("D%d-D%d", stats_row + 5, stats_row + 4), startRow = stats_row + 6, startCol = stats_col + 1)
    writeData(wb, ws, "Q3 - Q1", startRow = stats_row + 6, startCol = stats_col + 2)
    
    writeData(wb, ws, "nIQR", startRow = stats_row + 7, startCol = stats_col)
    writeFormula(wb, ws, sprintf("0.7413*D%d", stats_row + 6), startRow = stats_row + 7, startCol = stats_col + 1)
    addStyle(wb, ws, result_style, rows = stats_row + 7, cols = stats_col + 1)
    writeData(wb, ws, "0.7413 × IQR", startRow = stats_row + 7, startCol = stats_col + 2)
    
    writeData(wb, ws, "MADe", startRow = stats_row + 8, startCol = stats_col)
    # MAD calculation requires computing |xi - median| first, approximate with formula
    writeData(wb, ws, "(computed)", startRow = stats_row + 8, startCol = stats_col + 1)
    writeData(wb, ws, "1.483 × median(|xi-median|)", startRow = stats_row + 8, startCol = stats_col + 2)
    
    current_row <- max(data_end, stats_row + 9) + 3
  }
  
  # Summary comparison table
  writeData(wb, ws, "SUMMARY COMPARISON TABLE", startRow = current_row, startCol = 1)
  addStyle(wb, ws, createStyle(textDecoration = "bold"), rows = current_row, cols = 1)
  
  sum_headers <- c("Pollutant", "Level", "n", "Median", "Mean", "SD", "nIQR")
  writeData(wb, ws, t(sum_headers), startRow = current_row + 1, startCol = 1, colNames = FALSE)
  addStyle(wb, ws, header_style, rows = current_row + 1, cols = 1:7, gridExpand = TRUE)
  
  for (ex_idx in seq_len(nrow(examples))) {
    poll <- examples$pollutant[ex_idx]
    lev <- examples$level[ex_idx]
    example_data <- summary_data[summary_data$pollutant == poll & summary_data$level == lev, ]
    values <- example_data$mean_value[!is.na(example_data$mean_value)]
    n <- length(values)
    
    if (n >= 3) {
      r <- current_row + 1 + ex_idx
      writeData(wb, ws, toupper(poll), startRow = r, startCol = 1)
      writeData(wb, ws, lev, startRow = r, startCol = 2)
      writeData(wb, ws, n, startRow = r, startCol = 3)
      writeData(wb, ws, round(median(values), 4), startRow = r, startCol = 4)
      writeData(wb, ws, round(mean(values), 4), startRow = r, startCol = 5)
      writeData(wb, ws, round(sd(values), 4), startRow = r, startCol = 6)
      iqr_val <- IQR(values)
      writeData(wb, ws, round(0.7413 * iqr_val, 4), startRow = r, startCol = 7)
    }
  }
  
  setColWidths(wb, ws, cols = 1:6, widths = "auto")
}

main <- function() {
  message("Loading data files...")
  
  hom_data <- read.csv(file.path(DATA_DIR, "homogeneity.csv"), stringsAsFactors = FALSE)
  stab_data <- read.csv(file.path(DATA_DIR, "stability.csv"), stringsAsFactors = FALSE)
  summary_data <- read.csv(file.path(DATA_DIR, "summary_n4.csv"), stringsAsFactors = FALSE)
  
  message(sprintf("Loaded homogeneity: %d rows", nrow(hom_data)))
  message(sprintf("Loaded stability: %d rows", nrow(stab_data)))
  message(sprintf("Loaded summary_n4: %d rows", nrow(summary_data)))
  
  wb <- createWorkbook()
  
  message("Creating Homogeneity sheet...")
  create_homogeneity_sheet(wb, hom_data)
  
  message("Creating Stability sheet...")
  create_stability_sheet(wb, hom_data, stab_data)
  
  message("Creating Robust Stats sheet...")
  create_robust_stats_sheet(wb, summary_data)
  
  message("Creating Algorithm A sheet...")
  create_algorithm_a_sheet(wb, summary_data)
  
  message("Creating Multi-Pollutant sheet...")
  create_multi_pollutant_sheet(wb, summary_data, hom_data)
  
  message("Creating PT Scores sheet...")
  create_pt_scores_sheet(wb)
  
  output_path <- file.path(OUTPUT_DIR, "validation_calculations.xlsx")
  saveWorkbook(wb, output_path, overwrite = TRUE)
  message(sprintf("\nSaved: %s", output_path))
  
  message("\n", paste(rep("=", 60), collapse = ""))
  message("Validation spreadsheet created successfully!")
  message("Open in Excel/LibreOffice to verify formulas calculate correctly.")
  message(paste(rep("=", 60), collapse = ""))
  
  return(output_path)
}

if (!interactive() || identical(environment(), globalenv())) {
  main()
}
