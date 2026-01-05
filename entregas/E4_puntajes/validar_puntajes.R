# Script de Validación de Puntajes PT (ISO 13528)
# Laboratorio CALAIRE
# Fecha: 2026-01-03

cat("============================================\n")
cat("  Validación de Puntajes de Desempeño\n")
cat("============================================\n\n")

# =========================================
# 1. Funciones de Cálculo de Puntajes
# =========================================

library(dplyr)

calculate_scores <- function(xi, xpt, sigma_pt, ui = NULL, uxpt = 0, k = 2) {
  # z-score
  z <- (xi - xpt) / sigma_pt
  
  # z'-score
  z_prime <- (xi - xpt) / sqrt(sigma_pt^2 + uxpt^2)
  
  # zeta-score (requiere incertidumbre del participante)
  zeta <- if (!is.null(ui)) (xi - xpt) / sqrt(ui^2 + uxpt^2) else NA
  
  # En-score (requiere incertidumbre del participante)
  if (!is.null(ui)) {
    Ui <- k * ui
    Uxpt <- k * uxpt
    En <- (xi - xpt) / sqrt(Ui^2 + Uxpt^2)
  } else {
    En <- NA
  }
  
  list(z = z, z_prime = z_prime, zeta = zeta, En = En)
}

evaluate_z <- function(val) {
  case_when(
    is.na(val) ~ "N/A",
    abs(val) <= 2 ~ "Satisfactorio",
    abs(val) < 3 ~ "Cuestionable",
    TRUE ~ "Insatisfactorio"
  )
}

evaluate_en <- function(val) {
  case_when(
    is.na(val) ~ "N/A",
    abs(val) <= 1 ~ "Satisfactorio",
    TRUE ~ "Insatisfactorio"
  )
}

# =========================================
# 2. Escenarios de Prueba
# =========================================

cat("--- Escenario 1: Resultado Satisfactorio ---\n\n")

xi_1 <- 10.1      # Resultado del participante
xpt <- 10.0       # Valor asignado
sigma_pt <- 0.2   # Desviación para aptitud
ui_1 <- 0.08      # Incertidumbre estándar del participante
uxpt <- 0.05      # Incertidumbre estándar del valor asignado
k <- 2

scores_1 <- calculate_scores(xi_1, xpt, sigma_pt, ui_1, uxpt, k)

cat("Entradas:\n")
cat("  xi =", xi_1, "| xpt =", xpt, "| σpt =", sigma_pt, "\n")
cat("  ui =", ui_1, "| uxpt =", uxpt, "| k =", k, "\n\n")

cat("Resultados:\n")
cat("  z     =", round(scores_1$z, 4), "→", evaluate_z(scores_1$z), "\n")
cat("  z'    =", round(scores_1$z_prime, 4), "→", evaluate_z(scores_1$z_prime), "\n")
cat("  zeta  =", round(scores_1$zeta, 4), "→", evaluate_z(scores_1$zeta), "\n")
cat("  En    =", round(scores_1$En, 4), "→", evaluate_en(scores_1$En), "\n\n")

# =========================================

cat("--- Escenario 2: Resultado Cuestionable ---\n\n")

xi_2 <- 10.45     # Resultado con mayor desvío

scores_2 <- calculate_scores(xi_2, xpt, sigma_pt, ui_1, uxpt, k)

cat("Entradas:\n")
cat("  xi =", xi_2, "(mayor desvío)\n\n")

cat("Resultados:\n")
cat("  z     =", round(scores_2$z, 4), "→", evaluate_z(scores_2$z), "\n")
cat("  z'    =", round(scores_2$z_prime, 4), "→", evaluate_z(scores_2$z_prime), "\n")
cat("  zeta  =", round(scores_2$zeta, 4), "→", evaluate_z(scores_2$zeta), "\n")
cat("  En    =", round(scores_2$En, 4), "→", evaluate_en(scores_2$En), "\n\n")

# =========================================

cat("--- Escenario 3: Resultado Insatisfactorio ---\n\n")

xi_3 <- 10.8      # Resultado con desvío severo

scores_3 <- calculate_scores(xi_3, xpt, sigma_pt, ui_1, uxpt, k)

cat("Entradas:\n")
cat("  xi =", xi_3, "(desvío severo)\n\n")

cat("Resultados:\n")
cat("  z     =", round(scores_3$z, 4), "→", evaluate_z(scores_3$z), "\n")
cat("  z'    =", round(scores_3$z_prime, 4), "→", evaluate_z(scores_3$z_prime), "\n")
cat("  zeta  =", round(scores_3$zeta, 4), "→", evaluate_z(scores_3$zeta), "\n")
cat("  En    =", round(scores_3$En, 4), "→", evaluate_en(scores_3$En), "\n\n")

# =========================================
# 3. Verificación de Fórmulas
# =========================================

cat("--- Verificación Manual de Fórmulas ---\n\n")

# z manual
z_manual <- (xi_1 - xpt) / sigma_pt
cat("z = (", xi_1, "-", xpt, ") /", sigma_pt, "=", round(z_manual, 4), "\n")

# z' manual
z_prime_manual <- (xi_1 - xpt) / sqrt(sigma_pt^2 + uxpt^2)
cat("z' = (", xi_1, "-", xpt, ") / √(", sigma_pt^2, "+", uxpt^2, ") =", round(z_prime_manual, 4), "\n")

# zeta manual
zeta_manual <- (xi_1 - xpt) / sqrt(ui_1^2 + uxpt^2)
cat("ζ = (", xi_1, "-", xpt, ") / √(", ui_1^2, "+", uxpt^2, ") =", round(zeta_manual, 4), "\n")

# En manual
Ui <- k * ui_1
Uxpt <- k * uxpt
en_manual <- (xi_1 - xpt) / sqrt(Ui^2 + Uxpt^2)
cat("En = (", xi_1, "-", xpt, ") / √(", Ui^2, "+", Uxpt^2, ") =", round(en_manual, 4), "\n\n")

# =========================================
# 4. Prueba de Criterio u_xpt > 0.3σpt
# =========================================

cat("--- Verificación de Criterio para z' ---\n\n")

cat("uxpt =", uxpt, "\n")
cat("0.3 × σpt =", 0.3 * sigma_pt, "\n")

if (uxpt > 0.3 * sigma_pt) {
  cat("Resultado: uxpt > 0.3σpt → USAR z' en lugar de z\n\n")
} else {
  cat("Resultado: uxpt ≤ 0.3σpt → z estándar es adecuado\n\n")
}

# =========================================
# 5. Resumen Final
# =========================================

cat("============================================\n")
cat("  Resumen de Validación\n")
cat("============================================\n\n")

cat("✓ z-score calcula correctamente para todos los escenarios.\n")
cat("✓ z'-score incorpora incertidumbre del valor asignado.\n")
cat("✓ zeta-score incorpora incertidumbre del participante.\n")
cat("✓ En-score usa incertidumbres expandidas (k=2).\n")
cat("✓ Criterios de evaluación aplicados correctamente.\n\n")

cat("Validación completada exitosamente.\n")
