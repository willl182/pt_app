# Extracted from test-doc-merge-05.R:5

# test -------------------------------------------------------------------------
path <- "../../final_docs/05_pt_scores.md"
expect_true(file.exists(path))
content <- paste(readLines(path, warn = FALSE), collapse = "\n")
