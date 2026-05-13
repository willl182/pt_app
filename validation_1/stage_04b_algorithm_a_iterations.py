"""
Etapa 4b: Algoritmo A detallado (Python)
Validacion de iteraciones paso a paso del Algoritmo A.
"""

import csv
import math
import os

from helpers import COMBOS, make_combo_id, STATUS_PASS, STATUS_FAIL, write_report_md

DATA_SUMMARY = "../data/for_validation/summary_n4.csv"
OUTPUT_PY_CSV = "outputs/stage_04b_algorithm_a_iterations_py.csv"
R_CSV = "outputs/stage_04b_algorithm_a_iterations_r.csv"
OUTPUT_CSV = "outputs/stage_04b_algorithm_a_iterations.csv"
OUTPUT_REPORT = "outputs/stage_04b_algorithm_a_iterations_report.md"
MAX_ITER = 50
TOL_REL = 0.5
SIGMA_EPS = 1e-15


def median(values):
    vals = sorted(v for v in values if math.isfinite(v))
    n = len(vals)
    if n == 0:
        return float("nan")
    mid = n // 2
    if n % 2 == 1:
        return vals[mid]
    return (vals[mid - 1] + vals[mid]) / 2.0


def load_combo_values(filepath, pollutant, level):
    rows = []
    with open(filepath, "r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["pollutant"] != pollutant or row["level"] != level:
                continue
            if row["participant_id"].lower() == "ref":
                continue
            rows.append(float(row["mean_value"]))
    return sorted(v for v in rows if math.isfinite(v))


def run_algorithm_a_trace(values, max_iter=MAX_ITER, tol=TOL_REL):
    values = sorted(v for v in values if math.isfinite(v))
    if len(values) < 4:
        return {"error": "Algoritmo A requiere al menos 4 valores"}

    x_median = median(values)
    x_mad = median([abs(v - x_median) for v in values])
    sigma = 1.483 * x_mad
    trace = [{
        "iteration": 0,
        "step": "initial",
        "n": len(values),
        "x_median": x_median,
        "x_mad": x_mad,
        "sigma": sigma,
        "x_w_median": x_median,
        "x_w_mad": x_mad,
        "sigma_w": sigma,
        "max_abs_z": 0.0,
        "converged": False,
    }]

    if sigma < SIGMA_EPS:
        trace.append({**trace[0], "converged": True})
        return {
            "assigned_value": x_median,
            "robust_sd": sigma,
            "iterations": 0,
            "converged": True,
            "trace": trace,
            "winsorized_values": values,
        }

    x_w = values
    for iter_num in range(1, max_iter + 1):
        z = [(v - x_median) / (1.5 * sigma) for v in values]
        x_w = [
            x_median - 1.5 * sigma if zi < -1 else
            x_median + 1.5 * sigma if zi > 1 else
            v
            for v, zi in zip(values, z)
        ]
        x_w_median = median(x_w)
        x_w_mad = median([abs(v - x_w_median) for v in x_w])
        sigma_w = 1.06 * x_w_mad
        max_abs_z = max(abs(zi) for zi in z)
        converged = abs(sigma_w - sigma) <= tol * sigma
        trace.append({
            "iteration": iter_num,
            "step": "update",
            "n": len(values),
            "x_median": x_median,
            "x_mad": x_mad,
            "sigma": sigma,
            "x_w_median": x_w_median,
            "x_w_mad": x_w_mad,
            "sigma_w": sigma_w,
            "max_abs_z": max_abs_z,
            "converged": converged,
        })
        if converged:
            return {
                "assigned_value": x_median,
                "robust_sd": sigma_w,
                "iterations": iter_num,
                "converged": True,
                "trace": trace,
                "winsorized_values": x_w,
            }
        sigma = sigma_w

    return {
        "assigned_value": x_median,
        "robust_sd": sigma,
        "iterations": max_iter,
        "converged": False,
        "trace": trace,
        "winsorized_values": x_w,
    }


def fmt_num(value):
    if math.isfinite(value):
        return format(value, ".17g")
    return "NA"


def main():
    rows = []
    combos_processed = []
    for combo in COMBOS:
        values = load_combo_values(DATA_SUMMARY, combo["pollutant"], combo["level"])
        if len(values) < 4:
            continue
        algo = run_algorithm_a_trace(values)
        if "error" in algo:
            continue
        combos_processed.append(combo["label"])
        for row in algo["trace"]:
            rows.append({
                "combo_id": make_combo_id(combo["pollutant"], combo["level"]),
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "stage": "stage_04b_algorithm_a_iterations",
                "section": "Algoritmo A",
                "iteration": row["iteration"],
                "step": row["step"],
                "n": row["n"],
                "x_median": row["x_median"],
                "x_mad": row["x_mad"],
                "sigma": row["sigma"],
                "x_w_median": row["x_w_median"],
                "x_w_mad": row["x_w_mad"],
                "sigma_w": row["sigma_w"],
                "max_abs_z": row["max_abs_z"],
                "converged": row["converged"],
                "assigned_value": algo["assigned_value"],
                "robust_sd": algo["robust_sd"],
                "value_count": len(values),
                "values": ";".join(fmt_num(v) for v in values),
                "winsorized_values": ";".join(fmt_num(v) for v in algo["winsorized_values"]),
            })

    os.makedirs(os.path.dirname(OUTPUT_PY_CSV), exist_ok=True)
    with open(OUTPUT_PY_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()) if rows else [])
        if rows:
            writer.writeheader()
            writer.writerows(rows)

    # La comparación de esta fase es contra R, fila por fila
    r_map = {}
    if os.path.exists(R_CSV):
        with open(R_CSV, "r", newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                key = (row["combo_id"], row["iteration"], row["step"])
                r_map[key] = row

    comp_rows = []
    for row in rows:
        key = (row["combo_id"], str(row["iteration"]), row["step"])
        r_row = r_map.get(key)
        r_value = float(r_row["sigma_w"]) if r_row and r_row["sigma_w"] not in ("", "NA") else float("nan")
        py_value = row["sigma_w"]
        diff = r_value - py_value if math.isfinite(r_value) and math.isfinite(py_value) else float("nan")
        status = STATUS_PASS if math.isfinite(diff) and abs(diff) <= 1e-9 else STATUS_FAIL
        comp_rows.append({
            **row,
            "r_sigma_w": r_value,
            "python_sigma_w": py_value,
            "diff_sigma_w": diff,
            "status": status,
        })

    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        fieldnames = list(comp_rows[0].keys()) if comp_rows else []
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if comp_rows:
            writer.writeheader()
            writer.writerows(comp_rows)

    report_lines = [
        "# Reporte: Etapa 4b: Algoritmo A detallado",
        "",
        f"- Combos procesados: {', '.join(combos_processed) if combos_processed else 'ninguno'}",
        f"- Filas: {len(rows)}",
        f"- PASS: {sum(1 for r in comp_rows if r['status'] == STATUS_PASS)}",
        f"- FAIL: {sum(1 for r in comp_rows if r['status'] == STATUS_FAIL)}",
        "",
        "Conclusion: etapa completada",
    ]
    write_report_md(report_lines, OUTPUT_REPORT)


if __name__ == "__main__":
    main()
