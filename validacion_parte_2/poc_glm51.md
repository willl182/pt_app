# POC GLM-51: Validación Downstream Post-Algoritmo A

**Fecha**: 2026-03-30
**Estado**: plan
**Fusiona**: Plan A1 (tripartita por sección) + Plan A2 (canónico por combo)
**Modelo ejecutor**: glm-5.1

---

## 1. Objetivo

Validar toda la cadena de cálculos posterior al Algoritmo A en `pt_app`,
comparando tres fuentes independientes por cada una de las 15 combinaciones
objetivo:

| Fuente | Descripción |
|--------|-------------|
| **APP** | Extracción directa desde la lógica de `app.R` (funciones `R/`) |
| **R**   | Cálculo independiente reimplementado en R puro (sin `source()`) |
| **PY**  | Cálculo independiente reimplementado en Python puro (sin dependencias R) |

---

## 2. Dataset y 15 combinaciones

### Datos fuente

| Archivo | Rol |
|---------|-----|
| `data/summary_n13.csv` | Resultados de participantes (cols: `pollutant`, `run`, `level`, `participant_id`, `replicate`, `sample_group`, `mean_value`, `sd_value`) |
| `data/homogeneity_n13.csv` | Datos de homogeneidad (cols: `pollutant`, `run`, `level`, `replicate`, `sample_id`, `value`) |
| `data/stability_n13.csv` | Datos de estabilidad (cols: `pollutant`, `run`, `level`, `replicate`, `sample_id`, `value`) |

### 15 combinaciones (niveles 1, 3, 5 por contaminante)

| # | ID | Contaminante | Nivel |
|---|-----|-------------|-------|
| 1 | CO_0 | co | 0-μmol/mol |
| 2 | CO_4 | co | 4-μmol/mol |
| 3 | CO_8 | co | 8-μmol/mol |
| 4 | NO_0 | no | 0-nmol/mol |
| 5 | NO_81 | no | 81-nmol/mol |
| 6 | NO_121 | no | 121-nmol/mol |
| 7 | NO2_0 | no2 | 0-nmol/mol |
| 8 | NO2_60 | no2 | 60-nmol/mol |
| 9 | NO2_120 | no2 | 120-nmol/mol |
| 10 | O3_0 | o3 | 0-nmol/mol |
| 11 | O3_80 | o3 | 80-nmol/mol |
| 12 | O3_180 | o3 | 180-nmol/mol |
| 13 | SO2_0 | so2 | 0-nmol/mol |
| 14 | SO2_60 | so2 | 60-nmol/mol |
| 15 | SO2_100 | so2 | 100-nmol/mol |

**Nota**: niveles `0-*` pueden producir `sigma_pt ≈ 0` → puntajes NA. Documentar como caso borde.

---

## 3. Arquitectura de salida

### 3.1 Estructura por sección (siguiendo A1)

Se generan **5 workbooks** temáticos, cada uno con **15 hojas de combo** +
**INDICE** + **RESUMEN** (+ **FORMULAS** donde aplique):

```
validation/
  poc_glm51/
    Val_01_Robust_Stats.xlsx
    Val_02_Homogeneity.xlsx
    Val_03_Stability.xlsx
    Val_04_Uncertainties.xlsx
    Val_05_Scores.xlsx
    poc_glm51_master.csv          ← resumen maestro PASS/FAIL
```

### 3.2 Estructura por hoja de combo

Cada hoja de combo contiene **3 bloques columnares**:

```
| Métrica | APP_valor | R_valor | PY_valor | diff_APP_R | diff_APP_PY | diff_R_PY | tol | status |
```

- `status` = `PASS` si las 3 diferencias < `tol`, `FAIL` si alguna falla.
- `tol` varía por métrica (ver §5).

### 3.3 Hoja RESUMEN (por workbook)

| combo_id | sección | total_checks | PASS | FAIL | métricas_fallidas |
|----------|---------|-------------|------|------|-------------------|

### 3.4 CSV maestro (`poc_glm51_master.csv`)

Columnas canónicas (de A2):

```
combo_id, pollutant, level, section, participant_id, metric,
app_value, r_value, py_value,
diff_app_r, diff_app_py, diff_r_py,
status, tolerance
```

---

## 4. Contenido por sección

### 4.1 Val_01_Robust_Stats.xlsx

**Referencia**: `R/pt_robust_stats.R:33-95`, `app.R:2453-2459`

**Extracción de datos** (replica `app.R:2453-2459`):
```r
participant_data <- summary_data %>%
  filter(pollutant == pol, level == lev, participant_id != "ref") %>%
  group_by(participant_id) %>%
  summarise(result = mean(mean_value), sd_value = mean(sd_value))
values <- participant_data$result
```

**Métricas por combo (1 fila por métrica)**:

| Métrica | Fórmula APP | Fórmula R indep. | Fórmula PY indep. |
|---------|-------------|-------------------|--------------------|
| n | `length(values)` | `len(values)` | `len(values)` |
| xi (12 filas) | `participant_data$result[i]` | idem | idem |
| sd_i (12 filas) | `participant_data$sd_value[i]` | idem | idem |
| Mediana | `median(values)` | `statistics.median()` | reimplementado |
| MAD | `median(abs(xi - mediana))` | idem | idem |
| MADe | `calculate_mad_e(values)` = `1.483 * MAD` | `1.483 * MAD` | `1.483 * MAD` |
| Q1 | `quantile(values, 0.25, type=7)` | idem | `numpy.percentile(25)` equiv |
| Q3 | `quantile(values, 0.75, type=7)` | idem | idem |
| IQR | `Q3 - Q1` | idem | idem |
| nIQR | `calculate_niqr(values)` = `0.7413 * IQR` | `0.7413 * IQR` | `0.7413 * IQR` |

### 4.2 Val_02_Homogeneity.xlsx

**Referencia**: `R/pt_homogeneity.R:45-210`, `app.R:292-524`

**Pivoteo de datos** (replica `app.R`):
```r
hom_wide <- hom_data %>%
  filter(pollutant == pol, level == lev) %>%
  pivot_wider(names_from = replicate, values_from = value, names_prefix = "rep_")
```

**Métricas por combo**:

| Métrica | Fórmula | Línea ref. |
|---------|---------|------------|
| g (muestras) | `nrow(hom_wide)` | `pt_homogeneity.R:55` |
| m (réplicas) | `ncol(rep_cols)` | `pt_homogeneity.R:56` |
| Media general | `mean(all_values)` | `pt_homogeneity.R:67` |
| Medias por muestra | `rowMeans(rep_matrix)` | `pt_homogeneity.R:70-72` |
| x_pt (mediana rep1) | `median(rep1_values)` | `pt_homogeneity.R:77` |
| s²_x̄ | `var(sample_means)` | `pt_homogeneity.R:83` |
| sw | `sqrt(sum(ranges²) / (2*g))` para m=2 | `pt_homogeneity.R:87-92` |
| ss² | `abs(s²_x̄ - sw²/m)` | `pt_homogeneity.R:97` |
| ss | `sqrt(max(0, ss²))` | `pt_homogeneity.R:99` |
| MADe_hom | `1.483 * median(abs(rep2 - x_pt))` | `pt_homogeneity.R:102-105` |
| sigma_pt | `= MADe_hom` | `pt_homogeneity.R:108` |
| u_sigma_pt | `1.25 * MADe / sqrt(g)` | `pt_homogeneity.R:111` |
| c_criterio | `0.3 * sigma_pt` | `pt_homogeneity.R:139-148` |
| c_expandido | Fórmula F1/F2 por g (ver lookup) | `pt_homogeneity.R:157-183` |
| Evaluación | `ss <= c → "Cumple"/"No cumple"` | `pt_homogeneity.R:187-203` |
| u_hom | `ss` | `pt_homogeneity.R:386` |

### 4.3 Val_03_Stability.xlsx

**Referencia**: `R/pt_homogeneity.R:228-365`, `app.R:526-754`

**Métricas por combo**:

| Métrica | Fórmula | Línea ref. |
|---------|---------|------------|
| Datos crudos estab | `stab_data filtrado` | — |
| Media general estab | `mean(all_stab_values)` | `pt_homogeneity.R:244+` |
| d_max | `abs(media_estab - media_homog)` | `pt_homogeneity.R:276` |
| c_criterio | `0.3 * sigma_pt` (de homogeneidad) | `pt_homogeneity.R:322` |
| c_expandido | `c + 2*sqrt(u_hom_mean² + u_stab_mean²)` | `pt_homogeneity.R:335` |
| Evaluación estab | `d_max <= c → "Cumple"/"No cumple"` | `pt_homogeneity.R:349` |
| u_stab | **`d_max / sqrt(3)` (incondicional)** | `app.R:2494` |

**⚠️ Discrepancia documentada**: `app.R:2494` calcula `u_stab = d_max/sqrt(3)`
incondicionalmente, mientras que `calculate_u_stab()` en `R/pt_homogeneity.R:401`
retorna 0 si el criterio se cumple. **La validación POC usa el comportamiento de
`app.R`** como fuente de verdad.

### 4.4 Val_04_Uncertainties.xlsx

**Referencia**: `app.R:2431-2542`, `app.R:2328-2398`

Cada hoja de combo contiene **4 sub-tablas** (una por método de asignación).

#### Método 1 — Referencia

| Parámetro | Fuente APP | Línea ref. |
|-----------|-----------|------------|
| x_pt | `mean(ref_data$mean_value)` | `app.R:2476` |
| σ_pt | `hom_res$sigma_pt` (= MADe_hom) | `app.R:2478` |
| u(x_pt) | `hom_res$u_xpt` = `1.25 * MADe / sqrt(g)` | `app.R:2479` |

#### Método 2a — Consenso MADe

| Parámetro | Fuente APP | Línea ref. |
|-----------|-----------|------------|
| x_pt | `median(participant_values)` | `app.R:2509` |
| σ_pt | `1.483 * median(abs(xi - mediana))` | `app.R:2510-2511` |
| u(x_pt) | `1.25 * σ_pt / sqrt(n_part)` | `app.R:2512` |

#### Método 2b — Consenso nIQR

| Parámetro | Fuente APP | Línea ref. |
|-----------|-----------|------------|
| x_pt | `median(participant_values)` | `app.R:2524` |
| σ_pt | `calculate_niqr(values)` | `app.R:2525` |
| u(x_pt) | `1.25 * σ_pt / sqrt(n_part)` | `app.R:2526` |

#### Método 3 — Algoritmo A

| Parámetro | Fuente APP | Línea ref. |
|-----------|-----------|------------|
| x_pt | `algo_res$assigned_value` | `app.R:2538` |
| σ_pt | `algo_res$robust_sd` | `app.R:2539` |
| u(x_pt) | `1.25 * s* / sqrt(n_part)` | `app.R:2540` |
| **Precondición** | Solo si `n_part >= 12` | `app.R:2533` |

**Parámetros de Algoritmo A**: `max_iter = 50`, `tol = 1e-04` (`app.R:127`).

#### Común a todos los métodos

| Parámetro | Fórmula | Línea ref. |
|-----------|---------|------------|
| u_hom | `hom_res$ss` | `app.R:2481` |
| u_stab | `d_max / sqrt(3)` (incondicional) | `app.R:2494` |
| u(x_pt)_def | `sqrt(u_xpt² + u_hom² + u_stab²)` | `app.R:2329` |
| k | `2` | `app.R:2330` |
| U(x_pt) | `k * u_xpt_def` | `app.R:2331` |
| uncertainty_std (por participante) | `sd_value / sqrt(hom_res$m)` | `app.R:2465` |

### 4.5 Val_05_Scores.xlsx

**Referencia**: `R/pt_scores.R:28-183`, `app.R:2349-2361`

Cada hoja de combo contiene **4 sub-tablas** (una por método), **12 filas** por
sub-tabla (participantes).

**Puntajes** (por participante `i`):

| Puntaje | Fórmula | Línea ref. |
|---------|---------|------------|
| z_i | `(x_i - x_pt) / σ_pt` | `pt_scores.R:28` |
| z'_i | `(x_i - x_pt) / sqrt(σ_pt² + u_xpt_def²)` | `pt_scores.R:53` |
| ζ_i | `(x_i - x_pt) / sqrt(u_x_i² + u_xpt_def²)` | `pt_scores.R:79` |
| En_i | `(x_i - x_pt) / sqrt(U_x_i² + U_xpt²)` | `pt_scores.R:106` |

Donde:
- `u_x_i = uncertainty_std_i = sd_value_i / sqrt(m)`
- `U_x_i = k * u_x_i`
- `U_xpt = k * u_xpt_def`

**Evaluaciones**:

| Puntaje | Condición | Evaluación |
|---------|-----------|------------|
| z, z', ζ | `|score| <= 2` | Satisfactorio |
| z, z', ζ | `2 < |score| < 3` | Cuestionable |
| z, z', ζ | `|score| >= 3` | No satisfactorio |
| En | `|En| <= 1` | Satisfactorio |
| En | `|En| > 1` | No satisfactorio |

**La evaluación se compara como igualdad exacta de strings**.

---

## 5. Tolerancias de comparación

| Contexto | Tolerancia | Justificación |
|----------|-----------|---------------|
| Cálculos intermedios idénticos (misma fórmula) | `1e-12` | Precisión doble |
| Cadenas con redondeo acumulado | `1e-9` | Acumulación esperada |
| Evaluaciones cualitativas | `igualdad exacta` | Comparación de strings |
| Algoritmo A (iterativo, depende de `tol=1e-04`) | `1e-6` | Tolerancia generosa vs convergencia |

---

## 6. Archivos a crear

```
validation/
  poc_glm51/
    poc_glm51_val.R                    ← Script R principal (genera 5 xlsx + CSV)
    poc_glm51_val.py                   ← Script Python (genera comparación PY)
    Val_01_Robust_Stats.xlsx
    Val_02_Homogeneity.xlsx
    Val_03_Stability.xlsx
    Val_04_Uncertainties.xlsx
    Val_05_Scores.xlsx
    poc_glm51_master.csv
```

---

## 7. Estructura del script R (`poc_glm51_val.R`)

```r
# ===================================================================
# POC GLM-51: Validación Downstream Post-Algoritmo A
# Genera 5 workbooks de validación + CSV maestro
# Uso: Rscript validation/poc_glm51/poc_glm51_val.R
# ===================================================================

library(openxlsx2)
library(dplyr)
library(tidyr)

source("R/pt_robust_stats.R")
source("R/pt_homogeneity.R")
source("R/pt_scores.R")

ALGO_A_TOL <- 1e-04
ALGO_A_MAX_ITER <- 50
K_FACTOR <- 2
TOL_STRICT <- 1e-12
TOL_LOOSE <- 1e-9
TOL_ALGO <- 1e-6

# 0. Definir 15 combos
# 1. Leer datos: summary_n13, homogeneity_n13, stability_n13
# 2. Definir helpers de extracción APP
# 3. Definir helpers de cálculo independiente R
# 4. Generar estilos openxlsx2 (seguir patrón generate_algoA_validation.R)
# 5. Para cada combo: calcular las 5 secciones (APP + R indep)
# 6. Escribir cada sección a su workbook
# 7. Generar hojas RESUMEN por workbook
# 8. Generar CSV maestro
# 9. Guardar todo
```

**Helpers APP (replican lógica `app.R`)**:

```r
get_participant_values <- function(summary_data, pol, lev) {
  summary_data %>%
    filter(pollutant == pol, level == lev, participant_id != "ref") %>%
    group_by(participant_id) %>%
    summarise(result = mean(mean_value), sd_value = mean(sd_value))
}

get_hom_results <- function(hom_data, pol, lev) {
  # Replica compute_homogeneity_metrics() de app.R:292-524
  # Retorna: g, m, general_mean, x_pt, sw, ss, MADe_hom, sigma_pt,
  #          u_xpt, c_criterion, c_expanded, evaluation
}

get_stab_results <- function(stab_data, pol, lev, hom_res) {
  # Replica compute_stability_metrics() de app.R:526-754
  # Retorna: general_mean_stab, d_max, c_criterion, c_expanded,
  #          evaluation, u_stab (= d_max/sqrt(3) incondicional)
}

get_algo_a_results <- function(values) {
  # run_algorithm_a(values, max_iter=50, tol=1e-04)
  # Retorna: assigned_value, robust_sd
}

get_method_results <- function(method, participant_data, hom_res, stab_res) {
  # Para cada método (1, 2a, 2b, 3):
  # Retorna: x_pt, sigma_pt, u_xpt, u_xpt_def, U_xpt
  # Más los 4 scores y evaluaciones por participante
}
```

**Helpers R independiente (sin `source()`)**:

```r
r_indep_median <- function(x) sort(x)[(length(x)+1)/2]  # type-7 equiv
r_indep_made <- function(x) 1.483 * median(abs(x - median(x)))
r_indep_niqr <- function(x) {
  q <- quantile(x, c(0.25, 0.75), type = 7)
  0.7413 * (q[2] - q[1])
}
r_indep_homogeneity <- function(sample_data) { ... }
r_indep_stability <- function(stab_data, hom_mean, sigma_pt) { ... }
r_indep_scores <- function(x, x_pt, sigma_pt, u_xpt_def, u_x, U_xpt) { ... }
```

---

## 8. Estructura del script Python (`poc_glm51_val.py`)

```python
# ===================================================================
# POC GLM-51: Validación independiente en Python
# Uso: python3 validation/poc_glm51/poc_glm51_val.py
# ===================================================================

import csv, math, statistics
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Border, Side, Alignment

# Reimplementación 100% independiente de todas las fórmulas
# Sin dependencias de R ni del app

def median_type7(x): ...
def quantile_type7(x, p): ...
def mad_e(x): ...
def niqr_calc(x): ...
def homogeneity_stats(matrix): ...
def stability_stats(stab_matrix, hom_mean, sigma_pt): ...
def z_score(x, x_pt, sigma_pt): ...
def z_prime(x, x_pt, sigma_pt, u_xpt_def): ...
def zeta_score(x, x_pt, u_x, u_xpt_def): ...
def en_score(x, x_pt, U_x, U_xpt): ...
def eval_z(score): ...
def eval_en(score): ...

# Lee CSVs, calcula 15 combos, genera columnas PY_valor
# Escribe a los mismos workbooks (agrega columna PY_valor)
```

**Alternativa de integración**: el script Python puede generar un CSV
intermedio `poc_glm51_py_results.csv` que el script R lee para poblar la
columna `py_value`, evitando conflictos de escritura simultánea de xlsx.

---

## 9. Flujo de ejecución

```
Paso 1: Rscript poc_glm51_val.R
         ├── Lee datos CSV
         ├── Calcula APP_valor (usando funciones source() de R/)
         ├── Calcula R_valor (usando reimplementación independiente)
         ├── Lee PY_valor desde poc_glm51_py_results.csv (si existe)
         ├── Genera 5 workbooks .xlsx
         └── Genera poc_glm51_master.csv

Paso 2: python3 poc_glm51_val.py
         ├── Lee datos CSV
         ├── Calcula PY_valor (reimplementación Python pura)
         ├── Genera poc_glm51_py_results.csv
         └── (Opcional) genera reporte propio .xlsx

Paso 3: Rscript poc_glm51_val.R  (re-ejecutar para merge final)
         ├── Lee PY_valor actualizado
         ├── Recalcula diffs y status
         └── Regenera workbooks finales
```

---

## 10. Fases de implementación

### Fase 0 — Scaffolding (30 min)

- [ ] Crear directorio `validation/poc_glm51/`
- [ ] Crear `poc_glm51_val.R` con header, constants, definición de 15 combos
- [ ] Crear `poc_glm51_val.py` con header, funciones stub
- [ ] Verificar que `data/*.csv` existen y son legibles
- [ ] Verificar que `openxlsx2` y `openpyxl` están disponibles

### Fase 1 — Val_01 Robust Stats (45 min)

- [ ] Implementar `get_participant_values()` en R
- [ ] Implementar helpers R independiente (`r_indep_median`, `r_indep_made`, `r_indep_niqr`)
- [ ] Implementar generación de hoja INDICE
- [ ] Implementar generación de 15 hojas de combo
- [ ] Implementar generación de hoja RESUMEN
- [ ] Implementar funciones Python equivalentes
- [ ] Verificar: `n`, `mediana`, `MAD`, `MADe`, `Q1`, `Q3`, `IQR`, `nIQR` para CO_4

### Fase 2 — Val_02 Homogeneity (60 min)

- [ ] Implementar `get_hom_results()` replicando `app.R:292-524`
- [ ] Implementar pivoteo de datos homogeneidad
- [ ] Implementar cálculo: `g`, `m`, medias, `s²_x̄`, `sw`, `ss`, `MADe_hom`, `sigma_pt`, `u_xpt`
- [ ] Implementar criterios: `c_criterion`, `c_expanded` (tabla F1/F2)
- [ ] Implementar evaluación homogeneidad
- [ ] Agregar hoja FORMULAS con referencias ISO
- [ ] Verificar para CO_4 contra resultado conocido

### Fase 3 — Val_03 Stability (45 min)

- [ ] Implementar `get_stab_results()` replicando `app.R:526-754`
- [ ] Implementar `u_stab = d_max/sqrt(3)` incondicional (comportamiento app.R)
- [ ] Documentar discrepancia con `calculate_u_stab()` puro
- [ ] Verificar para CO_4 contra resultado conocido

### Fase 4 — Val_04 Uncertainties (60 min)

- [ ] Implementar los 4 métodos de asignación de valor
- [ ] Método 1: Referencia (`mean(ref_data)`)
- [ ] Método 2a: Consenso MADe (`median + 1.483*MAD`)
- [ ] Método 2b: Consenso nIQR (`median + calculate_niqr()`)
- [ ] Método 3: Algoritmo A (`run_algorithm_a()` con `tol=1e-04`)
- [ ] Implementar cadena de incertidumbres común
- [ ] Implementar `uncertainty_std = sd_value / sqrt(m)` por participante
- [ ] Verificar para CO_4, NO_81, O3_80

### Fase 5 — Val_05 Scores (45 min)

- [ ] Implementar cálculo de 4 puntajes por participante
- [ ] Implementar evaluaciones cualitativas
- [ ] Generar las 4 sub-tablas por método
- [ ] Verificar para CO_4 contra resultado conocido

### Fase 6 — Integración Python (60 min)

- [ ] Implementar todas las funciones Python puras
- [ ] Generar `poc_glm51_py_results.csv`
- [ ] Integrar columna `py_value` en workbooks R
- [ ] Recalcular diffs y status

### Fase 7 — Verificación final (30 min)

- [ ] Ejecutar flujo completo R → PY → R
- [ ] Verificar que `poc_glm51_master.csv` no contiene `FAIL`
- [ ] Verificar que las 5 hojas RESUMEN no tienen FAILs
- [ ] Documentar casos borde (niveles 0)
- [ ] Documentar discrepancias encontradas
- [ ] Guardar log de sesión

---

## 11. Verificación y aceptación

La implementación se considerará correcta si cumple **todo** lo siguiente:

1. Los 5 workbooks se generan sin errores.
2. Cada workbook contiene INDICE + 15 hojas combo + RESUMEN (+ FORMULAS si aplica).
3. Las 15 combinaciones se resuelven sin ambigüedad desde los 3 CSV fuente.
4. `x_pt`, `σ_pt`, `u_xpt`, `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt` coinciden
   entre APP, R y PY para todos los combos y métodos.
5. `z`, `z'`, `ζ`, `En` coinciden por participante entre las 3 fuentes.
6. Las evaluaciones cualitativas coinciden exactamente (igualdad de strings).
7. `poc_glm51_master.csv` no reporta `FAIL`.
8. Las 5 hojas RESUMEN reportan 0 FAILs.
9. Los casos borde (niveles 0) están documentados con NA esperados.

---

## 12. Archivos críticos de referencia

| Archivo | Qué consultar |
|---------|--------------|
| `app.R:127` | `ALGO_A_TOL = 1e-04` |
| `app.R:292-524` | `compute_homogeneity_metrics()` |
| `app.R:526-754` | `compute_stability_metrics()` |
| `app.R:2328-2398` | `compute_combo_scores()` — fórmulas de puntajes |
| `app.R:2431-2542` | `compute_scores_for_selection()` — flujo completo |
| `R/pt_robust_stats.R` | `calculate_mad_e()`, `calculate_niqr()`, `run_algorithm_a()` |
| `R/pt_homogeneity.R` | Homogeneidad, estabilidad, criterios, u_hom, u_stab |
| `R/pt_scores.R` | Los 4 scores + evaluaciones |
| `validation/generate_algoA_validation.R` | Patrón de estilos openxlsx |

---

## 13. Discrepancias conocidas a documentar

1. **`u_stab`**: `app.R:2494` lo calcula incondicionalmente como `d_max/sqrt(3)`;
   `calculate_u_stab()` en `R/pt_homogeneity.R:401` retorna 0 si el criterio
   se cumple. POC sigue `app.R`.

2. **Tolerancia Algoritmo A**: `app.R` usa `tol=1e-04`; `R/pt_robust_stats.R`
   default es `tol=1e-06`; `ptcalc` default es `tol=1e-03`. POC usa `1e-04`.

3. **Niveles 0**: Pueden generar `sigma_pt ≈ 0`, produciendo puntajes NA.
   Resultado esperado, no error.

4. **Dual codebase**: `R/` vs `ptcalc/R/` tienen divergencias en defaults y
   fórmulas (e.g., `calculate_homogeneity_criterion_expanded`). POC valida
   contra `R/` (lo que `app.R` efectivamente usa vía `source()`).
