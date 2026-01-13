# Entregable 01 - Repositorio de código y scripts iniciales

## Propósito
Este entregable tiene como objetivo crear un snapshot del código original de la aplicación como línea base del proyecto. Proporciona una copia íntegra de los archivos fuente y scripts iniciales antes de cualquier modificación o refactorización, asegurando la reproducibilidad de los resultados originales.

Este repositorio de código sirve como referencia fundamental y cumple con los requisitos de documentación de la norma **ISO 13528:2022** para la gestión de datos y algoritmos en ensayos de aptitud.

## Archivos Incluidos

- **app_original.R**: Copia exacta del archivo `app.R` original de la aplicación.
- **R/pt_homogeneity.R**: Contiene las funciones originales para el análisis de homogeneidad y estabilidad.
- **R/pt_robust_stats.R**: Implementación de los estimadores estadísticos robustos (nIQR, MADe y Algoritmo A).
- **R/pt_scores.R**: Funciones para el cálculo de los puntajes de desempeño (z, z', ζ, En).
- **R/utils.R**: Funciones utilitarias originales (deprecadas).
- **ptcalc/**: Paquete R completo con documentación roxygen2 y estructura estándar de paquete.
  - `DESCRIPTION`: Metadatos del paquete.
  - `NAMESPACE`: Exportaciones del paquete.
  - `R/`: Funciones del paquete.
  - `man/`: Documentación generada.
  - `LICENSE`: Licencia del paquete.
  - `README.md`: Documentación del paquete.
- **data/homogeneity.csv**: Datos de homogeneidad (622 líneas).
- **data/stability.csv**: Datos de estabilidad.
- **data/summary_n4.csv**: Datos consolidados de participantes (361 líneas).
- **data/participants_data4.csv**: Tabla de instrumentación (5 líneas).
- **reports/report_template.Rmd**: Plantilla RMarkdown para generación de informes.
- **tests/test_01_existencia_archivos.R**: Test automatizado utilizando el framework `testthat` para verificar la integridad del repositorio.
- **tests/test_01_existencia_archivos.md**: Guía técnica detallada sobre la ejecución y alcance del test.

## Ejecución de Pruebas

Para validar la correcta disposición e integridad de los archivos de este entregable, puede ejecutar los tests de la siguiente manera:

### Desde la consola de R
```r
library(testthat)
test_file("deliv/01_repo_inicial/tests/test_01_existencia_archivos.R")
```

### Desde la línea de comandos
```bash
Rscript deliv/01_repo_inicial/tests/test_01_existencia_archivos.R
```

El test verificará la existencia de todos los componentes listados y validará la correspondencia con los archivos originales.

## Referencias
- **ISO 13528:2022**: Statistical methods for use in proficiency testing by interlaboratory comparison.
