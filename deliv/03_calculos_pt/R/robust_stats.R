# ===================================================================
# Titulo: robust_stats.R
# Entregable: 03
# Descripcion: Funciones standalone de estadísticas robustas según ISO 13528:2022
# Entrada: Vectores numéricos
# Salida: Estimadores robustos (nIQR, MADe, Algoritmo A)
# Referencia: ISO 13528:2022, Sección 9.4, Anexo C
# ===================================================================

# ===================================================================
# ESTIMADORES ROBUSTOS DE ESCALA
# ===================================================================

calcular_niqr <- function(x) {
  # nIQR = 0.7413 * IQR
  # Referencia: ISO 13528:2022, Sección 9.4
  #
  # El nIQR es un estimador robusto de la desviación estándar.
  # Para datos normalmente distribuidos, nIQR ≈ σ (desviación estándar poblacional).

  x_clean <- x[is.finite(x)]

  if (length(x_clean) < 2) {
    return(NA_real_)
  }

  cuartiles <- quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (cuartiles[2] - cuartiles[1])
}

calcular_mad_e <- function(x) {
  # MADe = 1.483 * MAD
  # Referencia: ISO 13528:2022, Sección 9.4
  #
  # El MADe es un estimador robusto de la desviación estándar
  # altamente resistente a valores atípicos.
  # Para datos normalmente distribuidos, MADe ≈ σ.

  x_clean <- x[is.finite(x)]

  if (length(x_clean) == 0) {
    return(NA_real_)
  }

  mediana_datos <- median(x_clean, na.rm = TRUE)
  abs_desviaciones <- abs(x_clean - mediana_datos)
  mad_valor <- median(abs_desviaciones, na.rm = TRUE)

  1.483 * mad_valor
}

# ===================================================================
# ALGORITMO A - ESTIMACIÓN ROBUSTA ITERATIVA
# ===================================================================

ejecutar_algoritmo_a <- function(valores, ids = NULL, max_iter = 50, tol = 1e-03) {
  # Referencia: ISO 13528:2022, Anexo C
  #
  # Algoritmo iterativo para calcular estimaciones robustas de
  # ubicación (x*) y escala (s*) usando ponderación tipo Huber.
  #
  # Proceso:
  # 1. Inicializar con mediana (x*) y MADe (s*)
  # 2. Calcular residuales estandarizados: u = (x - x*) / (1.5 * s*)
  # 3. Aplicar pesos Huber: w = 1 si |u| <= 1, else w = 1/u^2
  # 4. Actualizar x* y s* usando media ponderada y SD ponderada
  # 5. Repetir hasta convergencia

  # Eliminar valores no finitos
  mask <- is.finite(valores)
  valores <- valores[mask]

  if (is.null(ids)) {
    ids <- seq_along(valores)
  } else {
    ids <- ids[mask]
  }

  n <- length(valores)

  if (n < 3) {
    return(list(
      error = "Algoritmo A requiere al menos 3 observaciones válidas.",
      valor_asignado = NA_real_,
      sigma_pt = NA_real_,
      iteraciones = data.frame(),
      pesos = data.frame(),
      convergencia = FALSE,
      peso_efectivo = NA_real_
    ))
  }

  # Estimaciones iniciales: mediana y MADe
  x_star <- median(valores, na.rm = TRUE)
  s_star <- 1.483 * median(abs(valores - x_star), na.rm = TRUE)

  # Manejar dispersión cercana a cero
  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    s_star <- sd(valores, na.rm = TRUE)
  }

  if (!is.finite(s_star) || s_star < .Machine$double.eps) {
    return(list(
      error = "La dispersión de datos es insuficiente para Algoritmo A.",
      valor_asignado = x_star,
      sigma_pt = 0,
      iteraciones = data.frame(),
      pesos = data.frame(),
      convergencia = TRUE,
      peso_efectivo = n
    ))
  }

  # Registros de iteración
  registros_iteracion <- list()
  convergencia <- FALSE

  for (iter in 1:max_iter) {
    # Residuales estandarizados
    u_valores <- (valores - x_star) / (1.5 * s_star)

    # Pesos tipo Huber
    pesos <- ifelse(abs(u_valores) <= 1, 1, 1 / (u_valores^2))

    suma_pesos <- sum(pesos)

    if (!is.finite(suma_pesos) || suma_pesos <= 0) {
      return(list(
        error = "Los pesos calculados son inválidos para Algoritmo A.",
        valor_asignado = x_star,
        sigma_pt = s_star,
        iteraciones = if (length(registros_iteracion) > 0) do.call(rbind, registros_iteracion) else data.frame(),
        pesos = data.frame(),
        convergencia = FALSE,
        peso_efectivo = NA_real_
      ))
    }

    # Estimaciones actualizadas
    x_new <- sum(pesos * valores) / suma_pesos
    s_new <- sqrt(sum(pesos * (valores - x_new)^2) / suma_pesos)

    if (!is.finite(s_new) || s_new < .Machine$double.eps) {
      return(list(
        error = "Algoritmo A colapsó debido a desviación estándar cero.",
        valor_asignado = x_new,
        sigma_pt = 0,
        iteraciones = if (length(registros_iteracion) > 0) do.call(rbind, registros_iteracion) else data.frame(),
        pesos = data.frame(),
        convergencia = FALSE,
        peso_efectivo = NA_real_
      ))
    }

    # Verificar convergencia
    delta_x <- abs(x_new - x_star)
    delta_s <- abs(s_new - s_star)
    delta <- max(delta_x, delta_s)

    registros_iteracion[[iter]] <- data.frame(
      iteracion = iter,
      x_star = x_new,
      s_star = s_new,
      delta = delta,
      stringsAsFactors = FALSE
    )

    x_star <- x_new
    s_star <- s_new

    if (delta_x < tol && delta_s < tol) {
      convergencia <- TRUE
      break
    }
  }

  # Pesos finales
  u_final <- (valores - x_star) / (1.5 * s_star)
  pesos_final <- ifelse(abs(u_final) <= 1, 1, 1 / (u_final^2))

  iteraciones_df <- if (length(registros_iteracion) > 0) {
    do.call(rbind, registros_iteracion)
  } else {
    data.frame()
  }

  pesos_df <- data.frame(
    id = ids,
    valor = valores,
    peso = pesos_final,
    residual_estandarizado = u_final,
    stringsAsFactors = FALSE
  )

  list(
    valor_asignado = x_star,
    sigma_pt = s_star,
    iteraciones = iteraciones_df,
    pesos = pesos_df,
    convergencia = convergencia,
    peso_efectivo = sum(pesos_final),
    error = NULL
  )
}

# ===================================================================
# FUNCIÓN PARA CALCULAR AMBOS ESTIMADORES ROBUSTOS
# ===================================================================

calcular_estadisticas_robustas <- function(x) {
  # Calcula nIQR, MADe y ejecuta Algoritmo A

  list(
    niqr = calcular_niqr(x),
    made = calcular_mad_e(x),
    algoritmo_a = ejecutar_algoritmo_a(x)
  )
}

# ===================================================================
# DETECCIÓN DE VALORES ATÍPICOS USANDO ESTADÍSTICAS ROBUSTAS
# ===================================================================

detectar_valores_atipicos <- function(x, metodo = "mad_e", umbral = 3) {
  # Detecta valores atípicos usando estadísticas robustas
  #
  # Métodos:
  # - "mad_e": usa MADe
  # - "niqr": usa nIQR
  #
  # Un valor se considera atípico si |z_score| > umbral
  # donde z_score = (x - mediana) / estimador_robusto

  x_clean <- x[is.finite(x)]

  if (length(x_clean) == 0) {
    return(list(
      error = "No hay datos válidos para detectar atípicos",
      atipicos = logical(length(x)),
      z_scores = rep(NA_real_, length(x))
    ))
  }

  if (metodo == "mad_e") {
    estimador <- calcular_mad_e(x_clean)
  } else if (metodo == "niqr") {
    estimador <- calcular_niqr(x_clean)
  } else {
    return(list(
      error = paste("Método no reconocido:", metodo),
      atipicos = logical(length(x)),
      z_scores = rep(NA_real_, length(x))
    ))
  }

  if (!is.finite(estimador) || estimador < .Machine$double.eps) {
    return(list(
      error = "Estimador robusto inválido o demasiado pequeño",
      atipicos = logical(length(x)),
      z_scores = rep(NA_real_, length(x))
    ))
  }

  mediana <- median(x_clean, na.rm = TRUE)
  z_scores <- (x - mediana) / estimador
  atipicos <- abs(z_scores) > umbral

  list(
    metodo = metodo,
    umbral = umbral,
    mediana = mediana,
    estimador_robusto = estimador,
    atipicos = atipicos,
    z_scores = z_scores,
    n_atipicos = sum(atipicos),
    pct_atipicos = mean(atipicos) * 100,
    error = NULL
  )
}
