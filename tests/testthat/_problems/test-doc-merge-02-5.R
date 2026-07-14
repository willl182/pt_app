# Extracted from test-doc-merge-02.R:5

# test -------------------------------------------------------------------------
path_02 <- "../../final_docs/02_ptcalc_package.md"
expect_true(file.exists(path_02))
content_02 <- paste(readLines(path_02, warn = FALSE), collapse = "\n")
