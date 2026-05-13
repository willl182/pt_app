"""
Etapa 4: Cadena de incertidumbre (Python)
Validacion de propagacion downstream de incertidumbres.

Referencia: ISO 13528:2022
Fuente: resultados Etapas 1-3, data/summary_n13.csv

Uso:
    python3 validation/stage_04_uncertainty_chain.py

Outputs:
    validation/outputs/stage_04_uncertainty_chain_py.csv (intermedio)
    validation/outputs/stage_04_uncertainty_chain.csv (comparacion final)
    validation/outputs/stage_04_uncertainty_chain_report.md

Metodos validados (por separado):
    1. Referencia (x_pt de referencia, sigma_pt de homogeneidad)
    2. Consenso MADe (mediana, sigma_pt = 1.483 * MADe)
    3. Consenso nIQR (mediana, sigma_pt = nIQR)
    4. Algoritmo A (Algoritmo A winsorizado)

Metricas por metodo:
    - x_pt (valor asignado)
    - sigma_pt (desviacion estandar para puntajes)
    - u_xpt (incertidumbre estandar de x_pt)
    - u_hom (incertidumbre por homogeneidad)
    - u_stab (incertidumbre por estabilidad)
    - u_xpt_def (incertidumbre combinada: sqrt(u_xpt^2 + u_hom^2 + u_stab^2))
    - U_xpt (incertidumbre expandida: k * u_xpt_def)
"""

import sys
import os
import csv as csv_mod
import math

sys.path.insert(0, os.path.dirname(__file__))

from helpers import (
    COMBOS, make_combo_id, load_summary_combo, load_wide_data,
    median, mad_e, niqr, TOL_DEFAULT, canonical_row, write_canonical_csv,
    CANONICAL_COLS, STATUS_PASS, STATUS_FAIL, STATUS_EDGE,
)

DATA_SUMMARY = "data/summary_n13.csv"
DATA_HOMOGENEITY = "data/homogeneity_n13.csv"
DATA_STABILITY = "data/stability_n13.csv"
HOM_PY_CSV = "validation/outputs/stage_02_homogeneity_py.csv"
STAB_PY_CSV = "validation/outputs/stage_03_stability_py.csv"
HOM_R_CSV = "validation/outputs/stage_02_homogeneity_r.csv"
STAB_R_CSV = "validation/outputs/stage_03_stability_r.csv"
OUTPUT_PY_CSV = "validation/outputs/stage_04_uncertainty_chain_py.csv"
OUTPUT_CSV = "validation/outputs/stage_04_uncertainty_chain.csv"
OUTPUT_REPORT = "validation/outputs/stage_04_uncertainty_chain_report.md"


def std(values):
    """Calcular desviacion estandar muestral (ddof=1, como R sd())."""
    n = len(values)
    if n < 2:
        return float("nan")
    m = sum(values) / n
    var = sum((x - m) ** 2 for x in values) / (n - 1)
    return math.sqrt(var)


def quantile_type7(values, prob):
    """Calcular cuantil con metodo type-7 (interpolacion lineal, como R)."""
    s = sorted(values)
    n = len(s)
    if n == 0:
        return float("nan")
    if n == 1:
        return s[0]
    h = (n - 1) * prob + 1
    lo = int(math.floor(h))
    hi = int(math.ceil(h))
    if lo == hi or lo < 1:
        return s[max(0, lo - 1)]
    frac = h - lo
    return s[lo - 1] * (1 - frac) + s[hi - 1] * frac


def calculate_niqr(values):
    """Calcular nIQR = 0.7413 * IQR."""
    q1 = quantile_type7(values, 0.25)
    q3 = quantile_type7(values, 0.75)
    return 0.7413 * (q3 - q1)


def run_algorithm_a(values, max_iter=50, tol=0.5):
    """Algoritmo A de winsorizacion iterativa (ISO 13528:2022 Anexo C)."""
    n = len(values)
    if n < 4:
        return {"error": "Algoritmo A requiere al menos 4 valores"}

    x = sorted(values)
    x_median = median(x)
    x_mad = median([abs(xi - x_median) for xi in x])
    sigma = 1.483 * x_mad

    if sigma < 1e-15:
        return {
            "assigned_value": x_median,
            "robust_sd": sigma,
            "iterations": 0,
            "converged": True,
        }

    for iter_num in range(1, max_iter + 1):
        z = [(xi - x_median) / (1.5 * sigma) for xi in x]
        x_w = [
            x_median - 1.5 * sigma if zi < -1
            else x_median + 1.5 * sigma if zi > 1
            else xi
            for xi, zi in zip(x, z)
        ]
        x_w_median = median(x_w)
        x_w_mad = median([abs(xi - x_w_median) for xi in x_w])
        sigma_w = 1.06 * x_w_mad

        if abs(sigma_w - sigma) <= tol * sigma:
            return {
                "assigned_value": x_median,
                "robust_sd": sigma_w,
                "iterations": iter_num,
                "converged": True,
            }
        sigma = sigma_w

    return {
        "assigned_value": x_median,
        "robust_sd": sigma,
        "iterations": max_iter,
        "converged": False,
    }


def calculate_uncertainty_chain(x_pt, sigma_pt, n_part, u_hom, u_stab, k=2):
    """Calcular cadena de incertidumbre por metodo."""
    if math.isfinite(sigma_pt) and n_part > 0:
        u_xpt = 1.25 * sigma_pt / math.sqrt(n_part)
    else:
        u_xpt = float("nan")

    if math.isfinite(u_xpt) and math.isfinite(u_hom) and math.isfinite(u_stab):
        u_xpt_def = math.sqrt(u_xpt**2 + u_hom**2 + u_stab**2)
    else:
        u_xpt_def = float("nan")

    if math.isfinite(u_xpt_def):
        U_xpt = k * u_xpt_def
    else:
        U_xpt = float("nan")

    return {
        "x_pt": x_pt,
        "sigma_pt": sigma_pt,
        "u_xpt": u_xpt,
        "u_hom": u_hom,
        "u_stab": u_stab,
        "u_xpt_def": u_xpt_def,
        "U_xpt": U_xpt,
    }


def load_homogeneity_results(csv_path):
    """Cargar resultados de homogeneidad desde CSV."""
    results = {}
    with open(csv_path, "r") as f:
        reader = csv_mod.DictReader(f)
        for row in reader:
            combo_id = row["combo_id"]
            results[combo_id] = {
                "x_pt": float(row["x_pt"]),
                "sigma_pt": float(row["sigma_pt"]),
                "u_sigma_pt": float(row["u_sigma_pt"]),
                "ss": float(row["ss"]),
            }
    return results


def load_stability_results(csv_path):
    """Cargar resultados de estabilidad desde CSV."""
    results = {}
    with open(csv_path, "r") as f:
        reader = csv_mod.DictReader(f)
        for row in reader:
            combo_id = row["combo_id"]
            results[combo_id] = {
                "u_stab_mean": float(row["u_stab_mean"]),
            }
    return results


def run_stage_04():
    print("Etapa 4: Cadena de incertidumbre — INICIO")

    # Leer resultados de etapas anteriores
    hom_r = load_homogeneity_results(HOM_R_CSV)
    stab_r = load_stability_results(STAB_R_CSV)

    all_rows = []
    discrepancies = []
    edge_cases = []
    combos_processed = []

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        print(f"  Procesando: {combo['label']}")

        # Fase 4.1: Cargar datos
        if combo_id not in hom_r:
            print(f"    ADVERTENCIA: no hay datos de homogeneidad, saltando")
            edge_cases.append(f"{combo_id}: sin datos de homogeneidad")
            continue

        if combo_id not in stab_r:
            print(f"    ADVERTENCIA: no hay datos de estabilidad, saltando")
            edge_cases.append(f"{combo_id}: sin datos de estabilidad")
            continue

        # Datos de participantes
        agg = load_summary_combo(DATA_SUMMARY, combo["pollutant"], combo["level"])
        n_part = len(agg)

        if n_part < 2:
            print(f"    ADVERTENCIA: menos de 2 participantes, saltando")
            edge_cases.append(f"{combo_id}: menos de 2 participantes")
            continue

        # Fase 4.2: Calcular cadena de incertidumbre por metodo
        values = [v["mean_value"] for v in agg.values()]

        # Obtener u_hom y u_stab de etapas anteriores
        u_hom_val = hom_r[combo_id]["ss"]
        u_stab_val = stab_r[combo_id]["u_stab_mean"]

        # Metodo 1: Referencia
        x_pt_ref = hom_r[combo_id]["x_pt"]
        sigma_pt_ref = hom_r[combo_id]["sigma_pt"]
        chain_ref = calculate_uncertainty_chain(
            x_pt_ref, sigma_pt_ref, n_part, u_hom_val, u_stab_val
        )

        # Metodo 2: Consenso MADe
        median_val = median(values)
        mad_val = mad_e(values) / 1.483  # Recuperar MAD original
        sigma_pt_2a = 1.483 * mad_val
        chain_2a = calculate_uncertainty_chain(
            median_val, sigma_pt_2a, n_part, u_hom_val, u_stab_val
        )

        # Metodo 3: Consenso nIQR
        sigma_pt_2b = calculate_niqr(values)
        chain_2b = calculate_uncertainty_chain(
            median_val, sigma_pt_2b, n_part, u_hom_val, u_stab_val
        )

        # Metodo 4: Algoritmo A
        algo_res = run_algorithm_a(values, max_iter=50, tol=0.5)
        if "error" not in algo_res:
            chain_algo = calculate_uncertainty_chain(
                algo_res["assigned_value"],
                algo_res["robust_sd"],
                n_part,
                u_hom_val,
                u_stab_val,
            )
        else:
            chain_algo = {
                "x_pt": float("nan"),
                "sigma_pt": float("nan"),
                "u_xpt": float("nan"),
                "u_hom": u_hom_val,
                "u_stab": u_stab_val,
                "u_xpt_def": float("nan"),
                "U_xpt": float("nan"),
            }

        # Fase 4.3: Generar filas canonicas
        methods = [
            ("Referencia", chain_ref),
            ("Consenso MADe", chain_2a),
            ("Consenso nIQR", chain_2b),
            ("Algoritmo A", chain_algo),
        ]

        for method_name, chain in methods:
            for metric in ["x_pt", "sigma_pt", "u_xpt", "u_hom", "u_stab", "u_xpt_def", "U_xpt"]:
                row = canonical_row(
                    combo_id=combo_id,
                    pollutant=combo["pollutant"],
                    level=combo["level"],
                    stage="stage_04_uncertainty_chain",
                    section=method_name,
                    participant_id="",
                    metric=metric,
                    app_value=float("nan"),  # Se comparara despues
                    r_value=float("nan"),
                    python_value=chain[metric],
                    tolerance=TOL_DEFAULT,
                )
                all_rows.append(row)

        combos_processed.append(combo_id)

    # Guardar resultados Python como CSV intermedio
    py_rows = []
    for row in all_rows:
        py_rows.append({
            "combo_id": row["combo_id"],
            "pollutant": row["pollutant"],
            "level": row["level"],
            "method": row["section"],
            "metric": row["metric"],
            "value": row["python_value"],
            "edge_case": False,
        })

    os.makedirs(os.path.dirname(OUTPUT_PY_CSV), exist_ok=True)
    with open(OUTPUT_PY_CSV, "w", newline="") as f:
        writer = csv_mod.DictWriter(
            f,
            fieldnames=["combo_id", "pollutant", "level", "method", "metric", "value", "edge_case"],
        )
        writer.writeheader()
        writer.writerows(py_rows)
    print(f"  CSV intermedio Python escrito: {OUTPUT_PY_CSV}")

    # Leer CSV R y comparar
    comparison_rows = []
    r_data = {}
    with open(OUTPUT_PY_CSV.replace("_py.csv", "_r.csv"), "r") as f:
        reader = csv_mod.DictReader(f)
        for row in reader:
            key = (row["combo_id"], row["method"], row["metric"])
            r_data[key] = float(row["value"]) if row["value"] != "NA" else float("nan")

    for py_row in all_rows:
        key = (py_row["combo_id"], py_row["section"], py_row["metric"])
        r_value = r_data.get(key, float("nan"))
        python_value = py_row["python_value"]

        # Calcular diferencias
        diff_rp = r_value - python_value if math.isfinite(r_value) and math.isfinite(python_value) else float("nan")

        # Determinar status
        if not math.isfinite(diff_rp):
            status = STATUS_FAIL
        elif abs(diff_rp) <= TOL_DEFAULT:
            status = STATUS_PASS
        else:
            status = STATUS_FAIL

        comparison_row = {
            "combo_id": py_row["combo_id"],
            "pollutant": py_row["pollutant"],
            "level": py_row["level"],
            "stage": "stage_04_uncertainty_chain",
            "section": py_row["section"],
            "participant_id": py_row["participant_id"],
            "metric": py_row["metric"],
            "app_value": float("nan"),
            "r_value": r_value,
            "python_value": python_value,
            "diff_app_r": float("nan"),
            "diff_app_python": float("nan"),
            "diff_r_python": diff_rp,
            "status": status,
            "tolerance": TOL_DEFAULT,
            "notes": "",
        }
        comparison_rows.append(comparison_row)

    write_canonical_csv(comparison_rows, OUTPUT_CSV)
    print(f"  CSV comparacion escrito: {OUTPUT_CSV}")

    # Generar reporte
    pass_count = sum(1 for r in comparison_rows if r["status"] == STATUS_PASS)
    fail_count = sum(1 for r in comparison_rows if r["status"] == STATUS_FAIL)

    report_lines = [
        "# Reporte: Etapa 4: Cadena de incertidumbre",
        "",
        f"**Fecha**: {os.popen('date +%Y-%m-%d').read().strip()}",
        "",
        "## Combos procesados",
    ]
    for cid in combos_processed:
        report_lines.append(f"- {cid}")

    report_lines.extend([
        "",
        "## Resumen PASS/FAIL",
        f"- PASS: {pass_count}",
        f"- FAIL: {fail_count}",
        f"- EDGE_CASE: 0",
        f"- KNOWN_DISCREPANCY: 0",
        "",
        "## Observaciones",
        "(pendiente)",
        "",
        "## Conclusion",
        "Etapa PASS" if fail_count == 0 else "Etapa con FAIL pendientes de revision",
    ])

    with open(OUTPUT_REPORT, "w") as f:
        f.write("\n".join(report_lines))
    print(f"  Reporte escrito: {OUTPUT_REPORT}")

    print("Etapa 4: Cadena de incertidumbre — FIN")


if __name__ == "__main__":
    run_stage_04()
