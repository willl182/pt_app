1. ## 

2. ## 

3. ## **Metodología de Evaluación de Desempeño**

La evaluación del desempeño de los participantes se realizó de acuerdo con los lineamientos de ISO 13528:2022, Cláusula 9, y P-PSEA-06.

1. ### **Desviación Estándar para Evaluación de Aptitud (σ)**

La desviación estándar para la evaluación de la aptitud (σ) se estableció para cada contaminante basándose en  ISO 13528:2022.

**Método Específico:** *Por consenso:* σpt \= s\*, donde s\* es la desviación estándar robusta calculada mediante el Algoritmo A. 

Los valores de σ\_pt calculados para cada nivel se presentan en el Anexo A.

2. ### **Indicadores de Desempeño y criterios de evaluación**

Se calcularon los siguientes indicadores de desempeño para cada resultado reportado x\_i por cada participante:

| Indicador | Evaluación |
| :---- | :---- |
| **Puntuación z/z’/zeta:** | |z| ≤ 2.0: **Satisfactorio** 2.0 \< |z| \< 3.0: **Cuestionable (Señal de Advertencia)** |z|≥ 3.0: **Insatisfactorio (Señal de Acción)** |
| **Puntuación** **En:**  | |E\_n| ≤ 1.0: **Satisfactorio** |E\_n| \> 1.0: **Insatisfactorio** |

### 

3. ### **Tratamiento Estadístico de Datos**

**Recepción y Validación:** Los resultados reportados por los participantes fueron recibidos a través del Aplicativo Web/Formulario y validados para verificar formato, unidades y completitud.

**Identificación de atípicos:** Se realizó una revisión de los datos para identificar posibles errores y atípicos, según ISO 13528:2022, 6.3.  
Para ello se llevó a cabo la prueba de Grubbs para atípicos, encontrando 2 valores, tal y como se presenta en la siguiente tabla:

| Contaminante | Nivel | Participantes Evaluados | Valor p | Atípicos detectados | Participante | Valor Atípico |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| CO | 0-umol/mol | 6 | 0.2594 | 0 | NA | NA |
| CO | 2-umol/mol | 6 | 0.3454 | 0 | NA | NA |
| CO | 4-umol/mol | 6 | 0.474 | 0 | NA | NA |
| CO | 6-umol/mol | 6 | 0.2644 | 0 | NA | NA |
| CO | 8-umol/mol | 6 | 0.039 | 1 | part\_1 | 8.029 |
| NO | 0-nmol/mol | 6 | 0.1344 | 0 | NA | NA |
| NO | 121-nmol/mol | 6 | 0.1879 | 0 | NA | NA |
| NO | 180-nmol/mol | 6 | 0.3358 | 0 | NA | NA |
| NO | 42-nmol/mol | 6 | 0.2846 | 0 | NA | NA |
| NO | 81-nmol/mol | 6 | 0.3787 | 0 | NA | NA |
| NO2 | 0-nmol/mol | 6 | 0.2833 | 0 | NA | NA |
| NO2 | 120-nmol/mol | 6 | 0.2611 | 0 | NA | NA |
| NO2 | 30-nmol/mol | 6 | 0.2461 | 0 | NA | NA |
| NO2 | 60-nmol/mol | 6 | 0.0632 | 0 | NA | NA |
| NO2 | 90-nmol/mol | 6 | 0.3341 | 0 | NA | NA |
| O3 | 0-nmol/mol | 6 | 0.5668 | 0 | NA | NA |
| O3 | 120-nmol/mol | 6 | 0.347 | 0 | NA | NA |
| O3 | 180-nmol/mol | 6 | 0.4403 | 0 | NA | NA |
| O3 | 40-nmol/mol | 6 | 0.5479 | 0 | NA | NA |
| O3 | 80-nmol/mol | 6 | 0.2855 | 0 | NA | NA |
| SO2 | 0-nmol/mol | 6 | 0.5048 | 0 | NA | NA |
| SO2 | 100-nmol/mol | 6 | 0.0863 | 0 | NA | NA |
| SO2 | 140-nmol/mol | 6 | 0.0551 | 0 | NA | NA |
| SO2 | 180-nmol/mol | 6 | 0.2462 | 0 | NA | NA |
| SO2 | 60-nmol/mol | 6 | 0.0294 | 1 | part\_1 | 59.905 |

4. ## 

5. ## 


## Actualización 2024-11-21
- Sincronizado con la lógica vigente en `app.R`, incluyendo el uso de Algoritmo A, las variantes de \u03c3_pt y los criterios de homogeneidad/estabilidad basados en las medianas robustas.
- Referencia cruzada con `reports/report_template.Rmd` para reflejar los parámetros YAML (pollutant, level, n_lab, k_factor y metrological_compatibility_method) utilizados al generar informes.
- Verificado que las descripciones mantienen consistencia con la interfaz Shiny y el flujo de cálculo de puntajes z, z', zeta y En.
