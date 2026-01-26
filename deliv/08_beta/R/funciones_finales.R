# ===================================================================
# Titulo: funciones_finales.R
# Entregable: 08
# Descripcion: Consolidación de todas las funciones standalone para PT
# Entrada: Ninguna (librería de funciones)
# Salida: Funciones exportadas para uso en app_final.R
# Autor: UNAL/INM
# Fecha: 2026-01-24
# Referencia: ISO 13528:2022, ISO 17043:2024
# ===================================================================

# -------------------------------------------------------------------
# ESTADÍSTICOS ROBUSTOS (nIQR, MADe, Algoritmo A)
# -------------------------------------------------------------------

#' Calcular nIQR (Normalized Interquartile Range)
#'
#' nIQR = 0.7413 * IQR
#'
#' Referencia: ISO 13528:2022, Sección 9.4
#'
#' @param x Vector numérico de valores
#' @return Valor nIQR calculado o NA si no es posible calcularlo
#'
#' @examples
#' datos <- c(10.2, 10.5, 10.3, 10.6, 10.4)
#' niqr <- calculate_niqr(datos)
#'
#' @export
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

#' Calcular MADe (Scaled Median Absolute Deviation)
#'
#' MADe = 1.483 * MAD
#'
#' Referencia: ISO 13528:2022, Sección 9.4
#'
#' @param x Vector numérico de valores
#' @return Valor MADe calculado o NA si no es posible calcularlo
#'
#' @examples
#' datos <- c(10.2, 10.5, 10.3, 10.6, 10.4)
#' made <- calculate_mad_e(datos)
#'
#' @export
calculate_mad_e <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) == 0) {
    return(NA_real_)
  }
  data_median <- stats::median(x_clean, na.rm = TRUE)
  abs_deviations <- abs(x_clean - data_median)
  mad_value <- stats::median(abs_deviations, na.rm = TRUE)
  1.483 * mad_value
}

#' Algoritmo A ISO 13528 - Media y desviación robustas
#'
#' Implementación del Algoritmo A del Anexo C de ISO 13528:2022.
#' Calcula valor asignado y desviación estándar robusta usando
#' ponderación iterativa.
#'
#' Referencia: ISO 13528:2022, Anexo C
#'
#' @param values Vector numérico de valores
#' @param ids Vector de identificadores (opcional)
#' @param max_iter Número máximo de iteraciones (default: 50)
#' @param tol Tolerancia de convergencia (default: 1e-03)
#' @return Lista con: assigned_value, robust_sd, iterations, weights, converged, effective_weight, error
#'
#' @examples
#' valores <- c(10.2, 10.5, 10.3, 10.6, 10.4, 10.1, 10.8)
#' resultado <- run_algorithm_a(valores)
#'
#' @export
run_algorithm_a <- function(values, ids = NULL, max_iter = 50, tol = 1e-03) {
  mask <- is.finite(values)
  values <- values[mask]

  if (is.null(ids)) {
    ids <- seq_along(values)
  } else {
    ids <- ids[mask]
  }

  n <- length(values)
  if (n < 3) {
    return(list(
      error = "Se requieren al menos 3 observaciones válidas para el Algoritmo A.",
      assigned_value = NA_real_,
      robust_sd = NA_real_,
      iterations = data.frame(),
      weights = data.frame(),
      converged = FALSE,
      effective_weight = NA_real_
    ))
  }

  x_star <- stats::median(values, na.rm = TRUE)
  s_star <- 1.483 * stats::median(abs(values - x_star), na.rm = TRUE)

  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    s_star <- stats::sd(values, na.rm = TRUE)
  }

  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    return(list(
      error = "La dispersión de datos es insuficiente para el Algoritmo A.",
      assigned_value = x_star,
      robust_sd = 0,
      iterations = data.frame(),
      weights = data.frame(),
      converged = TRUE,
      effective_weight = n
    ))
  }

  iteration_records <- list()
  converged <- FALSE

  for (iter in seq_len(max_iter)) {
    u_values <- (values - x_star) / (1.5 * s_star)
    weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))
    weight_sum <- sum(weights)

    if (!is.finite(weight_sum) || weight_sum <= 0) {
      return(list(
        error = "Los pesos calculados son inválidos para el Algoritmo A.",
        assigned_value = x_star,
        robust_sd = s_star,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        weights = data.frame(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }

    x_new <- sum(weights * values) / weight_sum
    s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)

    if (!is.finite(s_new) || s_new < .Machine$double.eps) {
      return(list(
        error = "El Algoritmo A colapsó debido a desviación estándar cero.",
        assigned_value = x_new,
        robust_sd = 0,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        weights = data.frame(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }

    delta_x <- abs(x_new - x_star)
    delta_s <- abs(s_new - s_star)
    delta <- max(delta_x, delta_s)

    iteration_records[[iter]] <- data.frame(
      iteracion = iter,
      x_star = x_new,
      s_star = s_new,
      delta = delta,
      stringsAsFactors = FALSE
    )

    x_star <- x_new
    s_star <- s_new

    if (delta_x < tol && delta_s < tol) {
      converged <- TRUE
      break
    }
  }

  u_final <- (values - x_star) / (1.5 * s_star)
  weights_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))

  iterations_df <- if (length(iteration_records) > 0) {
    do.call(rbind, iteration_records)
  } else {
    data.frame()
  }

  weights_df <- data.frame(
    id = ids,
    valor = values,
    peso = weights_final,
    residuo_estandarizado = u_final,
    stringsAsFactors = FALSE
  )

  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = iterations_df,
    weights = weights_df,
    converged = converged,
    effective_weight = sum(weights_final),
    error = NULL
  )
}

# -------------------------------------------------------------------
# CÁLCULOS DE PUNTAJES (z, z', zeta, En)
# -------------------------------------------------------------------

#' Calcular puntaje z
#'
#' z = (x - x_pt) / sigma_pt
#'
#' Referencia: ISO 13528:2022, Sección 10.2
#'
#' @param x Valor del participante
#' @param x_pt Valor asignado
#' @param sigma_pt Desviación estándar para aptitud
#' @return Puntaje z calculado o NA si sigma_pt es inválido
#'
#' @examples
#' z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25)
#'
#' @export
calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / sigma_pt
}

#' Calcular puntaje z' (z-prime)
#'
#' z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt^2)
#'
#' Referencia: ISO 13528:2022, Sección 10.3
#'
#' @param x Valor del participante
#' @param x_pt Valor asignado
#' @param sigma_pt Desviación estándar para aptitud
#' @param u_xpt Incertidumbre estándar del valor asignado
#' @return Puntaje z' calculado o NA si denominador es inválido
#'
#' @examples
#' z_prime <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25, u_xpt = 0.01)
#'
#' @export
calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominator <- sqrt(sigma_pt^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Calcular puntaje zeta
#'
#' zeta = (x - x_pt) / sqrt(u_x^2 + u_xpt^2)
#'
#' Referencia: ISO 13528:2022, Sección 10.4
#'
#' @param x Valor del participante
#' @param x_pt Valor asignado
#' @param u_x Incertidumbre estándar del valor del participante
#' @param u_xpt Incertidumbre estándar del valor asignado
#' @return Puntaje zeta calculado o NA si denominador es inválido
#'
#' @examples
#' zeta <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.05, u_xpt = 0.01)
#'
#' @export
calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominator <- sqrt(u_x^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Calcular puntaje En (Error normalizado)
#'
#' En = (x - x_pt) / sqrt(U_x^2 + U_xpt^2)
#'
#' Referencia: ISO 13528:2022, Sección 10.5
#'
#' @param x Valor del participante
#' @param x_pt Valor asignado
#' @param U_x Incertidumbre expandida del valor del participante
#' @param U_xpt Incertidumbre expandida del valor asignado
#' @return Puntaje En calculado o NA si denominador es inválido
#'
#' @examples
#' En <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.10, U_xpt = 0.02)
#'
#' @export
calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominator <- sqrt(U_x^2 + U_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Evaluar puntaje z (o z', zeta)
#'
#' Clasifica un puntaje z según criterios de ISO 13528:2022
#'
#' Referencia: ISO 13528:2022, Sección 10.2
#'
#' @param z Valor del puntaje z
#' @return "Satisfactorio", "Cuestionable", "No satisfactorio", o "N/A"
#'
#' @examples
#' evaluacion <- evaluate_z_score(z = 1.5)
#'
#' @export
evaluate_z_score <- function(z) {
  if (!is.finite(z)) {
    return("N/A")
  }
  if (abs(z) <= 2) {
    return("Satisfactorio")
  } else if (abs(z) < 3) {
    return("Cuestionable")
  } else {
    return("No satisfactorio")
  }
}

#' Evaluar puntaje En
#'
#' Clasifica un puntaje En según criterios de ISO 13528:2022
#'
#' Referencia: ISO 13528:2022, Sección 10.5
#'
#' @param en Valor del puntaje En
#' @return "Satisfactorio" o "No satisfactorio" o "N/A"
#'
#' @examples
#' evaluacion <- evaluate_en_score(en = 0.8)
#'
#' @export
evaluate_en_score <- function(en) {
  if (!is.finite(en)) {
    return("N/A")
  }
  if (abs(en) <= 1) {
    return("Satisfactorio")
  } else {
    return("No satisfactorio")
  }
}

# -------------------------------------------------------------------
# HOMOGENEIDAD Y ESTABILIDAD
# -------------------------------------------------------------------

#' Calcular estadísticos de homogeneidad
#'
#' Calcula los estadísticos para evaluar homogeneidad según ISO 13528:2022
#' Sección 9.2 usando análisis de varianza ANOVA.
#' También calcula estimación robusta de sigma (MADe) y su incertidumbre.
#'
#' Referencia: ISO 13528:2022, Sección 9.2
#'
#' @param sample_data Matriz o data.frame con muestras en filas y réplicas en columnas
#' @return Lista con: g, m, general_mean_homog, sample_means, x_pt, s_x_bar_sq, s_xt, sw, sw_sq, ss_sq, ss, median_of_diffs, MADe, sigma_pt, u_sigma_pt, error
#'
#' @examples
#' datos_matriz <- matrix(c(10.2, 10.3, 10.4, 10.1, 10.5, 10.2), nrow = 3, ncol = 2)
#' resultado <- calculate_homogeneity_stats(datos_matriz)
#'
#' @export
calculate_homogeneity_stats <- function(sample_data) {
  if (is.data.frame(sample_data)) {
    sample_data <- as.matrix(sample_data)
  }
  
  g <- nrow(sample_data)
  m <- ncol(sample_data)
  
  if (g < 2) {
    return(list(error = "Se requieren al menos 2 muestras para la evaluación de homogeneidad."))
  }
  if (m < 2) {
    return(list(error = "Se requieren al menos 2 réplicas por muestra para la evaluación de homogeneidad."))
  }
  
  sample_means <- rowMeans(sample_data, na.rm = TRUE)
  
  # General mean: media de TODOS los valores (no solo las medias)
  general_mean_homog <- base::mean(sample_data, na.rm = TRUE)
  
  # x_pt: mediana de la primera réplica
  x_pt <- stats::median(sample_data[, 1], na.rm = TRUE)

  s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)

  if (m == 2) {
    range_btw <- abs(sample_data[, 1] - sample_data[, 2])
    sw <- sqrt(sum(range_btw^2) / (2 * g))
  } else {
    within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(base::mean(within_vars, na.rm = TRUE))
  }

  sw_sq <- sw^2
  ss_sq <- abs(s_x_bar_sq - (sw_sq / m))
  ss <- sqrt(ss_sq)

  # Mediana de las diferencias absolutas entre medias de muestra
  median_of_diffs <- stats::median(abs(sample_means - stats::median(sample_means)), na.rm = TRUE)

  # MADe: estimación robusta de sigma
  MADe <- 1.483 * median_of_diffs

  # Incertidumbre de MADe
  u_sigma_pt <- 1.23 * MADe / sqrt(g)

  list(
    g = g,
    m = m,
    general_mean_homog = general_mean_homog,
    sample_means = sample_means,
    x_pt = x_pt,
    s_x_bar_sq = s_x_bar_sq,
    s_xt = s_xt,
    sw = sw,
    sw_sq = sw_sq,
    ss_sq = ss_sq,
    ss = ss,
    median_of_diffs = median_of_diffs,
    MADe = MADe,
    sigma_pt = MADe,
    u_sigma_pt = u_sigma_pt,
    error = NULL
  )
}

#' Calcular criterio de homogeneidad
#'
#' c = 0.3 * sigma_pt
#'
#' Referencia: ISO 13528:2022, Sección 9.2.3
#'
#' @param sigma_pt Desviación estándar para aptitud
#' @return Valor del criterio c
#'
#' @examples
#' c <- calculate_homogeneity_criterion(sigma_pt = 0.5)
#'
#' @export
calculate_homogeneity_criterion <- function(sigma_pt) {
  0.3 * sigma_pt
}

#' Calcular criterio expandido de homogeneidad
#'
#' c_expanded = c_criterion + u_sigma_pt
#'
#' @param sigma_pt Desviación estándar para aptitud (desde MADe)
#' @param u_sigma_pt Incertidumbre de sigma_pt
#' @return Valor del criterio expandido
#'
#' @examples
#' c_exp <- calculate_homogeneity_criterion_expanded(sigma_pt = 0.5, u_sigma_pt = 0.01)
#'
#' @export
calculate_homogeneity_criterion_expanded <- function(sigma_pt, u_sigma_pt) {
  c_criterion <- 0.3 * sigma_pt
  c_criterion + u_sigma_pt
}

#' Evaluar homogeneidad
#'
#' Evalúa si la variabilidad entre muestras es aceptable
#'
#' @param ss Desviación estándar entre muestras
#' @param c_criterion Criterio de homogeneidad
#' @return "Aceptable" o "No aceptable"
#'
#' @examples
#' resultado <- evaluate_homogeneity(ss = 0.15, c_criterion = 0.2)
#'
#' @export
evaluate_homogeneity <- function(ss, c_criterion) {
  if (!is.finite(ss) || !is.finite(c_criterion)) {
    return("N/A")
  }
  if (ss <= c_criterion) {
    return("Aceptable")
  } else {
    return("No aceptable")
  }
}

#' Calcular estadísticos de estabilidad
#'
#' Referencia: ISO 13528:2022, Sección 9.3
#'
#' @param stab_data Datos de estabilidad
#' @param hom_general_mean_homog Media de homogeneidad
#' @param hom_stab_x_pt Mediana de 1ª réplica de HOMOGENEIDAD (valor asignado x_pt), usada como REFERENCIA para el cálculo de median_of_diffs
#' @param hom_stab_sigma_pt Desviación estándar de HOMOGENEIDAD (estimación robusta MADe)
#' @return Lista con estadísticos de estabilidad
#'
#' @export
calculate_stability_stats <- function(stab_data, hom_general_mean_homog, hom_stab_x_pt, hom_stab_sigma_pt) {
  if (is.data.frame(stab_data)) {
    stab_data <- as.matrix(stab_data)
  }

  g_stab <- nrow(stab_data)
  m_stab <- ncol(stab_data)

  if (g_stab < 2) {
    return(list(error = "Se requieren al menos 2 muestras para la evaluación de estabilidad."))
  }
  if (m_stab < 2) {
    return(list(error = "Se requieren al menos 2 réplicas por muestra para la evaluación de estabilidad."))
  }

  stab_sample_means <- rowMeans(stab_data, na.rm = TRUE)

  stab_general_mean <- base::mean(stab_data, na.rm = TRUE)

  stab_x_pt <- stats::median(stab_data[, 1], na.rm = TRUE)

  stab_s_x_bar_sq <- stats::var(stab_sample_means, na.rm = TRUE)
  stab_s_xt <- sqrt(stab_s_x_bar_sq)

  if (m_stab == 2) {
    range_btw <- abs(stab_data[, 1] - stab_data[, 2])
    stab_sw <- sqrt(sum(range_btw^2) / (2 * g_stab))
  } else {
    within_vars <- apply(stab_data, 1, stats::var, na.rm = TRUE)
    stab_sw <- sqrt(base::mean(within_vars, na.rm = TRUE))
  }

  stab_sw_sq <- stab_sw^2

  stab_ss_sq <- abs(stab_s_x_bar_sq - (stab_sw_sq / m_stab))
  stab_ss <- sqrt(stab_ss_sq)

  hom_stab_median_of_diffs <- stats::median(abs(stab_data[, 2] - hom_stab_x_pt), na.rm = TRUE)

  difference <- abs(stab_general_mean - hom_general_mean_homog)

  list(
    g = g_stab,
    m = m_stab,
    general_mean = stab_general_mean,
    sample_means = stab_sample_means,
    x_pt = stab_x_pt,
    s_x_bar_sq = stab_s_x_bar_sq,
    s_xt = stab_s_xt,
    sw = stab_sw,
    sw_sq = stab_sw_sq,
    ss_sq = stab_ss_sq,
    ss = stab_ss,
    hom_stab_median_of_diffs = hom_stab_median_of_diffs,
    hom_stab_sigma_pt = hom_stab_sigma_pt,
    diff_hom_stab = difference,
    error = NULL
  )
}

#' Evaluar estabilidad
#'
#' @param difference Diferencia entre medias
#' @param criterion Criterio de estabilidad
#' @return "Estable" o "No estable"
#'
#' @export
evaluate_stability <- function(difference, criterion) {
  if (!is.finite(difference) || !is.finite(criterion)) {
    return("N/A")
  }
  if (difference <= criterion) {
    return("Estable")
  } else {
    return("No estable")
  }
}

# -------------------------------------------------------------------
# VALOR ASIGNADO
# -------------------------------------------------------------------

#' Calcular valor asignado - Método 1: Valor de referencia
#'
#' @param ref_data Datos de referencia
#' @return Valor asignado
#'
#' @export
calculate_assigned_value_reference <- function(ref_data) {
  mean(ref_data, na.rm = TRUE)
}

#' Calcular valor asignado - Método 2a: Consenso con MADe
#'
#' @param values Vector de valores
#' @return Valor asignado (media robusta)
#'
#' @export
calculate_assigned_value_made <- function(values) {
  median(values, na.rm = TRUE)
}

#' Calcular valor asignado - Método 2b: Consenso con nIQR
#'
#' @param values Vector de valores
#' @return Valor asignado (mediana)
#'
#' @export
calculate_assigned_value_niqr <- function(values) {
  median(values, na.rm = TRUE)
}

#' Calcular valor asignado - Método 3: Algoritmo A
#'
#' @param values Vector de valores
#' @return Valor asignado del Algoritmo A
#'
#' @export
calculate_assigned_value_algorithm_a <- function(values) {
  result <- run_algorithm_a(values)
  result$assigned_value
}

# -------------------------------------------------------------------
# SIGMA PT
# -------------------------------------------------------------------

#' Calcular sigma_pt - Método 1: nIQR
#'
#' @param values Vector de valores
#' @return sigma_pt usando nIQR
#'
#' @export
calculate_sigma_pt_niqr <- function(values) {
  calculate_niqr(values)
}

#' Calcular sigma_pt - Método 2: MADe
#'
#' @param values Vector de valores
#' @return sigma_pt usando MADe
#'
#' @export
calculate_sigma_pt_made <- function(values) {
  calculate_mad_e(values)
}

#' Calcular sigma_pt - Método 3: Algoritmo A
#'
#' @param values Vector de valores
#' @return sigma_pt del Algoritmo A
#'
#' @export
calculate_sigma_pt_algorithm_a <- function(values) {
  result <- run_algorithm_a(values)
  result$robust_sd
}

# -------------------------------------------------------------------
# UTILIDADES
# -------------------------------------------------------------------

#' Calcular puntajes para todos los participantes
#'
#' @param df data.frame con datos de participantes
#' @param x_pt Valor asignado
#' @param sigma_pt Desviación estándar
#' @param u_xpt Incertidumbre del valor asignado
#' @param k Factor de cobertura
#' @return data.frame con puntajes calculados
#'
#' @export
calculate_scores_participants <- function(df, x_pt_val, sigma_pt_val, u_xpt_val, k = 2) {
  df %>%
    dplyr::mutate(
      x_pt = x_pt_val,
      sigma_pt = sigma_pt_val,
      u_xpt = u_xpt_val,
      u_x = sd_value / sqrt(1),
      U_x = k * u_x,
      U_xpt = k * u_xpt_val
    ) %>%
    dplyr::mutate(
      z_score = (mean_value - x_pt) / sigma_pt,
      z_prime_score = (mean_value - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
      zeta_score = (mean_value - x_pt) / sqrt(u_x^2 + u_xpt^2),
      En_score = (mean_value - x_pt) / sqrt(U_x^2 + U_xpt^2),
      z_score_eval = sapply(z_score, evaluate_z_score),
      z_prime_score_eval = sapply(z_prime_score, evaluate_z_score),
      zeta_score_eval = sapply(zeta_score, evaluate_z_score),
      En_score_eval = sapply(En_score, evaluate_en_score)
    )
}

#' Resumir puntajes de un participante
#'
#' @param scores_df data.frame con puntajes
#' @return Resumen del participante
#'
#' @export
summarize_scores_participant <- function(scores_df) {
  list(
    z_mean = mean(abs(scores_df$z_score), na.rm = TRUE),
    z_max = max(abs(scores_df$z_score), na.rm = TRUE),
    satisfactorio_z = sum(scores_df$z_score_eval == "Satisfactorio"),
    cuestionable_z = sum(scores_df$z_score_eval == "Cuestionable"),
    no_satisfactorio_z = sum(scores_df$z_score_eval == "No satisfactorio"),
    satisfactorio_en = sum(scores_df$En_score_eval == "Satisfactorio"),
    no_satisfactorio_en = sum(scores_df$En_score_eval == "No satisfactorio")
  )
}
