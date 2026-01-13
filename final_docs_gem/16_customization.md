# Guía de Personalización

Esta guía cubre las opciones para personalizar la aplicación, incluyendo temas visuales, ajustes de diseño, adición de nuevos contaminantes y extensión del paquete `ptcalc`.

---

## Personalización del Tema

La aplicación utiliza `bslib` para temas con Bootstrap 5. El tema se define en la parte superior de `cloned_app.R`.

### Configuración Actual

```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",           # Fondo blanco
  fg = "#212529",           # Texto oscuro
  primary = "#FDB913",      # Amarillo CALAIRE (Primario)
  secondary = "#333333",    # Gris oscuro (Secundario)
  success = "#4DB848",      # Verde éxito
  base_font = font_google("Droid Sans"),
  code_font = font_google("JetBrains Mono")
)
```

### Selector de Tema en Tiempo de Ejecución

La aplicación incluye un panel de opciones de diseño en la barra lateral.
1.  Abra el panel **"Opciones de diseño"**.
2.  Marque **"Mostrar opciones de diseño"**.
3.  Use el widget `themeSelector` para previsualizar temas de Bootswatch (ej: `cerulean`, `flatly`, `cosmo`).

### Modificar Colores Manualmente

Para cambiar la paleta de colores permanentemente, edite los códigos hexadecimales en la definición de `bs_theme` en `cloned_app.R`.

| Variable | Uso Típico |
|----------|------------|
| `primary` | Botones principales, enlaces, pestañas activas. |
| `success` | Mensajes de aprobación, indicadores positivos. |
| `warning` | Alertas, estados cuestionables. |
| `danger` | Errores, estados no satisfactorios. |

---

## Controles de Diseño (Layout)

La aplicación permite ajustar el ancho de los paneles laterales dinámicamente.

| Control | Input ID | Rango | Defecto | Descripción |
|---------|----------|-------|---------|-------------|
| Ancho Navegación | `nav_width` | 1-5 | 2 | Ancho de la barra de navegación izquierda (columnas Bootstrap). |
| Ancho Sidebar | `analysis_sidebar_width` | 2-6 | 3 | Ancho del panel de parámetros en las pestañas de análisis. |

Esto es útil para adaptarse a diferentes tamaños de pantalla (laptops vs monitores anchos).

---

## Agregar Nuevos Contaminantes

La aplicación detecta **dinámicamente** los contaminantes desde los archivos cargados. Generalmente **no se requiere código** para añadir uno nuevo.

### Pasos
1.  Asegúrese de que sus archivos CSV (`homogeneity.csv`, `summary_n*.csv`) contengan el nuevo código en la columna `pollutant`.
2.  Ejemplo:
    ```csv
    pollutant,level,value
    PM2.5,low,15.2
    PM2.5,high,45.3
    ```
3.  La aplicación actualizará automáticamente los selectores desplegables (`selectInput`) al cargar los datos.

### Configuración Específica (Opcional)
Si necesita unidades específicas o nombres largos para mostrar en la UI, puede extender un dataframe de configuración interno (si existe) o modificar los `renderText` correspondientes.

---

## Agregar Nuevos Niveles

Similar a los contaminantes, los niveles se detectan automáticamente (`unique(df$level)`). Simplemente use el nuevo nivel en sus archivos CSV (ej: `medium-high`, `trace-level`).

---

## Extender el Paquete `ptcalc`

Para agregar un nuevo método estadístico:

### 1. Crear la Función
Cree un nuevo archivo R en `ptcalc/R/`, por ejemplo `new_method.R`.

```r
#' Calcular Estimador Hampel
#' @export
calculate_hampel <- function(x, k = 1.4826) {
  # Implementación...
}
```

### 2. Documentar y Exportar
Ejecute desde la consola de R:
```r
devtools::document("ptcalc")
```

### 3. Reinstalar/Recargar
```r
devtools::load_all("ptcalc") # Para desarrollo
# O
devtools::install("ptcalc") # Para producción
```

### 4. Integrar en la App
Modifique `cloned_app.R` para usar la nueva función, por ejemplo agregándola a un `switch` en la lógica de cálculo de puntajes o valor asignado.

---

## Personalizar Informes

Los informes se generan usando plantillas RMarkdown ubicadas en `reports/report_template.Rmd`.

### Modificar la Plantilla
1.  Edite `reports/report_template.Rmd`.
2.  Puede cambiar el texto estático, agregar logos o reorganizar secciones.
3.  Para cambiar estilos de Word (fuentes, encabezados), modifique el archivo de referencia `styles.docx` (si se utiliza) o cree uno nuevo y enlácelo en el encabezado YAML:
    ```yaml
    output:
      word_document:
        reference_docx: "mi_estilo.docx"
    ```

---

## Internacionalización

La aplicación está actualmente en Español. Para traducirla:
1.  Identifique las cadenas de texto en `ui` (títulos, etiquetas).
2.  Reemplácelas directamente o cree un archivo de mapeo de idiomas (`strings.R`) para cargar las etiquetas dinámicamente según una selección de idioma.
