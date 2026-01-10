# Data preparation helper functions

#' Convert data to wide format for Homogeneity/Stability analysis
#'
#' @param df Data frame with columns pollutant, replicate, value
#' @param target_pollutant The pollutant to filter for
#' @return Wide format data frame or NULL
get_wide_data <- function(df, target_pollutant) {
  filtered <- df %>% dplyr::filter(pollutant == target_pollutant)
  if (is.null(filtered) || nrow(filtered) == 0) {
    return(NULL)
  }
  if (!"value" %in% names(filtered)) {
    return(NULL)
  }
  filtered %>%
    dplyr::select(-pollutant) %>%
    tidyr::pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}
