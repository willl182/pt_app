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
