library(testthat)

source("/home/w182/w421/pt_app/deliv/03_calculos_pt/R/homogeneity.R")

ruta_esperados <- "/home/w182/w421/pt_app/deliv/03_calculos_pt/tests/test_03_homogeneity.csv"
ruta_datos <- "/home/w182/w421/pt_app/data/homogeneity.csv"

test_that("calcula estadísticos de homogeneidad para cada combinación", {
  esperados <- read.csv(ruta_esperados, stringsAsFactors = FALSE)

  for (i in seq_len(nrow(esperados))) {
    fila <- esperados[i, ]
    resultado <- calculate_homogeneity_stats(fila$pollutant, fila$level, ruta_datos)

    expect_null(resultado$error)
    expect_equal(resultado$g, fila$g)
    expect_equal(resultado$m, fila$m)
    expect_equal(resultado$grand_mean, fila$grand_mean, tolerance = 1e-10)
    expect_equal(resultado$sw, fila$sw, tolerance = 1e-10)
    expect_equal(resultado$ss, fila$ss, tolerance = 1e-10)
  }
})
