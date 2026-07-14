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

testthat::test_that("all nine controlled sources and principal derivatives exist", {
  sources <- c(
    "01_repo_inicial/README.md",
    "02_funciones_usadas/md/documentacion_funciones.md",
    "03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md",
    "04_puntajes/md/formulas_y_ejemplos.md",
    "05_prototipo_ui/md/wireframes.md",
    "06_app_logica/md/manual_usuario.md",
    "07_dashboards/md/documentacion_dashboards.md",
    "08_beta/md/manual_desarrollador.md",
    "09_informe_final/md/informe_validacion.md"
  )
  derivatives <- c(
    "01_repo_inicial/README.docx",
    "02_funciones_usadas/documentacion_funciones.docx",
    "03_calculos_pt/ejemplo_calculo_paso_a_paso.docx",
    "04_puntajes/formulas_y_ejemplos.docx",
    "05_prototipo_ui/wireframes.docx",
    "06_app_logica/manual_usuario.docx",
    "07_dashboards/documentacion_dashboards.docx",
    "08_beta/manual_desarrollador.docx",
    "09_informe_final/informe_validacion.docx",
    "09_informe_final/informe_validacion.pdf"
  )
  testthat::expect_true(all(file.exists(file.path(package_root, sources))))
  testthat::expect_true(all(file.exists(file.path(package_root, derivatives))))
  source_texts <- vapply(
    file.path(package_root, sources), read_text, character(1)
  )
  testthat::expect_false(any(grepl("file://", source_texts, fixed = TRUE)))
})

testthat::test_that("cross-audit records limits and non-technical path", {
  audit <- read_text(file.path(control_root, "auditoria_cierre.md"))
  testthat::expect_true(all(vapply(
    sprintf("E%02d", 1:9), grepl, logical(1), x = audit, fixed = TRUE
  )))
  required <- c(
    "Recorrido de lectura no técnica", "Aprobación contractual",
    "Revisión normativa independiente", "Riesgo funcional",
    "Reproducibilidad"
  )
  testthat::expect_true(all(vapply(
    required, grepl, logical(1), x = audit, fixed = TRUE
  )))
})

testthat::test_that("local Markdown links resolve", {
  markdown_files <- list.files(
    package_root, pattern = "[.]md$", recursive = TRUE, full.names = TRUE
  )
  failures <- character()
  for (markdown_file in markdown_files) {
    text <- read_text(markdown_file)
    matches <- regmatches(
      text,
      gregexpr("!?\\[[^]]*\\]\\(([^)]+)\\)", text, perl = TRUE)
    )[[1]]
    if (!length(matches) || identical(matches, "")) {
      next
    }
    targets <- sub("^!?\\[[^]]*\\]\\(([^)]+)\\)$", "\\1", matches)
    targets <- sub("[[:space:]]+['\"].*$", "", targets)
    targets <- utils::URLdecode(targets)
    targets <- targets[!grepl("^(https?://|mailto:|#)", targets)]
    targets <- sub("#.*$", "", targets)
    targets <- targets[nzchar(targets)]
    is_file_url <- grepl("^file://", targets)
    resolved <- targets
    resolved[is_file_url] <- sub("^file://", "", targets[is_file_url])
    resolved[!is_file_url] <- file.path(
      dirname(markdown_file), targets[!is_file_url]
    )
    missing <- targets[!file.exists(resolved)]
    if (length(missing)) {
      failures <- c(failures, paste(basename(markdown_file), missing, sep = ": "))
    }
  }
  if (length(failures)) {
    stop("Enlaces locales rotos:\n", paste(failures, collapse = "\n"))
  }
  testthat::succeed()
})

testthat::test_that("DOCX and PDF derivatives open technically", {
  docx <- list.files(package_root, pattern = "[.]docx$", recursive = TRUE,
                     full.names = TRUE)
  docx_status <- vapply(docx, function(path) {
    system2("unzip", c("-tq", shQuote(path)), stdout = FALSE, stderr = FALSE)
  }, integer(1))
  testthat::expect_true(all(docx_status == 0L))

  pdf <- list.files(package_root, pattern = "[.]pdf$", recursive = TRUE,
                    full.names = TRUE)
  pdf_status <- vapply(pdf, function(path) {
    system2("pdfinfo", shQuote(path), stdout = FALSE, stderr = FALSE)
  }, integer(1))
  testthat::expect_true(length(pdf) > 0L && all(pdf_status == 0L))
  extracted <- tempfile(fileext = ".txt")
  on.exit(unlink(extracted), add = TRUE)
  testthat::expect_equal(system2(
    "pdftotext", c(shQuote(pdf[[1]]), shQuote(extracted)),
    stdout = FALSE, stderr = FALSE
  ), 0L)
  testthat::expect_gt(file.info(extracted)$size, 100)
})

testthat::test_that("final manifest covers files with valid sizes and hashes", {
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
  testthat::expect_true(all(sprintf("E%02d", 1:9) %in% manifest$entregable))
  testthat::expect_true("TRANSVERSAL" %in% manifest$entregable)
  testthat::expect_false(any(grepl("/_problems/", manifest$ruta)))
})

testthat::test_that("checksum file validates and pending approvals remain explicit", {
  old_wd <- setwd(phase7_root)
  on.exit(setwd(old_wd), add = TRUE)
  status <- system2(
    "sha256sum",
    c("--check", "Entregables_pt_app/00_control_documental/checksums_entrega.sha256"),
    stdout = FALSE,
    stderr = FALSE
  )
  testthat::expect_equal(status, 0L)
  manifest <- read_text(file.path(control_root, "manifiesto_entrega.md"))
  testthat::expect_match(manifest, "aprobación formal", fixed = TRUE)
  testthat::expect_match(manifest, "riesgo técnico abierto", fixed = TRUE)
})
