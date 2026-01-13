# Glossary: Spanish/English Terminology

This glossary defines key terms used throughout the application and documentation.

---

## Core Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Analito** | Pollutant | - | The gas being analyzed (SO2, CO, O3, NO, NO2) |
| **Nivel** | Level | - | Concentration level of the sample |
| **Puntaje** | Score | z, z', ζ, En | Performance metric for participant results |
| **Valor asignado** | Assigned value | x_pt | Reference value for comparison |
| **Ensayo de aptitud** | Proficiency test (PT) | - | Interlaboratory comparison to evaluate laboratory performance |
| **Participante** | Participant | - | Laboratory participating in the PT scheme |
| **Valor reportado** | Reported value | x_i | Value submitted by a participant |
| **Desviación estándar** | Standard deviation | s, σ | Measure of data spread |

---

## Statistical Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Media robusta** | Robust mean | x* | Mean calculated using Algorithm A |
| **Mediana** | Median | x̃ | Middle value of ordered data |
| **Desviación estándar robusta** | Robust standard deviation | s* | Standard deviation from Algorithm A |
| **Rango intercuartílico normalizado** | Normalized interquartile range | nIQR | Robust measure of spread: 0.7413 × IQR |
| **Desviación absoluta mediana** | Median absolute deviation | MADe | Robust measure of spread |
| **Algoritmo A** | Algorithm A | - | ISO 13528 robust statistics algorithm |
| **Grado de libertad efectivo** | Effective degrees of freedom | ν_eff | Used in uncertainty propagation |

---

## Homogeneity & Stability

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Homogeneidad** | Homogeneity | - | Uniformity of samples in a batch |
| **Estabilidad** | Stability | - | Consistency of samples over time |
| **Criterio de homogeneidad** | Homogeneity criterion | c | Acceptance limit: c = 0.3 × σ_pt |
| **Incertidumbre de homogeneidad** | Homogeneity uncertainty | u_hom | Uncertainty contribution from inhomogeneity |
| **Incertidumbre de estabilidad** | Stability uncertainty | u_stab | Uncertainty contribution from instability |
| **Entre muestras** | Between samples | ss | Variance between different samples |
| **Dentro de muestra** | Within sample | sw | Variance within a single sample |

---

## PT Score Types

| Spanish Term | English Term | Symbol | Formula | Use Case |
|--------------|--------------|--------|---------|----------|
| **Puntaje z** | z-score | z | (x_i - x_pt) / σ_pt | When σ_pt is known or specified |
| **Puntaje z prima** | Robust z-score | z' | (x_i - x*) / s* | When σ_pt is estimated from data |
| **Puntaje zeta** | Zeta score | ζ | (x_i - x_pt) / √(u_xi² + u_pt²) | When participant uncertainty is known |
| **Puntaje En** | En number | En | (x_i - x_pt) / √(U_xi² + U_pt²) | For calibration comparison |
| **Puntaje Q** | Q score | Q | (x_i - x_pt) / √(σ_pt² + s_i²) | Alternative score |

---

## Uncertainty Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Incertidumbre estándar** | Standard uncertainty | u | Uncertainty expressed as standard deviation |
| **Incertidumbre expandida** | Expanded uncertainty | U | u × k, where k is coverage factor |
| **Factor de cobertura** | Coverage factor | k | Multiplier for expanded uncertainty (typically k=2) |
| **Incertidumbre del participante** | Participant uncertainty | u_xi | Uncertainty of participant's reported value |
| **Incertidumbre del valor asignado** | Assigned value uncertainty | u_pt | Uncertainty of the reference value |
| **Desviación objetivo** | Target deviation | σ_pt | Target standard deviation for PT |
| **Propagación de incertidumbre** | Uncertainty propagation | - | Combining uncertainty components |

---

## Metrological Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Compatibilidad metrológica** | Metrological compatibility | - | Two values are compatible if |x₁ - x₂| ≤ k·√(u₁² + u₂²) |
| **D_2a** | D_2a statistic | D_2a | Metrological compatibility index |
| **D_2b** | D_2b statistic | D_2b | Alternative compatibility index |
| **Trazabilidad** | Traceability | - | Property of a measurement result relating to a reference |
| **Exactitud** | Accuracy | - | Closeness of measurement to true value |
| **Precisión** | Precision | - | Closeness of repeated measurements |
| **Verdad** | Trueness | - | Closeness of mean to true value |

---

## ANOVA Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Análisis de varianza** | Analysis of variance | ANOVA | Statistical method to compare means |
| **Suma de cuadrados** | Sum of squares | SS | Total variation in data |
| **Grados de libertad** | Degrees of freedom | df | Number of independent values |
| **Cuadrado medio** | Mean square | MS | SS / df |
| **Valor F** | F-value | F | Ratio of variances |
| **Valor p** | p-value | p | Probability of observing data if null hypothesis is true |

---

## Outlier Detection

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Valor atípico** | Outlier | - | Data point significantly different from others |
| **Prueba de Grubbs** | Grubbs test | G | Test for single outlier |
| **Prueba de Dixon** | Dixon test | Q | Test for outliers in small samples |
| **Puntaje modificado** | Modified Z-score | M | Robust outlier detection |

---

## Classification Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Satisfactorio** | Satisfactory | - | |z| ≤ 2 (for z-scores) |
| **Cuestionable** | Questionable | - | 2 < |z| ≤ 3 (for z-scores) |
| **No satisfactorio** | Unsatisfactory | - | |z| > 3 (for z-scores) |
| **Aceptación** | Acceptance | - | Item meets homogeneity/stability criteria |
| **Rechazo** | Rejection | - | Item fails homogeneity/stability criteria |

---

## UI/Interface Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Pestaña** | Tab | - | Navigation section in the UI |
| **Panel lateral** | Sidebar | - | Left panel for controls and inputs |
| **Área principal** | Main panel | - | Right panel for outputs and visualizations |
| **Entrada de datos** | Data input | - | Section for uploading/loading data |
| **Análisis** | Analysis | - | Computational process on data |
| **Informe** | Report | - | Generated document with results |

---

## Pollutants

| Spanish | English | Chemical Formula | Typical Units |
|---------|---------|------------------|---------------|
| **Dióxido de azufre** | Sulfur dioxide | SO₂ | nmol/mol, μmol/mol |
| **Monóxido de carbono** | Carbon monoxide | CO | μmol/mol |
| **Ozono** | Ozone | O₃ | nmol/mol |
| **Óxido nítrico** | Nitric oxide | NO | nmol/mol |
| **Dióxido de nitrógeno** | Nitrogen dioxide | NO₂ | nmol/mol |
| **NOx** | Nitrogen oxides | NO + NO₂ | nmol/mol |

---

## File and Data Terms

| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| **Formato largo** | Long format | - | Each row is one observation |
| **Formato ancho** | Wide format | - | Each row is one participant |
| **Archivo CSV** | CSV file | - | Comma-separated values file |
| **Resumen** | Summary | - | Aggregated data table |
| **Réplica** | Replicate | - | Repeated measurement of same sample |
| **Muestra** | Sample | - | Individual test item in a batch |

---

## ISO Standards

| Standard Code | Full Name | Key Content |
|---------------|-----------|-------------|
| **ISO 13528** | Statistical methods for use in proficiency testing | Algorithms A, z-scores, robust statistics |
| **ISO 17043** | Proficiency testing — General requirements | PT scheme design, quality criteria |
| **ISO 5725** | Accuracy (trueness and precision) | Repeatability, reproducibility |

---

## Formula Symbols

| Symbol | Meaning | Context |
|--------|---------|---------|
| x_i | Participant's reported value | General |
| x_pt | Assigned value | Scores |
| x* | Robust mean (Algorithm A) | Statistics |
| σ_pt | Target standard deviation | Scores |
| s* | Robust standard deviation | Statistics |
| u_xi | Participant's standard uncertainty | Uncertainty |
| u_pt | Assigned value standard uncertainty | Uncertainty |
| u_hom | Homogeneity uncertainty | Quality |
| u_stab | Stability uncertainty | Quality |
| ν_eff | Effective degrees of freedom | Uncertainty propagation |
| α | Significance level | Statistics (commonly 0.05) |
| k | Coverage factor | Uncertainty (commonly 2) |

---

## Common Acronyms

| Acronym | Full Name | Context |
|---------|-----------|---------|
| **PT** | Proficiency Testing | General |
| **ANOVA** | Analysis of Variance | Statistics |
| **IQR** | Interquartile Range | Statistics |
| **nIQR** | Normalized IQR | Statistics |
| **MADe** | Median Absolute Deviation | Statistics |
| **CSV** | Comma-Separated Values | Data format |
| **RMD** | RMarkdown | Documentation |
| **PTB** | Proficiency Testing Body | Organization |
| **CALAIRE** | Laboratorio de Calidad del Aire | Laboratory name |

---

## Cross-References

For detailed information on specific topics:

- **Robust Statistics**: [03_pt_robust_stats.md](cloned_docs/03_pt_robust_stats.md)
- **Homogeneity/Stability**: [04_pt_homogeneity.md](cloned_docs/04_pt_homogeneity.md)
- **PT Scores**: [05_pt_scores.md](cloned_docs/05_pt_scores.md)
- **Metrological Compatibility**: [08_compatibilidad.md](cloned_docs/08_compatibilidad.md)
- **Data Formats**: [01_carga_datos.md](cloned_docs/01_carga_datos.md)
