library(dplyr)
library(tibble)

calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

run_algorithm_a <- function(values, ids, max_iter = 50) {
  mask <- is.finite(values)
  values <- values[mask]
  ids <- ids[mask]

  n <- length(values)
  if (n < 3) {
    return(list(error = "El Algoritmo A requiere al menos 3 resultados válidos."))
  }

  x_star <- median(values, na.rm = TRUE)
  s_star <- 1.483 * median(abs(values - x_star), na.rm = TRUE)

  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    s_star <- sd(values, na.rm = TRUE)
  }

  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    return(list(error = "La dispersión de los datos es insuficiente para ejecutar el Algoritmo A."))
  }

  iteration_records <- list()
  converged <- FALSE

  for (iter in seq_len(max_iter)) {
    u_values <- (values - x_star) / (1.5 * s_star)
    weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))

    weight_sum <- sum(weights)
    if (!is.finite(weight_sum) || weight_sum <= 0) {
      return(list(error = "Los pesos calculados no son válidos para el Algoritmo A."))
    }

    x_new <- sum(weights * values) / weight_sum
    s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)

    if (!is.finite(s_new) || s_new < .Machine$double.eps) {
      return(list(error = "El Algoritmo A colapsó debido a una desviación estándar nula."))
    }

    delta_x <- abs(x_new - x_star)
    delta_s <- abs(s_new - s_star)
    delta <- max(delta_x, delta_s)
    iteration_records[[iter]] <- data.frame(
      Iteración = iter,
      `Valor asignado (x*)` = x_new,
      `Desviación robusta (s*)` = s_new,
      Cambio = delta,
      check.names = FALSE
    )

    x_star <- x_new
    s_star <- s_new

    if (delta_x < 1e-03 && delta_s < 1e-03) {
      converged <- TRUE
      break
    }
  }

  iteration_df <- if (length(iteration_records) > 0) {
    bind_rows(iteration_records)
  } else {
    tibble()
  }
  u_final <- (values - x_star) / (1.5 * s_star)
  weights_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))
  weights_df <- tibble(Participante = ids, Resultado = values, Peso = weights_final, `Residuo estandarizado` = u_final)

  list(
    assigned_value = x_star, robust_sd = s_star, iterations = iteration_df, weights = weights_df,
    converged = converged, effective_weight = sum(weights_final), error = NULL
  )
}
