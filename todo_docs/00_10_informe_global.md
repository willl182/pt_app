# Módulo: Informe Global

## Descripción
Vista consolidada de resultados de todos los participantes mediante tablas resumen y mapas de calor interactivos.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| UI | `tabPanel("Informe global")` |

## Paleta de Colores
| Evaluación | Color |
|------------|-------|
| Satisfactorio | Verde (#00B050) |
| Cuestionable | Amarillo (#FFEB3B) |
| No satisfactorio | Rojo (#D32F2F) |
| N/A | Gris (#BDBDBD) |

## Reactives
- `global_report_combos()`: Combinaciones evaluadas
- `global_report_summary()`: Resumen de parámetros
- `global_report_overview()`: Vista general

## Visualizaciones
- Heatmaps por tipo de puntaje (z, z', ζ, En)
- Tablas resumen por método de valor asignado
