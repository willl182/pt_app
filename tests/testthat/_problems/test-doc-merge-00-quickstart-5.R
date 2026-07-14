# Extracted from test-doc-merge-00-quickstart.R:5

# test -------------------------------------------------------------------------
path <- "../../final_docs/00_quickstart.md"
expect_true(file.exists(path))
content <- readLines(path, warn = FALSE)
