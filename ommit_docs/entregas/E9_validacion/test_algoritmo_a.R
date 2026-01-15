# Script de Validación: Algoritmo A (Valor Asignado Robusto)
# Laboratorio CALAIRE
# ISO 13528:2022, Anexo C
# Fecha: 2026-01-03

cat("============================================\n")
cat("  VALIDACIÓN: Algoritmo A\n")
cat("  ISO 13528:2022, Anexo C\n")
cat("============================================\n\n")

# =========================================
# 1. Función a Validar
# =========================================

run_algorithm_a <- function(x, max_iter = 50) {
  x <- x[is.finite(x)]
  n <- length(x)
  
  if (n < 3) {
    return(list(mean = NA, sd = NA, converged = FALSE, iterations = 0, error = "n < 3"))
  }
  
  # Inicialización
  x_star <- median(x)
  s_star <- 1.4826 * median(abs(x - x_star))
  
  if (s_star < 1e-9) {
    s_star <- sd(x)
    if (s_star < 1e-9) {
      return(list(mean = x_star, sd = 0, converged = TRUE, iterations = 0, error = NULL))
    }
  }
  
  # Iteraciones
  for (i in 1:max_iter) {
    delta <- 1.5 * s_star
    x_truncated <- pmin(pmax(x, x_star - delta), x_star + delta)
    
    x_new <- mean(x_truncated)
    s_new <- 1.134 * sd(x_truncated)
    
    if (abs(x_new - x_star) < 1e-4 && abs(s_new - s_star) < 1e-4) {
      return(list(mean = x_new, sd = s_new, converged = TRUE, iterations = i, error = NULL))
    }
    
    x_star <- x_new
    s_star <- s_new
  }
  
  list(mean = x_star, sd = s_star, converged = FALSE, iterations = max_iter, error = "No convergió")
}

# =========================================
# 2. Función Auxiliar de Validación
# =========================================

validate_test <- function(test_name, calculated, expected, tolerance = 0.01) {
  if (is.na(calculated) && is.na(expected)) {
    cat(sprintf("  [PASA] %s: NA == NA (esperado)\n", test_name))
    return(TRUE)
  }
  if (is.na(calculated) || is.na(expected)) {
    cat(sprintf("  [FALLA] %s: uno es NA\n", test_name))
    return(FALSE)
  }
  if (abs(calculated - expected) <= tolerance) {
    cat(sprintf("  [PASA] %s: %.4f ≈ %.4f (tol=%.2f)\n", test_name, calculated, expected, tolerance))
    return(TRUE)
  } else {
    cat(sprintf("  [FALLA] %s: %.4f ≠ %.4f (diferencia: %.4f)\n", 
                test_name, calculated, expected, abs(calculated - expected)))
    return(FALSE)
  }
}

# =========================================
# 3. Casos de Prueba
# =========================================

results <- c()

cat("--- Caso 3.1: Datos Sin Atípicos ---\n")
data_1 <- c(10.0, 10.1, 9.9, 10.2, 10.0, 9.8, 10.1)
result_1 <- run_algorithm_a(data_1)
expected_mean_1 <- mean(data_1)  # Sin atípicos, debe ser cercano a la media
cat(sprintf("  Datos: %s\n", paste(data_1, collapse = ", ")))
cat(sprintf("  x* = %.4f, s* = %.4f, iteraciones = %d\n", 
            result_1$mean, result_1$sd, result_1$iterations))
results <- c(results, validate_test("x* cercano a media", result_1$mean, expected_mean_1, 0.1))
results <- c(results, result_1$converged)
cat(sprintf("  [%s] Convergencia\n", if(result_1$converged) "PASA" else "FALLA"))

cat("\n--- Caso 3.2: Datos con Un Atípico ---\n")
data_2 <- c(10.0, 10.1, 9.9, 10.2, 10.0, 9.8, 50.0)
result_2 <- run_algorithm_a(data_2)
media_sin_outlier <- mean(data_2[data_2 < 20])  # ~10.0
cat(sprintf("  Datos: %s\n", paste(data_2, collapse = ", ")))
cat(sprintf("  Media clásica: %.4f (sesgada por 50)\n", mean(data_2)))
cat(sprintf("  x* = %.4f, s* = %.4f, iteraciones = %d\n", 
            result_2$mean, result_2$sd, result_2$iterations))
results <- c(results, validate_test("x* robusto", result_2$mean, media_sin_outlier, 0.5))

cat("\n--- Caso 3.3: Datos con 30% Atípicos ---\n")
data_3 <- c(10, 10, 10, 10, 50, 60, 70)  # 3 de 7 = 43% atípicos
result_3 <- run_algorithm_a(data_3)
cat(sprintf("  Datos: %s\n", paste(data_3, collapse = ", ")))
cat(sprintf("  Mediana original: %.4f\n", median(data_3)))
cat(sprintf("  x* = %.4f, s* = %.4f, iteraciones = %d\n", 
            result_3$mean, result_3$sd, result_3$iterations))
# x* debe estar más cerca de 10 que de la media (30.0)
results <- c(results, result_3$mean < 25)
cat(sprintf("  [%s] x* < 25 (resistencia a atípicos)\n", if(result_3$mean < 25) "PASA" else "FALLA"))

cat("\n--- Caso 3.4: Datos Insuficientes ---\n")
data_4 <- c(10, 20)
result_4 <- run_algorithm_a(data_4)
cat(sprintf("  Datos: %s\n", paste(data_4, collapse = ", ")))
results <- c(results, is.na(result_4$mean) || !is.null(result_4$error))
cat(sprintf("  [%s] Error manejado correctamente (n<3)\n", 
            if(is.na(result_4$mean) || !is.null(result_4$error)) "PASA" else "FALLA"))

cat("\n--- Caso 3.5: Datos Idénticos ---\n")
data_5 <- c(10, 10, 10, 10, 10)
result_5 <- run_algorithm_a(data_5)
cat(sprintf("  Datos: %s\n", paste(data_5, collapse = ", ")))
cat(sprintf("  x* = %.4f, s* = %.4f\n", result_5$mean, result_5$sd))
results <- c(results, validate_test("x* = valor", result_5$mean, 10, 0.001))
results <- c(results, validate_test("s* = 0", result_5$sd, 0, 0.001))

cat("\n--- Caso 3.6: Verificación de Convergencia ---\n")
data_6 <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 100)
result_6 <- run_algorithm_a(data_6)
cat(sprintf("  Datos: %s\n", paste(data_6, collapse = ", ")))
cat(sprintf("  x* = %.4f, s* = %.4f, iteraciones = %d\n", 
            result_6$mean, result_6$sd, result_6$iterations))
results <- c(results, result_6$iterations <= 20)
cat(sprintf("  [%s] Convergencia en ≤20 iteraciones\n", 
            if(result_6$iterations <= 20) "PASA" else "FALLA"))

# =========================================
# 4. Resumen
# =========================================

cat("\n============================================\n")
cat("  RESUMEN DE VALIDACIÓN: Algoritmo A\n")
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
