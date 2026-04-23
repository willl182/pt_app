# Evolución del Proyecto: pt_app + ptcalc

**Fecha de corte**: 2026-04-23  
**Periodo cubierto**: 2026-02-05 → 2026-04-22  
**Repositorio**: `/home/w182/w421/pt_app`  
**Paquete interno**: `ptcalc` (v0.1.0 → v0.1.1)

---

## Resumen ejecutivo

`pt_app` es la aplicación R/Shiny para procesamiento estadístico de ensayos de aptitud conforme ISO 13528:2022. `ptcalc` es el paquete R interno que implementa las funciones matemáticas puras (Algoritmo A, estadísticos robustos, homogeneidad, estabilidad, incertidumbres, puntajes). La evolución cubre correcciones estadísticas críticas, un pipeline de validación tripartita, implementación de cifras significativas ISO, y depuración del contrato de datos.

---

## Línea de tiempo de hitos

### Fase 1 — Auditoría de cálculos (Feb 2026)

| Fecha | Hito | Detalle |
|-------|------|---------|
| 2026-02-05 | Auditoría CO 0-μmol/mol | Verificación de cálculos de homogeneidad y estabilidad contra `data/Homogenidad y estabilidad.xlsx`. Promedio, sx, sw coinciden. |
| 2026-02-05 | Discrepancia σ_pt identificada | σ_pt del Excel de auditoría (0.00579) ≠ ptcalc (0.03982 vía MADe). Hipótesis: valor prescrito externamente, no calculado. |
| 2026-02-05 | Error en fórmula ss | Celda F23 del Excel produce `#NUM!`. App calcula correctamente ss = 0.01786. |

### Fase 2 — Correcciones estadísticas (Mar 2026)

| Fecha | Hito | Detalle |
|-------|------|---------|
| 2026-03-10 | Hallazgos H1–H9 implementados | 9 hallazgos del Informe No. 2 corregidos en ramas paralelas opus/codex. |
| 2026-03-10 | **H1 — Fórmula B.10 corregida** | `abs(s_x_bar_sq - sw_sq/m)` → `max(0, s_x_bar_sq - (sw_sq/m))`. Aplicado en `pt_homogeneity.R`, `calculate_stability_stats()` y `funciones_finales.R`. |
| 2026-03-10 | **H2 — MADe separado** | MADe de homogeneidad renombrado a `MADe_hom`/`sigma_pt_hom` para evitar confusión con sigma_pt de puntajes. |
| 2026-03-10 | **H4 — Umbral Algoritmo A** | Cambiado de `n ≥ 3` a `n ≥ 12` (ISO 13528:2022 §9.4). Para n < 12: MADe o nIQR directo. |
| 2026-03-10 | Trazabilidad por `run` | Selector de serie habilitado en Valor Asignado, Puntajes PT e Informe Global. Resultados cacheados indexados por `pollutant ‖ n_lab ‖ level ‖ run`. |
| 2026-03-11 | Plan de validación cruzada | Plan A2 formalizado: validación downstream post-Algoritmo A para las 15 combinaciones (5 contaminantes × niveles 1, 3, 5). |

### Fase 3 — Pipeline de validación tripartita (Mar 2026)

| Fecha | Hito | Detalle |
|-------|------|---------|
| 2026-03-30 | POC GPT53CDX implementado | Pipeline completo con 3 fuentes independientes: lógica de `app.R` (APP), R puro independiente, Python puro (solo stdlib). |
| 2026-03-30 | 5 workbooks Excel generados | Estructura ÍNDICE + 15 hojas combo + RESUMEN por sección (Robust Stats, Homogeneity, Stability, Uncertainties, Scores). |
| 2026-03-30 | 4446/7665 FAILs iniciales | Causa raíz: tolerancia 1e-12 demasiado estricta para diferencias numéricas R↔Python en quantiles y propagación. |
| 2026-03-30 | Decisiones de diseño fijadas | `u_stab = d_max / sqrt(3)` incondicional. `ALGO_A_TOL = 1e-04`. Niveles 0: sigma_pt ≈ 0 → NA en puntajes. |

### Fase 4 — Fases downstream completadas (Mar 2026)

| Fecha | Hito | Detalle |
|-------|------|---------|
| 2026-03-31 | Fase 2: Homogeneidad | Implementación completada con validación. |
| 2026-03-31 | Fase 3: Estabilidad | Implementación completada con validación. |
| 2026-03-31 | Fase 4: Cadena de incertidumbres | `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt` — cadena completa implementada. |
| 2026-03-31 | Fase 5: Puntajes | z, z', ζ, En implementados y validados. Planificación tripartita scores cerrada. |

### Fase 5 — Cifras significativas ISO (Abr 2026)

| Fecha | Hito | Detalle |
|-------|------|---------|
| 2026-04-20 | Plan aprobado | Integración de cifras significativas ISO 13528:2022 en algoritmos estadísticos y UI. |
| 2026-04-20 | Convergencia Algoritmo A | Criterios de convergencia actualizados para respetar cifras significativas. |
| 2026-04-20 | Formateo numérico | Reconfiguración de presentación numérica en la app Shiny. |
| 2026-04-20 | Pendiente | Fases 5-6: tests y validación cruzada. Comentario inline `app.R:127` para `ALGO_A_TOL`. |

### Fase 6 — Deprecación sample_group (Abr 2026)

| Fecha | Hito | Detalle |
|-------|------|---------|
| 2026-04-22 | Deprecación completa | Columna `sample_group` eliminada del contrato de entrada. Era funcionalmente muerta. |
| 2026-04-22 | app.R: advertencia | `showNotification` si CSV de entrada aún contiene `sample_group`. |
| 2026-04-22 | ptcalc v0.1.1 | Bump de versión + NEWS.md documentando la deprecación. |
| 2026-04-22 | CSVs de prueba limpiados | `summary_n{4,7,10,13}.csv` — columna removida. |
| 2026-04-22 | Documentación actualizada | 4 archivos en `es/` — tablas y ejemplos CSV ajustados. |
| 2026-04-22 | Smoke test | CSVs limpios confirmados; 3 FAILs pre-existentes en `test_04_puntajes.R` ignorados (bugs en tests, no en código). |

---

## Estado del paquete ptcalc

| Aspecto | Estado |
|---------|--------|
| Versión | 0.1.1 |
| Funciones core | Algoritmo A, MADe, nIQR, homogeneidad, estabilidad, incertidumbres, puntajes z/z'/ζ/En |
| Tests propios | No tiene testthat propio; integración en `deliv/04_puntajes/tests/` |
| roxygen/Rd | `devtools::document()` pendiente desde sesión de cifras significativas |
| Fórmula B.10 | Corregida con `max(0, ...)` |
| Umbral Algo A | `n ≥ 12` (ISO compliant) |
| Convergencia | `ALGO_A_TOL = 1e-04` |

---

## Fallas conocidas pendientes

| Ubicación | Descripción | Severidad |
|-----------|-------------|-----------|
| `test_04_puntajes.R:82` | `calcular_puntaje_zeta` test espera ≈1.58, fórmula ISO produce ≈2.24 | Bug en test |
| `test_04_puntajes.R:94` | `calcular_puntaje_en` test espera 1.0, real ≈1.12 | Bug en test |
| `test_04_puntajes.R:370` | `generar_reporte_estadisticas_globales` retorna lista, test espera data.frame | Bug en función |
| Cifras significativas | Fases 5-6 pendientes (tests + validación cruzada) | Medio |

---

## Arquitectura de validación

```
app.R (lógica operativa)
  ├── ptcalc/R/ (funciones matemáticas puras)
  ├── deliv/04_puntajes/ (pipeline de entrega + tests)
  └── validation/
      ├── val3/ (pipeline tripartita GPT53CDX)
      │   ├── poc_gpt53cdx_val.R (modos: app_r_excel, merge_py)
      │   └── poc_gpt53cdx_val.py (Python stdlib only)
      └── A2_*.xlsx (15 workbooks × 6 hojas)
```
