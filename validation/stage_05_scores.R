# ===================================================================
# Etapa 5: Scores de Desempeño
# Validacion de scores por participante: z, z', zeta, En
#
# Referencia: ISO 13528:2022
# Fuente: data/summary_n13.csv, validation/outputs/stage_04_uncertainty_chain.csv
# ===================================================================
#
## Uso
#
# Propósito: Calcular scores de desempeño independientes en R
# Inputs:
#   data/summary_n13.csv
#   validation/outputs/stage_04_uncertainty_chain.csv
# Outputs:
#   validation/outputs/stage_05_scores_r.csv  (intermedio, wide)
#
# Ejemplo:
#   Rscript validation/stage_05_scores.R
#
# Scores por participante/método/combo:
#   z_score     = (result - x_pt) / sigma_pt
#   z_prime     = (result - x_pt) / sqrt(sigma_pt² + u_xpt_def²)
#   zeta        = (result - x_pt) / sqrt(uncertainty_std² + u_xpt_def²)
#   En          = (result - x_pt) / sqrt((k·u_std)² + (k·u_xpt_def)²)   k=2

DATA_SUMMARY <- "data/summary_n13.csv"
STAGE04_CSV  <- "validation/outputs/stage_04_uncertainty_chain.csv"
OUTPUT_R_CSV <- "validation/outputs/stage_05_scores_r.csv"

K <- 2  # Factor de cobertura

# --- Evaluaciones ---

evaluate_z <- function(z) {
  ifelse(!is.finite(z), "N/A",
    ifelse(abs(z) <= 2, "Satisfactorio",
      ifelse(abs(z) >= 3, "No satisfactorio", "Cuestionable")))
}

evaluate_en <- function(en) {
  ifelse(!is.finite(en), "N/A",
    ifelse(abs(en) <= 1, "Satisfactorio", "No satisfactorio"))
}

# --- Helpers ---

make_combo_id <- function(pollutant, level) {
  prefix <- toupper(pollutant)
  num    <- sub("^([0-9]+)-.*$", "\\1", level)
  paste0(prefix, "_", num)
}

run_stage_05 <- function() {
  cat("Etapa 5: Scores de Desempeño — INICIO\n")

  # ----------------------------------------------------------------
  # 1. Cargar parámetros de Etapa 4 (x_pt, sigma_pt, u_xpt_def)
  # ----------------------------------------------------------------
  cat("  Cargando parámetros de Etapa 4...\n")
  stage04 <- read.csv(STAGE04_CSV, stringsAsFactors = FALSE)
  stage04$r_value <- suppressWarnings(as.numeric(stage04$r_value))

  params_long <- stage04[stage04$metric %in% c("x_pt", "sigma_pt", "u_xpt_def"),
                          c("combo_id", "pollutant", "level", "section", "metric", "r_value")]

  # Pivotar a tabla wide: una fila por (combo_id, method)
  combos_methods <- unique(params_long[, c("combo_id", "pollutant", "level", "section")])
  params_wide <- data.frame()

  for (i in seq_len(nrow(combos_methods))) {
    cm  <- combos_methods[i, ]
    sub <- params_long[params_long$combo_id == cm$combo_id &
                       params_long$section   == cm$section, ]

    get_val <- function(m) {
      v <- sub$r_value[sub$metric == m]
      if (length(v) > 0) v[1] else NA_real_
    }

    params_wide <- rbind(params_wide, data.frame(
      combo_id  = cm$combo_id,
      pollutant = cm$pollutant,
      level     = cm$level,
      method    = cm$section,
      x_pt      = get_val("x_pt"),
      sigma_pt  = get_val("sigma_pt"),
      u_xpt_def = get_val("u_xpt_def"),
      stringsAsFactors = FALSE
    ))
  }

  cat("  Parámetros cargados:", nrow(params_wide), "filas (combo × método)\n")

  # ----------------------------------------------------------------
  # 2. Cargar y agregar datos de participantes
  # ----------------------------------------------------------------
  cat("  Cargando datos de participantes...\n")
  summary_raw <- read.csv(DATA_SUMMARY, stringsAsFactors = FALSE)

  # Filtrar referencia
  summary_raw <- summary_raw[summary_raw$participant_id != "ref", ]

  # Crear combo_id
  summary_raw$combo_id <- mapply(make_combo_id, summary_raw$pollutant, summary_raw$level)

  # Agregar mean(mean_value) y mean(sd_value) por combo/participante (3 sample_groups)
  agg <- aggregate(
    cbind(mean_value, sd_value) ~ combo_id + pollutant + level + participant_id,
    data    = summary_raw,
    FUN     = mean,
    na.rm   = TRUE
  )
  agg$result          <- agg$mean_value
  agg$uncertainty_std <- agg$sd_value / sqrt(2)  # m=2 de homogeneidad

  cat("  Participantes agregados:", nrow(agg), "filas\n")

  # ----------------------------------------------------------------
  # 3. Calcular scores por combo × método × participante
  # ----------------------------------------------------------------
  cat("  Calculando scores...\n")
  METHODS <- c("Referencia", "Consenso MADe", "Consenso nIQR", "Algoritmo A")

  all_rows <- list()

  for (combo_id in sort(unique(params_wide$combo_id))) {
    parts <- agg[agg$combo_id == combo_id, ]
    if (nrow(parts) == 0) next

    for (method in METHODS) {
      pm <- params_wide[params_wide$combo_id == combo_id & params_wide$method == method, ]
      if (nrow(pm) == 0) next

      x_pt      <- pm$x_pt[1]
      sigma_pt  <- pm$sigma_pt[1]
      u_xpt_def <- pm$u_xpt_def[1]

      # Clip u_xpt_def no finito a 0 (igual que app.R compute_combo_scores)
      if (!is.finite(u_xpt_def) || u_xpt_def < 0) u_xpt_def <- 0

      for (i in seq_len(nrow(parts))) {
        result          <- parts$result[i]
        uncertainty_std <- parts$uncertainty_std[i]
        participant_id  <- parts$participant_id[i]

        # z_score
        z <- if (is.finite(sigma_pt) && sigma_pt > 0) {
          (result - x_pt) / sigma_pt
        } else NA_real_

        # z_prime_score
        zprime_den <- sqrt(sigma_pt^2 + u_xpt_def^2)
        zprime <- if (is.finite(zprime_den) && zprime_den > 0) {
          (result - x_pt) / zprime_den
        } else NA_real_

        # zeta_score
        zeta_den <- sqrt(uncertainty_std^2 + u_xpt_def^2)
        zeta <- if (is.finite(zeta_den) && zeta_den > 0) {
          (result - x_pt) / zeta_den
        } else NA_real_

        # En_score (k=2)
        en_den <- sqrt((K * uncertainty_std)^2 + (K * u_xpt_def)^2)
        en <- if (is.finite(en_den) && en_den > 0) {
          (result - x_pt) / en_den
        } else NA_real_

        all_rows[[length(all_rows) + 1]] <- data.frame(
          combo_id          = combo_id,
          pollutant         = parts$pollutant[i],
          level             = parts$level[i],
          method            = method,
          participant_id    = participant_id,
          result            = result,
          uncertainty_std   = uncertainty_std,
          x_pt              = x_pt,
          sigma_pt          = sigma_pt,
          u_xpt_def         = u_xpt_def,
          z_score           = z,
          z_prime_score     = zprime,
          zeta_score        = zeta,
          En_score          = en,
          z_score_eval      = evaluate_z(z),
          z_prime_score_eval = evaluate_z(zprime),
          zeta_score_eval   = evaluate_z(zeta),
          En_score_eval     = evaluate_en(en),
          stringsAsFactors  = FALSE
        )
      }
    }
  }

  r_df <- do.call(rbind, all_rows)

  # ----------------------------------------------------------------
  # 4. Guardar CSV intermedio
  # ----------------------------------------------------------------
  dir.create("validation/outputs", showWarnings = FALSE, recursive = TRUE)
  write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE, na = "NA")

  cat("  CSV intermedio R escrito:", OUTPUT_R_CSV, "\n")
  cat("  Filas:", nrow(r_df), "(esperado:", 15 * 4 * 12, "= 720)\n")
  cat("Etapa 5: Scores de Desempeño — FIN\n")
}

if (sys.nframe() == 0) {
  run_stage_05()
}
