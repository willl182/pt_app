source(testthat::test_path("../../R/preprocessing/hourly_averages.R"))
source(testthat::test_path("../../data_use_cases/scripts/build_generalized_pt.R"))

project_root <- normalizePath(testthat::test_path("../.."), mustWork = TRUE)

test_that("plateau detection orders baseline and four concentrations", {
  set.seed(42)
  values <- c(
    rnorm(30, 0, 0.03), rnorm(35, 6, 0.03), rnorm(35, 4, 0.03),
    rnorm(35, 2.5, 0.03), rnorm(35, 1, 0.03)
  )
  result <- detect_five_plateaus(values)

  expect_equal(length(result$centers), 5L)
  expect_true(all(diff(result$centers) > 0))
  expect_equal(sort(unique(result$level)), 1:5)
  expect_true(all(result$counts >= 10L))
})

test_that("CO and SO2 participant data map to five ascending R1 levels", {
  r1 <- do.call(rbind, lapply(c("R1_CO.csv", "R1_SO2.csv"), function(file) {
    assign_round_roles(
      summarise_round_file(file.path(project_root, "data_use_cases", "data", "raw", file), "test_r1"),
      keep_participants = FALSE
    )
  }))
  participants <- add_nominal_levels(
    summarise_co_so2_participant(file.path(project_root, "data_use_cases", "R_r", "Datos R&R Jaison CO y SO2 JUL 2.txt")),
    r1
  )

  expect_equal(as.integer(table(participants$pollutant)), c(5L, 5L))
  expect_identical(unique(participants$participant_id), "Jaison")
  expect_true(all(grepl("^[0-9]+(\\.[0-9]+)?-", participants$level)))
  expect_setequal(unique(participants$unit), c("µmol/mol", "nmol/mol"))
})

test_that("synthetic second reference is deterministic and retains levels", {
  reference1 <- data.frame(
    pollutant = rep("co", 2), level = c("0-µmol/mol", "1-µmol/mol"),
    mean_value = c(0.01, 1), mean_h1 = c(0.01, 1), mean_h2 = NA_real_,
    mean_h3 = NA_real_, sd_value = c(0.01, 0.02), u_value = c(0.002, 0.003),
    instrument = "4U_REAL", serial = "4U_REAL", participant_id = "ref",
    source = "r1", run = 1:2, tipo = "referencia",
    reference_role = "ref1", simulated = FALSE, stringsAsFactors = FALSE
  )

  first <- make_synthetic_reference(reference1)
  second <- make_synthetic_reference(reference1)
  expect_identical(first, second)
  expect_equal(first$level, reference1$level)
  expect_true(all(grepl("^4U_SYNTH_", first$serial)))
  expect_false(identical(first$mean_value, reference1$mean_value))
})

test_that("generalized pipeline emits the requested pt_app contract", {
  output <- tempfile(fileext = ".csv")
  result <- build_generalized_pt(project_root, output)
  written <- read.csv(output, stringsAsFactors = FALSE, check.names = FALSE)

  expect_true(file.exists(output))
  expect_equal(nrow(written), nrow(result))
  expect_true(validate_generalized_pt(result))
  expect_equal(nrow(result), 90L)
  expect_equal(
    vapply(c("co", "so2", "o3", "no", "no2"), function(p) {
      length(unique(result$participant_id[result$pollutant == p & result$tipo == "participante"]))
    }, integer(1)),
    c(co = 1L, so2 = 1L, o3 = 2L, no = 2L, no2 = 2L)
  )
  references <- result[result$tipo == "referencia", ]
  expect_true(all(vapply(split(references, references$pollutant), function(x) {
    length(unique(x$serial)) == 2L
  }, logical(1))))
  expect_true(all(grepl("^[0-9]+(\\.[0-9]+)?-", result$level)))
  expect_true(all(is.finite(result$u_value)))
  expect_true(all(is.finite(result$u_exp)))
  expect_true(all(result$k_factor == 2))
  expect_setequal(unique(result$uncertainty_round), c("R1", "R2A", "R2B", "R2C", "R3"))
  expect_setequal(unique(references$reference_role), c("ref1", "ref2"))
  expect_true(all(references$simulated[references$pollutant %in% c("co", "so2") & references$reference_role == "ref2"]))
  expect_false(any(references$simulated[references$pollutant %in% c("no", "no2", "o3")]))
})
