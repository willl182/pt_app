# Módulo Shiny: Participantes

## 1. Descripción General
Este módulo crea un tablero dedicado para cada participante, permitiendo un análisis individual detallado. Se genera dinámicamente basado en la lista de participantes encontrados en los datos.

**Ubicación del Archivo:** `cloned_app.R` (Pestaña "Participantes")

---

## 2. Generación Dinámica de Pestañas

### 2.1 El Patrón
La aplicación utiliza un patrón `uiOutput` -> `renderUI` -> `lapply` para crear pestañas indefinidamente.

```r
output$scores_participant_tabs <- renderUI({
  participants <- unique(data$participant_id)

  # Crear una pestaña para cada participante
  tabs <- lapply(participants, function(id) {
    tabPanel(
      title = id,
      br(),
      # Outputs de UI específicos con IDs únicos
      dataTableOutput(paste0("participant_table_", id)),
      plotOutput(paste0("participant_plot_", id))
    )
  })

  do.call(tabsetPanel, tabs)
})
```

### 2.2 Consideraciones de Rendimiento
*   **Carga Perezosa (Lazy Loading):** Aunque las pestañas se generan, el contenido (gráficos/tablas) solo se renderiza cuando la pestaña está activa.
*   **Filtrado:** Los datos se filtran por participante *dentro* de la función de renderizado local, asegurando eficiencia.

---

## 3. Características por Participante

### 3.1 Tabla de Resultados Individuales
Muestra cada resultado para ese laboratorio específico a través de todos los contaminantes y niveles, incluyendo su incertidumbre reportada vs. el valor asignado.

### 3.2 Gráficos de Tendencia/Comparación
*   **Gráfico de Barras:** Compara Resultado de Lab vs. Valor de Referencia lado a lado.
*   **Gráfico de Dispersión:** Visualiza los puntajes z del laboratorio a través de diferentes ítems para detectar sesgo sistemático (ej: si todos los puntajes z son positivos > 1).
