# ============================================================================
# Script: Demo Cálculo de Homogeneidad, Estabilidad e Incertidumbre
# 
# Descripción: Este script demuestra paso a paso los cálculos de
# homogeneidad, estabilidad e incertidumbre implementados en app.R
# (líneas 223-556).
#
# Datos utilizados:
# - data/homogeneity.csv (para demostrar homogeneidad)
# - data/stability.csv (para demostrar estabilidad)
# - data/summary_n4.csv (para cálculos de incertidumbre del PT)
# ============================================================================

library(tidyverse)

# Establecer directorio de trabajo
setwd("/home/w182/w421/pt_app")

# ============================================================================
# PARTE 1: FUNCIÓN AUXILIAR calculate_niqr
# ============================================================================

#' Calcula el nIQR (normalized Interquartile Range)
#' @param x vector numérico
#' @return estimador robusto de la desviación estándar
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}

# ============================================================================
# PARTE 2: CÁLCULOS DE HOMOGENEIDAD
# ============================================================================

cat("\n", rep("=", 70), "\n", sep = "")
cat("CÁLCULOS DE HOMOGENEIDAD\n")
cat(rep("=", 70), "\n", sep = "")

# --- Paso 1: Cargar y preparar datos de homogeneidad ---
hom_data <- read.csv("data/homogeneity.csv")

# Parámetros de demostración
target_pollutant <- "co"
target_level <- "2-μmol/mol"

cat("\nParámetros seleccionados:\n")
cat(sprintf("  - Contaminante: %s\n", target_pollutant))
cat(sprintf("  - Nivel: %s\n", target_level))

# --- Paso 2: Transformar a formato ancho (get_wide_data) ---
# La estructura de homogeneity.csv es: pollutant, level, replicate, sample_id, value
# Necesitamos pivotar para tener sample_1, sample_2, etc. como columnas
wide_df <- hom_data %>%
  filter(pollutant == target_pollutant) %>%
  select(-pollutant) %>%
  pivot_wider(
    id_cols = c(level, sample_id),
    names_from = replicate,
    values_from = value,
    names_prefix = "sample_"
  )

# Filtrar por nivel
level_data <- wide_df %>%
  filter(level == target_level) %>%
  select(starts_with("sample_"))

# Dimensiones
g <- nrow(level_data)  # número de ítems
m <- ncol(level_data)  # número de réplicas

cat(sprintf("\nDatos filtrados:\n"))
cat(sprintf("  - Número de ítems (g): %d\n", g))
cat(sprintf("  - Número de réplicas por ítem (m): %d\n", m))
cat("\nPrimeras filas de datos:\n")
print(head(level_data))

# --- Paso 3: Cálculo de estadísticos por ítem ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Paso 3: Estadísticos por Ítem\n")
cat(rep("-", 50), "\n", sep = "")

intermediate_df <- level_data %>%
  mutate(
    Item = row_number(),
    average = (sample_1 + sample_2) / 2,  # Para m=2
    range = abs(sample_1 - sample_2)
  )

cat("\nTabla de medias y rangos por ítem:\n")
print(intermediate_df %>% select(Item, sample_1, sample_2, average, range))

# --- Paso 4: Cálculo de MADe (sigma_pt) ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Paso 4: Cálculo de MADe (σ_pt)\n")
cat(rep("-", 50), "\n", sep = "")

first_sample_results <- level_data %>% pull(sample_1)
median_val <- median(first_sample_results, na.rm = TRUE)
abs_diff_from_median <- abs(first_sample_results - median_val)
median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
mad_e <- 1.483 * median_abs_diff

cat(sprintf("\nValores de sample_1:\n"))
print(first_sample_results)
cat(sprintf("\n1. Mediana de sample_1: %.6f\n", median_val))
cat(sprintf("2. Desviaciones absolutas de la mediana:\n"))
print(abs_diff_from_median)
cat(sprintf("3. MAD (mediana de desviaciones): %.6f\n", median_abs_diff))
cat(sprintf("4. MADe (σ_pt) = 1.483 × MAD = 1.483 × %.6f = %.6f\n", 
            median_abs_diff, mad_e))

# Calcular nIQR también
n_iqr <- calculate_niqr(first_sample_results)
cat(sprintf("\n5. nIQR (estimador alternativo) = 0.7413 × IQR = %.6f\n", n_iqr))

# --- Paso 5: Cálculo de u_xpt ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Paso 5: Cálculo de u_xpt (incertidumbre del valor asignado)\n")
cat(rep("-", 50), "\n", sep = "")

n_robust <- length(first_sample_results)
u_xpt <- 1.25 * mad_e / sqrt(n_robust)

cat(sprintf("\nu_xpt = 1.25 × MADe / √n\n"))
cat(sprintf("u_xpt = 1.25 × %.6f / √%d\n", mad_e, n_robust))
cat(sprintf("u_xpt = %.6f / %.6f\n", 1.25 * mad_e, sqrt(n_robust)))
cat(sprintf("u_xpt = %.6f\n", u_xpt))

# --- Paso 6: Cálculos ANOVA (varianzas entre e intra grupos) ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Paso 6: Cálculos de Varianza (ANOVA)\n")
cat(rep("-", 50), "\n", sep = "")

# Estadísticos por ítem
hom_data_long <- level_data %>%
  mutate(Item = factor(row_number())) %>%
  pivot_longer(cols = -Item, names_to = "replicate", values_to = "Resultado")

hom_item_stats <- hom_data_long %>%
  group_by(Item) %>%
  summarise(
    mean = mean(Resultado, na.rm = TRUE),
    var = var(Resultado, na.rm = TRUE),
    diff = max(Resultado, na.rm = TRUE) - min(Resultado, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nEstadísticos resumidos por ítem:\n")
print(hom_item_stats)

# Media general y varianza de medias
hom_x_t_bar <- mean(hom_item_stats$mean, na.rm = TRUE)
hom_s_x_bar_sq <- var(hom_item_stats$mean, na.rm = TRUE)
hom_s_xt <- sqrt(hom_s_x_bar_sq)

cat(sprintf("\na) Media general (x̄..): %.6f\n", hom_x_t_bar))
cat(sprintf("b) Varianza de las medias (s_x̄²): %.8f\n", hom_s_x_bar_sq))
cat(sprintf("c) Desviación estándar de las medias (s_x̄): %.6f\n", hom_s_xt))

# Desviación intra-muestra (s_w)
hom_wt <- abs(hom_item_stats$diff)
hom_sw <- sqrt(sum(hom_wt^2) / (2 * length(hom_wt)))

cat(sprintf("\nd) Rangos por ítem (w_i):\n"))
print(hom_wt)
cat(sprintf("\ne) s_w = √(Σw_i² / 2g) = √(%.8f / %d) = %.6f\n", 
            sum(hom_wt^2), 2 * length(hom_wt), hom_sw))

# Desviación entre-muestras (s_s)
hom_ss_sq <- abs(hom_s_xt^2 - ((hom_sw^2) / 2))
hom_ss <- sqrt(hom_ss_sq)

cat(sprintf("\nf) s_s² = s_x̄² - s_w²/2 = %.8f - %.8f/2 = %.8f\n", 
            hom_s_xt^2, hom_sw^2, hom_ss_sq))
cat(sprintf("g) s_s = √(s_s²) = %.6f\n", hom_ss))

# --- Paso 7: Evaluación de criterios de homogeneidad ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Paso 7: Evaluación de Criterios de Homogeneidad\n")
cat(rep("-", 50), "\n", sep = "")

hom_sigma_pt <- mad_e
hom_c_criterion <- 0.3 * hom_sigma_pt
hom_sigma_allowed_sq <- hom_c_criterion^2
hom_c_criterion_expanded <- sqrt(hom_sigma_allowed_sq * 1.88 + (hom_sw^2) * 1.01)

cat(sprintf("\nCriterio básico: s_s ≤ 0.3 × σ_pt\n"))
cat(sprintf("  c = 0.3 × %.6f = %.6f\n", hom_sigma_pt, hom_c_criterion))
cat(sprintf("  s_s = %.6f\n", hom_ss))
cat(sprintf("  Evaluación: %.6f %s %.6f → %s\n", 
            hom_ss, ifelse(hom_ss <= hom_c_criterion, "≤", ">"), hom_c_criterion,
            ifelse(hom_ss <= hom_c_criterion, "CUMPLE", "NO CUMPLE")))

cat(sprintf("\nCriterio expandido: s_s ≤ √(1.88×c² + 1.01×s_w²)\n"))
cat(sprintf("  c_expandido = √(1.88 × %.8f + 1.01 × %.8f)\n", 
            hom_sigma_allowed_sq, hom_sw^2))
cat(sprintf("  c_expandido = √(%.8f + %.8f) = %.6f\n", 
            1.88 * hom_sigma_allowed_sq, 1.01 * hom_sw^2, hom_c_criterion_expanded))
cat(sprintf("  Evaluación: %.6f %s %.6f → %s\n", 
            hom_ss, ifelse(hom_ss <= hom_c_criterion_expanded, "≤", ">"), 
            hom_c_criterion_expanded,
            ifelse(hom_ss <= hom_c_criterion_expanded, "CUMPLE", "NO CUMPLE")))

# ============================================================================
# PARTE 3: CÁLCULOS DE ESTABILIDAD
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep = "")
cat("CÁLCULOS DE ESTABILIDAD\n")
cat(rep("=", 70), "\n", sep = "")

# --- Cargar datos de estabilidad ---
stab_data_full <- read.csv("data/stability.csv")

# Transformar a formato ancho
stab_wide_df <- stab_data_full %>%
  filter(pollutant == target_pollutant) %>%
  select(-pollutant) %>%
  pivot_wider(
    id_cols = c(level, sample_id),
    names_from = replicate,
    values_from = value,
    names_prefix = "sample_"
  )

stab_level_data <- stab_wide_df %>%
  filter(level == target_level) %>%
  select(starts_with("sample_"))

cat(sprintf("\nDatos de estabilidad para %s - %s:\n", target_pollutant, target_level))
print(head(stab_level_data))

# Calcular estadísticos de estabilidad
stab_data_long <- stab_level_data %>%
  mutate(Item = factor(row_number())) %>%
  pivot_longer(cols = -Item, names_to = "replicate", values_to = "Resultado")

stab_item_stats <- stab_data_long %>%
  group_by(Item) %>%
  summarise(
    mean = mean(Resultado, na.rm = TRUE),
    diff = max(Resultado, na.rm = TRUE) - min(Resultado, na.rm = TRUE),
    .groups = "drop"
  )

# Media general de estabilidad
stab_x_t_bar <- mean(stab_item_stats$mean, na.rm = TRUE)

# --- Diferencia entre homogeneidad y estabilidad ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Cálculo de la Diferencia D\n")
cat(rep("-", 50), "\n", sep = "")

diff_hom_stab <- abs(stab_x_t_bar - hom_x_t_bar)

cat(sprintf("\nMedia general de homogeneidad (ȳ_hom): %.6f\n", hom_x_t_bar))
cat(sprintf("Media general de estabilidad (ȳ_stab): %.6f\n", stab_x_t_bar))
cat(sprintf("\nD = |ȳ_hom - ȳ_stab| = |%.6f - %.6f| = %.6f\n", 
            hom_x_t_bar, stab_x_t_bar, diff_hom_stab))

# --- Cálculo de incertidumbres para criterio expandido ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Incertidumbres de las Medias\n")
cat(rep("-", 50), "\n", sep = "")

# Incertidumbre de la media de homogeneidad
hom_all_values <- wide_df %>%
  filter(level == target_level) %>%
  select(starts_with("sample_")) %>%
  unlist() %>%
  as.numeric()
hom_all_values <- hom_all_values[!is.na(hom_all_values)]

sd_hom_mean <- sd(hom_all_values)
n_hom <- length(hom_all_values)
u_hom_mean <- sd_hom_mean / sqrt(n_hom)

cat(sprintf("\nIncertidumbre de la media de homogeneidad:\n"))
cat(sprintf("  Número de valores: n_hom = %d\n", n_hom))
cat(sprintf("  Desviación estándar: s_hom = %.6f\n", sd_hom_mean))
cat(sprintf("  u_hom_mean = s_hom / √n_hom = %.6f / √%d = %.6f\n", 
            sd_hom_mean, n_hom, u_hom_mean))

# Incertidumbre de la media de estabilidad
stab_all_values <- stab_data_long$Resultado
stab_all_values <- stab_all_values[!is.na(stab_all_values)]

sd_stab_mean <- sd(stab_all_values)
n_stab <- length(stab_all_values)
u_stab_mean <- sd_stab_mean / sqrt(n_stab)

cat(sprintf("\nIncertidumbre de la media de estabilidad:\n"))
cat(sprintf("  Número de valores: n_stab = %d\n", n_stab))
cat(sprintf("  Desviación estándar: s_stab = %.6f\n", sd_stab_mean))
cat(sprintf("  u_stab_mean = s_stab / √n_stab = %.6f / √%d = %.6f\n", 
            sd_stab_mean, n_stab, u_stab_mean))

# --- Evaluación de criterios de estabilidad ---
cat("\n", rep("-", 50), "\n", sep = "")
cat("Evaluación de Criterios de Estabilidad\n")
cat(rep("-", 50), "\n", sep = "")

stab_c_criterion <- 0.3 * hom_sigma_pt
stab_c_criterion_expanded <- stab_c_criterion + 2 * sqrt(u_hom_mean^2 + u_stab_mean^2)

cat(sprintf("\nCriterio básico: D ≤ 0.3 × σ_pt\n"))
cat(sprintf("  c = 0.3 × %.6f = %.6f\n", hom_sigma_pt, stab_c_criterion))
cat(sprintf("  D = %.6f\n", diff_hom_stab))
cat(sprintf("  Evaluación: %.6f %s %.6f → %s\n", 
            diff_hom_stab, ifelse(diff_hom_stab <= stab_c_criterion, "≤", ">"), 
            stab_c_criterion,
            ifelse(diff_hom_stab <= stab_c_criterion, "CUMPLE", "NO CUMPLE")))

cat(sprintf("\nCriterio expandido: D ≤ 0.3×σ_pt + 2×√(u_hom² + u_stab²)\n"))
cat(sprintf("  c_expandido = %.6f + 2 × √(%.8f + %.8f)\n", 
            stab_c_criterion, u_hom_mean^2, u_stab_mean^2))
cat(sprintf("  c_expandido = %.6f + 2 × %.6f = %.6f\n", 
            stab_c_criterion, sqrt(u_hom_mean^2 + u_stab_mean^2), 
            stab_c_criterion_expanded))
cat(sprintf("  Evaluación: %.6f %s %.6f → %s\n", 
            diff_hom_stab, ifelse(diff_hom_stab <= stab_c_criterion_expanded, "≤", ">"), 
            stab_c_criterion_expanded,
            ifelse(diff_hom_stab <= stab_c_criterion_expanded, "CUMPLE", "NO CUMPLE")))

# ============================================================================
# PARTE 4: USO DE DATOS DE PARTICIPANTES (summary_n4.csv)
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep = "")
cat("CÁLCULOS CON DATOS DE PARTICIPANTES (summary_n4.csv)\n")
cat(rep("=", 70), "\n", sep = "")

summary_data <- read.csv("data/summary_n4.csv")

cat("\nEstructura del archivo summary_n4.csv:\n")
str(summary_data)

# Seleccionar un pollutant y level para demostración
pt_pollutant <- "co"
pt_level <- "2-μmol/mol"

# Filtrar datos de participantes
pt_data <- summary_data %>%
  filter(pollutant == pt_pollutant, level == pt_level)

cat(sprintf("\nDatos de participantes para %s - %s:\n", pt_pollutant, pt_level))
print(pt_data)

# Agregar por participante
pt_aggregated <- pt_data %>%
  filter(participant_id != "ref") %>%
  group_by(participant_id) %>%
  summarise(
    mean_result = mean(mean_value, na.rm = TRUE),
    mean_sd = mean(sd_value, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nDatos agregados por participante (sin referencia):\n")
print(pt_aggregated)

# Calcular estadísticos robustos de participantes
participant_values <- pt_aggregated$mean_result

# MADe de participantes
pt_median <- median(participant_values, na.rm = TRUE)
pt_abs_diff <- abs(participant_values - pt_median)
pt_mad <- median(pt_abs_diff, na.rm = TRUE)
pt_mad_e <- 1.483 * pt_mad

# nIQR de participantes
pt_niqr <- calculate_niqr(participant_values)

# u_xpt de participantes
pt_n <- length(participant_values)
pt_u_xpt <- 1.25 * pt_mad_e / sqrt(pt_n)

cat("\n", rep("-", 50), "\n", sep = "")
cat("Estadísticos robustos de participantes:\n")
cat(rep("-", 50), "\n", sep = "")
cat(sprintf("\n1. Valores de los participantes:\n"))
print(participant_values)
cat(sprintf("\n2. Mediana: %.6f\n", pt_median))
cat(sprintf("3. MAD: %.6f\n", pt_mad))
cat(sprintf("4. MADe (σ_pt): %.6f\n", pt_mad_e))
cat(sprintf("5. nIQR: %.6f\n", pt_niqr))
cat(sprintf("6. Número de participantes (n): %d\n", pt_n))
cat(sprintf("7. u_xpt = 1.25 × %.6f / √%d = %.6f\n", pt_mad_e, pt_n, pt_u_xpt))

# ============================================================================
# PARTE 5: RESUMEN DE TODOS LOS RESULTADOS
# ============================================================================

cat("\n\n", rep("=", 70), "\n", sep = "")
cat("RESUMEN DE RESULTADOS\n")
cat(rep("=", 70), "\n", sep = "")

resumen <- data.frame(
  Variable = c(
    "σ_pt (MADe) - Homogeneidad",
    "u_xpt - Homogeneidad",
    "s_s (desv. entre-muestras)",
    "s_w (desv. intra-muestra)",
    "nIQR - Homogeneidad",
    "Criterio c (0.3×σ_pt)",
    "Criterio expandido",
    "D (diferencia hom-stab)",
    "u_hom_mean",
    "u_stab_mean",
    "σ_pt (MADe) - Participantes",
    "u_xpt - Participantes"
  ),
  Valor = round(c(
    hom_sigma_pt,
    u_xpt,
    hom_ss,
    hom_sw,
    n_iqr,
    hom_c_criterion,
    hom_c_criterion_expanded,
    diff_hom_stab,
    u_hom_mean,
    u_stab_mean,
    pt_mad_e,
    pt_u_xpt
  ), 6)
)

print(resumen)

cat("\n", rep("=", 70), "\n", sep = "")
cat("FIN DEL SCRIPT DE DEMOSTRACIÓN\n")
cat(rep("=", 70), "\n\n", sep = "")
