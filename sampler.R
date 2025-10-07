# Set a seed for reproducibility
set.seed(421)

# List of files to process
files <- c(
  "for_paste_bsw_co.csv",
  "for_paste_bsw_no.csv",
  "for_paste_bsw_no2.csv",
  "for_paste_bsw_o3.csv",
  "for_paste_bsw_so2.csv"
)

# --- Homogeneity Samples ---

# Initialize an empty list to store data frames
all_samples_list <- list()

# Loop over each file
for (file_path in files) {
  # Extract pollutant name from filename
  pollutant_name <- gsub("for_paste_bsw_|[.]csv", "", file_path)
  
  # Read the data
  data <- read.csv(file_path)
  
  # Get unique levels
  unique_levels <- unique(data$level)
  
  for (lvl in unique_levels) {
    # Filter data for the current level and convert to a numeric vector
    level_data <- unlist(data[data$level == lvl, -1])
    level_data <- level_data[!is.na(level_data)]
    
    # Take two sets of 10 random samples (replicates) with replacement
    replicate1 <- sample(level_data, 10, replace = TRUE)
    replicate2 <- sample(level_data, 10, replace = TRUE)
    
    # Create data frames for each replicate and add to the list
    df1 <- data.frame(
      pollutant = pollutant_name,
      level = lvl,
      replicate = 1,
      sample_id = 1:10,
      value = replicate1
    )
    df2 <- data.frame(
      pollutant = pollutant_name,
      level = lvl,
      replicate = 2,
      sample_id = 1:10,
      value = replicate2
    )
    
    all_samples_list <- append(all_samples_list, list(df1, df2))
  }
}

# Combine all data frames into one
final_samples_df <- do.call(rbind, all_samples_list)

# Save the final dataframe to a CSV file
write.csv(final_samples_df, "homogeneity.csv", row.names = FALSE)


# --- Stability Samples ---

# Initialize an empty list for stability samples
stability_samples_list <- list()

# Loop over each file again for stability samples
for (file_path in files) {
  # Extract pollutant name from filename
  pollutant_name <- gsub("for_paste_bsw_|[.]csv", "", file_path)
  
  # Read the data
  data <- read.csv(file_path)
  
  # Get unique levels
  unique_levels <- unique(data$level)
  
  for (lvl in unique_levels) {
    # Filter data for the current level and convert to a numeric vector
    level_data <- unlist(data[data$level == lvl, -1])
    level_data <- level_data[!is.na(level_data)]
    
    # Take two sets of 2 random samples (replicates) with replacement
    replicate1 <- sample(level_data, 2, replace = TRUE)
    replicate2 <- sample(level_data, 2, replace = TRUE)
    
    # Create data frames for each replicate and add to the list
    df1 <- data.frame(
      pollutant = pollutant_name,
      level = lvl,
      replicate = 1,
      sample_id = 1:2,
      value = replicate1
    )
    df2 <- data.frame(
      pollutant = pollutant_name,
      level = lvl,
      replicate = 2,
      sample_id = 1:2,
      value = replicate2
    )
    
    stability_samples_list <- append(stability_samples_list, list(df1, df2))
  }
}

# Combine all data frames into one for stability
stability_samples_df <- do.call(rbind, stability_samples_list)

# Save the stability dataframe to a CSV file
write.csv(stability_samples_df, "stability.csv", row.names = FALSE)


# --- Subsets with n replicates ---

# List of replicate numbers
n_values <- c(4, 7, 10, 13)

# Number of samples per replicate
num_samples <- 10

# Loop over each n value
for (n in n_values) {
  # Initialize an empty list to store data frames
  all_samples_list_n <- list()

  # Loop over each file
  for (file_path in files) {
    # Extract pollutant name from filename
    pollutant_name <- gsub("for_paste_bsw_|[.]csv", "", file_path)

    # Read the data
    data <- read.csv(file_path)

    # Get unique levels
    unique_levels <- unique(data$level)

    for (lvl in unique_levels) {
      # Filter data for the current level and convert to a numeric vector
      level_data <- unlist(data[data$level == lvl, -1])
      level_data <- level_data[!is.na(level_data)]

      # Create n replicates
      for (i in 1:n) {
        # Take samples for the replicate
        replicate_samples <- sample(level_data, num_samples, replace = TRUE)
        
        # Determine participant_id
        participant_id <- if (i == 1) "ref" else paste0("part_", i - 1)
        
        # Create a data frame for the current replicate
        df <- data.frame(
          pollutant = pollutant_name,
          level = lvl,
          replicate = i,
          participant_id = rep(participant_id, num_samples),
          sample_id = 1:num_samples,
          value = replicate_samples
        )
        
        # Add the data frame to the list
        all_samples_list_n <- append(all_samples_list_n, list(df))
      }
    }
  }

  # Combine all data frames into one for the current n
  final_samples_df_n <- do.call(rbind, all_samples_list_n)

  # Save the final dataframe to a CSV file
  output_filename <- paste0("bsw_sampler_output_n", n, ".csv")
  write.csv(final_samples_df_n, output_filename, row.names = FALSE)
}
