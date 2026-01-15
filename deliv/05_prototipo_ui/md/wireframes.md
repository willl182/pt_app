# Prototipo de Interfaz de Usuario - Wireframes

Este documento describe la estructura de la interfaz de usuario del aplicativo para la evaluación de ensayos de aptitud, siguiendo los lineamientos de la norma ISO 13528:2022. El prototipo está implementado en `R/prototipo_ui.R` y es una copia fiel de la UI definida en `app.R`.

## 1. Carga de datos

- **Propósito**: Permitir al usuario cargar los archivos base necesarios para todos los cálculos del sistema.
- **Elementos de entrada (inputs)**:
  - `fileInput("hom_file")`: Cargar archivo homogeneity.csv
  - `fileInput("stab_file")`: Cargar archivo stability.csv
  - `fileInput("summary_files")`: Cargar múltiples archivos summary_n*.csv
- **Elementos de salida (outputs)**:
  - `verbatimTextOutput("data_upload_status")`: Estado de carga de los datos
- **Formato de archivos esperados**:
  - **homogeneity.csv**: columnas `pollutant, level, replicate, sample_id, value`
  - **stability.csv**: columnas `pollutant, level, replicate, sample_id, value`
  - **summary_n*.csv**: columnas `pollutant, level, participant_id, replicate, sample_group, mean_value, sd_value`
- **Contaminantes disponibles**: co, no, no2, o3, so2
- **Niveles disponibles (ejemplos)**:
  - co: 0-μmol/mol, 2-μmol/mol, 4-μmol/mol, 6-μmol/mol, 8-μmol/mol
  - no: 0-nmol/mol, 50-nmol/mol, 100-nmol/mol, 150-nmol/mol
  - no2: 0-nmol/mol, 50-nmol/mol, 100-nmol/mol, 150-nmol/mol
  - o3: 0-nmol/mol, 50-nmol/mol, 80-nmol/mol, 120-nmol/mol
  - so2: 0-nmol/mol, 50-nmol/mol, 100-nmol/mol, 150-nmol/mol

## 2. Análisis de homogeneidad y estabilidad

- **Propósito**: Evaluar si los ítems del ensayo de aptitud son suficientemente homogéneos y estables según los criterios de la norma ISO 13528:2022.
- **Elementos de entrada (inputs)**:
  - `actionButton("run_analysis")`: Ejecutar análisis
  - `uiOutput("pollutant_selector_analysis")`: Selector de contaminante
  - `uiOutput("level_selector")`: Selector de nivel
- **Pestañas de análisis**:
  1. **Vista previa de datos**:
     - `dataTableOutput("raw_data_preview")`: Datos de homogeneidad
     - `dataTableOutput("stability_data_preview")`: Datos de estabilidad
     - `plotlyOutput("results_histogram")`: Histograma
     - `plotlyOutput("results_boxplot")`: Boxplot
     - `verbatimTextOutput("validation_message")`: Mensaje de validación
  2. **Evaluación de homogeneidad**:
     - `uiOutput("homog_conclusion")`: Conclusión del criterio
     - `dataTableOutput("homogeneity_preview_table")`: Tabla de vista previa
     - `tableOutput("robust_stats_table")`: Estadísticos robustos
     - `verbatimTextOutput("robust_stats_summary")`: Resumen
     - `tableOutput("variance_components")`: Componentes de varianza
     - `tableOutput("details_per_item_table")`: Cálculos por ítem
     - `tableOutput("details_summary_stats_table")`: Estadísticos resumidos
  3. **Evaluación de estabilidad**:
     - `uiOutput("homog_conclusion_stability")`: Conclusión del criterio
     - `tableOutput("variance_components_stability")`: Componentes de varianza
     - `tableOutput("details_per_item_table_stability")`: Cálculos por ítem
     - `tableOutput("details_summary_stats_table_stability")`: Estadísticos resumidos
  4. **Contribuciones a la incertidumbre**:
     - `dataTableOutput("u_hom_table")`: Resumen u_hom por analito/nivel
     - `dataTableOutput("u_stab_table")`: Resumen u_stab por analito/nivel
- **Flujo de navegación**: Ubicado en el panel lateral principal. Los resultados se organizan en pestañas horizontales.

## 3. Valores atípicos

- **Propósito**: Identificar y visualizar resultados de participantes que se alejan significativamente del conjunto de datos mediante pruebas estadísticas.
- **Elementos de entrada (inputs)**:
  - `uiOutput("outliers_pollutant_selector")`: Selector de contaminante
  - `uiOutput("outliers_level_selector")`: Selector de nivel
- **Elementos de salida (outputs)**:
  - `dataTableOutput("grubbs_summary_table")`: Tabla resumen de la prueba de Grubbs
  - `plotlyOutput("outliers_histogram")`: Histograma con identificación de atípicos
  - `plotlyOutput("outliers_boxplot")`: Boxplot con identificación de atípicos
- **Flujo de navegación**: Módulo de consulta directa después de cargar los datos de participantes. Permite una revisión visual antes de proceder al cálculo del valor asignado.

## 4. Valor asignado

- **Propósito**: Determinar el valor de referencia y su incertidumbre utilizando diferentes métodos estadísticos.
- **Elementos de entrada (inputs)**:
  - `actionButton("algoA_run")`: Calcular Algoritmo A
  - `actionButton("consensus_run")`: Calcular valores consenso
  - `actionButton("run_metrological_compatibility")`: Calcular compatibilidad
  - `uiOutput("assigned_pollutant_selector")`: Selector de contaminante
  - `uiOutput("assigned_n_selector")`: Selector de esquema (n_lab)
  - `uiOutput("assigned_level_selector")`: Selector de nivel
  - `numericInput("algoA_max_iter")`: Iteraciones máximas para Algoritmo A
- **Pestañas de análisis**:
  1. **Algoritmo A**:
     - `uiOutput("algoA_result_summary")`: Resumen de resultados
     - `dataTableOutput("algoA_input_table")`: Datos de entrada
     - `plotlyOutput("algoA_histogram")`: Histograma de resultados
     - `dataTableOutput("algoA_iterations_table")`: Tabla de iteraciones
  2. **Valor consenso**:
     - `tableOutput("consensus_summary_table")`: Resumen del valor consenso
     - `dataTableOutput("consensus_input_table")`: Datos de participantes
  3. **Valor de referencia**:
     - `dataTableOutput("reference_table")`: Resultados de referencia
  4. **Compatibilidad Metrológica**:
     - `dataTableOutput("metrological_compatibility_table")`: Tabla de compatibilidad
- **Flujo de navegación**: Dividido en pestañas internas para cada método de asignación.

## 5. Puntajes PT

- **Propósito**: Calcular y mostrar los puntajes de desempeño de cada laboratorio participante.
- **Elementos de entrada (inputs)**:
  - `actionButton("scores_run")`: Calcular puntajes
  - `uiOutput("scores_pollutant_selector")`: Selector de contaminante
  - `uiOutput("scores_n_selector")`: Selector de esquema (n_lab)
  - `uiOutput("scores_level_selector")`: Selector de nivel
- **Elementos de salida (outputs)**:
  - `tableOutput("scores_parameter_table")`: Resumen de parámetros
  - `dataTableOutput("scores_overview_table")`: Tabla resumen de puntajes
  - `tableOutput("scores_evaluation_summary")`: Resumen de evaluaciones
- **Pestañas de análisis**:
  - "Resultados de puntajes"
  - "Puntajes Z": `uiOutput("z_scores_panel")`
  - "Puntajes Z'": `uiOutput("zprime_scores_panel")`
  - "Puntajes Zeta": `uiOutput("zeta_scores_panel")`
  - "Puntajes En": `uiOutput("en_scores_panel")`
- **Tipos de puntajes**:
  - z = (x - x_pt) / σ_pt
  - z' = (x - x_pt) / √(σ_pt² + u_xpt²)
  - ζ = (x - x_pt) / √(u_x² + u_xpt²)
  - E_n = (x - x_pt) / √(U_x² + U_xpt²)
- **Criterios de evaluación**:
  - z, z', ζ: |valor| ≤ 2 → Satisfactorio; 2 < |valor| < 3 → Cuestionable; |valor| ≥ 3 → No satisfactorio
  - E_n: |valor| ≤ 1 → Satisfactorio; |valor| > 1 → No satisfactorio
- **Flujo de navegación**: Requiere que se hayan ejecutado los cálculos de valor asignado previamente.

## 6. Informe global

- **Propósito**: Proporcionar una visión integral de los resultados de todos los analitos y niveles en una sola interfaz.
- **Elementos de entrada (inputs)**:
  - `uiOutput("global_report_pollutant_selector")`: Selector de contaminante
  - `uiOutput("global_report_n_selector")`: Selector de esquema
  - `uiOutput("global_report_level_selector")`: Selector de nivel
- **Pestañas de análisis**:
  1. **Resumen global**:
     - `dataTableOutput("global_xpt_summary_table")`: Resumen x_pt
     - `tableOutput("global_level_summary_table")`: Resumen de niveles
     - `dataTableOutput("global_evaluation_summary_table")`: Resumen de evaluaciones
  2. **Referencia (1)**:
     - `tableOutput("global_params_ref")`: Parámetros principales
     - `dataTableOutput("global_overview_ref")`: Resultados por participante
     - `plotlyOutput("global_heatmap_z_ref")`: Heatmap de puntajes Z
     - `plotlyOutput("global_heatmap_zprime_ref")`: Heatmap de puntajes Z'
     - `plotlyOutput("global_heatmap_zeta_ref")`: Heatmap de puntajes Zeta
     - `plotlyOutput("global_heatmap_en_ref")`: Heatmap de puntajes En
  3. **Consenso MADe (2a)**:
     - Similar estructura con datos de consenso MADe
  4. **Consenso nIQR (2b)**:
     - Similar estructura con datos de consenso nIQR
  5. **Algoritmo A (3)**:
     - Similar estructura con datos de Algoritmo A
- **Flujo de navegación**: Centraliza la información de múltiples niveles y métodos (Referencia, Consenso MADe/nIQR, Algoritmo A).

## 7. Participantes

- **Propósito**: Mostrar el detalle individual de cada laboratorio y su desempeño específico.
- **Elementos de entrada (inputs)**:
  - `uiOutput("participants_pollutant_selector")`: Selector de contaminante
  - `uiOutput("participants_level_selector")`: Selector de nivel
- **Elementos de salida (outputs)**:
  - `uiOutput("scores_participant_tabs")`: Pestañas dinámicas para cada participante con:
    - Tabla de resultados detallados
    - Puntajes obtenidos
    - Información de instrumentación
- **Flujo de navegación**: Permite un análisis profundo por laboratorio, facilitando la identificación de causas raíz en caso de desempeños no satisfactorios.

## 8. Generación de informes

- **Propósito**: Configurar y exportar el informe final del ensayo de aptitud en formatos estandarizados.
- **Elementos de entrada (inputs)**:
  - `uiOutput("report_n_selector")`: Selector de esquema
  - `uiOutput("report_level_selector")`: Selector de nivel
  - `selectInput("report_metric")`: Métrica (z, z', zeta, En)
  - `selectInput("report_method")`: Método (Referencia, Consenso MADe/nIQR, Algoritmo A)
  - `selectInput("report_metrological_compatibility")`: Compatibilidad metrológica
  - `numericInput("report_k")`: Factor de cobertura (k)
  - `fileInput("participants_data_upload")`: CSV de instrumentación (Codigo_Lab, Analizador_SO2, Analizador_CO, Analizador_O3, Analizador_NO_NO2)
  - `radioButtons("report_format")`: Formato (Word, HTML)
  - `downloadButton("download_report")`: Descargar informe
- **Campos de identificación**:
  - `textInput("report_scheme_id")`: ID Esquema EA
  - `textInput("report_id")`: ID Informe
  - `dateInput("report_date")`: Fecha de Emisión
  - `textInput("report_period")`: Periodo del Ensayo
  - `textInput("report_coordinator")`: Coordinador EA
  - `textInput("report_quality_pro")`: Profesional Calidad Aire
  - `textInput("report_ops_eng")`: Ingeniero Operativo
  - `textInput("report_quality_manager")`: Profesional Gestión Calidad
- **Elementos de salida (outputs)**:
  - `uiOutput("report_status")`: Estado del informe
  - `verbatimTextOutput("report_preview_summary")`: Vista previa del resumen
- **Pestañas**:
  - "1. Identificación": Campos de texto para identificación
  - "Vista Previa": Estado y resumen del informe
- **Flujo de navegación**: Es el paso final del proceso. Permite consolidar todos los análisis realizados en un documento oficial descargable.

## Estructura General de la UI

```
fluidPage(
  titlePanel("Aplicativo para Evaluación de Ensayos de Aptitud")
  h3("Gases Contaminantes Criterio")
  h4("Laboratorio Calaire")
  
  uiOutput("main_layout")  # navlistPanel con 8 módulos
)

main_layout = navlistPanel(
  "Carga de datos",
  "Análisis de homogeneidad y estabilidad",
  "Valores Atípicos",
  "Valor asignado",
  "Puntajes PT",
  "Informe global",
  "Participantes",
  "Generación de informes"
)
```

## Referencia

El prototipo se basa en la implementación completa en `app.R` del proyecto PT App. Para la implementación funcional, consulte el código fuente completo en el archivo `app.R`.
