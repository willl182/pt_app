# Guía de Prueba - Test End-to-End (Entregable 08)

**Entregable:** 08 - Versión Beta y Documentación Final  
**Test:** `test_08_end_to_end.R`  
**Fecha:** 2026-01-24  

---

## Descripción del Test

Este test valida el flujo completo de la aplicación final, incluyendo:

1. Carga correcta de todas las funciones
2. Cálculo de todos los tipos de puntajes (z, z', zeta, En)
3. Funciones de evaluación de puntajes
4. Estadísticos robustos (nIQR, MADe, Algoritmo A)
5. Cálculos de homogeneidad y estabilidad
6. Verificación de archivos de datos
7. Funciones de resumen y utilidad

---

## Cómo Ejecutar el Test

### Opción 1: Desde la Consola de R

```r
# Desde el directorio raíz del proyecto
setwd("/home/w182/w421/pt_app")

# Ejecutar el test
testthat::test_file("deliv/08_beta/tests/test_08_end_to_end.R")
```

### Opción 2: Desde Terminal

```bash
# Desde el directorio raíz del proyecto
cd /home/w182/w421/pt_app

# Ejecutar el test usando Rscript
Rscript -e "testthat::test_file('deliv/08_beta/tests/test_08_end_to_end.R')"
```

### Opción 3: Desde RStudio

1. Abrir `deliv/08_beta/tests/test_08_end_to_end.R` en RStudio
2. Click en el botón "Source" o presionar `Ctrl+Shift+Enter`
3. Ver resultados en la consola

---

## Pruebas Unitarias Incluidas

### 1. `Funciones finales se cargan correctamente`
- Verifica que `funciones_finales.R` se carga sin errores
- Confirma existencia de funciones clave:
  - `calculate_z_score`
  - `calculate_z_prime_score`
  - `calculate_zeta_score`
  - `calculate_en_score`
  - `evaluate_z_score`
  - `evaluate_en_score`
  - `calculate_niqr`
  - `calculate_mad_e`
  - `run_algorithm_a`
  - `calculate_homogeneity_stats`

### 2. `Cálculo de puntajes z funciona correctamente`
- Caso básico: z = 2.0 para x=10.5, x_pt=10.0, sigma_pt=0.25
- Caso negativo: z = -2.0
- Caso con sigma_pt inválido debe retornar NA
- Caso con NA debe retornar NA

### 3. `Evaluación de puntajes z funciona correctamente`
- z=1.5 → "Satisfactorio"
- z=2.5 → "Cuestionable"
- z=3.5 → "No satisfactorio"
- z=NA → "N/A"

### 4. `Cálculo de nIQR funciona correctamente`
- Cálculo con datos válidos debe retornar valor finito > 0
- Menos de 2 valores debe retornar NA

### 5. `Cálculo de MADe funciona correctamente`
- Cálculo con datos válidos debe retornar valor finito ≥ 0
- Vector vacío debe retornar NA

### 6. `Algoritmo A funciona correctamente`
- Ejecución exitosa con 7 valores
- Verifica: `assigned_value`, `robust_sd`, `converged`, `weights`
- Menos de 3 valores debe retornar error

### 7. `Cálculo de puntajes z' funciona correctamente`
- Cálculo básico retorna valor finito
- Denominador inválido retorna NA

### 8. `Cálculo de puntajes zeta funciona correctamente`
- Cálculo básico retorna valor finito
- Denominador inválido retorna NA

### 9. `Cálculo de puntajes En funciona correctamente`
- Cálculo básico retorna valor finito
- Denominador inválido retorna NA

### 10. `Evaluación de puntajes En funciona correctamente`
- En=0.8 → "Satisfactorio"
- En=1.5 → "No satisfactorio"
- En=NA → "N/A"

### 11. `Cálculo de estadísticos de homogeneidad funciona correctamente`
- Matriz 10x3 de datos de prueba
- Verifica: g=10, m=3, grand_mean, s_xt, sw, ss finitos y válidos

### 12. `Cálculo de criterio de homogeneidad funciona correctamente`
- sigma_pt=0.5 → c=0.15

### 13. `Cálculo de criterio expandido de homogeneidad funciona correctamente`
- Retorna valor finito > 0

### 14. `Evaluación de homogeneidad funciona correctamente`
- ss ≤ c → "Aceptable"
- ss > c → "No aceptable"
- NA → "N/A"

### 15. `Cálculo de estadísticos de estabilidad funciona correctamente`
- Verifica: stab_mean, difference finitos y válidos

### 16. `Evaluación de estabilidad funciona correctamente`
- difference ≤ criterion → "Estable"
- difference > criterion → "No estable"
- NA → "N/A"

### 17. `Cálculo de puntajes para múltiples participantes funciona correctamente`
- 3 participantes con diferentes valores
- Verifica columnas: z_score, z_prime_score, zeta_score, En_score, *_eval

### 18. `Resumen de puntajes de participante funciona correctamente`
- Cuenta de satisfactorio, cuestionable, no satisfactorio
- Para z y En

### 19. `Archivos de datos existen y tienen formato correcto`
- Verifica existencia de 4 archivos CSV en `data/`
- Verifica columnas clave en cada archivo

---

## Resultados Esperados

Al ejecutar el test correctamente, debería ver algo como:

```
Test passed: Functions loaded correctly
Test passed: z-score calculation works
Test passed: z-score evaluation works
...
Test passed: Data files exist and have correct format

=== Test 08 completado ===
```

**Total esperado:** 19 tests  
**Estado esperado:** Todos PASS (100%)

---

## Solución de Problemas

### Error: "No se pudo cargar funciones_finales.R"

**Solución:**
- Verificar que el archivo existe en `deliv/08_beta/R/funciones_finales.R`
- Verificar que hay permisos de lectura
- Ejecutar `source("deliv/08_beta/R/funciones_finales.R")` manualmente

### Error: "No se encontró archivo de datos"

**Solución:**
- Verificar que los archivos CSV existen en `data/`
- Ejecutar `list.files("data/")` para ver archivos disponibles
- Verificar rutas relativas (el test asume ejecución desde `pt_app/`)

### Error: "Test falla en Algoritmo A no converge"

**Solución:**
- Esto puede ocurrir aleatoriamente con ciertos conjuntos de datos
- El Algoritmo A puede no converger para datos con alta dispersión
- Reejecutar el test

### Error: "Valor esperado diferente del obtenido"

**Solución:**
- Revisar el mensaje de error específico
- Verificar implementación de la función
- Consultar la documentación en `funciones_finales.R`

---

## Manual de Verificación (Opcional)

Para verificación manual, puede ejecutar el siguiente script:

```r
# Cargar funciones
source("deliv/08_beta/R/funciones_finales.R")

# Prueba rápida de cálculo z
z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.25)
cat("z-score:", z, "\n")

# Prueba de evaluación
eval <- evaluate_z_score(z = 2.0)
cat("Evaluación:", eval, "\n")

# Prueba de nIQR
datos <- c(10.2, 10.5, 10.3, 10.6, 10.4)
niqr <- calculate_niqr(datos)
cat("nIQR:", niqr, "\n")

# Prueba de Algoritmo A
res <- run_algorithm_a(datos)
cat("Valor asignado:", res$assigned_value, "\n")
cat("Desviación robusta:", res$robust_sd, "\n")
cat("Convergió:", res$converged, "\n")
```

---

## Checklist de Validación

Antes de marcar el entregable como completado, verificar:

- [ ] Todos los tests pasan (19/19 PASS)
- [ ] `app_final.R` se ejecuta sin errores
- [ ] Todos los archivos CSV están presentes en `data/`
- [ ] Las gráficas se renderizan correctamente
- [ ] Los botones de descarga generan archivos CSV válidos
- [ ] `manual_desarrollador.md` está completo y actualizado

---

**Última actualización:** 2026-01-24
