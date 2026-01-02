# Entregable 4.2: Plantilla de Informe R Markdown

La generación del informe final se basa en la plantilla `reports/report_template.Rmd`, la cual permite consolidar todos los resultados en un documento de Microsoft Word de alta calidad.

## 1. Estructura del Informe

El informe generado sigue la estructura recomendada por la ISO 17043:

1. **Introducción:** Alcance del ensayo, confidencialidad y roles de autorización.
2. **Descripción del Ensayo:** Producción de ítems, niveles de concentración y cronograma.
3. **Metodología:** Determinación del valor asignado ($x_{pt}$) y su incertidumbre ($u_{xpt}$).
4. **Criterios de Evaluación:** Descripción de los puntajes utilizados (z, En, etc.).
5. **Resultados y Discusión:** Resumen de desempeño, atípicos (Prueba de Grubbs) y conclusiones.
6. **Anexos:** Tablas detalladas de Homogeneidad, Estabilidad y resultados por participante.

## 2. Parámetros de la Plantilla

Para asegurar su funcionamiento, la plantilla recibe una lista de parámetros (`params`):
- `summary_data`: Tabla consolidada de resultados.
- `hom_data` / `stab_data`: Datos brutos para los anexos.
- `metric`: Tipo de puntuación seleccionada (z, z', zeta, En).
- `method`: Método de cálculo del valor asignado (Referencia, Algoritmo A, etc.).
- `k_factor`: Factor de cobertura para las incertidumbres.

## 3. Lógica Interna de la Plantilla

- **Autoconsistencia:** Redefine funciones críticas como `run_algorithm_a` y `calculate_niqr` para asegurar que el informe se pueda generar sin depender de la sesión activa de Shiny.
- **Validación de Atípicos:** Ejecuta automáticamente la **Prueba de Grubbs** (`outliers::grubbs.test`) para informar sobre datos sospechosos en el resumen de resultados.
- **Visualizaciones:** Genera mapas de calor (heatmaps) y matrices de desempeño individuales para cada participante.
