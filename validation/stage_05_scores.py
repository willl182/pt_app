"""
Etapa 5: Scores de Desempeño (Python)
Validacion de scores por participante: z, z', zeta, En.

Referencia: ISO 13528:2022
Fuente: data/summary_n13.csv, validation/outputs/stage_04_uncertainty_chain.csv

Uso:
    python3 validation/stage_05_scores.py

Outputs:
    validation/outputs/stage_05_scores_py.csv   (intermedio Python)
    validation/outputs/stage_05_scores.csv       (comparacion R vs Python)
    validation/outputs/stage_05_scores_report.md

Scores validados (8 metricas por participante/metodo):
    z_score, z_score_eval
    z_prime_score, z_prime_score_eval
    zeta_score, zeta_score_eval
    En_score, En_score_eval
"""

import csv
import math
import os

DATA_SUMMARY = "data/summary_n13.csv"
STAGE04_CSV  = "validation/outputs/stage_04_uncertainty_chain.csv"
R_CSV        = "validation/outputs/stage_05_scores_r.csv"
OUTPUT_PY_CSV  = "validation/outputs/stage_05_scores_py.csv"
OUTPUT_CSV     = "validation/outputs/stage_05_scores.csv"
OUTPUT_REPORT  = "validation/outputs/stage_05_scores_report.md"

TOL_DEFAULT = 1e-9
STATUS_PASS = "PASS"
STATUS_FAIL = "FAIL"
K = 2  # Factor de cobertura

METHODS = ["Referencia", "Consenso MADe", "Consenso nIQR", "Algoritmo A"]
NUMERIC_METRICS = ["z_score", "z_prime_score", "zeta_score", "En_score"]
EVAL_METRICS    = ["z_score_eval", "z_prime_score_eval", "zeta_score_eval", "En_score_eval"]
# Orden intercalado: metrica numérica + su eval
ALL_METRICS = []
for n, e in zip(NUMERIC_METRICS, EVAL_METRICS):
    ALL_METRICS.extend([n, e])

CANONICAL_COLS = [
    "combo_id", "pollutant", "level", "stage", "section", "participant_id",
    "metric", "app_value", "r_value", "python_value",
    "diff_app_r", "diff_app_python", "diff_r_python",
    "status", "tolerance", "notes",
]

# ---------------------------------------------------------------------------
# Evaluaciones
# ---------------------------------------------------------------------------

def evaluate_z(z):
    """Evaluar z / z' / zeta."""
    if not math.isfinite(z):
        return "N/A"
    az = abs(z)
    if az <= 2:
        return "Satisfactorio"
    if az >= 3:
        return "No satisfactorio"
    return "Cuestionable"


def evaluate_en(en):
    """Evaluar En."""
    if not math.isfinite(en):
        return "N/A"
    return "Satisfactorio" if abs(en) <= 1 else "No satisfactorio"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_combo_id(pollutant, level):
    prefix = pollutant.upper()
    num = level.split("-")[0]
    return f"{prefix}_{num}"


def parse_float(s):
    """Parsear string a float; devuelve nan para NA/nan/vacío."""
    if s is None or s.strip() in ("", "NA", "NaN", "nan"):
        return float("nan")
    try:
        return float(s)
    except ValueError:
        return float("nan")


def fmt_float(v):
    """Formatear float para CSV con precisión completa."""
    if not math.isfinite(v):
        return "nan"
    return repr(v)


# ---------------------------------------------------------------------------
# Carga de datos
# ---------------------------------------------------------------------------

def load_stage04_params(csv_path):
    """Retorna dict (combo_id, method) -> {x_pt, sigma_pt, u_xpt_def}."""
    params = {}
    with open(csv_path, "r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["metric"] not in ("x_pt", "sigma_pt", "u_xpt_def"):
                continue
            key = (row["combo_id"], row["section"])
            if key not in params:
                params[key] = {
                    "pollutant": row["pollutant"],
                    "level": row["level"],
                }
            params[key][row["metric"]] = parse_float(row["r_value"])
    return params


def load_participants(csv_path):
    """Agrega summary_n13.csv por (combo_id, participant_id).
    Retorna dict (combo_id, participant_id) -> {result, sd_value, uncertainty_std, ...}.
    """
    raw = {}
    with open(csv_path, "r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            if row["participant_id"] == "ref":
                continue
            combo_id = make_combo_id(row["pollutant"], row["level"])
            key = (combo_id, row["participant_id"])
            if key not in raw:
                raw[key] = {
                    "mean_values": [],
                    "sd_values": [],
                    "pollutant": row["pollutant"],
                    "level": row["level"],
                }
            raw[key]["mean_values"].append(float(row["mean_value"]))
            raw[key]["sd_values"].append(float(row["sd_value"]))

    result = {}
    for (combo_id, participant_id), data in raw.items():
        n = len(data["mean_values"])
        mean_result = sum(data["mean_values"]) / n
        mean_sd     = sum(data["sd_values"]) / n
        result[(combo_id, participant_id)] = {
            "result":          mean_result,
            "sd_value":        mean_sd,
            "uncertainty_std": mean_sd / math.sqrt(2),  # m=2
            "pollutant":       data["pollutant"],
            "level":           data["level"],
        }
    return result


# ---------------------------------------------------------------------------
# Calculo de scores
# ---------------------------------------------------------------------------

def calculate_scores(result, uncertainty_std, x_pt, sigma_pt, u_xpt_def):
    """Calcular 4 scores numericos + 4 evaluaciones categoriales."""
    # Clip u_xpt_def no finito a 0 (igual que app.R compute_combo_scores)
    if not math.isfinite(u_xpt_def) or u_xpt_def < 0:
        u_xpt_def = 0.0

    # z_score
    if math.isfinite(sigma_pt) and sigma_pt > 0:
        z = (result - x_pt) / sigma_pt
    else:
        z = float("nan")

    # z_prime_score
    if math.isfinite(sigma_pt):
        zprime_den = math.sqrt(sigma_pt**2 + u_xpt_def**2)
        zprime = (result - x_pt) / zprime_den if zprime_den > 0 else float("nan")
    else:
        zprime = float("nan")

    # zeta_score
    zeta_den_sq = uncertainty_std**2 + u_xpt_def**2
    if math.isfinite(zeta_den_sq) and zeta_den_sq >= 0:
        zeta_den = math.sqrt(zeta_den_sq)
        zeta = (result - x_pt) / zeta_den if zeta_den > 0 else float("nan")
    else:
        zeta = float("nan")

    # En_score (k=2)
    en_den_sq = (K * uncertainty_std)**2 + (K * u_xpt_def)**2
    if math.isfinite(en_den_sq) and en_den_sq >= 0:
        en_den = math.sqrt(en_den_sq)
        en = (result - x_pt) / en_den if en_den > 0 else float("nan")
    else:
        en = float("nan")

    return {
        "z_score":             z,
        "z_prime_score":       zprime,
        "zeta_score":          zeta,
        "En_score":            en,
        "z_score_eval":        evaluate_z(z),
        "z_prime_score_eval":  evaluate_z(zprime),
        "zeta_score_eval":     evaluate_z(zeta),
        "En_score_eval":       evaluate_en(en),
    }


# ---------------------------------------------------------------------------
# Comparacion R vs Python
# ---------------------------------------------------------------------------

def compare_numeric(r_val, py_val):
    """Comparar dos valores numericos. Retorna (status, diff_str)."""
    r_fin  = math.isfinite(r_val)
    py_fin = math.isfinite(py_val)
    if not r_fin and not py_fin:
        return STATUS_PASS, "nan"
    if r_fin and py_fin:
        diff = r_val - py_val
        status = STATUS_PASS if abs(diff) <= TOL_DEFAULT else STATUS_FAIL
        return status, repr(diff)
    return STATUS_FAIL, "nan"


def compare_categorical(r_val, py_val):
    """Comparar dos strings de evaluacion. Retorna status."""
    return STATUS_PASS if r_val.strip() == py_val.strip() else STATUS_FAIL


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def run_stage_05():
    print("Etapa 5: Scores de Desempeño — INICIO")

    # 1. Cargar parámetros de Etapa 4
    params = load_stage04_params(STAGE04_CSV)
    print(f"  Parámetros cargados: {len(params)} combinaciones combo × método")

    # 2. Cargar datos de participantes
    participants = load_participants(DATA_SUMMARY)
    print(f"  Participantes cargados: {len(participants)} (sin 'ref')")

    # Organizar por combo_id
    combos = {}
    for (combo_id, participant_id), data in participants.items():
        if combo_id not in combos:
            combos[combo_id] = {}
        combos[combo_id][participant_id] = data

    # 3. Calcular scores en Python
    py_results = []
    for combo_id in sorted(combos.keys()):
        for method in METHODS:
            key = (combo_id, method)
            if key not in params:
                continue
            p = params[key]
            x_pt      = p.get("x_pt", float("nan"))
            sigma_pt  = p.get("sigma_pt", float("nan"))
            u_xpt_def = p.get("u_xpt_def", float("nan"))

            for participant_id in sorted(combos[combo_id].keys()):
                pt = combos[combo_id][participant_id]
                scores = calculate_scores(
                    pt["result"], pt["uncertainty_std"],
                    x_pt, sigma_pt, u_xpt_def,
                )
                py_results.append({
                    "combo_id":       combo_id,
                    "pollutant":      pt["pollutant"],
                    "level":          pt["level"],
                    "method":         method,
                    "participant_id": participant_id,
                    "result":         pt["result"],
                    "uncertainty_std": pt["uncertainty_std"],
                    "x_pt":           x_pt,
                    "sigma_pt":       sigma_pt,
                    "u_xpt_def":      u_xpt_def,
                    **scores,
                })

    print(f"  Scores calculados: {len(py_results)} filas (esperado: {15 * 4 * 12} = 720)")

    # 4. Guardar CSV intermedio Python
    os.makedirs(os.path.dirname(OUTPUT_PY_CSV), exist_ok=True)
    py_fields = [
        "combo_id", "pollutant", "level", "method", "participant_id",
        "result", "uncertainty_std", "x_pt", "sigma_pt", "u_xpt_def",
    ] + ALL_METRICS

    with open(OUTPUT_PY_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=py_fields, extrasaction="ignore")
        writer.writeheader()
        for row in py_results:
            out = {}
            for k in py_fields:
                v = row[k]
                if isinstance(v, str):
                    out[k] = v
                elif isinstance(v, float):
                    out[k] = fmt_float(v)
                else:
                    out[k] = str(v)
            writer.writerow(out)
    print(f"  CSV intermedio Python escrito: {OUTPUT_PY_CSV}")

    # 5. Leer CSV R para comparacion
    r_data = {}  # (combo_id, method, participant_id, metric) -> str
    with open(R_CSV, "r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            for metric in ALL_METRICS:
                r_data[(row["combo_id"], row["method"], row["participant_id"], metric)] = \
                    row.get(metric, "")

    # 6. Generar filas canonicas de comparacion
    canonical_rows = []
    pass_count = 0
    fail_count = 0

    for py_row in py_results:
        combo_id       = py_row["combo_id"]
        method         = py_row["method"]
        participant_id = py_row["participant_id"]

        for metric in ALL_METRICS:
            is_eval = metric.endswith("_eval")
            py_val  = py_row[metric]
            r_str   = r_data.get((combo_id, method, participant_id, metric), "")

            if is_eval:
                status = compare_categorical(r_str, py_val)
                crow = {
                    "combo_id":       combo_id,
                    "pollutant":      py_row["pollutant"],
                    "level":          py_row["level"],
                    "stage":          "stage_05_scores",
                    "section":        method,
                    "participant_id": participant_id,
                    "metric":         metric,
                    "app_value":      "nan",
                    "r_value":        r_str.strip(),
                    "python_value":   str(py_val),
                    "diff_app_r":     "nan",
                    "diff_app_python":"nan",
                    "diff_r_python":  "",
                    "status":         status,
                    "tolerance":      "exact",
                    "notes":          "",
                }
            else:
                r_val  = parse_float(r_str)
                status, diff_str = compare_numeric(r_val, py_val)
                crow = {
                    "combo_id":       combo_id,
                    "pollutant":      py_row["pollutant"],
                    "level":          py_row["level"],
                    "stage":          "stage_05_scores",
                    "section":        method,
                    "participant_id": participant_id,
                    "metric":         metric,
                    "app_value":      "nan",
                    "r_value":        fmt_float(r_val),
                    "python_value":   fmt_float(py_val),
                    "diff_app_r":     "nan",
                    "diff_app_python":"nan",
                    "diff_r_python":  diff_str,
                    "status":         status,
                    "tolerance":      str(TOL_DEFAULT),
                    "notes":          "",
                }

            canonical_rows.append(crow)
            if status == STATUS_PASS:
                pass_count += 1
            else:
                fail_count += 1

    # 7. Escribir CSV canonico
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CANONICAL_COLS)
        writer.writeheader()
        writer.writerows(canonical_rows)
    print(f"  CSV canónico escrito: {OUTPUT_CSV}")

    # 8. Reporte
    combos_processed = sorted(set(r["combo_id"] for r in canonical_rows))
    fail_rows = [r for r in canonical_rows if r["status"] == STATUS_FAIL]

    report_lines = [
        "# Reporte: Etapa 5 — Scores de Desempeño",
        "",
        f"**Fecha**: {os.popen('date +%Y-%m-%d').read().strip()}",
        "",
        "## Combos procesados",
    ]
    for cid in combos_processed:
        report_lines.append(f"- {cid}")

    report_lines.extend([
        "",
        "## Dimensiones de validación",
        f"- Combos: {len(combos_processed)}",
        "- Métodos: 4 (Referencia, Consenso MADe, Consenso nIQR, Algoritmo A)",
        "- Participantes por combo: 12 (excluido 'ref')",
        "- Métricas por participante/método: 8 (4 numéricos + 4 evaluaciones)",
        f"- **Total comparaciones**: {pass_count + fail_count}",
        "",
        "## Resumen PASS/FAIL",
        f"- **PASS**: {pass_count}",
        f"- **FAIL**: {fail_count}",
        "- EDGE_CASE: 0",
        "- KNOWN_DISCREPANCY: 0",
    ])

    if fail_rows:
        report_lines.extend(["", "## Discrepancias"])
        for row in fail_rows[:20]:
            report_lines.append(
                f"- {row['combo_id']} | {row['section']} | "
                f"{row['participant_id']} | {row['metric']}: "
                f"R={row['r_value']} vs Py={row['python_value']}"
            )
        if len(fail_rows) > 20:
            report_lines.append(f"- ... y {len(fail_rows) - 20} más")

    conclusion = "Etapa PASS" if fail_count == 0 else \
        f"Etapa con {fail_count} FAIL pendientes de revisión"
    report_lines.extend([
        "",
        "## Conclusión",
        conclusion,
        "",
    ])

    with open(OUTPUT_REPORT, "w", encoding="utf-8") as f:
        f.write("\n".join(report_lines))
    print(f"  Reporte escrito: {OUTPUT_REPORT}")

    total = pass_count + fail_count
    print(f"\n  RESUMEN: {pass_count} PASS, {fail_count} FAIL de {total} comparaciones")
    print("Etapa 5: Scores de Desempeño — FIN")


if __name__ == "__main__":
    run_stage_05()
