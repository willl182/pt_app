# Extracted from test-linea-base-entregables.R:112

# prequel ----------------------------------------------------------------------
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

# test -------------------------------------------------------------------------
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
        "Entregables_pt_app/00_control_documental/checksums_entrega.sha256"
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
