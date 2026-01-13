# ===================================================================
# Cálculos de estabilidad para ensayos de aptitud
# ISO 13528:2022
# Archivo independiente sin dependencias externas
# ===================================================================

cargar_datos_estabilidad <- function(ruta_datos = "../../data/stability.csv") {
  datos <- read.csv(ruta_datos, stringsAsFactors = FALSE)
  required_cols <- c("pollutant", "level", "replicate", "sample_id", "value")
  if (!all(required_cols %in% names(datos))) {
    stop("El archivo de estabilidad no contiene las columnas esperadas.")
  }
  datos
}

cargar_datos_homogeneidad_estabilidad <- function(ruta_datos = "../../data/homogeneity.csv") {
  datos <- read.csv(ruta_datos, stringsAsFactors = FALSE)
  required_cols <- c("pollutant", "level", "replicate", "sample_id", "value")
  if (!all(required_cols %in% names(datos))) {
    stop("El archivo de homogeneidad no contiene las columnas esperadas.")
  }
  datos
}

construir_matriz_estabilidad <- function(datos, contaminante, nivel) {
  subset_datos <- datos[datos$pollutant == contaminante & datos$level == nivel, , drop = FALSE]
  if (nrow(subset_datos) == 0) {
    stop("No se encontraron registros para el contaminante y nivel solicitados.")
  }
  matriz <- stats::xtabs(value ~ sample_id + replicate, data = subset_datos)
  as.matrix(matriz)
}

calcular_estadisticos_basicos <- function(muestras) {
  g <- nrow(muestras)
  m <- ncol(muestras)

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
    sw = sw,
    sw_sq = sw_sq,
    ss = ss,
    ss_sq = ss_sq
  )
}

#' Calcular estadísticos de estabilidad
#'
#' Compara la media de estabilidad con la media de homogeneidad.
#'
#' @param contaminante Nombre del analito.
#' @param nivel Nivel del analito.
#' @param ruta_estabilidad Ruta a `stability.csv`.
#' @param ruta_homogeneidad Ruta a `homogeneity.csv`.
#' @return Lista con medias y diferencia absoluta.
calculate_stability_stats <- function(contaminante,
                                      nivel,
                                      ruta_estabilidad = "../../data/stability.csv",
                                      ruta_homogeneidad = "../../data/homogeneity.csv") {
  datos_estabilidad <- cargar_datos_estabilidad(ruta_estabilidad)
  datos_homogeneidad <- cargar_datos_homogeneidad_estabilidad(ruta_homogeneidad)

  muestras_estabilidad <- construir_matriz_estabilidad(datos_estabilidad, contaminante, nivel)
  muestras_homogeneidad <- construir_matriz_estabilidad(datos_homogeneidad, contaminante, nivel)

  g <- nrow(muestras_estabilidad)
  m <- ncol(muestras_estabilidad)

  if (g < 2 || m < 2) {
    return(list(error = "No hay suficientes datos de estabilidad para evaluar el criterio."))
  }

  stats_estabilidad <- calcular_estadisticos_basicos(muestras_estabilidad)
  stats_homogeneidad <- calcular_estadisticos_basicos(muestras_homogeneidad)

  diff_hom_stab <- abs(stats_estabilidad$grand_mean - stats_homogeneidad$grand_mean)

  list(
    g = stats_estabilidad$g,
    m = stats_estabilidad$m,
    stab_grand_mean = stats_estabilidad$grand_mean,
    hom_grand_mean = stats_homogeneidad$grand_mean,
    diff_hom_stab = diff_hom_stab,
    sw = stats_estabilidad$sw,
    ss = stats_estabilidad$ss,
    error = NULL
  )
}

#' Evaluar criterio de estabilidad
#'
#' Criterio: c = 0.3 × σ_pt (ISO 13528:2022, 9.2.3).
#'
#' @param diff_hom_stab Diferencia absoluta entre medias.
#' @param sigma_pt Desviación estándar para la evaluación de aptitud.
#' @return Lista con evaluación y conclusión.
evaluate_stability <- function(diff_hom_stab, sigma_pt) {
  if (!is.finite(diff_hom_stab) || !is.finite(sigma_pt)) {
    return(list(passes_criterion = NA, c_criterion = NA_real_, conclusion = "Datos insuficientes"))
  }
  c_criterion <- 0.3 * sigma_pt
  passes <- diff_hom_stab <= c_criterion
  conclusion <- if (passes) {
    sprintf("|y1 - y2| (%.4f) <= c (%.4f): CUMPLE CRITERIO DE ESTABILIDAD", diff_hom_stab, c_criterion)
  } else {
    sprintf("|y1 - y2| (%.4f) > c (%.4f): NO CUMPLE CRITERIO DE ESTABILIDAD", diff_hom_stab, c_criterion)
  }

  list(
    passes_criterion = passes,
    c_criterion = c_criterion,
    conclusion = conclusion
  )
}
