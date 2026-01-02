# Script de Verificación de Dependencias - PT App
# Laboratorio CALAIRE

cat("--- Verificando librerías necesarias para PT App ---\n\n")

required_packages <- c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable", 
  "shinythemes", "outliers", "patchwork", "bsplus", 
  "plotly", "rmarkdown", "knitr", "kableExtra", "stringr"
)

missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]

if (length(missing_packages) > 0) {
  cat("Faltan los siguientes paquetes:\n")
  cat(paste("- ", missing_packages, collapse = "\n"), "\n\n")
  cat("Instalando paquetes faltantes...\n")
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
} else {
  cat("Todas las dependencias están correctamente instaladas.\n")
}

cat("\n--- Verificación completada ---\n")
