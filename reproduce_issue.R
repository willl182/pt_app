library(tidyverse)
library(vroom)

# Test reading summary files
summary_files <- list.files("data", pattern = "summary_n\\d+\\.csv", full.names = TRUE)
print(paste("Found summary files:", length(summary_files)))

data_list <- lapply(summary_files, function(f) {
    print(paste("Reading", f))
    df <- vroom::vroom(f, show_col_types = FALSE)
    print(names(df))
    n <- as.integer(stringr::str_extract(basename(f), "\\d+"))
    df$n_lab <- n
    return(df)
})

raw_data <- do.call(rbind, data_list)
print("Combined raw_data names:")
print(names(raw_data))

# Test group_by
tryCatch(
    {
        res <- raw_data %>%
            group_by(participant_id, pollutant, level, n_lab) %>%
            summarise(
                mean_value = mean(mean_value, na.rm = TRUE),
                sd_value = mean(sd_value, na.rm = TRUE),
                .groups = "drop"
            )
        print("group_by successful")
        print(head(res))
    },
    error = function(e) {
        print(paste("group_by failed:", e$message))
    }
)

# Test reading homogeneity file
hom_file <- "data/homogeneity.csv"
print(paste("Reading", hom_file))
hom_df <- vroom::vroom(hom_file, show_col_types = FALSE)
print(names(hom_df))

# Test get_wide_data logic
get_wide_data <- function(df, target_pollutant) {
    filtered <- df %>% filter(pollutant == target_pollutant)
    if (is.null(filtered) || nrow(filtered) == 0) {
        return(NULL)
    }
    filtered %>%
        select(-pollutant) %>%
        pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}

tryCatch(
    {
        wide <- get_wide_data(hom_df, "co")
        print("get_wide_data successful")
        print(head(wide))
    },
    error = function(e) {
        print(paste("get_wide_data failed:", e$message))
    }
)
