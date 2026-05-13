# Session State: Validación PT — Etapa 3 completada

**Last Updated**: 2026-05-12 23:55

## Session Objective

Implementar la Etapa 3 (Estabilidad) del plan de validación en `validation_2/`, desde cero, para O3 × 3 niveles (0, 80, 180 nmol/mol).

## Current State

- [x] Etapa 1 — Robust Stats: COMPLETADA (24/24 PASS, diff < 1e-15)
- [x] Etapa 2 — Homogeneidad: COMPLETADA (54/54 PASS, max diff = 1.14e-13; 12/12 evaluaciones NO_CUMPLE)
- [x] Etapa 3 — Estabilidad: COMPLETADA (66/66 PASS, max diff = 1.14e-13; 12/12 evaluaciones CUMPLE)
- [ ] Etapa 4 — Cadena de Incertidumbre: PENDIENTE
- [ ] Etapa 5 — Puntajes de Desempeño: PENDIENTE
- [ ] Fases 6–8: PENDIENTES

## Etapa 3 — Resultados clave

| Combo | Dmax | c_stab_MADe | c_stab_exp_MADe | u_stab | Resultado |
|-------|------|-------------|-----------------|--------|-----------|
| O3_0 | 0 | 2.847e-06 | 8.464e-06 | 0 | CUMPLE |
| O3_80 | 0 | 0.0535 | 0.1420 | 0 | CUMPLE |
| O3_180 | 0 | 0.3329 | 0.6885 | 0 | CUMPLE |

- **66/66 PASS** métricas numéricas (R = Python)
- **12/12 CUMPLE** evaluaciones de criterio
- Dmax = 0 para los 3 combos (datos homogeneidad = estabilidad)
- Verificación contra ptcalc: diff = 0 para Dmax, mean_stab, sw_stab, ss_stab
- u_stab = 0 para los 3 combos (Dmax ≤ c_stab siempre)

## Nota importante

Los datos de estabilidad (`stability_n13.csv`) y homogeneidad (`homogeneity_n13.csv`) son IDÉNTICOS para O3 × 3 niveles. Esto implica que Dmax = |media_stab - media_hom| = 0, por lo que el criterio de estabilidad siempre se cumple. u_stab = 0 para los 3 combos.

## Discrepancia conocida (documentada)

`calculate_stability_criterion_expanded` en app.R usa la fórmula:
- c_stab_exp = c_stab + 2 × √(u_hom_mean² + u_stab_mean²)

Esto es consistente con ISO 13528 §9.3.4. Los scripts de validación usan la misma fórmula.

## Critical Technical Context

- **Data source homogeneity**: `data/homogeneity_n13.csv` — columnas: pollutant, run, level, replicate, sample_id, value
- **Data source stability**: `data/stability_n13.csv` — mismas columnas, mismos datos para O3
- **Pivot a ancho**: replicate 1 → sample_1, replicate 2 → sample_2; filas = sample_id (1–13)
- **g=13, m=2** para los 3 combos O3
- **c_stab_MADe** = 0.3 × MADe_hom (usando MADe de homogeneidad)
- **c_stab_nIQR** = 0.3 × nIQR_hom (usando nIQR de homogeneidad)
- **u_hom_mean** = sd(all hom values) / √n_hom (como app.R L929-933)
- **u_stab_mean** = sd(all stab values) / √n_stab (como app.R L931-933)

## Files Created/Modified

- `validation_2/stage_03_stability.R` — Script R nuevo desde cero (22 métricas + 4 evaluaciones × 3 combos)
- `validation_2/stage_03_stability.py` — Script Python nuevo desde cero (comparación automática con R)
- `validation_2/outputs/stage_03_stability_r.csv` — Resultados R intermedios
- `validation_2/outputs/stage_03_stability.csv` — CSV canónico comparativo (78 filas)
- `validation_2/outputs/stage_03_stability_report.md` — Reporte Markdown
- `validation_2/TODO_validacion.md` — Etapa 3 marcada como completada

## Next Steps

1. Implementar Etapa 4 (Cadena de Incertidumbre) desde cero en validation_2/
2. Implementar Etapa 5 (Puntajes de Desempeño) desde cero en validation_2/
3. Extraer valores app_value comparando con app Shiny