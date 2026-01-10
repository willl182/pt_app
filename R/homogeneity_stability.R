# Homogeneity and Stability Analysis Functions

#' Compute Homogeneity Metrics
#'
#' @param target_pollutant Pollutant name
#' @param target_level Level name
#' @param hom_data_full Full homogeneity dataframe
#' @return List of results including statistics, ANOVA summary, and pass/fail flags
compute_homogeneity_metrics <- function(target_pollutant, target_level, hom_data_full) {
  # Note: `hom_data_full` argument passed explicitly to keep function pure,
  # unlike app.R which used reactive `hom_data_full()`.

  if (is.null(hom_data_full)) return(list(error = "No hay datos cargados."))

  wide_df <- get_wide_data(hom_data_full, target_pollutant)
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
    dplyr::filter(level == target_level) %>%
    dplyr::select(dplyr::starts_with("sample_"))

  g <- nrow(level_data)
  m <- ncol(level_data)

  if (m < 2) {
    return(list(error = "No hay suficientes réplicas (se requieren al menos 2) para evaluar la homogeneidad."))
  }
  if (g < 2) {
    return(list(error = "No hay suficientes ítems (se requieren al menos 2) para evaluar la homogeneidad."))
  }

  intermediate_df <- if (m == 2) {
    s1 <- level_data[[1]]
    s2 <- level_data[[2]]
    level_data %>%
      dplyr::mutate(
        Item = dplyr::row_number(),
        average = (s1 + s2) / 2,
        range = abs(s1 - s2)
      ) %>%
      dplyr::select(Item, dplyr::everything())
  } else {
    level_data %>%
      dplyr::mutate(
        Item = dplyr::row_number(),
        average = rowMeans(., na.rm = TRUE),
        range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
      ) %>%
      dplyr::select(Item, dplyr::everything())
  }

  hom_data <- level_data %>%
    dplyr::mutate(Item = factor(dplyr::row_number())) %>%
    tidyr::pivot_longer(
      cols = -Item,
      names_to = "replicate",
      values_to = "Resultado"
    )

  if (!"sample_1" %in% names(level_data)) {
    return(list(error = "No se encontró la columna 'sample_1'. Es obligatoria para calcular sigma_pt."))
  }

  first_sample_results <- level_data %>% dplyr::pull(sample_1)
  median_val <- median(first_sample_results, na.rm = TRUE)
  abs_diff_from_median <- abs(first_sample_results - median_val)
  median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
  mad_e <- 1.483 * median_abs_diff
  n_iqr <- calculate_niqr(first_sample_results)

  n_robust <- length(first_sample_results)
  u_xpt <- 1.25 * mad_e / sqrt(n_robust)

  hom_item_stats <- hom_data %>%
    dplyr::group_by(Item) %>%
    dplyr::summarise(
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

  hom_anova_summary <- data.frame(
    "gl" = c(g - 1, g * (m - 1)),
    "Suma de cuadrados" = c(hom_s_x_bar_sq * m * (g - 1), hom_sw^2 * g * (m - 1)),
    "Media de cuadrados" = c(hom_s_x_bar_sq * m, hom_sw^2),
    check.names = FALSE
  )
  rownames(hom_anova_summary) <- c("Ítem", "Residuos")

  hom_sigma_pt <- mad_e
  hom_c_criterion <- 0.3 * hom_sigma_pt
  hom_sigma_allowed_sq <- hom_c_criterion^2
  hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)

  # Determine pass/fail status (Data only, no HTML)
  passed_criterion <- hom_ss <= hom_c_criterion
  passed_expanded <- hom_ss <= hom_c_criterion_expanded

  list(
    summary = hom_anova_summary,
    ss = hom_ss,
    sw = hom_sw,
    passed_criterion = passed_criterion,
    passed_expanded = passed_expanded,
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

#' Compute Stability Metrics
#'
#' @param target_pollutant Pollutant name
#' @param target_level Level name
#' @param hom_results Results from compute_homogeneity_metrics
#' @param stab_data_full Full stability dataframe
#' @return List of results
compute_stability_metrics <- function(target_pollutant, target_level, hom_results, stab_data_full) {
  if (is.null(stab_data_full)) return(list(error = "No hay datos de estabilidad cargados."))

  wide_df <- get_wide_data(stab_data_full, target_pollutant)
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
    dplyr::filter(level == target_level) %>%
    dplyr::select(dplyr::starts_with("sample_"))

  g <- nrow(level_data)
  m <- ncol(level_data)

  if (m < 2) {
    return(list(error = "No hay suficientes réplicas (se requieren al menos 2) para evaluar la homogeneidad en los datos de estabilidad."))
  }
  if (g < 2) {
    return(list(error = "No hay suficientes ítems (se requieren al menos 2) para evaluar la homogeneidad en los datos de estabilidad."))
  }

  intermediate_df <- if (m == 2) {
    s1 <- level_data[[1]]
    s2 <- level_data[[2]]
    level_data %>%
      dplyr::mutate(
        Item = dplyr::row_number(),
        average = (s1 + s2) / 2,
        range = abs(s1 - s2)
      ) %>%
      dplyr::select(Item, dplyr::everything())
  } else {
    level_data %>%
      dplyr::mutate(
        Item = dplyr::row_number(),
        average = rowMeans(., na.rm = TRUE),
        range = apply(., 1, function(x) max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
      ) %>%
      dplyr::select(Item, dplyr::everything())
  }

  stab_data <- level_data %>%
    dplyr::mutate(Item = factor(dplyr::row_number())) %>%
    tidyr::pivot_longer(
      cols = -Item,
      names_to = "replicate",
      values_to = "Resultado"
    )

  if (!"sample_1" %in% names(level_data)) {
    return(list(error = "No se encontró la columna 'sample_1'. Es obligatoria para calcular sigma_pt en los datos de estabilidad."))
  }

  first_sample_results <- level_data %>% dplyr::pull(sample_1)
  median_val <- median(first_sample_results, na.rm = TRUE)
  abs_diff_from_median <- abs(first_sample_results - median_val)
  median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
  mad_e <- 1.483 * median_abs_diff
  stab_n_iqr <- calculate_niqr(first_sample_results)

  n_robust <- length(first_sample_results)
  u_xpt <- 1.25 * mad_e / sqrt(n_robust)

  stab_item_stats <- stab_data %>%
    dplyr::group_by(Item) %>%
    dplyr::summarise(
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

  stab_anova_summary <- data.frame(
    "gl" = c(g - 1, g * (m - 1)),
    "Suma de cuadrados" = c(stab_s_x_bar_sq * m * (g - 1), stab_sw^2 * g * (m - 1)),
    "Media de cuadrados" = c(stab_s_x_bar_sq * m, stab_sw^2),
    check.names = FALSE
  )
  rownames(stab_anova_summary) <- c("Ítem", "Residuos")

  stab_sigma_pt <- mad_e
  stab_c_criterion <- 0.3 * hom_results$sigma_pt
  stab_sigma_allowed_sq <- stab_c_criterion^2

  # Calculate u_hom_mean
  hom_values <- hom_results$data_wide %>%
    dplyr::select(dplyr::starts_with("sample_")) %>%
    unlist() %>%
    as.numeric()
  hom_values <- hom_values[!is.na(hom_values)]
  sd_hom_mean <- sd(hom_values)
  n_hom <- length(hom_values)
  u_hom_mean <- sd_hom_mean / sqrt(n_hom)

  # Calculate u_stab_mean
  stab_values <- stab_data$Resultado
  stab_values <- stab_values[!is.na(stab_values)]
  sd_stab_mean <- sd(stab_values)
  n_stab <- length(stab_values)
  u_stab_mean <- sd_stab_mean / sqrt(n_stab)

  stab_c_criterion_expanded <- stab_c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)

  # Flags for pass/fail
  passed_criterion <- diff_hom_stab <= stab_c_criterion
  passed_expanded <- diff_hom_stab <= stab_c_criterion_expanded

  list(
    stab_summary = stab_anova_summary,
    stab_ss = stab_ss,
    stab_sw = stab_sw,
    passed_criterion = passed_criterion,
    passed_expanded = passed_expanded,
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

#' Perform T-test for stability
#'
#' @param hom_values Numeric vector of homogeneity results
#' @param stab_values Numeric vector of stability results
#' @return List with p.value, statistic, and conclusion boolean (significant_diff)
check_stability_ttest <- function(hom_values, stab_values) {
  if (length(hom_values) < 2 || length(stab_values) < 2) {
    return(list(p_value = NA, significant_diff = NA, error = "Datos insuficientes para prueba t"))
  }
  res <- t.test(hom_values, stab_values)
  list(
    p_value = res.value,
    statistic = res,
    significant_diff = res.value <= 0.05,
    method = res,
    error = NULL
  )
}
