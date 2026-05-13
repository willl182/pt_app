# ===================================================================
# Etapa 5: Scores de Desempeño
# Validacion de scores por participante: z, z', zeta, En
#
# Referencia: ISO 13528:2022
# Fuente: data/for_validation/summary_n4.csv, validation/outputs/stage_04_uncertainty_chain.csv
# ===================================================================
#
## Uso
#
# Propósito: Calcular scores de desempeño independientes en R
# Inputs:
#   data/for_validation/summary_n4.csv
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

DATA_SUMMARY    <- "../data/for_validation/summary_n4.csv"
DATA_PT_DATA    <- "../data/pt_data_n13.csv"
STAGE04_CSV     <- "outputs/stage_04_uncertainty_chain.csv"
OUTPUT_R_CSV    <- "outputs/stage_05_scores_r.csv"

K <- 2  # Factor de cobertura
TOL_DEFAULT <- 1e-9
ROUND_DIGITS <- 4

round4 <- function(x) {
  ifelse(is.finite(x), round(x, ROUND_DIGITS), x)
}

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
  agg$result <- agg$mean_value

  # Incorporar u_i reportada por el participante (presupuesto propio).
  # El participante conoce su propio presupuesto; la app no puede recalcularlo.
  # Sin u_i no se calculan zeta ni En; sd_value queda solo como chequeo interno.
  if (file.exists(DATA_PT_DATA)) {
    u_df <- read.csv(DATA_PT_DATA, stringsAsFactors = FALSE)
    u_df$combo_id <- mapply(make_combo_id, u_df$pollutant, u_df$level)
    u_df <- u_df[, c("participant_id", "combo_id", "u_i")]
    agg <- merge(agg, u_df, by = c("participant_id", "combo_id"), all.x = TRUE)
    # Chequeo de consistencia interna (sólo trazabilidad, nunca bloquea)
    agg$u_i_check <- agg$sd_value / sqrt(3)
    agg$uncertainty_std <- agg$u_i
    missing <- agg$participant_id[is.na(agg$u_i)]
    if (length(missing) > 0) {
      warning("u_i no encontrado en 'pt_data_n13.csv' para: ",
              paste(unique(missing), collapse = ", "),
              ". zeta y En no se calcularán para esas filas.")
    }
    inconsistent <- with(agg,
      participant_id[
        is.finite(u_i) & is.finite(u_i_check) & u_i > 0 &
        abs(u_i - u_i_check) / u_i > 0.50
      ]
    )
    if (length(inconsistent) > 0) {
      warning("Chequeo de consistencia: u_i difiere >50% del estimado interno (sd/√3) para: ",
              paste(unique(inconsistent), collapse = ", "),
              ". Verificar presupuesto reportado.")
    }
  } else {
    warning("Archivo '", DATA_PT_DATA, "' no encontrado. ",
            "zeta y En no se calcularán sin u_i.")
    agg$u_i             <- NA_real_
    agg$u_i_check       <- agg$sd_value / sqrt(3)
    agg$uncertainty_std <- NA_real_
  }

  cat("  Participantes agregados:", nrow(agg), "filas\n")

  # ----------------------------------------------------------------
  # 3. Calcular scores por combo × método × participante
  # ----------------------------------------------------------------
  cat("  Calculando scores...\n")
  METHODS <- c("Referencia", "Consenso MADe", "Consenso nIQR", "Algoritmo A")
  METHOD_LABELS <- c(
    "Referencia" = "Método 1: valor de referencia",
    "Consenso MADe" = "Método 2a: consenso MADe",
    "Consenso nIQR" = "Método 2b: consenso nIQR",
    "Algoritmo A" = "Método 3: Algoritmo A"
  )
  SCORE_LABELS <- c(
    "z_score" = "z",
    "z_prime_score" = "z'",
    "zeta_score" = "zeta",
    "En_score" = "En",
    "z_score_eval" = "z",
    "z_prime_score_eval" = "z'",
    "zeta_score_eval" = "zeta",
    "En_score_eval" = "En"
  )

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

        score_row <- data.frame(
          combo_id          = combo_id,
          pollutant         = parts$pollutant[i],
          level             = parts$level[i],
          method            = method,
          method_label      = METHOD_LABELS[[method]],
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
        all_rows[[length(all_rows) + 1]] <- score_row
      }
    }
  }

  wide_df <- do.call(rbind, all_rows)

  long_rows <- list()
  metrics <- c("z_score", "z_prime_score", "zeta_score", "En_score")
  eval_metrics <- c("z_score_eval", "z_prime_score_eval", "zeta_score_eval", "En_score_eval")

  for (i in seq_len(nrow(wide_df))) {
    row <- wide_df[i, ]
    for (j in seq_along(metrics)) {
      long_rows[[length(long_rows) + 1]] <- data.frame(
        combo_id = row$combo_id,
        pollutant = row$pollutant,
        level = row$level,
        stage = "stage_05_scores",
        section = row$method,
        method_label = row$method_label,
        participant_id = row$participant_id,
        metric = metrics[j],
        score_type = SCORE_LABELS[[metrics[j]]],
        r_value = row[[metrics[j]]],
        python_value = NA_real_,
        app_value = NA_real_,
        diff_r_python = NA_character_,
        diff_app_r = NA_character_,
        diff_app_python = NA_character_,
        status = "PASS",
        tolerance = TOL_DEFAULT,
        notes = "",
        stringsAsFactors = FALSE
      )
      long_rows[[length(long_rows)]]$python_value <- NA_real_
      long_rows[[length(long_rows) + 1]] <- data.frame(
        combo_id = row$combo_id,
        pollutant = row$pollutant,
        level = row$level,
        stage = "stage_05_scores",
        section = row$method,
        method_label = row$method_label,
        participant_id = row$participant_id,
        metric = eval_metrics[j],
        score_type = SCORE_LABELS[[eval_metrics[j]]],
        r_value = row[[eval_metrics[j]]],
        python_value = row[[eval_metrics[j]]],
        app_value = NA_character_,
        diff_r_python = NA_character_,
        diff_app_r = NA_character_,
        diff_app_python = NA_character_,
        status = "PASS",
        tolerance = "exact",
        notes = "",
        stringsAsFactors = FALSE
      )
    }
  }

  r_df <- do.call(rbind, long_rows)
  numeric_metrics <- c("z_score", "z_prime_score", "zeta_score", "En_score")
  numeric_cols <- c("r_value", "python_value", "app_value", "tolerance")
  numeric_rows <- r_df$metric %in% numeric_metrics
  for (col in numeric_cols) {
    if (col %in% names(r_df)) {
      suppressWarnings(
        r_df[numeric_rows, col] <- round4(as.numeric(r_df[numeric_rows, col]))
      )
    }
  }

  # ----------------------------------------------------------------
  # 4. Guardar CSV intermedio
  # ----------------------------------------------------------------
  dir.create("outputs", showWarnings = FALSE, recursive = TRUE)
  write.csv(r_df, OUTPUT_R_CSV, row.names = FALSE, na = "NA")

  cat("  CSV intermedio R escrito:", OUTPUT_R_CSV, "\n")
  cat("  Métodos de valor asignado reportados:\n")
  for (method in METHODS) {
    cat("   - ", METHOD_LABELS[[method]], "\n", sep = "")
  }
  cat("  Tipos de score reportados: z, z', zeta, En\n")
  expected_rows <- length(unique(params_wide$combo_id)) * length(METHODS) *
    length(unique(agg$participant_id))
  expected_rows <- length(unique(params_wide$combo_id)) * length(METHODS) *
    length(unique(agg$participant_id)) * (length(metrics) + length(eval_metrics))
  cat("  Filas:", nrow(r_df), "(esperado:", expected_rows, ")\n")
  cat("Etapa 5: Scores de Desempeño — FIN\n")
}

if (sys.nframe() == 0) {
  run_stage_05()
}
