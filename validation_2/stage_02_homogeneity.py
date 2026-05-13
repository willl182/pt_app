"""
Etapa 2: Homogeneidad (Python)
Validación de estadísticos y criterios de homogeneidad.

Referencia: ISO 13528:2022, Sección 9.2
Fuente: data/homogeneity_n13.csv
Combos primarios: O3 × 3 niveles (0, 80, 180 nmol/mol)

Métricas validadas (18 numéricas × 3 combos + 2 evaluaciones × 3 combos = 60 filas):
  g, m, general_mean_homog, x_pt, s_x_bar_sq, s_xt,
  sw, sw_sq, ss_sq, ss,
  sigma_pt, MADe, u_sigma_pt, nIQR,
  criterio_c_MADe, criterio_exp_MADe, criterio_c_nIQR, criterio_exp_nIQR

Discrepancia conocida:
  - criterion_expanded: ptcalc usa 2 args (ISO clásica),
    R/app usa 3 args con tabla F1/F2. Este script usa F1/F2.

Uso:
    cd /home/w182/w421/pt_app
    python3 validation_2/stage_02_homogeneity.py
"""

import sys
import os
import math
import csv as csv_mod
import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from helpers import (
    COMBOS, make_combo_id, load_wide_data, median, iqr_type7,
    compare_values, write_canonical_csv, CANONICAL_COLS,
    STATUS_PASS, STATUS_FAIL, STATUS_EDGE, STATUS_KNOWN_DISC,
    TOL_DEFAULT,
)

DATA_HOMOGENEITY = "data/homogeneity_n13.csv"
OUTPUT_R_CSV    = "validation_2/outputs/stage_02_homogeneity_r.csv"
OUTPUT_CSV      = "validation_2/outputs/stage_02_homogeneity.csv"
OUTPUT_REPORT   = "validation_2/outputs/stage_02_homogeneity_report.md"

# --- Tabla F1/F2 para criterio expandido (ISO 13528:2022 §9.2.4) ---
F_TABLE = {
    7:  (2.10, 1.43), 8:  (2.01, 1.25), 9:  (1.94, 1.11),
    10: (1.88, 1.01), 11: (1.83, 0.93), 12: (1.79, 0.86),
    13: (1.75, 0.80), 14: (1.72, 0.75), 15: (1.69, 0.71),
    16: (1.67, 0.68), 17: (1.64, 0.64), 18: (1.62, 0.62),
    19: (1.60, 0.59), 20: (1.59, 0.57),
}


def calc_criterion_expanded_f1f2(sigma_pt, sw, g):
    """c_exp = F1*(0.3*sigma_pt)^2 + F2*sw^2 con clamp g a [7,20]."""
    g_clamped = max(7, min(20, g))
    f1, f2 = F_TABLE[g_clamped]
    return f1 * (0.3 * sigma_pt) ** 2 + f2 * sw ** 2


def variance_ddof1(values):
    """Varianza muestral con ddof=1 (equivalente a R var())."""
    n = len(values)
    if n < 2:
        return float("nan")
    m = sum(values) / n
    return sum((x - m) ** 2 for x in values) / (n - 1)


def calc_homogeneity(wide_df):
    """Calcular todos los estadísticos de homogeneidad.

    Args:
        wide_df: pandas DataFrame con columnas sample_1, sample_2, ...
                 (ya filtrado por pollutant y level)

    Returns:
        dict con todos los estadísticos de homogeneidad
    """
    sample_cols = sorted(
        [c for c in wide_df.columns if c.startswith("sample_") and c.replace("sample_", "").isdigit()],
        key=lambda c: int(c.split("_")[1])
    )
    matrix = wide_df[sample_cols].values  # numpy array g x m

    g = matrix.shape[0]
    m = matrix.shape[1]

    if g < 2:
        return {"error": "Se necesitan al menos 2 muestras."}
    if m < 2:
        return {"error": "Se necesitan al menos 2 replicas."}

    # Medias por muestra
    sample_means = np.mean(matrix, axis=1)

    # Media general de TODOS los valores
    general_mean_homog = np.mean(matrix)

    # x_pt: mediana de la primera columna
    x_pt = median(matrix[:, 0].tolist())

    # Varianza de medias muestrales (ddof=1)
    s_x_bar_sq = variance_ddof1(sample_means.tolist())
    s_xt = math.sqrt(s_x_bar_sq) if math.isfinite(s_x_bar_sq) and s_x_bar_sq >= 0 else float("nan")

    # sw: DE intra-muestra (rango para m=2)
    if m == 2:
        col1 = matrix[:, 0].tolist()
        col2 = matrix[:, 1].tolist()
        range_sq_sum = sum((a - b) ** 2 for a, b in zip(col1, col2))
        sw = math.sqrt(range_sq_sum / (2 * g))
    else:
        within_vars = [variance_ddof1(matrix[i, :].tolist()) for i in range(g)]
        sw = math.sqrt(sum(within_vars) / len(within_vars))

    sw_sq = sw ** 2

    # ss_sq = abs(s_x_bar_sq - sw_sq/m)
    ss_sq = abs(s_x_bar_sq - sw_sq / m)
    ss = math.sqrt(ss_sq)

    # sigma_pt = mediana(|sample_2 - x_pt|)  (misma lógica que ptcalc)
    col2_vals = matrix[:, 1].tolist()
    abs_diff_from_xpt = [abs(v - x_pt) for v in col2_vals]
    sigma_pt = median(abs_diff_from_xpt)

    # MADe = 1.483 * sigma_pt
    MADe = 1.483 * sigma_pt

    # u_sigma_pt = 1.25 * MADe / sqrt(g)
    u_sigma_pt = 1.25 * MADe / math.sqrt(g)

    # nIQR = 0.7413 * IQR (type=7) sobre sample_1
    sample1 = matrix[:, 0].tolist()
    nIQR = 0.7413 * iqr_type7(sample1)

    # Criterios MADe
    criterio_c_MADe = 0.3 * MADe
    criterio_exp_MADe = calc_criterion_expanded_f1f2(MADe, sw, g)

    # Criterios nIQR
    criterio_c_nIQR = 0.3 * nIQR
    criterio_exp_nIQR = calc_criterion_expanded_f1f2(nIQR, sw, g)

    # Evaluaciones
    ss_vs_c_MADe = "CUMPLE" if ss <= criterio_c_MADe else "NO_CUMPLE"
    ss_vs_c_nIQR = "CUMPLE" if (math.isfinite(nIQR) and nIQR > 0 and ss <= criterio_c_nIQR) else (
        "NO_CUMPLE" if (math.isfinite(nIQR) and nIQR > 0) else "N/A"
    )

    return {
        "g": g, "m": m,
        "general_mean_homog": general_mean_homog,
        "x_pt": x_pt,
        "s_x_bar_sq": s_x_bar_sq,
        "s_xt": s_xt,
        "sw": sw, "sw_sq": sw_sq,
        "ss_sq": ss_sq, "ss": ss,
        "sigma_pt": sigma_pt, "MADe": MADe,
        "u_sigma_pt": u_sigma_pt,
        "nIQR": nIQR,
        "criterio_c_MADe": criterio_c_MADe,
        "criterio_exp_MADe": criterio_exp_MADe,
        "criterio_c_nIQR": criterio_c_nIQR,
        "criterio_exp_nIQR": criterio_exp_nIQR,
        "ss_vs_c_MADe": ss_vs_c_MADe,
        "ss_vs_c_nIQR": ss_vs_c_nIQR,
        "error": None,
    }


def run_stage_02():
    import pandas as pd
    from datetime import date

    print("Etapa 2: Homogeneidad — INICIO")
    print(f"  Datos: {DATA_HOMOGENEITY}")
    print("  Combos: O3 × 3 niveles\n")

    all_results = []

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        print(f"  Procesando: {combo['label']}")

        # Cargar datos en formato ancho
        wide = load_wide_data(DATA_HOMOGENEITY, combo["pollutant"], combo["level"])

        if len(wide) < 2:
            print("    ADVERTENCIA: datos insuficientes, saltando")
            all_results.append({
                "combo_id": combo_id, "pollutant": combo["pollutant"], "level": combo["level"],
                "stage": "02_homogeneity", "section": "homogeneity",
                "metric": "insufficient_data",
                "r_value": float("nan"), "python_value": float("nan"), "app_value": float("nan"),
                "diff_r_python": float("nan"), "diff_app_r": float("nan"), "diff_app_python": float("nan"),
                "status": "EDGE_CASE", "tolerance": 1e-9, "notes": "Less than 2 samples",
            })
            continue

        # Calcular estadísticos
        hom = calc_homogeneity(wide)
        if hom.get("error"):
            print(f"    ERROR: {hom['error']}")
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
            ("g",                   hom["g"]),
            ("m",                   hom["m"]),
            ("general_mean_homog",  hom["general_mean_homog"]),
            ("x_pt",                hom["x_pt"]),
            ("s_x_bar_sq",          hom["s_x_bar_sq"]),
            ("s_xt",                hom["s_xt"]),
            ("sw",                  hom["sw"]),
            ("sw_sq",               hom["sw_sq"]),
            ("ss_sq",               hom["ss_sq"]),
            ("ss",                  hom["ss"]),
            ("sigma_pt",            hom["sigma_pt"]),
            ("MADe",                hom["MADe"]),
            ("u_sigma_pt",          hom["u_sigma_pt"]),
            ("nIQR",                hom["nIQR"]),
            ("criterio_c_MADe",     hom["criterio_c_MADe"]),
            ("criterio_exp_MADe",   hom["criterio_exp_MADe"]),
            ("criterio_c_nIQR",     hom["criterio_c_nIQR"]),
            ("criterio_exp_nIQR",   hom["criterio_exp_nIQR"]),
        ]

        for metric_name, py_val in numeric_metrics:
            key = f"{combo_id}_{metric_name}"
            r_row = r_data.get(key)
            r_val = float(r_row["r_value"]) if r_row and r_row["r_value"] not in ("", "NA", "nan") else float("nan")

            tol = 0.5 if metric_name in ("g", "m") else 1e-9
            cmp = compare_values(float("nan"), r_val, py_val, tol=tol)

            notes = ""
            if metric_name in ("criterio_exp_MADe", "criterio_exp_nIQR"):
                notes = "Usa tabla F1/F2 (app.R), NO ptcalc 2-arg"

            all_results.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "stage": "02_homogeneity",
                "section": "homogeneity",
                "metric": metric_name,
                "r_value": r_val,
                "python_value": py_val,
                "app_value": float("nan"),
                "diff_r_python": cmp["diff_r_python"],
                "diff_app_r": cmp["diff_app_r"],
                "diff_app_python": cmp["diff_app_python"],
                "status": cmp["status"],
                "tolerance": tol,
                "notes": notes,
            })

        # Evaluaciones cualitativas
        ss_vs_exp_MADe_res = "CUMPLE" if hom["ss"] <= hom["criterio_exp_MADe"] else "NO_CUMPLE"
        ss_vs_exp_nIQR_res = "CUMPLE" if (
            math.isfinite(hom["nIQR"]) and hom["nIQR"] > 0 and
            hom["ss"] <= hom["criterio_exp_nIQR"]
        ) else (
            "NO_CUMPLE" if (math.isfinite(hom["nIQR"]) and hom["nIQR"] > 0) else "N/A"
        )

        for metric_name, eval_val in [
            ("ss_vs_c_MADe", hom["ss_vs_c_MADe"]),
            ("ss_vs_c_nIQR", hom["ss_vs_c_nIQR"]),
            ("ss_vs_exp_MADe", ss_vs_exp_MADe_res),
            ("ss_vs_exp_nIQR", ss_vs_exp_nIQR_res),
        ]:
            key = f"{combo_id}_{metric_name}"
            r_row = r_data.get(key)
            r_eval = r_row["status"] if r_row else ""

            all_results.append({
                "combo_id": combo_id,
                "pollutant": combo["pollutant"],
                "level": combo["level"],
                "stage": "02_homogeneity",
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
                "notes": f"Python={eval_val}" + (f" R={r_eval}" if r_eval else ""),
            })

        print(f"    g={hom['g']} m={hom['m']} "
              f"x_pt={hom['x_pt']:.8f} sw={hom['sw']:.8f} "
              f"ss={hom['ss']:.8f} MADe={hom['MADe']:.8f} "
              f"sigma_pt={hom['sigma_pt']:.8f}")

    # Escribir CSV canónico
    os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)
    write_canonical_csv(all_results, OUTPUT_CSV)
    print(f"  CSV canónico escrito: {OUTPUT_CSV}")

    # --- Reporte Markdown ---
    pass_count = sum(1 for r in all_results if r["status"] == STATUS_PASS)
    fail_count = sum(1 for r in all_results if r["status"] == STATUS_FAIL)
    edge_count = sum(1 for r in all_results if r["status"] == STATUS_EDGE)

    # Contar evaluaciones
    eval_rows = [r for r in all_results if r.get("section") == "evaluation"]
    cumple_count = sum(1 for r in eval_rows if r.get("status") == "CUMPLE")
    no_cumple_count = sum(1 for r in eval_rows if r.get("status") == "NO_CUMPLE")

    report_lines = [
        "# Reporte: Etapa 2 — Homogeneidad",
        "",
        f"**Fecha**: {date.today()}",
        f"**Datos**: {DATA_HOMOGENEITY}",
        f"**Combos**: O3 × 3 niveles (0, 80, 180 nmol/mol)",
        "",
        "## Métricas evaluadas",
        "- g (número de muestras)",
        "- m (número de réplicas)",
        "- Media general (mean de todos los valores)",
        "- x_pt (mediana de primera réplica)",
        "- s_x_bar_sq (varianza de medias, ddof=1)",
        "- s_xt (DE de medias)",
        "- sw (DE intra-muestra)",
        "- sw_sq (varianza intra-muestra)",
        "- ss_sq (varianza entre-muestras, abs())",
        "- ss (DE entre-muestras)",
        "- sigma_pt (mediana de |sample_2 - x_pt|)",
        "- MADe (1.483 × sigma_pt)",
        "- u_sigma_pt (1.25 × MADe / √g)",
        "- nIQR (0.7413 × IQR type=7 sobre sample_1)",
        "- Criterio c MADe (0.3 × MADe)",
        "- Criterio exp MADe (F1×(0.3×MADe)² + F2×sw²)",
        "- Criterio c nIQR (0.3 × nIQR)",
        "- Criterio exp nIQR (F1×(0.3×nIQR)² + F2×sw²)",
        "",
        "## Discrepancia conocida",
        "- criterion_expanded usa fórmula F1/F2 con 3 args (app.R),",
        "  NO la fórmula `0.3×σ×√(1+(uσ/σ)²)` de ptcalc (2 args).",
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
    report_lines.append("| Combo | g | m | x_pt | sw | ss | MADe | σ_pt | c_MADe | c_exp_MADe | ss≤c? |")
    report_lines.append("|-------|---|---|------|-----|-----|------|------|--------|------------|-------|")

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        numeric = {r["metric"]: r for r in all_results
                    if r["combo_id"] == combo_id and r["section"] == "homogeneity"}
        evaluations = {r["metric"]: r["status"] for r in all_results
                       if r["combo_id"] == combo_id and r["section"] == "evaluation"}

        def fmt(metric):
            r = numeric.get(metric)
            if r is None or not math.isfinite(r["python_value"]):
                return "N/A"
            return f"{r['python_value']:.6g}"

        ss_vs = evaluations.get("ss_vs_c_MADe", "?")
        report_lines.append(
            f"| {combo_id} | {fmt('g')} | {fmt('m')} | "
            f"{fmt('x_pt')} | {fmt('sw')} | {fmt('ss')} | {fmt('MADe')} | "
            f"{fmt('sigma_pt')} | {fmt('criterio_c_MADe')} | {fmt('criterio_exp_MADe')} | {ss_vs} |"
        )
    report_lines.append("")

    # Tabla de evaluaciones expandidas
    report_lines.append("## Evaluaciones de criterio detalladas\n")
    report_lines.append("| Combo | ss | c_MADe | c_exp_MADe | ss≤c? | ss≤exp? | c_nIQR | c_exp_nIQR | ss≤c_nIQR? | ss≤exp_nIQR? |")
    report_lines.append("|-------|-----|--------|---------|-------|--------|--------|-----------|------------|-------------|")

    for combo in COMBOS:
        combo_id = make_combo_id(combo["pollutant"], combo["level"])
        numeric = {r["metric"]: r for r in all_results
                    if r["combo_id"] == combo_id and r["section"] == "homogeneity"}
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
            f"| {combo_id} | {fmt('ss')} | {fmt('criterio_c_MADe')} | {fmt('criterio_exp_MADe')} | "
            f"{evaluations.get('ss_vs_c_MADe', '?')} | {evaluations.get('ss_vs_exp_MADe', '?')} | "
            f"{fmt('criterio_c_nIQR')} | {fmt('criterio_exp_nIQR')} | "
            f"{evaluations.get('ss_vs_c_nIQR', '?')} | {evaluations.get('ss_vs_exp_nIQR', '?')} |"
        )
    report_lines.append("")

    # Tabla de diferencias R vs Python
    numeric_rows = [r for r in all_results if r["section"] == "homogeneity"
                    and r["metric"] not in ("g", "m")
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

    print("\nEtapa 2: Homogeneidad (Python) — FIN")


if __name__ == "__main__":
    run_stage_02()