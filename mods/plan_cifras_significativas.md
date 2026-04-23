# Plan de Cambio: Cifras Significativas en el Algoritmo A

**Fecha:** 2026-04-20  
**Estado:** Completado  
**Prioridad:** Alta — afecta la fidelidad al estándar ISO 13528:2022

---

## 1. Problema Identificado

### 1.1 Descripción

El Algoritmo A actualmente usa dos enfoques de precisión que no son consistentes entre sí ni con el estándar ISO 13528:2022:

| Componente | Implementación actual | Lo que dice ISO 13528:2022 |
|---|---|---|
| Criterio de convergencia (`pt_robust_stats.R:259`) | Tolerancia absoluta `1e-06` | "no change in the **3rd significant figure**" (NOTE 1) |
| Formato de salida (`app.R:210`) | `sprintf("%.5f", x)` — 5 decimales fijos | Implícito: 3 cifras significativas |

### 1.2 Impacto

La tolerancia absoluta `1e-06` produce resultados **magnitud-dependientes** incorrectos:

- Para un valor ~60 (SO₂ a 60 nmol/mol): `1e-06` es un criterio **200,000× más estricto** de lo necesario. El algoritmo itera de más.
- Para un valor ~0.02 (CO a 0 µmol/mol): `1e-06` es **más laxo** que 3 cifras significativas en esa magnitud, lo que puede detener el algoritmo prematuramente.

El formato de salida de 5 decimales fijos también es inconsistente: para un valor de 60.5, mostrar `60.50000` implica una precisión de 7 cifras significativas cuando el estándar solo exige 3.

---

## 2. Principio Correcto: Cifras Significativas

### 2.1 Definición aplicada

**3 cifras significativas** según la magnitud del valor:

| Rango del valor | Formato | Ejemplo entrada | Ejemplo salida |
|---|---|---|---|
| 0 < \|x\| < 10 | `#.##` | 9.8765 | **9.88** |
| 10 ≤ \|x\| < 100 | `##.#` | 60.451 | **60.5** |
| 100 ≤ \|x\| < 1000 | `###` | 456.7 | **457** |

Equivalente a `signif(x, 3)` en R, pero expresado explícitamente por rango para mayor claridad en validación.

### 2.2 Convergencia correcta (ISO 13528:2022 NOTE 1)

El criterio de parada de la iteración debe ser:

```r
# Convergencia cuando x* y s* no cambian en su 3ª cifra significativa
signif(x_new, 3) == signif(x_star, 3) &&
signif(s_new, 3) == signif(s_star, 3)
```

Este criterio es exactamente el que implementa la función deprecada `algorithm_A()` en `utils.R:44`. La función moderna `run_algorithm_a()` debe adoptar este comportamiento.

---

## 3. Cambios Requeridos

### Cambio 1 — Criterio de convergencia en `run_algorithm_a()`

**Archivo:** `R/pt_robust_stats.R`  
**Línea actual:** 259–262  
**Línea @param:** 96 (documentación del parámetro `tol`)

**Antes:**
```r
if (delta_x < tol && delta_s < tol) {
  converged <- TRUE
  break
}
```

**Después:**
```r
if (signif(x_new, 3) == signif(x_star, 3) &&
    signif(s_new, 3) == signif(s_star, 3)) {
  converged <- TRUE
  break
}
```

**Impacto colateral:**
- El parámetro `tol` queda sin efecto en el criterio principal. Debe mantenerse como **guardia de seguridad numérica** (e.g., `tol = 1e-10` para colapso numérico), no como criterio primario de convergencia.
- Actualizar el `@param tol` en la documentación.
- Actualizar el mensaje en `@details` línea 86: "Repeat until convergence (changes < tolerance)" → "Repeat until no change in 3rd significant figure".
- El campo `tolerance` guardado en la lista de salida (línea 215, 301) debe actualizarse o puede mantenerse como referencia de la guardia numérica.

**También en:** `ptcalc/R/pt_robust_stats.R` si existe copia sincronizada.

---

### Cambio 2 — Formato de salida numérica en `app.R`

**Archivo:** `app.R`  
**Línea actual:** 206–211

**Antes:**
```r
format_num <- function(x) {
  if (length(x) == 0) {
    return(NA_character_)
  }
  ifelse(is.na(x), NA_character_, sprintf("%.5f", x))
}
```

**Después:**
```r
format_num <- function(x) {
  if (length(x) == 0) return(NA_character_)
  ifelse(
    is.na(x),
    NA_character_,
    sapply(x, function(v) {
      av <- abs(v)
      if (!is.finite(av) || av == 0) return(formatC(v, format = "g", digits = 3))
      if (av < 10)   return(sprintf("%.2f", v))
      if (av < 100)  return(sprintf("%.1f", v))
      if (av < 1000) return(sprintf("%.0f", v))
      # Para valores >= 1000: notación con 3 cifras significativas
      return(formatC(v, format = "fg", digits = 3))
    })
  )
}
```

**Nota:** Esta función afecta toda la salida numérica del app. Se debe revisar que los scores (z, z', ζ, En) mantengan su presentación adecuada. Los scores dimensionales como z no tienen unidades físicas y su rango típico es [-3, 3], por lo que caerán en el caso `#.##`.

---

### Cambio 3 — Rounding intermedio en `app.R`

**Archivo:** `app.R`  
**Líneas actuales:** ~1810, ~1951

**Antes:**
```r
mutate(across(where(is.numeric), ~ round(.x, 5)))
```

**Después:**
```r
mutate(across(where(is.numeric), ~ signif(.x, 3)))
```

**Precaución:** Esta transformación afecta los datos antes de cálculos posteriores. Verificar que no se aplique a valores intermedios que luego se usan en fórmulas (e.g., incertidumbres que se propagan). Si el rounding es solo para display y no para cálculo, puede omitirse o restringirse a columnas de salida específicas.

---

### Cambio 4 — Documentación interna `run_algorithm_a()`

**Archivo:** `R/pt_robust_stats.R`  
**Líneas:** 82–96

Actualizar `@details` y `@param tol` para reflejar que:
- El criterio primario de convergencia es **3ª cifra significativa** (ISO 13528:2022 NOTE 1).
- `tol` se mantiene solo como guardia numérica de último recurso.

---

## 4. Archivos Afectados

| Archivo | Tipo de cambio | Prioridad |
|---|---|---|
| `R/pt_robust_stats.R` | Convergencia (criterio primario) + docstring | **Crítica** |
| `app.R` | `format_num()` + rounding intermedio | Alta |
| `ptcalc/R/pt_robust_stats.R` | Mismo cambio que arriba si es copia | Media |
| `validation/` scripts (Python) | Verificar si replican la convergencia; si sí, actualizar | Media |
| `validation_parte_1/` | Regenerar hojas de validación con criterio correcto | Media |

---

## 5. Validación Post-Cambio

1. **Test de regresión ISO**: Los casos del anexo C de ISO 13528:2022 deben producir los mismos valores de x* y s* con el nuevo criterio. Comparar número de iteraciones: con 3 cifras significativas se esperan **menos iteraciones** que con `tol=1e-06` para magnitudes ~60.

2. **Test de magnitudes extremas**:
   - CO a 0 µmol/mol (valores ~0.02): verificar que la convergencia no sea prematura.
   - SO₂ a 60 nmol/mol (valores ~60): verificar convergencia correcta.
   - Si se incorporaran valores ~500: verificar formato `###`.

3. **Test de display**: Confirmar que `format_num()` produce la representación esperada para cada rango.

4. **Test de scores**: z-scores, En-scores deben seguir evaluándose contra sus umbrales (|z|≤2, |En|≤1) correctamente después del cambio de formato.

---

## 6. Registro de Implementación

**Fecha de actualización:** 2026-04-21  
**Plan de 6 fases:** `logs/plans/260420_1459_plan_cifras-significativas-implementacion.md`

### Fases Completadas
- ✅ Fase 1: Criterio de convergencia en `ptcalc/R/pt_robust_stats.R` (51 tests PASS)
- ✅ Fase 2: Sincronizar convergencia en `R/pt_robust_stats.R` (smoke tests OK)
- ✅ Fase 3: Formato de salida numérica en `app.R` (3 cifras significativas)
- ✅ Fase 4.1: roxygen2 `@return` en `ptcalc/R/pt_robust_stats.R`
- ✅ Fase 4.2: roxygen2 `@return` en `R/pt_robust_stats.R`
- ✅ Fase 4.4: Nota de cambio en `README.md` (v0.4.1)

### Fases Pendientes
- ⏳ Fase 4.3: `devtools::document("ptcalc")` para regenerar `NAMESPACE` y `man/`
- ⏳ Fase 4.6: Comentario inline en `app.R:127` para `ALGO_A_TOL`
- ⏳ Fase 5: Tests nuevos para `signif3` y `format_num()`
- ⏳ Fase 6: Validación cruzada y revisión de scripts en `validation/`

## 7. Notas de Referencia

- **ISO 13528:2022 Annex C NOTE 1**: "The iteration continues until there is no change in the third significant figure of x* and s*."
- **Función deprecada `algorithm_A()`** (`utils.R:44`): Ya implementa `signif(x_star, 3)` correctamente — el cambio en `run_algorithm_a()` la homologa.
- **`signif(x, 3)` en R**: equivale al criterio ISO directamente. Es scale-invariante, a diferencia de la tolerancia absoluta.
