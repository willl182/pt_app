test_that("merged PT scores documentation contains content from all sources", {
  path <- "../../final_docs/05_pt_scores.md"
  expect_true(file.exists(path))
  
  content <- paste(readLines(path, warn = FALSE), collapse = "\n")
  
  expect_match(content, "Cálculo y Evaluación de Puntajes PT / PT Score Calculations")
  expect_match(content, "z-score")
  expect_match(content, "z-prime")
  expect_match(content, "zeta")
  expect_match(content, "En")
  expect_match(content, "flowchart TD") # Selection guide
  expect_match(content, "u_{xpt,def} = \\sqrt{u_{xpt}^2 + u_{hom}^2 + u_{stab}^2}", fixed = TRUE)
  expect_match(content, "a1")
  expect_match(content, "a7")
})
