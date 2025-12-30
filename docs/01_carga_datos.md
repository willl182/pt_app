# Módulo: Carga de Datos

## Descripción
Este módulo es el punto de entrada de la aplicación. Gestiona la carga de archivos CSV por parte del usuario, valida su estructura y prepara los datos básicos para todos los análisis posteriores (homogeneidad, estabilidad y evaluación de participantes).

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 67 - 211 |
| UI | `tabPanel("Carga de datos")` (Líneas 790 - 820) |

## Dependencias
- **Inputs**:
  - `input$hom_file`: Archivo CSV de homogeneidad.
  - `input$stab_file`: Archivo CSV de estabilidad.
  - `input$summary_files`: Archivos CSV consolidado de participantes.

## Reactives

### `hom_data_full()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Carga y valida el archivo de homogeneidad. |
| Depende de | `input$hom_file` |
| Retorna | DataFrame con columnas `value`, `pollutant`, `level`. |

### `stab_data_full()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Carga y valida el archivo de estabilidad. |
| Depende de | `input$stab_file` |
| Retorna | DataFrame con columnas `value`, `pollutant`, `level`. |

### `pt_prep_data()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Consolida múltiples archivos resumen de participantes. Extrae el número de laboratorios (n) del nombre del archivo. |
| Depende de | `input$summary_files` |
| Retorna | DataFrame agregado por `participant_id`, `pollutant`, `level`, `n_lab`. |

## Estructuras de Datos (ReactiveValues)

### `rv`
| Atributo | Descripción |
|----------|-------------|
| `rv$raw_summary_data` | Almacena los datos crudos de participantes antes de la agregación para cálculos específicos. |
| `rv$raw_summary_data_list` | Lista de DataFrames originales cargados desde los archivos resumen. |

## Triggers de Ejecución
El módulo gestiona diversos "triggers" que notifican a otras partes de la app cuando los datos han cambiado o deben recalcularse:
- `analysis_trigger`: Se activa al pulsar el botón "Ejecutar" en el módulo de homogeneidad/estabilidad.
- `algoA_trigger`, `consensus_trigger`, `scores_trigger`: Se activan o resetean al cargar nuevos archivos resumen.

## Formatos de Archivo Esperados

### Homogeneidad / Estabilidad
| Columna | Tipo | Descripción |
|---------|------|-------------|
| `pollutant` | character | Nombre del gas o analito. |
| `level` | character | Nivel de concentración (P1, P2, etc.). |
| `replicate` | numeric | Número de réplica (1, 2, etc.). |
| `value` | numeric | Resultado de la medición. |

### Resumen de Participantes (`summary_n*.csv`)
| Columna | Tipo | Descripción |
|---------|------|-------------|
| `participant_id` | character | ID único del participante o "ref" para referencia. |
| `pollutant` | character | Nombre del analito. |
| `level` | character | Nivel de concentración. |
| `mean_value` | numeric | Media de los resultados del participante. |
| `sd_value` | numeric | Desviación estándar del participante. |
