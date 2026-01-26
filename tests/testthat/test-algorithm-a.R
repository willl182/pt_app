# ===================================================================
# Tests for ISO 13528:2022 Algorithm A (Winsorization)
#
# Tests verify correct implementation of robust mean/sd estimation
# using Winsorization as specified in ISO 13528:2022 Annex C.3
# ===================================================================

test_that("algorithm a handles normal data", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 10.1, 10.0)
  result <- ptcalc::run_algorithm_a(values)

  expect_true(result$converged)
  expect_null(result$error)
  expect_true(is.finite(result$assigned_value))
  expect_true(is.finite(result$robust_sd))
  expect_true(result$robust_sd > 0)
  expect_equal(nrow(result$winsorized_values), length(values))
  expect_equal(result$n_participants, length(values))
})

test_that("algorithm a handles data with outlier", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 50.0)
  result <- ptcalc::run_algorithm_a(values)

  expect_true(result$converged)
  expect_null(result$error)
  expect_true(is.finite(result$assigned_value))

  assigned <- result$assigned_value
  robust_sd <- result$robust_sd

  expect_true(assigned > 9.5 && assigned < 11.0)
  expect_true(robust_sd > 0 && robust_sd < 1.0)

  expect_equal(nrow(result$winsorized_values), length(values))
})

test_that("algorithm a handles identical values (s* = 0 case)", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.0, 10.0, 10.0, 10.0, 10.0)
  result <- ptcalc::run_algorithm_a(values)

  expect_true(result$converged)
  expect_null(result$error)
  expect_equal(result$assigned_value, 10.0)
  expect_equal(result$robust_sd, 0)
})

test_that("algorithm a requires minimum 3 values", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  result <- ptcalc::run_algorithm_a(c(1.0, 2.0))

  expect_false(result$converged)
  expect_true(!is.null(result$error))
  expect_true(grepl("at least 3", result$error, ignore.case = TRUE))
})

test_that("algorithm a with exactly 3 values", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.0, 10.2, 9.8)
  result <- ptcalc::run_algorithm_a(values)

  expect_true(result$converged)
  expect_null(result$error)
  expect_true(is.finite(result$assigned_value))
})

test_that("algorithm a handles NA values", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.1, 10.2, NA, 10.0, 10.3, 50.0)
  result <- ptcalc::run_algorithm_a(values)

  expect_true(result$converged)
  expect_null(result$error)
  expect_equal(nrow(result$winsorized_values), 5)
})

test_that("algorithm a winsorizes outliers correctly", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.0, 10.1, 10.2, 100.0, 0.0)
  result <- ptcalc::run_algorithm_a(values)

  expect_true(result$converged)
  expect_null(result$error)

  winsorized <- result$winsorized_values$winsorized
  original <- result$winsorized_values$original

  # The high outlier (100.0) should be reduced
  expect_true(winsorized[original == 100.0] < 100.0)

  # The low outlier (0.0) should be increased or stay the same
  expect_true(winsorized[original == 0.0] >= 0.0)

  # Central values should remain close to original
  expect_true(abs(winsorized[original == 10.0] - 10.0) < 1.0)
})

test_that("algorithm a tracks iterations", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 10.1)
  result <- ptcalc::run_algorithm_a(values)

  expect_true(result$converged)
  expect_null(result$error)
  expect_true(nrow(result$iterations) >= 1)
  expect_true("x_star" %in% names(result$iterations))
  expect_true("s_star" %in% names(result$iterations))
})

test_that("algorithm a returns correct structure", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.1, 10.2, 9.9, 10.0, 10.3)
  result <- ptcalc::run_algorithm_a(values)

  expected_names <- c("assigned_value", "robust_sd", "iterations", "winsorized_values", "converged", "n_participants", "error")
  expect_true(all(expected_names %in% names(result)))

  expect_true("id" %in% names(result$winsorized_values))
  expect_true("original" %in% names(result$winsorized_values))
  expect_true("winsorized" %in% names(result$winsorized_values))
})

test_that("algorithm a with custom ids", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.1, 10.2, 9.9, 10.0, 10.3)
  ids <- c("LAB01", "LAB02", "LAB03", "LAB04", "LAB05")
  result <- ptcalc::run_algorithm_a(values, ids = ids)

  expect_true(result$converged)
  expect_equal(result$winsorized_values$id, ids)
})

test_that("algorithm a converges within max_iter", {
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))

  devtools::load_all("ptcalc")

  values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 10.1, 9.8, 10.2)
  result <- ptcalc::run_algorithm_a(values, max_iter = 100)

  expect_true(result$converged)
  expect_null(result$error)
  expect_true(nrow(result$iterations) < 100)
})
