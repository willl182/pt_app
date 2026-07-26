args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) >= 1L) args[1] else "."
raw_dir <- file.path(root, "data_use_cases", "data", "raw")
processed_dir <- file.path(root, "data_use_cases", "data", "processed")

source(file.path(root, "R", "preprocessing", "hourly_averages.R"))

dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
paths <- file.path(raw_dir, c("R3_O3.csv", "R3_NO2.csv", "R3_NO.csv"))
missing <- paths[!file.exists(paths)]
if (length(missing) > 0L) stop("Missing raw files: ", paste(missing, collapse = ", "))

result <- process_raw_round_files(paths, max_hours = 3L)
summary <- summarise_reference_levels(result$hourly)

write.csv(
  result$assessment,
  file.path(processed_dir, "r3_capacidad_horaria.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  result$hourly,
  file.path(processed_dir, "r3_promedios_horarios.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  summary,
  file.path(processed_dir, "r3_resumen_niveles.csv"),
  row.names = FALSE,
  na = ""
)

cat("Assessment:", nrow(result$assessment), "blocks\n")
cat("Hourly averages:", nrow(result$hourly), "rows\n")
cat("Level summaries:", nrow(summary), "rows\n")
