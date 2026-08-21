# Exporta la ronda 3 al formato de carga de calaire-app.
#
# Fuente: salidas del preprocesamiento por runtime (no por reloj):
#   data_use_cases/data/processed/r3_resumen_niveles.csv
#   data_use_cases/data/processed/r3_promedios_horarios.csv
#
# El serial del equipo (columna `instrument`, tomado del encabezado del crudo,
# p. ej. o3_4UDY72 / o3_ZFT5R6) se usa como `participant_id`.
# Prefijo 4U = equipo de referencia CalAire.
#
# Uso:
#   Rscript data_use_cases/scripts/export_r3_to_calaire_app.R [root] [k]

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) >= 1L && nzchar(args[1])) args[1] else "."
k_default <- if (length(args) >= 2L) suppressWarnings(as.numeric(args[2])) else 2
if (!is.finite(k_default) || k_default <= 0) k_default <- 2

processed_dir <- file.path(root, "data_use_cases", "data", "processed")
out_dir <- file.path(root, "data_use_cases", "data", "to_calaire-app")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

summary_df <- read.csv(file.path(processed_dir, "r3_resumen_niveles.csv"), stringsAsFactors = FALSE)
hourly_df <- read.csv(file.path(processed_dir, "r3_promedios_horarios.csv"), stringsAsFactors = FALSE)

# Nivel nominal generado por bloque de runtime (pollutant + level de diseño).
nominal <- unique(hourly_df[c("pollutant", "level", "generated_nominal")])
nominal <- aggregate(generated_nominal ~ pollutant + level, data = nominal, FUN = max)

out <- merge(summary_df, nominal, by = c("pollutant", "level"), all.x = TRUE, sort = FALSE)

is_reference <- grepl("^4U", out$instrument)

# hour_starts en runtime (minutos desde el inicio del crudo), no en hora de reloj.
runtime_key <- paste(hourly_df$pollutant, hourly_df$level, hourly_df$instrument, hourly_df$hour_start)
runtime_map <- setNames(hourly_df$runtime_start, runtime_key)

runtime_starts <- vapply(seq_len(nrow(out)), function(i) {
  hs <- strsplit(out$hour_starts[i], "|", fixed = TRUE)[[1]]
  keys <- paste(out$pollutant[i], out$level[i], out$instrument[i], hs)
  paste(runtime_map[keys], collapse = "|")
}, character(1))

out <- data.frame(
  pollutant = out$pollutant,
  run = as.integer(out$level),           # bloque de runtime: 1..5
  level = format(out$generated_nominal, trim = TRUE, scientific = FALSE),
  participant_id = out$instrument,       # serial del equipo
  replicate = 1L,
  sample_group = "A",
  d1 = out$mean_h1,
  d2 = out$mean_h2,
  d3 = out$mean_h3,
  mean_value = out$mean_value,
  sd_value = out$sd_value,
  ux = out$u_value,
  k = k_default,
  ux_exp = round(out$u_value * k_default, 6),
  # columnas requeridas adicionalmente por calaire-app
  source = ifelse(is_reference, "ronda_referencia", "ronda_participante"),
  unit = out$unit,
  instrument = out$instrument,
  # alias pt_app de d1/d2/d3: sin estas la app replica mean_value en las 3 casillas
  mean_h1 = out$mean_h1,
  mean_h2 = out$mean_h2,
  mean_h3 = out$mean_h3,
  u_value = out$u_value,
  u_exp = round(out$u_value * k_default, 6),
  k_factor = k_default,
  n_hours = out$n_hours,
  hour_starts = runtime_starts,
  is_reference = is_reference,
  stringsAsFactors = FALSE
)

out <- out[order(out$pollutant, out$run, out$participant_id), ]
row.names(out) <- NULL

write_split <- function(df, path) {
  df$is_reference <- NULL
  # NA explicito: las celdas vacias hacen que calaire-app reclame la replica
  # faltante (p. ej. no2 nivel 2, que solo tiene 140 min de datos crudos).
  write.csv(df, path, row.names = FALSE, na = "NA")
  cat("  ", path, ":", nrow(df), "filas\n")
}

# calaire-app valida `level` contra su catalogo de niveles PT (1..5), no contra
# la concentracion nominal.
out$level <- as.character(out$run)

cat("Exportado para calaire-app (level = indice PT 1..5):\n")
write_split(out[out$is_reference, ], file.path(out_dir, "3-ref.csv"))
write_split(out[!out$is_reference, ], file.path(out_dir, "3-pt.csv"))
