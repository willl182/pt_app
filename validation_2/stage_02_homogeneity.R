# ===================================================================
# Etapa 2: Homogeneidad
# Validación de estadísticos y criterios de homogeneidad
#
# Referencia: ISO 13528:2022, Sección 9.2
# Fuente: data/homogeneity_n13.csv
# Combos primarios: O3 × 3 niveles (0, 80, 180 nmol/mol)
#
# Métricas validadas (17 métricas × 3 combos = 51 filas en CSV):
#   g, m, general_mean_homog, x_pt, s_x_bar_sq, s_xt,
#   sw, sw_sq, ss_sq, ss,
#   sigma_pt, MADe, u_sigma_pt, nIQR,
#   criterio_c_MADe, criterio_exp_MADe, criterio_c_nIQR,
#   criterio_exp_nIQR, ss_vs_c_MADe, ss_vs_c_nIQR
# Discrepancia conocida:
#   - criterion_expanded: ptcalc usa 2 args (ISO clásica),
#     R/app usa 3 args con tabla F1/F2. Este script usa F1/F2.
# ===================================================================

source("validation_2/helpers.R")

DATA_HOMOGENEITY <- "data/homogeneity_n13.csv"
OUTPUT_R_CSV    <- "validation_2/outputs/stage_02_homogeneity_r.csv"
OUTPUT_CSV      <- "validation_2/outputs/stage_02_homogeneity.csv"
OUTPUT_REPORT   <- "validation_2/outputs/stage_02_homogeneity_report.md"

# --- Cargar ptcalc para comparación ---
devtools::load_all("ptcalc")

# --- Tabla F1/F2 para criterio expandido (ISO 13528:2022 §9.2.4) ---
F_TABLE <- data.frame(
  g  = 7:20,
  f1 = c(2.10, 2.01, 1.94, 1.88, 1.83, 1.79, 1.75, 1.72,
         1.69, 1.67, 1.64, 1.62, 1.60, 1.59),
  f2 = c(1.43, 1.25, 1.11, 1.01, 0.93, 0.86, 0.80, 0.75,
         0.71, 0.68, 0.64, 0.62, 0.59, 0.57)
)

# ===================================================================
# Funciones de cálculo
# ===================================================================

calc_criterion_expanded_f1f2 <- function(sigma_pt, sw, g) {
  # F1/F2 lookup table, clamped to g in [7, 20]
  g_clamped <- max(7, min(20, g))
  idx <- which(F_TABLE$g == g_clamped)
  f1 <- F_TABLE$f1[idx]
  f2 <- F_TABLE$f2[idx]
  f1 * (0.3 * sigma_pt)^2 + f2 * sw^2
}

calc_homogeneity <- function(wide_df) {
  # wide_df: data.frame con columnas sample_id, sample_1, sample_2
  sample_cols <- grep("^sample_\\d+$", names(wide_df), value = TRUE)
  sample_data <- as.matrix(wide_df[, sample_cols, drop = FALSE])

  g <- nrow(sample_data)
  m <- ncol(sample_data)

  if (g < 2) return(list(error = "Se necesitan al menos 2 muestras."))
  if (m < 2) return(list(error = "Se necesitan al menos 2 replicas."))

  # Medias por muestra
  sample_means <- rowMeans(sample_data, na.rm = TRUE)

  # Media general de TODOS los valores
  general_mean_homog <- mean(sample_data, na.rm = TRUE)

  # x_pt: mediana de la primera replica
  x_pt <- stats::median(sample_data[, 1], na.rm = TRUE)

  # Varianza de medias muestrales (ddof=1, como R var())
  s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)

  # sw: DE intra-muestra (rango para m=2)
  if (m == 2) {
    range_btw <- abs(sample_data[, 1] - sample_data[, 2])
    sw <- sqrt(sum(range_btw^2) / (2 * g))
  } else {
    within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(mean(within_vars, na.rm = TRUE))
  }

  sw_sq <- sw^2

  # ss_sq = abs(s_x_bar_sq - sw_sq/m)
  ss_sq <- abs(s_x_bar_sq - sw_sq / m)
  ss <- sqrt(ss_sq)

  # sigma_pt = mediana(|sample_2 - x_pt|)  (misma lógica que ptcalc)
  abs_diff_from_xpt <- abs(sample_data[, 2] - x_pt)
  sigma_pt <- stats::median(abs_diff_from_xpt, na.rm = TRUE)

  # MADe = 1.483 * sigma_pt
  MADe <- 1.483 * sigma_pt

  # u_sigma_pt = 1.25 * MADe / sqrt(g)
  u_sigma_pt <- 1.25 * MADe / sqrt(g)

  # nIQR = 0.7413 * IQR (type=7) sobre sample_1
  qs <- stats::quantile(sample_data[, 1], probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  Q1 <- unname(qs[1])
  Q3 <- unname(qs[2])
  IQR_val <- Q3 - Q1
  nIQR <- 0.7413 * IQR_val

  # Criterios MADe
  criterio_c_MADe <- 0.3 * MADe
  criterio_exp_MADe <- calc_criterion_expanded_f1f2(MADe, sw, g)

  # Criterios nIQR
  criterio_c_nIQR <- 0.3 * nIQR
  criterio_exp_nIQR <- calc_criterion_expanded_f1f2(nIQR, sw, g)

  # Evaluaciones
  ss_vs_c_MADe <- if (ss <= criterio_c_MADe) "CUMPLE" else "NO_CUMPLE"
  ss_vs_c_nIQR  <- if (!is.na(nIQR) && nIQR > 0) {
    if (ss <= criterio_c_nIQR) "CUMPLE" else "NO_CUMPLE"
  } else "N/A"

  list(
    g = g, m = m,
    general_mean_homog = general_mean_homog,
    x_pt = x_pt,
    s_x_bar_sq = s_x_bar_sq, s_xt = s_xt,
    sw = sw, sw_sq = sw_sq,
    ss_sq = ss_sq, ss = ss,
    sigma_pt = sigma_pt, MADe = MADe,
    u_sigma_pt = u_sigma_pt,
    nIQR = nIQR, Q1_homog = Q1, Q3_homog = Q3, IQR_homog = IQR_val,
    criterio_c_MADe = criterio_c_MADe,
    criterio_exp_MADe = criterio_exp_MADe,
    criterio_c_nIQR = criterio_c_nIQR,
    criterio_exp_nIQR = criterio_exp_nIQR,
    ss_vs_c_MADe = ss_vs_c_MADe,
    ss_vs_c_nIQR = ss_vs_c_nIQR,
    error = NULL
  )
}

# ===================================================================
# Ejecutar para O3 × 3 niveles
# ===================================================================

run_stage_02 <- function() {
  cat("Etapa 2: Homogeneidad — INICIO\n")
  cat("  Datos:", DATA_HOMOGENEITY, "\n")
  cat("  Combos: O3 × 3 niveles\n\n")

  all_results <- list()

  for (combo in COMBOS) {
    combo_id <- make_combo_id(combo$pollutant, combo$level)
    cat("  Procesando:", combo$label, "\n")

    # Cargar datos en formato ancho
    wide <- load_wide_data(DATA_HOMOGENEITY, combo$pollutant, combo$level)

    if (nrow(wide) < 2) {
      cat("    ADVERTENCIA: datos insuficientes, saltando\n")
      all_results[[paste0(combo_id, "_error")]] <- list(
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        stage = "02_homogeneity", section = "homogeneity",
        metric = "insufficient_data", r_value = NA_real_, python_value = NA_real_,
        app_value = NA_real_, diff_r_python = NA_real_,
        diff_app_r = NA_real_, diff_app_python = NA_real_,
        status = "EDGE_CASE", tolerance = 1e-9, notes = "Less than 2 samples"
      )
      next
    }

    # --- Cálculo propio ---
    hom <- calc_homogeneity(wide)
    if (!is.null(hom$error)) {
      cat("    ERROR:", hom$error, "\n")
      next
    }

    # --- Cálculo con ptcalc para comparación ---
    sample_cols <- grep("^sample_\\d+$", names(wide), value = TRUE)
    sample_matrix <- as.matrix(wide[, sample_cols, drop = FALSE])
    ptcalc_hom <- calculate_homogeneity_stats(sample_matrix)

    cat("    g=", hom$g, " m=", hom$m,
        " x_pt=", signif(hom$x_pt, 8),
        " sw=", signif(hom$sw, 8),
        " ss=", signif(hom$ss, 8),
        " MADe=", signif(hom$MADe, 8),
        " sigma_pt=", signif(hom$sigma_pt, 8), "\n")

    # Verificar consistencia con ptcalc
    diff_x_pt <- abs(hom$x_pt - ptcalc_hom$x_pt)
    diff_sw <- abs(hom$sw - ptcalc_hom$sw)
    diff_ss <- abs(hom$ss - ptcalc_hom$ss)
    diff_MADe <- abs(hom$MADe - ptcalc_hom$MADe)
    diff_sigma_pt <- abs(hom$sigma_pt - ptcalc_hom$sigma_pt)
    cat("    ptcalc diff: x_pt=", signif(diff_x_pt, 12),
        " sw=", signif(diff_sw, 12),
        " ss=", signif(diff_ss, 12),
        " MADe=", signif(diff_MADe, 12),
        " sigma_pt=", signif(diff_sigma_pt, 12), "\n")

    # Construir resultados canónicos
    metrics <- list(
      list(metric = "g",                   r_value = as.numeric(hom$g)),
      list(metric = "m",                   r_value = as.numeric(hom$m)),
      list(metric = "general_mean_homog",  r_value = hom$general_mean_homog),
      list(metric = "x_pt",                r_value = hom$x_pt),
      list(metric = "s_x_bar_sq",          r_value = hom$s_x_bar_sq),
      list(metric = "s_xt",                r_value = hom$s_xt),
      list(metric = "sw",                  r_value = hom$sw),
      list(metric = "sw_sq",               r_value = hom$sw_sq),
      list(metric = "ss_sq",               r_value = hom$ss_sq),
      list(metric = "ss",                  r_value = hom$ss),
      list(metric = "sigma_pt",            r_value = hom$sigma_pt),
      list(metric = "MADe",                r_value = hom$MADe),
      list(metric = "u_sigma_pt",          r_value = hom$u_sigma_pt),
      list(metric = "nIQR",                r_value = hom$nIQR),
      list(metric = "criterio_c_MADe",     r_value = hom$criterio_c_MADe),
      list(metric = "criterio_exp_MADe",   r_value = hom$criterio_exp_MADe),
      list(metric = "criterio_c_nIQR",     r_value = hom$criterio_c_nIQR),
      list(metric = "criterio_exp_nIQR",   r_value = hom$criterio_exp_nIQR)
    )

    for (m in metrics) {
      tol <- if (m$metric %in% c("g", "m")) 0.5 else 1e-9
      all_results[[paste0(combo_id, "_", m$metric)]] <- list(
        combo_id = combo_id,
        pollutant = combo$pollutant,
        level = combo$level,
        stage = "02_homogeneity",
        section = "homogeneity",
        metric = m$metric,
        r_value = m$r_value,
        python_value = NA_real_,
        app_value = NA_real_,
        diff_r_python = NA_real_,
        diff_app_r = NA_real_,
        diff_app_python = NA_real_,
        status = "PENDING_PYTHON",
        tolerance = tol,
        notes = if (m$metric %in% c("criterio_exp_MADe", "criterio_exp_nIQR")) 
          "Usa tabla F1/F2 (app.R), NO ptcalc 2-arg" else ""
      )
    }

    # Evaluaciones cualitativas
    ss_vs_exp_MADe <- if (hom$ss <= hom$criterio_exp_MADe) "CUMPLE" else "NO_CUMPLE"
    ss_vs_exp_nIQR <- if (!is.na(hom$nIQR) && hom$nIQR > 0) {
      if (hom$ss <= hom$criterio_exp_nIQR) "CUMPLE" else "NO_CUMPLE"
    } else "N/A"

    all_results[[paste0(combo_id, "_ss_vs_c_MADe")]] <- list(
      combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
      stage = "02_homogeneity", section = "evaluation",
      metric = "ss_vs_c_MADe",
      r_value = NA_real_, python_value = NA_real_, app_value = NA_real_,
      diff_r_python = NA_real_, diff_app_r = NA_real_, diff_app_python = NA_real_,
      status = hom$ss_vs_c_MADe, tolerance = NA_real_,
      notes = paste0("ss=", signif(hom$ss, 6), " c_MADe=", signif(hom$criterio_c_MADe, 6))
    )
    all_results[[paste0(combo_id, "_ss_vs_c_nIQR")]] <- list(
      combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
      stage = "02_homogeneity", section = "evaluation",
      metric = "ss_vs_c_nIQR",
      r_value = NA_real_, python_value = NA_real_, app_value = NA_real_,
      diff_r_python = NA_real_, diff_app_r = NA_real_, diff_app_python = NA_real_,
      status = hom$ss_vs_c_nIQR, tolerance = NA_real_,
      notes = paste0("ss=", signif(hom$ss, 6), " c_nIQR=", signif(hom$criterio_c_nIQR, 6))
    )
    all_results[[paste0(combo_id, "_ss_vs_exp_MADe")]] <- list(
      combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
      stage = "02_homogeneity", section = "evaluation",
      metric = "ss_vs_exp_MADe",
      r_value = NA_real_, python_value = NA_real_, app_value = NA_real_,
      diff_r_python = NA_real_, diff_app_r = NA_real_, diff_app_python = NA_real_,
      status = ss_vs_exp_MADe, tolerance = NA_real_,
      notes = paste0("ss=", signif(hom$ss, 6), " c_exp_MADe=", signif(hom$criterio_exp_MADe, 6))
    )
    all_results[[paste0(combo_id, "_ss_vs_exp_nIQR")]] <- list(
      combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
      stage = "02_homogeneity", section = "evaluation",
      metric = "ss_vs_exp_nIQR",
      r_value = NA_real_, python_value = NA_real_, app_value = NA_real_,
      diff_r_python = NA_real_, diff_app_r = NA_real_, diff_app_python = NA_real_,
      status = ss_vs_exp_nIQR, tolerance = NA_real_,
      notes = paste0("ss=", signif(hom$ss, 6), " c_exp_nIQR=", signif(hom$criterio_exp_nIQR, 6))
    )
  }

  # Guardar CSV intermedio R
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
      tolerance = ifelse(is.na(x$tolerance), NA, x$tolerance),
      notes = x$notes,
      stringsAsFactors = FALSE
    )
  }))
  rownames(r_df) <- NULL
  utils::write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE)
  cat("\n  Resultados R guardados:", OUTPUT_R_CSV, "\n")

  cat("\nEtapa 2: Homogeneidad (R) — FIN\n")

  invisible(all_results)
}

if (sys.nframe() == 0) {
  run_stage_02()
}