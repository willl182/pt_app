# Reporte: Etapa 2 — Homogeneidad

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
- g (numero de muestras)
- m (numero de replicas)
- Media general (mean de todos los valores)
- x_pt (mediana de primera replica)
- s_x_bar_sq (varianza de medias)
- sw (DE intra-muestra)
- ss_sq (varianza entre-muestras, abs())
- ss (DE entre-muestras)
- sigma_pt (mediana de |sample_2 - x_pt|)
- MADe (1.483 * sigma_pt)
- u_sigma_pt (1.25 * MADe / sqrt(g))
- Criterio c (0.3 * sigma_pt)
- Criterio expandido (F1*(0.3*sigma_pt)^2 + F2*sw^2)

## Resumen PASS/FAIL
- PASS: 195
- FAIL: 0
- EDGE_CASE: 0
- KNOWN_DISCREPANCY: 0

## Observaciones
- Maxima diferencia R vs Python: 2.984279490192e-13
- Tolerancia aplicada: 1e-09
- Total comparaciones: 195
- Combos con edge case: 0

## Conclusion
Etapa PASS
