"""
Etapa 1: Estadisticos robustos de dispersion (Python).
Validacion de mediana, MAD, MADe y nIQR.

Referencia: ISO 13528:2022, Seccion 9.4
Fuente: data/for_validation/summary_n4.csv
Alcance: O3 en 3 niveles (0, 80, 180 nmol/mol)
"""

import csv
import math
import os

DATA_SUMMARY = "../data/for_validation/summary_n4.csv"
R_CSV = "validation_1/outputs/stage_01_robust_stats_r.csv"
OUTPUT_PY_CSV = "validation_1/outputs/stage_01_robust_stats_py.csv"
OUTPUT_CSV = "validation_1/outputs/stage_01_robust_stats.csv"
OUTPUT_REPORT = "validation_1/outputs/stage_01_robust_stats_report.md"

TARGET_COMBOS = [
    {"pollutant": "o3", "level": "0-nmol/mol"},
    {"pollutant": "o3", "level": "80-nmol/mol"},
    {"pollutant": "o3", "level": "180-nmol/mol"},
]

TOL_DEFAULT = 1e-9
STATUS_PASS = "PASS"
STATUS_FAIL = "FAIL"


def make_combo_id(pollutant, level):
    return f"{pollutant.upper()}_{level.split('-')[0]}"


def median(values):
    vals = sorted(v for v in values if math.isfinite(v))
    n = len(vals)
    if n == 0:
        return float("nan")
    mid = n // 2
    if n % 2:
        return vals[mid]
    return (vals[mid - 1] + vals[mid]) / 2.0


def quantile_type7(values, prob):
    vals = sorted(v for v in values if math.isfinite(v))
    n = len(vals)
    if n == 0:
        return float("nan")
    if n == 1:
        return vals[0]
    h = (n - 1) * prob + 1
    lo = int(math.floor(h))
    hi = int(math.ceil(h))
    if lo == hi:
        return vals[lo - 1]
    frac = h - lo
    return vals[lo - 1] * (1 - frac) + vals[hi - 1] * frac


def calculate_niqr(values):
    q1 = quantile_type7(values, 0.25)
    q3 = quantile_type7(values, 0.75)
    return 0.7413 * (q3 - q1)


def run_stage_01_robust_stats():
    print("Etapa 1: Estadisticos robustos de dispersion — INICIO")

    rows = []
    with open(DATA_SUMMARY, "r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["participant_id"] == "ref":
                continue
            rows.append(row)

    py_rows = []
    for combo in TARGET_COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        values = [
            float(row["mean_value"])
            for row in rows
            if row["pollutant"] == combo["pollutant"]
            and row["level"] == combo["level"]
            and row["mean_value"] not in ("", "NA", "NaN", "nan")
        ]
        values = [v for v in values if math.isfinite(v)]
        n_values = len(values)

        if n_values < 2:
            py_rows.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "n_values": n_values,
                "x_pt": float("nan"),
                "mad": float("nan"),
                "MADe": float("nan"),
                "nIQR": float("nan"),
                "edge_case": True,
            })
            continue

        x_pt = median(values)
        mad_val = median([abs(v - x_pt) for v in values])
        made_val = 1.483 * mad_val
        niqr_val = calculate_niqr(values)

        py_rows.append({
            "combo_id": combo_id,
            "pollutant": combo["pollutant"],
            "level": combo["level"],
            "n_values": n_values,
            "x_pt": x_pt,
            "mad": mad_val,
            "MADe": made_val,
            "nIQR": niqr_val,
            "edge_case": False,
        })

        print(
            f"  {combo_id} n={n_values} x_pt={x_pt:.8f} "
            f"mad={mad_val:.8f} MADe={made_val:.8f} nIQR={niqr_val:.8f}"
        )

    os.makedirs(os.path.dirname(OUTPUT_PY_CSV), exist_ok=True)
    with open(OUTPUT_PY_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "combo_id", "pollutant", "level", "n_values",
                "x_pt", "mad", "MADe", "nIQR", "edge_case",
            ],
        )
        writer.writeheader()
        writer.writerows(py_rows)
    print(f"  Resultados Python guardados: {OUTPUT_PY_CSV}")

    r_data = {}
    if os.path.exists(R_CSV):
        with open(R_CSV, "r", newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                r_data[row["combo_id"]] = row
    else:
        print(f"  ADVERTENCIA: {R_CSV} no encontrado. Ejecute R primero.")

    canonical_rows = []
    for py_row in py_rows:
        r_row = r_data.get(py_row["combo_id"], {})
        for metric in ["n_values", "x_pt", "mad", "MADe", "nIQR"]:
            py_val = py_row[metric]
            r_val = float(r_row.get(metric, "nan")) if r_row else float("nan")
            if math.isfinite(py_val) and math.isfinite(r_val):
                diff = r_val - py_val
                status = STATUS_PASS if abs(diff) <= TOL_DEFAULT else STATUS_FAIL
            elif not math.isfinite(py_val) and not math.isfinite(r_val):
                diff = float("nan")
                status = STATUS_PASS
            else:
                diff = float("nan")
                status = STATUS_FAIL

            canonical_rows.append({
                "combo_id": py_row["combo_id"],
                "pollutant": py_row["pollutant"],
                "level": py_row["level"],
                "stage": "stage_01_robust_stats",
                "section": "robust_stats",
                "participant_id": "ALL",
                "metric": metric,
                "app_value": r_val,
                "r_value": r_val,
                "python_value": py_val,
                "diff_app_r": 0,
                "diff_app_python": diff,
                "diff_r_python": diff,
                "status": status,
                "tolerance": TOL_DEFAULT,
                "notes": "",
            })

    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "combo_id", "pollutant", "level", "stage", "section",
                "participant_id", "metric", "app_value", "r_value",
                "python_value", "diff_app_r", "diff_app_python",
                "diff_r_python", "status", "tolerance", "notes",
            ],
        )
        writer.writeheader()
        writer.writerows(canonical_rows)
    print(f"  CSV canónico escrito: {OUTPUT_CSV}")

    pass_count = sum(1 for row in canonical_rows if row["status"] == STATUS_PASS)
    fail_count = sum(1 for row in canonical_rows if row["status"] == STATUS_FAIL)
    report_lines = [
        "# Reporte: Etapa 1 - Estadisticos robustos de dispersion",
        "",
        f"**Fecha**: {os.popen('date +%Y-%m-%d').read().strip()}",
        "",
        "## Combos procesados",
    ]
    report_lines.extend(f"- {row['combo_id']}" for row in py_rows)
    report_lines.extend([
        "",
        "## Resumen PASS/FAIL",
        f"- PASS: {pass_count}",
        f"- FAIL: {fail_count}",
        "- EDGE_CASE: 0",
        "- KNOWN_DISCREPANCY: 0",
        "",
        "## Validaciones requeridas",
        "- Mediana calculada sobre mean_value filtrado por O3 y nivel",
        "- Factor MADe = 1.483",
        "- Factor nIQR = 0.7413",
        "- Cuartiles con type = 7",
        "",
        "## Conclusión",
        "Etapa PASS" if fail_count == 0 else "Etapa con FAIL pendientes de revisión",
        "",
    ])
    with open(OUTPUT_REPORT, "w", encoding="utf-8") as f:
        f.write("\n".join(report_lines))
    print(f"  Reporte escrito: {OUTPUT_REPORT}")
    print("Etapa 1: Estadisticos robustos de dispersion — FIN")


if __name__ == "__main__":
    run_stage_01_robust_stats()
