# ===================================================================
# Titulo: test_06_logica.R
# Entregable: 06
# Descripcion: Tests para verificar la lógica de negocio de app_v06.R
# Entrada: Archivos CSV en data/
# Salida: Resultados de verificación (consola)
# Autor: UNAL/INM
# Fecha: 2026-01-24
# ===================================================================

library(testthat)
library(tidyverse)

# Cambiar directorio para acceder a archivos de datos
old_wd <- setwd("..")
on.exit(setwd(old_wd))

# Cargar funciones de app_v06.R
source("deliv/06_app_logica/app_v06.R")

# ===================================================================
# Test: Funciones de Cálculo
# ===================================================================

test_that("calculate_z_score calcula correctamente", {
  z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
  expect_equal(z, 1.0, tolerance = 1e-6)
})

test_that("calculate_z_score devuelve NA para sigma_pt invalido", {
  z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0)
  expect_true(is.na(z))
})

test_that("calculate_z_prime_score calcula correctamente", {
  zprime <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5, u_xpt = 0.1)
  expected <- (10.5 - 10.0) / sqrt(0.5^2 + 0.1^2)
  expect_equal(zprime, expected, tolerance = 1e-6)
})

test_that("calculate_zeta_score calcula correctamente", {
  zeta <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.2, u_xpt = 0.1)
  expected <- (10.5 - 10.0) / sqrt(0.2^2 + 0.1^2)
  expect_equal(zeta, expected, tolerance = 1e-6)
})

test_that("calculate_en_score calcula correctamente", {
  en <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.4, U_xpt = 0.2)
  expected <- (10.5 - 10.0) / sqrt(0.4^2 + 0.2^2)
  expect_equal(en, expected, tolerance = 1e-6)
})

# ===================================================================
# Test: Evaluación de Puntajes
# ===================================================================

test_that("evaluate_z_score clasifica satisfactorio correctamente", {
  eval <- evaluate_z_score(z = 1.5)
  expect_equal(eval, "Satisfactorio")
})

test_that("evaluate_z_score clasifica cuestionable correctamente", {
  eval <- evaluate_z_score(z = 2.5)
  expect_equal(eval, "Cuestionable")
})

test_that("evaluate_z_score clasifica no satisfactorio correctamente", {
  eval <- evaluate_z_score(z = 3.5)
  expect_equal(eval, "No satisfactorio")
})

test_that("evaluate_z_score devuelve N/A para valor invalido", {
  eval <- evaluate_z_score(z = NA)
  expect_equal(eval, "N/A")
})

test_that("evaluate_en_score clasifica satisfactorio correctamente", {
  eval <- evaluate_en_score(en = 0.8)
  expect_equal(eval, "Satisfactorio")
})

test_that("evaluate_en_score clasifica no satisfactorio correctamente", {
  eval <- evaluate_en_score(en = 1.5)
  expect_equal(eval, "No satisfactorio")
})

# ===================================================================
# Test: Estadísticos Robustos
# ===================================================================

test_that("calculate_niqr calcula correctamente", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
  niqr <- calculate_niqr(x)
  expect_true(is.numeric(niqr))
  expect_true(is.finite(niqr))
  expect_gt(niqr, 0)
})

test_that("calculate_mad_e calcula correctamente", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
  made <- calculate_mad_e(x)
  expect_true(is.numeric(made))
  expect_true(is.finite(made))
  expect_gt(made, 0)
})

test_that("calculate_mad_e es robusto a outliers", {
  sin_outlier <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
  con_outlier <- c(10.1, 10.2, 9.9, 10.0, 50.0, 9.8, 10.1)
  made1 <- calculate_mad_e(sin_outlier)
  made2 <- calculate_mad_e(con_outlier)
  expect_lt(abs(made2 - made1), 0.5)
})

# ===================================================================
# Test: Algoritmo A
# ===================================================================

test_that("run_algorithm_a ejecuta correctamente", {
  values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
  ids <- c("Lab1", "Lab2", "Lab3", "Lab4", "Lab5", "Lab6", "Lab7")
  result <- run_algorithm_a(values, ids)
  
  expect_null(result$error)
  expect_true(is.numeric(result$assigned_value))
  expect_true(is.numeric(result$robust_sd))
  expect_true(result$converged)
})

test_that("run_algorithm_a devuelve error con menos de 3 observaciones", {
  values <- c(10.1, 10.2)
  result <- run_algorithm_a(values)
  expect_true(!is.null(result$error))
})

# ===================================================================
# Test: Homogeneidad
# ===================================================================

test_that("calculate_homogeneity_stats ejecuta correctamente", {
  sample_data <- matrix(rnorm(20, mean = 10, sd = 0.5), nrow = 10, ncol = 2)
  stats <- calculate_homogeneity_stats(sample_data)
  
  expect_null(stats$error)
  expect_equal(stats$g, 10)
  expect_equal(stats$m, 2)
  expect_true(is.numeric(stats$grand_mean))
  expect_true(is.numeric(stats$ss))
  expect_true(is.numeric(stats$sw))
})

test_that("calculate_homogeneity_criterion calcula correctamente", {
  c_criterion <- calculate_homogeneity_criterion(sigma_pt = 0.5)
  expect_equal(c_criterion, 0.15)
})

test_that("calculate_homogeneity_criterion_expanded calcula correctamente", {
  c_expanded <- calculate_homogeneity_criterion_expanded(sigma_pt = 0.5, sw = 0.316, g = 10)
  expect_true(is.numeric(c_expanded))
  expect_gt(c_expanded, 0)
})

# ===================================================================
# Test: Carga de Datos
# ===================================================================

test_that("hom_data tiene columnas esperadas", {
  expect_true("value" %in% names(hom_data))
  expect_true("pollutant" %in% names(hom_data))
  expect_true("level" %in% names(hom_data))
})

test_that("stab_data tiene columnas esperadas", {
  expect_true("value" %in% names(stab_data))
  expect_true("pollutant" %in% names(stab_data))
  expect_true("level" %in% names(stab_data))
})

test_that("summary_data tiene columnas esperadas", {
  expect_true("participant_id" %in% names(summary_data))
  expect_true("pollutant" %in% names(summary_data))
  expect_true("level" %in% names(summary_data))
  expect_true("mean_value" %in% names(summary_data))
  expect_true("sd_value" %in% names(summary_data))
})

test_that("participants_data tiene columnas esperadas", {
  expect_true("Codigo_Lab" %in% names(participants_data))
})

# ===================================================================
# Test: Verificación de Datos de Ejemplo
# ===================================================================

test_that("summary_data tiene datos para al menos un analito", {
  expect_gt(nrow(summary_data), 0)
  expect_true("pollutant" %in% names(summary_data))
  expect_true(length(unique(summary_data$pollutant)) > 0)
})

test_that("hom_data tiene datos de homogeneidad", {
  expect_gt(nrow(hom_data), 0)
  expect_true("pollutant" %in% names(hom_data))
})

test_that("stab_data tiene datos de estabilidad", {
  expect_gt(nrow(stab_data), 0)
  expect_true("pollutant" %in% names(stab_data))
})

# ===================================================================
# Generar CSV de resultados
# ===================================================================

cat("\n=== Generando CSV de verificación de tests ===\n")

results_df <- data.frame(
  test = character(),
  resultado = character(),
  valor_esperado = character(),
  status = character(),
  stringsAsFactors = FALSE
)

# Test de calculate_z_score
z_result <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
results_df <- rbind(results_df, data.frame(
  test = "calculate_z_score",
  resultado = sprintf("%.6f", z_result),
  valor_esperado = "1.000000",
  status = ifelse(abs(z_result - 1.0) < 1e-6, "PASS", "FAIL"),
  stringsAsFactors = FALSE
))

# Test de calculate_z_prime_score
zprime_result <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5, u_xpt = 0.1)
expected_zprime <- (10.5 - 10.0) / sqrt(0.5^2 + 0.1^2)
results_df <- rbind(results_df, data.frame(
  test = "calculate_z_prime_score",
  resultado = sprintf("%.6f", zprime_result),
  valor_esperado = sprintf("%.6f", expected_zprime),
  status = ifelse(abs(zprime_result - expected_zprime) < 1e-6, "PASS", "FAIL"),
  stringsAsFactors = FALSE
))

# Test de evaluate_z_score
eval_satisfactorio <- evaluate_z_score(z = 1.5)
eval_cuestionable <- evaluate_z_score(z = 2.5)
eval_no_satisfactorio <- evaluate_z_score(z = 3.5)

results_df <- rbind(results_df, data.frame(
  test = c("evaluate_z_score (1.5)", "evaluate_z_score (2.5)", "evaluate_z_score (3.5)"),
  resultado = c(eval_satisfactorio, eval_cuestionable, eval_no_satisfactorio),
  valor_esperado = c("Satisfactorio", "Cuestionable", "No satisfactorio"),
  status = c(
    ifelse(eval_satisfactorio == "Satisfactorio", "PASS", "FAIL"),
    ifelse(eval_cuestionable == "Cuestionable", "PASS", "FAIL"),
    ifelse(eval_no_satisfactorio == "No satisfactorio", "PASS", "FAIL")
  ),
  stringsAsFactors = FALSE
))

# Test de calculate_niqr
x_test <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
niqr_result <- calculate_niqr(x_test)
results_df <- rbind(results_df, data.frame(
  test = "calculate_niqr",
  resultado = sprintf("%.6f", niqr_result),
  valor_esperado = "> 0",
  status = ifelse(niqr_result > 0, "PASS", "FAIL"),
  stringsAsFactors = FALSE
))

# Test de calculate_mad_e
made_result <- calculate_mad_e(x_test)
results_df <- rbind(results_df, data.frame(
  test = "calculate_mad_e",
  resultado = sprintf("%.6f", made_result),
  valor_esperado = "> 0",
  status = ifelse(made_result > 0, "PASS", "FAIL"),
  stringsAsFactors = FALSE
))

# Test de run_algorithm_a
algo_result <- run_algorithm_a(x_test)
results_df <- rbind(results_df, data.frame(
  test = "run_algorithm_a (convergencia)",
  resultado = ifelse(algo_result$converged, "TRUE", "FALSE"),
  valor_esperado = "TRUE",
  status = ifelse(algo_result$converged, "PASS", "FAIL"),
  stringsAsFactors = FALSE
))

# Test de calculate_homogeneity_criterion
c_criterion <- calculate_homogeneity_criterion(sigma_pt = 0.5)
results_df <- rbind(results_df, data.frame(
  test = "calculate_homogeneity_criterion",
  resultado = sprintf("%.6f", c_criterion),
  valor_esperado = "0.150000",
  status = ifelse(abs(c_criterion - 0.15) < 1e-6, "PASS", "FAIL"),
  stringsAsFactors = FALSE
))

# Guardar CSV
setwd("deliv/06_app_logica/tests")
write.csv(results_df, "test_06_logica.csv", row.names = FALSE)
cat("CSV guardado en: deliv/06_app_logica/tests/test_06_logica.csv\n")

# Mostrar resumen
cat("\n=== Resumen de Tests ===\n")
print(results_df)

cat("\n=== Estadísticas ===\n")
cat("Total tests:", nrow(results_df), "\n")
cat("PASS:", sum(results_df$status == "PASS"), "\n")
cat("FAIL:", sum(results_df$status == "FAIL"), "\n")
cat("Tasa de éxito:", sprintf("%.1f%%", sum(results_df$status == "PASS") / nrow(results_df) * 100), "\n")
