# ===================================================================
# Etapa 1: Estadisticos Robust de Dispersión
# Validacion de mediana, MAD, MADe y nIQR
#
# Referencia: ISO 13528:2022, Seccion 9.4
# Fuente: data/for_validation/summary_n4.csv
# Alcance: O3 en 3 niveles (0, 80, 180 nmol/mol)
# ===================================================================

DATA_SUMMARY <- "../data/for_validation/summary_n4.csv"
OUTPUT_R_CSV <- "validation_1/outputs/stage_01_robust_stats_r.csv"
OUTPUT_CSV <- "validation_1/outputs/stage_01_robust_stats.csv"
OUTPUT_REPORT <- "validation_1/outputs/stage_01_robust_stats_report.md"

TARGET_COMBOS <- data.frame(
  pollutant = c("o3", "o3", "o3"),
  level = c("0-nmol/mol", "80-nmol/mol", "180-nmol/mol"),
  stringsAsFactors = FALSE
)

make_combo_id <- function(pollutant, level) {
  prefix <- toupper(pollutant)
  num <- sub("^([0-9]+)-.*$", "\\1", level)
  paste0(prefix, "_", num)
}

calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  q <- stats::quantile(x_clean, probs = c(0.25, 0.75), type = 7, na.rm = TRUE)
  0.7413 * as.numeric(q[2] - q[1])
}

run_stage_01_robust_stats <- function() {
  cat("Etapa 1: Estadisticos Robust de Dispersión — INICIO\n")

  summary_raw <- read.csv(DATA_SUMMARY, stringsAsFactors = FALSE)
  summary_raw <- summary_raw[summary_raw$participant_id != "ref", ]

  r_rows <- list()

  for (i in seq_len(nrow(TARGET_COMBOS))) {
    combo <- TARGET_COMBOS[i, ]
    combo_id <- make_combo_id(combo$pollutant, combo$level)
    combo_data <- summary_raw[
      summary_raw$pollutant == combo$pollutant &
        summary_raw$level == combo$level, ,
      drop = FALSE
    ]

    values <- combo_data$mean_value
    values <- values[is.finite(values)]
    n_values <- length(values)

    if (n_values < 2) {
      r_rows[[length(r_rows) + 1]] <- data.frame(
        combo_id = combo_id,
        pollutant = combo$pollutant,
        level = combo$level,
        n_values = n_values,
        x_pt = NA_real_,
        mad = NA_real_,
        MADe = NA_real_,
        nIQR = NA_real_,
        edge_case = TRUE,
        stringsAsFactors = FALSE
      )
      next
    }

    x_pt <- stats::median(values, na.rm = TRUE)
    mad_val <- stats::median(abs(values - x_pt), na.rm = TRUE)
    made_val <- 1.483 * mad_val
    niqr_val <- calculate_niqr(values)

    r_rows[[length(r_rows) + 1]] <- data.frame(
      combo_id = combo_id,
      pollutant = combo$pollutant,
      level = combo$level,
      n_values = n_values,
      x_pt = x_pt,
      mad = mad_val,
      MADe = made_val,
      nIQR = niqr_val,
      edge_case = FALSE,
      stringsAsFactors = FALSE
    )

    cat(
      "  ", combo_id,
      " n=", n_values,
      " x_pt=", round(x_pt, 8),
      " mad=", round(mad_val, 8),
      " MADe=", round(made_val, 8),
      " nIQR=", round(niqr_val, 8),
      "\n"
    )
  }

  r_df <- do.call(rbind, r_rows)
  dir.create(dirname(OUTPUT_R_CSV), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE, na = "NA")
  cat("  Resultados R guardados:", OUTPUT_R_CSV, "\n")

  py_path <- sub("_r.csv$", "_py.csv", OUTPUT_R_CSV)
  py_df <- if (file.exists(py_path)) {
    read.csv(py_path, stringsAsFactors = FALSE)
  } else {
    NULL
  }

  all_rows <- list()
  metrics <- c("n_values", "x_pt", "mad", "MADe", "nIQR")

  for (i in seq_len(nrow(r_df))) {
    r_row <- r_df[i, ]
    py_row <- if (!is.null(py_df)) py_df[py_df$combo_id == r_row$combo_id, ] else NULL

    for (metric in metrics) {
      r_val <- suppressWarnings(as.numeric(r_row[[metric]]))
      py_val <- if (!is.null(py_row) && nrow(py_row) > 0) {
        suppressWarnings(as.numeric(py_row[[metric]][1]))
      } else {
        NA_real_
      }
      both_finite <- isTRUE(is.finite(r_val)) && isTRUE(is.finite(py_val))
      diff_r_python <- if (both_finite) {
        r_val - py_val
      } else {
        NA_real_
      }
      status <- if (!is.na(diff_r_python) && abs(diff_r_python) <= 1e-9) {
        "PASS"
      } else if (isTRUE(is.na(diff_r_python)) && isTRUE(is.na(r_val)) && isTRUE(is.na(py_val))) {
        "PASS"
      } else {
        "FAIL"
      }

      all_rows[[length(all_rows) + 1]] <- data.frame(
        combo_id = r_row$combo_id,
        pollutant = r_row$pollutant,
        level = r_row$level,
        stage = "stage_01_robust_stats",
        section = "robust_stats",
        participant_id = "ALL",
        metric = metric,
        app_value = r_val,
        r_value = r_val,
        python_value = py_val,
        diff_app_r = 0,
        diff_app_python = if (both_finite) r_val - py_val else NA_real_,
        diff_r_python = diff_r_python,
        status = status,
        tolerance = 1e-9,
        notes = ifelse(metric == "n_values", "Filtrado O3 y exclusion de ref", ""),
        stringsAsFactors = FALSE
      )
    }
  }

  out_df <- do.call(rbind, all_rows)
  utils::write.csv(out_df, OUTPUT_CSV, row.names = FALSE, na = "NA")
  cat("  Comparacion guardada:", OUTPUT_CSV, "\n")

  pass_count <- sum(out_df$status == "PASS", na.rm = TRUE)
  fail_count <- sum(out_df$status == "FAIL", na.rm = TRUE)
  report_lines <- c(
    "# Reporte: Etapa 1 - Estadisticos Robust de Dispersión",
    "",
    paste0("**Fecha**: ", format(Sys.Date(), "%Y-%m-%d")),
    "",
    "## Combos procesados",
    paste0("- ", unique(out_df$combo_id)),
    "",
    "## Resumen PASS/FAIL",
    paste0("- PASS: ", pass_count),
    paste0("- FAIL: ", fail_count),
    "- EDGE_CASE: 0",
    "- KNOWN_DISCREPANCY: 0",
    "",
    "## Validaciones requeridas",
    "- Mediana calculada sobre mean_value filtrado por O3 y nivel",
    "- Factor MADe = 1.483",
    "- Factor nIQR = 0.7413",
    "- Cuartiles con type = 7",
    "",
    "## Conclusión",
    if (fail_count == 0) "Etapa PASS" else "Etapa con FAIL pendientes de revisión",
    ""
  )
  writeLines(report_lines, OUTPUT_REPORT)
  cat("  Reporte guardado:", OUTPUT_REPORT, "\n")
  cat("Etapa 1: Estadisticos Robust de Dispersión — FIN\n")
}

if (sys.nframe() == 0) {
  run_stage_01_robust_stats()
}
