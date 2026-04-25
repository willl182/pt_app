run_pipeline_ronda <- function(
    data_dir     = "data/raw",
    metadata_dir = "data/metadata",
    output_dir   = "data/processed",
    tz           = "America/Bogota"
) {
  path_ronda      <- file.path(data_dir,     "datos_ronda.csv")
  path_levels     <- file.path(metadata_dir, "niveles_calaire.csv")
  path_hourly_out <- file.path(output_dir,   "h_datos_ronda.csv")
  path_log_out    <- file.path(metadata_dir, "preprocesamiento_log_ronda.csv")

  required <- c(path_ronda, path_levels)
  missing  <- required[!file.exists(required)]
  if (length(missing) > 0)
    stop("Required input files missing:\n  ", paste(missing, collapse = "\n  "))

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  message("--- [Ronda] Paso 1: Leyendo datos ---")
  raw    <- read_calaire_raw(path_ronda)
  levels <- read.csv(path_levels, stringsAsFactors = FALSE)
  message("  Filas leidas: ", raw$n_rows)

  message("--- [Ronda] Paso 2: Limpieza y normalizacion ---")
  cleaned <- clean_calaire_raw(raw, tz = tz)
  message("  Filas tras limpieza: ", nrow(cleaned$data))

  message("--- [Ronda] Paso 3: Promedios horarios ---")
  hourly    <- compute_hourly_averages_ronda(cleaned$data, levels, tz = tz)
  n_valid_h <- sum(hourly$valid_hour == TRUE, na.rm = TRUE)
  message("  Horas evaluadas: ", nrow(hourly), " | Validas: ", n_valid_h)

  message("--- [Ronda] Paso 4: Validacion cruzada ---")
  val_log <- run_ronda_checks(
    paths        = list(ronda = path_ronda, levels = path_levels),
    raw_result   = raw,
    clean_result = cleaned,
    hourly_df    = hourly,
    levels_table = levels,
    tz           = tz
  )
  write.csv(val_log, path_log_out, row.names = FALSE)
  message("  Log escrito en: ", path_log_out)

  message("--- [Ronda] Paso 5: Escribiendo salidas ---")
  write.csv(hourly, path_hourly_out, row.names = FALSE)
  message("  Salida: ", path_hourly_out)

  fails <- val_log[val_log$status == "FAIL", ]
  warns <- val_log[val_log$status == "WARN", ]
  if (nrow(warns) > 0)
    message("  WARN (", nrow(warns), "): ", paste(warns$check, collapse = ", "))
  if (nrow(fails) > 0)
    message("  FAIL (", nrow(fails), "): ", paste(fails$check, collapse = ", "))

  invisible(list(
    raw     = raw,
    cleaned = cleaned,
    hourly  = hourly,
    log     = val_log,
    success = nrow(fails) == 0
  ))
}

run_pipeline_calaire <- function(
    data_dir     = "data/raw",
    metadata_dir = "data/metadata",
    output_dir   = "data/processed",
    tz           = "America/Bogota"
) {
  # Resolve paths
  path_estabilidad <- file.path(data_dir, "datos_estabilidad_homogeneidad.csv")
  path_design      <- file.path(metadata_dir, "diseno_estabilidad_homogeneidad.csv")
  path_levels      <- file.path(metadata_dir, "niveles_calaire.csv")
  path_hourly_out  <- file.path(output_dir, "h_estabilidad_homogeneidad.csv")
  path_mm_out      <- file.path(output_dir, "mm_estabilidad_homogeneidad.csv")
  path_incert_out  <- file.path(output_dir, "incertidumbre.md")
  path_log_out     <- file.path(metadata_dir, "preprocesamiento_log.csv")

  # Stop early if required inputs are missing
  required <- c(path_estabilidad, path_design, path_levels)
  missing  <- required[!file.exists(required)]
  if (length(missing) > 0) {
    stop("Required input files missing:\n  ", paste(missing, collapse = "\n  "))
  }

  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  message("--- Paso 1: Leyendo datos ---")
  raw     <- read_calaire_raw(path_estabilidad)
  design  <- read.csv(path_design,  stringsAsFactors = FALSE)
  levels  <- read.csv(path_levels,  stringsAsFactors = FALSE)
  message("  Filas leidas: ", raw$n_rows)

  message("--- Paso 2: Limpieza y normalizacion ---")
  cleaned <- clean_calaire_raw(raw, tz = tz)
  message("  Filas tras limpieza: ", nrow(cleaned$data))

  message("--- Paso 3: Promedios horarios ---")
  hourly  <- compute_hourly_averages(cleaned$data, design, tz = tz)
  n_valid_h <- sum(hourly$valid_hour == TRUE, na.rm = TRUE)
  message("  Horas evaluadas: ", nrow(hourly), " | Validas: ", n_valid_h)

  message("--- Paso 4: Medias moviles ---")
  mm      <- compute_moving_hourly_means(cleaned$data, design, tz = tz)
  n_valid_mm <- sum(mm$valid_mm == TRUE, na.rm = TRUE)
  message("  Ventanas validas: ", n_valid_mm, " | Total filas MM: ", nrow(mm))

  message("--- Paso 5: Reporte de incertidumbre ---")
  write_uncertainty_report(path_incert_out, hourly_summary = hourly)

  message("--- Paso 6: Escribiendo salidas ---")
  write.csv(hourly, path_hourly_out, row.names = FALSE)
  write.csv(mm,     path_mm_out,     row.names = FALSE)
  message("  Salidas escritas en: ", output_dir)

  message("--- Paso 7: Validacion cruzada ---")
  paths <- list(
    estabilidad = path_estabilidad,
    design      = path_design,
    levels      = path_levels
  )
  val_log <- run_all_checks(
    paths        = paths,
    raw_result   = raw,
    clean_result = cleaned,
    hourly_df    = hourly,
    mm_df        = mm,
    design       = design,
    levels_table = levels,
    tz           = tz
  )

  write.csv(val_log, path_log_out, row.names = FALSE)
  message("  Log escrito en: ", path_log_out)

  # Report failures
  fails <- val_log[val_log$status == "FAIL", ]
  warns <- val_log[val_log$status == "WARN", ]
  if (nrow(warns) > 0) {
    message("  WARN (", nrow(warns), "): ",
            paste(warns$check, collapse = ", "))
  }
  if (nrow(fails) > 0) {
    message("  FAIL (", nrow(fails), "): ",
            paste(fails$check, collapse = ", "))
  }

  invisible(list(
    raw     = raw,
    cleaned = cleaned,
    hourly  = hourly,
    mm      = mm,
    log     = val_log,
    success = nrow(fails) == 0
  ))
}
