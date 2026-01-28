# Glosario de Términos

Este glosario proporciona definiciones y traducciones (español/inglés) para los términos utilizados en el aplicativo de ensayos de aptitud (PT), el paquete `ptcalc` y la documentación asociada.

---

## 1. Conceptos Fundamentales

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Ensayo de aptitud | Proficiency testing (PT) | PT | Evaluación del desempeño de los participantes con respecto a criterios preestablecidos mediante comparaciones interlaboratorio. |
| Interlaboratorio | Interlaboratory | - | Comparación entre múltiples laboratorios. |
| Participante | Participant | - | Laboratorio o entidad que envía resultados para su evaluación. |
| Proveedor de PT | PT provider | - | Organización que lleva a cabo el ensayo de aptitud. |
| Organismo de Ensayos de Aptitud | Proficiency Testing Body | PTB | La organización responsable del esquema de PT. |

---

## 2. Mediciones y Datos

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Analito | Pollutant / Analyte | - | La especie de gas específica o sustancia que se está analizando (ej. CO, SO2, NO, etc.). |
| Nivel | Level | - | Nivel de concentración del analito (ej. bajo, medio, alto). |
| Muestra | Sample | - | Ítem físico que se está midiendo. |
| Ítem de ensayo de aptitud | PT item | g | Unidad de muestra individual para el ensayo, a menudo utilizada en estudios de homogeneidad. |
| Réplica | Replicate | - | Medición repetida sobre la misma muestra o ítem. |
| Valor | Value | x | Resultado de la concentración medida. |
| Valor reportado | Reported value | $x_i$ | Valor enviado por un participante para su evaluación. |
| Media | Mean | $\bar{x}$ | Promedio aritmético de los valores. |
| Mediana | Median | $\tilde{x}$ | Valor central cuando los datos están ordenados. |
| Desviación estándar | Standard deviation | s, $\sigma$ | Medida de la dispersión o variabilidad de los datos. |
| Varianza | Variance | $s^2$ | Cuadrado de la desviación estándar. |
| Formato largo | Long format | - | Estructura de datos donde cada fila representa una sola observación. |
| Formato ancho | Wide format | - | Estructura de datos donde cada fila representa un participante con múltiples columnas para contaminantes/niveles. |

---

## 3. Valor Asignado

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Valor asignado | Assigned value | $x_{pt}$ | Valor de referencia utilizado para evaluar los resultados de los participantes. |
| Valor de referencia | Reference value | $x_{ref}$ | Valor determinado por un laboratorio de referencia o mediante formulación. |
| Valor de consenso | Consensus value | $x^*$ | Media robusta derivada de los resultados de los participantes. |
| Laboratorio de referencia | Reference laboratory | - | Un laboratorio con alto nivel metrológico utilizado para determinar el valor asignado. |
| Incertidumbre del valor asignado | Assigned value uncertainty | $u_{xpt}$ | Incertidumbre estándar asociada al valor asignado. |

---

## 4. Estadísticos Robustos

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Estadístico robusto | Robust statistic | - | Un estimador resistente a la influencia de valores atípicos (outliers). |
| Algoritmo A | Algorithm A | - | Método de estimación robusta iterativa descrito en la norma ISO 13528, Anexo C. |
| Media robusta | Robust mean | $x^*$ | Media calculada utilizando estadísticas robustas (ej. Algoritmo A) para minimizar la influencia de valores atípicos. |
| Desviación estándar robusta | Robust standard deviation | $s^*$ | Desviación estándar calculada utilizando estadísticas robustas. |
| nIQR | Normalized IQR | nIQR | $0.7413 \times IQR$, una estimación robusta de la desviación estándar. |
| MADe | Scaled MAD | MADe | $1.483 \times MAD$, una estimación robusta de la desviación estándar. |
| Rango intercuartílico | Interquartile range | IQR | Diferencia entre el tercer y el primer cuartil ($Q_3 - Q_1$). |
| Desviación absoluta mediana | Median absolute deviation | MAD | Mediana de las desviaciones absolutas respecto a la mediana: $\text{median}(|x_i - \text{median}|)$. |
| Peso | Weight | w | Factor de influencia asignado a cada observación en el Algoritmo A. |
| Convergencia | Convergence | - | El punto donde los cálculos iterativos se estabilizan. |

---

## 5. Homogeneidad y Estabilidad

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Homogeneidad | Homogeneity | - | Uniformidad de las propiedades entre diferentes unidades (ítems) en un lote. |
| Estabilidad | Stability | - | Constancia de las propiedades de un material durante un período específico. |
| Desviación entre muestras | Between-sample std dev | $s_s$ | Componente de variación atribuido a las diferencias entre ítems. |
| Desviación intra-muestra | Within-sample std dev | $s_w$ | Componente de variación atribuido a la repetibilidad de la medición dentro de los ítems. |
| Varianza entre muestras | Between-sample variance | $s_s^2$ | Cuadrado de la desviación estándar entre muestras. |
| Varianza dentro de las muestras | Within-sample variance | $s_w^2$ | Cuadrado de la desviación estándar dentro de las muestras. |
| Criterio de homogeneidad | Homogeneity criterion | c | Límite de aceptación, típicamente definido como $0.3 \times \sigma_{pt}$. |
| Criterio expandido | Expanded criterion | $c_{exp}$ | Umbral calculado teniendo en cuenta la incertidumbre de la medición: $\sqrt{c^2 \times 1.88 + s_w^2 \times 1.01}$. |
| Incertidumbre de homogeneidad | Homogeneity uncertainty | $u_{hom}$ | Contribución de la incertidumbre derivada de una posible falta de homogeneidad. |
| Incertidumbre de estabilidad | Stability uncertainty | $u_{stab}$ | Contribución de la incertidumbre derivada de una posible inestabilidad. |
| Diferencia hom-estab | Hom-stab difference | D | Diferencia absoluta entre las medias de homogeneidad y estabilidad: $|\bar{y}_{hom} - \bar{y}_{stab}|$. |
| Aceptación | Acceptance | - | Condición en la que un ítem cumple con los criterios de homogeneidad o estabilidad. |
| Rechazo | Rejection | - | Condición en la que un ítem no cumple con los criterios de homogeneidad o estabilidad. |

---

## 6. Puntajes de Desempeño

| Español | Inglés | Símbolo | Fórmula | Caso de Uso |
|---------|---------|--------|---------|----------|
| Puntaje | Score | - | Medida cuantitativa utilizada para evaluar el desempeño de un participante. |
| Puntaje z | z-score | z | $(x - x_{pt}) / \sigma_{pt}$ | Evalúa la desviación relativa a $\sigma_{pt}$. |
| Puntaje z prima | z'-score | z' | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + u_{xpt}^2}$ | Se usa cuando la incertidumbre del valor asignado es significativa. |
| Puntaje zeta | zeta-score | $\zeta$ | $(x - x_{pt}) / \sqrt{u_x^2 + u_{xpt}^2}$ | Compara resultados utilizando la incertidumbre reportada por el propio participante. |
| Número normalizado | En number | $E_n$ | $(x - x_{pt}) / \sqrt{U_x^2 + U_{xpt}^2}$ | Se usa para comparar resultados con incertidumbres expandidas (k=2). |
| Puntaje Q | Q score | Q | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + s_i^2}$ | Método de puntuación alternativo. |
| Desviación típica para aptitud | Std dev for proficiency | $\sigma_{pt}$ | Dispersión objetivo utilizada para evaluar el desempeño. |
| Desviación objetivo | Target deviation | $\sigma_{pt}$ | Otro nombre para la desviación estándar para la evaluación de la aptitud. |

---

## 7. Evaluación y Clasificación de Puntajes

### Niveles de Desempeño
| Español | Inglés | Criterio | Descripción |
|---------|---------|-----------|-------------|
| Satisfactorio | Satisfactory | $|z| \leq 2$ o $|E_n| \leq 1$ | El desempeño se considera aceptable. |
| Cuestionable | Questionable | $2 < |z| < 3$ | El desempeño proporciona una señal de advertencia. |
| No satisfactorio | Unsatisfactory | $|z| \geq 3$ o $|E_n| > 1$ | El desempeño se considera inaceptable (se requiere acción). |

---

## 8. Términos Estadísticos

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Análisis de varianza | Analysis of variance | ANOVA | Método estadístico para comparar medias y particionar la varianza. |
| Grados de libertad | Degrees of freedom | df, gl | Número de valores independientes utilizados en un cálculo. |
| Grado de libertad efectivo | Effective degrees of freedom | $\nu_{eff}$ | Valor utilizado en la propagación de la incertidumbre (Welch-Satterthwaite). |
| Suma de cuadrados | Sum of squares | SS | Suma de las desviaciones al cuadrado de la media. |
| Media de cuadrados | Mean square | MS | Suma de cuadrados dividida por los grados de libertad. |
| Valor F | F-value | F | Relación de varianzas utilizada en el ANOVA. |
| Valor p | p-value | p | Probabilidad de observar el resultado si la hipótesis nula es verdadera. |
| Nivel de significancia | Significance level | $\alpha$ | Probabilidad de rechazar la hipótesis nula cuando es verdadera (comúnmente 0.05). |
| Prueba t | t-test | t | Prueba estadística utilizada para comparar dos medias. |

---

## 9. Términos de Incertidumbre

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Incertidumbre | Uncertainty | u(x) | Parámetro que caracteriza la dispersión de los valores atribuidos a una medición. |
| Incertidumbre estándar | Standard uncertainty | u | Incertidumbre expresada como una desviación estándar (k=1). |
| Incertidumbre expandida | Expanded uncertainty | U | Incertidumbre estándar multiplicada por un factor de cobertura (usualmente k=2). |
| Factor de cobertura | Coverage factor | k | Multiplicador utilizado para obtener la incertidumbre expandida. |
| Incertidumbre del participante | Participant uncertainty | $u_x$ | Incertidumbre estándar del valor reportado por el participante. |
| Propagación de incertidumbre | Uncertainty propagation | - | Método para combinar componentes de incertidumbre individuales. |

---

## 10. Términos Metrológicos

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Compatibilidad metrológica | Metrological compatibility | - | Acuerdo entre los resultados de la medición donde su diferencia está dentro de los límites de incertidumbre. |
| Trazabilidad | Traceability | - | Propiedad del resultado de una medición que lo relaciona con una referencia mediante una cadena de calibraciones. |
| Exactitud | Accuracy | - | Grado de concordancia entre un valor medido y un valor verdadero. |
| Precisión | Precision | - | Grado de concordancia entre mediciones repetidas. |
| Veracidad | Trueness | - | Grado de concordancia entre el promedio de infinitas mediciones y un valor de referencia. |
| Estadístico D2a | D2a statistic | $D_{2a}$ | Índice para evaluar la compatibilidad metrológica. |
| Estadístico D2b | D2b statistic | $D_{2b}$ | Índice alternativo para la compatibilidad metrológica. |

---

## 11. Detección de Valores Atípicos

| Español | Inglés | Símbolo | Definición |
|---------|---------|--------|------------|
| Valor atípico | Outlier | - | Una observación que parece desviarse marcadamente de los otros miembros de la muestra. |
| Prueba de Grubbs | Grubbs test | G | Prueba estadística para detectar un solo valor atípico en un conjunto de datos. |
| Prueba de Dixon | Dixon test | Q | Prueba estadística para valores atípicos en tamaños de muestra pequeños. |
| Puntaje z modificado | Modified z-score | M | Método robusto de detección de valores atípicos basado en la mediana y la MAD. |

---

## 12. Términos de Interfaz (UI)

| Español | Inglés | Contexto |
|---------|---------|---------|
| Carga de datos | Data loading | Pestaña o sección para subir archivos. |
| Ejecutar análisis | Run analysis | Botón para activar los cálculos. |
| Calcular puntajes | Calculate scores | Cálculo del desempeño de los participantes. |
| Generar informe | Generate report | Exportación de resultados a Word/HTML. |
| Archivo de homogeneidad | Homogeneity file | Archivo CSV con datos de estabilidad. |
| Archivo de estabilidad | Stability file | Archivo CSV con datos de estabilidad. |
| Archivos resumen | Summary files | Archivos CSV con resultados de los participantes. |
| Informe global | Global report | Vista resumen de todos los resultados y niveles. |
| Detalle por participante | Participant detail | Desglose individual del desempeño. |
| Pestaña | Tab | Elemento de navegación en la interfaz de usuario. |
| Panel lateral | Sidebar | Área de control a la izquierda. |
| Área principal | Main panel | Área de visualización de contenido. |

---

## 13. Contaminantes

| Español | Inglés | Fórmula | Unidades Típicas |
|---------|---------|---------|---------------|
| Monóxido de carbono | Carbon monoxide | CO | μmol/mol (ppm) |
| Dióxido de azufre | Sulfur dioxide | $SO_2$ | nmol/mol (ppb) |
| Monóxido de nitrógeno | Nitric oxide | NO | nmol/mol (ppb) |
| Dióxido de nitrógeno | Nitrogen dioxide | $NO_2$ | nmol/mol (ppb) |
| Óxidos de nitrógeno | Nitrogen oxides | $NO_x$ | nmol/mol (ppb) |
| Ozono | Ozone | $O_3$ | nmol/mol (ppb) |

---

## 14. Unidades

| Español | Inglés | Símbolo | Descripción |
|---------|---------|--------|-------------|
| micromol/mol | micromole/mole | μmol/mol | Relación de mezcla molar, equivalente a partes por millón (ppm). |
| nanomol/mol | nanomole/mole | nmol/mol | Relación de mezcla molar, equivalente a partes por billón (ppb). |
| partes por millón | parts per million | ppm | Relación de volumen o molar ($10^{-6}$). |
| partes por billón | parts per billion | ppb | Relación de volumen o molar ($10^{-9}$). |

---

## 15. Normas ISO

| Norma | Título | Contenido Clave |
|----------|-------|-------------|
| ISO 13528:2022 | Statistical methods for use in proficiency testing | Algoritmos robustos (Algoritmo A), métodos de puntuación, criterios de homogeneidad/estabilidad. |
| ISO 17043:2024 | Conformity assessment — General requirements for PT | Requisitos para el diseño del esquema de PT, gestión y competencia técnica. |
| ISO 5725 | Accuracy (trueness and precision) of measurement methods | Procedimientos para determinar la repetibilidad y reproducibilidad. |
| ISO/IEC 17025 | General requirements for the competence of laboratories | Estándares de acreditación para laboratorios de ensayo y calibración. |
| GUM (JCGM 100) | Guide to the expression of uncertainty in measurement | Marco internacional para evaluar la incertidumbre de la medición. |

---

## 16. Columnas de Archivos

| Columna en Español | Columna en Inglés | Tipo de Dato | Descripción |
|----------------|----------------|-----------|-------------|
| pollutant | pollutant | character | Código del contaminante (co, so2, etc.) |
| level | level | character | Nombre del nivel de concentración |
| replicate | replicate | integer | Índice de la réplica de medición |
| value | value | numeric | Valor de concentración medido |
| sample_id | sample_id | integer | Identificador único para el ítem de la muestra |
| participant_id | participant_id | character | Identificador único para el participante |
| mean_value | mean_value | numeric | Valor promedio reportado por el participante |
| sd_value | sd_value | numeric | Desviación estándar reportada por el participante |
| n_lab | n_lab | integer | Número de participantes en el esquema |

---

## 17. Acrónimos Comunes

| Acrónimo | Nombre Completo | Contexto |
|---------|-----------|---------|
| PT | Proficiency Testing | Campo de actividad general. |
| ANOVA | Analysis of Variance | Procesamiento estadístico. |
| IQR | Interquartile Range | Medida de dispersión robusta. |
| nIQR | Normalized IQR | Medida de dispersión estandarizada. |
| MAD | Median Absolute Deviation | Medida de dispersión robusta. |
| MADe | Scaled/Normalized MAD | Medida de dispersión estandarizada. |
| CSV | Comma-Separated Values | Formato de archivo de datos. |
| RMD | RMarkdown | Formato de generación de documentos. |
| MU | Measurement Uncertainty | Concepto general de incertidumbre. |
| CALAIRE | Laboratorio de Calidad del Aire | Nombre del laboratorio de referencia. |

---

## 18. Símbolos de Fórmulas

| Símbolo | Significado | Contexto |
|--------|---------|---------|
| $x_i$ | Valor reportado por el participante | Puntuación del desempeño |
| $x_{pt}$ | Valor asignado | Puntuación del desempeño |
| $x^*$ | Media robusta (Algoritmo A) | Estadísticas robustas |
| $\sigma_{pt}$ | Desviación estándar objetivo | Puntuación del desempeño |
| $s^*$ | Desviación estándar robusta | Estadísticas robustas |
| $u_{xi}$ | Incertidumbre estándar del participante | Incertidumbre |
| $u_{pt}$ | Incertidumbre estándar del valor asignado | Incertidumbre |
| $u_{hom}$ | Incertidumbre de homogeneidad | Criterios de calidad |
| $u_{stab}$ | Incertidumbre de estabilidad | Criterios de calidad |
| $\nu_{eff}$ | Grados de libertad efectivos | Propagación de la incertidumbre |
| $\alpha$ | Nivel de significancia | Pruebas estadísticas |
| k | Factor de cobertura | Incertidumbre (usualmente k=2) |

---

## 19. Referencias Cruzadas

Para información detallada sobre temas específicos:

- **Estadísticas Robustas**: [03_estadisticas_robustas_pt.md](03_estadisticas_robustas_pt.md)
- **Homogeneidad/Estabilidad**: [04_homogeneidad_pt.md](04_homogeneidad_pt.md)
- **Puntajes PT**: [05_puntajes_pt.md](05_puntajes_pt.md)
- **Compatibilidad Metrológica**: [08_compatibilidad.md](08_compatibilidad.md)
- **Formatos de Datos**: [01_carga_datos.md](01_carga_datos.md)
