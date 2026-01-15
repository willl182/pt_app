# Verificación de reproducibilidad - Deliverable 09

## Objetivo

Confirmar que la generación de anexos es determinística y reproducible.

## Requisitos

- R instalado en el entorno.
- Acceso a `/home/w182/w421/pt_app/data/`.

## Ejecución

1. Ejecutar la prueba con Rscript:

   `Rscript /home/w182/w421/pt_app/deliv/09_informe_final/tests/test_09_reproducibilidad.R`

2. Validar el resultado esperado:

- La salida debe indicar: `Prueba de reproducibilidad completada sin diferencias.`
- Se deben regenerar los CSV en `/home/w182/w421/pt_app/deliv/09_informe_final/R/output/`.

## Criterio de aceptación

La prueba pasa si los archivos `resumen_pruebas.csv`, `homogeneidad_resumen.csv` y `estabilidad_resumen.csv` son idénticos entre ejecuciones consecutivas.
