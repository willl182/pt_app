# ===================================================================
# Titulo: test_01_existencia_archivos.R
# Entregable: 01
# Descripcion: Verifica existencia e integridad de archivos originales
# Entrada: pt_app/app.R, pt_app/R/*.R
# Salida: data.frame con resultados de verificacion
# Referencia: N/A
# ===================================================================

library(testthat)
library(digest)

# Directorios
# Detectar directorio base del proyecto (buscando app.R)
current_wd <- getwd()

# Si estamos en el directorio de tests, navegar al raíz del proyecto
if (grepl("tests", current_wd)) {
  # Navegar hacia arriba hasta encontrar el directorio raíz del proyecto
  while (grepl("tests", current_wd) && current_wd != "/" && nchar(current_wd) > 0) {
    current_wd <- dirname(current_wd)
  }
}

# Establecer directorios base
if (file.exists(file.path(current_wd, "app.R"))) {
  orig_dir <- current_wd
  copy_dir <- file.path(current_wd, "deliv", "01_repo_inicial")
} else {
  # Fallback: intentar encontrar desde el directorio actual
  if (file.exists("app.R")) {
    orig_dir <- "."
    copy_dir <- "deliv/01_repo_inicial"
  } else if (file.exists("deliv/01_repo_inicial/app_original.R")) {
    orig_dir <- ".."
    copy_dir <- "deliv/01_repo_inicial"
  } else {
    stop("No se pudo encontrar el directorio raíz del proyecto")
  }
}

# Funciones auxiliares
calcular_hash <- function(archivo) {
  if (!file.exists(archivo)) {
    return(NA_character_)
  }
  digest::digest(file = archivo, algo = "sha256")
}

verificar_sintaxis_r <- function(archivo) {
  tryCatch({
    parse(file = archivo)
    TRUE
  }, error = function(e) {
    FALSE
  })
}

# Test suite
context("Entregable 01 - Verificación de Archivos Originales")

test_that("Existencia de archivos originales", {
  expect_true(file.exists(file.path(orig_dir, "app.R")),
              info = "app.R debe existir en el directorio original")
  expect_true(file.exists(file.path(orig_dir, "R", "pt_homogeneity.R")),
              info = "pt_homogeneity.R debe existir")
  expect_true(file.exists(file.path(orig_dir, "R", "pt_robust_stats.R")),
              info = "pt_robust_stats.R debe existir")
  expect_true(file.exists(file.path(orig_dir, "R", "pt_scores.R")),
              info = "pt_scores.R debe existir")
  expect_true(file.exists(file.path(orig_dir, "R", "utils.R")),
              info = "utils.R debe existir")
})

test_that("Existencia de archivos copiados", {
  expect_true(file.exists(file.path(copy_dir, "app_original.R")),
              info = "app_original.R debe existir en deliv/01")
  expect_true(file.exists(file.path(copy_dir, "R", "pt_homogeneity.R")),
              info = "pt_homogeneity.R debe existir en deliv/01")
  expect_true(file.exists(file.path(copy_dir, "R", "pt_robust_stats.R")),
              info = "pt_robust_stats.R debe existir en deliv/01")
  expect_true(file.exists(file.path(copy_dir, "R", "pt_scores.R")),
              info = "pt_scores.R debe existir en deliv/01")
  expect_true(file.exists(file.path(copy_dir, "R", "utils.R")),
              info = "utils.R debe existir en deliv/01")
})

test_that("Correspondencia de hash SHA256", {
  # app.R vs app_original.R
  hash_original <- calcular_hash(file.path(orig_dir, "app.R"))
  hash_copia <- calcular_hash(file.path(copy_dir, "app_original.R"))
  
  expect_true(!is.na(hash_original), info = "Hash de app.R debe ser calculable")
  expect_true(!is.na(hash_copia), info = "Hash de app_original.R debe ser calculable")
  expect_equal(hash_original, hash_copia,
               info = "Hash SHA256 de app.R y app_original.R deben coincidir")
  
  # Funciones R
  archivos_r <- c("pt_homogeneity.R", "pt_robust_stats.R", "pt_scores.R", "utils.R")
  for (arch in archivos_r) {
    hash_orig <- calcular_hash(file.path(orig_dir, "R", arch))
    hash_copy <- calcular_hash(file.path(copy_dir, "R", arch))
    
    expect_equal(hash_orig, hash_copy,
                 info = paste("Hash SHA256 de", arch, "debe coincidir"))
  }
})

test_that("Validación de sintaxis R", {
  # app_original.R
  sintaxis_app <- verificar_sintaxis_r(file.path(copy_dir, "app_original.R"))
  expect_true(sintaxis_app, info = "app_original.R debe tener sintaxis R válida")
  
  # Funciones R
  archivos_r <- c("pt_homogeneity.R", "pt_robust_stats.R", "pt_scores.R", "utils.R")
  for (arch in archivos_r) {
    ruta_arch <- file.path(copy_dir, "R", arch)
    sintaxis <- verificar_sintaxis_r(ruta_arch)
    expect_true(sintaxis,
                info = paste(arch, "debe tener sintaxis R válida"))
  }
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
  
  # Tests de existencia
  orig_files <- c("app.R",
                  "R/pt_homogeneity.R",
                  "R/pt_robust_stats.R",
                  "R/pt_scores.R",
                  "R/utils.R")
  
  for (f in orig_files) {
    existe <- file.exists(file.path(orig_dir, f))
    resultados <- rbind(resultados, data.frame(
      test = paste0("existencia_orig_", gsub("[/.]", "_", f)),
      resultado = as.character(existe),
      valor_esperado = "TRUE",
      status = ifelse(existe, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    ))
  }
  
  # Tests de hash
  hash_orig_app <- calcular_hash(file.path(orig_dir, "app.R"))
  hash_copy_app <- calcular_hash(file.path(copy_dir, "app_original.R"))
  resultados <- rbind(resultados, data.frame(
    test = "hash_app_R",
    resultado = hash_copy_app,
    valor_esperado = hash_orig_app,
    status = ifelse(hash_orig_app == hash_copy_app, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  archivos_r <- c("pt_homogeneity.R", "pt_robust_stats.R", "pt_scores.R", "utils.R")
  for (arch in archivos_r) {
    hash_orig <- calcular_hash(file.path(orig_dir, "R", arch))
    hash_copy <- calcular_hash(file.path(copy_dir, "R", arch))
    
    resultados <- rbind(resultados, data.frame(
      test = paste0("hash_", gsub("\\.R$", "", arch)),
      resultado = hash_copy,
      valor_esperado = hash_orig,
      status = ifelse(hash_orig == hash_copy, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    ))
  }
  
  # Tests de sintaxis
  sintaxis_app <- verificar_sintaxis_r(file.path(copy_dir, "app_original.R"))
  resultados <- rbind(resultados, data.frame(
    test = "sintaxis_app_original",
    resultado = as.character(sintaxis_app),
    valor_esperado = "TRUE",
    status = ifelse(sintaxis_app, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  for (arch in archivos_r) {
    ruta_arch <- file.path(copy_dir, "R", arch)
    sintaxis <- verificar_sintaxis_r(ruta_arch)
    
    resultados <- rbind(resultados, data.frame(
      test = paste0("sintaxis_", gsub("\\.R$", "", arch)),
      resultado = as.character(sintaxis),
      valor_esperado = "TRUE",
      status = ifelse(sintaxis, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    ))
  }
  
  return(resultados)
}

# Ejecutar y guardar reporte
cat("=== EJECUTANDO TESTS ENTREGABLE 01 ===\n\n")
resultados <- generar_reporte()
print(resultados)

# Guardar CSV
ruta_csv <- file.path(copy_dir, "test_01_resultados.csv")
cat("\nGuardando resultados en:", ruta_csv, "\n")
write.csv(resultados, ruta_csv, row.names = FALSE)
cat("\nResultados guardados correctamente.\n")

# Resumen
cat("\n=== RESUMEN ===\n")
cat("Total tests:", nrow(resultados), "\n")
cat("PASS:", sum(resultados$status == "PASS"), "\n")
cat("FAIL:", sum(resultados$status == "FAIL"), "\n")
