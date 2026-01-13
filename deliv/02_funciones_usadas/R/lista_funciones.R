# ===================================================================
# Titulo: lista_funciones.R
# Entregable: 02
# Descripcion: Extrae y muestra las firmas de las funciones definidas
#              en los archivos fuente utilizados por la aplicacion.
# Entrada: Archivos en pt_app/R/
# Salida: Impresion de firmas de funciones en consola
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022
# ===================================================================

obtener_directorio_base <- function() {
  script_path <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA)
  if (is.na(script_path)) {
    return(normalizePath(file.path(getwd(), "..", "..", "..")))
  }
  normalizePath(file.path(dirname(script_path), "..", "..", ".."))
}

base_dir <- obtener_directorio_base()
source_dir <- file.path(base_dir, "R")

source_files <- c(
  file.path(source_dir, "pt_homogeneity.R"),
  file.path(source_dir, "pt_robust_stats.R"),
  file.path(source_dir, "pt_scores.R"),
  file.path(source_dir, "utils.R")
)

# Cargar las funciones en un entorno temporal
entorno_funciones <- new.env()
for (archivo in source_files) {
  if (file.exists(archivo)) {
    try(source(archivo, local = entorno_funciones), silent = TRUE)
  } else {
    warning(sprintf("Archivo no encontrado: %s", archivo))
  }
}

# Obtener nombres de funciones
func_names <- sort(ls(entorno_funciones))

cat("Firmas de funciones encontradas:\n")
cat("================================\n\n")

for (name in func_names) {
  objeto <- get(name, envir = entorno_funciones)
  if (is.function(objeto)) {
    cat(name, "\n")
    args_out <- capture.output(args(objeto))
    cat(paste(args_out, collapse = "\n"), "\n")
    cat("-------------------------------\n")
  }
}
