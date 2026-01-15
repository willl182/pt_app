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
#'
#' Reference: ISO 13528:2022, Section 9.2
#'
#' @param sample_data Data frame or matrix with samples as rows and replicates as columns.
#' @return A list containing:
#'   - g: Number of samples (groups)
#'   - m: Number of replicates per sample
#'   - grand_mean: Overall mean (x bar bar)
#'   - sample_means: Vector of sample means
#'   - s_x_bar_sq: Variance of sample means
#'   - s_xt: Standard deviation of sample means
#'   - sw: Within-sample standard deviation
#'   - sw_sq: Within-sample variance
#'   - ss_sq: Between-sample variance component
#'   - ss: Between-sample standard deviation
#'   - error: Error message or NULL if successful
#'
#' @examples
#' # Create sample data: 10 items with 2 replicates each
#' sample_data <- matrix(rnorm(20, mean = 10, sd = 0.5), nrow = 10, ncol = 2)
#' stats <- calculate_homogeneity_stats(sample_data)
#' cat("Between-sample SD (ss):", stats$ss, "\n")
#'
#' @seealso \code{\link{calculate_homogeneity_criterion}}, \code{\link{evaluate_homogeneity}}
#' @export
calculate_homogeneity_stats <- function(sample_data) {
  # Convert to matrix if needed
  if (is.data.frame(sample_data)) {
    sample_data <- as.matrix(sample_data)
  }
  
  g <- nrow(sample_data)  # Number of samples
  m <- ncol(sample_data)  # Number of replicates
  
  if (g < 2) {
    return(list(error = "At least 2 samples required for homogeneity assessment."))
  }
  if (m < 2) {
    return(list(error = "At least 2 replicates per sample required for homogeneity assessment."))
  }
  
  # Sample means and grand mean
  sample_means <- rowMeans(sample_data, na.rm = TRUE)
  grand_mean <- base::mean(sample_means, na.rm = TRUE)
  
  # Variance of sample means
  s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)
  
  # Within-sample standard deviation (using ranges for m=2)
  if (m == 2) {
    ranges <- abs(sample_data[, 1] - sample_data[, 2])
    sw <- sqrt(sum(ranges^2) / (2 * g))
  } else {
    # General case: pooled within-sample variance
    within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(base::mean(within_vars, na.rm = TRUE))
  }
  
  sw_sq <- sw^2
  
  # Between-sample variance component
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
#' c_expanded = sqrt(sigma_allowed_sq * 1.88 + sw_sq * 1.01)
#'
#' Reference: ISO 13528:2022, Section 9.2.4
#'
#' @param sigma_pt Standard deviation for proficiency assessment
#' @param sw_sq Within-sample variance
#' @return The expanded criterion value
#' @export
calculate_homogeneity_criterion_expanded <- function(sigma_pt, sw_sq) {
  c_criterion <- 0.3 * sigma_pt
  sigma_allowed_sq <- c_criterion^2
  sqrt(sigma_allowed_sq * 1.88 + sw_sq * 1.01)
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
#' Compares stability sample mean to homogeneity sample mean to assess
#' short-term stability of proficiency test items.
#'
#' Reference: ISO 13528:2022, Section 9.3
#'
#' @param stab_sample_data Data frame or matrix with stability samples
#' @param hom_grand_mean Grand mean from homogeneity study
#' @return A list containing:
#'   - stab_grand_mean: Mean of stability samples
#'   - diff_hom_stab: Absolute difference |stab_mean - hom_mean|
#'   - (plus all outputs from calculate_homogeneity_stats on stability data)
#' @export
calculate_stability_stats <- function(stab_sample_data, hom_grand_mean) {
  # First calculate homogeneity-type stats on stability data
  stats <- calculate_homogeneity_stats(stab_sample_data)
  
  if (!is.null(stats$error)) {
    return(stats)
  }
  
  # Add stability-specific calculations
  stats$stab_grand_mean <- stats$grand_mean
  stats$diff_hom_stab <- abs(stats$grand_mean - hom_grand_mean)
  
  stats
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
