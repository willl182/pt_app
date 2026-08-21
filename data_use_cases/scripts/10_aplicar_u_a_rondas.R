# ===================================================================
# Copia los archivos de referencia de cada ronda agregando la
# incertidumbre del presupuesto.
#
# Lee data/processed/ronda_*_r.csv, les pega u_c, u_exp y k_factor
# desde outputs/tables/u_referencia_aplicable.csv y escribe las copias
# en data/processed/con_incertidumbre/. Los originales no se tocan.
#
# El cruce es por pollutant + level. Los niveles cero quedan sin
# incertidumbre: el presupuesto se construyo sobre niveles con
# concentracion nominal mayor que cero.
#
# La columna u_value se SOBRESCRIBE con la incertidumbre combinada del
# presupuesto. Antes traia solo la componente de repetibilidad, sin
# corregir autocorrelacion, y quedarse con las dos se prestaba a
# confusion.
# ===================================================================

if (!exists("pt_u_aplicable", inherits = TRUE)) {
  script_path <- if (file.exists(file.path("scripts", "09_presupuesto_incertidumbre.R"))) {
    file.path("scripts", "09_presupuesto_incertidumbre.R")
  } else {
    file.path("data_use_cases", "scripts", "09_presupuesto_incertidumbre.R")
  }
  source(script_path)
}

PROCESSED_DIR <- file.path(ANALYSIS_ROOT, "data", "processed")
OUTPUT_WITH_U <- file.path(PROCESSED_DIR, "con_incertidumbre")

# El participante no tiene presupuesto propio armado: no hay formatos
# de calibracion ni verificacion de aire cero de su equipo. Se toma el
# presupuesto de la referencia degradado un 15 %, que es el extremo
# conservador del 10-15 % estimado. Cambiar aqui si se consigue el
# dato real.
PARTICIPANT_U_FACTOR <- 1.15

# Archivo de participante que corresponde a cada archivo de referencia.
PARTICIPANT_FILE <- c(
  "ronda_1_r.csv" = "ronda_1_p_ronda.csv",
  "ronda_2a_r.csv" = "ronda_2a_p_ronda.csv",
  "ronda_2b_r.csv" = "ronda_2b_p_ronda.csv",
  "ronda_2c_r.csv" = "ronda_2c_p_ronda.csv",
  "ronda_3_r.csv" = "ronda_3_p_ronda.csv"
)

apply_uncertainty <- function(lookup = pt_u_aplicable) {
  dir.create(OUTPUT_WITH_U, recursive = TRUE, showWarnings = FALSE)
  report <- list()

  for (file_name in unique(lookup$archivo_procesado)) {
    source_path <- file.path(PROCESSED_DIR, file_name)
    if (!file.exists(source_path)) {
      warning("No existe ", file_name, "; se omite")
      next
    }
    data <- utils::read.csv(
      source_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8",
      check.names = FALSE
    )
    subset <- lookup[lookup$archivo_procesado == file_name, , drop = FALSE]

    # merge() reordena filas; se resuelve por indice para conservar el
    # orden original del archivo.
    key_data <- paste(data$pollutant, data$level, sep = "|")
    key_lookup <- paste(subset$pollutant, subset$level, sep = "|")
    position <- match(key_data, key_lookup)

    data$u_rep <- subset$u_rep[position]
    data$u_curva <- subset$u_curva[position]
    data$u_patron <- subset$u_patron[position]
    data$u_aire_cero <- subset$u_aire_cero[position]
    data$u_conv <- subset$u_conv[position]
    # u_value pasa a ser la incertidumbre combinada del presupuesto.
    # Antes era solo la componente de repetibilidad y estaba
    # subestimada; se sustituye en vez de agregar otra columna.
    data$u_value <- subset$u_c[position]
    data$k_factor <- ifelse(is.na(position), NA_real_, BUDGET_K)
    data$u_exp <- subset$u_exp[position]
    data$desfase_generador <- subset$desfase_generador[position]

    target_path <- file.path(
      OUTPUT_WITH_U, sub("\\.csv$", "_u.csv", file_name)
    )
    utils::write.csv(data, target_path, row.names = FALSE, na = "")

    # Mismo tratamiento para el participante de esa ronda.
    participant_name <- PARTICIPANT_FILE[[file_name]]
    participant_path <- file.path(PROCESSED_DIR, participant_name)
    if (file.exists(participant_path)) {
      participant <- utils::read.csv(
        participant_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8",
        check.names = FALSE
      )
      key_participant <- paste(
        participant$pollutant, participant$level, sep = "|"
      )
      index <- match(key_participant, key_lookup)
      factor <- PARTICIPANT_U_FACTOR

      participant$u_rep <- subset$u_rep[index] * factor
      participant$u_curva <- subset$u_curva[index] * factor
      participant$u_patron <- subset$u_patron[index] * factor
      participant$u_aire_cero <- subset$u_aire_cero[index] * factor
      participant$u_conv <- subset$u_conv[index] * factor
      participant$u_value <- subset$u_c[index] * factor
      participant$k_factor <- ifelse(is.na(index), NA_real_, BUDGET_K)
      participant$u_exp <- subset$u_exp[index] * factor
      participant$factor_participante <- ifelse(is.na(index), NA_real_, factor)
      participant$desfase_generador <- subset$desfase_generador[index]

      utils::write.csv(
        participant,
        file.path(OUTPUT_WITH_U, sub("\\.csv$", "_u.csv", participant_name)),
        row.names = FALSE, na = ""
      )
    }

    report[[length(report) + 1L]] <- data.frame(
      archivo = basename(target_path),
      filas = nrow(data),
      con_incertidumbre = sum(!is.na(position)),
      sin_incertidumbre = sum(is.na(position)),
      niveles_sin_cruce = paste(
        unique(data$level[is.na(position)]), collapse = ", "
      ),
      stringsAsFactors = FALSE
    )
  }

  result <- do.call(rbind, report)
  rownames(result) <- NULL
  result
}

# Columnas del archivo unificado por ronda. Los archivos de origen no
# comparten esquema (R1/R2 no traen serial ni tipo, y solo el
# participante trae factor_participante), asi que se rellena lo que
# falte antes de apilar.
COMBINED_COLUMNS <- c(
  "ronda", "tipo", "pollutant", "run", "level", "unit", "instrument",
  "participant_id", "serial", "mean_h1", "mean_h2", "mean_h3",
  "mean_value", "sd_value", "n_hours", "hour_starts",
  "u_rep", "u_curva", "u_patron", "u_aire_cero", "u_conv",
  "u_value", "k_factor", "u_exp", "factor_participante",
  "desfase_generador"
)

align_columns <- function(data, ronda, tipo) {
  data$ronda <- ronda
  data$tipo <- tipo
  for (column in setdiff(COMBINED_COLUMNS, names(data))) {
    data[[column]] <- NA
  }
  data[, COMBINED_COLUMNS, drop = FALSE]
}

# Un archivo por ronda con referencia y participante apilados.
combine_by_round <- function() {
  rondas <- c(
    ronda_1 = "R1", ronda_2a = "R2A", ronda_2b = "R2B",
    ronda_2c = "R2C", ronda_3 = "R3"
  )
  written <- character(0)
  for (base in names(rondas)) {
    reference_path <- file.path(OUTPUT_WITH_U, paste0(base, "_r_u.csv"))
    participant_path <- file.path(OUTPUT_WITH_U, paste0(base, "_p_ronda_u.csv"))
    if (!file.exists(reference_path)) next

    read_one <- function(path, tipo) {
      if (!file.exists(path)) {
        return(NULL)
      }
      data <- utils::read.csv(
        path, stringsAsFactors = FALSE, fileEncoding = "UTF-8",
        check.names = FALSE
      )
      align_columns(data, rondas[[base]], tipo)
    }

    combined <- rbind(
      read_one(reference_path, "referencia"),
      read_one(participant_path, "participante")
    )
    # Referencia y participante juntos en cada nivel, en el orden en
    # que la ronda recorrio los niveles.
    combined <- combined[order(
      combined$pollutant, combined$run, combined$tipo != "referencia"
    ), ]
    rownames(combined) <- NULL

    target <- file.path(OUTPUT_WITH_U, paste0(base, "_u.csv"))
    utils::write.csv(combined, target, row.names = FALSE, na = "")
    written <- c(written, basename(target))
  }
  written
}

run_aplicar <- function() {
  report <- apply_uncertainty()
  combined_files <- combine_by_round()
  cat("Archivos combinados por ronda:", paste(combined_files, collapse = ", "), "\n")
  utils::write.csv(
    report,
    file.path(OUTPUT_WITH_U, "_resumen_cruce.csv"),
    row.names = FALSE, na = ""
  )
  print(report)
  assign("pt_reporte_cruce", report, envir = .GlobalEnv)
  invisible(report)
}

run_aplicar()
