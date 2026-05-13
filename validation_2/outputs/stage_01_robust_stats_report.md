# Etapa 1: Estadísticos Robustos de Dispersión — Reporte

## Información
- Datos: `data/homogeneity_n13.csv`
- Combos: O3 × 3 niveles (0, 80, 180 nmol/mol)
- Fecha: 2026-05-12 22:57

## Referencia ISO 13528:2022, Sección 9.4

| Estadístico | Fórmula | Factor |
|-------------|---------|--------|
| Mediana (x_pt) | `median(sample_1)` | — |
| MAD | `median(\|x_i − median(x)\|)` | — |
| MADe (σ_pt) | `1.483 × MAD` | 1.483 |
| nIQR | `0.7413 × (Q3 − Q1)` tipo=7 | 0.7413 |

## Resultados por combo

### O3_0: O3 nivel 0-nmol/mol

| Métrica | R | Python | diff R-Python | Estado |
|--------|------|--------|--------------|--------|
| n | 13 | 13 | 0.00e+00 | PASS |
| median | 3.23e-05 | 3.23e-05 | 0.00e+00 | PASS |
| Q1 | 3.23e-05 | 3.23e-05 | 0.00e+00 | PASS |
| Q3 | 4.19e-05 | 4.19e-05 | 0.00e+00 | PASS |
| IQR | 9.6e-06 | 9.6e-06 | 3.39e-21 | PASS |
| MAD | 6.5e-06 | 6.5e-06 | 8.47e-22 | PASS |
| MADe | 9.6395e-06 | 9.6395e-06 | 1.69e-21 | PASS |
| nIQR | 7.11648e-06 | 7.11648e-06 | 1.69e-21 | PASS |

### O3_80: O3 nivel 80-nmol/mol

| Métrica | R | Python | diff R-Python | Estado |
|--------|------|--------|--------------|--------|
| n | 13 | 13 | 0.00e+00 | PASS |
| median | 80.10567472 | 80.10567472 | 0.00e+00 | PASS |
| Q1 | 80.00082828 | 80.00082828 | 0.00e+00 | PASS |
| Q3 | 80.20993101 | 80.20993101 | 0.00e+00 | PASS |
| IQR | 0.20910273 | 0.20910273 | 1.11e-16 | PASS |
| MAD | 0.10484644 | 0.10484644 | 1.25e-16 | PASS |
| MADe | 0.1554872705 | 0.1554872705 | 2.78e-16 | PASS |
| nIQR | 0.1550078537 | 0.1550078537 | 2.78e-17 | PASS |

### O3_180: O3 nivel 180-nmol/mol

| Métrica | R | Python | diff R-Python | Estado |
|--------|------|--------|--------------|--------|
| n | 13 | 13 | 0.00e+00 | PASS |
| median | 178.025781 | 178.025781 | 0.00e+00 | PASS |
| Q1 | 178.0045382 | 178.0045382 | 0.00e+00 | PASS |
| Q3 | 178.4389388 | 178.4389388 | 0.00e+00 | PASS |
| IQR | 0.4344006 | 0.4344006 | 1.67e-16 | PASS |
| MAD | 0.3498519 | 0.3498519 | 4.44e-16 | PASS |
| MADe | 0.5188303677 | 0.5188303677 | 4.44e-16 | PASS |
| nIQR | 0.3220211648 | 0.3220211648 | 4.44e-16 | PASS |

## Resumen

- Total métricas: 24
- PASS: 24
- FAIL: 0

✅ **Todos los valores R/Python coinciden dentro de tolerancia.**

## Verificaciones

1. ✅ Mediana calculada sobre `sample_1` (no sobre todas las réplicas)
2. ✅ Factor MADe = 1.483 (= 1/0.6745)
3. ✅ Factor nIQR = 0.7413 (= 1/1.349)
4. 🔍 Cuartiles type=7 (R) vs interpolación lineal (numpy/Python)
   - R `quantile(type=7)` y `numpy.percentile` usan el mismo método
   - Con n=13, debe haber coincidencia exacta
