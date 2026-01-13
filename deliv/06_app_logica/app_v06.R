# ===================================================================
# Titulo: app_v06.R
# Entregable: 06
# Descripcion: Aplicación Shiny con lógica de negocio, sin gráficos
# Entrada: data/homogeneity.csv, stability.csv, summary_n4.csv, participants_data4.csv
# Salida: Tablas de resultados, descargas CSV
# ===================================================================

# -------------------------------------------------------------------
# Librerías requeridas
# -------------------------------------------------------------------
library(shiny)
library(DT)
library(dplyr)
library(tidyr)
library(outliers)

# -------------------------------------------------------------------
# Carga fija de datos (sin fileInput)
# -------------------------------------------------------------------
hom_data <- if (file.exists("../data/homogeneity.csv")) {
  read.csv("../data/homogeneity.csv")
} else if (file.exists("../../data/homogeneity.csv")) {
  read.csv("../../data/homogeneity.csv")
} else {
  read.csv("../../../data/homogeneity.csv")
}

stab_data <- if (file.exists("../data/stability.csv")) {
  read.csv("../data/stability.csv")
} else if (file.exists("../../data/stability.csv")) {
  read.csv("../../data/stability.csv")
} else {
  read.csv("../../../data/stability.csv")
}

summary_data <- if (file.exists("../data/summary_n4.csv")) {
  read.csv("../data/summary_n4.csv")
} else if (file.exists("../../data/summary_n4.csv")) {
  read.csv("../../data/summary_n4.csv")
} else {
  read.csv("../../../data/summary_n4.csv")
}

participants_data <- if (file.exists("../data/participants_data4.csv")) {
  suppressWarnings(read.csv("../data/participants_data4.csv"))
} else if (file.exists("../../data/participants_data4.csv")) {
  suppressWarnings(read.csv("../../data/participants_data4.csv"))
} else {
  suppressWarnings(read.csv("../../../data/participants_data4.csv"))
}

summary_data$n_lab <- 4

# -------------------------------------------------------------------
# Funciones robustas ISO 13528 (pt_robust_stats.R)
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
        error = "Los pesos calculados no son válidos para el Algoritmo A.",
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
        error = "El Algoritmo A colapsó por desviación estándar cero.",
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
# Funciones ISO 13528 para homogeneidad y estabilidad (pt_homogeneity.R)
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
    return(list(error = "Se requieren al menos 2 réplicas por muestra para evaluar homogeneidad."))
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
  0.3 * sigma_pt
}

calculate_homogeneity_criterion_expanded <- function(sigma_pt, sw_sq) {
  c_criterion <- 0.3 * sigma_pt
  sigma_allowed_sq <- c_criterion^2
  sqrt(sigma_allowed_sq * 1.88 + sw_sq * 1.01)
}

evaluate_homogeneity <- function(ss, c_criterion, c_expanded = NULL) {
  passes_criterion <- ss <= c_criterion

  conclusion1 <- if (passes_criterion) {
    sprintf("ss (%.4f) <= criterio (%.4f): CUMPLE CRITERIO DE HOMOGENEIDAD", ss, c_criterion)
  } else {
    sprintf("ss (%.4f) > criterio (%.4f): NO CUMPLE CRITERIO DE HOMOGENEIDAD", ss, c_criterion)
  }

  passes_expanded <- NA
  conclusion2 <- NULL

  if (!is.null(c_expanded)) {
    passes_expanded <- ss <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("ss (%.4f) <= expandido (%.4f): CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
    } else {
      sprintf("ss (%.4f) > expandido (%.4f): NO CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
    }
  }

  list(
    passes_criterion = passes_criterion,
    passes_expanded = passes_expanded,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

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
  0.3 * sigma_pt
}

calculate_stability_criterion_expanded <- function(c_criterion, u_hom_mean, u_stab_mean) {
  c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
}

evaluate_stability <- function(diff_hom_stab, c_criterion, c_expanded = NULL) {
  passes_criterion <- diff_hom_stab <= c_criterion

  conclusion1 <- if (passes_criterion) {
    sprintf("diff (%.4f) <= criterio (%.4f): CUMPLE CRITERIO DE ESTABILIDAD", diff_hom_stab, c_criterion)
  } else {
    sprintf("diff (%.4f) > criterio (%.4f): NO CUMPLE CRITERIO DE ESTABILIDAD", diff_hom_stab, c_criterion)
  }

  passes_expanded <- NA
  conclusion2 <- NULL

  if (!is.null(c_expanded)) {
    passes_expanded <- diff_hom_stab <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("diff (%.4f) <= expandido (%.4f): CUMPLE CRITERIO EXPANDIDO", diff_hom_stab, c_expanded)
    } else {
      sprintf("diff (%.4f) > expandido (%.4f): NO CUMPLE CRITERIO EXPANDIDO", diff_hom_stab, c_expanded)
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

calculate_u_stab <- function(diff_hom_stab, c_criterion) {
  if (diff_hom_stab <= c_criterion) {
    return(0)
  }
  diff_hom_stab / sqrt(3)
}

# -------------------------------------------------------------------
# Funciones ISO 13528 para puntajes (pt_scores.R)
# -------------------------------------------------------------------
calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / sigma_pt
}

calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominator <- sqrt(sigma_pt^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominator <- sqrt(u_x^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominator <- sqrt(U_x^2 + U_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

evaluate_z_score <- function(z) {
  if (!is.finite(z)) {
    return("N/A")
  }
  if (abs(z) <= 2) {
    return("Satisfactorio")
  } else if (abs(z) < 3) {
    return("Cuestionable")
  }
  return("No satisfactorio")
}

evaluate_z_score_vec <- function(z) {
  dplyr::case_when(
    !is.finite(z) ~ "N/A",
    abs(z) <= 2 ~ "Satisfactorio",
    abs(z) > 2 & abs(z) < 3 ~ "Cuestionable",
    abs(z) >= 3 ~ "No satisfactorio"
  )
}

evaluate_en_score <- function(en) {
  if (!is.finite(en)) {
    return("N/A")
  }
  if (abs(en) <= 1) {
    return("Satisfactorio")
  }
  return("No satisfactorio")
}

evaluate_en_score_vec <- function(en) {
  dplyr::case_when(
    !is.finite(en) ~ "N/A",
    abs(en) <= 1 ~ "Satisfactorio",
    abs(en) > 1 ~ "No satisfactorio"
  )
}

PT_EN_CLASS_LABELS <- c(
  a1 = "a1 - Totalmente satisfactorio",
  a2 = "a2 - Satisfactorio pero conservador",
  a3 = "a3 - Satisfactorio con MU subestimada",
  a4 = "a4 - Cuestionable pero aceptable",
  a5 = "a5 - Cuestionable e inconsistente",
  a6 = "a6 - No satisfactorio pero la MU cubre la desviación",
  a7 = "a7 - No satisfactorio (crítico)"
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

# -------------------------------------------------------------------
# Funciones auxiliares de la aplicación
# -------------------------------------------------------------------
format_num <- function(x, digits = 5) {
  ifelse(is.na(x), NA_character_, sprintf(paste0("%.", digits, "f"), x))
}

get_wide_data <- function(df, target_pollutant) {
  filtered <- df %>% filter(pollutant == target_pollutant)
  if (is.null(filtered) || nrow(filtered) == 0) {
    return(NULL)
  }
  if (!"value" %in% names(filtered)) {
    return(NULL)
  }
  filtered %>%
    select(-pollutant) %>%
    pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}

compute_homogeneity_metrics <- function(df, target_pollutant, target_level) {
  wide_df <- get_wide_data(df, target_pollutant)
  if (is.null(wide_df)) {
    return(list(error = sprintf("No se encontraron datos de homogeneidad para el analito '%s'.", target_pollutant)))
  }
  if (!"level" %in% names(wide_df)) {
    return(list(error = "La columna 'level' no se encuentra en los datos cargados."))
  }
  if (!(target_level %in% unique(wide_df$level))) {
    return(list(error = sprintf("El nivel '%s' no existe para el analito '%s'.", target_level, target_pollutant)))
  }

  level_data <- wide_df %>%
    filter(level == target_level) %>%
    select(starts_with("sample_"))

  g <- nrow(level_data)
  m <- ncol(level_data)

  if (m < 2) {
    return(list(error = "No hay suficientes réplicas para evaluar la homogeneidad."))
  }
  if (g < 2) {
    return(list(error = "No hay suficientes ítems para evaluar la homogeneidad."))
  }

  intermediate_df <- if (m == 2) {
    s1 <- level_data[[1]]
    s2 <- level_data[[2]]
    level_data %>%
      mutate(
        Item = row_number(),
        average = (s1 + s2) / 2,
        range = abs(s1 - s2)
      ) %>%
      select(Item, everything())
  } else {
    level_data %>%
      mutate(
        Item = row_number(),
        average = rowMeans(., na.rm = TRUE),
        range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
      ) %>%
      select(Item, everything())
  }

  hom_data_long <- level_data %>%
    mutate(Item = factor(row_number())) %>%
    pivot_longer(
      cols = -Item,
      names_to = "replicate",
      values_to = "Resultado"
    )

  if (!"sample_1" %in% names(level_data)) {
    return(list(error = "No se encontró la columna 'sample_1'."))
  }

  first_sample_results <- level_data %>% pull(sample_1)
  median_val <- median(first_sample_results, na.rm = TRUE)
  abs_diff_from_median <- abs(first_sample_results - median_val)
  median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
  mad_e <- 1.483 * median_abs_diff
  n_iqr <- calculate_niqr(first_sample_results)

  n_robust <- length(first_sample_results)
  u_xpt <- 1.25 * mad_e / sqrt(n_robust)

  hom_item_stats <- hom_data_long %>%
    group_by(Item) %>%
    summarise(
      mean = mean(Resultado, na.rm = TRUE),
      var = var(Resultado, na.rm = TRUE),
      diff = max(Resultado, na.rm = TRUE) - min(Resultado, na.rm = TRUE),
      .groups = "drop"
    )

  hom_x_t_bar <- mean(hom_item_stats$mean, na.rm = TRUE)
  hom_s_x_bar_sq <- var(hom_item_stats$mean, na.rm = TRUE)
  hom_s_xt <- sqrt(hom_s_x_bar_sq)

  hom_wt <- abs(hom_item_stats$diff)
  hom_sw <- sqrt(sum(hom_wt^2) / (2 * length(hom_wt)))

  hom_ss_sq <- abs(hom_s_xt^2 - ((hom_sw^2) / 2))
  hom_ss <- sqrt(hom_ss_sq)

  hom_sigma_pt <- mad_e
  hom_c_criterion <- 0.3 * hom_sigma_pt
  hom_sigma_allowed_sq <- hom_c_criterion^2
  hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)

  conclusion_text <- if (hom_ss <= hom_c_criterion) {
    sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
  } else {
    sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
  }

  list(
    ss = hom_ss,
    sw = hom_sw,
    conclusion = conclusion_text,
    g = g,
    m = m,
    sigma_allowed_sq = hom_sigma_allowed_sq,
    c_criterion = hom_c_criterion,
    c_criterion_expanded = hom_c_criterion_expanded,
    sigma_pt = hom_sigma_pt,
    median_val = median_val,
    median_abs_diff = median_abs_diff,
    n_iqr = n_iqr,
    u_xpt = u_xpt,
    n_robust = n_robust,
    item_means = hom_item_stats$mean,
    general_mean = hom_x_t_bar,
    sd_of_means = hom_s_xt,
    s_x_bar_sq = hom_s_x_bar_sq,
    s_w_sq = hom_sw^2,
    intermediate_df = intermediate_df,
    data_wide = wide_df,
    level = target_level,
    pollutant = target_pollutant,
    error = NULL
  )
}

compute_stability_metrics <- function(df, target_pollutant, target_level, hom_results) {
  wide_df <- get_wide_data(df, target_pollutant)
  if (is.null(wide_df)) {
    return(list(error = sprintf("No se encontraron datos de estabilidad para el analito '%s'.", target_pollutant)))
  }
  if (!"level" %in% names(wide_df)) {
    return(list(error = "La columna 'level' no se encuentra en el conjunto de datos de estabilidad."))
  }
  if (!(target_level %in% unique(wide_df$level))) {
    return(list(error = sprintf("El nivel '%s' no existe en los datos de estabilidad del analito '%s'.", target_level, target_pollutant)))
  }
  if (!is.null(hom_results$error)) {
    return(list(error = hom_results$error))
  }

  level_data <- wide_df %>%
    filter(level == target_level) %>%
    select(starts_with("sample_"))

  g <- nrow(level_data)
  m <- ncol(level_data)

  if (m < 2) {
    return(list(error = "No hay suficientes réplicas para evaluar la estabilidad."))
  }
  if (g < 2) {
    return(list(error = "No hay suficientes ítems para evaluar la estabilidad."))
  }

  intermediate_df <- if (m == 2) {
    s1 <- level_data[[1]]
    s2 <- level_data[[2]]
    level_data %>%
      mutate(
        Item = row_number(),
        average = (s1 + s2) / 2,
        range = abs(s1 - s2)
      ) %>%
      select(Item, everything())
  } else {
    level_data %>%
      mutate(
        Item = row_number(),
        average = rowMeans(., na.rm = TRUE),
        range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
      ) %>%
      select(Item, everything())
  }

  stab_data_long <- level_data %>%
    mutate(Item = factor(row_number())) %>%
    pivot_longer(
      cols = -Item,
      names_to = "replicate",
      values_to = "Resultado"
    )

  if (!"sample_1" %in% names(level_data)) {
    return(list(error = "No se encontró la columna 'sample_1' en estabilidad."))
  }

  first_sample_results <- level_data %>% pull(sample_1)
  median_val <- median(first_sample_results, na.rm = TRUE)
  abs_diff_from_median <- abs(first_sample_results - median_val)
  median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
  mad_e <- 1.483 * median_abs_diff
  stab_n_iqr <- calculate_niqr(first_sample_results)

  n_robust <- length(first_sample_results)
  u_xpt <- 1.25 * mad_e / sqrt(n_robust)

  stab_item_stats <- stab_data_long %>%
    group_by(Item) %>%
    summarise(
      mean = mean(Resultado, na.rm = TRUE),
      var = var(Resultado, na.rm = TRUE),
      diff = max(Resultado, na.rm = TRUE) - min(Resultado, na.rm = TRUE),
      .groups = "drop"
    )

  stab_x_t_bar <- mean(stab_item_stats$mean, na.rm = TRUE)
  diff_hom_stab <- abs(stab_x_t_bar - hom_results$general_mean)

  stab_s_x_bar_sq <- var(stab_item_stats$mean, na.rm = TRUE)
  stab_s_xt <- sqrt(stab_s_x_bar_sq)

  stab_wt <- abs(stab_item_stats$diff)
  stab_sw <- sqrt(sum(stab_wt^2) / (2 * length(stab_wt)))

  stab_ss_sq <- abs(stab_s_xt^2 - ((stab_sw^2) / 2))
  stab_ss <- sqrt(stab_ss_sq)

  stab_sigma_pt <- mad_e
  stab_c_criterion <- 0.3 * hom_results$sigma_pt
  stab_sigma_allowed_sq <- stab_c_criterion^2

  hom_values <- hom_results$data_wide %>%
    select(starts_with("sample_")) %>%
    unlist() %>%
    as.numeric()
  hom_values <- hom_values[!is.na(hom_values)]
  sd_hom_mean <- sd(hom_values)
  n_hom <- length(hom_values)
  u_hom_mean <- sd_hom_mean / sqrt(n_hom)

  stab_values <- stab_data_long$Resultado
  stab_values <- stab_values[!is.na(stab_values)]
  sd_stab_mean <- sd(stab_values)
  n_stab <- length(stab_values)
  u_stab_mean <- sd_stab_mean / sqrt(n_stab)

  stab_c_criterion_expanded <- stab_c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)

  conclusion_text <- if (diff_hom_stab <= stab_c_criterion) {
    sprintf("diff (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
  } else {
    sprintf("diff (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
  }

  list(
    stab_ss = stab_ss,
    stab_sw = stab_sw,
    stab_conclusion = conclusion_text,
    g = g,
    m = m,
    diff_hom_stab = diff_hom_stab,
    stab_sigma_allowed_sq = stab_sigma_allowed_sq,
    stab_c_criterion = stab_c_criterion,
    stab_c_criterion_expanded = stab_c_criterion_expanded,
    stab_sigma_pt = stab_sigma_pt,
    stab_median_val = median_val,
    stab_median_abs_diff = median_abs_diff,
    stab_n_iqr = stab_n_iqr,
    stab_u_xpt = u_xpt,
    n_robust = n_robust,
    stab_item_means = stab_item_stats$mean,
    stab_general_mean = stab_x_t_bar,
    stab_sd_of_means = stab_s_xt,
    stab_s_x_bar_sq = stab_s_x_bar_sq,
    stab_s_w_sq = stab_sw^2,
    stab_intermediate_df = intermediate_df,
    data_wide = wide_df,
    level = target_level,
    pollutant = target_pollutant,
    error = NULL
  )
}

compute_scores_metrics <- function(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k, m = NULL) {
  if (is.null(summary_df) || nrow(summary_df) == 0) {
    return(list(error = "No hay datos resumen disponibles para los puntajes PT."))
  }

  data <- summary_df %>%
    filter(
      pollutant == target_pollutant,
      n_lab == target_n_lab,
      level == target_level
    )

  if (nrow(data) == 0) {
    return(list(error = "No se encontraron datos para los criterios seleccionados."))
  }

  ref_data <- data %>% filter(participant_id == "ref")

  if (nrow(ref_data) == 0) {
    return(list(error = "No se encontraron datos de referencia ('ref') para este nivel."))
  }

  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  participant_data <- data

  participant_data <- participant_data %>%
    rename(result = mean_value) %>%
    mutate(uncertainty_std = if (!is.null(m) && m > 0) sd_value / sqrt(m) else sd_value)

  final_scores <- participant_data %>%
    mutate(
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      z_score = (result - x_pt) / sigma_pt,
      z_prime_score = (result - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
      zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
      U_xi = k * uncertainty_std,
      U_xpt = k * u_xpt,
      En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
    ) %>%
    mutate(
      z_score_eval = case_when(
        abs(z_score) <= 2 ~ "Satisfactorio",
        abs(z_score) > 2 & abs(z_score) < 3 ~ "Cuestionable",
        abs(z_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      z_prime_score_eval = case_when(
        abs(z_prime_score) <= 2 ~ "Satisfactorio",
        abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Cuestionable",
        abs(z_prime_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      zeta_score_eval = case_when(
        abs(zeta_score) <= 2 ~ "Satisfactorio",
        abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Cuestionable",
        abs(zeta_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      En_score_eval = case_when(
        abs(En_score) <= 1 ~ "Satisfactorio",
        abs(En_score) > 1 ~ "No satisfactorio",
        TRUE ~ "N/A"
      )
    )

  list(
    error = NULL,
    scores = final_scores,
    x_pt = x_pt,
    sigma_pt = sigma_pt,
    u_xpt = u_xpt,
    k = k,
    pollutant = target_pollutant,
    n_lab = target_n_lab,
    level = target_level
  )
}

compute_grubbs_summary <- function(summary_df) {
  if (is.null(summary_df) || nrow(summary_df) == 0) {
    return(data.frame())
  }

  combos <- summary_df %>% distinct(pollutant, n_lab, level)
  results_list <- list()

  for (i in seq_len(nrow(combos))) {
    pol <- combos$pollutant[i]
    n <- combos$n_lab[i]
    lev <- combos$level[i]

    subset_data <- summary_df %>%
      filter(pollutant == pol, n_lab == n, level == lev, participant_id != "ref")

    n_eval <- nrow(subset_data)
    p_val <- NA
    outliers_detected <- 0
    outlier_participant <- "NA"
    outlier_value <- "NA"

    if (n_eval >= 3) {
      tryCatch(
        {
          test_res <- outliers::grubbs.test(subset_data$mean_value)
          p_val <- test_res$p.value

          if (p_val < 0.05) {
            outliers_detected <- 1
            vals <- subset_data$mean_value
            mean_val <- mean(vals)
            sd_val <- sd(vals)
            z_vals <- abs(vals - mean_val) / sd_val
            idx_max <- which.max(z_vals)
            outlier_val_num <- vals[idx_max]
            outlier_participant <- subset_data$participant_id[idx_max]
            outlier_value <- as.character(round(outlier_val_num, 3))
          }
        },
        error = function(e) {
        }
      )
    }

    results_list[[i]] <- data.frame(
      Contaminante = pol,
      Nivel = lev,
      Participantes_Evaluados = n_eval,
      Valor_p = ifelse(is.na(p_val), "NA", sprintf("%.4f", p_val)),
      Atipicos_detectados = outliers_detected,
      Participante = outlier_participant,
      Valor_Atipico = outlier_value,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, results_list)
}

compute_assigned_values <- function(summary_df) {
  if (is.null(summary_df) || nrow(summary_df) == 0) {
    return(data.frame())
  }

  combos <- summary_df %>% distinct(pollutant, n_lab, level)
  results_list <- list()

  for (i in seq_len(nrow(combos))) {
    pol <- combos$pollutant[i]
    n <- combos$n_lab[i]
    lev <- combos$level[i]

    subset_data <- summary_df %>%
      filter(pollutant == pol, n_lab == n, level == lev)

    ref_data <- subset_data %>% filter(participant_id == "ref")
    part_data <- subset_data %>% filter(participant_id != "ref")

    xpt_ref <- if (nrow(ref_data) > 0) mean(ref_data$mean_value, na.rm = TRUE) else NA_real_
    sigma_ref <- if (nrow(ref_data) > 0) mean(ref_data$sd_value, na.rm = TRUE) else NA_real_
    u_ref <- if (nrow(ref_data) > 0) mean(ref_data$sd_value, na.rm = TRUE) else NA_real_

    vals <- part_data$mean_value
    made <- if (length(vals) > 0) calculate_mad_e(vals) else NA_real_
    niqr <- if (length(vals) > 0) calculate_niqr(vals) else NA_real_

    algo <- if (length(vals) >= 3) run_algorithm_a(vals, part_data$participant_id) else list(error = "Datos insuficientes")

    results_list[[length(results_list) + 1]] <- data.frame(
      Contaminante = pol,
      Nivel = lev,
      Metodo = "Referencia (1)",
      x_pt = xpt_ref,
      u_xpt = u_ref,
      sigma_pt = sigma_ref,
      stringsAsFactors = FALSE
    )
    results_list[[length(results_list) + 1]] <- data.frame(
      Contaminante = pol,
      Nivel = lev,
      Metodo = "Consenso MADe (2a)",
      x_pt = ifelse(is.na(made), NA, median(vals, na.rm = TRUE)),
      u_xpt = ifelse(is.na(made), NA, 1.25 * made / sqrt(length(vals))),
      sigma_pt = made,
      stringsAsFactors = FALSE
    )
    results_list[[length(results_list) + 1]] <- data.frame(
      Contaminante = pol,
      Nivel = lev,
      Metodo = "Consenso nIQR (2b)",
      x_pt = ifelse(is.na(niqr), NA, median(vals, na.rm = TRUE)),
      u_xpt = ifelse(is.na(niqr), NA, 1.25 * niqr / sqrt(length(vals))),
      sigma_pt = niqr,
      stringsAsFactors = FALSE
    )
    results_list[[length(results_list) + 1]] <- data.frame(
      Contaminante = pol,
      Nivel = lev,
      Metodo = "Algoritmo A (3)",
      x_pt = if (!is.null(algo$error)) NA_real_ else algo$assigned_value,
      u_xpt = if (!is.null(algo$error)) NA_real_ else 1.25 * algo$robust_sd / sqrt(length(vals)),
      sigma_pt = if (!is.null(algo$error)) NA_real_ else algo$robust_sd,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, results_list)
}

get_assigned_params <- function(summary_df, target_pollutant, target_n_lab, target_level, metodo) {
  subset_data <- summary_df %>%
    filter(pollutant == target_pollutant, n_lab == target_n_lab, level == target_level)

  ref_data <- subset_data %>% filter(participant_id == "ref")
  part_data <- subset_data %>% filter(participant_id != "ref")
  vals <- part_data$mean_value

  if (metodo == "Referencia (1)") {
    x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
    sigma_pt <- mean(ref_data$sd_value, na.rm = TRUE)
    u_xpt <- mean(ref_data$sd_value, na.rm = TRUE)
  } else if (metodo == "Consenso MADe (2a)") {
    x_pt <- median(vals, na.rm = TRUE)
    sigma_pt <- calculate_mad_e(vals)
    u_xpt <- 1.25 * sigma_pt / sqrt(length(vals))
  } else if (metodo == "Consenso nIQR (2b)") {
    x_pt <- median(vals, na.rm = TRUE)
    sigma_pt <- calculate_niqr(vals)
    u_xpt <- 1.25 * sigma_pt / sqrt(length(vals))
  } else {
    algo <- run_algorithm_a(vals, part_data$participant_id)
    x_pt <- algo$assigned_value
    sigma_pt <- algo$robust_sd
    u_xpt <- 1.25 * sigma_pt / sqrt(length(vals))
  }

  list(x_pt = x_pt, sigma_pt = sigma_pt, u_xpt = u_xpt)
}

# -------------------------------------------------------------------
# Interfaz de usuario
# -------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Aplicación de Ensayos de Aptitud - Lógica de negocio"),
  h4("Versión sin gráficos"),
  tabsetPanel(
    tabPanel(
      "Homogeneidad y estabilidad",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          selectInput("hs_pollutant", "Seleccionar analito", choices = sort(unique(hom_data$pollutant))),
          uiOutput("hs_level_ui")
        ),
        mainPanel(
          width = 9,
          h4("Resumen homogeneidad"),
          dataTableOutput("hom_summary_table"),
          downloadButton("download_hom_summary", "Descargar resumen homogeneidad"),
          hr(),
          h4("Detalles por ítem"),
          dataTableOutput("hom_items_table"),
          downloadButton("download_hom_items", "Descargar detalles homogeneidad"),
          hr(),
          h4("Resumen estabilidad"),
          dataTableOutput("stab_summary_table"),
          downloadButton("download_stab_summary", "Descargar resumen estabilidad")
        )
      )
    ),
    tabPanel(
      "Valores atípicos",
      h4("Resumen de prueba de Grubbs"),
      dataTableOutput("grubbs_table"),
      downloadButton("download_grubbs", "Descargar resumen de atípicos")
    ),
    tabPanel(
      "Valor asignado",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          selectInput(
            "assigned_method",
            "Método",
            choices = c("Referencia (1)", "Consenso MADe (2a)", "Consenso nIQR (2b)", "Algoritmo A (3)")
          )
        ),
        mainPanel(
          width = 9,
          h4("Tabla de valores asignados"),
          dataTableOutput("assigned_table"),
          downloadButton("download_assigned", "Descargar valores asignados")
        )
      )
    ),
    tabPanel(
      "Puntajes PT",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          selectInput("scores_method", "Método", choices = c("Referencia (1)", "Consenso MADe (2a)", "Consenso nIQR (2b)", "Algoritmo A (3)")),
          selectInput("scores_pollutant", "Analito", choices = sort(unique(summary_data$pollutant))),
          uiOutput("scores_level_ui"),
          numericInput("scores_k", "Factor de cobertura (k)", value = 2, min = 1, max = 3, step = 0.1),
          numericInput("scores_m", "Número de réplicas (m)", value = 1, min = 1, step = 1)
        ),
        mainPanel(
          width = 9,
          h4("Resultados de puntajes"),
          dataTableOutput("scores_table"),
          downloadButton("download_scores", "Descargar puntajes"),
          hr(),
          h4("Resumen de evaluación"),
          dataTableOutput("scores_summary_table")
        )
      )
    ),
    tabPanel(
      "Participantes",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          selectInput("participant_id", "Participante", choices = sort(unique(summary_data$participant_id))),
          selectInput("participant_method", "Método", choices = c("Referencia (1)", "Consenso MADe (2a)", "Consenso nIQR (2b)", "Algoritmo A (3)")),
          selectInput("participant_pollutant", "Analito", choices = sort(unique(summary_data$pollutant))),
          uiOutput("participant_level_ui")
        ),
        mainPanel(
          width = 9,
          h4("Instrumentación reportada"),
          dataTableOutput("participants_table"),
          downloadButton("download_participants", "Descargar instrumentación"),
          hr(),
          h4("Resultados del participante"),
          dataTableOutput("participant_scores_table")
        )
      )
    )
  )
)

# -------------------------------------------------------------------
# Lógica del servidor
# -------------------------------------------------------------------
server <- function(input, output, session) {
  output$hs_level_ui <- renderUI({
    levels <- hom_data %>%
      filter(pollutant == input$hs_pollutant) %>%
      distinct(level) %>%
      arrange(level) %>%
      pull(level)
    selectInput("hs_level", "Seleccionar nivel", choices = levels)
  })

  hom_results <- reactive({
    req(input$hs_pollutant, input$hs_level)
    compute_homogeneity_metrics(hom_data, input$hs_pollutant, input$hs_level)
  })

  stab_results <- reactive({
    req(input$hs_pollutant, input$hs_level)
    hom_res <- hom_results()
    if (!is.null(hom_res$error)) {
      return(hom_res)
    }
    compute_stability_metrics(stab_data, input$hs_pollutant, input$hs_level, hom_res)
  })

  output$hom_summary_table <- renderDataTable({
    res <- hom_results()
    validate(need(is.null(res$error), res$error))

    summary_df <- data.frame(
      Metrica = c("ss", "sw", "c_criterion", "c_expanded", "sigma_pt"),
      Valor = c(res$ss, res$sw, res$c_criterion, res$c_criterion_expanded, res$sigma_pt),
      stringsAsFactors = FALSE
    )

    datatable(summary_df, options = list(pageLength = 5), rownames = FALSE)
  })

  output$hom_items_table <- renderDataTable({
    res <- hom_results()
    validate(need(is.null(res$error), res$error))
    datatable(res$intermediate_df, options = list(pageLength = 10), rownames = FALSE)
  })

  output$stab_summary_table <- renderDataTable({
    res <- stab_results()
    validate(need(is.null(res$error), res$error))

    summary_df <- data.frame(
      Metrica = c("diff_hom_stab", "c_criterion", "c_expanded", "sigma_pt"),
      Valor = c(res$diff_hom_stab, res$stab_c_criterion, res$stab_c_criterion_expanded, res$stab_sigma_pt),
      stringsAsFactors = FALSE
    )

    datatable(summary_df, options = list(pageLength = 5), rownames = FALSE)
  })

  output$download_hom_summary <- downloadHandler(
    filename = function() "homogeneidad_resumen.csv",
    content = function(file) {
      res <- hom_results()
      summary_df <- data.frame(
        Metrica = c("ss", "sw", "c_criterion", "c_expanded", "sigma_pt"),
        Valor = c(res$ss, res$sw, res$c_criterion, res$c_criterion_expanded, res$sigma_pt),
        stringsAsFactors = FALSE
      )
      write.csv(summary_df, file, row.names = FALSE)
    }
  )

  output$download_hom_items <- downloadHandler(
    filename = function() "homogeneidad_detalle.csv",
    content = function(file) {
      res <- hom_results()
      write.csv(res$intermediate_df, file, row.names = FALSE)
    }
  )

  output$download_stab_summary <- downloadHandler(
    filename = function() "estabilidad_resumen.csv",
    content = function(file) {
      res <- stab_results()
      summary_df <- data.frame(
        Metrica = c("diff_hom_stab", "c_criterion", "c_expanded", "sigma_pt"),
        Valor = c(res$diff_hom_stab, res$stab_c_criterion, res$stab_c_criterion_expanded, res$stab_sigma_pt),
        stringsAsFactors = FALSE
      )
      write.csv(summary_df, file, row.names = FALSE)
    }
  )

  grubbs_data <- reactive({
    compute_grubbs_summary(summary_data)
  })

  output$grubbs_table <- renderDataTable({
    datatable(grubbs_data(), options = list(pageLength = 10), rownames = FALSE)
  })

  output$download_grubbs <- downloadHandler(
    filename = function() "valores_atipicos_grubbs.csv",
    content = function(file) {
      write.csv(grubbs_data(), file, row.names = FALSE)
    }
  )

  assigned_values <- reactive({
    compute_assigned_values(summary_data)
  })

  output$assigned_table <- renderDataTable({
    datos <- assigned_values() %>% filter(Metodo == input$assigned_method)
    datatable(datos, options = list(pageLength = 10), rownames = FALSE)
  })

  output$download_assigned <- downloadHandler(
    filename = function() "valores_asignados.csv",
    content = function(file) {
      datos <- assigned_values() %>% filter(Metodo == input$assigned_method)
      write.csv(datos, file, row.names = FALSE)
    }
  )

  output$scores_level_ui <- renderUI({
    levels <- summary_data %>%
      filter(pollutant == input$scores_pollutant) %>%
      distinct(level) %>%
      arrange(level) %>%
      pull(level)
    selectInput("scores_level", "Nivel", choices = levels)
  })

  scores_results <- reactive({
    req(input$scores_pollutant, input$scores_level)
    params <- get_assigned_params(summary_data, input$scores_pollutant, 4, input$scores_level, input$scores_method)
    compute_scores_metrics(
      summary_df = summary_data,
      target_pollutant = input$scores_pollutant,
      target_n_lab = 4,
      target_level = input$scores_level,
      sigma_pt = params$sigma_pt,
      u_xpt = params$u_xpt,
      k = input$scores_k,
      m = input$scores_m
    )
  })

  output$scores_table <- renderDataTable({
    res <- scores_results()
    validate(need(is.null(res$error), res$error))
    datatable(res$scores, options = list(pageLength = 10), rownames = FALSE)
  })

  output$download_scores <- downloadHandler(
    filename = function() "puntajes_pt.csv",
    content = function(file) {
      res <- scores_results()
      if (!is.null(res$error)) {
        write.csv(data.frame(), file, row.names = FALSE)
      } else {
        write.csv(res$scores, file, row.names = FALSE)
      }
    }
  )

  output$scores_summary_table <- renderDataTable({
    res <- scores_results()
    validate(need(is.null(res$error), res$error))
    summary_df <- res$scores %>%
      summarise(
        Z_Satisfactorio = sum(z_score_eval == "Satisfactorio", na.rm = TRUE),
        Z_Cuestionable = sum(z_score_eval == "Cuestionable", na.rm = TRUE),
        Z_No_satisfactorio = sum(z_score_eval == "No satisfactorio", na.rm = TRUE),
        En_Satisfactorio = sum(En_score_eval == "Satisfactorio", na.rm = TRUE),
        En_No_satisfactorio = sum(En_score_eval == "No satisfactorio", na.rm = TRUE)
      )
    datatable(summary_df, options = list(pageLength = 5), rownames = FALSE)
  })

  output$participant_level_ui <- renderUI({
    levels <- summary_data %>%
      filter(pollutant == input$participant_pollutant) %>%
      distinct(level) %>%
      arrange(level) %>%
      pull(level)
    selectInput("participant_level", "Nivel", choices = levels)
  })

  output$participants_table <- renderDataTable({
    datatable(participants_data, options = list(pageLength = 5), rownames = FALSE)
  })

  output$download_participants <- downloadHandler(
    filename = function() "instrumentacion_participantes.csv",
    content = function(file) {
      write.csv(participants_data, file, row.names = FALSE)
    }
  )

  participant_scores <- reactive({
    req(input$participant_pollutant, input$participant_level, input$participant_method)
    params <- get_assigned_params(summary_data, input$participant_pollutant, 4, input$participant_level, input$participant_method)
    res <- compute_scores_metrics(
      summary_df = summary_data,
      target_pollutant = input$participant_pollutant,
      target_n_lab = 4,
      target_level = input$participant_level,
      sigma_pt = params$sigma_pt,
      u_xpt = params$u_xpt,
      k = 2,
      m = 1
    )
    if (!is.null(res$error)) {
      return(data.frame())
    }
    res$scores %>% filter(participant_id == input$participant_id)
  })

  output$participant_scores_table <- renderDataTable({
    datatable(participant_scores(), options = list(pageLength = 5), rownames = FALSE)
  })
}

shinyApp(ui, server)
