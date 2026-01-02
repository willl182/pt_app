# Entregable 5.1: Prototipo y Estructura de la Interfaz de Usuario (UI)

Este documento describe la arquitectura visual y los componentes de la interfaz de usuario del aplicativo Shiny, diseñada para facilitar el flujo de trabajo de los ensayos de aptitud.

## 1. Concepto de Diseño

- **Framework:** Shiny (`fluidPage`) con `shinythemes`.
- **Tema:** `cerulean` (proporciona un aspecto profesional y limpio en tonos azules).
- **Layout Principal:** `navlistPanel` lateral, que permite una navegación secuencial a través de los módulos del ensayo.

## 2. Componentes de la Interfaz

### 2.1. Panel de Navegación (Izquierdo)
El panel organiza los módulos en el orden lógico de un ejercicio de intercomparación:
1. **Módulos de análisis:**
   - Carga de datos
   - Evaluación de homogeneidad
   - Evaluación de estabilidad
   - Valor asignado y sigma_pt
   - Puntajes PT
   - Generación de informes

### 2.2. Panel de Contenido (Derecho)
Cada pestaña utiliza elementos de `bsplus` y `DT` para mostrar información de manera interactiva:
- **Inputs:** `fileInput` para carga masiva, `selectizeInput` para filtrado de analitos y niveles.
- **Acciones:** `actionButton` ("Calcular", "Ejecutar Análisis") con retroalimentación visual.
- **Visualización:**
  - `plotlyOutput` para gráficos interactivos.
  - `DTOutput` para tablas con funcionalidad de búsqueda y exportación.
  - `rhandsontableOutput` para edición de datos de participantes in-situ.

## 3. Estructura de Código (UI)

La interfaz se define dinámicamente en el servidor mediante `renderUI`, lo que permite ajustar el ancho de los paneles según la preferencia del usuario (Panel de Opciones de Diseño).

```r
# Estructura simplificada de app.R
ui <- fluidPage(
  theme = shinytheme("cerulean"),
  titlePanel("Aplicativo para Evaluación de Ensayos de Aptitud"),
  uiOutput("main_layout") # Generado dinámicamente con navlistPanel
)
```
