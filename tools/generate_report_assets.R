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
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

extract_grubbs_value <- function(text_line) {
  if (is.null(text_line) || !nzchar(text_line)) {
    return(NA_real_)
  }
  match <- regmatches(text_line, regexec("value ([+-]?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)", text_line))[[1]]
  if (length(match) >= 2) {
    suppressWarnings(as.numeric(match[2]))
  } else {
    NA_real_
  }
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
hom_data_full <- read_csv("data/homogeneity.csv", show_col_types = FALSE)
stab_data_full <- read_csv("data/stability.csv", show_col_types = FALSE)
raw_summary_data <- read_csv("data/summary_n7.csv", show_col_types = FALSE)

# --- Data Aggregation Step ---
# The raw summary data has one row per replicate (sample_group).
# We need to average these replicates for each participant at each level.
summary_data <- raw_summary_data %>%
  group_by(participant_id, pollutant, level) %>%
  summarise(
    mean_value = mean(mean_value, na.rm = TRUE),
    sd_value = mean(sd_value, na.rm = TRUE), # Taking the mean of SDs as a representative value
    .groups = "drop"
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

  valid_values <- participants_data %>%
    filter(is.finite(mean_value)) %>%
    pull(mean_value)

  n_valid <- length(valid_values)
  outlier_summary <- list(
    n_points = n_valid,
    p_value = NA_real_,
    count = NA_integer_,
    value = NA_real_,
    participant_id = NA_character_
  )

  if (n_valid < 3) {
    grubbs_test_result <- "Grubbs' test requires at least 3 data points."
    outlier_summary$count <- NA_integer_
  } else {
    grubbs_obj <- grubbs.test(valid_values)
    grubbs_test_result <- capture.output(grubbs_obj)
    p_val <- grubbs_obj$p.value
    outlier_summary$p_value <- p_val
    if (is.finite(p_val) && p_val < 0.05) {
      outlier_summary$count <- 1L
      alt_text <- grubbs_obj$alternative
      candidate_value <- extract_grubbs_value(alt_text)
      outlier_summary$value <- candidate_value
      if (is.finite(candidate_value)) {
        idx <- participants_data %>%
          mutate(diff = abs(mean_value - candidate_value)) %>%
          filter(is.finite(diff)) %>%
          arrange(diff) %>%
          slice_head(n = 1) %>%
          pull(participant_id)
        if (length(idx) == 0) {
          outlier_summary$participant_id <- NA_character_
        } else {
          outlier_summary$participant_id <- idx[1]
        }
      }
    } else {
      outlier_summary$count <- 0L
    }
  }

  list(
    data = data,
    grubbs = grubbs_test_result,
    outlier_summary = outlier_summary,
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

pt_en_class_labels <- c(
  sat_en_good = "Z Satisfactory & En ≤ 1",
  sat_en_bad = "Z Satisfactory & En > 1",
  ques_en_good = "Z Questionable & En ≤ 1",
  ques_en_bad = "Z Questionable & En > 1",
  unsat_en_good = "Z Unsatisfactory & En ≤ 1",
  unsat_en_bad = "Z Unsatisfactory & En > 1"
)

pt_en_class_colors <- c(
  sat_en_good = "#2E7D32",
  sat_en_bad = "#66BB6A",
  ques_en_good = "#FBC02D",
  ques_en_bad = "#FFA000",
  unsat_en_good = "#FB8C00",
  unsat_en_bad = "#C62828",
  mu_missing_z = "#90A4AE",
  mu_missing_zprime = "#78909C"
)

classify_with_en <- function(score_val, en_val, U_xi, sigma_pt, mu_missing, score_label) {
  if (!is.finite(score_val)) {
    return(list(code = NA_character_, label = "N/A"))
  }

  if (isTRUE(mu_missing)) {
    base_eval <- score_eval_z(score_val)
    if (base_eval == "N/A") {
      return(list(code = NA_character_, label = "N/A"))
    }
    label_key <- tolower(score_label)
    label_key <- gsub("'", "prime", label_key)
    label_key <- gsub("[^a-z0-9]+", "", label_key)
    code <- paste0("mu_missing_", label_key)
    label <- sprintf("MU missing - %s-only: %s", score_label, base_eval)
    return(list(code = code, label = label))
  }

  if (!is.finite(en_val) || !is.finite(sigma_pt) || sigma_pt <= 0 || !is.finite(U_xi)) {
    return(list(code = NA_character_, label = "N/A"))
  }

  z_eval <- score_eval_z(score_val)
  if (z_eval == "N/A") {
    return(list(code = NA_character_, label = "N/A"))
  }

  en_good <- abs(en_val) <= 1
  code <- switch(z_eval,
    "Satisfactory" = if (en_good) "sat_en_good" else "sat_en_bad",
    "Questionable" = if (en_good) "ques_en_good" else "ques_en_bad",
    "Unsatisfactory" = if (en_good) "unsat_en_good" else "unsat_en_bad",
    NA_character_
  )

  if (is.na(code)) {
    return(list(code = NA_character_, label = "N/A"))
  }

  list(code = code, label = pt_en_class_labels[[code]])
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
    mutate(
      uncertainty_std_missing = !is.finite(uncertainty_std),
      uncertainty_std = ifelse(uncertainty_std_missing, NA_real_, uncertainty_std)
    )

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
      ),
      U_xi = U_xi,
      U_xpt = U_xpt
    )
  data <- data %>%
    rowwise() %>%
    mutate(
      classification_z_en_res = list(classify_with_en(z_score, En_score, U_xi, sigma_pt, uncertainty_std_missing, "z")),
      classification_z_en = classification_z_en_res$label,
      classification_z_en_code = classification_z_en_res$code,
      classification_zprime_en_res = list(classify_with_en(z_prime_score, En_score, U_xi, sigma_pt, uncertainty_std_missing, "z'")),
      classification_zprime_en = classification_zprime_en_res$label,
      classification_zprime_en_code = classification_zprime_en_res$code
    ) %>%
    ungroup() %>%
    select(-classification_z_en_res, -classification_zprime_en_res)

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
      .groups = "drop"
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
  sigma_pt1 <- mean(ref_data$sd_value, na.rm = TRUE)
  u_xpt1 <- mean(ref_data$sd_value, na.rm = TRUE)

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
    if (is.null(combo)) {
      return(NULL)
    }
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
    if (is.null(combo)) {
      return(NULL)
    }
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
        `En-score Eval` = "",
        `Classification z+En` = "",
        `Classification z+En Code` = "",
        `Classification z'+En` = "",
        `Classification z'+En Code` = ""
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
          `En-score Eval` = En_score_eval,
          `Classification z+En` = classification_z_en,
          `Classification z+En Code` = classification_z_en_code,
          `Classification z'+En` = classification_zprime_en,
          `Classification z'+En Code` = classification_zprime_en_code
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
    level = target_level,
    algo_res = algo_res
  )
}

# 6. Generate outputs
pollutants <- sort(unique(summary_data$pollutant))
pollutant_fill_map <- setNames(
  grDevices::hcl.colors(max(1, length(pollutants)), palette = "Teal"),
  pollutants
)
all_scores_list <- list()
scores_results_map <- list()
grubbs_summary_records <- list()
hom_summary_records <- list()
stability_summary_records <- list()

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
        hom_summary_records[[length(hom_summary_records) + 1]] <- tibble(
          pollutant = p,
          level = l,
          items = hom_results$g,
          replicates = hom_results$m,
          sigma_pt = hom_results$sigma_pt,
          u_xpt = hom_results$u_xpt,
          ss = hom_results$ss,
          sw = hom_results$sw,
          c_criterion = hom_results$c_criterion,
          c_criterion_expanded = hom_results$c_criterion_expanded,
          meets_criterion = hom_results$ss <= hom_results$c_criterion,
          meets_expanded = hom_results$ss <= hom_results$c_criterion_expanded,
          conclusion = hom_results$conclusion
        )

        # --- Homogeneity Tables ---
        # 1. Variance Components
        hom_var_comp <- data.frame(
          Componente = c(
            "Valor asignado (xpt)", "DE robusta (sigma_pt)", "Incertidumbre del valor asignado (u_xpt)",
            "DE entre muestras (ss)", "DE dentro de la muestra (sw)", "---",
            "Criterio c", "Criterio c (expandido)"
          ),
          Valor = c(
            sprintf("%.5f", c(hom_results$median_val, hom_results$sigma_pt, hom_results$u_xpt, hom_results$ss, hom_results$sw)),
            "",
            sprintf("%.5f", c(hom_results$c_criterion, hom_results$c_criterion_expanded))
          )
        )
        write.csv(hom_var_comp, paste0("reports/assets/tables/homogeneity_variance_components_", p, "_", l, ".csv"), row.names = FALSE)

        # 2. Details per item
        write.csv(hom_results$intermediate_df, paste0("reports/assets/tables/homogeneity_details_per_item_", p, "_", l, ".csv"), row.names = FALSE)

        # 3. Summary Stats
        hom_summary_stats <- data.frame(
          Parametro = c(
            "Media general", "DE de medias", "Varianza de las medias (s_x_bar_sq)", "sw", "Varianza dentro de la muestra (s_w_sq)", "ss",
            "---", "Valor asignado (xpt)", "Mediana de diferencias absolutas", "Numero de items (g)", "Numero de replicas (m)",
            "DE robusta (MADe)", "nIQR", "Incertidumbre del valor asignado (u_xpt)",
            "---", "Criterio c", "Criterio c (expandido)"
          ),
          Valor = c(
            sprintf("%.5f", c(hom_results$general_mean, hom_results$sd_of_means, hom_results$s_x_bar_sq, hom_results$sw, hom_results$s_w_sq, hom_results$ss)),
            "",
            sprintf("%.5f", c(hom_results$median_val, hom_results$median_abs_diff)),
            as.character(c(hom_results$g, hom_results$m)),
            sprintf("%.5f", c(hom_results$sigma_pt, hom_results$n_iqr, hom_results$u_xpt)),
            "",
            sprintf("%.5f", c(hom_results$c_criterion, hom_results$c_criterion_expanded))
          )
        )
        write.csv(hom_summary_stats, paste0("reports/assets/tables/homogeneity_summary_stats_", p, "_", l, ".csv"), row.names = FALSE)

        # 4. Robust Stats
        hom_robust_stats <- data.frame(
          Estadistico = c("Mediana (x_pt)", "Diferencia absoluta mediana", "MADe (sigma_pt)", "nIQR"),
          Valor = sprintf("%.5f", c(hom_results$median_val, hom_results$median_abs_diff, hom_results$sigma_pt, hom_results$n_iqr))
        )
        write.csv(hom_robust_stats, paste0("reports/assets/tables/homogeneity_robust_stats_", p, "_", l, ".csv"), row.names = FALSE)

        stab_results <- compute_stability_metrics(p, l, hom_results)
        if (!is.null(stab_results$error)) {
          print(paste("  - Stability Error:", stab_results$error))
        } else {
          stability_summary_records[[length(stability_summary_records) + 1]] <- tibble(
            pollutant = p,
            level = l,
            items = stab_results$g,
            replicates = stab_results$m,
            sigma_pt = stab_results$stab_sigma_pt,
            u_xpt = stab_results$stab_u_xpt,
            diff_hom_stab = stab_results$diff_hom_stab,
            stab_ss = stab_results$stab_ss,
            stab_sw = stab_results$stab_sw,
            c_criterion = stab_results$stab_c_criterion,
            c_criterion_expanded = stab_results$stab_c_criterion_expanded,
            meets_criterion = stab_results$diff_hom_stab <= stab_results$stab_c_criterion,
            meets_expanded = stab_results$diff_hom_stab <= stab_results$stab_c_criterion_expanded,
            conclusion = stab_results$stab_conclusion
          )

          # --- Stability Tables ---
          # 1. Variance Components
          stab_var_comp <- data.frame(
            Componente = c("Valor asignado (xpt)", "DE robusta (sigma_pt)", "Incertidumbre del valor asignado (u_xpt)"),
            Valor = sprintf("%.5f", c(stab_results$stab_median_val, stab_results$stab_sigma_pt, stab_results$stab_u_xpt))
          )
          write.csv(stab_var_comp, paste0("reports/assets/tables/stability_variance_components_", p, "_", l, ".csv"), row.names = FALSE)

          # 2. Details per item
          write.csv(stab_results$stab_intermediate_df, paste0("reports/assets/tables/stability_details_per_item_", p, "_", l, ".csv"), row.names = FALSE)

          # 3. Summary Stats
          stab_summary_stats <- data.frame(
            Parametro = c(
              "Media general", "Diferencia absoluta respecto a la media general", "DE de medias", "Varianza de las medias (s_x_bar_sq)",
              "sw", "Varianza dentro de la muestra (s_w_sq)", "ss",
              "---", "Valor asignado (xpt)", "Mediana de diferencias absolutas", "Numero de items (g)", "Numero de replicas (m)",
              "DE robusta (MADe)", "nIQR", "Incertidumbre del valor asignado (u_xpt)",
              "---", "Criterio c", "Criterio c (expandido)"
            ),
            Valor = c(
              sprintf("%.5f", c(
                stab_results$stab_general_mean, stab_results$diff_hom_stab, stab_results$stab_sd_of_means, stab_results$stab_s_x_bar_sq,
                stab_results$stab_sw, stab_results$stab_s_w_sq, stab_results$stab_ss
              )),
              "",
              sprintf("%.5f", c(stab_results$stab_median_val, stab_results$stab_median_abs_diff)),
              as.character(c(stab_results$g, stab_results$m)),
              sprintf("%.5f", c(stab_results$stab_sigma_pt, stab_results$stab_n_iqr, stab_results$stab_u_xpt)),
              "",
              sprintf("%.5f", c(stab_results$stab_c_criterion, stab_results$stab_c_criterion_expanded))
            )
          )
          write.csv(stab_summary_stats, paste0("reports/assets/tables/stability_summary_stats_", p, "_", l, ".csv"), row.names = FALSE)
        }
      }

      pt_prep_results <- compute_pt_prep_metrics(summary_data, p, l)
      if (!is.null(pt_prep_results$error)) {
        print(paste("  - PT Prep Error:", pt_prep_results$error))
      } else if (!is.null(pt_prep_results$outlier_summary)) {
        summary_info <- pt_prep_results$outlier_summary
        grubbs_summary_records[[length(grubbs_summary_records) + 1]] <- tibble(
          pollutant = p,
          level = l,
          n_tested = summary_info$n_points,
          grubbs_p_value = summary_info$p_value,
          outlier_count = summary_info$count,
          outlier_participant = summary_info$participant_id,
          outlier_value = summary_info$value
        )
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

        if (!is.null(score_res$algo_res) && is.null(score_res$algo_res$error)) {
          # Save Iterations
          write.csv(score_res$algo_res$iterations, paste0("reports/assets/tables/algoA_iterations_", p, "_n", n_val, "_", l, ".csv"), row.names = FALSE)

          # Save Weights
          write.csv(score_res$algo_res$weights, paste0("reports/assets/tables/algoA_weights_", p, "_n", n_val, "_", l, ".csv"), row.names = FALSE)

          # Generate Histogram
          algo_hist_plot <- ggplot(score_res$algo_res$weights, aes(x = Resultado)) +
            geom_histogram(aes(y = after_stat(density)), bins = 15, fill = "#5DADE2", color = "white", alpha = 0.8) +
            geom_density(color = "#1A5276", size = 1) +
            geom_vline(xintercept = score_res$algo_res$assigned_value, color = "red", linetype = "dashed", size = 1) +
            labs(
              title = "Distribución de resultados por participante",
              subtitle = "La línea punteada indica el valor asignado robusto (x*)",
              x = "Resultado",
              y = "Densidad"
            ) +
            theme_minimal()

          ggsave(paste0("reports/assets/charts/algoA_histogram_", p, "_n", n_val, "_", l, ".png"), algo_hist_plot, width = 8, height = 6)
        }
      }
    }
  }
}

if (length(hom_summary_records) > 0) {
  homogeneity_summary_df <- dplyr::bind_rows(hom_summary_records) %>%
    mutate(
      sigma_pt = round(sigma_pt, 4),
      u_xpt = round(u_xpt, 4),
      ss = round(ss, 4),
      sw = round(sw, 4),
      c_criterion = round(c_criterion, 4),
      c_criterion_expanded = round(c_criterion_expanded, 4),
      Meets_Criterion = dplyr::if_else(meets_criterion, "Yes", "No"),
      Meets_Expanded = dplyr::if_else(meets_expanded, "Yes", "No")
    ) %>%
    transmute(
      Pollutant = pollutant,
      Level = level,
      Items = items,
      Replicates = replicates,
      sigma_pt,
      u_xpt,
      ss,
      sw,
      c_criterion,
      c_criterion_expanded,
      Meets_Criterion,
      Meets_Expanded,
      Conclusion = conclusion
    ) %>%
    arrange(Pollutant, Level)

  write.csv(homogeneity_summary_df, "reports/assets/tables/homogeneity_summary.csv", row.names = FALSE)
} else {
  print("No homogeneity summary generated (insufficient homogeneity data).")
}

if (length(stability_summary_records) > 0) {
  stability_summary_df <- dplyr::bind_rows(stability_summary_records) %>%
    mutate(
      sigma_pt = round(sigma_pt, 4),
      u_xpt = round(u_xpt, 4),
      diff_hom_stab = round(diff_hom_stab, 4),
      stab_ss = round(stab_ss, 4),
      stab_sw = round(stab_sw, 4),
      c_criterion = round(c_criterion, 4),
      c_criterion_expanded = round(c_criterion_expanded, 4),
      Meets_Criterion = dplyr::if_else(meets_criterion, "Yes", "No"),
      Meets_Expanded = dplyr::if_else(meets_expanded, "Yes", "No")
    ) %>%
    transmute(
      Pollutant = pollutant,
      Level = level,
      Items = items,
      Replicates = replicates,
      sigma_pt,
      u_xpt,
      diff_hom_stab,
      stab_ss,
      stab_sw,
      c_criterion,
      c_criterion_expanded,
      Meets_Criterion,
      Meets_Expanded,
      Conclusion = conclusion
    ) %>%
    arrange(Pollutant, Level)

  write.csv(stability_summary_df, "reports/assets/tables/stability_summary.csv", row.names = FALSE)
} else {
  print("No stability summary generated (insufficient stability data).")
}

if (length(grubbs_summary_records) > 0) {
  grubbs_summary_df <- dplyr::bind_rows(grubbs_summary_records) %>%
    mutate(
      outlier_count = dplyr::if_else(is.na(outlier_count), NA_integer_, as.integer(outlier_count)),
      grubbs_p_value = ifelse(is.finite(grubbs_p_value), round(grubbs_p_value, 4), grubbs_p_value)
    ) %>%
    arrange(pollutant, level) %>%
    transmute(
      Pollutant = pollutant,
      Level = level,
      `Results Tested` = n_tested,
      `Grubbs p-value` = grubbs_p_value,
      `Outliers Detected` = outlier_count,
      `Outlier Participant` = outlier_participant,
      `Outlier Value` = outlier_value
    )

  write.csv(grubbs_summary_df, "reports/assets/tables/grubbs_summary.csv", row.names = FALSE)
} else {
  print("No Grubbs test summary generated (insufficient participant data).")
}
# --- Global Heatmaps Generation ---
print("Generating global heatmaps...")

global_combo_specs <- list(
  ref = list(title = "Referencia (1)", label = "1"),
  consensus_ma = list(title = "Consenso MADe (2a)", label = "2a"),
  consensus_niqr = list(title = "Consenso nIQR (2b)", label = "2b"),
  algo = list(title = "Algoritmo A (3)", label = "3")
)

score_heatmap_palettes <- list(
  z = c("Satisfactorio" = "#00B050", "Cuestionable" = "#FFEB3B", "No satisfactorio" = "#D32F2F", "N/A" = "#BDBDBD"),
  zprime = c("Satisfactorio" = "#00B050", "Cuestionable" = "#FFEB3B", "No satisfactorio" = "#D32F2F", "N/A" = "#BDBDBD"),
  zeta = c("Satisfactorio" = "#00B050", "Cuestionable" = "#FFEB3B", "No satisfactorio" = "#D32F2F", "N/A" = "#BDBDBD"),
  en = c("Satisfactorio" = "#00B050", "Cuestionable" = "#D32F2F", "No satisfactorio" = "#D32F2F", "N/A" = "#BDBDBD")
)

# Reconstruct global combos data
combo_rows <- list()
purrr::iwalk(scores_results_map, function(res, key) {
  parts <- strsplit(key, "\\|\\|")[[1]]
  pollutant_val <- parts[1]
  n_lab_val <- parts[2]
  level_val <- parts[3]

  if (!is.null(res$error)) {
    return()
  }

  purrr::iwalk(res$combos, function(combo_res, combo_key) {
    if (!is.null(combo_res$error)) {
      return()
    }
    if (is.null(combo_res$data) || nrow(combo_res$data) == 0) {
      return()
    }

    combo_rows[[length(combo_rows) + 1]] <<- combo_res$data %>%
      mutate(
        pollutant = pollutant_val,
        n_lab = n_lab_val,
        level = level_val,
        combo_key = combo_key
      )
  })
})

global_combos <- if (length(combo_rows) > 0) dplyr::bind_rows(combo_rows) else tibble()

if (nrow(global_combos) > 0) {
  heatmap_groups <- global_combos %>%
    distinct(pollutant, n_lab)

  for (i in seq_len(nrow(heatmap_groups))) {
    p_val <- heatmap_groups$pollutant[i]
    n_val <- heatmap_groups$n_lab[i]

    # Filter data for this group
    group_data <- global_combos %>%
      filter(pollutant == p_val, n_lab == n_val)

    for (combo_key in names(global_combo_specs)) {
      spec <- global_combo_specs[[combo_key]]

      # Filter for this method
      method_data <- group_data %>%
        filter(combo_key == !!combo_key, participant_id != "ref")

      if (nrow(method_data) == 0) next

      # Function to generate and save heatmap
      generate_heatmap <- function(data, score_col, eval_col, palette, suffix) {
        plot_data <- data %>%
          mutate(
            run_label = as.character(level),
            score_value = .data[[score_col]],
            evaluation = .data[[eval_col]]
          ) %>%
          mutate(
            evaluation = ifelse(is.na(evaluation) | evaluation == "", "N/A", evaluation),
            tile_label = ifelse(is.finite(score_value), sprintf("%.2f", score_value), ""),
            evaluation = factor(evaluation, levels = names(palette))
          )

        # Ensure factor levels for ordering
        participant_levels <- sort(unique(plot_data$participant_id))
        run_levels <- plot_data %>%
          distinct(level, run_label) %>%
          mutate(level_numeric = readr::parse_number(as.character(level))) %>%
          arrange(level_numeric, level) %>%
          pull(run_label)

        plot_data$participant_id <- factor(plot_data$participant_id, levels = participant_levels)
        plot_data$run_label <- factor(plot_data$run_label, levels = run_levels)

        heatmap_plot <- ggplot(plot_data, aes(x = run_label, y = participant_id, fill = evaluation)) +
          geom_tile(color = "white") +
          geom_text(aes(label = tile_label), size = 3, color = "#1B1B1B") +
          scale_fill_manual(values = palette, drop = FALSE, na.value = "#BDBDBD") +
          labs(
            title = paste("Mapa de calor", suffix, "-", spec$title),
            subtitle = paste("Analito:", p_val, "| n =", n_val),
            x = "Nivel",
            y = "Participante",
            fill = "Evaluación"
          ) +
          theme_minimal() +
          theme(
            panel.grid = element_blank(),
            axis.text.x = element_text(angle = 45, hjust = 1)
          )

        ggsave(paste0("reports/assets/charts/global_heatmap_", suffix, "_", combo_key, "_", p_val, "_n", n_val, ".png"), heatmap_plot, width = 10, height = 8)
      }

      generate_heatmap(method_data, "z_score", "z_score_eval", score_heatmap_palettes$z, "z")
      generate_heatmap(method_data, "z_prime_score", "z_prime_score_eval", score_heatmap_palettes$zprime, "zprime")
      generate_heatmap(method_data, "zeta_score", "zeta_score_eval", score_heatmap_palettes$zeta, "zeta")
      generate_heatmap(method_data, "En_score", "En_score_eval", score_heatmap_palettes$en, "en")

      generate_class_heatmap <- function(data, code_col, label_col, suffix) {
        plot_data <- data %>%
          mutate(
            run_label = as.character(level),
            class_code = .data[[code_col]],
            class_label = .data[[label_col]]
          ) %>%
          mutate(
            class_code = ifelse(class_code == "", NA_character_, class_code),
            display_code = case_when(
              is.na(class_code) ~ "",
              grepl("^mu_missing", class_code) ~ "MU",
              TRUE ~ toupper(class_code)
            ),
            fill_code = factor(class_code, levels = names(pt_en_class_colors))
          )

        # Ensure factor levels
        participant_levels <- sort(unique(plot_data$participant_id))
        run_levels <- plot_data %>%
          distinct(level, run_label) %>%
          mutate(level_numeric = readr::parse_number(as.character(level))) %>%
          arrange(level_numeric, level) %>%
          pull(run_label)

        plot_data$participant_id <- factor(plot_data$participant_id, levels = participant_levels)
        plot_data$run_label <- factor(plot_data$run_label, levels = run_levels)

        class_plot <- ggplot(plot_data, aes(x = run_label, y = participant_id, fill = fill_code)) +
          geom_tile(color = "white") +
          geom_text(aes(label = display_code), size = 3, color = "#1B1B1B") +
          scale_fill_manual(
            values = pt_en_class_colors,
            breaks = names(pt_en_class_colors),
            drop = FALSE,
            na.value = "#EEEEEE"
          ) +
          labs(
            title = paste("Clasificación", suffix, "-", spec$title),
            subtitle = paste("Analito:", p_val, "| n =", n_val),
            x = "Nivel",
            y = "Participante",
            fill = "Clase"
          ) +
          theme_minimal() +
          theme(
            panel.grid = element_blank(),
            axis.text.x = element_text(angle = 45, hjust = 1)
          )

        ggsave(paste0("reports/assets/charts/global_class_heatmap_", suffix, "_", combo_key, "_", p_val, "_n", n_val, ".png"), class_plot, width = 10, height = 8)
      }

      generate_class_heatmap(method_data, "classification_z_en_code", "classification_z_en", "z")
      generate_class_heatmap(method_data, "classification_zprime_en_code", "classification_zprime_en", "zprime")
    }
  }
}

print("Generating combined participant summary plots...")


if (length(all_scores_list) > 0) {
  # Combine all scores from all pollutants and levels into one dataframe
  all_scores_df <- do.call(rbind, all_scores_list) %>%
    filter(participant_id != "ref") %>%
    mutate(
      combination_id = ifelse(
        !is.na(combination_label) & combination_label != "",
        combination_label,
        combination
      ),
      combination_display = ifelse(
        !is.na(combination_label) & combination_label != "",
        paste0(combination, " (", combination_label, ")"),
        combination
      ),
      pollutant = as.character(pollutant)
    )

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
      pollutant_panels <- list()

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
          geom_line(color = "blue") +
          geom_point(color = "blue", size = 2) +
          coord_cartesian(ylim = c(-4, 4)) +
          labs(
            title = paste(toupper(p_local), "- Z-Score"),
            subtitle = combo_row$combo_display,
            x = NULL,
            y = "Z-Score"
          ) +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))

        p_en_score <- ggplot(combo_data, aes(x = level, y = En_score, group = 1)) +
          geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "red") +
          geom_hline(yintercept = 0, color = "grey") +
          geom_line(color = "purple") +
          geom_point(color = "purple", size = 2) +
          coord_cartesian(ylim = c(-4, 4)) +
          labs(
            title = paste(toupper(p_local), "- En-Score"),
            subtitle = combo_row$combo_display,
            x = NULL,
            y = "En-Score"
          ) +
          theme_minimal() +
          theme(axis.text.x = element_text(angle = 45, hjust = 1))

        plot_list <- c(plot_list, list(p_values, p_z_score, p_en_score))
        pollutant_panels <- c(
          pollutant_panels,
          list(
            (p_values / p_z_score / p_en_score) +
              plot_layout(heights = c(1, 1, 1))
          )
        )
      }

      if (length(plot_list) == 0) next

      combined_plot <- wrap_plots(plot_list, ncol = 3, guides = "collect") +
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

      if (length(pollutant_panels) > 0) {
        horizontal_plot <- wrap_plots(
          pollutant_panels,
          nrow = 1,
          guides = "collect"
        ) +
          plot_annotation(
            title = paste(
              "Performance Summary (Pollutants Across Columns) - Participant:",
              participant,
              "| Combination",
              combo_row$combo_id
            ),
            theme = theme(
              plot.title = element_text(size = 16, face = "bold", hjust = 0.5)
            )
          )

        horizontal_filename <- paste0(
          "reports/assets/charts/summary_matrix_horizontal_",
          participant,
          "_combo_",
          sanitized_combo,
          ".png"
        )

        ggsave(
          filename = horizontal_filename,
          plot = horizontal_plot,
          width = 22,
          height = 10,
          units = "cm",
          scale = 1.5
        )
      }
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
    z_prime_score = list(
      label = "Z'-Score",
      short = "zprime",
      eval_col = "z_prime_score_eval",
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
      base_grid <- expand.grid(
        participant_id = participant_levels,
        run_label = run_levels,
        stringsAsFactors = FALSE
      ) %>%
        tibble::as_tibble()

      for (score_name in names(heatmap_specs)) {
        spec <- heatmap_specs[[score_name]]
        value_col <- rlang::sym(score_name)
        eval_col <- rlang::sym(spec$eval_col)

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

      classification_specs <- list(
        list(
          code_col = "classification_z_en_code",
          label_col = "classification_z_en",
          short = "class_z_en",
          title = "z-score + En Classification"
        ),
        list(
          code_col = "classification_zprime_en_code",
          label_col = "classification_zprime_en",
          short = "class_zprime_en",
          title = "z'-score + En Classification"
        )
      )

      for (class_spec in classification_specs) {
        code_sym <- rlang::sym(class_spec$code_col)
        label_sym <- rlang::sym(class_spec$label_col)

        class_plot_data <- base_grid %>%
          left_join(
            combo_df %>%
              select(
                participant_id,
                run_label,
                class_code = !!code_sym,
                class_label = !!label_sym
              ),
            by = c("participant_id", "run_label")
          ) %>%
          mutate(
            class_code = ifelse(class_code == "", NA_character_, class_code),
            class_label = ifelse(is.na(class_label) | class_label == "", "N/A", class_label),
            participant_id = factor(participant_id, levels = participant_levels),
            run_label = factor(run_label, levels = run_levels),
            display_code = case_when(
              is.na(class_code) ~ "",
              grepl("^mu_missing", class_code) ~ "MU",
              TRUE ~ toupper(class_code)
            ),
            fill_code = factor(class_code, levels = names(pt_en_class_colors))
          )

        if (all(is.na(class_plot_data$class_code))) next

        classification_plot <- ggplot(class_plot_data, aes(x = run_label, y = participant_id, fill = fill_code)) +
          geom_tile(color = "white") +
          geom_text(aes(label = display_code), size = 3, color = "#1B1B1B") +
          scale_fill_manual(
            values = pt_en_class_colors,
            breaks = names(pt_en_class_labels),
            labels = names(pt_en_class_labels),
            drop = FALSE,
            na.value = "#EEEEEE"
          ) +
          labs(
            title = paste(class_spec$title, "for Pollutant:", pollutant_id, "- Combination", combo_id),
            subtitle = combination_display,
            x = "Run (Level)",
            y = "Participant",
            fill = "Class"
          ) +
          theme_minimal() +
          theme(
            panel.grid = element_blank(),
            axis.text.x = element_text(angle = 45, hjust = 1),
            axis.title.x = element_text(margin = margin(t = 12)),
            axis.title.y = element_text(margin = margin(r = 12)),
            legend.position = "bottom"
          )

        sanitized_pollutant <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", pollutant_id)))
        sanitized_combination <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", combo_id)))
        class_prefix <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", tolower(class_spec$short))))
        class_output <- file.path(
          "reports/assets/charts",
          paste0(class_prefix, "_table_", sanitized_pollutant, "_", sanitized_combination, ".png")
        )
        class_width <- max(6, length(run_levels) * 1.2)
        class_height <- max(4, length(participant_levels) * 0.6)

        ggsave(class_output, classification_plot, width = class_width, height = class_height, dpi = 300)
      }
    }
  }

  # --- Combination-Level Performance Summary Plots ---
  print("  - Creating combination performance summary plots...")
  combo_ids_for_plot <- sort(unique(stats::na.omit(all_scores_df$combination_id)))
  for (combo_id in combo_ids_for_plot) {
    combo_data_all <- all_scores_df %>% filter(combination_id == !!combo_id)
    if (nrow(combo_data_all) == 0) next

    combo_display_label <- combo_data_all %>%
      distinct(combination_display) %>%
      pull(combination_display) %>%
      .[1]

    level_levels <- combo_data_all %>%
      mutate(level_numeric = readr::parse_number(as.character(level))) %>%
      arrange(level_numeric, level) %>%
      pull(level) %>%
      unique()

    combo_data_all <- combo_data_all %>%
      mutate(level_factor = factor(level, levels = level_levels))

    ref_df <- combo_data_all %>%
      distinct(pollutant, level_factor, x_pt)

    values_plot <- ggplot() +
      geom_line(
        data = ref_df,
        aes(x = level_factor, y = x_pt, color = "Reference", group = pollutant),
        linetype = "dashed",
        size = 1
      ) +
      geom_point(
        data = ref_df,
        aes(x = level_factor, y = x_pt, color = "Reference"),
        size = 2
      ) +
      geom_line(
        data = combo_data_all,
        aes(
          x = level_factor,
          y = result,
          group = interaction(participant_id, pollutant),
          color = "Participants"
        ),
        alpha = 0.25
      ) +
      geom_point(
        data = combo_data_all,
        aes(x = level_factor, y = result, color = "Participants"),
        position = position_jitter(width = 0.1),
        alpha = 0.6,
        size = 1.2
      ) +
      scale_color_manual(
        name = NULL,
        values = c("Participants" = "#1F77B4", "Reference" = "#D62728")
      ) +
      facet_wrap(~pollutant, scales = "free_x") +
      labs(
        title = "Participant vs Reference",
        subtitle = combo_display_label,
        x = "Level",
        y = "Value"
      ) +
      theme_minimal() +
      theme(
        legend.position = "top",
        axis.text.x = element_text(angle = 45, hjust = 1)
      )

    z_plot <- ggplot(combo_data_all, aes(x = level_factor, y = z_score, group = 1)) +
      geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#B71C1C") +
      geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "#F57F17") +
      geom_hline(yintercept = 0, color = "#424242") +
      geom_line(color = "#1565C0") +
      geom_point(color = "#1565C0", size = 1.8) +
      coord_cartesian(ylim = c(-4, 4)) +
      facet_wrap(~pollutant, scales = "free_x") +
      labs(
        title = "Z-Score",
        subtitle = combo_display_label,
        x = "Level",
        y = "Z-Score"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

    zprime_plot <- ggplot(combo_data_all, aes(x = level_factor, y = z_prime_score, group = 1)) +
      geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#B71C1C") +
      geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "#F57F17") +
      geom_hline(yintercept = 0, color = "#424242") +
      geom_line(color = "#FF8F00") +
      geom_point(color = "#FF8F00", size = 1.8) +
      coord_cartesian(ylim = c(-4, 4)) +
      facet_wrap(~pollutant, scales = "free_x") +
      labs(
        title = "Z'-Score",
        subtitle = combo_display_label,
        x = "Level",
        y = "Z'-Score"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

    zeta_plot <- ggplot(combo_data_all, aes(x = level_factor, y = zeta_score, group = 1)) +
      geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#B71C1C") +
      geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "#F57F17") +
      geom_hline(yintercept = 0, color = "#424242") +
      geom_line(color = "#2E7D32") +
      geom_point(color = "#2E7D32", size = 1.8) +
      coord_cartesian(ylim = c(-4, 4)) +
      facet_wrap(~pollutant, scales = "free_x") +
      labs(
        title = "Zeta-Score",
        subtitle = combo_display_label,
        x = "Level",
        y = "Zeta-Score"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

    en_plot <- ggplot(combo_data_all, aes(x = level_factor, y = En_score, group = 1)) +
      geom_hline(yintercept = c(-1, 1), linetype = "dashed", color = "#B71C1C") +
      geom_hline(yintercept = 0, color = "#424242") +
      geom_line(color = "#6A1B9A") +
      geom_point(color = "#6A1B9A", size = 1.8) +
      coord_cartesian(ylim = c(-4, 4)) +
      facet_wrap(~pollutant, scales = "free_x") +
      labs(
        title = "En-Score",
        subtitle = combo_display_label,
        x = "Level",
        y = "En-Score"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))

    sanitized_combo <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", combo_id)))

    values_grid <- (values_plot | z_plot | en_plot) +
      plot_layout(widths = c(1, 1, 1)) +
      plot_annotation(
        title = paste("Combination", combo_display_label, "- Values, Z-Score & En-Score"),
        theme = theme(
          plot.title = element_text(size = 15, face = "bold", hjust = 0.5)
        )
      )

    zprime_grid <- (zprime_plot | en_plot) +
      plot_layout(widths = c(1, 1)) +
      plot_annotation(
        title = paste("Combination", combo_display_label, "- Z'-Score & En-Score"),
        theme = theme(
          plot.title = element_text(size = 15, face = "bold", hjust = 0.5)
        )
      )

    zeta_grid <- (zeta_plot | en_plot) +
      plot_layout(widths = c(1, 1)) +
      plot_annotation(
        title = paste("Combination", combo_display_label, "- Zeta-Score & En-Score"),
        theme = theme(
          plot.title = element_text(size = 15, face = "bold", hjust = 0.5)
        )
      )

    ggsave(
      file.path("reports/assets/charts", paste0("combo_performance_values_", sanitized_combo, ".png")),
      values_grid,
      width = 15,
      height = 8,
      dpi = 300
    )

    ggsave(
      file.path("reports/assets/charts", paste0("combo_performance_zprime_", sanitized_combo, ".png")),
      zprime_grid,
      width = 10,
      height = 8,
      dpi = 300
    )

    ggsave(
      file.path("reports/assets/charts", paste0("combo_performance_zeta_", sanitized_combo, ".png")),
      zeta_grid,
      width = 10,
      height = 8,
      dpi = 300
    )
  }

  print("  - Creating score criteria summary tables by combination...")
  score_eval_map <- c(
    z_score_eval = "z-score",
    z_prime_score_eval = "z'-score",
    zeta_score_eval = "zeta-score",
    En_score_eval = "En-score"
  )
  criteria_levels <- c("Satisfactory", "Questionable", "Unsatisfactory", "N/A")
  score_order <- unname(score_eval_map)

  combo_ids <- sort(unique(stats::na.omit(all_scores_df$combination_id)))
  for (combo_id in combo_ids) {
    combo_df <- all_scores_df %>% filter(combination_id == !!combo_id)
    if (nrow(combo_df) == 0) next

    pollutant_levels <- sort(unique(combo_df$pollutant))
    if (length(pollutant_levels) == 0) next

    score_rows <- purrr::imap_dfr(
      score_eval_map,
      function(score_title, eval_col_name) {
        eval_sym <- rlang::sym(eval_col_name)
        combo_df %>%
          transmute(
            score = score_title,
            pollutant = factor(pollutant, levels = pollutant_levels),
            criteria = factor(
              dplyr::case_when(
                is.na(!!eval_sym) | !!eval_sym == "" ~ "N/A",
                TRUE ~ as.character(!!eval_sym)
              ),
              levels = criteria_levels
            )
          ) %>%
          count(score, pollutant, criteria, name = "Count") %>%
          tidyr::complete(
            score,
            pollutant,
            criteria,
            fill = list(Count = 0)
          )
      }
    )

    summary_table <- score_rows %>%
      mutate(
        Score = factor(score, levels = score_order),
        Criteria = factor(criteria, levels = criteria_levels)
      ) %>%
      arrange(Score, Criteria) %>%
      select(Score, Criteria, pollutant, Count) %>%
      pivot_wider(
        names_from = pollutant,
        values_from = Count,
        values_fill = 0
      ) %>%
      mutate(
        Score = as.character(Score),
        Criteria = as.character(Criteria)
      )

    sanitized_combo <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", combo_id)))
    output_table_path <- file.path(
      "reports/assets/tables",
      paste0("score_criteria_summary_", sanitized_combo, ".csv")
    )

    write.csv(summary_table, output_table_path, row.names = FALSE)
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

# --- Participant Outlier Detection Plots ---
print("Generating participant distribution plots for outlier detection...")
participant_distribution_df <- summary_data %>%
  filter(!is.na(mean_value), is.finite(mean_value))

if (nrow(participant_distribution_df) == 0) {
  print("  - No participant mean values available for distribution plots.")
} else {
  pollutants_for_outliers <- sort(unique(participant_distribution_df$pollutant))

  for (pollutant_id in pollutants_for_outliers) {
    pollutant_df <- participant_distribution_df %>%
      filter(pollutant == !!pollutant_id)

    if (nrow(pollutant_df) < 3) {
      print(paste("  - Skipping", pollutant_id, "because fewer than 3 participant results were found."))
      next
    }

    level_order <- pollutant_df %>%
      distinct(level) %>%
      mutate(level_numeric = readr::parse_number(as.character(level))) %>%
      arrange(level_numeric, level) %>%
      pull(level)

    if (length(level_order) == 0) {
      next
    }

    pollutant_df <- pollutant_df %>%
      mutate(level = factor(level, levels = level_order))

    density_fill <- pollutant_fill_map[[as.character(pollutant_id)]]
    if (is.null(density_fill)) density_fill <- "#4C78A8"

    box_plot <- ggplot(pollutant_df, aes(x = factor(1), y = mean_value)) +
      geom_boxplot(
        fill = "#4C78A8",
        alpha = 0.55,
        outlier.colour = "#B22222",
        outlier.fill = "#B22222",
        width = 0.4
      ) +
      facet_wrap(~level, nrow = 1, ncol = 5, scales = "free_y") +
      scale_x_discrete(labels = NULL) +
      labs(
        title = "Participant boxplots by concentration level",
        x = NULL,
        y = "Participant mean value"
      ) +
      theme_minimal() +
      theme(
        strip.text = element_text(face = "bold"),
        panel.spacing = grid::unit(1, "lines"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(size = 12, face = "bold"),
        axis.title.x = element_blank()
      )

    density_flags <- pollutant_df %>%
      group_by(level) %>%
      mutate(
        can_estimate_density = dplyr::n_distinct(mean_value) > 1
      ) %>%
      ungroup()

    density_data <- density_flags %>% filter(can_estimate_density)

    density_labels <- density_flags %>%
      group_by(level) %>%
      summarise(
        can_estimate_density = any(can_estimate_density),
        fallback_x = ifelse(all(is.na(mean_value)), 0, mean(mean_value, na.rm = TRUE)),
        .groups = "drop"
      ) %>%
      filter(!can_estimate_density) %>%
      mutate(
        label = "Need >= 2 unique values",
        fallback_x = ifelse(is.finite(fallback_x), fallback_x, 0),
        label_y = 0.02
      )

    if (nrow(density_data) > 0) {
      density_plot <- ggplot(density_data, aes(x = mean_value)) +
        geom_density(
          fill = density_fill,
          color = NA,
          alpha = 0.45,
          adjust = 1
        ) +
        facet_wrap(~level, nrow = 1, ncol = 5, scales = "free") +
        labs(
          title = "Kernel density of participant means",
          x = "Participant mean value",
          y = "Density"
        ) +
        theme_minimal() +
        theme(
          strip.text = element_text(face = "bold"),
          panel.spacing = grid::unit(1, "lines"),
          plot.title = element_text(size = 12, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    } else {
      density_plot <- ggplot(density_labels, aes(x = fallback_x, y = label_y)) +
        geom_text(aes(label = label), color = "#555555", size = 3.5) +
        facet_wrap(~level, nrow = 1, ncol = 5) +
        labs(
          title = "Kernel density of participant means",
          x = "Participant mean value",
          y = "Density"
        ) +
        theme_minimal() +
        theme(
          strip.text = element_text(face = "bold"),
          panel.spacing = grid::unit(1, "lines"),
          plot.title = element_text(size = 12, face = "bold"),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    }

    if (nrow(density_labels) > 0 && nrow(density_data) > 0) {
      density_plot <- density_plot +
        geom_text(
          data = density_labels,
          aes(x = fallback_x, y = label_y, label = label),
          color = "#555555",
          size = 3.5,
          inherit.aes = FALSE
        )
    }

    combined_outlier_plot <- (box_plot | density_plot) +
      plot_layout(widths = c(1, 1)) +
      plot_annotation(
        title = paste("Participant distribution summary -", pollutant_id),
        subtitle = "Left: boxplots (by level); Right: kernel density for outlier screening",
        theme = theme(
          plot.title = element_text(size = 15, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 11, hjust = 0.5)
        )
      )

    sanitized_pollutant <- gsub("_+$", "", gsub("^_+", "", gsub("[^A-Za-z0-9]+", "_", pollutant_id)))
    outlier_path <- file.path(
      "reports/assets/charts",
      paste0("participant_distribution_", sanitized_pollutant, ".png")
    )
    ggsave(
      outlier_path,
      combined_outlier_plot,
      width = 20,
      height = 7,
      dpi = 300,
      units = "cm"
    )
  }
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
    select(
      pollutant, n_lab, level, combination, combination_label,
      z_score_eval, zeta_score_eval, En_score_eval
    ) %>%
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
