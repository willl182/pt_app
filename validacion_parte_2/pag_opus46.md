# pag_opus46: Validación Completa Post-Algoritmo A

**Fecha**: 2026-03-30 12:03 -05  
**Estado**: draft  
**Consolida**: `plan_a2.md` + `260330_1118_plan_a1_validacion_post_algoA.md`  

## Resumen ejecutivo

Este plan describe la validación cruzada completa de todo el flujo downstream
del Algoritmo A en `pt_app`, usando `data/summary_n13.csv` con 12 participantes.
Compara **tres fuentes** (R app-like, R independiente, Python independiente) para
las **15 combinaciones** objetivo (5 contaminantes × 3 niveles), cubriendo:

1. Estadísticos robustos de consenso (mediana, MADe, nIQR)
2. Homogeneidad
3. Estabilidad
4. Cadena de incertidumbres (u_hom, u_stab, u_xpt_def, U_xpt)
5. Puntajes de desempeño (z, z', ζ, En) + evaluaciones cualitativas

## Estado actual — Código existente

| Artefacto | Estado | Nota |
|---|---|---|
| `validation/generate_post_algoA_validation.R` | ✅ Funcional (939 líneas) | Comparación R app-like vs R independiente vs Python |
| `validation/generate_post_algoA_validation.py` | ✅ Funcional (585 líneas) | Reimplementación independiente completa |
| 15 × `validation/A2_*.xlsx` | ✅ Generados | 6 hojas por workbook |
| `post_algoA_master_comparison.csv` | ⚠️ Verificar | Regenerar y validar 0 FAIL |
| `post_algoA_master_summary.csv` | ⚠️ Verificar | Conteo PASS/FAIL por combo×sección |

## Combinaciones objetivo (15)

| Contaminante | Nivel 1 | Nivel 3 | Nivel 5 |
|---|---|---|---|
| CO | `0-μmol/mol` | `4-μmol/mol` | `8-μmol/mol` |
| NO | `0-nmol/mol` | `81-nmol/mol` | `121-nmol/mol` |
| NO2 | `0-nmol/mol` | `60-nmol/mol` | `120-nmol/mol` |
| O3 | `0-nmol/mol` | `80-nmol/mol` | `180-nmol/mol` |
| SO2 | `0-nmol/mol` | `60-nmol/mol` | `100-nmol/mol` |

**Nota**: niveles `0-*` pueden producir σ_pt ≈ 0, generando NA en puntajes.
Esto es un caso borde documentado.

## Brechas por cubrir

### G1. Archivos xlsx seccionales (de plan_a1)

El script actual genera **1 xlsx por combinación** (15 archivos `A2_*.xlsx`).
`plan_a1` pide adicionalmente **5 archivos seccionales**:

```
validation/
  Val_01_Robust_Stats.xlsx     # 15 hojas combo + INDICE + RESUMEN
  Val_02_Homogeneity.xlsx      # 15 hojas combo + INDICE + FORMULAS + RESUMEN
  Val_03_Stability.xlsx        # 15 hojas combo + RESUMEN
  Val_04_Uncertainties.xlsx    # 15 hojas × 4 métodos + RESUMEN
  Val_05_Scores.xlsx           # 15 hojas × 4 métodos + RESUMEN
```

**Acción**: crear `validation/generate_val_sections.R` que reutilice las
funciones del script existente reorganizando la salida por sección en vez de
por combinación.

### G2. Hojas INDICE, RESUMEN y FORMULAS

Agregar a cada xlsx seccional:
- `INDICE`: lista de hojas con hipervínculos internos
- `RESUMEN`: conteo PASS/FAIL por combo dentro de esa sección
- `FORMULAS` (solo Val_02): documentación de las fórmulas ISO 13528

### G3. Columna `excel_value` rellena con `r_value`

En `generate_post_algoA_validation.R:691`, la columna `excel_value` se
iguala siempre a `r_value`. No hay lectura real desde un xlsx externo.

**Opciones**:
- a) Aceptar `excel_value = r_value` como diseño intencional (comparación R→R)
- b) Implementar lectura de los `A2_*.xlsx` generados y releer los valores
  como verificación de persistencia roundtrip

### G4. Pipeline de ejecución ordenada

El script R necesita que Python se ejecute primero para producir
`py_canonical_results.csv`. Documentar el orden:

```bash
# 1. Python genera CSV canónico
python3 validation/generate_post_algoA_validation.py

# 2. R genera los 15 A2_*.xlsx + master comparison/summary
Rscript validation/generate_post_algoA_validation.R

# 3. R genera los 5 Val_0*.xlsx seccionales (NUEVO)
Rscript validation/generate_val_sections.R
```

### G5. Informe final markdown

Crear `validation/post_algoA_validation_report.md` con: tabla de PASS/FAIL,
documentación de casos borde, y la discrepancia `u_stab` (app.R:2494 calcula
`d_max/sqrt(3)` incondicionalmente vs `calculate_u_stab()` que retorna 0 si 
criterio se cumple).

## Detalle de métricas por sección

### S1. Val_01 — Estadísticos robustos

| Métrica | Fórmula |
|---|---|
| Valores xi | `mean(mean_value)` por `participant_id` (excl. "ref") |
| Mediana | `median(xi)` |
| MAD | `median(|xi - mediana|)` |
| MADe | `1.483 × MAD` |
| Q1, Q3 | `quantile(x, type=7)` |
| IQR | `Q3 - Q1` |
| nIQR | `0.7413 × IQR` |

### S2. Val_02 — Homogeneidad

Datos fuente: `data/homogeneity_n13.csv`

| Métrica | Fórmula |
|---|---|
| x_pt | `median(rep1_values)` |
| s²_x̄ | `var(medias_muestra)` |
| sw | `sqrt(sum(rangos²)/(2g))` para m=2 |
| ss² | `|s²_x̄ - sw²/m|` |
| ss | `sqrt(ss²)` o 0 si ss² < 0 |
| MADe_hom | `1.483 × median(|rep2 - x_pt|)` |
| σ_pt | MADe_hom |
| u(σ_pt) | `1.25 × MADe / sqrt(g)` |
| c | `0.3 × σ_pt` |
| Evaluación | `ss ≤ c` |

### S3. Val_03 — Estabilidad

Datos fuente: `data/stability_n13.csv` + resultados de homogeneidad

| Métrica | Fórmula |
|---|---|
| d_max | `|media_estab - media_homog|` |
| c criterio | `0.3 × σ_pt` (de homogeneidad) |
| u_stab | `d_max / sqrt(3)` (app.R: incondicional) |
| Evaluación | `d_max ≤ c` |

> ⚠️ **Discrepancia**: `app.R:2494` calcula `u_stab = d_max/sqrt(3)` siempre,
> mientras que `calculate_u_stab()` en `pt_homogeneity.R:401` retorna 0 si el
> criterio se cumple. La validación usa el comportamiento de `app.R`.

### S4. Val_04 — Incertidumbres (4 métodos)

| Método | x_pt | σ_pt | u(x_pt) |
|---|---|---|---|
| Referencia | `mean(ref$mean_value)` | MADe_hom | `1.25 × MADe / sqrt(g)` |
| Consenso MADe | `median(xi)` | `1.483 × median(|xi - med|)` | `1.25 × σ_pt / sqrt(n)` |
| Consenso nIQR | `median(xi)` | `calculate_niqr(xi)` | `1.25 × σ_pt / sqrt(n)` |
| Algoritmo A | `algo$assigned_value` | `algo$robust_sd` | `1.25 × s* / sqrt(n)` |

Comunes:
- `u_hom = ss`
- `u_stab = d_max / sqrt(3)`
- `u(x_pt)_def = sqrt(u_xpt² + u_hom² + u_stab²)`
- `U(x_pt) = k × u(x_pt)_def`, k = 2

### S5. Val_05 — Puntajes de desempeño

| Puntaje | Fórmula |
|---|---|
| z | `(x - x_pt) / σ_pt` |
| z' | `(x - x_pt) / sqrt(σ_pt² + u_xpt_def²)` |
| ζ | `(x - x_pt) / sqrt(u_x² + u_xpt_def²)` |
| En | `(x - x_pt) / sqrt(U_xi² + U_xpt²)` |

Evaluación z/z'/ζ: |score| ≤ 2 → Satisfactorio, 2 < |score| < 3 → Cuestionable, |score| ≥ 3 → No satisfactorio  
Evaluación En: |En| ≤ 1 → Satisfactorio, |En| > 1 → No satisfactorio

## Tolerancias de comparación

| Tipo | Tolerancia |
|---|---|
| R vs R (scores) | `1e-12` |
| R vs R (agregados) | `1e-9` |
| R vs Python (todos) | `1e-9` |
| Etiquetas cualitativas | Igualdad exacta |

## Archivos a crear o modificar

### Nuevos
- `validation/generate_val_sections.R` — generador de 5 xlsx seccionales
- `validation/post_algoA_validation_report.md` — informe final markdown
- `logs/plans/pag_opus46.md` — este plan (ya creado)

### Modificar
- `validation/generate_post_algoA_validation.R` — extraer funciones reutilizables, agregar hoja RESUMEN a cada A2_*.xlsx, agregar métricas de robust stats a `04_global_checks`
- `validation/generate_post_algoA_validation.py` — verificar que CSV de salida se escribe en ruta esperada

## Orden de ejecución

1. `generate_val_sections.R` — codificar después de refactorizar helpers
2. Correr pipeline completo: Python → R principal → R seccional
3. Verificar 0 FAIL en master summary
4. Escribir informe final

## Criterios de aceptación

1. Las 15 combinaciones se resuelven sin error desde `summary_n13.csv`
2. El script R reproduce la lógica de `app.R` para la cadena completa downstream
3. Se generan 15 workbooks `A2_*.xlsx` (6 hojas cada uno)
4. Se generan 5 workbooks `Val_0*.xlsx` (15+ hojas cada uno)
5. Coinciden x_pt, σ_pt, u_xpt, u_hom, u_stab, u_xpt_def, U_xpt entre las 3 fuentes
6. Coinciden z, z', ζ, En por participante entre las 3 fuentes
7. Coinciden evaluaciones cualitativas
8. El master summary no reporta FAIL
9. Casos borde (nivel 0) documentados con NA en puntajes

## Archivos de referencia durante implementación

- `R/pt_robust_stats.R` — `calculate_mad_e()`, `calculate_niqr()`, `run_algorithm_a()`
- `R/pt_homogeneity.R` — `calculate_homogeneity_stats()`, `calculate_stability_stats()`, criterios
- `R/pt_scores.R` — z, z', ζ, En + evaluaciones vectorizadas
- `app.R:2328-2398` — `compute_combo_scores()` (fórmulas exactas)
- `app.R:2431-2542` — `compute_scores_for_selection()` (flujo completo)
- `app.R:127` — `ALGO_A_TOL = 1e-04`
- `validation/generate_algoA_validation.R` — patrón de estilos openxlsx
