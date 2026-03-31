# Plan: Fase 2 — Implementación Homogeneidad

**Timestamp:** 260331_1251
**Slug:** fase-2-homogeneidad
**Estado:** Completado

---

## Objetivo

Cerrar completamente la validación de homogeneidad, con comparación tripartita (app.R vs R independiente vs Python) para los 15 combos objetivo.

---

## Contexto

### Fuente de datos

- `data/homogeneity_n13.csv`
- Columnas: `pollutant, run, level, replicate, sample_id, value`

### Lógica efectiva en app.R

| Función | Archivo | Línea | Descripción |
|---------|---------|-------|-------------|
| `get_wide_data()` | `app.R` | 279-290 | Filtra por contaminante, pivotea réplicas |
| `compute_homogeneity_metrics()` | `app.R` | 292-525 | Orquesta cálculo de homogeneidad |
| `calculate_homogeneity_stats()` | `ptcalc/R/pt_homogeneity.R` | 45-124 | Cálculos ANOVA + robustos |

### Flujo en app.R

1. Filtrar por `pollutant == target_pollutant`
2. Pivotear: `replicate` → columnas `sample_1`, `sample_2`, ...
3. Filtrar por `level == target_level`
4. Extraer solo columnas `sample_*` → matriz `g × m`
5. Llamar `calculate_homogeneity_stats(matriz)`
6. Calcular criterio c = 0.3 * sigma_pt
7. Calcular criterio expandido (versión 3 args de R/)
8. Evaluar ss vs criterio

### Fórmulas (ISO 13528:2022, Sección 9.2)

| Métrica | Fórmula | Línea ptcalc |
|---------|---------|-------------|
| `g` | `nrow(sample_data)` | 51 |
| `m` | `ncol(sample_data)` | 52 |
| `sample_means` | `rowMeans(sample_data)` | 62 |
| `general_mean_homog` | `mean(sample_data)` (todos los valores) | 65 |
| `x_pt` | `median(sample_data[, 1])` | 68 |
| `s_x_bar_sq` | `var(sample_means)` | 71 |
| `s_xt` | `sqrt(s_x_bar_sq)` | 72 |
| `sw` (m=2) | `sqrt(sum(range^2) / (2*g))` | 77 |
| `sw` (m>2) | `sqrt(mean(within_vars))` | 80 |
| `sw_sq` | `sw^2` | 83 |
| `ss_sq` | `abs(s_x_bar_sq - sw_sq/m)` | 86 |
| `ss` | `sqrt(ss_sq)` | 87 |
| `sigma_pt` | `median(|sample_2 - x_pt|)` | 93 |
| `MADe` | `1.483 * sigma_pt` | 96 |
| `u_sigma_pt` | `1.25 * MADe / sqrt(g)` | 103 |

### Criterio expandido — DIFERENCIA CRÍTICA

Hay DOS versiones:

| Versión | Archivo | Args | Fórmula |
|---------|---------|------|---------|
| ptcalc | `ptcalc/R/pt_homogeneity.R:156` | `(sigma_pt, u_sigma_pt)` | `0.3*sigma_pt * sqrt(1 + (u/sigma)^2)` |
| **R/** (la que usa app) | `R/pt_homogeneity.R:157` | `(sigma_pt, sw, g)` | `F1*(0.3*sigma_pt)^2 + F2*sw^2` |

**La app usa la versión de R/ (3 args).** Tabla F1/F2 por g (7-20, clamp):

| g | F1 | F2 |
|---|----|----|
| 7 | 2.10 | 1.43 |
| 8 | 2.01 | 1.25 |
| 9 | 1.94 | 1.11 |
| 10 | 1.88 | 1.01 |
| 11 | 1.83 | 0.93 |
| 12 | 1.79 | 0.86 |
| 13 | 1.75 | 0.80 |
| 14 | 1.72 | 0.75 |
| 15 | 1.69 | 0.71 |
| 16 | 1.67 | 0.68 |
| 17 | 1.64 | 0.64 |
| 18 | 1.62 | 0.62 |
| 19 | 1.60 | 0.59 |
| 20 | 1.59 | 0.57 |

### Evaluación

```r
passes_criterion <- ss <= c_criterion
passes_expanded  <- ss <= c_expanded
```

---

## Fases

### Fase 2.1: Lectura y pivoteo de datos

| Item | Estado | Notas |
|------|--------|-------|
| Implementar pivoteo en R (usar helpers.R `load_wide_data`) | Completado | Filtrar pollutant + level, pivotear replicate |
| Implementar pivoteo en Python | Completado | Mismo formato ancho |
| Validar que g (muestras) y m (réplicas) coinciden entre R y Python | Completado | g=13, m=2 para todos los combos |
| Verificar consistencia de datos faltantes | Completado | Sin datos faltantes |

### Fase 2.2: Cálculo independiente en R

| Item | Estado | Notas |
|------|--------|-------|
| Calcular g, m | Completado | |
| Calcular sample_means (rowMeans) | Completado | |
| Calcular general_mean_homog (mean de TODOS los valores) | Completado | |
| Calcular x_pt (median de primera réplica) | Completado | |
| Calcular s_x_bar_sq (var de sample_means) | Completado | |
| Calcular sw (intra-sample SD) | Completado | Caso m=2 con rangos |
| Calcular ss_sq = abs(s_x_bar_sq - sw_sq/m) | Completado | abs() en ptcalc |
| Calcular ss = sqrt(ss_sq) | Completado | |
| Calcular sigma_pt = median(|sample_2 - x_pt|) | Completado | |
| Calcular MADe = 1.483 * sigma_pt | Completado | |
| Calcular u_sigma_pt = 1.25 * MADe / sqrt(g) | Completado | |
| Calcular criterio c = 0.3 * sigma_pt | Completado | |
| Calcular criterio expandido (3 args, tabla F1/F2) | Completado | Versión R/ |

### Fase 2.3: Cálculo independiente en Python

| Item | Estado | Notas |
|------|--------|-------|
| Implementar todas las fórmulas anteriores | Completado | Mismo orden, misma lógica |
| Implementar tabla F1/F2 para criterio expandido | Completado | |
| Validar contra resultados R | Completado | Max diff 2.98e-13, tol 1e-9 |

### Fase 2.4: Comparación tripartita

| Item | Estado | Notas |
|------|--------|-------|
| Generar filas canónicas por combo | Completado | 13 métricas × 15 combos = 195 filas |
| Aplicar tolerancia 1e-9 | Completado | |
| Clasificar PASS/FAIL | Completado | 195 PASS, 0 FAIL |
| Identificar EDGE_CASE | Completado | 0 edge cases (todos tienen sigma_pt > 0) |

### Fase 2.5: Outputs

| Item | Estado | Notas |
|------|--------|-------|
| Generar `outputs/stage_02_homogeneity.csv` | Completado | Tabla canónica |
| Generar `outputs/stage_02_homogeneity_report.md` | Completado | Con resumen PASS/FAIL |

### Fase 2.6: Reporte de etapa

| Item | Estado | Notas |
|------|--------|-------|
| Incluir combos procesados | Completado | 15 combos |
| Incluir métricas evaluadas | Completado | 13 métricas |
| Incluir conteo PASS/FAIL | Completado | 195 PASS, 0 FAIL |
| Incluir discrepancias | Completado | Sin discrepancias |
| Incluir casos borde (sigma_pt ≈ 0) | Completado | Sin edge cases |

---

## Riesgos y consideraciones

| Riesgo | Mitigación |
|--------|------------|
| Niveles 0 producen sigma_pt ≈ 0 → división problemática | Clasificar como EDGE_CASE, documentar |
| `ss_sq = abs(s_x_bar_sq - sw_sq/m)` en ptcalc vs clamp a 0 en R/ | Usar abs() como ptcalc (la que usa la app indirectamente) |
| Criterio expandido: 2 versiones diferentes | Usar la de R/ (3 args) que es la que usa app.R |
| m puede variar entre combos | Validar m por combo, no asumir constante |

---

## Métricas a validar (12 por combo)

| # | Métrica | Descripción |
|---|---------|-------------|
| 1 | g | Número de muestras |
| 2 | m | Número de réplicas |
| 3 | general_mean_homog | Media general de todos los valores |
| 4 | x_pt | Mediana de primera réplica |
| 5 | s_x_bar_sq | Varianza de medias |
| 6 | sw | DE intra-muestra |
| 7 | ss_sq | Varianza entre-muestras |
| 8 | ss | DE entre-muestras |
| 9 | sigma_pt | Mediana de |sample_2 - x_pt| |
| 10 | MADe | 1.483 * sigma_pt |
| 11 | u_sigma_pt | 1.25 * MADe / sqrt(g) |
| 12 | criterio_c | 0.3 * sigma_pt |

Total: 15 combos × 12 métricas = 180 comparaciones.

---

## Criterio de cierre

La Fase 2 está cerrada cuando:
1. Los 15 combos se procesan correctamente
2. El pivoteo de réplicas coincide entre R y Python
3. Todas las métricas coinciden dentro de tolerancia (1e-9)
4. El criterio expandido usa la versión correcta (3 args, tabla F1/F2)
5. Existe CSV de salida con tabla canónica
6. Existe reporte Markdown con resumen PASS/FAIL
7. Casos borde (sigma_pt ≈ 0) están documentados

---

## Log de Ejecución

- [260331 12:51] Plan creado — fase de implementación homogeneidad
- [260331 13:15] Implementación completada — R + Python scripts
- [260331 13:15] R ejecutado: 15 combos procesados, CSV intermedio generado
- [260331 13:15] Python ejecutado: 15 combos procesados, comparación tripartita
- [260331 13:15] Resultados: 195 PASS, 0 FAIL, 0 EDGE_CASE
- [260331 13:15] Máxima diferencia R vs Python: 2.98e-13 (tolerancia 1e-9)
- [260331 13:15] Fase 2 CERRADA — todos los criterios de cierre cumplidos
