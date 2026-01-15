test_that("merged data loading and formats contain content from all sources", {
  # Check 01_carga_datos.md
  path_01 <- "../../final_docs/01_carga_datos.md"
  expect_true(file.exists(path_01))
  content_01 <- paste(readLines(path_01, warn = FALSE), collapse = "\n")
  
  expect_match(content_01, "Módulo: Carga de Datos / Data Loading Module")
  expect_match(content_01, "graph TD") # Mermaid diagram
  expect_match(content_01, "algoA_results_cache\\(NULL\\)") # Technical detail
  expect_match(content_01, "ISO 13528:2022")
  
  # Check 01a_data_formats.md
  path_01a <- "../../final_docs/01a_data_formats.md"
  expect_true(file.exists(path_01a))
  content_01a <- paste(readLines(path_01a, warn = FALSE), collapse = "\n")
  
  expect_match(content_01a, "Formatos de Datos y Pipeline de Transformación")
  expect_match(content_01a, "get_wide_data <- function") # Function explanation
  expect_match(content_01a, "pivot_wider")
  expect_match(content_01a, "sample_1")
  expect_match(content_01a, "participant_id = \"ref\"")
})

