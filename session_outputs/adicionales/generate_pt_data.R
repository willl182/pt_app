library(dplyr)
library(readr)
library(stringr)

# Directorio de datos
data_dir <- "data"
# Archivos de entrada (todos los summaries)
input_files <- list.files(data_dir, pattern = "^summary_n[0-9]+.*\\.csv$", full.names = TRUE)

calculate_pt_data <- function(input_path) {
  # Obtener el sufijo del archivo (ej. n13 de summary_n13.csv)
  suffix <- str_extract(basename(input_path), "n[0-9]+")
  output_path <- file.path(data_dir, paste0("pt_data_", suffix, ".csv"))
  
  message(paste("Procesando:", basename(input_path), "->", basename(output_path)))
  
  df <- read_csv(input_path, show_col_types = FALSE)
  
  # Validar columnas necesarias
  required_cols <- c("pollutant", "level", "participant_id", "mean_value")
  if (!all(required_cols %in% colnames(df))) {
    stop(paste("El archivo", input_path, "no contiene las columnas necesarias:", paste(required_cols, collapse = ", ")))
  }
  
  # Filtrar participantes (excluir 'ref' si es necesario para el formato final)
  # Según la estructura de pt_data_n13.csv, no incluye 'ref'
  pt_data <- df %>%
    filter(participant_id != "ref") %>%
    group_by(participant_id, pollutant, level) %>%
    summarise(
      x_i = mean(mean_value, na.rm = TRUE),
      u_i = sd(mean_value, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    ) %>%
    select(participant_id, pollutant, level, x_i, u_i) %>%
    # Ordenar similar al original
    arrange(pollutant, level, participant_id)
  
  write_csv(pt_data, output_path)
  message("Guardado exitosamente.")
}

# Ejecutar para cada archivo encontrado
for (file in input_files) {
  tryCatch({
    calculate_pt_data(file)
  }, error = function(e) {
    warning(paste("Error procesando", file, ":", e$message))
  })
}
