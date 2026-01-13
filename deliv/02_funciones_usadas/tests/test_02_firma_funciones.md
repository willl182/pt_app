# Guía de Uso - test_02_firma_funciones.R

Este documento explica cómo ejecutar el test que valida la existencia y ejecución básica de las funciones definidas en `pt_app/R/`.

## Requisitos

- Tener instalado R.
- Paquete `testthat` disponible.
- Paquete `dplyr` recomendado para las pruebas vectorizadas.

## Ejecución desde la raíz del proyecto

```r
# Ejecutar el test específico
Rscript -e "testthat::test_file('deliv/02_funciones_usadas/tests/test_02_firma_funciones.R')"
```

## Ejecución desde el directorio de tests

```r
setwd('deliv/02_funciones_usadas/tests')
Rscript -e "testthat::test_dir('.')"
```

## Resultado esperado

El resultado esperado es que todas las pruebas reporten estado **PASS**. Si falta alguna función o no se puede ejecutar con los ejemplos mínimos, el test marcará un **FAIL** con el nombre de la función correspondiente.
