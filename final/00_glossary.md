# Glossary of Terms / Glosario de Términos

This glossary provides definitions and translations (Spanish/English) for terms used in the proficiency testing (PT) application, the `ptcalc` package, and associated documentation.

---

## 1. Core Concepts / Conceptos Fundamentales

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Ensayo de aptitud | Proficiency testing (PT) | PT | Evaluation of participant performance against established criteria through interlaboratory comparisons. |
| Interlaboratorio | Interlaboratory | - | Comparison between multiple laboratories. |
| Participante | Participant | - | Laboratory or entity submitting results for evaluation. |
| Proveedor de PT | PT provider | - | Organization conducting the proficiency test. |
| Organismo de Ensayos de Aptitud | Proficiency Testing Body | PTB | The organization responsible for the PT scheme. |

---

## 2. Measurements & Data / Mediciones y Datos

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Analito | Pollutant / Analyte | - | The specific gas species or substance being analyzed (e.g., CO, SO2, NO, etc.). |
| Nivel | Level | - | Concentration level of the analyte (e.g., low, medium, high). |
| Muestra | Sample | - | Physical item being measured. |
| Item de ensayo de aptitud | PT item | g | Individual sample unit for testing, often used in homogeneity studies. |
| Réplica | Replicate | - | Repeated measurement on the same sample or item. |
| Valor | Value | x | Measured concentration result. |
| Valor reportado | Reported value | $x_i$ | Value submitted by a participant for evaluation. |
| Media | Mean | $\bar{x}$ | Arithmetic average of values. |
| Mediana | Median | $\tilde{x}$ | Middle value when sorted. |
| Desviación estándar | Standard deviation | s, $\sigma$ | Measure of dispersion or spread of data. |
| Varianza | Variance | $s^2$ | Square of the standard deviation. |
| Formato largo | Long format | - | Data structure where each row represents a single observation. |
| Formato ancho | Wide format | - | Data structure where each row represents a participant with multiple columns for pollutants/levels. |

---

## 3. Assigned Value / Valor Asignado

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Valor asignado | Assigned value | $x_{pt}$ | Reference value used for evaluating participant results. |
| Valor de referencia | Reference value | $x_{ref}$ | Value determined by a reference laboratory or through formulation. |
| Valor de consenso | Consensus value | $x^*$ | Robust mean derived from participant results. |
| Laboratorio de referencia | Reference laboratory | - | A laboratory with high metrological standing used to determine the assigned value. |
| Incertidumbre del valor asignado | Assigned value uncertainty | $u_{xpt}$ | Standard uncertainty associated with the assigned value. |

---

## 4. Robust Statistics / Estadísticos Robustos

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Estadístico robusto | Robust statistic | - | An estimator resistant to the influence of outliers. |
| Algoritmo A | Algorithm A | - | Iterative robust estimation method described in ISO 13528 Annex C. |
| Media robusta | Robust mean | $x^*$ | Mean calculated using robust statistics (e.g., Algorithm A) to minimize outlier influence. |
| Desviación estándar robusta | Robust standard deviation | $s^*$ | Standard deviation calculated using robust statistics. |
| nIQR | Normalized IQR | nIQR | $0.7413 \times IQR$, a robust estimate of the standard deviation. |
| MADe | Scaled MAD | MADe | $1.483 \times MAD$, a robust estimate of the standard deviation. |
| Rango intercuartílico | Interquartile range | IQR | Difference between the third and first quartiles ($Q_3 - Q_1$). |
| Desviación absoluta mediana | Median absolute deviation | MAD | Median of the absolute deviations from the median: $\text{median}(|x_i - \text{median}|)$. |
| Peso | Weight | w | Influence factor assigned to each observation in Algorithm A. |
| Convergencia | Convergence | - | The point where iterative calculations stabilize. |

---

## 5. Homogeneity & Stability / Homogeneidad y Estabilidad

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Homogeneidad | Homogeneity | - | Uniformity of properties across different units (items) in a batch. |
| Estabilidad | Stability | - | Constancy of properties of a material over a specified period. |
| Desviación entre muestras | Between-sample std dev | $s_s$ | Variation component attributed to differences between items. |
| Desviación intra-muestra | Within-sample std dev | $s_w$ | Variation component attributed to measurement repeatability within items. |
| Varianza entre muestras | Between-sample variance | $s_s^2$ | Square of the between-sample standard deviation. |
| Varianza dentro de las muestras | Within-sample variance | $s_w^2$ | Square of the within-sample standard deviation. |
| Criterio de homogeneidad | Homogeneity criterion | c | Acceptance limit, typically defined as $0.3 \times \sigma_{pt}$. |
| Criterio expandido | Expanded criterion | $c_{exp}$ | Calculated threshold taking into account measurement uncertainty: $\sqrt{c^2 \times 1.88 + s_w^2 \times 1.01}$. |
| Incertidumbre de homogeneidad | Homogeneity uncertainty | $u_{hom}$ | Uncertainty contribution arising from potential inhomogeneity. |
| Incertidumbre de estabilidad | Stability uncertainty | $u_{stab}$ | Uncertainty contribution arising from potential instability. |
| Diferencia hom-estab | Hom-stab difference | D | Absolute difference between homogeneity and stability means: $|\bar{y}_{hom} - \bar{y}_{stab}|$. |
| Aceptación | Acceptance | - | Condition where an item meets the homogeneity or stability criteria. |
| Rechazo | Rejection | - | Condition where an item fails the homogeneity or stability criteria. |

---

## 6. Performance Scores / Puntajes de Desempeño

| Spanish | English | Symbol | Formula | Use Case |
|---------|---------|--------|---------|----------|
| Puntaje | Score | - | Quantitative measure used to evaluate participant performance. |
| Puntaje z | z-score | z | $(x - x_{pt}) / \sigma_{pt}$ | Evaluates deviation relative to $\sigma_{pt}$. |
| Puntaje z prima | z'-score | z' | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + u_{xpt}^2}$ | Used when assigned value uncertainty is significant. |
| Puntaje zeta | zeta-score | $\zeta$ | $(x - x_{pt}) / \sqrt{u_x^2 + u_{xpt}^2}$ | Compares results using participant's own reported uncertainty. |
| Número normalizado | En number | $E_n$ | $(x - x_{pt}) / \sqrt{U_x^2 + U_{xpt}^2}$ | Used for comparing results with expanded uncertainties (k=2). |
| Puntaje Q | Q score | Q | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + s_i^2}$ | Alternative scoring method. |
| Desviación típica para aptitud | Std dev for proficiency | $\sigma_{pt}$ | Target dispersion used to assess performance. |
| Desviación objetivo | Target deviation | $\sigma_{pt}$ | Another name for standard deviation for proficiency assessment. |

---

## 7. Score Evaluation & Classification / Evaluación y Clasificación de Puntajes

### Performance Levels
| Spanish | English | Criterion | Description |
|---------|---------|-----------|-------------|
| Satisfactorio | Satisfactory | $|z| \leq 2$ or $|E_n| \leq 1$ | Performance is considered acceptable. |
| Cuestionable | Questionable | $2 < |z| < 3$ | Performance provides a warning signal. |
| No satisfactorio | Unsatisfactory | $|z| \geq 3$ or $|E_n| > 1$ | Performance is considered unacceptable (action required). |

### Combined Classification (a1-a7)
| Code | Spanish | English | Description |
|------|---------|---------|-------------|
| a1 | Totalmente satisfactorio | Fully satisfactory | Both z and En are satisfactory. |
| a2 | Satisfactorio pero conservador | Satisfactory but conservative | z is satisfactory, but En is very small (MU may be overestimated). |
| a3 | Satisfactorio con MU subestimada | Satisfactory with underestimated MU | z is satisfactory, but En is unsatisfactory (MU is likely too small). |
| a4 | Cuestionable pero aceptable | Questionable but acceptable | z is questionable, but En is satisfactory. |
| a5 | Cuestionable e inconsistente | Questionable and inconsistent | Both z and En show issues (warning). |
| a6 | No satisfactorio pero MU cubre | Unsatisfactory but MU covers | z is unsatisfactory, but En is satisfactory due to large MU. |
| a7 | No satisfactorio (crítico) | Unsatisfactory (critical) | Both z and En are unsatisfactory. |

---

## 8. Statistical Terms / Términos Estadísticos

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Análisis de varianza | Analysis of variance | ANOVA | Statistical method to compare means and partition variance. |
| Grados de libertad | Degrees of freedom | df, gl | Number of independent values used in a calculation. |
| Grado de libertad efectivo | Effective degrees of freedom | $\nu_{eff}$ | Value used in uncertainty propagation (Welch-Satterthwaite). |
| Suma de cuadrados | Sum of squares | SS | Sum of squared deviations from the mean. |
| Media de cuadrados | Mean square | MS | Sum of squares divided by degrees of freedom. |
| Valor F | F-value | F | Ratio of variances used in ANOVA. |
| Valor p | p-value | p | Probability of observing the result if the null hypothesis is true. |
| Nivel de significancia | Significance level | $\alpha$ | Probability of rejecting the null hypothesis when it is true (commonly 0.05). |
| Prueba t | t-test | t | Statistical test used to compare two means. |

---

## 9. Uncertainty Terms / Términos de Incertidumbre

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Incertidumbre | Uncertainty | u(x) | Parameter characterizing the dispersion of values attributed to a measurement. |
| Incertidumbre estándar | Standard uncertainty | u | Uncertainty expressed as a standard deviation (k=1). |
| Incertidumbre expandida | Expanded uncertainty | U | Standard uncertainty multiplied by a coverage factor (usually k=2). |
| Factor de cobertura | Coverage factor | k | Multiplier used to obtain expanded uncertainty. |
| Incertidumbre del participante | Participant uncertainty | $u_x$ | Standard uncertainty of the value reported by the participant. |
| Propagación de incertidumbre | Uncertainty propagation | - | Method of combining individual uncertainty components. |

---

## 10. Metrological Terms / Términos Metrológicos

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Compatibilidad metrológica | Metrological compatibility | - | Agreement between measurement results where their difference is within uncertainty limits. |
| Trazabilidad | Traceability | - | Property of a measurement result relating it to a reference through a chain of calibrations. |
| Exactitud | Accuracy | - | Closeness of agreement between a measured value and a true value. |
| Precisión | Precision | - | Closeness of agreement between repeated measurements. |
| Veracidad | Trueness | - | Closeness of agreement between the average of infinite measurements and a reference value. |
| Estadístico D2a | D2a statistic | $D_{2a}$ | Index for assessing metrological compatibility. |
| Estadístico D2b | D2b statistic | $D_{2b}$ | Alternative index for metrological compatibility. |

---

## 11. Outlier Detection / Detección de Valores Atípicos

| Spanish | English | Symbol | Definition |
|---------|---------|--------|------------|
| Valor atípico | Outlier | - | An observation that appears to deviate markedly from other members of the sample. |
| Prueba de Grubbs | Grubbs test | G | Statistical test for detecting a single outlier in a dataset. |
| Prueba de Dixon | Dixon test | Q | Statistical test for outliers in small sample sizes. |
| Puntaje z modificado | Modified z-score | M | Robust outlier detection method based on the median and MAD. |

---

## 12. UI & Interface Terms / Términos de Interfaz

| Spanish | English | Context |
|---------|---------|---------|
| Carga de datos | Data loading | Tab or section for uploading files. |
| Ejecutar análisis | Run analysis | Button to trigger calculations. |
| Calcular puntajes | Calculate scores | Computation of participant performance. |
| Generar informe | Generate report | Exporting results to Word/HTML. |
| Archivo de homogeneidad | Homogeneity file | CSV file with stability data. |
| Archivo de estabilidad | Stability file | CSV file with stability data. |
| Archivos resumen | Summary files | CSV files with participant results. |
| Informe global | Global report | Summary view of all results and levels. |
| Detalle por participante | Participant detail | Individual performance breakdown. |
| Pestaña | Tab | Navigation element in the user interface. |
| Panel lateral | Sidebar | Left-hand control area. |
| Área principal | Main panel | Content display area. |

---

## 13. Pollutants / Contaminantes

| Spanish | English | Formula | Typical Units |
|---------|---------|---------|---------------|
| Monóxido de carbono | Carbon monoxide | CO | μmol/mol (ppm) |
| Dióxido de azufre | Sulfur dioxide | $SO_2$ | nmol/mol (ppb) |
| Monóxido de nitrógeno | Nitric oxide | NO | nmol/mol (ppb) |
| Dióxido de nitrógeno | Nitrogen dioxide | $NO_2$ | nmol/mol (ppb) |
| Óxidos de nitrógeno | Nitrogen oxides | $NO_x$ | nmol/mol (ppb) |
| Ozono | Ozone | $O_3$ | nmol/mol (ppb) |

---

## 14. Units / Unidades

| Spanish | English | Symbol | Description |
|---------|---------|--------|-------------|
| micromol/mol | micromole/mole | μmol/mol | Molar mixing ratio, equivalent to parts per million (ppm). |
| nanomol/mol | nanomole/mole | nmol/mol | Molar mixing ratio, equivalent to parts per billion (ppb). |
| partes por millón | parts per million | ppm | Volume or molar ratio ($10^{-6}$). |
| partes por billón | parts per billion | ppb | Volume or molar ratio ($10^{-9}$). |

---

## 15. ISO Standards / Normas ISO

| Standard | Title | Key Content |
|----------|-------|-------------|
| ISO 13528:2022 | Statistical methods for use in proficiency testing | Robust algorithms (Algorithm A), scoring methods, homogeneity/stability criteria. |
| ISO 17043:2024 | Conformity assessment — General requirements for PT | Requirements for PT scheme design, management, and technical competence. |
| ISO 5725 | Accuracy (trueness and precision) of measurement methods | Procedures for determining repeatability and reproducibility. |
| ISO/IEC 17025 | General requirements for the competence of laboratories | Accreditation standards for testing and calibration laboratories. |
| GUM (JCGM 100) | Guide to the expression of uncertainty in measurement | International framework for evaluating measurement uncertainty. |

---

## 16. File Columns / Columnas de Archivos

| Spanish Column | English Column | Data Type | Description |
|----------------|----------------|-----------|-------------|
| pollutant | pollutant | character | Pollutant code (co, so2, etc.) |
| level | level | character | Concentration level name |
| replicate | replicate | integer | Measurement replicate index |
| value | value | numeric | Measured concentration value |
| sample_id | sample_id | integer | Unique identifier for the sample item |
| participant_id | participant_id | character | Unique identifier for the participant |
| mean_value | mean_value | numeric | Average value reported by participant |
| sd_value | sd_value | numeric | Standard deviation reported by participant |
| n_lab | n_lab | integer | Number of participants in the scheme |

---

## 17. Common Acronyms / Acrónimos Comunes

| Acronym | Full Name | Context |
|---------|-----------|---------|
| PT | Proficiency Testing | General field of activity. |
| ANOVA | Analysis of Variance | Statistical processing. |
| IQR | Interquartile Range | Robust dispersion measure. |
| nIQR | Normalized IQR | Standardized dispersion measure. |
| MAD | Median Absolute Deviation | Robust dispersion measure. |
| MADe | Scaled/Normalized MAD | Standardized dispersion measure. |
| CSV | Comma-Separated Values | Data file format. |
| RMD | RMarkdown | Document generation format. |
| MU | Measurement Uncertainty | General concept of uncertainty. |
| CALAIRE | Laboratorio de Calidad del Aire | Reference laboratory name. |

---

## 18. Formula Symbols / Símbolos de Fórmulas

| Symbol | Meaning | Context |
|--------|---------|---------|
| $x_i$ | Participant's reported value | Performance scoring |
| $x_{pt}$ | Assigned value | Performance scoring |
| $x^*$ | Robust mean (Algorithm A) | Robust statistics |
| $\sigma_{pt}$ | Target standard deviation | Performance scoring |
| $s^*$ | Robust standard deviation | Robust statistics |
| $u_{xi}$ | Participant's standard uncertainty | Uncertainty |
| $u_{pt}$ | Assigned value standard uncertainty | Uncertainty |
| $u_{hom}$ | Homogeneity uncertainty | Quality criteria |
| $u_{stab}$ | Stability uncertainty | Quality criteria |
| $\nu_{eff}$ | Effective degrees of freedom | Uncertainty propagation |
| $\alpha$ | Significance level | Statistical testing |
| k | Coverage factor | Uncertainty (usually k=2) |

---

## 19. Cross-References / Referencias Cruzadas

For detailed information on specific topics:

- **Robust Statistics**: [03_pt_robust_stats.md](03_pt_robust_stats.md)
- **Homogeneity/Stability**: [04_pt_homogeneity.md](04_pt_homogeneity.md)
- **PT Scores**: [05_pt_scores.md](05_pt_scores.md)
- **Metrological Compatibility**: [08_compatibilidad.md](08_compatibilidad.md)
- **Data Formats**: [01_carga_datos.md](01_carga_datos.md)
