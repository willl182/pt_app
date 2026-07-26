# Convierte pares de archivos crudos (referencia + participante) al formato de
# ronda consolidado (estilo R3_O3.csv): date time, <gas>_<ref>, <gas>_<part>,
# runtime, level, <gas>_gen.
#
# Regla fija de etiquetado por runtime:
#   - Nivel 1: minutos 00:00-00:59 (1 h, sin estab inicial)
#   - 30 min de estab (01:00-01:29) antes del cambio de concentracion
#   - Niveles 2+: bloques de 3 h desde 01:30; primeros 10 minutos -> "estab"
#
# Uso:
#   Rscript convert_round_raw.R <ref.csv> <part.csv> <gas> <serial_ref> \
#     <serial_part> <salida.csv> [skip_filas]
#
# gas: prefijo de columnas en los crudos (o3, no, no2, co, so2); se buscan
#      <gas>_* (valor) y <gas>_gen sin distinguir mayusculas.
# skip_filas: filas iniciales a descartar antes de calcular runtime (excepcion
#             por ronda, p. ej. 7 en ronda 2A para alinear el cambio de nivel).

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 6L) {
  stop("Uso: convert_round_raw.R <ref.csv> <part.csv> <gas> <serial_ref> <serial_part> <salida.csv> [skip_filas]")
}
ref_path <- args[1]
part_path <- args[2]
gas <- tolower(args[3])
serial_ref <- args[4]
serial_part <- args[5]
out_path <- args[6]
skip_rows <- if (length(args) >= 7L) as.integer(args[7]) else 0L

read_raw <- function(path, gas) {
  df <- read.csv2(path, stringsAsFactors = FALSE, dec = ".",
                  colClasses = "character", strip.white = TRUE)
  names(df) <- trimws(tolower(names(df)))
  df[] <- lapply(df, trimws)
  df <- df[df$time != "" & !is.na(df$time), , drop = FALSE]
  gen_col <- paste0(gas, "_gen")
  val_col <- setdiff(grep(paste0("^", gas, "_"), names(df), value = TRUE), gen_col)
  if (!gen_col %in% names(df) || length(val_col) != 1L) {
    stop(path, ": no se hallaron columnas '", gas, "_*' y '", gen_col, "' unicas")
  }
  data.frame(date = df$date, time = df$time,
             value = as.numeric(df[[val_col]]), gen = df[[gen_col]],
             stringsAsFactors = FALSE)
}

# Normaliza fecha a MM/DD/YY
to_date <- function(date) {
  fmt <- ifelse(grepl("/\\d{4}$", date), "%m/%d/%Y", "%m/%d/%y")
  out <- format(as.Date(date, format = "%m/%d/%y"), "%m/%d/%y")
  idx <- grepl("/\\d{4}$", date)
  out[idx] <- format(as.Date(date[idx], format = "%m/%d/%Y"), "%m/%d/%y")
  out
}

# Normaliza hora a HH:MM 24h; conserva anomalia "24:00[:00]" -> "24:00"
to_24h <- function(time) {
  out <- character(length(time))
  is24 <- grepl("^24:00", time)
  ampm <- grepl("[AP]M$", time, ignore.case = TRUE)
  plain <- !is24 & !ampm
  out[is24] <- "24:00"
  out[ampm] <- format(strptime(time[ampm], format = "%I:%M:%S %p"), "%H:%M")
  hhmm <- sub("^(\\d{1,2}:\\d{2}).*", "\\1", time[plain])
  out[plain] <- sub("^(\\d):", "0\\1:", hhmm)
  out
}

ref <- read_raw(ref_path, gas)
part <- read_raw(part_path, gas)

if (nrow(ref) != nrow(part)) {
  stop("Archivos con distinto numero de filas: ", nrow(ref), " vs ", nrow(part))
}
if (!identical(ref$date, part$date) || !identical(ref$time, part$time)) {
  stop("Timestamps no coinciden entre referencia y participante")
}
if (!identical(ref$gen, part$gen)) {
  stop("Columna ", gas, "_gen difiere entre referencia y participante")
}

out <- data.frame(
  `date time` = paste(to_date(ref$date), to_24h(ref$time)),
  ref = ref$value,
  part = part$value,
  gen = ref$gen,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

if (skip_rows > 0L) {
  out <- out[-seq_len(skip_rows), , drop = FALSE]
}

n <- nrow(out)
minute <- seq_len(n) - 1L

out$runtime <- sprintf("%02d:%02d", minute %/% 60L, minute %% 60L)

# Nivel 1: 1 h sin estab inicial, seguida de 30 min de estab. Desde el
# minuto 90, bloques de 3 h con 10 min de estab al inicio de cada uno.
out$level <- vapply(minute, function(m) {
  if (m < 60L) return("1")
  if (m < 90L) return("estab")
  block <- 2L + (m - 90L) %/% 180L
  block_start <- 90L + (block - 2L) * 180L
  if (m - block_start < 10L) "estab" else as.character(block)
}, character(1))

out <- out[, c("date time", "ref", "part", "runtime", "level", "gen")]
names(out)[c(2, 3, 6)] <- paste0(gas, "_", c(serial_ref, serial_part, "gen"))

write.csv(out, out_path, row.names = FALSE, quote = FALSE, na = "")
cat("Filas escritas:", n, "->", out_path, "\n")
print(table(out$level))
