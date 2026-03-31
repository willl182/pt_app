#!/usr/bin/env Rscript

# ===================================================================
# Build homogeneity and stability datasets from summary_n*.csv files
#
# Output format follows data/h.csv and data/stability.csv:
# pollutant,run,level,replicate,sample_id,value
#
# Rule used for both homogeneity and stability:
#   - sample_group "1-10"  -> replicate 1
#   - sample_group "11-20" -> replicate 2
# ===================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

build_dataset <- function(path) {
  summary_df <- readr::read_csv(path, show_col_types = FALSE)

  summary_df %>%
    filter(sample_group %in% c("1-10", "11-20")) %>%
    mutate(
      replicate = dplyr::case_when(
        sample_group == "1-10" ~ 1L,
        sample_group == "11-20" ~ 2L
      )
    ) %>%
    arrange(pollutant, run, level, participant_id, replicate) %>%
    group_by(pollutant, run, level) %>%
    mutate(sample_id = match(participant_id, unique(participant_id))) %>%
    ungroup() %>%
    transmute(
      pollutant = pollutant,
      run = run,
      level = level,
      replicate = replicate,
      sample_id = sample_id,
      value = mean_value
    ) %>%
    arrange(pollutant, run, level, replicate, sample_id)
}

summary_files <- c(
  "data/summary_n4.csv",
  "data/summary_n7.csv",
  "data/summary_n10.csv",
  "data/summary_n13.csv"
)

for (path in summary_files) {
  n_value <- sub("^.*summary_n([0-9]+)\\.csv$", "\\1", path)
  dataset <- build_dataset(path)

  readr::write_csv(dataset, file = sprintf("data/homogeneity_n%s.csv", n_value))
  readr::write_csv(dataset, file = sprintf("data/stability_n%s.csv", n_value))
}
