# Extracted from test-entregables-fase-6.R:78

# prequel ----------------------------------------------------------------------
phase6_root <- normalizePath(file.path(testthat::test_path(), "../.."))
e09_root <- file.path(phase6_root, "Entregables_pt_app/09_informe_final")
read_e09 <- function(path) {
  paste(readLines(file.path(e09_root, path), warn = FALSE), collapse = "\n")
}

# test -------------------------------------------------------------------------
references <- read_e09("anexos/referencias_normativas.md")
testthat::expect_match(references, "2026-07-14 14:45 America/Bogota", fixed = TRUE)
testthat::expect_match(references, "https://www.iso.org/standard/78879.html", fixed = TRUE)
testthat::expect_match(references, "https://www.iso.org/standard/80864.html", fixed = TRUE)
testthat::expect_match(references, "https://www.iso.org/standard/90057.html", fixed = TRUE)
testthat::expect_match(references, "no demuestra conformidad", fixed = TRUE)
