# ===================================================================
# Deliverables Baseline Evidence Tests
#
# Checks the Phase 0/initial-phase artifacts and auditable inventory.
# ===================================================================

find_project_root <- function() {
  candidates <- c(".", "../..", "../../..")
  matches <- candidates[
    file.exists(file.path(candidates, "app.R")) &
      dir.exists(file.path(candidates, "Entregables_pt_app"))
  ]
  if (!length(matches)) {
    stop("No fue posible localizar la raíz del proyecto.")
  }
  normalizePath(matches[[1]], mustWork = TRUE)
}

project_root <- find_project_root()

baseline_inventory_status <- system2(
  "Rscript",
  c(
    file.path(
      project_root,
      "scripts",
      "documentacion",
      "generar_inventario_entregables.R"
    ),
    project_root
  ),
  stdout = FALSE,
  stderr = FALSE
)
if (baseline_inventory_status != 0L) {
  stop("No fue posible regenerar el inventario antes de las pruebas.")
}

expected_role <- function(path) {
  extension <- tolower(tools::file_ext(path))
  if (grepl("(^|/)tests?/", path) || grepl("(^|/)test_", path)) {
    return("prueba")
  }
  if (grepl("(^|/)(anexos|evidencia|capturas)/", path)) {
    return("evidencia")
  }
  if (extension %in% c("docx", "pdf", "html")) return("derivado")
  if (extension %in% c("md", "rmd", "mmd")) return("fuente_documental")
  if (extension %in% c("r", "js", "py", "sh")) return("ejecutable")
  if (extension %in% c("csv", "tsv", "xlsx", "xls", "rds")) return("dato")
  "otro"
}

expected_delivery <- function(path) {
  match <- regmatches(path, regexpr("(^|/)[0-9]{2}_[^/]+", path))
  if (!length(match) || identical(match, "")) return("TRANSVERSAL")
  sub("^/", "", match)
}

testthat::test_that("baseline evidence contains all required artifacts", {
  baseline_dir <- file.path(
    project_root,
    "Entregables_pt_app",
    "00_linea_base"
  )
  required <- c(
    "README.md",
    "linea_base_version.md",
    "inventario_maestro.csv",
    "mapa_funcional.md",
    "matriz_brechas.md",
    "fuentes_y_requisitos.md"
  )

  testthat::expect_true(dir.exists(baseline_dir))
  testthat::expect_true(all(file.exists(file.path(baseline_dir, required))))
})

testthat::test_that("master inventory is complete and structurally valid", {
  inventory_path <- file.path(
    project_root,
    "Entregables_pt_app",
    "00_linea_base",
    "inventario_maestro.csv"
  )
  inventory <- utils::read.csv(inventory_path, stringsAsFactors = FALSE)

  expected_columns <- c(
    "entregable", "ruta", "rol", "estado_documental", "extension",
    "tamano_bytes", "sha256", "estado_git"
  )
  testthat::expect_identical(names(inventory), expected_columns)
  testthat::expect_false(anyDuplicated(inventory$ruta) > 0)
  inventory_files <- file.path(project_root, inventory$ruta)
  testthat::expect_true(all(file.exists(inventory_files)))

  actual_files <- list.files(
    file.path(project_root, "Entregables_pt_app"),
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  actual_files <- actual_files[!dir.exists(actual_files)]
  actual_relative <- substring(actual_files, nchar(project_root) + 2L)
  actual_relative <- actual_relative[
    actual_relative != file.path(
      "Entregables_pt_app", "00_linea_base", "inventario_maestro.csv"
    ) &
      !actual_relative %in% c(
        "Entregables_pt_app/00_control_documental/manifiesto_entrega.csv",
        "Entregables_pt_app/00_control_documental/checksums_entrega.sha256",
        "Entregables_pt_app/plan_documentos_formales_entregables_pt.html"
      ) &
      !grepl("(^|/)_problems/", actual_relative) &
      !grepl("(^|/)~[$]|[.]tmp$", actual_relative)
  ]
  testthat::expect_setequal(inventory$ruta, actual_relative)

  calculated_hashes <- vapply(inventory_files, function(path) {
    output <- system2("sha256sum", path, stdout = TRUE)
    strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
  }, character(1))
  testthat::expect_identical(
    unname(inventory$sha256),
    unname(calculated_hashes)
  )
  testthat::expect_equal(
    inventory$tamano_bytes,
    as.numeric(file.info(inventory_files)$size)
  )
  testthat::expect_true(all(inventory$estado_git %in% c(
    "rastreado", "modificado", "no_rastreado"
  )))
  tracked <- system2(
    "git",
    c("-C", project_root, "ls-files", "--", "Entregables_pt_app"),
    stdout = TRUE
  )
  status <- system2(
    "git",
    c(
      "-C", project_root, "status", "--porcelain=v1", "--",
      "Entregables_pt_app"
    ),
    stdout = TRUE
  )
  modified <- if (length(status)) trimws(substring(status, 4L)) else character()
  expected_git_state <- ifelse(
    !inventory$ruta %in% tracked,
    "no_rastreado",
    ifelse(inventory$ruta %in% modified, "modificado", "rastreado")
  )
  testthat::expect_identical(inventory$estado_git, expected_git_state)
  historical <- basename(inventory$ruta) %in% c(
    "app_original.R", "app_v06.R", "app_v07.R", "app_final.R"
  )
  testthat::expect_true(all(inventory$estado_documental[historical] ==
    "historico"))
  testthat::expect_false(any(inventory$estado_documental[!historical] ==
    "historico"))
  testthat::expect_identical(
    inventory$rol,
    vapply(inventory$ruta, expected_role, character(1), USE.NAMES = FALSE)
  )
  testthat::expect_identical(
    inventory$entregable,
    vapply(inventory$ruta, expected_delivery, character(1), USE.NAMES = FALSE)
  )
  testthat::expect_setequal(
    sprintf("%02d", 1:9),
    unique(sub("^([0-9]{2}).*$", "\\1", inventory$entregable[
      grepl("^0[1-9]_", inventory$entregable)
    ]))
  )
})

testthat::test_that("gap matrix addresses every contractual delivery", {
  matrix_text <- paste(
    readLines(
      file.path(
        project_root,
        "Entregables_pt_app",
        "00_linea_base",
        "matriz_brechas.md"
      ),
      warn = FALSE
    ),
    collapse = "\n"
  )

  for (delivery_id in sprintf("E%02d", 1:9)) {
    testthat::expect_match(matrix_text, paste0("[|] ", delivery_id, " [|]"))
  }
})
