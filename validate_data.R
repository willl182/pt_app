library(vroom)
library(dplyr)

# Check Homogeneity
cat("Checking Homogeneity Data...\n")
hom_file <- "data/homogeneity.csv"
if (file.exists(hom_file)) {
    df <- vroom(hom_file, show_col_types = FALSE)
    if (!"value" %in% colnames(df)) {
        cat("FAIL: homogeneity.csv missing 'value' column\n")
    } else {
        cat("PASS: homogeneity.csv has 'value' column\n")
    }
} else {
    cat("homogeneity.csv not found\n")
}

# Check Stability
cat("\nChecking Stability Data...\n")
stab_file <- "data/stability.csv"
if (file.exists(stab_file)) {
    df <- vroom(stab_file, show_col_types = FALSE)
    if (!"value" %in% colnames(df)) {
        cat("FAIL: stability.csv missing 'value' column\n")
    } else {
        cat("PASS: stability.csv has 'value' column\n")
    }
} else {
    cat("stability.csv not found\n")
}

# Check Summary Files
cat("\nChecking Summary Files...\n")
summary_files <- list.files("data", pattern = "summary_n\\d+\\.csv", full.names = TRUE)
expected_cols <- c("participant_id", "pollutant", "level")

for (f in summary_files) {
    df <- vroom(f, show_col_types = FALSE)
    missing <- setdiff(expected_cols, colnames(df))
    if (length(missing) > 0) {
        cat("FAIL:", basename(f), "missing columns:", paste(missing, collapse = ", "), "\n")
    } else {
        # cat("PASS:", basename(f), "\n")
    }
}
cat("Finished checking summary files.\n")
