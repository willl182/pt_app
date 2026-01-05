# Módulo: Valor de Referencia

## Descripción
Este módulo se encarga de identificar y presentar el valor proporcionado por el laboratorio de referencia. En la aplicación, se asume que existe un participante con el identificador único `"ref"`, cuyo resultado se utiliza como valor asignado principal ($x_{pt}(1)$) en las comparaciones de desempeño.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 5289 - 5320 |
| UI | Accordion "Valor de referencia" dentro de "Valor asignado" (Líneas 1008 - 1021) |

## Dependencias
- **Reactives**: `pt_prep_data()`.
- **Inputs**: `input$assigned_pollutant`, `input$assigned_n_lab`, `input$assigned_level`.

## Lógica de Procesamiento
La aplicación filtra el conjunto de datos preparado (`pt_prep_data()`) buscando específicamente registros donde:
1. `participant_id == "ref"`
2. Coincidan el analito, esquema y nivel seleccionados por el usuario.

Si no se encuentra un registro con el ID `"ref"`, la sección mostrará un mensaje indicando la ausencia de datos de referencia para esa selección.

## Reactives

### `reference_table_data()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Filtra los datos de los participantes para extraer únicamente la fila correspondiente a la referencia. |
| Depende de | `pt_prep_data()`, `input$assigned_pollutant`, `input$assigned_n_lab`, `input$assigned_level` |
| Retorna | DataFrame (generalmente de una fila) con los datos del analito de referencia. |

## Outputs

### `output$reference_table`
- **Tipo**: renderDataTable
- **Descripción**: Muestra una tabla con el nombre del analito, el esquema, el nivel, el valor medio y la desviación estándar declarada por el laboratorio de referencia.

## Fórmulas y Cálculos
- **$x_{pt}(1)$:** Definido directamente como la media reportada por el laboratorio de referencia (`mean_value` donde `participant_id == "ref"`).
- **$u_{ref}$:** Se deriva de la desviación estándar declarada (`sd_value`) si está disponible.

## Referencias
- ISO 17043:2023.
- ISO 13528:2022 Sección 6.2.
