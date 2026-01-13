library(testthat)

context("Entregable 06 - Lógica de negocio")

test_that("Resultados clave coinciden con la verificación", {
  source("../app_v06.R", local = TRUE)

  hom_res <- compute_homogeneity_metrics(hom_data, "co", "2-μmol/mol")
  stab_res <- compute_stability_metrics(stab_data, "co", "2-μmol/mol", hom_res)

  assigned_vals <- compute_assigned_values(summary_data)
  ref_row <- assigned_vals %>%
    filter(Contaminante == "co", Nivel == "2-μmol/mol", Metodo == "Referencia (1)")

  params <- get_assigned_params(summary_data, "co", 4, "2-μmol/mol", "Referencia (1)")
  scores_res <- compute_scores_metrics(
    summary_df = summary_data,
    target_pollutant = "co",
    target_n_lab = 4,
    target_level = "2-μmol/mol",
    sigma_pt = params$sigma_pt,
    u_xpt = params$u_xpt,
    k = 2,
    m = 1
  )
  part1 <- scores_res$scores %>% filter(participant_id == "part_1")

  results_df <- data.frame(
    Metrica = c("hom_ss", "stab_diff", "xpt_ref", "z_part1"),
    Valor = c(hom_res$ss, stab_res$diff_hom_stab, ref_row$x_pt[1], part1$z_score[1])
  )

  expected <- read.csv("test_06_logica.csv", stringsAsFactors = FALSE)
  expect_equal(round(results_df$Valor, 6), round(expected$Valor, 6))
})
