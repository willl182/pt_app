# Guía de uso de tests (Entregable 03)

Esta guía explica cómo ejecutar los tests de cálculo de homogeneidad, estabilidad y sigma_pt.

## Requisitos

- R instalado (versión 4.0+)
- Paquete `testthat`

## Ejecutar todos los tests

Desde una sesión de R (o `Rscript`), ejecute:

```r
setwd("/home/w182/w421/pt_app/deliv/03_calculos_pt/tests")
library(testthat)

test_file("test_03_homogeneity.R")
test_file("test_03_stability.R")
test_file("test_03_sigma_pt.R")
```

## ¿Qué validan los tests?

- `test_03_homogeneity.R`: verifica estadísticos de homogeneidad contra `test_03_homogeneity.csv`.
- `test_03_stability.R`: verifica diferencias homogeneidad/estabilidad con `test_03_stability.csv`.
- `test_03_sigma_pt.R`: valida nIQR, MADe y Algoritmo A con `test_03_sigma_pt.csv`.

## Solución de problemas

- Si aparece `no se pudo abrir el archivo`, verifique las rutas absolutas en los tests.
- Si los resultados numéricos difieren, confirme que los archivos en `data/` no han sido modificados.
