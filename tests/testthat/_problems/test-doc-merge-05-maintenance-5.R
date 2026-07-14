# Extracted from test-doc-merge-05-maintenance.R:5

# test -------------------------------------------------------------------------
path_15 <- "../../final_docs/15_architecture.md"
expect_true(file.exists(path_15))
content_15 <- paste(readLines(path_15, warn = FALSE), collapse = "\n")
