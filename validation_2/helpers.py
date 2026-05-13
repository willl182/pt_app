# ===================================================================
# Helpers compartidos para validación (Python)
# Funciones comunes usadas por los scripts de etapa
# ===================================================================

import csv
import math
import os

# --- Combos O3 × 3 niveles (validación primaria) ---
COMBOS = [
    {"pollutant": "o3", "level": "0-nmol/mol",  "label": "O3_0"},
    {"pollutant": "o3", "level": "80-nmol/mol",  "label": "O3_80"},
    {"pollutant": "o3", "level": "180-nmol/mol", "label": "O3_180"},
]

TOL_DEFAULT = 1e-9
STATUS_PASS  = "PASS"
STATUS_FAIL  = "FAIL"
STATUS_EDGE  = "EDGE_CASE"
STATUS_KNOWN_DISC = "KNOWN_DISCREPANCY"

CANONICAL_COLS = [
    "combo_id", "pollutant", "level", "stage", "section",
    "metric", "r_value", "python_value", "app_value",
    "diff_r_python", "diff_app_r", "diff_app_python",
    "status", "tolerance", "notes",
]

# --- IDs de combo ---
def make_combo_id(pollutant, level):
    prefix = pollutant.upper()
    level_num = level.split("-")[0]
    return f"{prefix}_{level_num}"

# --- Carga de datos en formato ancho ---
def load_wide_data(filepath, pollutant, level):
    """Carga homogeneity CSV y pivota a formato ancho (sample_id × replicates)."""
    import pandas as pd
    df = pd.read_csv(filepath)
    df = df[(df["pollutant"] == pollutant) & (df["level"] == level)]
    if df.empty:
        return pd.DataFrame()
    wide = df.pivot_table(index="sample_id", columns="replicate", values="value")
    wide.columns = [f"sample_{c}" for c in wide.columns]
    wide = wide.reset_index().sort_values("sample_id").reset_index(drop=True)
    return wide

# --- Carga de datos de participantes (summary) ---
def load_summary_data(filepath, pollutant, level, exclude_ref=True):
    """Carga summary_n13 CSV filtrado por contaminante y nivel."""
    import pandas as pd
    df = pd.read_csv(filepath)
    df = df[(df["pollutant"] == pollutant) & (df["level"] == level)]
    if exclude_ref and "participant_id" in df.columns:
        df = df[~df["participant_id"].str.match(r"^ref$", case=False)]
    return df

# --- Mediana (compatible con R median()) ---
def median(values):
    sorted_vals = sorted(v for v in values if math.isfinite(v))
    n = len(sorted_vals)
    if n == 0:
        return float("nan")
    mid = n // 2
    if n % 2 == 1:
        return sorted_vals[mid]
    return (sorted_vals[mid - 1] + sorted_vals[mid]) / 2.0

# --- Cuartiles tipo 7 (compatible con R quantile type=7) ---
def quantile_type7(values, probs):
    """Calcula cuantiles usando el método lineal (R type=7, numpy default)."""
    import numpy as np
    arr = np.array([v for v in values if math.isfinite(v)])
    if len(arr) == 0:
        return [float("nan")] * len(probs)
    # numpy uses linear interpolation by default (equivalent to R type=7)
    return np.percentile(arr, [p * 100 for p in probs]).tolist()

def iqr_type7(values):
    """IQR usando cuartiles tipo 7 (R type=7)."""
    q1, q3 = quantile_type7(values, [0.25, 0.75])
    return q3 - q1

# --- Comparación con tolerancia ---
def compare_values(val_app, val_r, val_python, tol=TOL_DEFAULT):
    diff_app_r = abs(val_app - val_r) if (math.isfinite(val_app) and math.isfinite(val_r)) else float("nan")
    diff_app_py = abs(val_app - val_python) if (math.isfinite(val_app) and math.isfinite(val_python)) else float("nan")
    diff_r_py = abs(val_r - val_python) if (math.isfinite(val_r) and math.isfinite(val_python)) else float("nan")

    status = STATUS_PASS
    if math.isfinite(diff_app_r) and diff_app_r > tol:
        status = STATUS_FAIL
    if math.isfinite(diff_app_py) and diff_app_py > tol:
        status = STATUS_FAIL
    if math.isfinite(diff_r_py) and diff_r_py > tol:
        status = STATUS_FAIL
    if math.isnan(val_app) and math.isnan(val_r) and math.isnan(val_python):
        status = STATUS_PASS

    return {
        "diff_app_r": diff_app_r,
        "diff_app_python": diff_app_py,
        "diff_r_python": diff_r_py,
        "status": status,
    }

# --- Escribir CSV canónico ---
def write_canonical_csv(results, filepath):
    with open(filepath, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=CANONICAL_COLS, extrasaction="ignore")
        writer.writeheader()
        for row in results:
            # Fill missing columns with empty string
            full_row = {col: row.get(col, "") for col in CANONICAL_COLS}
            writer.writerow(full_row)
    print(f"  CSV guardado: {filepath}")

# --- Escribir reporte Markdown ---
def write_report_md(lines, filepath):
    with open(filepath, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"  Reporte guardado: {filepath}")