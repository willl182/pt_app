# ===================================================================
# Etapa 2: Homogeneidad
# Validacion de evaluacion de homogeneidad
#
# Referencia: ISO 13528:2022, Seccion 9.2
# Fuente: data/homogeneity_n13.csv
# ===================================================================

source("validation/helpers.R")

## Uso
#
# Proposito: Validar calculo de homogeneidad y criterios asociados
# Inputs: data/homogeneity_n13.csv
# Outputs: validation/outputs/stage_02_homogeneity_r.csv (intermedio)
#
# Ejemplo:
#   Rscript validation/stage_02_homogeneity.R
#
# Metricas validadas (12 por combo):
#   g, m, general_mean_homog, x_pt, s_x_bar_sq, sw, ss_sq, ss,
#   sigma_pt, MADe, u_sigma_pt, criterio_c, criterio_expandido

DATA_HOMOGENEITY <- "data/homogeneity_n13.csv"
OUTPUT_R_CSV <- "validation/outputs/stage_02_homogeneity_r.csv"

# --- Tabla F1/F2 para criterio expandido (3 args) ---
F_TABLE <- data.frame(
  g = 7:20,
  f1 = c(2.10, 2.01, 1.94, 1.88, 1.83, 1.79, 1.75, 1.72,
         1.69, 1.67, 1.64, 1.62, 1.60, 1.59),
  f2 = c(1.43, 1.25, 1.11, 1.01, 0.93, 0.86, 0.80, 0.75,
         0.71, 0.68, 0.64, 0.62, 0.59, 0.57)
)

calc_criterion_expanded <- function(sigma_pt, sw, g) {
  g_clamped <- max(7, min(20, g))
  idx <- which(F_TABLE$g == g_clamped)
  f1 <- F_TABLE$f1[idx]
  f2 <- F_TABLE$f2[idx]
  f1 * (0.3 * sigma_pt)^2 + f2 * sw^2
}

run_stage_02 <- function() {
  cat("Etapa 2: Homogeneidad — INICIO\n")

  r_results <- list()

  for (combo in COMBOS) {
    combo_id <- make_combo_id(combo$pollutant, combo$level)
    cat("  Procesando:", combo$label, "\n")

    # Fase 2.1: Cargar datos en formato ancho
    wide <- load_wide_data(DATA_HOMOGENEITY, combo$pollutant, combo$level)

    if (nrow(wide) < 2) {
      cat("    ADVERTENCIA: menos de 2 muestras, saltando\n")
      r_results[[combo_id]] <- list(
        combo_id = combo_id,
        pollutant = combo$pollutant,
        level = combo$level,
        g = nrow(wide),
        m = NA_integer_,
        general_mean_homog = NA_real_,
        x_pt = NA_real_,
        s_x_bar_sq = NA_real_,
        sw = NA_real_,
        ss_sq = NA_real_,
        ss = NA_real_,
        sigma_pt = NA_real_,
        MADe = NA_real_,
        u_sigma_pt = NA_real_,
        criterio_c = NA_real_,
        criterio_expandido = NA_real_,
        edge_case = TRUE
      )
      next
    }

    # Seleccionar solo columnas sample_* -> matriz g x m
    sample_cols <- grep("^sample_\\d+$", names(wide), value = TRUE)
    sample_data <- as.matrix(wide[, sample_cols, drop = FALSE])

    g <- nrow(sample_data)
    m <- ncol(sample_data)

    if (m < 2) {
      cat("    ADVERTENCIA: menos de 2 replicas, saltando\n")
      r_results[[combo_id]] <- list(
        combo_id = combo_id,
        pollutant = combo$pollutant,
        level = combo$level,
        g = g,
        m = m,
        general_mean_homog = NA_real_,
        x_pt = NA_real_,
        s_x_bar_sq = NA_real_,
        sw = NA_real_,
        ss_sq = NA_real_,
        ss = NA_real_,
        sigma_pt = NA_real_,
        MADe = NA_real_,
        u_sigma_pt = NA_real_,
        criterio_c = NA_real_,
        criterio_expandido = NA_real_,
        edge_case = TRUE
      )
      next
    }

    # Fase 2.2: Calcular 12 metricas de homogeneidad
    sample_means <- rowMeans(sample_data, na.rm = TRUE)
    general_mean_homog <- mean(sample_data, na.rm = TRUE)
    x_pt <- stats::median(sample_data[, 1], na.rm = TRUE)
    s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)

    # sw: DE intra-muestra
    if (m == 2) {
      range_btw <- abs(sample_data[, 1] - sample_data[, 2])
      sw <- sqrt(sum(range_btw^2) / (2 * g))
    } else {
      within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
      sw <- sqrt(mean(within_vars, na.rm = TRUE))
    }

    sw_sq <- sw^2

    # ss_sq = abs(s_x_bar_sq - sw_sq/m) — usar abs() como ptcalc
    ss_sq <- abs(s_x_bar_sq - sw_sq / m)
    ss <- sqrt(ss_sq)

    # sigma_pt = median(|sample_2 - x_pt|)
    abs_diff_from_xpt <- abs(sample_data[, 2] - x_pt)
    sigma_pt <- stats::median(abs_diff_from_xpt, na.rm = TRUE)

    # MADe = 1.483 * sigma_pt
    MADe <- 1.483 * sigma_pt

    # u_sigma_pt = 1.25 * MADe / sqrt(g)
    u_sigma_pt <- 1.25 * MADe / sqrt(g)

    # Criterio c = 0.3 * sigma_pt
    criterio_c <- 0.3 * sigma_pt

    # Criterio expandido (3 args, tabla F1/F2)
    criterio_exp <- calc_criterion_expanded(sigma_pt, sw, g)

    r_results[[combo_id]] <- list(
      combo_id = combo_id,
      pollutant = combo$pollutant,
      level = combo$level,
      g = g,
      m = m,
      general_mean_homog = general_mean_homog,
      x_pt = x_pt,
      s_x_bar_sq = s_x_bar_sq,
      sw = sw,
      ss_sq = ss_sq,
      ss = ss,
      sigma_pt = sigma_pt,
      MADe = MADe,
      u_sigma_pt = u_sigma_pt,
      criterio_c = criterio_c,
      criterio_expandido = criterio_exp,
      edge_case = FALSE
    )

    cat("    g=", g, " m=", m,
        " x_pt=", round(x_pt, 8),
        " sw=", round(sw, 8),
        " ss=", round(ss, 8),
        " sigma_pt=", round(sigma_pt, 8), "\n")
  }

  # Guardar resultados R como CSV intermedio
  r_df <- do.call(rbind, lapply(r_results, function(x) {
    data.frame(
      combo_id = x$combo_id,
      pollutant = x$pollutant,
      level = x$level,
      g = x$g,
      m = x$m,
      general_mean_homog = x$general_mean_homog,
      x_pt = x$x_pt,
      s_x_bar_sq = x$s_x_bar_sq,
      sw = x$sw,
      ss_sq = x$ss_sq,
      ss = x$ss,
      sigma_pt = x$sigma_pt,
      MADe = x$MADe,
      u_sigma_pt = x$u_sigma_pt,
      criterio_c = x$criterio_c,
      criterio_expandido = x$criterio_expandido,
      edge_case = x$edge_case,
      stringsAsFactors = FALSE
    )
  }))
  rownames(r_df) <- NULL
  utils::write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE)
  cat("  Resultados R guardados:", OUTPUT_R_CSV, "\n")

  cat("Etapa 2: Homogeneidad (R) — FIN\n")

  invisible(r_results)
}

if (sys.nframe() == 0) {
  run_stage_02()
}
