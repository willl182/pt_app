# ===================================================================
# Etapa 3: Estabilidad
# Validacion de evaluacion de estabilidad
#
# Referencia: ISO 13528:2022, Seccion 9.3
# Fuente: data/stability_n13.csv
# Dependencias: resultados de homogeneidad (Etapa 2)
# ===================================================================

source("validation/helpers.R")

## Uso
#
# Proposito: Validar calculo de estabilidad y criterios asociados
# Inputs: data/stability_n13.csv, data/homogeneity_n13.csv
# Outputs: validation/outputs/stage_03_stability_r.csv (intermedio)
#
# Ejemplo:
#   Rscript validation/stage_03_stability.R
#
# Metricas validadas (13 por combo):
#   g, m, general_mean_stab, x_pt_stab, s_x_bar_sq_stab, sw_stab,
#   ss_sq_stab, ss_stab, diff_hom_stab, u_hom_mean, u_stab_mean,
#   criterio_simple, criterio_expandido

DATA_STABILITY <- "data/stability_n13.csv"
DATA_HOMOGENEITY <- "data/homogeneity_n13.csv"
HOM_R_CSV <- "validation/outputs/stage_02_homogeneity_r.csv"
OUTPUT_R_CSV <- "validation/outputs/stage_03_stability_r.csv"

# --- Funciones auxiliares ---

# Cargar todos los valores de homogeneidad para un combo (para u_hom_mean)
load_hom_all_values <- function(pollutant, level) {
  df <- read.csv(DATA_HOMOGENEITY, stringsAsFactors = FALSE)
  df <- df[df$pollutant == pollutant & df$level == level, ]
  df$value
}

run_stage_03 <- function() {
  cat("Etapa 3: Estabilidad — INICIO\n")

  # Leer resultados de homogeneidad (R)
  hom_r <- read.csv(HOM_R_CSV, stringsAsFactors = FALSE)

  r_results <- list()

  for (combo in COMBOS) {
    combo_id <- make_combo_id(combo$pollutant, combo$level)
    cat("  Procesando:", combo$label, "\n")

    # Fase 3.1: Cargar datos de estabilidad en formato ancho
    wide <- load_wide_data(DATA_STABILITY, combo$pollutant, combo$level)

    if (nrow(wide) < 2) {
      cat("    ADVERTENCIA: menos de 2 muestras, saltando\n")
      r_results[[combo_id]] <- list(
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        g = nrow(wide), m = NA_integer_,
        general_mean_stab = NA_real_, x_pt_stab = NA_real_,
        s_x_bar_sq_stab = NA_real_, sw_stab = NA_real_,
        ss_sq_stab = NA_real_, ss_stab = NA_real_,
        diff_hom_stab = NA_real_, u_hom_mean = NA_real_,
        u_stab_mean = NA_real_, criterio_simple = NA_real_,
        criterio_expandido = NA_real_, edge_case = TRUE
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
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        g = g, m = m,
        general_mean_stab = NA_real_, x_pt_stab = NA_real_,
        s_x_bar_sq_stab = NA_real_, sw_stab = NA_real_,
        ss_sq_stab = NA_real_, ss_stab = NA_real_,
        diff_hom_stab = NA_real_, u_hom_mean = NA_real_,
        u_stab_mean = NA_real_, criterio_simple = NA_real_,
        criterio_expandido = NA_real_, edge_case = TRUE
      )
      next
    }

    # Fase 3.2: Calcular metricas de estabilidad
    sample_means <- rowMeans(sample_data, na.rm = TRUE)
    general_mean_stab <- mean(sample_data, na.rm = TRUE)
    x_pt_stab <- stats::median(sample_data[, 1], na.rm = TRUE)
    s_x_bar_sq_stab <- stats::var(sample_means, na.rm = TRUE)

    # sw: DE intra-muestra
    if (m == 2) {
      range_btw <- abs(sample_data[, 1] - sample_data[, 2])
      sw_stab <- sqrt(sum(range_btw^2) / (2 * g))
    } else {
      within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
      sw_stab <- sqrt(mean(within_vars, na.rm = TRUE))
    }

    sw_sq_stab <- sw_stab^2

    # ss_sq = abs(s_x_bar_sq - sw_sq/m) — usar abs() como ptcalc
    ss_sq_stab <- abs(s_x_bar_sq_stab - sw_sq_stab / m)
    ss_stab <- sqrt(ss_sq_stab)

    # --- Datos de homogeneidad para este combo ---
    hom_combo <- hom_r[hom_r$combo_id == combo_id, ]
    if (nrow(hom_combo) == 0) {
      cat("    ADVERTENCIA: sin datos de homogeneidad, saltando\n")
      next
    }
    general_mean_homog <- hom_combo$general_mean_homog[1]
    x_pt_hom <- hom_combo$x_pt[1]
    sigma_pt_hom <- hom_combo$sigma_pt[1]

    # diff_hom_stab = abs(mean_stab - mean_hom)
    diff_hom_stab <- abs(general_mean_stab - general_mean_homog)

    # u_hom_mean = sd(all_hom_values) / sqrt(n_hom)
    hom_all_vals <- load_hom_all_values(combo$pollutant, combo$level)
    hom_all_vals <- hom_all_vals[is.finite(hom_all_vals)]
    n_hom <- length(hom_all_vals)
    u_hom_mean <- if (n_hom > 1) stats::sd(hom_all_vals) / sqrt(n_hom) else NA_real_

    # u_stab_mean = sd(all_stab_values) / sqrt(n_stab)
    stab_all_vals <- as.numeric(sample_data)
    stab_all_vals <- stab_all_vals[is.finite(stab_all_vals)]
    n_stab <- length(stab_all_vals)
    u_stab_mean <- if (n_stab > 1) stats::sd(stab_all_vals) / sqrt(n_stab) else NA_real_

    # criterio_simple = 0.3 * sigma_pt_hom
    criterio_simple <- 0.3 * sigma_pt_hom

    # criterio_expandido = c + 2*sqrt(u_hom_mean^2 + u_stab_mean^2)
    if (is.finite(u_hom_mean) && is.finite(u_stab_mean)) {
      criterio_exp <- criterio_simple + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
    } else {
      criterio_exp <- NA_real_
    }

    r_results[[combo_id]] <- list(
      combo_id = combo_id,
      pollutant = combo$pollutant,
      level = combo$level,
      g = g,
      m = m,
      general_mean_stab = general_mean_stab,
      x_pt_stab = x_pt_stab,
      s_x_bar_sq_stab = s_x_bar_sq_stab,
      sw_stab = sw_stab,
      ss_sq_stab = ss_sq_stab,
      ss_stab = ss_stab,
      diff_hom_stab = diff_hom_stab,
      u_hom_mean = u_hom_mean,
      u_stab_mean = u_stab_mean,
      criterio_simple = criterio_simple,
      criterio_expandido = criterio_exp,
      edge_case = FALSE
    )

    cat("    g=", g, " m=", m,
        " mean_stab=", round(general_mean_stab, 8),
        " diff=", round(diff_hom_stab, 8),
        " c=", round(criterio_simple, 8), "\n")
  }

  # Guardar resultados R como CSV intermedio
  r_df <- do.call(rbind, lapply(r_results, function(x) {
    data.frame(
      combo_id = x$combo_id,
      pollutant = x$pollutant,
      level = x$level,
      g = x$g,
      m = x$m,
      general_mean_stab = x$general_mean_stab,
      x_pt_stab = x$x_pt_stab,
      s_x_bar_sq_stab = x$s_x_bar_sq_stab,
      sw_stab = x$sw_stab,
      ss_sq_stab = x$ss_sq_stab,
      ss_stab = x$ss_stab,
      diff_hom_stab = x$diff_hom_stab,
      u_hom_mean = x$u_hom_mean,
      u_stab_mean = x$u_stab_mean,
      criterio_simple = x$criterio_simple,
      criterio_expandido = x$criterio_expandido,
      edge_case = x$edge_case,
      stringsAsFactors = FALSE
    )
  }))
  rownames(r_df) <- NULL
  utils::write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE)
  cat("  Resultados R guardados:", OUTPUT_R_CSV, "\n")

  cat("Etapa 3: Estabilidad (R) — FIN\n")

  invisible(r_results)
}

if (sys.nframe() == 0) {
  run_stage_03()
}
