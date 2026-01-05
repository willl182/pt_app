# Script de Verificación de Dependencias - PT App
# Laboratorio CALAIRE
# Fecha: 2026-01-03

cat("============================================\n")
cat("  Verificación de Dependencias - PT App\n")
cat("============================================\n\n")

# Lista de paquetes requeridos
required_packages <- c(
  "shiny",
  "tidyverse",
  "vroom",
  "DT",
  "rhandsontable",
  "shinythemes",
  "outliers",
  "patchwork",
  "bsplus",
  "plotly",
  "rmarkdown",
  "knitr",
  "kableExtra",
  "stringr"
)

# Verificar instalación
installed <- installed.packages()[, "Package"]
missing_packages <- required_packages[!(required_packages %in% installed)]

cat("Paquetes requeridos:", length(required_packages), "\n")
cat("Paquetes instalados:", length(required_packages) - length(missing_packages), "\n")
cat("Paquetes faltantes:", length(missing_packages), "\n\n")

if (length(missing_packages) > 0) {
  cat("Los siguientes paquetes NO están instalados:\n")
  for (pkg in missing_packages) {
    cat("  - ", pkg, "\n")
  }
  
  cat("\n¿Desea instalar los paquetes faltantes? (Ejecute el siguiente código):\n")
  cat("install.packages(c(\"", paste(missing_packages, collapse = "\", \""), "\"))\n\n")
  
} else {
  cat("✓ Todas las dependencias están correctamente instaladas.\n\n")
}

# Verificar versión de R
cat("Versión de R instalada:", as.character(getRversion()), "\n")
if (getRversion() < "4.0.0") {
  cat("⚠ ADVERTENCIA: Se recomienda R versión 4.0.0 o superior.\n")
} else {
  cat("✓ Versión de R compatible.\n")
}

cat("\n============================================\n")
cat("  Verificación completada\n")
cat("============================================\n")
