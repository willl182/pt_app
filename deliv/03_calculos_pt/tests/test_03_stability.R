library(testthat)

source("/home/w182/w421/pt_app/deliv/03_calculos_pt/R/stability.R")

ruta_esperados <- "/home/w182/w421/pt_app/deliv/03_calculos_pt/tests/test_03_stability.csv"
ruta_estabilidad <- "/home/w182/w421/pt_app/data/stability.csv"
ruta_homogeneidad <- "/home/w182/w421/pt_app/data/homogeneity.csv"

test_that("calcula estadísticos de estabilidad para cada combinación", {
  esperados <- read.csv(ruta_esperados, stringsAsFactors = FALSE)

  for (i in seq_len(nrow(esperados))) {
    fila <- esperados[i, ]
    resultado <- calculate_stability_stats(
      fila$pollutant,
      fila$level,
      ruta_estabilidad,
      ruta_homogeneidad
    )

    expect_null(resultado$error)
    expect_equal(resultado$g, fila$g)
    expect_equal(resultado$m, fila$m)
    expect_equal(resultado$hom_grand_mean, fila$hom_grand_mean, tolerance = 1e-10)
    expect_equal(resultado$stab_grand_mean, fila$stab_grand_mean, tolerance = 1e-10)
    expect_equal(resultado$diff_hom_stab, fila$diff_hom_stab, tolerance = 1e-10)
  }
})
