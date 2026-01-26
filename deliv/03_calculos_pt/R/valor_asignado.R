# ===================================================================
# Titulo: valor_asignado.R
# Entregable: 03
# Descripcion: Funciones standalone para cálculo de valor asignado según ISO 13528:2022
# Entrada: data/summary_n4.csv
# Salida: Valor asignado por cada método (referencia, consenso MADe, consenso nIQR, Algoritmo A)
# Referencia: ISO 13528:2022, Sección 8
# ===================================================================

# ===================================================================
# NOTA: ESTADÍSTICOS ROBUSTOS
# ===================================================================
# Las funciones de estadísticas robustas (calcular_niqr, calcular_mad_e,
# ejecutar_algoritmo_a) están disponibles en robust_stats.R
# ===================================================================

# ===================================================================
# MÉTODO 1: VALOR DE REFERENCIA
# ===================================================================

calcular_valor_referencia <- function(datos_participantes, contaminante, nivel) {
  # Filtrar por contaminante, nivel y participante 'ref'
  datos_filtrados <- datos_participantes[
    datos_participantes$pollutant == contaminante &
    datos_participantes$level == nivel &
    datos_participantes$participant_id == "ref",
  ]

  if (nrow(datos_filtrados) == 0) {
    return(list(
      error = "No se encontraron datos de referencia",
      valor_asignado = NA_real_,
      metodo = "referencia"
    ))
  }

  # Promediar mean_value de todas las réplicas
  valor_asignado <- mean(datos_filtrados$mean_value, na.rm = TRUE)

  list(
    contaminante = contaminante,
    nivel = nivel,
    valor_asignado = valor_asignado,
    n_replicas = nrow(datos_filtrados),
    metodo = "referencia",
    error = NULL
  )
}

# ===================================================================
# MÉTODO 2a: CONSENSO CON MADe
# ===================================================================

calcular_valor_consenso_made <- function(datos_participantes, contaminante, nivel, excluir_ref = TRUE) {
  # Filtrar por contaminante y nivel
  datos_filtrados <- datos_participantes[
    datos_participantes$pollutant == contaminante &
    datos_participantes$level == nivel,
  ]

  # Excluir participante de referencia si se solicita
  if (excluir_ref) {
    datos_filtrados <- datos_filtrados[datos_filtrados$participant_id != "ref", ]
  }

  if (nrow(datos_filtrados) == 0) {
    return(list(
      error = "No se encontraron datos de participantes",
      valor_asignado = NA_real_,
      metodo = "consenso_made"
    ))
  }

  # Usar mean_value de cada participante
  valores <- datos_filtrados$mean_value

  # Calcular valor asignado como robust mean usando MADe
  valor_asignado <- median(valores, na.rm = TRUE)
  sigma_pt <- calcular_mad_e(valores)

  list(
    contaminante = contaminante,
    nivel = nivel,
    valor_asignado = valor_asignado,
    n_participantes = nrow(datos_filtrados),
    sigma_pt = sigma_pt,
    metodo = "consenso_made",
    error = NULL
  )
}

# ===================================================================
# MÉTODO 2b: CONSENSO CON nIQR
# ===================================================================

calcular_valor_consenso_niqr <- function(datos_participantes, contaminante, nivel, excluir_ref = TRUE) {
  # Filtrar por contaminante y nivel
  datos_filtrados <- datos_participantes[
    datos_participantes$pollutant == contaminante &
    datos_participantes$level == nivel,
  ]

  # Excluir participante de referencia si se solicita
  if (excluir_ref) {
    datos_filtrados <- datos_filtrados[datos_filtrados$participant_id != "ref", ]
  }

  if (nrow(datos_filtrados) == 0) {
    return(list(
      error = "No se encontraron datos de participantes",
      valor_asignado = NA_real_,
      metodo = "consenso_niqr"
    ))
  }

  # Usar mean_value de cada participante
  valores <- datos_filtrados$mean_value

  # Calcular valor asignado como robust mean usando nIQR
  valor_asignado <- median(valores, na.rm = TRUE)
  sigma_pt <- calcular_niqr(valores)

  list(
    contaminante = contaminante,
    nivel = nivel,
    valor_asignado = valor_asignado,
    n_participantes = nrow(datos_filtrados),
    sigma_pt = sigma_pt,
    metodo = "consenso_niqr",
    error = NULL
  )
}

# ===================================================================
# MÉTODO 3: ALGORITMO A (ISO 13528 ANEXO C)
# ===================================================================

calcular_valor_algoritmo_a <- function(datos_participantes, contaminante, nivel, excluir_ref = TRUE,
                                       max_iter = 50, tol = 1e-03) {
  # Filtrar por contaminante y nivel
  datos_filtrados <- datos_participantes[
    datos_participantes$pollutant == contaminante &
    datos_participantes$level == nivel,
  ]

  # Excluir participante de referencia si se solicita
  if (excluir_ref) {
    datos_filtrados <- datos_filtrados[datos_filtrados$participant_id != "ref", ]
  }

  if (nrow(datos_filtrados) == 0) {
    return(list(
      error = "No se encontraron datos de participantes",
      valor_asignado = NA_real_,
      metodo = "algoritmo_a"
    ))
  }

  # Usar mean_value de cada participante
  valores <- datos_filtrados$mean_value
  ids <- datos_filtrados$participant_id

  # Ejecutar Algoritmo A
  resultado_algo_a <- ejecutar_algoritmo_a(valores, ids, max_iter, tol)

  if (!is.null(resultado_algo_a$error)) {
    return(list(
      error = resultado_algo_a$error,
      valor_asignado = NA_real_,
      metodo = "algoritmo_a"
    ))
  }

  list(
    contaminante = contaminante,
    nivel = nivel,
    valor_asignado = resultado_algo_a$valor_asignado,
    sigma_pt = resultado_algo_a$sigma_pt,
    n_participantes = length(valores),
    n_iteraciones = nrow(resultado_algo_a$iteraciones),
    convergencia = resultado_algo_a$convergencia,
    metodo = "algoritmo_a",
    error = NULL
  )
}

# ===================================================================
# FUNCIÓN PRINCIPAL: CALCULAR VALOR ASIGNADO (TODOS LOS MÉTODOS)
# ===================================================================

calcular_valor_asignado <- function(datos_participantes, contaminante, nivel, metodo = "algoritmo_a",
                                    excluir_ref = TRUE) {
  if (metodo == "referencia") {
    return(calcular_valor_referencia(datos_participantes, contaminante, nivel))
  } else if (metodo == "consenso_made") {
    return(calcular_valor_consenso_made(datos_participantes, contaminante, nivel, excluir_ref))
  } else if (metodo == "consenso_niqr") {
    return(calcular_valor_consenso_niqr(datos_participantes, contaminante, nivel, excluir_ref))
  } else if (metodo == "algoritmo_a") {
    return(calcular_valor_algoritmo_a(datos_participantes, contaminante, nivel, excluir_ref))
  } else {
    return(list(
      error = paste("Método no reconocido:", metodo),
      valor_asignado = NA_real_,
      metodo = metodo
    ))
  }
}

# ===================================================================
# FUNCIÓN PARA PROCESAR MÚLTIPLES CONTAMINANTES/NIVELES
# ===================================================================

calcular_valor_asignado_todos <- function(datos_participantes, metodo = "algoritmo_a", excluir_ref = TRUE) {
  # Obtener combinaciones únicas de contaminante y nivel
  combinaciones <- unique(datos_participantes[, c("pollutant", "level")])

  resultados <- list()

  for (i in 1:nrow(combinaciones)) {
    cont <- combinaciones$pollutant[i]
    niv <- combinaciones$level[i]

    nombre <- paste(cont, niv, sep = "_")
    resultado <- calcular_valor_asignado(datos_participantes, cont, niv, metodo, excluir_ref)
    resultados[[nombre]] <- resultado
  }

  resultados
}

# ===================================================================
# FUNCIÓN PARA COMPARAR MÉTODOS
# ===================================================================

comparar_metodos_valor_asignado <- function(datos_participantes, contaminante, nivel) {
  metodos <- c("referencia", "consenso_made", "consenso_niqr", "algoritmo_a")

  resultados <- list()

  for (met in metodos) {
    resultado <- calcular_valor_asignado(datos_participantes, contaminante, nivel, met, excluir_ref = TRUE)
    resultados[[met]] <- resultado
  }

  list(
    contaminante = contaminante,
    nivel = nivel,
    metodos = resultados
  )
}
