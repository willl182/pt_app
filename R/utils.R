# ===================================================================
# Utility Functions for PT Data Analysis
#
# This script contains centralized, reusable functions for the
# app_gem.R Shiny application, including robust statistical
# estimators as described in ISO 13528:2022.
#
# Functions:
# - algorithm_A: Implements ISO 13528:2022 Algorithm A for robust mean/SD.
# - mad_e_manual: Calculates the scaled Median Absolute Deviation (MADe).
# - nIQR_manual: Calculates the normalized Interquartile Range (nIQR).
#
# ===================================================================

#' Applies ISO 13528:2022 Algorithm A to a numeric vector.
#'
#' This function calculates robust estimates of the mean and standard deviation
#' for a dataset, handling outliers by iteratively down-weighting extreme values.
#'
#' @param x A numeric vector of data.
#' @param max_iter An integer specifying the maximum number of iterations.
#' @return A named list containing `robust_mean` and `robust_sd`.
algorithm_A <- function(x, max_iter = 100) {
  x <- x[!is.na(x)]

  x_star <- median(x)
  s_star <- mad(x, constant = 1.4826)

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

    x_star <- mean(x_prime)
    s_star <- 1.134 * sd(x_prime)
  }

  warning("Algorithm did not converge within the maximum number of iterations.")
  return(list(robust_mean = x_star, robust_sd = s_star))
}

#' Manual Scaled MAD (MADe) Calculation
#'
#' Calculates the Median Absolute Deviation (MAD) and scales it by 1.4826
#' to provide a robust estimate of the standard deviation.
#'
#' @param x A numeric vector.
#' @return The scaled MAD (MADe).
mad_e_manual <- function(x) {
  x_clean <- x[!is.na(x)]
  if (length(x_clean) == 0) return(NA)

  data_median <- median(x_clean, na.rm = TRUE)
  abs_deviations <- abs(x_clean - data_median)
  mad_value <- median(abs_deviations, na.rm = TRUE)

  return(1.4826 * mad_value)
}

#' Manual Normalized IQR (nIQR) Calculation
#'
#' Calculates the Interquartile Range (IQR) and normalizes it by 0.7413
#' to provide a robust estimate of the standard deviation.
#'
#' @param x A numeric vector.
#' @return The normalized IQR (nIQR).
nIQR_manual <- function(x) {
  x_clean <- x[!is.na(x)]
  if (length(x_clean) < 2) return(NA)

  q <- quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  iqr_value <- q[2] - q[1]

  return(0.7413 * iqr_value)
}