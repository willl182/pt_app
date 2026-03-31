# Plan A1: Validación Post-Algoritmo A

## Contexto

El Algoritmo A (winsorización iterativa, ISO 13528:2022 Anexo C) ya está validado con hojas Excel dedicadas. Falta validar **todo lo que viene después**: estadísticos robustos de consenso, homogeneidad, estabilidad, propagación de incertidumbres, y los 4 puntajes de desempeño (z, z', zeta, En). Se necesita una comparación tripartita: **funciones R del app** vs **cálculo independiente R** vs **cálculo independiente Python**, usando el dataset `summary_n13` con 12 participantes.

## Combinaciones a validar

15 combos: niveles 1°, 3° y 5° (por orden ascendente de concentración) de cada contaminante:

| Contaminante | Nivel 1 | Nivel 3 | Nivel 5 |
|---|---|---|---|
| CO | `0-μmol/mol` | `4-μmol/mol` | `8-μmol/mol` |
| NO | `0-nmol/mol` | `81-nmol/mol` | `121-nmol/mol` |
| NO2 | `0-nmol/mol` | `60-nmol/mol` | `120-nmol/mol` |
| O3 | `0-nmol/mol` | `80-nmol/mol` | `180-nmol/mol` |
| SO2 | `0-nmol/mol` | `60-nmol/mol` | `100-nmol/mol` |

**Nota**: los niveles `0-*` pueden producir sigma_pt ≈ 0, generando NA en puntajes. Esto es un caso borde importante a documentar.

## Archivos a crear

```
validation/
  generate_post_algoA_validation.R      # Script R principal (openxlsx2)
  generate_post_algoA_validation.py     # Script Python verificación cruzada (openpyxl)
  Val_01_Robust_Stats.xlsx              # Salida
  Val_02_Homogeneity.xlsx               # Salida
  Val_03_Stability.xlsx                 # Salida
  Val_04_Uncertainties.xlsx             # Salida
  Val_05_Scores.xlsx                    # Salida
```

## Sección 1: Val_01_Robust_Stats.xlsx — Estadísticos robustos y consenso

**Datos fuente**: `data/summary_n13.csv`
**Funciones app**: `calculate_mad_e()`, `calculate_niqr()` de `R/pt_robust_stats.R`

**Por cada combo (15 hojas + INDICE + RESUMEN)**:

| Métrica | Fórmula | App (col B) | Independiente (col C) | Match (col D) |
|---|---|---|---|---|
| Valores xi (12 participantes) | `mean(mean_value)` por participant_id, excluyendo "ref" | — | — | — |
| Mediana | `median(xi)` | `median(values)` | reimplementado | `abs(B-C)<1e-9` |
| MAD | `median(\|xi - mediana\|)` | intermedio | reimplementado | |
| MADe | `1.483 × MAD` | `calculate_mad_e(values)` | `1.483 * MAD` | |
| Q1, Q3 | `quantile(x, type=7)` | `quantile()` | reimplementado | |
| IQR | `Q3 - Q1` | | | |
| nIQR | `0.7413 × IQR` | `calculate_niqr(values)` | `0.7413 * IQR` | |

**Extracción de datos app** (replica lógica `app.R:2453-2459`):
```r
participant_data <- summary_data %>%
  filter(pollutant == pol, level == lev, participant_id != "ref") %>%
  group_by(participant_id) %>%
  summarise(result = mean(mean_value), sd_value = mean(sd_value))
```

## Sección 2: Val_02_Homogeneity.xlsx — Evaluación de homogeneidad

**Datos fuente**: `data/homogeneity_n13.csv`
**Funciones app**: `calculate_homogeneity_stats()`, `calculate_homogeneity_criterion()`, `calculate_homogeneity_criterion_expanded()`, `evaluate_homogeneity()` de `R/pt_homogeneity.R`

**Por cada combo (15 hojas + INDICE + FORMULAS + RESUMEN)**:

| Métrica | Fórmula |
|---|---|
| Datos crudos | sample_id × (rep1, rep2) de homogeneity_n13.csv |
| g, m | nro muestras, nro réplicas |
| Media general | `mean(todos los valores)` |
| x_pt | `median(rep1_values)` |
| s²_x̄ | `var(medias_muestra)` |
| sw | `sqrt(sum(rangos²)/(2g))` para m=2 |
| ss² | `\|s²_x̄ - sw²/m\|` |
| ss | `sqrt(ss²)` o 0 si ss²<0 |
| MADe_hom | `1.483 × median(\|rep2 - x_pt\|)` |
| σ_pt | = MADe_hom |
| u(σ_pt) | `1.25 × MADe / sqrt(g)` |
| c criterio | `0.3 × σ_pt` |
| c expandido | `F1×(0.3×σ_pt)² + F2×sw²` con tabla F1,F2 por g |
| Evaluación | `ss ≤ c` → Cumple/No cumple |

**Pivoteo de datos** (replica lógica app.R):
```r
hom_wide <- hom_data %>%
  filter(pollutant == pol, level == lev) %>%
  pivot_wider(names_from = replicate, values_from = value, names_prefix = "rep_")
```

## Sección 3: Val_03_Stability.xlsx — Evaluación de estabilidad

**Datos fuente**: `data/stability_n13.csv` + resultados de homogeneidad
**Funciones app**: `calculate_stability_stats()`, `calculate_stability_criterion()`, `evaluate_stability()`, `calculate_u_stab()` de `R/pt_homogeneity.R`

**Por cada combo (15 hojas)**:

| Métrica | Fórmula |
|---|---|
| Datos crudos estabilidad | sample_id × (rep1, rep2) |
| Media general estabilidad | `mean(todos)` |
| d_max | `\|media_estab - media_homog\|` |
| c criterio | `0.3 × σ_pt` (de homogeneidad) |
| c expandido | `c + 2×sqrt(u_media_hom² + u_media_stab²)` |
| u_stab | `d_max / sqrt(3)` (**siempre**, ver nota) |
| Evaluación | `d_max ≤ c` → Cumple/No cumple |

**⚠️ Discrepancia documentada**: `app.R:2494` calcula `u_stab = d_max/sqrt(3)` **incondicionalmente**, mientras que `calculate_u_stab()` en `pt_homogeneity.R:401` retorna 0 si el criterio se cumple. La validación usa el comportamiento de app.R.

## Sección 4: Val_04_Uncertainties.xlsx — Propagación de incertidumbres

**Datos fuente**: resultados de secciones 1-3 + `summary_n13.csv`
**Lógica app**: `compute_scores_for_selection()` en `app.R:2431-2542`

**Por cada combo (15 hojas), 4 sub-tablas (una por método)**:

### Método 1 — Referencia
| Parámetro | Fuente |
|---|---|
| x_pt | `mean(ref_data$mean_value)` (app.R:2476) |
| σ_pt | `hom_res$sigma_pt` = MADe_hom |
| u(x_pt) | `hom_res$u_xpt` = `1.25 × MADe / sqrt(g)` |

### Método 2a — Consenso MADe
| Parámetro | Fuente |
|---|---|
| x_pt | `median(participant_values)` |
| σ_pt | `1.483 × median(\|xi - mediana\|)` (app.R:2510-2511, inline) |
| u(x_pt) | `1.25 × σ_pt / sqrt(n_part)` |

### Método 2b — Consenso nIQR
| Parámetro | Fuente |
|---|---|
| x_pt | `median(participant_values)` |
| σ_pt | `calculate_niqr(values)` |
| u(x_pt) | `1.25 × σ_pt / sqrt(n_part)` |

### Método 3 — Algoritmo A
| Parámetro | Fuente |
|---|---|
| x_pt | `algo_res$assigned_value` |
| σ_pt | `algo_res$robust_sd` |
| u(x_pt) | `1.25 × s* / sqrt(n_part)` |
| Nota | `ALGO_A_TOL = 1e-04` (app.R:127) |

### Común a todos los métodos
| Parámetro | Fórmula |
|---|---|
| u_hom | `hom_res$ss` (app.R:2481) |
| u_stab | `d_max / sqrt(3)` (app.R:2494) |
| u(x_pt)_def | `sqrt(u_xpt² + u_hom² + u_stab²)` (app.R:2329) |
| k | 2 |
| U(x_pt) | `k × u(x_pt)_def` |

**Nota**: `uncertainty_std` del participante = `sd_value / sqrt(hom_res$m)` donde m = nro réplicas de homogeneidad (app.R:2465).

## Sección 5: Val_05_Scores.xlsx — Puntajes de desempeño

**Funciones app**: `calculate_z_score()`, `calculate_z_prime_score()`, `calculate_zeta_score()`, `calculate_en_score()`, `evaluate_z_score_vec()`, `evaluate_en_score_vec()` de `R/pt_scores.R`

**Por cada combo (15 hojas), 4 sub-tablas (una por método), 12 filas (participantes)**:

| Puntaje | Fórmula (app.R:2349-2361) |
|---|---|
| z | `(x - x_pt) / σ_pt` |
| z' | `(x - x_pt) / sqrt(σ_pt² + u_xpt_def²)` |
| ζ | `(x - x_pt) / sqrt(u_x² + u_xpt_def²)` |
| En | `(x - x_pt) / sqrt(U_xi² + U_xpt²)` |

Donde: `u_x = uncertainty_std`, `U_xi = k × u_x`, `U_xpt = k × u_xpt_def`

**Evaluación**:
- z, z', ζ: |score| ≤ 2 → "Satisfactorio", 2 < |score| < 3 → "Cuestionable", |score| ≥ 3 → "No satisfactorio"
- En: |En| ≤ 1 → "Satisfactorio", |En| > 1 → "No satisfactorio"

## Script R — Estructura

```r
# validation/generate_post_algoA_validation.R
# Uso: Rscript validation/generate_post_algoA_validation.R

library(openxlsx2)
library(dplyr)
library(tidyr)

source("R/pt_robust_stats.R")
source("R/pt_homogeneity.R")
source("R/pt_scores.R")

ALGO_A_TOL <- 1e-04
MATCH_TOL <- 1e-9
K_FACTOR <- 2

# 1. Leer datos
summary_data <- read.csv("data/summary_n13.csv")
hom_data <- read.csv("data/homogeneity_n13.csv")
stab_data <- read.csv("data/stability_n13.csv")

# 2. Definir 15 combos
COMBOS <- list(
  list(pol = "co", lev = "0-μmol/mol"), ...
)

# 3. Helpers: get_participant_values(), get_hom_matrix(), get_stab_matrix()
# 4. Para cada combo: calcular las 5 secciones
# 5. Escribir cada sección a su .xlsx
```

## Script Python — Estructura

```python
# validation/generate_post_algoA_validation.py
# Uso: python3 validation/generate_post_algoA_validation.py

import csv, math, statistics
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Border, Side

# Reimplementación independiente de TODAS las fórmulas
# Sin dependencias de R ni del app

# Funciones: median_type7(), mad_e(), niqr(), quantile_type7()
# Homogeneidad: homogeneity_stats(), stability_stats()
# Puntajes: z_score(), z_prime(), zeta(), en_score()
# Evaluaciones: eval_z(), eval_en()

# Mismas 15 combos, misma estructura de hojas
# Columnas: Python Calc | Expected | Match
```

## Orden de implementación

1. **Val_01** (Robust Stats) — más simple, establece el patrón
2. **Val_02** (Homogeneidad) — requiere pivoteo de datos
3. **Val_03** (Estabilidad) — depende de homogeneidad
4. **Val_04** (Incertidumbres) — combina todo lo anterior
5. **Val_05** (Puntajes) — cadena completa

Primero todo el script R, luego todo el script Python.

## Verificación

1. **Columna Match** en cada hoja: `abs(app - indep) < 1e-9`
2. **Hoja RESUMEN** en cada xlsx: cuenta de TRUE/FALSE por combo
3. **R vs Python**: comparar valores independientes R contra Python (deben coincidir)
4. **Casos borde**: nivel 0 de cada contaminante puede dar sigma_pt ≈ 0 → puntajes NA
5. **Discrepancia u_stab**: documentar diferencia entre app.R (incondicional) y función pura

## Archivos críticos a consultar durante implementación

- `R/pt_robust_stats.R` — `calculate_mad_e()`, `calculate_niqr()`, `run_algorithm_a()`
- `R/pt_homogeneity.R` — `calculate_homogeneity_stats()`, `calculate_stability_stats()`, criterios, u_hom, u_stab
- `R/pt_scores.R` — los 4 scores + evaluaciones
- `app.R:2328-2398` — `compute_combo_scores()` (fórmulas exactas de puntajes)
- `app.R:2431-2542` — `compute_scores_for_selection()` (flujo completo de extracción)
- `app.R:127` — `ALGO_A_TOL = 1e-04`
- `validation/generate_algoA_validation.R` — patrón de estilos openxlsx para las hojas
