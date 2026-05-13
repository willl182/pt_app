# ===================================================================
# Etapa 3: Estabilidad
# Validación de estadísticos y criterios de estabilidad
#
# Referencia: ISO 13528:2022, Sección 9.3
# Fuente: data/stability_n13.csv + data/homogeneity_n13.csv
# Combos primarios: O3 × 3 niveles (0, 80, 180 nmol/mol)
#
# Métricas validadas (22 métricas × 3 combos + 4 evaluaciones × 3 combos = 78 filas):
#   ANOVA de estabilidad:
#     g_stab, m_stab, general_mean_stab, x_pt_stab,
#     s_x_bar_sq_stab, s_xt_stab, sw_stab, sw_sq_stab,
#     ss_sq_stab, ss_stab
#   Delta y criterios:
#     diff_hom_stab (Dmax), media_hom, media_stab,
#     c_stab_MADe, c_stab_nIQR,
#     c_stab_exp_MADe, c_stab_exp_nIQR,
#     u_hom_mean, u_stab_mean,
#     u_stab (0 si Dmax≤c_stab, Dmax/sqrt(3) si no)
#   Evaluaciones:
#     Dmax_vs_c_MADe, Dmax_vs_c_nIQR,
#     Dmax_vs_exp_MADe, Dmax_vs_exp_nIQR
#
# Dependencia: necesita resultados de Etapa 2 (homogeneidad)
# ===================================================================

source("validation_2/helpers.R")

DATA_HOMOGENEITY <- "data/homogeneity_n13.csv"
DATA_STABILITY   <- "data/stability_n13.csv"
OUTPUT_R_CSV     <- "validation_2/outputs/stage_03_stability_r.csv"
OUTPUT_CSV       <- "validation_2/outputs/stage_03_stability.csv"
OUTPUT_REPORT    <- "validation_2/outputs/stage_03_stability_report.md"

# --- Cargar ptcalc para comparación ---
devtools::load_all("ptcalc")

# ===================================================================
# Funciones de cálculo de homogeneidad (necesarias para Etapa 3)
# ===================================================================

F_TABLE <- data.frame(
  g  = 7:20,
  f1 = c(2.10, 2.01, 1.94, 1.88, 1.83, 1.79, 1.75, 1.72,
         1.69, 1.67, 1.64, 1.62, 1.60, 1.59),
  f2 = c(1.43, 1.25, 1.11, 1.01, 0.93, 0.86, 0.80, 0.75,
         0.71, 0.68, 0.64, 0.62, 0.59, 0.57)
)

calc_homogeneity_separate <- function(wide_df) {
  sample_cols <- grep("^sample_\\d+$", names(wide_df), value = TRUE)
  sample_data <- as.matrix(wide_df[, sample_cols, drop = FALSE])

  g <- nrow(sample_data)
  m <- ncol(sample_data)

  if (g < 2) return(list(error = "Se necesitan al menos 2 muestras."))

  sample_means <- rowMeans(sample_data, na.rm = TRUE)
  general_mean_homog <- mean(sample_data, na.rm = TRUE)
  x_pt <- stats::median(sample_data[, 1], na.rm = TRUE)

  s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)

  if (m == 2) {
    range_btw <- abs(sample_data[, 1] - sample_data[, 2])
    sw <- sqrt(sum(range_btw^2) / (2 * g))
  } else {
    within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(mean(within_vars, na.rm = TRUE))
  }

  sw_sq <- sw^2
  ss_sq <- abs(s_x_bar_sq - sw_sq / m)
  ss <- sqrt(ss_sq)

  abs_diff_from_xpt <- abs(sample_data[, 2] - x_pt)
  sigma_pt <- stats::median(abs_diff_from_xpt, na.rm = TRUE)
  MADe <- 1.483 * sigma_pt

  u_sigma_pt <- 1.25 * MADe / sqrt(g)

  qs <- stats::quantile(sample_data[, 1], probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  IQR_val <- unname(qs[2]) - unname(qs[1])
  nIQR <- 0.7413 * IQR_val

  list(
    g = g, m = m, general_mean_homog = general_mean_homog,
    x_pt = x_pt, s_x_bar_sq = s_x_bar_sq, s_xt = s_xt,
    sw = sw, sw_sq = sw_sq, ss_sq = ss_sq, ss = ss,
    sigma_pt = sigma_pt, MADe = MADe, u_sigma_pt = u_sigma_pt,
    nIQR = nIQR, error = NULL
  )
}

# ===================================================================
# Función de cálculo de estabilidad
# ===================================================================

calc_stability <- function(wide_stab, wide_hom) {

  # --- Cálculos de homogeneidad primero ---
  hom <- calc_homogeneity_separate(wide_hom)
  if (!is.null(hom$error)) return(list(error = paste("Error homogeneidad:", hom$error)))

  # --- ANOVA de estabilidad ---
  sample_cols_stab <- grep("^sample_\\d+$", names(wide_stab), value = TRUE)
  stab_matrix <- as.matrix(wide_stab[, sample_cols_stab, drop = FALSE])

  g_stab <- nrow(stab_matrix)
  m_stab <- ncol(stab_matrix)

  if (g_stab < 2) return(list(error = "Se necesitan al menos 2 muestras de estabilidad."))
  if (m_stab < 2) return(list(error = "Se necesitan al menos 2 replicas de estabilidad."))

  # Medias por muestra (estabilidad)
  stab_sample_means <- rowMeans(stab_matrix, na.rm = TRUE)

  # Media general de estabilidad: mean de TODOS los valores
  general_mean_stab <- mean(stab_matrix, na.rm = TRUE)

  # x_pt_stab: mediana de la primera réplica de estabilidad
  x_pt_stab <- stats::median(stab_matrix[, 1], na.rm = TRUE)

  # Varianza de medias muestrales de estabilidad
  s_x_bar_sq_stab <- stats::var(stab_sample_means, na.rm = TRUE)
  s_xt_stab <- sqrt(s_x_bar_sq_stab)

  # sw_stab: DE intra-muestra (rango para m=2)
  if (m_stab == 2) {
    range_btw_stab <- abs(stab_matrix[, 1] - stab_matrix[, 2])
    sw_stab <- sqrt(sum(range_btw_stab^2) / (2 * g_stab))
  } else {
    within_vars_stab <- apply(stab_matrix, 1, stats::var, na.rm = TRUE)
    sw_stab <- sqrt(mean(within_vars_stab, na.rm = TRUE))
  }

  sw_sq_stab <- sw_stab^2

  # ss_stab: DE entre-muestras de estabilidad
  ss_sq_stab <- abs(s_x_bar_sq_stab - sw_sq_stab / m_stab)
  ss_stab <- sqrt(ss_sq_stab)

  # --- Dmax = |media_estab - media_hom| ---
  diff_hom_stab <- abs(general_mean_stab - hom$general_mean_homog)

  # --- Criterios usando MADe y nIQR de HOMOGENEIDAD ---
  c_stab_MADe <- 0.3 * hom$MADe
  c_stab_nIQR  <- 0.3 * hom$nIQR

  # --- Incertidumbres de las medias ---
  # u_hom_mean: SD de todos los valores de homogeneidad / sqrt(n)
  sample_cols_hom <- grep("^sample_\\d+$", names(wide_hom), value = TRUE)
  hom_values <- as.numeric(unlist(wide_hom[, sample_cols_hom]))
  hom_values <- hom_values[!is.na(hom_values)]
  n_hom <- length(hom_values)
  u_hom_mean <- sd(hom_values) / sqrt(n_hom)

  # u_stab_mean: SD de todos los valores de estabilidad / sqrt(n)
  stab_values <- as.numeric(unlist(wide_stab[, sample_cols_stab]))
  stab_values <- stab_values[!is.na(stab_values)]
  n_stab <- length(stab_values)
  u_stab_mean <- sd(stab_values) / sqrt(n_stab)

  # --- Criterios expandidos ---
  c_stab_exp_MADe <- c_stab_MADe + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
  c_stab_exp_nIQR  <- c_stab_nIQR  + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)

  # --- u_stab para cadena de incertidumbre ---
  # Si Dmax ≤ c_stab → u_stab = 0; si no → u_stab = Dmax / sqrt(3)
  if (diff_hom_stab <= c_stab_MADe) {
    u_stab <- 0
  } else {
    u_stab <- diff_hom_stab / sqrt(3)
  }

  # --- Evaluaciones ---
  Dmax_vs_c_MADe <- if (diff_hom_stab <= c_stab_MADe) "CUMPLE" else "NO_CUMPLE"
  Dmax_vs_c_nIQR <- if (!is.na(hom$nIQR) && hom$nIQR > 0) {
    if (diff_hom_stab <= c_stab_nIQR) "CUMPLE" else "NO_CUMPLE"
  } else "N/A"

  Dmax_vs_exp_MADe <- if (diff_hom_stab <= c_stab_exp_MADe) "CUMPLE" else "NO_CUMPLE"
  Dmax_vs_exp_nIQR <- if (!is.na(hom$nIQR) && hom$nIQR > 0) {
    if (diff_hom_stab <= c_stab_exp_nIQR) "CUMPLE" else "NO_CUMPLE"
  } else "N/A"

  list(
    g_stab = g_stab, m_stab = m_stab,
    general_mean_stab = general_mean_stab,
    x_pt_stab = x_pt_stab,
    s_x_bar_sq_stab = s_x_bar_sq_stab, s_xt_stab = s_xt_stab,
    sw_stab = sw_stab, sw_sq_stab = sw_sq_stab,
    ss_sq_stab = ss_sq_stab, ss_stab = ss_stab,
    media_hom = hom$general_mean_homog,
    media_stab = general_mean_stab,
    diff_hom_stab = diff_hom_stab,
    hom_MADe = hom$MADe,
    hom_nIQR = hom$nIQR,
    hom_ss = hom$ss,
    c_stab_MADe = c_stab_MADe,
    c_stab_nIQR = c_stab_nIQR,
    u_hom_mean = u_hom_mean,
    u_stab_mean = u_stab_mean,
    n_hom = n_hom,
    n_stab = n_stab,
    c_stab_exp_MADe = c_stab_exp_MADe,
    c_stab_exp_nIQR = c_stab_exp_nIQR,
    u_stab = u_stab,
    Dmax_vs_c_MADe = Dmax_vs_c_MADe,
    Dmax_vs_c_nIQR = Dmax_vs_c_nIQR,
    Dmax_vs_exp_MADe = Dmax_vs_exp_MADe,
    Dmax_vs_exp_nIQR = Dmax_vs_exp_nIQR,
    error = NULL
  )
}

# ===================================================================
# Ejecutar para O3 × 3 niveles
# ===================================================================

run_stage_03 <- function() {
  cat("Etapa 3: Estabilidad — INICIO\n")
  cat("  Datos homogeneidad:", DATA_HOMOGENEITY, "\n")
  cat("  Datos estabilidad:", DATA_STABILITY, "\n")
  cat("  Combos: O3 × 3 niveles\n\n")

  all_results <- list()

  for (combo in COMBOS) {
    combo_id <- make_combo_id(combo$pollutant, combo$level)
    cat("  Procesando:", combo$label, "\n")

    # Cargar datos en formato ancho
    wide_hom <- load_wide_data(DATA_HOMOGENEITY, combo$pollutant, combo$level)
    wide_stab <- load_wide_data(DATA_STABILITY, combo$pollutant, combo$level)

    if (nrow(wide_hom) < 2 || nrow(wide_stab) < 2) {
      cat("    ADVERTENCIA: datos insuficientes, saltando\n")
      all_results[[paste0(combo_id, "_error")]] <- list(
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        stage = "03_stability", section = "stability",
        metric = "insufficient_data", r_value = NA_real_, python_value = NA_real_,
        app_value = NA_real_, diff_r_python = NA_real_,
        diff_app_r = NA_real_, diff_app_python = NA_real_,
        status = "EDGE_CASE", tolerance = 1e-9, notes = "Less than 2 samples"
      )
      next
    }

    # --- Cálculo propio ---
    stab <- calc_stability(wide_stab, wide_hom)
    if (!is.null(stab$error)) {
      cat("    ERROR:", stab$error, "\n")
      next
    }

    # --- Comparación con ptcalc ---
    sample_cols_stab <- grep("^sample_\\d+$", names(wide_stab), value = TRUE)
    stab_matrix <- as.matrix(wide_stab[, sample_cols_stab, drop = FALSE])

    sample_cols_hom <- grep("^sample_\\d+$", names(wide_hom), value = TRUE)
    hom_matrix <- as.matrix(wide_hom[, sample_cols_hom, drop = FALSE])
    hom_general_mean <- mean(hom_matrix, na.rm = TRUE)
    hom_x_pt <- stats::median(hom_matrix[, 1], na.rm = TRUE)
    hom_sigma_pt <- stats::median(abs(hom_matrix[, 2] - hom_x_pt), na.rm = TRUE)

    ptcalc_stab <- calculate_stability_stats(
      stab_sample_data = stab_matrix,
      hom_general_mean_homog = hom_general_mean,
      hom_stab_x_pt = hom_x_pt,
      hom_stab_sigma_pt = hom_sigma_pt
    )

    cat("    g_stab=", stab$g_stab, " m_stab=", stab$m_stab,
        " mean_stab=", signif(stab$general_mean_stab, 8),
        " mean_hom=", signif(stab$media_hom, 8),
        " Dmax=", signif(stab$diff_hom_stab, 8),
        " c_stab_MADe=", signif(stab$c_stab_MADe, 8), "\n")

    # Verificar diff_hom_stab contra ptcalc
    diff_Dmax <- abs(stab$diff_hom_stab - ptcalc_stab$diff_hom_stab)
    diff_mean_stab <- abs(stab$general_mean_stab - ptcalc_stab$general_mean)
    diff_sw <- abs(stab$sw_stab - ptcalc_stab$sw)
    diff_ss <- abs(stab$ss_stab - ptcalc_stab$ss)
    cat("    ptcalc diff: Dmax=", signif(diff_Dmax, 12),
        " mean_stab=", signif(diff_mean_stab, 12),
        " sw_stab=", signif(diff_sw, 12),
        " ss_stab=", signif(diff_ss, 12), "\n")

    # Construir resultados canónicos
    metrics <- list(
      list(metric = "g_stab",              r_value = as.numeric(stab$g_stab)),
      list(metric = "m_stab",              r_value = as.numeric(stab$m_stab)),
      list(metric = "general_mean_stab",    r_value = stab$general_mean_stab),
      list(metric = "x_pt_stab",            r_value = stab$x_pt_stab),
      list(metric = "s_x_bar_sq_stab",      r_value = stab$s_x_bar_sq_stab),
      list(metric = "s_xt_stab",            r_value = stab$s_xt_stab),
      list(metric = "sw_stab",              r_value = stab$sw_stab),
      list(metric = "sw_sq_stab",           r_value = stab$sw_sq_stab),
      list(metric = "ss_sq_stab",           r_value = stab$ss_sq_stab),
      list(metric = "ss_stab",              r_value = stab$ss_stab),
      list(metric = "media_hom",            r_value = stab$media_hom),
      list(metric = "media_stab",           r_value = stab$media_stab),
      list(metric = "diff_hom_stab",        r_value = stab$diff_hom_stab),
      list(metric = "hom_MADe",             r_value = stab$hom_MADe),
      list(metric = "hom_nIQR",             r_value = stab$hom_nIQR),
      list(metric = "c_stab_MADe",          r_value = stab$c_stab_MADe),
      list(metric = "c_stab_nIQR",          r_value = stab$c_stab_nIQR),
      list(metric = "u_hom_mean",           r_value = stab$u_hom_mean),
      list(metric = "u_stab_mean",          r_value = stab$u_stab_mean),
      list(metric = "c_stab_exp_MADe",      r_value = stab$c_stab_exp_MADe),
      list(metric = "c_stab_exp_nIQR",      r_value = stab$c_stab_exp_nIQR),
      list(metric = "u_stab",               r_value = stab$u_stab)
    )

    for (m_entry in metrics) {
      tol <- if (m_entry$metric %in% c("g_stab", "m_stab")) 0.5 else 1e-9
      all_results[[paste0(combo_id, "_", m_entry$metric)]] <- list(
        combo_id = combo_id,
        pollutant = combo$pollutant,
        level = combo$level,
        stage = "03_stability",
        section = "stability",
        metric = m_entry$metric,
        r_value = m_entry$r_value,
        python_value = NA_real_,
        app_value = NA_real_,
        diff_r_python = NA_real_,
        diff_app_r = NA_real_,
        diff_app_python = NA_real_,
        status = "PENDING_PYTHON",
        tolerance = tol,
        notes = ""
      )
    }

    # Evaluaciones cualitativas
    evaluations <- list(
      list(metric = "Dmax_vs_c_MADe",    eval_val = stab$Dmax_vs_c_MADe,
           notes = paste0("Dmax=", signif(stab$diff_hom_stab, 6),
                          " c_MADe=", signif(stab$c_stab_MADe, 6))),
      list(metric = "Dmax_vs_c_nIQR",    eval_val = stab$Dmax_vs_c_nIQR,
           notes = paste0("Dmax=", signif(stab$diff_hom_stab, 6),
                          " c_nIQR=", signif(stab$c_stab_nIQR, 6))),
      list(metric = "Dmax_vs_exp_MADe",  eval_val = stab$Dmax_vs_exp_MADe,
           notes = paste0("Dmax=", signif(stab$diff_hom_stab, 6),
                          " c_exp_MADe=", signif(stab$c_stab_exp_MADe, 6))),
      list(metric = "Dmax_vs_exp_nIQR",  eval_val = stab$Dmax_vs_exp_nIQR,
           notes = paste0("Dmax=", signif(stab$diff_hom_stab, 6),
                          " c_exp_nIQR=", signif(stab$c_stab_exp_nIQR, 6)))
    )

    for (ev in evaluations) {
      all_results[[paste0(combo_id, "_", ev$metric)]] <- list(
        combo_id = combo_id,
        pollutant = combo$pollutant,
        level = combo$level,
        stage = "03_stability",
        section = "evaluation",
        metric = ev$metric,
        r_value = NA_real_,
        python_value = NA_real_,
        app_value = NA_real_,
        diff_r_python = NA_real_,
        diff_app_r = NA_real_,
        diff_app_python = NA_real_,
        status = ev$eval_val,
        tolerance = NA_real_,
        notes = ev$notes
      )
    }
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

  cat("\nEtapa 3: Estabilidad (R) — FIN\n")

  invisible(all_results)
}

if (sys.nframe() == 0) {
  run_stage_03()
}