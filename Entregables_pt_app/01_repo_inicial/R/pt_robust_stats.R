# ===================================================================
# Robust Statistical Estimators for Proficiency Testing
# ISO 13528:2022 Implementation
#
# This file contains pure mathematical functions with NO Shiny dependencies.
# Functions:
# - calculate_niqr: Normalized Interquartile Range
# - calculate_mad_e: Scaled Median Absolute Deviation
# - run_algorithm_a: ISO 13528 Algorithm A for robust mean/sd
# ===================================================================

#' Normalized Interquartile Range (nIQR)
#'
#' Calculates 0.7413 * IQR, providing a robust estimate of the standard deviation.
#' The factor 0.7413 ensures consistency with normal distribution.
#'
#' @details
#' The nIQR is a robust scale estimator that is resistant to outliers.
#' For normally distributed data, nIQR ≈ σ (population standard deviation).
#'
#' Reference: ISO 13528:2022, Section 9.4
#'
#' @param x A numeric vector.
#' @return The normalized IQR (nIQR), or NA if insufficient data.
#'
#' @examples
#' # Calculate nIQR for proficiency testing data
#' values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
#' calculate_niqr(values)
#'
#' @seealso \code{\link{calculate_mad_e}} for an alternative robust scale estimator.
#' @export
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

#' Scaled Median Absolute Deviation (MADe)
#'
#' Calculates 1.483 * MAD, providing a robust estimate of the standard deviation.
#' The factor 1.483 ensures consistency with normal distribution.
#'
#' @details
#' The MADe is a robust scale estimator highly resistant to outliers.
#' For normally distributed data, MADe ≈ σ (population standard deviation).
#'
#' Reference: ISO 13528:2022, Section 9.4
#'
#' @param x A numeric vector.
#' @return The scaled MAD (MADe), or NA if insufficient data.
#'
#' @examples
#' # Calculate MADe for data with an outlier
#' values <- c(10.1, 10.2, 9.9, 10.0, 50.0)  # 50 is outlier
#' calculate_mad_e(values)  # Robust to the outlier
#'
#' @seealso \code{\link{calculate_niqr}} for an alternative robust scale estimator.
#' @export
calculate_mad_e <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) == 0) {
    return(NA_real_)
  }
  data_median <- stats::median(x_clean, na.rm = TRUE)
  abs_deviations <- abs(x_clean - data_median)
  mad_value <- stats::median(abs_deviations, na.rm = TRUE)
  1.483 * mad_value
}

#' ISO 13528 Algorithm A - Robust Mean and Standard Deviation
#'
#' Iterative algorithm for computing robust estimates of location (x*) and
#' scale (s*) from proficiency testing data. Down-weights outliers using
#' Huber-type weighting.
#'
#' @details
#' Algorithm A is an iterative procedure that computes robust estimates:
#' 1. Initialize with median (x*) and scaled MAD (s*)
#' 2. Compute standardized residuals: u = (x - x*) / (1.5 * s*)
#' 3. Apply Huber weights: w = 1 if |u| <= 1, else w = 1/u^2
#' 4. Update x* and s* using weighted mean and weighted SD
#' 5. Repeat until convergence (changes < tolerance)
#'
#' Reference: ISO 13528:2022, Annex C
#'
#' @param values A numeric vector of participant results.
#' @param ids Optional vector of participant identifiers (same length as values).
#' @param max_iter Maximum number of iterations (default: 50).
#' @param tol Convergence tolerance for x* and s* (default: 1e-03).
#' @return A list containing:
#'   - assigned_value: Robust mean (x*)
#'   - robust_sd: Robust standard deviation (s*)
#'   - iterations: Data frame of iteration history
#'   - weights: Data frame with participant weights
#'   - converged: Logical indicating convergence
#'   - effective_weight: Sum of final weights
#'   - error: Error message or NULL if successful
#'
#' @examples
#' # Robust mean/sd with outlier in data
#' values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 50.0)  # 50 is outlier
#' result <- run_algorithm_a(values)
#' cat("Robust mean:", result$assigned_value, "\n")
#' cat("Robust SD:", result$robust_sd, "\n")
#'
#' @seealso \code{\link{calculate_niqr}}, \code{\link{calculate_mad_e}}
#' @export
run_algorithm_a <- function(values, ids = NULL, max_iter = 50, tol = 1e-03) {
  # Remove non-finite values
  mask <- is.finite(values)
  values <- values[mask]
  
  if (is.null(ids)) {
    ids <- seq_along(values)
  } else {
    ids <- ids[mask]
  }
  
  n <- length(values)
  if (n < 3) {
    return(list(
      error = "Algorithm A requires at least 3 valid observations.",
      assigned_value = NA_real_,
      robust_sd = NA_real_,
      iterations = data.frame(),
      weights = data.frame(),
      converged = FALSE,
      effective_weight = NA_real_
    ))
  }
  
  # Initial estimates: median and scaled MAD
  x_star <- stats::median(values, na.rm = TRUE)
  s_star <- 1.483 * stats::median(abs(values - x_star), na.rm = TRUE)
  
  # Handle zero or near-zero dispersion
  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    s_star <- stats::sd(values, na.rm = TRUE)
  }
  
  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    return(list(
      error = "Data dispersion is insufficient for Algorithm A.",
      assigned_value = x_star,
      robust_sd = 0,
      iterations = data.frame(),
      weights = data.frame(),
      converged = TRUE,
      effective_weight = n
    ))
  }
  
  # Iteration records
  iteration_records <- list()
  converged <- FALSE
  
  for (iter in seq_len(max_iter)) {
    # Standardized residuals
    u_values <- (values - x_star) / (1.5 * s_star)
    
    # Huber-type weights: 1 if |u| <= 1, else 1/u^2
    weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))
    
    weight_sum <- sum(weights)
    if (!is.finite(weight_sum) || weight_sum <= 0) {
      return(list(
        error = "Computed weights are invalid for Algorithm A.",
        assigned_value = x_star,
        robust_sd = s_star,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        weights = data.frame(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }
    
    # Updated estimates
    x_new <- sum(weights * values) / weight_sum
    s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)
    
    if (!is.finite(s_new) || s_new < .Machine$double.eps) {
      return(list(
        error = "Algorithm A collapsed due to zero standard deviation.",
        assigned_value = x_new,
        robust_sd = 0,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        weights = data.frame(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }
    
    # Convergence check
    delta_x <- abs(x_new - x_star)
    delta_s <- abs(s_new - s_star)
    delta <- max(delta_x, delta_s)
    
    iteration_records[[iter]] <- data.frame(
      iteration = iter,
      x_star = x_new,
      s_star = s_new,
      delta = delta,
      stringsAsFactors = FALSE
    )
    
    x_star <- x_new
    s_star <- s_new
    
    if (delta_x < tol && delta_s < tol) {
      converged <- TRUE
      break
    }
  }
  
  # Final weights
  u_final <- (values - x_star) / (1.5 * s_star)
  weights_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))
  
  iterations_df <- if (length(iteration_records) > 0) {
    do.call(rbind, iteration_records)
  } else {
    data.frame()
  }
  
  weights_df <- data.frame(
    id = ids,
    value = values,
    weight = weights_final,
    standardized_residual = u_final,
    stringsAsFactors = FALSE
  )
  
  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = iterations_df,
    weights = weights_df,
    converged = converged,
    effective_weight = sum(weights_final),
    error = NULL
  )
}
