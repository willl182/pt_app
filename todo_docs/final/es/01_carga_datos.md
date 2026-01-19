# Módulo: Carga de Datos

## Descripción

Este módulo gestiona la carga y validación de los archivos CSV de entrada. Es el punto de partida para todos los análisis de la aplicación, asegurando la integridad de los datos antes de comenzar cualquier procesamiento estadístico. El sistema está diseñado para manejar datos de homogeneidad, estabilidad y resultados de participantes de múltiples rondas de ensayos de aptitud (PT).

---

## Ubicación en el Código

| Elemento | Valor |
|----------|-------|
| **Archivo** | `cloned_app.R` |
| **Líneas (Servidor)** | 79 - 156 |
| **Pestaña UI** | `tabPanel("Carga de datos")` (Líneas 730-759) |
| **Dependencias** | `vroom`, `stringr`, `dplyr`, `shiny` |

---

## Arquitectura y Flujo de Datos

El proceso de carga de datos activa una cadena de expresiones reactivas que validan, almacenan y transforman los datos para su uso en módulos posteriores.

### Diagrama de Flujo (Mermaid)

```mermaid
flowchart TB
    subgraph FILES["Archivos Cargados"]
        HOM["homogeneity.csv"]
        STAB["stability.csv"]
        SUM["summary_n*.csv"]
    end

    subgraph VALIDATION["Capa de Validación"]
        V1["hom_data_full()"]
        V2["stab_data_full()"]
        V3["pt_prep_data()"]
    end

    subgraph STORAGE["Almacenamiento Reactivo"]
        RV1["rv$raw_summary_data"]
        RV2["rv$raw_summary_data_list"]
    end

    subgraph PROCESSING["Procesamiento de Datos"]
        WIDE["get_wide_data()"]
        HOM_RUN["homogeneity_run()"]
        STAB_RUN["stability_run()"]
        CONSENSUS["consensus_run()"]
        SCORES["compute_scores_for_selection()"]
    end

    HOM --> V1
    STAB --> V2
    SUM --> V3
    
    V1 --> HOM_RUN & WIDE
    V2 --> STAB_RUN
    V3 --> RV1 & RV2
    
    RV1 --> SCORES
    RV2 --> CONSENSUS
```

---

## Reactives Principales

### `hom_data_full()`
Carga y valida el archivo de homogeneidad.

| Propiedad | Valor |
|-----------|-------|
| **Descripción** | Carga y valida el archivo CSV de homogeneidad |
| **Depende de** | `input$hom_file` |
| **Retorna** | DataFrame con columnas `value`, `pollutant`, `level` |
| **Validación** | Requiere columnas exactas: `value`, `pollutant`, `level` |

**Implementación:**
```r
hom_data_full <- reactive({
  req(input$hom_file)
  df <- vroom::vroom(input$hom_file$datapath, show_col_types = FALSE)
  validate(
    need(
      all(c("value", "pollutant", "level") %in% names(df)),
      "Error: El archivo de homogeneidad debe contener las columnas 'value', 'pollutant' y 'level'."
    )
  )
  df
})
```

### `stab_data_full()`
Carga y valida el archivo de estabilidad.

| Propiedad | Valor |
|-----------|-------|
| **Descripción** | Carga y valida el archivo CSV de estabilidad |
| **Depende de** | `input$stab_file` |
| **Retorna** | DataFrame con columnas `value`, `pollutant`, `level` |

**Implementación:**
```r
stab_data_full <- reactive({
  req(input$stab_file)
  df <- vroom::vroom(input$stab_file$datapath, show_col_types = FALSE)
  validate(
    need(
      all(c("value", "pollutant", "level") %in% names(df)),
      "Error: El archivo de estabilidad debe contener las columnas 'value', 'pollutant' y 'level'."
    )
  )
  df
})
```

### `pt_prep_data()`
Consolida múltiples archivos resumen de participantes, extrae el identificador de ronda (`n_lab`) y agrega los datos.

| Propiedad | Valor |
|-----------|-------|
| **Descripción** | Consolida archivos resumen, extrae `n_lab` y agrega datos |
| **Depende de** | `input$summary_files` |
| **Efectos Secundarios** | Puebla `rv$raw_summary_data` y `rv$raw_summary_data_list` |
| **Retorna** | DataFrame agrupado por `participant_id`, `pollutant`, `level`, `n_lab` |

**Implementación:**
```r
pt_prep_data <- reactive({
  req(input$summary_files)

  data_list <- lapply(seq_len(nrow(input$summary_files)), function(i) {
    df <- vroom::vroom(input$summary_files$datapath[i], show_col_types = FALSE)
    # Lógica de extracción de n_lab
    n <- as.integer(stringr::str_extract(input$summary_files$name[i], "\\d+"))
    df$n_lab <- n
    return(df)
  })

  if (length(data_list) == 0) return(NULL)

  raw_data <- do.call(rbind, data_list)
  if (is.null(raw_data) || nrow(raw_data) == 0) return(NULL)

  validate(
    need(
      all(c("participant_id", "pollutant", "level", "mean_value", "sd_value") %in% names(raw_data)),
      "Error: Los archivos resumen deben contener las columnas 'participant_id', 'pollutant', 'level', 'mean_value' y 'sd_value'."
    )
  )

  rv$raw_summary_data <- raw_data
  # Almacenar lista original para cálculos de consenso
  rv$raw_summary_data_list <- lapply(seq_len(nrow(input$summary_files)), function(i) {
    vroom::vroom(input$summary_files$datapath[i], show_col_types = FALSE)
  })

  raw_data %>%
    group_by(participant_id, pollutant, level, n_lab) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      sd_value = mean(sd_value, na.rm = TRUE),
      .groups = "drop"
    )
})
```

---

## Formatos de Archivos de Entrada

La aplicación espera tres tipos de archivos CSV. Los nombres de las columnas son sensibles a mayúsculas y minúsculas (preferiblemente minúsculas).

### 1. Datos de Homogeneidad (`homogeneity.csv`)
Contiene mediciones por duplicado para cada combinación de contaminante/nivel en múltiples ítems (muestras).

```csv
"pollutant","level","replicate","sample_id","value"
"co","2-umol/mol",1,1,2.0115
"co","2-umol/mol",2,1,2.0162
"so2","20-nmol/mol",1,1,19.70
"so2","20-nmol/mol",2,1,19.68
```

**Estructura Clave:**
- **replicate**: Número de réplica (usualmente 1 o 2).
- **sample_id**: Identificador del ítem físico.
- **Formato**: Formato largo (long format).

### 2. Datos de Estabilidad (`stability.csv`)
Misma estructura que el archivo de homogeneidad, pero representa las mediciones al final del periodo del PT.

### 3. Resumen de Participantes (`summary_n*.csv`)
Contiene resultados agregados de cada laboratorio participante.

**Patrón de nombre**: `summary_n(\d+).csv`. El número se extrae como `n_lab` (ej. `summary_n04.csv` -> `n_lab = 4`).

```csv
"pollutant","level","participant_id","replicate","sample_group","mean_value","sd_value"
"co","2-umol/mol","part_1",2,"1-10",2.025,0.012
"co","2-umol/mol","ref",1,"1-10",2.015,0.005
```

**Notas:**
- `participant_id = "ref"` designa al laboratorio de referencia.
- `mean_value` y `sd_value` son obligatorios.

---

## Reglas de Validación

| Validación | Regla | Mensaje de Error / Comportamiento |
|------------|-------|-----------------------------------|
| **Columnas (H/E)** | `value`, `pollutant`, `level` | "El archivo de [homogeneidad/estabilidad] debe contener las columnas..." |
| **Columnas (Resumen)** | `participant_id`, `pollutant`, `level`, `mean_value`, `sd_value` | "Los archivos resumen deben contener las columnas..." |
| **Tipos de Datos** | `value`, `mean_value`, `sd_value` deben ser numéricos | Error de vroom o validación de R |
| **Nombre de Archivo** | Los archivos resumen deben contener un número | `n_lab` se vuelve `NA` si no hay número |
| **Presencia de Archivo** | `req(input$file)` | Silencioso hasta que se sube el archivo |

---

## Convenciones de Nomenclatura

### Analitos (Pollutants)
Se recomienda el uso de códigos en minúsculas para consistencia.

| Analito | Correcto | Incorrecto |
|-----------|---------|------------|
| Dióxido de Azufre | `so2` | `SO2`, `Sulfur` |
| Monóxido de Carbono | `co` | `CO` |
| Ozono | `o3` | `O3`, `Ozone` |
| Óxido Nítrico | `no` | `NO` |
| Dióxido de Nitrógeno | `no2` | `NO2` |

### Niveles (Levels)
Formato recomendado: `{valor}-{unidad}`.

| Ejemplo | Correcto | Incorrecto |
|---------|---------|------------|
| Nivel Cero | `0-nmol/mol` | `0`, `zero`, `blank` |
| Conc. Baja | `20-nmol/mol` | `20`, `low` |
| Unidades Micro | `2-μmol/mol` | `2-umol/mol`, `2uM` |

---

## Mensajes de Error y Solución de problemas

| Mensaje de Error | Causa | Solución |
|------------------|-------|----------|
| "El archivo de homogeneidad debe contener las columnas 'value', 'pollutant' y 'level'" | Faltan cabeceras requeridas o hay error de mayúsculas. | Renombrar columnas a minúsculas exactas. |
| "No se encontraron datos para el analito" | El filtro de analito devolvió un resultado vacío. | Verificar que el nombre del analito en el archivo coincida con el selector de la app. |
| La aplicación muestra tablas vacías tras la carga | El archivo tiene cabeceras pero no filas de datos, o codificación incorrecta. | Verificar que el archivo tenga datos y esté codificado en UTF-8. |
| Los datos de participantes no aparecen | Desajuste entre `participant_id` o `pollutant` entre archivos. | Asegurar consistencia total de nombres entre todos los archivos subidos. |

---

## Detalles Técnicos Avanzados

### Invalidaicón de Caché
Cuando se sube un nuevo archivo en `input$summary_files`, se limpian todos los resultados cacheados para evitar persistencia de datos antiguos:

```r
observeEvent(input$summary_files, {
  algoA_results_cache(NULL)
  consensus_results_cache(NULL)
  scores_results_cache(NULL)
  # ... otros activadores (triggers)
}, ignoreNULL = FALSE)
```

### Función Auxiliar: `get_wide_data()`
Transforma los datos de formato largo a ancho para el análisis ANOVA.

```r
get_wide_data <- function(df, target_pollutant) {
  filtered <- df %>% filter(pollutant == target_pollutant)
  if (is.null(filtered) || nrow(filtered) == 0) return(NULL)
  
  filtered %>%
    select(-pollutant) %>%
    pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}
```

---

## Componentes de la Interfaz (UI)

| Elemento UI | ID de Entrada | Tipo | Propósito |
|-------------|---------------|------|-----------|
| Carga Homogeneidad | `hom_file` | `fileInput` | Subir `homogeneity.csv` |
| Carga Estabilidad | `stab_file` | `fileInput` | Subir `stability.csv` |
| Carga Resúmenes | `summary_files` | `fileInput` (múltiple) | Subir archivos `summary_n*.csv` |
| Estado de Carga | `data_upload_status` | `verbatimTextOutput` | Muestra el estado de la carga de archivos |

---

## Referencias Normativas

| Estándar | Sección | Aplicación |
|----------|---------|-------------|
| **ISO 13528:2022** | 7.2 / 7.3 | Requerimientos para ensayos de homogeneidad y estabilidad. |
| **ISO 17043:2024** | 5.4 | Requerimientos de gestión de datos para proveedores de PT. |

---

## Referencias Cruzadas
- **Formatos de Datos**: Ver [01a_data_formats.md](01a_data_formats.md) para esquemas detallados.
- **Análisis de Homogeneidad**: Ver [04_pt_homogeneity.md](../cloned_docs/04_pt_homogeneity.md).
- **Cálculo de Puntuaciones**: Ver [05_pt_scores.md](../cloned_docs/05_pt_scores.md).
- **Glosario**: Ver [00_glossary.md](00_glossary.md).
