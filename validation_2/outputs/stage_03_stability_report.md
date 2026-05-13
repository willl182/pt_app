# Reporte: Etapa 3 — Estabilidad

**Fecha**: 2026-05-12
**Datos homogeneidad**: data/homogeneity_n13.csv
**Datos estabilidad**: data/stability_n13.csv
**Combos**: O3 × 3 niveles (0, 80, 180 nmol/mol)

## Métricas evaluadas
- g_stab (número de muestras de estabilidad)
- m_stab (número de réplicas de estabilidad)
- general_mean_stab (media general de estabilidad)
- x_pt_stab (mediana de primera réplica de estabilidad)
- s_x_bar_sq_stab (varianza de medias, ddof=1)
- s_xt_stab (DE de medias de estabilidad)
- sw_stab (DE intra-muestra de estabilidad)
- sw_sq_stab (varianza intra-muestra de estabilidad)
- ss_sq_stab (varianza entre-muestras de estabilidad)
- ss_stab (DE entre-muestras de estabilidad)
- media_hom (media general de HOMOGENEIDAD)
- media_stab (media general de ESTABILIDAD)
- diff_hom_stab (Dmax = |media_stab - media_hom|)
- hom_MADe (MADe de homogeneidad)
- hom_nIQR (nIQR de homogeneidad)
- c_stab_MADe (0.3 × MADe_hom)
- c_stab_nIQR (0.3 × nIQR_hom)
- u_hom_mean (SD valores hom / √n_hom)
- u_stab_mean (SD valores stab / √n_stab)
- c_stab_exp_MADe (c_stab_MADe + 2×√(u_hom²+u_stab²))
- c_stab_exp_nIQR (c_stab_nIQR + 2×√(u_hom²+u_stab²))
- u_stab (0 si Dmax≤c, Dmax/√3 si no)

## Nota importante
- Los datos de estabilidad y homogeneidad son IDÉNTICOS para O3 × 3 niveles.
  Esto implica Dmax = 0, por lo que el criterio de estabilidad se cumple siempre.

## Discrepancia conocida
- u_stab (incertidumbre): ptcalc usa calculate_u_stab(diff, c) que
  devuelve 0 si diff≤c, o diff/√3 si no. Este script sigue la misma lógica.

## Resumen PASS/FAIL
- PASS: 66
- FAIL: 0
- EDGE_CASE: 0

## Evaluaciones de criterio
- CUMPLE: 12
- NO_CUMPLE: 0

## Valores por combo

| Combo | g | m | mean_hom | mean_stab | Dmax | c_MADe | c_exp_MADe | u_stab | Dmax≤c? |
|-------|---|---|----------|-----------|------|--------|-----------|--------|---------|
| O3_0 | 13 | 2 | 3.53654e-05 | 3.53654e-05 | 0 | 2.84736e-06 | 8.46366e-06 | 0 | CUMPLE |
| O3_80 | 13 | 2 | 80.0839 | 80.0839 | 0 | 0.0534927 | 0.14195 | 0 | CUMPLE |
| O3_180 | 13 | 2 | 178.334 | 178.334 | 0 | 0.332885 | 0.688488 | 0 | CUMPLE |

## Evaluaciones de criterio detalladas

| Combo | Dmax | c_MADe | c_exp_MADe | c_nIQR | c_exp_nIQR | Dmax≤c_MADe? | Dmax≤c_nIQR? | Dmax≤exp_MADe? | Dmax≤exp_nIQR? | u_hom | u_stab_mean | u_stab |
|-------|------|--------|------------|--------|------------|--------------|---------------|----------------|-----------------|-------|-------------|--------|
| O3_0 | 0.0000e+00 | 2.8474e-06 | 8.4637e-06 | 2.1349e-06 | 7.7512e-06 | CUMPLE | CUMPLE | CUMPLE | CUMPLE | 1.9857e-06 | 1.9857e-06 | 0.0000e+00 |
| O3_80 | 0.0000e+00 | 0.0534927 | 0.14195 | 0.0465024 | 0.13496 | CUMPLE | CUMPLE | CUMPLE | CUMPLE | 0.0312744 | 0.0312744 | 0.0000e+00 |
| O3_180 | 0.0000e+00 | 0.332885 | 0.688488 | 0.0966063 | 0.45221 | CUMPLE | CUMPLE | CUMPLE | CUMPLE | 0.125725 | 0.125725 | 0.0000e+00 |

## Diferencias R vs Python
- Máxima diferencia: 1.136868377216e-13
- Tolerancia: 1e-09
- Total comparaciones numéricas: 60

## Conclusión
Etapa PASS
