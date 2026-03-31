"""Stage 05 scores (Python independent implementation).

Reads summary_n13 and Stage 04 outputs, computes participant-level scores
(z, z', zeta, En) for methods 2a/2b/3, and writes Python-side values for
tripartite comparison.
"""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path
from typing import Any

from common_config import get_target_combos, validate_combo_definition


STAGE_ID = "stage_05_scores"
K_FACTOR = 2.0


def safe_float(value: Any) -> float:
  try:
    return float(value)
  except (TypeError, ValueError):
    return float("nan")


def mean(values: list[float]) -> float:
  finite_values = [x for x in values if math.isfinite(x)]
  if not finite_values:
    return float("nan")
  return sum(finite_values) / len(finite_values)


def safe_ratio(numerator: float, denominator: float) -> float:
  if not math.isfinite(denominator) or denominator <= 0:
    return float("nan")
  return numerator / denominator


def aggregate_participants(
    rows: list[dict[str, Any]],
    pollutant: str,
    level: str,
) -> list[dict[str, Any]]:
  grouped: dict[str, dict[str, float]] = {}
  for row in rows:
    if row["pollutant"] != pollutant or row["level"] != level:
      continue

    participant_id = row["participant_id"]
    if participant_id == "ref":
      continue

    grouped.setdefault(participant_id, {
        "sum_mean": 0.0,
        "sum_sd": 0.0,
        "n": 0.0,
    })
    grouped[participant_id]["sum_mean"] += safe_float(row["mean_value"])
    grouped[participant_id]["sum_sd"] += safe_float(row["sd_value"])
    grouped[participant_id]["n"] += 1.0

  participants: list[dict[str, Any]] = []
  for participant_id in sorted(grouped.keys()):
    info = grouped[participant_id]
    if info["n"] <= 0:
      continue

    participants.append({
        "participant_id": participant_id,
        "result": info["sum_mean"] / info["n"],
        "sd_value": info["sum_sd"] / info["n"],
    })

  return participants


def get_stage_04_metric(
    stage_rows: list[dict[str, Any]],
    combo_id: str,
    method_id: str,
    metric: str,
) -> float:
  for row in stage_rows:
    if row.get("combo_id") != combo_id:
      continue
    if row.get("section") != "uncertainty_chain":
      continue
    if row.get("participant_id") != method_id:
      continue
    if row.get("metric") != metric:
      continue
    return safe_float(row.get("python_value"))

  return float("nan")


def compute_score_metrics(
    result: float,
    sd_value: float,
    x_pt: float,
    sigma_pt: float,
    u_xpt: float,
    u_xpt_def: float,
    u_hom: float,
    u_stab: float,
    m: float,
) -> dict[str, float]:
  uncertainty_std = sd_value
  if math.isfinite(m) and m > 0:
    uncertainty_std = sd_value / math.sqrt(m)

  z_den = sigma_pt
  z_score = safe_ratio(result - x_pt, z_den)

  z_prime_den = math.sqrt(sigma_pt**2 + u_xpt_def**2)
  z_prime_score = safe_ratio(result - x_pt, z_prime_den)

  zeta_den = math.sqrt(uncertainty_std**2 + u_xpt_def**2)
  zeta_score = safe_ratio(result - x_pt, zeta_den)

  u_xi_expanded = K_FACTOR * uncertainty_std
  u_xpt_expanded = K_FACTOR * u_xpt_def
  en_den = math.sqrt(u_xi_expanded**2 + u_xpt_expanded**2)
  en_score = safe_ratio(result - x_pt, en_den)

  return {
      "m": m,
      "result": result,
      "sd_value": sd_value,
      "uncertainty_std": uncertainty_std,
      "x_pt": x_pt,
      "sigma_pt": sigma_pt,
      "u_xpt": u_xpt,
      "u_xpt_def": u_xpt_def,
      "u_hom": u_hom,
      "u_stab": u_stab,
      "z_den": z_den,
      "z_score": z_score,
      "z_prime_den": z_prime_den,
      "z_prime_score": z_prime_score,
      "zeta_den": zeta_den,
      "zeta_score": zeta_score,
      "u_xi_expanded": u_xi_expanded,
      "u_xpt_expanded": u_xpt_expanded,
      "en_den": en_den,
      "en_score": en_score,
  }


def build_python_rows(
    combos: list[dict[str, str]],
    summary_rows: list[dict[str, Any]],
    stage_04_rows: list[dict[str, Any]],
) -> list[dict[str, Any]]:
  method_ids = ["method_2a", "method_2b", "method_3"]
  metric_names = [
      "m",
      "result",
      "sd_value",
      "uncertainty_std",
      "x_pt",
      "sigma_pt",
      "u_xpt",
      "u_xpt_def",
      "u_hom",
      "u_stab",
      "z_den",
      "z_score",
      "z_prime_den",
      "z_prime_score",
      "zeta_den",
      "zeta_score",
      "u_xi_expanded",
      "u_xpt_expanded",
      "en_den",
      "en_score",
  ]

  output_rows: list[dict[str, Any]] = []

  for combo in combos:
    combo_id = combo["combo_id"]
    pollutant = combo["pollutant"]
    level = combo["level"]

    participants = aggregate_participants(summary_rows, pollutant, level)

    for method_id in method_ids:
      x_pt = get_stage_04_metric(stage_04_rows, combo_id, method_id, "x_pt_method")
      sigma_pt = get_stage_04_metric(
          stage_04_rows,
          combo_id,
          method_id,
          "sigma_pt_method",
      )
      u_xpt = get_stage_04_metric(stage_04_rows, combo_id, method_id, "u_xpt")
      u_xpt_def = get_stage_04_metric(stage_04_rows, combo_id, method_id, "u_xpt_def")
      u_hom = get_stage_04_metric(stage_04_rows, combo_id, method_id, "u_hom")
      u_stab = get_stage_04_metric(stage_04_rows, combo_id, method_id, "u_stab")
      m = get_stage_04_metric(stage_04_rows, combo_id, method_id, "m")

      section_name = f"scores_{method_id}"
      for participant in participants:
        metrics = compute_score_metrics(
            result=participant["result"],
            sd_value=participant["sd_value"],
            x_pt=x_pt,
            sigma_pt=sigma_pt,
            u_xpt=u_xpt,
            u_xpt_def=u_xpt_def,
            u_hom=u_hom,
            u_stab=u_stab,
            m=m,
        )

        for metric_name in metric_names:
          output_rows.append({
              "combo_id": combo_id,
              "pollutant": pollutant,
              "level": level,
              "stage": STAGE_ID,
              "section": section_name,
              "participant_id": participant["participant_id"],
              "metric": metric_name,
              "python_value": metrics.get(metric_name, float("nan")),
          })

  return output_rows


def write_python_values(path: Path, rows: list[dict[str, Any]]) -> None:
  path.parent.mkdir(parents=True, exist_ok=True)
  fieldnames = [
      "combo_id",
      "pollutant",
      "level",
      "stage",
      "section",
      "participant_id",
      "metric",
      "python_value",
  ]
  with path.open("w", encoding="utf-8", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=fieldnames)
    writer.writeheader()
    for row in rows:
      writer.writerow(row)


def run_stage_05_scores(
    summary_input: str = "data/summary_n13.csv",
    stage_04_output: str = "validation/outputs/stage_04_uncertainty_chain.csv",
    output_path: str = "validation/outputs/stage_05_python_values.csv",
) -> list[dict[str, Any]]:
  combos = get_target_combos()
  validate_combo_definition(combos)

  with Path(summary_input).open("r", encoding="utf-8", newline="") as handle:
    summary_rows = list(csv.DictReader(handle))
  with Path(stage_04_output).open("r", encoding="utf-8", newline="") as handle:
    stage_04_rows = list(csv.DictReader(handle))

  required_summary = {
      "pollutant",
      "level",
      "participant_id",
      "mean_value",
      "sd_value",
  }
  if not summary_rows:
    raise ValueError("summary_n13.csv has no data rows.")
  if not required_summary.issubset(summary_rows[0].keys()):
    raise ValueError(
        "summary_n13.csv must include pollutant, level, participant_id, "
        "mean_value, sd_value."
    )

  output_rows = build_python_rows(combos, summary_rows, stage_04_rows)
  write_python_values(Path(output_path), output_rows)
  print(f"Stage 05 Python values generated: {output_path}")
  return output_rows


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser()
  parser.add_argument(
      "--summary-input",
      default="data/summary_n13.csv",
      help="Path to summary_n13.csv file.",
  )
  parser.add_argument(
      "--stage-04-output",
      default="validation/outputs/stage_04_uncertainty_chain.csv",
      help="CSV output path from Stage 04 (uncertainty chain).",
  )
  parser.add_argument(
      "--values-output",
      default="validation/outputs/stage_05_python_values.csv",
      help="CSV output path for Python metric values.",
  )
  return parser.parse_args()


if __name__ == "__main__":
  args = parse_args()
  run_stage_05_scores(
      summary_input=args.summary_input,
      stage_04_output=args.stage_04_output,
      output_path=args.values_output,
  )
