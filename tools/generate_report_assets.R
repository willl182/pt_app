# generate_report_assets.R

# This script generates all the tables and charts needed for the reports.

# 1. Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
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
hom_data_full <- read.csv("../homogeneity.csv")
stab_data_full <- read.csv("../stability.csv")
summary_data <- read.csv("../summary_n7.csv")
summary_data$n_lab <- 7 # Add n_lab column for consistency

# Create output directories
dir.create("../reports/assets", showWarnings = FALSE)
dir.create("../reports/assets/charts", showWarnings = FALSE)
dir.create("../reports/assets/tables", showWarnings = FALSE)


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

# 5. PT Scores Analysis
compute_scores_metrics <- function(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k) {
    if (is.null(summary_df) || nrow(summary_df) == 0) {
      return(list(error = "No summary data available for PT scores."))
    }

    data <- summary_df %>%
      filter(
        pollutant == target_pollutant,
        n_lab == target_n_lab,
        level == target_level
      )

    if (nrow(data) == 0) {
      return(list(error = "No data found for the selected criteria."))
    }

    ref_data <- data %>% filter(participant_id == "ref")
    participant_data <- data %>% filter(participant_id != "ref")

    if (nrow(ref_data) == 0) {
      return(list(error = "No reference data ('ref' participant) found for this level."))
    }
    if (nrow(participant_data) == 0) {
      return(list(error = "No participant data found for this level."))
    }

    x_pt <- mean(ref_data$mean_value, na.rm = TRUE)

    participant_data <- participant_data %>%
      rename(result = mean_value, uncertainty_std = sd_value)

    final_scores <- participant_data %>%
      mutate(
        z_score = (result - x_pt) / sigma_pt,
        z_prime_score = (result - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
        zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
        U_xi = k * uncertainty_std,
        U_xpt = k * u_xpt,
        En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2)
      ) %>%
      mutate(
        z_score_eval = case_when(
          abs(z_score) <= 2 ~ "Satisfactory",
          abs(z_score) > 2 & abs(z_score) < 3 ~ "Questionable",
          abs(z_score) >= 3 ~ "Unsatisfactory",
          TRUE ~ "N/A"
        ),
        z_prime_score_eval = case_when(
          abs(z_prime_score) <= 2 ~ "Satisfactory",
          abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Questionable",
          abs(z_prime_score) >= 3 ~ "Unsatisfactory",
          TRUE ~ "N/A"
        ),
        zeta_score_eval = case_when(
          abs(zeta_score) <= 2 ~ "Satisfactory",
          abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Questionable",
          abs(zeta_score) >= 3 ~ "Unsatisfactory",
          TRUE ~ "N/A"
        ),
        En_score_eval = case_when(
          abs(En_score) <= 1 ~ "Satisfactory",
          abs(En_score) > 1 ~ "Unsatisfactory",
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

# 6. Generate outputs
pollutants <- unique(summary_data$pollutant)
levels <- unique(summary_data$level)

for (p in pollutants) {
    for (l in levels) {
        print(paste("Processing:", p, "-", l))

        # --- Homogeneity and Stability ---
        hom_results <- compute_homogeneity_metrics(p, l)
        if (!is.null(hom_results$error)) {
            print(paste("  - Homogeneity Error:", hom_results$error))
        } else {
            stab_results <- compute_stability_metrics(p, l, hom_results)
            if (!is.null(stab_results$error)) {
                print(paste("  - Stability Error:", stab_results$error))
            } else {
                # Save tables
                write.csv(hom_results$intermediate_df, paste0("../reports/assets/tables/homogeneity_details_", p, "_", l, ".csv"))
                write.csv(stab_results$stab_intermediate_df, paste0("../reports/assets/tables/stability_details_", p, "_", l, ".csv"))

                # Create and save plots
                hom_plot_data <- hom_data_full %>% filter(pollutant == p, level == l) %>% pivot_longer(starts_with("sample_"), names_to = "sample", values_to = "result")

                p_hom_hist <- ggplot(hom_plot_data, aes(x = result)) + geom_histogram(bins=20) + ggtitle(paste("Homogeneity Distribution:", p, "-", l))
                ggsave(paste0("../reports/assets/charts/homogeneity_hist_", p, "_", l, ".png"), p_hom_hist)

                p_hom_box <- ggplot(hom_plot_data, aes(y = result)) + geom_boxplot() + ggtitle(paste("Homogeneity Boxplot:", p, "-", l))
                ggsave(paste0("../reports/assets/charts/homogeneity_box_", p, "_", l, ".png"), p_hom_box)
            }
        }

        # --- PT Preparation ---
        pt_prep_results <- compute_pt_prep_metrics(summary_data, p, l)
        if (!is.null(pt_prep_results$error)) {
            print(paste("  - PT Prep Error:", pt_prep_results$error))
        } else {
            # Save tables
            write.csv(pt_prep_results$data, paste0("../reports/assets/tables/pt_prep_data_", p, "_", l, ".csv"))
            writeLines(pt_prep_results$grubbs, paste0("../reports/assets/tables/pt_prep_grubbs_", p, "_", l, ".txt"))

            # Create and save plots
            p_pt_prep_hist <- ggplot(pt_prep_results$data, aes(x=mean_value)) + geom_histogram(bins=15) + ggtitle(paste("PT Prep Distribution:", p, "-", l))
            ggsave(paste0("../reports/assets/charts/pt_prep_hist_", p, "_", l, ".png"), p_pt_prep_hist)

            p_pt_prep_box <- ggplot(pt_prep_results$data, aes(y=mean_value)) + geom_boxplot() + ggtitle(paste("PT Prep Boxplot:", p, "-", l))
            ggsave(paste0("../reports/assets/charts/pt_prep_box_", p, "_", l, ".png"), p_pt_prep_box)
        }

        # --- PT Scores ---
        # Using hom_results$sigma_pt and hom_results$u_xpt as default values
        if (!is.null(hom_results) && is.null(hom_results$error)) {
            scores_results <- compute_scores_metrics(summary_data, p, 7, l, hom_results$sigma_pt, hom_results$u_xpt, 2)
            if (!is.null(scores_results$error)) {
                print(paste("  - Scores Error:", scores_results$error))
            } else {
                # Save table
                write.csv(scores_results$scores, paste0("../reports/assets/tables/scores_table_", p, "_", l, ".csv"))

                # Create and save plots
                p_z <- ggplot(scores_results$scores, aes(x=reorder(participant_id, z_score), y=z_score)) + geom_point() + geom_hline(yintercept=c(-2,2), linetype="dashed") + geom_hline(yintercept=c(-3,3), linetype="dotted") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) + ggtitle(paste("Z-Scores:", p, "-", l))
                ggsave(paste0("../reports/assets/charts/z_scores_", p, "_", l, ".png"), p_z)

                p_zeta <- ggplot(scores_results$scores, aes(x=reorder(participant_id, zeta_score), y=zeta_score)) + geom_point() + geom_hline(yintercept=c(-2,2), linetype="dashed") + geom_hline(yintercept=c(-3,3), linetype="dotted") + theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) + ggtitle(paste("Zeta-Scores:", p, "-", l))
                ggsave(paste0("../reports/assets/charts/zeta_scores_", p, "_", l, ".png"), p_zeta)

            }
        }
    }
}

print("Script finished. All assets generated.")
