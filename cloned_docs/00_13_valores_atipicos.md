# Módulo: Valores Atípicos

## Descripción
Detección de valores anómalos mediante la prueba de Grubbs.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| Librería | `outliers` |
| UI | `tabPanel("Valores Atípicos")` |

## Método: Prueba de Grubbs
- **Requisito**: $n \geq 3$ participantes
- **Función**: `outliers::grubbs.test()`
- **Criterio**: $p < 0.05$ indica valor atípico

## Reactive
### `grubbs_summary()`
Genera tabla maestra con:
- Contaminante, Nivel
- Participantes evaluados
- Valor p
- Atípicos detectados (0/1)
- ID y valor del participante sospechoso

## Visualizaciones
- `output$outliers_histogram`: Distribución con curva de densidad
- `output$outliers_boxplot`: Diagrama de caja con atípicos resaltados

## Referencias
- ISO 13528:2022 Sección 7.3
- Grubbs, F. E. (1969)
