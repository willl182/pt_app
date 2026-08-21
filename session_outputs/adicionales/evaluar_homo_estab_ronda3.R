#!/usr/bin/env Rscript

# ===================================================================
# Homogeneity and stability evaluation for round 3 (ISO 13528:2022).
#
# Consumes the bootstrap datasets produced by
# build_bootstrap_homogeneity_stability.R and reproduces the criteria
# app.R applies: sigma_pt from MADe of the homogeneity items,
# c = 0.3 * sigma_pt, plus the expanded variants.
#
# Run from the repository root.
# ===================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
})

source("R/pt_homogeneity.R")

blocks <- c("3a", "3b", "3c")
out_path <- "data_use_cases/data/processed/ronda_3_homogeneidad_estabilidad_resultados.csv"

to_wide <- function(df) {
  df |>
    dplyr::select("replicate", "sample_id", "value") |>
    tidyr::pivot_wider(
      names_from = "replicate",
      values_from = "value",
      names_prefix = "sample_"
    ) |>
    dplyr::arrange(.data$sample_id) |>
    dplyr::select(-"sample_id") |>
    as.data.frame()
}

rows <- list()

for (block in blocks) {
  hom <- readr::read_csv(
    sprintf("data_use_cases/data/processed/ronda_%s_homogeneidad.csv", block),
    show_col_types = FALSE, progress = FALSE
  )
  stb <- readr::read_csv(
    sprintf("data_use_cases/data/processed/ronda_%s_estabilidad.csv", block),
    show_col_types = FALSE, progress = FALSE
  )

  groups <- hom |>
    dplyr::distinct(.data$pollutant, .data$run, .data$level) |>
    dplyr::arrange(.data$pollutant, .data$run, .data$level)

  for (i in seq_len(nrow(groups))) {
    g <- groups[i, ]
    hom_g <- hom |>
      dplyr::filter(
        .data$pollutant == g$pollutant, .data$run == g$run, .data$level == g$level
      )
    stb_g <- stb |>
      dplyr::filter(
        .data$pollutant == g$pollutant, .data$run == g$run, .data$level == g$level
      )
    if (nrow(stb_g) == 0) next

    hs <- calculate_homogeneity_stats(to_wide(hom_g))
    if (!is.null(hs$error)) stop(hs$error, call. = FALSE)

    sigma_pt <- hs$sigma_pt
    c_hom <- calculate_homogeneity_criterion(sigma_pt)
    c_hom_exp <- calculate_homogeneity_criterion_expanded(sigma_pt, hs$sw, hs$g)
    hom_eval <- evaluate_homogeneity(hs$ss, c_hom, c_hom_exp)

    ss_stats <- calculate_stability_stats(
      to_wide(stb_g),
      hom_general_mean_homog = hs$general_mean_homog,
      hom_stab_x_pt = hs$x_pt,
      hom_stab_sigma_pt = sigma_pt
    )
    if (!is.null(ss_stats$error)) stop(ss_stats$error, call. = FALSE)

    u_hom <- calculate_u_hom(hs$ss)
    c_stab <- calculate_stability_criterion(sigma_pt)
    u_stab <- calculate_u_stab(ss_stats$diff_hom_stab, c_stab)
    c_stab_exp <- calculate_stability_criterion_expanded(c_stab, u_hom, u_stab)
    stab_eval <- evaluate_stability(ss_stats$diff_hom_stab, c_stab, c_stab_exp)

    rows[[length(rows) + 1L]] <- data.frame(
      bloque = block,
      pollutant = g$pollutant,
      run = g$run,
      level = g$level,
      g = hs$g,
      m = hs$m,
      media_general_hom = hs$general_mean_homog,
      x_pt = hs$x_pt,
      sigma_pt_MADe = sigma_pt,
      sw = hs$sw,
      ss = hs$ss,
      c_homogeneidad = c_hom,
      c_homogeneidad_ampliado = c_hom_exp,
      homogeneo = hom_eval$passes_criterion,
      homogeneo_ampliado = hom_eval$passes_expanded,
      media_general_estab = ss_stats$general_mean,
      diff_hom_estab = ss_stats$diff_hom_stab,
      c_estabilidad = c_stab,
      c_estabilidad_ampliado = c_stab_exp,
      estable = stab_eval$passes_criterion,
      estable_ampliado = stab_eval$passes_expanded,
      u_hom = u_hom,
      u_stab = u_stab,
      stringsAsFactors = FALSE
    )
  }
}

results <- dplyr::bind_rows(rows)
readr::write_csv(results, out_path)

print(
  results |>
    dplyr::transmute(
      .data$bloque, .data$pollutant, .data$run, .data$level,
      sigma_pt = round(.data$sigma_pt_MADe, 4),
      sw = round(.data$sw, 4),
      ss = round(.data$ss, 4),
      c = round(.data$c_homogeneidad, 4),
      c_amp = round(.data$c_homogeneidad_ampliado, 4),
      homog = .data$homogeneo,
      homog_amp = .data$homogeneo_ampliado,
      dif = round(.data$diff_hom_estab, 4),
      c_est_amp = round(.data$c_estabilidad_ampliado, 4),
      estab = .data$estable,
      estab_amp = .data$estable_ampliado
    ),
  row.names = FALSE
)
message("\nResultados -> ", out_path, " (", nrow(results), " filas)")
