# POC GLM-4.7: Implementación de Validación Downstream Algoritmo A

**Fecha**: 2026-03-30
**Estado**: Plan de Implementación
**Basado en**: plan_a2.md + plan_a1_validacion_post_algoA.md

## Resumen Ejecutivo

Implementar una Proof of Concept (POC) para validación cruzada completa de cálculos posteriores al Algoritmo A en `pt_app`, comparando tres fuentes:

1. **app.R** - Implementación actual del sistema Shiny
2. **R independiente** - Script R reproducible sin dependencias Shiny
3. **Python independiente** - Script Python para verificación cruzada
4. **Excel** - Hojas de validación por combinación objetivo

## Combinaciones Objetivo (15 total)

| Contaminante | Nivel 1 | Nivel 3 | Nivel 5 |
|--------------|---------|---------|---------|
| CO | `0-μmol/mol` | `4-μmol/mol` | `8-μmol/mol` |
| NO | `0-nmol/mol` | `81-nmol/mol` | `121-nmol/mol` |
| NO2 | `0-nmol/mol` | `60-nmol/mol` | `120-nmol/mol` |
| O3 | `0-nmol/mol` | `80-nmol/mol` | `180-nmol/mol` |
| SO2 | `0-nmol/mol` | `60-nmol/mol` | `100-nmol/mol` |

## Estructura de Archivos a Crear

```
validation/
├── poc_glm47.R                     # Script R principal (POC)
├── poc_glm47.py                    # Script Python verificación cruzada
├── helpers/
│   ├── extract_app_logic.R         # Extracción lógica desde app.R
│   ├── robust_stats_indep.R        # Funciones R independientes
│   └── utils.R                     # Helpers comunes
├── output/
│   ├── Val_01_Robust_Stats.xlsx   # 15 hojas + índice
│   ├── Val_02_Homogeneity.xlsx    # 15 hojas + índice
│   ├── Val_03_Stability.xlsx      # 15 hojas + índice
│   ├── Val_04_Uncertainties.xlsx  # 15 hojas + índice
│   ├── Val_05_Scores.xlsx         # 15 hojas + índice
│   ├── A2_CO_0_umol.xlsx          # Por combinación (6 hojas c/u)
│   ├── A2_CO_4_umol.xlsx
│   └── ... (13 archivos más)
└── reports/
    ├── comparison_summary.csv      # Resumen comparativo
    └── validation_report.md       # Reporte final
```

## Fase 1: Preparación y Extracción

### Tarea 1.1: Análisis de app.R
- Localizar funciones clave en app.R
- Identificar puntos de entrada para extracción
- Documentar constantes y parámetros globales

**Archivos a leer:**
- `app.R` (líneas 2328-2542: compute_combo_scores, compute_scores_for_selection)
- `R/pt_robust_stats.R` (calculate_mad_e, calculate_niqr)
- `R/pt_homogeneity.R` (homogeneity y stability)
- `R/pt_scores.R` (4 puntajes + evaluaciones)

### Tarea 1.2: Creación de helpers de extracción
- `validation/helpers/extract_app_logic.R`: funciones para replicar lógica de app.R
- `validation/helpers/robust_stats_indep.R`: reimplementación independiente

**Constantes a definir:**
```r
ALGO_A_TOL <- 1e-04
MATCH_TOL_R_EXCEL <- 1e-12
MATCH_TOL_AGGREGATE <- 1e-9
K_FACTOR <- 2
```

## Fase 2: Implementación R (Principal)

### Tarea 2.1: Script Principal - `validation/poc_glm47.R`

**Estructura:**
```r
# Carga de librerías
library(openxlsx2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# Source helpers
source("validation/helpers/extract_app_logic.R")
source("validation/helpers/robust_stats_indep.R")
source("R/pt_robust_stats.R")
source("R/pt_homogeneity.R")
source("R/pt_scores.R")

# 1. Carga de datos
# 2. Definición de 15 combinaciones
# 3. Loop principal por combinación
#    - Extracción de datos app
#    - Cálculo independiente R
#    - Generación de hojas Excel
# 4. Escritura de archivos de salida
# 5. Generación de reporte resumen
```

### Tarea 2.2: Sección 1 - Estadísticos Robustos (Val_01)

**Por cada combinación:**
1. Extraer valores por participante (agregación de réplicas)
2. Calcular: median, MAD, MADe, Q1, Q3, IQR, nIQR
3. Comparar: app.R vs R independiente
4. Crear hoja en Val_01_Robust_Stats.xlsx

**Tolerancia:** `1e-9` para comparaciones

### Tarea 2.3: Sección 2 - Homogeneidad (Val_02)

**Por cada combinación:**
1. Pivotear datos homogeneity_n13 (rep1, rep2)
2. Calcular: g, m, media_general, x_pt, s²_x̄, sw, ss, ss², MADe_hom, σ_pt, u(σ_pt)
3. Calcular criterios: c_estándar, c_expandido
4. Evaluación: ss ≤ c
5. Comparar: app.R vs R independiente

**Funciones clave:**
- `calculate_homogeneity_stats()`
- `calculate_homogeneity_criterion()`
- `calculate_homogeneity_criterion_expanded()`

### Tarea 2.4: Sección 3 - Estabilidad (Val_03)

**Por cada combinación:**
1. Pivotear datos stability_n13
2. Calcular: media_estab, d_max = |media_estab - media_homog|
3. Calcular: c_estándar, c_expandido
4. Calcular u_stab = d_max / sqrt(3) ⚠️ (usar lógica app.R, no función pura)
5. Evaluación: d_max ≤ c

**⚠️ Discrepancia crítica:**
- `app.R:2494`: u_stab = d_max/sqrt(3) (incondicional)
- `pt_homogeneity.R:401`: u_stab = 0 si criterio se cumple
- **Usar lógica de app.R**

### Tarea 2.5: Sección 4 - Incertidumbres (Val_04)

**Por cada combinación y método (4 métodos):**

**Método 1 - Referencia:**
- x_pt = mean(ref_data$mean_value)
- σ_pt = hom_res$sigma_pt
- u(x_pt) = hom_res$u_xpt

**Método 2a - Consenso MADe:**
- x_pt = median(participant_values)
- σ_pt = 1.483 × median(|xi - mediana|)
- u(x_pt) = 1.25 × σ_pt / sqrt(n_part)

**Método 2b - Consenso nIQR:**
- x_pt = median(participant_values)
- σ_pt = calculate_niqr(values)
- u(x_pt) = 1.25 × σ_pt / sqrt(n_part)

**Método 3 - Algoritmo A:**
- x_pt = algo_res$assigned_value
- σ_pt = algo_res$robust_sd
- u(x_pt) = 1.25 × s* / sqrt(n_part)

**Común a todos:**
- u_hom = hom_res$ss
- u_stab = d_max / sqrt(3)
- u(x_pt)_def = sqrt(u_xpt² + u_hom² + u_stab²)
- U(x_pt) = 2 × u(x_pt)_def

### Tarea 2.6: Sección 5 - Puntajes (Val_05)

**Por cada combinación, método y participante:**
1. Calcular z = (x - x_pt) / σ_pt
2. Calcular z' = (x - x_pt) / sqrt(σ_pt² + u_xpt_def²)
3. Calcular ζ = (x - x_pt) / sqrt(u_x² + u_xpt_def²)
4. Calcular En = (x - x_pt) / sqrt(U_xi² + U_xpt²)

**Evaluaciones:**
- z, z', ζ: |score| ≤ 2 → "Satisfactorio", 2 < |score| < 3 → "Cuestionable", |score| ≥ 3 → "No satisfactorio"
- En: |En| ≤ 1 → "Satisfactorio", |En| > 1 → "No satisfactorio"

## Fase 3: Implementación Python (Verificación Cruzada)

### Tarea 3.1: Script Principal - `validation/poc_glm47.py`

**Dependencias:**
```python
import csv
import math
import statistics
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Border, Side
from typing import List, Dict, Tuple
```

### Tarea 3.2: Reimplementación de funciones

**Estadísticos robustos:**
- `median_type7(data)` - quantile type 7 de R
- `mad_e(data)` - 1.483 × MAD
- `niqr(data)` - 0.7413 × IQR

**Homogeneidad y estabilidad:**
- `homogeneity_stats(hom_data)`
- `stability_stats(stab_data, hom_mean)`

**Puntajes:**
- `z_score(x, x_pt, sigma_pt)`
- `z_prime_score(x, x_pt, sigma_pt, u_xpt_def)`
- `zeta_score(x, x_pt, u_x, u_xpt_def)`
- `en_score(x, x_pt, U_xi, U_xpt)`

### Tarea 3.3: Estructura de salida Python

Cada hoja Excel tendrá columnas:
- `Python Calc` - valor calculado por Python
- `Expected (R)` - valor de referencia (de script R)
- `Match` - TRUE si |Python - Expected| < 1e-9

## Fase 4: Generación de Excels por Combinación (A2)

### Tarea 4.1: Estructura de cada workbook

Por cada combinación (15 archivos):
- `00_input` - datos fuente, parámetros, identificadores
- `01_algorithm_a_feed` - serie agregada por participante
- `02_uncertainty_chain` - u_xpt, u_hom, u_stab, u_xpt_def, U_xpt
- `03_scores` - z, z', zeta, En por participante
- `04_global_checks` - tablas agregadas downstream
- `05_comparison` - app.R vs R vs Excel con diferencias

### Tarea 4.2: Formato de comparación

Columnas en `05_comparison`:
- `combo_id`
- `pollutant`
- `level`
- `section`
- `participant_id` (si aplica)
- `metric`
- `app_value`
- `r_value`
- `excel_value`
- `diff_app_r`
- `diff_app_excel`
- `diff_r_excel`
- `status` (PASS/FAIL)
- `tolerance`

**Tolerancias:**
- R vs Excel (fórmula exacta): `1e-12`
- Agregados con redondeo: `1e-9`
- Etiquetas de evaluación: igualdad exacta

## Fase 5: Reportes y Validación

### Tasa 5.1: Resumen maestro

Generar `validation/output/comparison_summary.csv` con:
- `combo_id`
- `section`
- `total_metrics`
- `pass_count`
- `fail_count`
- `status` (PASS si fail_count = 0)

### Tarea 5.2: Reporte final

Crear `validation/reports/validation_report.md` con:
- Resumen de ejecución
- Listado de combinaciones procesadas
- Tabla de PASS/FAIL por sección
- Detalle de discrepancias (si hay)
- Notas sobre casos borde (niveles 0 con sigma_pt ≈ 0)

## Orden de Implementación

### Prioridad 1 (Core):
1. Fase 1: Preparación (Tareas 1.1, 1.2)
2. Fase 2.1: Script R base
3. Fase 2.2: Sección 1 - Robust Stats
4. Fase 2.3: Sección 2 - Homogeneity

### Prioridad 2 (Completitud):
5. Fase 2.4: Sección 3 - Stability
6. Fase 2.5: Sección 4 - Uncertainties
7. Fase 2.6: Sección 5 - Scores
8. Fase 5.1: Resumen maestro

### Prioridad 3 (Verificación):
9. Fase 3: Implementación Python
10. Fase 4: Excels por combinación A2
11. Fase 5.2: Reporte final

## Criterios de Aceptación

La POC se considerará exitosa si:

1. ✅ Las 15 combinaciones se resuelven sin ambigüedad
2. ✅ Se generan los 5 archivos Val_01 a Val_05 con 15 hojas cada uno
3. ✅ Se generan 15 workbooks A2 con 6 hojas cada uno
4. ✅ Coinciden todos los estadísticos robustos (tolerancia 1e-9)
5. ✅ Coinciden x_pt, sigma_pt y u_xpt por método
6. ✅ Coinciden u_hom, u_stab, u_xpt_def, U_xpt
7. ✅ Coinciden z, z', zeta, En por participante y método
8. ✅ Coinciden evaluaciones cualitativas (exactitud)
9. ✅ Python reproduce valores R (tolerancia 1e-9)
10. ✅ El resumen maestro no reporta FAIL
11. ✅ Se documentan casos borde (niveles 0)

## Archivos de Referencia Críticos

Durante implementación, consultar:
- `app.R:2328-2398` - `compute_combo_scores()` (fórmulas puntajes)
- `app.R:2431-2542` - `compute_scores_for_selection()` (flujo completo)
- `app.R:127` - `ALGO_A_TOL`
- `app.R:2453-2459` - agregación por participante
- `app.R:2476` - x_pt método referencia
- `app.R:2494` - u_stab incondicional
- `R/pt_robust_stats.R` - funciones robustas
- `R/pt_homogeneity.R` - homogeneidad y estabilidad
- `R/pt_scores.R` - 4 puntajes + evaluaciones
- `data/summary_n13.csv` - datos principales
- `data/homogeneity_n13.csv` - homogeneidad
- `data/stability_n13.csv` - estabilidad
- `validation/generate_algoA_validation.R` - patrón estilos openxlsx

## Comandos de Ejecución

```r
# Ejecutar POC R
Rscript validation/poc_glm47.R

# Ejecutar validación Python
python3 validation/poc_glm47.py

# Ver resultados
ls -lh validation/output/
```

## Manejo de Errores y Casos Borde

### Caso 1: sigma_pt ≈ 0 (niveles 0)
- Generará NA en puntajes z, z', zeta, En
- Debe registrarse en reporte como "expected NA"
- No debe causar fallo de script

### Caso 2: Discrepancia u_stab
- Documentar en reporte final
- Usar siempre lógica de app.R (incondicional)
- Agregar comentario explícito en código

### Caso 3: Diferencias en tolerancia
- Revisar si es redondeo acumulado (usar 1e-9)
- O es fórmula exacta (usar 1e-12)
- Ajustar según contexto

## Próximos Pasos Después de POC

1. Validar con usuario final
2. Ajustar tolerancias según necesidad
3. Integrar tests en suite de testthat
4. Documentar para equipo de desarrollo
5. Considerar extensión a otros algoritmos
