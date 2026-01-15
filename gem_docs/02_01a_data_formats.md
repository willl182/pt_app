# Data Formats & Transformation

This document details the required data schemas and the internal transformation logic used to prepare data for statistical analysis.

## 1. Complete CSV Schema Reference

### 1.1 Homogeneity & Stability Data
Used for `homogeneity.csv` and `stability.csv`. This format represents "Long Format" data where each row is a single measurement.

| Column | Required | Type | Description | Example |
|:-------|:--------:|:-----|:------------|:--------|
| `pollutant` | Yes | String | Analyte identifier | `CO`, `NO2`, `SO2` |
| `level` | Yes | String | Concentration level | `low`, `high` |
| `replicate` | No* | Integer | Replicate number (1 or 2) | `1` |
| `value` | Yes | Float | Measurement result | `0.0523` |
| `date` | No | Date | Measurement date | `2023-10-01` |

*\*While `replicate` is not strictly checked by the validator, it is essential for the logic of `pivot_wider` in `get_wide_data`. If missing, transformation may fail or produce unexpected results.*

### 1.2 Participant Summary Data
Used for `summary_n*.csv`. Represents aggregated results from participants.

| Column | Required | Type | Description | Example |
|:-------|:--------:|:-----|:------------|:--------|
| `participant_id` | Yes | String | Unique lab identifier | `LAB_001` |
| `pollutant` | Yes | String | Analyte identifier | `CO` |
| `level` | Yes | String | Concentration level | `medium` |
| `mean_value` | Yes | Float | Reported mean | `10.5` |
| `sd_value` | Yes | Float | Reported standard deviation | `0.2` |

## 2. Data Transformation Pipeline

The application stores data in "Long Format" but requires "Wide Format" for ANOVA calculations (ISO 13528). This transformation is handled by `get_wide_data()`.

### The `get_wide_data()` Function
**Source Location:** `cloned_app.R` (lines 227-238)

```r
get_wide_data <- function(df, target_pollutant) {
  filtered <- df %>% filter(pollutant == target_pollutant)
  
  # Return NULL if no data found
  if (is.null(filtered) || nrow(filtered) == 0) {
    return(NULL)
  }
  
  # Return NULL if critical column missing
  if (!"value" %in% names(filtered)) {
    return(NULL)
  }
  
  # Pivot to Wide Format
  filtered %>%
    select(-pollutant) %>%
    pivot_wider(
      names_from = replicate, 
      values_from = value, 
      names_prefix = "sample_"
    )
}
```

### Transformation Example

**Input (Long Format):**
```
pollutant  level  replicate  value
SO2        low    1          0.05
SO2        low    2          0.06
SO2        high   1          0.10
SO2        high   2          0.11
```

**Operation:** `get_wide_data(df, "SO2")`

**Output (Wide Format):**
```
level  sample_1  sample_2
low    0.05      0.06
high   0.10      0.11
```

## 3. Sample Data Generator Script

Use this R script to generate valid dummy data for testing the application.

```r
# Generate Homogeneity Data
pollutants <- c("CO", "NO", "SO2")
levels <- c("low", "medium", "high")
n_items <- 10

hom_data <- expand.grid(
  pollutant = pollutants,
  level = levels,
  item = 1:n_items,
  replicate = 1:2
)

hom_data$value <- runif(nrow(hom_data), 10, 20) # Random values

write.csv(hom_data, "homogeneity_dummy.csv", row.names = FALSE)
```
