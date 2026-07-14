# Extracted from test-doc-merge-04.R:5

# test -------------------------------------------------------------------------
path <- "../../final_docs/04_pt_homogeneity.md"
expect_true(file.exists(path))
content <- paste(readLines(path, warn = FALSE), collapse = "\n")
