# ===================================================================
# Titulo: test_08_end_to_end.R
# Entregable: 08
# Descripcion: Test end-to-end de la aplicación final
# Entrada: app_final.R, funciones_finales.R, datos en data/
# Salida: Validación de flujo completo
# Autor: UNAL/INM
# Fecha: 2026-01-24
# ===================================================================

library(testthat)
library(tidyverse)

# Función auxiliar para obtener rutas
get_project_root <- function() {
  current_wd <- getwd()
  
  # Si estamos en tests/, subir 2 niveles para llegar a raíz del proyecto
  if (basename(current_wd) == "tests") {
    # tests/ -> 08_beta/ -> deliv/ -> raíz/
    return(dirname(dirname(dirname(current_wd))))
  }
  
  # Si estamos en 08_beta/, subir 2 niveles para llegar a raíz del proyecto
  if (basename(current_wd) == "08_beta") {
    return(dirname(dirname(current_wd)))
  }
  
  # Si estamos en deliv/, subir 1 nivel para llegar a raíz del proyecto
  if (basename(current_wd) == "deliv") {
    return(dirname(current_wd))
  }
  
  # Asumir que estamos en el directorio raíz del proyecto
  return(current_wd)
}

# Obtener rutas base
base_dir <- get_project_root()
funciones_path <- file.path(base_dir, "deliv/08_beta/R/funciones_finales.R")
data_dir <- file.path(base_dir, "data")

test_that("Funciones finales se cargan correctamente", {
  expect_true(file.exists(funciones_path))
  expect_silent(source(funciones_path))
  
  expect_true(exists("calculate_z_score"))
  expect_true(exists("calculate_z_prime_score"))
  expect_true(exists("calculate_zeta_score"))
  expect_true(exists("calculate_en_score"))
  expect_true(exists("evaluate_z_score"))
  expect_true(exists("evaluate_en_score"))
  expect_true(exists("calculate_niqr"))
  expect_true(exists("calculate_mad_e"))
  expect_true(exists("run_algorithm_a"))
  expect_true(exists("calculate_homogeneity_stats"))
})

test_that("Cálculo de puntajes z funciona correctamente", {
  expect_silent(source(funciones_path))
  
  z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25)
  expect_equal(z, 2.0)
  
  z_neg <- calculate_z_score(x = 9.5, x_pt = 10.0, sigma_pt = 0.25)
  expect_equal(z_neg, -2.0)
  
  z_invalid <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0)
  expect_true(is.na(z_invalid))
  
  z_na <- calculate_z_score(x = NA_real_, x_pt = 10.0, sigma_pt = 0.25)
  expect_true(is.na(z_na))
})

test_that("Evaluación de puntajes z funciona correctamente", {
  expect_silent(source(funciones_path))
  
  eval_sat <- evaluate_z_score(z = 1.5)
  expect_equal(eval_sat, "Satisfactorio")
  
  eval_cues <- evaluate_z_score(z = 2.5)
  expect_equal(eval_cues, "Cuestionable")
  
  eval_no_sat <- evaluate_z_score(z = 3.5)
  expect_equal(eval_no_sat, "No satisfactorio")
  
  eval_na <- evaluate_z_score(z = NA_real_)
  expect_equal(eval_na, "N/A")
})

test_that("Cálculo de nIQR funciona correctamente", {
  expect_silent(source(funciones_path))
  
  datos <- c(10.2, 10.5, 10.3, 10.6, 10.4)
  niqr <- calculate_niqr(datos)
  expect_true(is.finite(niqr))
  expect_true(niqr > 0)
  
  niqr_na <- calculate_niqr(c(10.2))
  expect_true(is.na(niqr_na))
})

test_that("Cálculo de MADe funciona correctamente", {
  expect_silent(source(funciones_path))
  
  datos <- c(10.2, 10.5, 10.3, 10.6, 10.4)
  made <- calculate_mad_e(datos)
  expect_true(is.finite(made))
  expect_true(made >= 0)
  
  made_na <- calculate_mad_e(numeric(0))
  expect_true(is.na(made_na))
})

test_that("Algoritmo A funciona correctamente", {
  expect_silent(source(funciones_path))
  
  valores <- c(10.2, 10.5, 10.3, 10.6, 10.4, 10.1, 10.8)
  resultado <- run_algorithm_a(valores)
  
  expect_true(!is.null(resultado))
  expect_true(is.finite(resultado$assigned_value))
  expect_true(is.finite(resultado$robust_sd))
  expect_true(resultado$robust_sd > 0)
  expect_true(is.data.frame(resultado$weights))
  expect_true(nrow(resultado$weights) == length(valores))
  
  resultado_error <- run_algorithm_a(c(10.2, 10.5))
  expect_true(!is.null(resultado_error$error))
})

test_that("Cálculo de puntajes z' funciona correctamente", {
  expect_silent(source(funciones_path))
  
  z_prime <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25, u_xpt = 0.01)
  expect_true(is.finite(z_prime))
  
  z_prime_invalid <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0, u_xpt = 0)
  expect_true(is.na(z_prime_invalid))
})

test_that("Cálculo de puntajes zeta funciona correctamente", {
  expect_silent(source(funciones_path))
  
  zeta <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.05, u_xpt = 0.01)
  expect_true(is.finite(zeta))
  
  zeta_invalid <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0, u_xpt = 0)
  expect_true(is.na(zeta_invalid))
})

test_that("Cálculo de puntajes En funciona correctamente", {
  expect_silent(source(funciones_path))
  
  en <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.10, U_xpt = 0.02)
  expect_true(is.finite(en))
  
  en_invalid <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0, U_xpt = 0)
  expect_true(is.na(en_invalid))
})

test_that("Evaluación de puntajes En funciona correctamente", {
  expect_silent(source(funciones_path))
  
  eval_sat <- evaluate_en_score(en = 0.8)
  expect_equal(eval_sat, "Satisfactorio")
  
  eval_no_sat <- evaluate_en_score(en = 1.5)
  expect_equal(eval_no_sat, "No satisfactorio")
  
  eval_na <- evaluate_en_score(en = NA_real_)
  expect_equal(eval_na, "N/A")
})

test_that("Cálculo de estadísticos de homogeneidad funciona correctamente", {
  expect_silent(source(funciones_path))
  
  set.seed(123)
  datos_matriz <- matrix(rnorm(30, mean = 10, sd = 0.5), nrow = 10, ncol = 3)
  
  resultado <- calculate_homogeneity_stats(datos_matriz)
  
  expect_true(!is.null(resultado))
  expect_null(resultado$error)
  expect_equal(resultado$g, 10)
  expect_equal(resultado$m, 3)
  expect_true(is.finite(resultado$grand_mean))
  expect_true(is.finite(resultado$s_xt))
  expect_true(is.finite(resultado$sw))
  expect_true(is.finite(resultado$ss))
  expect_true(resultado$sw >= 0)
  expect_true(resultado$ss >= 0)
})

test_that("Cálculo de criterio de homogeneidad funciona correctamente", {
  expect_silent(source(funciones_path))
  
  sigma_pt <- 0.5
  c_criterion <- calculate_homogeneity_criterion(sigma_pt)
  expect_equal(c_criterion, 0.15)
})

test_that("Cálculo de criterio expandido de homogeneidad funciona correctamente", {
  expect_silent(source(funciones_path))
  
  c_expanded <- calculate_homogeneity_criterion_expanded(sigma_pt = 0.5, sw_sq = 0.01)
  expect_true(is.finite(c_expanded))
  expect_true(c_expanded > 0)
})

test_that("Evaluación de homogeneidad funciona correctamente", {
  expect_silent(source(funciones_path))
  
  eval_sat <- evaluate_homogeneity(ss = 0.1, c_criterion = 0.15)
  expect_equal(eval_sat, "Aceptable")
  
  eval_no_sat <- evaluate_homogeneity(ss = 0.2, c_criterion = 0.15)
  expect_equal(eval_no_sat, "No aceptable")
  
  eval_na <- evaluate_homogeneity(ss = NA_real_, c_criterion = 0.15)
  expect_equal(eval_na, "N/A")
})

test_that("Cálculo de estadísticos de estabilidad funciona correctamente", {
  expect_silent(source(funciones_path))

  hom_mean <- 10.0
  hom_stab_x_pt <- 10.0
  hom_stab_sigma_pt <- 0.5
  stab_values <- c(9.98, 10.02, 10.01, 9.99)

  resultado <- calculate_stability_stats(stab_values, hom_mean, hom_stab_x_pt, hom_stab_sigma_pt)
  
  expect_true(!is.null(resultado))
  expect_true(is.finite(resultado$stab_mean))
  expect_true(is.finite(resultado$difference))
  expect_equal(resultado$hom_mean, hom_mean)
})

test_that("Evaluación de estabilidad funciona correctamente", {
  expect_silent(source(funciones_path))
  
  eval_sat <- evaluate_stability(difference = 0.01, criterion = 0.02)
  expect_equal(eval_sat, "Estable")
  
  eval_no_sat <- evaluate_stability(difference = 0.03, criterion = 0.02)
  expect_equal(eval_no_sat, "No estable")
  
  eval_na <- evaluate_stability(difference = NA_real_, criterion = 0.02)
  expect_equal(eval_na, "N/A")
})

test_that("Cálculo de puntajes para múltiples participantes funciona correctamente", {
  expect_silent(source(funciones_path))
  
  df <- data.frame(
    participant_id = c("P01", "P02", "P03"),
    mean_value = c(10.2, 9.8, 10.1),
    sd_value = c(0.05, 0.06, 0.04)
  )
  
  x_pt <- 10.0
  sigma_pt <- 0.25
  u_xpt <- 0.01
  k <- 2
  
  resultado <- calculate_scores_participants(df, x_pt, sigma_pt, u_xpt, k)
  
  expect_true(is.data.frame(resultado))
  expect_equal(nrow(resultado), 3)
  expect_true("z_score" %in% names(resultado))
  expect_true("z_prime_score" %in% names(resultado))
  expect_true("zeta_score" %in% names(resultado))
  expect_true("En_score" %in% names(resultado))
  expect_true("z_score_eval" %in% names(resultado))
  expect_true("En_score_eval" %in% names(resultado))
})

test_that("Resumen de puntajes de participante funciona correctamente", {
  expect_silent(source(funciones_path))
  
  scores_df <- data.frame(
    z_score = c(1.5, 2.5, -0.5),
    En_score = c(0.8, 1.2, 0.5),
    z_score_eval = c("Satisfactorio", "Cuestionable", "Satisfactorio"),
    En_score_eval = c("Satisfactorio", "No satisfactorio", "Satisfactorio")
  )
  
  resumen <- summarize_scores_participant(scores_df)
  
  expect_true(is.list(resumen))
  expect_true("z_mean" %in% names(resumen))
  expect_true("z_max" %in% names(resumen))
  expect_true("satisfactorio_z" %in% names(resumen))
  expect_true("cuestionable_z" %in% names(resumen))
  expect_true("no_satisfactorio_z" %in% names(resumen))
  expect_true("satisfactorio_en" %in% names(resumen))
  expect_true("no_satisfactorio_en" %in% names(resumen))
  
  expect_equal(resumen$satisfactorio_z, 2)
  expect_equal(resumen$cuestionable_z, 1)
  expect_equal(resumen$no_satisfactorio_z, 0)
  expect_equal(resumen$satisfactorio_en, 2)
  expect_equal(resumen$no_satisfactorio_en, 1)
})

test_that("Archivos de datos existen y tienen formato correcto", {
  expect_true(file.exists(file.path(data_dir, "homogeneity.csv")))
  expect_true(file.exists(file.path(data_dir, "stability.csv")))
  expect_true(file.exists(file.path(data_dir, "summary_n4.csv")))
  expect_true(file.exists(file.path(data_dir, "participants_data4.csv")))
  
  hom_data <- read.csv(file.path(data_dir, "homogeneity.csv"))
  stab_data <- read.csv(file.path(data_dir, "stability.csv"))
  summary_data <- read.csv(file.path(data_dir, "summary_n4.csv"))
  participants_data <- read.csv(file.path(data_dir, "participants_data4.csv"))
  
  expect_true("pollutant" %in% names(hom_data))
  expect_true("pollutant" %in% names(stab_data))
  expect_true("pollutant" %in% names(summary_data))
  expect_true("participant_id" %in% names(summary_data))
  expect_true("mean_value" %in% names(summary_data))
  expect_true("sd_value" %in% names(summary_data))
})

cat("\n=== Test 08 completado ===\n")
