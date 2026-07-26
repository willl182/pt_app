source(testthat::test_path("../../data_use_cases/scripts/build_r3_pt_app.R"))

make_r3_summary <- function(instruments = c("ZFT5R6", "4UDY72")) {
  rows <- expand.grid(
    instrument = instruments,
    run = c(1L, 3L),
    stringsAsFactors = FALSE
  )
  rows$source <- "ronda3_raw"
  rows$pollutant <- "no2"
  rows$level <- ifelse(rows$run == 1L, "1", "2")
  rows$unit <- "nmol/mol"
  rows$mean_h1 <- ifelse(rows$run == 1L, 0, 144)
  rows$mean_h2 <- NA_real_
  rows$mean_h3 <- NA_real_
  rows$mean_value <- rows$mean_h1
  rows$sd_value <- 0.1
  rows$u_value <- 0.05
  rows$n_hours <- 1L
  rows$hour_starts <- "2026-07-15 08:00:00"
  rows[c(
    "source", "run", "pollutant", "level", "unit", "instrument",
    "mean_h1", "mean_h2", "mean_h3", "mean_value", "sd_value",
    "u_value", "n_hours", "hour_starts"
  )]
}

make_r3_capacity <- function(gen_nominal = c(0, 144)) {
  data.frame(
    pollutant = "no2",
    run = c(1L, 3L),
    level = c("1", "2"),
    gen_nominal = gen_nominal,
    stringsAsFactors = FALSE
  )
}

make_complete_r3 <- function(n_participants = 1L) {
  participant_ids <- paste0("LAB", seq_len(n_participants))
  participants <- expand.grid(
    participant_id = participant_ids,
    level = c("0-nmol/mol", "144-nmol/mol"),
    stringsAsFactors = FALSE
  )
  participants$pollutant <- "no2"
  participants$mean_value <- ifelse(participants$level == "0-nmol/mol", 0, 144)
  participants$u_value <- 0.05
  participants$tipo <- "participante"
  participants$n_lab <- n_participants

  reference <- data.frame(
    participant_id = "calaire_ref",
    level = c("0-nmol/mol", "144-nmol/mol"),
    pollutant = "no2",
    mean_value = c(-0.335, 144),
    u_value = 0.05,
    tipo = "referencia",
    n_lab = n_participants,
    stringsAsFactors = FALSE
  )

  rbind(participants, reference)
}

run_consolidator <- function(summary, capacity = make_r3_capacity()) {
  temp_dir <- tempfile("r3-builder-")
  dir.create(temp_dir)
  summary_path <- file.path(temp_dir, "summary.csv")
  capacity_path <- file.path(temp_dir, "capacity.csv")
  participants_path <- file.path(temp_dir, "participants.csv")
  reference_path <- file.path(temp_dir, "reference.csv")
  output_path <- file.path(temp_dir, "complete.csv")

  write.csv(summary, summary_path, row.names = FALSE, na = "NA")
  write.csv(capacity, capacity_path, row.names = FALSE, na = "NA")
  build_r3_pt_app(summary_path, capacity_path, participants_path, reference_path)

  consolidator <- testthat::test_path("../../scripts/aplicativo/consolidar_ronda_pt_app.R")
  command_output <- system2(
    "Rscript",
    c(consolidator, "3", participants_path, reference_path, output_path),
    stdout = TRUE,
    stderr = TRUE
  )
  expect_null(attr(command_output, "status"), info = paste(command_output, collapse = "\n"))

  list(
    complete = read.csv(output_path, stringsAsFactors = FALSE, check.names = FALSE),
    participants_path = participants_path
  )
}

test_that("builder assigns deterministic nominal levels", {
  result <- join_nominal_levels(make_r3_summary(), make_r3_capacity())

  expect_setequal(result$level, c("0-nmol/mol", "144-nmol/mol"))
  expect_equal(unique(result$level[result$run == 3L]), "144-nmol/mol")
  expect_equal(format_nominal(143.99666), "144")
  expect_equal(format_nominal(1e-04), "0")
  expect_error(format_nominal(-0.03), "gen_nominal negativo")
  expect_error(format_nominal(c(NA_real_, Inf)), "gen_nominal no finito")
})

test_that("builder merge ignores unrelated capacity columns", {
  capacity <- make_r3_capacity()
  capacity$unit <- "ppb"
  capacity$n_hours <- 99L

  result <- join_nominal_levels(make_r3_summary(), capacity)

  expect_setequal(result$level, c("0-nmol/mol", "144-nmol/mol"))
  expect_equal(unique(result$unit), "nmol/mol")
  expect_false(any(grepl("_capacity$|_summary$", names(result))))
})

test_that("builder splits roles by case-insensitive 4U prefix", {
  summary <- make_r3_summary(c("RANDOM9", "4uRef9"))
  result <- split_r3_roles(join_nominal_levels(summary, make_r3_capacity()))

  expect_equal(unique(result$participants$participant_id), "RANDOM9")
  expect_equal(unique(result$participants$tipo), "participante")
  expect_equal(unique(result$participants$source), "ronda_participante")
  expect_equal(unique(result$reference$serial), "4uRef9")
  expect_equal(unique(result$reference$instrument), "calaire_ref")
  expect_equal(unique(result$reference$participant_id), "calaire_ref")
  expect_equal(unique(result$reference$tipo), "referencia")
})

test_that("builder requires reference and participant roles", {
  no_reference <- make_r3_summary(c("ABC123", "XYZ789"))
  expect_error(
    split_r3_roles(no_reference),
    "exactamente 1 serial.*encontrados: 0"
  )

  two_references <- make_r3_summary(c("4UAAAA", "4UBBBB", "ABC123"))
  expect_error(
    split_r3_roles(two_references),
    "exactamente 1 serial.*encontrados: 2"
  )

  only_reference <- make_r3_summary("4UDY72")
  expect_error(
    split_r3_roles(only_reference),
    "No se encontraron filas de participante"
  )
})

test_that("builder rejects ambiguous, orphan, and mismatched nominal maps", {
  duplicate <- make_r3_capacity()
  conflicting <- duplicate[2, , drop = FALSE]
  conflicting$gen_nominal <- 145
  duplicate <- rbind(duplicate, conflicting)
  expect_error(
    build_nominal_map(duplicate),
    "Mapa nominal ambiguo.*no2/3"
  )

  orphan <- make_r3_summary()
  orphan$run[1] <- 99L
  expect_error(
    join_nominal_levels(orphan, make_r3_capacity()),
    "Sin nivel nominal.*no2/99"
  )

  mismatch <- make_r3_summary()
  mismatch$level[mismatch$run == 3L] <- "3"
  expect_error(
    join_nominal_levels(mismatch, make_r3_capacity()),
    "Nivel ordinal no coincide"
  )
})

test_that("validate_r3_output enforces final contract", {
  complete <- make_complete_r3()

  expect_true(validate_r3_output(complete, expected_levels = 2L))

  missing_level <- complete[complete$level != "144-nmol/mol", , drop = FALSE]
  expect_error(
    validate_r3_output(missing_level, expected_levels = 2L),
    "Conteo de niveles inesperado"
  )
  expect_true(validate_r3_output(missing_level, expected_levels = 1L))

  bad_level <- complete
  bad_level$level[1] <- "nivel-1"
  expect_error(
    validate_r3_output(bad_level, expected_levels = 2L),
    "Niveles no nominales"
  )

  missing_type <- complete[complete$tipo == "participante", , drop = FALSE]
  expect_error(
    validate_r3_output(missing_type, expected_levels = 2L),
    "Tipos ausentes.*referencia"
  )

  bad_n_lab <- complete
  bad_n_lab$n_lab <- 2L
  expect_error(
    validate_r3_output(bad_n_lab, expected_levels = 2L),
    "n_lab distinto de 1"
  )

  missing_uncertainty <- complete
  missing_uncertainty$u_value[1] <- NA_real_
  expect_error(
    validate_r3_output(missing_uncertainty, expected_levels = 2L),
    "NA en mean_value/u_value"
  )
})

test_that("validate_r3_output warns about reference deviation except zero level", {
  complete <- make_complete_r3()
  complete$mean_value[complete$tipo == "referencia" & complete$level == "144-nmol/mol"] <- 153.988

  expect_warning(
    validate_r3_output(complete, expected_levels = 2L),
    "se aparta >5%.*no2 144-nmol/mol"
  )

  complete$mean_value[complete$tipo == "referencia" & complete$level == "144-nmol/mol"] <- 144
  expect_no_warning(validate_r3_output(complete, expected_levels = 2L))
})

test_that("builder output is accepted by pt_app consolidator", {
  result <- run_consolidator(make_r3_summary())
  complete <- result$complete

  expect_equal(nrow(complete), 4L)
  expect_true(validate_r3_output(complete, expected_levels = 2L, expected_n_lab = 1L))
  participant_lines <- readLines(result$participants_path)
  expect_false(any(grepl(",NA,|,NA$", participant_lines)))
})

test_that("builder supports multiple participants and consolidator reports n_lab", {
  result <- run_consolidator(make_r3_summary(c("LAB001", "LAB002", "4UDY72")))
  complete <- result$complete

  expect_equal(nrow(complete), 6L)
  expect_setequal(
    unique(complete$participant_id[complete$tipo == "participante"]),
    c("LAB001", "LAB002")
  )
  expect_true(validate_r3_output(complete, expected_levels = 2L, expected_n_lab = 2L))
})
