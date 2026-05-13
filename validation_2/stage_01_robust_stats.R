# ===================================================================
# Etapa 1: Estadísticos Robustos de Dispersión
# Validación de mediana, MAD, MADe, nIQR sobre sample_1
#
# Referencia: ISO 13528:2022, Sección 9.4
# Fuente: data/homogeneity_n13.csv
# Combos primarios: O3 × 3 niveles (0, 80, 180 nmol/mol)
# ===================================================================
#
## Uso
#
# Propósito: Calcular estadísticos robustos independientemente en R
# Inputs: data/homogeneity_n13.csv
# Outputs: validation_2/outputs/stage_01_robust_stats_r.csv (intermedio)
#          validation_2/outputs/stage_01_robust_stats.csv (canónico)
#          validation_2/outputs/stage_01_robust_stats_report.md
#
# Métricas validadas (4 por combo):
#   median (x_pt), MAD, MADe, nIQR
#
# Ejemplo:
#   Rscript validation_2/stage_01_robust_stats.R

source("validation_2/helpers.R")

DATA_HOMOGENEITY <- "data/homogeneity_n13.csv"
OUTPUT_R_CSV     <- "validation_2/outputs/stage_01_robust_stats_r.csv"
OUTPUT_CSV       <- "validation_2/outputs/stage_01_robust_stats.csv"
OUTPUT_REPORT    <- "validation_2/outputs/stage_01_robust_stats_report.md"

# --- Cargar paquete ptcalc para comparación ---
devtools::load_all("ptcalc")

# ===================================================================
# Funciones de cálculo
# ===================================================================

calc_robust_stats <- function(sample1_values) {
  x_clean <- sample1_values[is.finite(sample1_values)]
  n <- length(x_clean)

  if (n < 2) {
    return(list(
      n = n, median_val = NA_real_, MAD_val = NA_real_,
      MADe_val = NA_real_, nIQR_val = NA_real_,
      Q1 = NA_real_, Q3 = NA_real_, IQR_val = NA_real_,
      edge_case = TRUE
    ))
  }

  # Mediana (x_pt) — Sección 9.2
  median_val <- stats::median(x_clean, na.rm = TRUE)

  # MAD: median(|x_i - median(x)|) — Sección 9.4
  abs_dev <- abs(x_clean - median_val)
  MAD_val <- stats::median(abs_dev, na.rm = TRUE)

  # MADe = 1.483 × MAD — Sección 9.4
  MADe_val <- 1.483 * MAD_val

  # Cuartiles tipo 7 (default de R) — Sección 9.4
  qs <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  Q1 <- unname(qs[1])
  Q3 <- unname(qs[2])
  IQR_val <- Q3 - Q1

  # nIQR = 0.7413 × IQR — Sección 9.4
  nIQR_val <- 0.7413 * IQR_val

  list(
    n = n,
    median_val = median_val,
    MAD_val = MAD_val,
    MADe_val = MADe_val,
    nIQR_val = nIQR_val,
    Q1 = Q1,
    Q3 = Q3,
    IQR_val = IQR_val,
    edge_case = FALSE
  )
}

# ===================================================================
# Ejecutar para O3 × 3 niveles
# ===================================================================

run_stage_01 <- function() {
  cat("Etapa 1: Estadísticos Robustos — INICIO\n")
  cat("  Datos:", DATA_HOMOGENEITY, "\n")
  cat("  Combos: O3 × 3 niveles\n\n")

  all_results <- list()

  for (combo in COMBOS) {
    combo_id <- make_combo_id(combo$pollutant, combo$level)
    cat("  Procesando:", combo$label, "\n")

    # Cargar datos en formato ancho
    wide <- load_wide_data(DATA_HOMOGENEITY, combo$pollutant, combo$level)

    if (nrow(wide) < 2 || !("sample_1" %in% names(wide))) {
      cat("    ADVERTENCIA: datos insuficientes, saltando\n")
      all_results[[combo_id]] <- list(
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        stage = "01_robust_stats", section = "robust",
        metric = "insufficient_data", r_value = NA_real_, python_value = NA_real_,
        app_value = NA_real_, diff_r_python = NA_real_,
        diff_app_r = NA_real_, diff_app_python = NA_real_,
        status = "EDGE_CASE", tolerance = 1e-9, notes = "Less than 2 samples"
      )
      next
    }

    # Extraer sample_1 (primera réplica)
    sample1 <- wide$sample_1

    # Calcular estadísticos robustos con funciones propias
    stats <- calc_robust_stats(sample1)

    # Calcular estadísticos robustos con ptcalc para verificación
    ptcalc_niqr <- calculate_niqr(sample1)
    ptcalc_made <- calculate_mad_e(sample1)

    cat("    n=", stats$n,
        " median=", signif(stats$median_val, 8),
        " MAD=", signif(stats$MAD_val, 8),
        " MADe=", signif(stats$MADe_val, 8),
        " nIQR=", signif(stats$nIQR_val, 8), "\n")

    # Verificar consistencia con ptcalc
    diff_made <- abs(stats$MADe_val - ptcalc_made)
    diff_niqr <- abs(stats$nIQR_val - ptcalc_niqr)
    cat("    ptcalc MADe diff=", signif(diff_made, 12),
        " nIQR diff=", signif(diff_niqr, 12), "\n")

    # Construir resultados canónicos
    metrics <- list(
      list(metric = "median",  r_value = stats$median_val),
      list(metric = "MAD",     r_value = stats$MAD_val),
      list(metric = "MADe",    r_value = stats$MADe_val),
      list(metric = "nIQR",    r_value = stats$nIQR_val),
      list(metric = "Q1",      r_value = stats$Q1),
      list(metric = "Q3",      r_value = stats$Q3),
      list(metric = "IQR",     r_value = stats$IQR_val),
      list(metric = "n",       r_value = as.numeric(stats$n))
    )

    for (m in metrics) {
      # La comparación app_value se deja NA hasta que se ejecuten los scripts Python
      all_results[[paste0(combo_id, "_", m$metric)]] <- list(
        combo_id = combo_id,
        pollutant = combo$pollutant,
        level = combo$level,
        stage = "01_robust_stats",
        section = "robust",
        metric = m$metric,
        r_value = m$r_value,
        python_value = NA_real_,
        app_value = NA_real_,
        diff_r_python = NA_real_,
        diff_app_r = NA_real_,
        diff_app_python = NA_real_,
        status = "PENDING_PYTHON",
        tolerance = 1e-9,
        notes = ""
      )
    }
  }

  # Guardar resultados R como CSV intermedio
  r_df <- do.call(rbind, lapply(all_results, function(x) {
    data.frame(
      combo_id = x$combo_id,
      pollutant = x$pollutant,
      level = x$level,
      stage = x$stage,
      section = x$section,
      metric = x$metric,
      r_value = x$r_value,
      python_value = x$python_value,
      app_value = x$app_value,
      diff_r_python = x$diff_r_python,
      diff_app_r = x$diff_app_r,
      diff_app_python = x$diff_app_python,
      status = x$status,
      tolerance = x$tolerance,
      notes = x$notes,
      stringsAsFactors = FALSE
    )
  }))
  rownames(r_df) <- NULL
  utils::write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE)
  cat("\n  Resultados R guardados:", OUTPUT_R_CSV, "\n")

  cat("\nEtapa 1: Estadísticos Robustos (R) — FIN\n")

  invisible(all_results)
}

if (sys.nframe() == 0) {
  run_stage_01()
}