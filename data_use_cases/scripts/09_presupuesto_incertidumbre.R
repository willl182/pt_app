# ===================================================================
# Presupuesto de incertidumbre por analito y nivel
#
# Reune los componentes calculados en los scripts anteriores y los
# combina en cuadratura segun uncer.md paso 4:
#
#   u_rep        repetibilidad Tipo A corregida por autocorrelacion
#                (07_u_repetibilidad.R)
#   u_curva      curva de calibracion del analizador, max(GUM H.3,
#                falta de ajuste EN 14211) (08_u_calibracion.R)
#   u_patron     patron que genera la concentracion:
#                  - O3: certificado del calibrador dinamico
#                    F-PSMT-01 sn 554, U(X) = 0.0051*X + 0.67 nmol/mol
#                    con k = 2, intervalo 0-500 nmol/mol
#                  - demas gases: cilindro certificado, U absoluta de
#                    1 umol/mol sobre su concentracion nominal,
#                    propagada como componente relativo a la dilucion
#   u_aire_cero  impureza residual del generador de aire cero, del
#                error medido en F-PSEY-51 frente al cilindro de
#                referencia PRAXAIR, tratado como rectangular
#   u_conv       eficiencia del convertidor, solo NO2
#
# NO incluye la incertidumbre de los controladores de flujo de
# dilucion: no hay certificado de esos canales en la carpeta. Para
# O3 no aplica porque el certificado del calibrador ya cubre la
# concentracion generada de punta a punta.
# ===================================================================

if (!exists("pt_u_curva_niveles", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "08_u_calibracion.R"))) {
    file.path("scripts", "08_u_calibracion.R")
  } else {
    file.path("data_use_cases", "scripts", "08_u_calibracion.R")
  }
  source(script_path)
}

BUDGET_K <- 2

# --- Certificado del calibrador dinamico (solo O3) ------------------
# F-PSMT-01 sn 554, hoja Uexp: ecuacion del informe, U expandida.
O3_STANDARD_SLOPE <- 0.0051
O3_STANDARD_INTERCEPT <- 0.67
O3_STANDARD_K <- 2
O3_STANDARD_MAX <- 500

# --- Patron de gas (cilindro certificado) ----------------------------
# Incertidumbre EXPANDIDA del certificado, absoluta, en la unidad del
# gas: 1 umol/mol para CO, 1 nmol/mol para los gases en ppb. Se aplica
# sobre la concentracion entregada, asi que es un componente FIJO: no
# cambia con el nivel.
#
# CO va en 0.1 umol/mol, no 1: con 1 el patron solo valdria el 16 %
# del nivel mas alto y aplastaria todo lo demas. 0.1 deja a CO en
# ~1.9 % del nivel alto, en linea con los demas gases (0.8-2.6 %).
CYLINDER_EXPANDED_U <- c(
  co = 0.1,    # umol/mol
  so2 = 1,     # nmol/mol
  no = 1,      # nmol/mol
  no2 = 1,     # nmol/mol
  nox = 1      # nmol/mol
)
CYLINDER_K <- 2
# "absoluto": U del certificado aplica al nivel entregado (fijo).
# "relativo": U del certificado aplica a la concentracion del cilindro
#             y la dilucion conserva la fraccion (proporcional al
#             nivel). Requiere CYLINDER_CONCENTRATION.
CYLINDER_MODE <- "absoluto"
# Concentracion certificada del cilindro, en la unidad del gas. Solo
# el formato de NOx la registra ("Concentr. NO:" = 711 ppm).
CYLINDER_CONCENTRATION <- c(
  co = NA_real_, so2 = NA_real_, no = 711, no2 = 711, nox = 711
)

# --- Eficiencia del convertidor (NO2) -------------------------------
# La desviacion respecto al 100 % se trata como rectangular.
CONVERTER_EFFICIENCY_PCT <- 98.136170959065

# -------------------------------------------------------------------
# Componentes
# -------------------------------------------------------------------

standard_uncertainty <- function(analyte, level) {
  if (identical(analyte, "o3")) {
    if (level > O3_STANDARD_MAX) {
      return(NA_real_)
    }
    expanded <- O3_STANDARD_SLOPE * level + O3_STANDARD_INTERCEPT
    return(expanded / O3_STANDARD_K)
  }
  expanded <- CYLINDER_EXPANDED_U[[analyte]]
  if (is.null(expanded) || !is.finite(expanded)) {
    return(NA_real_)
  }
  if (identical(CYLINDER_MODE, "absoluto")) {
    return(expanded / CYLINDER_K)
  }
  concentration <- CYLINDER_CONCENTRATION[[analyte]]
  if (!is.finite(concentration)) {
    return(NA_real_)
  }
  # La dilucion conserva la incertidumbre relativa del cilindro.
  (expanded / CYLINDER_K) / concentration * level
}

# F-PSEY-51: error del generador de aire cero de estacion frente al
# cilindro de aire de referencia. Es un sesgo no corregido, asi que
# entra como rectangular sobre su propio valor.
read_zero_air_errors <- function() {
  path <- file.path(ANALYSIS_ROOT, "F-PSEY-51 Verificacion Generador Aire Cero.xlsm")
  if (!file.exists(path)) {
    warning("Falta el formato F-PSEY-51; u_aire_cero queda en NA")
    return(NULL)
  }
  sheet <- read_formato(path)
  anchor <- find_label_row(sheet, "5. CRITERIO DE ACEPTACIÓN:", exact = FALSE)
  if (is.null(anchor)) {
    return(NULL)
  }
  errors <- list()
  for (i in seq(anchor$fila, min(anchor$fila + 12L, nrow(sheet)))) {
    cells <- trimws(as.character(unlist(sheet[i, ], use.names = FALSE)))
    analyte <- tolower(cells[[anchor$columna]])
    if (!analyte %in% c("so2", "no", "no2", "co", "o3")) next
    numbers <- suppressWarnings(as.numeric(cells))
    numbers <- numbers[is.finite(numbers)]
    if (length(numbers) < 3L) next
    # Columnas: referencia, bajo prueba, error.
    errors[[analyte]] <- numbers[[3L]]
  }
  errors
}

zero_air_uncertainty <- function(errors, analyte) {
  if (is.null(errors) || is.null(errors[[analyte]])) {
    return(NA_real_)
  }
  abs(errors[[analyte]]) / sqrt(3)
}

converter_uncertainty <- function(analyte, level) {
  if (!identical(analyte, "no2")) {
    return(0)
  }
  (100 - CONVERTER_EFFICIENCY_PCT) / 100 * level / sqrt(3)
}

# -------------------------------------------------------------------
# Ensamblaje
# -------------------------------------------------------------------

# Fecha de inicio de cada ronda, para elegir la calibracion vigente.
round_start_dates <- function(qc = pt_qc) {
  stamps <- as.POSIXct(qc$ts, tz = "America/Bogota")
  vapply(
    split(stamps, qc$ronda),
    function(x) format(min(x, na.rm = TRUE), "%Y-%m-%d"),
    character(1)
  )
}

# Se usa la calibracion vigente: la mas reciente en o antes del inicio
# de la ronda. Si no hay ninguna previa (la del formato es posterior),
# se toma la mas cercana y se deja constancia en la salida.
select_curve <- function(curve_levels, analyte, level, round_date) {
  matching <- curve_levels[
    curve_levels$analito == analyte &
      abs(curve_levels$nominal - level) < 1e-9,
    , drop = FALSE
  ]
  if (nrow(matching) == 0L) {
    return(NULL)
  }
  dates <- as.Date(matching$fecha)
  reference <- as.Date(round_date)
  previous <- which(is.finite(as.numeric(dates)) & dates <= reference)
  if (length(previous) > 0L) {
    chosen <- previous[which.max(dates[previous])]
    matching <- matching[chosen, , drop = FALSE]
    matching$calibracion_vigente <- TRUE
  } else {
    chosen <- which.min(abs(as.numeric(dates - reference)))
    matching <- matching[chosen, , drop = FALSE]
    matching$calibracion_vigente <- FALSE
  }
  matching
}

build_budget <- function(repeatability = pt_u_rep_nivel,
                         curve_levels = pt_u_curva_niveles) {
  zero_air <- read_zero_air_errors()
  round_dates <- round_start_dates()
  levels <- repeatability[repeatability$fuente == "referencia_4U", , drop = FALSE]
  parts <- list()

  for (i in seq_len(nrow(levels))) {
    row <- levels[i, ]
    round_date <- round_dates[[row$ronda]]
    curve <- select_curve(curve_levels, row$analito, row$nominal, round_date)

    components <- c(
      u_rep = row$u_recomendada,
      u_curva = if (is.null(curve)) NA_real_ else curve$u_curva,
      u_patron = standard_uncertainty(row$analito, row$nominal),
      u_aire_cero = zero_air_uncertainty(zero_air, row$analito),
      u_conv = converter_uncertainty(row$analito, row$nominal)
    )
    present <- components[is.finite(components)]
    combined <- sqrt(sum(present^2))
    missing <- names(components)[!is.finite(components)]

    contribution <- 100 * components^2 / combined^2
    parts[[length(parts) + 1L]] <- data.frame(
      analito = row$analito,
      ronda = row$ronda,
      unidad = row$unidad,
      level = row$level,
      nominal = row$nominal,
      fecha_ronda = round_date,
      archivo_calibracion = if (is.null(curve)) NA_character_ else curve$archivo,
      fecha_calibracion = if (is.null(curve)) NA_character_ else curve$fecha,
      calibracion_vigente = if (is.null(curve)) NA else curve$calibracion_vigente,
      u_rep = components[["u_rep"]],
      u_curva = components[["u_curva"]],
      u_patron = components[["u_patron"]],
      u_aire_cero = components[["u_aire_cero"]],
      u_conv = components[["u_conv"]],
      u_c = combined,
      U = BUDGET_K * combined,
      U_rel_pct = if (abs(row$nominal) < 1e-9) NA_real_ else 100 * BUDGET_K * combined / row$nominal,
      aporte_rep_pct = contribution[["u_rep"]],
      aporte_curva_pct = contribution[["u_curva"]],
      aporte_patron_pct = contribution[["u_patron"]],
      aporte_aire_cero_pct = contribution[["u_aire_cero"]],
      aporte_conv_pct = contribution[["u_conv"]],
      desfase_generador = isTRUE(row$desfase_generador),
      componentes_faltantes = paste(missing, collapse = "|"),
      stringsAsFactors = FALSE
    )
  }
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$analito, result$ronda, -result$nominal), ]
}

# Resumen legible: un presupuesto por analito en su nivel mas alto,
# que es donde se declara el alcance.
budget_summary <- function(budget) {
  parts <- lapply(split(budget, budget$analito), function(block) {
    top <- block[which.max(block$nominal), , drop = FALSE]
    data.frame(
      analito = top$analito,
      unidad = top$unidad,
      nivel_declarado = top$nominal,
      u_rep = top$u_rep,
      u_curva = top$u_curva,
      u_patron = top$u_patron,
      u_aire_cero = top$u_aire_cero,
      u_conv = top$u_conv,
      u_c = top$u_c,
      U_k2 = top$U,
      U_rel_pct = top$U_rel_pct,
      dominante = c("u_rep", "u_curva", "u_patron", "u_aire_cero", "u_conv")[
        which.max(c(
          top$aporte_rep_pct, top$aporte_curva_pct, top$aporte_patron_pct,
          top$aporte_aire_cero_pct, top$aporte_conv_pct
        ))
      ],
      componentes_faltantes = top$componentes_faltantes,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$analito), ]
}

# Clave de union con data/processed/: el nivel alli es una cadena
# "<nominal>-<unidad>" y la unidad va en micro/nano mol por mol.
processed_level_key <- function(nominal, unidad) {
  unit_label <- ifelse(unidad == "ppm", "\u00b5mol/mol", "nmol/mol")
  # format() sobre el vector completo alinea decimales y produciria
  # "180.0"; cada valor se formatea por separado.
  texto <- vapply(nominal, function(value) {
    formatted <- format(value, trim = TRUE, scientific = FALSE, drop0trailing = TRUE)
    sub("\\.0+$", "", formatted)
  }, character(1))
  paste0(texto, "-", unit_label)
}

ROUND_FILE <- c(
  R1 = "ronda_1_r.csv", R2A = "ronda_2a_r.csv", R2B = "ronda_2b_r.csv",
  R2C = "ronda_2c_r.csv", R3 = "ronda_3_r.csv"
)

# Tabla de union: una fila por (archivo procesado, pollutant, level).
lookup_table <- function(budget) {
  data.frame(
    archivo_procesado = unname(ROUND_FILE[budget$ronda]),
    pollutant = budget$analito,
    level = processed_level_key(budget$nominal, budget$unidad),
    unit = ifelse(budget$unidad == "ppm", "\u00b5mol/mol", "nmol/mol"),
    nominal = budget$nominal,
    u_rep = budget$u_rep,
    u_curva = budget$u_curva,
    u_patron = budget$u_patron,
    u_aire_cero = budget$u_aire_cero,
    u_conv = budget$u_conv,
    u_c = budget$u_c,
    k_factor = BUDGET_K,
    u_exp = budget$U,
    desfase_generador = budget$desfase_generador,
    stringsAsFactors = FALSE
  )
}

run_presupuesto <- function() {
  budget <- build_budget()
  summary <- budget_summary(budget)
  lookup <- lookup_table(budget)

  table_dir <- file.path(OUTPUT_DIR, "tables")
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  writers <- list(
    presupuesto_incertidumbre = budget,
    presupuesto_resumen = summary,
    u_referencia_aplicable = lookup
  )
  for (name in names(writers)) {
    utils::write.csv(
      writers[[name]],
      file.path(table_dir, paste0(name, ".csv")),
      row.names = FALSE, na = ""
    )
  }

  assign("pt_presupuesto", budget, envir = .GlobalEnv)
  assign("pt_presupuesto_resumen", summary, envir = .GlobalEnv)
  assign("pt_u_aplicable", lookup, envir = .GlobalEnv)
  invisible(writers)
}

run_presupuesto()
