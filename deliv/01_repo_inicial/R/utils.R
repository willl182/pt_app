# ===================================================================
# Utility Functions for PT Data Analysis
# DEPRECATED: Use R/pt_robust_stats.R instead
#
# This file is maintained for backward compatibility only.
# New code should use the functions from pt_robust_stats.R:
# - algorithm_A -> run_algorithm_a (more features, better error handling)
# - mad_e_manual -> calculate_mad_e
# - nIQR_manual -> calculate_niqr
#
# Reference: ISO 13528:2022
# ===================================================================

#' Applies ISO 13528:2022 Algorithm A to a numeric vector
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function is deprecated. Please use \code{\link{run_algorithm_a}} instead,
#' which provides more detailed output including iteration history and weights.
#'
#' @details
#' This function calculates robust estimates of the mean and standard deviation
#' for a dataset, handling outliers by iteratively down-weighting extreme values.
#'
#' @param x A numeric vector of data.
#' @param max_iter An integer specifying the maximum number of iterations.
#' @return A named list containing `robust_mean` and `robust_sd`.
#'
#' @seealso \code{\link{run_algorithm_a}} for the recommended replacement.
#' @export
algorithm_A <- function(x, max_iter = 100) {
  x <- x[!is.na(x)]

  x_star <- stats::median(x)
  s_star <- stats::mad(x, constant = 1.4826)

  x_star_prev <- -Inf
  s_star_prev <- -Inf

  tolerance <- 1e-9

  for (i in 1:max_iter) {
    if (signif(x_star, 3) == signif(x_star_prev, 3) && signif(s_star, 3) == signif(s_star_prev, 3)) {
      return(list(robust_mean = x_star, robust_sd = s_star))
    }

    x_star_prev <- x_star
    s_star_prev <- s_star

    delta <- 1.5 * s_star
    if (s_star < tolerance) {
      return(list(robust_mean = x_star, robust_sd = 0))
    }

    x_prime <- pmin(pmax(x, x_star - delta), x_star + delta)

    x_star <- base::mean(x_prime)
    s_star <- 1.134 * stats::sd(x_prime)
  }

  warning("Algorithm did not converge within the maximum number of iterations.")
  return(list(robust_mean = x_star, robust_sd = s_star))
}

#' Manual Scaled MAD (MADe) Calculation
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function is deprecated. Please use \code{\link{calculate_mad_e}} instead.
#'
#' @details
#' Calculates the Median Absolute Deviation (MAD) and scales it by 1.4826
#' to provide a robust estimate of the standard deviation.
#'
#' @param x A numeric vector.
#' @return The scaled MAD (MADe).
#'
#' @seealso \code{\link{calculate_mad_e}} for the recommended replacement.
#' @export
mad_e_manual <- function(x) {
  x_clean <- x[!is.na(x)]
  if (length(x_clean) == 0) return(NA)

  data_median <- stats::median(x_clean, na.rm = TRUE)
  abs_deviations <- abs(x_clean - data_median)
  mad_value <- stats::median(abs_deviations, na.rm = TRUE)

  return(1.4826 * mad_value)
}

#' Manual Normalized IQR (nIQR) Calculation
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function is deprecated. Please use \code{\link{calculate_niqr}} instead.
#'
#' @details
#' Calculates the Interquartile Range (IQR) and normalizes it by 0.7413
#' to provide a robust estimate of the standard deviation.
#'
#' @param x A numeric vector.
#' @return The normalized IQR (nIQR).
#'
#' @seealso \code{\link{calculate_niqr}} for the recommended replacement.
#' @export
nIQR_manual <- function(x) {
  x_clean <- x[!is.na(x)]
  if (length(x_clean) < 2) return(NA)

  q <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  iqr_value <- q[2] - q[1]

  return(0.7413 * iqr_value)
}