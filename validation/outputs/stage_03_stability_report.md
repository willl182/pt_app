# Reporte: Etapa 3 — Estabilidad

**Fecha**: 2026-03-31

## Combos procesados
- CO_0
- CO_4
- CO_8
- NO_0
- NO_81
- NO_121
- NO2_0
- NO2_60
- NO2_120
- O3_0
- O3_80
- O3_180
- SO2_0
- SO2_60
- SO2_100

## Metricas evaluadas
- g (numero de muestras estabilidad)
- m (numero de replicas estabilidad)
- Media general stab (mean de todos los valores de estabilidad)
- x_pt stab (mediana de primera replica estabilidad)
- s_x_bar_sq stab (varianza de medias estabilidad)
- sw stab (DE intra-muestra estabilidad)
- ss_sq stab (varianza entre-muestras estabilidad)
- ss stab (DE entre-muestras estabilidad)
- diff_hom_stab (abs(mean_stab - mean_hom))
- u_hom_mean (sd(all_hom_values) / sqrt(n_hom))
- u_stab_mean (sd(all_stab_values) / sqrt(n_stab))
- Criterio simple (0.3 * sigma_pt_hom)
- Criterio expandido (c + 2*sqrt(u_hom^2 + u_stab^2))

## Resumen PASS/FAIL
- PASS: 195
- FAIL: 0
- EDGE_CASE: 0
- KNOWN_DISCREPANCY: 0

## Observaciones
- Maxima diferencia R vs Python: 3.126388037344e-13
- Tolerancia aplicada: 1e-09
- Total comparaciones: 195
- Combos con edge case: 0

## Conclusion
Etapa PASS
