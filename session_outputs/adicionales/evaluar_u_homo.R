# ===================================================================
# Evaluación de u_homo por distribución rectangular
# Compara medias de réplicas (10 mediciones cada una) por nivel
# u_homo = X × 0.003 si la diferencia relativa < 0.5%
# ===================================================================

library(tidyverse)

# --- Leer datos ---
homo <- read_csv("data/processed/ronda_1_homogeneidad.csv",
  show_col_types = FALSE
)

# --- Paso 1: Calcular media por (pollutant, level, replicate) ---
# Cada réplica tiene 10 mediciones → 1 media por réplica
rep_means <- homo |>
  group_by(pollutant, level, replicate) |>
  summarise(
    n = n(),
    mean_val = mean(value, na.rm = TRUE),
    .groups = "drop"
  ) |>
  pivot_wider(
    id_cols = c(pollutant, level),
    names_from = replicate,
    values_from = c(n, mean_val),
    names_sep = "_"
  )

# --- Paso 2: Diferencia relativa entre réplicas ---
results <- rep_means |>
  mutate(
    grand_mean    = (mean_val_1 + mean_val_2) / 2,
    diff_abs      = abs(mean_val_1 - mean_val_2),
    diff_pct      = (diff_abs / abs(grand_mean)) * 100,
    # Paso 3: ¿diferencia < 0.5%? → distribución rectangular
    meets_0.5pct  = diff_pct < 0.5,
    # Paso 4: u_homo = X × 0.003  (0.5% / sqrt(3) ≈ 0.289% ≈ 0.3%)
    # Para niveles donde |X| ≈ 0, usar 0 directamente
    u_homo_pct    = case_when(
      !meets_0.5pct ~ NA_real_,       # No cumple supuesto → requiere otro enfoque
      abs(grand_mean) < 1e-9 ~ 0,     # Nivel ~0: u_homo = 0
      TRUE ~ 0.3                      # u_homo como % del valor
    ),
    u_homo_abs    = grand_mean * u_homo_pct / 100,
    u_homo_formula = case_when(
      !meets_0.5pct ~ "No cumple supuesto < 0.5%",
      abs(grand_mean) < 1e-9 ~ "0 (nivel ~0)",
      TRUE ~ "X × 0.003"
    )
  )

# --- Mostrar resultados ---
cat("\n========================================\n")
cat("EVALUACIÓN DE HOMOGENEIDAD - u_homo\n")
cat("Distribución rectangular: semi-ancho 0.5%\n")
cat("u = 0.5% / √3 ≈ 0.289% ≈ 0.3%\n")
cat("========================================\n\n")

results |>
  select(
    pollutant, level,
    mean_val_1, mean_val_2,
    n_1, n_2,
    grand_mean, diff_abs, diff_pct,
    meets_0.5pct, u_homo_formula, u_homo_abs
  ) |>
  print(n = Inf, width = Inf)

cat("\n--- Resumen: niveles que NO cumplen < 0.5% ---\n")
no_cumplen <- results |> filter(!meets_0.5pct)
if (nrow(no_cumplen) == 0) {
  cat("Todos los niveles cumplen el criterio < 0.5%\n")
} else {
  no_cumplen |>
    select(pollutant, level, diff_pct) |>
    print(n = Inf)
}

cat("\n--- Valores de u_homo por nivel ---\n")
results |>
  select(pollutant, level, grand_mean, u_homo_abs, u_homo_formula) |>
  print(n = Inf, width = Inf)