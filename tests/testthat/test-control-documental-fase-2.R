library(testthat)

find_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(candidate, "AGENTS.md")) &&
        dir.exists(file.path(candidate, "Entregables_pt_app"))) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Project root not found.")
    }
    candidate <- parent
  }
}

project_root <- find_project_root()
control_dir <- file.path(
  project_root,
  "Entregables_pt_app",
  "00_control_documental"
)

test_that("phase 2 controlled files exist", {
  expected <- c(
    "README.md",
    "indice_maestro.md",
    "glosario_ciudadano.md",
    "convencion_evidencia.md",
    "mapa_audiencias.md",
    "matriz_trazabilidad.csv",
    "matriz_trazabilidad.md",
    "cadena_generacion.md",
    file.path("plantillas", "plantilla_documento.md"),
    file.path("plantillas", "ejemplo_controlado.md")
  )
  expect_true(all(file.exists(file.path(control_dir, expected))))
})

test_that("master index covers all deliverables and uses relative paths", {
  index <- readLines(file.path(control_dir, "indice_maestro.md"),
                     warn = FALSE)
  text <- paste(index, collapse = "\n")

  for (deliverable in sprintf("E%02d", 1:9)) {
    expect_match(text, paste0("\\| ", deliverable, " \\|"))
  }
  expect_false(grepl("file://|/home/", text))

  controlled_sources <- regmatches(
    text,
    gregexpr("`[0-9]{2}_[^`]+[.]md`", text)
  )[[1]]
  controlled_sources <- gsub("`", "", controlled_sources, fixed = TRUE)
  existing_sources <- controlled_sources[!grepl("^07_dashboards/", controlled_sources)]
  expect_true(all(file.exists(file.path(
    project_root,
    "Entregables_pt_app",
    existing_sources
  ))))
})

test_that("common template contains required sections and metadata", {
  template <- readLines(
    file.path(control_dir, "plantillas", "plantilla_documento.md"),
    warn = FALSE
  )
  text <- paste(template, collapse = "\n")
  metadata <- c("title:", "version:", "status:", "audience:",
                "deliverable:", "source_commit:")
  sections <- c(
    "# Ficha de control documental", "# Objetivo", "# Alcance y límites",
    "# Audiencia", "# Prerrequisitos", "# Procedimiento",
    "# Resultados e interpretación", "# Problemas frecuentes",
    "# Evidencia y trazabilidad", "# Referencias",
    "# Historial de cambios"
  )
  expect_true(all(vapply(metadata, grepl, logical(1), x = text, fixed = TRUE)))
  expect_true(all(vapply(sections, grepl, logical(1), x = text, fixed = TRUE)))
})

test_that("traceability matrix has valid minimal coverage", {
  matrix <- read.csv(
    file.path(control_dir, "matriz_trazabilidad.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required <- c(
    "requisito_id", "origen_requisito", "documento_id", "entregable",
    "fuente_controlada", "evidencia_id", "evidencia_fuente", "estado",
    "limitacion"
  )

  expect_identical(names(matrix), required)
  expect_setequal(unique(matrix$entregable), sprintf("E%02d", 1:9))
  expect_true(all(grepl("^REQ-E[0-9]{2}(-[0-9]{3})?$", matrix$requisito_id)))
  expect_true(all(grepl("^DOC-E[0-9]{2}-[A-Z]{3}-[0-9]{2}$", matrix$documento_id)))
  expect_true(all(nzchar(matrix$limitacion)))
  expect_false(any(grepl("file://|^/", matrix$fuente_controlada)))
})

test_that("controlled document chain generated valid outputs", {
  required_commands <- c("bash", "pandoc", "libreoffice", "sha256sum",
                         "unzip", "pdftotext")
  available <- nzchar(Sys.which(required_commands))
  if (!all(available)) {
    skip(paste("Missing document tools:",
               paste(required_commands[!available], collapse = ", ")))
  }

  script <- file.path(
    project_root,
    "scripts",
    "documentacion",
    "generar_documentos_controlados.sh"
  )
  generation <- system2("bash", script, stdout = TRUE, stderr = TRUE)
  expect_null(attr(generation, "status"))

  output_dir <- file.path(control_dir, "derivados")
  docx <- file.path(output_dir, "ejemplo_controlado.docx")
  pdf <- file.path(output_dir, "ejemplo_controlado.pdf")
  manifest <- file.path(output_dir, "manifiesto_generacion.csv")

  expect_true(file.exists(docx))
  expect_true(file.exists(pdf))
  expect_true(file.exists(manifest))
  expect_gt(file.info(docx)$size, 1000)
  expect_gt(file.info(pdf)$size, 1000)

  pdf_header <- readBin(pdf, what = "raw", n = 5)
  expect_identical(rawToChar(pdf_header), "%PDF-")

  generated <- read.csv(manifest, stringsAsFactors = FALSE)
  expect_setequal(generated$formato, c("DOCX", "PDF"))
  expect_true(all(grepl("^[a-f0-9]{64}$", generated$sha256_fuente)))
  expect_true(all(grepl("^[a-f0-9]{64}$", generated$sha256_salida)))

  sha256 <- function(path) {
    output <- system2("sha256sum", path, stdout = TRUE)
    strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
  }
  source <- file.path(control_dir, generated$fuente)
  outputs <- file.path(control_dir, generated$archivo)
  expect_identical(
    generated$sha256_fuente,
    unname(vapply(source, sha256, character(1)))
  )
  expect_identical(
    generated$sha256_salida,
    unname(vapply(outputs, sha256, character(1)))
  )

  docx_text <- system2(
    "pandoc",
    c(shQuote(docx), "--to=plain"),
    stdout = TRUE
  )
  pdf_text_file <- tempfile(fileext = ".txt")
  on.exit(unlink(pdf_text_file), add = TRUE)
  status <- system2("pdftotext", c(shQuote(pdf), shQuote(pdf_text_file)))
  expect_identical(status, 0L)
  pdf_text <- readLines(pdf_text_file, warn = FALSE)
  essential <- "Confirmar que una única fuente Markdown"
  expect_true(grepl(essential, paste(docx_text, collapse = " "), fixed = TRUE))
  expect_true(grepl(essential, paste(pdf_text, collapse = " "), fixed = TRUE))
})
