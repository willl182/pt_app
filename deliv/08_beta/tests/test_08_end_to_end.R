# ===================================================================
# Titulo: test_08_end_to_end.R
# Entregable: 08
# Descripcion: Test end-to-end del flujo de calculos de la version beta
# Entrada: R/funciones_finales.R y archivos CSV en data/
# Salida: Resultados de testthat (PASS/FAIL)
# Autor: [PT App Team]
# Fecha: 2026-01-11
# ===================================================================

library(testthat)

# Detectar directorio base
detectar_base_dir <- function() {
  candidatos <- c(
    getwd(),
    Sys.getenv("PT_APP_DIR"),
    "/home/w182/w421/pt_app"
  )
  
  for (candidato in candidatos) {
    if (nchar(candidato) > 0 && dir.exists(file.path(candidato, "data"))) {
      return(candidato)
    }
    if (grepl("deliv", candidato)) {
      partes <- strsplit(candidato, "deliv")[[1]][1]
      partes <- sub("/$", "", partes)
      if (dir.exists(file.path(partes, "data"))) {
        return(partes)
      }
    }
  }
  
  wd <- getwd()
  if (grepl("pt_app", wd)) {
    base <- sub("/deliv.*", "", wd)
    if (dir.exists(file.path(base, "data"))) {
      return(base)
    }
  }
  
  return("/home/w182/w421/pt_app")
}

base_dir <- detectar_base_dir()
carpeta_entregable <- file.path(base_dir, "deliv", "08_beta")
ruta_funciones <- file.path(carpeta_entregable, "R", "funciones_finales.R")
ruta_data <- file.path(base_dir, "data")


# -------------------------------------------------------------------
# Validacion de existencia de archivos
# -------------------------------------------------------------------

test_that("Archivos base existen", {
  expect_true(file.exists(ruta_funciones))
  expect_true(file.exists(file.path(ruta_data, "homogeneity.csv")))
  expect_true(file.exists(file.path(ruta_data, "stability.csv")))
  expect_true(file.exists(file.path(ruta_data, "summary_n4.csv")))
})

calc_env <- new.env()
expresiones <- parse(file = ruta_funciones)
for (expresion in expresiones) {
  eval(expresion, envir = calc_env)
}

hom_data <- read.csv(file.path(ruta_data, "homogeneity.csv"), stringsAsFactors = FALSE)
stab_data <- read.csv(file.path(ruta_data, "stability.csv"), stringsAsFactors = FALSE)
summary_data <- read.csv(file.path(ruta_data, "summary_n4.csv"), stringsAsFactors = FALSE)

pollutant <- hom_data$pollutant[1]
level <- hom_data$level[1]

# -------------------------------------------------------------------
# Flujo de homogeneidad
# -------------------------------------------------------------------

test_that("Homogeneidad devuelve estadisticos validos", {
  matriz <- calc_env$construir_matriz_muestras(hom_data, pollutant, level)
  stats <- calc_env$calculate_homogeneity_stats(matriz)

  expect_null(stats$error)
  expect_true(is.finite(stats$ss))
  expect_true(is.finite(stats$sw))
})

# -------------------------------------------------------------------
# Flujo de estabilidad
# -------------------------------------------------------------------

test_that("Estabilidad devuelve evaluacion valida", {
  matriz_hom <- calc_env$construir_matriz_muestras(hom_data, pollutant, level)
  hom_stats <- calc_env$calculate_homogeneity_stats(matriz_hom)

  matriz_stab <- calc_env$construir_matriz_muestras(stab_data, pollutant, level)
  stab_stats <- calc_env$calculate_stability_stats(matriz_stab, hom_stats$grand_mean)

  sigma_pt <- calc_env$calculate_mad_e(hom_data$value)
  c_criterion <- calc_env$calculate_stability_criterion(sigma_pt)
  evaluacion <- calc_env$evaluate_stability(stab_stats$diff_hom_stab, c_criterion)

  expect_null(stab_stats$error)
  expect_true(is.logical(evaluacion$passes_criterion) || is.na(evaluacion$passes_criterion))
})

# -------------------------------------------------------------------
# Valor asignado y puntajes
# -------------------------------------------------------------------

test_that("Valor asignado y puntajes se calculan", {
  valor <- calc_env$calculate_valor_asignado(summary_data, pollutant, level, metodo = "2a")
  expect_null(valor$error)
  expect_true(is.finite(valor$x_pt))

  tabla <- calc_env$calculate_scores_table(summary_data, k = 2)
  expect_true(nrow(tabla) > 0)
  columnas_esperadas <- c("z_score", "z_prime_score", "zeta_score", "En_score")
  expect_true(all(columnas_esperadas %in% names(tabla)))
})

# ===================================================================
# Generar resultados estructurados
# ===================================================================
generar_resultados_estructurados <- function() {
  resultados <- data.frame(
    test = character(),
    resultado = character(),
    valor_esperado = character(),
    status = character(),
    stringsAsFactors = FALSE
  )
  
  # Test 1: Archivos base existen
  archivos_ok <- file.exists(ruta_funciones) && 
                 file.exists(file.path(ruta_data, "homogeneity.csv")) &&
                 file.exists(file.path(ruta_data, "stability.csv")) &&
                 file.exists(file.path(ruta_data, "summary_n4.csv"))
  resultados <- rbind(resultados, data.frame(
    test = "archivos_base_existen",
    resultado = as.character(archivos_ok),
    valor_esperado = "TRUE",
    status = ifelse(archivos_ok, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  # Test 2: Homogeneidad
  tryCatch({
    matriz <- calc_env$construir_matriz_muestras(hom_data, pollutant, level)
    stats <- calc_env$calculate_homogeneity_stats(matriz)
    hom_ok <- is.null(stats$error) && is.finite(stats$ss) && is.finite(stats$sw)
    resultados <<- rbind(resultados, data.frame(
      test = "homogeneidad_estadisticos_validos",
      resultado = as.character(hom_ok),
      valor_esperado = "TRUE",
      status = ifelse(hom_ok, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    ))
  }, error = function(e) {
    resultados <<- rbind(resultados, data.frame(
      test = "homogeneidad_estadisticos_validos",
      resultado = paste("Error:", e$message),
      valor_esperado = "TRUE",
      status = "FAIL",
      stringsAsFactors = FALSE
    ))
  })
  
  # Test 3: Estabilidad
  tryCatch({
    matriz_hom <- calc_env$construir_matriz_muestras(hom_data, pollutant, level)
    hom_stats <- calc_env$calculate_homogeneity_stats(matriz_hom)
    matriz_stab <- calc_env$construir_matriz_muestras(stab_data, pollutant, level)
    stab_stats <- calc_env$calculate_stability_stats(matriz_stab, hom_stats$grand_mean)
    stab_ok <- is.null(stab_stats$error)
    resultados <<- rbind(resultados, data.frame(
      test = "estabilidad_evaluacion_valida",
      resultado = as.character(stab_ok),
      valor_esperado = "TRUE",
      status = ifelse(stab_ok, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    ))
  }, error = function(e) {
    resultados <<- rbind(resultados, data.frame(
      test = "estabilidad_evaluacion_valida",
      resultado = paste("Error:", e$message),
      valor_esperado = "TRUE",
      status = "FAIL",
      stringsAsFactors = FALSE
    ))
  })
  
  # Test 4: Valor asignado y puntajes
  tryCatch({
    valor <- calc_env$calculate_valor_asignado(summary_data, pollutant, level, metodo = "2a")
    tabla <- calc_env$calculate_scores_table(summary_data, k = 2)
    columnas_esperadas <- c("z_score", "z_prime_score", "zeta_score", "En_score")
    puntajes_ok <- is.null(valor$error) && is.finite(valor$x_pt) && 
                   nrow(tabla) > 0 && all(columnas_esperadas %in% names(tabla))
    resultados <<- rbind(resultados, data.frame(
      test = "valor_asignado_y_puntajes",
      resultado = as.character(puntajes_ok),
      valor_esperado = "TRUE",
      status = ifelse(puntajes_ok, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    ))
  }, error = function(e) {
    resultados <<- rbind(resultados, data.frame(
      test = "valor_asignado_y_puntajes",
      resultado = paste("Error:", e$message),
      valor_esperado = "TRUE",
      status = "FAIL",
      stringsAsFactors = FALSE
    ))
  })
  
  resultados
}

# Ejecutar y exportar resultados si se llama directamente
if (!interactive()) {
  cat("=== Ejecutando tests de Entregable 08 ===\n")
  resultados_08 <- generar_resultados_estructurados()
  print(resultados_08)
  assign("test_results", resultados_08, envir = .GlobalEnv)
}

