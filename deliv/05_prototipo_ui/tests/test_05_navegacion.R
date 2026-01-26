# ===================================================================
# Titulo: test_05_navegacion.R
# Entregable: 05 - Prototipo estático de interfaz
# Descripcion: Tests para verificar la estructura y navegacion del HTML
# Entrada: deliv/05_prototipo_ui/html/prototipo.html
# Salida: Resultados de test
# Autor: Sistema
# Fecha: 2026-01-24
# ===================================================================

test_that("archivo HTML existe", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  expect_true(file.exists(html_file), 
              info = "El archivo prototipo.html debe existir")
})

test_that("archivo HTML tiene estructura basica valida", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl("<!DOCTYPE html>", html_text, ignore.case = TRUE),
              info = "Debe tener DOCTYPE HTML5")
  
  expect_true(grepl("<html", html_text, ignore.case = TRUE),
              info = "Debe tener etiqueta html")
  
  expect_true(grepl("<head>", html_text, ignore.case = TRUE),
              info = "Debe tener etiqueta head")
  
  expect_true(grepl("<body>", html_text, ignore.case = TRUE),
              info = "Debe tener etiqueta body")
  
  expect_true(grepl("</html>", html_text, ignore.case = TRUE),
              info = "Debe cerrar etiqueta html")
})

test_that("HTML tiene barra lateral con todos los modulos", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  modulos_esperados <- c(
    "Inicio",
    "Carga de Datos",
    "Homogeneidad/Estabilidad",
    "Valores Atípicos",
    "Valor Asignado",
    "Puntajes PT",
    "Informe Global",
    "Participantes",
    "Generación de Informes",
    "Configuración",
    "Ayuda"
  )
  
  for (modulo in modulos_esperados) {
    expect_true(grepl(modulo, html_text, fixed = TRUE),
                info = paste("El modulo", modulo, "debe existir en el menu lateral"))
  }
})

test_that("HTML tiene todos los modulos principales como secciones", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  ids_modulos_esperados <- c(
    "home",
    "carga-datos",
    "homogeneidad",
    "outliers",
    "valor-asignado",
    "puntajes",
    "informe-global",
    "participantes",
    "generacion-informes",
    "configuracion",
    "ayuda"
  )
  
  for (id_modulo in ids_modulos_esperados) {
    expect_true(grepl(paste0('id="', id_modulo, '"'), html_text),
                info = paste("El modulo con id", id_modulo, "debe existir"))
  }
})

test_that("modulo Carga de Datos tiene estructura correcta", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl("homogeneity\\.csv", html_text),
              info = "Debe mencionar archivo homogeneity.csv")
  
  expect_true(grepl("stability\\.csv", html_text),
              info = "Debe mencionar archivo stability.csv")
  
  expect_true(grepl("summary_n4\\.csv", html_text),
              info = "Debe mencionar archivo summary_n4.csv")
  
  expect_true(grepl("participants_data4\\.csv", html_text),
              info = "Debe mencionar archivo participants_data4.csv")
})

test_that("HTML tiene elementos UI esperados", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl('<table', html_text, ignore.case = TRUE),
              info = "Debe tener tablas")
  
  expect_true(grepl('<button', html_text, ignore.case = TRUE),
              info = "Debe tener botones")
  
  expect_true(grepl('<select', html_text, ignore.case = TRUE),
              info = "Debe tener select boxes")
  
  expect_true(grepl('<input', html_text, ignore.case = TRUE),
              info = "Debe tener inputs")
  
  expect_true(grepl('class="badge', html_text),
              info = "Debe tener badges")
})

test_that("HTML tiene estilos CSS en linea", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl('<style>', html_text, ignore.case = TRUE),
              info = "Debe tener tag style")
  
  expect_true(grepl('\\.sidebar', html_text),
              info = "Debe tener estilos para sidebar")
  
  expect_true(grepl('\\.content', html_text),
              info = "Debe tener estilos para content")
  
  expect_true(grepl('\\.card', html_text),
              info = "Debe tener estilos para card")
  
  expect_true(grepl('\\.table', html_text),
              info = "Debe tener estilos para table")
})

test_that("HTML tiene JavaScript para navegacion", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl('<script>', html_text, ignore.case = TRUE),
              info = "Debe tener tag script")
  
  expect_true(grepl('addEventListener', html_text),
              info = "Debe tener JavaScript event listeners")
  
  expect_true(grepl('classList\\.(add|remove)', html_text),
              info = "Debe tener manipulacion de clases CSS")
})

test_that("HTML tiene barra superior con elementos correctos", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl('Análisis PT.*ISO 13528:2022', html_text),
              info = "Debe tener titulo de la aplicacion")
  
  expect_true(grepl('class="top-bar"', html_text),
              info = "Debe tener barra superior")
  
  expect_true(grepl('class="sidebar"', html_text),
              info = "Debe tener barra lateral")
  
  expect_true(grepl('breadcrumb', html_text),
              info = "Debe tener breadcrumb de navegacion")
})

test_that("HTML tiene componentes de cards", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl('class="card"', html_text),
              info = "Debe tener elementos card")
  
  expect_true(grepl('class="card-header"', html_text),
              info = "Debe tener card headers")
  
  expect_true(grepl('class="kpi-card"', html_text),
              info = "Debe tener kpi cards")
  
  expect_true(grepl('class="summary-panel"', html_text),
              info = "Debe tener summary panels")
})

test_that("HTML tiene placeholders para graficos", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  html_file <- "html/prototipo.html"
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  
  expect_true(grepl('class="chart-placeholder"', html_text),
              info = "Debe tener placeholders para graficos")
  
  expect_true(grepl('Placeholder para gráfico ggplot2', html_text),
              info = "Debe mencionar ggplot2 en placeholders")
})

test_that("archivo wireframes.md existe", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  md_file <- "md/wireframes.md"
  expect_true(file.exists(md_file), 
              info = "El archivo wireframes.md debe existir")
})

test_that("wireframes.md contiene todos los modulos documentados", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  md_file <- "md/wireframes.md"
  md_content <- readLines(md_file, warn = FALSE)
  md_text <- paste(md_content, collapse = "\n")
  
  modulos_esperados <- c(
    "Módulo de Carga de Datos",
    "Módulo de Homogeneidad y Estabilidad",
    "Módulo de Valores Atípicos",
    "Módulo de Valor Asignado",
    "Módulo de Puntajes PT",
    "Módulo de Informe Global",
    "Módulo de Participantes",
    "Módulo de Generación de Informes"
  )
  
  for (modulo in modulos_esperados) {
    expect_true(grepl(modulo, md_text, fixed = TRUE),
                info = paste("El modulo", modulo, "debe estar documentado"))
  }
})

test_that("archivo diagrama_navegacion.mmd existe", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  mmd_file <- "mmd/diagrama_navegacion.mmd"
  expect_true(file.exists(mmd_file), 
              info = "El archivo diagrama_navegacion.mmd debe existir")
})

test_that("diagrama_navegacion.mmd tiene estructura de mermaid valida", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  mmd_file <- "mmd/diagrama_navegacion.mmd"
  mmd_content <- readLines(mmd_file, warn = FALSE)
  mmd_text <- paste(mmd_content, collapse = "\n")
  
  expect_true(grepl("^flowchart", mmd_text),
              info = "Debe ser un diagrama de tipo flowchart")
  
  expect_true(grepl("Inicio", mmd_text),
              info = "Debe tener nodo Inicio")
  
  expect_true(grepl("Carga de Datos", mmd_text),
              info = "Debe tener nodo Carga de Datos")
  
  expect_true(grepl("Homogeneidad", mmd_text),
              info = "Debe tener nodo Homogeneidad")
})

test_that("diagrama de navegacion tiene nodos de decision", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  mmd_file <- "mmd/diagrama_navegacion.mmd"
  mmd_content <- readLines(mmd_file, warn = FALSE)
  mmd_text <- paste(mmd_content, collapse = "\n")
  
  expect_true(grepl("\\{", mmd_text),
              info = "Debe tener nodos de decision (diamantes)")
  
  expect_true(grepl("-->", mmd_text),
              info = "Debe tener flechas de navegacion")
})

test_that("estructura de directorios es correcta", {
  old_wd <- setwd("..")
  on.exit(setwd(old_wd))
  
  directorios_esperados <- c(
    ".",
    "md",
    "html",
    "mmd",
    "tests"
  )
  
  for (directorio in directorios_esperados) {
    expect_true(dir.exists(directorio),
                info = paste("El directorio", directorio, "debe existir"))
  }
})
