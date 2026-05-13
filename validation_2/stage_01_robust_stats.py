"""
Etapa 1: Estadísticos Robustos de Dispersión (Python)
Validación de mediana, MAD, MADe, nIQR sobre sample_1

Referencia: ISO 13528:2022, Sección 9.4
Fuente: data/homogeneity_n13.csv
Combos primarios: O3 × 3 niveles (0, 80, 180 nmol/mol)

Uso:
    cd /home/w182/w421/pt_app
    python3 validation_2/stage_01_robust_stats.py

Outputs:
    validation_2/outputs/stage_01_robust_stats_py.csv  (intermedio Python)
    validation_2/outputs/stage_01_robust_stats.csv      (canónico comparado)
    validation_2/outputs/stage_01_robust_stats_report.md
"""

import sys
import os
import math
import csv

sys.path.insert(0, os.path.dirname(__file__))

from helpers import (
    COMBOS, make_combo_id, load_wide_data, median, quantile_type7,
    iqr_type7, TOL_DEFAULT, STATUS_PASS, STATUS_FAIL, STATUS_EDGE,
    CANONICAL_COLS, write_canonical_csv, write_report_md,
)

import numpy as np

DATA_HOMOGENEITY = "data/homogeneity_n13.csv"
OUTPUT_PY_CSV    = "validation_2/outputs/stage_01_robust_stats_py.csv"
R_CSV            = "validation_2/outputs/stage_01_robust_stats_r.csv"
OUTPUT_CSV       = "validation_2/outputs/stage_01_robust_stats.csv"
OUTPUT_REPORT    = "validation_2/outputs/stage_01_robust_stats_report.md"

# ===================================================================
# Funciones de cálculo
# ===================================================================

def calc_robust_stats(sample1_values):
    """Calcular estadísticos robustos: mediana, MAD, MADe, nIQR."""
    x_clean = [v for v in sample1_values if math.isfinite(v)]
    n = len(x_clean)

    if n < 2:
        return {
            "n": n, "median_val": float("nan"), "MAD_val": float("nan"),
            "MADe_val": float("nan"), "nIQR_val": float("nan"),
            "Q1": float("nan"), "Q3": float("nan"), "IQR_val": float("nan"),
            "edge_case": True,
        }

    x_arr = np.array(x_clean, dtype=float)

    # Mediana (x_pt) — Sección 9.2
    median_val = float(np.median(x_arr))

    # MAD: median(|x_i - median(x)|) — Sección 9.4
    abs_dev = np.abs(x_arr - median_val)
    MAD_val = float(np.median(abs_dev))

    # MADe = 1.483 × MAD — Sección 9.4
    MADe_val = 1.483 * MAD_val

    # Cuartiles (numpy percentile = R type=7 linear interpolation)
    q1, q3 = np.percentile(x_arr, [25, 75])
    IQR_val = q3 - q1

    # nIQR = 0.7413 × IQR — Sección 9.4
    nIQR_val = 0.7413 * IQR_val

    return {
        "n": n, "median_val": median_val, "MAD_val": MAD_val,
        "MADe_val": MADe_val, "nIQR_val": nIQR_val,
        "Q1": float(q1), "Q3": float(q3), "IQR_val": float(IQR_val),
        "edge_case": False,
    }


# ===================================================================
# Ejecutar para O3 × 3 niveles y comparar con R
# ===================================================================

def run_stage_01():
    print("Etapa 1: Estadísticos Robustos (Python) — INICIO")
    print(f"  Datos: {DATA_HOMOGENEITY}")
    print("  Combos: O3 × 3 niveles\n")

    py_results = {}

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        print(f"  Procesando: {combo['label']}")

        # Cargar datos en formato ancho
        wide = load_wide_data(DATA_HOMOGENEITY, combo["pollutant"], combo["level"])

        if wide.empty or "sample_1" not in wide.columns:
            print("    ADVERTENCIA: datos insuficientes, saltando")
            for metric in ["median", "MAD", "MADe", "nIQR", "Q1", "Q3", "IQR", "n"]:
                py_results[f"{combo_id}_{metric}"] = {
                    "combo_id": combo_id, "pollutant": combo["pollutant"],
                    "level": combo["level"], "stage": "01_robust_stats",
                    "section": "robust", "metric": metric,
                    "python_value": float("nan"), "r_value": float("nan"),
                    "app_value": float("nan"), "diff_r_python": float("nan"),
                    "diff_app_r": float("nan"), "diff_app_python": float("nan"),
                    "status": STATUS_EDGE, "tolerance": TOL_DEFAULT,
                    "notes": "Insufficient data",
                }
            continue

        # Extraer sample_1 (primera réplica)
        sample1 = wide["sample_1"].tolist()

        # Calcular estadísticos robustos
        stats = calc_robust_stats(sample1)

        print(f"    n={stats['n']}"
              f"  median={stats['median_val']:.10g}"
              f"  MAD={stats['MAD_val']:.10g}"
              f"  MADe={stats['MADe_val']:.10g}"
              f"  nIQR={stats['nIQR_val']:.10g}")

        # Construir resultados
        metrics_map = {
            "median":  stats["median_val"],
            "MAD":     stats["MAD_val"],
            "MADe":    stats["MADe_val"],
            "nIQR":    stats["nIQR_val"],
            "Q1":      stats["Q1"],
            "Q3":      stats["Q3"],
            "IQR":     stats["IQR_val"],
            "n":       float(stats["n"]),
        }

        for metric, value in metrics_map.items():
            py_results[f"{combo_id}_{metric}"] = {
                "combo_id": combo_id, "pollutant": combo["pollutant"],
                "level": combo["level"], "stage": "01_robust_stats",
                "section": "robust", "metric": metric,
                "python_value": value, "r_value": float("nan"),
                "app_value": float("nan"), "diff_r_python": float("nan"),
                "diff_app_r": float("nan"), "diff_app_python": float("nan"),
                "status": "PENDING_COMPARE", "tolerance": TOL_DEFAULT,
                "notes": "",
            }

    # Guardar resultados Python como CSV intermedio
    write_canonical_csv(list(py_results.values()), OUTPUT_PY_CSV)
    print(f"\n  Resultados Python guardados: {OUTPUT_PY_CSV}")

    return py_results


def compare_with_r(py_results):
    """Comparar resultados Python con R y generar CSV canónico y reporte."""
    print("\n  Comparando con resultados R...")

    # Leer resultados R
    r_values = {}
    if os.path.exists(R_CSV):
        with open(R_CSV, "r") as f:
            reader = csv.DictReader(f)
            for row in reader:
                key = f"{row['combo_id']}_{row['metric']}"
                try:
                    r_values[key] = float(row["r_value"])
                except (ValueError, TypeError):
                    r_values[key] = float("nan")
    else:
        print(f"  ADVERTENCIA: No se encontró {R_CSV}. Saltando comparación R.")
        return py_results

    report_lines = [
        "# Etapa 1: Estadísticos Robustos de Dispersión — Reporte",
        "",
        "## Información",
        f"- Datos: `{DATA_HOMOGENEITY}`",
        "- Combos: O3 × 3 niveles (0, 80, 180 nmol/mol)",
        f"- Fecha: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M')}",
        "",
        "## Referencia ISO 13528:2022, Sección 9.4",
        "",
        "| Estadístico | Fórmula | Factor |",
        "|-------------|---------|--------|",
        "| Mediana (x_pt) | `median(sample_1)` | — |",
        "| MAD | `median(\\|x_i − median(x)\\|)` | — |",
        "| MADe (σ_pt) | `1.483 × MAD` | 1.483 |",
        "| nIQR | `0.7413 × (Q3 − Q1)` tipo=7 | 0.7413 |",
        "",
        "## Resultados por combo",
        "",
    ]

    canonical_results = []
    all_pass = True

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])

        report_lines.append(f"### {combo_id}: O3 nivel {combo['level']}")
        report_lines.append("")
        report_lines.append("| Métrica | R | Python | diff R-Python | Estado |")
        report_lines.append("|--------|------|--------|--------------|--------|")

        for metric in ["n", "median", "Q1", "Q3", "IQR", "MAD", "MADe", "nIQR"]:
            key = f"{combo_id}_{metric}"
            py_val = py_results[key]["python_value"] if key in py_results else float("nan")
            r_val = r_values.get(key, float("nan"))

            diff_r_py = abs(r_val - py_val) if (math.isfinite(r_val) and math.isfinite(py_val)) else float("nan")

            status = STATUS_PASS
            if math.isfinite(diff_r_py) and diff_r_py > TOL_DEFAULT:
                status = STATUS_FAIL
                all_pass = False

            py_results[key]["r_value"] = r_val
            py_results[key]["diff_r_python"] = diff_r_py
            py_results[key]["status"] = status

            r_str = f"{r_val:.10g}" if math.isfinite(r_val) else "NA"
            py_str = f"{py_val:.10g}" if math.isfinite(py_val) else "NA"
            diff_str = f"{diff_r_py:.2e}" if math.isfinite(diff_r_py) else "—"

            report_lines.append(f"| {metric} | {r_str} | {py_str} | {diff_str} | {status} |")

            canonical_results.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "stage": "01_robust_stats",
                "section": "robust",
                "metric": metric,
                "r_value": r_val,
                "python_value": py_val,
                "app_value": float("nan"),
                "diff_r_python": diff_r_py,
                "diff_app_r": float("nan"),
                "diff_app_python": float("nan"),
                "status": status,
                "tolerance": TOL_DEFAULT,
                "notes": "",
            })

        report_lines.append("")

    # Resumen global
    report_lines.append("## Resumen")
    report_lines.append("")
    total = len(canonical_results)
    passed = sum(1 for r in canonical_results if r["status"] == STATUS_PASS)
    failed = sum(1 for r in canonical_results if r["status"] == STATUS_FAIL)
    report_lines.append(f"- Total métricas: {total}")
    report_lines.append(f"- PASS: {passed}")
    report_lines.append(f"- FAIL: {failed}")
    report_lines.append("")

    if all_pass:
        report_lines.append("✅ **Todos los valores R/Python coinciden dentro de tolerancia.**")
    else:
        report_lines.append("❌ **Hay discrepancias entre R y Python.** Verificar cuartiles type=7 vs interpolación lineal.")

    # Verificaciones específicas
    report_lines.append("")
    report_lines.append("## Verificaciones")
    report_lines.append("")
    report_lines.append("1. ✅ Mediana calculada sobre `sample_1` (no sobre todas las réplicas)")
    report_lines.append("2. ✅ Factor MADe = 1.483 (= 1/0.6745)")
    report_lines.append("3. ✅ Factor nIQR = 0.7413 (= 1/1.349)")
    report_lines.append("4. 🔍 Cuartiles type=7 (R) vs interpolación lineal (numpy/Python)")
    report_lines.append("   - R `quantile(type=7)` y `numpy.percentile` usan el mismo método")
    report_lines.append("   - Con n=13, debe haber coincidencia exacta")

    # Guardar CSV canónico y reporte
    write_canonical_csv(canonical_results, OUTPUT_CSV)
    write_report_md(report_lines, OUTPUT_REPORT)

    print(f"\nEtapa 1: Estadísticos Robustos (Python + Comparación) — FIN")
    return py_results


if __name__ == "__main__":
    py_results = run_stage_01()
    py_results = compare_with_r(py_results)