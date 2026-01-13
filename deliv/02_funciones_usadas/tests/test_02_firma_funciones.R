# ===================================================================
# Titulo: test_02_firma_funciones.R
# Entregable: 02
# Descripcion: Test testthat que verifica la existencia y ejecucion
#              basica de las funciones definidas en pt_app/R/.
# Entrada: Archivos fuente en pt_app/R/
# Salida: Resultados de test (PASS/FAIL) en formato testthat
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022
# ===================================================================

library(testthat)

# Directorio base del proyecto
base_dir <- normalizePath(file.path(dirname(dirname(dirname(getwd())))))
source_dir <- file.path(base_dir, "R")

source_files <- c(
  file.path(source_dir, "pt_homogeneity.R"),
  file.path(source_dir, "pt_robust_stats.R"),
  file.path(source_dir, "pt_scores.R"),
  file.path(source_dir, "utils.R")
)

funciones_esperadas <- c(
  "calculate_homogeneity_stats",
  "calculate_homogeneity_criterion",
  "calculate_homogeneity_criterion_expanded",
  "evaluate_homogeneity",
  "calculate_stability_stats",
  "calculate_stability_criterion",
  "calculate_stability_criterion_expanded",
  "evaluate_stability",
  "calculate_u_hom",
  "calculate_u_stab",
  "calculate_niqr",
  "calculate_mad_e",
  "run_algorithm_a",
  "calculate_z_score",
  "calculate_z_prime_score",
  "calculate_zeta_score",
  "calculate_en_score",
  "evaluate_z_score",
  "evaluate_z_score_vec",
  "evaluate_en_score",
  "evaluate_en_score_vec",
  "classify_with_en",
  "algorithm_A",
  "mad_e_manual",
  "nIQR_manual"
)

test_that("Los archivos fuente existen", {
  for (archivo in source_files) {
    expect_true(
      file.exists(archivo),
      info = sprintf("Archivo fuente no encontrado: %s", basename(archivo))
    )
  }
})

test_that("Las funciones existen en los archivos fuente", {
  entorno_funciones <- new.env()
  for (archivo in source_files) {
    source(archivo, local = entorno_funciones)
  }

  for (nombre in funciones_esperadas) {
    expect_true(
      exists(nombre, envir = entorno_funciones),
      info = sprintf("Funcion no encontrada: %s", nombre)
    )
    expect_true(
      is.function(get(nombre, envir = entorno_funciones)),
      info = sprintf("Objeto no es funcion: %s", nombre)
    )
  }
})

test_that("Las funciones se pueden ejecutar con ejemplos minimos", {
  entorno_funciones <- new.env()
  for (archivo in source_files) {
    source(archivo, local = entorno_funciones)
  }

  calcular <- function(nombre, ...) {
    funcion <- get(nombre, envir = entorno_funciones)
    salida <- NULL
    expect_silent({
      salida <- funcion(...)
    })
    expect_true(!is.null(salida))
  }

  sample_matrix <- matrix(c(1, 1.1, 0.9, 1.05), nrow = 2, ncol = 2)
  calcular("calculate_homogeneity_stats", sample_data = sample_matrix)
  calcular("calculate_homogeneity_criterion", sigma_pt = 0.5)
  calcular("calculate_homogeneity_criterion_expanded", sigma_pt = 0.5, sw_sq = 0.01)
  calcular("evaluate_homogeneity", ss = 0.05, c_criterion = 0.15, c_expanded = 0.2)
  calcular("calculate_stability_stats", stab_sample_data = sample_matrix, hom_grand_mean = 1.0)
  calcular("calculate_stability_criterion", sigma_pt = 0.5)
  calcular("calculate_stability_criterion_expanded", c_criterion = 0.15, u_hom_mean = 0.02, u_stab_mean = 0.03)
  calcular("evaluate_stability", diff_hom_stab = 0.05, c_criterion = 0.15, c_expanded = 0.2)
  calcular("calculate_u_hom", ss = 0.04)
  calcular("calculate_u_stab", diff_hom_stab = 0.2, c_criterion = 0.15)

  calcular("calculate_niqr", x = c(1, 2, 3, 4))
  calcular("calculate_mad_e", x = c(1, 2, 3, 4, 5))
  calcular("run_algorithm_a", values = c(1, 2, 3, 4, 5))

  calcular("calculate_z_score", x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
  calcular("calculate_z_prime_score", x = 10.5, x_pt = 10.0, sigma_pt = 0.5, u_xpt = 0.1)
  calcular("calculate_zeta_score", x = 10.5, x_pt = 10.0, u_x = 0.2, u_xpt = 0.1)
  calcular("calculate_en_score", x = 10.5, x_pt = 10.0, U_x = 0.4, U_xpt = 0.2)
  calcular("evaluate_z_score", z = 1.2)

  if (requireNamespace("dplyr", quietly = TRUE)) {
    calcular("evaluate_z_score_vec", z = c(0, 2.2, 3.1))
    calcular("evaluate_en_score_vec", en = c(0.5, 1.2))
  } else {
    skip("Paquete dplyr no disponible para pruebas vectorizadas")
  }

  calcular("evaluate_en_score", en = 0.8)
  calcular(
    "classify_with_en",
    score_val = 1.5,
    en_val = 0.8,
    U_xi = 0.4,
    sigma_pt = 0.2,
    mu_missing = FALSE,
    score_label = "z"
  )

  calcular("algorithm_A", x = c(1, 2, 3, 4), max_iter = 20)
  calcular("mad_e_manual", x = c(1, 2, 3, 4, 5))
  calcular("nIQR_manual", x = c(1, 2, 3, 4, 5))
})

# Ejecutar si se llama directamente
if (!interactive()) {
  cat("=== Ejecutando tests de Entregable 02 ===\n")
  test_dir(dirname(sys.frame(1)$ofile))
}
