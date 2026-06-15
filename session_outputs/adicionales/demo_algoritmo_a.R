# ============================================================================
# Demostración paso a paso del Algoritmo A (ISO 13528)
# ============================================================================
# Este script muestra cómo el algoritmo itera para calcular el valor asignado
# y la desviación estándar robusta de forma didáctica.
# ============================================================================

library(tidyverse)

# --- 1. DATOS DE ENTRADA ---
# Usando datos de CO a nivel 2-μmol/mol del archivo summary_n4.csv
# (Excluyendo el participante "ref" para simular cálculo de consenso)

data <- read_csv("data/summary_n4.csv") %>%
  filter(pollutant == "co", level == "2-μmol/mol", participant_id != "ref") %>%
  group_by(participant_id) %>%
  summarise(Resultado = mean(mean_value, na.rm = TRUE), .groups = "drop")

cat("=" |> rep(60) |> paste(collapse = ""), "\n")
cat("ALGORITMO A - DEMOSTRACIÓN PASO A PASO\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n\n")

cat("PASO 1: DATOS DE ENTRADA\n")
cat("-" |> rep(40) |> paste(collapse = ""), "\n")
print(data)
cat("\nTotal de participantes: ", nrow(data), "\n\n")

# --- 2. ESTIMADORES INICIALES ---
values <- data$Resultado
ids <- data$participant_id
n <- length(values)

x_star <- median(values, na.rm = TRUE)
mad_raw <- median(abs(values - x_star), na.rm = TRUE)
s_star <- 1.483 * mad_raw

cat("PASO 2: ESTIMADORES INICIALES (Robustos)\n")
cat("-" |> rep(40) |> paste(collapse = ""), "\n")
cat(sprintf("  Mediana (x*₀):                    %.9f\n", x_star))
cat(sprintf("  MAD (sin escalar):                %.9f\n", mad_raw))
cat(sprintf("  Desviación robusta (s*₀ = 1.483×MAD): %.9f\n\n", s_star))

# --- 3. ITERACIONES ---
max_iter <- 50
convergence_threshold <- 1e-03

# Almacenar historial
iteration_history <- tibble(
  Iteracion = integer(),
  x_star = double(),
  s_star = double(),
  delta_x = double(),
  delta_s = double(),
  convergido = logical()
)

# Almacenar detalles por participante en cada iteración
participant_details_list <- list()

cat("PASO 3: ITERACIONES\n")
cat("-" |> rep(40) |> paste(collapse = ""), "\n\n")

converged <- FALSE

for (iter in seq_len(max_iter)) {
  cat(sprintf("--- Iteración %d ---\n", iter))
  
  # 3.1 Calcular residuos estandarizados (u)
  u_values <- (values - x_star) / (1.5 * s_star)
  
  # 3.2 Calcular pesos (internamente, no se muestran al usuario final)
  # wi = 1 si |ui| <= 1, wi = 1/ui² si |ui| > 1
  weights <- ifelse(abs(u_values) <= 1, 1, 1 / (u_values^2))
  
  # Guardar detalles por participante
  participant_details <- tibble(
    Iteracion = iter,
    Participante = ids,
    Resultado = values,
    u = u_values,
    x_star_actual = x_star,
    s_star_actual = s_star
  )
  participant_details_list[[iter]] <- participant_details
  
  # 3.3 Calcular nuevas estimaciones
  weight_sum <- sum(weights)
  x_new <- sum(weights * values) / weight_sum
  s_new <- sqrt(sum(weights * (values - x_new)^2) / weight_sum)
  
  # Calcular cambios
  delta_x <- abs(x_new - x_star)
  delta_s <- abs(s_new - s_star)
  
  cat(sprintf("  x* anterior:  %.9f\n", x_star))
  cat(sprintf("  x* nuevo:     %.9f  (Δx = %.9f)\n", x_new, delta_x))
  cat(sprintf("  s* anterior:  %.9f\n", s_star))
  cat(sprintf("  s* nuevo:     %.9f  (Δs = %.9f)\n", s_new, delta_s))
  
  # Verificar convergencia
  if (delta_x < convergence_threshold && delta_s < convergence_threshold) {
    converged <- TRUE
    cat(sprintf("  ✓ CONVERGIÓ (Δx < %.3f y Δs < %.3f)\n\n", 
                convergence_threshold, convergence_threshold))
    
    # Guardar última iteración
    iteration_history <- iteration_history %>%
      add_row(
        Iteracion = iter,
        x_star = x_new,
        s_star = s_new,
        delta_x = delta_x,
        delta_s = delta_s,
        convergido = TRUE
      )
    
    x_star <- x_new
    s_star <- s_new
    break
  } else {
    cat(sprintf("  → Continuar iterando...\n\n"))
  }
  
  # Guardar historial
  iteration_history <- iteration_history %>%
    add_row(
      Iteracion = iter,
      x_star = x_new,
      s_star = s_new,
      delta_x = delta_x,
      delta_s = delta_s,
      convergido = FALSE
    )
  
  # Actualizar para siguiente iteración
  x_star <- x_new
  s_star <- s_new
}

# --- 4. RESULTADOS FINALES ---
cat("=" |> rep(60) |> paste(collapse = ""), "\n")
cat("PASO 4: RESULTADOS FINALES\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n\n")

cat(sprintf("  Valor asignado (x*):           %.9f\n", x_star))
cat(sprintf("  Desviación robusta (s*):       %.9f\n", s_star))
cat(sprintf("  Convergió:                     %s\n", ifelse(converged, "Sí", "No")))
cat(sprintf("  Iteraciones requeridas:        %d\n\n", nrow(iteration_history)))

# --- 5. DATAFRAMES GENERADOS ---
cat("=" |> rep(60) |> paste(collapse = ""), "\n")
cat("DATAFRAMES GENERADOS\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n\n")

cat("5.1 Historial de Iteraciones:\n")
print(iteration_history)

cat("\n5.2 Detalles por Participante (todas las iteraciones):\n")
all_participant_details <- bind_rows(participant_details_list)
print(all_participant_details)

# --- 6. RESUMEN VISUAL ---
cat("\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n")
cat("EVOLUCIÓN DE x* y s* POR ITERACIÓN\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n\n")

iteration_history %>%
  mutate(
    `x* (formateado)` = sprintf("%.9f", x_star),
    `s* (formateado)` = sprintf("%.9f", s_star),
    `Δx` = sprintf("%.2e", delta_x),
    `Δs` = sprintf("%.2e", delta_s)
  ) %>%
  select(Iteracion, `x* (formateado)`, `s* (formateado)`, `Δx`, `Δs`, convergido) %>%
  print()

cat("\n--- FIN DE LA DEMOSTRACIÓN ---\n")
