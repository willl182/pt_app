# ===================================================================
# Titulo: test_03_calculos_pt.R
# Entregable: 03
# Descripcion: Tests para funciones de cálculo PT (homogeneidad, estabilidad, valor asignado, sigma_pt)
# Referencia: ISO 13528:2022
# ===================================================================

library(testthat)

# Configurar directorio de trabajo
old_wd <- setwd("../../..")
on.exit(setwd(old_wd))

# Cargar datos
hom_data <- read.csv("data/homogeneity.csv")
stab_data <- read.csv("data/stability.csv")
summary_data <- read.csv("data/summary_n4.csv")

# Cargar funciones
source("deliv/03_calculos_pt/R/robust_stats.R")
source("deliv/03_calculos_pt/R/homogeneity.R")
source("deliv/03_calculos_pt/R/stability.R")
source("deliv/03_calculos_pt/R/valor_asignado.R")
source("deliv/03_calculos_pt/R/sigma_pt.R")

# ===================================================================
# TESTS DE ESTADÍSTICAS ROBUSTAS
# ===================================================================

context("Estadísticas Robustas")

test_that("calcular_niqr calcula nIQR correctamente", {
  x <- c(1, 2, 3, 4, 5)
  niqr <- calcular_niqr(x)

  expect_true(is.finite(niqr))
  expect_true(niqr > 0)
})

test_that("calcular_niqr maneja datos insuficientes", {
  x <- c(1)
  niqr <- calcular_niqr(x)

  expect_true(is.na(niqr))
})

test_that("calcular_mad_e calcula MADe correctamente", {
  x <- c(1, 2, 3, 4, 5)
  made <- calcular_mad_e(x)

  expect_true(is.finite(made))
  expect_true(made > 0)
})

test_that("calcular_mad_e maneja datos vacíos", {
  x <- numeric(0)
  made <- calcular_mad_e(x)

  expect_true(is.na(made))
})

test_that("calcular_mad_e es robusto a valores atípicos", {
  x_normal <- c(1, 2, 3, 4, 5)
  x_con_outlier <- c(1, 2, 3, 4, 100)

  made_normal <- calcular_mad_e(x_normal)
  made_outlier <- calcular_mad_e(x_con_outlier)

  expect_true(abs(made_normal - made_outlier) < 0.5)
})

test_that("ejecutar_algoritmo_a calcula x* y s* correctamente", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3)
  resultado <- ejecutar_algoritmo_a(x)

  expect_null(resultado$error)
  expect_true(is.finite(resultado$valor_asignado))
  expect_true(is.finite(resultado$sigma_pt))
  expect_true(resultado$convergencia)
})

test_that("ejecutar_algoritmo_a maneja datos insuficientes", {
  x <- c(1, 2)
  resultado <- ejecutar_algoritmo_a(x)

  expect_false(is.null(resultado$error))
})

test_that("ejecutar_algoritmo_a es robusto a valores atípicos", {
  x <- c(10.1, 10.2, 9.9, 10.0, 50.0)
  resultado <- ejecutar_algoritmo_a(x)

  expect_null(resultado$error)
  expect_true(abs(resultado$valor_asignado - 10) < 1)
})

test_that("ejecutar_algoritmo_a registra iteraciones", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1, 10.2, 9.9, 10.0)
  resultado <- ejecutar_algoritmo_a(x)

  expect_true(nrow(resultado$iteraciones) > 0)
  expect_true("delta" %in% names(resultado$iteraciones))
})

test_that("ejecutar_algoritmo_a calcula pesos finales", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3)
  resultado <- ejecutar_algoritmo_a(x)

  expect_true(nrow(resultado$pesos) == length(x))
  expect_true("peso" %in% names(resultado$pesos))
  expect_true("residual_estandarizado" %in% names(resultado$pesos))
})

test_that("calcular_estadisticas_robustas calcula todas las métricas", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3)
  resultado <- calcular_estadisticas_robustas(x)

  expect_true("niqr" %in% names(resultado))
  expect_true("made" %in% names(resultado))
  expect_true("algoritmo_a" %in% names(resultado))
})

test_that("detectar_valores_atipicos detecta correctamente con MADe", {
  x <- c(10.1, 10.2, 9.9, 10.0, 100.0)
  resultado <- detectar_valores_atipicos(x, metodo = "mad_e", umbral = 3)

  expect_null(resultado$error)
  expect_true(resultado$metodo == "mad_e")
  expect_true(resultado$n_atipicos >= 0)
})

test_that("detectar_valores_atipicos detecta correctamente con nIQR", {
  x <- c(10.1, 10.2, 9.9, 10.0, 100.0)
  resultado <- detectar_valores_atipicos(x, metodo = "niqr", umbral = 3)

  expect_null(resultado$error)
  expect_true(resultado$metodo == "niqr")
  expect_true(resultado$n_atipicos >= 0)
})

test_that("detectar_valores_atipicos maneja método inválido", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3)
  resultado <- detectar_valores_atipicos(x, metodo = "invalido", umbral = 3)

  expect_false(is.null(resultado$error))
})

# ===================================================================
# TESTS DE HOMOGENEIDAD
# ===================================================================

context("Cálculo de Homogeneidad")

test_that("calcular_estadisticas_homogeneidad calcula estadísticos correctamente", {
  result <- calcular_estadisticas_homogeneidad(hom_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_equal(result$contaminante, "co")
  expect_equal(result$nivel, "2-μmol/mol")
  expect_true(result$g >= 10)
  expect_true(result$m >= 1)
  expect_true(is.finite(result$media_global))
  expect_true(is.finite(result$ss))
  expect_true(is.finite(result$sw))
})

test_that("calcular_estadisticas_homogeneidad maneja datos inexistentes", {
  result <- calcular_estadisticas_homogeneidad(hom_data, "xyz", "999-nmol/mol")

  expect_false(is.null(result$error))
  expect_true(grepl("No se encontraron datos", result$error))
})

test_that("calcular_criterio_homogeneidad calcula criterio correctamente", {
  sigma_pt <- 0.1
  c_val <- calcular_criterio_homogeneidad(sigma_pt)

  expect_equal(c_val, 0.03)
})

test_that("calcular_criterio_expandido_homogeneidad calcula criterio expandido", {
  sigma_pt <- 0.1
  sw_sq <- 0.01
  c_exp <- calcular_criterio_expandido_homogeneidad(sigma_pt, sw_sq)

  expect_true(is.finite(c_exp))
  expect_true(c_exp > 0)
})

test_that("evaluar_homogeneidad evalúa correctamente cuando cumple criterio", {
  ss <- 0.01
  c_criterion <- 0.02

  result <- evaluar_homogeneidad(ss, c_criterion)

  expect_true(result$pasa_criterio)
  expect_true(grepl("CUMPLE", result$conclusion))
})

test_that("evaluar_homogeneidad evalúa correctamente cuando NO cumple criterio", {
  ss <- 0.03
  c_criterion <- 0.02

  result <- evaluar_homogeneidad(ss, c_criterion)

  expect_false(result$pasa_criterio)
  expect_true(grepl("NO CUMPLE", result$conclusion))
})

test_that("analizar_homogeneidad ejecuta análisis completo", {
  sigma_pt <- 0.06
  result <- analizar_homogeneidad(hom_data, "co", "2-μmol/mol", sigma_pt)

  expect_null(result$error)
  expect_true(is.finite(result$c_criterion))
  expect_true(is.finite(result$c_expanded))
  expect_true(is.finite(result$stats$ss))
})

# ===================================================================
# TESTS DE ESTABILIDAD
# ===================================================================

context("Cálculo de Estabilidad")

test_that("calcular_estadisticas_estabilidad calcula estadísticos correctamente", {
  media_hom <- 2.01
  result <- calcular_estadisticas_estabilidad(stab_data, media_hom, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_equal(result$contaminante, "co")
  expect_equal(result$nivel, "2-μmol/mol")
  expect_true(is.finite(result$media_estabilidad))
  expect_true(is.finite(result$diff_hom_est))
})

test_that("calcular_estadisticas_estabilidad maneja datos inexistentes", {
  media_hom <- 0
  result <- calcular_estadisticas_estabilidad(stab_data, media_hom, "xyz", "999-nmol/mol")

  expect_false(is.null(result$error))
})

test_that("calcular_criterio_estabilidad calcula criterio correctamente", {
  sigma_pt <- 0.1
  c_val <- calcular_criterio_estabilidad(sigma_pt)

  expect_equal(c_val, 0.03)
})

test_that("evaluar_estabilidad evalúa correctamente cuando cumple criterio", {
  diff <- 0.01
  c_criterion <- 0.02

  result <- evaluar_estabilidad(diff, c_criterion)

  expect_true(result$pasa_criterio)
  expect_true(grepl("CUMPLE", result$conclusion))
})

test_that("evaluar_estabilidad evalúa correctamente cuando NO cumple criterio", {
  diff <- 0.03
  c_criterion <- 0.02

  result <- evaluar_estabilidad(diff, c_criterion)

  expect_false(result$pasa_criterio)
  expect_true(grepl("NO CUMPLE", result$conclusion))
})

test_that("analizar_estabilidad ejecuta análisis completo", {
  media_hom <- 2.01
  sigma_pt <- 0.06
  result <- analizar_estabilidad(stab_data, media_hom, "co", "2-μmol/mol", sigma_pt)

  expect_null(result$error)
  expect_true(is.finite(result$c_criterion))
  expect_true(is.finite(result$diff_hom_est))
})

# ===================================================================
# TESTS DE VALOR ASIGNADO
# ===================================================================

context("Cálculo de Valor Asignado")

test_that("calcular_niqr calcula nIQR correctamente", {
  x <- c(1, 2, 3, 4, 5)
  niqr <- calcular_niqr(x)

  expect_true(is.finite(niqr))
  expect_true(niqr > 0)
})

test_that("calcular_mad_e calcula MADe correctamente", {
  x <- c(1, 2, 3, 4, 5)
  made <- calcular_mad_e(x)

  expect_true(is.finite(made))
  expect_true(made > 0)
})

test_that("calcular_valor_referencia calcula valor de referencia", {
  result <- calcular_valor_referencia(summary_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_true(is.finite(result$valor_asignado))
  expect_equal(result$metodo, "referencia")
})

test_that("calcular_valor_consenso_made calcula valor con MADe", {
  result <- calcular_valor_consenso_made(summary_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_true(is.finite(result$valor_asignado))
  expect_true(is.finite(result$sigma_pt))
  expect_equal(result$metodo, "consenso_made")
})

test_that("calcular_valor_consenso_niqr calcula valor con nIQR", {
  result <- calcular_valor_consenso_niqr(summary_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_true(is.finite(result$valor_asignado))
  expect_true(is.finite(result$sigma_pt))
  expect_equal(result$metodo, "consenso_niqr")
})

test_that("calcular_valor_algoritmo_a calcula valor con Algoritmo A", {
  result <- calcular_valor_algoritmo_a(summary_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_true(is.finite(result$valor_asignado))
  expect_true(is.finite(result$sigma_pt))
  expect_equal(result$metodo, "algoritmo_a")
  expect_true(is.null(result$convergencia) || is.logical(result$convergencia))
})

test_that("calcular_valor_asignado selecciona método correcto", {
  result <- calcular_valor_asignado(summary_data, "co", "2-μmol/mol", "algoritmo_a")

  expect_null(result$error)
  expect_equal(result$metodo, "algoritmo_a")
})

test_that("calcular_valor_asignado maneja método inválido", {
  result <- calcular_valor_asignado(summary_data, "co", "2-μmol/mol", "metodo_invalido")

  expect_false(is.null(result$error))
})

test_that("calcular_valor_asignado_todos procesa todos los contaminantes", {
  results <- calcular_valor_asignado_todos(summary_data, metodo = "algoritmo_a")

  expect_true(length(results) > 0)
  expect_true(all(sapply(results, function(r) is.null(r$error))))
})

# ===================================================================
# TESTS DE SIGMA_PT
# ===================================================================

context("Cálculo de sigma_pt")

test_that("calcular_sigma_pt_made calcula sigma_pt con MADe", {
  result <- calcular_sigma_pt_made(summary_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_true(is.finite(result$sigma_pt))
  expect_equal(result$metodo, "made")
})

test_that("calcular_sigma_pt_niqr calcula sigma_pt con nIQR", {
  result <- calcular_sigma_pt_niqr(summary_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_true(is.finite(result$sigma_pt))
  expect_equal(result$metodo, "niqr")
})

test_that("calcular_sigma_pt_algoritmo_a calcula sigma_pt con Algoritmo A", {
  result <- calcular_sigma_pt_algoritmo_a(summary_data, "co", "2-μmol/mol")

  expect_null(result$error)
  expect_true(is.finite(result$sigma_pt))
  expect_true(is.finite(result$valor_asignado))
  expect_equal(result$metodo, "algoritmo_a")
})

test_that("calcular_sigma_pt selecciona método correcto", {
  result <- calcular_sigma_pt(summary_data, "co", "2-μmol/mol", "algoritmo_a")

  expect_null(result$error)
  expect_equal(result$metodo, "algoritmo_a")
})

test_that("calcular_sigma_pt maneja método inválido", {
  result <- calcular_sigma_pt(summary_data, "co", "2-μmol/mol", "metodo_invalido")

  expect_false(is.null(result$error))
})

test_that("calcular_sigma_pt_todos procesa todos los contaminantes", {
  results <- calcular_sigma_pt_todos(summary_data, metodo = "algoritmo_a")

  expect_true(length(results) > 0)
  expect_true(all(sapply(results, function(r) is.null(r$error))))
})

test_that("crear_diccionario_sigma_pt crea diccionario válido", {
  sigma_dict <- crear_diccionario_sigma_pt(summary_data, metodo = "algoritmo_a")

  expect_true(length(sigma_dict) > 0)
  expect_true(all(sapply(sigma_dict, is.finite)))
})

# ===================================================================
# TESTS DE INTEGRACIÓN
# ===================================================================

context("Integración de Módulos")

test_that("flujo completo homogeneidad -> estabilidad -> valor asignado", {
  # 1. Calcular sigma_pt
  sigma_dict <- crear_diccionario_sigma_pt(summary_data, metodo = "algoritmo_a")
  expect_true("co_2-μmol/mol" %in% names(sigma_dict))

  # 2. Calcular homogeneidad
  resultados_hom <- analizar_homogeneidad_todos(hom_data, sigma_dict)
  expect_true("co_2-μmol/mol" %in% names(resultados_hom))

  # 3. Calcular estabilidad
  resultados_stab <- analizar_estabilidad_todos(stab_data, hom_data, resultados_hom)
  expect_true("co_2-μmol/mol" %in% names(resultados_stab))

  # 4. Calcular valor asignado
  resultados_va <- calcular_valor_asignado_todos(summary_data, metodo = "algoritmo_a")
  expect_true("co_2-μmol/mol" %in% names(resultados_va))

  # 5. Verificar consistencia
  hom_result <- resultados_hom$`co_2-μmol/mol`
  stab_result <- resultados_stab$`co_2-μmol/mol`
  va_result <- resultados_va$`co_2-μmol/mol`

  expect_null(hom_result$error)
  expect_null(stab_result$error)
  expect_null(va_result$error)
})

test_that("comparación de métodos para valor asignado", {
  result <- comparar_metodos_valor_asignado(summary_data, "co", "2-μmol/mol")

  expect_equal(result$contaminante, "co")
  expect_equal(result$nivel, "2-μmol/mol")
  expect_equal(length(result$metodos), 4)

  for (metodo in c("referencia", "consenso_made", "consenso_niqr", "algoritmo_a")) {
    expect_null(result$metodos[[metodo]]$error)
  }
})

test_that("comparación de métodos para sigma_pt", {
  result <- comparar_metodos_sigma_pt(summary_data, "co", "2-μmol/mol")

  expect_equal(result$contaminante, "co")
  expect_equal(result$nivel, "2-μmol/mol")
  expect_equal(length(result$metodos), 3)

  for (metodo in c("made", "niqr", "algoritmo_a")) {
    expect_null(result$metodos[[metodo]]$error)
  }
})

# ===================================================================
# FINAL
# ===================================================================

cat("\n=== TESTS COMPLETADOS - Entregable 03 ===\n")
