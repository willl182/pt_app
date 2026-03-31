"""Run all validation stages (Python orchestrator).

Executes available stages in sequence.
"""

from common_config import get_target_combos, validate_combo_definition
from stage_01_robust_stats import run_stage_01_robust_stats
from stage_02_homogeneity import run_stage_02_homogeneity
from stage_03_stability import run_stage_03_stability
from stage_04_uncertainty_chain import run_stage_04_uncertainty_chain
from stage_05_scores import run_stage_05_scores


def run_validation_all() -> None:
  combos = get_target_combos()
  validate_combo_definition(combos)

  print("Validation pipeline started.")
  print(f"Target combos loaded: {len(combos)}")
  print("Running stage_01_robust_stats...")
  run_stage_01_robust_stats()
  print("Running stage_02_homogeneity...")
  run_stage_02_homogeneity()
  print("Running stage_03_stability...")
  run_stage_03_stability()
  print("Running stage_04_uncertainty_chain...")
  run_stage_04_uncertainty_chain()
  print("Running stage_05_scores...")
  run_stage_05_scores()
  print("Validation pipeline finished.")


if __name__ == "__main__":
  run_validation_all()
