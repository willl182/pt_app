# ===================================================================
# R&R: analizador UNAL (otro analista) vs referencia 4U de R1/R2/R3
#
# Los archivos de data_use_cases/R_r/ solo traen el canal del
# analizador UNAL: no hay columna de generador ni serie de referencia
# simultanea. Por eso este script:
#
#   1. Detecta las mesetas de cada corrida UNAL (segmentacion por
#      salto + descarte del transitorio inicial).
#   2. Las parea contra los niveles 1..5 de cada ronda de referencia,
#      primero por valor nominal y, si el nominal no coincide, por
#      orden descendente de concentracion.
#   3. Calcula repetibilidad (s_r, r) de ambos lados, sesgo y E_n de
#      los pares con nominal equivalente, reproducibilidad entre
#      "laboratorios" (UNAL vs 4U) y regresion de Deming.
#
# Limitaciones que quedan registradas en las salidas:
#   - sin valor asignado propio en R_r (columna nominal ausente),
#   - mesetas de 40-60 min => una sola media horaria por nivel,
#   - un solo operador y una sola corrida por gas => s_L con 1 gl.
# ===================================================================

if (!exists("pt_qc", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "02_qc.R"))) {
    file.path("scripts", "02_qc.R")
  } else {
    file.path("data_use_cases", "scripts", "02_qc.R")
  }
  source(script_path)
}

RR_DIR <- file.path(ANALYSIS_ROOT, "R_r")

# Transitorio descartado al inicio de cada meseta (min).
RR_SETTLING_MIN <- 10L
# Minimo de puntos estables para aceptar una meseta.
RR_MIN_POINTS <- 20L
# Tolerancia de pareo por nominal.
RR_ABS_TOL <- 3
RR_REL_TOL <- 0.05
# Factor de cobertura.
RR_K <- 2

rr_file_metadata <- data.frame(
  file = c(
    "Datos R&R Jaison CO y SO2 JUL 2.txt",
    "Datos R&R Jaison O3 JUN.txt",
    "Datos R&R Jaison NO JUL 7.txt",
    "Datos R&R Jaison NO2 JUL 7.txt"
  ),
  corrida = c("RR_CO_SO2", "RR_O3", "RR_NO", "RR_NO2"),
  stringsAsFactors = FALSE
)

# Canal UNAL que interesa por corrida; el resto se ignora.
#
# El archivo de NO contiene dos fases: la generacion de NO (NO ~ NOx)
# y la titulacion posterior para NO2 (NOx constante ~186 ppb y NO como
# residual). Solo la primera es un nivel generado de NO, asi que se
# exige coherencia con NOx. Para NO2 la condicion es la inversa: NO2
# es el analito generado por titulacion y NO no puede confundirse con
# el.
rr_channels <- data.frame(
  corrida = c("RR_CO_SO2", "RR_CO_SO2", "RR_O3", "RR_NO", "RR_NO2"),
  columna = c("CO_UNAL", "SO2_UNAL", "O3_UNAL", "NO_UNAL", "NO2_UNAL"),
  analito = c("co", "so2", "o3", "no", "no2"),
  companero = c(NA, NA, NA, "NOx_UNAL", "NOx_UNAL"),
  # Fraccion maxima/minima admitida de canal / companero en la meseta.
  companero_min = c(NA, NA, NA, 0.95, 0.05),
  companero_max = c(NA, NA, NA, 1.05, 0.95),
  stringsAsFactors = FALSE
)

# -------------------------------------------------------------------
# Lectura
# -------------------------------------------------------------------

strip_status_suffix <- function(x) {
  cleaned <- gsub("[^0-9eE.+-]", "", trimws(as.character(x)))
  cleaned[!grepl("[0-9]", cleaned)] <- NA_character_
  suppressWarnings(as.numeric(cleaned))
}

read_rr_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  header <- strsplit(lines[[1L]], ",", fixed = TRUE)[[1L]]
  units <- strsplit(lines[[2L]], ",", fixed = TRUE)[[1L]]
  body <- utils::read.csv(
    text = paste(lines[-c(1L, 2L)], collapse = "\n"),
    header = FALSE, colClasses = "character",
    stringsAsFactors = FALSE
  )
  names(body) <- trimws(header)[seq_len(ncol(body))]

  stamp_column <- names(body)[[1L]]
  ts <- as.POSIXct(
    body[[stamp_column]], format = "%m/%d/%y %H:%M", tz = "America/Bogota"
  )
  body <- body[!is.na(ts), , drop = FALSE]
  body$ts <- ts[!is.na(ts)]
  attr(body, "unidades") <- stats::setNames(
    trimws(units)[seq_len(length(header))], trimws(header)
  )
  body
}

# -------------------------------------------------------------------
# Segmentacion de mesetas
# -------------------------------------------------------------------

# Corta la serie donde el salto entre minutos consecutivos supera la
# tolerancia, y descarta los tramos que no son mesetas de generacion
# (pocos puntos o dispersion tipica de aire ambiente).
segment_plateaus <- function(ts, value, settling = RR_SETTLING_MIN,
                             min_points = RR_MIN_POINTS) {
  keep <- is.finite(value)
  ts <- ts[keep]
  value <- value[keep]
  if (length(value) < min_points) {
    return(NULL)
  }

  span <- diff(range(value, na.rm = TRUE))
  step_tolerance <- max(0.02 * span, 3 * stats::mad(diff(value)), 1e-9)

  breaks <- which(abs(diff(value)) > step_tolerance)
  starts <- c(1L, breaks + 1L)
  ends <- c(breaks, length(value))

  segments <- list()
  for (i in seq_along(starts)) {
    index <- starts[[i]]:ends[[i]]
    if (length(index) < min_points + settling) next
    index <- index[-seq_len(settling)]
    segment_value <- value[index]
    center <- mean(segment_value)
    dispersion <- stats::sd(segment_value)
    # Una meseta de generador es plana; el aire ambiente no lo es.
    if (dispersion > 0.02 * abs(center)) next
    segments[[length(segments) + 1L]] <- data.frame(
      inicio = min(ts[index]),
      fin = max(ts[index]),
      n = length(index),
      media = center,
      sd = dispersion,
      stringsAsFactors = FALSE
    )
  }
  if (length(segments) == 0L) {
    return(NULL)
  }
  do.call(rbind, segments)
}

collect_rr_plateaus <- function() {
  parts <- list()
  for (i in seq_len(nrow(rr_file_metadata))) {
    path <- file.path(RR_DIR, rr_file_metadata$file[[i]])
    if (!file.exists(path)) {
      warning("Archivo R_r ausente: ", rr_file_metadata$file[[i]])
      next
    }
    raw <- read_rr_file(path)
    unidades <- attr(raw, "unidades")
    channels <- rr_channels[
      rr_channels$corrida == rr_file_metadata$corrida[[i]], , drop = FALSE
    ]
    for (j in seq_len(nrow(channels))) {
      column <- channels$columna[[j]]
      if (!column %in% names(raw)) next
      plateaus <- segment_plateaus(raw$ts, strip_status_suffix(raw[[column]]))
      if (is.null(plateaus)) next

      companion <- channels$companero[[j]]
      if (!is.na(companion) && companion %in% names(raw)) {
        companion_value <- strip_status_suffix(raw[[companion]])
        ratio <- vapply(seq_len(nrow(plateaus)), function(k) {
          window <- raw$ts >= plateaus$inicio[[k]] &
            raw$ts <= plateaus$fin[[k]] & is.finite(companion_value)
          if (!any(window)) {
            return(NA_real_)
          }
          plateaus$media[[k]] / mean(companion_value[window])
        }, numeric(1))
        plateaus$razon_companero <- ratio
        plateaus <- plateaus[
          is.finite(ratio) &
            ratio >= channels$companero_min[[j]] &
            ratio <= channels$companero_max[[j]], , drop = FALSE
        ]
        if (nrow(plateaus) == 0L) next
      } else {
        plateaus$razon_companero <- NA_real_
      }

      plateaus$corrida <- rr_file_metadata$corrida[[i]]
      plateaus$archivo <- rr_file_metadata$file[[i]]
      plateaus$analito <- channels$analito[[j]]
      plateaus$canal <- column
      plateaus$unidad <- unname(unidades[[column]])
      parts[[length(parts) + 1L]] <- plateaus
    }
  }
  result <- do.call(rbind, parts)
  # Nivel 1 = mas alto, siguiendo la secuencia descendente del diseno.
  result <- do.call(rbind, lapply(
    split(result, result$analito),
    function(block) {
      block <- block[order(-block$media), ]
      block$orden <- seq_len(nrow(block))
      block
    }
  ))
  rownames(result) <- NULL
  result[order(result$analito, result$orden), ]
}

# -------------------------------------------------------------------
# Resumen de la referencia 4U por nivel
# -------------------------------------------------------------------

summarise_reference <- function(qc = pt_qc) {
  selected <- qc[
    qc$es_analito & qc$rol == "ref" &
      qc$level %in% as.character(1:5) &
      is.finite(qc$valor) &
      !qc$flag_na & !qc$flag_outlier & !qc$flag_gen_mismatch,
    , drop = FALSE
  ]
  key <- interaction(
    selected$ronda, selected$analito, selected$level, drop = TRUE
  )
  parts <- lapply(split(selected, key), function(block) {
    data.frame(
      ronda = block$ronda[[1L]],
      analito = block$analito[[1L]],
      unidad = block$unidad[[1L]],
      serial_ref = block$serial[[1L]],
      level = block$level[[1L]],
      nominal = stats::median(block$nominal, na.rm = TRUE),
      n_ref = nrow(block),
      media_ref = mean(block$valor),
      sd_ref = stats::sd(block$valor),
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  # Excluye el nivel cero: no aporta a pendiente ni a E_n relativo.
  result <- result[is.finite(result$nominal) & result$nominal > 0, ]
  result <- do.call(rbind, lapply(
    split(result, interaction(result$ronda, result$analito, drop = TRUE)),
    function(block) {
      block <- block[order(-block$nominal), ]
      block$orden <- seq_len(nrow(block))
      block
    }
  ))
  rownames(result) <- NULL
  result[order(result$analito, result$ronda, result$orden), ]
}

# -------------------------------------------------------------------
# Pareo UNAL <-> referencia
# -------------------------------------------------------------------

# Primero por nominal dentro de tolerancia; los que sobran se parean
# por orden descendente para no perder ningun nivel de la comparacion.
pair_levels <- function(plateaus, reference) {
  parts <- list()
  groups <- split(reference, interaction(
    reference$ronda, reference$analito, drop = TRUE
  ))
  for (block in groups) {
    analyte <- block$analito[[1L]]
    unal <- plateaus[plateaus$analito == analyte, , drop = FALSE]
    if (nrow(unal) == 0L) next

    used_unal <- rep(FALSE, nrow(unal))
    matched <- rep(NA_integer_, nrow(block))
    tipo <- rep(NA_character_, nrow(block))

    tolerance <- pmax(RR_ABS_TOL, RR_REL_TOL * block$nominal)
    distances <- outer(block$nominal, unal$media, function(a, b) abs(a - b))
    candidates <- which(
      distances <= tolerance[row(distances)], arr.ind = TRUE
    )
    if (nrow(candidates) > 0L) {
      candidates <- candidates[
        order(distances[candidates]), , drop = FALSE
      ]
      for (r in seq_len(nrow(candidates))) {
        ref_index <- candidates[r, 1L]
        unal_index <- candidates[r, 2L]
        if (!is.na(matched[ref_index]) || used_unal[unal_index]) next
        matched[ref_index] <- unal_index
        used_unal[unal_index] <- TRUE
        tipo[ref_index] <- "nominal"
      }
    }
    for (ref_index in which(is.na(matched))) {
      unal_index <- which(!used_unal & unal$orden == block$orden[ref_index])
      if (length(unal_index) == 0L) next
      matched[ref_index] <- unal_index[[1L]]
      used_unal[unal_index[[1L]]] <- TRUE
      tipo[ref_index] <- "rango"
    }

    valid <- !is.na(matched)
    if (!any(valid)) next
    block <- block[valid, , drop = FALSE]
    partner <- unal[matched[valid], , drop = FALSE]

    parts[[length(parts) + 1L]] <- data.frame(
      analito = block$analito,
      ronda = block$ronda,
      unidad = block$unidad,
      level = block$level,
      nominal = block$nominal,
      pareo = tipo[valid],
      serial_ref = block$serial_ref,
      n_ref = block$n_ref,
      media_ref = block$media_ref,
      sd_ref = block$sd_ref,
      corrida_unal = partner$corrida,
      inicio_unal = partner$inicio,
      fin_unal = partner$fin,
      n_unal = partner$n,
      media_unal = partner$media,
      sd_unal = partner$sd,
      stringsAsFactors = FALSE
    )
  }
  result <- do.call(rbind, parts)
  rownames(result) <- NULL

  result$delta_nominal <- result$media_unal - result$nominal
  result$u_ref <- result$sd_ref / sqrt(result$n_ref)
  result$u_unal <- result$sd_unal / sqrt(result$n_unal)
  # El sesgo solo tiene sentido si ambos lados vieron la misma
  # concentracion nominal.
  comparable <- result$pareo == "nominal"
  result$d <- ifelse(comparable, result$media_unal - result$media_ref, NA_real_)
  result$u_d <- ifelse(
    comparable, sqrt(result$u_unal^2 + result$u_ref^2), NA_real_
  )
  result$U_d <- RR_K * result$u_d
  result$e_n <- result$d / result$U_d
  result$d_rel_pct <- 100 * result$d / result$media_ref
  result$aprueba_en <- ifelse(is.finite(result$e_n), abs(result$e_n) <= 1, NA)
  result$nota <- ifelse(
    comparable, "",
    "nominal no equivalente: solo comparable en varianza y pendiente"
  )
  result[order(result$analito, result$ronda, -result$nominal), ]
}

# -------------------------------------------------------------------
# Repetibilidad, reproducibilidad, regresion
# -------------------------------------------------------------------

pooled_sd <- function(sd_values, n_values) {
  keep <- is.finite(sd_values) & is.finite(n_values) & n_values > 1L
  if (!any(keep)) {
    return(c(s = NA_real_, gl = NA_real_))
  }
  df <- n_values[keep] - 1L
  c(s = sqrt(sum(df * sd_values[keep]^2) / sum(df)), gl = sum(df))
}

repeatability_table <- function(paired) {
  paired$r_unal <- 2.8 * paired$sd_unal
  paired$r_ref <- 2.8 * paired$sd_ref
  paired$cv_unal_pct <- 100 * paired$sd_unal / paired$media_unal
  paired$cv_ref_pct <- 100 * paired$sd_ref / paired$media_ref
  paired$razon_varianzas <- paired$sd_unal^2 / paired$sd_ref^2
  paired$p_f <- mapply(function(ratio, n1, n2) {
    if (!is.finite(ratio) || n1 < 2L || n2 < 2L) {
      return(NA_real_)
    }
    tail_p <- stats::pf(ratio, n1 - 1L, n2 - 1L)
    2 * min(tail_p, 1 - tail_p)
  }, paired$razon_varianzas, paired$n_unal, paired$n_ref)

  columns <- c(
    "analito", "ronda", "unidad", "level", "nominal", "pareo",
    "n_unal", "media_unal", "sd_unal", "cv_unal_pct", "r_unal",
    "n_ref", "media_ref", "sd_ref", "cv_ref_pct", "r_ref",
    "razon_varianzas", "p_f"
  )
  paired[, columns, drop = FALSE]
}

reproducibility_table <- function(paired) {
  groups <- split(paired, interaction(
    paired$analito, paired$ronda, drop = TRUE
  ))
  parts <- lapply(groups, function(block) {
    unal <- pooled_sd(block$sd_unal, block$n_unal)
    ref <- pooled_sd(block$sd_ref, block$n_ref)
    both <- pooled_sd(
      c(block$sd_unal, block$sd_ref), c(block$n_unal, block$n_ref)
    )
    comparable <- block[block$pareo == "nominal", , drop = FALSE]

    # s_L con dos laboratorios y k niveles: varianza de la diferencia
    # media entre series, corregida por el ruido de repetibilidad.
    if (nrow(comparable) >= 2L) {
      between <- stats::var(comparable$d) / 2
      within <- both[["s"]]^2 *
        mean(1 / comparable$n_unal + 1 / comparable$n_ref) / 2
      s_l_squared <- max(between - within, 0)
    } else {
      s_l_squared <- NA_real_
    }
    s_r_within <- both[["s"]]
    s_reproducibility <- sqrt(s_l_squared + s_r_within^2)

    data.frame(
      analito = block$analito[[1L]],
      ronda = block$ronda[[1L]],
      unidad = block$unidad[[1L]],
      niveles = nrow(block),
      niveles_nominal_equivalente = nrow(comparable),
      s_r_unal = unal[["s"]],
      gl_unal = unal[["gl"]],
      s_r_ref = ref[["s"]],
      gl_ref = ref[["gl"]],
      s_r = s_r_within,
      r = 2.8 * s_r_within,
      s_L = sqrt(s_l_squared),
      s_R = s_reproducibility,
      R = 2.8 * s_reproducibility,
      sesgo_medio = if (nrow(comparable) > 0L) mean(comparable$d) else NA_real_,
      gl_s_L = 1L,
      advertencia = paste(
        "s_L estimado con 2 series (1 gl): indicativo, no estimador",
        if (nrow(comparable) < nrow(block)) {
          "; incluye niveles pareados por rango"
        } else {
          ""
        },
        sep = ""
      ),
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$analito, result$ronda), ]
}

# Deming: errores en ambos ejes, lambda = var(y) / var(x).
deming_fit <- function(x, y, lambda) {
  n <- length(x)
  mean_x <- mean(x)
  mean_y <- mean(y)
  sxx <- sum((x - mean_x)^2) / (n - 1L)
  syy <- sum((y - mean_y)^2) / (n - 1L)
  sxy <- sum((x - mean_x) * (y - mean_y)) / (n - 1L)
  term <- syy - lambda * sxx
  slope <- (term + sqrt(term^2 + 4 * lambda * sxy^2)) / (2 * sxy)
  c(pendiente = slope, intercepto = mean_y - slope * mean_x)
}

regression_table <- function(paired, replicates = 500L, seed = 20260730L) {
  set.seed(seed)
  groups <- split(paired, interaction(
    paired$analito, paired$ronda, drop = TRUE
  ))
  parts <- lapply(groups, function(block) {
    keep <- is.finite(block$media_ref) & is.finite(block$media_unal)
    block <- block[keep, , drop = FALSE]
    base <- data.frame(
      analito = block$analito[[1L]],
      ronda = block$ronda[[1L]],
      unidad = block$unidad[[1L]],
      n_puntos = nrow(block),
      niveles_nominal_equivalente = sum(block$pareo == "nominal"),
      stringsAsFactors = FALSE
    )
    if (nrow(block) < 3L) {
      return(cbind(base, data.frame(
        pendiente = NA_real_, pendiente_ic_inf = NA_real_,
        pendiente_ic_sup = NA_real_, intercepto = NA_real_,
        intercepto_ic_inf = NA_real_, intercepto_ic_sup = NA_real_,
        r2 = NA_real_, nota = "menos de 3 niveles pareados"
      )))
    }

    lambda <- mean(block$u_unal^2, na.rm = TRUE) /
      mean(block$u_ref^2, na.rm = TRUE)
    if (!is.finite(lambda) || lambda <= 0) lambda <- 1
    estimate <- deming_fit(block$media_ref, block$media_unal, lambda)

    boot <- replicate(replicates, {
      index <- sample.int(nrow(block), replace = TRUE)
      if (length(unique(block$media_ref[index])) < 2L) {
        return(c(NA_real_, NA_real_))
      }
      deming_fit(block$media_ref[index], block$media_unal[index], lambda)
    })
    slope_ci <- stats::quantile(boot[1L, ], c(0.025, 0.975), na.rm = TRUE)
    intercept_ci <- stats::quantile(boot[2L, ], c(0.025, 0.975), na.rm = TRUE)

    cbind(base, data.frame(
      pendiente = unname(estimate[["pendiente"]]),
      pendiente_ic_inf = unname(slope_ci[[1L]]),
      pendiente_ic_sup = unname(slope_ci[[2L]]),
      intercepto = unname(estimate[["intercepto"]]),
      intercepto_ic_inf = unname(intercept_ci[[1L]]),
      intercepto_ic_sup = unname(intercept_ci[[2L]]),
      r2 = stats::cor(block$media_ref, block$media_unal)^2,
      nota = if (any(block$pareo == "rango")) {
        "pendiente valida; sesgo por nivel no, nominal no equivalente"
      } else {
        ""
      },
      stringsAsFactors = FALSE
    ))
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result[order(result$analito, result$ronda), ]
}

# -------------------------------------------------------------------
# Ejecucion
# -------------------------------------------------------------------

run_rr_unal <- function() {
  plateaus <- collect_rr_plateaus()
  reference <- summarise_reference()
  paired <- pair_levels(plateaus, reference)

  repeatability <- repeatability_table(paired)
  reproducibility <- reproducibility_table(paired)
  regression <- regression_table(paired)

  table_dir <- file.path(OUTPUT_DIR, "tables")
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  writers <- list(
    rr_unal_mesetas = plateaus,
    rr_unal_referencia_niveles = reference,
    rr_unal_pareo_sesgo = paired,
    rr_unal_repetibilidad = repeatability,
    rr_unal_reproducibilidad = reproducibility,
    rr_unal_regresion = regression
  )
  for (name in names(writers)) {
    utils::write.csv(
      writers[[name]],
      file.path(table_dir, paste0(name, ".csv")),
      row.names = FALSE, na = ""
    )
  }

  assign("pt_rr_mesetas", plateaus, envir = .GlobalEnv)
  assign("pt_rr_pareo", paired, envir = .GlobalEnv)
  assign("pt_rr_repetibilidad", repeatability, envir = .GlobalEnv)
  assign("pt_rr_reproducibilidad", reproducibility, envir = .GlobalEnv)
  assign("pt_rr_regresion", regression, envir = .GlobalEnv)
  invisible(writers)
}

run_rr_unal()
