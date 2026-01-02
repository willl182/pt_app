# Módulo: Detalle por Participante

## Descripción
Este módulo genera una interfaz dinámica personalizada para cada laboratorio participante. Su objetivo es permitir la visualización detallada y aislada del desempeño de un laboratorio específico a través de todos los analitos y niveles en los que participó, facilitando el análisis individualizado.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 3768 - 3850 (Lógica dinámica de pestañas) |
| UI | `tabPanel("Participantes")` (Líneas 1193 - 1208) |

## Dependencias
- **Reactives**: `participants_combined_data()` (Proviene de la consolidación de puntajes).
- **Inputs**: Depende indirectamente de la ejecución del cálculo de puntajes.

## Lógica de Generación Dinámica
A diferencia de otros módulos con estructura fija, este módulo utiliza `renderUI` para construir un conjunto de pestañas (`tabsetPanel`) basado en los IDs únicos reales encontrados en los datos de entrada (excluyendo el laboratoro `"ref"`).

1. Obtiene la lista ordenada de IDs de participantes.
2. Crea un `tabPanel` para cada ID.
3. Genera identificadores de salida únicos para cada participante (ej. `participant_table_Lab123`, `participant_plot_Lab123`).

## Reactives / Server Helpers

### `participants_combined_data()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Reactive que consolida los resultados de todos los métodos evaluados. |

## Outputs Dinámicos

### `output$scores_participant_tabs`
- **Tipo**: renderUI
- **Descripción**: El contenedor principal que alberga las pestañas de todos los participantes.

### `output$participant_table_[ID]`
- **Tipo**: renderDataTable
- **Descripción**: Tabla específica que resume:
  - Combinación (Analito/Esquema).
  - Nivel.
  - Resultado reportado vs Valor asignado ($x_{pt}$).
  - Incertidumbres ($u_{xpt}$, $u_{xpt,def}$).
  - Todos los puntajes (**z**, **z'**, **ζ**, **En**) y sus evaluaciones.

### `output$participant_plot_[ID]`
- **Tipo**: renderPlotly
- **Descripción**: Gráfico de dos paneles:
  - **Comparación Directa**: Resultado del participante vs. Referencia por nivel.
  - **Tendencia de Puntaje**: Gráfico de evolución del puntaje Z con franjas de tolerancia ($\pm 2, \pm 3$).

## Visualizaciones
Los gráficos de los participantes incluyen:
- Puntos azules para los resultados del lab.
- Puntos rojos y línea punteada para el valor de referencia.
- Líneas de control en los gráficos de puntaje para indicar zonas satisfactorias, cuestionables y no satisfactorias.

## Referencias
- ISO 13528:2022 Sección 11.2 (Reportes individuales).
