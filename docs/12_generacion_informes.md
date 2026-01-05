# Módulo: Generación de Informes

## Descripción
Este módulo es el encargado de consolidar todos los resultados de los análisis (homogeneidad, estabilidad, valores atípicos y puntajes) en documentos profesionales descargables en formatos **Word (.docx)** y **HTML**. Utiliza plantillas de RMarkdown para estructurar la información técnica de acuerdo con los requisitos de informes de ensayos de aptitud.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 3901 - 4852 |
| UI | `tabPanel("Generación de informes")` (Líneas 1209 - 1270) |

## Dependencias
- **Librería principal**: `rmarkdown`.
- **Plantilla**: `reports/report_template.Rmd`.
- **Reactives**: Integra casi todos los reactivos de análisis previos (`homogeneity_run`, `stability_run`, `pt_prep_data`, etc.).
- **Inputs**: 
  - Datos de instrumentación (Archivo CSV).
  - Parámetros del informe: Título, ID esquema, Fecha, Personal encargado.
  - Configuración de cálculo: Método de valor asignado, métrica principal, factor k.

## Procesamiento de Datos para Informes
El módulo reconstruye internamente las tablas resumen divididas por anexos para asegurar la consistencia del informe:

### Reactives de Apoyo:
- `grubbs_summary()`: Genera la tabla de detección de valores atípicos para el Anexo A del informe.
- `report_xpt_summary()`: Consolida los valores asignados e incertidumbres según el método seleccionado (1, 2a, 2b o 3).
- `report_homogeneity_summary()` / `report_stability_summary()`: Estructuran los datos de calidad del ítem para los Anexos de homogeneidad y estabilidad.
- `report_heatmaps()`: Genera los mapas de calor dinámicos que se incrustan en el informe.
- `report_participant_data()`: Prepara un "pack" por participante con su tabla de puntajes individual y sus gráficos de desempeño.

## Outputs y Exportación

### `downloadHandler`
- **Nombre de archivo**: `Informe_PT_[ID_Esquema]_[Fecha].docx` (o .html).
- **Contenido**: Se pasan todos los reactivos anteriores como parámetros al archivo `.Rmd`.
- **Motor**: `rmarkdown::render()` ejecuta la compilación del documento utilizando los resultados calculados en la sesión actual.

## Visualizaciones Incluidas
1. **Gráficos de Homogeneidad**: Distribución de ítems y réplicas.
2. **Heatmaps Globales**: Resumen cromático de desempeño por analito/nivel.
3. **Ploteos Individuales**: Combinación de gráfico de valores (Referencia vs Lab) y gráfico de tendencia de Scores para cada participante.

## Configuración del Informe
| Parámetro | Opciones | Descripción |
|-----------|----------|-------------|
| Metodología $x_{pt}$ | 1, 2a, 2b, 3 | Define qué valor se usará como base para el informe. |
| Métrica | z, z', ζ, En | Define el puntaje principal a resaltar en las tablas de resumen. |
| Factor k | 2, 2.77, 3 | Afecta el cálculo de En y de las incertidumbres expandidas. |

## Referencias
- ISO 17043:2023 (Requisitos de informes).
- ISO 13528:2022 Sección 11.
