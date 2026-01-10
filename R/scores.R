# R/scores.R

library(dplyr)
library(tidyr)
library(purrr)

# Helper for classification labels
pt_en_class_labels <- c(
  a1 = "a1 - Totalmente satisfactorio",
  a2 = "a2 - Satisfactorio pero conservador",
  a3 = "a3 - Satisfactorio con MU subestimada",
  a4 = "a4 - Cuestionable pero aceptable",
  a5 = "a5 - Cuestionable e inconsistente",
  a6 = "a6 - No satisfactorio pero la MU cubre la desviación",
  a7 = "a7 - No satisfactorio (crítico)"
)

score_eval_z <- function(z) {
  dplyr::case_when(
    !is.finite(z) ~ "N/A",
    abs(z) <= 2 ~ "Satisfactorio",
    abs(z) > 2 & abs(z) < 3 ~ "Cuestionable",
    abs(z) >= 3 ~ "No satisfactorio"
  )
}

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

  list(code = code, label = pt_en_class_labels[[code]])
}

compute_scores_metrics <- function(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k) {
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
    # If no ref data found but method is not 1 (Ref), x_pt might be passed from outside?
    # In this function x_pt is derived from ref_data if using method 1 logic inside app.R
    # But wait, compute_scores_metrics in app.R (lines 405+) calculates x_pt from ref_data ALWAYS.
    # This seems to be a specific implementation for the "Scores" tab preview or initial calc?
    # Actually, lines 405-470 in app.R implement compute_scores_metrics which hardcodes x_pt = mean(ref_data).
    # This implies this specific function is for the "Reference" scenario or base calculation.
    # However, the broader score calculation in app.R (lines 1146+) `compute_scores_for_selection` handles
    # different x_pt sources (Ref, Consensus, Algo A).

    # We will implement the generic calculation logic that takes x_pt as an argument if provided,
    # or defaults to Ref if not. But to match app.R `compute_scores_metrics` exactly:
    return(list(error = "No se encontraron datos de referencia ('ref') para este nivel."))
  }

  x_pt_ref <- mean(ref_data$mean_value, na.rm = TRUE)

  # Allow overriding x_pt if passed (though app.R function doesn't seem to have it as arg, it calculates it).
  # But `compute_scores_metrics` in app.R is ONLY used in `report_preview` (line 1733)
  # AND it takes `sigma_pt`, `u_xpt` as arguments!
  # But inside `compute_scores_metrics` (line 405), it RECALCULATES x_pt from ref_data!
  # This looks like a potential inconsistency in app.R if report_preview passes a Consensus x_pt
  # but compute_scores_metrics overwrites it with Ref x_pt.

  # Let's check app.R line 427: `x_pt <- mean(ref_data$mean_value, na.rm = TRUE)`
  # Yes, it overwrites it. This means `report_preview` in app.R might be showing scores against Reference
  # regardless of the method selected for x_pt, OR `compute_scores_metrics` is only intended for Method 1.

  # Wait, looking at `report_preview` in app.R:
  # It calculates `x_pt` based on method (Ref, Consensus, Algo A).
  # Then it calls `compute_scores_metrics(...)`.
  # But `compute_scores_metrics` ignores the passed `x_pt`? No, it doesn't take `x_pt` as argument!
  # app.R: `compute_scores_metrics <- function(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k)`
  # It does NOT take `x_pt` as argument.
  # So `report_preview` calculates `x_pt` (lines 1731-1748), but then `compute_scores_metrics` ignores it
  # and calculates its own `x_pt` from reference.
  # This suggests the report preview table might be misleading if Method != 1.

  # HOWEVER, to faithfully reproduce the "Scores Module" logic requested, I should look at `compute_scores_for_selection` (line 1146)
  # which handles the multiple scenarios (Ref, Consensus, Algo A) correctly.
  # I will extract the core scoring LOGIC (calculating z, z', zeta, En given x_pt, sigma_pt, u_xpt)
  # into a reusable function, and then implement `compute_scores_metrics` (the one used for preview)
  # and `compute_combo_scores` (the one used for the main tab).

  x_pt <- x_pt_ref # Default behavior of the existing function

  participant_data <- data # Includes ref? app.R says `participant_data <- data` then renames.
  # Usually we want scores for everyone including ref?

  participant_data <- participant_data %>%
    rename(result = mean_value, uncertainty_std = sd_value)

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
      z_score_eval = score_eval_z(z_score),
      z_prime_score_eval = score_eval_z(z_prime_score),
      zeta_score_eval = score_eval_z(zeta_score),
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
