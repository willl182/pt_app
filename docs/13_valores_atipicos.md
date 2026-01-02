# Módulo: Detección de Valores Atípicos

## Descripción
Este módulo implementa técnicas estadísticas para la identificación de resultados anómalos (outliers) en los datos reportados por los participantes. Utiliza principalmente la **Prueba de Grubbs**, recomendada por la norma **ISO 13528:2022**, para detectar si un valor extremo en una muestra pequeña proviene de la misma distribución que el resto.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 3954 - 4023 (Lógica de la prueba) y 5360 - 5424 (Visualización) |
| UI | `tabPanel("Valores Atípicos")` (Líneas 918 - 936) |

## Dependencias
- **Librería**: `outliers`.
- **Reactives**: `pt_prep_data()`.
- **Inputs**: `input$outliers_pollutant`, `input$outliers_level`.

## Lógica de la Prueba (Grubbs)
La prueba de Grubbs se aplica sobre las medias de los resultados de los participantes para cada combinación de analito, esquema (n) y nivel.

1. **Requisito**: La prueba requiere al menos 3 participantes evaluados ($n \geq 3$).
2. **Ejecución**: Se utiliza `outliers::grubbs.test(subset_data$mean_value)`.
3. **Identificación**: Si el valor p es menor a 0.05 ($p < 0.05$), se identifica el valor más alejado de la media mediante el cálculo de residuos estandarizados (Z-scores internos).

## Reactives

### `grubbs_summary()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Genera una tabla maestra con el resultado de la prueba de Grubbs para todas las combinaciones posibles. |
| Retorna | DataFrame con `Contaminante`, `Nivel`, `Valor_p`, `Atipicos_detectados` y el ID del participante sospechoso. |

### `outliers_plot_data()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Filtra los datos correspondientes a la selección de la interfaz para alimentar los gráficos. |

## Outputs

### `output$grubbs_summary_table`
- **Tipo**: renderDataTable
- **Descripción**: Muestra el resumen de atípicos para todo el conjunto de datos cargado.

### `output$outliers_histogram`
- **Tipo**: renderPlotly
- **Descripción**: Histograma con curva de densidad que visualiza la distribución de los resultados de los participantes.

### `output$outliers_boxplot`
- **Tipo**: renderPlotly
- **Descripción**: Diagrama de caja y bigotes que resalta los valores fuera del rango esperado (marcando atípicos en rojo).

## Visualizaciones
- **Histograma**: Permite observar la normalidad y sesgo de los datos.
- **Boxplot**: Útil para identificar visualmente valores que se alejan significativamente del cuartil superior o inferior (1.5 * IQR).

## Referencias
- ISO 13528:2022 Sección 7.3 (Detección de valores atípicos).
- Grubbs, F. E. (1969). Procedures for detecting outlying observations in samples.
