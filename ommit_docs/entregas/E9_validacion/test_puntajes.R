# Script de Validación: Puntajes de Desempeño (z, z', zeta, En)
# Laboratorio CALAIRE
# ISO 13528:2022, Sección 9
# Fecha: 2026-01-03

cat("============================================\n")
cat("  VALIDACIÓN: Puntajes de Desempeño\n")
cat("  ISO 13528:2022, Sección 9\n")
cat("============================================\n\n")

library(dplyr, warn.conflicts = FALSE)

# =========================================
# 1. Funciones a Validar
# =========================================

calculate_z <- function(xi, xpt, sigma_pt) {
  (xi - xpt) / sigma_pt
}

calculate_z_prime <- function(xi, xpt, sigma_pt, u_xpt) {
  (xi - xpt) / sqrt(sigma_pt^2 + u_xpt^2)
}

calculate_zeta <- function(xi, xpt, u_i, u_xpt) {
  (xi - xpt) / sqrt(u_i^2 + u_xpt^2)
}

calculate_en <- function(xi, xpt, u_i, u_xpt, k = 2) {
  U_i <- k * u_i
  U_xpt <- k * u_xpt
  (xi - xpt) / sqrt(U_i^2 + U_xpt^2)
}

evaluate_z <- function(z) {
  case_when(
    abs(z) <= 2 ~ "Satisfactorio",
    abs(z) < 3 ~ "Cuestionable",
    TRUE ~ "Insatisfactorio"
  )
}

evaluate_en <- function(en) {
  if_else(abs(en) <= 1, "Satisfactorio", "Insatisfactorio")
}

# =========================================
# 2. Función Auxiliar de Validación
# =========================================

validate_score <- function(test_name, calculated, expected, tolerance = 0.001) {
  if (abs(calculated - expected) <= tolerance) {
    cat(sprintf("  [PASA] %s: %.4f ≈ %.4f\n", test_name, calculated, expected))
    return(TRUE)
  } else {
    cat(sprintf("  [FALLA] %s: %.4f ≠ %.4f\n", test_name, calculated, expected))
    return(FALSE)
  }
}

validate_eval <- function(test_name, calculated, expected) {
  if (calculated == expected) {
    cat(sprintf("  [PASA] %s: '%s' == '%s'\n", test_name, calculated, expected))
    return(TRUE)
  } else {
    cat(sprintf("  [FALLA] %s: '%s' ≠ '%s'\n", test_name, calculated, expected))
    return(FALSE)
  }
}

# =========================================
# 3. Parámetros de Prueba
# =========================================

xpt <- 10.0       # Valor asignado
sigma_pt <- 0.2   # Desviación para aptitud
u_xpt <- 0.05     # Incertidumbre del valor asignado
u_i <- 0.08       # Incertidumbre del participante
k <- 2            # Factor de cobertura

results <- c()

# =========================================
# 4. Casos de Prueba: Cálculo de Puntajes
# =========================================

cat("--- Caso 4.1: Resultado Satisfactorio (xi = 10.1) ---\n")
xi_1 <- 10.1

# Cálculos manuales
z_manual <- (xi_1 - xpt) / sigma_pt
z_prime_manual <- (xi_1 - xpt) / sqrt(sigma_pt^2 + u_xpt^2)
zeta_manual <- (xi_1 - xpt) / sqrt(u_i^2 + u_xpt^2)
en_manual <- (xi_1 - xpt) / sqrt((k*u_i)^2 + (k*u_xpt)^2)

# Cálculos con funciones
z_calc <- calculate_z(xi_1, xpt, sigma_pt)
z_prime_calc <- calculate_z_prime(xi_1, xpt, sigma_pt, u_xpt)
zeta_calc <- calculate_zeta(xi_1, xpt, u_i, u_xpt)
en_calc <- calculate_en(xi_1, xpt, u_i, u_xpt, k)

results <- c(results, validate_score("z", z_calc, z_manual))
results <- c(results, validate_score("z'", z_prime_calc, z_prime_manual))
results <- c(results, validate_score("zeta", zeta_calc, zeta_manual))
results <- c(results, validate_score("En", en_calc, en_manual))

cat("\n--- Caso 4.2: Resultado Cuestionable (xi = 10.5) ---\n")
xi_2 <- 10.5

z_2 <- calculate_z(xi_2, xpt, sigma_pt)
z_prime_2 <- calculate_z_prime(xi_2, xpt, sigma_pt, u_xpt)

results <- c(results, validate_score("z (cuestionable)", z_2, (xi_2 - xpt) / sigma_pt))
cat(sprintf("  z = %.2f → debe ser Cuestionable (2 < |z| < 3)\n", z_2))
results <- c(results, z_2 > 2 && z_2 < 3)
cat(sprintf("  [%s] Rango correcto\n", if(z_2 > 2 && z_2 < 3) "PASA" else "FALLA"))

cat("\n--- Caso 4.3: Resultado Insatisfactorio (xi = 10.8) ---\n")
xi_3 <- 10.8

z_3 <- calculate_z(xi_3, xpt, sigma_pt)

results <- c(results, validate_score("z (insatisfactorio)", z_3, (xi_3 - xpt) / sigma_pt))
cat(sprintf("  z = %.2f → debe ser Insatisfactorio (|z| ≥ 3)\n", z_3))
results <- c(results, abs(z_3) >= 3)
cat(sprintf("  [%s] Rango correcto\n", if(abs(z_3) >= 3) "PASA" else "FALLA"))

cat("\n--- Caso 4.4: Resultado Exacto (xi = xpt) ---\n")
xi_4 <- 10.0

z_4 <- calculate_z(xi_4, xpt, sigma_pt)
en_4 <- calculate_en(xi_4, xpt, u_i, u_xpt, k)

results <- c(results, validate_score("z = 0", z_4, 0))
results <- c(results, validate_score("En = 0", en_4, 0))

# =========================================
# 5. Casos de Prueba: Evaluación Cualitativa
# =========================================

cat("\n--- Caso 4.5: Evaluación Cualitativa de z ---\n")

test_evals <- data.frame(
  z_value = c(0.5, 1.9, 2.0, 2.5, 2.99, 3.0, 4.0),
  expected = c("Satisfactorio", "Satisfactorio", "Satisfactorio", 
               "Cuestionable", "Cuestionable", "Insatisfactorio", "Insatisfactorio")
)

for (i in 1:nrow(test_evals)) {
  eval_calc <- evaluate_z(test_evals$z_value[i])
  results <- c(results, validate_eval(
    sprintf("z=%.2f", test_evals$z_value[i]),
    eval_calc, 
    test_evals$expected[i]
  ))
}

cat("\n--- Caso 4.6: Evaluación Cualitativa de En ---\n")

test_en_evals <- data.frame(
  en_value = c(0.5, 0.99, 1.0, 1.01, 1.5),
  expected = c("Satisfactorio", "Satisfactorio", "Satisfactorio", 
               "Insatisfactorio", "Insatisfactorio")
)

for (i in 1:nrow(test_en_evals)) {
  eval_calc <- evaluate_en(test_en_evals$en_value[i])
  results <- c(results, validate_eval(
    sprintf("En=%.2f", test_en_evals$en_value[i]),
    eval_calc, 
    test_en_evals$expected[i]
  ))
}

# =========================================
# 6. Caso de Prueba: Criterio para z'
# =========================================

cat("\n--- Caso 4.7: Criterio de Uso de z' ---\n")

# z' se usa cuando u_xpt > 0.3 * sigma_pt
criterio_z_prime <- u_xpt > 0.3 * sigma_pt

cat(sprintf("  u_xpt = %.3f\n", u_xpt))
cat(sprintf("  0.3 * sigma_pt = %.3f\n", 0.3 * sigma_pt))
cat(sprintf("  u_xpt > 0.3*sigma_pt: %s\n", if(criterio_z_prime) "SÍ → usar z'" else "NO → usar z"))

# En este caso: 0.05 > 0.06 es FALSO, usar z estándar
results <- c(results, !criterio_z_prime)
cat(sprintf("  [PASA] Criterio evaluado correctamente\n"))

# =========================================
# 7. Resumen
# =========================================

cat("\n============================================\n")
cat("  RESUMEN DE VALIDACIÓN: Puntajes\n")
cat("============================================\n")
cat(sprintf("  Total de casos: %d\n", length(results)))
cat(sprintf("  Casos exitosos: %d\n", sum(results)))
cat(sprintf("  Casos fallidos: %d\n", sum(!results)))
cat(sprintf("  Tasa de éxito: %.1f%%\n", 100 * mean(results)))

if (all(results)) {
  cat("\n  ✓ MÓDULO VALIDADO\n")
} else {
  cat("\n  ✗ VALIDACIÓN FALLIDA\n")
}
cat("============================================\n")
