"""
Etapa 3: Estabilidad (Python)
Validación de estadísticos y criterios de estabilidad.

Referencia: ISO 13528:2022, Sección 9.3
Fuente: data/stability_n13.csv + data/homogeneity_n13.csv
Combos primarios: O3 × 3 niveles (0, 80, 180 nmol/mol)

Métricas validadas (22 numéricas × 3 combos + 4 evaluaciones × 3 combos = 78 filas):
  ANOVA de estabilidad:
    g_stab, m_stab, general_mean_stab, x_pt_stab,
    s_x_bar_sq_stab, s_xt_stab, sw_stab, sw_sq_stab,
    ss_sq_stab, ss_stab
  Delta y criterios:
    media_hom, media_stab, diff_hom_stab (Dmax),
    hom_MADe, hom_nIQR,
    c_stab_MADe, c_stab_nIQR,
    c_stab_exp_MADe, c_stab_exp_nIQR,
    u_hom_mean, u_stab_mean, u_stab
  Evaluaciones:
    Dmax_vs_c_MADe, Dmax_vs_c_nIQR,
    Dmax_vs_exp_MADe, Dmax_vs_exp_nIQR

Dependencia: necesita resultados de Etapa 2 (homogeneidad)

Uso:
    cd /home/w182/w421/pt_app
    python3 validation_2/stage_03_stability.py
"""

import sys
import os
import math
import csv as csv_mod
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from helpers import (
    COMBOS, make_combo_id, load_wide_data, median, iqr_type7,
    compare_values, write_canonical_csv, write_report_md, CANONICAL_COLS,
    STATUS_PASS, STATUS_FAIL, STATUS_EDGE, STATUS_KNOWN_DISC,
    TOL_DEFAULT,
)

DATA_HOMOGENEITY = "data/homogeneity_n13.csv"
DATA_STABILITY   = "data/stability_n13.csv"
OUTPUT_R_CSV     = "validation_2/outputs/stage_03_stability_r.csv"
OUTPUT_CSV       = "validation_2/outputs/stage_03_stability.csv"
OUTPUT_REPORT    = "validation_2/outputs/stage_03_stability_report.md"


def variance_ddof1(values):
    """Varianza muestral con ddof=1 (equivalente a R var())."""
    n = len(values)
    if n < 2:
        return float("nan")
    m = sum(values) / n
    return sum((x - m) ** 2 for x in values) / (n - 1)


def calc_homogeneity_separate(wide_df):
    """Calcular estadísticos de homogeneidad (para uso en estabilidad)."""
    import pandas as pd
    sample_cols = sorted(
        [c for c in wide_df.columns if c.startswith("sample_") and c.replace("sample_", "").isdigit()],
        key=lambda c: int(c.split("_")[1])
    )
    matrix = wide_df[sample_cols].values

    g = matrix.shape[0]
    m = matrix.shape[1]

    if g < 2:
        return {"error": "Se necesitan al menos 2 muestras."}

    sample_means = np.mean(matrix, axis=1)
    general_mean_homog = np.mean(matrix)
    x_pt = median(matrix[:, 0].tolist())

    s_x_bar_sq = variance_ddof1(sample_means.tolist())
    s_xt = math.sqrt(s_x_bar_sq) if math.isfinite(s_x_bar_sq) and s_x_bar_sq >= 0 else float("nan")

    if m == 2:
        col1 = matrix[:, 0].tolist()
        col2 = matrix[:, 1].tolist()
        range_sq_sum = sum((a - b) ** 2 for a, b in zip(col1, col2))
        sw = math.sqrt(range_sq_sum / (2 * g))
    else:
        within_vars = [variance_ddof1(matrix[i, :].tolist()) for i in range(g)]
        sw = math.sqrt(sum(within_vars) / len(within_vars))

    sw_sq = sw ** 2
    ss_sq = abs(s_x_bar_sq - sw_sq / m)
    ss = math.sqrt(ss_sq)

    col2_vals = matrix[:, 1].tolist()
    abs_diff_from_xpt = [abs(v - x_pt) for v in col2_vals]
    sigma_pt = median(abs_diff_from_xpt)
    MADe = 1.483 * sigma_pt
    u_sigma_pt = 1.25 * MADe / math.sqrt(g)

    sample1 = matrix[:, 0].tolist()
    nIQR = 0.7413 * iqr_type7(sample1)

    return {
        "g": g, "m": m, "general_mean_homog": general_mean_homog,
        "x_pt": x_pt, "s_x_bar_sq": s_x_bar_sq, "s_xt": s_xt,
        "sw": sw, "sw_sq": sw_sq, "ss_sq": ss_sq, "ss": ss,
        "sigma_pt": sigma_pt, "MADe": MADe, "u_sigma_pt": u_sigma_pt,
        "nIQR": nIQR, "error": None,
    }


def calc_stability(wide_stab, wide_hom):
    """Calcular todos los estadísticos de estabilidad.

    Args:
        wide_stab: pandas DataFrame con datos de estabilidad en formato ancho
        wide_hom: pandas DataFrame con datos de homogeneidad en formato ancho

    Returns:
        dict con todos los estadísticos de estabilidad y criterios
    """
    # --- Cálculos de homogeneidad primero ---
    hom = calc_homogeneity_separate(wide_hom)
    if hom.get("error"):
        return {"error": f"Error homogeneidad: {hom['error']}"}

    # --- ANOVA de estabilidad ---
    sample_cols_stab = sorted(
        [c for c in wide_stab.columns if c.startswith("sample_") and c.replace("sample_", "").isdigit()],
        key=lambda c: int(c.split("_")[1])
    )
    stab_matrix = wide_stab[sample_cols_stab].values

    g_stab = stab_matrix.shape[0]
    m_stab = stab_matrix.shape[1]

    if g_stab < 2:
        return {"error": "Se necesitan al menos 2 muestras de estabilidad."}
    if m_stab < 2:
        return {"error": "Se necesitan al menos 2 replicas de estabilidad."}

    # Medias por muestra (estabilidad)
    stab_sample_means = np.mean(stab_matrix, axis=1)

    # Media general de estabilidad: mean de TODOS los valores
    general_mean_stab = np.mean(stab_matrix)

    # x_pt_stab: mediana de la primera columna
    x_pt_stab = median(stab_matrix[:, 0].tolist())

    # Varianza de medias muestrales de estabilidad (ddof=1)
    s_x_bar_sq_stab = variance_ddof1(stab_sample_means.tolist())
    s_xt_stab = math.sqrt(s_x_bar_sq_stab) if math.isfinite(s_x_bar_sq_stab) and s_x_bar_sq_stab >= 0 else float("nan")

    # sw_stab: DE intra-muestra (rango para m=2)
    if m_stab == 2:
        col1 = stab_matrix[:, 0].tolist()
        col2 = stab_matrix[:, 1].tolist()
        range_sq_sum = sum((a - b) ** 2 for a, b in zip(col1, col2))
        sw_stab = math.sqrt(range_sq_sum / (2 * g_stab))
    else:
        within_vars = [variance_ddof1(stab_matrix[i, :].tolist()) for i in range(g_stab)]
        sw_stab = math.sqrt(sum(within_vars) / len(within_vars))

    sw_sq_stab = sw_stab ** 2

    # ss_stab: DE entre-muestras de estabilidad
    ss_sq_stab = abs(s_x_bar_sq_stab - sw_sq_stab / m_stab)
    ss_stab = math.sqrt(ss_sq_stab)

    # --- Dmax = |media_estab - media_hom| ---
    diff_hom_stab = abs(general_mean_stab - hom["general_mean_homog"])

    # --- Criterios usando MADe y nIQR de HOMOGENEIDAD ---
    c_stab_MADe = 0.3 * hom["MADe"]
    c_stab_nIQR = 0.3 * hom["nIQR"]

    # --- Incertidumbres de las medias ---
    # u_hom_mean: SD de todos los valores de homogeneidad / sqrt(n)
    sample_cols_hom = sorted(
        [c for c in wide_hom.columns if c.startswith("sample_") and c.replace("sample_", "").isdigit()],
        key=lambda c: int(c.split("_")[1])
    )
    hom_values = wide_hom[sample_cols_hom].values.flatten().tolist()
    hom_values = [v for v in hom_values if math.isfinite(v)]
    n_hom = len(hom_values)
    u_hom_mean = (sum(hom_values) / n_hom - 0 + 0) if n_hom > 0 else float("nan")  # placeholder
    # Calculate u_hom_mean properly
    import statistics
    sd_hom = statistics.pstdev(hom_values) if n_hom > 1 else 0.0
    # R's sd() uses ddof=1, which is statistics.stdev in Python
    sd_hom_ddof1 = statistics.stdev(hom_values) if n_hom > 1 else 0.0
    u_hom_mean = sd_hom_ddof1 / math.sqrt(n_hom)

    # u_stab_mean: SD de todos los valores de estabilidad / sqrt(n)
    stab_values = wide_stab[sample_cols_stab].values.flatten().tolist()
    stab_values = [v for v in stab_values if math.isfinite(v)]
    n_stab = len(stab_values)
    sd_stab_ddof1 = statistics.stdev(stab_values) if n_stab > 1 else 0.0
    u_stab_mean = sd_stab_ddof1 / math.sqrt(n_stab)

    # --- Criterios expandidos ---
    # c_stab_exp_MADe = c_stab_MADe + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
    c_stab_exp_MADe = c_stab_MADe + 2 * math.sqrt(u_hom_mean ** 2 + u_stab_mean ** 2)
    # c_stab_exp_nIQR = c_stab_nIQR + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)
    c_stab_exp_nIQR = c_stab_nIQR + 2 * math.sqrt(u_hom_mean ** 2 + u_stab_mean ** 2)

    # --- u_stab para cadena de incertidumbre ---
    # Si Dmax ≤ c_stab → u_stab = 0; si no → u_stab = Dmax / sqrt(3)
    if diff_hom_stab <= c_stab_MADe:
        u_stab = 0.0
    else:
        u_stab = diff_hom_stab / math.sqrt(3)

    # --- Evaluaciones ---
    Dmax_vs_c_MADe = "CUMPLE" if diff_hom_stab <= c_stab_MADe else "NO_CUMPLE"

    if math.isfinite(hom["nIQR"]) and hom["nIQR"] > 0:
        Dmax_vs_c_nIQR = "CUMPLE" if diff_hom_stab <= c_stab_nIQR else "NO_CUMPLE"
    else:
        Dmax_vs_c_nIQR = "N/A"

    Dmax_vs_exp_MADe = "CUMPLE" if diff_hom_stab <= c_stab_exp_MADe else "NO_CUMPLE"

    if math.isfinite(hom["nIQR"]) and hom["nIQR"] > 0:
        Dmax_vs_exp_nIQR = "CUMPLE" if diff_hom_stab <= c_stab_exp_nIQR else "NO_CUMPLE"
    else:
        Dmax_vs_exp_nIQR = "N/A"

    return {
        "g_stab": g_stab, "m_stab": m_stab,
        "general_mean_stab": general_mean_stab,
        "x_pt_stab": x_pt_stab,
        "s_x_bar_sq_stab": s_x_bar_sq_stab,
        "s_xt_stab": s_xt_stab,
        "sw_stab": sw_stab, "sw_sq_stab": sw_sq_stab,
        "ss_sq_stab": ss_sq_stab, "ss_stab": ss_stab,
        "media_hom": hom["general_mean_homog"],
        "media_stab": general_mean_stab,
        "diff_hom_stab": diff_hom_stab,
        "hom_MADe": hom["MADe"],
        "hom_nIQR": hom["nIQR"],
        "hom_ss": hom["ss"],
        "c_stab_MADe": c_stab_MADe,
        "c_stab_nIQR": c_stab_nIQR,
        "u_hom_mean": u_hom_mean,
        "u_stab_mean": u_stab_mean,
        "n_hom": n_hom,
        "n_stab": n_stab,
        "c_stab_exp_MADe": c_stab_exp_MADe,
        "c_stab_exp_nIQR": c_stab_exp_nIQR,
        "u_stab": u_stab,
        "Dmax_vs_c_MADe": Dmax_vs_c_MADe,
        "Dmax_vs_c_nIQR": Dmax_vs_c_nIQR,
        "Dmax_vs_exp_MADe": Dmax_vs_exp_MADe,
        "Dmax_vs_exp_nIQR": Dmax_vs_exp_nIQR,
        "error": None,
    }


def run_stage_03():
    import pandas as pd
    from datetime import date

    print("Etapa 3: Estabilidad — INICIO")
    print(f"  Datos homogeneidad: {DATA_HOMOGENEITY}")
    print(f"  Datos estabilidad: {DATA_STABILITY}")
    print("  Combos: O3 × 3 niveles\n")

    all_results = []

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        print(f"  Procesando: {combo['label']}")

        # Cargar datos en formato ancho
        wide_hom = load_wide_data(DATA_HOMOGENEITY, combo["pollutant"], combo["level"])
        wide_stab = load_wide_data(DATA_STABILITY, combo["pollutant"], combo["level"])

        if len(wide_hom) < 2 or len(wide_stab) < 2:
            print("    ADVERTENCIA: datos insuficientes, saltando")
            all_results.append({
                "combo_id": combo_id, "pollutant": combo["pollutant"], "level": combo["level"],
                "stage": "03_stability", "section": "stability",
                "metric": "insufficient_data",
                "r_value": float("nan"), "python_value": float("nan"), "app_value": float("nan"),
                "diff_r_python": float("nan"), "diff_app_r": float("nan"), "diff_app_python": float("nan"),
                "status": "EDGE_CASE", "tolerance": 1e-9, "notes": "Less than 2 samples",
            })
            continue

        # Calcular estadísticos
        stab = calc_stability(wide_stab, wide_hom)
        if stab.get("error"):
            print(f"    ERROR: {stab['error']}")
            continue

        # Cargar resultados R para comparación
        r_data = {}
        r_csv_path = OUTPUT_R_CSV
        if os.path.exists(r_csv_path):
            with open(r_csv_path, "r") as f:
                reader = csv_mod.DictReader(f)
                for row in reader:
                    r_data[row["combo_id"] + "_" + row["metric"]] = row

        # Métricas numéricas
        numeric_metrics = [
            ("g_stab",              stab["g_stab"]),
            ("m_stab",              stab["m_stab"]),
            ("general_mean_stab",    stab["general_mean_stab"]),
            ("x_pt_stab",            stab["x_pt_stab"]),
            ("s_x_bar_sq_stab",      stab["s_x_bar_sq_stab"]),
            ("s_xt_stab",            stab["s_xt_stab"]),
            ("sw_stab",              stab["sw_stab"]),
            ("sw_sq_stab",           stab["sw_sq_stab"]),
            ("ss_sq_stab",           stab["ss_sq_stab"]),
            ("ss_stab",              stab["ss_stab"]),
            ("media_hom",            stab["media_hom"]),
            ("media_stab",           stab["media_stab"]),
            ("diff_hom_stab",        stab["diff_hom_stab"]),
            ("hom_MADe",             stab["hom_MADe"]),
            ("hom_nIQR",             stab["hom_nIQR"]),
            ("c_stab_MADe",          stab["c_stab_MADe"]),
            ("c_stab_nIQR",          stab["c_stab_nIQR"]),
            ("u_hom_mean",           stab["u_hom_mean"]),
            ("u_stab_mean",          stab["u_stab_mean"]),
            ("c_stab_exp_MADe",      stab["c_stab_exp_MADe"]),
            ("c_stab_exp_nIQR",      stab["c_stab_exp_nIQR"]),
            ("u_stab",               stab["u_stab"]),
        ]

        for metric_name, py_val in numeric_metrics:
            key = f"{combo_id}_{metric_name}"
            r_row = r_data.get(key)
            r_val = float(r_row["r_value"]) if r_row and r_row["r_value"] not in ("", "NA", "nan") else float("nan")

            tol = 0.5 if metric_name in ("g_stab", "m_stab") else 1e-9
            cmp = compare_values(float("nan"), r_val, py_val, tol=tol)

            all_results.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "stage": "03_stability",
                "section": "stability",
                "metric": metric_name,
                "r_value": r_val,
                "python_value": py_val,
                "app_value": float("nan"),
                "diff_r_python": cmp["diff_r_python"],
                "diff_app_r": cmp["diff_app_r"],
                "diff_app_python": cmp["diff_app_python"],
                "status": cmp["status"],
                "tolerance": tol,
                "notes": "",
            })

        # Evaluaciones cualitativas
        evaluations = [
            ("Dmax_vs_c_MADe",    stab["Dmax_vs_c_MADe"],
             f"Dmax={stab['diff_hom_stab']:.6g} c_MADe={stab['c_stab_MADe']:.6g}"),
            ("Dmax_vs_c_nIQR",    stab["Dmax_vs_c_nIQR"],
             f"Dmax={stab['diff_hom_stab']:.6g} c_nIQR={stab['c_stab_nIQR']:.6g}"),
            ("Dmax_vs_exp_MADe",  stab["Dmax_vs_exp_MADe"],
             f"Dmax={stab['diff_hom_stab']:.6g} c_exp_MADe={stab['c_stab_exp_MADe']:.6g}"),
            ("Dmax_vs_exp_nIQR",  stab["Dmax_vs_exp_nIQR"],
             f"Dmax={stab['diff_hom_stab']:.6g} c_exp_nIQR={stab['c_stab_exp_nIQR']:.6g}"),
        ]

        for metric_name, eval_val, notes in evaluations:
            key = f"{combo_id}_{metric_name}"
            r_row = r_data.get(key)
            r_eval = r_row["status"] if r_row else ""

            all_results.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "stage": "03_stability",
                "section": "evaluation",
                "metric": metric_name,
                "r_value": float("nan"),
                "python_value": float("nan"),
                "app_value": float("nan"),
                "diff_r_python": float("nan"),
                "diff_app_r": float("nan"),
                "diff_app_python": float("nan"),
                "status": eval_val,
                "tolerance": float("nan"),
                "notes": f"Python={eval_val}" + (f" R={r_eval}" if r_eval else "") + f" | {notes}",
            })

        print(f"    g_stab={stab['g_stab']} m_stab={stab['m_stab']} "
              f"mean_stab={stab['general_mean_stab']:.8f} "
              f"mean_hom={stab['media_hom']:.8f} "
              f"Dmax={stab['diff_hom_stab']:.8e} "
              f"c_MADe={stab['c_stab_MADe']:.8f}")

    # Escribir CSV canónico
    os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)
    write_canonical_csv(all_results, OUTPUT_CSV)
    print(f"  CSV canónico escrito: {OUTPUT_CSV}")

    # --- Reporte Markdown ---
    pass_count = sum(1 for r in all_results if r["status"] == STATUS_PASS)
    fail_count = sum(1 for r in all_results if r["status"] == STATUS_FAIL)
    edge_count = sum(1 for r in all_results if r["status"] == STATUS_EDGE)

    eval_rows = [r for r in all_results if r.get("section") == "evaluation"]
    cumple_count = sum(1 for r in eval_rows if r.get("status") == "CUMPLE")
    no_cumple_count = sum(1 for r in eval_rows if r.get("status") == "NO_CUMPLE")

    report_lines = [
        "# Reporte: Etapa 3 — Estabilidad",
        "",
        f"**Fecha**: {date.today()}",
        f"**Datos homogeneidad**: {DATA_HOMOGENEITY}",
        f"**Datos estabilidad**: {DATA_STABILITY}",
        f"**Combos**: O3 × 3 niveles (0, 80, 180 nmol/mol)",
        "",
        "## Métricas evaluadas",
        "- g_stab (número de muestras de estabilidad)",
        "- m_stab (número de réplicas de estabilidad)",
        "- general_mean_stab (media general de estabilidad)",
        "- x_pt_stab (mediana de primera réplica de estabilidad)",
        "- s_x_bar_sq_stab (varianza de medias, ddof=1)",
        "- s_xt_stab (DE de medias de estabilidad)",
        "- sw_stab (DE intra-muestra de estabilidad)",
        "- sw_sq_stab (varianza intra-muestra de estabilidad)",
        "- ss_sq_stab (varianza entre-muestras de estabilidad)",
        "- ss_stab (DE entre-muestras de estabilidad)",
        "- media_hom (media general de HOMOGENEIDAD)",
        "- media_stab (media general de ESTABILIDAD)",
        "- diff_hom_stab (Dmax = |media_stab - media_hom|)",
        "- hom_MADe (MADe de homogeneidad)",
        "- hom_nIQR (nIQR de homogeneidad)",
        "- c_stab_MADe (0.3 × MADe_hom)",
        "- c_stab_nIQR (0.3 × nIQR_hom)",
        "- u_hom_mean (SD valores hom / √n_hom)",
        "- u_stab_mean (SD valores stab / √n_stab)",
        "- c_stab_exp_MADe (c_stab_MADe + 2×√(u_hom²+u_stab²))",
        "- c_stab_exp_nIQR (c_stab_nIQR + 2×√(u_hom²+u_stab²))",
        "- u_stab (0 si Dmax≤c, Dmax/√3 si no)",
        "",
        "## Nota importante",
        "- Los datos de estabilidad y homogeneidad son IDÉNTICOS para O3 × 3 niveles.",
        "  Esto implica Dmax = 0, por lo que el criterio de estabilidad se cumple siempre.",
        "",
        "## Discrepancia conocida",
        "- u_stab (incertidumbre): ptcalc usa calculate_u_stab(diff, c) que",
        "  devuelve 0 si diff≤c, o diff/√3 si no. Este script sigue la misma lógica.",
        "",
        "## Resumen PASS/FAIL",
        f"- PASS: {pass_count}",
        f"- FAIL: {fail_count}",
        f"- EDGE_CASE: {edge_count}",
        "",
        "## Evaluaciones de criterio",
        f"- CUMPLE: {cumple_count}",
        f"- NO_CUMPLE: {no_cumple_count}",
        "",
    ]

    # Tabla de valores por combo
    report_lines.append("## Valores por combo\n")
    report_lines.append("| Combo | g | m | mean_hom | mean_stab | Dmax | c_MADe | c_exp_MADe | u_stab | Dmax≤c? |")
    report_lines.append("|-------|---|---|----------|-----------|------|--------|-----------|--------|---------|")

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        numeric = {r["metric"]: r for r in all_results
                    if r["combo_id"] == combo_id and r["section"] == "stability"}
        evaluations = {r["metric"]: r["status"] for r in all_results
                       if r["combo_id"] == combo_id and r["section"] == "evaluation"}

        def fmt(metric):
            r = numeric.get(metric)
            if r is None or not math.isfinite(r["python_value"]):
                return "N/A"
            return f"{r['python_value']:.6g}"

        Dmax_vs = evaluations.get("Dmax_vs_c_MADe", "?")
        report_lines.append(
            f"| {combo_id} | {fmt('g_stab')} | {fmt('m_stab')} | "
            f"{fmt('media_hom')} | {fmt('media_stab')} | {fmt('diff_hom_stab')} | "
            f"{fmt('c_stab_MADe')} | {fmt('c_stab_exp_MADe')} | {fmt('u_stab')} | {Dmax_vs} |"
        )
    report_lines.append("")

    # Tabla de evaluaciones completas
    report_lines.append("## Evaluaciones de criterio detalladas\n")
    report_lines.append("| Combo | Dmax | c_MADe | c_exp_MADe | c_nIQR | c_exp_nIQR | Dmax≤c_MADe? | Dmax≤c_nIQR? | Dmax≤exp_MADe? | Dmax≤exp_nIQR? | u_hom | u_stab_mean | u_stab |")
    report_lines.append("|-------|------|--------|------------|--------|------------|--------------|---------------|----------------|-----------------|-------|-------------|--------|")

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        numeric = {r["metric"]: r for r in all_results
                    if r["combo_id"] == combo_id and r["section"] == "stability"}
        evaluations = {r["metric"]: r["status"] for r in all_results
                       if r["combo_id"] == combo_id and r["section"] == "evaluation"}

        def fmt(metric):
            r = numeric.get(metric)
            if r is None or not math.isfinite(r["python_value"]):
                return "N/A"
            v = r["python_value"]
            if abs(v) < 0.001 or abs(v) > 10000:
                return f"{v:.4e}"
            return f"{v:.6g}"

        report_lines.append(
            f"| {combo_id} | {fmt('diff_hom_stab')} | {fmt('c_stab_MADe')} | {fmt('c_stab_exp_MADe')} | "
            f"{fmt('c_stab_nIQR')} | {fmt('c_stab_exp_nIQR')} | "
            f"{evaluations.get('Dmax_vs_c_MADe', '?')} | {evaluations.get('Dmax_vs_c_nIQR', '?')} | "
            f"{evaluations.get('Dmax_vs_exp_MADe', '?')} | {evaluations.get('Dmax_vs_exp_nIQR', '?')} | "
            f"{fmt('u_hom_mean')} | {fmt('u_stab_mean')} | {fmt('u_stab')} |"
        )
    report_lines.append("")

    # Tabla de diferencias R vs Python
    numeric_rows = [r for r in all_results if r["section"] == "stability"
                    and r["metric"] not in ("g_stab", "m_stab")
                    and math.isfinite(r.get("diff_r_python", float("nan")))]

    if numeric_rows:
        max_diff = max(abs(r["diff_r_python"]) for r in numeric_rows
                       if math.isfinite(r.get("diff_r_python", float("nan"))))
        report_lines.extend([
            "## Diferencias R vs Python",
            f"- Máxima diferencia: {max_diff:.12e}",
            f"- Tolerancia: {TOL_DEFAULT}",
            f"- Total comparaciones numéricas: {len(numeric_rows)}",
            "",
        ])

    # Detalle de FAIL
    fail_rows = [r for r in all_results if r["status"] == STATUS_FAIL]
    if fail_rows:
        report_lines.append("## Detalle de FAIL\n")
        for r in fail_rows:
            report_lines.append(
                f"- {r['combo_id']} {r['metric']}: "
                f"R={r['r_value']:.12e} Py={r['python_value']:.12e} "
                f"diff={r['diff_r_python']:.12e}"
            )
        report_lines.append("")

    # Conclusión
    report_lines.extend([
        "## Conclusión",
        "Etapa PASS" if fail_count == 0 else "Etapa con FAIL pendientes de revisión",
        "",
    ])

    with open(OUTPUT_REPORT, "w") as f:
        f.write("\n".join(report_lines))
    print(f"  Reporte escrito: {OUTPUT_REPORT}")

    print("\nEtapa 3: Estabilidad (Python) — FIN")


if __name__ == "__main__":
    run_stage_03()