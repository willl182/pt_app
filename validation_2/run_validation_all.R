# ===================================================================
# Run All Validation Stages (R Orchestrator)
#
# Executes available stages in sequence.
# ===================================================================

source("validation/common_config.R")
source("validation/stage_01_robust_stats.R")
source("validation/stage_02_homogeneity.R")
source("validation/stage_03_stability.R")
source("validation/stage_04_uncertainty_chain.R")
source("validation/stage_05_scores.R")

run_validation_all <- function() {
  combos <- get_target_combos()
  validate_combo_definition(combos)

  cat("Validation pipeline started.\n")
  cat(sprintf("Target combos loaded: %d\n", nrow(combos)))
  cat("Running stage_01_robust_stats...\n")
  run_stage_01_robust_stats()
  cat("Running stage_02_homogeneity...\n")
  run_stage_02_homogeneity()
  cat("Running stage_03_stability...\n")
  run_stage_03_stability()
  cat("Running stage_04_uncertainty_chain...\n")
  run_stage_04_uncertainty_chain()
  cat("Running stage_05_scores...\n")
  run_stage_05_scores()
  cat("Validation pipeline finished.\n")
}

if (identical(environment(), globalenv())) {
  run_validation_all()
}
