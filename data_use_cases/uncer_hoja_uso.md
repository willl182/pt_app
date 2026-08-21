# Incertidumbres de la referencia — hoja de uso

**Tabla lista:** `outputs/tables/u_referencia_aplicable.csv`
**Detalle y método:** `uncer_presupuesto.md`

---

## 1. Los cinco componentes

| Componente | Qué es | ¿Depende del nivel? |
|---|---|---|
| `u_rep` | Repetibilidad: cuánto varía el analizador entre lecturas | **Sí** |
| `u_curva` | Curva de calibración: qué tan bien traduce lectura a concentración | **Sí** |
| `u_patron` | El patrón que genera el gas (cilindro u ozono) | O3 **sí** · demás **no** |
| `u_aire_cero` | Impureza que deja pasar el generador de aire cero | **No** |
| `u_conv` | Eficiencia del convertidor (solo NO2) | **Sí** |

Se combinan así:

```
u_c = raiz( u_rep^2 + u_curva^2 + u_patron^2 + u_aire_cero^2 + u_conv^2 )
U   = 2 * u_c
```

## 2. Los que NO dependen del nivel

Valores fijos, iguales en todos los niveles de ese gas:

| gas | `u_patron` | `u_aire_cero` |
|---|---|---|
| CO (µmol/mol) | 0.050 | 0.010 |
| SO2 (nmol/mol) | 0.500 | 0.036 |
| NO (nmol/mol) | 0.500 | 0.442 |
| NO2 (nmol/mol) | 0.500 | 0.358 |
| O3 (nmol/mol) | — depende — | 0.023 |

## 3. Los que SÍ dependen del nivel

| componente | regla |
|---|---|
| `u_rep` | Sin fórmula: se midió en cada meseta de cada ronda. Hay que leerla de la tabla |
| `u_curva` | Sin fórmula simple: forma de U, mínima al centro de la curva, sube al cero y al tope. Leer de la tabla |
| `u_patron` de O3 | `u = (0.0051 * C + 0.67) / 2` |
| `u_conv` de NO2 | `u = 0.0108 * C` |

## 4. Por qué el porcentaje sube en los niveles bajos

Los componentes fijos aportan lo mismo en valor absoluto, pero se dividen entre una concentración cada vez menor.

NO2 en R2C:

| nivel | U absoluta | U relativa |
|---|---|---|
| 140 nmol/mol | 3.402 | 2.4 % |
| 30 nmol/mol | 1.559 | 5.2 % |

La incertidumbre absoluta bajó a la mitad, pero el porcentaje se duplicó. **Para comparar niveles entre sí, usa la U absoluta.**

## 5. Tabla final

Unidades: nmol/mol, salvo CO en µmol/mol. `U` con k = 2.

| gas | ronda | nivel | u_rep | u_curva | u_patron | u_aire_cero | u_conv | **u_c** | **U (k=2)** | U rel |
|---|---|---|---|---|---|---|---|---|---|---|
| CO | R1 | 6.3 | 0.026 | 0.048 | 0.050 | 0.010 | — | **0.075** | **0.149** | 2.4 % |
| CO | R1 | 4.2 | 0.020 | 0.030 | 0.050 | 0.010 | — | **0.063** | **0.125** | 3.0 % |
| CO | R1 | 2.8 | 0.015 | 0.026 | 0.050 | 0.010 | — | **0.059** | **0.118** | 4.2 % |
| CO | R1 | 1.4 | 0.012 | 0.032 | 0.050 | 0.010 | — | **0.061** | **0.123** | 8.8 % |
| NO | R2B | 180 | 0.077 | 0.318 | 0.500 | 0.442 | — | **0.743** | **1.487** | 0.8 % |
| NO | R2B | 119 | 0.074 | 0.204 | 0.500 | 0.442 | — | **0.702** | **1.404** | 1.2 % |
| NO | R2B | 78 | 0.056 | 0.187 | 0.500 | 0.442 | — | **0.695** | **1.391** | 1.8 % |
| NO | R2B | 37 | 0.145 | 0.234 | 0.500 | 0.442 | — | **0.722** | **1.444** | 3.9 % |
| NO | R3 | 179 | 0.135 | 0.860 | 0.500 | 0.442 | — | **1.097** | **2.193** | 1.2 % |
| NO | R3 | 119 | 0.650 | 0.555 | 0.500 | 0.442 | — | **1.084** | **2.168** | 1.8 % |
| NO | R3 | 80 | 0.061 | 0.505 | 0.500 | 0.442 | — | **0.839** | **1.678** | 2.1 % |
| NO | R3 | 41 | 0.071 | 0.617 | 0.500 | 0.442 | — | **0.912** | **1.824** | 4.4 % |
| NO2 | R2C | 140 | 0.119 | 0.481 | 0.500 | 0.358 | 1.507 | **1.701** | **3.402** | 2.4 % |
| NO2 | R2C | 105 | 0.050 | 0.351 | 0.500 | 0.358 | 1.130 | **1.334** | **2.669** | 2.5 % |
| NO2 | R2C | 60 | 0.050 | 0.287 | 0.500 | 0.358 | 0.646 | **0.938** | **1.876** | 3.1 % |
| NO2 | R2C | 30 | 0.049 | 0.351 | 0.500 | 0.358 | 0.323 | **0.780** | **1.559** | 5.2 % |
| NO2 | R3 | 112 | 0.040 | 0.548 | 0.500 | 0.358 | 1.205 | **1.460** | **2.921** | 2.6 % |
| NO2 | R3 | 64 | 0.096 | 0.392 | 0.500 | 0.358 | 0.689 | **1.008** | **2.016** | 3.1 % |
| NO2 | R3 | 32 | 0.069 | 0.496 | 0.500 | 0.358 | 0.344 | **0.864** | **1.729** | 5.4 % |
| O3 | R2A | 180 | 0.757 | 1.001 | 0.794 | 0.023 | — | **1.485** | **2.970** | 1.7 % |
| O3 | R2A | 120 | 0.139 | 0.667 | 0.641 | 0.023 | — | **0.936** | **1.872** | 1.6 % |
| O3 | R2A | 80 | 0.044 | 0.523 | 0.539 | 0.023 | — | **0.753** | **1.506** | 1.9 % |
| O3 | R2A | 40 | 0.036 | 0.642 | 0.437 | 0.023 | — | **0.778** | **1.556** | 3.9 % |
| O3 | R3 | 180 | 0.108 | 0.621 | 0.794 | 0.023 | — | **1.014** | **2.028** | 1.1 % |
| O3 | R3 | 120 | 0.206 | 0.404 | 0.641 | 0.023 | — | **0.786** | **1.571** | 1.3 % |
| O3 | R3 | 80 | 0.093 | 0.361 | 0.539 | 0.023 | — | **0.656** | **1.311** | 1.6 % |
| O3 | R3 | 40 | 0.047 | 0.443 | 0.437 | 0.023 | — | **0.624** | **1.249** | 3.1 % |
| SO2 | R1 | 179 | 0.650 | 0.361 | 0.500 | 0.036 | — | **0.897** | **1.793** | 1.0 % |
| SO2 | R1 | 119 | 0.294 | 0.227 | 0.500 | 0.036 | — | **0.624** | **1.248** | 1.0 % |
| SO2 | R1 | 80 | 0.168 | 0.197 | 0.500 | 0.036 | — | **0.564** | **1.129** | 1.4 % |
| SO2 | R1 | 40 | 0.107 | 0.241 | 0.500 | 0.036 | — | **0.566** | **1.133** | 2.8 % |

## 6. Cómo aplicarla a los datos de cada ronda

Cada ronda tiene su archivo de referencia en `data/processed/`:

| ronda | gases | archivo |
|---|---|---|
| R1 | SO2, CO | `ronda_1_r.csv` |
| R2A | O3 | `ronda_2a_r.csv` |
| R2B | NO | `ronda_2b_r.csv` |
| R2C | NO2 | `ronda_2c_r.csv` |
| R3 | O3, NO, NO2 | `ronda_3_r.csv` |

Los `ronda_N_p_ronda.csv` son del participante y no llevan este presupuesto. `parts_r1.csv` no son datos, es el listado de equipos.

El cruce es por `pollutant` + `level`:

```r
ref <- read.csv("data/processed/ronda_3_r.csv")
u   <- read.csv("outputs/tables/u_referencia_aplicable.csv")

ref <- merge(ref, u[, c("pollutant", "level", "u_c", "u_exp", "k_factor")],
             by = c("pollutant", "level"), all.x = TRUE)
```

Quedan tres columnas nuevas: `u_c` (estándar), `u_exp` (expandida) y `k_factor` (= 2).

**Importante:** la columna `u_value` que ya traen esos archivos NO es esta incertidumbre. Es solo la parte de repetibilidad, y además está subestimada. Usa `u_c` en su lugar; no las sumes.

## 7. Lo que falta

- **Controladores de flujo de dilución** en NO, NO2, SO2 y CO. No hay certificado de esos canales.
- **CO en 0.1 µmol/mol de cilindro** es una elección, no un dato leído. Se cambia en `CYLINDER_EXPANDED_U` de `scripts/09_presupuesto_incertidumbre.R`.
- **Se asume k = 2** en el certificado del cilindro.
