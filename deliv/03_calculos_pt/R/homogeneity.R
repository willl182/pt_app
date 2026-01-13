# ===================================================================
# Cálculos de homogeneidad para ensayos de aptitud
# ISO 13528:2022
# Archivo independiente sin dependencias externas
# ===================================================================

cargar_datos_homogeneidad <- function(ruta_datos = "../../data/homogeneity.csv") {
  datos <- read.csv(ruta_datos, stringsAsFactors = FALSE)
  required_cols <- c("pollutant", "level", "replicate", "sample_id", "value")
  if (!all(required_cols %in% names(datos))) {
    stop("El archivo de homogeneidad no contiene las columnas esperadas.")
  }
  datos
}

construir_matriz_muestras <- function(datos, contaminante, nivel) {
  subset_datos <- datos[datos$pollutant == contaminante & datos$level == nivel, , drop = FALSE]
  if (nrow(subset_datos) == 0) {
    stop("No se encontraron registros para el contaminante y nivel solicitados.")
  }
  matriz <- stats::xtabs(value ~ sample_id + replicate, data = subset_datos)
  as.matrix(matriz)
}

#' Calcular estadísticos de homogeneidad
#'
#' Calcula estadísticos básicos para evaluar la homogeneidad de un lote de ítems.
#' Incluye la desviación estándar entre muestras (s_s) y dentro de muestras (s_w).
#'
#' @param contaminante Nombre del analito (ej. "co").
#' @param nivel Nivel del analito (ej. "2-μmol/mol").
#' @param ruta_datos Ruta al archivo `homogeneity.csv`.
#' @return Lista con estadísticos calculados y un campo `error` si aplica.
calculate_homogeneity_stats <- function(contaminante, nivel, ruta_datos = "../../data/homogeneity.csv") {
  datos <- cargar_datos_homogeneidad(ruta_datos)
  muestras <- construir_matriz_muestras(datos, contaminante, nivel)

  g <- nrow(muestras)
  m <- ncol(muestras)

  if (g < 2) {
    return(list(error = "Se requieren al menos 2 muestras para evaluar homogeneidad."))
  }
  if (m < 2) {
    return(list(error = "Se requieren al menos 2 réplicas por muestra para evaluar homogeneidad."))
  }

  medias_muestras <- rowMeans(muestras, na.rm = TRUE)
  media_general <- base::mean(medias_muestras, na.rm = TRUE)

  s_x_bar_sq <- stats::var(medias_muestras, na.rm = TRUE)
  s_xt <- sqrt(s_x_bar_sq)

  if (m == 2) {
    rangos <- abs(muestras[, 1] - muestras[, 2])
    sw <- sqrt(sum(rangos^2) / (2 * g))
  } else {
    vars_internas <- apply(muestras, 1, stats::var, na.rm = TRUE)
    sw <- sqrt(base::mean(vars_internas, na.rm = TRUE))
  }

  sw_sq <- sw^2
  ss_sq <- abs(s_x_bar_sq - (sw_sq / m))
  ss <- sqrt(ss_sq)

  list(
    g = g,
    m = m,
    grand_mean = media_general,
    sample_means = medias_muestras,
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
#'
#' Criterio: c = 0.3 × σ_pt (ISO 13528:2022, 9.2.3).
#'
#' @param sigma_pt Desviación estándar para la evaluación de aptitud.
#' @return Valor del criterio de homogeneidad.
calculate_homogeneity_criterion <- function(sigma_pt) {
  if (!is.finite(sigma_pt)) {
    return(NA_real_)
  }
  0.3 * sigma_pt
}
