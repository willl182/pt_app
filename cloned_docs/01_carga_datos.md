# Módulo: Carga de Datos

## Descripción
Este módulo gestiona la carga y validación de los archivos CSV de entrada. Es el punto de partida para todos los análisis de la aplicación.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| Líneas | 79 - 151 |
| UI | `tabPanel("Carga de datos")` |

## Reactives Principales

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
| Descripción | Consolida archivos resumen de participantes. Extrae `n_lab` del nombre del archivo. |
| Depende de | `input$summary_files` |
| Retorna | DataFrame agregado por `participant_id`, `pollutant`, `level`, `n_lab`. |

## Formatos de Entrada

### homogeneity.csv / stability.csv
| Columna | Tipo | Descripción |
|---------|------|-------------|
| `pollutant` | character | Nombre del gas |
| `level` | character | Nivel de concentración |
| `replicate` | numeric | Número de réplica |
| `value` | numeric | Medición |

### summary_n*.csv
| Columna | Tipo | Descripción |
|---------|------|-------------|
| `participant_id` | character | ID del lab o "ref" |
| `pollutant` | character | Analito |
| `level` | character | Nivel |
| `mean_value` | numeric | Media del participante |
| `sd_value` | numeric | Desviación estándar |
