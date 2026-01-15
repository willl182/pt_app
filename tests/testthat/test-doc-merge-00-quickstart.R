test_that("merged quickstart contains content from all sources", {
  path <- "../../final_docs/00_quickstart.md"
  expect_true(file.exists(path))
  
  content <- readLines(path, warn = FALSE)
  content_str <- paste(content, collapse = "\n")
  
  # Check for unique or core elements
  expect_match(content_str, "Guía de Inicio Rápido / Quick Start Guide")
  expect_match(content_str, "4.3.0 o superior") # Recommended version
  expect_match(content_str, "devtools::install(\"ptcalc\")", fixed = TRUE)
  expect_match(content_str, "homogeneity.csv")
  expect_match(content_str, "\\| \\*\\*pollutant\\*\\* \\| Texto \\|") # Table headers
  expect_match(content_str, "flowchart TD") # Mermaid diagram
  expect_match(content_str, "Columna no encontrada") # Troubleshooting
})

