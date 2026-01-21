# 16. Guía de Personalización

| Propiedad | Valor |
|-----------|-------|
| **Tipo de Documento** | Guía de Configuración |
| **Archivo Principal** | `cloned_app.R` |
| **Docs Relacionados** | `15_architecture.md`, `02_ptcalc_package.md`, `02a_ptcalc_api.md`, `01a_data_formats.md` |

---

## Descripción General

Esta guía cubre varias formas de personalizar la aplicación de Ensayos de Aptitud (PT), incluyendo:

- Personalización del tema (colores, fuentes, temas de Bootswatch)
- Controles de ancho del diseño (dinámicos y fijos)
- Adición de nuevos contaminantes y niveles de concentración
- Extensión del paquete `ptcalc` con nuevos métodos estadísticos y tipos de puntajes
- Personalización de plantillas de informes y colores de visualización de puntajes
- Internacionalización (personalización del texto de la interfaz de usuario)

---

## Ubicación en el Código

| Elemento | Valor |
|----------|-------|
| Archivo Principal de la Aplicación | `cloned_app.R` |
| Definición del Tema | Líneas 40-50 (aprox.) |
| Controles de Diseño | Líneas 58-67 (aprox.) |
| Puntos de Extensión | A lo largo de la función server y el paquete `ptcalc/` |
| Plantillas de Informe | `pt_app/inst/rmarkdown/templates/` o integradas en `downloadHandler` |

---

## Personalización del Tema (bslib)

La aplicación utiliza Bootstrap 5 a través del paquete `bslib`. El tema se define en la parte superior de `cloned_app.R`.

### Configuración Actual del Tema

```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",           # Fondo blanco
  fg = "#212529",           # Texto de primer plano oscuro
  primary = "#FDB913",      # Amarillo/Oro (Amarillo CALAIRE)
  secondary = "#333333",    # Gris oscuro secundario
  success = "#4DB848",      # Color de éxito verde
  base_font = font_google("Droid Sans"),
  code_font = font_google("JetBrains Mono")
)
```

### Referencia de la Paleta de Colores

| Variable | Actual | Propósito | Uso |
|----------|---------|-----------|-----|
| `bg` | `#FFFFFF` | Fondo de página | Fondo principal de la aplicación |
| `fg` | `#212529` | Color de texto | Texto de cuerpo predeterminado |
| `primary` | `#FDB913` | Acento primario | Botones, enlaces, elementos activos (Amarillo) |
| `secondary` | `#333333` | Acento secundario | Encabezados de navegación, elementos secundarios |
| `success` | `#4DB848` | Color de éxito | Indicadores positivos, estados válidos |
| `info` | `#0dcaf0` | Color de información | (Predeterminado) Alertas de información |
| `warning`| `#ffc107` | Color de advertencia | (Predeterminado) Alertas de advertencia |
| `danger` | `#dc3545` | Color de error | (Predeterminado) Mensajes de error |

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

### Temas de Bootswatch

Puede cambiar fácilmente a un tema de Bootswatch predefinido.

**Opción 1: Selección en Tiempo de Ejecución**
La aplicación incluye un widget selector de temas en el panel "Opciones de diseño". Marque "Mostrar opciones de diseño" para usar el widget `themeSelector`.

**Opción 2: Tema Codificado (Hardcoded)**
```r
theme = bs_theme(
  version = 5,
  bootswatch = "cerulean",  # ej., "flatly", "cosmo", "yeti"
  primary = "#FDB913"       # Aún puede anular colores específicos
)
```

### Cambio de Fuentes

La aplicación utiliza Google Fonts. Alternativas populares:
- **Fuentes de cuerpo:** `"Open Sans"`, `"Roboto"`, `"Lato"`, `"Source Sans Pro"`, `"Inter"`
- **Fuentes de código:** `"Fira Code"`, `"Source Code Pro"`, `"JetBrains Mono"`, `"IBM Plex Mono"`

```r
base_font = font_google("Inter"),
code_font = font_google("Fira Code")
```

---

## Controles de Ancho del Diseño

La aplicación proporciona controles de diseño dinámicos a través de entradas numéricas o deslizadores en la interfaz de usuario.

### Deslizadores de Ancho Dinámico

| Control | ID de Entrada | Predeterminado | Rango | Propósito |
|---------|---------------|----------------|-------|-----------|
| Ancho de Navegación | `nav_width` | 2 | 1-5 | Ancho del panel de navegación (columnas Bootstrap) |
| Barra Lateral de Análisis | `analysis_sidebar_width` | 3 | 2-6 | Ancho del panel de parámetros de análisis |

### Referencia del Sistema de Rejilla de Bootstrap

El diseño utiliza una rejilla de 12 columnas. El ancho del contenido se calcula como `12 - sidebar_width`.

| Ancho | Columna Bootstrap | Ancho Visual (aprox.) |
|-------|-------------------|-----------------------|
| 1 | `col-1` | 8.33% |
| 2 | `col-2` | 16.67% |
| 3 | `col-3` | 25.00% |
| 4 | `col-4` | 33.33% |

### Codificación de Anchos de Diseño (Hardcoding)

Para establecer anchos fijos, elimine los elementos `sliderInput` y use valores fijos:
```r
sidebarLayout(
  sidebarPanel(width = 2, ...),
  mainPanel(width = 10, ...)
)
```

### Recomendaciones de Diseño

| Tamaño de Pantalla | nav_width | analysis_sidebar_width |
|--------------------|-----------|------------------------|
| Pequeño (laptop) | 2 | 4 |
| Medio (escritorio) | 2 | 3 |
| Grande (monitor ancho) | 1 | 2 |

---

## Adición de Nuevos Contaminantes

La aplicación detecta automáticamente los contaminantes de los datos cargados. Por lo general, **no se requieren cambios en el código**.

### Requisitos de Datos

Incluya el nuevo contaminante (ej., "PM2.5") en sus archivos CSV (`homogeneity.csv`, `summary_*.csv`):

```csv
pollutant,level,replicate,value,participant_id
PM2.5,low,1,15.2,lab001
PM2.5,low,2,15.5,lab001
```

### Detección Dinámica

La aplicación llena las listas desplegables utilizando expresiones reactivas:
```r
pollutant_choices <- reactive({
  req(pt_prep_data())
  unique(pt_prep_data()$pollutant)
})
```

### Configuración Específica por Contaminante

Si necesita configuraciones específicas (como unidades), puede extender una tabla de configuración en la lógica del servidor:
```r
pollutant_config <- tibble(
  pollutant = c("SO2", "NO2", "PM10", "PM2.5"),
  unit = c("ppb", "ppb", "µg/m³", "µg/m³")
)
```

---

## Adición de Nuevos Niveles de Concentración

Los niveles de concentración también se detectan automáticamente a partir de los datos.

### Formato de Datos
```csv
pollutant,level,replicate,value
SO2,very_low,1,0.012
SO2,medium,1,0.156
```

### Orden de los Niveles
Los niveles se ordenan alfabéticamente. Para personalizar el orden, prefije con números (ej., `1_low`, `2_medium`) o use factores en la preparación de datos.

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

### Adición de un Nuevo Método Estadístico

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

### Adición de un Nuevo Tipo de Puntaje (Score)

1. **Implemente en `ptcalc/R/pt_scores.R`**:
```r
#' @export
calculate_q_score <- function(x, x_pt, sigma) {
  (x - x_pt) / sigma
}
```

2. **Integre en `cloned_app.R`**:
- Actualice `selectInput("score_method", ...)` en la UI.
- Actualice la lógica de computación de puntajes en el servidor (ej., bloques `switch` o `if`).

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

### Modificación de Colores (ej., Puntaje En)
Edite `PT_EN_CLASS_COLORS` en `ptcalc/R/pt_scores.R`:
```r
PT_EN_CLASS_COLORS <- c(
  "a1" = "#2E7D32",  # Verde - Excelente
  "a4" = "#FFEB3B",  # Amarillo - Aceptable
  "a7" = "#B71C1C"   # Rojo - Deficiente
)
```

---

## Personalización de Plantillas de Informe

La generación de informes utiliza plantillas RMarkdown.

### Ubicación de la Plantilla
Las plantillas suelen estar en `pt_app/inst/rmarkdown/templates/pt_report/template.Rmd`. Algunas versiones pueden usar definiciones integradas en `downloadHandler`.

### Modificación de la Plantilla
Puede editar `template.Rmd` para cambiar el diseño, agregar logotipos o modificar la lógica del resumen ejecutivo.

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
1. **Logo:** Agregue la ruta del logo a la plantilla o a `inst/resources`.
2. **Estilos:** Modifique `styles.docx` para establecer fuentes predeterminadas y estilos de tabla para las exportaciones a Word.

---

## Personalización de Texto de la UI (Internacionalización)

La aplicación está en español de forma predeterminada.

### Enfoque 1: Modificación Directa
Busque y reemplace cadenas en `cloned_app.R`:
`actionButton("run", "Ejecutar")` → `actionButton("run", "Run")`

### Enfoque 2: Externalizar Cadenas
Cree un diccionario de traducción:
```r
translations <- list(
  es = list(calculate = "Calcular"),
  en = list(calculate = "Calculate")
)
# Uso en UI/Server: translations[[input$language]]$calculate
```

---

## Ver También

- `15_architecture.md`: Arquitectura del sistema y patrones reactivos.
- `02a_ptcalc_api.md`: Referencia detallada de las funciones de `ptcalc`.
- `01a_data_formats.md`: Detalles del esquema CSV para contaminantes y niveles.
- `12_generacion_informes.md`: Flujo de trabajo de generación de informes.
