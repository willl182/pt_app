library(dplyr)
library(readr)
library(stringr)

# Directorio de datos
data_dir <- "data"
# Archivos de entrada (todos los summaries)
input_files <- list.files(data_dir, pattern = "^summary_n[0-9]+.*\\.csv$", full.names = TRUE)

generate_csvs <- function(input_path) {
  # Obtener el sufijo del archivo (ej. n13)
  suffix <- str_extract(basename(input_path), "n[0-9]+")
  pt_output_path <- file.path(data_dir, paste0("pt_data_", suffix, ".csv"))
  ref_output_path <- file.path(data_dir, paste0("referencia_ronda_", suffix, ".csv"))
  
  message(paste("Procesando:", basename(input_path)))
  
  df <- read_csv(input_path, show_col_types = FALSE)
  
  # 1. Generar pt_data (sin ref)
  pt_data <- df %>%
    filter(participant_id != "ref") %>%
    group_by(participant_id, pollutant, level) %>%
    summarise(
      x_i = mean(mean_value, na.rm = TRUE),
      u_i = sd(mean_value, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    ) %>%
    select(participant_id, pollutant, level, x_i, u_i) %>%
    arrange(pollutant, level, participant_id)
  
  write_csv(pt_data, pt_output_path)
  message(paste("  - Guardado:", basename(pt_output_path)))
  
  # 2. Generar referencia_ronda (solo ref)
  ref_data <- df %>%
    filter(participant_id == "ref") %>%
    group_by(pollutant, level) %>%
    summarise(
      x_ref = mean(mean_value, na.rm = TRUE),
      u_ref = sd(mean_value, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    ) %>%
    select(pollutant, level, x_ref, u_ref) %>%
    arrange(pollutant, level)
  
  write_csv(ref_data, ref_output_path)
  message(paste("  - Guardado:", basename(ref_output_path)))
}

# Ejecutar
for (file in input_files) {
  tryCatch({
    generate_csvs(file)
  }, error = function(e) {
    warning(paste("Error procesando", file, ":", e$message))
  })
}
