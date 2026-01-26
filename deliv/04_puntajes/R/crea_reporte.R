# ===================================================================
# Titulo: crea_reporte.R
# Entregable: 04
# Descripcion: Función para generar reporte de puntajes PT
# Entrada: data/summary_n4.csv, valores asignados, sigma_pt
# Salida: data.frame con puntajes, archivo CSV
# Referencia: ISO 13528:2022, Sección 10
# ===================================================================

# ===================================================================
# GENERAR REPORTE COMPLETO DE PUNTAJES
# ===================================================================

generar_reporte_puntajes <- function(datos_participantes, valor_asignado_dict, sigma_pt_dict,
                                    archivo_salida = NULL, incluir_ref = TRUE) {
  # Generar reporte completo con todos los puntajes

  # Preparar diccionarios de incertidumbre (usar NA si no están disponibles)
  u_xpt_dict <- NULL
  u_x_dict <- NULL
  U_x_dict <- NULL
  U_xpt_dict <- NULL

  # Generar puntajes
  datos_puntajes <- calcular_puntajes_todos(
    datos_participantes,
    valor_asignado_dict,
    sigma_pt_dict,
    u_xpt_dict,
    u_x_dict,
    U_x_dict,
    U_xpt_dict
  )

  if (nrow(datos_puntajes) == 0) {
    return(list(
      error = "No se generaron datos de puntajes",
      datos = data.frame(),
      archivo_salida = NULL
    ))
  }

  # Opcional: excluir participante de referencia del reporte
  if (!incluir_ref) {
    datos_puntajes <- datos_puntajes[datos_puntajes$participant_id != "ref", ]
  }

  # Guardar en archivo si se especifica
  if (!is.null(archivo_salida)) {
    write.csv(datos_puntajes, archivo_salida, row.names = FALSE)
  }

  list(
    error = NULL,
    datos = datos_puntajes,
    archivo_salida = archivo_salida,
    n_observaciones = nrow(datos_puntajes),
    n_participantes = length(unique(datos_puntajes$participant_id))
  )
}

# ===================================================================
# GENERAR REPORTE RESUMIDO POR PARTICIPANTE
# ===================================================================

generar_reporte_resumido_participantes <- function(datos_puntajes, archivo_salida = NULL) {
  # Generar reporte resumido por participante

  participantes <- unique(datos_puntajes$participant_id)
  resumenes_list <- list()

  for (part in participantes) {
    resumen <- resumir_puntajes_participante(datos_puntajes, part)
    resumenes_list[[part]] <- resumen
  }

  # Convertir a data.frame
  resumenes_df <- do.call(rbind, lapply(resumenes_list, function(r) {
    if (is.null(r$error)) {
      data.frame(
        participant_id = r$participant_id,
        total_observaciones = r$total_observaciones,
        n_satisfactorio_z = r$resumen_z$`Satisfactorio`,
        n_cuestionable_z = if (!is.null(r$resumen_z$`Cuestionable`)) r$resumen_z$`Cuestionable` else 0,
        n_no_satisfactorio_z = if (!is.null(r$resumen_z$`No satisfactorio`)) r$resumen_z$`No satisfactorio` else 0,
        n_satisfactorio_en = if (!is.null(r$resumen_en$`Satisfactorio`)) r$resumen_en$`Satisfactorio` else 0,
        n_no_satisfactorio_en = if (!is.null(r$resumen_en$`No satisfactorio`)) r$resumen_en$`No satisfactorio` else 0,
        stringsAsFactors = FALSE
      )
    } else {
      NULL
    }
  }))

  resumenes_df <- resumenes_df[!sapply(resumenes_df, is.null), ]

  # Guardar en archivo si se especifica
  if (!is.null(archivo_salida) && nrow(resumenes_df) > 0) {
    write.csv(resumenes_df, archivo_salida, row.names = FALSE)
  }

  list(
    error = NULL,
    datos = resumenes_df,
    archivo_salida = archivo_salida,
    n_participantes = nrow(resumenes_df)
  )
}

# ===================================================================
# GENERAR REPORTE DE ESTADÍSTICAS GLOBALES
# ===================================================================

generar_reporte_estadisticas_globales <- function(datos_puntajes, archivo_salida = NULL) {
  # Generar reporte de estadísticas globales

  stats_global <- calcular_estadisticas_puntajes(datos_puntajes)

  # Crear data.frame con estadísticas
  estadisticas_df <- data.frame(
    tipo_puntaje = c("z", "z", "z", "z", "z", "z", "z",
                      "z'", "z'",
                      "ζ", "ζ",
                      "En", "En", "En"),
    metrica = c("n", "media", "sd", "max_abs",
                "% satisfactorio", "% cuestionable", "% no satisfactorio",
                "n", "sd",
                "n", "sd",
                "n", "media", "% satisfactorio"),
    valor = c(stats_global$n_z, stats_global$media_z, stats_global$sd_z,
              stats_global$max_abs_z,
              stats_global$pct_satisfactorio_z, stats_global$pct_cuestionable_z,
              stats_global$pct_no_satisfactorio_z,
              stats_global$n_z_prima, stats_global$sd_z_prima,
              stats_global$n_zeta, stats_global$sd_zeta,
              stats_global$n_en, stats_global$media_en, stats_global$pct_satisfactorio_en)
  )

  # Guardar en archivo si se especifica
  if (!is.null(archivo_salida)) {
    write.csv(estadisticas_df, archivo_salida, row.names = FALSE)
  }

  list(
    error = NULL,
    datos = estadisticas_df,
    estadisticas = stats_global,
    archivo_salida = archivo_salida
  )
}

# ===================================================================
# GENERAR REPORTE COMPLETO (TODOS LOS COMPONENTES)
# ===================================================================

generar_reporte_completo <- function(datos_participantes, valor_asignado_dict, sigma_pt_dict,
                                    directorio_salida = NULL, incluir_ref = TRUE) {
  # Generar todos los reportes

  # Generar reporte de puntajes
  archivo_puntajes <- if (!is.null(directorio_salida)) {
    file.path(directorio_salida, "puntajes_completos.csv")
  } else {
    NULL
  }

  reporte_puntajes <- generar_reporte_puntajes(
    datos_participantes,
    valor_asignado_dict,
    sigma_pt_dict,
    archivo_puntajes,
    incluir_ref
  )

  if (!is.null(reporte_puntajes$error)) {
    return(reporte_puntajes)
  }

  # Generar reporte resumido
  archivo_resumido <- if (!is.null(directorio_salida)) {
    file.path(directorio_salida, "resumen_participantes.csv")
  } else {
    NULL
  }

  reporte_resumido <- generar_reporte_resumido_participantes(
    reporte_puntajes$datos,
    archivo_resumido
  )

  # Generar reporte de estadísticas globales
  archivo_estadisticas <- if (!is.null(directorio_salida)) {
    file.path(directorio_salida, "estadisticas_globales.csv")
  } else {
    NULL
  }

  reporte_estadisticas <- generar_reporte_estadisticas_globales(
    reporte_puntajes$datos,
    archivo_estadisticas
  )

  list(
    error = NULL,
    puntajes = reporte_puntajes,
    resumen_participantes = reporte_resumido,
    estadisticas_globales = reporte_estadisticas,
    directorio_salida = directorio_salida
  )
}

# ===================================================================
# FUNCIÓN PRINCIPAL: GENERAR REPORTE PT
# ===================================================================

generar_reporte_pt <- function(datos_participantes, metodo_valor_asignado = "algoritmo_a",
                                metodo_sigma_pt = "algoritmo_a", directorio_salida = NULL,
                                incluir_ref = TRUE) {
  # Flujo completo: calcular valor asignado, sigma_pt y generar reporte

  # Calcular valor asignado para todos
  resultados_va <- calcular_valor_asignado_todos(datos_participantes, metodo_valor_asignado, incluir_ref)

  # Extraer valor asignado por contaminante/nivel
  valor_asignado_dict <- lapply(resultados_va, function(r) {
    if (is.null(r$error)) r$valor_asignado else NA_real_
  })

  # Calcular sigma_pt para todos
  resultados_sigma <- calcular_sigma_pt_todos(datos_participantes, metodo_sigma_pt, incluir_ref)

  # Extraer sigma_pt por contaminante/nivel
  sigma_pt_dict <- lapply(resultados_sigma, function(r) {
    if (is.null(r$error)) r$sigma_pt else NA_real_
  })

  # Generar reporte completo
  generar_reporte_completo(
    datos_participantes,
    valor_asignado_dict,
    sigma_pt_dict,
    directorio_salida,
    incluir_ref
  )
}
