test_that("final scores export maps report combos to flat CSV schema", {
  source(testthat::test_path("../../R/export_final_scores.R"))

  report_data <- list(
    error = NULL,
    combos = data.frame(
      participant_id = c("lab-01", "ref"),
      pollutant = c("NO2", "NO2"),
      n_lab = c("1", "1"),
      level = c("0-umol/mol", "0-umol/mol"),
      combination_label = c("1", "1"),
      x_pt = c(10, 10),
      u_xpt_def = c(0.2, 0.2),
      sigma_pt = c(1.5, 1.5),
      result = c(11, 10),
      uncertainty_std = c(0.3, 0.1),
      U_xi = c(0.6, 0.2),
      z_score = c(0.67, 0),
      z_prime_score = c(0.66, 0),
      zeta_score = c(2.77, 0),
      En_score = c(1.58, 0),
      z_score_eval = c("Satisfactorio", "Satisfactorio"),
      stringsAsFactors = FALSE
    )
  )

  export_df <- format_final_scores_export_df(report_data)

  expect_named(export_df, c(
    "participant_code", "contaminante", "run_code", "level_label",
    "unidad", "metodo", "valor_asignado", "u_xpt", "sigma_pt",
    "valor_participante", "u_lab", "U_lab", "z", "z_prima",
    "zeta", "en", "clasificacion"
  ))
  expect_equal(ncol(export_df), 17)
  expect_false("ref" %in% export_df$participant_code)
  expect_equal(export_df$unidad, "umol/mol")
})

test_that("final scores export returns NULL on error, empty or ref-only data", {
  source(testthat::test_path("../../R/export_final_scores.R"))

  expect_null(format_final_scores_export_df(NULL))
  expect_null(format_final_scores_export_df(list(error = "sin datos", combos = NULL)))
  expect_null(format_final_scores_export_df(list(error = NULL, combos = NULL)))
  expect_null(format_final_scores_export_df(list(error = NULL, combos = data.frame())))

  ref_only <- list(
    error = NULL,
    combos = data.frame(
      participant_id = "ref",
      pollutant = "NO2",
      n_lab = "1",
      level = "0-umol/mol",
      combination_label = "1",
      x_pt = 10,
      u_xpt_def = 0.2,
      sigma_pt = 1.5,
      result = 10,
      uncertainty_std = 0.1,
      U_xi = 0.2,
      z_score = 0,
      z_prime_score = 0,
      zeta_score = 0,
      En_score = 0,
      z_score_eval = "Satisfactorio",
      stringsAsFactors = FALSE
    )
  )
  expect_null(format_final_scores_export_df(ref_only))
})

test_that("final scores export handles N/A evaluations and levels without unit", {
  source(testthat::test_path("../../R/export_final_scores.R"))

  report_data <- list(
    error = NULL,
    combos = data.frame(
      participant_id = "lab-02",
      pollutant = "CO",
      n_lab = "4",
      level = "bajo",
      combination_label = "2a",
      x_pt = 5,
      u_xpt_def = 0.1,
      sigma_pt = 0.8,
      result = 5.4,
      uncertainty_std = NA_real_,
      U_xi = NA_real_,
      z_score = 0.5,
      z_prime_score = 0.5,
      zeta_score = NA_real_,
      En_score = NA_real_,
      z_score_eval = "N/A",
      stringsAsFactors = FALSE
    )
  )

  export_df <- format_final_scores_export_df(report_data)

  expect_equal(nrow(export_df), 1)
  expect_true(is.na(export_df$unidad))
  expect_equal(export_df$clasificacion, "N/A")
  expect_true(is.na(export_df$zeta))
  expect_true(is.na(export_df$en))
})
