# Módulo: Valor Consenso

## Descripción
Este módulo calcula el **valor de consenso** ($x_{pt}(2)$) y las estimaciones de la desviación estándar del PT ($\sigma_{pt}$) a partir de los resultados promediados de los participantes. Se utiliza como alternativa cuando no se dispone de un valor de referencia o para realizar comparaciones de compatibilidad metrológica.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 5152 - 5288 |
| UI | Accordion "Valor consenso" dentro de "Valor asignado" (Líneas 986 - 1006) |

## Dependencias
- **Reactives**: `pt_prep_data()`.
- **Inputs**: `input$consensus_run`, `input$assigned_pollutant`, `input$assigned_n_lab`, `input$assigned_level`.

## Lógica de Procesamiento
1. Se filtran los datos de `pt_prep_data()` para excluir al laboratorio de referencia (`participant_id != "ref"`).
2. Se agrupan los datos por participante para obtener una media única por combinación de analito, esquema (n) y nivel.
3. Se calculan los estadísticos robustos sobre el conjunto de medias resultantes.

## Reactives

### `consensus_results_cache()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Almacena los resultados de consenso para todas las combinaciones procesadas. |

### `consensus_selected()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Recupera del cache los resultados específicos para el analito, esquema y nivel seleccionados en la interfaz. |
| Depende de | `consensus_trigger()`, `input$assigned_pollutant`, `input$assigned_n_lab`, `input$assigned_level` |

## Outputs

### `output$consensus_summary_table`
- **Tipo**: renderTable
- **Descripción**: Tabla resumen con los valores de la mediana, MAD, MADe, nIQR y el número total de participantes incluidos.

### `output$consensus_input_table`
- **Tipo**: renderDataTable
- **Descripción**: Muestra la lista de participantes y sus medias calculadas que sirvieron de entrada para los estadísticos de consenso.

## Fórmulas y Cálculos

### Valor Consenso
- **$x_{pt}(2)$:** Mediana de las medias de los participantes.

### Desviaciones Robustas ($\sigma_{pt}$)
1. **MADe (Método 2a):** 
   - $MAD = \text{mediana}(|x_i - \text{mediana}(x_i)|)$
   - $\sigma_{pt,2a} = 1.483 \times MAD$
2. **nIQR (Método 2b):**
   - $\sigma_{pt,2b} = 0.7413 \times (Q_3 - Q_1)$

## Referencias
- ISO 13528:2022 Sección 6.2 y Anexo C.
