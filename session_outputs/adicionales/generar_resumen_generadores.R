#!/usr/bin/env Rscript
# Genera resumen de valores generadores por dataset

source("R/preprocessing/read_calaire_raw.R")
source("R/preprocessing/clean_calaire_raw.R")

raw_files <- list.files("data/raw/", pattern = "datos_ronda_.*\\.csv$", full.names = TRUE)

results <- list()
for (f in raw_files) {
  fname <- basename(f)
  parts <- strsplit(gsub("datos_ronda_|\\.csv", "", fname), "_")[[1]]
  ronda <- parts[1]
  tipo <- parts[2]
  id <- paste0("ronda_", ronda, "_", tipo)

  # Leer y limpiar
  raw <- read_calaire_raw(f)
  cleaned <- clean_calaire_raw(raw)

  # Encontrar columnas de generador
  gen_cols <- names(cleaned$data)[grepl("gen", names(cleaned$data))]

  for (col in gen_cols) {
    # Extraer contaminante y unidad del nombre de columna
    col_parts <- strsplit(col, "_")[[1]]
    pollutant <- col_parts[1]
    unit <- col_parts[length(col_parts)]

    vals <- cleaned$data[[col]]
    vals <- as.numeric(vals)
    unique_vals <- sort(unique(vals[!is.na(vals) & vals != "samp"]))

    if (length(unique_vals) > 0) {
      results[[length(results) + 1]] <- data.frame(
        archivo = fname,
        ronda_id = id,
        contaminante = pollutant,
        unidad = unit,
        columna = col,
        valores_generador = paste(unique_vals, collapse = ", "),
        n_niveles = length(unique_vals),
        stringsAsFactors = FALSE
      )
    }
  }
}

df <- do.call(rbind, results)
write.csv(df, "data/processed/valores_generadores_resumen.csv", row.names = FALSE)
cat("=== VALORES GENERADORES POR DATASET ===\n\n")
print(df, row.names = FALSE)
cat("\n")
cat("Archivo guardado: data/processed/valores_generadores_resumen.csv\n")
