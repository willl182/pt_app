phase6_root <- normalizePath(file.path(testthat::test_path(), "../.."))
e09_root <- file.path(phase6_root, "Entregables_pt_app/09_informe_final")

read_e09 <- function(path) {
  paste(readLines(file.path(e09_root, path), warn = FALSE), collapse = "\n")
}

testthat::test_that("E09 states a bounded and auditable conclusion", {
  report <- read_e09("md/informe_validacion.md")
  testthat::expect_match(report, "11 PASS; 1 OPEN_RISK", fixed = TRUE)
  testthat::expect_match(report, "No incluido", fixed = TRUE)
  testthat::expect_match(report, "aprobación contractual pendiente", fixed = TRUE)
  testthat::expect_match(report, "no debe usarse", fixed = TRUE)
  testthat::expect_false(grepl("ISO 17043:2024", report, fixed = TRUE))
})

testthat::test_that("E09 matrix and calculation annex are complete", {
  matrix <- utils::read.csv(
    file.path(e09_root, "anexos/matriz_validacion.csv"),
    stringsAsFactors = FALSE
  )
  testthat::expect_named(matrix, c(
    "id", "capability", "expected", "obtained", "status", "evidence",
    "responsible"
  ))
  testthat::expect_equal(nrow(matrix), 12L)
  testthat::expect_setequal(unique(matrix$status), c("PASS", "OPEN_RISK"))
  annex <- read_e09("md/anexo_calculos.md")
  testthat::expect_true(all(vapply(
    c("Homogeneidad", "Estabilidad", "Estimadores robustos", "Puntajes"),
    grepl, logical(1), x = annex, fixed = TRUE
  )))
})

testthat::test_that("E09 derived documents and manifest have valid hashes", {
  manifest_path <- file.path(
    phase6_root,
    "Entregables_pt_app/00_control_documental/derivados/manifiesto_fase_6.csv"
  )
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
  testthat::expect_equal(nrow(manifest), 3L)
  testthat::expect_true(all(file.exists(file.path(phase6_root, manifest$archivo))))
  sha256_file <- function(path) {
    output <- system2("sha256sum", path, stdout = TRUE)
    strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
  }
  testthat::expect_identical(
    manifest$sha256_fuente,
    unname(vapply(file.path(phase6_root, manifest$fuente), sha256_file, character(1)))
  )
  testthat::expect_identical(
    manifest$sha256_salida,
    unname(vapply(file.path(phase6_root, manifest$archivo), sha256_file, character(1)))
  )
})

testthat::test_that("E09 environment records both repositories", {
  environment <- read_e09("anexos/entorno_ejecucion.txt")
  testthat::expect_match(environment, "root_commit=", fixed = TRUE)
  testthat::expect_match(environment, "root_status=", fixed = TRUE)
  testthat::expect_match(environment, "ptcalc_commit=", fixed = TRUE)
  testthat::expect_match(environment, "ptcalc_status=", fixed = TRUE)
  testthat::expect_true(file.exists(file.path(e09_root, "anexos/ptcalc_worktree.patch")))
  hashes <- utils::read.csv(
    file.path(e09_root, "anexos/ptcalc_fuentes_sha256.csv"),
    stringsAsFactors = FALSE
  )
  testthat::expect_gt(nrow(hashes), 0L)
  testthat::expect_true(all(nchar(hashes$sha256) == 64L))
  sha256_file <- function(path) {
    output <- system2("sha256sum", path, stdout = TRUE)
    strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
  }
  testthat::expect_identical(
    hashes$sha256,
    unname(vapply(file.path(phase6_root, hashes$path), sha256_file, character(1)))
  )
  testthat::expect_gt(file.info(
    file.path(e09_root, "anexos/ptcalc_worktree.patch")
  )$size, 0)
})

testthat::test_that("normative metadata has auditable official sources", {
  references <- read_e09("anexos/referencias_normativas.md")
  testthat::expect_match(references, "2026-07-14 14:45 America/Bogota", fixed = TRUE)
  testthat::expect_match(references, "https://www.iso.org/standard/78879.html", fixed = TRUE)
  testthat::expect_match(references, "https://www.iso.org/standard/80864.html", fixed = TRUE)
  testthat::expect_match(references, "https://www.iso.org/standard/90057.html", fixed = TRUE)
  testthat::expect_match(references, "No constituye", fixed = TRUE)
})
