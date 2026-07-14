# ===================================================================
# Focused reproducibility tests for deliverable E09
# ===================================================================

find_project_root <- function(path = getwd()) {
  path <- normalizePath(path)
  repeat {
    if (file.exists(file.path(path, "app.R")) &&
        file.exists(file.path(path, "ptcalc", "DESCRIPTION"))) {
      return(path)
    }
    parent <- dirname(path)
    if (identical(parent, path)) {
      stop("Project root not found.")
    }
    path <- parent
  }
}

root_dir <- find_project_root()
devtools::load_all(file.path(root_dir, "ptcalc"), quiet = TRUE)

hom <- matrix(c(
  9.98, 10.02, 10.01, 10.03, 9.99, 10.00, 10.04, 10.02,
  9.97, 10.01, 10.00, 10.02, 10.03, 10.01, 9.98, 9.99,
  10.02, 10.00, 10.01, 10.04
), ncol = 2, byrow = TRUE)
participants <- c(9.91, 9.96, 9.99, 10.00, 10.02, 10.04, 10.08, 10.60)

testthat::test_that("homogeneity components match frozen expectations", {
  result <- calculate_homogeneity_stats(hom)
  testthat::expect_equal(result$general_mean_homog, 10.0085, tolerance = 1e-12)
  testthat::expect_equal(result$sw, 0.01774823935, tolerance = 1e-10)
  testthat::expect_equal(result$ss, 0.00903696114, tolerance = 1e-10)
  testthat::expect_equal(result$MADe, 0.022245, tolerance = 1e-12)
  testthat::expect_equal(
    calculate_homogeneity_criterion(result$MADe), 0.0066735,
    tolerance = 1e-12
  )
})

testthat::test_that("stability matches frozen expectations", {
  h <- calculate_homogeneity_stats(hom)
  stab <- matrix(c(
    10.00, 10.01, 10.02, 10.00,
    9.99, 10.01, 10.03, 10.02
  ), ncol = 2, byrow = TRUE)
  result <- calculate_stability_stats(
    stab, h$general_mean_homog, h$x_pt, h$MADe
  )
  testthat::expect_equal(result$general_mean, 10.01, tolerance = 1e-12)
  testthat::expect_equal(result$diff_hom_stab, 0.0015, tolerance = 1e-12)
})

testthat::test_that("robust estimators and Algorithm A are reproducible", {
  testthat::expect_equal(
    unname(calculate_niqr(participants)), 0.05003775, tolerance = 1e-12
  )
  testthat::expect_equal(calculate_mad_e(participants), 0.05932, tolerance = 1e-12)
  result <- run_algorithm_a(participants)
  testthat::expect_true(result$converged)
  testthat::expect_equal(result$n_winsorized, 1L)
  testthat::expect_equal(result$assigned_value, 10.01702296, tolerance = 1e-8)
  testthat::expect_equal(result$robust_sd, 0.07952769, tolerance = 1e-8)
})

testthat::test_that("score values and classification boundaries are explicit", {
  testthat::expect_equal(calculate_z_score(10.08, 10, 0.05), 1.6)
  testthat::expect_equal(
    calculate_z_prime_score(10.08, 10, 0.05, 0.01),
    1.56892908110547, tolerance = 1e-12
  )
  testthat::expect_equal(
    calculate_zeta_score(10.08, 10, 0.03, 0.01),
    2.52982212813471, tolerance = 1e-12
  )
  testthat::expect_equal(
    calculate_en_score(10.08, 10, 0.06, 0.02),
    1.26491106406735, tolerance = 1e-12
  )
  testthat::expect_equal(evaluate_z_score(2), "Satisfactorio")
  testthat::expect_equal(evaluate_z_score(3), "No satisfactorio")
  testthat::expect_equal(evaluate_en_score(1), "Satisfactorio")
  testthat::expect_equal(evaluate_en_score(1.01), "No satisfactorio")
})

testthat::test_that("expanded criterion positional integration defect reproduces", {
  h <- calculate_homogeneity_stats(hom)
  testthat::expect_error(
    calculate_homogeneity_criterion_expanded(h$MADe, h$sw, h$g),
    "Invalid arguments", fixed = TRUE
  )
  named_result <- calculate_homogeneity_criterion_expanded(
    sigma_pt = h$MADe, sw = h$sw, g = h$g
  )
  testthat::expect_equal(named_result, 0.00040187693223, tolerance = 1e-12)
})

testthat::test_that("invalid denominators return typed missing values", {
  testthat::expect_identical(calculate_z_score(1, 1, 0), NA_real_)
  testthat::expect_identical(calculate_en_score(1, 1, 0, 0), NA_real_)
})

testthat::test_that("generated validation evidence is internally coherent", {
  annex_dir <- file.path(
    root_dir, "Entregables_pt_app", "09_informe_final", "anexos"
  )
  matrix <- utils::read.csv(
    file.path(annex_dir, "matriz_validacion.csv"), stringsAsFactors = FALSE
  )
  testthat::expect_equal(nrow(matrix), 12L)
  testthat::expect_equal(sum(matrix$status == "PASS"), 11L)
  testthat::expect_equal(sum(matrix$status == "OPEN_RISK"), 1L)
  testthat::expect_true(all(c(
    "calculos_reproducibles.csv", "algoritmo_a_iteraciones.csv",
    "entorno_ejecucion.txt", "generacion_log.txt", "ptcalc_worktree.patch",
    "ptcalc_fuentes_sha256.csv"
  ) %in% list.files(annex_dir)))
})
