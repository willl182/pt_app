test_that("merged robust stats documentation contains content from all sources", {
  path <- "../../final_docs/03_pt_robust_stats.md"
  expect_true(file.exists(path))
  
  content <- paste(readLines(path, warn = FALSE), collapse = "\n")
  
  expect_match(content, "Métodos Estadísticos Robustos / Robust Statistical Methods")
  expect_match(content, "Algoritmo A")
  expect_match(content, "flowchart TD") # Mermaid diagram
  expect_match(content, "MADe")
  expect_match(content, "nIQR")
  expect_match(content, "10.1, 10.2, 9.9, 10.0, 10.3, 50.0") # Numerical example data
  expect_match(content, "Punto de Ruptura")
})

