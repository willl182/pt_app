# Guía de Uso - Test 01: Verificación de Archivos Originales

## Propósito

Este test verifica la integridad y completitud de los archivos copiados en el Entregable 01, asegurando que son copias exactas de los archivos originales.

## Prerrequisitos

- R versión 4.0 o superior
- Paquetes R instalados:
  - `testthat`
  - `digest`

Para instalar los paquetes necesarios:

```r
install.packages(c("testthat", "digest"))
```

## Estructura de Verificación

El test realiza tres tipos de verificaciones:

### 1. Verificación de Existencia
- Confirma que los 5 archivos originales existen en `pt_app/`
- Confirma que las 5 copias existen en `deliv/01_repo_inicial/`

**Archivos verificados:**
- `app.R` / `app_original.R`
- `R/pt_homogeneity.R`
- `R/pt_robust_stats.R`
- `R/pt_scores.R`
- `R/utils.R`

### 2. Verificación de Hash SHA256
- Calcula el hash SHA256 de cada archivo original
- Calcula el hash SHA256 de cada copia
- Compara que sean idénticos

Esto garantiza que no hubo modificaciones en los archivos.

### 3. Verificación de Sintaxis R
- Ejecuta `parse()` en cada archivo `.R`
- Verifica que no haya errores de sintaxis

Esto asegura que el código R es válido y puede ser interpretado.

## Ejecución del Test

### Opción 1: Ejecutar desde la consola de R

```r
# Ir al directorio de tests
setwd("deliv/01_repo_inicial/tests")

# Ejecutar el test
source("test_01_existencia_archivos.R")
```

### Opción 2: Ejecutar con testthat

```r
# Desde cualquier directorio
library(testthat)

# Ejecutar todos los tests en el archivo
test_file("deliv/01_repo_inicial/tests/test_01_existencia_archivos.R")
```

### Opción 3: Ejecutar desde la línea de comandos

```bash
Rscript deliv/01_repo_inicial/tests/test_01_existencia_archivos.R
```

## Salida del Test

El test genera dos salidas:

### 1. Salida en Consola

```
=== EJECUTANDO TESTS ENTREGABLE 01 ===

                    test  resultado                 valor_esperado status
1       existencia_orig_app_R                     TRUE            PASS
2 existencia_orig_R_pt_homogeneity_R            TRUE            PASS
3 existencia_orig_R_pt_robust_stats_R           TRUE            PASS
4     existencia_orig_R_pt_scores_R              TRUE            PASS
5        existencia_orig_R_utils_R               TRUE            PASS
6           hash_app_R       a1b2c3...             a1b2c3...     PASS
7     hash_pt_homogeneity    d4e5f6...             d4e5f6...     PASS
...

=== RESUMEN ===
Total tests: 15
PASS: 15
FAIL: 0

Resultados guardados en: deliv/01_repo_inicial/test_01_resultados.csv
```

### 2. Archivo CSV

El archivo `test_01_resultados.csv` contiene una tabla con todos los resultados:

| test | resultado | valor_esperado | status |
|------|-----------|----------------|--------|
| existencia_orig_app_R | TRUE | TRUE | PASS |
| hash_app_R | a1b2c3... | a1b2c3... | PASS |
| sintaxis_app_original | TRUE | TRUE | PASS |
| ... | ... | ... | ... |

## Interpretación de Resultados

### Status PASS ✅
- El archivo existe y es correcto
- El hash coincide con el original
- La sintaxis R es válida

### Status FAIL ❌
Posibles causas:
- **Falta archivo original:** El archivo no existe en `pt_app/`
- **Falta archivo copia:** El archivo no fue copiado a `deliv/01_repo_inicial/`
- **Hash diferente:** El archivo fue modificado accidentalmente
- **Error de sintaxis:** El archivo tiene errores de código R

## Solución de Problemas

### Error: "package 'digest' not found"
```r
install.packages("digest")
```

### Error: "package 'testthat' not found"
```r
install.packages("testthat")
```

### Error: "File does not exist"
Verifique que está ejecutando el test desde el directorio correcto o ajuste las rutas relativas en el script.

### Error de sintaxis en un archivo
Si un archivo tiene errores de sintaxis, revise el archivo original. No intente corregir el error en el entregable, ya que debe ser una copia exacta del original.

## Próximos Pasos

Una vez que todos los tests pasen (status PASS), puede proceder con:

1. **Entregable 02:** Documentar las funciones usadas en `app.R`
2. Revisar las funciones identificadas para entender su propósito

## Notas

- Los hashes SHA256 son únicos por contenido. Cualquier cambio en el archivo (incluso un espacio) generará un hash diferente.
- La validación de sintaxis no ejecuta el código, solo verifica que puede ser parseado correctamente.
- Este test debe ejecutarse antes de modificar cualquier archivo, para tener una línea base verificada.
