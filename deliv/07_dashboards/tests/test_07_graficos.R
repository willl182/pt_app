testthat::test_that("La app_v07 incluye datos fijos y librerías requeridas", {
  ruta_app <- file.path(
    "/home/w182/w421/pt_app/deliv/07_dashboards",
    "app_v07.R"
  )

  expect_true(file.exists(ruta_app))

  contenido <- readLines(ruta_app, warn = FALSE)
  script <- paste(contenido, collapse = " ")

  expect_true(grepl("library\\(shiny\\)", script))
  expect_true(grepl("library\\(DT\\)", script))
  expect_true(grepl("library\\(ggplot2\\)", script))
  expect_true(grepl("library\\(plotly\\)", script))
  expect_true(grepl("homogeneity.csv", script))
  expect_true(grepl("stability.csv", script))
  expect_true(grepl("summary_n4.csv", script))
  expect_true(grepl("participants_data4.csv", script))
})

testthat::test_that("La app_v07 declara gráficos dinámicos", {
  ruta_app <- file.path(
    "/home/w182/w421/pt_app/deliv/07_dashboards",
    "app_v07.R"
  )

  contenido <- readLines(ruta_app, warn = FALSE)
  script <- paste(contenido, collapse = " ")

  expect_true(grepl("grafico_histograma", script))
  expect_true(grepl("grafico_boxplot", script))
  expect_true(grepl("grafico_heatmap", script))
  expect_true(grepl("grafico_barras", script))
})
