# ===================================================================
# Titulo: test_09_reproducibilidad.R
# Entregable: 09
# Descripcion: Verifica que resultados sean reproducibles
# Entrada: Funciones en funciones_finales.R, datos en data/
# Salida: Validación de reproducibilidad
# Autor: UNAL/INM
# Fecha: 2026-01-24
# ===================================================================

library(testthat)
library(tidyverse)

# Función auxiliar para obtener rutas
get_project_root <- function() {
  current_wd <- getwd()
  
  if (basename(current_wd) == "tests") {
    return(dirname(dirname(dirname(current_wd))))
  }
  
  if (basename(current_wd) == "09_informe_final") {
    return(dirname(dirname(current_wd)))
  }
  
  return(current_wd)
}

base_dir <- get_project_root()
funciones_path <- file.path(base_dir, "deliv/08_beta/R/funciones_finales.R")
data_dir <- file.path(base_dir, "data")

# Cargar funciones
source(funciones_path)

test_that("Reproducibilidad de nIQR - mismos datos deben dar mismo resultado", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  # Datos de prueba
  datos <- c(10.2, 10.5, 10.3, 10.6, 10.4)
  
  # Ejecutar 3 veces
  niqr1 <- calculate_niqr(datos)
  niqr2 <- calculate_niqr(datos)
  niqr3 <- calculate_niqr(datos)
  
  # Verificar que son idénticos
  expect_equal(niqr1, niqr2)
  expect_equal(niqr2, niqr3)
  expect_equal(niqr1, niqr3)
})

test_that("Reproducibilidad de MADe - mismos datos deben dar mismo resultado", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  datos <- c(10.2, 10.5, 10.3, 10.6, 10.4)
  
  made1 <- calculate_mad_e(datos)
  made2 <- calculate_mad_e(datos)
  made3 <- calculate_mad_e(datos)
  
  expect_equal(made1, made2)
  expect_equal(made2, made3)
  expect_equal(made1, made3)
})

test_that("Reproducibilidad de Algoritmo A - mismos datos deben dar mismo resultado", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  valores <- c(10.2, 10.5, 10.3, 10.6, 10.4, 10.1, 10.8)
  
  result1 <- run_algorithm_a(valores)
  result2 <- run_algorithm_a(valores)
  result3 <- run_algorithm_a(valores)
  
  expect_equal(result1$assigned_value, result2$assigned_value)
  expect_equal(result2$assigned_value, result3$assigned_value)
  expect_equal(result1$robust_sd, result2$robust_sd)
  expect_equal(result2$robust_sd, result3$robust_sd)
})

test_that("Reproducibilidad de puntajes z - mismos inputs deben dar mismo resultado", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  z1 <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25)
  z2 <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25)
  z3 <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25)
  
  expect_equal(z1, z2)
  expect_equal(z2, z3)
})

test_that("Reproducibilidad de puntajes z' - mismos inputs deben dar mismo resultado", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  zp1 <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25, u_xpt = 0.01)
  zp2 <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25, u_xpt = 0.01)
  zp3 <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25, u_xpt = 0.01)
  
  expect_equal(zp1, zp2)
  expect_equal(zp2, zp3)
})

test_that("Reproducibilidad de puntajes zeta - mismos inputs deben dar mismo resultado", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  zeta1 <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.05, u_xpt = 0.01)
  zeta2 <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.05, u_xpt = 0.01)
  zeta3 <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.05, u_xpt = 0.01)
  
  expect_equal(zeta1, zeta2)
  expect_equal(zeta2, zeta3)
})

test_that("Reproducibilidad de puntajes En - mismos inputs deben dar mismo resultado", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  en1 <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.10, U_xpt = 0.02)
  en2 <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.10, U_xpt = 0.02)
  en3 <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.10, U_xpt = 0.02)
  
  expect_equal(en1, en2)
  expect_equal(en2, en3)
})

test_that("Valores esperados de cálculos básicos son correctos", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  # nIQR con datos simples
  datos <- c(1, 2, 3, 4, 5)
  niqr <- calculate_niqr(datos)
  expect_true(is.finite(niqr))
  expect_true(niqr > 0)
  
  # MADe con datos simples
  made <- calculate_mad_e(datos)
  expect_true(is.finite(made))
  expect_true(made >= 0)
})

test_that("Evaluación de puntajes es consistente", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  # z-score: abs(z) <= 2 es Satisfactorio
  expect_equal(evaluate_z_score(0), "Satisfactorio")
  expect_equal(evaluate_z_score(2), "Satisfactorio")
  expect_equal(evaluate_z_score(-2), "Satisfactorio")
  
  # z-score: 2 < abs(z) < 3 es Cuestionable
  expect_equal(evaluate_z_score(2.1), "Cuestionable")
  expect_equal(evaluate_z_score(2.9), "Cuestionable")
  expect_equal(evaluate_z_score(-2.5), "Cuestionable")
  
  # z-score: abs(z) >= 3 es No satisfactorio
  expect_equal(evaluate_z_score(3), "No satisfactorio")
  expect_equal(evaluate_z_score(-3), "No satisfactorio")
  expect_equal(evaluate_z_score(4), "No satisfactorio")
  
  # En-score: abs(En) <= 1 es Satisfactorio
  expect_equal(evaluate_en_score(0), "Satisfactorio")
  expect_equal(evaluate_en_score(1), "Satisfactorio")
  expect_equal(evaluate_en_score(-1), "Satisfactorio")
  
  # En-score: abs(En) > 1 es No satisfactorio
  expect_equal(evaluate_en_score(1.1), "No satisfactorio")
  expect_equal(evaluate_en_score(-1.5), "No satisfactorio")
})

test_that("Homogeneidad - cálculo es determinista", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  # Crear matriz de datos
  set.seed(123)
  matriz1 <- matrix(rnorm(20, mean = 10, sd = 0.5), nrow = 5, ncol = 4)
  matriz2 <- matriz1
  
  stats1 <- calculate_homogeneity_stats(matriz1)
  stats2 <- calculate_homogeneity_stats(matriz2)
  
  expect_equal(stats1$g, stats2$g)
  expect_equal(stats1$m, stats2$m)
  expect_equal(stats1$grand_mean, stats2$grand_mean)
  expect_equal(stats1$ss, stats2$ss)
})

test_that("Puntajes para múltiples participantes son consistentes", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  df1 <- data.frame(
    participant_id = c("P01", "P02", "P03"),
    mean_value = c(10.2, 9.8, 10.1),
    sd_value = c(0.05, 0.06, 0.04)
  )
  
  df2 <- df1
  
  result1 <- calculate_scores_participants(df1, 10.0, 0.25, 0.01, 2)
  result2 <- calculate_scores_participants(df2, 10.0, 0.25, 0.01, 2)
  
  expect_equal(result1$z_score, result2$z_score)
  expect_equal(result1$z_prime_score, result2$z_prime_score)
  expect_equal(result1$zeta_score, result2$zeta_score)
  expect_equal(result1$En_score, result2$En_score)
})

test_that("Resultados con datos reales son finitos", {
  # Cargar datos reales
  summary_data <- read.csv(file.path(data_dir, "summary_n4.csv"), check.names = FALSE)
  
  # Filtrar un analito/nivel específico
  filtered <- summary_data[summary_data$pollutant == "co" & 
                          summary_data$level == "2-μmol/mol" &
                          summary_data$participant_id != "ref", ]
  
  if (nrow(filtered) > 0) {
    valores <- filtered$mean_value
    
    # Verificar que cálculos producen valores finitos
    niqr <- calculate_niqr(valores)
    made <- calculate_mad_e(valores)
    algo_a <- run_algorithm_a(valores)
    
    expect_true(is.finite(niqr))
    expect_true(is.finite(made))
    
    if (!is.null(algo_a$error)) {
      expect_true(is.finite(algo_a$assigned_value))
      expect_true(is.finite(algo_a$robust_sd))
    }
  }
})

test_that("Orden de datos no afecta resultado final (para estadísticos robustos)", {
  old_wd <- getwd()
  if (basename(old_wd) == "tests") {
    setwd("../..")
  }
  on.exit(setwd(old_wd))
  
  # Mismo conjunto de datos, diferente orden
  set.seed(123)
  datos1 <- rnorm(100, mean = 10, sd = 0.5)
  set.seed(456)
  datos2 <- sample(datos1)
  
  # Mediana y MADe son invariantes al orden
  expect_equal(median(datos1), median(datos2))
  
  made1 <- calculate_mad_e(datos1)
  made2 <- calculate_mad_e(datos2)
  expect_equal(made1, made2)
})

cat("\n=== Test 09 completado ===\n")
cat("Todos los tests de reproducibilidad pasaron.\n")
