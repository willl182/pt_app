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
#' scale (s*) from proficiency testing data using winsorization.
#'
#' @details
#' Algorithm A is the iterative winsorization procedure from ISO 13528:2022,
#' Annex C:
#' 1. Initialize: x* = median(xi), s* = 1.483 * MAD(xi)
#' 2. Compute delta = 1.5 * s*
#' 3. Winsorize: x*_i = clamp(xi, x* - delta, x* + delta)
#' 4. Update: x* = mean(x*_i), s* = 1.134 * sd(x*_i)
#' 5. Repeat until no change in 3rd significant figure of x* and s*
#'    (ISO 13528:2022 NOTE 1). A numerical guard (tol = 1e-10) catches
#'    machine-precision stalls.
#'
#' The factor 1.134 corrects the bias introduced by winsorization.
#' The sd() uses (p-1) denominator (sample standard deviation).
#'
#' Reference: ISO 13528:2022, Annex C
#'
#' @param values A numeric vector of participant results.
#' @param ids Optional vector of participant identifiers (same length as values).
#' @param max_iter Maximum number of iterations (default: 50).
#' @param tol Numerical guard tolerance for x* and s* (default: 1e-10). The
#'   primary convergence criterion is 3rd significant figure comparison per
#'   ISO 13528:2022 NOTE 1; tol only catches machine-precision stalls.
#' @return A list containing:
#'   - assigned_value: Robust mean (x*)
#'   - robust_sd: Robust standard deviation (s*)
#'   - iterations: Data frame of iteration history (includes signif3_* columns)
#'   - iteration_detail: Data frame with per-participant detail per iteration
#'   - weights: Data frame with final winsorized values per participant
#'   - converged: Logical indicating convergence
#'   - convergence_method: `"signif3"` (ISO 13528:2022 NOTE 1) or
#'     `"numerical_guard"` (machine-precision stall) or `NA` if not converged
#'   - n_winsorized: Number of winsorized observations in final iteration
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
run_algorithm_a <- function(values, ids = NULL, max_iter = 50, tol = 1e-10) {
  # Remove non-finite values
  mask <- is.finite(values)
  values <- values[mask]

  if (is.null(ids)) {
    ids <- seq_along(values)
  } else {
    ids <- ids[mask]
  }

  p <- length(values)
  if (p < 3) {
    return(list(
      error = "Algorithm A requires at least 3 valid observations.",
      assigned_value = NA_real_,
      robust_sd = NA_real_,
      iterations = data.frame(),
      iteration_detail = data.frame(),
      weights = data.frame(),
      converged = FALSE,
      n_winsorized = NA_integer_
    ))
  }

  # Step 1: Initial estimates (ISO 13528:2022, Annex C, step 1)
  x_star <- stats::median(values, na.rm = TRUE)
  s_star <- 1.483 * stats::median(abs(values - x_star), na.rm = TRUE)

  initial_median <- x_star
  initial_mad_e <- s_star

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
      iteration_detail = data.frame(),
      weights = data.frame(
        id = ids, value = values, winsorized = values,
        is_winsorized = FALSE, stringsAsFactors = FALSE
      ),
      converged = TRUE,
      n_winsorized = 0L,
      n = p,
      initial_median = initial_median,
      initial_mad_e = initial_mad_e,
      tolerance = tol,
      error = NULL
    ))
  }

  # Iteration records
  iteration_records <- list()
  iteration_detail <- list()
  converged <- FALSE
  convergence_method <- NA_character_

  for (iter in seq_len(max_iter)) {
    # Step 2: Compute delta (ISO 13528, Annex C, step 2)
    delta <- 1.5 * s_star

    # Step 3: Winsorize (ISO 13528, Annex C, step 3)
    # x*_i = x* - delta  if xi < x* - delta
    # x*_i = x* + delta  if xi > x* + delta
    # x*_i = xi           otherwise
    lower <- x_star - delta
    upper <- x_star + delta
    winsorized <- pmax(pmin(values, upper), lower)
    is_winsorized <- (values < lower) | (values > upper)

    # Step 4: Update estimates (ISO 13528, Annex C, step 4)
    # x* = (1/p) * sum(x*_i)
    x_new <- mean(winsorized)
    # s* = 1.134 * sqrt( (1/(p-1)) * sum((x*_i - x*)^2) )
    # The 1.134 factor corrects for winsorization bias
    s_new <- 1.134 * sqrt(sum((winsorized - x_new)^2) / (p - 1))

    if (!is.finite(s_new) || s_new < .Machine$double.eps) {
      return(list(
        error = "Algorithm A collapsed: s* converged to zero.",
        assigned_value = x_new,
        robust_sd = 0,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        iteration_detail = if (length(iteration_detail) > 0) do.call(rbind, iteration_detail) else data.frame(),
        weights = data.frame(
          id = ids, value = values, winsorized = winsorized,
          is_winsorized = is_winsorized, stringsAsFactors = FALSE
        ),
        converged = FALSE,
        n_winsorized = sum(is_winsorized),
        n = p,
        initial_median = initial_median,
        initial_mad_e = initial_mad_e,
        tolerance = tol,
        error = NULL
      ))
    }

    # Step 5: Convergence check
    delta_x <- abs(x_new - x_star)
    delta_s <- abs(s_new - s_star)
    delta_max <- max(delta_x, delta_s)

    iteration_records[[iter]] <- data.frame(
      iteration = iter,
      x_star_prev = x_star,
      s_star_prev = s_star,
      delta_winsor = delta,
      lower_bound = lower,
      upper_bound = upper,
      n_winsorized = sum(is_winsorized),
      x_star_new = x_new,
      s_star_new = s_new,
      delta_x = delta_x,
      delta_s = delta_s,
      delta_max = delta_max,
      signif3_x_prev = signif(x_star, 3),
      signif3_s_prev = signif(s_star, 3),
      signif3_x_new = signif(x_new, 3),
      signif3_s_new = signif(s_new, 3),
      signif3_converged = signif(x_new, 3) == signif(x_star, 3) &&
                          signif(s_new, 3) == signif(s_star, 3),
      stringsAsFactors = FALSE
    )

    # Per-participant detail for this iteration
    iteration_detail[[iter]] <- data.frame(
      iteration = iter,
      id = ids,
      value = values,
      winsorized = winsorized,
      is_winsorized = is_winsorized,
      x_star = x_star,
      s_star = s_star,
      delta = delta,
      lower = lower,
      upper = upper,
      stringsAsFactors = FALSE
    )

    # Primary: ISO 13528:2022 NOTE 1 — 3rd significant figure
    # Must compare before updating x_star/s_star
    sig_converged <- signif(x_new, 3) == signif(x_star, 3) &&
                     signif(s_new, 3) == signif(s_star, 3)
    # Secondary: numerical guard against machine-precision stall
    num_converged <- delta_x < tol && delta_s < tol

    x_star <- x_new
    s_star <- s_new

    if (sig_converged || num_converged) {
      converged <- TRUE
      convergence_method <- if (sig_converged) "signif3" else "numerical_guard"
      break
    }
  }

  # Final winsorized values
  delta_final <- 1.5 * s_star
  winsorized_final <- pmax(pmin(values, x_star + delta_final), x_star - delta_final)
  is_winsorized_final <- (values < x_star - delta_final) | (values > x_star + delta_final)

  iterations_df <- if (length(iteration_records) > 0) {
    do.call(rbind, iteration_records)
  } else {
    data.frame()
  }

  iteration_detail_df <- if (length(iteration_detail) > 0) {
    do.call(rbind, iteration_detail)
  } else {
    data.frame()
  }

  weights_df <- data.frame(
    id = ids,
    value = values,
    winsorized = winsorized_final,
    is_winsorized = is_winsorized_final,
    stringsAsFactors = FALSE
  )

  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = iterations_df,
    iteration_detail = iteration_detail_df,
    weights = weights_df,
    converged = converged,
    convergence_method = convergence_method,
    n_winsorized = sum(is_winsorized_final),
    n = p,
    initial_median = initial_median,
    initial_mad_e = initial_mad_e,
    tolerance = tol,
    error = NULL
  )
}
