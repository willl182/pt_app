# Extracted from test-doc-merge-readme.R:5

# test -------------------------------------------------------------------------
path <- "../../final_docs/README.md"
expect_true(file.exists(path))
content <- paste(readLines(path, warn = FALSE), collapse = "\n")
