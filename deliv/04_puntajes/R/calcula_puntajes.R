# ===================================================================
# Titulo: calcula_puntajes.R
# Entregable: 04 - Modulo de Calculo de Puntajes
# Descripcion: Funciones para calcular z, z', zeta y En, y generar
#              una tabla de puntajes por participante segun ISO 13528.
# Entrada: data.frame con columnas del resumen de participantes
# Salida: data.frame con puntajes y evaluaciones
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022 §10.2-10.5
# ===================================================================

# -------------------------------------------------------------------
# Funciones de calculo de puntajes (ISO 13528:2022 §10.2-10.5)
# -------------------------------------------------------------------

calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / sigma_pt
}

calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominador <- sqrt(sigma_pt^2 + u_xpt^2)
  resultado <- (x - x_pt) / denominador
  resultado[!is.finite(denominador) | denominador <= 0] <- NA_real_
  resultado
}

calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominador <- sqrt(u_x^2 + u_xpt^2)
  resultado <- (x - x_pt) / denominador
  resultado[!is.finite(denominador) | denominador <= 0] <- NA_real_
  resultado
}

calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominador <- sqrt(U_x^2 + U_xpt^2)
  resultado <- (x - x_pt) / denominador
  resultado[!is.finite(denominador) | denominador <= 0] <- NA_real_
  resultado
}

# -------------------------------------------------------------------
# Evaluacion de puntajes
# -------------------------------------------------------------------

evaluate_z_score <- function(z) {
  ifelse(
    !is.finite(z),
    "N/A",
    ifelse(
      abs(z) <= 2,
      "Satisfactorio",
      ifelse(abs(z) < 3, "Cuestionable", "No satisfactorio")
    )
  )
}

evaluate_en_score <- function(en) {
  ifelse(
    !is.finite(en),
    "N/A",
    ifelse(abs(en) <= 1, "Satisfactorio", "No satisfactorio")
  )
}

# -------------------------------------------------------------------
# Calculo completo de puntajes por participante
# -------------------------------------------------------------------

calculate_scores_table <- function(summary_df, m = NULL, k = 2) {
  columnas_requeridas <- c(
    "pollutant", "level", "participant_id", "sample_group",
    "mean_value", "sd_value"
  )
  columnas_faltantes <- setdiff(columnas_requeridas, names(summary_df))
  if (length(columnas_faltantes) > 0) {
    stop(
      sprintf("Faltan columnas requeridas: %s", paste(columnas_faltantes, collapse = ", "))
    )
  }

  grupos <- split(summary_df, list(summary_df$pollutant, summary_df$level), drop = TRUE)

  resultados <- lapply(grupos, function(datos_grupo) {
    valores <- datos_grupo$mean_value
    valores <- valores[is.finite(valores)]

    ref_data <- datos_grupo[datos_grupo$participant_id == "ref", , drop = FALSE]
    if (nrow(ref_data) == 0) {
      x_pt <- NA_real_
    } else {
      x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
    }

    mediana_val <- median(valores, na.rm = TRUE)
    sigma_pt <- 1.483 * median(abs(valores - mediana_val), na.rm = TRUE)

    n_valores <- length(valores)
    if (!is.finite(sigma_pt) || n_valores == 0) {
      u_xpt <- NA_real_
    } else {
      u_xpt <- 1.25 * sigma_pt / sqrt(n_valores)
    }

    m_local <- if (is.null(m)) length(unique(datos_grupo$sample_group)) else m
    u_x <- datos_grupo$sd_value / sqrt(m_local)
    U_x <- k * u_x
    U_xpt <- k * u_xpt

    z_score <- calculate_z_score(datos_grupo$mean_value, x_pt, sigma_pt)
    z_prime_score <- calculate_z_prime_score(datos_grupo$mean_value, x_pt, sigma_pt, u_xpt)
    zeta_score <- calculate_zeta_score(datos_grupo$mean_value, x_pt, u_x, u_xpt)
    en_score <- calculate_en_score(datos_grupo$mean_value, x_pt, U_x, U_xpt)

    data.frame(
      datos_grupo,
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      u_x = u_x,
      U_x = U_x,
      U_xpt = U_xpt,
      z_score = z_score,
      z_eval = evaluate_z_score(z_score),
      z_prime_score = z_prime_score,
      z_prime_eval = evaluate_z_score(z_prime_score),
      zeta_score = zeta_score,
      zeta_eval = evaluate_z_score(zeta_score),
      En_score = en_score,
      En_eval = evaluate_en_score(en_score),
      stringsAsFactors = FALSE
    )
  })

  tabla_final <- do.call(rbind, resultados)
  rownames(tabla_final) <- NULL
  tabla_final
}
