# PT Scoring Functions

#' Evaluate z-score
#'
#' @param z Numeric z-score
#' @return Character string: "Satisfactorio", "Cuestionable", "No satisfactorio", or "N/A"
score_eval_z <- function(z) {
  dplyr::case_when(
    !is.finite(z) ~ "N/A",
    abs(z) <= 2 ~ "Satisfactorio",
    abs(z) > 2 & abs(z) < 3 ~ "Cuestionable",
    abs(z) >= 3 ~ "No satisfactorio"
  )
}

#' Compute PT Scores Metrics
#'
#' @param summary_df Dataframe with summary statistics
#' @param target_pollutant Pollutant name
#' @param target_n_lab n_lab identifier
#' @param target_level Level identifier
#' @param sigma_pt SD for proficiency assessment
#' @param u_xpt Uncertainty of assigned value
#' @param k Coverage factor
#' @param m Number of replicates (for uncertainty calc)
#' @return List of results and scores dataframe
compute_scores_metrics <- function(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k, m = NULL) {
  if (is.null(summary_df) || nrow(summary_df) == 0) {
    return(list(error = "No hay datos resumen disponibles para los puntajes PT."))
  }

  data <- summary_df %>%
    dplyr::filter(
      pollutant == target_pollutant,
      n_lab == target_n_lab,
      level == target_level
    )

  if (nrow(data) == 0) {
    return(list(error = "No se encontraron datos para los criterios seleccionados."))
  }

  ref_data <- data %>% dplyr::filter(participant_id == "ref")

  if (nrow(ref_data) == 0) {
    return(list(error = "No se encontraron datos de referencia ('ref') para este nivel."))
  }

  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  participant_data <- data

  participant_data <- participant_data %>%
    dplyr::rename(result = mean_value) %>%
    dplyr::mutate(uncertainty_std = if (!is.null(m) && m > 0) sd_value / sqrt(m) else sd_value)

  final_scores <- participant_data %>%
    dplyr::mutate(
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      z_score = (result - x_pt) / sigma_pt,
      z_prime_score = (result - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
      zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
      U_xi = k * uncertainty_std,
      U_xpt = k * u_xpt,
      En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
    ) %>%
    dplyr::mutate(
      z_score_eval = dplyr::case_when(
        abs(z_score) <= 2 ~ "Satisfactorio",
        abs(z_score) > 2 & abs(z_score) < 3 ~ "Cuestionable",
        abs(z_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      z_prime_score_eval = dplyr::case_when(
        abs(z_prime_score) <= 2 ~ "Satisfactorio",
        abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Cuestionable",
        abs(z_prime_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      zeta_score_eval = dplyr::case_when(
        abs(zeta_score) <= 2 ~ "Satisfactorio",
        abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Cuestionable",
        abs(zeta_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      En_score_eval = dplyr::case_when(
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

#' Compute Scores for a specific combination (Method + Data)
#'
#' @param participants_df DataFrame of participant results
#' @param x_pt Assigned value
#' @param sigma_pt SD for proficiency assessment
#' @param u_xpt Uncertainty of assigned value
#' @param combo_meta List with 'title' and 'label'
#' @param k Coverage factor
#' @param u_hom Homogeneity uncertainty component
#' @param u_stab Stability uncertainty component
#' @return List with results
compute_combo_scores <- function(participants_df, x_pt, sigma_pt, u_xpt, combo_meta, k = 2, u_hom = 0, u_stab = 0) {
  x_pt_def <- x_pt
  u_xpt_def <- sqrt(u_xpt^2 + u_hom^2 + u_stab^2)

  if (!is.finite(x_pt_def)) {
    return(list(
      error = sprintf("Valor asignado no disponible para %s.", combo_meta$title)
    ))
  }

  if (!is.finite(u_xpt_def) || u_xpt_def < 0) {
    u_xpt_def <- 0
  }

  participants_df <- participants_df %>%
    dplyr::mutate(
      uncertainty_std_missing = !is.finite(uncertainty_std),
      uncertainty_std = ifelse(uncertainty_std_missing, NA_real_, uncertainty_std)
    )

  z_values <- (participants_df$result - x_pt_def) / sigma_pt
  zprime_den <- sqrt(sigma_pt^2 + u_xpt_def^2)
  z_prime_values <- if (zprime_den > 0) {
    (participants_df$result - x_pt_def) / zprime_den
  } else {
    NA_real_
  }
  zeta_den <- sqrt(participants_df$uncertainty_std^2 + u_xpt_def^2)
  zeta_values <- ifelse(zeta_den > 0, (participants_df$result - x_pt_def) / zeta_den, NA_real_)
  U_xi <- k * participants_df$uncertainty_std
  U_xpt <- k * u_xpt_def
  en_den <- sqrt(U_xi^2 + U_xpt^2)
  en_values <- ifelse(en_den > 0, (participants_df$result - x_pt_def) / en_den, NA_real_)

  data <- participants_df %>%
    dplyr::mutate(
      combination = combo_meta$title,
      combination_label = combo_meta$label,
      x_pt = x_pt_def,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      u_xpt_def = u_xpt_def,
      u_hom = u_hom,
      u_stab = u_stab,
      k_factor = k,
      z_score = z_values,
      z_score_eval = score_eval_z(z_score),
      z_prime_score = z_prime_values,
      z_prime_score_eval = score_eval_z(z_prime_score),
      zeta_score = zeta_values,
      zeta_score_eval = score_eval_z(zeta_score),
      En_score = en_values,
      En_score_eval = dplyr::case_when(
        !is.finite(En_score) ~ "N/A",
        abs(En_score) <= 1 ~ "Satisfactorio",
        abs(En_score) > 1 ~ "No satisfactorio"
      ),
      U_xi = U_xi,
      U_xpt = U_xpt
    )

  list(
    error = NULL,
    title = combo_meta$title,
    label = combo_meta$label,
    x_pt = x_pt_def,
    x_pt_def = x_pt_def,
    sigma_pt = sigma_pt,
    u_xpt = u_xpt,
    u_xpt_def = u_xpt_def,
    u_hom = u_hom,
    u_stab = u_stab,
    data = data
  )
}

#' Score combination metadata
#' @export
score_combo_info <- list(
  ref = list(title = "Referencia (1)", label = "1"),
  consensus_ma = list(title = "Consenso MADe (2a)", label = "2a"),
  consensus_niqr = list(title = "Consenso nIQR (2b)", label = "2b"),
  algo = list(title = "Algoritmo A (3)", label = "3")
)

#' Compute scores for all methods for a specific selection
#'
#' @param target_pollutant Pollutant name
#' @param target_n_lab n_lab identifier
#' @param target_level Level identifier
#' @param summary_data Dataframe with summary data
#' @param hom_data_full Dataframe with homogeneity data
#' @param stab_data_full Dataframe with stability data
#' @param max_iter Max iterations for Algo A
#' @param k_factor Coverage factor
#' @return List of results
compute_scores_for_selection <- function(target_pollutant, target_n_lab, target_level, summary_data, hom_data_full, stab_data_full, max_iter = 50, k_factor = 2) {
  subset_data <- summary_data %>%
    dplyr::filter(
      pollutant == target_pollutant,
      n_lab == target_n_lab,
      level == target_level
    )

  if (nrow(subset_data) == 0) {
    return(list(error = "No se encontraron datos para la combinación seleccionada."))
  }

  hom_res <- tryCatch(
    compute_homogeneity_metrics(target_pollutant, target_level, hom_data_full),
    error = function(e) list(error = conditionMessage(e))
  )
  if (!is.null(hom_res$error)) {
    return(list(error = paste("Error obteniendo parámetros de homogeneidad:", hom_res$error)))
  }
  sigma_pt1 <- hom_res$sigma_pt
  u_xpt1 <- hom_res$u_xpt

  participant_data <- subset_data %>%
    dplyr::filter(participant_id != "ref") %>%
    dplyr::group_by(participant_id) %>%
    dplyr::summarise(
      result = mean(mean_value, na.rm = TRUE),
      sd_value = mean(sd_value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      pollutant = target_pollutant,
      n_lab = target_n_lab,
      level = target_level,
      uncertainty_std = if (!is.null(hom_res$m) && hom_res$m > 0) sd_value / sqrt(hom_res$m) else sd_value
    )

  if (nrow(participant_data) == 0) {
    return(list(error = "No se encontraron participantes (distintos al valor de referencia) para la combinación seleccionada."))
  }

  ref_data <- subset_data %>% dplyr::filter(participant_id == "ref")
  if (nrow(ref_data) == 0) {
    return(list(error = "No se encontró información del participante de referencia para esta combinación."))
  }
  x_pt1 <- mean(ref_data$mean_value, na.rm = TRUE)

  # Calculate u_hom
  u_hom_val <- hom_res$ss

  # Calculate u_stab
  stab_res <- tryCatch(
    compute_stability_metrics(target_pollutant, target_level, hom_res, stab_data_full),
    error = function(e) list(error = conditionMessage(e))
  )

  u_stab_val <- 0
  if (is.null(stab_res$error)) {
    y1 <- hom_res$general_mean
    y2 <- stab_res$stab_general_mean
    d_max <- abs(y1 - y2)
    u_stab_val <- d_max / sqrt(3)
  }

  values <- participant_data$result
  n_part <- length(values)

  median_val <- median(values, na.rm = TRUE)
  mad_val <- median(abs(values - median_val), na.rm = TRUE)
  sigma_pt_2a <- 1.483 * mad_val
  sigma_pt_2b <- calculate_niqr(values)
  u_xpt2a <- if (is.finite(sigma_pt_2a)) 1.25 * sigma_pt_2a / sqrt(n_part) else NA_real_
  u_xpt2b <- if (is.finite(sigma_pt_2b)) 1.25 * sigma_pt_2b / sqrt(n_part) else NA_real_

  algo_res <- if (n_part >= 3) {
    run_algorithm_a(values = values, ids = participant_data$participant_id, max_iter = max_iter)
  } else {
    list(error = "Se requieren al menos tres participantes para calcular el Algoritmo A.")
  }

  combos <- list()
  combos$ref <- compute_combo_scores(participant_data, x_pt1, sigma_pt1, u_xpt1, score_combo_info$ref, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)
  combos$consensus_ma <- compute_combo_scores(participant_data, median_val, sigma_pt_2a, u_xpt2a, score_combo_info$consensus_ma, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)
  combos$consensus_niqr <- compute_combo_scores(participant_data, median_val, sigma_pt_2b, u_xpt2b, score_combo_info$consensus_niqr, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)

  if (is.null(algo_res$error)) {
    u_xpt3 <- 1.25 * algo_res$robust_sd / sqrt(n_part)
    combos$algo <- compute_combo_scores(participant_data, algo_res$assigned_value, algo_res$robust_sd, u_xpt3, score_combo_info$algo, k = k_factor, u_hom = u_hom_val, u_stab = u_stab_val)
  } else {
    combos$algo <- list(error = algo_res$error, title = score_combo_info$algo$title, label = score_combo_info$algo$label)
  }

  summary_table <- purrr::map_dfr(names(score_combo_info), function(key) {
    meta <- score_combo_info[[key]]
    combo <- combos[[key]]
    if (is.null(combo)) {
      return(NULL)
    }
    if (!is.null(combo$error)) {
      tibble::tibble(
        Combinación = meta$title,
        Etiqueta = meta$label,
        `x_pt` = NA_real_,
        `x_pt_def` = NA_real_,
        `sigma_pt` = NA_real_,
        `u(x_pt)` = NA_real_,
        `u(x_pt)_def` = NA_real_,
        Nota = combo$error
      )
    } else {
      tibble::tibble(
        Combinación = combo$title,
        Etiqueta = combo$label,
        `x_pt` = combo$x_pt,
        `x_pt_def` = combo$x_pt_def,
        `sigma_pt` = combo$sigma_pt,
        `u(x_pt)` = combo$u_xpt,
        `u(x_pt)_def` = combo$u_xpt_def,
        Nota = ""
      )
    }
  })

  overview_table <- purrr::map_dfr(names(score_combo_info), function(key) {
    meta <- score_combo_info[[key]]
    combo <- combos[[key]]
    if (is.null(combo)) {
      return(NULL)
    }
    if (!is.null(combo$error)) {
      tibble::tibble(
        Combinación = meta$title,
        Participante = NA_character_,
        Resultado = NA_real_,
        `u(xi)` = NA_real_,
        `Puntaje z` = NA_real_,
        `Evaluación z` = combo$error,
        `Puntaje z'` = NA_real_,
        `Evaluación z'` = "",
        `Puntaje zeta` = NA_real_,
        `Evaluación zeta` = "",
        `Puntaje En` = NA_real_,
        `Puntaje En Eval` = ""
      )
    } else {
      combo$data %>%
        dplyr::transmute(
          Combinación = combo$title,
          Participante = participant_id,
          Resultado = result,
          `u(xi)` = uncertainty_std,
          `Puntaje z` = z_score,
          `Evaluación z` = z_score_eval,
          `Puntaje z'` = z_prime_score,
          `Evaluación z'` = z_prime_score_eval,
          `Puntaje zeta` = zeta_score,
          `Evaluación zeta` = zeta_score_eval,
          `Puntaje En` = En_score,
          `Puntaje En Eval` = En_score_eval
        )
    }
  })

  list(
    error = NULL,
    combos = combos,
    summary = summary_table,
    overview = overview_table,
    k = k_factor
  )
}
