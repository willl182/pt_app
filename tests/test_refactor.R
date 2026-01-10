source("R/core_statistics.R")
source("R/data_prep.R")
source("R/homogeneity_stability.R")
source("R/scores.R")

test_that <- function(desc, code) {
  cat(paste("Running test:", desc, "... "))
  tryCatch({
    code()
    cat("PASS\n")
  }, error = function(e) {
    cat("FAIL: ", conditionMessage(e), "\n")
  })
}

test_that("Core Statistics - nIQR", {
  x <- c(1, 2, 3, 4, 5, 100) # 100 is outlier
  val <- calculate_niqr(x)
  if (is.na(val) || val <= 0) stop("nIQR calculation failed")
})

test_that("Core Statistics - Algo A", {
  vals <- c(10, 10.1, 9.9, 10.2, 50.0) # 50 is outlier
  ids <- paste0("Lab", 1:5)
  res <- run_algorithm_a(vals, ids)
  if (!is.null(res)) stop(res)
  if (abs(res - 10) > 0.5) stop("Algo A assigned value too high")
})

test_that("Homogeneity Metrics", {
  # Mock data
  df <- data.frame(
    pollutant = "CO", level = "L1", replicate = rep(c("sample_1", "sample_2"), 10),
    value = rnorm(20, 10, 0.1)
  )
  res <- compute_homogeneity_metrics("CO", "L1", df)
  if (!is.null(res)) stop(res)
  if (!res && !res) warning("Random data failed homogeneity (expected usually)")
})

test_that("Scores Metrics", {
  # Mock Summary Data
  df <- data.frame(
    pollutant = "CO", level = "L1", n_lab = 5,
    participant_id = c("ref", "L1", "L2", "L3", "L4"),
    mean_value = c(10, 10.1, 9.9, 10.5, 12),
    sd_value = c(0.1, 0.2, 0.2, 0.2, 0.5)
  )
  res <- compute_scores_metrics(df, "CO", 5, "L1", 0.5, 0.1, 2)
  if (!is.null(res)) stop(res)
  # Check if z-scores calculated
  if (!"z_score" %in% names(res)) stop("z_score missing")
})

cat("Tests completed.\n")
