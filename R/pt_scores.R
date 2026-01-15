# ===================================================================
# Score Calculations for Proficiency Testing
# ISO 13528:2022 Implementation
#
# This file contains pure mathematical functions with NO Shiny dependencies.
# Functions for computing z-score, z'-score, zeta-score, En-score and 
# their evaluations/classifications.
# ===================================================================

#' Calculate z-score
#'
#' z = (x - x_pt) / sigma_pt
#'
#' Reference: ISO 13528:2022, Section 10.2
#'
#' @param x Participant result.
#' @param x_pt Assigned value.
#' @param sigma_pt Standard deviation for proficiency assessment.
#' @return z-score value.
#'
#' @examples
#' # Calculate z-score for a participant
#' z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
#' cat("z-score:", z)  # 1.0 (Satisfactorio)
#'
#' @seealso \code{\link{calculate_z_prime_score}}, \code{\link{evaluate_z_score}}
#' @export
calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / sigma_pt
}

#' Calculate z'-score (z-prime score)
#'
#' z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt^2)
#'
#' Reference: ISO 13528:2022, Section 10.3
#'
#' @param x Participant result.
#' @param x_pt Assigned value.
#' @param sigma_pt Standard deviation for proficiency assessment.
#' @param u_xpt Standard uncertainty of the assigned value.
#' @return z'-score value.
#'
#' @examples
#' # z'-score accounts for uncertainty in assigned value
#' zprime <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5, u_xpt = 0.1)
#'
#' @seealso \code{\link{calculate_z_score}}, \code{\link{calculate_zeta_score}}
#' @export
calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominator <- sqrt(sigma_pt^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Calculate zeta-score
#'
#' zeta = (x - x_pt) / sqrt(u_x^2 + u_xpt^2)
#'
#' Reference: ISO 13528:2022, Section 10.4
#'
#' @param x Participant result.
#' @param x_pt Assigned value.
#' @param u_x Standard uncertainty of participant's result.
#' @param u_xpt Standard uncertainty of the assigned value.
#' @return zeta-score value.
#'
#' @examples
#' # zeta-score uses participant's uncertainty
#' zeta <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.2, u_xpt = 0.1)
#'
#' @seealso \code{\link{calculate_en_score}}
#' @export
calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominator <- sqrt(u_x^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Calculate En-score (Error normalized)
#'
#' En = (x - x_pt) / sqrt(U_x^2 + U_xpt^2)
#'
#' Reference: ISO 13528:2022, Section 10.5
#'
#' @param x Participant result.
#' @param x_pt Assigned value.
#' @param U_x Expanded uncertainty of participant's result.
#' @param U_xpt Expanded uncertainty of the assigned value.
#' @return En-score value.
#'
#' @examples
#' # En-score uses expanded uncertainties (k=2)
#' en <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.4, U_xpt = 0.2)
#' cat("En-score:", en, "Eval:", evaluate_en_score(en))
#'
#' @seealso \code{\link{evaluate_en_score}}, \code{\link{classify_with_en}}
#' @export
calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominator <- sqrt(U_x^2 + U_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Evaluate z-score (or z'-score, zeta-score)
#'
#' Classifies score performance based on ISO 13528 criteria:
#' - |z| <= 2: Satisfactorio (Satisfactory)
#' - 2 < |z| < 3: Cuestionable (Questionable)
#' - |z| >= 3: No satisfactorio (Unsatisfactory)
#'
#' @param z Score value (z, z', or zeta)
#' @return Character string with evaluation category
#' @export
evaluate_z_score <- function(z) {
  if (!is.finite(z)) {
    return("N/A")
  }
  if (abs(z) <= 2) {
    return("Satisfactorio")
  } else if (abs(z) < 3) {
    return("Cuestionable")
  } else {
    return("No satisfactorio")
  }
}

#' Vectorized z-score evaluation
#'
#' @param z Vector of score values
#' @return Character vector with evaluation categories
#' @export
evaluate_z_score_vec <- function(z) {
  dplyr::case_when(
    !is.finite(z) ~ "N/A",
    abs(z) <= 2 ~ "Satisfactorio",
    abs(z) > 2 & abs(z) < 3 ~ "Cuestionable",
    abs(z) >= 3 ~ "No satisfactorio"
  )
}

#' Evaluate En-score
#'
#' Classifies En-score performance:
#' - |En| <= 1: Satisfactorio (Satisfactory)
#' - |En| > 1: No satisfactorio (Unsatisfactory)
#'
#' @param en En-score value
#' @return Character string with evaluation category
#' @export
evaluate_en_score <- function(en) {
  if (!is.finite(en)) {
    return("N/A")
  }
  if (abs(en) <= 1) {
    return("Satisfactorio")
  } else {
    return("No satisfactorio")
  }
}

#' Vectorized En-score evaluation
#'
#' @param en Vector of En-score values
#' @return Character vector with evaluation categories
#' @export
evaluate_en_score_vec <- function(en) {
  dplyr::case_when(
    !is.finite(en) ~ "N/A",
    abs(en) <= 1 ~ "Satisfactorio",
    abs(en) > 1 ~ "No satisfactorio"
  )
}

# ===================================================================
# Combined z/En Classification (a1-a7 categories)
# ===================================================================

#' Classification labels for combined z/En evaluation
#' @export
PT_EN_CLASS_LABELS <- c(
  a1 = "a1 - Totalmente satisfactorio",
  a2 = "a2 - Satisfactorio pero conservador",
  a3 = "a3 - Satisfactorio con MU subestimada",
  a4 = "a4 - Cuestionable pero aceptable",
  a5 = "a5 - Cuestionable e inconsistente",
  a6 = "a6 - No satisfactorio pero la MU cubre la desviación",
  a7 = "a7 - No satisfactorio (crítico)"
)

#' Classification colors for combined z/En evaluation
#' @export
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

#' Classify result using combined z-score and En-score
#'
#' Returns a classification code (a1-a7) based on the combination of
#' z-score (or z'-score) and En-score, considering measurement uncertainty.
#'
#' @param score_val z-score or z'-score value
#' @param en_val En-score value
#' @param U_xi Expanded uncertainty of participant's result
#' @param sigma_pt Standard deviation for proficiency assessment
#' @param mu_missing Logical, TRUE if measurement uncertainty is missing
#' @param score_label Label for the score type ("z" or "z'")
#' @return A list with:
#'   - code: Classification code (a1-a7 or mu_missing_*)
#'   - label: Human-readable classification label
#' @export
classify_with_en <- function(score_val, en_val, U_xi, sigma_pt, mu_missing, score_label) {
  if (!is.finite(score_val)) {
    return(list(code = NA_character_, label = "N/A"))
  }
  
  # Handle missing measurement uncertainty
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
  
  # Validate inputs
  if (!is.finite(en_val) || !is.finite(sigma_pt) || sigma_pt <= 0 || !is.finite(U_xi)) {
    return(list(code = NA_character_, label = "N/A"))
  }
  
  abs_score <- abs(score_val)
  abs_en <- abs(en_val)
  u_is_conservative <- U_xi >= (2 * sigma_pt)
  
  # Classification logic based on z-score and En-score combination
  if (abs_score <= 2) {
    # Satisfactory z-score
    if (abs_en < 1) {
      code <- if (u_is_conservative) "a2" else "a1"
    } else {
      code <- "a3"
    }
  } else if (abs_score < 3) {
    # Questionable z-score
    code <- if (abs_en < 1) "a4" else "a5"
  } else {
    # Unsatisfactory z-score
    code <- if (abs_en < 1) "a6" else "a7"
  }
  
  list(code = code, label = PT_EN_CLASS_LABELS[[code]])
}
