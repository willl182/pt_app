test_that("merged homogeneity documentation contains content from all sources", {
  path <- "../../final_docs/04_pt_homogeneity.md"
  expect_true(file.exists(path))
  
  content <- paste(readLines(path, warn = FALSE), collapse = "\n")
  
  expect_match(content, "Evaluación de Homogeneidad y Estabilidad / Homogeneity & Stability Assessment")
  expect_match(content, "ANOVA")
  expect_match(content, "s_s = \\sqrt{\\max(0, s_{\\bar{x}}^2 - \\frac{s_w^2}{m})}", fixed = TRUE)
  expect_match(content, "0.3 \\times \\sigma_{pt}", fixed = TRUE)
  expect_match(content, "flowchart TD") # Mermaid diagram
  expect_match(content, "u_{hom} = s_s", fixed = TRUE)
  expect_match(content, "rectangular") # Uncertainty distribution
})

