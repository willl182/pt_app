test_that("merged glossary contains content from all sources", {
  path <- "../../final_docs/00_glossary.md"
  expect_true(file.exists(path))
  
  content <- readLines(path, warn = FALSE)
  content_str <- paste(content, collapse = "\n")
  
  # Check for unique or core terms from different sources
  expect_match(content_str, "Glosario de Términos / Glossary of Terms") # Combined header
  expect_match(content_str, "Algoritmo A") # Core from all
  expect_match(content_str, "D2a statistic") # From glm_docs
  expect_match(content_str, "Factor de cobertura") # From glm_docs
  expect_match(content_str, "nIQR") # From claude_docs/glm_docs
  expect_match(content_str, "ISO 13528:2022") # From gem_docs/claude_docs
})

