# Manual de usuario - Entregable 06

## Objetivo
Esta versión presenta la lógica de negocio del aplicativo sin gráficos. Los cálculos se muestran únicamente en tablas y pueden descargarse en CSV.

## Requisitos
- R 4.x
- Paquetes: `shiny`, `DT`, `dplyr`, `tidyr`, `outliers`

## Cómo ejecutar
1. Abra R en la carpeta `pt_app/deliv/06_app_logica`.
2. Ejecute:
   ```r
   shiny::runApp(".")
   ```
3. La aplicación carga los datos desde `../data`. Si la ruta no existe, prueba `../../data` y luego `../../../data`.

## Datos de entrada
- `data/homogeneity.csv`
- `data/stability.csv`
- `data/summary_n4.csv`
- `data/participants_data4.csv`

## Módulos disponibles
- **Homogeneidad y estabilidad**: resumen estadístico y tabla por ítem.
- **Valores atípicos**: resultados de la prueba de Grubbs.
- **Valor asignado**: tabla de x_pt, u_xpt y sigma_pt por método.
- **Puntajes PT**: cálculo de z, z', zeta y En con evaluación.
- **Participantes**: instrumentación y resultados individuales.

## Descargas
Cada tabla tiene un botón para descargar el CSV correspondiente.
