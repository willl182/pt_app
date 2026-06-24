# Glosario de términos (ES/EN)

Este glosario reúne la terminología clave del sistema de ensayos de aptitud (PT), el paquete `ptcalc` y la interfaz de usuario. Incluye equivalentes en inglés, símbolos y definiciones para facilitar la lectura técnica.

---

## Conceptos fundamentales

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| Ensayo de aptitud | Proficiency testing (PT) | PT | Comparación interlaboratorio para evaluar desempeño. |
| Interlaboratorio | Interlaboratory | - | Comparación entre múltiples laboratorios. |
| Participante | Participant | - | Laboratorio o entidad que reporta resultados. |
| Proveedor de PT | PT provider | - | Organización que coordina el esquema PT. |
| Valor reportado | Reported value | xᵢ | Valor entregado por un participante. |

---

## Mediciones y datos

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| Analito / Contaminante | Analyte / Pollutant | - | Gas medido (CO, SO₂, NO, O₃, NO₂). |
| Nivel | Level | - | Nivel de concentración. |
| Réplica | Replicate | - | Medición repetida sobre la misma muestra. |
| Muestra / Ítem | Sample / Item | - | Unidad física distribuida. |
| Valor | Value | x | Resultado de concentración medido. |
| Media | Mean | x̄ | Promedio aritmético. |
| Mediana | Median | x̃ | Valor central de un conjunto ordenado. |
| Desviación estándar | Standard deviation | s, σ | Medida de dispersión. |
| Varianza | Variance | s² | Cuadrado de la desviación estándar. |
| Formato largo | Long format | - | Cada fila es una observación. |
| Formato ancho | Wide format | - | Cada fila es un participante (o muestra). |
| Archivo CSV | CSV file | - | Archivo separado por comas. |

---

## Valor asignado y consenso

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| Valor asignado | Assigned value | xₚₜ | Valor de referencia para evaluar resultados. |
| Valor de referencia | Reference value | x_ref | Valor de laboratorio de referencia. |
| Valor de consenso | Consensus value | x* | Media robusta de participantes. |
| Incertidumbre del valor asignado | Assigned value uncertainty | uₚₜ | Incertidumbre estándar de xₚₜ. |
| Algoritmo A | Algorithm A | - | Estimación robusta iterativa (ISO 13528). |
| Media robusta | Robust mean | x* | Media calculada con estadística robusta. |
| Desviación estándar robusta | Robust standard deviation | s* | Dispersión robusta (Algoritmo A). |

---

## Estadística robusta

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| Estadístico robusto | Robust statistic | - | Estimador resistente a atípicos. |
| Rango intercuartílico normalizado | Normalized IQR | nIQR | 0.7413 × IQR. |
| Desviación absoluta mediana escalada | Scaled MAD | MADe | 1.483 × MAD. |
| Rango intercuartílico | Interquartile range | IQR | Q₃ − Q₁. |
| Desviación absoluta mediana | Median absolute deviation | MAD | Mediana de |xᵢ − mediana|. |
| Peso | Weight | w | Peso de observaciones en Algoritmo A. |
| Convergencia | Convergence | - | Estabilización del algoritmo iterativo. |

---

## Homogeneidad y estabilidad

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| Homogeneidad | Homogeneity | - | Uniformidad entre ítems. |
| Estabilidad | Stability | - | Constancia del valor en el tiempo. |
| Desviación entre muestras | Between-sample SD | sₛ | Variación entre ítems. |
| Desviación intra-muestra | Within-sample SD | s_w | Variación de réplicas. |
| Criterio de homogeneidad | Homogeneity criterion | c | c = 0.3 × σₚₜ. |
| Criterio expandido | Expanded criterion | c_exp | Criterio ajustado por réplica. |
| Incertidumbre de homogeneidad | Homogeneity uncertainty | u_hom | Contribución de inhomogeneidad. |
| Incertidumbre de estabilidad | Stability uncertainty | u_stab | Contribución de inestabilidad. |
| Diferencia hom-estab | Hom-stab difference | D | |ȳ_hom − ȳ_stab|. |

---

## Puntajes de desempeño

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| Puntaje z | z-score | z | (xᵢ − xₚₜ) / σₚₜ. |
| Puntaje z prima | z′-score | z′ | (xᵢ − xₚₜ) / √(σₚₜ² + uₚₜ²). |
| Puntaje zeta | Zeta score | ζ | (xᵢ − xₚₜ) / √(uᵢ² + uₚₜ²). |
| Número En | En number | Eₙ | (xᵢ − xₚₜ) / √(Uᵢ² + Uₚₜ²). |
| Puntaje Q | Q score | Q | (xᵢ − xₚₜ) / √(σₚₜ² + sᵢ²). |
| Desviación para aptitud | Std dev for proficiency | σₚₜ | Dispersión objetivo para PT. |

---

## Evaluación de puntajes

| Español | Inglés | Criterio | Descripción |
|---|---|---|---|
| Satisfactorio | Satisfactory | |z| ≤ 2 o |Eₙ| ≤ 1 | Resultado aceptable. |
| Cuestionable | Questionable | 2 < |z| < 3 | Señal de advertencia. |
| No satisfactorio | Unsatisfactory | |z| ≥ 3 o |Eₙ| > 1 | Requiere acción. |

---

## Incertidumbre y compatibilidad metrológica

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| Incertidumbre estándar | Standard uncertainty | u | Desviación estándar asociada al resultado. |
| Incertidumbre expandida | Expanded uncertainty | U | u × k (típicamente k = 2). |
| Factor de cobertura | Coverage factor | k | Multiplicador de U. |
| Compatibilidad metrológica | Metrological compatibility | - | |x₁ − x₂| ≤ k·√(u₁² + u₂²). |
| D₂a / D₂b | D2a / D2b | D₂a, D₂b | Índices de compatibilidad. |

---

## ANOVA y pruebas de atípicos

| Español | Inglés | Símbolo | Definición |
|---|---|---|---|
| ANOVA | Analysis of variance | ANOVA | Comparación de medias. |
| Suma de cuadrados | Sum of squares | SS | Variación total. |
| Grados de libertad | Degrees of freedom | df | Valores independientes. |
| Cuadrado medio | Mean square | MS | SS / df. |
| Prueba de Grubbs | Grubbs test | G | Detección de un atípico. |
| Prueba de Dixon | Dixon test | Q | Detección de atípicos en muestras pequeñas. |
| Puntaje modificado | Modified Z-score | M | Detección robusta de atípicos. |

---

## Interfaz de usuario

| Español | Inglés | Contexto |
|---|---|---|
| Carga de datos | Data loading | Subida de archivos. |
| Ejecutar análisis | Run analysis | Botón de cálculo. |
| Calcular puntajes | Calculate scores | Cálculo de desempeño. |
| Generar informe | Generate report | Exportación. |
| Informe global | Global report | Vista resumida. |
| Detalle por participante | Participant detail | Resultados individuales. |
| Valores atípicos | Outliers | Detección. |
| Compatibilidad metrológica | Metrological compatibility | Evaluación de acuerdo. |

---

## Contaminantes y unidades

| Código | Español | Inglés | Fórmula | Unidades típicas |
|---|---|---|---|---|
| co | Monóxido de carbono | Carbon monoxide | CO | μmol/mol |
| so2 | Dióxido de azufre | Sulfur dioxide | SO₂ | nmol/mol, μmol/mol |
| no | Óxido nítrico | Nitric oxide | NO | nmol/mol |
| no2 | Dióxido de nitrógeno | Nitrogen dioxide | NO₂ | nmol/mol |
| o3 | Ozono | Ozone | O₃ | nmol/mol |
| nox | Óxidos de nitrógeno | Nitrogen oxides | NO + NO₂ | nmol/mol |

| Unidad | Inglés | Símbolo | Descripción |
|---|---|---|---|
| micromol/mol | micromole/mole | μmol/mol | Mezcla molar (ppm). |
| nanomol/mol | nanomole/mole | nmol/mol | Mezcla molar (ppb). |
| ppm | parts per million | ppm | Razón volumétrica. |
| ppb | parts per billion | ppb | Razón volumétrica. |

---

## Referencias ISO

| Norma | Título | Alcance |
|---|---|---|
| ISO 13528:2022 | Statistical methods for use in proficiency testing | Métodos estadísticos PT. |
| ISO 17043:2024 | Conformity assessment — General requirements for PT | Requisitos del proveedor. |
| ISO/IEC 17025:2017 | General requirements for testing laboratories | Acreditación. |
| ISO 5725 | Accuracy (trueness and precision) | Repetibilidad/reproducibilidad. |
| GUM (JCGM 100) | Guide to the expression of uncertainty in measurement | Marco de incertidumbre. |
