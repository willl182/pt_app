# ===================================================================
# Estimadores robustos para sigma_pt
# ISO 13528:2022
# Archivo independiente sin dependencias externas
# ===================================================================

#' Calcular nIQR (Rango Intercuartílico Normalizado)
#'
#' nIQR = 0.7413 × IQR (ISO 13528:2022, 9.4).
#'
#' @param x Vector numérico.
#' @return nIQR o NA si no hay datos suficientes.
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

#' Calcular MADe (Desviación Absoluta de la Mediana Escalada)
#'
#' MADe = 1.483 × MAD (ISO 13528:2022, 9.4).
#'
#' @param x Vector numérico.
#' @return MADe o NA si no hay datos suficientes.
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

#' Ejecutar Algoritmo A (ISO 13528:2022, Anexo C)
#'
#' @param values Vector numérico de resultados.
#' @param ids Vector opcional de identificadores.
#' @param max_iter Número máximo de iteraciones.
#' @param tol Tolerancia de convergencia.
#' @return Lista con valor asignado, desviación robusta y detalles de iteraciones.
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
      error = "El Algoritmo A requiere al menos 3 observaciones válidas.",
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
      error = "La dispersión es insuficiente para el Algoritmo A.",
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
        error = "El Algoritmo A colapsó por desviación cero.",
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
      iteration = iter,
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
    value = values,
    weight = weights_final,
    standardized_residual = u_final,
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
