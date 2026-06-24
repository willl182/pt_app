# Visualización de Datos

Este documento describe las capacidades de visualización implementadas en la aplicación.

## Tecnologías
*   **ggplot2:** Generación de gráficos base estáticos.
*   **plotly:** Conversión a gráficos interactivos (tooltips, zoom) para la interfaz web.

## Catálogo de Gráficos

### 1. Análisis de Datos Crudos
*   **Histograma de Resultados:** Muestra la distribución de las mediciones (densidad) superpuesta con barras. Facetado por nivel.
*   **Diagrama de Caja (Boxplot):** Visualización de la dispersión y atípicos (puntos rojos) por nivel.

### 2. Algoritmo A
*   **Histograma de Convergencia:** Muestra la distribución de los promedios de los participantes con una línea vertical indicando el valor asignado robusto ($x^*$).

### 3. Puntajes PT
*   **Gráfico de Dispersión (Puntajes):**
    *   Eje X: Participantes.
    *   Eje Y: Valor del puntaje (Z, Z', Zeta, En).
    *   Líneas de referencia:
        *   Z/Z'/Zeta: $\pm 2$ (Advertencia, naranja), $\pm 3$ (Acción, rojo).
        *   En: $\pm 1$ (Acción, rojo).
    *   Interacción: Al pasar el mouse muestra el valor exacto y participante.

### 4. Informe Global (Heatmaps)
*   **Mapa de Calor de Desempeño:**
    *   Eje X: Niveles/Corridas.
    *   Eje Y: Participantes.
    *   Color: Semáforo (Verde=Satisfactorio, Amarillo=Cuestionable, Rojo=No Satisfactorio).
    *   Texto: Valor numérico del puntaje dentro de la celda.
*   **Mapa de Calor de Clasificación (ISO 13528):**
    *   Muestra los códigos de clasificación (a1, a2... a7) basados en la combinación de Z y En.

### 5. Reporte Individual
*   **Matriz de Gráficos (4 paneles):**
    1.  Valores absolutos (Participante vs Referencia).
    2.  Puntaje Z a través de los niveles.
    3.  Puntaje Zeta a través de los niveles.
    4.  Puntaje En a través de los niveles.
