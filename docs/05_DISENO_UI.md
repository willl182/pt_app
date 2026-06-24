# Diseño de Interfaz de Usuario (UI)

## Descripción General
La interfaz está construida utilizando `shiny` con `navlistPanel` para la navegación principal. El diseño es responsivo y modular.

## Estructura de Navegación

### 1. Módulos de análisis
*   **Carga de datos:**
    *   Inputs: `fileInput` para Homogeneidad, Estabilidad y Resumen (múltiple).
    *   Outputs: Resumen de estado de carga.
*   **Análisis de homogeneidad y estabilidad:**
    *   Sidebar: Botón "Ejecutar", selectores de Analito y Nivel.
    *   Main Panel (Tabs):
        *   *Vista previa:* Tablas raw data, histogramas, boxplots.
        *   *Evaluación homogeneidad:* ANOVA, conclusión textual, tabla de varianzas.
        *   *Evaluación estabilidad:* Comparación de medias, t-test, conclusión.
*   **Valor asignado:**
    *   Sidebar: Selectores de datos.
    *   Accordion (Paneles colapsables):
        *   *Algoritmo A:* Configuración iteraciones, resultados, gráficos de convergencia.
        *   *Valor consenso:* Tablas de media robusta y nIQR.
        *   *Valor de referencia:* Tabla de valores del laboratorio de referencia.
        *   *Compatibilidad Metrológica:* Tabla comparativa de diferencias.
*   **Outlier:**
    *   Tabla resumen de prueba de Grubbs.
*   **Puntajes PT:**
    *   Sidebar: Botón "Calcular", selectores.
    *   Tabs: Resumen, Puntajes Z, Z', Zeta, En (tablas y gráficos de dispersión).
*   **Informe global:**
    *   Accordion con resúmenes agregados y mapas de calor (heatmaps) para cada método de valor asignado (Ref, Consenso MADe, Consenso nIQR, Algoritmo A).
*   **Participantes:**
    *   Vista detallada por participante (tabla resumen y gráfico matricial).
*   **Generación de informes:**
    *   Configuración de parámetros del informe (IDs, fechas, firmas).
    *   Botón de descarga (Word/HTML).

## Componentes Gráficos
*   **Librería:** `plotly` para interactividad, `ggplot2` como motor base.
*   **Tipos:**
    *   Histogramas con densidad.
    *   Boxplots por nivel.
    *   Gráficos de dispersión para puntajes (con líneas de límite).
    *   Mapas de calor (Heatmaps) para resumen global de desempeño.

## Estilo
*   Uso de `bsplus` para acordeones.
*   Temas de `shinythemes` (configurable).
*   Alertas de bootstrap (success/warning/danger) para conclusiones automáticas.
