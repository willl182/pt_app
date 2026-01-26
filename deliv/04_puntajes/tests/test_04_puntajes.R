# ===================================================================
# Titulo: test_04_puntajes.R
# Entregable: 04
# Descripcion: Tests para funciones de cálculo de puntajes PT (z, z', ζ, En)
# Referencia: ISO 13528:2022, Sección 10
# ===================================================================

library(testthat)

# Configurar directorio de trabajo
old_wd <- setwd("../../..")
on.exit(setwd(old_wd))

# Cargar datos
summary_data <- read.csv("data/summary_n4.csv")

# Cargar funciones
source("deliv/03_calculos_pt/R/robust_stats.R")
source("deliv/03_calculos_pt/R/valor_asignado.R")
source("deliv/03_calculos_pt/R/sigma_pt.R")
source("deliv/04_puntajes/R/calcula_puntajes.R")
source("deliv/04_puntajes/R/crea_reporte.R")

# ===================================================================
# TESTS DE CÁLCULO DE PUNTAJES
# ===================================================================

context("Cálculo de Puntajes")

test_that("calcular_puntaje_z calcula puntaje z correctamente", {
  x <- 10.5
  x_pt <- 10.0
  sigma_pt <- 0.5

  z <- calcular_puntaje_z(x, x_pt, sigma_pt)

  expect_true(is.finite(z))
  expect_equal(z, 1.0)
})

test_that("calcular_puntaje_z maneja sigma_pt inválido", {
  x <- 10.5
  x_pt <- 10.0
  sigma_pt <- 0

  z <- calcular_puntaje_z(x, x_pt, sigma_pt)

  expect_true(is.na(z))
})

test_that("calcular_puntaje_z maneja sigma_pt negativo", {
  x <- 10.5
  x_pt <- 10.0
  sigma_pt <- -0.5

  z <- calcular_puntaje_z(x, x_pt, sigma_pt)

  expect_true(is.na(z))
})

test_that("calcular_puntaje_z_prima calcula puntaje z' correctamente", {
  x <- 10.5
  x_pt <- 10.0
  sigma_pt <- 0.5
  u_xpt <- 0.1

  z_prima <- calcular_puntaje_z_prima(x, x_pt, sigma_pt, u_xpt)

  expect_true(is.finite(z_prima))
  expect_true(abs(z_prima - 1.0) < 0.1)
})

test_that("calcular_puntaje_zeta calcula puntaje ζ correctamente", {
  x <- 10.5
  x_pt <- 10.0
  u_x <- 0.2
  u_xpt <- 0.1

  zeta <- calcular_puntaje_zeta(x, x_pt, u_x, u_xpt)

  expect_true(is.finite(zeta))
  expect_true(abs(zeta - 1.58) < 0.1)
})

test_that("calcular_puntaje_en calcula puntaje En correctamente", {
  x <- 10.5
  x_pt <- 10.0
  U_x <- 0.4
  U_xpt <- 0.2

  en <- calcular_puntaje_en(x, x_pt, U_x, U_xpt)

  expect_true(is.finite(en))
  expect_equal(en, 1.0)
})

test_that("calcular_puntaje_en maneja denominador cero", {
  x <- 10.5
  x_pt <- 10.0
  U_x <- 0
  U_xpt <- 0

  en <- calcular_puntaje_en(x, x_pt, U_x, U_xpt)

  expect_true(is.na(en))
})

# ===================================================================
# TESTS DE EVALUACIÓN DE PUNTAJES
# ===================================================================

context("Evaluación de Puntajes")

test_that("evaluar_puntaje_z clasifica Satisfactorio correctamente", {
  z <- 1.5
  eval <- evaluar_puntaje_z(z)

  expect_equal(eval, "Satisfactorio")
})

test_that("evaluar_puntaje_z clasifica Cuestionable correctamente", {
  z <- 2.5
  eval <- evaluar_puntaje_z(z)

  expect_equal(eval, "Cuestionable")
})

test_that("evaluar_puntaje_z clasifica No satisfactorio correctamente", {
  z <- 3.5
  eval <- evaluar_puntaje_z(z)

  expect_equal(eval, "No satisfactorio")
})

test_that("evaluar_puntaje_z maneja NA", {
  z <- NA
  eval <- evaluar_puntaje_z(z)

  expect_equal(eval, "N/A")
})

test_that("evaluar_puntaje_z_vec evalúa vector correctamente", {
  z <- c(1.5, 2.5, 3.5, NA)
  eval <- evaluar_puntaje_z_vec(z)

  expect_equal(length(eval), 4)
  expect_equal(eval[1], "Satisfactorio")
  expect_equal(eval[2], "Cuestionable")
  expect_equal(eval[3], "No satisfactorio")
  expect_equal(eval[4], "N/A")
})

test_that("evaluar_puntaje_en clasifica Satisfactorio correctamente", {
  en <- 0.8
  eval <- evaluar_puntaje_en(en)

  expect_equal(eval, "Satisfactorio")
})

test_that("evaluar_puntaje_en clasifica No satisfactorio correctamente", {
  en <- 1.5
  eval <- evaluar_puntaje_en(en)

  expect_equal(eval, "No satisfactorio")
})

test_that("evaluar_puntaje_en maneja NA", {
  en <- NA
  eval <- evaluar_puntaje_en(en)

  expect_equal(eval, "N/A")
})

test_that("evaluar_puntaje_en_vec evalúa vector correctamente", {
  en <- c(0.8, 1.5, NA)
  eval <- evaluar_puntaje_en_vec(en)

  expect_equal(length(eval), 3)
  expect_equal(eval[1], "Satisfactorio")
  expect_equal(eval[2], "No satisfactorio")
  expect_equal(eval[3], "N/A")
})

# ===================================================================
# TESTS DE CÁLCULO PARA PARTICIPANTES
# ===================================================================

context("Cálculo para Participantes")

test_that("calcular_puntajes_participante genera data.frame válido", {
  datos_part <- summary_data[summary_data$participant_id == "part_1", ]
  x_pt <- 2.0
  sigma_pt <- 0.06

  resultado <- calcular_puntajes_participante(datos_part, x_pt, sigma_pt)

  expect_true(is.data.frame(resultado))
  expect_true(nrow(resultado) > 0)
  expect_true("z" %in% names(resultado))
  expect_true("evaluacion_z" %in% names(resultado))
})

test_that("calcular_puntajes_participante incluye todas las columnas", {
  datos_part <- summary_data[summary_data$participant_id == "part_1", ]
  x_pt <- 2.0
  sigma_pt <- 0.06

  resultado <- calcular_puntajes_participante(datos_part, x_pt, sigma_pt)

  columnas_esperadas <- c("pollutant", "run", "level", "participant_id",
                          "replicate", "sample_group", "x", "x_pt", "sigma_pt",
                          "z", "evaluacion_z", "z_prima", "evaluacion_z_prima",
                          "zeta", "evaluacion_zeta", "en", "evaluacion_en")
  expect_true(all(columnas_esperadas %in% names(resultado)))
})

test_that("calcular_puntajes_todos procesa todos los participantes", {
  # Crear diccionarios simples
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  resultado <- calcular_puntajes_todos(summary_data, va_dict, sigma_dict)

  expect_true(is.data.frame(resultado))
  expect_true(nrow(resultado) > 0)
})

test_that("calcular_puntajes_todos genera puntajes finitos", {
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  resultado <- calcular_puntajes_todos(summary_data, va_dict, sigma_dict)
  z_vals <- resultado$z[is.finite(resultado$z)]

  expect_true(length(z_vals) > 0)
})

# ===================================================================
# TESTS DE RESUMEN DE PUNTAJES
# ===================================================================

context("Resumen de Puntajes")

test_that("resumir_puntajes_participante genera resumen válido", {
  datos_part <- summary_data[summary_data$participant_id == "part_1", ]
  x_pt <- 2.0
  sigma_pt <- 0.06

  puntajes <- calcular_puntajes_participante(datos_part, x_pt, sigma_pt)
  resumen <- resumir_puntajes_participante(puntajes, "part_1")

  expect_null(resumen$error)
  expect_true(resumen$total_observaciones > 0)
})

test_that("resumir_puntajes_participante maneja participante inexistente", {
  datos_part <- summary_data[summary_data$participant_id == "part_1", ]
  x_pt <- 2.0
  sigma_pt <- 0.06

  puntajes <- calcular_puntajes_participante(datos_part, x_pt, sigma_pt)
  resumen <- resumir_puntajes_participante(puntajes, "part_inexistente")

  expect_false(is.null(resumen$error))
})

test_that("resumir_puntajes_global genera resúmenes para todos", {
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  puntajes <- calcular_puntajes_todos(summary_data, va_dict, sigma_dict)
  resumenes <- resumir_puntajes_global(puntajes)

  expect_true(length(resumenes) > 0)
  expect_true(all(sapply(resumenes, function(r) is.null(r$error))))
})

# ===================================================================
# TESTS DE ESTADÍSTICAS
# ===================================================================

context("Estadísticas de Puntajes")

test_that("calcular_estadisticas_puntajes calcula estadísticas z", {
  datos <- data.frame(
    z = c(1.0, -1.0, 2.0, -2.0, 0.5, -0.5)
  )

  stats <- calcular_estadisticas_puntajes(datos)

  expect_true(is.finite(stats$media_z))
  expect_true(is.finite(stats$sd_z))
  expect_true(is.finite(stats$n_z))
})

test_that("calcular_estadisticas_puntajes calcula porcentajes correctamente", {
  datos <- data.frame(
    z = c(1.0, -1.0, 2.0, -2.0, 0.5, -0.5, 3.5)
  )

  stats <- calcular_estadisticas_puntajes(datos)

  expect_true(is.finite(stats$pct_satisfactorio_z))
  expect_true(is.finite(stats$pct_cuestionable_z))
  expect_true(is.finite(stats$pct_no_satisfactorio_z))
  expect_equal(sum(stats$pct_satisfactorio_z, stats$pct_cuestionable_z,
                 stats$pct_no_satisfactorio_z), 100, tolerance = 0.1)
})

test_that("calcular_estadisticas_puntajes calcula estadísticas En", {
  datos <- data.frame(
    en = c(0.5, -0.5, 1.2, -0.8, 0.3)
  )

  stats <- calcular_estadisticas_puntajes(datos)

  expect_true(is.finite(stats$media_en))
  expect_true(is.finite(stats$sd_en))
  expect_true(is.finite(stats$n_en))
  expect_true(is.finite(stats$pct_satisfactorio_en))
  expect_true(is.finite(stats$pct_no_satisfactorio_en))
})

# ===================================================================
# TESTS DE GENERACIÓN DE REPORTES
# ===================================================================

context("Generación de Reportes")

test_that("generar_reporte_puntajes genera data.frame válido", {
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  resultado <- generar_reporte_puntajes(summary_data, va_dict, sigma_dict)

  expect_null(resultado$error)
  expect_true(is.data.frame(resultado$datos))
  expect_true(resultado$n_observaciones > 0)
})

test_that("generar_reporte_puntajes cuenta participantes correctamente", {
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  resultado <- generar_reporte_puntajes(summary_data, va_dict, sigma_dict)

  expect_true(resultado$n_participantes > 0)
})

test_that("generar_reporte_resumido_participantes genera resumen válido", {
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  reporte_puntajes <- generar_reporte_puntajes(summary_data, va_dict, sigma_dict)
  reporte_resumido <- generar_reporte_resumido_participantes(reporte_puntajes$datos)

  expect_null(reporte_resumido$error)
  expect_true(is.data.frame(reporte_resumido$datos))
})

test_that("generar_reporte_estadisticas_globales genera estadísticas válidas", {
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  reporte_puntajes <- generar_reporte_puntajes(summary_data, va_dict, sigma_dict)
  reporte_estadisticas <- generar_reporte_estadisticas_globales(reporte_puntajes$datos)

  expect_null(reporte_estadisticas$error)
  expect_true(is.data.frame(reporte_estadisticas$datos))
  expect_true(is.data.frame(reporte_estadisticas$estadisticas))
})

test_that("generar_reporte_completo genera todos los reportes", {
  va_dict <- list("co_2-μmol/mol" = 2.0)
  sigma_dict <- list("co_2-μmol/mol" = 0.06)

  resultado <- generar_reporte_completo(summary_data, va_dict, sigma_dict, NULL, FALSE)

  expect_null(resultado$error)
  expect_true(!is.null(resultado$puntajes))
  expect_true(!is.null(resultado$resumen_participantes))
  expect_true(!is.null(resultado$estadisticas_globales))
})

test_that("generar_reporte_pt ejecuta flujo completo", {
  resultado <- generar_reporte_pt(
    datos_participantes = summary_data,
    metodo_valor_asignado = "algoritmo_a",
    metodo_sigma_pt = "algoritmo_a",
    directorio_salida = NULL,
    incluir_ref = FALSE
  )

  expect_null(resultado$error)
  expect_true(!is.null(resultado$puntajes))
})

# ===================================================================
# FINAL
# ===================================================================

cat("\n=== TESTS COMPLETADOS - Entregable 04 ===\n")
