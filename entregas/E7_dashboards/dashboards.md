# Entregable 7: Dashboards con Gráficos Dinámicos Integrados

**Proyecto:** Aplicativo para Evaluación de Ensayos de Aptitud (PT App)  
**Organización:** Laboratorio CALAIRE - Universidad Nacional de Colombia  
**Tecnologías:** ggplot2, plotly, patchwork, DT  
**Fecha:** 2026-01-03

---

## 1. Introducción

El aplicativo PT integra múltiples visualizaciones dinámicas e interactivas que facilitan la interpretación de los datos estadísticos complejos. Este documento describe cada tipo de gráfico, su propósito, implementación y personalización.

---

## 2. Catálogo de Visualizaciones

### 2.1. Resumen de Gráficos

| ID | Tipo | Módulo | Librería | Interactivo |
|----|------|--------|----------|-------------|
| G1 | Boxplot | Homogeneidad | plotly | ✓ |
| G2 | Boxplot | Estabilidad | plotly | ✓ |
| G3 | Líneas de Convergencia | Algoritmo A | plotly | ✓ |
| G4 | Barras Horizontales | Puntajes PT | plotly | ✓ |
| G5 | Mapa de Calor (Heatmap) | Informe Global | ggplot2 + plotly | ✓ |
| G6 | Matriz de Desempeño | Informes Individuales | patchwork | ✗ |
| G7 | Histograma de Distribución | Algoritmo A | ggplot2 | ✗ |

---

## 3. Gráfico G1: Boxplot de Homogeneidad

### 3.1. Propósito

Visualizar la distribución de resultados por ítem para identificar:
- Variabilidad entre ítems (altura del boxplot)
- Valores atípicos instrumentales (puntos fuera de los bigotes)
- Tendencia central (línea de la mediana)

### 3.2. Estructura Visual

```
       Ítem 1    Ítem 2    Ítem 3    Ítem 4    Ítem 5
         │         │         │         │         │
    ─────┼─────────┼─────────┼─────────┼─────────┼─────
         │         │         │         │         │
      ┌──┴──┐   ┌──┴──┐   ┌──┴──┐   ┌──┴──┐   ┌──┴──┐
      │     │   │     │   │     │   │     │   │     │
    ──┤  █  ├───┤  █  ├───┤  █  ├───┤  █  ├───┤  █  ├──
      │     │   │     │   │     │   │     │   │     │
      └──┬──┘   └──┬──┘   └──┬──┘   └──┬──┘   └──┬──┘
         │         │         │         │         │
    ─────┼─────────┼─────────┼─────────┼─────────┼─────
         │         │         ○ (atípico)
         │         │
```

### 3.3. Implementación en R

```r
# Preparar datos
plot_data <- hom_results()$data_wide %>%
  select(Item, starts_with("sample_")) %>%
  pivot_longer(
    cols = starts_with("sample_"),
    names_to = "replica",
    values_to = "value"
  )

# Crear gráfico base con ggplot2
p <- ggplot(plot_data, aes(x = factor(Item), y = value)) +
  geom_boxplot(
    fill = "#3498db",
    color = "#2c3e50",
    alpha = 0.7,
    outlier.color = "#e74c3c",
    outlier.size = 3
  ) +
  labs(
    title = paste("Homogeneidad -", input$pollutant, "-", input$level),
    x = "Ítem de Ensayo",
    y = "Valor Medido"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# Convertir a plotly para interactividad
ggplotly(p, tooltip = c("x", "y")) %>%
  layout(
    hoverlabel = list(bgcolor = "white"),
    hovermode = "closest"
  )
```

### 3.4. Interactividad (plotly)

| Acción | Resultado |
|--------|-----------|
| Hover sobre boxplot | Muestra Q1, mediana, Q3 |
| Hover sobre punto | Muestra valor exacto del atípico |
| Doble clic | Resetea zoom |
| Arrastrar | Zoom a región seleccionada |
| Botón "📷" | Descargar como PNG |

---

## 4. Gráfico G3: Convergencia del Algoritmo A

### 4.1. Propósito

Visualizar cómo los estimadores robustos ($x^*$ y $s^*$) convergen a través de las iteraciones.

### 4.2. Estructura Visual

```
x*
  │
  │    ●───────────●───────────●───────────●
  │   ╱
  │  ●
  │ ╱
  │●
  └─────────────────────────────────────────── Iteración
      1     2     3     4     5

s*
  │
  │●
  │ ╲
  │  ●
  │   ╲
  │    ●───────────●───────────●───────────●
  └─────────────────────────────────────────── Iteración
      1     2     3     4     5
```

### 4.3. Implementación en R

```r
# Datos de iteraciones
iterations_df <- algo_results()$iterations

# Gráfico de x* (media robusta)
p1 <- ggplot(iterations_df, aes(x = iter, y = x_star)) +
  geom_line(color = "#2980b9", size = 1.2) +
  geom_point(color = "#2980b9", size = 3) +
  geom_hline(
    yintercept = tail(iterations_df$x_star, 1),
    linetype = "dashed",
    color = "#27ae60"
  ) +
  labs(
    title = "Convergencia de x* (Media Robusta)",
    x = "Iteración",
    y = "x*"
  ) +
  theme_minimal()

# Gráfico de s* (desviación robusta)
p2 <- ggplot(iterations_df, aes(x = iter, y = s_star)) +
  geom_line(color = "#e74c3c", size = 1.2) +
  geom_point(color = "#e74c3c", size = 3) +
  geom_hline(
    yintercept = tail(iterations_df$s_star, 1),
    linetype = "dashed",
    color = "#27ae60"
  ) +
  labs(
    title = "Convergencia de s* (Desviación Robusta)",
    x = "Iteración",
    y = "s*"
  ) +
  theme_minimal()

# Combinar con patchwork
combined_plot <- p1 / p2

# Convertir a plotly
subplot(
  ggplotly(p1),
  ggplotly(p2),
  nrows = 2,
  shareX = TRUE,
  titleY = TRUE
)
```

---

## 5. Gráfico G4: Barras de Puntajes

### 5.1. Propósito

Mostrar el puntaje de cada participante con codificación visual de la evaluación (satisfactorio, cuestionable, insatisfactorio).

### 5.2. Estructura Visual

```
                    Puntaje z
    -4   -3   -2   -1   0   +1   +2   +3   +4
     │    │    │    │   │    │    │    │    │
     │    │    │    │   │    │    │    │    │
lab_1████████████████▓▓▓│                     │  z = -0.8 (Satisfactorio)
     │    │    │    │   │    │    │    │    │
lab_2████████████████░░░░░░░░░░│              │  z = 2.3 (Cuestionable)
     │    │    │    │   │    │    │    │    │
lab_3░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  z = 4.1 (Insatisfactorio)
     │    │    │    │   │    │    │    │    │
     │    ╎    │    │   │    │    ╎    │    │
     │  -3.0   │  -2.0  │  +2.0  │  +3.0    │
     │(Límite) │(Límite)│(Límite)│(Límite)  │

Leyenda: ████ Satisfactorio  ░░░░ Cuestionable  ▒▒▒▒ Insatisfactorio
```

### 5.3. Implementación en R

```r
# Preparar datos con colores
scores_df <- scores_results()$scores %>%
  mutate(
    color = case_when(
      abs(z_score) <= 2 ~ "#28a745",  # Verde - Satisfactorio
      abs(z_score) < 3 ~ "#ffc107",   # Amarillo - Cuestionable
      TRUE ~ "#dc3545"                 # Rojo - Insatisfactorio
    ),
    evaluation = case_when(
      abs(z_score) <= 2 ~ "Satisfactorio",
      abs(z_score) < 3 ~ "Cuestionable",
      TRUE ~ "Insatisfactorio"
    )
  )

# Crear gráfico
p <- ggplot(scores_df, aes(
  x = z_score, 
  y = reorder(participant_id, z_score),
  fill = evaluation,
  text = paste(
    "Participante:", participant_id,
    "<br>z-score:", round(z_score, 3),
    "<br>Evaluación:", evaluation
  )
)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = c(
    "Satisfactorio" = "#28a745",
    "Cuestionable" = "#ffc107",
    "Insatisfactorio" = "#dc3545"
  )) +
  geom_vline(xintercept = c(-2, 2), linetype = "dashed", color = "#6c757d") +
  geom_vline(xintercept = c(-3, 3), linetype = "dotted", color = "#dc3545") +
  geom_vline(xintercept = 0, color = "black") +
  labs(
    title = paste("Puntajes z -", input$pollutant, "-", input$level),
    x = "z-score",
    y = "Participante",
    fill = "Evaluación"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Convertir a plotly
ggplotly(p, tooltip = "text") %>%
  layout(
    showlegend = TRUE,
    legend = list(orientation = "h", y = -0.2)
  )
```

---

## 6. Gráfico G5: Mapa de Calor (Heatmap)

### 6.1. Propósito

Proporcionar una vista panorámica del desempeño de todos los participantes en todos los analitos/niveles simultáneamente.

### 6.2. Estructura Visual

```
              SO2_L1  SO2_L2  CO_L1   O3_L1   NO_L1
           ┌────────────────────────────────────────┐
   lab_1   │  🟢      🟢      🟢      🟡      🟢    │
   lab_2   │  🟢      🟡      🟢      🟢      🟢    │
   lab_3   │  🟡      🔴      🟢      🟢      🔴    │
   lab_4   │  🟢      🟢      🟡      🟢      🟢    │
   lab_5   │  🔴      🟢      🟢      🟢      🟢    │
           └────────────────────────────────────────┘

Leyenda: 🟢 |z|≤2  🟡 2<|z|<3  🔴 |z|≥3
```

### 6.3. Implementación en R

```r
# Preparar matriz de puntajes
heatmap_data <- all_scores_combined %>%
  mutate(
    combo = paste(pollutant, level, sep = "_"),
    z_cat = case_when(
      abs(z_score) <= 2 ~ 1,
      abs(z_score) < 3 ~ 2,
      TRUE ~ 3
    )
  ) %>%
  select(participant_id, combo, z_score, z_cat)

# Crear heatmap
p <- ggplot(heatmap_data, aes(
  x = combo, 
  y = participant_id, 
  fill = z_cat,
  text = paste(
    "Participante:", participant_id,
    "<br>Analito/Nivel:", combo,
    "<br>z-score:", round(z_score, 2)
  )
)) +
  geom_tile(color = "white", size = 0.5) +
  scale_fill_gradientn(
    colors = c("#28a745", "#ffc107", "#dc3545"),
    values = scales::rescale(c(1, 2, 3)),
    breaks = c(1, 2, 3),
    labels = c("Satisfactorio", "Cuestionable", "Insatisfactorio"),
    name = "Evaluación"
  ) +
  labs(
    title = "Mapa de Desempeño Global",
    x = "Analito / Nivel",
    y = "Participante"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

# Convertir a plotly
ggplotly(p, tooltip = "text")
```

### 6.4. Análisis Visual

| Patrón | Interpretación |
|--------|----------------|
| Columna roja | Problema sistemático en ese analito/nivel |
| Fila roja | Laboratorio con problemas generalizados |
| Punto rojo aislado | Error puntual, verificar resultado |
| Todo verde | Excelente desempeño general |

---

## 7. Gráfico G6: Matriz de Desempeño Individual

### 7.1. Propósito

Generar un resumen visual compacto para cada participante, combinando múltiples elementos en una sola imagen para el informe.

### 7.2. Implementación con patchwork

```r
library(patchwork)

create_individual_matrix <- function(participant_id, scores_df) {
  
  # Filtrar datos del participante
  participant_data <- scores_df %>%
    filter(participant_id == !!participant_id)
  
  # Gráfico 1: Barras de puntajes por analito
  p1 <- ggplot(participant_data, aes(x = pollutant, y = z_score, fill = evaluation)) +
    geom_col() +
    scale_fill_manual(values = c(
      "Satisfactorio" = "#28a745",
      "Cuestionable" = "#ffc107",
      "Insatisfactorio" = "#dc3545"
    )) +
    geom_hline(yintercept = c(-2, 2), linetype = "dashed") +
    labs(title = "Puntajes por Analito", x = NULL, y = "z-score") +
    theme_minimal() +
    theme(legend.position = "none")
  
  # Gráfico 2: Resultados vs Valor Asignado
  p2 <- ggplot(participant_data, aes(x = pollutant)) +
    geom_point(aes(y = result), color = "#3498db", size = 4) +
    geom_point(aes(y = x_pt), color = "#2ecc71", size = 4, shape = 4) +
    geom_segment(aes(xend = pollutant, y = result, yend = x_pt), 
                 linetype = "dotted", color = "gray") +
    labs(title = "Resultado vs Valor Asignado", x = NULL, y = "Concentración") +
    theme_minimal()
  
  # Tabla resumen
  summary_table <- participant_data %>%
    select(pollutant, level, z_score, evaluation) %>%
    tableGrob(rows = NULL, theme = ttheme_minimal())
  
  # Combinar con patchwork
  combined <- (p1 | p2) / wrap_elements(summary_table)
  combined + plot_annotation(
    title = paste("Informe Individual -", participant_id),
    theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5))
  )
}

# Usar la función
output$individual_matrix <- renderPlot({
  req(input$selected_participant)
  create_individual_matrix(input$selected_participant, scores_results()$scores)
})
```

---

## 8. Paleta de Colores Estándar

### 8.1. Colores de Evaluación

| Evaluación | Nombre | Hex | RGB |
|------------|--------|-----|-----|
| Satisfactorio | Verde Bootstrap | `#28a745` | rgb(40, 167, 69) |
| Cuestionable | Amarillo Bootstrap | `#ffc107` | rgb(255, 193, 7) |
| Insatisfactorio | Rojo Bootstrap | `#dc3545` | rgb(220, 53, 69) |

### 8.2. Colores de Marca

| Elemento | Nombre | Hex |
|----------|--------|-----|
| Primario | Azul Cerulean | `#2fa4e7` |
| Secundario | Azul Oscuro | `#033c73` |
| Neutro | Gris | `#6c757d` |

### 8.3. Implementación en R

```r
# Definir paleta como constante
PT_COLORS <- list(
  satisfactorio = "#28a745",
  cuestionable = "#ffc107",
  insatisfactorio = "#dc3545",
  primario = "#2fa4e7",
  secundario = "#033c73",
  neutro = "#6c757d"
)

# Escala de colores personalizada
scale_fill_pt <- function() {
  scale_fill_manual(values = c(
    "Satisfactorio" = PT_COLORS$satisfactorio,
    "Cuestionable" = PT_COLORS$cuestionable,
    "Insatisfactorio" = PT_COLORS$insatisfactorio
  ))
}
```

---

## 9. Configuración de Interactividad (plotly)

### 9.1. Opciones de Configuración

```r
# Configuración global de plotly
plotly_config <- function(p) {
  p %>%
    config(
      displayModeBar = TRUE,
      modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d"),
      toImageButtonOptions = list(
        format = "png",
        filename = "grafico_pt_app",
        height = 600,
        width = 900,
        scale = 2
      )
    ) %>%
    layout(
      hoverlabel = list(
        bgcolor = "white",
        font = list(size = 12, color = "black"),
        bordercolor = "#ccc"
      ),
      hovermode = "closest"
    )
}

# Aplicar a cualquier gráfico
output$my_plot <- renderPlotly({
  p <- create_my_plot()
  plotly_config(ggplotly(p))
})
```

### 9.2. Barra de Herramientas de plotly

| Icono | Acción |
|-------|--------|
| 📷 | Descargar como imagen PNG |
| 🔍+ | Zoom in |
| 🔍- | Zoom out |
| ↔️ | Pan (arrastrar) |
| 🏠 | Resetear ejes |
| ⬜ | Selección rectangular |

---

## 10. Integración con Informes

### 10.1. Inclusión en report_template.Rmd

```r
```{r heatmap, echo=FALSE, fig.width=10, fig.height=6}
# El heatmap se genera estáticamente para el Word
if (!is.null(params$heatmaps) && !is.null(params$heatmaps[[params$pollutant]])) {
  print(params$heatmaps[[params$pollutant]])
}
```

### 10.2. Exportación Manual de Gráficos

```r
# Guardar gráfico como archivo
ggsave(
  filename = "heatmap_global.png",
  plot = heatmap_plot,
  width = 10,
  height = 6,
  dpi = 300,
  bg = "white"
)
```

---

## 11. Solución de Problemas de Visualización

| Problema | Causa | Solución |
|----------|-------|----------|
| Gráfico no aparece | Datos vacíos | Agregar `req()` antes del render |
| Colores incorrectos | Factor mal ordenado | Usar `factor(x, levels = ...)` |
| Tooltips vacíos | `text` no definido | Agregar `aes(text = ...)` |
| Plotly muy lento | Muchos puntos | Reducir datos o usar `scattergl` |
| Ejes cortados | Rango automático | Usar `coord_cartesian()` |

---

**Archivos del Entregable E7:**
- `dashboards.md` — Este documento
