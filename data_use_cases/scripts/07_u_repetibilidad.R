# ===================================================================
# Contribucion de la repetibilidad a la incertidumbre (GUM Tipo A)
#
# uncer.md define u(x) = s / sqrt(3) sobre las n=3 medias horarias
# reportadas. Ese es el estimador correcto para el valor que se
# reporta, pero se apoya en 2 grados de libertad. Las corridas de R_r
# y los crudos de R1/R2/R3 tienen resolucion de 1 min, asi que aqui se
# descompone la varianza en dos escalas:
#
#   s_w  = dispersion minuto a minuto dentro de un bloque (ruido del
#          analizador),
#   s_b  = dispersion entre medias de bloque (deriva de corto plazo
#          del generador + del analizador).
#
# Punto critico: los datos de 1 min estan autocorrelacionados, asi que
# u = s_w / sqrt(n_min) subestima la incertidumbre. El pipeline actual
# (R/preprocessing/hourly_averages.R) calcula justamente ese u_value
# por hora. Aqui se corrige con el tamano efectivo de muestra bajo
# AR(1) y se contrasta contra el estimador del protocolo.
#
# Salidas en outputs/tables/:
#   u_rep_bloques.csv     medias de bloque usadas
#   u_rep_por_nivel.csv   componentes por analito/ronda/nivel
#   u_rep_resumen.csv     valor recomendado por analito para el
#                         presupuesto, con su transferibilidad UNAL/4U
# ===================================================================

if (!exists("pt_rr_mesetas", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "06_rr_unal.R"))) {
    file.path("scripts", "06_rr_unal.R")
  } else {
    file.path("data_use_cases", "scripts", "06_rr_unal.R")
  }
  source(script_path)
}

# Bloque de la referencia: hora de reloj, igual que el pipeline
# (>= 45 min validos = 75 %).
REF_BLOCK_MIN <- 60L
REF_BLOCK_MIN_VALID <- 45L
# Bloque de R_r: las mesetas duran 25-50 min, no cabe una hora.
RR_BLOCK_MIN <- 20L
RR_BLOCK_MIN_VALID <- 15L
# Bloque comun a las dos fuentes, solo para comparar s_w entre
# analistas sin el sesgo de la duracion del bloque.
COMPARABLE_BLOCK_MIN <- 20L
COMPARABLE_BLOCK_MIN_VALID <- 15L
# n del protocolo declarado en uncer.md.
PROTOCOL_N <- 3L

# -------------------------------------------------------------------
# Descomposicion de varianza de una serie de minutos
# -------------------------------------------------------------------

# Autocorrelacion de retardo 1 de los residuos respecto a la media del
# bloque. Se agrega entre bloques ponderando por grados de libertad.
lag1_autocorrelation <- function(blocks) {
  numerator <- 0
  denominator <- 0
  for (values in blocks) {
    values <- values[is.finite(values)]
    if (length(values) < 3L) next
    residual <- values - mean(values)
    numerator <- numerator +
      sum(residual[-length(residual)] * residual[-1L])
    denominator <- denominator + sum(residual^2)
  }
  if (denominator <= 0) {
    return(NA_real_)
  }
  max(min(numerator / denominator, 0.99), 0)
}

effective_size <- function(n, rho) {
  if (!is.finite(rho) || rho <= 0) {
    return(n)
  }
  max(n * (1 - rho) / (1 + rho), 1)
}

# Devuelve los componentes de repetibilidad de un nivel a partir de la
# lista de bloques (cada uno un vector de lecturas de 1 min).
decompose_level <- function(blocks) {
  blocks <- Filter(function(values) sum(is.finite(values)) >= 2L, blocks)
  if (length(blocks) == 0L) {
    return(NULL)
  }
  sizes <- vapply(blocks, function(values) sum(is.finite(values)), integer(1))
  sds <- vapply(blocks, function(values) stats::sd(values, na.rm = TRUE), numeric(1))
  means <- vapply(blocks, function(values) mean(values, na.rm = TRUE), numeric(1))

  df <- sizes - 1L
  s_within <- sqrt(sum(df * sds^2) / sum(df))
  n_total <- sum(sizes)
  rho <- lag1_autocorrelation(blocks)
  n_eff <- effective_size(n_total, rho)

  n_blocks <- length(blocks)
  s_between <- if (n_blocks >= 2L) stats::sd(means) else NA_real_

  list(
    n_bloques = n_blocks,
    n_min = n_total,
    media = mean(means),
    s_w = s_within,
    rho1 = rho,
    n_eff = n_eff,
    s_b = s_between,
    medias_bloque = means
  )
}

# -------------------------------------------------------------------
# Extraccion de bloques
# -------------------------------------------------------------------

reference_blocks <- function(qc = pt_qc) {
  selected <- qc[
    qc$es_analito & qc$rol == "ref" &
      qc$level %in% as.character(1:5) &
      is.finite(qc$valor) & is.finite(qc$nominal) &
      !qc$flag_na & !qc$flag_outlier,
    , drop = FALSE
  ]
  stamps <- as.POSIXct(selected$ts, tz = "America/Bogota")
  selected$bloque <- format(stamps, "%Y-%m-%d %H")
  key <- interaction(
    selected$ronda, selected$analito, selected$level, drop = TRUE
  )
  selected$ts_num <- as.numeric(stamps)
  lapply(split(selected, key), function(block) {
    pieces <- split(block$valor, block$bloque)
    pieces <- pieces[lengths(pieces) >= REF_BLOCK_MIN_VALID]
    # Un nivel de una sola hora que arranca a mitad de hora de reloj
    # (p. ej. 12:33) reparte sus 60 min entre dos horas y ninguna
    # alcanza el 75 %. En ese caso se bloquea por hora corrida desde
    # el inicio del nivel en vez de por hora de reloj.
    if (length(pieces) == 0L) {
      pieces <- split_fixed_blocks(
        block$ts_num, block$valor,
        block_min = REF_BLOCK_MIN, min_valid = REF_BLOCK_MIN_VALID
      )
    }
    # El protocolo conserva hasta 3 horas por nivel.
    pieces <- pieces[seq_len(min(length(pieces), PROTOCOL_N))]
    list(
      fuente = "referencia_4U",
      analito = block$analito[[1L]],
      ronda = block$ronda[[1L]],
      unidad = block$unidad[[1L]],
      serial = block$serial[[1L]],
      level = block$level[[1L]],
      nominal = stats::median(block$nominal, na.rm = TRUE),
      # El generador no entrego el nominal declarado en este nivel;
      # la dispersion sigue siendo valida, pero el nominal no.
      desfase_generador = any(block$flag_gen_mismatch),
      bloque_min = REF_BLOCK_MIN,
      bloques = pieces,
      bloques_comp = split_fixed_blocks(block$ts_num, block$valor)
    )
  })
}

# Bloques de duracion fija medida desde el inicio del nivel. Se usa la
# misma duracion en ambas fuentes para que s_w sea comparable: un
# bloque mas largo captura mas deriva y eleva s_w por construccion.
split_fixed_blocks <- function(ts_num, values,
                               block_min = COMPARABLE_BLOCK_MIN,
                               min_valid = COMPARABLE_BLOCK_MIN_VALID) {
  offset <- (ts_num - min(ts_num)) / 60
  pieces <- split(values, floor(offset / block_min))
  pieces[lengths(pieces) >= min_valid]
}

unal_blocks <- function(plateaus = pt_rr_mesetas) {
  raw_cache <- list()
  result <- list()
  for (i in seq_len(nrow(plateaus))) {
    row <- plateaus[i, ]
    if (is.null(raw_cache[[row$archivo]])) {
      raw_cache[[row$archivo]] <- read_rr_file(file.path(RR_DIR, row$archivo))
    }
    raw <- raw_cache[[row$archivo]]
    window <- raw$ts >= row$inicio & raw$ts <= row$fin
    values <- strip_status_suffix(raw[[row$canal]])[window]
    stamps <- raw$ts[window]

    offset <- as.numeric(difftime(stamps, min(stamps), units = "mins"))
    pieces <- split(values, floor(offset / RR_BLOCK_MIN))
    pieces <- pieces[lengths(pieces) >= RR_BLOCK_MIN_VALID]
    if (length(pieces) == 0L) next

    result[[length(result) + 1L]] <- list(
      fuente = "unal_R_r",
      analito = row$analito,
      ronda = row$corrida,
      unidad = row$unidad,
      serial = "UNAL",
      level = as.character(row$orden),
      nominal = row$media,
      bloque_min = RR_BLOCK_MIN,
      bloques = pieces,
      bloques_comp = split_fixed_blocks(as.numeric(stamps), values)
    )
  }
  result
}

# -------------------------------------------------------------------
# Tabla por nivel
# -------------------------------------------------------------------

# En el nivel cero la media ronda 0 y cualquier cociente relativo se
# dispara; se deja NA en lugar de un porcentaje sin sentido.
safe_relative <- function(value, reference) {
  if (!is.finite(reference) || abs(reference) < 1e-9) {
    return(NA_real_)
  }
  100 * value / reference
}

level_table <- function(entries) {
  parts <- list()
  block_parts <- list()
  for (entry in entries) {
    components <- decompose_level(entry$bloques)
    if (is.null(components)) next
    comparable <- decompose_level(entry$bloques_comp)

    # Estimador del protocolo (uncer.md paso 3): s de las medias de
    # bloque dividido por la raiz del numero de bloques.
    u_protocolo <- components$s_b / sqrt(components$n_bloques)
    # Lo que hoy produce el pipeline por hora: s_w / sqrt(n_min).
    u_ingenua <- components$s_w / sqrt(components$n_min)
    # Corregida por autocorrelacion AR(1).
    u_efectiva <- components$s_w / sqrt(components$n_eff)
    # Conservador: la repetibilidad no puede ser menor que el ruido
    # efectivo ni ignorar la deriva entre bloques.
    u_recomendada <- max(c(u_protocolo, u_efectiva), na.rm = TRUE)

    parts[[length(parts) + 1L]] <- data.frame(
      fuente = entry$fuente,
      analito = entry$analito,
      ronda = entry$ronda,
      unidad = entry$unidad,
      serial = entry$serial,
      level = entry$level,
      nominal = entry$nominal,
      desfase_generador = isTRUE(entry$desfase_generador),
      bloque_min = entry$bloque_min,
      n_bloques = components$n_bloques,
      n_min = components$n_min,
      media = components$media,
      s_w = components$s_w,
      cv_w_pct = safe_relative(components$s_w, components$media),
      bloque_comp_min = COMPARABLE_BLOCK_MIN,
      n_bloques_comp = if (is.null(comparable)) NA_integer_ else comparable$n_bloques,
      s_w_comp = if (is.null(comparable)) NA_real_ else comparable$s_w,
      rho1 = components$rho1,
      n_eff = components$n_eff,
      s_b = components$s_b,
      u_protocolo = u_protocolo,
      u_ingenua = u_ingenua,
      u_efectiva = u_efectiva,
      u_recomendada = u_recomendada,
      u_recomendada_rel_pct = safe_relative(u_recomendada, entry$nominal),
      factor_subestimacion = u_recomendada / u_ingenua,
      stringsAsFactors = FALSE
    )
    block_parts[[length(block_parts) + 1L]] <- data.frame(
      fuente = entry$fuente,
      analito = entry$analito,
      ronda = entry$ronda,
      level = entry$level,
      bloque = seq_along(components$medias_bloque),
      media_bloque = components$medias_bloque,
      stringsAsFactors = FALSE
    )
  }
  list(
    niveles = do.call(rbind, parts),
    bloques = do.call(rbind, block_parts)
  )
}

# -------------------------------------------------------------------
# Resumen por analito para el presupuesto
# -------------------------------------------------------------------

# u_rep se modela como componente relativo (proporcional al nivel),
# que es como se comporta el ruido de estos analizadores fuera del
# cero. Se reporta tambien el valor absoluto por si se prefiere fijo.
budget_summary <- function(levels) {
  parts <- lapply(split(levels, levels$analito), function(block) {
    unal <- block[block$fuente == "unal_R_r", , drop = FALSE]
    reference <- block[block$fuente == "referencia_4U", , drop = FALSE]

    # Comparacion en bloques de igual duracion: mismo instrumento, asi
    # que una diferencia real solo puede venir del analista o de la
    # fecha, no del equipo.
    pooled <- function(subset) {
      keep <- is.finite(subset$s_w_comp) & is.finite(subset$n_bloques_comp)
      subset <- subset[keep, , drop = FALSE]
      df <- subset$n_min - subset$n_bloques_comp
      if (nrow(subset) == 0L || sum(df) <= 0) {
        return(NA_real_)
      }
      sqrt(sum(df * subset$s_w_comp^2) / sum(df))
    }
    s_w_unal <- pooled(unal)
    s_w_ref <- pooled(reference)

    data.frame(
      analito = block$analito[[1L]],
      unidad = block$unidad[[1L]],
      niveles_unal = nrow(unal),
      niveles_ref = nrow(reference),
      s_w_unal = s_w_unal,
      s_w_ref = s_w_ref,
      razon_s_w = s_w_unal / s_w_ref,
      # Componente para el presupuesto, tomado del lado con mayor
      # dispersion (criterio conservador).
      u_rep_rel_pct = suppressWarnings(max(block$u_recomendada_rel_pct, na.rm = TRUE)),
      u_rep_rel_pct_mediana = stats::median(
        block$u_recomendada_rel_pct, na.rm = TRUE
      ),
      u_rep_abs_max = max(block$u_recomendada, na.rm = TRUE),
      factor_subestimacion_max = max(block$factor_subestimacion, na.rm = TRUE),
      gl_unal = sum(unal$n_min - unal$n_bloques),
      gl_ref = sum(reference$n_min - reference$n_bloques),
      nota = if (isTRUE(s_w_unal / s_w_ref <= 1.5)) {
        "s_w equivalente entre analistas (mismo equipo)"
      } else {
        "s_w difiere entre analistas pese al mismo equipo: revisar montaje"
      },
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$analito), ]
}

# -------------------------------------------------------------------
# Ejecucion
# -------------------------------------------------------------------

run_u_repetibilidad <- function() {
  entries <- c(reference_blocks(), unal_blocks())
  tables <- level_table(entries)
  levels <- tables$niveles
  levels <- levels[order(levels$analito, levels$fuente, -levels$nominal), ]
  rownames(levels) <- NULL
  summary <- budget_summary(levels)

  table_dir <- file.path(OUTPUT_DIR, "tables")
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  writers <- list(
    u_rep_bloques = tables$bloques,
    u_rep_por_nivel = levels,
    u_rep_resumen = summary
  )
  for (name in names(writers)) {
    utils::write.csv(
      writers[[name]],
      file.path(table_dir, paste0(name, ".csv")),
      row.names = FALSE, na = ""
    )
  }

  assign("pt_u_rep_nivel", levels, envir = .GlobalEnv)
  assign("pt_u_rep_resumen", summary, envir = .GlobalEnv)
  invisible(writers)
}

run_u_repetibilidad()
