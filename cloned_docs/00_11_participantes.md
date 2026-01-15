# Módulo: Detalle por Participante

## Descripción
Genera pestañas dinámicas con el detalle de desempeño para cada laboratorio participante.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| UI | `tabPanel("Participantes")` |

## Generación Dinámica
El módulo usa `renderUI` para crear un `tabPanel` por cada participante único (excluyendo `"ref"`).

## Contenido por Participante
1. **Tabla de Resultados**: Valores, puntajes y evaluaciones
2. **Gráfico Comparativo**: Resultado vs Referencia por nivel
3. **Gráfico de Tendencia**: Evolución del z-score con líneas de control

## Outputs Dinámicos
- `output$scores_participant_tabs`: Contenedor principal
- `output$participant_table_[ID]`: Tabla individual
- `output$participant_plot_[ID]`: Gráfico individual
