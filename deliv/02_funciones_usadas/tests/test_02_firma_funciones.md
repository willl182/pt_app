# Guía de Uso - Test 02: Verificación de Firma de Funciones

## Propósito

Este test verifica que todas las funciones principales del sistema existen y pueden ejecutarse correctamente con valores de prueba.

## Prerrequisitos

- R versión 4.0 o superior
- Paquetes R instalados:
  - `testthat`
  - `tidyverse`

Para instalar los paquetes necesarios:

```r
install.packages(c("testthat", "tidyverse"))
```

## Estructura de Verificación

El test realiza dos tipos de verificaciones:

### 1. Verificación de Existencia
- Confirma que las 18 funciones principales están definidas
- Verifica que cada función está cargada en el entorno

### 2. Verificación de Ejecución
- Ejecuta cada función con valores de prueba válidos
- Verifica que no hay errores de ejecución
- Valida que el resultado tiene el tipo esperado

## Funciones Probadas

### Estadísticos Robustos (3 funciones)
1. `calculate_niqr(x)` - nIQR (ISO 13528:2022 §9.4)
2. `calculate_mad_e(x)` - MADe (ISO 13528:2022 §9.4)
3. `run_algorithm_a(values, ids)` - Algoritmo A

### Puntajes PT (5 funciones)
4. `calculate_z_score(x, x_pt, sigma_pt)` - Puntaje z
5. `calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)` - Puntaje z'
6. `calculate_zeta_score(x, x_pt, u_x, u_xpt)` - Puntaje ζ
7. `calculate_en_score(x, x_pt, U_x, U_xpt)` - Puntaje En
8. `evaluate_z_score(z)` - Clasificación de puntajes z

### Homogeneidad (6 funciones)
9. `calculate_homogeneity_stats(sample_data)` - Estadísticos ANOVA
10. `calculate_homogeneity_criterion(sigma_pt)` - Criterio
11. `calculate_homogeneity_criterion_expanded(sigma_pt, sw_sq)` - Criterio expandido
12. `evaluate_homogeneity(ss, c_criterion)` - Evaluación
13. `calculate_stability_stats(stab_sample_data, hom_grand_mean)` - Estadísticos estabilidad
14. `calculate_stability_criterion(sigma_pt)` - Criterio estabilidad

### Estabilidad (2 funciones)
15. `evaluate_stability(diff_hom_stab, c_criterion)` - Evaluación estabilidad
16. `calculate_u_hom(ss)` - Incertidumbre homogeneidad
17. `calculate_u_stab(diff_hom_stab, c_criterion)` - Incertidumbre estabilidad

### Utilidades (1 función)
18. `evaluate_en_score(en)` - Clasificación puntajes En

## Ejecución del Test

### Opción 1: Ejecutar desde la consola de R

```r
# Ir al directorio de tests
setwd("deliv/02_funciones_usadas/tests")

# Ejecutar el test
source("test_02_firma_funciones.R")
```

### Opción 2: Ejecutar con testthat

```r
# Desde cualquier directorio
library(testthat)

# Ejecutar todos los tests en el archivo
test_file("deliv/02_funciones_usadas/tests/test_02_firma_funciones.R")
```

### Opción 3: Ejecutar desde la línea de comandos

```bash
Rscript deliv/02_funciones_usadas/tests/test_02_firma_funciones.R
```

## Salida del Test

El test genera dos salidas:

### 1. Salida en Consola

```
=== EJECUTANDO TESTS ENTREGABLE 02 ===

                           test resultado valor_esperado status
1       existe_calculate_niqr      TRUE            TRUE   PASS
2     ejecuta_calculate_niqr   EJECUTA         EJECUTA   PASS
3       existe_calculate_mad_e      TRUE            TRUE   PASS
4     ejecuta_calculate_mad_e   EJECUTA         EJECUTA   PASS
...

Guardando resultados en: ../test_02_resultados.csv

=== RESUMEN ===
Total tests: 36 
PASS: 36 
FAIL: 0
```

### 2. Archivo CSV

El archivo `test_02_resultados.csv` contiene una tabla con todos los resultados:

| test | resultado | valor_esperado | status |
|------|-----------|----------------|--------|
| existe_calculate_niqr | TRUE | TRUE | PASS |
| ejecuta_calculate_niqr | EJECUTA | EJECUTA | PASS |
| existe_calculate_mad_e | TRUE | TRUE | PASS |
| ejecuta_calculate_mad_e | EJECUTA | EJECUTA | PASS |
| ... | ... | ... | ... |

## Interpretación de Resultados

### Status PASS ✅
- **existe_XXX = TRUE:** La función está definida
- **ejecuta_XXX = EJECUTA:** La función se ejecuta sin errores

### Status FAIL ❌

Posibles causas:
- **existe_XXX = FALSE:** La función no está definida o no fue cargada
  - Solución: Verificar que el archivo R correspondiente fue cargado con `source()`
  
- **ejecuta_XXX = ERROR:** La función generó un error al ejecutarse
  - Solución: Verificar que los parámetros de prueba sean correctos
  - Revisar la implementación de la función

## Solución de Problemas

### Error: "package 'testthat' not found"
```r
install.packages("testthat")
```

### Error: "package 'tidyverse' not found"
```r
install.packages("tidyverse")
```

### Error: "could not find function XXX"
El archivo R correspondiente no fue cargado. Verifique que todas las líneas `source()` al inicio del test son correctas.

### Error de ejecución en una función específica

1. Verifique que los valores de prueba en el test sean válidos
2. Consulte la documentación de la función en `md/documentacion_funciones.md`
3. Revise la implementación en el archivo R correspondiente

## Valores de Prueba

El test utiliza valores de prueba simples para verificar que las funciones ejecutan:

```r
# Para calculate_niqr
x = c(10.1, 10.3, 10.2, 10.4, 10.0)

# Para calculate_z_score
x = 10.2, x_pt = 10.0, sigma_pt = 0.5

# Para calculate_homogeneity_stats
sample_data = matrix(c(10.1, 10.3, 10.2, 10.4, 10.0, 10.2), nrow = 3, ncol = 2)
```

**Nota:** Los valores de prueba NO son para validar la exactitud de los cálculos, solo para verificar que las funciones pueden ejecutarse sin errores.

## Próximos Pasos

Una vez que todos los tests pasen (status PASS), puede proceder con:

1. **Entregable 03:** Implementar funciones standalone para cálculos PT
2. **Entregable 04:** Implementar módulo de cálculo de puntajes
3. **Entregable 08:** Documentación final para desarrolladores

## Notas

- Este test solo verifica 18 de las 48 funciones totales identificadas
- Las funciones probadas son las principales de cálculo y evaluación
- Funciones auxiliares y utilidades pueden probarse manualmente si es necesario
- Los tipos de retorno se verifican en un test separado
- Los valores de prueba son mínimos y no representan casos reales
