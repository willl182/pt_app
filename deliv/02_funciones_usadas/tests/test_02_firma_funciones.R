# ===================================================================
# Titulo: test_02_firma_funciones.R
# Entregable: 02
# Descripcion: Verifica que las funciones existan y ejecuten correctamente
# Entrada: pt_app/R/*.R, pt_app/app.R
# Salida: data.frame con resultados de verificacion
# Referencia: N/A
# ===================================================================

library(testthat)
library(tidyverse)

# Cargar las funciones de los archivos R
source("../../../R/pt_homogeneity.R")
source("../../../R/pt_robust_stats.R")
source("../../../R/pt_scores.R")
source("../../../R/utils.R")

# Funciones a probar (lista principal)
funciones_principales <- list(
  # Estadísticos robustos
  list(
    nombre = "calculate_niqr",
    archivo = "pt_robust_stats.R",
    parametros = c("x"),
    test_valores = list(x = c(10.1, 10.3, 10.2, 10.4, 10.0))
  ),
  list(
    nombre = "calculate_mad_e",
    archivo = "pt_robust_stats.R",
    parametros = c("x"),
    test_valores = list(x = c(10.1, 10.3, 10.2, 10.4, 10.0))
  ),
  list(
    nombre = "run_algorithm_a",
    archivo = "pt_robust_stats.R",
    parametros = c("values", "ids"),
    test_valores = list(
      values = c(10.1, 10.3, 10.2, 10.4, 10.0),
      ids = 1:5
    )
  ),
  
  # Puntajes
  list(
    nombre = "calculate_z_score",
    archivo = "pt_scores.R",
    parametros = c("x", "x_pt", "sigma_pt"),
    test_valores = list(x = 10.2, x_pt = 10.0, sigma_pt = 0.5)
  ),
  list(
    nombre = "calculate_z_prime_score",
    archivo = "pt_scores.R",
    parametros = c("x", "x_pt", "sigma_pt", "u_xpt"),
    test_valores = list(x = 10.2, x_pt = 10.0, sigma_pt = 0.5, u_xpt = 0.05)
  ),
  list(
    nombre = "calculate_zeta_score",
    archivo = "pt_scores.R",
    parametros = c("x", "x_pt", "u_x", "u_xpt"),
    test_valores = list(x = 10.2, x_pt = 10.0, u_x = 0.1, u_xpt = 0.05)
  ),
  list(
    nombre = "calculate_en_score",
    archivo = "pt_scores.R",
    parametros = c("x", "x_pt", "U_x", "U_xpt"),
    test_valores = list(x = 10.2, x_pt = 10.0, U_x = 0.2, U_xpt = 0.1)
  ),
  list(
    nombre = "evaluate_z_score",
    archivo = "pt_scores.R",
    parametros = c("z"),
    test_valores = list(z = 0.4)
  ),
  list(
    nombre = "evaluate_en_score",
    archivo = "pt_scores.R",
    parametros = c("en"),
    test_valores = list(en = 0.9)
  ),
  
  # Homogeneidad
  list(
    nombre = "calculate_homogeneity_stats",
    archivo = "pt_homogeneity.R",
    parametros = c("sample_data"),
    test_valores = list(sample_data = matrix(c(10.1, 10.3, 10.2, 10.4, 10.0, 10.2), nrow = 3, ncol = 2))
  ),
  list(
    nombre = "calculate_homogeneity_criterion",
    archivo = "pt_homogeneity.R",
    parametros = c("sigma_pt"),
    test_valores = list(sigma_pt = 0.5)
  ),
  list(
    nombre = "calculate_homogeneity_criterion_expanded",
    archivo = "pt_homogeneity.R",
    parametros = c("sigma_pt", "sw_sq"),
    test_valores = list(sigma_pt = 0.5, sw_sq = 0.01)
  ),
  list(
    nombre = "evaluate_homogeneity",
    archivo = "pt_homogeneity.R",
    parametros = c("ss", "c_criterion"),
    test_valores = list(ss = 0.1, c_criterion = 0.15)
  ),
  list(
    nombre = "calculate_stability_stats",
    archivo = "pt_homogeneity.R",
    parametros = c("stab_sample_data", "hom_grand_mean"),
    test_valores = list(stab_sample_data = matrix(c(10.1, 10.3, 10.2, 10.4), nrow = 2, ncol = 2), hom_grand_mean = 10.2)
  ),
  list(
    nombre = "calculate_stability_criterion",
    archivo = "pt_homogeneity.R",
    parametros = c("sigma_pt"),
    test_valores = list(sigma_pt = 0.5)
  ),
  list(
    nombre = "evaluate_stability",
    archivo = "pt_homogeneity.R",
    parametros = c("diff_hom_stab", "c_criterion"),
    test_valores = list(diff_hom_stab = 0.05, c_criterion = 0.1)
  ),
  list(
    nombre = "calculate_u_hom",
    archivo = "pt_homogeneity.R",
    parametros = c("ss"),
    test_valores = list(ss = 0.1)
  ),
  list(
    nombre = "calculate_u_stab",
    archivo = "pt_homogeneity.R",
    parametros = c("diff_hom_stab", "c_criterion"),
    test_valores = list(diff_hom_stab = 0.05, c_criterion = 0.1)
  )
)

# Test suite
context("Entregable 02 - Verificación de Funciones")

test_that("Funciones principales existen y son ejecutables", {
  for (f in funciones_principales) {
    nombre <- f$nombre
    
    # Verificar que la función existe
    expect_true(exists(nombre, mode = "function"),
                info = paste("La función", nombre, "debe existir"))
    
    # Intentar ejecutar la función con valores de prueba
    test_args <- f$test_valores
    
    resultado <- tryCatch({
      do.call(nombre, test_args)
    }, error = function(e) {
      list(error = e$message)
    })
    
    # Verificar que no haya error
    hay_error <- if(is.list(resultado)) {
      !is.null(resultado$error)
    } else if (is.character(resultado) && length(resultado) == 1) {
      grepl("error", resultado, ignore.case = TRUE)
    } else {
      FALSE
    }
    expect_false(hay_error, info = paste("La función", nombre, "debe ejecutarse sin errores"))
  }
})

test_that("Retornos de funciones son del tipo esperado", {
  # Test específico para calculate_niqr
  x <- c(10.1, 10.3, 10.2, 10.4, 10.0)
  resultado <- calculate_niqr(x)
  expect_type(resultado, "double")

  # Test para calculate_z_score
  resultado <- calculate_z_score(10.2, 10.0, 0.5)
  expect_type(resultado, "double")

  # Test para evaluate_z_score
  resultado <- evaluate_z_score(0.4)
  expect_type(resultado, "character")

  # Test para calculate_homogeneity_stats
  datos <- matrix(c(10.1, 10.3, 10.2, 10.4, 10.0, 10.2), nrow = 3, ncol = 2)
  resultado <- calculate_homogeneity_stats(datos)
  expect_type(resultado, "list")
})

# Generar reporte de resultados
generar_reporte <- function() {
  resultados <- data.frame(
    test = character(),
    resultado = character(),
    valor_esperado = character(),
    status = character(),
    stringsAsFactors = FALSE
  )
  
  # Verificar existencia de cada función
  for (f in funciones_principales) {
    nombre <- f$nombre
    existe <- exists(nombre, mode = "function")
    
    resultados <- rbind(resultados, data.frame(
      test = paste0("existe_", nombre),
      resultado = as.character(existe),
      valor_esperado = "TRUE",
      status = ifelse(existe, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    ))
    
    # Ejecutar función
    if (existe) {
      test_args <- f$test_valores
      resultado <- tryCatch({
        res <- do.call(nombre, test_args)
        "EJECUTA"
      }, error = function(e) {
        "ERROR"
      })
      
      resultados <- rbind(resultados, data.frame(
        test = paste0("ejecuta_", nombre),
        resultado = resultado,
        valor_esperado = "EJECUTA",
        status = ifelse(resultado == "EJECUTA", "PASS", "FAIL"),
        stringsAsFactors = FALSE
      ))
    }
  }
  
  return(resultados)
}

# Ejecutar y guardar reporte
cat("=== EJECUTANDO TESTS ENTREGABLE 02 ===\n\n")
resultados <- generar_reporte()
print(resultados)

# Guardar CSV
ruta_csv <- "../test_02_resultados.csv"
cat("\nGuardando resultados en:", ruta_csv, "\n")
write.csv(resultados, ruta_csv, row.names = FALSE)
cat("\nResultados guardados correctamente.\n")

# Resumen
cat("\n=== RESUMEN ===\n")
cat("Total tests:", nrow(resultados), "\n")
cat("PASS:", sum(resultados$status == "PASS"), "\n")
cat("FAIL:", sum(resultados$status == "FAIL"), "\n")
