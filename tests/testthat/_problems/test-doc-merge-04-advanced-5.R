# Extracted from test-doc-merge-04-advanced.R:5

# test -------------------------------------------------------------------------
path_06 <- "../../final_docs/06_shiny_homogeneidad.md"
expect_true(file.exists(path_06))
content_06 <- paste(readLines(path_06, warn = FALSE), collapse = "\n")
