# Reporte: Etapa 2 — Homogeneidad

**Fecha**: 2026-05-12
**Datos**: data/homogeneity_n13.csv
**Combos**: O3 × 3 niveles (0, 80, 180 nmol/mol)

## Métricas evaluadas
- g (número de muestras)
- m (número de réplicas)
- Media general (mean de todos los valores)
- x_pt (mediana de primera réplica)
- s_x_bar_sq (varianza de medias, ddof=1)
- s_xt (DE de medias)
- sw (DE intra-muestra)
- sw_sq (varianza intra-muestra)
- ss_sq (varianza entre-muestras, abs())
- ss (DE entre-muestras)
- sigma_pt (mediana de |sample_2 - x_pt|)
- MADe (1.483 × sigma_pt)
- u_sigma_pt (1.25 × MADe / √g)
- nIQR (0.7413 × IQR type=7 sobre sample_1)
- Criterio c MADe (0.3 × MADe)
- Criterio exp MADe (F1×(0.3×MADe)² + F2×sw²)
- Criterio c nIQR (0.3 × nIQR)
- Criterio exp nIQR (F1×(0.3×nIQR)² + F2×sw²)

## Discrepancia conocida
- criterion_expanded usa fórmula F1/F2 con 3 args (app.R),
  NO la fórmula `0.3×σ×√(1+(uσ/σ)²)` de ptcalc (2 args).

## Resumen PASS/FAIL
- PASS: 54
- FAIL: 0
- EDGE_CASE: 0

## Evaluaciones de criterio
- CUMPLE: 0
- NO_CUMPLE: 12

## Valores por combo

| Combo | g | m | x_pt | sw | ss | MADe | σ_pt | c_MADe | c_exp_MADe | ss≤c? |
|-------|---|---|------|-----|-----|------|------|--------|------------|-------|
| O3_0 | 13 | 2 | 3.23e-05 | 9.21961e-06 | 4.27117e-06 | 9.4912e-06 | 6.4e-06 | 2.84736e-06 | 8.2189e-11 | NO_CUMPLE |
| O3_80 | 13 | 2 | 80.1057 | 0.144398 | 0.0690666 | 0.178309 | 0.120235 | 0.0534927 | 0.0216883 | NO_CUMPLE |
| O3_180 | 13 | 2 | 178.026 | 0.483402 | 0.42975 | 1.10962 | 0.748223 | 0.332885 | 0.380863 | NO_CUMPLE |

## Evaluaciones de criterio detalladas

| Combo | ss | c_MADe | c_exp_MADe | ss≤c? | ss≤exp? | c_nIQR | c_exp_nIQR | ss≤c_nIQR? | ss≤exp_nIQR? |
|-------|-----|--------|---------|-------|--------|--------|-----------|------------|-------------|
| O3_0 | 4.2712e-06 | 2.8474e-06 | 8.2189e-11 | NO_CUMPLE | NO_CUMPLE | 2.1349e-06 | 7.5977e-11 | NO_CUMPLE | NO_CUMPLE |
| O3_80 | 0.0690666 | 0.0534927 | 0.0216883 | NO_CUMPLE | NO_CUMPLE | 0.0465024 | 0.020465 | NO_CUMPLE | NO_CUMPLE |
| O3_180 | 0.42975 | 0.332885 | 0.380863 | NO_CUMPLE | NO_CUMPLE | 0.0966063 | 0.203274 | NO_CUMPLE | NO_CUMPLE |

## Diferencias R vs Python
- Máxima diferencia: 1.136868377216e-13
- Tolerancia: 1e-09
- Total comparaciones numéricas: 48

## Conclusión
Etapa PASS
