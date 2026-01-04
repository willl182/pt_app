# Entregable 5.1: Prototipo y Estructura de la Interfaz de Usuario

**Proyecto:** Aplicativo para Evaluación de Ensayos de Aptitud (PT App)  
**Organización:** Laboratorio CALAIRE - Universidad Nacional de Colombia  
**Archivo Principal:** `app.R` (líneas 36-64: UI)  
**Fecha:** 2026-01-03

---

## 1. Arquitectura de la Interfaz

### 1.1. Framework y Tecnologías

| Componente | Tecnología | Versión |
|------------|------------|---------|
| Framework UI | Shiny `fluidPage` | 1.7.0+ |
| Tema Visual | shinythemes `cerulean` | 1.2.0 |
| Tablas | DT `datatable` | 0.28+ |
| Edición de Datos | rhandsontable | 0.3.8 |
| Gráficos Interactivos | plotly | 4.10.0+ |
| Componentes Bootstrap | bsplus | 0.1.4 |

### 1.2. Estructura General

```
┌─────────────────────────────────────────────────────────────────┐
│                         TÍTULO DEL APLICATIVO                   │
│     "Aplicativo para Evaluación de Ensayos de Aptitud"         │
│                    Gases Contaminantes Criterio                 │
├─────────────────────────────────────────────────────────────────┤
│ [☐] Mostrar opciones de diseño                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌────────────────────────────────────────┐   │
│  │              │  │                                        │   │
│  │  NAVEGACIÓN  │  │         CONTENIDO PRINCIPAL            │   │
│  │   (Panel     │  │                                        │   │
│  │   Lateral)   │  │   - Inputs (fileInput, selectize)     │   │
│  │              │  │   - Tablas (DTOutput)                  │   │
│  │  ○ Inicio    │  │   - Gráficos (plotlyOutput)            │   │
│  │  ○ Datos     │  │   - Acciones (actionButton)            │   │
│  │  ○ Hom.      │  │                                        │   │
│  │  ○ Estab.    │  │                                        │   │
│  │  ○ Consenso  │  │                                        │   │
│  │  ○ Puntajes  │  │                                        │   │
│  │  ○ Informes  │  │                                        │   │
│  │              │  │                                        │   │
│  └──────────────┘  └────────────────────────────────────────┘   │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                          PIE DE PÁGINA                          │
│  "Este aplicativo fue desarrollado en el marco del proyecto..." │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Componentes del Encabezado

### 2.1. Título y Subtítulos

```r
titlePanel("Aplicativo para Evaluación de Ensayos de Aptitud")
h3("Gases Contaminantes Criterio")
h4("Laboratorio Calaire")
```

### 2.2. Panel de Opciones de Diseño (Colapsable)

```r
checkboxInput("show_layout_options", "Mostrar opciones de diseño", value = FALSE)

conditionalPanel(
  condition = "input.show_layout_options == true",
  wellPanel(
    themeSelector(),                    # Selector de tema Bootstrap
    hr(),
    sliderInput("nav_width", ...),      # Ancho del panel de navegación (1-5)
    sliderInput("analysis_sidebar_width", ...)  # Ancho de barra lateral (2-6)
  )
)
```

| Control | Tipo | Rango | Propósito |
|---------|------|-------|-----------|
| `themeSelector()` | Dropdown | Temas Bootstrap | Cambiar apariencia visual |
| `nav_width` | Slider | 1-5 | Ajustar ancho del panel izquierdo |
| `analysis_sidebar_width` | Slider | 2-6 | Ajustar ancho de sidebars internos |

---

## 3. Panel de Navegación Principal

### 3.1. Implementación con `navlistPanel`

```r
navlistPanel(
  id = "main_nav",
  widths = c(input$nav_width, 12 - input$nav_width),
  well = TRUE,
  
  tabPanel("Inicio", ...),
  tabPanel("Carga de Datos", ...),
  "--- Evaluación del Ítem ---",
  tabPanel("Homogeneidad", ...),
  tabPanel("Estabilidad", ...),
  "--- Valor Asignado ---",
  tabPanel("Valor por Referencia", ...),
  tabPanel("Valor por Consenso", ...),
  tabPanel("Algoritmo A", ...),
  "--- Evaluación de Desempeño ---",
  tabPanel("Puntajes PT", ...),
  tabPanel("Informe Global", ...),
  tabPanel("Informes Individuales", ...),
  "--- Utilidades ---",
  tabPanel("Datos de Participantes", ...)
)
```

### 3.2. Estructura de Pestañas

| Grupo | Pestaña | ID | Descripción |
|-------|---------|-----|-------------|
| **Principal** | Inicio | `inicio` | Bienvenida e instrucciones |
| **Principal** | Carga de Datos | `datos` | Upload de archivos CSV |
| **Evaluación Ítem** | Homogeneidad | `hom` | Análisis ANOVA |
| **Evaluación Ítem** | Estabilidad | `stab` | Comparación temporal |
| **Valor Asignado** | Valor por Referencia | `ref` | Método 1 |
| **Valor Asignado** | Valor por Consenso | `cons` | Métodos 2a, 2b |
| **Valor Asignado** | Algoritmo A | `algo` | Método 3 |
| **Desempeño** | Puntajes PT | `scores` | z, z', zeta, En |
| **Desempeño** | Informe Global | `global` | Mapas de calor |
| **Desempeño** | Informes Individuales | `indiv` | Por participante |
| **Utilidades** | Datos de Participantes | `part` | Gestión de labs |

---

## 4. Módulos de Contenido

### 4.1. Módulo: Carga de Datos

```
┌─────────────────────────────────────────────────────────────┐
│                      CARGA DE DATOS                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │ Archivo Homogeneidad│  │ Archivo Estabilidad │          │
│  │ [Seleccionar...]    │  │ [Seleccionar...]    │          │
│  │ homogeneity.csv     │  │ stability.csv       │          │
│  └─────────────────────┘  └─────────────────────┘          │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Archivos de Resumen (múltiples)                        ││
│  │ [Seleccionar archivos...]                              ││
│  │ summary_n4.csv, summary_n7.csv, summary_n10.csv        ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              VISTA PREVIA DE DATOS                      ││
│  │ ┌─────────────────────────────────────────────────────┐││
│  │ │ pollutant │ level   │ value │ replicate │          │││
│  │ │ SO2       │ level_1 │ 100.5 │ 1         │          │││
│  │ │ SO2       │ level_1 │ 100.3 │ 2         │          │││
│  │ │ ...       │ ...     │ ...   │ ...       │          │││
│  │ └─────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

**Elementos UI:**
- `fileInput("hom_file", ...)` — Archivo de homogeneidad
- `fileInput("stab_file", ...)` — Archivo de estabilidad
- `fileInput("summary_files", ..., multiple = TRUE)` — Resúmenes
- `DTOutput("data_preview")` — Vista previa interactiva

### 4.2. Módulo: Análisis (Homogeneidad/Estabilidad)

```
┌─────────────────────────────────────────────────────────────┐
│                       HOMOGENEIDAD                          │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐                                        │
│ │   Selección     │  Contaminante: [SO2 ▼]                 │
│ │   de Filtros    │  Nivel:        [level_1 ▼]             │
│ │                 │  [Ejecutar Análisis]                   │
│ └─────────────────┘                                        │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐│
│ │                   RESULTADOS                            ││
│ │  ┌───────────────────────────────────────────────────┐ ││
│ │  │ Parámetro              │ Valor                   │ ││
│ │  │ Número de ítems (g)    │ 10                      │ ││
│ │  │ Réplicas por ítem (m)  │ 2                       │ ││
│ │  │ ss                     │ 0.0234                  │ ││
│ │  │ sw                     │ 0.0456                  │ ││
│ │  │ σpt (MADe)             │ 0.0891                  │ ││
│ │  │ Criterio (0.3σpt)      │ 0.0267                  │ ││
│ │  │ Evaluación             │ ✓ CUMPLE                │ ││
│ │  └───────────────────────────────────────────────────┘ ││
│ └─────────────────────────────────────────────────────────┘│
│ ┌─────────────────────────────────────────────────────────┐│
│ │                   GRÁFICO (Boxplot)                     ││
│ │                      [plotlyOutput]                     ││
│ └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 4.3. Módulo: Puntajes PT

```
┌─────────────────────────────────────────────────────────────┐
│                       PUNTAJES PT                           │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐  ┌────────────────────────────────────┐│
│ │  Configuración  │  │         Parámetros                 ││
│ │                 │  │                                    ││
│ │ Contaminante:   │  │ σpt:        [0.2        ]          ││
│ │ [SO2 ▼]         │  │ u(xpt):     [0.05       ]          ││
│ │                 │  │ k:          [2          ]          ││
│ │ Nivel:          │  │                                    ││
│ │ [level_1 ▼]     │  │ Métrica: ○ z ○ z' ○ zeta ● En     ││
│ │                 │  │                                    ││
│ │ N° Labs:        │  │ [Calcular Puntajes]                ││
│ │ [7 ▼]           │  │                                    ││
│ └─────────────────┘  └────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐│
│ │                 TABLA DE RESULTADOS                     ││
│ │ ┌─────────────────────────────────────────────────────┐││
│ │ │ ID    │ Resultado │ Puntaje │ Evaluación           │││
│ │ │ lab_1 │ 10.12     │ 0.60    │ 🟢 Satisfactorio     │││
│ │ │ lab_2 │ 10.45     │ 2.25    │ 🟡 Cuestionable      │││
│ │ │ lab_3 │ 10.80     │ 4.00    │ 🔴 Insatisfactorio   │││
│ │ └─────────────────────────────────────────────────────┘││
│ └─────────────────────────────────────────────────────────┘│
│ ┌─────────────────────────────────────────────────────────┐│
│ │               GRÁFICO DE BARRAS                         ││
│ │                  [plotlyOutput]                         ││
│ │    ████████████ lab_1 (0.60)                           ││
│ │    ██████████████████████ lab_2 (2.25)                 ││
│ │    ████████████████████████████████████ lab_3 (4.00)   ││
│ └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Componentes de Entrada (Inputs)

### 5.1. Catálogo de Inputs

| ID | Tipo | Ubicación | Propósito |
|----|------|-----------|-----------|
| `hom_file` | fileInput | Carga de Datos | Archivo CSV homogeneidad |
| `stab_file` | fileInput | Carga de Datos | Archivo CSV estabilidad |
| `summary_files` | fileInput (multiple) | Carga de Datos | Archivos CSV resumen |
| `pollutant` | selectizeInput | Varios | Filtro de contaminante |
| `level` | selectizeInput | Varios | Filtro de nivel |
| `n_lab` | selectizeInput | Puntajes | Número de laboratorios |
| `sigma_pt` | numericInput | Puntajes | Desviación para aptitud |
| `u_xpt` | numericInput | Puntajes | Incertidumbre del VA |
| `k_factor` | numericInput | Puntajes | Factor de cobertura |
| `metric` | radioButtons | Puntajes | Tipo de puntaje |
| `method` | radioButtons | Consenso | Método de VA |

### 5.2. Botones de Acción

| ID | Etiqueta | Módulo | Trigger |
|----|----------|--------|---------|
| `run_hom_analysis` | "Ejecutar Análisis" | Homogeneidad | Cálculo de métricas |
| `run_stab_analysis` | "Ejecutar Análisis" | Estabilidad | Comparación temporal |
| `run_algo_a` | "Ejecutar Algoritmo A" | Algoritmo A | Iteraciones robustas |
| `calculate_scores` | "Calcular Puntajes" | Puntajes | Evaluación de desempeño |
| `download_report` | "Descargar Informe" | Informes | Generar Word |

---

## 6. Componentes de Salida (Outputs)

### 6.1. Tablas

| ID | Tipo | Módulo | Contenido |
|----|------|--------|-----------|
| `hom_data_table` | DTOutput | Homogeneidad | Datos por ítem |
| `hom_results_table` | DTOutput | Homogeneidad | Resultados ANOVA |
| `stab_results_table` | DTOutput | Estabilidad | Comparación medias |
| `algo_a_results` | DTOutput | Algoritmo A | Iteraciones |
| `scores_table` | DTOutput | Puntajes | Puntajes por lab |
| `participants_table` | rhandsontableOutput | Participantes | Editable |

### 6.2. Gráficos

| ID | Tipo | Módulo | Visualización |
|----|------|--------|---------------|
| `hom_boxplot` | plotlyOutput | Homogeneidad | Boxplot por ítem |
| `stab_comparison_plot` | plotlyOutput | Estabilidad | Líneas temporales |
| `algo_a_convergence` | plotlyOutput | Algoritmo A | Curva de convergencia |
| `scores_barplot` | plotlyOutput | Puntajes | Barras horizontales |
| `global_heatmap` | plotlyOutput | Informe Global | Mapa de calor |

---

## 7. Estilos y Tema Visual

### 7.1. Tema Cerulean (Bootstrap)

| Elemento | Color |
|----------|-------|
| Fondo principal | `#ffffff` |
| Navegación activa | `#033c73` (azul oscuro) |
| Botones primarios | `#2fa4e7` (azul claro) |
| Alertas éxito | `#73a839` (verde) |
| Alertas error | `#c71c22` (rojo) |

### 7.2. Codificación de Colores de Evaluación

```css
.satisfactorio { background-color: #28a745; color: white; }
.cuestionable  { background-color: #ffc107; color: black; }
.insatisfactorio { background-color: #dc3545; color: white; }
```

---

## 8. Responsividad

### 8.1. Sistema de Grid Bootstrap

El aplicativo utiliza el sistema de 12 columnas de Bootstrap:

| Componente | Columnas (default) | Ajustable |
|------------|-------------------|-----------|
| Panel de navegación | 2 | Sí (1-5) |
| Contenido principal | 10 | Automático |
| Sidebar interno | 3 | Sí (2-6) |
| Área de resultados | 9 | Automático |

### 8.2. Implementación Dinámica

```r
output$main_layout <- renderUI({
  fluidRow(
    column(input$nav_width, navlistPanel(...)),
    column(12 - input$nav_width, ...)
  )
})
```

---

## 9. Accesibilidad

### 9.1. Características Implementadas

- **Textos descriptivos** en todos los inputs (`label` parameter)
- **Tooltips** en botones de acción (usando `bsplus::bs_embed_tooltip`)
- **Mensajes de validación** claros con `shiny::validate`
- **Alto contraste** en indicadores de evaluación

---

**Siguiente documento:** E5.2 - Diagrama de Navegación
