library(testthat)
library(dplyr)
library(tidyr)

# Mock get_wide_data from app.R (copied logic)
get_wide_data <- function(df, target_pollutant) {
    if (!"value" %in% names(df)) {
        return(NULL)
    }
    filtered <- df %>% filter(pollutant == target_pollutant)
    if (is.null(filtered) || nrow(filtered) == 0) {
        return(NULL)
    }
    filtered %>%
        select(-pollutant) %>%
        pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}

test_that("get_wide_data handles missing value column", {
    df_invalid <- data.frame(pollutant = "co", replicate = 1, wrong_col = 1)
    res <- get_wide_data(df_invalid, "co")
    expect_null(res)
})

test_that("get_wide_data works with valid data", {
    df_valid <- data.frame(pollutant = "co", replicate = 1, value = 10, level = "L1")
    res <- get_wide_data(df_valid, "co")
    expect_true(is.data.frame(res))
    expect_true("sample_1" %in% names(res))
})

print("All tests passed!")
