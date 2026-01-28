test_that("merged ptcalc documentation contains content from all sources", {
  # Check 02_ptcalc_package.md
  path_02 <- "../../final_docs/02_ptcalc_package.md"
  expect_true(file.exists(path_02))
  content_02 <- paste(readLines(path_02, warn = FALSE), collapse = "\n")
  
  expect_match(content_02, "El Paquete `ptcalc` / The `ptcalc` Package")
  expect_match(content_02, "graph LR") # Mermaid diagram
  expect_match(content_02, "devtools::install(\"ptcalc\")", fixed = TRUE)
  expect_match(content_02, "pt_robust_stats.R")
  
  # Check 02a_ptcalc_api.md
  path_02a <- "../../final_docs/02a_ptcalc_api.md"
  expect_true(file.exists(path_02a))
  content_02a <- paste(readLines(path_02a, warn = FALSE), collapse = "\n")
  
  expect_match(content_02a, "Referencia de la API de `ptcalc` / `ptcalc` API Reference")
  expect_match(content_02a, "run_algorithm_a")
  expect_match(content_02a, "calculate_mad_e")
  expect_match(content_02a, "calculate_homogeneity_stats")
})
