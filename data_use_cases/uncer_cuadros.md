# Cuadros de incertidumbre por contaminante

Un cuadro por gas. Filas = niveles de cada ronda. `u_c` es la incertidumbre estándar combinada; `U` es la expandida con k = 2.

En el encabezado de cada columna: **(G)** = global, el mismo valor en todos los niveles · **(N)** = depende del nivel.

---

## CO — µmol/mol

| ronda | nivel | u_rep (N) | u_curva (N) | u_patron (G) | u_aire_cero (G) | **u_c** | **U (k=2)** | U rel |
|---|---|---|---|---|---|---|---|---|
| R1 | 6.3 | 0.026 | 0.048 | 0.050 | 0.010 | **0.075** | **0.149** | 2.4 % |
| R1 | 4.2 | 0.020 | 0.030 | 0.050 | 0.010 | **0.063** | **0.125** | 3.0 % |
| R1 | 2.8 | 0.015 | 0.026 | 0.050 | 0.010 | **0.059** | **0.118** | 4.2 % |
| R1 | 1.4 | 0.012 | 0.032 | 0.050 | 0.010 | **0.061** | **0.123** | 8.8 % |

- `u_patron` = **0.050** fijo (cilindro certificado, k = 2)
- `u_aire_cero` = **0.010** fijo (F-PSEY-51)

## SO2 — nmol/mol

| ronda | nivel | u_rep (N) | u_curva (N) | u_patron (G) | u_aire_cero (G) | **u_c** | **U (k=2)** | U rel |
|---|---|---|---|---|---|---|---|---|
| R1 | 179 | 0.650 | 0.361 | 0.500 | 0.036 | **0.897** | **1.793** | 1.0 % |
| R1 | 119 | 0.294 | 0.227 | 0.500 | 0.036 | **0.624** | **1.248** | 1.0 % |
| R1 | 80 | 0.168 | 0.197 | 0.500 | 0.036 | **0.564** | **1.129** | 1.4 % |
| R1 | 40 | 0.107 | 0.241 | 0.500 | 0.036 | **0.566** | **1.133** | 2.8 % |

- `u_patron` = **0.500** fijo (cilindro certificado, k = 2)
- `u_aire_cero` = **0.036** fijo (F-PSEY-51)

## NO — nmol/mol

| ronda | nivel | u_rep (N) | u_curva (N) | u_patron (G) | u_aire_cero (G) | **u_c** | **U (k=2)** | U rel |
|---|---|---|---|---|---|---|---|---|
| R2B | 180 | 0.077 | 0.318 | 0.500 | 0.442 | **0.743** | **1.487** | 0.8 % |
| R2B | 119 | 0.074 | 0.204 | 0.500 | 0.442 | **0.702** | **1.404** | 1.2 % |
| R2B | 78 | 0.056 | 0.187 | 0.500 | 0.442 | **0.695** | **1.391** | 1.8 % |
| R2B | 37 | 0.145 | 0.234 | 0.500 | 0.442 | **0.722** | **1.444** | 3.9 % |
| R3 | 179 | 0.135 | 0.860 | 0.500 | 0.442 | **1.097** | **2.193** | 1.2 % |
| R3 | 119 | 0.650 | 0.555 | 0.500 | 0.442 | **1.084** | **2.168** | 1.8 % |
| R3 | 80 | 0.061 | 0.505 | 0.500 | 0.442 | **0.839** | **1.678** | 2.1 % |
| R3 | 41 | 0.071 | 0.617 | 0.500 | 0.442 | **0.912** | **1.824** | 4.4 % |

- `u_patron` = **0.500** fijo (cilindro certificado, k = 2)
- `u_aire_cero` = **0.442** fijo (F-PSEY-51)

## NO2 — nmol/mol

| ronda | nivel | u_rep (N) | u_curva (N) | u_patron (G) | u_aire_cero (G) | u_conv (N) | **u_c** | **U (k=2)** | U rel |
|---|---|---|---|---|---|---|---|---|---|
| R2C | 140 | 0.119 | 0.481 | 0.500 | 0.358 | 1.507 | **1.701** | **3.402** | 2.4 % |
| R2C | 105 | 0.050 | 0.351 | 0.500 | 0.358 | 1.130 | **1.334** | **2.669** | 2.5 % |
| R2C | 60 | 0.050 | 0.287 | 0.500 | 0.358 | 0.646 | **0.938** | **1.876** | 3.1 % |
| R2C | 30 | 0.049 | 0.351 | 0.500 | 0.358 | 0.323 | **0.780** | **1.559** | 5.2 % |
| R3 | 112 | 0.040 | 0.548 | 0.500 | 0.358 | 1.205 | **1.460** | **2.921** | 2.6 % |
| R3 | 64 | 0.096 | 0.392 | 0.500 | 0.358 | 0.689 | **1.008** | **2.016** | 3.1 % |
| R3 | 32 | 0.069 | 0.496 | 0.500 | 0.358 | 0.344 | **0.864** | **1.729** | 5.4 % |

- `u_patron` = **0.500** fijo (cilindro certificado, k = 2)
- `u_aire_cero` = **0.358** fijo (F-PSEY-51)
- `u_conv` = **0.0108 · C** (eficiencia del convertidor 98.14 %)

## O3 — nmol/mol

| ronda | nivel | u_rep (N) | u_curva (N) | u_patron (N) | u_aire_cero (G) | **u_c** | **U (k=2)** | U rel |
|---|---|---|---|---|---|---|---|---|
| R2A | 180 | 0.757 | 1.001 | 0.794 | 0.023 | **1.485** | **2.970** | 1.7 % |
| R2A | 120 | 0.139 | 0.667 | 0.641 | 0.023 | **0.936** | **1.872** | 1.6 % |
| R2A | 80 | 0.044 | 0.523 | 0.539 | 0.023 | **0.753** | **1.506** | 1.9 % |
| R2A | 40 | 0.036 | 0.642 | 0.437 | 0.023 | **0.778** | **1.556** | 3.9 % |
| R3 | 180 | 0.108 | 0.621 | 0.794 | 0.023 | **1.014** | **2.028** | 1.1 % |
| R3 | 120 | 0.206 | 0.404 | 0.641 | 0.023 | **0.786** | **1.571** | 1.3 % |
| R3 | 80 | 0.093 | 0.361 | 0.539 | 0.023 | **0.656** | **1.311** | 1.6 % |
| R3 | 40 | 0.047 | 0.443 | 0.437 | 0.023 | **0.624** | **1.249** | 3.1 % |

- `u_patron` sigue la recta del certificado del calibrador: `(0.0051 · C + 0.67) / 2`
- `u_aire_cero` = **0.023** fijo (F-PSEY-51)

---

## Cómo se combinan

```
u_c = raiz( u_rep^2 + u_curva^2 + u_patron^2 + u_aire_cero^2 + u_conv^2 )
U   = 2 * u_c
```

## Dónde aplicarlos

| ronda | gases | archivo en `data/processed/` |
|---|---|---|
| R1 | SO2, CO | `ronda_1_r.csv` |
| R2A | O3 | `ronda_2a_r.csv` |
| R2B | NO | `ronda_2b_r.csv` |
| R2C | NO2 | `ronda_2c_r.csv` |
| R3 | O3, NO, NO2 | `ronda_3_r.csv` |

Cruce por `pollutant` + `level` contra `outputs/tables/u_referencia_aplicable.csv`:

```r
ref <- read.csv("data/processed/ronda_3_r.csv")
u   <- read.csv("outputs/tables/u_referencia_aplicable.csv")
ref <- merge(ref, u[, c("pollutant", "level", "u_c", "u_exp", "k_factor")],
             by = c("pollutant", "level"), all.x = TRUE)
```

La columna `u_value` que ya traen esos archivos no es esta incertidumbre: es solo repetibilidad y está subestimada. Reemplázala por `u_c`.
