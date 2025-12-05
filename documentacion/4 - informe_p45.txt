1. ## 

2. ## 

3. ## 

4. ## **Resultados y Discusión**

   1. ### **Resumen General del Desempeño**

En esta ronda del EA, participaron 6 laboratorios, reportando 150 resultados para 5 ítems de ensayo (combinaciones de contaminante y nivel).

| Indicador | Evaluación | SO₂ | CO | O₃ | NO | NO₂ | TOTAL | TOTAL (%) |
| ----- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| z-score | Satisfactorio | 27 | 29 | 28 | 30 | 27 | 141 | 94.00% |
|  | Cuestionable | 2 | 1 | 1 | 0 | 1 | 5 | 3.33% |
|  | Insatisfactorio | 1 | 0 | 1 | 0 | 2 | 4 | 2.67% |
| En-score | Satisfactorio | 30 | 30 | 30 | 30 | 30 | 150 | 100.00% |
|  | Insatisfactorio | 0 | 0 | 0 | 0 | 0 | 0 | 0.00% |

2. ### **Evaluación por Contaminante**

A continuación, se presenta un resumen del desempeño para cada contaminante. Los resultados detallados por participante, incluyendo valores reportados, incertidumbres, valores asignados y puntuaciones, se encuentran en el Anexo C. 

1. #### **Resultados para SO₂**

| \[image\_score\_heatmap\_so2\] |  |
| :---- | :---- |
| Figura 6\. Mapa de Calor para las puntuaciones para el SO2 por participante |  |

Para la puntuación z en el dióxido de azufre, se presentaron 2 resultados insatisfactorios en las corridas de 60 nmol/mol y 140 nmol/mol y 1 cuestionable en la corrida de 100 nmol/mol, en 3 participantes. Para la puntuación En todos los resultados fueron satisfactorios.

2. #### **Resultados para CO**

| \[image\_score\_heatmap\_co\] |  |
| :---- | :---- |
| Figura 7\. Mapa de Calor para las puntuaciones para el CO por participante |  |

Para la puntuación z en el monóxido de carbono, se presentaron 1 resultado insatisfactorio en la corrida de 8-umol/mol, y los 2 cuestionables en la corrida de 6-umol/mol. Para la puntuación En todos los resultados fueron satisfactorios.

3. #### **Resultados para O₃**

| \[image\_score\_heatmap\_o3\] |  |
| :---- | :---- |
| Figura 8\. Mapa de Calor para las puntuaciones para el O3 por participante |  |

Para la puntuación z y el En en el ozono para todos los niveles y participantes todos los resultados fueron satisfactorios.

#### 

4. #### **Resultados para NO**

| \[image\_score\_heatmap\_no\] |  |
| :---- | :---- |
| Figura 9\. Mapa de Calor para las puntuaciones  para el NO por participante |  |

Para la puntuación z en el monóxido de nitrógeno, se presentó 1 resultado cuestionable en la corrida de 0-nmol/mol. Para la puntuación En todos los resultados fueron satisfactorios.

5. #### **Resultados para NO₂**

| \[image\_score\_heatmap\_no2\] |  |
| :---- | :---- |
| Figura 10\. Mapa de Calor para las puntuaciones para el NO2  por participante |  |

Para la puntuación z en el dióxido de nitrógeno, se presentaron 1 resultado insatisfactorio, y 1 cuestionable ambos en la corrida de 60-ppb. Para la puntuación En todos los resultados fueron satisfactorios.

## **5\. Conclusiones**

**Conformidad General:** El desempeño general de los laboratorios participantes en esta ronda fue positivo con un 94% de resultados satisfactorios según el criterio z-score.

**Áreas de Preocupación:** Se observaron desempeños cuestionables o insatisfactorios principalmente en el participante 1 con dos resultados insatisfactorios, el participante 2 con un resultados insatisfactorio y cuestionable.   
**Acciones Sugeridas para Participantes:**  
Se recomienda a los laboratorios con resultados **Cuestionables** ($2.0 \< |z| \< 3.0$) investigar las posibles causas de la desviación.  
Se requiere a los laboratorios con resultados **Insatisfactorios** ($|z|≥ 3.0$) realizar una investigación exhaustiva de las causas raíz (e.g., calibración, procedimiento, equipo) e implementar acciones correctivas documentadas.   

## Actualización 2024-11-21
- Sincronizado con la lógica vigente en `app.R`, incluyendo el uso de Algoritmo A, las variantes de \u03c3_pt y los criterios de homogeneidad/estabilidad basados en las medianas robustas.
- Referencia cruzada con `reports/report_template.Rmd` para reflejar los parámetros YAML (pollutant, level, n_lab, k_factor y metrological_compatibility_method) utilizados al generar informes.
- Verificado que las descripciones mantienen consistencia con la interfaz Shiny y el flujo de cálculo de puntajes z, z', zeta y En.
