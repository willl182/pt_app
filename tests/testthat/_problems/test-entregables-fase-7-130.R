# Extracted from test-entregables-fase-7.R:130

# prequel ----------------------------------------------------------------------
phase7_root <- normalizePath(file.path(testthat::test_path(), "../.."))
package_root <- file.path(phase7_root, "Entregables_pt_app")
control_root <- file.path(package_root, "00_control_documental")
read_text <- function(path) {
  paste(readLines(path, warn = FALSE), collapse = "\n")
}
sha256_file <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE)
  strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
}

# test -------------------------------------------------------------------------
manifest <- utils::read.csv(
    file.path(control_root, "manifiesto_entrega.csv"),
    stringsAsFactors = FALSE
  )
testthat::expect_named(
    manifest, c("entregable", "ruta", "tamano_bytes", "sha256")
  )
paths <- file.path(phase7_root, manifest$ruta)
testthat::expect_true(all(file.exists(paths)))
testthat::expect_equal(manifest$tamano_bytes, as.numeric(file.info(paths)$size))
testthat::expect_identical(
    manifest$sha256, unname(vapply(paths, sha256_file, character(1)))
  )
