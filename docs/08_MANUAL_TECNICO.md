# Manual Técnico y de Despliegue

## Requisitos del Sistema
*   **R:** Versión 4.0.0 o superior.
*   **Paquetes R:**
    *   `shiny`, `tidyverse`, `vroom`, `DT`, `rhandsontable`, `shinythemes`, `outliers`, `patchwork`, `bsplus`, `plotly`, `rmarkdown`, `knitr`, `kableExtra`.

## Estructura del Código
*   `app.R`: Punto de entrada principal. Contiene la definición de UI y Server.
*   `R/`: Módulos de funciones estadísticas.
    *   `robust_stats.R`: Algoritmo A, nIQR.
    *   `homogeneity_stability.R`: Lógica ANOVA y criterios de estabilidad.
    *   `scores.R`: Cálculo de puntajes Z, En, etc.
*   `reports/report_template.Rmd`: Plantilla Parametrizada para generación de informes Word.

## Despliegue Local
1.  Clonar el repositorio.
2.  Abrir RStudio o terminal en la raíz del proyecto.
3.  Instalar dependencias:
    ```r
    install.packages(c("shiny", "tidyverse", "vroom", "DT", "rhandsontable", "shinythemes", "outliers", "patchwork", "bsplus", "plotly", "rmarkdown"))
    ```
4.  Ejecutar la app:
    ```r
    shiny::runApp("app.R")
    ```

## Mantenimiento
*   **Actualización de cálculos:** Modificar los archivos en `R/`. Reiniciar la app para que tome los cambios (si se usa `source`).
*   **Modificación del reporte:** Editar `reports/report_template.Rmd`. No es necesario reiniciar la app, ya que se renderiza en cada descarga.
