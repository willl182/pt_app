# Documentacion de Funciones

**Fecha de generacion:** 2026-06-16 12:16:28

**Total funciones documentadas:** 77

**Funciones exportadas (`@export`):** 24

**Funciones obsoletas (`lifecycle::badge('deprecated')`):** 3

## Convenciones

- Las funciones del paquete `ptcalc` son calculos puros sin dependencias de Shiny.
- Las funciones de `app.R` son helpers reactivos y de orquestacion de la interfaz.
- Las funciones de `reports/report_template.Rmd` son helpers para la generacion de informes.
- Las funciones de `R/utils.R` estan **obsoletas**; usen sus equivalentes en `ptcalc`.
- Las referencias ISO siguen la nomenclatura `ISO 13528:2022, Seccion X.X`.

## Resumen por Categoria

| Categoria | Funciones |
|-----------|-----------:|
| Estadisticos Robustos | 6 |
| Homogeneidad y Estabilidad | 15 |
| Puntajes PT | 15 |
| Carga y Normalizacion | 8 |
| Formateo | 3 |
| Visualizacion | 3 |
| Reportes | 18 |
| Servidor Shiny | 3 |
| UI / Utilidades | 3 |
| Obsoleto | 3 |

---

## Categoria: Estadisticos Robustos

### `calculate_mad_e` `[EXPORTADA]`

Calculates 1.483 * MAD, providing a robust estimate of the standard deviation. The factor 1.483 ensures consistency with normal distribution.

**Detalles**

The MADe is a robust scale estimator highly resistant to outliers. For normally distributed data, MADe ≈ σ (population standard deviation).

**Firma:** `calculate_mad_e(x)`

**Parametros**

- x A numeric vector.

**Valor de retorno**

The scaled MAD (MADe), or NA if insufficient data.


**Ejemplo**

```r
# Calculate MADe for data with an outlier
values <- c(10.1, 10.2, 9.9, 10.0, 50.0)  # 50 is outlier
calculate_mad_e(values)  # Robust to the outlier
```

**Vease tambien**

`calculate_niqr()` for an alternative robust scale estimator.

**Archivo fuente:** `ptcalc/R/pt_robust_stats.R`

**Referencia ISO:** ISO 13528:2022, Section 9.4

---

### `calculate_niqr` `[EXPORTADA]`

Calculates 0.7413 * IQR, providing a robust estimate of the standard deviation. The factor 0.7413 ensures consistency with normal distribution.

**Detalles**

The nIQR is a robust scale estimator that is resistant to outliers. For normally distributed data, nIQR ≈ σ (population standard deviation).

**Firma:** `calculate_niqr(x)`

**Parametros**

- x A numeric vector.

**Valor de retorno**

The normalized IQR (nIQR), or NA if insufficient data.


**Ejemplo**

```r
# Calculate nIQR for proficiency testing data
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
calculate_niqr(values)
```

**Vease tambien**

`calculate_mad_e()` for an alternative robust scale estimator.

**Archivo fuente:** `ptcalc/R/pt_robust_stats.R`

**Referencia ISO:** ISO 13528:2022, Section 9.4

---

### `get_algo_a_stabilization_iter`

Extrae el numero de iteracion en la que el Algoritmo A alcanzo la convergencia, a partir del data frame de iteraciones.

**Firma:** `get_algo_a_stabilization_iter(res)`

**Parametros**

- res: lista de resultado de run_algorithm_a.

**Valor de retorno**

Entero con la iteracion de convergencia o NA.

**Notas**

Wrapper utilitario para reportes.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Annex C

---

### `run_algorithm_a` `[EXPORTADA]`

Iterative algorithm for computing robust estimates of location (x*) and scale (s*) from proficiency testing data using winsorization.

**Detalles**

Algorithm A is the iterative winsorization procedure from ISO 13528:2022, Annex C: 1. Initialize: x* = median(xi), s* = 1.483 * MAD(xi) 2. Compute delta = 1.5 * s* 3. Winsorize: x*_i = clamp(xi, x* - delta, x* + delta) 4. Update: x* = mean(x*_i), s* = 1.134 * sd(x*_i) 5. Repeat until no change in 3rd significant figure of x* and s* (ISO 13528:2022 NOTE 1). A numerical guard (tol = 1e-10) catches machine-precision stalls. The factor 1.134 corrects the bias introduced by winsorization. The sd() uses (p - 1) denominator (sample standard deviation).

**Firma:** `run_algorithm_a(values, ids = NULL, max_iter = 100, tol = 1e-10)`

**Parametros**

- values A numeric vector of participant results.
- ids Optional vector of participant identifiers (same length as values).
- max_iter Maximum number of iterations (default: 100).
- tol Numerical guard tolerance for x* and s* (default: 1e-10). The primary convergence criterion is 3rd significant figure comparison per ISO 13528:2022 NOTE 1; tol only catches machine-precision stalls.

**Valor de retorno**

A list containing:
  - assigned_value: Robust mean (x*)
  - robust_sd: Robust standard deviation (s*)
  - iterations: Data frame of iteration history (includes signif4_* columns)
  - iteration_detail: Data frame with per-participant detail per iteration
  - weights: Data frame with final winsorized values per participant
  - winsorized_values: Backward-compatible alias of weights
  - converged: Logical indicating convergence
  - convergence_method: `"signif3"` (ISO 13528:2022 NOTE 1) or
    `"numerical_guard"` (machine-precision stall) or `NA` if not converged
  - n_winsorized: Number of winsorized observations in final iteration
  - n: Number of valid observations used
  - n_participants: Backward-compatible alias of n
  - error: Error message or NULL if successful


**Ejemplo**

```r
# Robust mean/sd with outlier in data
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 50.0)  # 50 is outlier
result <- run_algorithm_a(values)
cat("Robust mean:", result$assigned_value, "\n")
cat("Robust SD:", result$robust_sd, "\n")
```

**Vease tambien**

`calculate_niqr()`, `calculate_mad_e()`

**Archivo fuente:** `ptcalc/R/pt_robust_stats.R`

**Referencia ISO:** ISO 13528:2022, Annex C

---

### `run_algorithm_a_report`

Wrapper del Algoritmo A para el reporte Rmd. Llama a run_algorithm_a de ptcalc con tolerancia 1e-03 y devuelve una lista simplificada (mean, sd, error).

**Firma:** `run_algorithm_a_report(values, max_iter = 50)`

**Parametros**

- values: vector numerico; max_iter: iteraciones maximas.

**Valor de retorno**

Lista con mean (valor asignado robusto), sd (desviacion robusta) y error.

**Ejemplo**

```r
run_algorithm_a_report(c(10, 10.1, 9.9, 50))
```

**Notas**

Asegura consistencia de tolerancia con app.R.

**Archivo fuente:** `reports/report_template.Rmd`

**Referencia ISO:** ISO 13528:2022, Annex C

---

### `stable_sigfig_value`

Redondea un valor al numero de cifras significativas estables usado por el Algoritmo A para verificar convergencia.

**Firma:** `stable_sigfig_value(x, digits = algo_a_significant_figures)`

**Parametros**

- x: valor numerico; digits: numero de cifras significativas (default 3).

**Valor de retorno**

Valor redondeado.

**Notas**

Funcion interna de run_algorithm_a; no se exporta.

**Archivo fuente:** `ptcalc/R/pt_robust_stats.R`

**Referencia ISO:** ISO 13528:2022, Annex C

---

## Categoria: Homogeneidad y Estabilidad

### `build_homogeneity_export_df`

Construye un data frame limpio con los resultados de homogeneidad para descarga.

**Parametros**

- Ninguno (usa reactives internos).

**Valor de retorno**

Data frame exportable.

**Notas**

Vinculado al boton de descarga de resultados de homogeneidad.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 9.2

---

### `build_stability_export_df`

Construye un data frame limpio con los resultados de estabilidad para descarga.

**Parametros**

- Ninguno (usa reactives internos).

**Valor de retorno**

Data frame exportable.

**Notas**

Vinculado al boton de descarga de resultados de estabilidad.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 9.3

---

### `calculate_homogeneity_criterion` `[EXPORTADA]`

c = 0.3 * sigma_pt

**Firma:** `calculate_homogeneity_criterion(sigma_pt)`

**Parametros**

- sigma_pt Standard deviation for proficiency assessment.

**Valor de retorno**

The homogeneity criterion value.


**Ejemplo**

```r
# Criterion for sigma_pt = 0.5
c <- calculate_homogeneity_criterion(sigma_pt = 0.5)
cat("Homogeneity criterion:", c)  # 0.15
```

**Vease tambien**

`evaluate_homogeneity()`

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

**Referencia ISO:** ISO 13528:2022, Section 9.2.3

---

### `calculate_homogeneity_criterion_expanded` `[EXPORTADA]`

c_expanded = c_criterion * sqrt(1 + (u_sigma_pt/sigma_pt)^2)

**Firma:** `calculate_homogeneity_criterion_expanded(sigma_pt, u_sigma_pt = NULL, sw = NULL, g = NULL)`

**Parametros**

- sigma_pt Standard deviation for proficiency assessment (from MADe)
- u_sigma_pt Uncertainty of sigma_pt

**Valor de retorno**

The expanded criterion value

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

**Referencia ISO:** ISO 13528:2022, Section 9.2.4

---

### `calculate_homogeneity_stats` `[EXPORTADA]`

Computes between-sample standard deviation (ss), within-sample standard deviation (sw), and related ANOVA components for homogeneity assessment. Also calculates robust sigma estimate (MADe) and its uncertainty.

**Firma:** `calculate_homogeneity_stats(sample_data)`

**Parametros**

- sample_data Data frame or matrix with samples as rows and replicates as columns.

**Valor de retorno**

A list containing:
  - g: Number of samples (groups)
  - m: Number of replicates per sample
  - general_mean_homog: Overall mean of ALL values
  - sample_means: Vector of sample means
  - x_pt: Median of first replicate values
  - s_x_bar_sq: Variance of sample means
  - s_xt: Standard deviation of sample means
  - sw: Within-sample standard deviation
  - sw_sq: Within-sample variance
  - ss_sq: Between-sample variance component
  - ss: Between-sample standard deviation
  - median_of_diffs: Median of absolute differences between sample means
  - MADe: Robust sigma estimate (1.483 * median_of_diffs)
  - sigma_pt: Standard deviation for proficiency assessment (equals MADe)
  - u_sigma_pt: Uncertainty of sigma_pt (1.23 * MADe / sqrt(g))
  - error: Error message or NULL if successful


**Ejemplo**

```r
# Create sample data: 10 items with 2 replicates each
sample_data <- matrix(rnorm(20, mean = 10, sd = 0.5), nrow = 10, ncol = 2)
stats <- calculate_homogeneity_stats(sample_data)
cat("Between-sample SD (ss):", stats$ss, "\n")
cat("Sigma PT (MADe):", stats$sigma_pt, "\n")
```

**Vease tambien**

`calculate_homogeneity_criterion()`, `evaluate_homogeneity()`

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

**Referencia ISO:** ISO 13528:2022, Section 9.2

---

### `calculate_stability_criterion` `[EXPORTADA]`

c_stab = 0.3 * sigma_pt (same as homogeneity criterion)

**Firma:** `calculate_stability_criterion(sigma_pt)`

**Parametros**

- sigma_pt Standard deviation for proficiency assessment

**Valor de retorno**

The stability criterion value

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

**Referencia ISO:** ISO 13528:2022, Section 9.3.3

---

### `calculate_stability_criterion_expanded` `[EXPORTADA]`

c_stab_expanded = c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)

**Firma:** `calculate_stability_criterion_expanded(c_criterion, u_hom_mean, u_stab_mean)`

**Parametros**

- c_criterion Base stability criterion
- u_hom_mean Uncertainty of homogeneity mean
- u_stab_mean Uncertainty of stability mean

**Valor de retorno**

The expanded stability criterion

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

---

### `calculate_stability_stats` `[EXPORTADA]`

Calculates statistics from stability data using same pattern as homogeneity assessment. Independent of homogeneity calculations. Compares stability mean to homogeneity mean to assess short-term stability of proficiency test items.

**Firma:** `calculate_stability_stats(stab_sample_data, hom_general_mean_homog, hom_stab_x_pt, hom_stab_sigma_pt)`

**Parametros**

- stab_sample_data Data frame or matrix with stability samples
- hom_general_mean_homog General mean from homogeneity study
- hom_stab_x_pt Median of 1st replicate values from HOMOGENEITY study (assigned value x_pt), used as REFERENCE for median_of_diffs calculation
- hom_stab_sigma_pt Standard deviation for proficiency assessment from HOMOGENEITY study (robust sigma estimate MADe)

**Valor de retorno**

A list containing:
  - g: Number of stability samples (groups)
  - m: Number of replicates per stability sample
  - general_mean: Overall mean of ALL stability values
  - sample_means: Vector of stability sample means
  - x_pt: Median of first replicate values (calculated internally, same formula as homogeneity)
  - s_x_bar_sq: Variance of stability sample means
  - s_xt: Standard deviation of stability sample means
  - sw: Within-sample standard deviation (stability)
  - sw_sq: Within-sample variance (stability)
  - ss_sq: Between-sample variance component (stability)
  - ss: Between-sample standard deviation (stability)
  - hom_stab_median_of_diffs: Median of absolute differences between 2nd replicate values (stability) and HOMOGENEITY's x_pt
  - hom_stab_sigma_pt: Standard deviation from HOMOGENEITY study (passed through, not calculated internally)
  - diff_hom_stab: Absolute difference |stability_mean - homogeneity_mean|
  - error: Error message or NULL if successful

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

**Referencia ISO:** ISO 13528:2022, Section 9.3

---

### `calculate_u_hom` `[EXPORTADA]`

u_hom = ss (between-sample standard deviation)

**Firma:** `calculate_u_hom(ss)`

**Parametros**

- ss Between-sample standard deviation from homogeneity study

**Valor de retorno**

Uncertainty contribution from homogeneity

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

**Referencia ISO:** ISO 13528:2022, Section 9.5

---

### `calculate_u_stab` `[EXPORTADA]`

u_stab = diff_hom_stab / sqrt(3) (if criterion not met) or 0 (if criterion is met)

**Firma:** `calculate_u_stab(diff_hom_stab, c_criterion)`

**Parametros**

- diff_hom_stab Absolute difference between stability and homogeneity means
- c_criterion Stability criterion

**Valor de retorno**

Uncertainty contribution from stability

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

**Referencia ISO:** ISO 13528:2022, Section 9.5

---

### `compute_homogeneity`

Wrapper del calculo de homogeneidad para el reporte Rmd. Pasa datos en formato largo a ancho y llama a calculate_homogeneity_stats de ptcalc.

**Firma:** `compute_homogeneity(data_full, pol, lev)`

**Parametros**

- data_full: datos largos; pol: analito; lev: nivel.

**Valor de retorno**

Lista de estadisticos de homogeneidad o NULL si no hay datos/error.

**Notas**

Usado en secciones de homogeneidad del informe.

**Archivo fuente:** `reports/report_template.Rmd`

**Referencia ISO:** ISO 13528:2022, Section 9.2

---

### `compute_homogeneity_metrics`

Calcula metricas completas de homogeneidad para un analito y nivel: estadisticos descriptivos, ANOVA, sigma_pt (MADe y nIQR), criterios ISO y conclusiones.

**Firma:** `compute_homogeneity_metrics(target_pollutant, target_level)`

**Parametros**

- target_pollutant: analito; target_level: nivel.

**Valor de retorno**

Lista extensa con tablas, valores, criterios, conclusiones y clase CSS para la UI.

**Notas**

Depende de hom_data_full() y funciones de ptcalc. Devuelve la informacion necesaria para llenar la pestana de homogeneidad y para los calculos de puntajes.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 9.2

---

### `compute_stability_metrics`

Calcula metricas de estabilidad comparando datos de estabilidad con los resultados de homogeneidad para un analito y nivel.

**Firma:** `compute_stability_metrics(target_pollutant, target_level, hom_results)`

**Parametros**

- target_pollutant: analito; target_level: nivel; hom_results: resultado de compute_homogeneity_metrics().

**Valor de retorno**

Lista con estadisticos de estabilidad, criterios, conclusiones y contribucion u_stab.

**Notas**

Depende de stab_data_full() y hom_results.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 9.3

---

### `evaluate_homogeneity` `[EXPORTADA]`

Evaluate homogeneity against criterion

**Firma:** `evaluate_homogeneity(ss, c_criterion, c_expanded = NULL)`

**Parametros**

- ss Between-sample standard deviation
- c_criterion Homogeneity criterion
- c_expanded Expanded homogeneity criterion (optional)

**Valor de retorno**

A list with:
  - passes_criterion: Logical, TRUE if ss <= c_criterion
  - passes_expanded: Logical, TRUE if ss <= c_expanded (or NA if c_expanded not provided)
  - conclusion: Text description of result

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

---

### `evaluate_stability` `[EXPORTADA]`

Evaluate stability against criterion

**Firma:** `evaluate_stability(diff_hom_stab, c_criterion, c_expanded = NULL)`

**Parametros**

- diff_hom_stab Absolute difference between stability and homogeneity means
- c_criterion Stability criterion
- c_expanded Expanded stability criterion (optional)

**Valor de retorno**

A list with:
  - passes_criterion: Logical, TRUE if diff <= c_criterion
  - passes_expanded: Logical, TRUE if diff <= c_expanded (or NA if not provided)
  - conclusion: Text description of result

**Archivo fuente:** `ptcalc/R/pt_homogeneity.R`

---

## Categoria: Puntajes PT

### `calculate_en_score` `[EXPORTADA]`

En = (x - x_pt) / sqrt(U_x^2 + U_xpt^2)

**Firma:** `calculate_en_score(x, x_pt, U_x, U_xpt)`

**Parametros**

- x Participant result.
- x_pt Assigned value.
- U_x Expanded uncertainty of participant's result.
- U_xpt Expanded uncertainty of the assigned value.

**Valor de retorno**

En-score value.


**Ejemplo**

```r
# En-score uses expanded uncertainties (k=2)
en <- calculate_en_score(x = 10.5, x_pt = 10.0, U_x = 0.4, U_xpt = 0.2)
cat("En-score:", en, "Eval:", evaluate_en_score(en))
```

**Vease tambien**

`evaluate_en_score()`

**Archivo fuente:** `ptcalc/R/pt_scores.R`

**Referencia ISO:** ISO 13528:2022, Section 10.5

---

### `calculate_expert_sigma_pt`

Calcula sigma_pt a partir de parametros expertos (modelo lineal a*x_pt + b) por analito, segun tabla interna de CALAIRE.

**Firma:** `calculate_expert_sigma_pt(pollutant, x_pt)`

**Parametros**

- pollutant: codigo del analito; x_pt: valor asignado.

**Valor de retorno**

Valor numerico de sigma_pt o NA.

**Notas**

Metodo 'Expertos' (codigo 4) en build_xpt_summary_row().

**Archivo fuente:** `app.R`

---

### `calculate_expert_u_xpt`

Calcula la incertidumbre estandar del valor asignado como 0.3% del valor asignado (0.003 * x_pt).

**Firma:** `calculate_expert_u_xpt(x_pt)`

**Parametros**

- x_pt: valor asignado.

**Valor de retorno**

Incertidumbre estandar u_xpt.

**Notas**

Usado por el metodo 'Expertos'.

**Archivo fuente:** `app.R`

---

### `calculate_z_prime_score` `[EXPORTADA]`

z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt^2)

**Firma:** `calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)`

**Parametros**

- x Participant result.
- x_pt Assigned value.
- sigma_pt Standard deviation for proficiency assessment.
- u_xpt Standard uncertainty of the assigned value.

**Valor de retorno**

z'-score value.


**Ejemplo**

```r
# z'-score accounts for uncertainty in assigned value
zprime <- calculate_z_prime_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5, u_xpt = 0.1)
```

**Vease tambien**

`calculate_z_score()`, `calculate_zeta_score()`

**Archivo fuente:** `ptcalc/R/pt_scores.R`

**Referencia ISO:** ISO 13528:2022, Section 10.3

---

### `calculate_z_score` `[EXPORTADA]`

z = (x - x_pt) / sigma_pt

**Firma:** `calculate_z_score(x, x_pt, sigma_pt)`

**Parametros**

- x Participant result.
- x_pt Assigned value.
- sigma_pt Standard deviation for proficiency assessment.

**Valor de retorno**

z-score value.


**Ejemplo**

```r
# Calculate z-score for a participant
z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
cat("z-score:", z)  # 1.0 (Satisfactorio)
```

**Vease tambien**

`calculate_z_prime_score()`, `evaluate_z_score()`

**Archivo fuente:** `ptcalc/R/pt_scores.R`

**Referencia ISO:** ISO 13528:2022, Section 10.2

---

### `calculate_zeta_score` `[EXPORTADA]`

zeta = (x - x_pt) / sqrt(u_x^2 + u_xpt^2)

**Firma:** `calculate_zeta_score(x, x_pt, u_x, u_xpt)`

**Parametros**

- x Participant result.
- x_pt Assigned value.
- u_x Standard uncertainty of participant's result.
- u_xpt Standard uncertainty of the assigned value.

**Valor de retorno**

zeta-score value.


**Ejemplo**

```r
# zeta-score uses participant's uncertainty
zeta <- calculate_zeta_score(x = 10.5, x_pt = 10.0, u_x = 0.2, u_xpt = 0.1)
```

**Vease tambien**

`calculate_en_score()`

**Archivo fuente:** `ptcalc/R/pt_scores.R`

**Referencia ISO:** ISO 13528:2022, Section 10.4

---

### `compute_combo_scores`

Calcula los cuatro puntajes (z, z', zeta, En) para un grupo de participantes y una combinacion analito/nivel/n_lab, usando u_xpt definida que incluye u_hom y u_stab.

**Firma:** `compute_combo_scores(participants_df, x_pt, sigma_pt, u_xpt, combo_meta, k = 2, u_hom = 0, u_stab = 0)`

**Parametros**

- participants_df: data frame de participantes; x_pt, sigma_pt, u_xpt: parametros de referencia; combo_meta: lista con title y label; k: factor de cobertura; u_hom, u_stab: incertidumbres adicionales.

**Valor de retorno**

Lista con data frame ampliado (incluyendo columnas *_score y *_eval) o mensaje de error.

**Notas**

Funcion nuclear del calculo de puntajes en app.R.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 10

---

### `compute_scores_for_selection`

Orquesta el flujo completo de puntajes para una seleccion de analito, n_lab y nivel: obtiene parametros de homogeneidad, carga datos de participantes, deriva incertidumbres y calcula puntajes.

**Firma:** `compute_scores_for_selection(target_pollutant, target_n_lab, target_level, summary_data, max_iter = 50, k_factor = 2)`

**Parametros**

- target_pollutant, target_n_lab, target_level: seleccion; summary_data: datos consolidados; max_iter, k_factor: parametros.

**Valor de retorno**

Lista con resultados de puntajes, resumenes, graficos y errores si los hay.

**Notas**

Punto de entrada principal para la pestana de puntajes.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 10

---

### `compute_scores_metrics`

Calcula puntajes z, z', zeta y En para un conjunto de participantes dados x_pt, sigma_pt y u_xpt, incluyendo contribuciones de homogeneidad y estabilidad.

**Firma:** `compute_scores_metrics(summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k, m = NULL, u_hom = 0, u_stab = 0)`

**Parametros**

- summary_df: datos resumidos; target_pollutant, target_n_lab, target_level: seleccion; sigma_pt, u_xpt, k: parametros; m: replicados; u_hom, u_stab: contribuciones adicionales.

**Valor de retorno**

Lista con data frame de puntajes, resumenes y metadata de la combinacion.

**Notas**

Version vectorizada/orquestadora usada por los reportes globales.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 10

---

### `ensure_classification_columns`

Garantiza que un data frame contenga las columnas de clasificacion usadas por los reportes; las crea con NA si no existen.

**Firma:** `ensure_classification_columns(df)`

**Parametros**

- df: data frame.

**Valor de retorno**

Data frame con columnas classification_z_en, classification_z_en_code, classification_zprime_en, classification_zprime_en_code.

**Notas**

Defensa contra data frames antiguos o incompletos.

**Archivo fuente:** `app.R`

---

### `evaluate_en_score` `[EXPORTADA]`

Classifies En-score performance: - |En| <= 1: Satisfactorio (Satisfactory) - |En| > 1: No satisfactorio (Unsatisfactory)

**Firma:** `evaluate_en_score(en)`

**Parametros**

- en En-score value

**Valor de retorno**

Character string with evaluation category

**Archivo fuente:** `ptcalc/R/pt_scores.R`

---

### `evaluate_en_score_vec` `[EXPORTADA]`

Vectorized En-score evaluation

**Firma:** `evaluate_en_score_vec(en)`

**Parametros**

- en Vector of En-score values

**Valor de retorno**

Character vector with evaluation categories

**Archivo fuente:** `ptcalc/R/pt_scores.R`

---

### `evaluate_u_xpt_sigma_criterion`

Evalua si la incertidumbre del valor asignado cumple el criterio ISO u(x_pt) <= 0.3 * sigma_pt.

**Firma:** `evaluate_u_xpt_sigma_criterion(u_xpt_def, sigma_pt)`

**Parametros**

- u_xpt_def: incertidumbre definida; sigma_pt: desviacion estandar de evaluacion.

**Valor de retorno**

Cadena con la conclusion ('Cumple' / 'No cumple' / 'No evaluable').

**Notas**

Determina si se debe usar z' o zeta/En en lugar de z.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Section 10

---

### `evaluate_z_score` `[EXPORTADA]`

Classifies score performance based on ISO 13528 criteria: - |z| <= 2: Satisfactorio (Satisfactory) - 2 < |z| < 3: Cuestionable (Questionable) - |z| >= 3: No satisfactorio (Unsatisfactory)

**Firma:** `evaluate_z_score(z)`

**Parametros**

- z Score value (z, z', or zeta)

**Valor de retorno**

Character string with evaluation category

**Archivo fuente:** `ptcalc/R/pt_scores.R`

---

### `evaluate_z_score_vec` `[EXPORTADA]`

Vectorized z-score evaluation

**Firma:** `evaluate_z_score_vec(z)`

**Parametros**

- z Vector of score values

**Valor de retorno**

Character vector with evaluation categories

**Archivo fuente:** `ptcalc/R/pt_scores.R`

---

## Categoria: Carga y Normalizacion

### `get_calaire_reference_for_combo`

Filtra el data frame de referencia CALAIRE para devolver la fila correspondiente a un analito y nivel.

**Firma:** `get_calaire_reference_for_combo(target_pollutant, target_level)`

**Parametros**

- target_pollutant: codigo del analito; target_level: nivel.

**Valor de retorno**

Data frame filtrado o NULL si no hay referencia.

**Notas**

Depende del reactive calaire_reference_df().

**Archivo fuente:** `app.R`

---

### `get_wide_data`

Transforma datos en formato largo a formato ancho (una fila por item, columnas sample_1, sample_2, ...) filtrando por analito.

**Firma:** `get_wide_data(df, target_pollutant)`

**Parametros**

- df: data frame largo; target_pollutant: analito a filtrar.

**Valor de retorno**

Data frame ancho o NULL si no hay datos.

**Notas**

Usada tanto en app.R como en report_template.Rmd.

**Archivo fuente:** `app.R`

---

### `infer_n_lab`

Infere la columna n_lab (numero de laboratorio) de un data frame. Primero busca una columna existente, luego un patron en el nombre de archivo y finalmente cuenta participantes distintos por combinacion.

**Firma:** `infer_n_lab(df, filename = NULL)`

**Parametros**

- df: data frame; filename: nombre de archivo opcional para extraer n_lab.

**Valor de retorno**

Data frame con columna n_lab anadida o preservada.

**Ejemplo**

```r
infer_n_lab(df, "ronda_n12_o3.csv")
```

**Notas**

Permite compatibilidad con archivos que no incluyen n_lab explicitamente.

**Archivo fuente:** `app.R`

---

### `normalize_n`

Normaliza valores de n (numero de laboratorio / ronda) a entero, limpiando prefijos como 'N' o 'n'.

**Firma:** `normalize_n(df)`

**Parametros**

- df: data frame con columna n_lab.

**Valor de retorno**

Data frame con n_lab como entero.

**Notas**

Funcion interna del preprocesamiento.

**Archivo fuente:** `app.R`

---

### `normalize_participant_uncertainty`

Normaliza la incertidumbre reportada por participantes. Detecta alias de incertidumbre expandida (u_exp, U(xi), etc.) y factor de cobertura k, y deriva u_value cuando no esta presente. Advierte si hay inconsistencia entre u_value y u_exp/k.

**Firma:** `normalize_participant_uncertainty(df)`

**Parametros**

- df: data frame con columnas de incertidumbre.

**Valor de retorno**

Data frame con columnas u_exp, k_factor y u_value normalizadas.

**Notas**

Escala entre incertidumbre estandar y expandida para calculos zeta/En.

**Archivo fuente:** `app.R`

---

### `normalize_pollutant_code`

Normaliza codigos de analito a mayusculas, reemplaza subindices unicode por digitos y elimina caracteres no alfanumericos.

**Firma:** `normalize_pollutant_code(pollutant)`

**Parametros**

- pollutant: vector de codigos.

**Valor de retorno**

Vector de codigos normalizados.

**Ejemplo**

```r
normalize_pollutant_code("NO₂") # devuelve "NO2"
```

**Notas**

Permite comparar contaminantes aunque vengan con diferentes formatos.

**Archivo fuente:** `app.R`

---

### `normalize_u_df`

Normaliza un data frame de incertidumbres proveniente de un archivo consolidado: asegura columnas estandar, convierte formatos y emite notificaciones si detecta inconsistencias.

**Firma:** `normalize_u_df(df, source_label, notify = TRUE)`

**Parametros**

- df: data frame; source_label: etiqueta descriptiva; notify: mostrar notificaciones.

**Valor de retorno**

Data frame normalizado.

**Notas**

Usada en la carga de archivos de incertidumbre.

**Archivo fuente:** `app.R`

---

### `read_hom_stab_csv`

Lee un CSV de homogeneidad o estabilidad con vroom y valida que contenga las columnas 'value', 'pollutant' y 'level'.

**Firma:** `read_hom_stab_csv(path, label)`

**Parametros**

- path: ruta al archivo; label: etiqueta ('homogeneidad' o 'estabilidad') para mensajes de error.

**Valor de retorno**

Data frame leido o mensaje de validacion Shiny si falla.

**Ejemplo**

```r
read_hom_stab_csv("homogeneity.csv", "homogeneidad")
```

**Notas**

Punto de entrada para los reactivos hom_data_full() y stab_data_full().

**Archivo fuente:** `app.R`

---

## Categoria: Formateo

### `format_convergence_method`

Traduce el metodo de convergencia del Algoritmo A a una etiqueta legible en espanol.

**Firma:** `format_convergence_method(method)`

**Parametros**

- method: cadena ('signif3', 'numerical_guard', NA).

**Valor de retorno**

Cadena descriptiva.

**Ejemplo**

```r
format_convergence_method("signif3")
```

**Notas**

Usado en tablas de resultados del Algoritmo A.

**Archivo fuente:** `app.R`

---

### `format_num`

Formatea un numero a n_digits decimales, manejando valores no finitos como cadena vacia.

**Firma:** `format_num(x, n_digits = 4)`

**Parametros**

- x: valor numerico; n_digits: numero de decimales (default 4).

**Valor de retorno**

Cadena de texto formateada.

**Ejemplo**

```r
format_num(pi, 3) # "3.142"
```

**Archivo fuente:** `app.R`

---

### `format_numeric_columns`

Aplica format_num a un conjunto de columnas numericas de un data frame.

**Firma:** `format_numeric_columns(df, columns = NULL)`

**Parametros**

- df: data frame; columns: nombres de columnas (default: todas las numericas).

**Valor de retorno**

Data frame con columnas formateadas como texto.

**Archivo fuente:** `app.R`

---

## Categoria: Visualizacion

### `create_combo_plot`

Crea un grafico combinado (valores del participante vs referencia + evolucion del puntaje) por nivel, usando patchwork.

**Firma:** `create_combo_plot(df, score_col, title_suffix, limit_lines = c(2, 3), limit_colors = c("orange", "red"), show_legend = TRUE)`

**Parametros**

- df: data frame; score_col: columna de puntaje; title_suffix: sufijo del titulo; limit_lines, limit_colors, show_legend: opciones graficas.

**Valor de retorno**

Objeto ggplot combinado.

**Notas**

Usado en el anexo C del reporte por participante.

**Archivo fuente:** `app.R`

---

### `plot_scores`

Genera un grafico ggplot de puntajes por participante con lineas de advertencia y accion opcionales.

**Firma:** `plot_scores(df, score_col, title, subtitle, ylab, warn_limits = NULL, action_limits = NULL)`

**Parametros**

- df: data frame; score_col: columna de puntaje; title, subtitle, ylab: etiquetas; warn_limits, action_limits: vectores de limites.

**Valor de retorno**

Objeto ggplot.

**Notas**

Usado en la pestana de puntajes y en reportes.

**Archivo fuente:** `app.R`

---

### `render_global_score_heatmap`

Renderiza un heatmap interactivo de puntajes por participante y nivel usando plotly.

**Firma:** `render_global_score_heatmap(output_id, combo_key, score_col, eval_col, palette, title_prefix)`

**Parametros**

- output_id: id del output Shiny; combo_key, score_col, eval_col: columnas a visualizar; palette: paleta de colores; title_prefix: prefijo del titulo.

**Valor de retorno**

Efecto secundario: asigna output[[output_id]].

**Notas**

Usado en la seccion de reportes globales.

**Archivo fuente:** `app.R`

---

## Categoria: Reportes

### `build_xpt_summary_row`

Construye una fila del resumen de valor asignado para una combinacion analito/n_lab/nivel y un metodo dado. Los metodos son: 1=Referencia, 2a=Consenso MADe, 2b=Consenso nIQR, 3=Algoritmo A, 4=Expertos.

**Firma:** `build_xpt_summary_row(pol, n, lev, subset_data, method_code)`

**Parametros**

- pol, n, lev: identificadores; subset_data: datos filtrados; method_code: codigo de metodo.

**Valor de retorno**

Data frame de una fila con Contaminante, Nivel, Metodo, x_pt, u_xpt, sigma_pt, etc.

**Notas**

Funcion central para el modulo de valor asignado.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Sections 8-9

---

### `calculate_method_scores_df`

Calcula el resumen de valor asignado aplicando build_xpt_summary_row() a todas las combinaciones de un data frame para un metodo dado (y el metodo experto como comparacion si aplica).

**Firma:** `calculate_method_scores_df(method_code)`

**Parametros**

- method_code: codigo de metodo.

**Valor de retorno**

Data frame con resultados por combinacion.

**Notas**

Reactive que alimenta la tabla de valor asignado.

**Archivo fuente:** `app.R`

**Referencia ISO:** ISO 13528:2022, Sections 8-9

---

### `combine_scores_result`

Combina multiples resultados de puntajes (lista) en un unico data frame, anadiendo metadatos de combinacion.

**Firma:** `combine_scores_result(res)`

**Parametros**

- res: lista de resultados de compute_scores_metrics() o similares.

**Valor de retorno**

Data frame combinado o mensaje de error.

**Notas**

Usado en reportes globales que agregan varias combinaciones.

**Archivo fuente:** `app.R`

---

### `count_eval`

Cuenta el numero de ocurrencias de una categoria de evaluacion en una columna.

**Firma:** `count_eval(eval_col, eval_type)`

**Parametros**

- eval_col: vector de categorias; eval_type: categoria a contar.

**Valor de retorno**

Entero con el conteo.

**Notas**

Helper de summarize_scores().

**Archivo fuente:** `app.R`

---

### `empty_algo_df`

Devuelve un data frame vacio con la estructura esperada para resultados del Algoritmo A (usado como plantilla).

**Parametros**

- Ninguno.

**Valor de retorno**

Data frame vacio.

**Notas**

Defensa contra resultados nulos en reportes.

**Archivo fuente:** `app.R`

---

### `empty_consensus_df`

Devuelve un data frame vacio con la estructura esperada para resumenes de consenso (usado como plantilla).

**Parametros**

- Ninguno.

**Valor de retorno**

Data frame vacio.

**Notas**

Defensa contra resultados nulos en reportes.

**Archivo fuente:** `app.R`

---

### `get_combo_levels_order`

Devuelve los niveles de un conjunto de combinaciones ordenados numericamente.

**Firma:** `get_combo_levels_order(combos_filtered)`

**Parametros**

- combos_filtered: data frame con columna level.

**Valor de retorno**

Vector de niveles ordenados.

**Notas**

Usado para ordenar ejes y tablas de reportes.

**Archivo fuente:** `app.R`

---

### `get_global_overview_data`

Filtra la tabla global_report_overview() para la combinacion seleccionada en la UI.

**Firma:** `get_global_overview_data(spec)`

**Parametros**

- spec: lista con title de la combinacion.

**Valor de retorno**

Tibble filtrado.

**Notas**

Helper para reportes globales.

**Archivo fuente:** `app.R`

---

### `get_global_summary_row`

Filtra la tabla global_report_summary() para la combinacion y etiqueta seleccionadas en la UI.

**Firma:** `get_global_summary_row(spec)`

**Parametros**

- spec: lista con label de la combinacion.

**Valor de retorno**

Tibble filtrado.

**Notas**

Helper para reportes globales.

**Archivo fuente:** `app.R`

---

### `get_scores_result`

Obtiene el resultado de puntajes almacenado en reactiveValues para una combinacion analito/n_lab/nivel.

**Firma:** `get_scores_result(pollutant, n_lab, level)`

**Parametros**

- pollutant, n_lab, level: identificadores de la combinacion.

**Valor de retorno**

Lista con resultados o NULL.

**Notas**

Usado para evitar recalcular puntajes en multiples outputs.

**Archivo fuente:** `app.R`

---

### `is_nonempty_df`

Verifica si un objeto es un data frame no vacio.

**Firma:** `is_nonempty_df(x)`

**Parametros**

- x: objeto.

**Valor de retorno**

Logical TRUE/FALSE.

**Ejemplo**

```r
is_nonempty_df(data.frame(a = 1))
```

**Notas**

Helper del reporte Rmd.

**Archivo fuente:** `reports/report_template.Rmd`

---

### `participant_count`

Cuenta el numero de participantes unicos (excluyendo 'ref' y NA) en un data frame.

**Firma:** `participant_count(df)`

**Parametros**

- df: data frame con columna participant_id.

**Valor de retorno**

Entero.

**Notas**

Usado para mostrar el numero de participantes en el reporte.

**Archivo fuente:** `reports/report_template.Rmd`

---

### `round_summary_data`

Filtra params$summary_data por n_lab si esta definido (alias de selected_summary_data sin filtro de level).

**Parametros**

- Ninguno (usa params del Rmd).

**Valor de retorno**

Data frame filtrado.

**Notas**

Helper del reporte Rmd.

**Archivo fuente:** `reports/report_template.Rmd`

---

### `safe_param_df`

Devuelve un data frame pasado por params o un data frame vacio si no es valido.

**Firma:** `safe_param_df(x)`

**Parametros**

- x: objeto (params$...).

**Valor de retorno**

Data frame.

**Notas**

Defensa contra parametros nulos en Rmd.

**Archivo fuente:** `reports/report_template.Rmd`

---

### `safe_rename_by_position`

Renombra las primeras columnas de un data frame segun un vector de etiquetas, si el data frame no esta vacio.

**Firma:** `safe_rename_by_position(df, labels)`

**Parametros**

- df: data frame; labels: vector de nombres.

**Valor de retorno**

Data frame renombrado.

**Notas**

Usado para formatear tablas de reportes.

**Archivo fuente:** `reports/report_template.Rmd`

---

### `scalar_or_default`

Devuelve el valor de una columna si es escalar unico, o un valor por defecto.

**Firma:** `scalar_or_default(x, default)`

**Parametros**

- x: valor; default: valor por defecto.

**Valor de retorno**

Valor escalar o default.

**Notas**

Usado en la generacion de reportes parametrizados.

**Archivo fuente:** `app.R`

---

### `selected_summary_data`

Filtra params$summary_data por n_lab y level si estan definidos.

**Parametros**

- Ninguno (usa params del Rmd).

**Valor de retorno**

Data frame filtrado.

**Notas**

Helper del reporte Rmd.

**Archivo fuente:** `reports/report_template.Rmd`

---

### `summarize_scores`

Resume un data frame de puntajes calculando totales y porcentajes de cada categoria de evaluacion.

**Firma:** `summarize_scores(df)`

**Parametros**

- df: data frame con columnas de evaluacion.

**Valor de retorno**

Data frame resumen.

**Notas**

Usado en reportes y tablas de resumen.

**Archivo fuente:** `app.R`

---

## Categoria: Servidor Shiny

### `run_workflow_script`

Ejecuta un script R externo a traves de Rscript en un proceso separado, capturando salida estandar y error.

**Firma:** `run_workflow_script(script, args = character())`

**Parametros**

- script: ruta al script; args: vector de argumentos de linea de comandos.

**Valor de retorno**

Lista con status (codigo de salida) y output (texto concatenado).

**Ejemplo**

```r
run_workflow_script("scripts/aplicativo/preprocesar_calaire.R", c("--input", "datos.csv"))
```

**Notas**

Se usa para lanzar pipelines de preprocesamiento desde la UI.

**Archivo fuente:** `app.R`

---

### `save_preprocessor_raw_files`

Guarda en disco los archivos raw seleccionados por el preprocesador y devuelve sus rutas temporales.

**Firma:** `save_preprocessor_raw_files(raw_files)`

**Parametros**

- raw_files: data frame con columnas name y datapath (tipico de input$file).

**Valor de retorno**

Vector de rutas de archivo guardadas.

**Notas**

Funcion interna del preprocesador de datos CALAIRE.

**Archivo fuente:** `app.R`

---

### `server`

Funcion servidor de la aplicacion Shiny. Contiene toda la logica reactiva, helpers internos, carga de datos, calculos de homogeneidad/estabilidad/puntajes y generacion de reportes.

**Firma:** `server(input, output, session)`

**Parametros**

- input, output, session: objetos Shiny estandar.

**Valor de retorno**

Efectos secundarios en la sesion Shiny; no retorna valor.

**Notas**

Es la funcion principal de la aplicacion; las demas funciones documentadas en app.R estan anidadas o relacionadas con ella.

**Archivo fuente:** `app.R`

---

## Categoria: UI / Utilidades

### `algo_key`

Genera una clave unica para una combinacion analito/n_lab/nivel usando '||' como separador.

**Firma:** `algo_key(pollutant, n_lab, level) paste(pollutant, n_lab, level, sep = "||")`

**Parametros**

- pollutant, n_lab, level: identificadores.

**Valor de retorno**

Cadena de texto.

**Ejemplo**

```r
algo_key("O3", 12, "Nivel 1")
```

**Notas**

Usada para indexar resultados en reactiveValues.

**Archivo fuente:** `app.R`

---

### `safe_filename_stem`

Limpia una cadena para usarla como nombre base de archivo: elimina espacios, tildes y caracteres especiales, colapsa guiones bajos y recorta extremos.

**Firma:** `safe_filename_stem(x, fallback = "Informe_EA")`

**Parametros**

- x: valor a limpiar; fallback: nombre por defecto si x es vacio.

**Valor de retorno**

Cadena de texto segura para usar en nombres de archivo.

**Ejemplo**

```r
safe_filename_stem("Informe O3 Nivel Alto", "Informe_EA")
```

**Notas**

Se usa al descargar informes y exportaciones.

**Archivo fuente:** `app.R`

---

### `score_equation`

Renderiza una ecuacion en LaTeX usando MathJax dentro de un div con estilo 'text-muted'.

**Firma:** `score_equation(math)`

**Parametros**

- math: cadena LaTeX sin delimitadores (se envuelve en \( ... \)).

**Valor de retorno**

Objeto Shiny (withMathJax + div).

**Ejemplo**

```r
score_equation("z = \frac{x - x_{pt}}{\sigma_{pt}}")
```

**Notas**

Usado para mostrar ecuaciones en paneles de ayuda.

**Archivo fuente:** `app.R`

---

## Categoria: Obsoleto

### `algorithm_A` `[OBSOLETO]` `[EXPORTADA]`

Version anterior del Algoritmo A (ISO 13528). Deprecada: usar run_algorithm_a().

**Detalles**

This function calculates robust estimates of the mean and standard deviation for a dataset, handling outliers by iteratively down-weighting extreme values.

**Firma:** `algorithm_A(x, max_iter = 100)`

**Parametros**

- x: vector numerico; max_iter: iteraciones maximas.

**Valor de retorno**

Lista con robust_mean y robust_sd.

**Vease tambien**

`run_algorithm_a()` for the recommended replacement.

**Notas**

Se mantiene solo por compatibilidad hacia atras.

**Archivo fuente:** `R/utils.R`

**Referencia ISO:** ISO 13528:2022, Annex C

---

### `mad_e_manual` `[OBSOLETO]` `[EXPORTADA]`

Version manual de calculate_mad_e(). Deprecada.

**Detalles**

Calculates the Median Absolute Deviation (MAD) and scales it by 1.4826 to provide a robust estimate of the standard deviation.

**Firma:** `mad_e_manual(x)`

**Parametros**

- x: vector numerico.

**Valor de retorno**

Valor MADe.

**Vease tambien**

`calculate_mad_e()` for the recommended replacement.

**Notas**

Se mantiene solo por compatibilidad hacia atras.

**Archivo fuente:** `R/utils.R`

**Referencia ISO:** ISO 13528:2022, Section 9.4

---

### `nIQR_manual` `[OBSOLETO]` `[EXPORTADA]`

Version manual de calculate_niqr(). Deprecada.

**Detalles**

Calculates the Interquartile Range (IQR) and normalizes it by 0.7413 to provide a robust estimate of the standard deviation.

**Firma:** `nIQR_manual(x)`

**Parametros**

- x: vector numerico.

**Valor de retorno**

Valor nIQR.

**Vease tambien**

`calculate_niqr()` for the recommended replacement.

**Notas**

Se mantiene solo por compatibilidad hacia atras.

**Archivo fuente:** `R/utils.R`

**Referencia ISO:** ISO 13528:2022, Section 9.4

---


