# This script prepares the bootstrap data files for easy pasting into the Shiny app.
# It reads each specified CSV file, removes the unnecessary 'source_file' column,
# and writes the cleaned data to a new file prefixed with 'for_paste_'.

# Load necessary library for data manipulation
library(tidyverse)

# List of input files to process
files_to_process <- c(
  "bsw_co.csv",
  "bsw_no.csv",
  "bsw_no2.csv",
  "bsw_o3.csv",
  "bsw_so2.csv"
)

# Loop through the files, read, process, and write new files
for (input_file in files_to_process) {
  # Create a new file name for the output
  output_file <- paste0("for_paste_", input_file)

  # Read the data from the input file
  data <- read_csv(input_file, show_col_types = FALSE)

  # Process data: select all columns except 'source_file'
  processed_data <- data %>%
    select(-source_file)

  # Write the processed data to the new CSV file
  write_csv(processed_data, output_file)

  # Print a message to confirm processing
  cat(paste("Created:", output_file, "\n"))
}

cat("\nAll files processed successfully.\n")
