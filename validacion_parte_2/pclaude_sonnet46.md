# Plan de implementación: Validación Post-Algoritmo A
# pclaude_sonnet46.md — Claude Sonnet 4.6 — 2026-03-30

**Fuente**: `plan_a2.md` + `logs/plans/260330_1118_plan_a1_validacion_post_algoA.md`
**Estado**: completado — 2026-03-30

---

## Objetivo

Validar la cadena downstream del Algoritmo A en `pt_app` mediante comparación tripartita:
`app.R` vs script R independiente vs (futuro) script Python.

Alcance: estadísticos robustos → homogeneidad → estabilidad → incertidumbres → puntajes.

---

## Archivos a crear

```
pclaude_sonnet46.md                              # este plan
validation/generate_post_algoA_validation.R     # script R principal
validation/Val_01_Robust_Stats.xlsx             # salida — 15 combos + RESUMEN
validation/Val_02_Homogeneity.xlsx              # salida — 15 combos + RESUMEN
validation/Val_03_Stability.xlsx                # salida — 15 combos + RESUMEN
validation/Val_04_Uncertainties.xlsx            # salida — 15 combos × 4 métodos
validation/Val_05_Scores.xlsx                   # salida — 15 combos × 4 métodos × 12 part.
```

No se crea el script Python en esta iteración.

---

## 15 combinaciones objetivo

| # | Contaminante | Nivel           |
|---|---|---|
| 1  | co  | 0-μmol/mol  |
| 2  | co  | 4-μmol/mol  |
| 3  | co  | 8-μmol/mol  |
| 4  | no  | 0-nmol/mol  |
| 5  | no  | 81-nmol/mol |
| 6  | no  | 121-nmol/mol |
| 7  | no2 | 0-nmol/mol  |
| 8  | no2 | 60-nmol/mol |
| 9  | no2 | 120-nmol/mol |
| 10 | o3  | 0-nmol/mol  |
| 11 | o3  | 80-nmol/mol |
| 12 | o3  | 180-nmol/mol |
| 13 | so2 | 0-nmol/mol  |
| 14 | so2 | 60-nmol/mol |
| 15 | so2 | 100-nmol/mol |

---

## Fuentes de datos

| Archivo | Columnas clave |
|---|---|
| `data/summary_n13.csv`    | `pollutant, run, level, participant_id, replicate, sample_group, mean_value, sd_value` |
| `data/homogeneity_n13.csv` | `pollutant, run, level, replicate, sample_id, value` |
| `data/stability_n13.csv`   | `pollutant, run, level, replicate, sample_id, value` |

`n_lab = 13` se agrega a `summary_n13.csv` (extraído del nombre de archivo, `app.R:163`).

---

## Funciones ptcalc utilizadas

Fuentes: `ptcalc/R/pt_robust_stats.R`, `ptcalc/R/pt_homogeneity.R`, `ptcalc/R/pt_scores.R`

| Función | Origen | Uso |
|---|---|---|
| `calculate_mad_e(x)` | pt_robust_stats | MADe = 1.483 × MAD |
| `calculate_niqr(x)` | pt_robust_stats | nIQR = 0.7413 × IQR |
| `run_algorithm_a(values, ids, max_iter, tol)` | pt_robust_stats | Algoritmo A |
| `calculate_homogeneity_stats(matrix)` | pt_homogeneity | ANOVA homogeneidad |
| `calculate_homogeneity_criterion(MADe)` | pt_homogeneity | c = 0.3 × σ_pt |
| `calculate_homogeneity_criterion_expanded(MADe, sw, g)` | pt_homogeneity | c expandido |
| `calculate_stability_stats(data, hom_mean, x_pt, sigma_pt)` | pt_homogeneity | ANOVA estabilidad |
| `evaluate_z_score_vec(z)` | pt_scores | Sat/Cuest/NoSat |
| `evaluate_en_score_vec(en)` | pt_scores | Sat/NoSat |

---

## Helpers estáticos (sin Shiny)

Tres funciones que replican la lógica de `app.R` sin reactivos:

### `get_wide_data_static(df, pollutant)`
Replica `app.R:279-290`. Filtra por pollutant, pivota wide por `replicate` → `sample_1, sample_2, ...`

### `compute_homogeneity_static(hom_data, pollutant, level)`
Replica `app.R:292-524`. Usa `get_wide_data_static` + `calculate_homogeneity_stats`.
Retorna mismas claves: `sigma_pt, u_xpt, ss, sw, x_pt, general_mean, MADe, nIQR, g, m, ...`

### `compute_stability_static(stab_data, pollutant, level, hom_res)`
Replica `app.R:526-780`. Usa `get_wide_data_static` + `calculate_stability_stats`.
Retorna: `stab_general_mean, d_max, u_stab` (= `d_max/sqrt(3)`, **siempre**, `app.R:2494`).

---

## Lógica de extracción (replica `compute_scores_for_selection`, app.R:2431-2542)

```r
# 1. Filtrar y agregar participantes (excluir "ref")
participant_data <- summary_data %>%
  filter(pollutant == pol, n_lab == 13, level == lev, participant_id != "ref") %>%
  group_by(participant_id) %>%
  summarise(result = mean(mean_value), sd_value = mean(sd_value)) %>%
  mutate(uncertainty_std = sd_value / sqrt(hom_res$m))  # app.R:2465

# 2. Valor asignado referencia
x_pt1 <- mean(ref_data$mean_value)  # app.R:2476

# 3. Incertidumbres
u_hom_val  <- hom_res$ss            # app.R:2481
d_max      <- abs(hom_res$general_mean - stab_res$stab_general_mean)
u_stab_val <- d_max / sqrt(3)       # app.R:2494 — SIEMPRE, sin condición

# 4. Métodos de consenso
median_val    <- median(values)
sigma_pt_2a   <- 1.483 * median(abs(values - median_val))  # app.R:2511
sigma_pt_2b   <- calculate_niqr(values)                    # app.R:2512
u_xpt2a       <- 1.25 * sigma_pt_2a / sqrt(n_part)
u_xpt2b       <- 1.25 * sigma_pt_2b / sqrt(n_part)

# 5. Algoritmo A (solo si n >= 12)
algo_res <- run_algorithm_a(values, ids, max_iter=50, tol=1e-04)
u_xpt3   <- 1.25 * algo_res$robust_sd / sqrt(n_part)  # app.R:2538

# 6. Puntajes (app.R:2328-2397)
u_xpt_def <- sqrt(u_xpt^2 + u_hom^2 + u_stab^2)
z      <- (x - x_pt) / sigma_pt
z_prim <- (x - x_pt) / sqrt(sigma_pt^2 + u_xpt_def^2)
zeta   <- (x - x_pt) / sqrt(u_x^2 + u_xpt_def^2)
En     <- (x - x_pt) / sqrt((k*u_x)^2 + (k*u_xpt_def)^2)   # k = 2
```

---

## Estructura de las hojas Excel

### Val_01_Robust_Stats.xlsx (hoja por combo)
Columnas: `participant_id | xi | Mediana | MAD | MADe | Q1 | Q3 | IQR | nIQR`
+ hoja `RESUMEN`: conteo PASS/FAIL (match < 1e-9 entre app y R)

### Val_02_Homogeneity.xlsx (hoja por combo)
Filas: parámetros `g, m, x_pt, general_mean, sw, ss, MADe, sigma_pt, u_sigma_pt, c_criterion, c_criterion_exp, u_xpt`
+ tabla de datos crudos items × (sample_1, sample_2)
+ hoja `RESUMEN`

### Val_03_Stability.xlsx (hoja por combo)
Filas: `stab_general_mean, hom_general_mean, d_max, c_criterion, u_stab`
+ hoja `RESUMEN`

### Val_04_Uncertainties.xlsx (hoja por combo, 4 sub-tablas)
Para cada método (REF, MADe, nIQR, ALGO_A):
`x_pt | sigma_pt | u_xpt | u_hom | u_stab | u_xpt_def | k | U_xpt`

### Val_05_Scores.xlsx (hoja por combo, 4 sub-tablas × 12 participantes)
Para cada método: `participant_id | result | z | eval_z | z' | eval_z' | zeta | eval_zeta | En | eval_En`

---

## Tolerancias de comparación

| Comparación | Tolerancia |
|---|---|
| R vs Excel (fórmula exacta) | 1e-12 |
| Cadena propagada | 1e-9 |
| Evaluaciones cualitativas | igualdad exacta |

---

## Orden de implementación

1. `pclaude_sonnet46.md` — este archivo ✓
2. `generate_post_algoA_validation.R` ✓ — 15/15 combos OK, 0 errores:
   - Sección 0: bibliotecas, fuentes, constantes
   - Sección 1: helpers estáticos
   - Sección 2: procesamiento de 15 combos → lista `results`
   - Sección 3: escribir Val_01_Robust_Stats.xlsx
   - Sección 4: escribir Val_02_Homogeneity.xlsx
   - Sección 5: escribir Val_03_Stability.xlsx
   - Sección 6: escribir Val_04_Uncertainties.xlsx
   - Sección 7: escribir Val_05_Scores.xlsx

---

## Discrepancias conocidas a documentar

| ID | Descripción |
|---|---|
| D1 | `u_stab = d_max/sqrt(3)` siempre en `app.R:2494`; `calculate_u_stab()` en `pt_homogeneity.R:401` retorna 0 si cumple criterio. La validación usa `app.R`. |
| D2 | Niveles `0-*`: `sigma_pt ≈ 0` → z/z'/zeta = NA. Caso borde esperado. |
| D3 | `u_xpt` en Método REF = `1.25 × MADe_hom / sqrt(g)` (de homogeneidad, no de participantes). |

---

## Criterios de aceptación

1. Script corre sin error con `Rscript validation/generate_post_algoA_validation.R`
2. Se generan 5 archivos `.xlsx` en `validation/`
3. Cada xlsx tiene hojas para los 15 combos + RESUMEN
4. Hoja RESUMEN de cada xlsx muestra 0 FAIL (o documenta D1/D2/D3 si aplica)
5. z, z', zeta, En por participante reproducen la lógica de `app.R` con tolerancia ≤ 1e-9
