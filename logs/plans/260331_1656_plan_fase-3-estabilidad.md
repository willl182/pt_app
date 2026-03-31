# Plan: Fase 3 — Implementación Estabilidad

**Timestamp:** 260331_1656
**Slug:** fase-3-estabilidad
**Estado:** Pendiente

---

## Objetivo

Cerrar completamente la validación de estabilidad, con comparación tripartita (app.R vs R independiente vs Python) para los 15 combos objetivo.

---

## Contexto

### Fuente de datos

- `data/stability_n13.csv`
- Columnas: `pollutant, run, level, replicate, sample_id, value`
- Misma estructura que homogeneidad

### Dependencias de Fase 2

La estabilidad necesita datos de homogeneidad como entrada:
- `general_mean_homog` — media de todos los valores de homogeneidad
- `x_pt` — mediana de primera réplica de homogeneidad
- `sigma_pt` — MADe de homogeneidad (1.483 * median(|sample_2 - x_pt|))

Se leen de `validation/outputs/stage_02_homogeneity_r.csv`.

### Lógica efectiva en app.R

| Función | Archivo | Línea | Descripción |
|---------|---------|-------|-------------|
| `compute_stability_metrics()` | `app.R` | 526-754 | Orquesta cálculo de estabilidad |
| `calculate_stability_stats()` | `R/pt_homogeneity.R` | 244-311 | Cálculos ANOVA + robustos |

### Flujo en app.R

1. Cargar datos de estabilidad, filtrar por pollutant + level
2. Pivotear: `replicate` → columnas `sample_1`, `sample_2`, ...
3. Obtener datos de homogeneidad del combo correspondiente
4. Llamar `calculate_stability_stats(matriz, hom_general_mean, hom_x_pt, hom_sigma_pt)`
5. Calcular `diff_hom_stab = abs(stab_general_mean - hom_general_mean)`
6. Calcular criterio simple = `0.3 * hom_sigma_pt`
7. Calcular u_hom_mean y u_stab_mean
8. Calcular criterio expandido = `c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)`
9. Evaluar `diff_hom_stab <= c_criterion` y `diff_hom_stab <= c_expanded`

### Fórmulas (ISO 13528:2022, Sección 9.3)

| Métrica | Fórmula | Fuente |
|---------|---------|--------|
| `g` | `nrow(sample_data)` | ptcalc:234 |
| `m` | `ncol(sample_data)` | ptcalc:235 |
| `sample_means` | `rowMeans(sample_data)` | ptcalc:245 |
| `general_mean_stab` | `mean(sample_data)` (todos los valores) | ptcalc:248 |
| `x_pt_stab` | `median(sample_data[, 1])` | ptcalc:251 |
| `s_x_bar_sq_stab` | `var(sample_means)` | ptcalc:254 |
| `sw_stab` (m=2) | `sqrt(sum(range^2) / (2*g))` | ptcalc:258-260 |
| `sw_stab` (m>2) | `sqrt(mean(within_vars))` | ptcalc:262-263 |
| `ss_sq_stab` | `abs(s_x_bar_sq - sw_sq/m)` | ptcalc:269 (clamp a 0 en R/) |
| `ss_stab` | `sqrt(ss_sq_stab)` | ptcalc:270 |
| `diff_hom_stab` | `abs(stab_general_mean - hom_general_mean)` | app.R:616 |
| `u_hom_mean` | `sd(hom_values) / sqrt(n_hom)` | app.R:643-645 |
| `u_stab_mean` | `sd(stab_values) / sqrt(n_stab)` | app.R:649-652 |
| `criterio_simple` | `0.3 * hom_sigma_pt` | app.R:632 |
| `criterio_expandido` | `c_criterion + 2*sqrt(u_hom^2 + u_stab^2)` | app.R:654-658 |

### Diferencia crítica: ss_sq en estabilidad

En `R/pt_homogeneity.R:285-286`:
```r
stab_ss_sq <- stab_s_x_bar_sq - (stab_sw_sq / m_stab)
stab_ss <- if (stab_ss_sq < 0) 0 else sqrt(stab_ss_sq)
```

En `ptcalc/R/pt_homogeneity.R:269`:
```r
stab_ss_sq <- abs(stab_s_x_bar_sq - (stab_sw_sq / m_stab))
```

**Decisión**: Usar `abs()` como en Fase 2 (versión ptcalc). Documentar diferencia.

### Métricas a validar (13 por combo)

| # | Métrica | Descripción |
|---|---------|-------------|
| 1 | g | Número de muestras estabilidad |
| 2 | m | Número de réplicas estabilidad |
| 3 | general_mean_stab | Media general de todos los valores de estabilidad |
| 4 | x_pt_stab | Mediana de primera réplica de estabilidad |
| 5 | s_x_bar_sq_stab | Varianza de medias de estabilidad |
| 6 | sw_stab | DE intra-muestra de estabilidad |
| 7 | ss_sq_stab | Varianza entre-muestras de estabilidad |
| 8 | ss_stab | DE entre-muestras de estabilidad |
| 9 | diff_hom_stab | |mean_stab - mean_hom| |
| 10 | u_hom_mean | sd(hom) / sqrt(n_hom) |
| 11 | u_stab_mean | sd(stab) / sqrt(n_stab) |
| 12 | criterio_simple | 0.3 * sigma_pt_hom |
| 13 | criterio_expandido | c + 2*sqrt(u_hom^2 + u_stab^2) |

Total: 15 combos × 13 métricas = 195 comparaciones.

---

## Fases

### Fase 3.1: Lectura y pivoteo de datos

| Item | Estado | Notas |
|------|--------|-------|
| Cargar stability_n13.csv y pivotear | Pendiente | Reusar load_wide_data() |
| Cargar resultados de homogeneidad (R) | Pendiente | Leer stage_02_homogeneity_r.csv |
| Validar que g y m coinciden entre R y Python | Pendiente | |

### Fase 3.2: Cálculo independiente en R

| Item | Estado | Notas |
|------|--------|-------|
| Calcular g, m | Pendiente | |
| Calcular sample_means (rowMeans) | Pendiente | |
| Calcular general_mean_stab | Pendiente | |
| Calcular x_pt_stab (median de primera réplica) | Pendiente | |
| Calcular s_x_bar_sq_stab | Pendiente | |
| Calcular sw_stab (intra-sample SD) | Pendiente | m=2 con rangos |
| Calcular ss_sq_stab = abs(s_x_bar_sq - sw_sq/m) | Pendiente | abs() |
| Calcular ss_stab = sqrt(ss_sq_stab) | Pendiente | |
| Calcular diff_hom_stab = abs(mean_stab - mean_hom) | Pendiente | Requiere hom data |
| Calcular u_hom_mean | Pendiente | sd de todos los valores hom / sqrt(n) |
| Calcular u_stab_mean | Pendiente | sd de todos los valores stab / sqrt(n) |
| Calcular criterio_simple = 0.3 * sigma_pt_hom | Pendiente | |
| Calcular criterio_expandido | Pendiente | c + 2*sqrt(u_hom^2 + u_stab^2) |

### Fase 3.3: Cálculo independiente en Python

| Item | Estado | Notas |
|------|--------|-------|
| Implementar todas las fórmulas anteriores | Pendiente | Mismo orden, misma lógica |
| Cargar resultados de homogeneidad (Python) | Pendiente | Leer stage_02_homogeneity_py.csv |
| Validar contra resultados R | Pendiente | Tolerancia 1e-9 |

### Fase 3.4: Comparación tripartita

| Item | Estado | Notas |
|------|--------|-------|
| Generar filas canónicas por combo | Pendiente | 13 métricas |
| Aplicar tolerancia 1e-9 | Pendiente | |
| Clasificar PASS/FAIL | Pendiente | |
| Identificar EDGE_CASE | Pendiente | |

### Fase 3.5: Outputs

| Item | Estado | Notas |
|------|--------|-------|
| Generar `outputs/stage_03_stability.csv` | Pendiente | Tabla canónica |
| Generar `outputs/stage_03_stability_report.md` | Pendiente | Con resumen PASS/FAIL |

### Fase 3.6: Reporte de etapa

| Item | Estado | Notas |
|------|--------|-------|
| Incluir combos procesados | Pendiente | |
| Incluir métricas evaluadas | Pendiente | |
| Incluir conteo PASS/FAIL | Pendiente | |
| Incluir discrepancias | Pendiente | |

---

## Riesgos y consideraciones

| Riesgo | Mitigación |
|--------|------------|
| ss_sq: clamp a 0 en R/ vs abs() en ptcalc | Usar abs() como Fase 2 |
| diff_hom_stab requiere datos de homogeneidad | Leer CSV intermedio de Fase 2 |
| u_hom_mean requiere TODOS los valores de hom (no solo medias) | Acceder a datos raw de homogeneidad |
| m puede variar entre combos | Validar m por combo |

---

## Criterio de cierre

La Fase 3 está cerrada cuando:
1. Los 15 combos se procesan correctamente
2. El pivoteo de réplicas coincide entre R y Python
3. Todas las métricas coinciden dentro de tolerancia (1e-9)
4. diff_hom_stab se calcula correctamente con datos de homogeneidad
5. Existe CSV de salida con tabla canónica
6. Existe reporte Markdown con resumen PASS/FAIL

---

## Log de Ejecución

- [260331 16:56] Plan creado — fase de implementación estabilidad
