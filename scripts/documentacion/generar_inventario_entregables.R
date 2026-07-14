# ===================================================================
# Auditable Inventory of PT Application Deliverables
#
# Generates a deterministic CSV inventory for Entregables_pt_app/.
# Records file role, delivery number, size, SHA-256, and Git state.
# ===================================================================

args <- commandArgs(trailingOnly = TRUE)
root_dir <- if (length(args) >= 1) args[[1]] else "."
output_file <- if (length(args) >= 2) {
  args[[2]]
} else {
  file.path(
    "Entregables_pt_app",
    "00_linea_base",
    "inventario_maestro.csv"
  )
}

root_dir <- normalizePath(root_dir, mustWork = TRUE)
deliverables_dir <- file.path(root_dir, "Entregables_pt_app")

if (!dir.exists(deliverables_dir)) {
  stop("No existe Entregables_pt_app/ en la raíz indicada.")
}

classify_role <- function(path) {
  extension <- tolower(tools::file_ext(path))

  if (grepl("(^|/)tests?/", path) || grepl("(^|/)test_", path)) {
    return("prueba")
  }
  if (grepl("(^|/)(anexos|evidencia|capturas)/", path)) {
    return("evidencia")
  }
  if (extension %in% c("docx", "pdf", "html")) {
    return("derivado")
  }
  if (extension %in% c("md", "rmd", "mmd")) {
    return("fuente_documental")
  }
  if (extension %in% c("r", "js", "py", "sh")) {
    return("ejecutable")
  }
  if (extension %in% c("csv", "tsv", "xlsx", "xls", "rds")) {
    return("dato")
  }
  "otro"
}

classify_delivery <- function(path) {
  match <- regmatches(path, regexpr("(^|/)[0-9]{2}_[^/]+", path))
  if (!length(match) || identical(match, "")) {
    return("TRANSVERSAL")
  }
  sub("^/", "", match)
}

classify_document_state <- function(path) {
  historical_files <- c(
    "app_original.R",
    "app_v06.R",
    "app_v07.R",
    "app_final.R"
  )
  if (basename(path) %in% historical_files) {
    return("historico")
  }
  if (grepl("Entregables_pt_app/00_linea_base/", path, fixed = TRUE)) {
    return("vigente_fase_1")
  }
  if (grepl("Entregables_pt_app/00_control_documental/", path,
            fixed = TRUE)) {
    if (grepl("manifiesto_fase_6.csv$", path)) {
      return("vigente_fase_6")
    }
    if (grepl("manifiesto_fase_5.csv$", path)) {
      return("vigente_fase_5")
    }
    if (grepl("manifiesto_fase_4.csv$", path)) {
      return("vigente_fase_4")
    }
    return("vigente_fase_2")
  }
  if (grepl("Entregables_pt_app/09_informe_final/", path, fixed = TRUE)) {
    return("vigente_fase_6")
  }
  "pendiente_revision"
}

sha256_file <- function(path) {
  result <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    stop("No fue posible calcular SHA-256 para: ", path)
  }
  strsplit(result[[1]], "[[:space:]]+")[[1]][[1]]
}

files <- list.files(
  deliverables_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
files <- files[!dir.exists(files)]
relative_paths <- substring(files, nchar(root_dir) + 2L)

# Avoid a self-referential checksum and keep generated temporary files out.
output_relative <- file.path("Entregables_pt_app", "00_linea_base",
                             "inventario_maestro.csv")
keep <- relative_paths != output_relative &
  !relative_paths %in% c(
    "Entregables_pt_app/00_control_documental/manifiesto_entrega.csv",
    "Entregables_pt_app/00_control_documental/checksums_entrega.sha256",
    "Entregables_pt_app/plan_documentos_formales_entregables_pt.html"
  ) &
  !grepl("(^|/)_problems/", relative_paths) &
  !grepl("(^|/)~[$]|[.]tmp$", relative_paths)
files <- files[keep]
relative_paths <- relative_paths[keep]

git_tracked <- system2(
  "git",
  c("-C", shQuote(root_dir), "ls-files", "--", "Entregables_pt_app"),
  stdout = TRUE
)
git_modified <- system2(
  "git",
  c("-C", shQuote(root_dir), "status", "--porcelain=v1", "--",
    "Entregables_pt_app"),
  stdout = TRUE
)
modified_paths <- if (length(git_modified)) {
  trimws(substring(git_modified, 4L))
} else {
  character()
}

inventory <- data.frame(
  entregable = vapply(relative_paths, classify_delivery, character(1)),
  ruta = relative_paths,
  rol = vapply(relative_paths, classify_role, character(1)),
  estado_documental = vapply(
    relative_paths,
    classify_document_state,
    character(1)
  ),
  extension = tolower(tools::file_ext(relative_paths)),
  tamano_bytes = as.numeric(file.info(files)$size),
  sha256 = vapply(files, sha256_file, character(1)),
  estado_git = ifelse(
    !relative_paths %in% git_tracked,
    "no_rastreado",
    ifelse(relative_paths %in% modified_paths, "modificado", "rastreado")
  ),
  stringsAsFactors = FALSE
)
inventory <- inventory[order(inventory$entregable, inventory$ruta), ]

output_path <- if (grepl("^/", output_file)) {
  output_file
} else {
  file.path(root_dir, output_file)
}
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(
  inventory,
  output_path,
  row.names = FALSE,
  fileEncoding = "UTF-8",
  na = ""
)

message("Inventario generado: ", output_file)
message("Archivos inventariados: ", nrow(inventory))
