# =============================================================================
# Script de Demostración: Cálculo de los 4 Scores en Ensayos de Aptitud
# Basado en la función compute_scores_metrics de app.R (líneas 557-635)
# =============================================================================

library(tidyverse)

# Helper function para crear líneas divisoras
line_sep <- function(char = "=", n = 70) paste0(char, strrep(char, n))

# =============================================================================
# PASO 1: CARGAR DATOS
# =============================================================================

cat(line_sep("="), "\n")
cat("CÁLCULO DE LOS 4 SCORES DE ENSAYOS DE APTITUD\n")
cat(line_sep("="), "\n\n")

# Cargar datos
summary_data <- read_csv("data/summary_n4.csv", show_col_types = FALSE)

cat("✓ Datos cargados: summary_n4.csv\n")
cat("  - Filas:", nrow(summary_data), "\n")
cat("  - Columnas:", ncol(summary_data), "\n")
cat("  - Variables:", paste(names(summary_data), collapse = ", "), "\n\n")

# Mostrar estructura de datos
cat("Estructura de datos:\n")
print(head(summary_data, 5))
cat("\n")

# =============================================================================
# PASO 2: SELECCIONAR DATOS PARA EL EJEMPLO
# =============================================================================

# Parámetros de ejemplo
target_pollutant <- "co"
target_level <- "2-μmol/mol"

cat(line_sep("-"), "\n")
cat("PARÁMETROS SELECCIONADOS\n")
cat(line_sep("-"), "\n")
cat("  Contaminante:", target_pollutant, "\n")
cat("  Nivel:", target_level, "\n\n")

# Filtrar datos para el analito y nivel seleccionados
data_filtered <- summary_data %>%
  filter(
    pollutant == target_pollutant,
    level == target_level
  )

cat("✓ Datos filtrados:", nrow(data_filtered), "filas\n\n")
print(data_filtered)
cat("\n")

# =============================================================================
# PASO 3: CALCULAR VALOR ASIGNADO (x_pt)
# =============================================================================

cat(line_sep("-"), "\n")
cat("PASO 3: VALOR ASIGNADO (x_pt)\n")
cat(line_sep("-"), "\n")

# Datos de referencia
ref_data <- data_filtered %>% 
  filter(participant_id == "ref")

cat("Datos de referencia:\n")
print(ref_data)
cat("\n")

# Calcular x_pt como la media de los valores de referencia
x_pt <- mean(ref_data$mean_value, na.rm = TRUE)

cat("Fórmula: x_pt = media de los valores de referencia\n")
cat("x_pt = (", paste(round(ref_data$mean_value, 6), collapse = " + "), ") /", nrow(ref_data), "\n")
cat("x_pt =", round(x_pt, 6), "\n\n")

# =============================================================================
# PASO 4: DEFINIR PARÁMETROS DEL PT
# =============================================================================

cat(line_sep("-"), "\n")
cat("PASO 4: PARÁMETROS DEL ENSAYO DE APTITUD\n")
cat(line_sep("-"), "\n")

# Calcular sigma_pt usando MADe (Median Absolute Deviation escalado)
all_values <- data_filtered$mean_value
median_val <- median(all_values, na.rm = TRUE)
abs_diff_from_median <- abs(all_values - median_val)
median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
sigma_pt <- 1.483 * median_abs_diff

cat("Cálculo de sigma_pt (usando MADe):\n")
cat("  1. Mediana de todos los valores:", round(median_val, 6), "\n")
cat("  2. |xi - mediana| para cada valor:\n")
print(round(abs_diff_from_median, 6))
cat("  3. Mediana de |xi - mediana|:", round(median_abs_diff, 6), "\n")
cat("  4. MADe = 1.483 × MAD =", round(sigma_pt, 6), "\n\n")

# Calcular u_xpt (incertidumbre del valor asignado)
n_robust <- length(all_values)
u_xpt <- 1.25 * sigma_pt / sqrt(n_robust)

cat("Cálculo de u_xpt:\n")
cat("  Fórmula: u_xpt = 1.25 × sigma_pt / sqrt(n)\n")
cat("  u_xpt = 1.25 ×", round(sigma_pt, 6), "/ sqrt(", n_robust, ")\n")
cat("  u_xpt =", round(u_xpt, 6), "\n\n")

# Factor de cobertura
k <- 2

cat("Factor de cobertura: k =", k, "\n")
cat("  (Para intervalo de confianza del 95%)\n\n")

# =============================================================================
# PASO 5: PREPARAR DATOS DE PARTICIPANTES
# =============================================================================

cat(line_sep("-"), "\n")
cat("PASO 5: PREPARACIÓN DE DATOS DE PARTICIPANTES\n")
cat(line_sep("-"), "\n")

# Número de réplicas (sample_groups por participante)
m <- 3  # 3 sample_groups: "1-10", "11-20", "21-30"

participant_data <- data_filtered %>%
  mutate(
    result = mean_value,
    # Incertidumbre estándar del participante
    uncertainty_std = sd_value / sqrt(m)
  )

cat("Número de réplicas (m):", m, "\n")
cat("Incertidumbre del participante: u_i = sd_value / sqrt(m)\n\n")

cat("Datos preparados:\n")
participant_data %>%
  select(participant_id, sample_group, result, sd_value, uncertainty_std) %>%
  print()
cat("\n")

# =============================================================================
# PASO 6: CÁLCULO DE LOS 4 SCORES
# =============================================================================

cat(line_sep("-"), "\n")
cat("PASO 6: CÁLCULO DE LOS 4 SCORES\n")
cat(line_sep("-"), "\n\n")

# Calcular todos los scores
scores <- participant_data %>%
  mutate(
    x_pt = x_pt,
    sigma_pt = sigma_pt,
    u_xpt = u_xpt,
    
    # 1. z-score
    z_score = (result - x_pt) / sigma_pt,
    
    # 2. z'-score (z prima)
    z_prime_denom = sqrt(sigma_pt^2 + u_xpt^2),
    z_prime_score = (result - x_pt) / z_prime_denom,
    
    # 3. zeta-score
    zeta_denom = sqrt(uncertainty_std^2 + u_xpt^2),
    zeta_score = (result - x_pt) / zeta_denom,
    
    # 4. En-score
    U_xi = k * uncertainty_std,
    U_xpt = k * u_xpt,
    En_denom = sqrt(U_xi^2 + U_xpt^2),
    En_score = (result - x_pt) / En_denom
  )

# =============================================================================
# MOSTRAR CÁLCULOS DETALLADOS PARA LA PRIMERA FILA
# =============================================================================

cat("EJEMPLO DETALLADO (primera fila de datos):\n")
cat(line_sep("-", 50), "\n")

primera_fila <- scores[1, ]

cat("\nParticipante:", primera_fila$participant_id, "\n")
cat("Grupo de muestra:", primera_fila$sample_group, "\n")
cat("Resultado (xi):", round(primera_fila$result, 6), "\n")
cat("Desviación estándar:", round(primera_fila$sd_value, 6), "\n")
cat("Incertidumbre estándar (ui):", round(primera_fila$uncertainty_std, 6), "\n")
cat("\n")

cat("1. z-score:\n")
cat("   Fórmula: z = (xi - x_pt) / sigma_pt\n")
cat("   z = (", round(primera_fila$result, 6), "-", round(x_pt, 6), ") /", round(sigma_pt, 6), "\n")
cat("   z =", round(primera_fila$z_score, 4), "\n\n")

cat("2. z'-score:\n")
cat("   Fórmula: z' = (xi - x_pt) / sqrt(sigma_pt² + u_xpt²)\n")
cat("   Denominador = sqrt(", round(sigma_pt^2, 8), "+", round(u_xpt^2, 8), ") =", round(primera_fila$z_prime_denom, 6), "\n")
cat("   z' = (", round(primera_fila$result, 6), "-", round(x_pt, 6), ") /", round(primera_fila$z_prime_denom, 6), "\n")
cat("   z' =", round(primera_fila$z_prime_score, 4), "\n\n")

cat("3. zeta-score:\n")
cat("   Fórmula: zeta = (xi - x_pt) / sqrt(ui² + u_xpt²)\n")
cat("   Denominador = sqrt(", round(primera_fila$uncertainty_std^2, 8), "+", round(u_xpt^2, 8), ") =", round(primera_fila$zeta_denom, 6), "\n")
cat("   zeta = (", round(primera_fila$result, 6), "-", round(x_pt, 6), ") /", round(primera_fila$zeta_denom, 6), "\n")
cat("   zeta =", round(primera_fila$zeta_score, 4), "\n\n")

cat("4. En-score:\n")
cat("   Fórmula: En = (xi - x_pt) / sqrt(U_xi² + U_xpt²)\n")
cat("   U_xi = k × ui =", k, "×", round(primera_fila$uncertainty_std, 6), "=", round(primera_fila$U_xi, 6), "\n")
cat("   U_xpt = k × u_xpt =", k, "×", round(u_xpt, 6), "=", round(primera_fila$U_xpt, 6), "\n")
cat("   Denominador = sqrt(", round(primera_fila$U_xi^2, 8), "+", round(primera_fila$U_xpt^2, 8), ") =", round(primera_fila$En_denom, 6), "\n")
cat("   En = (", round(primera_fila$result, 6), "-", round(x_pt, 6), ") /", round(primera_fila$En_denom, 6), "\n")
cat("   En =", round(primera_fila$En_score, 4), "\n\n")

# =============================================================================
# PASO 7: EVALUACIÓN DE LOS SCORES
# =============================================================================

cat(line_sep("-"), "\n")
cat("PASO 7: EVALUACIÓN DE LOS SCORES\n")
cat(line_sep("-"), "\n\n")

# Evaluar scores
scores_evaluated <- scores %>%
  mutate(
    z_score_eval = case_when(
      abs(z_score) <= 2 ~ "Satisfactorio",
      abs(z_score) > 2 & abs(z_score) < 3 ~ "Cuestionable",
      abs(z_score) >= 3 ~ "No satisfactorio",
      TRUE ~ "N/A"
    ),
    z_prime_score_eval = case_when(
      abs(z_prime_score) <= 2 ~ "Satisfactorio",
      abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Cuestionable",
      abs(z_prime_score) >= 3 ~ "No satisfactorio",
      TRUE ~ "N/A"
    ),
    zeta_score_eval = case_when(
      abs(zeta_score) <= 2 ~ "Satisfactorio",
      abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Cuestionable",
      abs(zeta_score) >= 3 ~ "No satisfactorio",
      TRUE ~ "N/A"
    ),
    En_score_eval = case_when(
      abs(En_score) <= 1 ~ "Satisfactorio",
      abs(En_score) > 1 ~ "No satisfactorio",
      TRUE ~ "N/A"
    )
  )

cat("Criterios de evaluación:\n")
cat("  z, z', zeta:\n")
cat("    |score| ≤ 2     → Satisfactorio\n")
cat("    2 < |score| < 3 → Cuestionable\n")
cat("    |score| ≥ 3     → No satisfactorio\n")
cat("\n")
cat("  En:\n")
cat("    |En| ≤ 1 → Satisfactorio\n")
cat("    |En| > 1 → No satisfactorio\n")
cat("\n")

# =============================================================================
# PASO 8: RESULTADOS FINALES
# =============================================================================

cat(line_sep("-"), "\n")
cat("PASO 8: RESULTADOS FINALES\n")
cat(line_sep("-"), "\n\n")

# Tabla resumen de scores
results_summary <- scores_evaluated %>%
  select(
    participant_id,
    sample_group,
    result,
    z_score,
    z_score_eval,
    z_prime_score,
    z_prime_score_eval,
    zeta_score,
    zeta_score_eval,
    En_score,
    En_score_eval
  )

cat("Tabla de resultados:\n")
print(results_summary)
cat("\n")

# Resumen estadístico
cat(line_sep("-"), "\n")
cat("RESUMEN ESTADÍSTICO\n")
cat(line_sep("-"), "\n")

cat("\nParámetros utilizados:\n")
cat("  x_pt (valor asignado):", round(x_pt, 6), "\n")
cat("  sigma_pt (desv. estándar PT):", round(sigma_pt, 6), "\n")
cat("  u_xpt (incertidumbre del VA):", round(u_xpt, 6), "\n")
cat("  k (factor de cobertura):", k, "\n")
cat("  m (número de réplicas):", m, "\n")
cat("\n")

# Conteo de evaluaciones
cat("Conteo de evaluaciones por score:\n\n")

count_evaluations <- function(eval_col, score_name) {
  counts <- table(eval_col)
  cat("  ", score_name, ":\n")
  for (name in names(counts)) {
    cat("    -", name, ":", counts[name], "\n")
  }
  cat("\n")
}

count_evaluations(scores_evaluated$z_score_eval, "z-score")
count_evaluations(scores_evaluated$z_prime_score_eval, "z'-score")
count_evaluations(scores_evaluated$zeta_score_eval, "zeta-score")
count_evaluations(scores_evaluated$En_score_eval, "En-score")

cat(line_sep("="), "\n")
cat("FIN DEL CÁLCULO DE SCORES\n")
cat(line_sep("="), "\n")

# =============================================================================
# FUNCIÓN REUTILIZABLE
# =============================================================================

#' Función para calcular los 4 scores de PT
#' 
#' @param summary_df DataFrame con columnas: pollutant, level, participant_id, 
#'                   sample_group, mean_value, sd_value
#' @param target_pollutant Analito a evaluar
#' @param target_level Nivel de concentración
#' @param sigma_pt Desviación estándar para aptitud
#' @param u_xpt Incertidumbre del valor asignado
#' @param k Factor de cobertura (default = 2)
#' @param m Número de réplicas (default = 3)
#' 
#' @return Lista con: x_pt, sigma_pt, u_xpt, k, y dataframe de scores
compute_pt_scores <- function(summary_df, target_pollutant, target_level, 
                               sigma_pt = NULL, u_xpt = NULL, k = 2, m = 3) {
  
  # Filtrar datos
  data <- summary_df %>%
    filter(
      pollutant == target_pollutant,
      level == target_level
    )
  
  if (nrow(data) == 0) {
    return(list(error = "No se encontraron datos para los criterios seleccionados."))
  }
  
  # Calcular valor asignado
  ref_data <- data %>% filter(participant_id == "ref")
  
  if (nrow(ref_data) == 0) {
    return(list(error = "No se encontraron datos de referencia."))
  }
  
  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  
  # Calcular sigma_pt si no se proporciona
  if (is.null(sigma_pt)) {
    all_values <- data$mean_value
    median_val <- median(all_values, na.rm = TRUE)
    median_abs_diff <- median(abs(all_values - median_val), na.rm = TRUE)
    sigma_pt <- 1.483 * median_abs_diff
  }
  
  # Calcular u_xpt si no se proporciona
  if (is.null(u_xpt)) {
    n <- length(data$mean_value)
    u_xpt <- 1.25 * sigma_pt / sqrt(n)
  }
  
  # Preparar datos y calcular scores
  scores <- data %>%
    mutate(
      result = mean_value,
      uncertainty_std = sd_value / sqrt(m),
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      u_xpt = u_xpt,
      z_score = (result - x_pt) / sigma_pt,
      z_prime_score = (result - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
      zeta_score = (result - x_pt) / sqrt(uncertainty_std^2 + u_xpt^2),
      U_xi = k * uncertainty_std,
      U_xpt = k * u_xpt,
      En_score = (result - x_pt) / sqrt(U_xi^2 + U_xpt^2),
      z_score_eval = case_when(
        abs(z_score) <= 2 ~ "Satisfactorio",
        abs(z_score) > 2 & abs(z_score) < 3 ~ "Cuestionable",
        abs(z_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      z_prime_score_eval = case_when(
        abs(z_prime_score) <= 2 ~ "Satisfactorio",
        abs(z_prime_score) > 2 & abs(z_prime_score) < 3 ~ "Cuestionable",
        abs(z_prime_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      zeta_score_eval = case_when(
        abs(zeta_score) <= 2 ~ "Satisfactorio",
        abs(zeta_score) > 2 & abs(zeta_score) < 3 ~ "Cuestionable",
        abs(zeta_score) >= 3 ~ "No satisfactorio",
        TRUE ~ "N/A"
      ),
      En_score_eval = case_when(
        abs(En_score) <= 1 ~ "Satisfactorio",
        abs(En_score) > 1 ~ "No satisfactorio",
        TRUE ~ "N/A"
      )
    )
  
  list(
    error = NULL,
    x_pt = x_pt,
    sigma_pt = sigma_pt,
    u_xpt = u_xpt,
    k = k,
    m = m,
    scores = scores
  )
}

# Ejemplo de uso de la función
cat("\n\nEJEMPLO DE USO DE LA FUNCIÓN compute_pt_scores:\n")
cat(line_sep("-", 50), "\n")

result <- compute_pt_scores(
  summary_df = summary_data,
  target_pollutant = "no2",
  target_level = "30-nmol/mol"
)

if (is.null(result$error)) {
  cat("\n✓ Cálculo exitoso para NO2 - 30 nmol/mol\n")
  cat("  x_pt:", round(result$x_pt, 4), "\n")
  cat("  sigma_pt:", round(result$sigma_pt, 6), "\n")
  cat("  u_xpt:", round(result$u_xpt, 6), "\n")
  cat("\n")
  
  result$scores %>%
    select(participant_id, sample_group, z_score, z_score_eval, En_score, En_score_eval) %>%
    print()
} else {
  cat("Error:", result$error, "\n")
}
