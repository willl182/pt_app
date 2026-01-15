# Glossary of Terms / Glosario de Terminos

This glossary provides Spanish-English translations and definitions for terms used in the proficiency testing application.

---

## Core Concepts / Conceptos Fundamentales

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Ensayo de aptitud | Proficiency testing (PT) | PT | Evaluation of participant performance against established criteria |
| Interlaboratorio | Interlaboratory | - | Comparison between multiple laboratories |
| Participante | Participant | - | Laboratory or entity submitting results for evaluation |
| Proveedor de PT | PT provider | - | Organization conducting the proficiency test |

---

## Measurements / Mediciones

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Analito | Pollutant/Analyte | - | The gas species being measured (CO, SO2, NO, etc.) |
| Nivel | Level | - | Concentration level of the analyte |
| Replica | Replicate | - | Repeated measurement on the same sample |
| Muestra | Sample | - | Physical item being measured |
| Item | Item | g | Individual sample unit for homogeneity testing |
| Valor | Value | x | Measured concentration result |
| Media | Mean | $\bar{x}$ | Arithmetic average of values |
| Mediana | Median | - | Middle value when sorted |
| Desviacion estandar | Standard deviation | s, $\sigma$ | Measure of dispersion |
| Varianza | Variance | $s^2$ | Square of standard deviation |

---

## Assigned Value / Valor Asignado

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Valor asignado | Assigned value | $x_{pt}$ | Reference value for evaluating participant results |
| Valor de referencia | Reference value | $x_{ref}$ | Value from reference laboratory |
| Valor de consenso | Consensus value | $x^*$ | Robust mean from participant results |
| Incertidumbre del valor asignado | Assigned value uncertainty | $u_{xpt}$ | Standard uncertainty of $x_{pt}$ |
| Algoritmo A | Algorithm A | - | ISO 13528 iterative robust estimation |

---

## Robust Statistics / Estadisticos Robustos

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Estadistico robusto | Robust statistic | - | Estimator resistant to outliers |
| nIQR | Normalized IQR | nIQR | $0.7413 \times IQR$, robust scale estimate |
| MADe | Scaled MAD | MADe | $1.483 \times MAD$, robust scale estimate |
| Rango intercuartilico | Interquartile range | IQR | $Q_3 - Q_1$ |
| Desviacion absoluta mediana | Median absolute deviation | MAD | Median of $|x_i - \text{median}|$ |
| Peso | Weight | w | Algorithm A weight for each observation |
| Convergencia | Convergence | - | When iterative algorithm stabilizes |

---

## Homogeneity & Stability / Homogeneidad y Estabilidad

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Homogeneidad | Homogeneity | - | Uniformity of items distributed to participants |
| Estabilidad | Stability | - | Constancy of item properties over time |
| Desviacion entre muestras | Between-sample std dev | $s_s$ | Variation between different items |
| Desviacion intra-muestra | Within-sample std dev | $s_w$ | Variation within replicate measurements |
| Criterio de homogeneidad | Homogeneity criterion | c | $0.3 \times \sigma_{pt}$ |
| Criterio expandido | Expanded criterion | $c_{exp}$ | $\sqrt{c^2 \times 1.88 + s_w^2 \times 1.01}$ |
| Incertidumbre de homogeneidad | Homogeneity uncertainty | $u_{hom}$ | Contribution from inhomogeneity |
| Incertidumbre de estabilidad | Stability uncertainty | $u_{stab}$ | Contribution from instability |
| Diferencia hom-estab | Hom-stab difference | D | $|\bar{y}_{hom} - \bar{y}_{stab}|$ |

---

## Performance Scores / Puntajes de Desempeno

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Puntaje | Score | - | Quantitative measure of participant performance |
| Puntaje z | z-score | z | $(x - x_{pt}) / \sigma_{pt}$ |
| Puntaje z prima | z'-score | z' | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + u_{xpt}^2}$ |
| Puntaje zeta | zeta-score | $\zeta$ | $(x - x_{pt}) / \sqrt{u_x^2 + u_{xpt}^2}$ |
| Numero normalizado | Normalized error | $E_n$ | $(x - x_{pt}) / \sqrt{U_x^2 + U_{xpt}^2}$ |
| Desviacion tipica para aptitud | Std dev for proficiency | $\sigma_{pt}$ | Target dispersion for PT |
| Incertidumbre estandar | Standard uncertainty | u | Uncertainty at k=1 coverage |
| Incertidumbre expandida | Expanded uncertainty | U | Uncertainty at k=2 coverage |

---

## Score Evaluation / Evaluacion de Puntajes

| Spanish | English | Criterion | Description |
|---------|---------|-----------|-------------|
| Satisfactorio | Satisfactory | $|z| \leq 2$ or $|E_n| \leq 1$ | Acceptable performance |
| Cuestionable | Questionable | $2 < |z| < 3$ | Warning signal |
| No satisfactorio | Unsatisfactory | $|z| \geq 3$ or $|E_n| > 1$ | Action required |

---

## Combined Classification (a1-a7) / Clasificacion Combinada

| Code | Spanish | English | Description |
|------|---------|---------|-------------|
| a1 | Totalmente satisfactorio | Fully satisfactory | z and En both satisfactory |
| a2 | Satisfactorio pero conservador | Satisfactory but conservative | Good result with overestimated uncertainty |
| a3 | Satisfactorio con MU subestimada | Satisfactory with underestimated MU | Good result but uncertainty too small |
| a4 | Cuestionable pero aceptable | Questionable but acceptable | z warning, En satisfactory |
| a5 | Cuestionable e inconsistente | Questionable and inconsistent | z warning, En unsatisfactory |
| a6 | No satisfactorio pero MU cubre | Unsatisfactory but MU covers | Poor z but En still acceptable |
| a7 | No satisfactorio (critico) | Unsatisfactory (critical) | Both scores unacceptable |

---

## Statistical Terms / Terminos Estadisticos

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| ANOVA | ANOVA | - | Analysis of variance |
| Grados de libertad | Degrees of freedom | df, gl | Number of independent values |
| Suma de cuadrados | Sum of squares | SS | $\sum(x_i - \bar{x})^2$ |
| Media de cuadrados | Mean square | MS | SS / df |
| Prueba de Grubbs | Grubbs test | G | Test for single outlier |
| Valor atipico | Outlier | - | Observation far from others |
| Prueba t | t-test | t | Test for mean difference |
| Valor p | p-value | p | Probability of observing result under null |

---

## UI Terms / Terminos de Interfaz

| Spanish | English | Context |
|---------|---------|---------|
| Carga de datos | Data loading | File upload tab |
| Ejecutar analisis | Run analysis | Analysis button |
| Calcular puntajes | Calculate scores | Score computation |
| Generar informe | Generate report | Report export |
| Archivo de homogeneidad | Homogeneity file | File upload |
| Archivo de estabilidad | Stability file | File upload |
| Archivos resumen | Summary files | Participant data |
| Informe global | Global report | Summary view |
| Detalle por participante | Participant detail | Individual results |
| Valores atipicos | Outliers | Outlier detection tab |
| Compatibilidad metrologica | Metrological compatibility | Agreement assessment |

---

## File Columns / Columnas de Archivos

| Spanish Column | English Column | Data Type |
|----------------|----------------|-----------|
| pollutant | pollutant | character |
| level | level | character |
| replicate | replicate | integer |
| value | value | numeric |
| sample_id | sample_id | integer |
| participant_id | participant_id | character |
| mean_value | mean_value | numeric |
| sd_value | sd_value | numeric |
| n_lab | n_lab | integer |

---

## Pollutant Codes / Codigos de Contaminantes

| Code | Spanish | English | Formula |
|------|---------|---------|---------|
| co | Monoxido de carbono | Carbon monoxide | CO |
| so2 | Dioxido de azufre | Sulfur dioxide | SO2 |
| no | Monoxido de nitrogeno | Nitric oxide | NO |
| no2 | Dioxido de nitrogeno | Nitrogen dioxide | NO2 |
| o3 | Ozono | Ozone | O3 |

---

## Units / Unidades

| Spanish | English | Symbol | Description |
|---------|---------|--------|-------------|
| micromol/mol | micromole/mole | umol/mol | Molar mixing ratio (ppm equivalent) |
| nanomol/mol | nanomole/mole | nmol/mol | Molar mixing ratio (ppb equivalent) |
| ppm | partes por millon | parts per million | Volume ratio |
| ppb | partes por billon | parts per billion | Volume ratio |

---

## ISO References / Referencias ISO

| Standard | Title (English) | Scope |
|----------|-----------------|-------|
| ISO 13528:2022 | Statistical methods for use in proficiency testing | Statistical procedures |
| ISO 17043:2024 | Conformity assessment - General requirements for PT | PT provider requirements |
| ISO/IEC 17025:2017 | General requirements for testing laboratories | Laboratory accreditation |
| GUM (JCGM 100) | Guide to the expression of uncertainty in measurement | Uncertainty framework |
