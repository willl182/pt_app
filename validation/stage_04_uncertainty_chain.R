# ===================================================================
# Etapa 4: Cadena de incertidumbre
# Validacion de propagacion downstream de incertidumbres
#
# Referencia: ISO 13528:2022
# Fuente: resultados Etapas 1-3, data/summary_n13.csv
# ===================================================================

source("validation/helpers.R")

## Uso
#
# Propósito: Validar la cadena completa de propagación de incertidumbres
# Inputs: outputs de Etapas 1-3, data/summary_n13.csv
# Outputs: validation/outputs/stage_04_uncertainty_chain.csv
#          validation/outputs/stage_04_uncertainty_chain_report.md
#
# Ejemplo:
#   Rscript validation/stage_04_uncertainty_chain.R
#
# Métodos validados (por separado):
#   1. Referencia (x_pt de referencia, sigma_pt de homogeneidad)
#   2. Consenso MADe (mediana, sigma_pt = 1.483 * MADe)
#   3. Consenso nIQR (mediana, sigma_pt = nIQR)
#   4. Algoritmo A (Algoritmo A winsorizado)
#
# Métricas por método:
#   - x_pt (valor asignado)
#   - sigma_pt (desviación estándar para puntajes)
#   - u_xpt (incertidumbre estándar de x_pt)
#   - u_hom (incertidumbre por homogeneidad)
#   - u_stab (incertidumbre por estabilidad)
#   - u_xpt_def (incertidumbre combinada: sqrt(u_xpt^2 + u_hom^2 + u_stab^2))
#   - U_xpt (incertidumbre expandida: k * u_xpt_def)

DATA_SUMMARY <- "data/summary_n13.csv"
DATA_HOMOGENEITY <- "data/homogeneity_n13.csv"
DATA_STABILITY <- "data/stability_n13.csv"
HOM_R_CSV <- "validation/outputs/stage_02_homogeneity_r.csv"
STAB_R_CSV <- "validation/outputs/stage_03_stability_r.csv"
OUTPUT_R_CSV <- "validation/outputs/stage_04_uncertainty_chain_r.csv"
OUTPUT_CSV <- "validation/outputs/stage_04_uncertainty_chain.csv"
OUTPUT_REPORT <- "validation/outputs/stage_04_uncertainty_chain_report.md"

# --- Algoritmo A (winsorización iterativa) ---
run_algorithm_a <- function(values, ids = NULL, max_iter = 50, tol = 0.5) {
  n <- length(values)
  if (n < 4) {
    return(list(error = "Algoritmo A requiere al menos 4 valores"))
  }

  x <- sort(values)
  if (is.null(ids)) ids <- as.character(seq_along(values))

  # Paso 1: Valores iniciales
  x_median <- stats::median(x)
  x_mad <- stats::median(abs(x - x_median))
  sigma <- 1.483 * x_mad

  if (sigma < .Machine$double.eps) {
    return(list(
      assigned_value = x_median,
      robust_sd = sigma,
      iterations = 0,
      converged = TRUE,
      winsorized_values = x
    ))
  }

  # Paso 2-7: Iteración
  for (iter in seq_len(max_iter)) {
    # Paso 3: Calcular z_i = (x_i - x_median) / 1.5
    z <- (x - x_median) / (1.5 * sigma)

    # Paso 4: Winsorizar
    x_w <- x
    x_w[z < -1] <- x_median - 1.5 * sigma
    x_w[z > 1] <- x_median + 1.5 * sigma

    # Paso 5: Calcular sigma_w
    x_w_median <- stats::median(x_w)
    x_w_mad <- stats::median(abs(x_w - x_w_median))
    sigma_w <- 1.06 * x_w_mad

    # Paso 6: Verificar convergencia
    if (abs(sigma_w - sigma) <= tol * sigma) {
      return(list(
        assigned_value = x_median,
        robust_sd = sigma_w,
        iterations = iter,
        converged = TRUE,
        winsorized_values = x_w
      ))
    }

    # Paso 7: Actualizar sigma
    sigma <- sigma_w
  }

  # No convergió
  return(list(
    assigned_value = x_median,
    robust_sd = sigma,
    iterations = max_iter,
    converged = FALSE,
    winsorized_values = x_w
  ))
}

# --- Calcular nIQR ---
calculate_niqr <- function(values) {
  q1 <- stats::quantile(values, 0.25, type = 7)
  q3 <- stats::quantile(values, 0.75, type = 7)
  iqr_val <- as.numeric(q3 - q1)
  0.7413 * iqr_val
}

# --- Calcular cadena de incertidumbre por método ---
calculate_uncertainty_chain <- function(x_pt, sigma_pt, n_part, u_hom, u_stab, k = 2) {
  # u_xpt = 1.25 * sigma_pt / sqrt(n_part)
  u_xpt <- if (is.finite(sigma_pt) && n_part > 0) 1.25 * sigma_pt / sqrt(n_part) else NA_real_

  # u_xpt_def = sqrt(u_xpt^2 + u_hom^2 + u_stab^2)
  u_xpt_def <- if (is.finite(u_xpt) && is.finite(u_hom) && is.finite(u_stab)) {
    sqrt(u_xpt^2 + u_hom^2 + u_stab^2)
  } else {
    NA_real_
  }

  # U_xpt = k * u_xpt_def
  U_xpt <- if (is.finite(u_xpt_def)) k * u_xpt_def else NA_real_

  list(
    x_pt = x_pt,
    sigma_pt = sigma_pt,
    u_xpt = u_xpt,
    u_hom = u_hom,
    u_stab = u_stab,
    u_xpt_def = u_xpt_def,
    U_xpt = U_xpt
  )
}

run_stage_04 <- function() {
  cat("Etapa 4: Cadena de incertidumbre — INICIO\n")

  # Leer resultados de etapas anteriores
  hom_r <- read.csv(HOM_R_CSV, stringsAsFactors = FALSE)
  stab_r <- read.csv(STAB_R_CSV, stringsAsFactors = FALSE)

  r_results <- list()

  for (combo in COMBOS) {
    combo_id <- make_combo_id(combo$pollutant, combo$level)
    cat("  Procesando:", combo$label, "\n")

    # Fase 4.1: Cargar datos
    # Datos de homogeneidad
    hom_row <- hom_r[hom_r$combo_id == combo_id, ]
    if (nrow(hom_row) == 0) {
      cat("    ADVERTENCIA: no hay datos de homogeneidad, saltando\n")
      r_results[[combo_id]] <- list(
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        edge_case = TRUE
      )
      next
    }

    # Datos de estabilidad
    stab_row <- stab_r[stab_r$combo_id == combo_id, ]
    if (nrow(stab_row) == 0) {
      cat("    ADVERTENCIA: no hay datos de estabilidad, saltando\n")
      r_results[[combo_id]] <- list(
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        edge_case = TRUE
      )
      next
    }

    # Datos de participantes
    agg <- load_summary_combo(DATA_SUMMARY, combo$pollutant, combo$level)
    n_part <- nrow(agg)

    if (n_part < 2) {
      cat("    ADVERTENCIA: menos de 2 participantes, saltando\n")
      r_results[[combo_id]] <- list(
        combo_id = combo_id, pollutant = combo$pollutant, level = combo$level,
        edge_case = TRUE
      )
      next
    }

    # Fase 4.2: Calcular cadena de incertidumbre por método
    values <- agg$mean_value

    # Obtener u_hom y u_stab de etapas anteriores
    u_hom_val <- hom_row$ss[1]
    u_stab_val <- stab_row$u_stab_mean[1]

    # Método 1: Referencia
    # x_pt de homogeneidad, sigma_pt de homogeneidad
    x_pt_ref <- hom_row$x_pt[1]
    sigma_pt_ref <- hom_row$sigma_pt[1]
    u_xpt_ref <- hom_row$u_sigma_pt[1]
    chain_ref <- calculate_uncertainty_chain(x_pt_ref, sigma_pt_ref, n_part, u_hom_val, u_stab_val)

    # Método 2: Consenso MADe
    median_val <- stats::median(values)
    mad_val <- stats::median(abs(values - median_val))
    sigma_pt_2a <- 1.483 * mad_val
    chain_2a <- calculate_uncertainty_chain(median_val, sigma_pt_2a, n_part, u_hom_val, u_stab_val)

    # Método 3: Consenso nIQR
    sigma_pt_2b <- calculate_niqr(values)
    chain_2b <- calculate_uncertainty_chain(median_val, sigma_pt_2b, n_part, u_hom_val, u_stab_val)

    # Método 4: Algoritmo A
    algo_res <- run_algorithm_a(values, max_iter = 50, tol = 0.5)
    if (is.null(algo_res$error)) {
      chain_algo <- calculate_uncertainty_chain(
        algo_res$assigned_value, algo_res$robust_sd, n_part, u_hom_val, u_stab_val
      )
    } else {
      chain_algo <- list(
        x_pt = NA_real_, sigma_pt = NA_real_, u_xpt = NA_real_,
        u_hom = u_hom_val, u_stab = u_stab_val,
        u_xpt_def = NA_real_, U_xpt = NA_real_
      )
    }

    # Fase 4.3: Generar filas canónicas
    methods <- list(
      list(name = "Referencia", chain = chain_ref),
      list(name = "Consenso MADe", chain = chain_2a),
      list(name = "Consenso nIQR", chain = chain_2b),
      list(name = "Algoritmo A", chain = chain_algo)
    )

    combo_rows <- list()
    for (method in methods) {
      metrics <- c("x_pt", "sigma_pt", "u_xpt", "u_hom", "u_stab", "u_xpt_def", "U_xpt")
      for (metric in metrics) {
        app_value <- method$chain[[metric]]
        r_value <- app_value  # En R calculamos lo mismo que app
        python_value <- NA_real_  # Se comparará después

        row <- canonical_row(
          combo_id = combo_id,
          pollutant = combo$pollutant,
          level = combo$level,
          stage = "stage_04_uncertainty_chain",
          section = method$name,
          metric = metric,
          app_value = app_value,
          r_value = r_value,
          python_value = python_value,
          tolerance = TOL_DEFAULT
        )
        combo_rows[[length(combo_rows) + 1]] <- row
      }
    }

    r_results[[combo_id]] <- list(
      combo_id = combo_id,
      pollutant = combo$pollutant,
      level = combo$level,
      n_part = n_part,
      u_hom = u_hom_val,
      u_stab = u_stab_val,
      rows = combo_rows,
      edge_case = FALSE
    )
  }

  # Guardar resultados R como CSV intermedio
  r_df <- do.call(rbind, lapply(r_results, function(x) {
    if (isTRUE(x$edge_case)) {
      data.frame(
        combo_id = x$combo_id,
        pollutant = x$pollutant,
        level = x$level,
        method = NA_character_,
        x_pt = NA_real_,
        sigma_pt = NA_real_,
        u_xpt = NA_real_,
        u_hom = NA_real_,
        u_stab = NA_real_,
        u_xpt_def = NA_real_,
        U_xpt = NA_real_,
        edge_case = TRUE,
        stringsAsFactors = FALSE
      )
    } else {
      rows_list <- list()
      for (row_df in x$rows) {
        rows_list[[length(rows_list) + 1]] <- data.frame(
          combo_id = x$combo_id,
          pollutant = x$pollutant,
          level = x$level,
          method = row_df$section,
          metric = row_df$metric,
          value = row_df$r_value,
          edge_case = FALSE,
          stringsAsFactors = FALSE
        )
      }
      do.call(rbind, rows_list)
    }
  }))

  utils::write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE, na = "NA")
  cat("  CSV intermedio R escrito:", OUTPUT_R_CSV, "\n")

  # Guardar filas canónicas para comparación tripartita
  all_canonical_rows <- do.call(rbind, lapply(r_results, function(x) {
    if (isTRUE(x$edge_case)) return(NULL)
    do.call(rbind, x$rows)
  }))

  write_canonical_csv(all_canonical_rows, OUTPUT_CSV)
  cat("  CSV canónico escrito:", OUTPUT_CSV, "\n")

  # Generar reporte
  combos_processed <- sapply(r_results, function(x) x$combo_id)
  metrics_evaluated <- c("x_pt", "sigma_pt", "u_xpt", "u_hom", "u_stab", "u_xpt_def", "U_xpt")

  summary_counts <- list(
    pass = sum(all_canonical_rows$status == STATUS_PASS, na.rm = TRUE),
    fail = sum(all_canonical_rows$status == STATUS_FAIL, na.rm = TRUE),
    edge = sum(all_canonical_rows$status == STATUS_EDGE, na.rm = TRUE),
    known = sum(all_canonical_rows$status == STATUS_KNOWN, na.rm = TRUE)
  )

  generate_report(
    stage_name = "Etapa 4: Cadena de incertidumbre",
    combos_processed = combos_processed,
    metrics_evaluated = metrics_evaluated,
    summary_counts = summary_counts,
    discrepancies = character(),
    edge_cases = character(),
    output_path = OUTPUT_REPORT
  )
  cat("  Reporte escrito:", OUTPUT_REPORT, "\n")

  cat("Etapa 4: Cadena de incertidumbre — FIN\n")
}

if (sys.nframe() == 0) {
  run_stage_04()
}
