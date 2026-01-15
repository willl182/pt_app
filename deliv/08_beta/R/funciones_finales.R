# ===================================================================
# Titulo: funciones_finales.R
# Entregable: 08 - Version Beta y Documentacion Final
# Descripcion: Funciones standalone consolidadas para homogeneidad,
#              estabilidad, estadisticos robustos, puntajes y evaluaciones.
# Entrada: Datos numericos en vectores o data.frame
# Salida: Listas y data.frame con resultados de calculo
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022 / ISO 17043:2024
# ===================================================================

# -------------------------------------------------------------------
# Utilidades para preparar matrices de muestras
# -------------------------------------------------------------------

construir_matriz_muestras <- function(datos, contaminante, nivel) {
  columnas_requeridas <- c("pollutant", "level", "replicate", "sample_id", "value")
  if (!all(columnas_requeridas %in% names(datos))) {
    stop("Los datos no contienen las columnas requeridas para construir la matriz.")
  }

  subset_datos <- datos[datos$pollutant == contaminante & datos$level == nivel, , drop = FALSE]
  if (nrow(subset_datos) == 0) {
    stop("No se encontraron registros para el contaminante y nivel solicitados.")
  }

  matriz <- stats::xtabs(value ~ sample_id + replicate, data = subset_datos)
  as.matrix(matriz)
}

# -------------------------------------------------------------------
# Homogeneidad (ISO 13528:2022, Seccion 9)
# -------------------------------------------------------------------

calculate_homogeneity_stats <- function(sample_data) {
  if (is.data.frame(sample_data)) {
    sample_data <- as.matrix(sample_data)
  }

  g <- nrow(sample_data)
  m <- ncol(sample_data)

  if (g < 2) {
    return(list(error = "Se requieren al menos 2 muestras para evaluar homogeneidad."))
  }
  if (m < 2) {
    return(list(error = "Se requieren al menos 2 replicados por muestra para evaluar homogeneidad."))
  }

  sample_means <- rowMeans(sample_data, na.rm = TRUE)
  grand_mean <- base::mean(sample_means, na.rm = TRUE)

  s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)

  if (m == 2) {
    ranges <- abs(sample_data[, 1] - sample_data[, 2])
    sw <- sqrt(sum(ranges^2) / (2 * g))
  } else {
    within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(base::mean(within_vars, na.rm = TRUE))
  }

  sw_sq <- sw^2
  ss_sq <- abs(s_x_bar_sq - (sw_sq / m))
  ss <- sqrt(ss_sq)

  list(
    g = g,
    m = m,
    grand_mean = grand_mean,
    sample_means = sample_means,
    s_x_bar_sq = s_x_bar_sq,
    s_xt = s_xt,
    sw = sw,
    sw_sq = sw_sq,
    ss_sq = ss_sq,
    ss = ss,
    error = NULL
  )
}

calculate_homogeneity_criterion <- function(sigma_pt) {
  if (!is.finite(sigma_pt)) {
    return(NA_real_)
  }
  0.3 * sigma_pt
}

calculate_homogeneity_criterion_expanded <- function(sigma_pt, sw_sq) {
  if (!is.finite(sigma_pt) || !is.finite(sw_sq)) {
    return(NA_real_)
  }
  c_criterion <- 0.3 * sigma_pt
  sigma_allowed_sq <- c_criterion^2
  sqrt(sigma_allowed_sq * 1.88 + sw_sq * 1.01)
}

evaluate_homogeneity <- function(ss, c_criterion, c_expanded = NULL) {
  if (!is.finite(ss) || !is.finite(c_criterion)) {
    return(list(
      passes_criterion = NA,
      passes_expanded = NA,
      conclusion = "Datos insuficientes para evaluar homogeneidad."
    ))
  }

  passes_criterion <- ss <= c_criterion
  conclusion1 <- if (passes_criterion) {
    sprintf("ss (%.4f) <= c (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", ss, c_criterion)
  } else {
    sprintf("ss (%.4f) > c (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", ss, c_criterion)
  }

  passes_expanded <- NA
  conclusion2 <- NULL
  if (!is.null(c_expanded) && is.finite(c_expanded)) {
    passes_expanded <- ss <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("ss (%.4f) <= c_exp (%.4f): CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
    } else {
      sprintf("ss (%.4f) > c_exp (%.4f): NO CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
    }
  }

  list(
    passes_criterion = passes_criterion,
    passes_expanded = passes_expanded,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

calculate_u_hom <- function(ss) {
  ss
}

# -------------------------------------------------------------------
# Estabilidad (ISO 13528:2022, Seccion 9.3)
# -------------------------------------------------------------------

calculate_stability_stats <- function(stab_sample_data, hom_grand_mean) {
  stats <- calculate_homogeneity_stats(stab_sample_data)
  if (!is.null(stats$error)) {
    return(stats)
  }

  stats$stab_grand_mean <- stats$grand_mean
  stats$diff_hom_stab <- abs(stats$grand_mean - hom_grand_mean)
  stats
}

calculate_stability_criterion <- function(sigma_pt) {
  if (!is.finite(sigma_pt)) {
    return(NA_real_)
  }
  0.3 * sigma_pt
}

calculate_stability_criterion_expanded <- function(c_criterion, u_hom_mean, u_stab_mean) {
  if (!is.finite(c_criterion) || !is.finite(u_hom_mean) || !is.finite(u_stab_mean)) {
    return(NA_real_)
  }
  c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
}

evaluate_stability <- function(diff_hom_stab, c_criterion, c_expanded = NULL) {
  if (!is.finite(diff_hom_stab) || !is.finite(c_criterion)) {
    return(list(
      passes_criterion = NA,
      passes_expanded = NA,
      conclusion = "Datos insuficientes para evaluar estabilidad."
    ))
  }

  passes_criterion <- diff_hom_stab <= c_criterion
  conclusion1 <- if (passes_criterion) {
    sprintf("|y1 - y2| (%.4f) <= c (%.4f): CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, c_criterion)
  } else {
    sprintf("|y1 - y2| (%.4f) > c (%.4f): NO CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, c_criterion)
  }

  passes_expanded <- NA
  conclusion2 <- NULL
  if (!is.null(c_expanded) && is.finite(c_expanded)) {
    passes_expanded <- diff_hom_stab <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("|y1 - y2| (%.4f) <= c_exp (%.4f): CUMPLE CRITERIO EXPANDIDO", diff_hom_stab, c_expanded)
    } else {
      sprintf("|y1 - y2| (%.4f) > c_exp (%.4f): NO CUMPLE CRITERIO EXPANDIDO", diff_hom_stab, c_expanded)
    }
  }

  list(
    passes_criterion = passes_criterion,
    passes_expanded = passes_expanded,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

calculate_u_stab <- function(diff_hom_stab, c_criterion) {
  if (!is.finite(diff_hom_stab) || !is.finite(c_criterion)) {
    return(NA_real_)
  }
  if (diff_hom_stab <= c_criterion) {
    return(0)
  }
  diff_hom_stab / sqrt(3)
}

# -------------------------------------------------------------------
# Estadisticos robustos (ISO 13528:2022, Seccion 9.4)
# -------------------------------------------------------------------

calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

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
      error = "El Algoritmo A requiere al menos 3 observaciones validas.",
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
      error = "La dispersion es insuficiente para el Algoritmo A.",
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
        error = "Los pesos calculados son invalidos para el Algoritmo A.",
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
        error = "El Algoritmo A colapso por desviacion cero.",
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

# -------------------------------------------------------------------
# Valor asignado y sigma_pt (ISO 13528:2022)
# -------------------------------------------------------------------

calculate_valor_asignado <- function(datos_resumen, contaminante, nivel, metodo = c("1", "2a", "2b", "3")) {
  metodo <- match.arg(metodo)
  columnas_requeridas <- c("pollutant", "level", "participant_id", "mean_value", "sd_value")
  if (!all(columnas_requeridas %in% names(datos_resumen))) {
    return(list(error = "El resumen no contiene las columnas requeridas."))
  }

  subset_datos <- datos_resumen[datos_resumen$pollutant == contaminante & datos_resumen$level == nivel, , drop = FALSE]
  if (nrow(subset_datos) == 0) {
    return(list(error = "No hay datos para el contaminante y nivel solicitados."))
  }

  ref_data <- subset_datos[subset_datos$participant_id == "ref", , drop = FALSE]
  part_data <- subset_datos[subset_datos$participant_id != "ref", , drop = FALSE]

  if (metodo == "1") {
    if (nrow(ref_data) == 0) {
      return(list(error = "No hay datos de referencia para el metodo 1."))
    }
    x_pt <- base::mean(ref_data$mean_value, na.rm = TRUE)
    sigma_pt <- base::mean(ref_data$sd_value, na.rm = TRUE)
    u_xpt <- sigma_pt
    n_vals <- nrow(ref_data)
  } else if (metodo == "2a") {
    valores <- part_data$mean_value
    x_pt <- stats::median(valores, na.rm = TRUE)
    sigma_pt <- calculate_mad_e(valores)
    n_vals <- sum(is.finite(valores))
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  } else if (metodo == "2b") {
    valores <- part_data$mean_value
    x_pt <- stats::median(valores, na.rm = TRUE)
    sigma_pt <- calculate_niqr(valores)
    n_vals <- sum(is.finite(valores))
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  } else {
    valores <- part_data$mean_value
    n_vals <- sum(is.finite(valores))
    res_algo <- run_algorithm_a(valores)
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

# -------------------------------------------------------------------
# Puntajes (ISO 13528:2022, Secciones 10.2-10.5)
# -------------------------------------------------------------------

calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / sigma_pt
}

calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominador <- sqrt(sigma_pt^2 + u_xpt^2)
  if (any(!is.finite(denominador)) || any(denominador <= 0)) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominador <- sqrt(u_x^2 + u_xpt^2)
  if (any(!is.finite(denominador)) || any(denominador <= 0)) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominador <- sqrt(U_x^2 + U_xpt^2)
  if (any(!is.finite(denominador)) || any(denominador <= 0)) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

evaluate_z_score <- function(z) {
  ifelse(
    !is.finite(z),
    "N/A",
    ifelse(abs(z) <= 2, "Satisfactorio", ifelse(abs(z) < 3, "Cuestionable", "No satisfactorio"))
  )
}

evaluate_z_score_vec <- function(z) {
  evaluate_z_score(z)
}

evaluate_en_score <- function(en) {
  ifelse(!is.finite(en), "N/A", ifelse(abs(en) <= 1, "Satisfactorio", "No satisfactorio"))
}

evaluate_en_score_vec <- function(en) {
  evaluate_en_score(en)
}

PT_EN_CLASS_LABELS <- c(
  a1 = "a1 - Totalmente satisfactorio",
  a2 = "a2 - Satisfactorio pero conservador",
  a3 = "a3 - Satisfactorio con MU subestimada",
  a4 = "a4 - Cuestionable pero aceptable",
  a5 = "a5 - Cuestionable e inconsistente",
  a6 = "a6 - No satisfactorio pero la MU cubre la desviacion",
  a7 = "a7 - No satisfactorio (critico)"
)

PT_EN_CLASS_COLORS <- c(
  a1 = "#2E7D32",
  a2 = "#66BB6A",
  a3 = "#9CCC65",
  a4 = "#FFF59D",
  a5 = "#FBC02D",
  a6 = "#EF9A9A",
  a7 = "#C62828",
  mu_missing_z = "#90A4AE",
  mu_missing_zprime = "#78909C"
)

classify_with_en <- function(score_val, en_val, U_xi, sigma_pt, mu_missing, score_label) {
  if (!is.finite(score_val)) {
    return(list(code = NA_character_, label = "N/A"))
  }

  if (isTRUE(mu_missing)) {
    base_eval <- evaluate_z_score(score_val)
    if (base_eval == "N/A") {
      return(list(code = NA_character_, label = "N/A"))
    }
    label_key <- tolower(score_label)
    label_key <- gsub("'", "prime", label_key)
    label_key <- gsub("[^a-z0-9]+", "", label_key)
    code <- paste0("mu_missing_", label_key)
    label <- sprintf("MU ausente - solo %s: %s", score_label, base_eval)
    return(list(code = code, label = label))
  }

  if (!is.finite(en_val) || !is.finite(sigma_pt) || sigma_pt <= 0 || !is.finite(U_xi)) {
    return(list(code = NA_character_, label = "N/A"))
  }

  abs_score <- abs(score_val)
  abs_en <- abs(en_val)
  u_is_conservative <- U_xi >= (2 * sigma_pt)

  if (abs_score <= 2) {
    if (abs_en < 1) {
      code <- if (u_is_conservative) "a2" else "a1"
    } else {
      code <- "a3"
    }
  } else if (abs_score < 3) {
    code <- if (abs_en < 1) "a4" else "a5"
  } else {
    code <- if (abs_en < 1) "a6" else "a7"
  }

  list(code = code, label = PT_EN_CLASS_LABELS[[code]])
}

calculate_scores_table <- function(summary_df, m = NULL, k = 2) {
  columnas_requeridas <- c("pollutant", "level", "participant_id", "sample_group", "mean_value", "sd_value")
  columnas_faltantes <- setdiff(columnas_requeridas, names(summary_df))
  if (length(columnas_faltantes) > 0) {
    stop(sprintf("Faltan columnas requeridas: %s", paste(columnas_faltantes, collapse = ", ")))
  }

  grupos <- split(summary_df, list(summary_df$pollutant, summary_df$level), drop = TRUE)

  resultados <- lapply(grupos, function(datos_grupo) {
    valores <- datos_grupo$mean_value
    valores <- valores[is.finite(valores)]

    ref_data <- datos_grupo[datos_grupo$participant_id == "ref", , drop = FALSE]
    x_pt <- if (nrow(ref_data) == 0) NA_real_ else mean(ref_data$mean_value, na.rm = TRUE)

    mediana_val <- median(valores, na.rm = TRUE)
    sigma_pt <- 1.483 * median(abs(valores - mediana_val), na.rm = TRUE)

    n_valores <- length(valores)
    u_xpt <- if (!is.finite(sigma_pt) || n_valores == 0) NA_real_ else 1.25 * sigma_pt / sqrt(n_valores)

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
