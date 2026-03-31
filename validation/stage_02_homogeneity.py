"""
Etapa 2: Homogeneidad (Python)
Validacion de evaluacion de homogeneidad.

Referencia: ISO 13528:2022, Seccion 9.2
Fuente: data/homogeneity_n13.csv

Uso:
    python3 validation/stage_02_homogeneity.py

Outputs:
    validation/outputs/stage_02_homogeneity_py.csv (intermedio)
    validation/outputs/stage_02_homogeneity.csv (comparacion final)
    validation/outputs/stage_02_homogeneity_report.md

Metricas validadas (12 por combo):
    g, m, general_mean_homog, x_pt, s_x_bar_sq, sw, ss_sq, ss,
    sigma_pt, MADe, u_sigma_pt, criterio_c, criterio_expandido
"""

import sys
import os
import csv as csv_mod
import math

sys.path.insert(0, os.path.dirname(__file__))

from helpers import (
    COMBOS, make_combo_id, load_wide_data, median, quantile_type7,
    TOL_DEFAULT, canonical_row, write_canonical_csv, CANONICAL_COLS,
    STATUS_PASS, STATUS_FAIL, STATUS_EDGE,
)

DATA_HOMOGENEITY = "data/homogeneity_n13.csv"
OUTPUT_PY_CSV = "validation/outputs/stage_02_homogeneity_py.csv"
OUTPUT_CSV = "validation/outputs/stage_02_homogeneity.csv"
OUTPUT_REPORT = "validation/outputs/stage_02_homogeneity_report.md"

# --- Tabla F1/F2 para criterio expandido (3 args) ---
F_TABLE = {
    7:  (2.10, 1.43), 8:  (2.01, 1.25), 9:  (1.94, 1.11),
    10: (1.88, 1.01), 11: (1.83, 0.93), 12: (1.79, 0.86),
    13: (1.75, 0.80), 14: (1.72, 0.75), 15: (1.69, 0.71),
    16: (1.67, 0.68), 17: (1.64, 0.64), 18: (1.62, 0.62),
    19: (1.60, 0.59), 20: (1.59, 0.57),
}


def calc_criterion_expanded(sigma_pt, sw, g):
    """c_exp = F1*(0.3*sigma_pt)^2 + F2*sw^2 con clamp g a [7,20]."""
    g_clamped = max(7, min(20, g))
    f1, f2 = F_TABLE[g_clamped]
    return f1 * (0.3 * sigma_pt) ** 2 + f2 * sw ** 2


def variance(values):
    """Calcular varianza muestral (ddof=1, como R var())."""
    n = len(values)
    if n < 2:
        return float("nan")
    m = sum(values) / n
    return sum((x - m) ** 2 for x in values) / (n - 1)


def load_wide_as_matrix(data_path, pollutant, level):
    """Cargar datos y pivotear a matriz g x m (lista de listas).
    Retorna (sample_ids_sorted, matrix) donde matrix[i] es la fila i.
    """
    wide = load_wide_data(data_path, pollutant, level)
    if len(wide) < 1:
        return [], []

    # Determinar replicas disponibles
    all_reps = set()
    for sid, reps in wide.items():
        all_reps.update(reps.keys())

    # Ordenar replicas numericamente
    sorted_reps = sorted(all_reps, key=lambda x: int(x))

    # Ordenar sample_ids numericamente
    sorted_sids = sorted(wide.keys(), key=lambda x: int(x))

    matrix = []
    for sid in sorted_sids:
        row = []
        for rep in sorted_reps:
            val = wide[sid].get(rep, float("nan"))
            row.append(val)
        matrix.append(row)

    return sorted_sids, matrix


def row_means(matrix):
    """Calcular media de cada fila."""
    return [sum(row) / len(row) for row in matrix]


def col_values(matrix, col_idx):
    """Extraer columna col_idx de la matriz."""
    return [row[col_idx] for row in matrix]


def run_stage_02():
    print("Etapa 2: Homogeneidad — INICIO")

    py_results = []

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        print(f"  Procesando: {combo['label']}")

        sids, matrix = load_wide_as_matrix(
            DATA_HOMOGENEITY, combo["pollutant"], combo["level"]
        )

        g = len(matrix)
        if g < 2:
            print(f"    ADVERTENCIA: menos de 2 muestras ({g}), saltando")
            py_results.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "g": g,
                "m": 0,
                "general_mean_homog": float("nan"),
                "x_pt": float("nan"),
                "s_x_bar_sq": float("nan"),
                "sw": float("nan"),
                "ss_sq": float("nan"),
                "ss": float("nan"),
                "sigma_pt": float("nan"),
                "MADe": float("nan"),
                "u_sigma_pt": float("nan"),
                "criterio_c": float("nan"),
                "criterio_expandido": float("nan"),
                "edge_case": True,
            })
            continue

        m = len(matrix[0])
        if m < 2:
            print(f"    ADVERTENCIA: menos de 2 replicas ({m}), saltando")
            py_results.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "g": g,
                "m": m,
                "general_mean_homog": float("nan"),
                "x_pt": float("nan"),
                "s_x_bar_sq": float("nan"),
                "sw": float("nan"),
                "ss_sq": float("nan"),
                "ss": float("nan"),
                "sigma_pt": float("nan"),
                "MADe": float("nan"),
                "u_sigma_pt": float("nan"),
                "criterio_c": float("nan"),
                "criterio_expandido": float("nan"),
                "edge_case": True,
            })
            continue

        # --- Calcular 12 metricas ---
        means = row_means(matrix)
        general_mean_homog = sum(sum(row) for row in matrix) / (g * m)

        # x_pt: mediana de primera columna
        first_col = col_values(matrix, 0)
        x_pt = median(first_col)

        # s_x_bar_sq: varianza de medias (ddof=1)
        s_x_bar_sq = variance(means)

        # sw: DE intra-muestra
        if m == 2:
            col1 = col_values(matrix, 0)
            col2 = col_values(matrix, 1)
            range_sq_sum = sum((abs(a - b)) ** 2 for a, b in zip(col1, col2))
            sw = math.sqrt(range_sq_sum / (2 * g))
        else:
            within_vars = []
            for row in matrix:
                within_vars.append(variance(row))
            mean_within_var = sum(within_vars) / len(within_vars)
            sw = math.sqrt(mean_within_var)

        sw_sq = sw ** 2

        # ss_sq = abs(s_x_bar_sq - sw_sq/m) — usar abs() como ptcalc
        ss_sq = abs(s_x_bar_sq - sw_sq / m)
        ss = math.sqrt(ss_sq)

        # sigma_pt = median(|sample_2 - x_pt|)
        second_col = col_values(matrix, 1)
        abs_diffs = [abs(v - x_pt) for v in second_col]
        sigma_pt = median(abs_diffs)

        # MADe = 1.483 * sigma_pt
        MADe = 1.483 * sigma_pt

        # u_sigma_pt = 1.25 * MADe / sqrt(g)
        u_sigma_pt = 1.25 * MADe / math.sqrt(g)

        # criterio_c = 0.3 * sigma_pt
        criterio_c = 0.3 * sigma_pt

        # criterio_expandido (3 args, tabla F1/F2)
        criterio_exp = calc_criterion_expanded(sigma_pt, sw, g)

        py_results.append({
            "combo_id": combo_id,
            "pollutant": combo["pollutant"],
            "level": combo["level"],
            "g": g,
            "m": m,
            "general_mean_homog": general_mean_homog,
            "x_pt": x_pt,
            "s_x_bar_sq": s_x_bar_sq,
            "sw": sw,
            "ss_sq": ss_sq,
            "ss": ss,
            "sigma_pt": sigma_pt,
            "MADe": MADe,
            "u_sigma_pt": u_sigma_pt,
            "criterio_c": criterio_c,
            "criterio_expandido": criterio_exp,
            "edge_case": False,
        })

        print(f"    g={g} m={m} x_pt={x_pt:.8f} sw={sw:.8f} ss={ss:.8f} sigma_pt={sigma_pt:.8f}")

    # Guardar resultados Python como CSV intermedio
    os.makedirs(os.path.dirname(OUTPUT_PY_CSV), exist_ok=True)
    fieldnames = ["combo_id", "pollutant", "level", "g", "m",
                  "general_mean_homog", "x_pt", "s_x_bar_sq", "sw",
                  "ss_sq", "ss", "sigma_pt", "MADe", "u_sigma_pt",
                  "criterio_c", "criterio_expandido", "edge_case"]
    with open(OUTPUT_PY_CSV, "w", newline="") as f:
        writer = csv_mod.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(py_results)
    print(f"  Resultados Python guardados: {OUTPUT_PY_CSV}")

    # --- Comparacion tripartita ---
    print("  Generando comparacion tripartita...")

    # Leer resultados R
    r_data = {}
    r_csv_path = "validation/outputs/stage_02_homogeneity_r.csv"
    if os.path.exists(r_csv_path):
        with open(r_csv_path, "r") as f:
            reader = csv_mod.DictReader(f)
            for row in reader:
                r_data[row["combo_id"]] = row
    else:
        print(f"    ADVERTENCIA: {r_csv_path} no encontrado. Ejecutar R primero.")

    all_rows = []
    discrepancies = []
    edge_cases = []
    combos_processed = []

    metrics = [
        "g", "m", "general_mean_homog", "x_pt", "s_x_bar_sq",
        "sw", "ss_sq", "ss", "sigma_pt", "MADe", "u_sigma_pt",
        "criterio_c", "criterio_expandido",
    ]
    metric_labels = {
        "g": "g",
        "m": "m",
        "general_mean_homog": "Media general",
        "x_pt": "x_pt",
        "s_x_bar_sq": "s_x_bar_sq",
        "sw": "sw",
        "ss_sq": "ss_sq",
        "ss": "ss",
        "sigma_pt": "sigma_pt",
        "MADe": "MADe",
        "u_sigma_pt": "u_sigma_pt",
        "criterio_c": "Criterio c",
        "criterio_expandido": "Criterio expandido",
    }

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        py_row = next((r for r in py_results if r["combo_id"] == combo_id), None)
        r_row = r_data.get(combo_id)

        if py_row is None or r_row is None:
            discrepancies.append(f"{combo_id}: datos faltantes en una fuente")
            continue

        if py_row.get("edge_case", False):
            edge_cases.append(f"{combo_id}: edge case (g o m insuficiente)")
            continue

        for metric in metrics:
            r_val = float(r_row[metric]) if r_row[metric] != "NA" else float("nan")
            py_val = py_row[metric]
            if isinstance(py_val, bool):
                py_val = float(py_val)

            # Para g y m, comparar como enteros exactos
            if metric in ("g", "m"):
                r_val_int = int(r_val) if _isfinite(r_val) else None
                py_val_int = int(py_val) if _isfinite(py_val) else None
                row = canonical_row(
                    combo_id=combo_id,
                    pollutant=combo["pollutant"],
                    level=combo["level"],
                    stage="stage_02_homogeneity",
                    section="homogeneity",
                    participant_id="ALL",
                    metric=metric_labels.get(metric, metric),
                    app_value=float(r_val_int) if r_val_int is not None else float("nan"),
                    r_value=float(r_val_int) if r_val_int is not None else float("nan"),
                    python_value=float(py_val_int) if py_val_int is not None else float("nan"),
                    tolerance=0.5,  # Para enteros
                    notes="",
                )
            else:
                row = canonical_row(
                    combo_id=combo_id,
                    pollutant=combo["pollutant"],
                    level=combo["level"],
                    stage="stage_02_homogeneity",
                    section="homogeneity",
                    participant_id="ALL",
                    metric=metric_labels.get(metric, metric),
                    app_value=r_val,
                    r_value=r_val,
                    python_value=py_val,
                    tolerance=TOL_DEFAULT,
                    notes="",
                )
            all_rows.append(row)

        combos_processed.append(combo_id)

    write_canonical_csv(all_rows, OUTPUT_CSV)
    print(f"  CSV comparacion escrito: {OUTPUT_CSV}")

    # --- Reporte ---
    pass_count = sum(1 for r in all_rows if r["status"] == STATUS_PASS)
    fail_count = sum(1 for r in all_rows if r["status"] == STATUS_FAIL)
    edge_count = len(edge_cases)

    report_lines = [
        "# Reporte: Etapa 2 — Homogeneidad",
        "",
        f"**Fecha**: {__import__('datetime').date.today()}",
        "",
        "## Combos procesados",
    ]
    for cid in combos_processed:
        report_lines.append(f"- {cid}")
    report_lines.extend([
        "",
        "## Metricas evaluadas",
        "- g (numero de muestras)",
        "- m (numero de replicas)",
        "- Media general (mean de todos los valores)",
        "- x_pt (mediana de primera replica)",
        "- s_x_bar_sq (varianza de medias)",
        "- sw (DE intra-muestra)",
        "- ss_sq (varianza entre-muestras, abs())",
        "- ss (DE entre-muestras)",
        "- sigma_pt (mediana de |sample_2 - x_pt|)",
        "- MADe (1.483 * sigma_pt)",
        "- u_sigma_pt (1.25 * MADe / sqrt(g))",
        "- Criterio c (0.3 * sigma_pt)",
        "- Criterio expandido (F1*(0.3*sigma_pt)^2 + F2*sw^2)",
        "",
        "## Resumen PASS/FAIL",
        f"- PASS: {pass_count}",
        f"- FAIL: {fail_count}",
        f"- EDGE_CASE: {edge_count}",
        f"- KNOWN_DISCREPANCY: 0",
        "",
    ])

    if discrepancies:
        report_lines.append("## Discrepancias")
        for d in discrepancies:
            report_lines.append(f"- {d}")
        report_lines.append("")

    if edge_cases:
        report_lines.append("## Casos borde")
        for e in edge_cases:
            report_lines.append(f"- {e}")
        report_lines.append("")

    # Detalle de diferencias
    diff_rows = [r for r in all_rows if r["status"] == STATUS_FAIL]
    if diff_rows:
        report_lines.append("## Detalle de FAIL")
        for r in diff_rows:
            report_lines.append(
                f"- {r['combo_id']} {r['metric']}: "
                f"R={r['app_value']:.12e} Py={r['python_value']:.12e} "
                f"diff={r['diff_r_python']:.12e}"
            )
        report_lines.append("")

    # Valores maximos de diferencia
    if all_rows:
        diffs = [abs(r["diff_r_python"]) for r in all_rows
                 if r["diff_r_python"] == r["diff_r_python"]]
        max_diff = max(diffs) if diffs else 0
        report_lines.extend([
            "## Observaciones",
            f"- Maxima diferencia R vs Python: {max_diff:.12e}",
            f"- Tolerancia aplicada: {TOL_DEFAULT}",
            f"- Total comparaciones: {len(all_rows)}",
            f"- Combos con edge case: {edge_count}",
            "",
        ])

    report_lines.extend([
        "## Conclusion",
        "Etapa PASS" if fail_count == 0 else "Etapa con FAIL pendientes de revision",
        "",
    ])

    with open(OUTPUT_REPORT, "w") as f:
        f.write("\n".join(report_lines))
    print(f"  Reporte escrito: {OUTPUT_REPORT}")

    print("Etapa 2: Homogeneidad — FIN")


def _isfinite(x):
    """Verificar si un valor es finito."""
    if x is None:
        return False
    try:
        return math.isfinite(float(x))
    except (TypeError, ValueError):
        return False


if __name__ == "__main__":
    run_stage_02()
