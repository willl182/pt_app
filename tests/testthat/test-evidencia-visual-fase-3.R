# ===================================================================
# Phase 3 Visual Evidence Tests
#
# Validates capture coverage, hashes, controlled demonstration data,
# reproducibility metadata, and Markdown cross-references.
# ===================================================================

project_path <- function(...) {
  file.path(testthat::test_path("..", ".."), ...)
}

testthat::test_that("visual evidence covers CAP-01 through CAP-19", {
  index_path <- project_path(
    "Entregables_pt_app", "00_evidencia_visual", "indice_capturas.csv"
  )
  index <- utils::read.csv(index_path, check.names = FALSE)

  testthat::expect_equal(nrow(index), 21L)
  testthat::expect_setequal(unique(index$id), sprintf("CAP-%02d", 1:19))
  testthat::expect_equal(sum(index$id == "CAP-13"), 2L)
  testthat::expect_equal(sum(index$id == "CAP-14"), 2L)
  testthat::expect_true(all(nzchar(index$accion_previa)))
  testthat::expect_true(all(nzchar(index$estado_esperado)))
  testthat::expect_true(all(nzchar(index$documentos_consumidores)))
  testthat::expect_equal(index$viewport[index$id == "CAP-19"], "1024x768")
})

testthat::test_that("capture and demonstration-data hashes are current", {
  index <- utils::read.csv(project_path(
    "Entregables_pt_app", "00_evidencia_visual", "indice_capturas.csv"
  ))
  evidence_dir <- project_path("Entregables_pt_app", "00_evidencia_visual")

  for (i in seq_len(nrow(index))) {
    capture_path <- file.path(evidence_dir, index$archivo[[i]])
    testthat::expect_true(file.exists(capture_path), info = index$id[[i]])
    testthat::expect_gt(file.info(capture_path)$size, 10000)
    sha <- system2("sha256sum", capture_path, stdout = TRUE)
    testthat::expect_equal(strsplit(sha, " +")[[1]][[1]], index$sha256[[i]])
  }

  demo_files <- file.path(
    evidence_dir,
    "datos_demo",
    c(
      "homogeneity_demo.csv", "stability_demo.csv", "summary_demo.csv",
      "archivo_invalido.csv"
    )
  )
  testthat::expect_true(all(file.exists(demo_files)))
  demo_text <- paste(unlist(lapply(demo_files, readLines, warn = FALSE)),
    collapse = "\n"
  )
  testthat::expect_false(grepl("@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", demo_text))
})

testthat::test_that("execution record and source links are auditable", {
  record <- jsonlite::read_json(project_path(
    "Entregables_pt_app", "00_evidencia_visual", "registro_ejecucion.json"
  ))
  testthat::expect_identical(record$status, "ok")
  testthat::expect_identical(record$captures, 21L)
  testthat::expect_identical(record$playwright, "1.61.1")
  testthat::expect_match(record$commit, "^[0-9a-f]{40}$")

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
  for (source in sources) {
    text <- paste(readLines(project_path("Entregables_pt_app", source)),
      collapse = "\n"
    )
    testthat::expect_match(text, "CAP-[0-9]{2}", info = source)
    testthat::expect_match(text, "00_evidencia_visual", info = source)
  }
})
