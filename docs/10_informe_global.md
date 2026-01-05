# Módulo: Informe Global

## Descripción
Este módulo proporciona una visión consolidada y comparativa de los resultados de todos los participantes para todos los analitos y niveles evaluados. Su función principal es facilitar la identificación de tendencias, desempeños atípicos y la validación cruzada de resultados mediante visualizaciones matriciales (heatmaps).

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 2409 - 3900 |
| UI | `tabPanel("Informe global")` (Líneas 1082 - 1192) |

## Dependencias
- **Reactives**: `scores_results_cache()`, `combine_scores_result()`.
- **Paletas de Colores**: `score_heatmap_palettes` (Definidas para z, z', zeta y En).

## Lógica de Consolidación
El módulo utiliza la función `combine_scores_result()` para unificar los datos almacenados en el cache de puntajes. Los datos se organizan en estructuras tabulares que permiten filtrar por:
- Método de valor asignado (Referencia, Consenso, Algoritmo A).
- Analito y nivel.
- ID del participante.

## Reactives

### `global_report_combos()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Genera el DataFrame base con todas las combinaciones de resultados y sus evaluaciones de desempeño. |
| Retorna | DataFrame con columnas `participant_id`, `pollutant`, `level`, `z_score_eval`, etc. |

### `global_report_summary()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Resume los parámetros estadísticos ($x_{pt}$, $\sigma_{pt}$, $u_{xpt}$) utilizados en cada combinación evaluada. |

## Visualizaciones (Heatmaps)
La aplicación genera mapas de calor interactivos para cada tipo de puntaje. La paleta de colores estándar es:
- **Satisfactorio**: Verde (`#00B050`).
- **Cuestionable**: Amarillo (`#FFEB3B`).
- **No satisfactorio**: Rojo (`#D32F2F`).
- **N/A**: Gris (`#BDBDBD`).

### Tipos de Heatmaps Disponibles:
1. **Heatmap de Puntajes Z**: Visión general del desempeño relativo.
2. **Heatmap de Puntajes Z'**: Desempeño considerando la incertidumbre del valor asignado.
3. **Heatmap de Puntajes Zeta**: Evaluación de la coherencia de la incertidumbre estándar.
4. **Heatmap de Puntajes En**: Evaluación de la compatibilidad metrológica individual ($|En| \leq 1$).

## Outputs

### `output$global_scores_heatmap`
- **Tipo**: renderPlotly
- **Descripción**: Gráfico interactivo que muestra los participantes en el eje Y y las combinaciones Analito/Nivel en el eje X, coloreado según la evaluación del puntaje seleccionado.

### `output$global_parameter_summary`
- **Tipo**: renderTable
- **Descripción**: Resumen consolidado de los valores asignados e incertidumbres para todo el esquema de PT.

## Referencias
- ISO 13528:2022 Sección 11 (Representación gráfica de puntajes).
