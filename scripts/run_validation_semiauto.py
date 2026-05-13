#!/usr/bin/env python3

"""Wrapper semiautomatico para ejecutar validation_1 con datos custom.

- Respaldar los CSV fijos de data/for_validation
- Copiar los archivos provistos a los nombres esperados por validation_1
- Ejecutar run_validation_all.py
- Restaurar los archivos originales al final
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
  if len(sys.argv) != 4:
    print(
      'Uso: python3 scripts/run_validation_semiauto.py '
      '"ruta/homogeneity.csv" "ruta/stability.csv" "ruta/summary.csv"',
      file=sys.stderr,
    )
    return 2

  project_root = Path.cwd().resolve()
  validation_dir = project_root / "validation_1"
  target_dir = project_root / "data" / "for_validation"

  source_files = {
    "homogeneity": Path(sys.argv[1]).expanduser().resolve(),
    "stability": Path(sys.argv[2]).expanduser().resolve(),
    "summary": Path(sys.argv[3]).expanduser().resolve(),
  }
  expected_files = {
    "homogeneity": target_dir / "homogeneity_n4.csv",
    "stability": target_dir / "stability_n4.csv",
    "summary": target_dir / "summary_n4.csv",
  }
  backup_files = {
    name: Path(str(path) + ".backup_semiauto")
    for name, path in expected_files.items()
  }

  for name, path in source_files.items():
    if not path.is_file():
      raise FileNotFoundError(f"No existe el archivo de entrada: {path}")

  def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

  try:
    for name, dst in expected_files.items():
      if dst.exists():
        shutil.copy2(dst, backup_files[name])

    for name, dst in expected_files.items():
      copy_file(source_files[name], dst)

    subprocess.run(
      [
        "python3",
        "-c",
        (
          "import os, sys; "
          "sys.path.insert(0, os.getcwd()); "
          "from stage_01_robust_stats import run_stage_01_robust_stats; "
          "from stage_02_homogeneity import run_stage_02; "
          "from stage_03_stability import run_stage_03; "
          "from stage_04_uncertainty_chain import run_stage_04; "
          "from stage_05_scores import run_stage_05; "
          "import stage_05_scores as s5; s5.DATA_PT_DATA = '../data/pt_data_n13.csv'; "
          "run_stage_01_robust_stats(); "
          "run_stage_02(); "
          "run_stage_03(); "
          "run_stage_04(); "
          "run_stage_05()"
        ),
      ],
      cwd=validation_dir,
      check=True,
    )
    print("\nValidación semiautomática completada.")
    return 0
  finally:
    for name, dst in expected_files.items():
      bak = backup_files[name]
      if bak.exists():
        shutil.copy2(bak, dst)
        bak.unlink()


if __name__ == "__main__":
  raise SystemExit(main())
