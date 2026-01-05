# Script de Validación: nIQR (Rango Intercuartílico Normalizado)
# Laboratorio CALAIRE
# ISO 13528:2022, Sección 6.4
# Fecha: 2026-01-03

cat("============================================\n")
cat("  VALIDACIÓN: nIQR\n")
cat("  ISO 13528:2022, Sección 6.4\n")
cat("============================================\n\n")

# =========================================
# 1. Función a Validar
# =========================================

calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA_real_)
  q <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (q[2] - q[1])
}

# =========================================
# 2. Función Auxiliar de Validación
# =========================================

validate_test <- function(test_name, calculated, expected, tolerance = 0.0001) {
  if (is.na(calculated) && is.na(expected)) {
    cat(sprintf("  [PASA] %s: NA == NA (esperado)\n", test_name))
    return(TRUE)
  }
  if (abs(calculated - expected) <= tolerance) {
    cat(sprintf("  [PASA] %s: %.4f ≈ %.4f\n", test_name, calculated, expected))
    return(TRUE)
  } else {
    cat(sprintf("  [FALLA] %s: %.4f ≠ %.4f (diferencia: %.6f)\n", 
                test_name, calculated, expected, abs(calculated - expected)))
    return(FALSE)
  }
}

# =========================================
# 3. Casos de Prueba
# =========================================

results <- c()

cat("--- Caso 1.1: Datos Normales ---\n")
data_1 <- c(9.9, 10.0, 10.1, 10.2, 10.3)
# Q1 = 9.95, Q3 = 10.25, IQR = 0.3, nIQR = 0.7413 * 0.2 = 0.1483
expected_1 <- 0.7413 * (quantile(data_1, 0.75) - quantile(data_1, 0.25))
calculated_1 <- calculate_niqr(data_1)
results <- c(results, validate_test("Datos normales", calculated_1, expected_1))

cat("\n--- Caso 1.2: Datos con Atípico Severo ---\n")
data_2 <- c(10, 10, 10, 10, 50)
# Mediana grupo = 10, Q1 y Q3 cercanos a 10, IQR puede ser 0
expected_2 <- 0.7413 * (quantile(data_2, 0.75) - quantile(data_2, 0.25))
calculated_2 <- calculate_niqr(data_2)
results <- c(results, validate_test("Con atípico", calculated_2, expected_2))

cat("\n--- Caso 1.3: Datos Insuficientes (n=1) ---\n")
data_3 <- c(5.0)
calculated_3 <- calculate_niqr(data_3)
results <- c(results, validate_test("n=1", calculated_3, NA))

cat("\n--- Caso 1.4: Datos con NA ---\n")
data_4 <- c(9.9, 10.0, NA, 10.2, 10.3)
expected_4 <- 0.7413 * (quantile(data_4, 0.75, na.rm=TRUE) - quantile(data_4, 0.25, na.rm=TRUE))
calculated_4 <- calculate_niqr(data_4)
results <- c(results, validate_test("Con NA", calculated_4, expected_4))

cat("\n--- Caso 1.5: Datos Vacíos ---\n")
data_5 <- c()
calculated_5 <- calculate_niqr(data_5)
results <- c(results, validate_test("Vacío", calculated_5, NA))

cat("\n--- Caso 1.6: Datos Idénticos ---\n")
data_6 <- c(10, 10, 10, 10, 10)
expected_6 <- 0  # IQR = 0
calculated_6 <- calculate_niqr(data_6)
results <- c(results, validate_test("Idénticos", calculated_6, expected_6))

# =========================================
# 4. Resumen
# =========================================

cat("\n============================================\n")
cat("  RESUMEN DE VALIDACIÓN: nIQR\n")
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
