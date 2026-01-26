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

# Helper: Check if two values are equal to 3 significant figures
same_3sf <- function(a, b) {
  if (!is.finite(a) || !is.finite(b)) {
    return(FALSE)
  }
  if (a == 0 && b == 0) {
    return(TRUE)
  }
  signif(a, 3) == signif(b, 3)
}

#' ISO 13528 Algorithm A - Robust Mean and Standard Deviation
#'
#' Iterative algorithm for computing robust estimates of location (x*) and
#' scale (s*) from proficiency testing data using Winsorization.
#'
#' @details
#' Algorithm A is an iterative procedure that computes robust estimates:
#' 1. Initialize with median (x*) and scaled MAD (s*)
#' 2. Compute delta: δ = 1.5 × s*
#' 3. Winsorize values: clamp to \code{[x* - δ, x* + δ]}
#' 4. Update x* = mean(winsorized), s* = 1.134 × sqrt(Σ(x* - x)²/(p-1))
#' 5. Repeat until convergence (no change in 3rd significant figure)
#'
#' Reference: ISO 13528:2022, Annex C.3
#'
#' @param values A numeric vector of participant results.
#' @param ids Optional vector of participant identifiers (same length as values).
#' @param max_iter Maximum number of iterations (default: 50).
#' @return A list containing:
#'   - assigned_value: Robust mean (x*)
#'   - robust_sd: Robust standard deviation (s*)
#'   - iterations: Data frame of iteration history
#'   - winsorized_values: Data frame with original and winsorized values
#'   - converged: Logical indicating convergence
#'   - n_participants: Number of participants used
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
run_algorithm_a <- function(values, ids = NULL, max_iter = 50) {
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
      winsorized_values = data.frame(),
      converged = FALSE,
      n_participants = p
    ))
  }

  # Initial estimates: median and scaled MAD (Formula C.6)
  x_star <- stats::median(values, na.rm = TRUE)
  s_star <- 1.483 * stats::median(abs(values - x_star), na.rm = TRUE)

  # Handle s* = 0 case (ISO NOTE 2): use sample standard deviation as fallback
  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    s_star <- stats::sd(values, na.rm = TRUE)
  }

  # If still zero dispersion, return with robust_sd = 0 (no error needed)
  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    return(list(
      assigned_value = x_star,
      robust_sd = 0,
      iterations = data.frame(iteration = 0, x_star = x_star, s_star = 0, stringsAsFactors = FALSE),
      winsorized_values = data.frame(id = ids, original = values, winsorized = values, stringsAsFactors = FALSE),
      converged = TRUE,
      n_participants = p,
      error = NULL
    ))
  }

  # Iteration records
  iteration_records <- list()
  converged <- FALSE

  for (iter in seq_len(max_iter)) {
    delta <- 1.5 * s_star

    # Winsorize: clamp values to [x* - δ, x* + δ] (Formula C.8)
    x_winsorized <- pmax(pmin(values, x_star + delta), x_star - delta)

    # Updated estimates (Formulas C.9, C.10)
    x_new <- mean(x_winsorized)
    s_new <- 1.134 * sqrt(sum((x_winsorized - x_new)^2) / (p - 1))

    if (!is.finite(s_new) || s_new < .Machine$double.eps) {
      return(list(
        error = "Algorithm A collapsed due to zero standard deviation.",
        assigned_value = x_new,
        robust_sd = 0,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        winsorized_values = data.frame(),
        converged = FALSE,
        n_participants = p
      ))
    }

    # Convergence check: 3rd significant figure
    if (same_3sf(x_star, x_new) && same_3sf(s_star, s_new)) {
      converged <- TRUE
      x_star <- x_new
      s_star <- s_new
      iteration_records[[iter]] <- data.frame(
        iteration = iter,
        x_star = x_new,
        s_star = s_new,
        stringsAsFactors = FALSE
      )
      break
    }

    iteration_records[[iter]] <- data.frame(
      iteration = iter,
      x_star = x_new,
      s_star = s_new,
      stringsAsFactors = FALSE
    )

    x_star <- x_new
    s_star <- s_new
  }

  iterations_df <- if (length(iteration_records) > 0) {
    do.call(rbind, iteration_records)
  } else {
    data.frame()
  }

  delta <- 1.5 * s_star
  x_winsorized_final <- pmax(pmin(values, x_star + delta), x_star - delta)

  winsorized_df <- data.frame(
    id = ids,
    original = values,
    winsorized = x_winsorized_final,
    stringsAsFactors = FALSE
  )

  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = iterations_df,
    winsorized_values = winsorized_df,
    converged = converged,
    n_participants = p,
    error = NULL
  )
}
