# Guia de Uso - Test 01: Existencia de Archivos

## Descripcion

Este test verifica que el Entregable 01 contenga copias exactas de los archivos
originales del repositorio pt_app. Valida:

1. **Existencia de archivos originales** en `pt_app/R/`
2. **Existencia de copias** en `deliv/01_repo_inicial/R/`
3. **Correspondencia SHA256** entre originales y copias
4. **Existencia de app_original.R**
5. **Sintaxis R basica** (parentesis, llaves y corchetes balanceados)

## Archivos Verificados

| Archivo | Descripcion |
|---------|-------------|
| `pt_homogeneity.R` | Funciones de homogeneidad y estabilidad |
| `pt_robust_stats.R` | Estimadores estadisticos robustos |
| `pt_scores.R` | Calculo de puntajes z, z', zeta, En |
| `utils.R` | Funciones utilitarias (deprecadas) |
| `app_original.R` | Copia de la aplicacion Shiny original |

## Requisitos

```r
install.packages(c("testthat", "digest"))
```

## Ejecucion

### Opcion 1: Desde linea de comandos

```bash
cd pt_app/deliv/01_repo_inicial/tests
Rscript -e "testthat::test_file('test_01_existencia_archivos.R')"
```

### Opcion 2: Desde R interactivo

```r
setwd("pt_app/deliv/01_repo_inicial/tests")
library(testthat)
test_file("test_01_existencia_archivos.R")
```

### Opcion 3: Ejecutar todos los tests del entregable

```r
testthat::test_dir("pt_app/deliv/01_repo_inicial/tests")
```

## Interpretacion de Resultados

| Status | Significado |
|--------|-------------|
| `PASS` | El test paso correctamente |
| `FAIL` | El test fallo - revisar mensaje de error |
| `SKIP` | El test fue omitido |

## Formato de Salida

Los resultados se presentan como data.frame con las columnas:

| Columna | Descripcion |
|---------|-------------|
| `test` | Nombre del test |
| `resultado` | Valor obtenido |
| `valor_esperado` | Valor esperado |
| `status` | PASS o FAIL |

## Solucion de Problemas

### Error: "Archivo original no encontrado"

Verificar que los archivos existen en `pt_app/R/`:
```bash
ls -la pt_app/R/
```

### Error: "Hash no coincide"

Los archivos fueron modificados despues de la copia. Regenerar las copias:
```bash
cp pt_app/R/*.R pt_app/deliv/01_repo_inicial/R/
```

### Error: "Parentesis desbalanceados"

El archivo tiene un error de sintaxis. Revisar manualmente el archivo indicado.

## Referencia

- ISO 13528:2022 - Metodos estadisticos para ensayos de aptitud
- Entregable 01: Repositorio de codigo y scripts iniciales
