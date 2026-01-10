test_that("merged Phase 5 documentation files exist and contain key elements", {
  # Check 15_architecture.md
  path_15 <- "../../final_docs/15_architecture.md"
  expect_true(file.exists(path_15))
  content_15 <- paste(readLines(path_15, warn = FALSE), collapse = "\n")
  expect_match(content_15, "MVC")
  expect_match(content_15, "Trigger-Cache")
  expect_match(content_15, "mermaid")
  
  # Check 16_customization.md
  path_16 <- "../../final_docs/16_customization.md"
  expect_true(file.exists(path_16))
  content_16 <- paste(readLines(path_16, warn = FALSE), collapse = "\n")
  expect_match(content_16, "bslib")
  expect_match(content_16, "nav_width")
  expect_match(content_16, "pollutant")
  
  # Check 17_troubleshooting.md
  path_17 <- "../../final_docs/17_troubleshooting.md"
  expect_true(file.exists(path_17))
  content_17 <- paste(readLines(path_17, warn = FALSE), collapse = "\n")
  expect_match(content_17, "Common Errors")
  expect_match(content_17, "UTF-8")
  expect_match(content_17, "Chrome")
})
