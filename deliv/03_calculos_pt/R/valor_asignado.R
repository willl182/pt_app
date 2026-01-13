# ===================================================================
# Cálculo de valor asignado (x_pt) y sigma_pt
# ISO 13528:2022
# Archivo independiente sin dependencias externas
# ===================================================================

cargar_datos_resumen <- function(ruta_datos = "../../data/summary_n4.csv") {
  datos <- read.csv(ruta_datos, stringsAsFactors = FALSE)
  required_cols <- c("pollutant", "level", "participant_id", "mean_value", "sd_value")
  if (!all(required_cols %in% names(datos))) {
    stop("El archivo summary_n4.csv no contiene las columnas esperadas.")
  }
  datos
}

calcular_niqr_local <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

calcular_made_local <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) == 0) {
    return(NA_real_)
  }
  mediana <- stats::median(x_clean, na.rm = TRUE)
  mad_val <- stats::median(abs(x_clean - mediana), na.rm = TRUE)
  1.483 * mad_val
}

run_algorithm_a_local <- function(values, max_iter = 50, tol = 1e-03) {
  values <- values[is.finite(values)]
  n <- length(values)
  if (n < 3) {
    return(list(error = "El Algoritmo A requiere al menos 3 observaciones."))
  }

  x_star <- stats::median(values, na.rm = TRUE)
  s_star <- 1.483 * stats::median(abs(values - x_star), na.rm = TRUE)

  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    s_star <- stats::sd(values, na.rm = TRUE)
  }

  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    return(list(assigned_value = x_star, robust_sd = 0, converged = TRUE, iterations = data.frame()))
  }

  iteration_records <- list()
  converged <- FALSE

  for (iter in seq_len(max_iter)) {
    u_values <- (values - x_star) / (1.5 * s_star)
    weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))
    weight_sum <- sum(weights)

    x_new <- sum(weights * values) / weight_sum
    s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)

    iteration_records[[iter]] <- data.frame(
      iteration = iter,
      x_star = x_new,
      s_star = s_new,
      delta = max(abs(x_new - x_star), abs(s_new - s_star)),
      stringsAsFactors = FALSE
    )

    if (abs(x_new - x_star) < tol && abs(s_new - s_star) < tol) {
      converged <- TRUE
      x_star <- x_new
      s_star <- s_new
      break
    }

    x_star <- x_new
    s_star <- s_new
  }

  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
    converged = converged
  )
}

#' Calcular valor asignado según método
#'
#' Métodos disponibles: 1 (referencia), 2a (MADe), 2b (nIQR), 3 (Algoritmo A).
#'
#' @param contaminante Nombre del analito.
#' @param nivel Nivel del analito.
#' @param metodo Código del método ("1", "2a", "2b", "3").
#' @param ruta_datos Ruta al archivo `summary_n4.csv`.
#' @param grupo_muestra Opcional, filtra por `sample_group`.
#' @return Lista con x_pt, u_xpt, sigma_pt y n.
calculate_valor_asignado <- function(contaminante,
                                     nivel,
                                     metodo = c("1", "2a", "2b", "3"),
                                     ruta_datos = "../../data/summary_n4.csv",
                                     grupo_muestra = NULL) {
  metodo <- match.arg(metodo)
  datos <- cargar_datos_resumen(ruta_datos)

  if (!is.null(grupo_muestra)) {
    datos <- datos[datos$sample_group == grupo_muestra, , drop = FALSE]
  }

  subset_datos <- datos[datos$pollutant == contaminante & datos$level == nivel, , drop = FALSE]
  if (nrow(subset_datos) == 0) {
    return(list(error = "No hay datos para el contaminante y nivel solicitados."))
  }

  ref_data <- subset_datos[subset_datos$participant_id == "ref", , drop = FALSE]
  part_data <- subset_datos[subset_datos$participant_id != "ref", , drop = FALSE]

  if (metodo == "1") {
    if (nrow(ref_data) == 0) {
      return(list(error = "No hay datos de referencia para el método 1."))
    }
    x_pt <- base::mean(ref_data$mean_value, na.rm = TRUE)
    u_xpt <- base::mean(ref_data$sd_value, na.rm = TRUE)
    sigma_pt <- base::mean(ref_data$sd_value, na.rm = TRUE)
    n_vals <- nrow(ref_data)
  } else if (metodo == "2a") {
    valores <- part_data$mean_value
    x_pt <- stats::median(valores, na.rm = TRUE)
    sigma_pt <- calcular_made_local(valores)
    n_vals <- sum(is.finite(valores))
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  } else if (metodo == "2b") {
    valores <- part_data$mean_value
    x_pt <- stats::median(valores, na.rm = TRUE)
    sigma_pt <- calcular_niqr_local(valores)
    n_vals <- sum(is.finite(valores))
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  } else {
    valores <- part_data$mean_value
    n_vals <- sum(is.finite(valores))
    res_algo <- run_algorithm_a_local(valores)
    if (!is.null(res_algo$error)) {
      return(list(error = res_algo$error))
    }
    x_pt <- res_algo$assigned_value
    sigma_pt <- res_algo$robust_sd
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  }

  list(
    metodo = metodo,
    x_pt = x_pt,
    u_xpt = u_xpt,
    sigma_pt = sigma_pt,
    n = n_vals,
    error = NULL
  )
}
