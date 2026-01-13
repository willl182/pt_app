# ===================================================================
# Titulo: test_09_reproducibilidad.R
# Entregable: 09
# Descripcion: Prueba de reproducibilidad de calculos
# Entrada: R/genera_anexos.R y archivos CSV en data/
# Salida: Resultados estructurados (PASS/FAIL)
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 17043:2024
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
entregable_dir <- file.path(base_dir, "deliv", "09_informe_final")
script_path <- file.path(entregable_dir, "R", "genera_anexos.R")
output_dir <- file.path(entregable_dir, "R", "output")

# ===================================================================
# Tests con testthat
# ===================================================================

test_that("Script genera_anexos.R existe", {
  expect_true(file.exists(script_path))
})

test_that("Datos de entrada existen", {
  expect_true(file.exists(file.path(base_dir, "data", "homogeneity.csv")))
  expect_true(file.exists(file.path(base_dir, "data", "stability.csv")))
  expect_true(file.exists(file.path(base_dir, "data", "summary_n4.csv")))
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
  
  # Test 1: Script existe
  script_ok <- file.exists(script_path)
  resultados <- rbind(resultados, data.frame(
    test = "script_genera_anexos_existe",
    resultado = as.character(script_ok),
    valor_esperado = "TRUE",
    status = ifelse(script_ok, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  # Test 2: Datos de entrada existen
  datos_ok <- file.exists(file.path(base_dir, "data", "homogeneity.csv")) &&
              file.exists(file.path(base_dir, "data", "stability.csv")) &&
              file.exists(file.path(base_dir, "data", "summary_n4.csv"))
  resultados <- rbind(resultados, data.frame(
    test = "datos_entrada_existen",
    resultado = as.character(datos_ok),
    valor_esperado = "TRUE",
    status = ifelse(datos_ok, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  # Test 3: Reproducibilidad (dos ejecuciones producen mismo resultado)
  reproducible <- FALSE
  tryCatch({
    if (script_ok) {
      # Ejecutar el script directamente con Rscript para evitar problemas de rutas
      system2("Rscript", args = script_path, stdout = FALSE, stderr = FALSE)
      
      if (file.exists(file.path(output_dir, "homogeneidad_resumen.csv"))) {
        hom_1 <- read.csv(file.path(output_dir, "homogeneidad_resumen.csv"))
        
        # Segunda ejecucion
        system2("Rscript", args = script_path, stdout = FALSE, stderr = FALSE)
        hom_2 <- read.csv(file.path(output_dir, "homogeneidad_resumen.csv"))
        
        reproducible <- isTRUE(all.equal(hom_1, hom_2))
      }
    }
  }, error = function(e) {
    # Si hay error, reproducible queda FALSE
  })
  
  resultados <- rbind(resultados, data.frame(
    test = "reproducibilidad_calculos",
    resultado = as.character(reproducible),
    valor_esperado = "TRUE",
    status = ifelse(reproducible, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  # Test 4: Archivos de salida generados
  salidas_ok <- FALSE
  tryCatch({
    salidas_ok <- file.exists(file.path(output_dir, "homogeneidad_resumen.csv")) ||
                  file.exists(file.path(output_dir, "resumen_pruebas.csv"))
  }, error = function(e) {})
  
  resultados <- rbind(resultados, data.frame(
    test = "archivos_salida_generados",
    resultado = as.character(salidas_ok),
    valor_esperado = "TRUE",
    status = ifelse(salidas_ok, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  resultados
}

# Ejecutar y exportar resultados
if (!interactive()) {
  cat("=== Ejecutando tests de Entregable 09 ===\n")
  resultados_09 <- generar_resultados_estructurados()
  print(resultados_09)
  assign("test_results", resultados_09, envir = .GlobalEnv)
}
