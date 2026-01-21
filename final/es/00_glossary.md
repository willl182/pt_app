# Glosario de Términos

Este glosario proporciona definiciones y traducciones (español/inglés) para los términos utilizados en la aplicación de ensayos de aptitud (PT), el paquete `ptcalc` y la documentación asociada.

---

## 1. Conceptos Fundamentales

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Ensayo de aptitud | Proficiency testing (PT) | PT | Evaluación del desempeño de los participantes con respecto a criterios establecidos mediante comparaciones interlaboratorio. |
| Interlaboratorio | Interlaboratory | - | Comparación entre múltiples laboratorios. |
| Participante | Participant | - | Laboratorio o entidad que envía resultados para su evaluación. |
| Proveedor de PT | PT provider | - | Organización que realiza el ensayo de aptitud. |
| Organismo de Ensayos de Aptitud | Proficiency Testing Body | PTB | La organización responsable del esquema de PT. |

---

## 2. Mediciones y Datos

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Analito | Pollutant / Analyte | - | La especie gaseosa o sustancia específica que se analiza (por ejemplo, CO, SO2, NO, etc.). |
| Nivel | Level | - | Nivel de concentración del analito (por ejemplo, bajo, medio, alto). |
| Muestra | Sample | - | Ítem físico que se mide. |
| Ítem de ensayo de aptitud | PT item | g | Unidad de muestra individual para el ensayo, a menudo utilizada en estudios de homogeneidad. |
| Réplica | Replicate | - | Medición repetida en la misma muestra o ítem. |
| Valor | Value | x | Resultado de la concentración medida. |
| Valor reportado | Reported value | $x_i$ | Valor enviado por un participante para su evaluación. |
| Media | Mean | $\bar{x}$ | Promedio aritmético de los valores. |
| Mediana | Median | $\tilde{x}$ | Valor central cuando se ordenan los datos. |
| Desviación estándar | Standard deviation | s, $\sigma$ | Medida de dispersión o propagación de los datos. |
| Varianza | Variance | $s^2$ | Cuadrado de la desviación estándar. |
| Formato largo | Long format | - | Estructura de datos donde cada fila representa una sola observación. |
| Formato ancho | Wide format | - | Estructura de datos donde cada fila representa un participante con múltiples columnas para contaminantes/niveles. |

---

## 3. Valor Asignado

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Valor asignado | Assigned value | $x_{pt}$ | Valor de referencia utilizado para evaluar los resultados de los participantes. |
| Valor de referencia | Reference value | $x_{ref}$ | Valor determinado por un laboratorio de referencia o mediante formulación. |
| Valor de consenso | Consensus value | $x^*$ | Media robusta derivada de los resultados de los participantes. |
| Laboratorio de referencia | Reference laboratory | - | Un laboratorio con alto nivel metrológico utilizado para determinar el valor asignado. |
| Incertidumbre del valor asignado | Assigned value uncertainty | $u_{xpt}$ | Incertidumbre estándar asociada al valor asignado. |

---

## 4. Estadísticos Robustos

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Estadístico robusto | Robust statistic | - | Un estimador resistente a la influencia de los valores atípicos. |
| Algoritmo A | Algorithm A | - | Método de estimación robusto iterativo descrito en el Anexo C de la norma ISO 13528. |
| Media robusta | Robust mean | $x^*$ | Media calculada utilizando estadísticos robustos (por ejemplo, Algoritmo A) para minimizar la influencia de los valores atípicos. |
| Desviación estándar robusta | Robust standard deviation | $s^*$ | Desviación estándar calculada utilizando estadísticos robustos. |
| nIQR | Normalized IQR | nIQR | `$0.7413 \times IQR$` , una estimación robusta de la desviación estándar. |
| MADe | Scaled MAD | MADe | `$1.483 \times MAD$`, una estimación robusta de la desviación estándar. |
| Rango intercuartílico | Interquartile range | IQR | Diferencia entre el tercer y primer cuartil ($Q_3 - Q_1$). |
| Desviación absoluta mediana | Median absolute deviation | MAD | Mediana de las desviaciones absolutas respecto a la mediana: $\text{median}(|x_i - \text{median}|)$. |
| Peso | Weight | w | Factor de influencia asignado a cada observación en el Algoritmo A. |
| Convergencia | Convergence | - | El punto donde los cálculos iterativos se estabilizan. |

---

## 5. Homogeneidad y Estabilidad

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Homogeneidad | Homogeneity | - | Uniformidad de las propiedades en las diferentes unidades (ítems) de un lote. |
| Estabilidad | Stability | - | Constancia de las propiedades de un material durante un periodo especificado. |
| Desviación entre muestras | Between-sample std dev | $s_s$ | Componente de variación atribuido a las diferencias entre ítems. |
| Desviación intra-muestra | Within-sample std dev | $s_w$ | Componente de variación atribuido a la repetibilidad de la medición dentro de los ítems. |
| Varianza entre muestras | Between-sample variance | $s_s^2$ | Cuadrado de la desviación estándar entre muestras. |
| Varianza dentro de las muestras | Within-sample variance | $s_w^2$ | Cuadrado de la desviación estándar dentro de las muestras. |
| Criterio de homogeneidad | Homogeneity criterion | c | Límite de aceptación, típicamente definido como $0.3 \times \sigma_{pt}$. |
| Criterio expandido | Expanded criterion | $c_{exp}$ | Umbral calculado teniendo en cuenta la incertidumbre de medida: $\sqrt{c^2 \times 1.88 + s_w^2 \times 1.01}$. |
| Incertidumbre de homogeneidad | Homogeneity uncertainty | $u_{hom}$ | Contribución de incertidumbre derivada de una posible falta de homogeneidad. |
| Incertidumbre de estabilidad | Stability uncertainty | $u_{stab}$ | Contribución de incertidumbre derivada de una posible inestabilidad. |
| Diferencia hom-estab | Hom-stab difference | D | Diferencia absoluta entre las medias de homogeneidad y estabilidad: $|\bar{y}_{hom} - \bar{y}_{stab}|$. |
| Aceptación | Acceptance | - | Condición en la que un ítem cumple con los criterios de homogeneidad o estabilidad. |
| Rechazo | Rejection | - | Condición en la que un ítem no cumple con los criterios de homogeneidad o estabilidad. |

---

## 6. Puntajes de Desempeño

| Término (ES) | Término (EN) | Símbolo | Fórmula | Caso de Uso |
|--------------|--------------|---------|---------|-------------|
| Puntaje | Score | - | Medida cuantitativa utilizada para evaluar el desempeño de los participantes. |
| Puntaje z | z-score | z | $(x - x_{pt}) / \sigma_{pt}$ | Evalúa la desviación relativa a $\sigma_{pt}$. |
| Puntaje z prima | z'-score | z' | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + u_{xpt}^2}$ | Se utiliza cuando la incertidumbre del valor asignado es significativa. |
| Puntaje zeta | zeta-score | $\zeta$ | $(x - x_{pt}) / \sqrt{u_x^2 + u_{xpt}^2}$ | Compara los resultados utilizando la propia incertidumbre reportada por el participante. |
| Número normalizado | En number | $E_n$ | $(x - x_{pt}) / \sqrt{U_x^2 + U_{xpt}^2}$ | Se utiliza para comparar resultados con incertidumbres expandidas (k=2). |
| Puntaje Q | Q score | Q | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + s_i^2}$ | Método de puntuación alternativo. |
| Desviación típica para aptitud | Std dev for proficiency | $\sigma_{pt}$ | Dispersión objetivo utilizada para evaluar el desempeño. |
| Desviación objetivo | Target deviation | $\sigma_{pt}$ | Otro nombre para la desviación estándar para la evaluación de la aptitud. |

---

## 7. Evaluación y Clasificación de Puntajes

### Niveles de Desempeño
| Término (ES) | Término (EN) | Criterio | Descripción |
|--------------|--------------|-----------|-------------|
| Satisfactorio | Satisfactory | $|z| \leq 2$ o $|E_n| \leq 1$ | El desempeño se considera aceptable. |
| Cuestionable | Questionable | $2 < |z| < 3$ | El desempeño proporciona una señal de advertencia. |
| No satisfactorio | Unsatisfactory | $|z| \geq 3$ o $|E_n| > 1$ | El desempeño se considera inaceptable (se requiere acción). |

### Clasificación Combinada (a1-a7)
| Código | Término (ES) | Término (EN) | Descripción |
|------|--------------|--------------|-------------|
| a1 | Totalmente satisfactorio | Fully satisfactory | Tanto z como En son satisfactorios. |
| a2 | Satisfactorio pero conservador | Satisfactory but conservative | z es satisfactorio, pero En es muy pequeño (la incertidumbre de medida puede estar sobreestimada). |
| a3 | Satisfactorio con MU subestimada | Satisfactory with underestimated MU | z es satisfactorio, pero En no es satisfactorio (la incertidumbre de medida es probablemente demasiado pequeña). |
| a4 | Cuestionable pero aceptable | Questionable but acceptable | z es cuestionable, pero En es satisfactorio. |
| a5 | Cuestionable e inconsistente | Questionable and inconsistent | Tanto z como En muestran problemas (advertencia). |
| a6 | No satisfactorio pero MU cubre | Unsatisfactory but MU covers | z no es satisfactorio, pero En es satisfactorio debido a una gran incertidumbre de medida. |
| a7 | No satisfactorio (crítico) | Unsatisfactory (critical) | Tanto z como En no son satisfactorios. |

---

## 8. Términos Estadísticos

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Análisis de varianza | Analysis of variance | ANOVA | Método estadístico para comparar medias y particionar la varianza. |
| Grados de libertad | Degrees of freedom | df, gl | Número de valores independientes utilizados en un cálculo. |
| Grado de libertad efectivo | Effective degrees of freedom | $\nu_{eff}$ | Valor utilizado en la propagación de la incertidumbre (Welch-Satterthwaite). |
| Suma de cuadrados | Sum of squares | SS | Suma de las desviaciones al cuadrado respecto a la media. |
| Media de cuadrados | Mean square | MS | Suma de cuadrados dividida por los grados de libertad. |
| Valor F | F-value | F | Razón de varianzas utilizada en ANOVA. |
| Valor p | p-value | p | Probabilidad de observar el resultado si la hipótesis nula es verdadera. |
| Nivel de significancia | Significance level | $\alpha$ | Probabilidad de rechazar la hipótesis nula cuando es verdadera (comúnmente 0.05). |
| Prueba t | t-test | t | Prueba estadística utilizada para comparar dos medias. |

---

## 9. Términos de Incertidumbre

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Incertidumbre | Uncertainty | u(x) | Parámetro que caracteriza la dispersión de los valores atribuidos a una medición. |
| Incertidumbre estándar | Standard uncertainty | u | Incertidumbre expresada como una desviación estándar (k=1). |
| Incertidumbre expandida | Expanded uncertainty | U | Incertidumbre estándar multiplicada por un factor de cobertura (usualmente k=2). |
| Factor de cobertura | Coverage factor | k | Multiplicador utilizado para obtener la incertidumbre expandida. |
| Incertidumbre del participante | Participant uncertainty | $u_x$ | Incertidumbre estándar del valor reportado por el participante. |
| Propagación de incertidumbre | Uncertainty propagation | - | Método para combinar los componentes individuales de incertidumbre. |

---

## 10. Términos Metrológicos

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Compatibilidad metrológica | Metrological compatibility | - | Concordancia entre los resultados de medición donde su diferencia está dentro de los límites de incertidumbre. |
| Trazabilidad | Traceability | - | Propiedad de un resultado de medición que lo relaciona con una referencia a través de una cadena de calibraciones. |
| Exactitud | Accuracy | - | Cercanía de la concordancia entre un valor medido y un valor verdadero. |
| Precisión | Precision | - | Cercanía de la concordancia entre mediciones repetidas. |
| Veracidad | Trueness | - | Cercanía de la concordancia entre el promedio de infinitas mediciones y un valor de referencia. |
| Estadístico D2a | D2a statistic | $D_{2a}$ | Índice para evaluar la compatibilidad metrológica. |
| Estadístico D2b | D2b statistic | $D_{2b}$ | Índice alternativo para la compatibilidad metrológica. |

---

## 11. Detección de Valores Atípicos

| Término (ES) | Término (EN) | Símbolo | Definición |
|--------------|--------------|---------|------------|
| Valor atípico | Outlier | - | Una observación que parece desviarse marcadamente de los demás miembros de la muestra. |
| Prueba de Grubbs | Grubbs test | G | Prueba estadística para detectar un único valor atípico en un conjunto de datos. |
| Prueba de Dixon | Dixon test | Q | Prueba estadística para valores atípicos en tamaños de muestra pequeños. |
| Puntaje z modificado | Modified z-score | M | Método robusto de detección de valores atípicos basado en la mediana y el MAD. |

---

## 12. Términos de Interfaz

| Término (ES) | Término (EN) | Contexto |
|--------------|--------------|----------|
| Carga de datos | Data loading | Pestaña o sección para cargar archivos. |
| Ejecutar análisis | Run analysis | Botón para iniciar los cálculos. |
| Calcular puntajes | Calculate scores | Cálculo del desempeño de los participantes. |
| Generar informe | Generate report | Exportación de resultados a Word/HTML. |
| Archivo de homogeneidad | Homogeneity file | Archivo CSV con datos de homogeneidad. |
| Archivo de estabilidad | Stability file | Archivo CSV con datos de estabilidad. |
| Archivos resumen | Summary files | Archivos CSV con resultados de los participantes. |
| Informe global | Global report | Vista resumida de todos los resultados y niveles. |
| Detalle por participante | Participant detail | Desglose del desempeño individual. |
| Pestaña | Tab | Elemento de navegación en la interfaz de usuario. |
| Panel lateral | Sidebar | Área de control a la izquierda. |
| Área principal | Main panel | Área de visualización de contenido. |

---

## 13. Contaminantes

| Término (ES) | Término (EN) | Fórmula | Unidades Típicas |
|--------------|--------------|---------|------------------|
| Monóxido de carbono | Carbon monoxide | CO | μmol/mol (ppm) |
| Dióxido de azufre | Sulfur dioxide | $SO_2$ | nmol/mol (ppb) |
| Monóxido de nitrógeno | Nitric oxide | NO | nmol/mol (ppb) |
| Dióxido de nitrógeno | Nitrogen dioxide | $NO_2$ | nmol/mol (ppb) |
| Óxidos de nitrógeno | Nitrogen oxides | $NO_x$ | nmol/mol (ppb) |
| Ozono | Ozone | $O_3$ | nmol/mol (ppb) |

---

## 14. Unidades

| Término (ES) | Término (EN) | Símbolo | Descripción |
|--------------|--------------|---------|-------------|
| micromol/mol | micromole/mole | μmol/mol | Relación de mezcla molar, equivalente a partes por millón (ppm). |
| nanomol/mol | nanomole/mole | nmol/mol | Relación de mezcla molar, equivalente a partes por billón (ppb). |
| partes por millón | parts per million | ppm | Relación de volumen o molar ($10^{-6}$). |
| partes por billón | parts per billion | ppb | Relación de volumen o molar ($10^{-9}$). |

---

## 15. Normas ISO

| Norma | Título | Contenido Clave |
|-------|--------|-----------------|
| ISO 13528:2022 | Métodos estadísticos para su uso en ensayos de aptitud | Algoritmos robustos (Algoritmo A), métodos de puntuación, criterios de homogeneidad/estabilidad. |
| ISO 17043:2024 | Evaluación de la conformidad — Requisitos generales para los ensayos de aptitud | Requisitos para el diseño, gestión y competencia técnica de los esquemas de PT. |
| ISO 5725 | Exactitud (veracidad y precisión) de los métodos de medición | Procedimientos para determinar la repetibilidad y la reproducibilidad. |
| ISO/IEC 17025 | Requisitos generales para la competencia de los laboratorios | Estándares de acreditación para laboratorios de ensayo y calibración. |
| GUM (JCGM 100) | Guía para la expresión de la incertidumbre de medida | Marco internacional para la evaluación de la incertidumbre de medida. |

---

## 16. Columnas de Archivos

| Columna (ES) | Columna (EN) | Tipo de Dato | Descripción |
|--------------|--------------|--------------|-------------|
| pollutant | pollutant | character | Código del contaminante (co, so2, etc.) |
| level | level | character | Nombre del nivel de concentración |
| replicate | replicate | integer | Índice de réplica de la medición |
| value | value | numeric | Valor de concentración medido |
| sample_id | sample_id | integer | Identificador único para el ítem de muestra |
| participant_id | participant_id | character | Identificador único para el participante |
| mean_value | mean_value | numeric | Valor promedio reportado por el participante |
| sd_value | sd_value | numeric | Desviación estándar reportada por el participante |
| n_lab | n_lab | integer | Número de participantes en el esquema |

---

## 17. Acrónimos Comunes

| Acrónimo | Nombre Completo | Contexto |
|----------|-----------------|----------|
| PT | Proficiency Testing | Campo general de actividad. |
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
|---------|-------------|----------|
| $x_i$ | Valor reportado por el participante | Puntuación del desempeño |
| $x_{pt}$ | Valor asignado | Puntuación del desempeño |
| $x^*$ | Media robusta (Algoritmo A) | Estadísticos robustos |
| $\sigma_{pt}$ | Desviación estándar objetivo | Puntuación del desempeño |
| $s^*$ | Desviación estándar robusta | Estadísticos robustos |
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

- **Estadísticos Robustos**: [03_pt_robust_stats.md](../03_pt_robust_stats.md)
- **Homogeneidad/Estabilidad**: [04_pt_homogeneity.md](../04_pt_homogeneity.md)
- **Puntajes PT**: [05_pt_scores.md](../05_pt_scores.md)
- **Compatibilidad Metrológica**: [08_compatibilidad.md](../08_compatibilidad.md)
- **Formatos de Datos**: [01_carga_datos.md](../01_carga_datos.md)
