# Manual del Desarrollador - Aplicación PT/ptcalc

**Entregable:** 08 - Versión Beta y Documentación Final  
**Fecha:** 2026-01-24  
**Versión:** 1.0  
**Autor:** UNAL/INM  

---

## Índice

1. [Arquitectura del Sistema](#arquitectura-del-sistema)
2. [Dependencias y Paquetes R](#dependencias-y-paquetes-r)
3. [Estructura de Archivos](#estructura-de-archivos)
4. [Cómo Ejecutar la Aplicación](#cómo-ejecutar-la-aplicación)
5. [Extender y Modificar la Aplicación](#extender-y-modificar-la-aplicación)
6. [Troubleshooting Común](#troubleshooting-común)
7. [Referencias de Normas ISO](#referencias-de-normas-iso)

---

## Arquitectura del Sistema

### Vista General

La aplicación sigue una arquitectura MVC (Modelo-Vista-Controlador) con las siguientes capas:

```
┌─────────────────────────────────────────────────────────┐
│                    Capa de Presentación                  │
│                    (UI - Shiny)                          │
│  - Pestañas de navegación                                 │
│  - Tablas DT interactivas                                 │
│  - Gráficos ggplot2/plotly                                │
│  - Botones de descarga                                    │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Capa de Lógica                        │
│                  (Server - Shiny)                        │
│  - Reactive values                                         │
│  - EventReactive para cálculos                            │
│  - Filtros de datos                                       │
│  - Coordinación de funciones                              │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Capa de Negocio                       │
│              (funciones_finales.R)                       │
│  - Cálculos estadísticos robustos                         │
│  - Evaluación de homogeneidad/estabilidad                 │
│  - Cálculo de puntajes (z, z', zeta, En)                  │
│  - Funciones de utilidad                                  │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                    Capa de Datos                         │
│              (Archivos CSV)                              │
│  - homogeneity.csv                                        │
│  - stability.csv                                          │
│  - summary_n4.csv                                         │
│  - participants_data4.csv                                 │
└─────────────────────────────────────────────────────────┘
```

### Separación de Responsabilidades

1. **Modelo (`funciones_finales.R`)**
   - Funciones puras sin dependencias de Shiny
   - Cálculos matemáticos según ISO 13528:2022
   - Lógica de negocio reutilizable
   - Testeable independientemente de la UI

2. **Vista (`ui` en `app_final.R`)**
   - Definición de componentes de interfaz
   - Layout y navegación
   - No contiene lógica de cálculo

3. **Controlador (`server` en `app_final.R`)**
   - Orquestación de reactividad
   - Llamadas a funciones del modelo
   - Gestión de estado de la aplicación

---

## Dependencias y Paquetes R

### Paquetes Requeridos

```r
# Aplicación web y UI
library(shiny)          # Framework de aplicación web
library(bslib)          # Bootstrap theme (opcional)

# Manipulación de datos
library(tidyverse)      # Conjunto de paquetes tidyverse
  # dplyr    - Manipulación de data.frames
  # tidyr    - Transformación de datos
  # ggplot2  - Visualización
  # readr    - Lectura de CSV
  # purrr    - Programación funcional

# Tablas interactivas
library(DT)             # DataTables para R

# Gráficos interactivos
library(plotly)         # Gráficos interactivos
```

### Versión Mínima de R

- **R >= 4.0.0** recomendado
- Probado en R 4.2.0 y superiores

### Instalación de Dependencias

```r
# Instalar todos los paquetes requeridos
install.packages(c(
  "shiny", "tidyverse", "DT", "plotly"
))
```

---

## Estructura de Archivos

### Directorio de Deliverable 08

```
deliv/08_beta/
├── app_final.R                 # Aplicación Shiny final
├── R/
│   └── funciones_finales.R     # Librería de funciones standalone
├── md/
│   └── manual_desarrollador.md # Este archivo
└── tests/
    ├── test_08_end_to_end.R    # Test end-to-end
    └── test_08_end_to_end.md   # Guía de prueba
```

### Archivos de Datos (Ubicación: `data/`)

```
data/
├── homogeneity.csv            # Datos de homogeneidad (g muestras, m réplicas)
├── stability.csv              # Datos de estabilidad
├── summary_n4.csv             # Datos consolidados de participantes
└── participants_data4.csv     # Tabla de instrumentación
```

### Descripción de Archivos Clave

#### `app_final.R`
- **Propósito:** Aplicación Shiny consolidada
- **Entradas:** 4 archivos CSV (precargados)
- **Salidas:** Tablas DT, gráficos plotly, descargas CSV
- **Dependencias:** shiny, tidyverse, DT, plotly, funciones_finales.R

#### `funciones_finales.R`
- **Propósito:** Librería de funciones standalone
- **Funciones exportadas:** ~30 funciones de cálculo
- **Dependencias:** Ninguna (solo R base)

---

## Cómo Ejecutar la Aplicación

### Opción 1: Desde la Consola de R

```r
# Cambiar al directorio del deliverable
setwd("deliv/08_beta")

# Ejecutar la aplicación
shiny::runApp("app_final.R")
```

### Opción 2: Desde Terminal

```bash
# Desde el directorio raíz del proyecto
Rscript deliv/08_beta/app_final.R
```

### Opción 3: Usando el atajo en RStudio

1. Abrir `deliv/08_beta/app_final.R` en RStudio
2. Click en el botón "Run App" en la esquina superior derecha

### Configuración de Datos

La aplicación carga automáticamente los 4 archivos CSV desde `../data/`. Asegúrese de que:

1. Los archivos existan en el directorio `data/`
2. El formato CSV sea válido (coma como separador)
3. Las columnas requeridas estén presentes

---

## Extender y Modificar la Aplicación

### Agregar Nuevo Analito

1. **Preparar el archivo CSV:**
   - Formato: debe coincidir con `summary_n4.csv`
   - Columnas requeridas: `pollutant`, `level`, `n_lab`, `participant_id`, `mean_value`, `sd_value`

2. **Agregar datos de homogeneidad/estabilidad:**
   - Crear entradas en `homogeneity.csv` y `stability.csv`
   - Seguir el formato existente

3. **Probar:**
   - Reiniciar la aplicación
   - Seleccionar el nuevo analito desde el dropdown

### Agregar Nuevo Puntaje

1. **Implementar función de cálculo en `funciones_finales.R`:**
```r
#' Calcular nuevo puntaje
#'
#' Descripción del puntaje...
#'
#' @param x Valor del participante
#' @param x_pt Valor asignado
#' @param ... Otros parámetros
#' @return Valor del puntaje
#'
#' @export
calculate_new_score <- function(x, x_pt, ...) {
  # Implementación
  result <- (x - x_pt) / ...
  return(result)
}
```

2. **Agregar función de evaluación:**
```r
#' Evaluar nuevo puntaje
#' @export
evaluate_new_score <- function(score) {
  if (!is.finite(score)) return("N/A")
  if (abs(score) <= 2) return("Satisfactorio")
  # ... más criterios
}
```

3. **Integrar en `app_final.R`:**
   - Agregar cálculo en `resultados_puntajes$reactive()`
   - Agregar columnas en el `select()` final
   - Actualizar tablas de resumen

### Modificar Gráficos

1. **Editar `ui`:**
   - Modificar o agregar `plotlyOutput()` en la pestaña correspondiente

2. **Editar `server`:**
   - Localizar la función `renderPlotly()` correspondiente
   - Modificar el código `ggplot2`

Ejemplo de modificación de gráfico:
```r
output$mi_nuevo_grafico <- renderPlotly({
  res <- resultados_puntajes()
  if (is.null(res)) return(NULL)
  
  p <- ggplot(res, aes(x = participant_id, y = mean_value)) +
    geom_col(fill = "steelblue", alpha = 0.7) +  # Cambiar tipo de gráfico
    labs(title = "Mi nuevo gráfico") +           # Cambiar título
    theme_minimal()
  
  ggplotly(p)
})
```

### Agregar Nueva Pestaña

1. **En `ui` - Agregar nueva pestaña:**
```r
tabPanel(
  title = "Mi Nueva Pestaña",
  h4("Título de la pestaña"),
  plotlyOutput("mi_nuevo_grafico"),
  DTOutput("mi_nueva_tabla")
)
```

2. **En `server` - Implementar lógica:**
```r
# Gráfico nuevo
output$mi_nuevo_grafico <- renderPlotly({
  # Lógica del gráfico
})

# Tabla nueva
output$mi_nueva_tabla <- renderDT({
  # Lógica de la tabla
})
```

### Cambiar Método de Cálculo de sigma_pt

El usuario puede seleccionar entre tres métodos desde la UI:

1. **MADe** (Scaled Median Absolute Deviation)
2. **nIQR** (Normalized Interquartile Range)  
3. **Algoritmo A** (Algoritmo iterativo robusto)

Para agregar un nuevo método:

1. Implementar la función en `funciones_finales.R`
2. Agregar opción en `selectInput("sigma_method")` en `ui`
3. Agregar caso en `switch(input$sigma_method, ...)` en `server`

---

## Troubleshooting Común

### Problema: "No se encontró el archivo CSV"

**Solución:**
- Verificar que los archivos están en `data/` relativo a `deliv/08_beta/`
- Verificar nombres de archivo (case-sensitive en Linux/Mac)
- Usar `list.files("../data/")` para listar archivos disponibles

### Problema: "Error en calculate_niqr: se requieren al menos 2 valores"

**Solución:**
- Verificar que hay suficientes datos después de filtrar
- El filtrado por analito/nivel/n_lab puede dejar menos de 2 participantes
- Revisar la tabla `tabla_participantes` para ver datos disponibles

### Problema: "Gráficos no se muestran"

**Solución:**
- Asegurarse de que `input$calcular_puntajes` ha sido presionado
- Verificar que hay datos disponibles en `filtered_data()`
- Revisar la consola de R para mensajes de error

### Problema: "Descarga de CSV vacía"

**Solución:**
- Verificar que `resultados_puntajes()` no es NULL
- Asegurarse de haber presionado "Calcular Puntajes PT"
- Revisar que hay participantes distintos de "ref"

### Problema: "Valores NA en puntajes"

**Solución:**
- Verificar que `sigma_pt` es finito y mayor que 0
- Revisar que los valores de mean_value son finitos
- Verificar que `u_xpt` se calculó correctamente

### Problema: "Performance lenta"

**Solución:**
- Reducir el número de filas mostradas en `DTOutput` con `head()`
- Usar `dplyr::filter()` para reducir datos antes de cálculos
- Limitar número de observaciones para gráficos

### Problema: "Algoritmo A no converge"

**Solución:**
- El algoritmo puede no converger para datos con alta dispersión
- Verificar que hay al menos 3 observaciones válidas
- Intentar con otros métodos (MADe o nIQR)

---

## Referencias de Normas ISO

### ISO 13528:2022

**Título:** Statistical methods for use in proficiency testing by interlaboratory comparison

**Secciones relevantes:**
- **Sección 9.2:** Homogeneity assessment
- **Sección 9.3:** Stability assessment  
- **Sección 9.4:** Robust statistics (nIQR, MADe)
- **Sección 10.2:** z-score
- **Sección 10.3:** z'-score
- **Sección 10.4:** zeta score
- **Sección 10.5:** En score
- **Anexo C:** Algorithm A (robust statistics)

### ISO 17043:2024

**Título:** Conformity assessment — General requirements for proficiency testing

**Secciones relevantes:**
- **Requisitos generales** para esquemas de PT
- **Validación de homogeneidad y estabilidad**
- **Evaluación de desempeño de participantes**

### Implementación de Normas

| Función | Norma ISO | Sección | Descripción |
|---------|-----------|---------|-------------|
| `calculate_niqr()` | 13528:2022 | 9.4 | nIQR = 0.7413 × IQR |
| `calculate_mad_e()` | 13528:2022 | 9.4 | MADe = 1.483 × MAD |
| `run_algorithm_a()` | 13528:2022 | Anexo C | Algoritmo iterativo robusto |
| `calculate_homogeneity_stats()` | 13528:2022 | 9.2 | ANOVA para homogeneidad |
| `calculate_homogeneity_criterion()` | 13528:2022 | 9.2.3 | c = 0.3 × σ_pt |
| `calculate_z_score()` | 13528:2022 | 10.2 | z = (x - x_pt)/σ_pt |
| `calculate_z_prime_score()` | 13528:2022 | 10.3 | z' = (x - x_pt)/√(σ_pt² + u_xpt²) |
| `calculate_zeta_score()` | 13528:2022 | 10.4 | ζ = (x - x_pt)/√(u_x² + u_xpt²) |
| `calculate_en_score()` | 13528:2022 | 10.5 | En = (x - x_pt)/√(U_x² + U_xpt²) |

---

## Notas Adicionales

### Convenciones de Código

- **Comentarios:** En español
- **Nombres de funciones:** snake_case (e.g., `calculate_z_score`)
- **Nombres de variables:** snake_case (e.g., `mean_value`, `sigma_pt`)
- **Indentación:** 2 espacios
- **Asignación:** Operador `<-` (no `=`)

### Testing

Todas las funciones en `funciones_finales.R` están documentadas con roxygen2 y pueden ser probadas independientemente de la aplicación Shiny.

### Licencia

MIT License - Universidad Nacional de Colombia / Instituto Nacional de Metrología

---

**Documento versión:** 1.0  
**Última actualización:** 2026-01-24
