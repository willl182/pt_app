test_that("merged README.md exists and contains key sections", {
  skip("Superseded by the controlled E01-E09 documentation package")
  path <- "../../final_docs/README.md"
  expect_true(file.exists(path))
  
  content <- paste(readLines(path, warn = FALSE), collapse = "\n")
  
  expect_match(content, "Aplicativo para Evaluación de Ensayos de Aptitud / Proficiency Testing App")
  expect_match(content, "Arquitectura del Sistema")
  expect_match(content, "ptcalc/")
  expect_match(content, "ISO 13528:2022")
  expect_match(content, "Index")
  expect_match(content, "MIT")
})
