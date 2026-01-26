# ===================================================================
# Titulo: stability.R
# Entregable: 03
# Descripcion: Funciones standalone para cálculo de estabilidad según ISO 13528:2022
# Entrada: data/stability.csv, data/homogeneity.csv
# Salida: Diferencia de medias, evaluación de criterio
# Referencia: ISO 13528:2022, Sección 9.3
# ===================================================================

# ===================================================================
# ESTADÍSTICOS DE ESTABILIDAD
# ===================================================================

calcular_estadisticas_estabilidad <- function(datos_estabilidad, media_homogeneidad, contaminante, nivel) {
  # Filtrar por contaminante y nivel
  datos_filtrados <- datos_estabilidad[
    datos_estabilidad$pollutant == contaminante &
    datos_estabilidad$level == nivel,
  ]

  if (nrow(datos_filtrados) == 0) {
    return(list(error = paste("No se encontraron datos de estabilidad para", contaminante, nivel)))
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

  # Media de estabilidad: media de TODOS los valores (no solo las medias)
  media_estabilidad <- mean(datos_matrix, na.rm = TRUE)

  # Diferencia entre medias de homogeneidad y estabilidad
  diff_hom_est <- abs(media_estabilidad - media_homogeneidad)

  # Desviación estándar dentro de la muestra
  if (m == 2) {
    rangos <- abs(datos_matrix[, 1] - datos_matrix[, 2])
    sw <- sqrt(sum(rangos^2) / (2 * g))
  } else {
    var_dentro <- apply(datos_matrix, 1, var, na.rm = TRUE)
    sw <- sqrt(mean(var_dentro, na.rm = TRUE))
  }

  list(
    contaminante = contaminante,
    nivel = nivel,
    g = g,
    m = m,
    media_homogeneidad = media_homogeneidad,
    media_estabilidad = media_estabilidad,
    diff_hom_est = diff_hom_est,
    medias_muestras = medias_muestras,
    sw = sw,
    datos_matrix = datos_matrix,
    error = NULL
  )
}

# ===================================================================
# CRITERIOS DE ESTABILIDAD
# ===================================================================

calcular_criterio_estabilidad <- function(sigma_pt) {
  # c_stab = 0.3 * sigma_pt (igual que criterio de homogeneidad)
  0.3 * sigma_pt
}

calcular_criterio_expandido_estabilidad <- function(c_criterion, u_hom_mean, u_stab_mean) {
  # c_stab_expanded = c_criterion + 2 * sqrt(u_hom^2 + u_stab^2)
  c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
}

# ===================================================================
# INCERTIDUMBRE DE MEDIA
# ===================================================================

calcular_incertidumbre_media <- function(media, datos_matrix, sw) {
  # u(x) = sw / sqrt(n) donde n es número total de observaciones
  g <- nrow(datos_matrix)
  m <- ncol(datos_matrix)
  n_total <- g * m

  sw / sqrt(n_total)
}

evaluar_estabilidad <- function(diff_hom_est, c_criterion, c_expanded = NULL) {
  if (!is.finite(diff_hom_est) || !is.finite(c_criterion)) {
    pasa_criterio <- NA
    conclusion1 <- "No se puede evaluar estabilidad (valores NA)"
  } else {
    pasa_criterio <- diff_hom_est <= c_criterion

    conclusion1 <- if (pasa_criterio) {
      sprintf("diff (%.6f) <= criterio (%.6f): CUMPLE CRITERIO DE ESTABILIDAD", diff_hom_est, c_criterion)
    } else {
      sprintf("diff (%.6f) > criterio (%.6f): NO CUMPLE CRITERIO DE ESTABILIDAD", diff_hom_est, c_criterion)
    }
  }

  pasa_expandido <- NA
  conclusion2 <- NULL

  if (!is.null(c_expanded)) {
    if (!is.finite(diff_hom_est) || !is.finite(c_expanded)) {
      conclusion2 <- "No se puede evaluar criterio expandido (valores NA)"
    } else {
      pasa_expandido <- diff_hom_est <= c_expanded
      conclusion2 <- if (pasa_expandido) {
        sprintf("diff (%.6f) <= expandido (%.6f): CUMPLE CRITERIO EXPANDIDO", diff_hom_est, c_expanded)
      } else {
        sprintf("diff (%.6f) > expandido (%.6f): NO CUMPLE CRITERIO EXPANDIDO", diff_hom_est, c_expanded)
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
# FUNCIÓN PRINCIPAL DE ESTABILIDAD
# ===================================================================

analizar_estabilidad <- function(datos_estabilidad, media_homogeneidad, contaminante, nivel, sigma_pt) {
  # Calcular estadísticos
  stats <- calcular_estadisticas_estabilidad(datos_estabilidad, media_homogeneidad, contaminante, nivel)

  if (!is.null(stats$error)) {
    return(stats)
  }

  # Calcular incertidumbre de medias
  u_hom_mean <- calcular_incertidumbre_media(media_homogeneidad, stats$datos_matrix, stats$sw)
  u_stab_mean <- calcular_incertidumbre_media(stats$media_estabilidad, stats$datos_matrix, stats$sw)

  # Calcular criterios
  c_criterion <- calcular_criterio_estabilidad(sigma_pt)
  c_expanded <- calcular_criterio_expandido_estabilidad(c_criterion, u_hom_mean, u_stab_mean)

  # Evaluar
  evaluacion <- evaluar_estabilidad(stats$diff_hom_est, c_criterion, c_expanded)

  list(
    contaminante = contaminante,
    nivel = nivel,
    media_homogeneidad = media_homogeneidad,
    media_estabilidad = stats$media_estabilidad,
    diff_hom_est = stats$diff_hom_est,
    stats = stats,
    u_hom_mean = u_hom_mean,
    u_stab_mean = u_stab_mean,
    c_criterion = c_criterion,
    c_expanded = c_expanded,
    evaluacion = evaluacion,
    error = NULL
  )
}

# ===================================================================
# FUNCIÓN PARA PROCESAR MÚLTIPLES CONTAMINANTES/NIVELES
# ===================================================================

analizar_estabilidad_todos <- function(datos_estabilidad, datos_homogeneidad, resultados_homogeneidad) {
  # Obtener combinaciones únicas de contaminante y nivel de estabilidad
  combinaciones <- unique(datos_estabilidad[, c("pollutant", "level")])

  resultados <- list()

  for (i in 1:nrow(combinaciones)) {
    cont <- combinaciones$pollutant[i]
    niv <- combinaciones$level[i]

    # Buscar resultado de homogeneidad correspondiente
    nombre_hom <- paste(cont, niv, sep = "_")
    resultado_hom <- resultados_homogeneidad[[nombre_hom]]

    if (is.null(resultado_hom) || !is.null(resultado_hom$error)) {
      warning(paste("No se encontró resultado de homogeneidad para", nombre_hom))
      next
    }

    media_hom <- resultado_hom$stats$media_global
    sigma_pt <- resultado_hom$c_criterion / 0.3

    resultado <- analizar_estabilidad(datos_estabilidad, media_hom, cont, niv, sigma_pt)
    resultados[[nombre_hom]] <- resultado
  }

  resultados
}
