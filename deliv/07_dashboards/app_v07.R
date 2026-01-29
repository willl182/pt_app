# ===================================================================
# Titulo: app_v07.R
# Entregable: 07
# Descripcion: Aplicación Shiny con lógica de negocio y gráficos dinámicos
# Entrada: data/homogeneity.csv, stability.csv, summary_n4.csv, participants_data4.csv
# Salida: Tablas de resultados, gráficos, descargas CSV
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

# ===================================================================
# FUNCIONES STANDALONE (Sin dependencias de ptcalc)
# ===================================================================

# -------------------------------------------------------------------
# Estadísticos Robustos (nIQR, MADe, Algoritmo A)
# -------------------------------------------------------------------

#' Calcular nIQR (Normalized Interquartile Range)
#' nIQR = 0.7413 * IQR
#' Referencia: ISO 13528:2022, Sección 9.4
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

#' Calcular MADe (Scaled Median Absolute Deviation)
#' MADe = 1.483 * MAD
#' Referencia: ISO 13528:2022, Sección 9.4
calculate_mad_e <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) == 0) {
    return(NA_real_)
  }
  data_median <- stats::median(x_clean, na.rm = TRUE)
  abs_deviations <- abs(x_clean - data_median)
  mad_value <- stats::median(abs_deviations, na.rm = TRUE)
  1.483 * mad_value
}

#' Algoritmo A ISO 13528 - Media y desviación robustas
#' Referencia: ISO 13528:2022, Anexo C
run_algorithm_a <- function(values, ids = NULL, max_iter = 50, tol = 1e-03) {
  mask <- is.finite(values)
  values <- values[mask]
  
  if (is.null(ids)) {
    ids <- seq_along(values)
  } else {
    ids <- ids[mask]
  }
  
  n <- length(values)
  if (n < 3) {
    return(list(
      error = "Se requieren al menos 3 observaciones válidas para el Algoritmo A.",
      assigned_value = NA_real_,
      robust_sd = NA_real_,
      iterations = data.frame(),
      weights = data.frame(),
      converged = FALSE,
      effective_weight = NA_real_
    ))
  }
  
  x_star <- stats::median(values, na.rm = TRUE)
  s_star <- 1.483 * stats::median(abs(values - x_star), na.rm = TRUE)
  
  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    s_star <- stats::sd(values, na.rm = TRUE)
  }
  
  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    return(list(
      error = "La dispersión de datos es insuficiente para el Algoritmo A.",
      assigned_value = x_star,
      robust_sd = 0,
      iterations = data.frame(),
      weights = data.frame(),
      converged = TRUE,
      effective_weight = n
    ))
  }
  
  iteration_records <- list()
  converged <- FALSE
  
  for (iter in seq_len(max_iter)) {
    u_values <- (values - x_star) / (1.5 * s_star)
    weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))
    weight_sum <- sum(weights)
    
    if (!is.finite(weight_sum) || weight_sum <= 0) {
      return(list(
        error = "Los pesos calculados son inválidos para el Algoritmo A.",
        assigned_value = x_star,
        robust_sd = s_star,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        weights = data.frame(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }
    
    x_new <- sum(weights * values) / weight_sum
    s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)
    
    if (!is.finite(s_new) || s_new < .Machine$double.eps) {
      return(list(
        error = "El Algoritmo A colapsó debido a desviación estándar cero.",
        assigned_value = x_new,
        robust_sd = 0,
        iterations = if (length(iteration_records) > 0) do.call(rbind, iteration_records) else data.frame(),
        weights = data.frame(),
        converged = FALSE,
        effective_weight = NA_real_
      ))
    }
    
    delta_x <- abs(x_new - x_star)
    delta_s <- abs(s_new - s_star)
    delta <- max(delta_x, delta_s)
    
    iteration_records[[iter]] <- data.frame(
      iteracion = iter,
      x_star = x_new,
      s_star = s_new,
      delta = delta,
      stringsAsFactors = FALSE
    )
    
    x_star <- x_new
    s_star <- s_new
    
    if (delta_x < tol && delta_s < tol) {
      converged <- TRUE
      break
    }
  }
  
  u_final <- (values - x_star) / (1.5 * s_star)
  weights_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))
  
  iterations_df <- if (length(iteration_records) > 0) {
    do.call(rbind, iteration_records)
  } else {
    data.frame()
  }
  
  weights_df <- data.frame(
    id = ids,
    valor = values,
    peso = weights_final,
    residuo_estandarizado = u_final,
    stringsAsFactors = FALSE
  )
  
  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = iterations_df,
    weights = weights_df,
    converged = converged,
    effective_weight = sum(weights_final),
    error = NULL
  )
}

# -------------------------------------------------------------------
# Cálculos de Puntajes (z, z', zeta, En)
# -------------------------------------------------------------------

#' Calcular puntaje z
#' z = (x - x_pt) / sigma_pt
calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / sigma_pt
}

#' Calcular puntaje z' (z-prime)
#' z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt^2)
calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominator <- sqrt(sigma_pt^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Calcular puntaje zeta
#' zeta = (x - x_pt) / sqrt(u_x^2 + u_xpt^2)
calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominator <- sqrt(u_x^2 + u_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Calcular puntaje En (Error normalizado)
#' En = (x - x_pt) / sqrt(U_x^2 + U_xpt^2)
calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominator <- sqrt(U_x^2 + U_xpt^2)
  if (!is.finite(denominator) || denominator <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / denominator
}

#' Evaluar puntaje z (o z', zeta)
evaluate_z_score <- function(z) {
  if (!is.finite(z)) {
    return("N/A")
  }
  if (abs(z) <= 2) {
    return("Satisfactorio")
  } else if (abs(z) < 3) {
    return("Cuestionable")
  } else {
    return("No satisfactorio")
  }
}

#' Evaluar puntaje En
evaluate_en_score <- function(en) {
  if (!is.finite(en)) {
    return("N/A")
  }
  if (abs(en) <= 1) {
    return("Satisfactorio")
  } else {
    return("No satisfactorio")
  }
}

# -------------------------------------------------------------------
# Homogeneidad y Estabilidad
# -------------------------------------------------------------------

#' Calcular estadísticos de homogeneidad
#' Referencia: ISO 13528:2022, Sección 9.2
calculate_homogeneity_stats <- function(sample_data) {
  if (is.data.frame(sample_data)) {
    sample_data <- as.matrix(sample_data)
  }
  
  g <- nrow(sample_data)
  m <- ncol(sample_data)
  
  if (g < 2) {
    return(list(error = "Se requieren al menos 2 muestras para la evaluación de homogeneidad."))
  }
  if (m < 2) {
    return(list(error = "Se requieren al menos 2 réplicas por muestra para la evaluación de homogeneidad."))
  }
  
  sample_means <- rowMeans(sample_data, na.rm = TRUE)
  grand_mean <- base::mean(sample_means, na.rm = TRUE)
  s_x_bar_sq <- stats::var(sample_means, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)
  
  if (m == 2) {
    ranges <- abs(sample_data[, 1] - sample_data[, 2])
    sw <- sqrt(sum(ranges^2) / (2 * g))
  } else {
    within_vars <- apply(sample_data, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(base::mean(within_vars, na.rm = TRUE))
  }
  
  sw_sq <- sw^2
  ss_sq <- abs(s_x_bar_sq - (sw_sq / m))
  ss <- sqrt(ss_sq)
  
  list(
    g = g,
    m = m,
    grand_mean = grand_mean,
    sample_means = sample_means,
    s_x_bar_sq = s_x_bar_sq,
    s_xt = s_xt,
    sw = sw,
    sw_sq = sw_sq,
    ss_sq = ss_sq,
    ss = ss,
    error = NULL
  )
}

#' Calcular criterio de homogeneidad
#' c = 0.3 * sigma_pt
calculate_homogeneity_criterion <- function(sigma_pt) {
  0.3 * sigma_pt
}

#' Calcular criterio expandido de homogeneidad
#' c_expanded = F1 * (0.3 * sigma_pt)^2 + F2 * sw^2
#' Donde F1 y F2 son coeficientes que dependen de g
calculate_homogeneity_criterion_expanded <- function(sigma_pt, sw, g) {
  f_table <- data.frame(
    g = 7:20,
    f1 = c(2.10, 2.01, 1.94, 1.88, 1.83, 1.79, 1.75, 1.72, 1.69, 1.67, 1.64, 1.62, 1.60, 1.59),
    f2 = c(1.43, 1.25, 1.11, 1.01, 0.93, 0.86, 0.80, 0.75, 0.71, 0.68, 0.64, 0.62, 0.59, 0.57)
  )
  g_clamped <- max(7, min(20, g))
  idx <- which(f_table$g == g_clamped)
  f1 <- f_table$f1[idx]
  f2 <- f_table$f2[idx]
  f1 * (0.3 * sigma_pt)^2 + f2 * sw^2
}

# ===================================================================
# CARGA DE DATOS (Fija, sin fileInput)
# ===================================================================

# Determinar la ruta correcta según donde se ejecute la app
if (file.exists("data/homogeneity.csv")) {
  data_path <- "data/"
} else if (file.exists("../data/homogeneity.csv")) {
  data_path <- "../data/"
} else if (file.exists("../../data/homogeneity.csv")) {
  data_path = "../../data/"
} else {
  stop("No se encontraron los archivos de datos en data/ o ../data/")
}

hom_data <- read.csv(paste0(data_path, "homogeneity.csv"))
stab_data <- read.csv(paste0(data_path, "stability.csv"))
summary_data <- read.csv(paste0(data_path, "summary_n4.csv"))
participants_data <- read.csv(paste0(data_path, "participants_data4.csv"))

# ===================================================================
# INTERFAZ DE USUARIO (UI)
# ===================================================================
ui <- fluidPage(
  titlePanel("Aplicación PT - Versión 07 (Dashboards con Gráficos)"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Datos precargados"),
      p("Los siguientes archivos están cargados automáticamente:"),
      tags$ul(
        tags$li("homogeneity.csv"),
        tags$li("stability.csv"),
        tags$li("summary_n4.csv"),
        tags$li("participants_data4.csv")
      ),
      hr(),
      h4("Análisis"),
      selectInput("analito", "Seleccione analito:", choices = unique(summary_data$pollutant)),
      selectInput("nivel", "Seleccione nivel:", choices = unique(summary_data$level)),
      hr(),
      actionButton("calcular_puntajes", "Calcular Puntajes PT", class = "btn-primary")
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
    req(input$analito, input$nivel)
    summary_data %>%
      filter(
        pollutant == input$analito,
        level == input$nivel
      ) %>%
      group_by(participant_id) %>%
      summarise(
        pollutant = first(pollutant),
        level = first(level),
        run = first(run),
        mean_value = mean(mean_value, na.rm = TRUE),
        sd_value = mean(sd_value, na.rm = TRUE),
        .groups = "drop"
      )
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
    
    sigma_pt_made <- calculate_mad_e(results)
    sigma_pt_niqr <- calculate_niqr(results)
    u_xpt <- 1.25 * sigma_pt_made / sqrt(length(results))
    
    list(
      x_pt = x_pt,
      sigma_pt_made = sigma_pt_made,
      sigma_pt_niqr = sigma_pt_niqr,
      u_xpt = u_xpt,
      k = 2,
      metodo = "Referencia"
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
        sigma_pt = params$sigma_pt_made,
        u_xpt = params$u_xpt,
        z_score = (mean_value - params$x_pt) / params$sigma_pt_made,
        z_prime_score = (mean_value - params$x_pt) / sqrt(params$sigma_pt_made^2 + params$u_xpt^2),
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
  
  # Tabla de parámetros
  output$tabla_parametros <- renderTable({
    params <- parametros()
    if (is.null(params)) return(NULL)
    
    data.frame(
      Parametro = c("Valor asignado (x_pt)", "sigma_pt (MADe)", "sigma_pt (nIQR)", "u_xpt", "Factor k", "Método"),
      Valor = c(
        sprintf("%.5f", params$x_pt),
        sprintf("%.5f", params$sigma_pt_made),
        sprintf("%.5f", params$sigma_pt_niqr),
        sprintf("%.5f", params$u_xpt),
        params$k,
        params$metodo
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
    
    # Contar evaluaciones para z-score
    counts <- res %>%
      count(z_score_eval) %>%
      rename(Evaluacion = z_score_eval, Cantidad = n)
    
    # Definir orden de categorías
    counts$Evaluacion <- factor(counts$Evaluacion, levels = c("Satisfactorio", "Cuestionable", "No satisfactorio", "N/A"))
    
    # Colores según evaluación
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
}

# Ejecutar aplicación
shinyApp(ui = ui, server = server)
