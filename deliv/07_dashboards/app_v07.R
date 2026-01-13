# ===================================================================
# Aplicación Shiny para Análisis de Ensayos de Aptitud
# Implementación ISO 17043:2024 / ISO 13528:2022
#
# Versión 07: Tableros con gráficos dinámicos y datos fijos.
#
# Esta aplicación presenta paneles interactivos con tablas y gráficos
# usando datos predefinidos para homogeneidad, estabilidad y puntajes.
#
# Autor: UNAL/INM - Laboratorio CALAIRE
# ===================================================================

# 1. Cargar librerías necesarias
library(shiny)
library(DT)
library(ggplot2)
library(plotly)
library(dplyr)
library(tidyr)

# -------------------------------------------------------------------
# II. Carga de datos fijos
# -------------------------------------------------------------------
obtener_directorio_datos <- function() {
  ruta_preferida <- file.path("..", "data")
  ruta_alterna <- file.path("..", "..", "data")

  if (dir.exists(ruta_preferida)) {
    ruta_preferida
  } else {
    ruta_alterna
  }
}

data_dir <- obtener_directorio_datos()

hom_data_full <- read.csv(file.path(data_dir, "homogeneity.csv"), stringsAsFactors = FALSE)
stab_data_full <- read.csv(file.path(data_dir, "stability.csv"), stringsAsFactors = FALSE)
summary_data_full <- read.csv(file.path(data_dir, "summary_n4.csv"), stringsAsFactors = FALSE)
participants_data_full <- read.csv(file.path(data_dir, "participants_data4.csv"), stringsAsFactors = FALSE)

# -------------------------------------------------------------------
# III. Funciones de cálculo (definidas en este archivo)
# -------------------------------------------------------------------
preparar_resumen_participantes <- function(df) {
  df %>%
    group_by(pollutant, level, participant_id) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      sd_value = mean(sd_value, na.rm = TRUE),
      .groups = "drop"
    )
}

calcular_parametros_pt <- function(df) {
  df %>%
    group_by(pollutant, level) %>%
    summarise(
      x_pt = mean(mean_value[participant_id == "ref"], na.rm = TRUE),
      sigma_pt = sd(mean_value[participant_id != "ref"], na.rm = TRUE),
      .groups = "drop"
    )
}

calcular_puntajes_z <- function(df) {
  parametros <- calcular_parametros_pt(df)

  df %>%
    left_join(parametros, by = c("pollutant", "level")) %>%
    mutate(
      sigma_pt = ifelse(is.na(sigma_pt) | sigma_pt == 0, 1, sigma_pt),
      z_score = (mean_value - x_pt) / sigma_pt
    )
}

preparar_datos_muestras <- function(df, pollutant_sel, level_sel) {
  df %>%
    filter(pollutant == pollutant_sel, level == level_sel) %>%
    select(pollutant, level, replicate, sample_id, value)
}

# -------------------------------------------------------------------
# IV. Interfaz de usuario
# -------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Tableros PT con Gráficos - Versión 07"),
  tabsetPanel(
    tabPanel(
      "Datos fijos",
      h4("Homogeneidad"),
      DTOutput("tabla_homogeneidad"),
      hr(),
      h4("Estabilidad"),
      DTOutput("tabla_estabilidad"),
      hr(),
      h4("Resumen de participantes"),
      DTOutput("tabla_resumen"),
      hr(),
      h4("Instrumentación de participantes"),
      DTOutput("tabla_participantes")
    ),
    tabPanel(
      "Distribución",
      sidebarLayout(
        sidebarPanel(
          selectInput(
            "fuente_distribucion",
            "Datos para distribución",
            choices = c("Homogeneidad", "Estabilidad")
          ),
          uiOutput("selector_analito"),
          uiOutput("selector_nivel")
        ),
        mainPanel(
          h4("Histograma por nivel"),
          plotlyOutput("grafico_histograma"),
          hr(),
          h4("Diagrama de caja por réplica"),
          plotlyOutput("grafico_boxplot")
        )
      )
    ),
    tabPanel(
      "Puntajes",
      sidebarLayout(
        sidebarPanel(
          uiOutput("selector_analito_puntajes"),
          uiOutput("selector_nivel_puntajes")
        ),
        mainPanel(
          h4("Tabla de puntajes z"),
          DTOutput("tabla_puntajes"),
          hr(),
          h4("Gráfico de barras"),
          plotlyOutput("grafico_barras")
        )
      )
    ),
    tabPanel(
      "Mapas de calor",
      sidebarLayout(
        sidebarPanel(
          uiOutput("selector_analito_heatmap")
        ),
        mainPanel(
          h4("Mapa de calor de puntajes z"),
          plotlyOutput("grafico_heatmap")
        )
      )
    )
  )
)

# -------------------------------------------------------------------
# V. Lógica del servidor
# -------------------------------------------------------------------
server <- function(input, output, session) {
  resumen_participantes <- preparar_resumen_participantes(summary_data_full)
  puntajes_z <- calcular_puntajes_z(resumen_participantes)

  output$tabla_homogeneidad <- renderDT({
    datatable(hom_data_full, options = list(pageLength = 10), rownames = FALSE)
  })

  output$tabla_estabilidad <- renderDT({
    datatable(stab_data_full, options = list(pageLength = 10), rownames = FALSE)
  })

  output$tabla_resumen <- renderDT({
    datatable(resumen_participantes, options = list(pageLength = 10), rownames = FALSE)
  })

  output$tabla_participantes <- renderDT({
    datatable(participants_data_full, options = list(pageLength = 10), rownames = FALSE)
  })

  output$selector_analito <- renderUI({
    choices <- sort(unique(hom_data_full$pollutant))
    selectInput("analito_seleccion", "Seleccionar analito", choices = choices)
  })

  output$selector_nivel <- renderUI({
    req(input$analito_seleccion)
    data_base <- if (input$fuente_distribucion == "Homogeneidad") hom_data_full else stab_data_full
    niveles <- sort(unique(data_base$level[data_base$pollutant == input$analito_seleccion]))
    selectInput("nivel_seleccion", "Seleccionar nivel", choices = niveles)
  })

  datos_distribucion <- reactive({
    req(input$analito_seleccion, input$nivel_seleccion)
    data_base <- if (input$fuente_distribucion == "Homogeneidad") hom_data_full else stab_data_full
    preparar_datos_muestras(data_base, input$analito_seleccion, input$nivel_seleccion)
  })

  output$grafico_histograma <- renderPlotly({
    datos <- datos_distribucion()
    grafico <- ggplot(datos, aes(x = value)) +
      geom_histogram(bins = 20, fill = "#2C7FB8", color = "white") +
      labs(x = "Valor", y = "Frecuencia") +
      theme_minimal()
    ggplotly(grafico)
  })

  output$grafico_boxplot <- renderPlotly({
    datos <- datos_distribucion()
    grafico <- ggplot(datos, aes(x = factor(replicate), y = value, fill = factor(replicate))) +
      geom_boxplot(alpha = 0.7, show.legend = FALSE) +
      labs(x = "Réplica", y = "Valor") +
      theme_minimal()
    ggplotly(grafico)
  })

  output$selector_analito_puntajes <- renderUI({
    choices <- sort(unique(puntajes_z$pollutant))
    selectInput("analito_puntajes", "Analito", choices = choices)
  })

  output$selector_nivel_puntajes <- renderUI({
    req(input$analito_puntajes)
    niveles <- sort(unique(puntajes_z$level[puntajes_z$pollutant == input$analito_puntajes]))
    selectInput("nivel_puntajes", "Nivel", choices = niveles)
  })

  puntajes_filtrados <- reactive({
    req(input$analito_puntajes, input$nivel_puntajes)
    puntajes_z %>%
      filter(pollutant == input$analito_puntajes, level == input$nivel_puntajes)
  })

  output$tabla_puntajes <- renderDT({
    datatable(puntajes_filtrados(), options = list(pageLength = 10), rownames = FALSE)
  })

  output$grafico_barras <- renderPlotly({
    datos <- puntajes_filtrados()
    grafico <- ggplot(datos, aes(x = participant_id, y = z_score, fill = participant_id)) +
      geom_col(show.legend = FALSE) +
      labs(x = "Participante", y = "Puntaje z") +
      theme_minimal()
    ggplotly(grafico)
  })

  output$selector_analito_heatmap <- renderUI({
    choices <- sort(unique(puntajes_z$pollutant))
    selectInput("analito_heatmap", "Analito", choices = choices)
  })

  output$grafico_heatmap <- renderPlotly({
    req(input$analito_heatmap)
    datos <- puntajes_z %>%
      filter(pollutant == input$analito_heatmap, participant_id != "ref")

    grafico <- ggplot(datos, aes(x = level, y = participant_id, fill = z_score)) +
      geom_tile(color = "white") +
      scale_fill_gradient2(low = "#D7191C", mid = "#FFFFBF", high = "#1A9641") +
      labs(x = "Nivel", y = "Participante", fill = "z") +
      theme_minimal()
    ggplotly(grafico)
  })
}

# -------------------------------------------------------------------
# VI. Ejecutar aplicación
# -------------------------------------------------------------------
shinyApp(ui = ui, server = server)
