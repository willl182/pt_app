# 16. Guía de Personalización

| Propiedad | Valor |
|----------|-------|
| **Tipo de Documento** | Guía de Configuración |
| **Archivo Principal** | `app.R` |
| **Docs Relacionados** | `15_arquitectura.md`, `02_paquete_ptcalc.md`, `02a_api_ptcalc.md`, `01a_formatos_datos.md` |

---

## Descripción General

Esta guía cubre varias formas de personalizar el aplicativo PT, incluyendo:

- Personalización del tema (colores, fuentes, temas Bootswatch).
- Controles de ancho del diseño (dinámicos y fijos).
- Adición de nuevos contaminantes y niveles de concentración.
- Extensión del paquete `ptcalc` con nuevos métodos estadísticos y tipos de puntaje.
- Personalización de plantillas de informe y colores de visualización de puntajes.
- Internacionalización (personalización del texto de la interfaz de usuario).

---

## Ubicación en el Código

| Elemento | Valor |
|---------|-------|
| Archivo Principal de la Aplicación | `app.R` |
| Definición del Tema | Líneas 40-50 (aprox.) |
| Controles de Diseño | Líneas 58-67 (aprox.) |
| Puntos de Extensión | A lo largo de la función del servidor y del paquete `ptcalc/` |
| Plantillas de Informe | `pt_app/inst/rmarkdown/templates/` o en línea en `downloadHandler` |

---

## Personalización del Tema (bslib)

La aplicación utiliza Bootstrap 5 a través del paquete `bslib`. El tema se define en la parte superior de `app.R`.

### Configuración Actual del Tema

```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",           # Fondo blanco
  fg = "#212529",           # Texto frontal oscuro
  primary = "#FDB913",      # Amarillo/Oro (Amarillo CALAIRE)
  secondary = "#333333",    # Gris oscuro secundario
  success = "#4DB848",      # Color verde para éxito
  base_font = font_google("Droid Sans"),
  code_font = font_google("JetBrains Mono")
)
```

### Referencia de la Paleta de Colores

| Variable | Actual | Propósito | Uso |
|----------|---------|---------|-------|
| `bg` | `#FFFFFF` | Fondo de página | Fondo principal de la aplicación |
| `fg` | `#212529` | Color de texto | Texto del cuerpo predeterminado |
| `primary` | `#FDB913` | Acento primario | Botones, enlaces, elementos activos (Amarillo) |
| `secondary` | `#333333` | Acento secundario | Encabezados de navegación, elementos secundarios |
| `success` | `#4DB848` | Color de éxito | Indicadores positivos, estados válidos |
| `info` | `#0dcaf0` | Color de info | (Predet.) Alertas de información |
| `warning`| `#ffc107` | Color de advertencia | (Predet.) Alertas de advertencia |
| `danger` | `#dc3545` | Color de error | (Predet.) Mensajes de error |

### Modificación de los Colores del Tema

Para cambiar el esquema de colores, modifique los valores hexadecimales en la llamada a `bs_theme()`.

#### Ejemplo: Tema Azul
```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = "#212529",
  primary = "#0d6efd",      # Azul Bootstrap
  secondary = "#6c757d",    # Gris Bootstrap
  success = "#198754",      # Verde Bootstrap
  base_font = font_google("Roboto"),
  code_font = font_google("Source Code Pro")
)
```

### Temas Bootswatch

Puede cambiar fácilmente a un tema Bootswatch predefinido.

**Opción 1: Selección en tiempo de ejecución**
La aplicación incluye un widget selector de temas en el panel "Opciones de diseño". Marque "Mostrar opciones de diseño" para usar el widget `themeSelector`.

**Opción 2: Tema codificado (Hardcode)**
```r
theme = bs_theme(
  version = 5,
  bootswatch = "cerulean",  # ej., "flatly", "cosmo", "yeti"
  primary = "#FDB913"       # Aún puede anular colores específicos
)
```

### Cambio de Fuentes

La aplicación utiliza Google Fonts. Alternativas populares:
- **Fuentes del cuerpo:** `"Open Sans"`, `"Roboto"`, `"Lato"`, `"Source Sans Pro"`, `"Inter"`
- **Fuentes de código:** `"Fira Code"`, `"Source Code Pro"`, `"JetBrains Mono"`, `"IBM Plex Mono"`

```r
base_font = font_google("Inter"),
code_font = font_google("Fira Code")
```

---

### Personalización con Variables CSS

El diseño moderno utiliza Propiedades Personalizadas CSS (variables) para un estilo consistente. Estas variables se definen en `www/appR.css`.

#### Referencia de Variables CSS

**Paleta de Colores**
```css
:root {
  --pt-primary: #FDB913;        /* Amarillo/oro UNAL */
  --pt-bg: #E8EAED;             /* Fondo principal */
  --pt-bg-card: #F5F6F7;        /* Fondos de tarjetas */
  --pt-fg: #1F2937;             /* Texto primario */
  --pt-fg-muted: #6B7280;       /* Texto atenuado */
  --pt-satisfactory: #00B050;   /* Puntajes verdes */
  --pt-questionable: #FFEB3B;   /* Puntajes amarillos */
  --pt-unsatisfactory: #D32F2F; /* Puntajes rojos */
}
```

**Espaciado y Diseño**
```css
--space-xs: 0.25rem;
--space-sm: 0.5rem;
--space-md: 1rem;
--space-lg: 1.5rem;
--space-xl: 2rem;
--space-xxl: 3rem;
--radius-sm: 0.25rem;
--radius-md: 0.5rem;
--radius-lg: 0.75rem;
--radius-xl: 1rem;
```

#### Anulación de Variables CSS

**Opción 1: Crear custom.css**
1. Cree `www/custom.css`:
```css
:root {
  --pt-primary: #SU_COLOR;
  --pt-bg: #SU_FONDO;
  --pt-bg-card: #EL_FONDO_DE_SU_TARJETA;
}
```

2. Cárguelo en `app.R`:
```r
tags$head(
  tags$link(rel = "stylesheet", href = "appR.css"),
  tags$link(rel = "stylesheet", href = "custom.css")  # Después de appR.css
)
```

**Opción 2: Añadir estilos personalizados en app.R**
```r
tags$head(
  tags$style(HTML("
    :root {
      --pt-primary: #SU_COLOR;
    }
  "))
)
```

---

### Personalización de Componentes Inspirados en shadcn

La aplicación utiliza componentes inspirados en shadcn para los elementos modernos de la interfaz de usuario.

#### Tarjetas (.shadcn-card)

```css
.shadcn-card {
  background: var(--pt-bg-card);
  border: 1px solid #e5e7eb;
  border-radius: var(--radius-lg);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
```

**Ejemplo de Personalización:**
```css
.shadcn-card {
  --card-bg: #SU_FONDO;
  --card-border: #SU_BORDE;
  background: var(--card-bg);
  border-color: var(--card-border);
}
```

#### Alertas (.alert-modern)

```css
.alert-modern.alert-info {
  background: #e0f2fe;
  border-color: #0284c7;
  color: #0c4a6e;
}
.alert-modern.alert-success {
  background: #dcfce7;
  border-color: #16a34a;
  color: #14532d;
}
.alert-modern.alert-warning {
  background: #fef9c3;
  border-color: #ca8a04;
  color: #713f12;
}
.alert-modern.alert-error {
  background: #fee2e2;
  border-color: #dc2626;
  color: #7f1d1d;
}
```

#### Badges (.badge-modern)

```css
.badge-modern.badge-satisfactory {
  background: var(--pt-satisfactory);
  color: white;
}
.badge-modern.badge-questionable {
  background: var(--pt-questionable);
  color: black;
}
.badge-modern.badge-unsatisfactory {
  background: var(--pt-unsatisfactory);
  color: white;
}
```

---

### Personalización de Encabezado/Pie de Página

#### Encabezado (Enhanced Header)

Ubicación: `www/appR.css` líneas 828-902

**Elementos Clave:**
- Contenedor del logo con la marca UNAL (alineado a la izquierda)
- Texto de la imagen institucional
- Acentos de color primario

**Ejemplo de Personalización:**
```css
.pt-header {
  background: var(--pt-bg-card);
  border-bottom: 2px solid var(--pt-primary);
}
.pt-logo-container img {
  max-height: SU_ALTURA;
}
.pt-header-title {
  color: var(--pt-primary);
  font-size: SU_TAMAÑO;
}
```

#### Pie de Página (Modern Footer)

Ubicación: `www/appR.css` líneas 1217-1280

**Elementos Clave:**
- Diseño de tres columnas
- Información del proyecto
- Logos de instituciones
- Información de contacto

**Ejemplo de Personalización:**
```css
.pt-footer {
  background: var(--pt-bg);
  border-top: 1px solid #e5e7eb;
}
.pt-footer-section {
  padding: var(--space-lg);
}
.pt-footer-title {
  color: var(--pt-primary);
  font-weight: bold;
}
```

---

## Controles de Ancho del Diseño

La aplicación proporciona controles de diseño dinámicos a través de entradas numéricas o deslizantes (sliders) en la interfaz de usuario.

### Deslizadores de Ancho Dinámicos

| Control | ID de Entrada | Predet. | Rango | Propósito |
|---------|----------|---------|-------|---------|
| Ancho de Navegación | `nav_width` | 2 | 1-5 | Ancho del panel de navegación (columnas Bootstrap) |
| Sidebar de Análisis | `analysis_sidebar_width` | 3 | 2-6 | Ancho del panel de parámetros de análisis |

### Referencia del Sistema de Rejilla de Bootstrap

El diseño utiliza una rejilla de 12 columnas. El ancho del contenido se calcula como `12 - ancho_sidebar`.

| Ancho | Columna Bootstrap | Ancho Visual (aprox.) |
|-------|------------------|------------------------|
| 1 | `col-1` | 8.33% |
| 2 | `col-2` | 16.67% |
| 3 | `col-3` | 25.00% |
| 4 | `col-4` | 33.33% |

### Codificación de los Anchos de Diseño (Hardcoding)

Para establecer anchos fijos, elimine los elementos `sliderInput` y utilice valores fijos:
```r
sidebarLayout(
  sidebarPanel(width = 2, ...),
  mainPanel(width = 10, ...)
)
```

### Recomendaciones de Diseño

| Tamaño de Pantalla | nav_width | analysis_sidebar_width |
|-------------|-----------|------------------------|
| Pequeño (laptop) | 2 | 4 |
| Mediano (desktop) | 2 | 3 |
| Grande (monitor ancho) | 1 | 2 |

---

## Añadir Nuevos Contaminantes

La aplicación detecta automáticamente los contaminantes a partir de los datos cargados. Por lo general, **no se requieren cambios en el código**.

### Requisitos de Datos

Incluya el nuevo contaminante (ej., "PM2.5") en sus archivos CSV (`homogeneity.csv`, `summary_*.csv`):

```csv
pollutant,level,replicate,value,participant_id
PM2.5,low,1,15.2,lab001
PM2.5,low,2,15.5,lab001
```

### Detección Dinámica

La aplicación puebla los menús desplegables utilizando expresiones reactivas:
```r
pollutant_choices <- reactive({
  req(pt_prep_data())
  unique(pt_prep_data()$pollutant)
})
```

### Configuración Específica de Contaminantes

Si necesita configuraciones específicas (como unidades), puede extender una tabla de configuración en la lógica del servidor:
```r
pollutant_config <- tibble(
  pollutant = c("SO2", "NO2", "PM10", "PM2.5"),
  unit = c("ppb", "ppb", "µg/m³", "µg/m³")
)
```

---

## Añadir Nuevos Niveles de Concentración

Los niveles de concentración también se detectan automáticamente a partir de los datos.

### Formato de Datos
```csv
pollutant,level,replicate,value
SO2,muy_bajo,1,0.012
SO2,medio,1,0.156
```

### Orden de los Niveles
Los niveles se ordenan alfabéticamente. Para personalizar el orden, use un prefijo numérico (ej., `1_bajo`, `2_medio`) o utilice factores en la preparación de los datos.

---

## Extensión del Paquete ptcalc

### Estructura del Paquete
```
ptcalc/
  DESCRIPTION
  NAMESPACE
  R/
    pt_robust_stats.R    # Estadísticas robustas (Algoritmo A, MADe, nIQR)
    pt_homogeneity.R     # Pruebas de homogeneidad y estabilidad
    pt_scores.R          # Puntuación (z, z', zeta, En)
```

### Añadir un Nuevo Método Estadístico

1. **Cree o modifique un archivo R** en `ptcalc/R/` (ej., `new_method.R`):
```r
#' Calcular Estimador Hampel
#' @param x Vector numérico
#' @export
calculate_hampel <- function(x) {
  # Implementación
  median_val <- median(x, na.rm = TRUE)
  1.4826 * median(abs(x - median_val), na.rm = TRUE)
}
```

2. **Actualice la Documentación e Instale**:
```bash
devtools::document("ptcalc")
devtools::install("ptcalc")
```

### Añadir un Nuevo Tipo de Puntaje

1. **Implemente en `ptcalc/R/pt_scores.R`**:
```r
#' @export
calculate_q_score <- function(x, x_pt, sigma) {
  (x - x_pt) / sigma
}
```

2. **Integre en `cloned_app.R`**:
- Actualice `selectInput("score_method", ...)` en la UI.
- Actualice la lógica de computación del puntaje en el servidor (ej., bloques `switch` o `if`).

### Flujo de Trabajo de Desarrollo
```r
devtools::document("ptcalc") # Reconstruir documentos
devtools::load_all("ptcalc") # Recarga rápida para pruebas
devtools::test("ptcalc")     # Ejecutar pruebas unitarias
devtools::install("ptcalc")  # Instalar para uso de la aplicación
```

---

## Personalización de los Colores de Clasificación de Puntajes

Las visualizaciones de puntajes (como los mapas de calor) utilizan paletas de colores predefinidas.

### Modificación de los Colores (ej., Puntaje En)
Edite `PT_EN_CLASS_COLORS` en `ptcalc/R/pt_scores.R`:
```r
PT_EN_CLASS_COLORS <- c(
  "a1" = "#2E7D32",  # Verde - Excelente
  "a4" = "#FFEB3B",  # Amarillo - Aceptable
  "a7" = "#B71C1C"   # Rojo - Pobre
)
```

---

## Personalización de Plantillas de Informe

La generación de informes utiliza plantillas de RMarkdown.

### Ubicación de la Plantilla
Las plantillas se encuentran típicamente en `pt_app/inst/rmarkdown/templates/pt_report/template.Rmd`. Algunas versiones pueden usar definiciones en línea en `downloadHandler`.

### Modificación de la Plantilla
Puede editar `template.Rmd` para cambiar el diseño, añadir logos o modificar la lógica del resumen ejecutivo.

**Ejemplo de Encabezado YAML:**
```yaml
---
title: "Informe de Ensayo de Aptitud"
output:
  word_document:
    reference_docx: "styles.docx"  # Usar para estilo personalizado de Word
params:
  data: NULL
---
```

### Personalizaciones Comunes
1. **Logo:** Añada la ruta del logo a la plantilla o a `inst/resources`.
2. **Estilos:** Modifique `styles.docx` para establecer las fuentes predeterminadas y los estilos de tabla para las exportaciones a Word.

---

## Personalización del Texto de la UI (Internacionalización)

La aplicación está en español por defecto.

### Enfoque 1: Modificación Directa
Busque y reemplace cadenas en `app.R`:
`actionButton("run", "Ejecutar")` → `actionButton("run", "Run")`

### Enfoque 2: Externalizar Cadenas
Cree un diccionario de traducción:
```r
translations <- list(
  es = list(calculate = "Calcular"),
  en = list(calculate = "Calculate")
)
# Usar en UI/Server: translations[[input$language]]$calculate
```

---

## Ver También

- `15_arquitectura.md`: Arquitectura del sistema y patrones reactivos.
- `02a_api_ptcalc.md`: Referencia detallada de las funciones de `ptcalc`.
- `01a_formatos_datos.md`: Detalles del esquema CSV para contaminantes y niveles.
- `12_generacion_informes.md`: Flujo de trabajo de generación de informes.
