# Script de Validación: MADe (Median Absolute Deviation escalada)
# Laboratorio CALAIRE
# ISO 13528:2022, Sección 6.4
# Fecha: 2026-01-03

cat("============================================\n")
cat("  VALIDACIÓN: MADe\n")
cat("  ISO 13528:2022, Sección 6.4\n")
cat("============================================\n\n")

# =========================================
# 1. Función a Validar
# =========================================

calculate_made <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 1) return(NA_real_)
  med <- median(x_clean)
  1.4826 * median(abs(x_clean - med))
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

cat("--- Caso 2.1: Datos Normales ---\n")
data_1 <- c(9.9, 10.0, 10.1, 10.2, 10.3)
# mediana = 10.1, desvíos = [0.2, 0.1, 0, 0.1, 0.2], mediana(desvíos) = 0.1
expected_1 <- 1.4826 * median(abs(data_1 - median(data_1)))
calculated_1 <- calculate_made(data_1)
results <- c(results, validate_test("Datos normales", calculated_1, expected_1))

cat("\n--- Caso 2.2: Datos con Atípico Severo ---\n")
data_2 <- c(10, 10, 10, 10, 50)
# mediana = 10, desvíos = [0, 0, 0, 0, 40], mediana(desvíos) = 0
expected_2 <- 1.4826 * median(abs(data_2 - median(data_2)))
calculated_2 <- calculate_made(data_2)
results <- c(results, validate_test("Con atípico (robusto)", calculated_2, expected_2))
cat(sprintf("  Nota: MADe = %.4f, resistente al atípico 50\n", calculated_2))

cat("\n--- Caso 2.3: Datos con Múltiples Atípicos ---\n")
data_3 <- c(1, 2, 3, 100, 200)
# mediana = 3, desvíos = [2, 1, 0, 97, 197], mediana(desvíos) = 2
expected_3 <- 1.4826 * median(abs(data_3 - median(data_3)))
calculated_3 <- calculate_made(data_3)
results <- c(results, validate_test("Múltiples atípicos", calculated_3, expected_3))

cat("\n--- Caso 2.4: Datos Vacíos ---\n")
data_4 <- c()
calculated_4 <- calculate_made(data_4)
results <- c(results, validate_test("Vacío", calculated_4, NA))

cat("\n--- Caso 2.5: Datos con NA ---\n")
data_5 <- c(9.9, 10.0, NA, 10.2, 10.3)
data_5_clean <- data_5[!is.na(data_5)]
expected_5 <- 1.4826 * median(abs(data_5_clean - median(data_5_clean)))
calculated_5 <- calculate_made(data_5)
results <- c(results, validate_test("Con NA", calculated_5, expected_5))

cat("\n--- Caso 2.6: Un Solo Valor ---\n")
data_6 <- c(10)
# mediana = 10, desvío = 0
expected_6 <- 0
calculated_6 <- calculate_made(data_6)
results <- c(results, validate_test("n=1", calculated_6, expected_6))

cat("\n--- Caso 2.7: Comparación con SD Clásica ---\n")
data_7 <- c(10.0, 10.1, 9.9, 10.2, 10.0, 9.8, 50.0)
sd_classico <- sd(data_7)
made_value <- calculate_made(data_7)
cat(sprintf("  SD clásica: %.4f (inflada por atípico 50)\n", sd_classico))
cat(sprintf("  MADe:       %.4f (robusto)\n", made_value))
robusto <- made_value < sd_classico
results <- c(results, robusto)
cat(sprintf("  [%s] MADe < SD clásica (robustez)\n", if(robusto) "PASA" else "FALLA"))

# =========================================
# 4. Resumen
# =========================================

cat("\n============================================\n")
cat("  RESUMEN DE VALIDACIÓN: MADe\n")
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
