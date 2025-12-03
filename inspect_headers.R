library(vroom)
library(dplyr)

files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)

for (f in files) {
    cat("\n--------------------------------------------------\n")
    cat("File:", basename(f), "\n")

    # Read with default settings (similar to app)
    tryCatch(
        {
            df <- vroom(f, show_col_types = FALSE, progress = FALSE)
            cat("Dimensions:", paste(dim(df), collapse = " x "), "\n")
            cat("Column names:\n")
            print(colnames(df))

            # Check for specific columns
            required_cols <- c("participant_id", "pollutant", "level", "value")
            missing <- setdiff(required_cols, colnames(df))
            if (length(missing) > 0) {
                cat("MISSING columns:", paste(missing, collapse = ", "), "\n")
            } else {
                cat("All required columns present (for basic checks).\n")
            }

            # Check first few rows
            print(head(df, 3))
        },
        error = function(e) {
            cat("ERROR reading file:", e$message, "\n")
        }
    )
}
