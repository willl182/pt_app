test_that("final_docs directory exists and is empty", {
  expect_true(dir.exists("../../final_docs"), "final_docs directory should exist in project root")
  # Note: testthat runs inside tests/testthat, so we need ../../ to get to root
  
  files <- list.files("../../final_docs", all.files = TRUE, no.. = TRUE)
  # Allow .gitkeep for git tracking
  files <- files[files != ".gitkeep"]
  expect_length(files, 0)
})
