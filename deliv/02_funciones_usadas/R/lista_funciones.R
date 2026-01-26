# ===================================================================
# Titulo: lista_funciones.R
# Entregable: 02
# Descripcion: Extrae y documenta todas las funciones usadas en app.R y reports/
# Entrada: pt_app/app.R, pt_app/R/*.R, pt_app/reports/report_template.Rmd
# Salida: Lista de funciones con firmas y metadata
# Referencia: N/A
# ===================================================================

library(roxygen2)
library(tidyverse)

# Directorios
app_file <- "../../../app.R"
r_dir <- "../../../R/"
reports_dir <- "../../../reports/"

cat("Directorio de trabajo actual:", getwd(), "\n")
cat("Archivo app.R:", app_file, "- Existe:", file.exists(app_file), "\n")
cat("Directorio R/:", r_dir, "- Existe:", dir.exists(r_dir), "\n")
cat("Directorio reports/:", reports_dir, "- Existe:", dir.exists(reports_dir), "\n\n")

# Función para extraer firmas de funciones
extraer_firmas <- function(archivo) {
  if (!file.exists(archivo)) {
    return(tibble(
      archivo = basename(archivo),
      nombre_funcion = character(),
      descripcion = character(),
      parametros = character(),
      retorno = character(),
      referencia_iso = character()
    ))
  }
  
  # Leer archivo
  contenido <- readLines(archivo)
  
  # Buscar definiciones de funciones
  patrones_funciones <- c(
    "^([a-zA-Z_][a-zA-Z0-9_.]*)[[:space:]]*<-[[:space:]]*function[[:space:]]*(\\()",
    "^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_.]*)[[:space:]]*<-[[:space:]]*function[[:space:]]*(\\()",
    "^([a-zA-Z_][a-zA-Z0-9_.]*)[[:space:]]*=[[:space:]]*function[[:space:]]*(\\()"
  )
  
  nombres_funciones <- character()
  descripciones <- character()
  parametros <- character()
  referencias_iso <- character()
  
  cat("Procesando archivo:", basename(archivo), "\n")
  for (i in seq_along(contenido)) {
    linea <- contenido[i]
    
    # Buscar definición de función
    for (patron in patrones_funciones) {
      match <- regmatches(linea, regexec(patron, linea))[[1]]
      if (length(match) >= 2) {
        nombre_funcion <- match[2]
        nombres_funciones <- c(nombres_funciones, nombre_funcion)
        
        # Buscar descripción en líneas anteriores (roxygen2)
        descripcion <- ""
        referencia <- ""
        
        if (i > 1) {
          # Buscar hacia atrás para encontrar la documentación roxygen2
          j <- i - 1
          while (j >= 1 && grepl("^#'", contenido[j])) {
            doc_linea <- contenido[j]
            
            # Extraer descripción principal
            if (grepl("^#'[[:space:]]*[^@]", doc_linea) && descripcion == "") {
              descripcion <- sub("^#'[[:space:]]*", "", doc_linea)
            }
            
            # Extraer referencia ISO
            if (grepl("Reference:", doc_linea)) {
              referencia <- sub(".*Reference:[[:space:]]*", "", doc_linea)
              referencia <- trimws(referencia)
            }
            
            j <- j - 1
          }
        }
        
        descripciones <- c(descripciones, descripcion)
        referencias_iso <- c(referencias_iso, referencia)
        
        # Extraer parámetros
        params <- ""
        if (i < length(contenido)) {
          k <- i
          parentesis_abiertos <- 0
          parentesis_cerrados <- 0
          param_lineas <- ""
          
          while (k <= length(contenido)) {
            linea_actual <- contenido[k]
            parentesis_abiertos <- parentesis_abiertos + str_count(linea_actual, "\\(")
            parentesis_cerrados <- parentesis_cerrados + str_count(linea_actual, "\\)")
            param_lineas <- paste0(param_lineas, linea_actual)
            
            if (parentesis_abiertos > 0 && parentesis_abiertos == parentesis_cerrados) {
              break
            }
            k <- k + 1
          }
          
          # Extraer contenido entre paréntesis
          match_params <- regmatches(param_lineas, regexec("\\((.*)\\)", param_lineas))[[1]]
          if (length(match_params) >= 2) {
            params <- match_params[2]
            params <- trimws(params)
          }
        }
        
        parametros <- c(parametros, params)
      }
    }
  }
  
  if (length(nombres_funciones) == 0) {
    return(tibble(
      archivo = basename(archivo),
      nombre_funcion = character(),
      descripcion = character(),
      parametros = character(),
      retorno = character(),
      referencia_iso = character()
    ))
  }
  
  tibble(
    archivo = basename(archivo),
    nombre_funcion = nombres_funciones,
    descripcion = descripciones,
    parametros = parametros,
    retorno = NA_character_,
    referencia_iso = referencias_iso
  )
}

# Función para procesar directorio de archivos R
procesar_directorio <- function(directorio) {
  archivos_r <- list.files(directorio, pattern = "\\.R$", full.names = TRUE)
  
  todas_funciones <- map_dfr(archivos_r, extraer_firmas)
  return(todas_funciones)
}

# Procesar todos los archivos
cat("Procesando archivos...\n\n")

# Archivos R en el directorio R/
funciones_R <- procesar_directorio(r_dir)
cat("Funciones en R/:", nrow(funciones_R), "\n")

# Archivo app.R
funciones_app <- extraer_firmas(app_file)
cat("Funciones en app.R:", nrow(funciones_app), "\n")

# Report template (opcional)
report_template <- file.path(reports_dir, "report_template.Rmd")
if (file.exists(report_template)) {
  funciones_report <- extraer_firmas(report_template)
  cat("Funciones en reports/:", nrow(funciones_report), "\n")
} else {
  funciones_report <- tibble(
    archivo = character(),
    nombre_funcion = character(),
    descripcion = character(),
    parametros = character(),
    retorno = character(),
    referencia_iso = character()
  )
}

# Combinar todas las funciones
todas_funciones <- bind_rows(
  funciones_R,
  funciones_app,
  funciones_report
)

cat("\nTotal funciones encontradas:", nrow(todas_funciones), "\n\n")

# Eliminar duplicados por nombre de función
todas_funciones <- todas_funciones %>%
  group_by(nombre_funcion) %>%
  slice(1) %>%
  ungroup()

cat("Total funciones únicas:", nrow(todas_funciones), "\n\n")

# Guardar en CSV
write.csv(todas_funciones, "../md/funciones_extraidas.csv", row.names = FALSE)
cat("Resultados guardados en: deliv/02_funciones_usadas/md/funciones_extraidas.csv\n\n")

# Imprimir resumen
cat("=== RESUMEN DE FUNCIONES ===\n\n")
print(todas_funciones %>% select(nombre_funcion, archivo, referencia_iso))

# Guardar versión formateada en markdown
crear_markdown_documentacion <- function(funciones) {
  contenido <- "# Documentación de Funciones\n\n"
  contenido <- paste0(contenido, "**Fecha de generación:** ", Sys.time(), "\n\n")
  contenido <- paste0(contenido, "**Total funciones:** ", nrow(funciones), "\n\n")
  contenido <- paste0(contenido, "---\n\n")
  
  for (i in seq_len(nrow(funciones))) {
    f <- funciones[i, ]
    contenido <- paste0(contenido, "## `", f$nombre_funcion, "`\n\n")
    
    if (!is.na(f$descripcion) && f$descripcion != "") {
      contenido <- paste0(contenido, f$descripcion, "\n\n")
    }
    
    contenido <- paste0(contenido, "**Archivo:** `", f$archivo, "`\n\n")
    
    if (!is.na(f$parametros) && f$parametros != "") {
      contenido <- paste0(contenido, "**Parámetros:** `", f$parametros, "`\n\n")
    }
    
    if (!is.na(f$referencia_iso) && f$referencia_iso != "") {
      contenido <- paste0(contenido, "**Referencia ISO:** ", f$referencia_iso, "\n\n")
    }
    
    contenido <- paste0(contenido, "---\n\n")
  }
  
  writeLines(contenido, "../md/documentacion_funciones.md")
}

crear_markdown_documentacion(todas_funciones)
cat("Documentación Markdown guardada en: deliv/02_funciones_usadas/md/documentacion_funciones.md\n")
