# Extracted from test-doc-merge-01.R:5

# test -------------------------------------------------------------------------
path_01 <- "../../final_docs/01_carga_datos.md"
expect_true(file.exists(path_01))
content_01 <- paste(readLines(path_01, warn = FALSE), collapse = "\n")
