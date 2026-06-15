# Reporte: Etapa 2 — Homogeneidad

**Fecha**: 2026-05-13

## Combos procesados
- O3_0
- O3_80
- O3_180

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
- PASS: 39
- FAIL: 0
- EDGE_CASE: 0
- KNOWN_DISCREPANCY: 0

## Observaciones
- Maxima diferencia R vs Python: 1.421085471520e-14
- Tolerancia aplicada: 1e-09
- Total comparaciones: 39
- Combos con edge case: 0

## Conclusion
Etapa PASS
