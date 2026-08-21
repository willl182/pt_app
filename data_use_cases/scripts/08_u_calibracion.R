# ===================================================================
# Componentes de incertidumbre extraidos de los formatos de
# calibracion multipunto (F-PSEY-47/49/61/62)
#
# Implementa el metodo descrito en uncer_cal.md. Cada formato trae la
# curva multipunto del analizador: concentracion del calibrador,
# lectura promedio y estabilidad de las replicas. Con 5 puntos (cero
# dejado + 20/40/70/90 %) se calculan los dos componentes que uncer.md
# deja planteados pero sin datos:
#
#   u_gum   incertidumbre de la curva por minimos cuadrados (GUM anexo
#           H.3, ecuaciones H.13c-e), evaluada en cada nivel,
#   u_lof   falta de ajuste (EN 14211/14212), desde el residuo maximo
#           relativo al tope de la curva.
#
# u_curva es el MAYOR de los dos, no su suma: son dos estimaciones del
# mismo efecto (uncer_cal.md seccion 3).
#
# Ademas se registran, sin combinarlos automaticamente:
#   - estabilidad de las replicas de calibracion (repetibilidad de
#     corto plazo, contraste con 07_u_repetibilidad.R),
#   - deriva de gain/offset entre calibraciones sucesivas del mismo
#     analizador,
#   - eficiencia del convertidor de NO2.
#
# Las lecturas de los formatos son valores en cache de formulas de
# Excel; readxl no los devuelve, asi que la pendiente y el intercepto
# se recalculan aqui desde los puntos, que si son numeros literales.
# ===================================================================

if (!exists("pt_u_rep_resumen", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "07_u_repetibilidad.R"))) {
    file.path("scripts", "07_u_repetibilidad.R")
  } else {
    file.path("data_use_cases", "scripts", "07_u_repetibilidad.R")
  }
  source(script_path)
}

CALIBRATION_DIRS <- c(RR_DIR, ANALYSIS_ROOT)
# Factor de cobertura para reportar U.
CAL_K <- 2

# -------------------------------------------------------------------
# Lectura de la hoja FORMATO
# -------------------------------------------------------------------

read_formato <- function(path) {
  suppressMessages(as.data.frame(readxl::read_excel(
    path, sheet = "FORMATO", col_names = FALSE, .name_repair = "minimal"
  )))
}

# Los formatos difieren en filas y columnas segun el gas, asi que
# nada se referencia por coordenada fija: se ancla por la etiqueta.
find_label_row <- function(sheet, label, exact = TRUE, from_row = 1L) {
  normalized <- function(x) {
    x <- gsub("[[:space:]]+", " ", trimws(as.character(x)))
    tolower(x)
  }
  target <- normalized(label)
  for (i in seq(from_row, nrow(sheet))) {
    cells <- normalized(unlist(sheet[i, ], use.names = FALSE))
    hit <- if (exact) {
      which(cells == target)
    } else {
      which(startsWith(cells, target))
    }
    if (length(hit) > 0L) {
      return(list(fila = i, columna = hit[[1L]]))
    }
  }
  NULL
}

# Devuelve los valores de una fila a la derecha de la etiqueta,
# conservando la posicion: los formatos marcan los puntos que no
# aplican con "+" o "---", y compactarlos desalinearia las columnas
# respecto al encabezado (zero, 20 %, 40 %, ...).
label_values <- function(sheet, label, count = 7L, exact = TRUE, from_row = 1L) {
  anchor <- find_label_row(sheet, label, exact, from_row)
  if (is.null(anchor)) {
    return(NULL)
  }
  cells <- unlist(sheet[anchor$fila, ], use.names = FALSE)
  index <- seq(anchor$columna + 1L, min(anchor$columna + count, length(cells)))
  suppressWarnings(as.numeric(cells[index]))
}

single_value <- function(sheet, label, exact = TRUE) {
  values <- label_values(sheet, label, count = 3L, exact = exact)
  values <- values[is.finite(values)]
  if (length(values) == 0L) NA_real_ else values[[1L]]
}

text_value <- function(sheet, label, exact = TRUE) {
  anchor <- find_label_row(sheet, label, exact)
  if (is.null(anchor)) {
    return(NA_character_)
  }
  cells <- unlist(sheet[anchor$fila, ], use.names = FALSE)
  tail_cells <- trimws(as.character(cells[seq(anchor$columna + 1L, length(cells))]))
  tail_cells <- tail_cells[!is.na(tail_cells) & nzchar(tail_cells) &
                             tail_cells != "NA"]
  if (length(tail_cells) == 0L) NA_character_ else tail_cells[[1L]]
}

# -------------------------------------------------------------------
# Extraccion de la curva multipunto
# -------------------------------------------------------------------

# En los formatos de un solo gas las 7 columnas son, en orden:
# zero encontrado, zero dejado, 20 %, 40 %, 70 %, 90 % dejado,
# 90 % encontrado. Siguiendo uncer_cal.md seccion 2 se usan 5 puntos:
# el zero dejado mas los cuatro multipunto. El "90 % encontrado" se
# excluye por ser pre-ajuste, y el "zero encontrado" por lo mismo.
MULTIPOINT_INDEX <- 2:6

extract_single_gas <- function(sheet, path, gas) {
  nominal <- label_values(sheet, "Concentración de Salida")
  reading <- label_values(sheet, "Lectura")
  stability <- label_values(sheet, "Estabilidad")
  if (is.null(nominal) || is.null(reading)) {
    return(NULL)
  }
  index <- MULTIPOINT_INDEX
  # Un formato de zero/span deja los puntos multipunto en "+", asi que
  # quedan como NA y la curva se descarta aguas abajo.
  list(
    archivo = basename(path),
    gas = gas,
    nominal = nominal[index],
    lectura = reading[index],
    estabilidad = if (is.null(stability)) rep(NA_real_, length(index)) else stability[index],
    eficiencia_convertidor = NA_real_
  )
}

# El formato de NOx trae dos curvas: la de NO por dilucion directa y
# la de NO2 por titulacion en fase gaseosa (GPT).
extract_nox <- function(sheet, path) {
  no_nominal <- label_values(sheet, "Concentración de Salida")
  no_reading <- label_values(sheet, "Lectura NO")
  no_stability <- label_values(sheet, "Estabilidad NO")
  # "NO2" y "Estabilidad" aparecen sueltos en varias partes del
  # formato, asi que la curva GPT se busca a partir de su encabezado.
  gpt_anchor <- find_label_row(sheet, "Valor Esperado de NO2")
  gpt_row <- if (is.null(gpt_anchor)) 1L else gpt_anchor$fila
  no2_nominal <- label_values(sheet, "Valor Esperado de NO2")
  no2_reading <- label_values(sheet, "NO2", from_row = gpt_row)
  no2_stability <- label_values(sheet, "Estabilidad", from_row = gpt_row)

  nox_reading <- label_values(sheet, "Lectura NOx")
  nox_stability <- label_values(sheet, "Estabilidad NOx")

  result <- list()
  for (channel in list(
    list(gas = "no", lectura = no_reading, estabilidad = no_stability),
    list(gas = "nox", lectura = nox_reading, estabilidad = nox_stability)
  )) {
    if (is.null(no_nominal) || is.null(channel$lectura)) next
    result[[length(result) + 1L]] <- list(
      archivo = basename(path),
      gas = channel$gas,
      nominal = no_nominal[MULTIPOINT_INDEX],
      lectura = channel$lectura[MULTIPOINT_INDEX],
      estabilidad = if (is.null(channel$estabilidad)) {
        rep(NA_real_, length(MULTIPOINT_INDEX))
      } else {
        channel$estabilidad[MULTIPOINT_INDEX]
      },
      eficiencia_convertidor = NA_real_
    )
  }
  # La curva GPT arranca en el zero dejado; los puntos utiles son los
  # cuatro siguientes.
  if (!is.null(no2_nominal) && !is.null(no2_reading)) {
    # La curva GPT ya arranca en el zero dejado: sus 5 columnas son
    # zero dejado + 20/40/70/90 %.
    index <- 1:5
    result[[length(result) + 1L]] <- list(
      archivo = basename(path),
      gas = "no2",
      nominal = no2_nominal[index],
      lectura = no2_reading[index],
      estabilidad = if (is.null(no2_stability)) {
        rep(NA_real_, length(index))
      } else {
        no2_stability[index]
      },
      eficiencia_convertidor = single_value(sheet, "Eficiencia del Convertidor")
    )
  }
  result
}

# El factor de escala se llama "Gain" en el formato de O3 y "Slope" en
# los demas; el numero de serie va en la misma fila.
analyzer_metadata <- function(sheet) {
  # Las etiquetas cambian entre formatos: "Gain inicial:",
  # "Slope inicial:", "SO2 GAIN inicial:", "Slope inicial NOX:". Se
  # busca por patron y se guarda la etiqueta hallada, porque en el
  # formato de NOx las dos filas son canales (NOX y NO), no
  # inicial/final.
  scale_label <- function(prefix) {
    pattern <- paste0("^(.*\\b)?(gain|slope)\\b.*\\b", prefix, "\\b")
    for (i in seq_len(nrow(sheet))) {
      cells <- trimws(as.character(unlist(sheet[i, ], use.names = FALSE)))
      hit <- which(grepl(pattern, tolower(cells)))
      if (length(hit) == 0L) next
      value <- suppressWarnings(as.numeric(cells[hit[[1L]] + 1L]))
      if (is.finite(value)) {
        return(list(valor = value, etiqueta = cells[hit[[1L]]], fila = i))
      }
    }
    list(valor = NA_real_, etiqueta = NA_character_, fila = NA_integer_)
  }
  initial <- scale_label("inicial")
  final <- scale_label("final")

  serie <- NA_character_
  if (is.finite(initial$fila)) {
    cells <- trimws(as.character(unlist(sheet[initial$fila, ], use.names = FALSE)))
    position <- which(cells == "Serie:")
    if (length(position) > 0L && position[[1L]] < length(cells)) {
      serie <- cells[[position[[1L]] + 1L]]
    }
  }

  fecha <- NA_character_
  anchor <- find_label_row(sheet, "Fecha de Calibración", exact = FALSE)
  if (!is.null(anchor)) {
    cells <- unlist(sheet[anchor$fila, ], use.names = FALSE)
    tail_cells <- cells[seq(anchor$columna + 1L, length(cells))]
    numeric_cells <- suppressWarnings(as.numeric(tail_cells))
    numeric_cells <- numeric_cells[is.finite(numeric_cells)]
    if (length(numeric_cells) > 0L) {
      # Numero de serie de fecha de Excel (base 1899-12-30).
      fecha <- format(
        as.Date(numeric_cells[[1L]], origin = "1899-12-30"), "%Y-%m-%d"
      )
    }
  }

  # Solo hay deriva medible si las dos etiquetas son inicial/final del
  # mismo canal; en el formato de NOx son canales distintos.
  same_channel <- !is.na(initial$etiqueta) && !is.na(final$etiqueta) &&
    identical(
      tolower(gsub("inicial", "", initial$etiqueta)),
      tolower(gsub("final", "", final$etiqueta))
    )

  data.frame(
    fecha = fecha,
    serie = serie,
    etiqueta_inicial = initial$etiqueta,
    etiqueta_final = final$etiqueta,
    par_comparable = same_channel,
    gain_inicial = initial$valor,
    gain_final = if (same_channel) final$valor else NA_real_,
    offset_inicial = single_value(sheet, "Offset inicial:"),
    offset_final = single_value(sheet, "Offset final:"),
    stringsAsFactors = FALSE
  )
}

gas_from_filename <- function(name) {
  lowered <- tolower(name)
  if (grepl("no2|e&t&h no", lowered) && grepl("f-psey-61", lowered)) "nox"
  else if (grepl("\\bco\\b|f-psey-47", lowered)) "co"
  else if (grepl("so2|f-psey-62", lowered)) "so2"
  else if (grepl("o3|f-psey-49", lowered)) "o3"
  else NA_character_
}

collect_calibrations <- function() {
  paths <- unlist(lapply(CALIBRATION_DIRS, function(directory) {
    list.files(directory, pattern = "\\.xlsm$", full.names = TRUE)
  }))
  # Hay copias del mismo formato en R_r/ y en la raiz; una sola vale.
  paths <- paths[!duplicated(basename(paths))]
  curves <- list()
  metadata <- list()
  for (path in paths) {
    sheets <- tryCatch(readxl::excel_sheets(path), error = function(e) character(0))
    if (!"FORMATO" %in% sheets) next
    sheet <- read_formato(path)
    gas <- gas_from_filename(basename(path))
    if (is.na(gas)) next

    extracted <- if (identical(gas, "nox")) {
      extract_nox(sheet, path)
    } else {
      piece <- extract_single_gas(sheet, path, gas)
      if (is.null(piece)) list() else list(piece)
    }
    if (length(extracted) == 0L) next

    info <- analyzer_metadata(sheet)
    metadata[[length(metadata) + 1L]] <- cbind(
      data.frame(archivo = basename(path), gas = gas, stringsAsFactors = FALSE),
      info
    )
    extracted <- lapply(extracted, function(curve) {
      curve$fecha <- info$fecha
      curve
    })
    curves <- c(curves, extracted)
  }
  list(curvas = curves, metadatos = do.call(rbind, metadata))
}

# -------------------------------------------------------------------
# GUM H.3: incertidumbre de la curva de calibracion
# -------------------------------------------------------------------

# Ajusta lectura = y1 + y2 * nominal y devuelve u(y1), u(y2) y su
# correlacion. Se centra en la media de los nominales, con lo que la
# covarianza se anula (uncer.md, "el truco para simplificar").
calibration_fit <- function(nominal, reading) {
  keep <- is.finite(nominal) & is.finite(reading)
  nominal <- nominal[keep]
  reading <- reading[keep]
  n <- length(nominal)
  if (n < 3L) {
    return(NULL)
  }
  center <- mean(nominal)
  centered <- nominal - center
  fit <- stats::lm(reading ~ centered)
  coefficients <- unname(stats::coef(fit))
  residual_sd <- sqrt(sum(stats::residuals(fit)^2) / (n - 2L))
  sxx <- sum(centered^2)

  list(
    n = n,
    centro = center,
    intercepto_centrado = coefficients[[1L]],
    pendiente = coefficients[[2L]],
    # Pendiente e intercepto en la escala original, para reporte.
    intercepto = coefficients[[1L]] - coefficients[[2L]] * center,
    s_residual = residual_sd,
    u_intercepto = residual_sd / sqrt(n),
    u_pendiente = residual_sd / sqrt(sxx),
    residuos = stats::residuals(fit),
    # uncer_cal.md seccion 3: r_max se expresa como fraccion del tope
    # de la curva de calibracion, no de la lectura de cada punto.
    fondo_escala = max(nominal),
    residuo_max = max(abs(stats::residuals(fit))),
    r_max = max(abs(stats::residuals(fit))) / max(nominal),
    r2 = summary(fit)$r.squared
  )
}

# u de la concentracion predicha por la curva en el nivel dado.
# Con el ajuste centrado la covarianza es cero, asi que:
#   u_c^2(x) = [ u(y1)^2 + (x - x0)^2 u(y2)^2 ] / pendiente^2
calibration_uncertainty <- function(fit, level) {
  sqrt(fit$u_intercepto^2 + (level - fit$centro)^2 * fit$u_pendiente^2) /
    abs(fit$pendiente)
}

# EN 14211/14212: el residuo maximo se trata como distribucion
# rectangular sobre el nivel de interes.
lack_of_fit_uncertainty <- function(fit, level) {
  fit$r_max * level / sqrt(3)
}

# uncer_cal.md seccion 3: se toma el mayor de los dos metodos, no su
# suma en cuadratura. Son dos estimaciones del mismo efecto (la
# desviacion de la recta), asi que sumarlas lo contaria dos veces.
# GUM manda en el cero y en niveles bajos, donde la falta de ajuste da
# un valor artificialmente nulo; la falta de ajuste manda en el tope.
curve_uncertainty <- function(fit, level) {
  gum <- calibration_uncertainty(fit, level)
  lof <- lack_of_fit_uncertainty(fit, level)
  list(
    u_gum = gum,
    u_lof = lof,
    u_curva = max(gum, lof),
    metodo = if (gum >= lof) "GUM_H.3" else "falta_ajuste_EN14211"
  )
}

# -------------------------------------------------------------------
# Tablas
# -------------------------------------------------------------------

curve_table <- function(curves) {
  parts <- lapply(curves, function(curve) {
    fit <- calibration_fit(curve$nominal, curve$lectura)
    if (is.null(fit)) {
      return(NULL)
    }
    data.frame(
      archivo = curve$archivo,
      fecha = curve$fecha,
      gas = curve$gas,
      n_puntos = fit$n,
      rango_min = min(curve$nominal),
      rango_max = max(curve$nominal),
      pendiente = fit$pendiente,
      u_pendiente = fit$u_pendiente,
      intercepto = fit$intercepto,
      # u del intercepto en la parametrizacion centrada (= s/sqrt(n)).
      u_intercepto_centrado = fit$u_intercepto,
      # u del valor ajustado en c = 0, que es la columna u(intercepto)
      # de uncer_cal.md seccion 4 (GUM H.13c, escala sin centrar).
      u_ajuste_en_cero = calibration_uncertainty(fit, 0) * abs(fit$pendiente),
      s_residual = fit$s_residual,
      residuo_max = fit$residuo_max,
      fondo_escala = fit$fondo_escala,
      r_max_pct = 100 * fit$r_max,
      r2 = fit$r2,
      estabilidad_media = mean(curve$estabilidad, na.rm = TRUE),
      estabilidad_max = suppressWarnings(max(curve$estabilidad, na.rm = TRUE)),
      eficiencia_convertidor = curve$eficiencia_convertidor,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$gas, result$archivo), ]
}

# Tabla de referencia de uncer_cal.md seccion 5: u de la curva en cada
# nivel nominal de la ronda, incluido el cero.
curve_level_table <- function(curves, repeatability = pt_u_rep_nivel) {
  nominals <- unique(repeatability[
    repeatability$fuente == "referencia_4U",
    c("analito", "unidad", "level", "nominal")
  ])
  parts <- list()
  for (curve in curves) {
    fit <- calibration_fit(curve$nominal, curve$lectura)
    if (is.null(fit)) next
    matching <- nominals[nominals$analito == curve$gas, , drop = FALSE]
    if (nrow(matching) == 0L) next
    # El nivel cero no aparece en la tabla de repetibilidad (se filtra
    # por nominal > 0) pero si debe quedar en la de curva.
    matching <- rbind(
      data.frame(
        analito = curve$gas, unidad = matching$unidad[[1L]],
        level = "1", nominal = 0, stringsAsFactors = FALSE
      ),
      matching
    )
    matching <- matching[!duplicated(matching$nominal), , drop = FALSE]

    for (i in seq_len(nrow(matching))) {
      level <- matching$nominal[[i]]
      components <- curve_uncertainty(fit, level)
      parts[[length(parts) + 1L]] <- data.frame(
        archivo = curve$archivo,
        fecha = curve$fecha,
        analito = curve$gas,
        unidad = matching$unidad[[i]],
        level = matching$level[[i]],
        nominal = level,
        u_gum = components$u_gum,
        u_lof = components$u_lof,
        u_curva = components$u_curva,
        metodo = components$metodo,
        u_curva_rel_pct = if (level > 0) 100 * components$u_curva / level else NA_real_,
        stringsAsFactors = FALSE
      )
    }
  }
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$analito, result$archivo, result$nominal), ]
}

# Presupuesto por nivel: repetibilidad (07) mas curva de calibracion.
# No incluye patron, cilindro certificado ni generador de aire cero,
# que son Tipo B y vienen de sus certificados (uncer_cal.md 8).
budget_table <- function(curve_levels, repeatability = pt_u_rep_nivel) {
  levels <- repeatability[repeatability$fuente == "referencia_4U", , drop = FALSE]
  parts <- list()
  for (i in seq_len(nrow(levels))) {
    row <- levels[i, ]
    matching <- curve_levels[
      curve_levels$analito == row$analito &
        abs(curve_levels$nominal - row$nominal) < 1e-9,
      , drop = FALSE
    ]
    if (nrow(matching) == 0L) next
    for (j in seq_len(nrow(matching))) {
      u_rep <- row$u_recomendada
      u_curve <- matching$u_curva[[j]]
      u_combined <- sqrt(u_rep^2 + u_curve^2)
      parts[[length(parts) + 1L]] <- data.frame(
        analito = row$analito,
        ronda = row$ronda,
        unidad = row$unidad,
        level = row$level,
        nominal = row$nominal,
        archivo_calibracion = matching$archivo[[j]],
        u_rep = u_rep,
        u_curva = u_curve,
        metodo_curva = matching$metodo[[j]],
        u_parcial = u_combined,
        U_parcial = CAL_K * u_combined,
        U_parcial_rel_pct = 100 * CAL_K * u_combined / row$nominal,
        aporte_rep_pct = 100 * u_rep^2 / u_combined^2,
        aporte_curva_pct = 100 * u_curve^2 / u_combined^2,
        nota = "parcial: falta patron, cilindro y generador de aire cero (Tipo B)",
        stringsAsFactors = FALSE
      )
    }
  }
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$analito, result$ronda, -result$nominal), ]
}

# Deriva entre calibraciones sucesivas del mismo analizador. El cambio
# de gain aplicado en una calibracion mide cuanto se habia ido el
# equipo desde la anterior.
drift_table <- function(metadata) {
  metadata <- metadata[is.finite(metadata$gain_inicial) &
                         is.finite(metadata$gain_final), , drop = FALSE]
  if (nrow(metadata) == 0L) {
    return(metadata)
  }
  metadata$cambio_gain_pct <- 100 *
    (metadata$gain_final - metadata$gain_inicial) / metadata$gain_inicial
  metadata$cambio_offset <- metadata$offset_final - metadata$offset_inicial
  # El ajuste encontrado se modela rectangular: el equipo pudo estar
  # en cualquier punto del intervalo desde la calibracion anterior.
  metadata$u_deriva_rel_pct <- abs(metadata$cambio_gain_pct) / sqrt(3)
  metadata[order(metadata$gas, metadata$fecha), ]
}

# -------------------------------------------------------------------
# Ejecucion
# -------------------------------------------------------------------

run_u_calibracion <- function() {
  collected <- collect_calibrations()
  if (length(collected$curvas) == 0L) {
    warning("No se extrajo ninguna curva de calibracion")
    return(invisible(NULL))
  }
  curves <- curve_table(collected$curvas)
  curve_levels <- curve_level_table(collected$curvas)
  budget <- budget_table(curve_levels)
  drift <- drift_table(collected$metadatos)

  table_dir <- file.path(OUTPUT_DIR, "tables")
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  writers <- list(
    u_cal_curvas = curves,
    u_curva_referencia_niveles = curve_levels,
    u_curva_por_nivel = budget,
    u_cal_deriva = drift
  )
  for (name in names(writers)) {
    utils::write.csv(
      writers[[name]],
      file.path(table_dir, paste0(name, ".csv")),
      row.names = FALSE, na = ""
    )
  }

  assign("pt_u_cal_curvas", curves, envir = .GlobalEnv)
  assign("pt_u_curva_niveles", curve_levels, envir = .GlobalEnv)
  assign("pt_u_curva_por_nivel", budget, envir = .GlobalEnv)
  assign("pt_u_cal_deriva", drift, envir = .GlobalEnv)
  invisible(writers)
}

run_u_calibracion()
