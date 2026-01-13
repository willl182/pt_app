# ===================================================================
# Titulo: verifica_entregables.R
# Entregable: N/A (script global)
# Descripcion: Recorre deliv/ y ejecuta todos los tests
# Entrada: Todos los archivos en deliv/
# Salida: deliv/verificacion_global.log
# ===================================================================

library(testthat)

ruta_script <- sys.frame(1)$ofile
if (is.null(ruta_script)) {
  ruta_script <- "deliv/scripts/verifica_entregables.R"
}

ruta_script <- normalizePath(ruta_script, mustWork = FALSE)
carpeta_script <- dirname(ruta_script)
base_dir <- dirname(dirname(carpeta_script))
carpeta_deliv <- file.path(base_dir, "deliv")

obtener_entregables <- function(carpeta_deliv) {
  carpetas <- list.dirs(carpeta_deliv, full.names = TRUE, recursive = FALSE)
  entregables <- carpetas[grepl("^0[1-9]_", basename(carpetas))]
  entregables[order(entregables)]
}

formatear_test <- function(nombre_test, indice, total) {
  if (total > 1) {
    paste0(nombre_test, " (", indice, ")")
  } else {
    nombre_test
  }
}

resultado_sin_tests <- function(entregable_num) {
  data.frame(
    entregable = entregable_num,
    test = "sin_tests",
    resultado = "No hay archivos de test",
    valor_esperado = "Tests disponibles",
    status = "FAIL",
    stringsAsFactors = FALSE
  )
}

resultado_error <- function(entregable_num, mensaje) {
  data.frame(
    entregable = entregable_num,
    test = "error_ejecucion",
    resultado = mensaje,
    valor_esperado = "Ejecucion sin errores",
    status = "FAIL",
    stringsAsFactors = FALSE
  )
}

extraer_resultados <- function(entregable_num, reporter) {
  resumen <- reporter$get_results()
  resultados <- data.frame(
    entregable = character(),
    test = character(),
    resultado = character(),
    valor_esperado = character(),
    status = character(),
    stringsAsFactors = FALSE
  )

  if (length(resumen) == 0) {
    return(resultados)
  }

  for (bloque in resumen) {
    if (is.null(bloque$test) || is.na(bloque$test)) {
      next
    }
    if (length(bloque$results) == 0) {
      next
    }

    total_resultados <- length(bloque$results)
    for (i in seq_along(bloque$results)) {
      expectativa <- bloque$results[[i]]
      es_ok <- inherits(expectativa, "expectation_success")
      mensaje <- conditionMessage(expectativa)
      if (is.null(mensaje) || is.na(mensaje)) {
        mensaje <- "success"
      }

      resultados <- rbind(resultados, data.frame(
        entregable = entregable_num,
        test = formatear_test(bloque$test, i, total_resultados),
        resultado = mensaje,
        valor_esperado = "success",
        status = ifelse(es_ok, "PASS", "FAIL"),
        stringsAsFactors = FALSE
      ))
    }
  }

  resultados
}

ejecutar_tests_entregable <- function(carpeta_entregable) {
  entregable_num <- substr(basename(carpeta_entregable), 1, 2)
  carpeta_tests <- file.path(carpeta_entregable, "tests")

  if (!dir.exists(carpeta_tests)) {
    cat("Entregable ", entregable_num, ": carpeta tests no existe.\n", sep = "")
    return(resultado_sin_tests(entregable_num))
  }

  archivos_tests <- list.files(carpeta_tests, pattern = "^test_.*\\.R$", full.names = TRUE)
  if (length(archivos_tests) == 0) {
    cat("Entregable ", entregable_num, ": no hay archivos de test.\n", sep = "")
    return(resultado_sin_tests(entregable_num))
  }

  reporter <- testthat::ListReporter$new()
  mensaje_error <- NULL

  tryCatch({
    directorio_actual <- getwd()
    on.exit(setwd(directorio_actual), add = TRUE)
    setwd(base_dir)
    testthat::test_dir(carpeta_tests, reporter = reporter, stop_on_failure = FALSE, stop_on_error = FALSE)
  }, error = function(e) {
    mensaje_error <<- conditionMessage(e)
  })

  resultados <- extraer_resultados(entregable_num, reporter)
  if (!is.null(mensaje_error)) {
    resultados <- rbind(resultados, resultado_error(entregable_num, mensaje_error))
  }

  if (nrow(resultados) == 0) {
    resultados <- resultado_error(entregable_num, "No se generaron resultados de test")
  }

  resultados
}

cat("=== Verificacion global de entregables ===\n")

entregables <- obtener_entregables(carpeta_deliv)
resultados_globales <- data.frame(
  entregable = character(),
  test = character(),
  resultado = character(),
  valor_esperado = character(),
  status = character(),
  stringsAsFactors = FALSE
)

for (carpeta_entregable in entregables) {
  entregable_num <- substr(basename(carpeta_entregable), 1, 2)
  cat("Ejecutando tests del entregable ", entregable_num, "...\n", sep = "")
  resultados_globales <- rbind(resultados_globales, ejecutar_tests_entregable(carpeta_entregable))
}

ruta_log <- file.path(carpeta_deliv, "verificacion_global.log")
write.table(
  resultados_globales,
  file = ruta_log,
  sep = ",",
  row.names = FALSE,
  col.names = TRUE,
  quote = TRUE
)

total_tests <- nrow(resultados_globales)
pass_tests <- sum(resultados_globales$status == "PASS")
fail_tests <- sum(resultados_globales$status == "FAIL")

cat("=== Resumen global ===\n")
cat("Total de tests: ", total_tests, "\n", sep = "")
cat("PASS: ", pass_tests, "\n", sep = "")
cat("FAIL: ", fail_tests, "\n", sep = "")
cat("Log guardado en: ", ruta_log, "\n", sep = "")
