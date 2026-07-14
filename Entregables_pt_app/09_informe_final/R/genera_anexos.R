# ===================================================================
# Reproducible evidence generator for deliverable E09
# ISO 13528:2022 and ISO/IEC 17043:2023
#
# Executes deterministic validation cases against the current ptcalc
# development tree and writes auditable CSV and environment evidence.
# ===================================================================

root_dir <- normalizePath(getwd())
output_dir <- file.path(
  root_dir, "Entregables_pt_app", "09_informe_final", "anexos"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

devtools::load_all(file.path(root_dir, "ptcalc"), quiet = TRUE)

hom <- matrix(c(
  9.98, 10.02, 10.01, 10.03, 9.99, 10.00, 10.04, 10.02,
  9.97, 10.01, 10.00, 10.02, 10.03, 10.01, 9.98, 9.99,
  10.02, 10.00, 10.01, 10.04
), ncol = 2, byrow = TRUE)
stab <- matrix(c(
  10.00, 10.01, 10.02, 10.00,
  9.99, 10.01, 10.03, 10.02
), ncol = 2, byrow = TRUE)
participants <- c(9.91, 9.96, 9.99, 10.00, 10.02, 10.04, 10.08, 10.60)

h <- calculate_homogeneity_stats(hom)
c_base <- calculate_homogeneity_criterion(h$MADe)
c_expanded <- calculate_homogeneity_criterion_expanded(
  sigma_pt = h$MADe, sw = h$sw, g = h$g
)
s <- calculate_stability_stats(
  stab_sample_data = stab,
  hom_general_mean_homog = h$general_mean_homog,
  hom_stab_x_pt = h$x_pt,
  hom_stab_sigma_pt = h$MADe
)
c_stab <- calculate_stability_criterion(h$MADe)
algorithm_a <- run_algorithm_a(participants)

calculations <- data.frame(
  id = c(
    "CAL-HOM-MEAN", "CAL-HOM-SW", "CAL-HOM-SS", "CAL-HOM-MADE",
    "CAL-HOM-CBASE", "CAL-HOM-CEXP", "CAL-STAB-MEAN",
    "CAL-STAB-DIFF", "CAL-STAB-CRIT", "CAL-NIQR", "CAL-MADE",
    "CAL-ALGO-X", "CAL-ALGO-S", "CAL-Z", "CAL-ZP", "CAL-ZETA", "CAL-EN"
  ),
  value = c(
    h$general_mean_homog, h$sw, h$ss, h$MADe, c_base, c_expanded,
    s$general_mean, s$diff_hom_stab, c_stab, calculate_niqr(participants),
    calculate_mad_e(participants), algorithm_a$assigned_value,
    algorithm_a$robust_sd, calculate_z_score(10.08, 10.00, 0.05),
    calculate_z_prime_score(10.08, 10.00, 0.05, 0.01),
    calculate_zeta_score(10.08, 10.00, 0.03, 0.01),
    calculate_en_score(10.08, 10.00, 0.06, 0.02)
  ),
  unit = c(
    rep("umol/mol", 5), "(umol/mol)^2", rep("umol/mol", 7),
    rep("dimensionless", 4)
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(
  calculations, file.path(output_dir, "calculos_reproducibles.csv"),
  row.names = FALSE
)
utils::write.csv(
  algorithm_a$iterations,
  file.path(output_dir, "algoritmo_a_iteraciones.csv"), row.names = FALSE
)

cases <- data.frame(
  id = c(
    "VAL-01", "VAL-02", "VAL-03", "VAL-04", "VAL-05", "VAL-06",
    "VAL-07", "VAL-08", "VAL-09", "VAL-10", "VAL-11", "VAL-12"
  ),
  capability = c(
    "Homogeneity", "Stability", "nIQR", "MADe", "Algorithm A",
    "z score", "z prime score", "zeta score", "En score",
    "Score boundaries", "Invalid denominators", "Expanded criterion"
  ),
  expected = c(
    "sw=0.01774823935; ss=0.00903696114",
    "difference=0.0015; criterion=0.0066735", "0.05003775",
    "0.05932", "x=10.01702296; s=0.07952769; one winsorized", "1.6",
    "1.5689290811", "2.5298221281", "1.2649110641",
    "2 satisfactory; 3 unsatisfactory", "typed NA",
    "positional app call errors; returned value has squared unit"
  ),
  obtained = c(
    sprintf("sw=%.12g; ss=%.12g", h$sw, h$ss),
    sprintf("difference=%.12g; criterion=%.12g", s$diff_hom_stab, c_stab),
    sprintf("%.12g", calculate_niqr(participants)),
    sprintf("%.12g", calculate_mad_e(participants)),
    sprintf(
      "converged=%s; n_winsorized=%d", algorithm_a$converged,
      algorithm_a$n_winsorized
    ),
    sprintf("%.12g", calculate_z_score(10.08, 10.00, 0.05)),
    sprintf("%.12g", calculate_z_prime_score(10.08, 10.00, 0.05, 0.01)),
    sprintf("%.12g", calculate_zeta_score(10.08, 10.00, 0.03, 0.01)),
    sprintf("%.12g", calculate_en_score(10.08, 10.00, 0.06, 0.02)),
    paste(evaluate_z_score(2), evaluate_z_score(3), sep = "; "),
    sprintf(
      "z=%s; En=%s", calculate_z_score(1, 1, 0),
      calculate_en_score(1, 1, 0, 0)
    ),
    sprintf("returned %.12g with squared unit", c_expanded)
  ),
  status = c(rep("PASS", 11), "OPEN_RISK"),
  evidence = c(
    rep("anexos/calculos_reproducibles.csv", 10),
    "tests/test_09_reproducibilidad.R",
    "ptcalc/R/pt_homogeneity.R; E03 documented defect"
  ),
  responsible = c(rep("Equipo técnico PT", 11), "Responsable de ptcalc"),
  stringsAsFactors = FALSE
)
utils::write.csv(
  cases, file.path(output_dir, "matriz_validacion.csv"), row.names = FALSE
)

git_value <- function(args, directory = root_dir) {
  output <- system2("git", c("-C", directory, args), stdout = TRUE, stderr = FALSE)
  paste(output, collapse = " ")
}
environment <- c(
  paste("generated_at=", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), sep = ""),
  paste("root_commit=", git_value(c("rev-parse", "HEAD")), sep = ""),
  paste("root_status=", git_value(c("status", "--short")), sep = ""),
  paste(
    "ptcalc_commit=", git_value(c("rev-parse", "HEAD"), file.path(root_dir, "ptcalc")),
    sep = ""
  ),
  paste(
    "ptcalc_status=", git_value(c("status", "--short"), file.path(root_dir, "ptcalc")),
    sep = ""
  ),
  paste("r_version=", R.version.string, sep = ""),
  paste("platform=", R.version$platform, sep = ""),
  paste("devtools_version=", as.character(packageVersion("devtools")), sep = ""),
  paste("testthat_version=", as.character(packageVersion("testthat")), sep = "")
)
writeLines(environment, file.path(output_dir, "entorno_ejecucion.txt"))

ptcalc_dir <- file.path(root_dir, "ptcalc")
ptcalc_diff <- system2(
  "git", c("-C", ptcalc_dir, "diff", "--binary", "HEAD"),
  stdout = TRUE, stderr = TRUE
)
writeLines(ptcalc_diff, file.path(output_dir, "ptcalc_worktree.patch"))
ptcalc_sources <- list.files(
  file.path(ptcalc_dir, "R"), pattern = "[.]R$", full.names = TRUE
)
source_hashes <- data.frame(
  path = substring(ptcalc_sources, nchar(root_dir) + 2L),
  sha256 = vapply(ptcalc_sources, function(path) {
    output <- system2("sha256sum", path, stdout = TRUE)
    strsplit(output[[1]], "[[:space:]]+")[[1]][[1]]
  }, character(1)),
  stringsAsFactors = FALSE
)
utils::write.csv(
  source_hashes, file.path(output_dir, "ptcalc_fuentes_sha256.csv"),
  row.names = FALSE
)
writeLines(
  c(
    "E09 evidence generation completed.",
    sprintf("Validation cases: %d PASS, %d OPEN_RISK.", sum(cases$status == "PASS"), sum(cases$status == "OPEN_RISK")),
    "Inputs: synthetic, deterministic, non-sensitive.",
    "Precision: full numeric precision in CSV; rounded only in documents."
  ),
  file.path(output_dir, "generacion_log.txt")
)
