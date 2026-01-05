# Script de Validación: Detección de Outliers (Prueba de Grubbs)
# Laboratorio CALAIRE - ISO 13528:2022
# Fecha: 2026-01-03

cat("============================================\n")
cat("  VALIDACIÓN: Detección de Outliers\n")
cat("============================================\n\n")

if (!require("outliers", quietly = TRUE)) {
  install.packages("outliers", quiet = TRUE)
  library(outliers)
}

run_grubbs_test <- function(x, alpha = 0.05) {
  x <- x[is.finite(x)]
  if (length(x) < 3) return(list(outlier = NA, is_outlier = FALSE, error = "n<3"))
  
  test_result <- grubbs.test(x, type = 10)
  outlier_value <- x[which.max(abs(x - mean(x)))]
  
  list(
    outlier = outlier_value,
    statistic = test_result$statistic,
    p_value = test_result$p.value,
    is_outlier = test_result$p.value < alpha
  )
}

results <- c()

cat("--- Caso 5.1: Sin Outliers ---\n")
data_1 <- c(10.0, 10.1, 9.9, 10.2, 10.0)
r1 <- run_grubbs_test(data_1)
cat(sprintf("  p-valor: %.4f, Outlier: %s\n", r1$p_value, r1$is_outlier))
results <- c(results, !r1$is_outlier)

cat("\n--- Caso 5.2: Con Outlier ---\n")
data_2 <- c(10, 10, 10, 10, 50)
r2 <- run_grubbs_test(data_2)
cat(sprintf("  Valor detectado: %.0f, p-valor: %.4f\n", r2$outlier, r2$p_value))
results <- c(results, r2$is_outlier && r2$outlier == 50)

cat("\n--- Caso 5.3: Outlier Negativo ---\n")
data_3 <- c(10, 10, 10, 10, -30)
r3 <- run_grubbs_test(data_3)
cat(sprintf("  Valor detectado: %.0f\n", r3$outlier))
results <- c(results, r3$is_outlier)

cat("\n============================================\n")
cat(sprintf("  Casos: %d | Éxitos: %d | Tasa: %.0f%%\n", 
            length(results), sum(results), 100*mean(results)))
if(all(results)) cat("  ✓ MÓDULO VALIDADO\n")
cat("============================================\n")
