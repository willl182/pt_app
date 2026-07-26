source(testthat::test_path("../../R/preprocessing/hourly_averages.R"))

make_runtime_raw <- function(blocks, pollutant = "o3") {
  level <- unlist(Map(function(x, n) rep(x, n), names(blocks), blocks), use.names = FALSE)
  runtime_min <- seq_along(level) - 1L
  gen_value <- suppressWarnings(as.numeric(level) * 10)
  gen_value[level == "1"] <- 0
  gen_value[level == "estab"] <- NA_real_
  out <- data.frame(
    timestamp = as.POSIXct("2026-07-15 08:00:00", tz = "America/Bogota") + runtime_min * 60,
    runtime_min = runtime_min,
    level = level,
    gen_value = gen_value,
    stringsAsFactors = FALSE
  )
  col <- paste0(pollutant, "_ABC123")
  out[[col]] <- runtime_min
  attr(out, "pollutant") <- pollutant
  attr(out, "instrument_cols") <- col
  attr(out, "instrument_serials") <- "ABC123"
  attr(out, "file") <- "synthetic.csv"
  out
}

test_that("raw R3 parser handles runtime over 24 hours and wall-clock 24:00", {
  path <- tempfile(fileext = ".csv")
  writeLines(c(
    "date time,o3_ABC123,runtime,level,o3_gen",
    "07/15/26 24:00,1.5,24:00,1,0",
    "07/16/26 01:30,2.5,25:30,2,20"
  ), path)

  raw <- read_raw_round_file(path)

  expect_equal(raw$runtime_min, c(1440L, 1530L))
  expect_equal(format(raw$timestamp[1], "%Y-%m-%d %H:%M"), "2026-07-16 00:00")
  expect_equal(attr(raw, "pollutant"), "o3")
  expect_equal(attr(raw, "instrument_cols"), "o3_ABC123")

  writeLines(c(
    "date time,o3_ABC123,runtime,level,o3_gen",
    "07/15/26 12:00,1.5,-1:30,1,0"
  ), path)
  expect_error(read_raw_round_file(path), "Invalid runtime")
})

test_that("capacity excludes stabilization and applies 45-minute residual rule", {
  raw <- make_runtime_raw(c("1" = 60, "estab" = 10, "2" = 170, "3" = 171))
  capacity <- assess_hourly_capacity(raw)

  expect_equal(capacity$level, c("1", "2", "3"))
  expect_equal(capacity$n_minutes, c(60L, 170L, 171L))
  expect_equal(capacity$n_computable_hours, c(1L, 3L, 3L))
  expect_true(all(capacity$meets_min_hours))
})

test_that("50-minute partial hour counts and carries n flag", {
  raw <- make_runtime_raw(c("2" = 170))
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(nrow(hourly), 3L)
  expect_equal(hourly$n, c(60L, 60L, 50L))
  expect_match(hourly$validation_flags[3], "n=50", fixed = TRUE)
  expect_true(all(hourly$valid_hour))
})

test_that("partial chunks below 45 minutes are discarded", {
  raw <- make_runtime_raw(c("2" = 104))
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(nrow(hourly), 1L)
  expect_equal(hourly$n, 60L)
  expect_match(hourly$validation_flags, "below_min_hours", fixed = TRUE)
})

test_that("105-minute non-zero block meets two-hour minimum", {
  raw <- make_runtime_raw(c("2" = 105))
  capacity <- assess_hourly_capacity(raw)
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(capacity$n_computable_hours, 2L)
  expect_true(capacity$meets_min_hours)
  expect_equal(hourly$n, c(60L, 45L))
  expect_false(any(grepl("below_min_hours", hourly$validation_flags, fixed = TRUE)))
})

test_that("100-minute non-zero block is flagged below minimum", {
  raw <- make_runtime_raw(c("2" = 100))
  capacity <- assess_hourly_capacity(raw)
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(capacity$n_computable_hours, 1L)
  expect_false(capacity$meets_min_hours)
  expect_equal(nrow(hourly), 1L)
  expect_match(hourly$validation_flags, "below_min_hours", fixed = TRUE)
})

test_that("runtime gaps determine chunk boundaries consistently", {
  raw <- make_runtime_raw(c("2" = 90))
  raw$runtime_min <- c(0:44, 60:104)
  capacity <- assess_hourly_capacity(raw)
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(capacity$n_minutes, 90L)
  expect_equal(capacity$runtime_span, 105L)
  expect_equal(capacity$n_computable_hours, 2L)
  expect_equal(capacity$n_reported_hours, 2L)
  expect_true(capacity$meets_min_hours)
  expect_equal(nrow(hourly), 2L)
  expect_equal(hourly$n, c(45L, 45L))
  expect_equal(hourly$runtime_start, c(0L, 60L))
})

test_that("chunk retention is separate from instrument validity", {
  raw <- make_runtime_raw(c("2" = 60))
  raw$o3_ABC123[31:60] <- NA_real_
  raw$o3_DEF456 <- raw$runtime_min
  attr(raw, "instrument_cols") <- c("o3_ABC123", "o3_DEF456")
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(nrow(hourly), 2L)
  expect_equal(hourly$n, c(30L, 60L))
  expect_equal(hourly$valid_hour, c(FALSE, TRUE))
  expect_true(all(is.na(hourly[1, c("mean_value", "sd_value", "u_value")])))
  expect_match(hourly$validation_flags[1], "n=30", fixed = TRUE)
  expect_match(hourly$validation_flags[1], "less_than_75pct", fixed = TRUE)
})

test_that("max-hours cap is applied before short chunks are filtered", {
  raw <- make_runtime_raw(c("2" = 210))
  raw$runtime_min <- c(0:59, 60:89, 120:179, 180:239)
  hourly <- compute_hourly_averages_runtime(raw, max_hours = 3L)

  expect_equal(nrow(hourly), 2L)
  expect_equal(hourly$runtime_start, c(0L, 120L))
  expect_false(any(hourly$runtime_start == 180L))
  expect_false(any(grepl("below_min_hours", hourly$validation_flags, fixed = TRUE)))
})

test_that("zero level reports only first hour", {
  raw <- make_runtime_raw(c("1" = 180))
  capacity <- assess_hourly_capacity(raw)
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(capacity$n_computable_hours, 3L)
  expect_equal(capacity$n_reported_hours, 1L)
  expect_true(capacity$meets_min_hours)
  expect_equal(nrow(hourly), 1L)
  expect_equal(hourly$runtime_start, 0L)
})

test_that("assessment distinguishes computable and reported hours", {
  raw <- make_runtime_raw(c("2" = 240))
  capacity <- assess_hourly_capacity(raw, max_hours = 3L)
  hourly <- compute_hourly_averages_runtime(raw, max_hours = 3L)

  expect_equal(capacity$n_computable_hours, 4L)
  expect_equal(capacity$n_reported_hours, 3L)
  expect_equal(nrow(hourly), 3L)
})

test_that("generated nominal uses block mode instead of mean", {
  raw <- make_runtime_raw(c("2" = 120))
  raw$gen_value <- c(rep(20, 90), rep(25, 30))
  capacity <- assess_hourly_capacity(raw)
  hourly <- compute_hourly_averages_runtime(raw)

  expect_equal(capacity$gen_nominal, 20)
  expect_equal(unique(hourly$generated_nominal), 20)
  expect_true(any(hourly$generated_mean != hourly$generated_nominal))
})

test_that("runtime output works with reference level summary", {
  raw <- make_runtime_raw(c("1" = 60, "estab" = 10, "2" = 170))
  hourly <- compute_hourly_averages_runtime(raw)
  summary <- summarise_reference_levels(hourly)

  expect_equal(summary$n_hours, c(1L, 3L))
  expect_equal(summary$source, rep("ronda3_raw", 2))
  expect_equal(summary$instrument, rep("ABC123", 2))
})
