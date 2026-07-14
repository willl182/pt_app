phase4_root <- normalizePath(file.path(testthat::test_path(), "../.."))

testthat::test_that("E01 distinguishes the historical snapshot", {
  text <- paste(readLines(file.path(
    phase4_root, "Entregables_pt_app/01_repo_inicial/README.md"
  ), warn = FALSE), collapse = "\n")
  testthat::expect_match(text, "no es el código operativo actual", fixed = TRUE)
  testthat::expect_match(text, "inventario_maestro.csv", fixed = TRUE)
})

testthat::test_that("E02 inventory matches current scanned sources", {
  csv <- utils::read.csv(file.path(
    phase4_root, "Entregables_pt_app/02_funciones_usadas/funciones_extraidas.csv"
  ), stringsAsFactors = FALSE)
  testthat::expect_equal(nrow(csv), 78L)
  testthat::expect_true(all(c(
    "calculate_z_score", "run_algorithm_a", "calculate_homogeneity_stats",
    "server"
  ) %in% csv$nombre_funcion))
  testthat::expect_true(all(file.exists(file.path(phase4_root, csv$archivo_ruta))))
})

testthat::test_that("E03 example reproduces current calculations", {
  source(file.path(phase4_root, "ptcalc/R/pt_homogeneity.R"), local = TRUE)
  source(file.path(phase4_root, "ptcalc/R/pt_robust_stats.R"), local = TRUE)
  hom <- matrix(c(
    9.98, 10.02, 10.01, 10.03, 9.99, 10.00, 10.04, 10.02,
    9.97, 10.01, 10.00, 10.02, 10.03, 10.01, 9.98, 9.99,
    10.02, 10.00, 10.01, 10.04
  ), ncol = 2, byrow = TRUE)
  h <- calculate_homogeneity_stats(hom)
  testthat::expect_equal(h$general_mean_homog, 10.0085, tolerance = 1e-10)
  testthat::expect_equal(h$ss, 0.009036961, tolerance = 1e-9)
  testthat::expect_equal(h$MADe, 0.022245, tolerance = 1e-10)
  expanded_sq <- calculate_homogeneity_criterion_expanded(
    sigma_pt = h$MADe, sw = h$sw, g = h$g
  )
  testthat::expect_equal(expanded_sq, 0.0004018769, tolerance = 1e-10)
  testthat::expect_error(
    calculate_homogeneity_criterion_expanded(h$MADe, h$sw, h$g),
    "Invalid arguments"
  )
  testthat::expect_equal(calculate_u_stab(0.03, 0.02), 0.03 / sqrt(3))
  algorithm_a <- run_algorithm_a(c(
    9.91, 9.96, 9.99, 10.00, 10.02, 10.04, 10.08, 10.60
  ))
  testthat::expect_equal(algorithm_a$assigned_value, 10.017017, tolerance = 1e-6)
  testthat::expect_equal(algorithm_a$robust_sd, 0.07952769, tolerance = 1e-7)
  testthat::expect_identical(algorithm_a$convergence_method, "signif3")
})

testthat::test_that("E04 formulas, boundaries and invalid cases match ptcalc", {
  source(file.path(phase4_root, "ptcalc/R/pt_scores.R"), local = TRUE)
  scores <- c(
    z = calculate_z_score(10.18, 10.00, 0.08),
    z_prime = calculate_z_prime_score(10.18, 10.00, 0.08, 0.03),
    zeta = calculate_zeta_score(10.18, 10.00, 0.05, 0.03),
    en = calculate_en_score(10.18, 10.00, 0.10, 0.06)
  )
  testthat::expect_equal(
    unname(scores), c(2.25, 2.106740658, 3.086974532, 1.543487266),
    tolerance = 1e-8
  )
  testthat::expect_identical(evaluate_z_score(2), "Satisfactorio")
  testthat::expect_identical(evaluate_z_score(3), "No satisfactorio")
  testthat::expect_identical(evaluate_en_score(1), "Satisfactorio")
  testthat::expect_true(is.na(calculate_z_score(1, 1, 0)))
  testthat::expect_true(is.na(calculate_z_prime_score(1, 1, 0, 0)))
  testthat::expect_true(is.na(calculate_zeta_score(1, 1, 0, 0)))
  testthat::expect_true(is.na(calculate_en_score(1, 1, 0, 0)))
  testthat::expect_identical(evaluate_z_score(NA_real_), "N/A")
  testthat::expect_identical(evaluate_en_score(NA_real_), "N/A")
})

testthat::test_that("Phase 4 derived documents and manifest are valid", {
  manifest_path <- file.path(
    phase4_root,
    "Entregables_pt_app/00_control_documental/derivados/manifiesto_fase_4.csv"
  )
  testthat::expect_true(file.exists(manifest_path))
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
  testthat::expect_equal(nrow(manifest), 5L)
  testthat::expect_true(all(file.exists(file.path(phase4_root, manifest$archivo))))
  sha256_file <- function(path) {
    output <- system2("sha256sum", path, stdout = TRUE)
    strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
  }
  source_hashes <- vapply(
    file.path(phase4_root, manifest$fuente), sha256_file, character(1)
  )
  output_hashes <- vapply(
    file.path(phase4_root, manifest$archivo), sha256_file, character(1)
  )
  testthat::expect_identical(manifest$sha256_fuente, unname(source_hashes))
  testthat::expect_identical(manifest$sha256_salida, unname(output_hashes))
})
