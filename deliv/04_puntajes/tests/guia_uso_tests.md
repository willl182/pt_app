# Guía de Uso de Tests - Entregable 04

Esta guía explica cómo ejecutar y revisar los tests del módulo de cálculo de puntajes.

## Requisitos

- R instalado.
- Paquete `testthat` disponible.
- Archivo `summary_n4.csv` presente en `pt_app/data/`.

## Ejecución rápida

Desde la carpeta del proyecto (`/home/w182/w421/pt_app`):

```r
setwd("/home/w182/w421/pt_app/deliv/04_puntajes/tests")
testthat::test_file("test_04_puntajes.R")
```

## ¿Qué validan los tests?

- Cálculo correcto de z, z', zeta y En con valores conocidos.
- Evaluación correcta de los criterios de desempeño.
- Generación de la tabla de puntajes con columnas requeridas.

## Archivos involucrados

- `R/calcula_puntajes.R`: funciones de cálculo y evaluación.
- `tests/test_04_puntajes.csv`: valores esperados para validación.
- `tests/test_04_puntajes.R`: script de pruebas.

## Resultado esperado

Los tests deben finalizar con estado **PASS** en todas las pruebas.
