# ===================================================================
# Titulo: app_final.R
# Entregable: 08 - Version Beta y Documentacion Final
# Descripcion: Aplicacion Shiny consolidada basada en v07 con datos fijos,
#              tablas y graficos interactivos para ensayos de aptitud.
# Entrada: data/homogeneity.csv, stability.csv, summary_n4.csv,
#          participants_data4.csv
# Salida: Tablas de resultados, graficos y evaluaciones de puntajes
# Autor: [PT App Team]
# Fecha: 2026-01-11
# Referencia: ISO 13528:2022 / ISO 17043:2024
# ===================================================================

# -------------------------------------------------------------------
# Librerias requeridas
# -------------------------------------------------------------------

library(shiny)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)
library(DT)

# -------------------------------------------------------------------
# Funciones standalone (copiadas desde R/funciones_finales.R)
# -------------------------------------------------------------------

construir_matriz_muestras <- function(datos, contaminante, nivel) {
  columnas_requeridas <- c("pollutant", "level", "replicate", "sample_id", "value")
  if (!all(columnas_requeridas %in% names(datos))) {
    stop("Los datos no contienen las columnas requeridas para construir la matriz.")
  }

  subset_datos <- datos[datos$pollutant == contaminante & datos$level == nivel, , drop = FALSE]
  if (nrow(subset_datos) == 0) {
    stop("No se encontraron registros para el contaminante y nivel solicitados.")
  }

  matriz <- stats::xtabs(value ~ sample_id + replicate, data = subset_datos)
  as.matrix(matriz)
}

calculate_homogeneity_stats <- function(sample_data) {
  if (is.data.frame(sample_data)) {
    sample_data <- as.matrix(sample_data)
  }

  g <- nrow(sample_data)
  m <- ncol(sample_data)

  if (g < 2) {
    return(list(error = "Se requieren al menos 2 muestras para evaluar homogeneidad."))
  }
  if (m < 2) {
    return(list(error = "Se requieren al menos 2 replicados por muestra para evaluar homogeneidad."))
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

calculate_homogeneity_criterion <- function(sigma_pt) {
  if (!is.finite(sigma_pt)) {
    return(NA_real_)
  }
  0.3 * sigma_pt
}

calculate_homogeneity_criterion_expanded <- function(sigma_pt, sw_sq) {
  if (!is.finite(sigma_pt) || !is.finite(sw_sq)) {
    return(NA_real_)
  }
  c_criterion <- 0.3 * sigma_pt
  sigma_allowed_sq <- c_criterion^2
  sqrt(sigma_allowed_sq * 1.88 + sw_sq * 1.01)
}

evaluate_homogeneity <- function(ss, c_criterion, c_expanded = NULL) {
  if (!is.finite(ss) || !is.finite(c_criterion)) {
    return(list(
      passes_criterion = NA,
      passes_expanded = NA,
      conclusion = "Datos insuficientes para evaluar homogeneidad."
    ))
  }

  passes_criterion <- ss <= c_criterion
  conclusion1 <- if (passes_criterion) {
    sprintf("ss (%.4f) <= c (%.4f): CUMPLE CRITERIO HOMOGENEIDAD", ss, c_criterion)
  } else {
    sprintf("ss (%.4f) > c (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", ss, c_criterion)
  }

  passes_expanded <- NA
  conclusion2 <- NULL
  if (!is.null(c_expanded) && is.finite(c_expanded)) {
    passes_expanded <- ss <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("ss (%.4f) <= c_exp (%.4f): CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
    } else {
      sprintf("ss (%.4f) > c_exp (%.4f): NO CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
    }
  }

  list(
    passes_criterion = passes_criterion,
    passes_expanded = passes_expanded,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

calculate_stability_stats <- function(stab_sample_data, hom_grand_mean) {
  stats <- calculate_homogeneity_stats(stab_sample_data)
  if (!is.null(stats$error)) {
    return(stats)
  }

  stats$stab_grand_mean <- stats$grand_mean
  stats$diff_hom_stab <- abs(stats$grand_mean - hom_grand_mean)
  stats
}

calculate_stability_criterion <- function(sigma_pt) {
  if (!is.finite(sigma_pt)) {
    return(NA_real_)
  }
  0.3 * sigma_pt
}

calculate_stability_criterion_expanded <- function(c_criterion, u_hom_mean, u_stab_mean) {
  if (!is.finite(c_criterion) || !is.finite(u_hom_mean) || !is.finite(u_stab_mean)) {
    return(NA_real_)
  }
  c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
}

evaluate_stability <- function(diff_hom_stab, c_criterion, c_expanded = NULL) {
  if (!is.finite(diff_hom_stab) || !is.finite(c_criterion)) {
    return(list(
      passes_criterion = NA,
      passes_expanded = NA,
      conclusion = "Datos insuficientes para evaluar estabilidad."
    ))
  }

  passes_criterion <- diff_hom_stab <= c_criterion
  conclusion1 <- if (passes_criterion) {
    sprintf("|y1 - y2| (%.4f) <= c (%.4f): CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, c_criterion)
  } else {
    sprintf("|y1 - y2| (%.4f) > c (%.4f): NO CUMPLE CRITERIO ESTABILIDAD", diff_hom_stab, c_criterion)
  }

  passes_expanded <- NA
  conclusion2 <- NULL
  if (!is.null(c_expanded) && is.finite(c_expanded)) {
    passes_expanded <- diff_hom_stab <= c_expanded
    conclusion2 <- if (passes_expanded) {
      sprintf("|y1 - y2| (%.4f) <= c_exp (%.4f): CUMPLE CRITERIO EXPANDIDO", diff_hom_stab, c_expanded)
    } else {
      sprintf("|y1 - y2| (%.4f) > c_exp (%.4f): NO CUMPLE CRITERIO EXPANDIDO", diff_hom_stab, c_expanded)
    }
  }

  list(
    passes_criterion = passes_criterion,
    passes_expanded = passes_expanded,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

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
      error = "El Algoritmo A requiere al menos 3 observaciones validas.",
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
      error = "La dispersion es insuficiente para el Algoritmo A.",
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
        error = "Los pesos calculados son invalidos para el Algoritmo A.",
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
        error = "El Algoritmo A colapso por desviacion cero.",
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
      iteration = iter,
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
    value = values,
    weight = weights_final,
    standardized_residual = u_final,
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

calculate_valor_asignado <- function(datos_resumen, contaminante, nivel, metodo = c("1", "2a", "2b", "3")) {
  metodo <- match.arg(metodo)
  columnas_requeridas <- c("pollutant", "level", "participant_id", "mean_value", "sd_value")
  if (!all(columnas_requeridas %in% names(datos_resumen))) {
    return(list(error = "El resumen no contiene las columnas requeridas."))
  }

  subset_datos <- datos_resumen[datos_resumen$pollutant == contaminante & datos_resumen$level == nivel, , drop = FALSE]
  if (nrow(subset_datos) == 0) {
    return(list(error = "No hay datos para el contaminante y nivel solicitados."))
  }

  ref_data <- subset_datos[subset_datos$participant_id == "ref", , drop = FALSE]
  part_data <- subset_datos[subset_datos$participant_id != "ref", , drop = FALSE]

  if (metodo == "1") {
    if (nrow(ref_data) == 0) {
      return(list(error = "No hay datos de referencia para el metodo 1."))
    }
    x_pt <- base::mean(ref_data$mean_value, na.rm = TRUE)
    sigma_pt <- base::mean(ref_data$sd_value, na.rm = TRUE)
    u_xpt <- sigma_pt
    n_vals <- nrow(ref_data)
  } else if (metodo == "2a") {
    valores <- part_data$mean_value
    x_pt <- stats::median(valores, na.rm = TRUE)
    sigma_pt <- calculate_mad_e(valores)
    n_vals <- sum(is.finite(valores))
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  } else if (metodo == "2b") {
    valores <- part_data$mean_value
    x_pt <- stats::median(valores, na.rm = TRUE)
    sigma_pt <- calculate_niqr(valores)
    n_vals <- sum(is.finite(valores))
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  } else {
    valores <- part_data$mean_value
    n_vals <- sum(is.finite(valores))
    res_algo <- run_algorithm_a(valores)
    if (!is.null(res_algo$error)) {
      return(list(error = res_algo$error))
    }
    x_pt <- res_algo$assigned_value
    sigma_pt <- res_algo$robust_sd
    u_xpt <- 1.25 * sigma_pt / sqrt(n_vals)
  }

  list(
    metodo = metodo,
    x_pt = x_pt,
    u_xpt = u_xpt,
    sigma_pt = sigma_pt,
    n = n_vals,
    error = NULL
  )
}

calculate_z_score <- function(x, x_pt, sigma_pt) {
  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / sigma_pt
}

calculate_z_prime_score <- function(x, x_pt, sigma_pt, u_xpt) {
  denominador <- sqrt(sigma_pt^2 + u_xpt^2)
  if (any(!is.finite(denominador)) || any(denominador <= 0)) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

calculate_zeta_score <- function(x, x_pt, u_x, u_xpt) {
  denominador <- sqrt(u_x^2 + u_xpt^2)
  if (any(!is.finite(denominador)) || any(denominador <= 0)) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

calculate_en_score <- function(x, x_pt, U_x, U_xpt) {
  denominador <- sqrt(U_x^2 + U_xpt^2)
  if (any(!is.finite(denominador)) || any(denominador <= 0)) {
    return(rep(NA_real_, length(x)))
  }
  (x - x_pt) / denominador
}

evaluate_z_score <- function(z) {
  ifelse(
    !is.finite(z),
    "N/A",
    ifelse(abs(z) <= 2, "Satisfactorio", ifelse(abs(z) < 3, "Cuestionable", "No satisfactorio"))
  )
}

evaluate_en_score <- function(en) {
  ifelse(!is.finite(en), "N/A", ifelse(abs(en) <= 1, "Satisfactorio", "No satisfactorio"))
}

calculate_scores_table <- function(summary_df, m = NULL, k = 2) {
  columnas_requeridas <- c("pollutant", "level", "participant_id", "sample_group", "mean_value", "sd_value")
  columnas_faltantes <- setdiff(columnas_requeridas, names(summary_df))
  if (length(columnas_faltantes) > 0) {
    stop(sprintf("Faltan columnas requeridas: %s", paste(columnas_faltantes, collapse = ", ")))
  }

  grupos <- split(summary_df, list(summary_df$pollutant, summary_df$level), drop = TRUE)

  resultados <- lapply(grupos, function(datos_grupo) {
    valores <- datos_grupo$mean_value
    valores <- valores[is.finite(valores)]

    ref_data <- datos_grupo[datos_grupo$participant_id == "ref", , drop = FALSE]
    x_pt <- if (nrow(ref_data) == 0) NA_real_ else mean(ref_data$mean_value, na.rm = TRUE)

    mediana_val <- median(valores, na.rm = TRUE)
    sigma_pt <- 1.483 * median(abs(valores - mediana_val), na.rm = TRUE)

    n_valores <- length(valores)
    u_xpt <- if (!is.finite(sigma_pt) || n_valores == 0) NA_real_ else 1.25 * sigma_pt / sqrt(n_valores)

    m_local <- if (is.null(m)) length(unique(datos_grupo$sample_group)) else m
    u_x <- datos_grupo$sd_value / sqrt(m_local)
    U_x <- k * u_x
    U_xpt <- k * u_xpt

    z_score <- calculate_z_score(datos_grupo$mean_value, x_pt, sigma_pt)
    z_prime_score <- calculate_z_prime_score(datos_grupo$mean_value, x_pt, sigma_pt, u_xpt)
    zeta_score <- calculate_zeta_score(datos_grupo$mean_value, x_pt, u_x, u_xpt)
    en_score <- calculate_en_score(datos_grupo$mean_value, x_pt, U_x, U_xpt)

    data.frame(
      datos_grupo,
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      u_x = u_x,
      U_x = U_x,
      U_xpt = U_xpt,
      z_score = z_score,
      z_eval = evaluate_z_score(z_score),
      z_prime_score = z_prime_score,
      z_prime_eval = evaluate_z_score(z_prime_score),
      zeta_score = zeta_score,
      zeta_eval = evaluate_z_score(zeta_score),
      En_score = en_score,
      En_eval = evaluate_en_score(en_score),
      stringsAsFactors = FALSE
    )
  })

  tabla_final <- do.call(rbind, resultados)
  rownames(tabla_final) <- NULL
  tabla_final
}

# -------------------------------------------------------------------
# Carga fija de datos
# -------------------------------------------------------------------

ruta_datos <- normalizePath(file.path("..", "..", "data"), mustWork = TRUE)

hom_data <- read.csv(file.path(ruta_datos, "homogeneity.csv"), stringsAsFactors = FALSE)
stab_data <- read.csv(file.path(ruta_datos, "stability.csv"), stringsAsFactors = FALSE)
summary_data <- read.csv(file.path(ruta_datos, "summary_n4.csv"), stringsAsFactors = FALSE)
participants_data <- read.csv(file.path(ruta_datos, "participants_data4.csv"), stringsAsFactors = FALSE)

# -------------------------------------------------------------------
# Interfaz de usuario
# -------------------------------------------------------------------

ui <- fluidPage(
  titlePanel("Aplicativo para Evaluacion de Ensayos de Aptitud"),
  sidebarLayout(
    sidebarPanel(
      h4("Seleccion de datos"),
      selectInput("pollutant", "Analito", choices = sort(unique(hom_data$pollutant))),
      uiOutput("level_selector"),
      hr(),
      h4("Parametros"),
      selectInput("metodo_valor", "Metodo valor asignado", choices = c("1", "2a", "2b", "3"), selected = "1"),
      numericInput("k_factor", "Factor de cobertura k", value = 2, min = 1, max = 3, step = 0.1)
    ),
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Resumen",
          h4("Datos base"),
          dataTableOutput("tabla_resumen_datos"),
          hr(),
          h4("Participantes"),
          dataTableOutput("tabla_participantes")
        ),
        tabPanel(
          "Homogeneidad",
          h4("Estadisticos de homogeneidad"),
          tableOutput("tabla_homogeneidad"),
          verbatimTextOutput("conclusion_homogeneidad")
        ),
        tabPanel(
          "Estabilidad",
          h4("Estadisticos de estabilidad"),
          tableOutput("tabla_estabilidad"),
          verbatimTextOutput("conclusion_estabilidad")
        ),
        tabPanel(
          "Valor asignado",
          h4("Resumen del valor asignado"),
          tableOutput("tabla_valor_asignado")
        ),
        tabPanel(
          "Puntajes",
          h4("Tabla de puntajes"),
          dataTableOutput("tabla_puntajes")
        ),
        tabPanel(
          "Graficos",
          fluidRow(
            column(6, plotlyOutput("histograma_valores")),
            column(6, plotlyOutput("boxplot_valores"))
          ),
          hr(),
          fluidRow(
            column(6, plotlyOutput("heatmap_puntajes")),
            column(6, plotlyOutput("barras_evaluacion"))
          )
        )
      )
    )
  )
)

# -------------------------------------------------------------------
# Logica del servidor
# -------------------------------------------------------------------

server <- function(input, output, session) {
  output$level_selector <- renderUI({
    niveles <- sort(unique(hom_data$level[hom_data$pollutant == input$pollutant]))
    selectInput("level", "Nivel", choices = niveles, selected = niveles[1])
  })

  datos_hom_filtrados <- reactive({
    req(input$pollutant, input$level)
    hom_data %>% filter(pollutant == input$pollutant, level == input$level)
  })

  datos_stab_filtrados <- reactive({
    req(input$pollutant, input$level)
    stab_data %>% filter(pollutant == input$pollutant, level == input$level)
  })

  resumen_filtrado <- reactive({
    req(input$pollutant, input$level)
    summary_data %>% filter(pollutant == input$pollutant, level == input$level)
  })

  hom_stats <- reactive({
    datos <- datos_hom_filtrados()
    muestras <- construir_matriz_muestras(datos, input$pollutant, input$level)
    calculate_homogeneity_stats(muestras)
  })

  hom_sigma_pt <- reactive({
    valores <- datos_hom_filtrados()$value
    calculate_mad_e(valores)
  })

  hom_eval <- reactive({
    stats <- hom_stats()
    sigma_pt <- hom_sigma_pt()
    c_criterion <- calculate_homogeneity_criterion(sigma_pt)
    c_expanded <- calculate_homogeneity_criterion_expanded(sigma_pt, stats$sw_sq)
    evaluate_homogeneity(stats$ss, c_criterion, c_expanded)
  })

  stab_stats <- reactive({
    datos <- datos_stab_filtrados()
    hom_stats_local <- hom_stats()
    muestras <- construir_matriz_muestras(datos, input$pollutant, input$level)
    calculate_stability_stats(muestras, hom_stats_local$grand_mean)
  })

  stab_eval <- reactive({
    stats <- stab_stats()
    sigma_pt <- hom_sigma_pt()
    c_criterion <- calculate_stability_criterion(sigma_pt)

    hom_values <- datos_hom_filtrados()$value
    stab_values <- datos_stab_filtrados()$value
    u_hom_mean <- stats::sd(hom_values, na.rm = TRUE) / sqrt(sum(is.finite(hom_values)))
    u_stab_mean <- stats::sd(stab_values, na.rm = TRUE) / sqrt(sum(is.finite(stab_values)))

    c_expanded <- calculate_stability_criterion_expanded(c_criterion, u_hom_mean, u_stab_mean)
    evaluate_stability(stats$diff_hom_stab, c_criterion, c_expanded)
  })

  valor_asignado <- reactive({
    calculate_valor_asignado(summary_data, input$pollutant, input$level, metodo = input$metodo_valor)
  })

  tabla_puntajes <- reactive({
    calculate_scores_table(summary_data, k = input$k_factor)
  })

  puntajes_filtrados <- reactive({
    tabla_puntajes() %>% filter(pollutant == input$pollutant, level == input$level)
  })

  output$tabla_resumen_datos <- renderDataTable({
    datatable(resumen_filtrado(), options = list(pageLength = 5), rownames = FALSE)
  })

  output$tabla_participantes <- renderDataTable({
    datatable(participants_data, options = list(pageLength = 5), rownames = FALSE)
  })

  output$tabla_homogeneidad <- renderTable({
    stats <- hom_stats()
    data.frame(
      g = stats$g,
      m = stats$m,
      s_x_bar_sq = stats$s_x_bar_sq,
      s_xt = stats$s_xt,
      sw = stats$sw,
      ss = stats$ss,
      stringsAsFactors = FALSE
    )
  })

  output$conclusion_homogeneidad <- renderText({
    hom_eval()$conclusion
  })

  output$tabla_estabilidad <- renderTable({
    stats <- stab_stats()
    data.frame(
      g = stats$g,
      m = stats$m,
      stab_mean = stats$stab_grand_mean,
      diff_hom_stab = stats$diff_hom_stab,
      sw = stats$sw,
      ss = stats$ss,
      stringsAsFactors = FALSE
    )
  })

  output$conclusion_estabilidad <- renderText({
    stab_eval()$conclusion
  })

  output$tabla_valor_asignado <- renderTable({
    valor <- valor_asignado()
    if (!is.null(valor$error)) {
      return(data.frame(Error = valor$error, stringsAsFactors = FALSE))
    }
    data.frame(
      metodo = valor$metodo,
      x_pt = valor$x_pt,
      sigma_pt = valor$sigma_pt,
      u_xpt = valor$u_xpt,
      n = valor$n,
      stringsAsFactors = FALSE
    )
  })

  output$tabla_puntajes <- renderDataTable({
    datatable(puntajes_filtrados(), options = list(pageLength = 10), rownames = FALSE)
  })

  output$histograma_valores <- renderPlotly({
    datos <- datos_hom_filtrados()
    p <- ggplot(datos, aes(x = value)) +
      geom_histogram(fill = "#FDB913", color = "#333333", bins = 15) +
      labs(title = "Histograma de valores", x = "Valor", y = "Frecuencia")
    ggplotly(p)
  })

  output$boxplot_valores <- renderPlotly({
    datos <- datos_hom_filtrados()
    p <- ggplot(datos, aes(x = pollutant, y = value)) +
      geom_boxplot(fill = "#4DB848", color = "#333333") +
      labs(title = "Boxplot de valores", x = "Analito", y = "Valor")
    ggplotly(p)
  })

  output$heatmap_puntajes <- renderPlotly({
    datos <- puntajes_filtrados()
    if (nrow(datos) == 0) {
      return(plotly_empty())
    }

    datos_long <- datos %>%
      select(participant_id, z_score, z_prime_score, zeta_score, En_score) %>%
      pivot_longer(cols = -participant_id, names_to = "metrica", values_to = "valor")

    p <- ggplot(datos_long, aes(x = metrica, y = participant_id, fill = valor)) +
      geom_tile(color = "white") +
      scale_fill_gradient2(low = "#C62828", mid = "#FFF59D", high = "#2E7D32", midpoint = 0) +
      labs(title = "Heatmap de puntajes", x = "Metrica", y = "Participante")

    ggplotly(p)
  })

  output$barras_evaluacion <- renderPlotly({
    datos <- puntajes_filtrados()
    if (nrow(datos) == 0) {
      return(plotly_empty())
    }

    resumen_eval <- datos %>%
      count(z_eval, name = "conteo")

    p <- ggplot(resumen_eval, aes(x = z_eval, y = conteo, fill = z_eval)) +
      geom_col() +
      labs(title = "Evaluacion de z-score", x = "Categoria", y = "Conteo") +
      theme(legend.position = "none")

    ggplotly(p)
  })
}

shinyApp(ui, server)
