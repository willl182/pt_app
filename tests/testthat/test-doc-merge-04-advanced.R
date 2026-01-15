test_that("merged Phase 4 documentation files exist and contain key elements", {
  # Check 06_shiny_homogeneidad.md
  path_06 <- "../../final_docs/06_shiny_homogeneidad.md"
  expect_true(file.exists(path_06))
  content_06 <- paste(readLines(path_06, warn = FALSE), collapse = "\n")
  expect_match(content_06, "homogeneity_run")
  expect_match(content_06, "u_hom_table")
  
  # Check 07_valor_asignado.md
  path_07 <- "../../final_docs/07_valor_asignado.md"
  expect_true(file.exists(path_07))
  content_07 <- paste(readLines(path_07, warn = FALSE), collapse = "\n")
  expect_match(content_07, "Algoritmo A")
  expect_match(content_07, "u_{xpt,def} = \\sqrt{u_{xpt}^2 + u_{hom}^2 + u_{stab}^2}", fixed = TRUE)
  
  # Check 09_puntajes_pt.md
  path_09 <- "../../final_docs/09_puntajes_pt.md"
  expect_true(file.exists(path_09))
  content_09 <- paste(readLines(path_09, warn = FALSE), collapse = "\n")
  expect_match(content_09, "lollipop")
  expect_match(content_09, "a1-a7")
  
  # Check 10_informe_global.md
  path_10 <- "../../final_docs/10_informe_global.md"
  expect_true(file.exists(path_10))
  content_10 <- paste(readLines(path_10, warn = FALSE), collapse = "\n")
  expect_match(content_10, "heatmaps")
  expect_match(content_10, "#00B050") # Green color code
  
  # Check 11_participantes.md
  path_11 <- "../../final_docs/11_participantes.md"
  expect_true(file.exists(path_11))
  content_11 <- paste(readLines(path_11, warn = FALSE), collapse = "\n")
  expect_match(content_11, "dynamic tab generation", ignore.case = TRUE)
  expect_match(content_11, "Lazy Loading")
  
  # Check 12_generacion_informes.md
  path_12 <- "../../final_docs/12_generacion_informes.md"
  expect_true(file.exists(path_12))
  content_12 <- paste(readLines(path_12, warn = FALSE), collapse = "\n")
  expect_match(content_12, "RMarkdown")
  expect_match(content_12, ".docx")
  
  # Check 13_valores_atipicos.md
  path_13 <- "../../final_docs/13_valores_atipicos.md"
  expect_true(file.exists(path_13))
  content_13 <- paste(readLines(path_13, warn = FALSE), collapse = "\n")
  expect_match(content_13, "Grubbs")
  expect_match(content_13, "G = \\frac{\\max|x_i - \\bar{x}|}{s}", fixed = TRUE)
})
