# generate_report_assets.R

# This script generates all the tables and charts needed for the reports.

# 1. Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(patchwork)
  library(vroom)
  library(DT)
  library(outliers)
})

# -------------------------------------------------------------------
# Helper Functions from app.R
# -------------------------------------------------------------------
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA_real_)
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

combined_scores_df <- tibble()

get_wide_data <- function(df, target_pollutant) {
    filtered <- df %>% filter(pollutant == target_pollutant)
    if (nrow(filtered) == 0) {
      return(NULL)
    }
    filtered %>%
      select(-pollutant) %>%
      pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}

# 2. Load data
hom_data_full <- read.csv("homogeneity.csv")
stab_data_full <- read.csv("stability.csv")
raw_summary_data <- read.csv("summary_n7.csv")

# --- Data Aggregation Step ---
# The raw summary data has one row per replicate (sample_group).
# We need to average these replicates for each participant at each level.
summary_data <- raw_summary_data %>%
  group_by(participant_id, pollutant, level) %>%
  summarise(
    mean_value = mean(mean_value, na.rm = TRUE),
    sd_value = mean(sd_value, na.rm = TRUE), # Taking the mean of SDs as a representative value
    .groups = 'drop'
  )
summary_data$n_lab <- 7 # Add n_lab column for consistency with app logic

# Create output directories
dir.create("reports/assets", showWarnings = FALSE)
dir.create("reports/assets/charts", showWarnings = FALSE)
dir.create("reports/assets/tables", showWarnings = FALSE)


# 3. Homogeneity and Stability Analysis
compute_homogeneity_metrics <- function(target_pollutant, target_level) {
    wide_df <- get_wide_data(hom_data_full, target_pollutant)
    if (is.null(wide_df)) {
      return(list(error = sprintf("No homogeneity data found for pollutant '%s'.", target_pollutant)))
    }
    if (!"level" %in% names(wide_df)) {
      return(list(error = "Column 'level' not found in the loaded data."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("Level '%s' not found for pollutant '%s'.", target_level, target_pollutant)))
    }

    level_data <- wide_df %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) {
      return(list(error = "Not enough replicate runs (at least 2 required) for homogeneity assessment."))
    }
    if (g < 2) {
      return(list(error = "Not enough items (at least 2 required) for homogeneity assessment."))
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

    hom_data <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt."))
    }

    first_sample_results <- level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff
    n_iqr <- calculate_niqr(first_sample_results)

    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)

    hom_item_stats <- hom_data %>%
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE),
        .groups = "drop"
      )

    hom_x_t_bar <- mean(hom_item_stats$mean, na.rm = TRUE)
    hom_s_x_bar_sq <- var(hom_item_stats$mean, na.rm = TRUE)
    hom_s_xt <- sqrt(hom_s_x_bar_sq)

    hom_wt <- abs(hom_item_stats$diff)
    hom_sw <- sqrt(sum(hom_wt^2) / (2 * length(hom_wt)))

    hom_ss_sq <- abs(hom_s_xt^2 - ((hom_sw^2) / 2))
    hom_ss <- sqrt(hom_ss_sq)

    hom_anova_summary <- data.frame(
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(hom_s_x_bar_sq * m * (g - 1), hom_sw^2 * g * (m - 1)),
      "Mean Sq" = c(hom_s_x_bar_sq * m, hom_sw^2),
      check.names = FALSE
    )
    rownames(hom_anova_summary) <- c("Item", "Residuals")

    hom_sigma_pt <- mad_e
    hom_c_criterion <- 0.3 * hom_sigma_pt
    hom_sigma_allowed_sq <- hom_c_criterion^2
    hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)

    if (hom_ss <= hom_c_criterion) {
      hom_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
    } else {
      hom_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", hom_ss, hom_c_criterion)
    }

    if (hom_ss <= hom_c_criterion_expanded) {
      hom_conclusion2 <- sprintf("ss (%.4f) <= c_expanded (%.4f): CUMPLE CRITERIO EXP HOMOGENEIDAD", hom_ss, hom_c_criterion_expanded)
    } else {
      hom_conclusion2 <- sprintf("ss (%.4f) > c_expanded (%.4f): NO CUMPLE CRITERIO EXP HOMOGENEIDAD", hom_ss, hom_c_criterion_expanded)
    }

    hom_conclusion <- paste(hom_conclusion1, hom_conclusion2, sep = "\n")

    list(
      summary = hom_anova_summary,
      ss = hom_ss,
      sw = hom_sw,
      conclusion = hom_conclusion,
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
      first_sample_results = first_sample_results,
      abs_diff_from_median = abs_diff_from_median,
      data_wide = wide_df,
      level = target_level,
      pollutant = target_pollutant,
      error = NULL
    )
  }

compute_stability_metrics <- function(target_pollutant, target_level, hom_results) {
    wide_df <- get_wide_data(stab_data_full, target_pollutant)
    if (is.null(wide_df)) {
      return(list(error = sprintf("No stability data found for pollutant '%s'.", target_pollutant)))
    }
    if (!"level" %in% names(wide_df)) {
      return(list(error = "Column 'level' not found in the stability dataset."))
    }
    if (!(target_level %in% unique(wide_df$level))) {
      return(list(error = sprintf("Level '%s' not found for stability data of pollutant '%s'.", target_level, target_pollutant)))
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
      return(list(error = "Not enough replicate runs (at least 2 required) for stability data homogeneity assessment."))
    }
    if (g < 2) {
      return(list(error = "Not enough items (at least 2 required) for stability data homogeneity assessment."))
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

    stab_data <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    if (!"sample_1" %in% names(level_data)) {
      return(list(error = "Column 'sample_1' not found. It is required to calculate sigma_pt for stability data."))
    }

    first_sample_results <- level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff
    stab_n_iqr <- calculate_niqr(first_sample_results)

    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)

    stab_item_stats <- stab_data %>%
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE),
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

    stab_anova_summary <- data.frame(
      "Df" = c(g - 1, g * (m - 1)),
      "Sum Sq" = c(stab_s_x_bar_sq * m * (g - 1), stab_sw^2 * g * (m - 1)),
      "Mean Sq" = c(stab_s_x_bar_sq * m, stab_sw^2),
      check.names = FALSE
    )
    rownames(stab_anova_summary) <- c("Item", "Residuals")

    stab_sigma_pt <- mad_e
    stab_c_criterion <- 0.3 * hom_results$sigma_pt
    stab_sigma_allowed_sq <- stab_c_criterion^2
    stab_c_criterion_expanded <- sqrt(stab_sigma_allowed_sq * 1.88 + (stab_sw^2) * 1.01)

    if (diff_hom_stab <= stab_c_criterion) {
      stab_conclusion1 <- sprintf("ss (%.4f) <= c_criterion (%.4f): CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
    } else {
      stab_conclusion1 <- sprintf("ss (%.4f) > c_criterion (%.4f): NO CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, stab_c_criterion)
    }

    list(
      stab_summary = stab_anova_summary,
      stab_ss = stab_ss,
      stab_sw = stab_sw,
      stab_conclusion = stab_conclusion1,
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


# 4. PT Preparation Analysis
compute_pt_prep_metrics <- function(summary_df, target_pollutant, target_level) {
    data <- summary_df %>%
      filter(
        pollutant == target_pollutant,
        level == target_level
      )

    if (nrow(data) == 0) {
        return(list(error = "No data found for the selected criteria."))
    }

    participants_data <- data %>% filter(participant_id != "ref")

    if (length(participants_data$mean_value) < 3) {
        grubbs_test_result <- "Grubbs' test requires at least 3 data points."
    } else {
        grubbs_test_result <- capture.output(grubbs.test(participants_data$mean_value))
    }

    list(
        data = data,
        grubbs = grubbs_test_result,
        error = NULL
    )
}

# 5. PT Scores Analysis (extended to match app calculations)

score_combo_info <- list(
  ref = list(title = "Referencia (1)", label = "1"),
  consensus_ma = list(title = "Consenso MADe (2a)", label = "2a"),
  consensus_niqr = list(title = "Consenso nIQR (2b)", label = "2b"),
  algo = list(title = "Algoritmo A (3)", label = "3")
)

score_eval_z <- function(z) {
  case_when(
    !is.finite(z) ~ "N/A",
    abs(z) <= 2 ~ "Satisfactory",
    abs(z) > 2 & abs(z) < 3 ~ "Questionable",
    abs(z) >= 3 ~ "Unsatisfactory"
  )
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

  iteration_df <- if (length(iteration_records) > 0) dplyr::bind_rows(iteration_records) else tibble()
  u_final <- (values - x_star) / (1.5 * s_star)
  weights_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))
  weights_df <- tibble(
    Participante = ids,
    Resultado = values,
    Peso = weights_final,
    `Residuo estandarizado` = u_final
  )

  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = iteration_df,
    weights = weights_df,
    converged = converged,
    effective_weight = sum(weights_final),
    error = NULL
  )
}

compute_combo_scores <- function(participants_df, x_pt, sigma_pt, u_xpt, combo_meta, k = 2) {
  if (!is.finite(x_pt)) {
    return(list(error = sprintf("Valor asignado no disponible para %s.", combo_meta$title)))
  }
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(list(error = sprintf("sigma_pt no válido para %s.", combo_meta$title)))
  }
  if (!is.finite(u_xpt) || u_xpt < 0) {
    u_xpt <- 0
  }

  participants_df <- participants_df %>%
    mutate(uncertainty_std = replace_na(uncertainty_std, 0))

  z_values <- (participants_df$result - x_pt) / sigma_pt
  zprime_den <- sqrt(sigma_pt^2 + u_xpt^2)
  z_prime_values <- if (zprime_den > 0) (participants_df$result - x_pt) / zprime_den else NA_real_
  zeta_den <- sqrt(participants_df$uncertainty_std^2 + u_xpt^2)
  zeta_values <- ifelse(zeta_den > 0, (participants_df$result - x_pt) / zeta_den, NA_real_)
  U_xi <- k * participants_df$uncertainty_std
  U_xpt <- k * u_xpt
  en_den <- sqrt(U_xi^2 + U_xpt^2)
  en_values <- ifelse(en_den > 0, (participants_df$result - x_pt) / en_den, NA_real_)

  data <- participants_df %>%
    mutate(
      combination = combo_meta$title,
      combination_label = combo_meta$label,
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      k_factor = k,
      z_score = z_values,
      z_score_eval = score_eval_z(z_score),
      z_prime_score = z_prime_values,
      z_prime_score_eval = score_eval_z(z_prime_score),
      zeta_score = zeta_values,
      zeta_score_eval = score_eval_z(zeta_score),
      En_score = en_values,
      En_score_eval = case_when(
        !is.finite(En_score) ~ "N/A",
        abs(En_score) <= 1 ~ "Satisfactory",
        abs(En_score) > 1 ~ "Unsatisfactory"
      )
    )

  list(
    error = NULL,
    title = combo_meta$title,
    label = combo_meta$label,
    x_pt = x_pt,
    sigma_pt = sigma_pt,
    u_xpt = u_xpt,
    data = data
  )
}

compute_scores_for_selection <- function(summary_data, target_pollutant, target_n_lab, target_level, max_iter = 50, k_factor = 2) {
  subset_data <- summary_data %>%
    filter(
      pollutant == target_pollutant,
      n_lab == target_n_lab,
      level == target_level
    )

  if (nrow(subset_data) == 0) {
    return(list(error = "No se encontraron datos para la combinación seleccionada."))
  }

  participant_data <- subset_data %>%
    filter(participant_id != "ref") %>%
    group_by(participant_id) %>%
    summarise(
      result = mean(mean_value, na.rm = TRUE),
      uncertainty_std = mean(sd_value, na.rm = TRUE),
      .groups = 'drop'
    ) %>%
    mutate(
      pollutant = target_pollutant,
      n_lab = target_n_lab,
      level = target_level
    )

  if (nrow(participant_data) == 0) {
    return(list(error = "No se encontraron participantes (distintos al valor de referencia) para la combinación seleccionada."))
  }

  ref_data <- subset_data %>% filter(participant_id == "ref")
  if (nrow(ref_data) == 0) {
    return(list(error = "No se encontró información del participante de referencia para esta combinación."))
  }
  x_pt1 <- mean(ref_data$mean_value, na.rm = TRUE)

  hom_res <- tryCatch(
    compute_homogeneity_metrics(target_pollutant, target_level),
    error = function(e) list(error = conditionMessage(e))
  )
  if (!is.null(hom_res$error)) {
    return(list(error = paste("Error obteniendo parámetros de homogeneidad:", hom_res$error)))
  }
  sigma_pt1 <- hom_res$sigma_pt
  u_xpt1 <- hom_res$u_xpt

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
  combos$ref <- compute_combo_scores(participant_data, x_pt1, sigma_pt1, u_xpt1, score_combo_info$ref, k = k_factor)
  combos$consensus_ma <- compute_combo_scores(participant_data, median_val, sigma_pt_2a, u_xpt2a, score_combo_info$consensus_ma, k = k_factor)
  combos$consensus_niqr <- compute_combo_scores(participant_data, median_val, sigma_pt_2b, u_xpt2b, score_combo_info$consensus_niqr, k = k_factor)

  if (is.null(algo_res$error)) {
    u_xpt3 <- 1.25 * algo_res$robust_sd / sqrt(n_part)
    combos$algo <- compute_combo_scores(participant_data, algo_res$assigned_value, algo_res$robust_sd, u_xpt3, score_combo_info$algo, k = k_factor)
  } else {
    combos$algo <- list(error = algo_res$error, title = score_combo_info$algo$title, label = score_combo_info$algo$label)
  }

  summary_table <- purrr::map_dfr(names(score_combo_info), function(key) {
    meta <- score_combo_info[[key]]
    combo <- combos[[key]]
    if (is.null(combo)) return(NULL)
    if (!is.null(combo$error)) {
      tibble(
        Combinación = meta$title,
        Etiqueta = meta$label,
        `x_pt` = NA_real_,
        `sigma_pt` = NA_real_,
        `u(x_pt)` = NA_real_,
        Nota = combo$error
      )
    } else {
      tibble(
        Combinación = combo$title,
        Etiqueta = combo$label,
        `x_pt` = combo$x_pt,
        `sigma_pt` = combo$sigma_pt,
        `u(x_pt)` = combo$u_xpt,
        Nota = ""
      )
    }
  })

  overview_table <- purrr::map_dfr(names(score_combo_info), function(key) {
    combo <- combos[[key]]
    if (is.null(combo)) return(NULL)
    if (!is.null(combo$error)) {
      tibble(
        Combinación = score_combo_info[[key]]$title,
        Participant = NA_character_,
        Result = NA_real_,
        `u(xi)` = NA_real_,
        `z-score` = NA_real_,
        `z-score Eval` = combo$error,
        `z'-score` = NA_real_,
        `z'-score Eval` = "",
        `zeta-score` = NA_real_,
        `zeta-score Eval` = "",
        `En-score` = NA_real_,
        `En-score Eval` = ""
      )
    } else {
      combo$data %>%
        transmute(
          Combinación = combination,
          Participant = participant_id,
          Result = result,
          `u(xi)` = uncertainty_std,
          `z-score` = z_score,
          `z-score Eval` = z_score_eval,
          `z'-score` = z_prime_score,
          `z'-score Eval` = z_prime_score_eval,
          `zeta-score` = zeta_score,
          `zeta-score Eval` = zeta_score_eval,
          `En-score` = En_score,
          `En-score Eval` = En_score_eval
        )
    }
  })

  list(
    error = NULL,
    combos = combos,
    summary = summary_table,
    overview = overview_table,
    pollutant = target_pollutant,
    n_lab = target_n_lab,
    level = target_level
  )
}

# 6. Generate outputs
pollutants <- sort(unique(summary_data$pollutant))
all_scores_list <- list()
scores_results_map <- list()

for (p in pollutants) {
  pollutant_data <- summary_data %>% filter(pollutant == p)
  n_values <- sort(unique(pollutant_data$n_lab))

  for (n_val in n_values) {
    n_subset <- pollutant_data %>% filter(n_lab == n_val)
    pollutant_levels <- sort(unique(n_subset$level))

    for (l in pollutant_levels) {
      print(paste("--- Processing:", p, "(n=", n_val, ") -", l, "---"))

      hom_results <- compute_homogeneity_metrics(p, l)
      if (!is.null(hom_results$error)) {
        print(paste("  - Homogeneity Error:", hom_results$error))
      } else {
        stab_results <- compute_stability_metrics(p, l, hom_results)
        if (!is.null(stab_results$error)) {
          print(paste("  - Stability Error:", stab_results$error))
        }
      }

      pt_prep_results <- compute_pt_prep_metrics(summary_data, p, l)
      if (!is.null(pt_prep_results$error)) {
        print(paste("  - PT Prep Error:", pt_prep_results$error))
      }

      score_res <- compute_scores_for_selection(summary_data, p, n_val, l, max_iter = 50, k_factor = 2)
      key <- paste(p, as.character(n_val), l, sep = "||")
      scores_results_map[[key]] <- score_res

      if (!is.null(score_res$error)) {
        print(paste("  - Scores Error:", score_res$error))
      } else {
        write.csv(score_res$summary, paste0("reports/assets/tables/scores_parameters_", p, "_n", n_val, "_", l, ".csv"), row.names = FALSE)
        write.csv(score_res$overview, paste0("reports/assets/tables/scores_overview_", p, "_n", n_val, "_", l, ".csv"), row.names = FALSE)

        purrr::walk(score_res$combos, function(combo) {
          if (is.null(combo$error)) {
            all_scores_list[[length(all_scores_list) + 1]] <<- combo$data
          }
        })
      }
    }
  }
}

# --- Combined Participant Summary Plots ---
if (length(all_scores_list) > 0) {
  combined_scores_df <- dplyr::bind_rows(all_scores_list)
}
print("Generating combined participant summary plots...")


if (length(all_scores_list) > 0) {
    # Combine all scores from all pollutants and levels into one dataframe
  all_scores_df <- do.call(rbind, all_scores_list) %>%
    filter(participant_id != "ref")

  all_participants <- unique(all_scores_df$participant_id)

  for (participant in all_participants) {
    print(paste("  - Creating summary plots for participant:", participant))
    participant_full_data <- all_scores_df %>% filter(participant_id == participant)

    combo_info <- participant_full_data %>%
      mutate(
        combo_id = ifelse(!is.na(combination_label) & combination_label != "", combination_label, "ref"),
        combo_display = ifelse(
          !is.na(combination_label) & combination_label != "",
          paste0(combination, " (", combination_label, ")"),
          combination
        )
      ) %>%
      distinct(combo_id, combo_display, combination, combination_label)

    pollutants_for_participant <- unique(participant_full_data$pollutant)

    for (idx in seq_len(nrow(combo_info))) {
      combo_row <- combo_info[idx, ]
      plot_list <- list()

      for (p_local in pollutants_for_participant) {
        plot_data <- participant_full_data %>% filter(pollutant == p_local)

        combo_data <- if (is.na(combo_row$combination_label) || combo_row$combination_label == "") {
          plot_data %>%
            filter(
              combination == combo_row$combination,
              is.na(combination_label) | combination_label == ""
            )
        } else {
          plot_data %>%
            filter(
              combination == combo_row$combination,
              combination_label == combo_row$combination_label
            )
        }

        if (nrow(combo_data) == 0) next

        p_values <- ggplot(combo_data, aes(x = level)) +
          geom_point(aes(y = result, color = "Participant"), size = 2) +
          geom_line(aes(y = result, group = 1, color = "Participant")) +
          geom_point(aes(y = x_pt, color = "Reference"), size = 2) +
          geom_line(aes(y = x_pt, group = 1, color = "Reference"), linetype = "dashed") +
          scale_color_manual(
            name = "Value",
            values = c("Participant" = "blue", "Reference" = "red")
          ) +
          labs(
            title = paste(toupper(p_local), "- Values"),
            subtitle = combo_row$combo_display,
            x = NULL,
            y = "Value"
          ) +
          theme_minimal() +
          theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))

        p_z_score <- ggplot(combo_data, aes(x = level, y = z_score, group = 1)) +
          geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "red") +
          geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "orange") +
          geom_hline(yintercept = 0, color = "grey") +
          geom_line(color = "blue") + geom_point(color = "blue", size = 2) +
          coord_cartesian(ylim = c(-4, 4)) +
          labs(
            title = paste(toupper(p_local), "- Z-Score"),
            subtitle = combo_row$combo_display,
            x = NULL,
            y = "Z-Score"
          ) +
          theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))

        p_zeta_score <- ggplot(combo_data, aes(x = level, y = zeta_score, group = 1)) +
          geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "red") +
          geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "orange") +
          geom_hline(yintercept = 0, color = "grey") +
          geom_line(color = "darkgreen") + geom_point(color = "darkgreen", size = 2) +
          labs(
            title = paste(toupper(p_local), "- Zeta-Score"),
            subtitle = combo_row$combo_display,
            x = NULL,
            y = "Zeta-Score"
          ) +
          theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))

        p_en_score <- ggplot(combo_data, aes(x = level, y = En_score, group = 1)) +
          geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "red") +
          geom_hline(yintercept = 0, color = "grey") +
          geom_line(color = "purple") + geom_point(color = "purple", size = 2) +
          labs(
            title = paste(toupper(p_local), "- En-Score"),
            subtitle = combo_row$combo_display,
            x = NULL,
            y = "En-Score"
          ) +
          theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))

        plot_list <- c(plot_list, list(p_values, p_z_score, p_zeta_score, p_en_score))
      }

      if (length(plot_list) == 0) next

      combined_plot <- wrap_plots(plot_list, ncol = 4, guides = "collect") +
        plot_annotation(
          title = paste(
            "Performance Summary for Participant:", participant,
            "| Combination", combo_row$combo_id
          ),
          theme = theme(
            plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
          )
        )

      sanitized_combo <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", combo_row$combo_id)))
      output_filename <- paste0(
        "reports/assets/charts/summary_matrix_",
        participant,
        "_combo_",
        sanitized_combo,
        ".png"
      )

      ggsave(
        filename = output_filename,
        plot = combined_plot,
        width = 10,
        height = 12,
        units = "in"
      )
    }
  }

  # --- Score Heatmap ---
  print("  - Creating score heatmaps by pollutant...")
  heatmap_specs <- list(
    z_score = list(
      label = "Z-Score",
      short = "z",
      eval_col = "z_score_eval",
      colors = c(
        "Satisfactory" = "#00B050",
        "Questionable" = "#FFEB3B",
        "Unsatisfactory" = "#D32F2F",
        "N/A" = "#BDBDBD"
      )
    ),
    zeta_score = list(
      label = "Zeta-Score",
      short = "zeta",
      eval_col = "zeta_score_eval",
      colors = c(
        "Satisfactory" = "#00B050",
        "Questionable" = "#FFEB3B",
        "Unsatisfactory" = "#D32F2F",
        "N/A" = "#BDBDBD"
      )
    ),
    En_score = list(
      label = "En-Score",
      short = "en",
      eval_col = "En_score_eval",
      colors = c(
        "Satisfactory" = "#00B050",
        "Questionable" = "#D32F2F",
        "Unsatisfactory" = "#D32F2F",
        "N/A" = "#BDBDBD"
      )
    )
  )

  pollutant_ids <- sort(unique(all_scores_df$pollutant))
  for (pollutant_id in pollutant_ids) {
    pollutant_df <- all_scores_df %>% filter(pollutant == pollutant_id)
    if (nrow(pollutant_df) == 0) next

    participant_levels <- pollutant_df %>%
      distinct(participant_id) %>%
      arrange(participant_id) %>%
      pull(participant_id)

    pollutant_df <- pollutant_df %>%
      mutate(
        run_label = as.character(level),
        combination_id = ifelse(
          !is.na(combination_label) & combination_label != "",
          combination_label,
          combination
        ),
        combination_display = ifelse(
          !is.na(combination_label) & combination_label != "",
          paste0(combination, " (", combination_label, ")"),
          combination
        )
      )

    run_levels <- pollutant_df %>%
      distinct(level, run_label) %>%
      mutate(level_numeric = readr::parse_number(as.character(level))) %>%
      arrange(level_numeric, level, run_label) %>%
      pull(run_label)

    if (length(participant_levels) == 0 || length(run_levels) == 0) next

    for (combo_id in unique(pollutant_df$combination_id)) {
      combo_df <- pollutant_df %>% filter(combination_id == !!combo_id)
      combination_display <- combo_df %>%
        distinct(combination_display) %>%
        pull(combination_display)
      combination_display <- combination_display[1]

      for (score_name in names(heatmap_specs)) {
        spec <- heatmap_specs[[score_name]]
        value_col <- rlang::sym(score_name)
        eval_col <- rlang::sym(spec$eval_col)

        base_grid <- expand.grid(
          participant_id = participant_levels,
          run_label = run_levels,
          stringsAsFactors = FALSE
        )

        plot_data <- base_grid %>%
          left_join(
            combo_df %>%
              select(
                participant_id,
                run_label,
                score_value = !!value_col,
                evaluation = !!eval_col
              ),
            by = c("participant_id", "run_label")
          ) %>%
          mutate(
            evaluation = ifelse(is.na(evaluation) | evaluation == "", "N/A", evaluation),
            tile_label = ifelse(is.finite(score_value), sprintf("%.2f", score_value), ""),
            participant_id = factor(participant_id, levels = participant_levels),
            run_label = factor(run_label, levels = run_levels),
            evaluation = factor(evaluation, levels = names(spec$colors))
          )

        if (all(is.na(plot_data$score_value))) next

        heatmap_plot <- ggplot(plot_data, aes(x = run_label, y = participant_id, fill = evaluation)) +
          geom_tile(color = "white") +
          geom_text(aes(label = tile_label), size = 3, color = "#1B1B1B") +
          scale_fill_manual(
            values = spec$colors,
            limits = names(spec$colors),
            drop = FALSE,
            na.value = "#BDBDBD"
          ) +
          labs(
            title = paste(spec$label, "Heatmap for Pollutant:", pollutant_id, "- Combination", combo_id),
            subtitle = combination_display,
            x = "Run (Level)",
            y = "Participant",
            fill = paste(spec$label, "Evaluation")
          ) +
          theme_minimal() +
          theme(
            panel.grid = element_blank(),
            axis.text.x = element_text(angle = 45, hjust = 1),
            axis.title.x = element_text(margin = margin(t = 12)),
            axis.title.y = element_text(margin = margin(r = 12)),
            legend.position = "right"
          )

        sanitized_pollutant <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", pollutant_id)))
        sanitized_combination <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", combo_id)))
        score_prefix <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", tolower(spec$short))))
        output_path <- file.path(
          "reports/assets/charts",
          paste0(score_prefix, "_heatmap_", sanitized_pollutant, "_", sanitized_combination, ".png")
        )
        plot_width <- max(6, length(run_levels) * 1.2)
        plot_height <- max(4, length(participant_levels) * 0.6)

        ggsave(output_path, heatmap_plot, width = plot_width, height = plot_height, dpi = 300)
      }
    }
  }

  xpt_summary <- all_scores_df %>%
    group_by(pollutant, level, combination, combination_label) %>%
    summarise(
      x_pt = dplyr::first(x_pt),
      u_xpt = dplyr::first(u_xpt),
      expanded_uncertainty = dplyr::first(k_factor * u_xpt),
      sigma_pt = dplyr::first(sigma_pt),
      .groups = "drop"
    ) %>%
    mutate(
      combination_id = ifelse(
        !is.na(combination_label) & combination_label != "",
        combination_label,
        combination
      )
    ) %>%
    select(
      Pollutant = pollutant,
      Level = level,
      Combination = combination,
      Combination_Label = combination_id,
      x_pt,
      u_xpt,
      expanded_uncertainty,
      sigma_pt
    ) %>%
    arrange(Pollutant, Level, Combination_Label)

  write.csv(xpt_summary, "reports/assets/tables/xpt_summary.csv", row.names = FALSE)

  level_summary <- summary_data %>%
    distinct(pollutant, level) %>%
    mutate(level_numeric = readr::parse_number(as.character(level))) %>%
    arrange(pollutant, level_numeric, level) %>%
    group_by(pollutant) %>%
    mutate(Run_Order = row_number()) %>%
    ungroup() %>%
    select(
      Pollutant = pollutant,
      Run_Order,
      Level = level
    )

  write.csv(level_summary, "reports/assets/tables/level_summary.csv", row.names = FALSE)
}

# --- Generate Detailed Participant Summary CSVs ---
print("Generating detailed summary CSV for each participant...")
if (length(all_scores_list) > 0) {
  # 1. Reshape the raw data to get individual replicate values in columns
  raw_replicates_wide <- raw_summary_data %>%
    group_by(participant_id, pollutant, level) %>%
    mutate(replicate_num = row_number()) %>%
    ungroup() %>%
    pivot_wider(
      id_cols = c(participant_id, pollutant, level),
      names_from = replicate_num,
      values_from = mean_value,
      names_prefix = "value_"
    )

  # 2. Get the final scores data, which is already aggregated
  all_scores_df <- do.call(rbind, all_scores_list)

  # 3. Loop through each participant to create and save their summary file
  participants_to_export <- unique(all_scores_df$participant_id)

  for (participant in participants_to_export) {
    print(paste("  - Creating CSV for participant:", participant))

    # Join the scores with the wide-format raw values
    participant_summary_df <- all_scores_df %>%
      filter(participant_id == !!participant) %>%
      left_join(raw_replicates_wide, by = c("participant_id", "pollutant", "level")) %>%
      mutate(
        participant_sd = apply(select(., starts_with("value_")), 1, sd, na.rm = TRUE)
      ) %>%
      select(
        pollutant,
        n_lab,
        level,
        combination,
        combination_label,
        participant_mean = result,
        value_1, value_2, value_3,
        participant_sd,
        sigma_pt,
        `u(x_pt)` = u_xpt,
        ref_value = x_pt,
        z_score, z_score_eval,
        `z_prime` = z_prime_score,
        `z_prime Eval` = z_prime_score_eval,
        zeta_score, zeta_score_eval,
        En_score, En_score_eval
      )

    # Export to CSV
    write.csv(participant_summary_df, paste0("reports/assets/tables/participant_summary_", participant, ".csv"), row.names = FALSE)
  }
}

# --- Generate Overall Score Evaluation Summary ---
print("Generating overall score evaluation summary...")
if (nrow(combined_scores_df) > 0) {
  scores_long <- combined_scores_df %>%
    filter(participant_id != "ref") %>%
    select(pollutant, n_lab, level, combination, combination_label,
           z_score_eval, zeta_score_eval, En_score_eval) %>%
    pivot_longer(
      cols = c(z_score_eval, zeta_score_eval, En_score_eval),
      names_to = "score_type",
      values_to = "evaluation"
    ) %>%
    mutate(
      score_type = sub("_eval$", "", score_type),
      evaluation = factor(evaluation, levels = c("Satisfactory", "Questionable", "Unsatisfactory", "N/A"))
    )

  evaluation_summary <- scores_long %>%
    count(pollutant, n_lab, level, combination, combination_label, score_type, evaluation, .drop = FALSE, name = "Count") %>%
    group_by(pollutant, n_lab, level, combination, combination_label, score_type) %>%
    mutate(Percentage = ifelse(sum(Count) > 0, (Count / sum(Count)) * 100, 0)) %>%
    ungroup() %>%
    mutate(Criteria = paste(score_type, evaluation)) %>%
    select(
      Pollutant = pollutant,
      `PT Scheme (n)` = n_lab,
      Level = level,
      Combination = combination,
      `Combination Label` = combination_label,
      Criteria,
      Count,
      Percentage
    )

  write.csv(evaluation_summary, "reports/assets/tables/score_evaluation_summary.csv", row.names = FALSE)
}

print("Script finished. All assets generated.")
