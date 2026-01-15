# ===================================================================
# Titulo: test_04_puntajes.R
# Entregable: 04
# Descripcion: Tests para funciones de calculo de puntajes ISO 13528
# Entrada: calcula_puntajes.R y test_04_puntajes.csv
# Salida: Resultados de testthat (PASS/FAIL)
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022 §10.2-10.5
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
carpeta_entregable <- file.path(base_dir, "deliv", "04_puntajes")
carpeta_tests <- file.path(carpeta_entregable, "tests")
ruta_funciones <- file.path(carpeta_entregable, "R", "calcula_puntajes.R")

test_that("Archivo de funciones existe", {
  expect_true(file.exists(ruta_funciones))
})

calc_env <- new.env()
expresiones <- parse(file = ruta_funciones)
for (expresion in expresiones) {
  eval(expresion, envir = calc_env)
}

datos_prueba <- read.csv(
  file.path(carpeta_tests, "test_04_puntajes.csv"),
  stringsAsFactors = FALSE
)

test_that("Calculo de puntajes coincide con valores esperados", {
  for (i in seq_len(nrow(datos_prueba))) {
    fila <- datos_prueba[i, ]

    z <- calc_env$calculate_z_score(fila$x, fila$x_pt, fila$sigma_pt)
    z_prime <- calc_env$calculate_z_prime_score(fila$x, fila$x_pt, fila$sigma_pt, fila$u_xpt)
    zeta <- calc_env$calculate_zeta_score(fila$x, fila$x_pt, fila$u_x, fila$u_xpt)
    en <- calc_env$calculate_en_score(fila$x, fila$x_pt, fila$U_x, fila$U_xpt)

    expect_equal(z, fila$z_expected, tolerance = 1e-6)
    expect_equal(z_prime, fila$z_prime_expected, tolerance = 1e-6)
    expect_equal(zeta, fila$zeta_expected, tolerance = 1e-6)
    expect_equal(en, fila$en_expected, tolerance = 1e-6)

    expect_equal(calc_env$evaluate_z_score(z), fila$z_eval_expected)
    expect_equal(calc_env$evaluate_z_score(z_prime), fila$z_prime_eval_expected)
    expect_equal(calc_env$evaluate_z_score(zeta), fila$zeta_eval_expected)
    expect_equal(calc_env$evaluate_en_score(en), fila$en_eval_expected)
  }
})

test_that("calculate_scores_table devuelve tabla valida", {
  datos_demo <- data.frame(
    pollutant = "co",
    level = "1-umol/mol",
    participant_id = c("ref", "part_1"),
    sample_group = c("1-10", "1-10"),
    mean_value = c(10.0, 10.5),
    sd_value = c(0.2, 0.3),
    stringsAsFactors = FALSE
  )

  tabla <- calc_env$calculate_scores_table(datos_demo, m = 1, k = 2)

  expect_equal(nrow(tabla), 2)
  columnas_esperadas <- c(
    "x_pt", "sigma_pt", "u_xpt", "u_x", "U_x", "U_xpt",
    "z_score", "z_eval", "z_prime_score", "z_prime_eval",
    "zeta_score", "zeta_eval", "En_score", "En_eval"
  )
  expect_true(all(columnas_esperadas %in% names(tabla)))
})

if (!interactive()) {
  test_dir(dirname(sys.frame(1)$ofile))
}
