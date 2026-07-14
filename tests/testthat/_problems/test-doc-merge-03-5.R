# Extracted from test-doc-merge-03.R:5

# test -------------------------------------------------------------------------
path <- "../../final_docs/03_pt_robust_stats.md"
expect_true(file.exists(path))
content <- paste(readLines(path, warn = FALSE), collapse = "\n")
