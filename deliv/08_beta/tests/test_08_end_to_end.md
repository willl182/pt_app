# Guia de prueba integral - Entregable 08

## Objetivo

Verificar el flujo completo de calculos de homogeneidad, estabilidad, valor asignado y puntajes usando los datos fijos de `data/`.

## Requisitos

- Tener instalados los paquetes `testthat`, `dplyr`, `tidyr`, `ggplot2`, `plotly`, `DT`, `shiny`.
- Ejecutar desde la raiz del repositorio `pt_app`.

## Ejecucion

```r
# Desde la raiz del repositorio
setwd("/home/w182/w421/pt_app")

testthat::test_file("deliv/08_beta/tests/test_08_end_to_end.R")
```

## Resultado esperado

- Todos los tests deben finalizar en **PASS**.
- Se valida la lectura de archivos y calculos principales.

## Que hacer si falla

- Revisar que `deliv/08_beta/R/funciones_finales.R` exista.
- Verificar nombres de columnas en los CSV (`homogeneity.csv`, `stability.csv`, `summary_n4.csv`).
- Confirmar que el directorio `data/` existe dos niveles arriba de `deliv/08_beta/`.
