# ===================================================================
# Titulo: test_01_existencia_archivos.R
# Entregable: 01
# Descripcion: Test testthat que verifica la existencia de archivos
#              fuente, correspondencia SHA256 entre original y copia,
#              y validacion basica de sintaxis R.
# Entrada: Archivos en pt_app/R/, pt_app/app.R y deliv/01_repo_inicial/
# Salida: Resultados de test (PASS/FAIL) en formato testthat
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022
# ===================================================================

library(testthat)

# Directorio base del proyecto - detectar desde multiples fuentes
detectar_base_dir <- function() {
  # Intentar desde el directorio de trabajo actual
  candidatos <- c(
    getwd(),
    Sys.getenv("PT_APP_DIR"),
    "/home/w182/w421/pt_app"
  )
  
  for (candidato in candidatos) {
    if (nchar(candidato) > 0 && dir.exists(file.path(candidato, "R"))) {
      return(candidato)
    }
    # Buscar hacia arriba si estamos en deliv/
    if (grepl("deliv", candidato)) {
      partes <- strsplit(candidato, "deliv")[[1]][1]
      partes <- sub("/$", "", partes)
      if (dir.exists(file.path(partes, "R"))) {
        return(partes)
      }
    }
  }
  
  # Fallback: buscar pt_app en el path actual
  wd <- getwd()
  if (grepl("pt_app", wd)) {
    base <- sub("/deliv.*", "", wd)
    if (dir.exists(file.path(base, "R"))) {
      return(base)
    }
  }
  
  return("/home/w182/w421/pt_app")
}

base_dir <- detectar_base_dir()
carpeta_entregable <- file.path(base_dir, "deliv", "01_repo_inicial")

original_dir <- file.path(base_dir, "R")
copy_dir <- file.path(carpeta_entregable, "R")

# Lista de archivos esperados
archivos_esperados <- c(

"pt_homogeneity.R",
"pt_robust_stats.R",
"pt_scores.R",
"utils.R"
)

# ===================================================================
# Test 1: Verificar existencia de archivos originales
# ===================================================================
test_that("Archivos originales existen en pt_app/R/", {
for (archivo in archivos_esperados) {
  ruta_original <- file.path(original_dir, archivo)
  expect_true(
    file.exists(ruta_original),
    info = paste("Archivo original no encontrado:", archivo)
  )
}
})

# ===================================================================
# Test 2: Verificar existencia de copias en el entregable
# ===================================================================
test_that("Copias existen en deliv/01_repo_inicial/R/", {
for (archivo in archivos_esperados) {
  ruta_copia <- file.path(copy_dir, archivo)
  expect_true(
    file.exists(ruta_copia),
    info = paste("Copia no encontrada:", archivo)
  )
}
})

# ===================================================================
# Test 3: Verificar correspondencia SHA256 entre original y copia
# ===================================================================
test_that("Hash SHA256 coincide entre originales y copias", {
for (archivo in archivos_esperados) {
  ruta_original <- file.path(original_dir, archivo)
  ruta_copia <- file.path(copy_dir, archivo)
  
  if (file.exists(ruta_original) && file.exists(ruta_copia)) {
    hash_original <- digest::digest(file = ruta_original, algo = "sha256")
    hash_copia <- digest::digest(file = ruta_copia, algo = "sha256")
    
    expect_equal(
      hash_original,
      hash_copia,
      info = paste("Hash no coincide para:", archivo)
    )
  }
}
})

# ===================================================================
# Test 4: Verificar existencia de app_original.R
# ===================================================================
test_that("app_original.R existe en el entregable", {
 ruta_app <- file.path(carpeta_entregable, "app_original.R")
 expect_true(
   file.exists(ruta_app),
   info = "app_original.R no encontrado"
 )
})

# ===================================================================
# Test 4b: Verificar existencia de archivos de datos
# ===================================================================
archivos_data <- c(
  "homogeneity.csv",
  "stability.csv",
  "summary_n4.csv",
  "participants_data4.csv"
)

test_that("Archivos de datos existen en deliv/01_repo_inicial/data/", {
  for (archivo in archivos_data) {
    ruta_data <- file.path(carpeta_entregable, "data", archivo)
    expect_true(
      file.exists(ruta_data),
      info = paste("Archivo de datos no encontrado:", archivo)
    )
  }
})

# ===================================================================
# Test 4c: Verificar correspondencia SHA256 de archivos de datos
# ===================================================================
test_that("Hash SHA256 coincide para archivos de datos", {
  for (archivo in archivos_data) {
    ruta_original <- file.path(base_dir, "data", archivo)
    ruta_copia <- file.path(carpeta_entregable, "data", archivo)
    
    if (file.exists(ruta_original) && file.exists(ruta_copia)) {
      hash_original <- digest::digest(file = ruta_original, algo = "sha256")
      hash_copia <- digest::digest(file = ruta_copia, algo = "sha256")
      
      expect_equal(
        hash_original,
        hash_copia,
        info = paste("Hash no coincide para datos:", archivo)
      )
    }
  }
})

# ===================================================================
# Test 4d: Verificar existencia de template de reportes
# ===================================================================
test_that("Template de reportes existe", {
  ruta_template <- file.path(carpeta_entregable, "reports", "report_template.Rmd")
  expect_true(
    file.exists(ruta_template),
    info = "report_template.Rmd no encontrado"
  )
})

test_that("Hash SHA256 coincide para template de reportes", {
  ruta_original <- file.path(base_dir, "reports", "report_template.Rmd")
  ruta_copia <- file.path(carpeta_entregable, "reports", "report_template.Rmd")
  
  if (file.exists(ruta_original) && file.exists(ruta_copia)) {
    hash_original <- digest::digest(file = ruta_original, algo = "sha256")
    hash_copia <- digest::digest(file = ruta_copia, algo = "sha256")
    
    expect_equal(
      hash_original,
      hash_copia,
      info = "Hash no coincide para report_template.Rmd"
    )
  }
})

# ===================================================================
# Test 4e: Verificar existencia del paquete ptcalc
# ===================================================================
test_that("Paquete ptcalc existe con estructura completa", {
  ptcalc_dir <- file.path(carpeta_entregable, "ptcalc")
  expect_true(dir.exists(ptcalc_dir), info = "Directorio ptcalc no encontrado")
  expect_true(file.exists(file.path(ptcalc_dir, "DESCRIPTION")), info = "DESCRIPTION no encontrado")
  expect_true(file.exists(file.path(ptcalc_dir, "NAMESPACE")), info = "NAMESPACE no encontrado")
  expect_true(dir.exists(file.path(ptcalc_dir, "R")), info = "ptcalc/R no encontrado")
  expect_true(dir.exists(file.path(ptcalc_dir, "man")), info = "ptcalc/man no encontrado")
})

test_that("Archivos R del paquete ptcalc existen", {
  ptcalc_r_dir <- file.path(carpeta_entregable, "ptcalc", "R")
  archivos_ptcalc <- c("pt_homogeneity.R", "pt_robust_stats.R", "pt_scores.R")
  
  for (archivo in archivos_ptcalc) {
    expect_true(
      file.exists(file.path(ptcalc_r_dir, archivo)),
      info = paste("Archivo ptcalc no encontrado:", archivo)
    )
  }
})


# ===================================================================
# Test 5: Validar sintaxis R basica (parentesis y llaves balanceados)
# ===================================================================
validar_sintaxis_basica <- function(archivo) {
contenido <- readLines(archivo, warn = FALSE)
texto <- paste(contenido, collapse = "\n")

# Contar parentesis
abre_paren <- sum(gregexpr("\\(", texto)[[1]] > 0)
cierra_paren <- sum(gregexpr("\\)", texto)[[1]] > 0)

# Contar llaves
abre_llave <- sum(gregexpr("\\{", texto)[[1]] > 0)
cierra_llave <- sum(gregexpr("\\}", texto)[[1]] > 0)

# Contar corchetes
abre_corchete <- sum(gregexpr("\\[", texto)[[1]] > 0)
cierra_corchete <- sum(gregexpr("\\]", texto)[[1]] > 0)

list(
  parentesis_ok = abre_paren == cierra_paren,
  llaves_ok = abre_llave == cierra_llave,
  corchetes_ok = abre_corchete == cierra_corchete
)
}

test_that("Sintaxis R basica es valida en archivos copiados", {
for (archivo in archivos_esperados) {
  ruta_copia <- file.path(copy_dir, archivo)
  
  if (file.exists(ruta_copia)) {
    resultado <- validar_sintaxis_basica(ruta_copia)
    
    expect_true(
      resultado$parentesis_ok,
      info = paste("Parentesis desbalanceados en:", archivo)
    )
    expect_true(
      resultado$llaves_ok,
      info = paste("Llaves desbalanceadas en:", archivo)
    )
    expect_true(
      resultado$corchetes_ok,
      info = paste("Corchetes desbalanceados en:", archivo)
    )
  }
}
})

# ===================================================================
# Generar reporte de resultados
# ===================================================================
generar_reporte <- function() {
resultados <- data.frame(
  test = character(),
  resultado = character(),
  valor_esperado = character(),
  status = character(),
  stringsAsFactors = FALSE
)

for (archivo in archivos_esperados) {
  ruta_original <- file.path(original_dir, archivo)
  ruta_copia <- file.path(copy_dir, archivo)
  
  # Test existencia original
  existe_orig <- file.exists(ruta_original)
  resultados <- rbind(resultados, data.frame(
    test = paste0("existe_original_", archivo),
    resultado = as.character(existe_orig),
    valor_esperado = "TRUE",
    status = ifelse(existe_orig, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
  
  # Test existencia copia
  existe_copia <- file.exists(ruta_copia)
  resultados <- rbind(resultados, data.frame(
    test = paste0("existe_copia_", archivo),
    resultado = as.character(existe_copia),
    valor_esperado = "TRUE",
    status = ifelse(existe_copia, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  ))
}

resultados
}

# Ejecutar si se llama directamente
if (!interactive()) {
cat("=== Ejecutando tests de Entregable 01 ===\n")
test_dir(dirname(sys.frame(1)$ofile))
}
