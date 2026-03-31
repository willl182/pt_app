"""
Etapa 3: Estabilidad (Python)
Validacion de evaluacion de estabilidad.

Referencia: ISO 13528:2022, Seccion 9.3
Fuente: data/stability_n13.csv
Dependencias: resultados de homogeneidad (Etapa 2)

Uso:
    python3 validation/stage_03_stability.py

Outputs:
    validation/outputs/stage_03_stability_py.csv (intermedio)
    validation/outputs/stage_03_stability.csv (comparacion final)
    validation/outputs/stage_03_stability_report.md

Metricas validadas (13 por combo):
    g, m, general_mean_stab, x_pt_stab, s_x_bar_sq_stab, sw_stab,
    ss_sq_stab, ss_stab, diff_hom_stab, u_hom_mean, u_stab_mean,
    criterio_simple, criterio_expandido
"""

import sys
import os
import csv as csv_mod
import math

sys.path.insert(0, os.path.dirname(__file__))

from helpers import (
    COMBOS, make_combo_id, load_wide_data, median, load_summary_combo,
    TOL_DEFAULT, canonical_row, write_canonical_csv, CANONICAL_COLS,
    STATUS_PASS, STATUS_FAIL, STATUS_EDGE,
)

DATA_STABILITY = "data/stability_n13.csv"
DATA_HOMOGENEITY = "data/homogeneity_n13.csv"
HOM_PY_CSV = "validation/outputs/stage_02_homogeneity_py.csv"
OUTPUT_PY_CSV = "validation/outputs/stage_03_stability_py.csv"
OUTPUT_CSV = "validation/outputs/stage_03_stability.csv"
OUTPUT_REPORT = "validation/outputs/stage_03_stability_report.md"


def variance(values):
    """Calcular varianza muestral (ddof=1, como R var())."""
    n = len(values)
    if n < 2:
        return float("nan")
    m = sum(values) / n
    return sum((x - m) ** 2 for x in values) / (n - 1)


def std(values):
    """Calcular desviacion estandar muestral (ddof=1, como R sd())."""
    return math.sqrt(variance(values))


def load_wide_as_matrix(data_path, pollutant, level):
    """Cargar datos y pivotear a matriz g x m (lista de listas)."""
    wide = load_wide_data(data_path, pollutant, level)
    if len(wide) < 1:
        return [], []

    all_reps = set()
    for sid, reps in wide.items():
        all_reps.update(reps.keys())

    sorted_reps = sorted(all_reps, key=lambda x: int(x))
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


def load_hom_all_values(data_path, pollutant, level):
    """Cargar todos los valores de homogeneidad para un combo."""
    vals = []
    with open(data_path, "r") as f:
        reader = csv_mod.DictReader(f)
        for row in reader:
            if row["pollutant"] != pollutant:
                continue
            if row["level"] != level:
                continue
            vals.append(float(row["value"]))
    return vals


def run_stage_03():
    print("Etapa 3: Estabilidad — INICIO")

    # Leer resultados de homogeneidad (Python)
    hom_data = {}
    if os.path.exists(HOM_PY_CSV):
        with open(HOM_PY_CSV, "r") as f:
            reader = csv_mod.DictReader(f)
            for row in reader:
                hom_data[row["combo_id"]] = row
    else:
        print(f"  ADVERTENCIA: {HOM_PY_CSV} no encontrado. Ejecutar Fase 2 primero.")

    py_results = []

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        print(f"  Procesando: {combo['label']}")

        sids, matrix = load_wide_as_matrix(
            DATA_STABILITY, combo["pollutant"], combo["level"]
        )

        g = len(matrix)
        if g < 2:
            print(f"    ADVERTENCIA: menos de 2 muestras ({g}), saltando")
            py_results.append({
                "combo_id": combo_id, "pollutant": combo["pollutant"],
                "level": combo["level"], "g": g, "m": 0,
                "general_mean_stab": float("nan"), "x_pt_stab": float("nan"),
                "s_x_bar_sq_stab": float("nan"), "sw_stab": float("nan"),
                "ss_sq_stab": float("nan"), "ss_stab": float("nan"),
                "diff_hom_stab": float("nan"), "u_hom_mean": float("nan"),
                "u_stab_mean": float("nan"), "criterio_simple": float("nan"),
                "criterio_expandido": float("nan"), "edge_case": True,
            })
            continue

        m = len(matrix[0])
        if m < 2:
            print(f"    ADVERTENCIA: menos de 2 replicas ({m}), saltando")
            py_results.append({
                "combo_id": combo_id, "pollutant": combo["pollutant"],
                "level": combo["level"], "g": g, "m": m,
                "general_mean_stab": float("nan"), "x_pt_stab": float("nan"),
                "s_x_bar_sq_stab": float("nan"), "sw_stab": float("nan"),
                "ss_sq_stab": float("nan"), "ss_stab": float("nan"),
                "diff_hom_stab": float("nan"), "u_hom_mean": float("nan"),
                "u_stab_mean": float("nan"), "criterio_simple": float("nan"),
                "criterio_expandido": float("nan"), "edge_case": True,
            })
            continue

        # --- Calcular metricas de estabilidad ---
        means = row_means(matrix)
        general_mean_stab = sum(sum(row) for row in matrix) / (g * m)

        first_col = col_values(matrix, 0)
        x_pt_stab = median(first_col)

        s_x_bar_sq_stab = variance(means)

        if m == 2:
            col1 = col_values(matrix, 0)
            col2 = col_values(matrix, 1)
            range_sq_sum = sum((abs(a - b)) ** 2 for a, b in zip(col1, col2))
            sw_stab = math.sqrt(range_sq_sum / (2 * g))
        else:
            within_vars = [variance(row) for row in matrix]
            sw_stab = math.sqrt(sum(within_vars) / len(within_vars))

        sw_sq_stab = sw_stab ** 2

        # ss_sq = abs(s_x_bar_sq - sw_sq/m)
        ss_sq_stab = abs(s_x_bar_sq_stab - sw_sq_stab / m)
        ss_stab = math.sqrt(ss_sq_stab)

        # --- Datos de homogeneidad ---
        hom_row = hom_data.get(combo_id)
        if hom_row is None:
            print(f"    ADVERTENCIA: sin datos de homogeneidad para {combo_id}")
            continue

        general_mean_homog = float(hom_row["general_mean_homog"])
        sigma_pt_hom = float(hom_row["sigma_pt"])

        # diff_hom_stab
        diff_hom_stab = abs(general_mean_stab - general_mean_homog)

        # u_hom_mean = sd(all_hom_values) / sqrt(n_hom)
        hom_all_vals = load_hom_all_values(DATA_HOMOGENEITY, combo["pollutant"], combo["level"])
        n_hom = len(hom_all_vals)
        u_hom_mean = std(hom_all_vals) / math.sqrt(n_hom) if n_hom > 1 else float("nan")

        # u_stab_mean = sd(all_stab_values) / sqrt(n_stab)
        stab_all_vals = [v for row in matrix for v in row]
        n_stab = len(stab_all_vals)
        u_stab_mean = std(stab_all_vals) / math.sqrt(n_stab) if n_stab > 1 else float("nan")

        # criterio_simple = 0.3 * sigma_pt_hom
        criterio_simple = 0.3 * sigma_pt_hom

        # criterio_expandido = c + 2*sqrt(u_hom_mean^2 + u_stab_mean^2)
        if _isfinite(u_hom_mean) and _isfinite(u_stab_mean):
            criterio_exp = criterio_simple + 2 * math.sqrt(u_hom_mean ** 2 + u_stab_mean ** 2)
        else:
            criterio_exp = float("nan")

        py_results.append({
            "combo_id": combo_id,
            "pollutant": combo["pollutant"],
            "level": combo["level"],
            "g": g,
            "m": m,
            "general_mean_stab": general_mean_stab,
            "x_pt_stab": x_pt_stab,
            "s_x_bar_sq_stab": s_x_bar_sq_stab,
            "sw_stab": sw_stab,
            "ss_sq_stab": ss_sq_stab,
            "ss_stab": ss_stab,
            "diff_hom_stab": diff_hom_stab,
            "u_hom_mean": u_hom_mean,
            "u_stab_mean": u_stab_mean,
            "criterio_simple": criterio_simple,
            "criterio_expandido": criterio_exp,
            "edge_case": False,
        })

        print(f"    g={g} m={m} mean_stab={general_mean_stab:.8f} diff={diff_hom_stab:.8f} c={criterio_simple:.8f}")

    # Guardar resultados Python como CSV intermedio
    os.makedirs(os.path.dirname(OUTPUT_PY_CSV), exist_ok=True)
    fieldnames = ["combo_id", "pollutant", "level", "g", "m",
                  "general_mean_stab", "x_pt_stab", "s_x_bar_sq_stab", "sw_stab",
                  "ss_sq_stab", "ss_stab", "diff_hom_stab", "u_hom_mean",
                  "u_stab_mean", "criterio_simple", "criterio_expandido", "edge_case"]
    with open(OUTPUT_PY_CSV, "w", newline="") as f:
        writer = csv_mod.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(py_results)
    print(f"  Resultados Python guardados: {OUTPUT_PY_CSV}")

    # --- Comparacion tripartita ---
    print("  Generando comparacion tripartita...")

    # Leer resultados R
    r_data = {}
    r_csv_path = "validation/outputs/stage_03_stability_r.csv"
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
        "g", "m", "general_mean_stab", "x_pt_stab", "s_x_bar_sq_stab",
        "sw_stab", "ss_sq_stab", "ss_stab", "diff_hom_stab",
        "u_hom_mean", "u_stab_mean", "criterio_simple", "criterio_expandido",
    ]
    metric_labels = {
        "g": "g",
        "m": "m",
        "general_mean_stab": "Media general stab",
        "x_pt_stab": "x_pt stab",
        "s_x_bar_sq_stab": "s_x_bar_sq stab",
        "sw_stab": "sw stab",
        "ss_sq_stab": "ss_sq stab",
        "ss_stab": "ss stab",
        "diff_hom_stab": "diff_hom_stab",
        "u_hom_mean": "u_hom_mean",
        "u_stab_mean": "u_stab_mean",
        "criterio_simple": "Criterio simple",
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

            if metric in ("g", "m"):
                r_val_int = int(r_val) if _isfinite(r_val) else None
                py_val_int = int(py_val) if _isfinite(py_val) else None
                row = canonical_row(
                    combo_id=combo_id,
                    pollutant=combo["pollutant"],
                    level=combo["level"],
                    stage="stage_03_stability",
                    section="stability",
                    participant_id="ALL",
                    metric=metric_labels.get(metric, metric),
                    app_value=float(r_val_int) if r_val_int is not None else float("nan"),
                    r_value=float(r_val_int) if r_val_int is not None else float("nan"),
                    python_value=float(py_val_int) if py_val_int is not None else float("nan"),
                    tolerance=0.5,
                    notes="",
                )
            else:
                row = canonical_row(
                    combo_id=combo_id,
                    pollutant=combo["pollutant"],
                    level=combo["level"],
                    stage="stage_03_stability",
                    section="stability",
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
        "# Reporte: Etapa 3 — Estabilidad",
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
        "- g (numero de muestras estabilidad)",
        "- m (numero de replicas estabilidad)",
        "- Media general stab (mean de todos los valores de estabilidad)",
        "- x_pt stab (mediana de primera replica estabilidad)",
        "- s_x_bar_sq stab (varianza de medias estabilidad)",
        "- sw stab (DE intra-muestra estabilidad)",
        "- ss_sq stab (varianza entre-muestras estabilidad)",
        "- ss stab (DE entre-muestras estabilidad)",
        "- diff_hom_stab (abs(mean_stab - mean_hom))",
        "- u_hom_mean (sd(all_hom_values) / sqrt(n_hom))",
        "- u_stab_mean (sd(all_stab_values) / sqrt(n_stab))",
        "- Criterio simple (0.3 * sigma_pt_hom)",
        "- Criterio expandido (c + 2*sqrt(u_hom^2 + u_stab^2))",
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

    print("Etapa 3: Estabilidad — FIN")


def _isfinite(x):
    if x is None:
        return False
    try:
        return math.isfinite(float(x))
    except (TypeError, ValueError):
        return False


if __name__ == "__main__":
    run_stage_03()
