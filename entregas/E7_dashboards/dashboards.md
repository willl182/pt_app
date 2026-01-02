# Entregable 7: Dashboards con Gráficos Dinámicos

Este documento describe las capacidades de visualización dinámica integradas en el aplicativo, las cuales facilitan la interpretación de los datos estadísticos complejos mediante gráficos interactivos y comparativos.

## 1. Visualizaciones de Preparación del Ítem

### 1.1. Boxplots de Homogeneidad y Estabilidad
- **Implementación:** `ggplot2` + `plotly`.
- **Descripción:** Muestra la distribución de los resultados por ítem y por réplica. Permite identificar visualmente si algún ítem se sale de la tendencia general (atípico instrumental).
- **Interactividad:** Al pasar el ratón se visualiza el valor exacto del resultado, la réplica y el ítem correspondiente.

## 2. Dashboards de Desempeño (Puntajes PT)

### 2.1. Gráfico de Barras de Puntajes z / En
- **Ubicación:** Pestaña "Puntajes PT".
- **Lógica:** Renderiza una barra por cada participante para el analito/nivel seleccionado.
- **Codificación de Color:**
  - **Verde:** Satisfactorio.
  - **Amarillo/Naranja:** Cuestionable (solo para z/zeta).
  - **Rojo:** Insatisfactorio.

### 2.2. Mapa de Calor (Heatmap) de Desempeño
- **Implementación:** `ggplot2` con `geom_tile()`.
- **Descripción:** Proporciona una vista aérea de todos los participantes frente a todos los analitos/niveles para la métrica seleccionada.
- **Utilidad:** Permite a los coordinadores identificar rápidamente laboratorios con problemas sistemáticos en múltiples parámetros.

## 3. Informes Individuales: Matriz de Desempeño

### 3.1. Gráfico Combinado por Participante
- **Tecnología:** Librería `patchwork`.
- **Descripción:** En la vista de "Detalle por Participante", se combinan gráficos de barras y tablas en una sola imagen de alta resolución que resume el cumplimiento del laboratorio en toda la ronda.
- **Gráficos Incluidos:**
  - Desempeño relativo frente al valor asignado.
  - Evaluación cualitativa codificada por colores.

## 4. Tecnologías Utilizadas

| Librería | Función |
|----------|---------|
| `plotly` | Interactividad, zoom y tooltips en tiempo real. |
| `patchwork` | Combinación de múltiples gráficos en dashboards compuestos. |
| `ggplot2` | Motor gráfico base siguiendo la gramática de gráficos. |
| `shiny` | Sincronización de los gráficos con los filtros de la UI. |
