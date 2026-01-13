# ==============================================================================
# Archivo: prototipo_ui.R
# Propósito: Prototipo de interfaz de usuario - Copia fiel de la UI de app.R
# Autor: Sisyphus Agent
# Fecha: 2026-01-11
# ==============================================================================
# Este archivo contiene la definición de la interfaz de usuario (UI) del
# aplicativo para evaluación de ensayos de aptitud, extraída directamente
# de app.R para servir como prototipo de referencia.
# ==============================================================================

library(shiny)
library(bslib)

# ===================================================================
# I. Interfaz de Usuario (UI)
# ===================================================================
ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bg = "#FFFFFF",
    fg = "#212529",
    primary = "#FDB913",
    secondary = "#333333",
    success = "#4DB848",
    base_font = font_google("Droid Sans"),
    code_font = font_google("JetBrains Mono")
  ),

  # 1. Título de la aplicación
  titlePanel("Aplicativo para Evaluación de Ensayos de Aptitud"),
  h3("Gases Contaminantes Criterio"),
  h4("Laboratorio Calaire"),

  # Panel desplegable para opciones de diseño
  checkboxInput("show_layout_options", "Mostrar opciones de diseño", value = FALSE),
  conditionalPanel(
    condition = "input.show_layout_options == true",
    wellPanel(
      themeSelector(),
      hr(),
      sliderInput("nav_width", "Ancho del panel de navegación:", min = 1, max = 5, value = 2, width = "250px"),
      sliderInput("analysis_sidebar_width", "Ancho de la barra lateral de análisis:", min = 2, max = 6, value = 3, width = "250px")
    )
  ),
  hr(),

  # UI dinámica para el diseño principal
  uiOutput("main_layout"),
  hr(),
  p(em("Este aplicativo fue desarrollado en el marco del proyecto «Implementación de Ensayos de Aptitud en la Matriz Aire. Caso Gases Contaminantes Criterio», ejecutado por el Laboratorio CALAIRE de la Universidad Nacional de Colombia en alianza con el Instituto Nacional de Metrología (INM)."), style = "text-align:center; font-size:small;")
)

# ==============================================================================
# Diseño Principal Dinámico (renderUI en server)
# ==============================================================================
# La función main_layout se renderiza dinámicamente en el servidor.
# A continuación se documenta la estructura de navegación:
#
# navlistPanel con los siguientes módulos:
#
# 1. "Carga de datos"
#    - fileInput: hom_file (homogeneity.csv)
#    - fileInput: stab_file (stability.csv)
#    - fileInput: summary_files (summary_n*.csv, multiple)
#    - verbatimTextOutput: data_upload_status
#
# 2. "Análisis de homogeneidad y estabilidad"
#    - sidebarLayout con:
#      - actionButton: run_analysis
#      - uiOutput: pollutant_selector_analysis
#      - uiOutput: level_selector
#    - tabsetPanel:
#      - "Vista previa de datos"
#      - "Evaluación de homogeneidad"
#      - "Evaluación de estabilidad"
#      - "Contribuciones a la incertidumbre"
#
# 3. "Valores Atípicos"
#    - dataTableOutput: grubbs_summary_table
#    - uiOutput: outliers_pollutant_selector
#    - uiOutput: outliers_level_selector
#    - plotlyOutput: outliers_histogram, outliers_boxplot
#
# 4. "Valor asignado"
#    - sidebarLayout con:
#      - actionButton: algoA_run, consensus_run, run_metrological_compatibility
#      - uiOutput: assigned_pollutant_selector, assigned_n_selector, assigned_level_selector
#      - numericInput: algoA_max_iter
#    - tabsetPanel:
#      - "Algoritmo A"
#      - "Valor consenso"
#      - "Valor de referencia"
#      - "Compatibilidad Metrológica"
#
# 5. "Puntajes PT"
#    - sidebarLayout con:
#      - actionButton: scores_run
#      - uiOutput: scores_pollutant_selector, scores_n_selector, scores_level_selector
#    - tabsetPanel:
#      - "Resultados de puntajes"
#      - "Puntajes Z"
#      - "Puntajes Z'"
#      - "Puntajes Zeta"
#      - "Puntajes En"
#
# 6. "Informe global"
#    - sidebarLayout con selectores
#    - tabsetPanel:
#      - "Resumen global"
#      - "Referencia (1)"
#      - "Consenso MADe (2a)"
#      - "Consenso nIQR (2b)"
#      - "Algoritmo A (3)"
#
# 7. "Participantes"
#    - sidebarLayout con selectores
#    - uiOutput: scores_participant_tabs
#
# 8. "Generación de informes"
#    - sidebarLayout con:
#      - uiOutput: report_n_selector, report_level_selector
#      - selectInput: report_metric, report_method, report_metrological_compatibility
#      - numericInput: report_k
#      - fileInput: participants_data_upload
#      - radioButtons: report_format
#      - downloadButton: download_report
#    - tabsetPanel:
#      - "1. Identificación" (textInput, dateInput)
#      - "Vista Previa"
# ==============================================================================

# Datos utilizados por la aplicación:
# - Contaminantes: co, no, no2, o3, so2
# - Niveles (ejemplos):
#   - co: 0-μmol/mol, 2-μmol/mol, 4-μmol/mol, 6-μmol/mol, 8-μmol/mol
#   - no: 0-nmol/mol, 50-nmol/mol, 100-nmol/mol, etc.
#   - no2: 0-nmol/mol, 50-nmol/mol, 100-nmol/mol, etc.
#   - o3: 0-nmol/mol, 50-nmol/mol, 80-nmol/mol, etc.
#   - so2: 0-nmol/mol, 50-nmol/mol, 100-nmol/mol, etc.
#
# Archivos de entrada:
# - homogeneity.csv: columnas (pollutant, level, replicate, sample_id, value)
# - stability.csv: columnas (pollutant, level, replicate, sample_id, value)
# - summary_n*.csv: columnas (pollutant, level, participant_id, replicate, sample_group, mean_value, sd_value)
# ==============================================================================
