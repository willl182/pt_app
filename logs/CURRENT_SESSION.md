# Session State: PT App — Validacion Downstream Algoritmo A

**Last Updated**: 2026-03-31 16:56 (260331_1656)

## Session Objective

Planificar Fase 3 (Estabilidad) del sistema de validación downstream.

## Current State

- [x] Fase 0 completada: estructura de carpetas, stubs, helpers, USAGE.md
- [x] Fase 1 completada: estadísticos robustos validados (90 PASS, 0 FAIL)
- [x] Fase 2 completada: homogeneidad validada (195 PASS, 0 FAIL)
- [x] Plan Fase 3 creado: `logs/plans/260331_1656_plan_fase-3-estabilidad.md`
- [ ] **Fase 3: Estabilidad** — pendiente de implementación

## Archivos outputs actuales

```
validation/outputs/
  stage_01_robust_stats_r.csv      # Resultados R
  stage_01_robust_stats_py.csv     # Resultados Python
  stage_01_robust_stats.csv        # Comparación final (90 PASS)
  stage_01_robust_stats_report.md  # Reporte PASS
  stage_02_homogeneity_r.csv       # Resultados R homogeneidad
  stage_02_homogeneity_py.csv      # Resultados Python homogeneidad
  stage_02_homogeneity.csv         # Comparación final (195 PASS)
  stage_02_homogeneity_report.md   # Reporte PASS
```

## Resultados Fase 1

- 15 combos × 6 métricas = 90 PASS, 0 FAIL
- Máxima diferencia R vs Python: 3.41e-13

## Resultados Fase 2

- 15 combos × 13 métricas = 195 PASS, 0 FAIL
- Máxima diferencia R vs Python: 2.98e-13
- 0 EDGE_CASE (todos los combos tienen sigma_pt > 0)

## Plan Fase 3 — Resumen

13 métricas por combo (195 comparaciones totales):

| Sub-fase | Contenido |
|----------|-----------|
| 3.1 | Pivoteo de réplicas (wide format) + carga datos homogeneidad |
| 3.2 | Cálculo R (ANOVA + diff_hom + criterios) |
| 3.3 | Cálculo Python (mismas fórmulas) |
| 3.4 | Comparación tripartita |
| 3.5 | Outputs (CSV + reporte) |
| 3.6 | Reporte de etapa |

### Punto crítico: dependencia de homogeneidad

La estabilidad necesita de Fase 2:
- `general_mean_homog` — media de todos los valores de homogeneidad
- `x_pt` — mediana de primera réplica de homogeneidad
- `sigma_pt` — MADe de homogeneidad
- Datos raw de homogeneidad para u_hom_mean

### Riesgos

- ss_sq: clamp a 0 en R/ vs abs() en ptcalc → usar abs()
- u_hom_mean requiere TODOS los valores de homogeneidad (no solo medias)
- diff_hom_stab = abs(general_mean_stab - general_mean_homog)

## Next Steps

1. Implementar Fase 3 según plan:
   - Cargar y pivotear stability_n13.csv
   - Leer resultados de homogeneidad (Fase 2)
   - Calcular 13 métricas de estabilidad en R
   - Calcular lo mismo en Python
   - Comparar y generar CSV + reporte
2. Ejecutar subagente `revisor-fase`
3. Git commit y push
4. Planificar Fase 4 (Uncertainty Chain)

## Critical Technical Context

- **Pivoteo estabilidad**: `replicate` → columnas `sample_1`, `sample_2`, ...
- **x_pt_stab**: `median(sample_data[, 1])` (mediana de primera réplica)
- **diff_hom_stab**: `abs(general_mean_stab - general_mean_homog)`
- **criterio_simple**: `0.3 * sigma_pt_hom` (sigma_pt de homogeneidad)
- **u_hom_mean**: `sd(all_hom_values) / sqrt(n_hom)` (requiere datos raw)
- **u_stab_mean**: `sd(all_stab_values) / sqrt(n_stab)`
- **criterio_expandido**: `c + 2*sqrt(u_hom_mean^2 + u_stab_mean^2)`
- **Tabla F1/F2 NO aplica** para estabilidad (solo para homogeneidad)
