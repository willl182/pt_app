# Manual del desarrollador - Entregable 08

## Arquitectura del sistema

- **Capa de datos**: archivos CSV en `pt_app/data/` con homogeneidad, estabilidad, resumen y tabla de participantes.
- **Capa de calculo**: funciones standalone en `deliv/08_beta/R/funciones_finales.R` para homogeneidad, estabilidad, robustez y puntajes.
- **Capa de presentacion**: `deliv/08_beta/app_final.R` monta la interfaz Shiny con tablas DT y graficos interactivos.

## Dependencias

Paquetes requeridos para ejecutar la version beta:

- `shiny`
- `DT`
- `dplyr`
- `tidyr`
- `ggplot2`
- `plotly`

Los paquetes base de R (`stats`, `utils`) se usan para calculos estadisticos y lectura de datos.

## Como extender o modificar

1. **Agregar nuevas metricas**
   - Añadir la funcion en `R/funciones_finales.R`.
   - Incluir la nueva metrica en `calculate_scores_table()` si aplica.
   - Agregar una columna en la tabla de puntajes o un grafico nuevo en `app_final.R`.

2. **Cambiar fuentes de datos**
   - Reemplazar los CSV en `pt_app/data/` manteniendo las columnas requeridas.
   - Verificar que `homogeneity.csv` y `stability.csv` tengan `pollutant`, `level`, `sample_id`, `replicate`, `value`.
   - Verificar que `summary_n4.csv` tenga `pollutant`, `level`, `participant_id`, `mean_value`, `sd_value`.

3. **Agregar una nueva vista**
   - Crear un nuevo `tabPanel()` en `app_final.R`.
   - Reutilizar los reactivos existentes o crear uno nuevo para la logica.

## Troubleshooting comun

- **Error al cargar datos**: confirmar que la ruta relativa `../../data` existe desde `deliv/08_beta/`.
- **Columnas faltantes**: validar nombres exactos en los CSV segun la seccion de cambios de datos.
- **Graficos vacios**: revisar que la combinacion analito/nivel tenga datos en los CSV.
- **Puntajes NA**: revisar que `sigma_pt` sea finito y que existan participantes distintos de `ref`.
- **Fallo en testthat**: ejecutar desde la raiz del repositorio para que las rutas relativas se resuelvan correctamente.
