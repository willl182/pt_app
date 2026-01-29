# ===================================================================
# Titulo: app_final.R
# Entregable: 08
# Descripcion: Aplicación Shiny final consolidada - Versión Beta
# Entrada: data/homogeneity.csv, stability.csv, summary_n4.csv, participants_data4.csv
# Salida: Tablas, gráficos, descargas CSV
# Autor: UNAL/INM
# Fecha: 2026-01-24
# Referencia: ISO 13528:2022, ISO 17043:2024
# ===================================================================

# Cargar librerías necesarias
library(shiny)
library(tidyverse)
library(DT)
library(ggplot2)
library(plotly)

# Cargar funciones consolidadas
source("R/funciones_finales.R")

# ===================================================================
# CARGA DE DATOS (Fija, sin fileInput)
# ===================================================================

hom_data <- read.csv("../data/homogeneity.csv")
stab_data <- read.csv("../data/stability.csv")
summary_data <- read.csv("../data/summary_n4.csv")
participants_data <- read.csv("../data/participants_data4.csv")

# ===================================================================
# INTERFAZ DE USUARIO (UI)
# ===================================================================
ui <- fluidPage(
  titlePanel("Aplicación PT - Versión Final (Beta)"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Datos precargados"),
      p("Los siguientes archivos están cargados automáticamente:"),
      tags$ul(
        tags$li("homogeneity.csv (", nrow(hom_data), " registros)"),
        tags$li("stability.csv (", nrow(stab_data), " registros)"),
        tags$li("summary_n4.csv (", nrow(summary_data), " registros)"),
        tags$li("participants_data4.csv (", nrow(participants_data), " registros)")
      ),
      hr(),
      h4("Configuración de Análisis"),
      selectInput("analito", "Seleccione analito:", choices = sort(unique(summary_data$pollutant))),
      selectInput("nivel", "Seleccione nivel:", choices = sort(unique(summary_data$level))),
      selectInput("n_lab", "Seleccione n:", choices = sort(unique(summary_data$n_lab))),
      hr(),
      h4("Parámetros de Cálculo"),
      numericInput("k_factor", "Factor de cobertura (k):", value = 2, min = 1, max = 3),
      selectInput("sigma_method", "Método para sigma_pt:",
                  choices = c("MADe" = "made", "nIQR" = "niqr", "Algoritmo A" = "algorithm_a")),
      hr(),
      actionButton("calcular_puntajes", "Calcular Puntajes PT", class = "btn-primary"),
      hr(),
      downloadButton("descargar_reporte", "Descargar Reporte Completo")
    ),
    
    mainPanel(
      tabsetPanel(
        id = "tabs",
        
        tabPanel(
          title = "Resumen de Datos",
          h4("Datos de participantes"),
          DTOutput("tabla_participantes"),
          hr(),
          h4("Datos de homogeneidad"),
          DTOutput("tabla_homogeneidad"),
          hr(),
          h4("Datos de estabilidad"),
          DTOutput("tabla_estabilidad"),
          hr(),
          downloadButton("descargar_participantes", "Descargar CSV de participantes")
        ),
        
        tabPanel(
          title = "Homogeneidad y Estabilidad",
          h4("Análisis de Homogeneidad"),
          tableOutput("tabla_homogeneidad_resultados"),
          hr(),
          h4("Análisis de Estabilidad"),
          tableOutput("tabla_estabilidad_resultados"),
          hr(),
          h4("Evaluación"),
          tableOutput("tabla_evaluacion_he")
        ),
        
        tabPanel(
          title = "Puntajes PT",
          h4("Parámetros de cálculo"),
          tableOutput("tabla_parametros"),
          hr(),
          h4("Resultados de puntajes"),
          DTOutput("tabla_puntajes"),
          hr(),
          h4("Resumen de evaluación"),
          tableOutput("tabla_evaluacion"),
          hr(),
          downloadButton("descargar_puntajes", "Descargar CSV de puntajes")
        ),
        
        tabPanel(
          title = "Gráficos - Distribución",
          h4("Histograma por nivel"),
          plotlyOutput("histograma_nivel"),
          hr(),
          h4("Boxplot por participante"),
          plotlyOutput("boxplot_participantes")
        ),
        
        tabPanel(
          title = "Gráficos - Puntajes",
          h4("Heatmap de puntajes z"),
          plotlyOutput("heatmap_z"),
          hr(),
          h4("Gráfico de barras de evaluación"),
          plotlyOutput("barras_evaluacion")
        ),
        
        tabPanel(
          title = "Gráficos - Comparación",
          h4("Comparación de puntajes (z, z', zeta, En)"),
          plotlyOutput("comparacion_puntajes"),
          hr(),
          h4("Diagrama de dispersión vs valor asignado"),
          plotlyOutput("dispersion_xpt")
        )
      )
    )
  )
)

# ===================================================================
# SERVIDOR
# ===================================================================
server <- function(input, output, session) {
  
  # Filtrar datos según selección del usuario
  filtered_data <- reactive({
    req(input$analito, input$nivel, input$n_lab)
    summary_data %>%
      filter(
        pollutant == input$analito,
        level == input$nivel,
        n_lab == input$n_lab
      )
  })
  
  # Calcular sigma_pt según método seleccionado
  sigma_pt <- reactive({
    df <- filtered_data()
    ref_data <- df %>% filter(participant_id == "ref")
    participants <- df %>% filter(participant_id != "ref")
    results <- participants$mean_value
    
    if (length(results) == 0) return(NA_real_)
    
    switch(input$sigma_method,
           "made" = calculate_sigma_pt_made(results),
           "niqr" = calculate_sigma_pt_niqr(results),
           "algorithm_a" = calculate_sigma_pt_algorithm_a(results),
           NA_real_)
  })
  
  # Calcular parámetros
  parametros <- reactive({
    df <- filtered_data()
    ref_data <- df %>% filter(participant_id == "ref")
    
    if (nrow(ref_data) == 0) {
      return(NULL)
    }
    
    x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
    participants <- df %>% filter(participant_id != "ref")
    results <- participants$mean_value
    
    sigma_val <- sigma_pt()
    u_xpt <- 1.25 * sigma_val / sqrt(length(results))
    
    list(
      x_pt = x_pt,
      sigma_pt = sigma_val,
      u_xpt = u_xpt,
      k = input$k_factor,
      metodo = "Referencia",
      sigma_method = input$sigma_method
    )
  })
  
  # Calcular estadísticos de homogeneidad
  homogeneidad_resultados <- reactive({
    pollutant <- input$analito
    if (is.null(pollutant) || pollutant == "") return(NULL)
    
    hom_filtered <- hom_data %>% 
      filter(pollutant == pollutant) %>%
      select(-pollutant)
    
    if (nrow(hom_filtered) == 0) return(NULL)
    
    sample_data <- as.matrix(hom_filtered)
    stats <- calculate_homogeneity_stats(sample_data)
    
    if (!is.null(stats$error)) return(list(error = stats$error))
    
    c_criterion <- calculate_homogeneity_criterion(stats$s_xt)
     c_expanded <- calculate_homogeneity_criterion_expanded(stats$s_xt, stats$sw, stats$g)
    
    list(
      stats = stats,
      c_criterion = c_criterion,
      c_expanded = c_expanded,
      evaluacion = evaluate_homogeneity(stats$ss, c_criterion)
    )
  })
  
  # Calcular estadísticos de estabilidad
  estabilidad_resultados <- reactive({
    pollutant <- input$analito
    if (is.null(pollutant) || pollutant == "") return(NULL)
    
    hom_res <- homogeneidad_resultados()
    if (is.null(hom_res) || !is.null(hom_res$error)) return(NULL)
    
    stab_filtered <- stab_data %>% filter(pollutant == pollutant)
    
    if (nrow(stab_filtered) == 0) return(NULL)
    
    stats <- calculate_stability_stats(
      stab_filtered$value,
      hom_res$stats$grand_mean,
      hom_res$stats$x_pt,
      hom_res$stats$sigma_pt
    )
    
    criterion <- 0.3 * hom_res$stats$s_xt
    
    list(
      stats = stats,
      criterion = criterion,
      evaluacion = evaluate_stability(stats$difference, criterion)
    )
  })
  
  # Calcular puntajes
  resultados_puntajes <- eventReactive(input$calcular_puntajes, {
    df <- filtered_data()
    params <- parametros()
    
    if (is.null(df) || is.null(params)) {
      return(NULL)
    }
    
    k <- params$k
    
    df %>%
      mutate(
        x_pt = params$x_pt,
        sigma_pt = params$sigma_pt,
        u_xpt = params$u_xpt,
        z_score = (mean_value - params$x_pt) / params$sigma_pt,
        z_prime_score = (mean_value - params$x_pt) / sqrt(params$sigma_pt^2 + params$u_xpt^2),
        u_x = sd_value / sqrt(1),
        zeta_score = (mean_value - params$x_pt) / sqrt(u_x^2 + params$u_xpt^2),
        U_x = k * u_x,
        U_xpt = k * params$u_xpt,
        En_score = (mean_value - params$x_pt) / sqrt(U_x^2 + U_xpt^2),
        z_score_eval = sapply(z_score, evaluate_z_score),
        z_prime_score_eval = sapply(z_prime_score, evaluate_z_score),
        zeta_score_eval = sapply(zeta_score, evaluate_z_score),
        En_score_eval = sapply(En_score, evaluate_en_score)
      ) %>%
      select(
        participant_id, pollutant, level, n_lab, mean_value, sd_value,
        x_pt, sigma_pt, u_xpt, z_score, z_score_eval,
        z_prime_score, z_prime_score_eval, zeta_score, zeta_score_eval,
        En_score, En_score_eval
      )
  })
  
  # Tablas de resumen de datos
  output$tabla_participantes <- renderDT({
    DT::datatable(
      head(participants_data, 50),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    )
  })
  
  output$tabla_homogeneidad <- renderDT({
    DT::datatable(
      head(hom_data, 50),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    )
  })
  
  output$tabla_estabilidad <- renderDT({
    DT::datatable(
      head(stab_data, 50),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    )
  })
  
  # Tabla de resultados de homogeneidad
  output$tabla_homogeneidad_resultados <- renderTable({
    hom <- homogeneidad_resultados()
    if (is.null(hom) || !is.null(hom$error)) return(NULL)
    
    data.frame(
      Parametro = c("g (muestras)", "m (réplicas)", "Media global", "s_x_bar", "sw", "ss", "Criterio c", "Criterio expandido", "Evaluación"),
      Valor = c(
        hom$stats$g,
        hom$stats$m,
        sprintf("%.6f", hom$stats$grand_mean),
        sprintf("%.6f", hom$stats$s_xt),
        sprintf("%.6f", hom$stats$sw),
        sprintf("%.6f", hom$stats$ss),
        sprintf("%.6f", hom$c_criterion),
        sprintf("%.6f", hom$c_expanded),
        hom$evaluacion
      )
    )
  })
  
  # Tabla de resultados de estabilidad
  output$tabla_estabilidad_resultados <- renderTable({
    stab <- estabilidad_resultados()
    if (is.null(stab)) return(NULL)
    
    data.frame(
      Parametro = c("Media homogeneidad", "Media estabilidad", "Diferencia", "Criterio", "Evaluación"),
      Valor = c(
        sprintf("%.6f", stab$stats$hom_mean),
        sprintf("%.6f", stab$stats$stab_mean),
        sprintf("%.6f", stab$stats$difference),
        sprintf("%.6f", stab$criterion),
        stab$evaluacion
      )
    )
  })
  
  # Tabla de evaluación H&E
  output$tabla_evaluacion_he <- renderTable({
    hom <- homogeneidad_resultados()
    stab <- estabilidad_resultados()
    
    if (is.null(hom) || is.null(stab) || !is.null(hom$error)) return(NULL)
    
    data.frame(
      Analisis = c("Homogeneidad", "Estabilidad"),
      Resultado = c(hom$evaluacion, stab$evaluacion),
      stringsAsFactors = FALSE
    )
  })
  
  # Tabla de parámetros
  output$tabla_parametros <- renderTable({
    params <- parametros()
    if (is.null(params)) return(NULL)
    
    data.frame(
      Parametro = c("Valor asignado (x_pt)", "sigma_pt", "u_xpt", "Factor k", "Método", "Método sigma_pt"),
      Valor = c(
        sprintf("%.6f", params$x_pt),
        sprintf("%.6f", params$sigma_pt),
        sprintf("%.6f", params$u_xpt),
        params$k,
        params$metodo,
        params$sigma_method
      )
    )
  })
  
  # Tabla de puntajes
  output$tabla_puntajes <- renderDT({
    res <- resultados_puntajes()
    if (is.null(res)) return(NULL)
    
    DT::datatable(
      res,
      options = list(pageLength = 20, scrollX = TRUE),
      rownames = FALSE,
      filter = "top"
    )
  })
  
  # Tabla de evaluación
  output$tabla_evaluacion <- renderTable({
    res <- resultados_puntajes()
    if (is.null(res)) return(NULL)
    
    data.frame(
      Puntaje = c("z-score", "z'-score", "zeta-score", "En-score"),
      Satisfactorio = c(
        sum(res$z_score_eval == "Satisfactorio"),
        sum(res$z_prime_score_eval == "Satisfactorio"),
        sum(res$zeta_score_eval == "Satisfactorio"),
        sum(res$En_score_eval == "Satisfactorio")
      ),
      Cuestionable = c(
        sum(res$z_score_eval == "Cuestionable"),
        sum(res$z_prime_score_eval == "Cuestionable"),
        sum(res$zeta_score_eval == "Cuestionable"),
        0
      ),
      No_Satisfactorio = c(
        sum(res$z_score_eval == "No satisfactorio"),
        sum(res$z_prime_score_eval == "No satisfactorio"),
        sum(res$zeta_score_eval == "No satisfactorio"),
        sum(res$En_score_eval == "No satisfactorio")
      )
    )
  })
  
  # Gráfico: Histograma por nivel
  output$histograma_nivel <- renderPlotly({
    req(input$analito, input$nivel)
    
    df_filtered <- summary_data %>%
      filter(pollutant == input$analito, level == input$nivel)
    
    p <- ggplot(df_filtered, aes(x = mean_value)) +
      geom_histogram(bins = 20, fill = "steelblue", alpha = 0.7, color = "black") +
      labs(
        title = paste("Distribución de valores -", input$analito, "-", input$nivel),
        x = "Valor medio",
        y = "Frecuencia"
      ) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Gráfico: Boxplot por participante
  output$boxplot_participantes <- renderPlotly({
    res <- resultados_puntajes()
    if (is.null(res)) return(NULL)
    
    p <- ggplot(res, aes(x = participant_id, y = mean_value, fill = participant_id)) +
      geom_boxplot(alpha = 0.7) +
      labs(
        title = "Distribución de valores por participante",
        x = "ID Participante",
        y = "Valor medio"
      ) +
      theme_minimal() +
      theme(legend.position = "none") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Gráfico: Heatmap de puntajes z
  output$heatmap_z <- renderPlotly({
    res <- resultados_puntajes()
    if (is.null(res)) return(NULL)
    
    df_heatmap <- res %>%
      select(participant_id, z_score) %>%
      mutate(puntaje_z = z_score)
    
    p <- ggplot(df_heatmap, aes(x = participant_id, y = 1, fill = puntaje_z)) +
      geom_tile(color = "white") +
      scale_fill_gradient2(
        low = "red",
        mid = "white",
        high = "blue",
        midpoint = 0,
        name = "Puntaje z"
      ) +
      labs(
        title = "Heatmap de puntajes z",
        x = "ID Participante",
        y = ""
      ) +
      theme_minimal() +
      theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())
    
    ggplotly(p)
  })
  
  # Gráfico: Barras de evaluación
  output$barras_evaluacion <- renderPlotly({
    res <- resultados_puntajes()
    if (is.null(res)) return(NULL)
    
    counts <- res %>%
      count(z_score_eval) %>%
      rename(Evaluacion = z_score_eval, Cantidad = n)
    
    counts$Evaluacion <- factor(counts$Evaluacion, levels = c("Satisfactorio", "Cuestionable", "No satisfactorio", "N/A"))
    
    colores <- c("Satisfactorio" = "#4CAF50", "Cuestionable" = "#FFC107", "No satisfactorio" = "#F44336", "N/A" = "#9E9E9E")
    
    p <- ggplot(counts, aes(x = Evaluacion, y = Cantidad, fill = Evaluacion)) +
      geom_bar(stat = "identity", alpha = 0.8) +
      scale_fill_manual(values = colores) +
      labs(
        title = "Conteo de evaluaciones (z-score)",
        x = "Evaluación",
        y = "Cantidad de participantes"
      ) +
      theme_minimal() +
      theme(legend.position = "none")
    
    ggplotly(p)
  })
  
  # Gráfico: Comparación de puntajes
  output$comparacion_puntajes <- renderPlotly({
    res <- resultados_puntajes()
    if (is.null(res)) return(NULL)
    
    df_long <- res %>%
      filter(participant_id != "ref") %>%
      select(participant_id, z_score, z_prime_score, zeta_score, En_score) %>%
      pivot_longer(
        cols = c(z_score, z_prime_score, zeta_score, En_score),
        names_to = "Puntaje",
        values_to = "Valor"
      )
    
    p <- ggplot(df_long, aes(x = participant_id, y = Valor, fill = Puntaje)) +
      geom_bar(stat = "identity", position = "dodge", alpha = 0.8) +
      geom_hline(yintercept = 2, linetype = "dashed", color = "gray") +
      geom_hline(yintercept = -2, linetype = "dashed", color = "gray") +
      labs(
        title = "Comparación de puntajes por participante",
        x = "ID Participante",
        y = "Valor del puntaje"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      theme(legend.position = "bottom")
    
    ggplotly(p)
  })
  
  # Gráfico: Dispersión vs valor asignado
  output$dispersion_xpt <- renderPlotly({
    res <- resultados_puntajes()
    if (is.null(res)) return(NULL)
    
    params <- parametros()
    
    p <- ggplot(res, aes(x = x_pt, y = mean_value, color = z_score_eval)) +
      geom_point(size = 4, alpha = 0.8) +
      geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "black") +
      labs(
        title = "Valores de participantes vs valor asignado",
        x = "Valor asignado (x_pt)",
        y = "Valor medio del participante",
        color = "Evaluación z-score"
      ) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Descarga de CSV - Participantes
  output$descargar_participantes <- downloadHandler(
    filename = function() {
      paste("participantes_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(participants_data, file, row.names = FALSE)
    }
  )
  
  # Descarga de CSV - Puntajes
  output$descargar_puntajes <- downloadHandler(
    filename = function() {
      paste("puntajes_", input$analito, "_", input$nivel, "_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      res <- resultados_puntajes()
      write.csv(res, file, row.names = FALSE)
    }
  )
  
  # Descarga de reporte completo
  output$descargar_reporte <- downloadHandler(
    filename = function() {
      paste("reporte_pt_", input$analito, "_", input$nivel, "_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      hom <- homogeneidad_resultados()
      stab <- estabilidad_resultados()
      params <- parametros()
      scores <- resultados_puntajes()
      
      resumen <- data.frame(
        Analito = input$analito,
        Nivel = input$nivel,
        n_lab = input$n_lab,
        Valor_asignado = if (!is.null(params)) params$x_pt else NA,
        Sigma_pt = if (!is.null(params)) params$sigma_pt else NA,
        Homogeneidad = if (!is.null(hom)) hom$evaluacion else NA,
        Estabilidad = if (!is.null(stab)) stab$evaluacion else NA,
        Fecha = Sys.Date(),
        stringsAsFactors = FALSE
      )
      
      write.csv(resumen, file, row.names = FALSE)
    }
  )
}

# Ejecutar aplicación
shinyApp(ui = ui, server = server)
