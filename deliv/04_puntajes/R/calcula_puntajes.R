# ===================================================================
# Titulo: calcula_puntajes.R
# Entregable: 04
# Descripcion: Funciones standalone para cálculo de puntajes PT (z, z', ζ, En)
# Entrada: data/summary_n4.csv, valores asignados y sigma_pt
# Salida: data.frame con puntajes por participante
# Referencia: ISO 13528:2022, Sección 10
# ===================================================================

# ===================================================================
# CÁLCULO DE PUNTAJES PT
# ===================================================================

calcular_puntaje_z <- function(x, x_pt, sigma_pt) {
  # z = (x - x_pt) / sigma_pt
  # Referencia: ISO 13528:2022, Sección 10.2

  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(NA_real_)
  }
  (x - x_pt) / sigma_pt
}

calcular_puntaje_z_prima <- function(x, x_pt, sigma_pt, u_xpt) {
  # z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt^2)
  # Referencia: ISO 13528:2022, Sección 10.3

  if (!is.finite(sigma_pt) || sigma_pt <= 0) {
    return(NA_real_)
  }

  denominador <- sqrt(sigma_pt^2 + u_xpt^2)

  if (!is.finite(denominador) || denominador <= 0) {
    return(NA_real_)
  }

  (x - x_pt) / denominador
}

calcular_puntaje_zeta <- function(x, x_pt, u_x, u_xpt) {
  # ζ = (x - x_pt) / sqrt(u_x^2 + u_xpt^2)
  # Referencia: ISO 13528:2022, Sección 10.4

  denominador <- sqrt(u_x^2 + u_xpt^2)

  if (!is.finite(denominador) || denominador <= 0) {
    return(NA_real_)
  }

  (x - x_pt) / denominador
}

calcular_puntaje_en <- function(x, x_pt, U_x, U_xpt) {
  # En = (x - x_pt) / sqrt(U_x^2 + U_xpt^2)
  # Referencia: ISO 13528:2022, Sección 10.5

  denominador <- sqrt(U_x^2 + U_xpt^2)

  if (!is.finite(denominador) || denominador <= 0) {
    return(NA_real_)
  }

  (x - x_pt) / denominador
}

# ===================================================================
# EVALUACIÓN DE PUNTAJES
# ===================================================================

evaluar_puntaje_z <- function(z) {
  # Criterios para z, z', ζ:
  # |z| <= 2: Satisfactorio
  # 2 < |z| < 3: Cuestionable
  # |z| >= 3: No satisfactorio
  # Referencia: ISO 13528:2022, Sección 10

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

evaluar_puntaje_z_vec <- function(z) {
  # Evaluación vectorizada
  sapply(z, evaluar_puntaje_z)
}

evaluar_puntaje_en <- function(en) {
  # Criterios para En:
  # |En| <= 1: Satisfactorio
  # |En| > 1: No satisfactorio
  # Referencia: ISO 13528:2022, Sección 10.5

  if (!is.finite(en)) {
    return("N/A")
  }

  if (abs(en) <= 1) {
    return("Satisfactorio")
  } else {
    return("No satisfactorio")
  }
}

evaluar_puntaje_en_vec <- function(en) {
  # Evaluación vectorizada
  sapply(en, evaluar_puntaje_en)
}

# ===================================================================
# FUNCIÓN PRINCIPAL: CALCULAR TODOS LOS PUNTAJES PARA UN PARTICIPANTE
# ===================================================================

calcular_puntajes_participante <- function(datos_participante, x_pt, sigma_pt, u_xpt = NA, u_x = NA, U_x = NA, U_xpt = NA) {
  # Calcular puntajes para todas las observaciones de un participante

  z <- calcular_puntaje_z(datos_participante$mean_value, x_pt, sigma_pt)
  eval_z <- evaluar_puntaje_z_vec(z)

  z_prima <- if (is.finite(u_xpt)) {
    calcular_puntaje_z_prima(datos_participante$mean_value, x_pt, sigma_pt, u_xpt)
  } else {
    rep(NA_real_, nrow(datos_participante))
  }
  eval_z_prima <- evaluar_puntaje_z_vec(z_prima)

  zeta <- if (is.finite(u_x) && is.finite(u_xpt)) {
    calcular_puntaje_zeta(datos_participante$mean_value, x_pt, u_x, u_xpt)
  } else {
    rep(NA_real_, nrow(datos_participante))
  }
  eval_zeta <- evaluar_puntaje_z_vec(zeta)

  en <- if (is.finite(U_x) && is.finite(U_xpt)) {
    calcular_puntaje_en(datos_participante$mean_value, x_pt, U_x, U_xpt)
  } else {
    rep(NA_real_, nrow(datos_participante))
  }
  eval_en <- evaluar_puntaje_en_vec(en)

  data.frame(
    pollutant = datos_participante$pollutant,
    run = datos_participante$run,
    level = datos_participante$level,
    participant_id = datos_participante$participant_id,
    replicate = datos_participante$replicate,
    sample_group = datos_participante$sample_group,
    x = datos_participante$mean_value,
    x_pt = x_pt,
    sigma_pt = sigma_pt,
    z = z,
    evaluacion_z = eval_z,
    z_prima = z_prima,
    evaluacion_z_prima = eval_z_prima,
    zeta = zeta,
    evaluacion_zeta = eval_zeta,
    en = en,
    evaluacion_en = eval_en,
    stringsAsFactors = FALSE
  )
}

# ===================================================================
# CALCULAR PUNTAJES PARA TODOS LOS PARTICIPANTES
# ===================================================================

calcular_puntajes_todos <- function(datos_participantes, valor_asignado_dict, sigma_pt_dict, u_xpt_dict = NULL, u_x_dict = NULL, U_x_dict = NULL, U_xpt_dict = NULL) {
  # Obtener combinaciones únicas
  combinaciones <- unique(datos_participantes[, c("pollutant", "level")])

  resultados <- list()

  for (i in 1:nrow(combinaciones)) {
    cont <- combinaciones$pollutant[i]
    niv <- combinaciones$level[i]

    # Buscar valor asignado y sigma_pt
    nombre_clave <- paste(cont, niv, sep = "_")

    x_pt <- if (!is.null(valor_asignado_dict[[nombre_clave]])) {
      valor_asignado_dict[[nombre_clave]]
    } else {
      warning(paste("No se encontró valor asignado para", nombre_clave))
      next
    }

    sigma_pt <- if (!is.null(sigma_pt_dict[[nombre_clave]])) {
      sigma_pt_dict[[nombre_clave]]
    } else {
      warning(paste("No se encontró sigma_pt para", nombre_clave))
      next
    }

    # Buscar incertidumbres si están disponibles
    u_xpt <- if (!is.null(u_xpt_dict)) u_xpt_dict[[nombre_clave]] else NA
    u_x <- if (!is.null(u_x_dict)) u_x_dict[[nombre_clave]] else NA
    U_x <- if (!is.null(U_x_dict)) U_x_dict[[nombre_clave]] else NA
    U_xpt <- if (!is.null(U_xpt_dict)) U_xpt_dict[[nombre_clave]] else NA

    # Filtrar datos para este contaminante y nivel
    datos_filtrados <- datos_participantes[
      datos_participantes$pollutant == cont &
      datos_participantes$level == niv,
    ]

    # Calcular puntajes
    resultados[[nombre_clave]] <- calcular_puntajes_participante(
      datos_filtrados, x_pt, sigma_pt, u_xpt, u_x, U_x, U_xpt
    )
  }

  # Combinar todos los resultados
  if (length(resultados) > 0) {
    do.call(rbind, resultados)
  } else {
    data.frame()
  }
}

# ===================================================================
# RESUMEN DE PUNTAJES POR PARTICIPANTE
# ===================================================================

resumir_puntajes_participante <- function(datos_puntajes, participant_id) {
  # Filtrar por participante
  datos_part <- datos_puntajes[datos_puntajes$participant_id == participant_id, ]

  if (nrow(datos_part) == 0) {
    return(list(
      error = paste("No se encontraron datos para participante", participant_id)
    ))
  }

  # Contar evaluaciones por tipo
  counts_z <- table(datos_part$evaluacion_z)
  counts_z_prima <- table(datos_part$evaluacion_z_prima)
  counts_zeta <- table(datos_part$evaluacion_zeta)
  counts_en <- table(datos_part$evaluacion_en)

  list(
    participant_id = participant_id,
    total_observaciones = nrow(datos_part),
    resumen_z = as.list(counts_z),
    resumen_z_prima = as.list(counts_z_prima),
    resumen_zeta = as.list(counts_zeta),
    resumen_en = as.list(counts_en),
    error = NULL
  )
}

# ===================================================================
# RESUMEN GLOBAL DE TODOS LOS PARTICIPANTES
# ===================================================================

resumir_puntajes_global <- function(datos_puntajes) {
  participantes <- unique(datos_puntajes$participant_id)

  resumenes <- list()

  for (part in participantes) {
    resumenes[[part]] <- resumir_puntajes_participante(datos_puntajes, part)
  }

  resumenes
}

# ===================================================================
# ESTADÍSTICAS DE PUNTAJES
# ===================================================================

calcular_estadisticas_puntajes <- function(datos_puntajes) {
  # Filtrar valores finitos, manejando columnas opcionales
  z_validos <- if ("z" %in% names(datos_puntajes)) {
    datos_puntajes$z[is.finite(datos_puntajes$z)]
  } else {
    numeric(0)
  }

  z_prima_validos <- if ("z_prima" %in% names(datos_puntajes)) {
    datos_puntajes$z_prima[is.finite(datos_puntajes$z_prima)]
  } else {
    numeric(0)
  }

  zeta_validos <- if ("zeta" %in% names(datos_puntajes)) {
    datos_puntajes$zeta[is.finite(datos_puntajes$zeta)]
  } else {
    numeric(0)
  }

  en_validos <- if ("en" %in% names(datos_puntajes)) {
    datos_puntajes$en[is.finite(datos_puntajes$en)]
  } else {
    numeric(0)
  }

  list(
    n_z = length(z_validos),
    media_z = if (length(z_validos) > 0) mean(z_validos, na.rm = TRUE) else NA_real_,
    sd_z = if (length(z_validos) > 0) sd(z_validos, na.rm = TRUE) else NA_real_,
    max_abs_z = if (length(z_validos) > 0) max(abs(z_validos), na.rm = TRUE) else NA_real_,
    pct_satisfactorio_z = if (length(z_validos) > 0) mean(abs(z_validos) <= 2) * 100 else NA_real_,
    pct_cuestionable_z = if (length(z_validos) > 0) mean(abs(z_validos) > 2 & abs(z_validos) < 3) * 100 else NA_real_,
    pct_no_satisfactorio_z = if (length(z_validos) > 0) mean(abs(z_validos) >= 3) * 100 else NA_real_,

    n_z_prima = length(z_prima_validos),
    media_z_prima = if (length(z_prima_validos) > 0) mean(z_prima_validos, na.rm = TRUE) else NA_real_,
    sd_z_prima = if (length(z_prima_validos) > 0) sd(z_prima_validos, na.rm = TRUE) else NA_real_,

    n_zeta = length(zeta_validos),
    media_zeta = if (length(zeta_validos) > 0) mean(zeta_validos, na.rm = TRUE) else NA_real_,
    sd_zeta = if (length(zeta_validos) > 0) sd(zeta_validos, na.rm = TRUE) else NA_real_,

    n_en = length(en_validos),
    media_en = if (length(en_validos) > 0) mean(en_validos, na.rm = TRUE) else NA_real_,
    sd_en = if (length(en_validos) > 0) sd(en_validos, na.rm = TRUE) else NA_real_,
    pct_satisfactorio_en = if (length(en_validos) > 0) mean(abs(en_validos) <= 1) * 100 else NA_real_,
    pct_no_satisfactorio_en = if (length(en_validos) > 0) mean(abs(en_validos) > 1) * 100 else NA_real_
  )
}
