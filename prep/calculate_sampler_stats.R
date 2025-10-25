# Load the dplyr library for data manipulation
library(dplyr)

# List of file paths to process
file_paths <- c(
  "Z:/201_calferquim/z/pt_app/bsw_sampler_output_n10.csv",
  "Z:/201_calferquim/z/pt_app/bsw_sampler_output_n13.csv",
  "Z:/201_calferquim/z/pt_app/bsw_sampler_output_n4.csv",
  "Z:/201_calferquim/z/pt_app/bsw_sampler_output_n7.csv"
)

# Function to calculate stats and save to a single file per n-value
calculate_stats_and_save_by_n <- function(file_path) {
  # Read the CSV file
  df <- read.csv(file_path)

  # Extract n-number from filename (e.g., "n10")
  n_number_str <- regmatches(basename(file_path), regexpr("n\\d+", basename(file_path)))

  # Define the sample groups
  df <- df %>%
    mutate(sample_group = case_when(
      sample_id >= 1 & sample_id <= 10 ~ "1-10",
      sample_id >= 11 & sample_id <= 20 ~ "11-20",
      sample_id >= 21 & sample_id <= 30 ~ "21-30"
    ))

  # Group by the required columns and calculate mean and sd
  result <- df %>%
    group_by(pollutant, level, participant_id, replicate, sample_group) %>%
    summarise(
      mean_value = mean(value, na.rm = TRUE),
      sd_value = sd(value, na.rm = TRUE),
      .groups = 'drop'
    )

  # Construct output filename
  output_filename <- paste0("summary_", n_number_str, ".csv")

  # Save the result to a single file for this "n"
  write.csv(result, output_filename, row.names = FALSE)
  cat("Saved all pollutant results from", basename(file_path), "to:", output_filename, "\n")
}

# Apply the function to each file
lapply(file_paths, calculate_stats_and_save_by_n)
