# ==============================================================================
# Archivo: test_05_navegacion.R
# Propósito: Tests para validar el prototipo de UI de Shiny
# Autor: Sisyphus Agent
# Fecha: 2026-01-11
# ==============================================================================

library(testthat)

test_that("El archivo de prototipo UI existe y tiene contenido", {
  ruta_ui <- file.path(
    "/home/w182/w421/pt_app/deliv/05_prototipo_ui/R",
    "prototipo_ui.R"
  )

  expect_true(file.exists(ruta_ui))

  contenido <- readLines(ruta_ui, warn = FALSE)
  contenido_texto <- paste(contenido, collapse = " ")

  # Verificar que es código R de Shiny
  expect_true(grepl("library\\(shiny\\)", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("ui\\s*<-\\s*fluidPage", contenido_texto))
  expect_true(grepl("titlePanel", contenido_texto))
})

test_that("El prototipo UI contiene los módulos principales", {
  ruta_ui <- file.path(
    "/home/w182/w421/pt_app/deliv/05_prototipo_ui/R",
    "prototipo_ui.R"
  )

  contenido <- readLines(ruta_ui, warn = FALSE)
  contenido_texto <- paste(contenido, collapse = " ")

  # Verificar módulos principales de la UI
  expect_true(grepl("Carga de datos", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("Análisis de homogeneidad y estabilidad", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("Valores Atípicos", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("Valor asignado", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("Puntajes PT", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("Informe global", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("Participantes", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("Generación de informes", contenido_texto, ignore.case = TRUE))
})

test_that("El prototipo UI incluye los elementos de Shiny apropiados", {
  ruta_ui <- file.path(
    "/home/w182/w421/pt_app/deliv/05_prototipo_ui/R",
    "prototipo_ui.R"
  )

  contenido <- readLines(ruta_ui, warn = FALSE)
  contenido_texto <- paste(contenido, collapse = " ")

  # Verificar elementos de Shiny UI
  expect_true(grepl("fileInput", contenido_texto))
  expect_true(grepl("actionButton", contenido_texto))
  expect_true(grepl("selectInput", contenido_texto))
  expect_true(grepl("numericInput", contenido_texto))
  expect_true(grepl("dataTableOutput", contenido_texto))
  expect_true(grepl("plotlyOutput", contenido_texto))
  expect_true(grepl("tabsetPanel|navlistPanel", contenido_texto))
})

test_that("El prototipo UI usa los contaminantes correctos", {
  ruta_ui <- file.path(
    "/home/w182/w421/pt_app/deliv/05_prototipo_ui/R",
    "prototipo_ui.R"
  )

  contenido <- readLines(ruta_ui, warn = FALSE)
  contenido_texto <- paste(contenido, collapse = " ")

  # Verificar que se mencionan los contaminantes correctos (gases atmosféricos)
  expect_true(grepl("co", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("no", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("no2", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("o3", contenido_texto, ignore.case = TRUE))
  expect_true(grepl("so2", contenido_texto, ignore.case = TRUE))

  # Verificar que NO se mencionan contaminantes incorrectos (metales)
  expect_false(grepl("plomo|cadmio|mercurio", contenido_texto, ignore.case = TRUE))
})

test_that("El archivo wireframes.md existe y tiene contenido", {
  ruta_md <- file.path(
    "/home/w182/w421/pt_app/deliv/05_prototipo_ui/md",
    "wireframes.md"
  )

  expect_true(file.exists(ruta_md))

  contenido <- readLines(ruta_md, warn = FALSE)
  contenido_texto <- paste(contenido, collapse = " ")

  # Verificar secciones principales en wireframes
  expect_true(grepl("## 1. Carga de datos", contenido_texto))
  expect_true(grepl("## 2. Análisis de homogeneidad y estabilidad", contenido_texto))
  expect_true(grepl("## 3. Valores atípicos", contenido_texto))
  expect_true(grepl("## 4. Valor asignado", contenido_texto))
  expect_true(grepl("## 5. Puntajes PT", contenido_texto))
  expect_true(grepl("## 6. Informe global", contenido_texto))
  expect_true(grepl("## 7. Participantes", contenido_texto))
  expect_true(grepl("## 8. Generación de informes", contenido_texto))
})

test_that("El prototipo UI sigue el estilo de app.R", {
  ruta_ui <- file.path(
    "/home/w182/w421/pt_app/deliv/05_prototipo_ui/R",
    "prototipo_ui.R"
  )

  ruta_app <- file.path(
    "/home/w182/w421/pt_app",
    "app.R"
  )

  contenido_ui <- readLines(ruta_ui, warn = FALSE)
  contenido_app <- readLines(ruta_app, warn = FALSE)

  contenido_ui_texto <- paste(contenido_ui, collapse = " ")
  contenido_app_texto <- paste(contenido_app, collapse = " ")

  # Verificar que comparten elementos clave
  expect_true(grepl("bs_theme", contenido_ui_texto))
  expect_true(grepl("primary.*#FDB913", contenido_ui_texto))
  expect_true(grepl("Gases Contaminantes Criterio", contenido_ui_texto))
  expect_true(grepl("Laboratorio Calaire", contenido_ui_texto))
})
