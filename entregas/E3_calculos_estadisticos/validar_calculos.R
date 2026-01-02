# Script de Validación de Cálculos Estadísticos ISO 13528
# Laboratorio CALAIRE

# 1. Funciones de Cálculo
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA)
  q <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (q[2] - q[1])
}

calculate_made <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 1) return(NA)
  med <- median(x_clean)
  1.4826 * median(abs(x_clean - med))
}

run_algorithm_a <- function(x, max_iter = 50) {
  x <- x[is.finite(x)]
  n <- length(x)
  x_star <- median(x)
  s_star <- 1.4826 * median(abs(x - x_star))
  
  for (i in 1:max_iter) {
    delta <- 1.5 * s_star
    x_phi <- pmin(pmax(x, x_star - delta), x_star + delta)
    x_new <- mean(x_phi)
    s_new <- 1.134 * sd(x_phi)
    
    if (abs(x_new - x_star) < 1e-4 && abs(s_new - s_star) < 1e-4) break
    x_star <- x_new
    s_star <- s_new
  }
  list(mean = x_star, sd = s_star)
}

# 2. Datos de Prueba
test_data <- c(10.2, 10.5, 9.8, 11.0, 10.1, 10.3, 15.0) # 15.0 es un atípico

# 3. Ejecución y Validación
cat("--- Validación de Cálculos Estadísticos ---\n\n")
cat("Datos de prueba:", paste(test_data, collapse = ", "), "\n")

res_niqr <- calculate_niqr(test_data)
res_made <- calculate_made(test_data)
res_algo <- run_algorithm_a(test_data)

cat("1. nIQR:", round(res_niqr, 4), "\n")
cat("2. MADe:", round(res_made, 4), "\n")
cat("3. Algoritmo A:\n")
cat("   - Media Robusta (x*):", round(res_algo$mean, 4), "\n")
cat("   - Desviación Robusta (s*):", round(res_algo$sd, 4), "\n\n")

# Verificación de lógica robusta
cat("Conclusión: ")
if (res_algo$mean < mean(test_data)) {
  cat("El Algoritmo A minimizó correctamente el efecto del atípico (15.0).\n")
} else {
  cat("Verificar implementación del algoritmo.\n")
}

cat("\n--- Validación finalizada ---\n")
