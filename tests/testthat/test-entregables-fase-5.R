phase5_root <- normalizePath(file.path(testthat::test_path(), "../.."))

phase5_sources <- c(
  "05_prototipo_ui/md/wireframes.md",
  "06_app_logica/md/manual_usuario.md",
  "07_dashboards/md/documentacion_dashboards.md",
  "08_beta/md/manual_desarrollador.md"
)

read_deliverable <- function(path) {
  paste(readLines(file.path(
    phase5_root, "Entregables_pt_app", path
  ), warn = FALSE), collapse = "\n")
}

testthat::test_that("E05-E08 identify current and historical authorities", {
  texts <- vapply(phase5_sources, read_deliverable, character(1))
  testthat::expect_true(all(grepl("app.R", texts, fixed = TRUE)))
  testthat::expect_match(texts[[1]], "ocho módulos", fixed = TRUE)
  testthat::expect_match(texts[[1]], "antecedentes", fixed = TRUE)
  testthat::expect_match(texts[[4]], "no deben desplegarse", fixed = TRUE)
})

testthat::test_that("E05-E08 have coherent controlled-document status", {
  texts <- vapply(phase5_sources, read_deliverable, character(1))
  testthat::expect_true(all(grepl(
    'status: "Vigente verificado"', texts, fixed = TRUE
  )))
  testthat::expect_true(all(grepl(
    "aprobación contractual pendiente", texts, fixed = TRUE
  )))
  testthat::expect_match(
    texts[[1]], "html/recorrido_interfaz.html", fixed = TRUE
  )
})

testthat::test_that("documented navigation and dependencies exist in app.R", {
  app_text <- paste(readLines(
    file.path(phase5_root, "app.R"), warn = FALSE
  ), collapse = "\n")
  modules <- c(
    "Carga de datos", "Análisis de homogeneidad y estabilidad",
    "Valores Atípicos", "Valor asignado", "Puntajes EA",
    "Informe global", "Participantes", "Generación de informes"
  )
  dependencies <- c(
    "shiny", "tidyverse", "vroom", "DT", "rhandsontable",
    "shinythemes", "outliers", "patchwork", "bsplus", "plotly",
    "rmarkdown", "bslib"
  )
  testthat::expect_true(all(vapply(
    modules, grepl, logical(1), x = app_text, fixed = TRUE
  )))
  testthat::expect_true(all(vapply(
    paste0("library(", dependencies, ")"),
    grepl, logical(1), x = app_text, fixed = TRUE
  )))
})

testthat::test_that("E06 covers the complete citizen workflow", {
  text <- read_deliverable(phase5_sources[[2]])
  required <- c(
    "Preparación de archivos", "Preprocesador de datos", "Homogeneidad",
    "Valores Atípicos", "Valor asignado", "Puntajes EA",
    "Informe global", "Participantes", "Generación de informes",
    "Problemas frecuentes"
  )
  testthat::expect_true(all(vapply(
    required, grepl, logical(1), x = text, fixed = TRUE
  )))
})

testthat::test_that("E07 explains all current dashboard groups", {
  text <- read_deliverable(phase5_sources[[3]])
  required <- c(
    "Homogeneidad", "Estabilidad", "Atípicos", "Algoritmo A",
    "Consenso/compatibilidad", "Puntajes", "Informe global", "Participantes"
  )
  testthat::expect_true(all(vapply(
    required, grepl, logical(1), x = text, fixed = TRUE
  )))
})

testthat::test_that("E08 documents operations, security and recovery", {
  text <- read_deliverable(phase5_sources[[4]])
  required <- c(
    "Arquitectura", "Instalación y ejecución", "Despliegue",
    "Seguridad y datos", "respaldo y recuperación", "Diagnóstico",
    "Límites y riesgos conocidos", "sessionInfo()", "renv.lock"
  )
  testthat::expect_true(all(vapply(
    required, grepl, logical(1), x = text, fixed = TRUE
  )))
})

testthat::test_that("Phase 5 sources reference existing visual evidence", {
  texts <- vapply(phase5_sources, read_deliverable, character(1))
  references <- unlist(regmatches(
    texts, gregexpr("[.][.]/[.][.]/00_evidencia_visual/capturas/[^)]+[.]png", texts)
  ))
  testthat::expect_gte(length(references), 10L)
  paths <- file.path(
    phase5_root, "Entregables_pt_app",
    sub("^[.][.]/[.][.]/", "", references)
  )
  testthat::expect_true(all(file.exists(paths)))
})

testthat::test_that("Phase 5 derived documents and manifest are valid", {
  manifest_path <- file.path(
    phase5_root,
    "Entregables_pt_app/00_control_documental/derivados/manifiesto_fase_5.csv"
  )
  testthat::expect_true(file.exists(manifest_path))
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
  testthat::expect_equal(nrow(manifest), 5L)
  testthat::expect_true(all(file.exists(file.path(phase5_root, manifest$archivo))))
  sha256_file <- function(path) {
    output <- system2("sha256sum", path, stdout = TRUE)
    strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
  }
  testthat::expect_identical(
    manifest$sha256_fuente,
    unname(vapply(file.path(phase5_root, manifest$fuente), sha256_file, character(1)))
  )
  testthat::expect_identical(
    manifest$sha256_salida,
    unname(vapply(file.path(phase5_root, manifest$archivo), sha256_file, character(1)))
  )
})
