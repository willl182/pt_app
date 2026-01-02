# Script de Validación de Puntajes PT (ISO 13528 / ISO 17043)
# Laboratorio CALAIRE

# 1. Funciones de Cálculo
calculate_scores <- function(xi, xpt, sigma_pt, ui=NULL, uxpt=0, k=2) {
  # Incertidumbres expandidas
  Ui <- if(!is.null(ui)) k * ui else 0
  Uxpt <- k * uxpt
  
  # Cálculos
  z <- (xi - xpt) / sigma_pt
  z_prime <- (xi - xpt) / sqrt(sigma_pt^2 + uxpt^2)
  zeta <- if(!is.null(ui)) (xi - xpt) / sqrt(ui^2 + uxpt^2) else NA
  En <- if(!is.null(ui)) (xi - xpt) / sqrt(Ui^2 + Uxpt^2) else NA
  
  list(z = z, z_prime = z_prime, zeta = zeta, En = En)
}

evaluate_z <- function(val) {
  case_when(
    abs(val) <= 2 ~ "Satisfactorio",
    abs(val) < 3 ~ "Cuestionable",
    abs(val) >= 3 ~ "Insatisfactorio",
    TRUE ~ "N/A"
  )
}

# 2. Datos de Prueba (Escenario: Participante con desvío)
library(dplyr)
xi <- 10.5      # Resultado del participante
xpt <- 10.0     # Valor asignado
sigma_pt <- 0.2 # Desviación para aptitud
ui <- 0.1       # Incertidumbre estándar del participante
uxpt <- 0.05    # Incertidumbre estándar del valor asignado
k <- 2

# 3. Ejecución y Validación
cat("--- Validación de Puntajes de Desempeño ---\n\n")
cat("Entradas:\n")
cat("  xi =", xi, "| xpt =", xpt, "| sigma_pt =", sigma_pt, "\n")
cat("  ui =", ui, "| uxpt =", uxpt, "| k =", k, "\n\n")

scores <- calculate_scores(xi, xpt, sigma_pt, ui, uxpt, k)

cat("Resultados Calculados:\n")
cat("1. z-score:", round(scores$z, 4), "-", evaluate_z(scores$z), "\n")
cat("2. z'-score:", round(scores$z_prime, 4), "-", evaluate_z(scores$z_prime), "\n")
cat("3. zeta-score:", round(scores$zeta, 4), "-", evaluate_z(scores$zeta), "\n")
cat("4. En-score:", round(scores$En, 4), "-", ifelse(abs(scores$En) <= 1, "Satisfactorio", "Insatisfactorio"), "\n")

cat("\n--- Validación finalizada ---\n")
