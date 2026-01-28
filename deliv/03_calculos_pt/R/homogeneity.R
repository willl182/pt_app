# ===================================================================
# Titulo: homogeneity.R
# Entregable: 03
# Descripcion: Funciones standalone para cálculo de homogeneidad según ISO 13528:2022
# Entrada: data/homogeneity.csv
# Salida: Estadísticos ss, sw, criterios c y c_expandido
# Referencia: ISO 13528:2022, Sección 9.2
# ===================================================================

# ===================================================================
# ESTADÍSTICOS DE HOMOGENEIDAD
# ===================================================================

calcular_estadisticas_homogeneidad <- function(datos_homogeneidad, contaminante, nivel) {
  # Filtrar por contaminante y nivel
  datos_filtrados <- datos_homogeneidad[
    datos_homogeneidad$pollutant == contaminante &
    datos_homogeneidad$level == nivel,
  ]

  if (nrow(datos_filtrados) == 0) {
    return(list(error = paste("No se encontraron datos para", contaminante, nivel)))
  }

  # Preparar matriz de datos (muestras como filas, réplicas como columnas)
  datos_matrix <- tapply(
    datos_filtrados$value,
    list(datos_filtrados$sample_id, datos_filtrados$replicate),
    function(x) x[1]
  )

  # Convertir a matriz
  datos_matrix <- as.matrix(datos_matrix)

  # Número de muestras (g) y réplicas (m)
  g <- nrow(datos_matrix)
  m <- ncol(datos_matrix)

  # Medias por muestra
  medias_muestras <- rowMeans(datos_matrix, na.rm = TRUE)

  # Media global: media de TODOS los valores (no solo las medias)
  media_global <- mean(datos_matrix, na.rm = TRUE)

  # x_pt: mediana de la primera réplica
  x_pt <- median(datos_matrix[, 1], na.rm = TRUE)

  # Varianza entre medias de muestra (s_x_bar^2)
  s_x_bar_sq <- var(medias_muestras, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)

  # Desviación estándar dentro de la muestra (sw)
  if (m == 2) {
    # Para m=2, usar rangos
    range_btw <- abs(datos_matrix[, 1] - datos_matrix[, 2])
    sw <- sqrt(sum(range_btw^2) / (2 * g))
  } else {
    # Caso general: varianza dentro de la muestra agrupada
    var_dentro <- apply(datos_matrix, 1, var, na.rm = TRUE)
    sw <- sqrt(mean(var_dentro, na.rm = TRUE))
  }

  sw_sq <- sw^2

  # Componente de varianza entre muestras (ss^2)
  ss_sq <- abs(s_x_bar_sq - (sw_sq / m))
  ss <- sqrt(ss_sq)

  # Mediana de las diferencias absolutas entre primera réplica y x_pt
  median_of_diffs <- median(abs(datos_matrix[, 1] - x_pt), na.rm = TRUE)

  # MADe: estimación robusta de sigma
  MADe <- 1.483 * median_of_diffs

  # Incertidumbre de MADe
  u_sigma_pt <- 1.25 * MADe / sqrt(g)

  # nIQR: estimación robusta alternativa de sigma
  Q1 <- quantile(datos_matrix[, 1], 0.25, na.rm = TRUE)
  Q3 <- quantile(datos_matrix[, 1], 0.75, na.rm = TRUE)
  IQR_val <- Q3 - Q1
  nIQR_val <- 0.7413 * IQR_val

  list(
    contaminante = contaminante,
    nivel = nivel,
    g = g,
    m = m,
    media_global = media_global,
    medias_muestras = medias_muestras,
    x_pt = x_pt,
    s_x_bar_sq = s_x_bar_sq,
    s_xt = s_xt,
    sw = sw,
    sw_sq = sw_sq,
    ss_sq = ss_sq,
    ss = ss,
    median_of_diffs = median_of_diffs,
    MADe = MADe,
    nIQR = nIQR_val,
    sigma_pt = MADe,
    u_sigma_pt = u_sigma_pt,
    datos_matrix = datos_matrix,
    error = NULL
  )
}

# ===================================================================
# CRITERIOS DE HOMOGENEIDAD
# ===================================================================

calcular_criterio_homogeneidad <- function(sigma_pt) {
  # c = 0.3 * sigma_pt
  0.3 * sigma_pt
}

calcular_criterio_expandido_homogeneidad <- function(sigma_pt, sw, g) {
  # c_exp = F1*(0.3*sigma_pt)^2 + F2*(sw)^2
  # F1/F2 lookup table indexed by g (7 to 20)
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

evaluar_homogeneidad <- function(ss, c_criterion, c_expanded = NULL) {
  if (!is.finite(ss) || !is.finite(c_criterion)) {
    pasa_criterio <- NA
    conclusion1 <- "No se puede evaluar homogeneidad (valores NA)"
  } else {
    pasa_criterio <- ss <= c_criterion

    conclusion1 <- if (pasa_criterio) {
      sprintf("ss (%.6f) <= criterio (%.6f): CUMPLE CRITERIO DE HOMOGENEIDAD", ss, c_criterion)
    } else {
      sprintf("ss (%.6f) > criterio (%.6f): NO CUMPLE CRITERIO DE HOMOGENEIDAD", ss, c_criterion)
    }
  }

  pasa_expandido <- NA
  conclusion2 <- NULL

  if (!is.null(c_expanded)) {
    if (!is.finite(ss) || !is.finite(c_expanded)) {
      conclusion2 <- "No se puede evaluar criterio expandido (valores NA)"
    } else {
      pasa_expandido <- ss <= c_expanded
      conclusion2 <- if (pasa_expandido) {
        sprintf("ss (%.6f) <= expandido (%.6f): CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
      } else {
        sprintf("ss (%.6f) > expandido (%.6f): NO CUMPLE CRITERIO EXPANDIDO", ss, c_expanded)
      }
    }
  }

  list(
    pasa_criterio = pasa_criterio,
    pasa_expandido = pasa_expandido,
    conclusion = paste(c(conclusion1, conclusion2), collapse = "\n")
  )
}

# ===================================================================
# FUNCIÓN PRINCIPAL DE HOMOGENEIDAD
# ===================================================================

analizar_homogeneidad <- function(datos_homogeneidad, contaminante, nivel, sigma_pt) {
  # Calcular estadísticos
  stats <- calcular_estadisticas_homogeneidad(datos_homogeneidad, contaminante, nivel)

  if (!is.null(stats$error)) {
    return(stats)
  }

  # Calcular criterios (usar sigma_pt calculado de MADe)
  c_criterion <- calcular_criterio_homogeneidad(stats$sigma_pt)
  c_expanded <- calcular_criterio_expandido_homogeneidad(stats$sigma_pt, stats$u_sigma_pt)

  # Evaluar
  evaluacion <- evaluar_homogeneidad(stats$ss, c_criterion, c_expanded)

  list(
    contaminante = contaminante,
    nivel = nivel,
    stats = stats,
    c_criterion = c_criterion,
    c_expanded = c_expanded,
    evaluacion = evaluacion,
    error = NULL
  )
}

# ===================================================================
# FUNCIÓN PARA PROCESAR MÚLTIPLES CONTAMINANTES/NIVELES
# ===================================================================

analizar_homogeneidad_todos <- function(datos_homogeneidad, sigma_pt_por_nivel) {
  # Obtener combinaciones únicas de contaminante y nivel
  combinaciones <- unique(datos_homogeneidad[, c("pollutant", "level")])

  resultados <- list()

  for (i in 1:nrow(combinaciones)) {
    cont <- combinaciones$pollutant[i]
    niv <- combinaciones$level[i]

    # sigma_pt ahora se calcula internamente desde los datos (MADe)
    # El parámetro sigma_pt_por_nivel ya no se usa pero se mantiene por compatibilidad
    nombre_sigma <- paste(cont, niv, sep = "_")

    resultado <- analizar_homogeneidad(datos_homogeneidad, cont, niv, NULL)
    resultados[[nombre_sigma]] <- resultado
  }

  resultados
}
