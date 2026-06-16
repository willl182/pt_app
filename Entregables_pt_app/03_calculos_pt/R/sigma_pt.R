# ===================================================================
# Titulo: sigma_pt.R
# Entregable: 03
# Descripcion: Funciones standalone para cálculo de sigma_pt según ISO 13528:2022
# Entrada: data/summary_n4.csv
# Salida: sigma_pt por cada método (MADe, nIQR, Algoritmo A)
# Referencia: ISO 13528:2022, Sección 9.4
# ===================================================================

# ===================================================================
# NOTA: ESTADÍSTICOS ROBUSTOS
# ===================================================================
# Las funciones de estadísticas robustas (calcular_niqr, calcular_mad_e,
# ejecutar_algoritmo_a) están disponibles en robust_stats.R
# ===================================================================

# ===================================================================
# MÉTODO 1: SIGMA_PT USANDO MADe
# ===================================================================

calcular_sigma_pt_made <- function(datos_participantes, contaminante, nivel, excluir_ref = TRUE) {
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
      sigma_pt = NA_real_,
      metodo = "made"
    ))
  }

  # Usar mean_value de cada participante
  valores <- datos_filtrados$mean_value

  # Calcular sigma_pt como MADe
  sigma_pt <- calcular_mad_e(valores)

  list(
    contaminante = contaminante,
    nivel = nivel,
    sigma_pt = sigma_pt,
    n_participantes = nrow(datos_filtrados),
    metodo = "made",
    error = NULL
  )
}

# ===================================================================
# MÉTODO 2: SIGMA_PT USANDO nIQR
# ===================================================================

calcular_sigma_pt_niqr <- function(datos_participantes, contaminante, nivel, excluir_ref = TRUE) {
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
      sigma_pt = NA_real_,
      metodo = "niqr"
    ))
  }

  # Usar mean_value de cada participante
  valores <- datos_filtrados$mean_value

  # Calcular sigma_pt como nIQR
  sigma_pt <- calcular_niqr(valores)

  list(
    contaminante = contaminante,
    nivel = nivel,
    sigma_pt = sigma_pt,
    n_participantes = nrow(datos_filtrados),
    metodo = "niqr",
    error = NULL
  )
}

# ===================================================================
# MÉTODO 3: SIGMA_PT USANDO ALGORITMO A
# ===================================================================

calcular_sigma_pt_algoritmo_a <- function(datos_participantes, contaminante, nivel, excluir_ref = TRUE,
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
      sigma_pt = NA_real_,
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
      sigma_pt = NA_real_,
      metodo = "algoritmo_a"
    ))
  }

  list(
    contaminante = contaminante,
    nivel = nivel,
    sigma_pt = resultado_algo_a$sigma_pt,
    valor_asignado = resultado_algo_a$valor_asignado,
    n_participantes = length(valores),
    n_iteraciones = nrow(resultado_algo_a$iteraciones),
    convergencia = resultado_algo_a$convergencia,
    metodo = "algoritmo_a",
    error = NULL
  )
}

# ===================================================================
# FUNCIÓN PRINCIPAL: CALCULAR SIGMA_PT
# ===================================================================

calcular_sigma_pt <- function(datos_participantes, contaminante, nivel, metodo = "algoritmo_a",
                             excluir_ref = TRUE) {
  if (metodo == "made") {
    return(calcular_sigma_pt_made(datos_participantes, contaminante, nivel, excluir_ref))
  } else if (metodo == "niqr") {
    return(calcular_sigma_pt_niqr(datos_participantes, contaminante, nivel, excluir_ref))
  } else if (metodo == "algoritmo_a") {
    return(calcular_sigma_pt_algoritmo_a(datos_participantes, contaminante, nivel, excluir_ref))
  } else {
    return(list(
      error = paste("Método no reconocido:", metodo),
      sigma_pt = NA_real_,
      metodo = metodo
    ))
  }
}

# ===================================================================
# FUNCIÓN PARA PROCESAR MÚLTIPLES CONTAMINANTES/NIVELES
# ===================================================================

calcular_sigma_pt_todos <- function(datos_participantes, metodo = "algoritmo_a", excluir_ref = TRUE) {
  # Obtener combinaciones únicas de contaminante y nivel
  combinaciones <- unique(datos_participantes[, c("pollutant", "level")])

  resultados <- list()

  for (i in 1:nrow(combinaciones)) {
    cont <- combinaciones$pollutant[i]
    niv <- combinaciones$level[i]

    nombre <- paste(cont, niv, sep = "_")
    resultado <- calcular_sigma_pt(datos_participantes, cont, niv, metodo, excluir_ref)
    resultados[[nombre]] <- resultado
  }

  resultados
}

# ===================================================================
# FUNCIÓN PARA COMPARAR MÉTODOS
# ===================================================================

comparar_metodos_sigma_pt <- function(datos_participantes, contaminante, nivel) {
  metodos <- c("made", "niqr", "algoritmo_a")

  resultados <- list()

  for (met in metodos) {
    resultado <- calcular_sigma_pt(datos_participantes, contaminante, nivel, met, excluir_ref = TRUE)
    resultados[[met]] <- resultado
  }

  list(
    contaminante = contaminante,
    nivel = nivel,
    metodos = resultados
  )
}

# ===================================================================
# CREAR DICCIONARIO DE SIGMA_PT PARA USO EN HOMOGENEIDAD/ESTABILIDAD
# ===================================================================

crear_diccionario_sigma_pt <- function(datos_participantes, metodo = "algoritmo_a") {
  resultados <- calcular_sigma_pt_todos(datos_participantes, metodo, excluir_ref = TRUE)

  diccionario <- list()

  for (nombre in names(resultados)) {
    resultado <- resultados[[nombre]]
    if (is.null(resultado$error)) {
      diccionario[[nombre]] <- resultado$sigma_pt
    }
  }

  diccionario
}
