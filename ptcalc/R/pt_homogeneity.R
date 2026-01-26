# ===================================================================
# Homogeneity and Stability Calculations for Proficiency Testing
# ISO 13528:2022 Implementation
#
# This file contains pure mathematical functions with NO Shiny dependencies.
# Functions for computing homogeneity and stability statistics per Section 9.
# ===================================================================

#' Calculate homogeneity statistics from sample data
#'
#' Computes between-sample standard deviation (ss), within-sample standard
#' deviation (sw), and related ANOVA components for homogeneity assessment.
#' Also calculates robust sigma estimate (MADe) and its uncertainty.
#'
#' Reference: ISO 13528:2022, Section 9.2
#'
#' @param sample_data Data frame or matrix with samples as rows and replicates as columns.
#' @return A list containing:
#'   - g: Number of samples (groups)
#'   - m: Number of replicates per sample
#'   - general_mean_homog: Overall mean of ALL values
#'   - sample_means: Vector of sample means
#'   - x_pt: Median of first replicate values
#'   - s_x_bar_sq: Variance of sample means
#'   - s_xt: Standard deviation of sample means
#'   - sw: Within-sample standard deviation
#'   - sw_sq: Within-sample variance
#'   - ss_sq: Between-sample variance component
#'   - ss: Between-sample standard deviation
#'   - median_of_diffs: Median of absolute differences between sample means
#'   - MADe: Robust sigma estimate (1.483 * median_of_diffs)
#'   - sigma_pt: Standard deviation for proficiency assessment (equals MADe)
#'   - u_sigma_pt: Uncertainty of sigma_pt (1.23 * MADe / sqrt(g))
#'   - error: Error message or NULL if successful
#'
#' @examples
#' # Create sample data: 10 items with 2 replicates each
#' sample_data <- matrix(rnorm(20, mean = 10, sd = 0.5), nrow = 10, ncol = 2)
#' stats <- calculate_homogeneity_stats(sample_data)
#' cat("Between-sample SD (ss):", stats$ss, "\n")
#' cat("Sigma PT (MADe):", stats$sigma_pt, "\n")
#'
#' @seealso \code{\link{calculate_homogeneity_criterion}}, \code{\link{evaluate_homogeneity}}
#' @export
calculate_homogeneity_stats <- function(sample_data) {
  # Convert to matrix if needed
  if (is.data.frame(sample_data)) {
    sample_data <- as.matrix(sample_data)
  }

  g <- nrow(sample_data)
  m <- ncol(sample_data)

  if (g < 2) {
    return(list(error = "At least 2 samples required for homogeneity assessment."))
  }
  if (m < 2) {
    return(list(error = "At least 2 replicates per sample required for homogeneity assessment."))
  }

  # Sample means
  sample_means <- rowMeans(sample_data, na.rm = TRUE)

  # General mean: mean of ALL values (not just means)
  general_mean_homog <- base::mean(sample_data, na.rm = TRUE)

  # x_pt: median of first replicate values
  x_pt <- stats::median(sample_data[, 1], na.rm = TRUE)

  # Variance and standard deviation of sample means
  s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)

  # Within-sample standard deviation (using ranges for m=2)
  if (m == 2) {
    range_btw <- abs(sample_data[, 1] - sample_data[, 2])
    sw <- sqrt(sum(range_btw^2) / (2 * g))
  } else {
    within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(base::mean(within_vars, na.rm = TRUE))
  }

  sw_sq <- sw^2

  # Between-sample variance component
  ss_sq <- abs(s_x_bar_sq - (sw_sq / m))
  ss <- sqrt(ss_sq)

  # Absolute differences from x_pt for each sample (using sample_2)
  abs_diff_from_xpt <- abs(sample_data[, 2] - x_pt)

  # sigma_pt: median of absolute differences from x_pt
  sigma_pt <- stats::median(abs_diff_from_xpt, na.rm = TRUE)

  # MADe: robust sigma estimate (1.483 factor for normal distribution)
  MADe <- 1.483 * sigma_pt

  # nIQR: Normalised Interquartile Range (ISO 13528:2022 Section 8.1.2)
  nIQR_val <- 0.7413 * (stats::quantile(sample_data[, 1], 0.75, na.rm = TRUE) - stats::quantile(sample_data[, 1], 0.25, na.rm = TRUE))
  names(nIQR_val) <- NULL

  # Uncertainty of sigma_pt (ISO 13528:2022)
  u_sigma_pt <- 1.25 * MADe / sqrt(g)

  list(
    g = g,
    m = m,
    general_mean_homog = general_mean_homog,
    sample_means = sample_means,
    x_pt = x_pt,
    s_x_bar_sq = s_x_bar_sq,
    s_xt = s_xt,
    sw = sw,
    sw_sq = sw_sq,
    ss_sq = ss_sq,
    ss = ss,
    abs_diff_from_xpt = abs_diff_from_xpt,
    sigma_pt = sigma_pt,
    MADe = MADe,
    u_sigma_pt = u_sigma_pt,
    nIQR = nIQR_val,
    error = NULL
  )
}

#' Calculate homogeneity criterion
#'
#' c = 0.3 * sigma_pt
#'
#' Reference: ISO 13528:2022, Section 9.2.3
#'
#' @param sigma_pt Standard deviation for proficiency assessment.
#' @return The homogeneity criterion value.
#'
#' @examples
#' # Criterion for sigma_pt = 0.5
#' c <- calculate_homogeneity_criterion(sigma_pt = 0.5)
#' cat("Homogeneity criterion:", c)  # 0.15
#'
#' @seealso \code{\link{evaluate_homogeneity}}
#' @export
calculate_homogeneity_criterion <- function(sigma_pt) {
  0.3 * sigma_pt
}

#' Calculate expanded homogeneity criterion
#'
#' c_expanded = c_criterion * sqrt(1 + (u_sigma_pt/sigma_pt)^2)
#'
#' Reference: ISO 13528:2022, Section 9.2.4
#'
#' @param sigma_pt Standard deviation for proficiency assessment (from MADe)
#' @param u_sigma_pt Uncertainty of sigma_pt
#' @return The expanded criterion value
#' @export
calculate_homogeneity_criterion_expanded <- function(sigma_pt, u_sigma_pt) {
  c_criterion <- 0.3 * sigma_pt
  c_criterion * sqrt(1 + (u_sigma_pt/sigma_pt)^2)
}

#' Evaluate homogeneity against criterion
#'
#' @param ss Between-sample standard deviation
#' @param c_criterion Homogeneity criterion
#' @param c_expanded Expanded homogeneity criterion (optional)
#' @return A list with:
#'   - passes_criterion: Logical, TRUE if ss <= c_criterion
#'   - passes_expanded: Logical, TRUE if ss <= c_expanded (or NA if c_expanded not provided)
#'   - conclusion: Text description of result
#' @export
evaluate_homogeneity <- function(ss, c_criterion, c_expanded = NULL) {
  passes_criterion <- ss <= c_criterion
  
  conclusion1 <- if (passes_criterion) {
    sprintf("ss (%.4f) <= criterion (%.4f): MEETS HOMOGENEITY CRITERION", ss, c_criterion)
  } else {
    sprintf("ss (%.4f) > criterion (%.4f): DOES NOT MEET HOMOGENEITY CRITERION", ss, c_criterion)
  }
  
  passes_expanded <- NA
  conclusion2 <- NULL
  
  if (!is.null(c_expanded)) {
    passes_expanded <- ss <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("ss (%.4f) <= expanded (%.4f): MEETS EXPANDED CRITERION", ss, c_expanded)
    } else {
      sprintf("ss (%.4f) > expanded (%.4f): DOES NOT MEET EXPANDED CRITERION", ss, c_expanded)
    }
  }
  
  list(
    passes_criterion = passes_criterion,
    passes_expanded = passes_expanded,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

#' Calculate stability statistics
#'
#' Calculates statistics from stability data using same pattern as homogeneity
#' assessment. Independent of homogeneity calculations. Compares stability mean to
#' homogeneity mean to assess short-term stability of proficiency test items.
#'
#' Reference: ISO 13528:2022, Section 9.3
#'
#' @param stab_sample_data Data frame or matrix with stability samples
#' @param hom_general_mean_homog General mean from homogeneity study
#' @param hom_stab_x_pt Median of 1st replicate values from HOMOGENEITY study (assigned value x_pt), used as REFERENCE for median_of_diffs calculation
#' @param hom_stab_sigma_pt Standard deviation for proficiency assessment from HOMOGENEITY study (robust sigma estimate MADe)
#' @return A list containing:
#'   - g: Number of stability samples (groups)
#'   - m: Number of replicates per stability sample
#'   - general_mean: Overall mean of ALL stability values
#'   - sample_means: Vector of stability sample means
#'   - x_pt: Median of first replicate values (calculated internally, same formula as homogeneity)
#'   - s_x_bar_sq: Variance of stability sample means
#'   - s_xt: Standard deviation of stability sample means
#'   - sw: Within-sample standard deviation (stability)
#'   - sw_sq: Within-sample variance (stability)
#'   - ss_sq: Between-sample variance component (stability)
#'   - ss: Between-sample standard deviation (stability)
#'   - hom_stab_median_of_diffs: Median of absolute differences between 2nd replicate values (stability) and HOMOGENEITY's x_pt
#'   - hom_stab_sigma_pt: Standard deviation from HOMOGENEITY study (passed through, not calculated internally)
#'   - diff_hom_stab: Absolute difference |stability_mean - homogeneity_mean|
#'   - error: Error message or NULL if successful
#' @export
calculate_stability_stats <- function(stab_sample_data, hom_general_mean_homog, hom_stab_x_pt, hom_stab_sigma_pt) {
  # Convert to matrix if needed
  if (is.data.frame(stab_sample_data)) {
    stab_sample_data <- as.matrix(stab_sample_data)
  }

  g_stab <- nrow(stab_sample_data)
  m_stab <- ncol(stab_sample_data)

  if (g_stab < 2) {
    return(list(error = "At least 2 samples required for stability assessment."))
  }
  if (m_stab < 2) {
    return(list(error = "At least 2 replicates per sample required for stability assessment."))
  }

  # Sample means
  stab_sample_means <- rowMeans(stab_sample_data, na.rm = TRUE)

  # General mean: mean of ALL values (not just means)
  stab_general_mean <- base::mean(stab_sample_data, na.rm = TRUE)

  # x_pt: median of first replicate values
  stab_x_pt <- stats::median(stab_sample_data[, 1], na.rm = TRUE)

  # Variance and standard deviation of sample means
  stab_s_x_bar_sq <- stats::var(stab_sample_means, na.rm = TRUE)
  stab_s_xt <- sqrt(stab_s_x_bar_sq)

  # Within-sample standard deviation (using ranges for m=2)
  if (m_stab == 2) {
    range_btw <- abs(stab_sample_data[, 1] - stab_sample_data[, 2])
    stab_sw <- sqrt(sum(range_btw^2) / (2 * g_stab))
  } else {
    within_vars <- apply(stab_sample_data, 1, stats::var, na.rm = TRUE)
    stab_sw <- sqrt(base::mean(within_vars, na.rm = TRUE))
  }

  stab_sw_sq <- stab_sw^2

  # Between-sample variance component
  stab_ss_sq <- abs(stab_s_x_bar_sq - (stab_sw_sq / m_stab))
  stab_ss <- sqrt(stab_ss_sq)

  # hom_stab_median_of_diffs: Median of absolute differences between 2nd replicate (stability) and hom_stab_x_pt (HOMOGENEITY's x_pt as reference)
  hom_stab_median_of_diffs <- stats::median(abs(stab_sample_data[, 2] - hom_stab_x_pt), na.rm = TRUE)

  # Difference between homogeneity and stability means
  diff_hom_stab <- abs(stab_general_mean - hom_general_mean_homog)

  list(
    g = g_stab,
    m = m_stab,
    general_mean = stab_general_mean,
    sample_means = stab_sample_means,
    x_pt = stab_x_pt,
    s_x_bar_sq = stab_s_x_bar_sq,
    s_xt = stab_s_xt,
    sw = stab_sw,
    sw_sq = stab_sw_sq,
    ss_sq = stab_ss_sq,
    ss = stab_ss,
    hom_stab_median_of_diffs = hom_stab_median_of_diffs,
    hom_stab_sigma_pt = hom_stab_sigma_pt,
    diff_hom_stab = diff_hom_stab,
    error = NULL
  )
}

#' Calculate stability criterion
#'
#' c_stab = 0.3 * sigma_pt (same as homogeneity criterion)
#'
#' Reference: ISO 13528:2022, Section 9.3.3
#'
#' @param sigma_pt Standard deviation for proficiency assessment
#' @return The stability criterion value
#' @export
calculate_stability_criterion <- function(sigma_pt) {
  0.3 * sigma_pt
}

#' Calculate expanded stability criterion
#'
#' c_stab_expanded = c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
#'
#' @param c_criterion Base stability criterion
#' @param u_hom_mean Uncertainty of homogeneity mean
#' @param u_stab_mean Uncertainty of stability mean
#' @return The expanded stability criterion
#' @export
calculate_stability_criterion_expanded <- function(c_criterion, u_hom_mean, u_stab_mean) {
  c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
}

#' Evaluate stability against criterion
#'
#' @param diff_hom_stab Absolute difference between stability and homogeneity means
#' @param c_criterion Stability criterion
#' @param c_expanded Expanded stability criterion (optional)
#' @return A list with:
#'   - passes_criterion: Logical, TRUE if diff <= c_criterion
#'   - passes_expanded: Logical, TRUE if diff <= c_expanded (or NA if not provided)
#'   - conclusion: Text description of result
#' @export
evaluate_stability <- function(diff_hom_stab, c_criterion, c_expanded = NULL) {
  passes_criterion <- diff_hom_stab <= c_criterion
  
  conclusion1 <- if (passes_criterion) {
    sprintf("diff (%.4f) <= criterion (%.4f): MEETS STABILITY CRITERION", diff_hom_stab, c_criterion)
  } else {
    sprintf("diff (%.4f) > criterion (%.4f): DOES NOT MEET STABILITY CRITERION", diff_hom_stab, c_criterion)
  }
  
  passes_expanded <- NA
  conclusion2 <- NULL
  
  if (!is.null(c_expanded)) {
    passes_expanded <- diff_hom_stab <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("diff (%.4f) <= expanded (%.4f): MEETS EXPANDED CRITERION", diff_hom_stab, c_expanded)
    } else {
      sprintf("diff (%.4f) > expanded (%.4f): DOES NOT MEET EXPANDED CRITERION", diff_hom_stab, c_expanded)
    }
  }
  
  list(
    passes_criterion = passes_criterion,
    passes_expanded = passes_expanded,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

#' Calculate uncertainty contribution from homogeneity
#'
#' u_hom = ss (between-sample standard deviation)
#'
#' Reference: ISO 13528:2022, Section 9.5
#'
#' @param ss Between-sample standard deviation from homogeneity study
#' @return Uncertainty contribution from homogeneity
#' @export
calculate_u_hom <- function(ss) {
  ss
}

#' Calculate uncertainty contribution from stability
#'
#' u_stab = diff_hom_stab / sqrt(3) (if criterion not met)
#' or 0 (if criterion is met)
#'
#' Reference: ISO 13528:2022, Section 9.5
#'
#' @param diff_hom_stab Absolute difference between stability and homogeneity means
#' @param c_criterion Stability criterion
#' @return Uncertainty contribution from stability
#' @export
calculate_u_stab <- function(diff_hom_stab, c_criterion) {
  if (diff_hom_stab <= c_criterion) {
    return(0)
  }
  diff_hom_stab / sqrt(3)
}
