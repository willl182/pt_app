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

# Encontrar el directorio raíz del proyecto buscando app.R hacia arriba
project_root <- current_wd
while (project_root != "/" && !file.exists(file.path(project_root, "app.R")) && nchar(project_root) > 0) {
  project_root <- dirname(project_root)
}

if (file.exists(file.path(project_root, "app.R"))) {
  orig_dir <- project_root
  copy_dir <- file.path(project_root, "Entregables_pt_app", "01_repo_inicial")
} else {
  stop("No se pudo encontrar el directorio raíz del proyecto conteniendo app.R")
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
              info = "app_original.R debe existir en Entregables_pt_app/01")
  expect_true(file.exists(file.path(copy_dir, "R", "pt_homogeneity.R")),
              info = "pt_homogeneity.R debe existir en Entregables_pt_app/01")
  expect_true(file.exists(file.path(copy_dir, "R", "pt_robust_stats.R")),
              info = "pt_robust_stats.R debe existir en Entregables_pt_app/01")
  expect_true(file.exists(file.path(copy_dir, "R", "pt_scores.R")),
              info = "pt_scores.R debe existir en Entregables_pt_app/01")
  expect_true(file.exists(file.path(copy_dir, "R", "utils.R")),
              info = "utils.R debe existir en Entregables_pt_app/01")
})

test_that("Correspondencia de hash SHA256", {
  # Hashes esperados de la línea base original
  hashes_esperados <- list(
    "app_original.R" = "3dab2caa410ceed2fa12e0e4968428f8901d09d39fedcdc179edbfcb037905ee",
    "pt_homogeneity.R" = "b995de5ffdf2b4bb118cccfefbfe23b470505601a9a236be994fff2eb8ab217e",
    "pt_robust_stats.R" = "b0fe77110e4f72aaa744548c2e965edfc0aa10c2144acbe7d9d13a5726f2fdcf",
    "pt_scores.R" = "fbf7458475986d54a6e71a27df17ff6953d47ba90b98af32f6b9c9a919265cd6",
    "utils.R" = "77c49354652225d0793e592209496ba366da0dd8cb4707a9fa219cb0943d2b70"
  )
  
  # app_original.R
  hash_copia <- calcular_hash(file.path(copy_dir, "app_original.R"))
  expect_true(!is.na(hash_copia), info = "Hash de app_original.R debe ser calculable")
  expect_equal(hash_copia, hashes_esperados[["app_original.R"]],
               info = "Hash SHA256 de app_original.R debe coincidir con la línea base")
  
  # Funciones R
  archivos_r <- c("pt_homogeneity.R", "pt_robust_stats.R", "pt_scores.R", "utils.R")
  for (arch in archivos_r) {
    hash_copy <- calcular_hash(file.path(copy_dir, "R", arch))
    expect_equal(hash_copy, hashes_esperados[[arch]],
                 info = paste("Hash SHA256 de", arch, "debe coincidir con la línea base"))
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
  
  # Hashes esperados de la línea base original
  hashes_esperados <- list(
    "app_original.R" = "3dab2caa410ceed2fa12e0e4968428f8901d09d39fedcdc179edbfcb037905ee",
    "pt_homogeneity.R" = "b995de5ffdf2b4bb118cccfefbfe23b470505601a9a236be994fff2eb8ab217e",
    "pt_robust_stats.R" = "b0fe77110e4f72aaa744548c2e965edfc0aa10c2144acbe7d9d13a5726f2fdcf",
    "pt_scores.R" = "fbf7458475986d54a6e71a27df17ff6953d47ba90b98af32f6b9c9a919265cd6",
    "utils.R" = "77c49354652225d0793e592209496ba366da0dd8cb4707a9fa219cb0943d2b70"
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
  hash_copy_app <- calcular_hash(file.path(copy_dir, "app_original.R"))
  hash_esperado_app <- hashes_esperados[["app_original.R"]]
  resultados <- rbind(resultados, data.frame(
    test = "hash_app_R",
    resultado = hash_copy_app,
    valor_esperado = hash_esperado_app,
    status = ifelse(hash_copy_app == hash_esperado_app, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  archivos_r <- c("pt_homogeneity.R", "pt_robust_stats.R", "pt_scores.R", "utils.R")
  for (arch in archivos_r) {
    hash_copy <- calcular_hash(file.path(copy_dir, "R", arch))
    hash_esperado <- hashes_esperados[[arch]]
    
    resultados <- rbind(resultados, data.frame(
      test = paste0("hash_", gsub("\\.R$", "", arch)),
      resultado = hash_copy,
      valor_esperado = hash_esperado,
      status = ifelse(hash_copy == hash_esperado, "PASS", "FAIL"),
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
