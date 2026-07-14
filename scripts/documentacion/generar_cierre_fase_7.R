# ===================================================================
# Final Delivery Manifest Generator
#
# Creates the auditable file list and SHA-256 checksum set for the PT
# application documentation package. Self-referential outputs are excluded.
# ===================================================================

args <- commandArgs(trailingOnly = TRUE)
root_dir <- if (length(args)) args[[1]] else "."
root_dir <- normalizePath(root_dir, mustWork = TRUE)
package_dir <- file.path(root_dir, "Entregables_pt_app")
control_dir <- file.path(package_dir, "00_control_documental")
manifest_path <- file.path(control_dir, "manifiesto_entrega.csv")
checksums_path <- file.path(control_dir, "checksums_entrega.sha256")

files <- list.files(
  package_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
files <- files[!dir.exists(files)]
relative_paths <- substring(files, nchar(root_dir) + 2L)
excluded <- c(
  "Entregables_pt_app/00_control_documental/manifiesto_entrega.csv",
  "Entregables_pt_app/00_control_documental/checksums_entrega.sha256",
  "Entregables_pt_app/plan_documentos_formales_entregables_pt.html"
)
keep <- !relative_paths %in% excluded &
  !grepl("(^|/)_problems/", relative_paths) &
  !grepl("(^|/)~[$]|[.]tmp$", relative_paths)
files <- files[keep]
relative_paths <- relative_paths[keep]

sha256_file <- function(path) {
  output <- system2("sha256sum", path, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0) {
    stop("No fue posible calcular SHA-256 para: ", path)
  }
  strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
}

delivery_id <- function(path) {
  match <- regmatches(path, regexpr("Entregables_pt_app/[0-9]{2}_[^/]+", path))
  if (!length(match) || identical(match, "")) {
    return("TRANSVERSAL")
  }
  id <- sub("Entregables_pt_app/([0-9]{2}).*", "\\1", match)
  if (identical(id, "00")) "TRANSVERSAL" else paste0("E", id)
}

manifest <- data.frame(
  entregable = vapply(relative_paths, delivery_id, character(1)),
  ruta = relative_paths,
  tamano_bytes = as.numeric(file.info(files)$size),
  sha256 = vapply(files, sha256_file, character(1)),
  stringsAsFactors = FALSE
)
manifest <- manifest[order(manifest$entregable, manifest$ruta), ]

write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  fileEncoding = "UTF-8",
  na = ""
)
checksum_lines <- paste(manifest$sha256, manifest$ruta)
writeLines(checksum_lines, checksums_path, useBytes = TRUE)

message("Manifiesto final generado: ", nrow(manifest), " archivos.")
