# Glosario de Términos

Este glosario define los términos clave utilizados en toda la aplicación y documentación, relacionando los términos de la interfaz en español con sus equivalentes en inglés y símbolos matemáticos cuando corresponde.

---

## Términos Principales

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Analito** | Pollutant | - | El gas que está siendo analizado (SO2, CO, O3, NO, NO2). |
| **Nivel** | Level | - | Nivel de concentración de la muestra. |
| **Puntaje** | Score | z, z', ζ, En | Métrica de desempeño para los resultados de los participantes. |
| **Valor asignado** | Assigned value | $x_{pt}$ | Valor de referencia para comparación. |
| **Ensayo de aptitud** | Proficiency test (PT) | - | Comparación interlaboratorios para evaluar el desempeño del laboratorio. |
| **Participante** | Participant | - | Laboratorio que participa en el esquema de PT. |
| **Valor reportado** | Reported value | $x_i$ | Valor enviado por un participante. |
| **Desviación estándar** | Standard deviation | s, σ | Medida de dispersión de los datos. |

---

## Términos Estadísticos

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Media robusta** | Robust mean | $x^*$ | Media calculada utilizando el Algoritmo A. |
| **Mediana** | Median | $\tilde{x}$ | Valor central de los datos ordenados. |
| **Desviación estándar robusta** | Robust standard deviation | $s^*$ | Desviación estándar obtenida del Algoritmo A. |
| **Rango intercuartílico normalizado** | Normalized interquartile range | nIQR | Medida robusta de dispersión: $0.7413 \times IQR$. |
| **Desviación absoluta de la mediana** | Median absolute deviation | MADe | Medida robusta de dispersión. |
| **Algoritmo A** | Algorithm A | - | Algoritmo estadístico robusto de la norma ISO 13528. |
| **Grados de libertad efectivos** | Effective degrees of freedom | $\nu_{eff}$ | Utilizado en la propagación de incertidumbre. |

---

## Homogeneidad y Estabilidad

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Homogeneidad** | Homogeneity | - | Uniformidad de las muestras en un lote. |
| **Estabilidad** | Stability | - | Consistencia de las muestras a lo largo del tiempo. |
| **Criterio de homogeneidad** | Homogeneity criterion | c | Límite de aceptación: $c = 0.3 \times \sigma_{pt}$. |
| **Incertidumbre de homogeneidad** | Homogeneity uncertainty | $u_{hom}$ | Contribución de incertidumbre debido a la falta de homogeneidad. |
| **Incertidumbre de estabilidad** | Stability uncertainty | $u_{stab}$ | Contribución de incertidumbre debido a la inestabilidad. |
| **Entre muestras** | Between samples | $s_s$ | Varianza entre diferentes muestras. |
| **Dentro de muestra** | Within sample | $s_w$ | Varianza dentro de una misma muestra (réplicas). |

---

## Tipos de Puntajes PT

| Término en Español | Término en Inglés | Símbolo | Fórmula | Caso de Uso |
|--------------------|-------------------|---------|---------|-------------|
| **Puntaje z** | z-score | z | $(x_i - x_{pt}) / \sigma_{pt}$ | Cuando $\sigma_{pt}$ es conocida o especificada. |
| **Puntaje z prima** | Robust z-score | z' | $(x_i - x^*) / s^*$ | Cuando $\sigma_{pt}$ se estima a partir de los datos. |
| **Puntaje zeta** | Zeta score | $\zeta$ | $(x_i - x_{pt}) / \sqrt{u_{xi}^2 + u_{pt}^2}$ | Cuando se conoce la incertidumbre del participante. |
| **Puntaje En** | En number | $E_n$ | $(x_i - x_{pt}) / \sqrt{U_{xi}^2 + U_{pt}^2}$ | Para comparación de calibración. |
| **Puntaje Q** | Q score | Q | $(x_i - x_{pt}) / \sqrt{\sigma_{pt}^2 + s_i^2}$ | Puntaje alternativo. |

---

## Términos de Incertidumbre

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Incertidumbre estándar** | Standard uncertainty | u | Incertidumbre expresada como desviación estándar. |
| **Incertidumbre expandida** | Expanded uncertainty | U | $u \times k$, donde $k$ es el factor de cobertura. |
| **Factor de cobertura** | Coverage factor | k | Multiplicador para la incertidumbre expandida (típicamente $k=2$). |
| **Incertidumbre del participante** | Participant uncertainty | $u_{xi}$ | Incertidumbre del valor reportado por el participante. |
| **Incertidumbre del valor asignado** | Assigned value uncertainty | $u_{pt}$ | Incertidumbre del valor de referencia. |
| **Desviación objetivo** | Target deviation | $\sigma_{pt}$ | Desviación estándar objetivo para el PT. |
| **Propagación de incertidumbre** | Uncertainty propagation | - | Combinación de componentes de incertidumbre. |

---

## Términos Metrológicos

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Compatibilidad metrológica** | Metrological compatibility | - | Dos valores son compatibles si $|x_1 - x_2| \leq k \sqrt{u_1^2 + u_2^2}$. |
| **Estadístico D_2a** | D_2a statistic | $D_{2a}$ | Índice de compatibilidad metrológica. |
| **Estadístico D_2b** | D_2b statistic | $D_{2b}$ | Índice de compatibilidad alternativo. |
| **Trazabilidad** | Traceability | - | Propiedad de un resultado de medición relacionado con una referencia. |
| **Exactitud** | Accuracy | - | Cercanía de la medición al valor verdadero. |
| **Precisión** | Precision | - | Cercanía entre mediciones repetidas. |
| **Veracidad** | Trueness | - | Cercanía de la media al valor verdadero. |

---

## Términos de ANOVA

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Análisis de varianza** | Analysis of variance | ANOVA | Método estadístico para comparar medias. |
| **Suma de cuadrados** | Sum of squares | SS | Variación total en los datos. |
| **Grados de libertad** | Degrees of freedom | df | Número de valores independientes. |
| **Cuadrado medio** | Mean square | MS | $SS / df$. |
| **Valor F** | F-value | F | Relación de varianzas. |
| **Valor p** | p-value | p | Probabilidad de observar los datos si la hipótesis nula es verdadera. |

---

## Detección de Valores Atípicos

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Valor atípico** | Outlier | - | Dato significativamente diferente a los demás. |
| **Prueba de Grubbs** | Grubbs test | G | Prueba para un solo valor atípico. |
| **Prueba de Dixon** | Dixon test | Q | Prueba para valores atípicos en muestras pequeñas. |
| **Puntaje modificado** | Modified Z-score | M | Detección robusta de valores atípicos. |

---

## Términos de Clasificación

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Satisfactorio** | Satisfactory | - | $|z| \leq 2$ (para puntajes z). |
| **Cuestionable** | Questionable | - | $2 < |z| \leq 3$ (para puntajes z). |
| **No satisfactorio** | Unsatisfactory | - | $|z| > 3$ (para puntajes z). |
| **Aceptación** | Acceptance | - | El ítem cumple con los criterios de homogeneidad/estabilidad. |
| **Rechazo** | Rejection | - | El ítem no cumple con los criterios de homogeneidad/estabilidad. |

---

## Términos de Interfaz (UI)

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Pestaña** | Tab | - | Sección de navegación en la interfaz. |
| **Panel lateral** | Sidebar | - | Panel izquierdo para controles y entradas. |
| **Área principal** | Main panel | - | Panel derecho para salidas y visualizaciones. |
| **Entrada de datos** | Data input | - | Sección para cargar datos. |
| **Análisis** | Analysis | - | Proceso computacional sobre los datos. |
| **Informe** | Report | - | Documento generado con los resultados. |

---

## Contaminantes (Analitos)

| Español | Inglés | Fórmula Química | Unidades Típicas |
|---------|--------|-----------------|------------------|
| **Dióxido de azufre** | Sulfur dioxide | SO₂ | nmol/mol, μmol/mol |
| **Monóxido de carbono** | Carbon monoxide | CO | μmol/mol |
| **Ozono** | Ozone | O₃ | nmol/mol |
| **Óxido nítrico** | Nitric oxide | NO | nmol/mol |
| **Dióxido de nitrógeno** | Nitrogen dioxide | NO₂ | nmol/mol |
| **NOx** | Nitrogen oxides | NO + NO₂ | nmol/mol |

---

## Términos de Archivos y Datos

| Término en Español | Término en Inglés | Símbolo | Definición |
|--------------------|-------------------|---------|------------|
| **Formato largo** | Long format | - | Cada fila es una observación. |
| **Formato ancho** | Wide format | - | Cada fila es un participante. |
| **Archivo CSV** | CSV file | - | Archivo de valores separados por comas. |
| **Resumen** | Summary | - | Tabla de datos agregados. |
| **Réplica** | Replicate | - | Medición repetida de la misma muestra. |
| **Muestra** | Sample | - | Ítem de prueba individual en un lote. |

---

## Normas ISO

| Código de Norma | Nombre Completo | Contenido Clave |
|-----------------|-----------------|-----------------|
| **ISO 13528** | Métodos estadísticos para su uso en ensayos de aptitud | Algoritmo A, puntajes z, estadística robusta. |
| **ISO 17043** | Evaluación de la conformidad — Requisitos generales para los ensayos de aptitud | Diseño de esquemas de PT, criterios de calidad. |
| **ISO 5725** | Exactitud (veracidad y precisión) | Repetibilidad, reproducibilidad. |

---

## Símbolos de Fórmulas

| Símbolo | Significado | Contexto |
|---------|-------------|----------|
| $x_i$ | Valor reportado por el participante | General |
| $x_{pt}$ | Valor asignado | Puntajes |
| $x^*$ | Media robusta (Algoritmo A) | Estadística |
| $\sigma_{pt}$ | Desviación estándar objetivo | Puntajes |
| $s^*$ | Desviación estándar robusta | Estadística |
| $u_{xi}$ | Incertidumbre estándar del participante | Incertidumbre |
| $u_{pt}$ | Incertidumbre estándar del valor asignado | Incertidumbre |
| $u_{hom}$ | Incertidumbre de homogeneidad | Calidad |
| $u_{stab}$ | Incertidumbre de estabilidad | Calidad |
| $\nu_{eff}$ | Grados de libertad efectivos | Propagación de incertidumbre |
| $\alpha$ | Nivel de significancia | Estadística (comúnmente 0.05) |
| $k$ | Factor de cobertura | Incertidumbre (comúnmente 2) |

---

## Acrónimos Comunes

| Acrónimo | Nombre Completo | Contexto |
|----------|-----------------|----------|
| **PT** | Proficiency Testing (Ensayo de Aptitud) | General |
| **ANOVA** | Analysis of Variance (Análisis de Varianza) | Estadística |
| **IQR** | Interquartile Range (Rango Intercuartílico) | Estadística |
| **nIQR** | Normalized IQR (IQR Normalizado) | Estadística |
| **MADe** | Median Absolute Deviation (Desviación Absoluta de la Mediana) | Estadística |
| **CSV** | Comma-Separated Values (Valores Separados por Comas) | Formato de datos |
| **RMD** | RMarkdown | Documentación |
| **PTB** | Proficiency Testing Body (Organismo de Ensayos de Aptitud) | Organización |
| **CALAIRE** | Laboratorio de Calidad del Aire | Nombre del laboratorio |

---

## Referencias Cruzadas

Para información detallada sobre temas específicos:

- **Estadística Robusta**: [03_pt_robust_stats.md](03_pt_robust_stats.md)
- **Homogeneidad/Estabilidad**: [04_pt_homogeneity.md](04_pt_homogeneity.md)
- **Puntajes PT**: [05_pt_scores.md](05_pt_scores.md)
- **Formatos de Datos**: [01_carga_datos.md](01_carga_datos.md)
