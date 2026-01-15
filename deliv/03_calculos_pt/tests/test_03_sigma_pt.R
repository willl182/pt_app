library(testthat)

source("/home/w182/w421/pt_app/deliv/03_calculos_pt/R/sigma_pt.R")

ruta_esperados <- "/home/w182/w421/pt_app/deliv/03_calculos_pt/tests/test_03_sigma_pt.csv"
ruta_datos <- "/home/w182/w421/pt_app/data/summary_n4.csv"

test_that("calcula estimadores robustos para sigma_pt", {
  esperados <- read.csv(ruta_esperados, stringsAsFactors = FALSE)
  fila <- esperados[1, ]

  datos <- read.csv(ruta_datos, stringsAsFactors = FALSE)
  subset <- datos[datos$pollutant == fila$pollutant &
                   datos$level == fila$level &
                   datos$participant_id != "ref", ]

  valores <- subset$mean_value

  niqr <- calculate_niqr(valores)
  made <- calculate_mad_e(valores)
  algo <- run_algorithm_a(valores)

  expect_equal(length(valores), fila$n)
  expect_equal(as.numeric(niqr), fila$niqr, tolerance = 1e-10)
  expect_equal(as.numeric(made), fila$made, tolerance = 1e-10)
  expect_equal(algo$assigned_value, fila$algo_x_pt, tolerance = 1e-10)
  expect_equal(algo$robust_sd, fila$algo_sigma, tolerance = 1e-10)
  expect_equal(algo$converged, as.logical(fila$converged))
})
