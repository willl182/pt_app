# Manual de Usuario - Aplicación PT Data Analysis

## Introducción
Esta aplicación permite realizar el análisis estadístico de Ensayos de Aptitud (EA) para gases contaminantes criterio, siguiendo la norma ISO 13528:2022.

## Flujo de Trabajo Típico

1.  **Carga de Datos:**
    *   Vaya a la pestaña **"Carga de datos"**.
    *   Suba los archivos CSV requeridos:
        *   `homogeneity.csv`: Datos de las pruebas de homogeneidad.
        *   `stability.csv`: Datos de las pruebas de estabilidad.
        *   `summary_n*.csv`: Archivos resumen de los participantes (seleccione todos los necesarios).

2.  **Verificación de Datos:**
    *   En **"Análisis de homogeneidad y estabilidad"**, seleccione un analito y nivel.
    *   Pulse **"Ejecutar"**.
    *   Revise las pestañas de resultados para confirmar que se cumplen los criterios de homogeneidad y estabilidad.

3.  **Determinación del Valor Asignado:**
    *   En **"Valor asignado"**, explore los diferentes métodos:
        *   **Algoritmo A:** Ejecute para ver la convergencia robusta.
        *   **Valor Consenso:** Vea las estadísticas robustas (MADe, nIQR).
        *   **Referencia:** Consulte los valores del laboratorio de referencia.

4.  **Cálculo de Puntajes:**
    *   Vaya a **"Puntajes PT"**.
    *   Pulse **"Calcular puntajes"** (esto procesa todos los datos cargados).
    *   Explore los gráficos de Z, Z', Zeta y En para detectar participantes con desempeño insatisfactorio.

5.  **Análisis Global:**
    *   En **"Informe global"**, revise los mapas de calor para tener una visión general del desempeño de la ronda.

6.  **Generación del Informe:**
    *   Vaya a **"Generación de informes"**.
    *   Complete los campos de identificación (ID Informe, Fecha, Responsables).
    *   Seleccione el método de evaluación deseado (e.g., Referencia o Algoritmo A).
    *   (Opcional) Suba el CSV de instrumentación de participantes para incluirlo en el anexo.
    *   Pulse **"Descargar informe"** para obtener el documento Word (.docx).

## Solución de Problemas
*   **Error "No hay datos":** Verifique que los nombres de columnas en los CSV sean exactos (`value`, `pollutant`, `level`, `replicate`, `sample_*`).
*   **Error en Algoritmo A:** Requiere al menos 3 participantes válidos.
