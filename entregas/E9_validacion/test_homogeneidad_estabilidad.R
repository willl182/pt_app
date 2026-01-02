# Prueba de Validación: Homogeneidad y Estabilidad
# Laboratorio CALAIRE

# 1. Funciones Core
compute_hom_ss <- function(data_wide) {
  g <- nrow(data_wide)
  m <- ncol(data_wide)
  item_means <- rowMeans(data_wide)
  item_ranges <- apply(data_wide, 1, function(x) max(x) - min(x))
  
  sx <- sd(item_means)
  sw <- sqrt(sum(item_ranges^2) / (2 * g))
  ss <- sqrt(max(0, sx^2 - (sw^2 / m)))
  
  return(list(ss = ss, sw = sw))
}

# 2. Carga/Simulación de Datos
# 10 ítems, 2 réplicas cada uno
set.seed(123)
hom_data <- matrix(rnorm(20, mean=10, sd=0.05), ncol=2) 

# 3. Validación
cat("--- VALIDACIÓN: HOMOGENEIDAD ---\n\n")
res <- compute_hom_ss(as.data.frame(hom_data))

cat("Resultados Calculados:\n")
cat("  - Desviación entre muestras (ss):", round(res$ss, 5), "\n")
cat("  - Desviación analítica (sw):", round(res$sw, 5), "\n")

sigma_pt <- 0.2
c_crit <- 0.3 * sigma_pt

cat("Criterio c (0.3*sigma_pt):", c_crit, "\n")
cat("Resultado:", if(res$ss <= c_crit) "CUMPLE" else "NO CUMPLE", "\n\n")

cat("--- VALIDACIÓN: ESTABILIDAD ---\n\n")
mean_hom <- 10.02
mean_stab <- 10.05
diff <- abs(mean_hom - mean_stab)

cat("Media Homogeneidad:", mean_hom, "\n")
cat("Media Estabilidad:", mean_stab, "\n")
cat("Diferencia:", diff, "\n")
cat("Criterio Estabilidad (0.3*sigma_pt):", c_crit, "\n")
cat("Resultado:", if(diff <= c_crit) "ESTABLE" else "INESTABLE", "\n")

cat("\n--- Fin de Prueba ---\n")
