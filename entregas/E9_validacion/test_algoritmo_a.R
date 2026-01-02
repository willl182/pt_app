# Prueba de Validación: Algoritmo A (ISO 13528:2022)
# Laboratorio CALAIRE

# 1. Función de Prueba
run_algorithm_a <- function(x, max_iter = 50) {
  x <- x[is.finite(x)]
  n <- length(x)
  x_star <- median(x)
  s_star <- 1.4826 * median(abs(x - x_star))
  
  status <- "No Convergió"
  for (i in 1:max_iter) {
    delta <- 1.5 * s_star
    x_phi <- pmin(pmax(x, x_star - delta), x_star + delta)
    x_new <- mean(x_phi)
    s_new <- 1.134 * sd(x_phi)
    
    if (abs(x_new - x_star) < 1e-4 && abs(s_new - s_star) < 1e-4) {
      status <- paste("Convergió en iteración", i)
      break
    }
    x_star <- x_new
    s_star <- s_new
  }
  list(mean = x_star, sd = s_star, status = status)
}

# 2. Escenarios de Prueba
cat("--- VALIDACIÓN: ALGORITMO A ---\n\n")

# Escenario A: Datos simétricos sin atípicos
data_a <- c(9.9, 10.1, 10.0, 10.2, 9.8)
res_a <- run_algorithm_a(data_a)
cat("Escenario A (Sin atípicos):\n")
cat("  - Media Robusta:", round(res_a$mean, 4), "\n")
cat("  - Desviación Robusta:", round(res_a$sd, 4), "\n")
cat("  - Estado:", res_a$status, "\n\n")

# Escenario B: Datos con atípico severo
data_b <- c(10.0, 10.1, 9.9, 10.0, 50.0) # 50.0 es un outlier
res_b <- run_algorithm_a(data_b)
cat("Escenario B (Con atípico: 50.0):\n")
cat("  - Media Robusta:", round(res_b$mean, 4), "(Esperado cerca de 10.0)\n")
cat("  - Desviación Robusta:", round(res_b$sd, 4), "\n")
cat("  - Estado:", res_b$status, "\n\n")

cat("--- Fin de Prueba ---\n")
