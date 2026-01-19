# Módulo: Generación de Informes

## Descripción
Exportación de resultados consolidados a documentos Word (.docx) y HTML mediante RMarkdown.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| Template | `reports/report_template.Rmd` |
| UI | `tabPanel("Generación de informes")` |

## Parámetros de Entrada
| Parámetro | Descripción |
|-----------|-------------|
| `report_n_lab` | Esquema PT seleccionado |
| `report_level` | Nivel de concentración |
| `report_method` | Método de valor asignado (1, 2a, 2b, 3) |
| `report_metric` | Puntaje principal (z, z', ζ, En) |
| `report_k` | Factor de cobertura |

## Reactives de Apoyo
- `grubbs_summary()`: Tabla de valores atípicos
- `report_xpt_summary()`: Valores asignados
- `report_homogeneity_summary()`: Homogeneidad
- `report_stability_summary()`: Estabilidad
- `report_heatmaps()`: Visualizaciones

## Formatos de Salida
- Word (DOCX)
- HTML
