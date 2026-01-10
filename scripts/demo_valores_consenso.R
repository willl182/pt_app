# ============================================================================
# Script de Demostración: Cálculo de Valores por Consenso (MADe y nIQR)
# ============================================================================
# Este script demuestra paso a paso cómo se calculan los valores por consenso
# tal como se implementan en app.R, usando los datos de summary_n4.csv
# ============================================================================

# --- 1. Configuración Inicial ---

library(tidyverse)

# Definir directorio de trabajo
# Si se ejecuta desde línea de comandos, usar el directorio actual
# Si se ejecuta desde RStudio, usar el directorio del script
if (interactive() && requireNamespace("rstudioapi", quietly = TRUE)) {
  if (rstudioapi::isAvailable()) {
    script_dir <- dirname(rstudioapi::getActiveDocumentContext()$path)
    if (script_dir != "") {
      setwd(script_dir)
      setwd("..")  # Ir al directorio raíz del proyecto
    }
  }
}
# Si se ejecuta con Rscript, asumir que ya estamos en el directorio correcto

# --- 2. Función calculate_niqr (igual que en app.R) ---

calculate_niqr <- function(x) {
  # Limpiar valores no finitos (NA, Inf, -Inf)
  x_clean <- x[is.finite(x)]
  
  # Se requieren al menos 2 valores para calcular cuartiles
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  
  # Calcular cuartiles Q1 (25%) y Q3 (75%) usando tipo 7 (método por defecto en R)
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  
  # nIQR = 0.7413 × (Q3 - Q1)
  0.7413 * (quartiles[2] - quartiles[1])
}

# --- 3. Cargar Datos ---

cat("=== CÁLCULO DE VALORES POR CONSENSO ===\n\n")

# Cargar el archivo summary_n4.csv
data_file <- "data/summary_n4.csv"
cat(sprintf("Cargando datos desde: %s\n\n", data_file))

raw_data <- read.csv(data_file, stringsAsFactors = FALSE)

# Mostrar estructura de los datos
cat("Estructura de los datos cargados:\n")
cat(sprintf("  - Filas: %d\n", nrow(raw_data)))
cat(sprintf("  - Columnas: %s\n", paste(names(raw_data), collapse = ", ")))
cat(sprintf("  - Contaminantes: %s\n", paste(unique(raw_data$pollutant), collapse = ", ")))
cat("\n")

# --- 4. Seleccionar un Caso de Ejemplo ---

target_pollutant <- "co"
target_level <- "2-μmol/mol"

cat(sprintf("=== EJEMPLO: %s, nivel %s ===\n\n", target_pollutant, target_level))

# Filtrar datos para el contaminante y nivel seleccionados
example_data <- raw_data %>%
  filter(pollutant == target_pollutant, level == target_level)

cat("Datos originales:\n")
print(example_data %>% select(participant_id, sample_group, mean_value))
cat("\n")

# --- 5. Agregar Datos por Participante ---

# En app.R, los datos se agregan promediando todos los sample_group por participante
aggregated_data <- example_data %>%
  filter(participant_id != "ref") %>%  # Excluir referencia para valores por consenso
  group_by(participant_id) %>%
  summarise(
    Resultado = mean(mean_value, na.rm = TRUE),
    .groups = "drop"
  )

cat("Datos agregados por participante (excluyendo 'ref'):\n")
print(aggregated_data)
cat("\n")

# Vector de valores para cálculos
values <- aggregated_data$Resultado

cat(sprintf("Vector de valores: c(%s)\n", paste(sprintf("%.8f", values), collapse = ", ")))
cat(sprintf("Número de participantes (n): %d\n\n", length(values)))

# --- 6. PASO A PASO: Cálculo de la Mediana (x_pt) ---

cat("=== PASO 1: CÁLCULO DE LA MEDIANA (x_pt) ===\n\n")

# Paso 1.1: Ordenar valores
values_sorted <- sort(values)
cat("Valores ordenados:\n")
for (i in seq_along(values_sorted)) {
  cat(sprintf("  [%d] %.8f\n", i, values_sorted[i]))
}
cat("\n")

# Paso 1.2: Calcular mediana
x_pt <- median(values, na.rm = TRUE)
cat(sprintf("La mediana (valor central) es:\n"))
cat(sprintf("  x_pt = %.8f\n\n", x_pt))

# --- 7. PASO A PASO: Cálculo de MADe (sigma_pt_2a) ---

cat("=== PASO 2: CÁLCULO DE MADe (sigma_pt_2a) ===\n\n")

# Paso 2.1: Calcular desviaciones absolutas respecto a la mediana
deviations <- abs(values - x_pt)
cat("Desviaciones absolutas |xi - mediana|:\n")
for (i in seq_along(values)) {
  cat(sprintf("  |%.8f - %.8f| = %.8f\n", values[i], x_pt, deviations[i]))
}
cat("\n")

# Paso 2.2: Ordenar desviaciones
deviations_sorted <- sort(deviations)
cat("Desviaciones ordenadas:\n")
for (i in seq_along(deviations_sorted)) {
  cat(sprintf("  [%d] %.8f\n", i, deviations_sorted[i]))
}
cat("\n")

# Paso 2.3: Calcular mediana de desviaciones (MAD)
mad_val <- median(deviations, na.rm = TRUE)
cat(sprintf("MAD = mediana(desviaciones) = %.8f\n\n", mad_val))

# Paso 2.4: Escalar por 1.483 para obtener MADe
sigma_pt_2a <- 1.483 * mad_val
cat("sigma_pt_2a (MADe) = 1.483 × MAD\n")
cat(sprintf("sigma_pt_2a = 1.483 × %.8f = %.8f\n\n", mad_val, sigma_pt_2a))

# --- 8. PASO A PASO: Cálculo de nIQR (sigma_pt_2b) ---

cat("=== PASO 3: CÁLCULO DE nIQR (sigma_pt_2b) ===\n\n")

# Paso 3.1: Calcular cuartiles
quartiles <- quantile(values, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
Q1 <- quartiles[1]
Q3 <- quartiles[2]

cat(sprintf("Cuartiles (usando type = 7):\n"))
cat(sprintf("  Q1 (25%%) = %.8f\n", Q1))
cat(sprintf("  Q3 (75%%) = %.8f\n\n", Q3))

# Paso 3.2: Calcular IQR
IQR_val <- Q3 - Q1
cat(sprintf("IQR = Q3 - Q1 = %.8f - %.8f = %.8f\n\n", Q3, Q1, IQR_val))

# Paso 3.3: Normalizar por 0.7413
sigma_pt_2b <- 0.7413 * IQR_val
cat("sigma_pt_2b (nIQR) = 0.7413 × IQR\n")
cat(sprintf("sigma_pt_2b = 0.7413 × %.8f = %.8f\n\n", IQR_val, sigma_pt_2b))

# Verificar con la función calculate_niqr
sigma_pt_2b_check <- calculate_niqr(values)
cat(sprintf("Verificación con calculate_niqr(): %.8f\n\n", sigma_pt_2b_check))

# --- 9. Cálculo de Incertidumbre u(x_pt) ---

cat("=== PASO 4: CÁLCULO DE INCERTIDUMBRE u(x_pt) ===\n\n")

n_part <- length(values)

# u(x_pt) para MADe
u_xpt_2a <- 1.25 * sigma_pt_2a / sqrt(n_part)
cat("u(x_pt)_2a = 1.25 × sigma_pt_2a / √n\n")
cat(sprintf("u(x_pt)_2a = 1.25 × %.8f / √%d = %.8f\n\n", sigma_pt_2a, n_part, u_xpt_2a))

# u(x_pt) para nIQR
u_xpt_2b <- 1.25 * sigma_pt_2b / sqrt(n_part)
cat("u(x_pt)_2b = 1.25 × sigma_pt_2b / √n\n")
cat(sprintf("u(x_pt)_2b = 1.25 × %.8f / √%d = %.8f\n\n", sigma_pt_2b, n_part, u_xpt_2b))

# --- 10. Resumen de Resultados ---

cat("=== RESUMEN DE RESULTADOS ===\n\n")

summary_table <- data.frame(
  Estadístico = c(
    "x_pt(2) - Mediana",
    "MAD (desviación mediana absoluta)",
    "sigma_pt_2a (MADe)",
    "sigma_pt_2b (nIQR)",
    "u(x_pt)_2a",
    "u(x_pt)_2b",
    "Participantes (n)"
  ),
  Valor = c(
    sprintf("%.8f", x_pt),
    sprintf("%.8f", mad_val),
    sprintf("%.8f", sigma_pt_2a),
    sprintf("%.8f", sigma_pt_2b),
    sprintf("%.8f", u_xpt_2a),
    sprintf("%.8f", u_xpt_2b),
    as.character(n_part)
  )
)

print(summary_table, row.names = FALSE)
cat("\n")

# --- 11. Explicación de las Constantes ---

cat("=== EXPLICACIÓN DE CONSTANTES ===\n\n")

cat("1.483 (para MADe):\n")
cat("   - Es aproximadamente 1/Φ⁻¹(0.75) donde Φ⁻¹ es la función cuantil normal inversa\n")
cat("   - Convierte MAD a escala comparable con desviación estándar bajo distribución normal\n")
cat(sprintf("   - Verificación: 1/qnorm(0.75) = %.4f\n\n", 1/qnorm(0.75)))

cat("0.7413 (para nIQR):\n")
cat("   - Es aproximadamente 1/(2×Φ⁻¹(0.75))\n")
cat("   - Normaliza IQR para ser comparable con desviación estándar\n")
cat(sprintf("   - Verificación: 1/(2×qnorm(0.75)) = %.4f\n\n", 1/(2*qnorm(0.75))))

cat("1.25 (para u(x_pt)):\n")
cat("   - Factor de cobertura para estimar incertidumbre del valor asignado\n")
cat("   - Según ISO 13528, u(x_pt) = 1.25 × s* / √n para estimadores robustos\n\n")

# --- 12. Cálculo para Todos los Niveles de un Contaminante ---

cat("=== CÁLCULO PARA TODOS LOS NIVELES DE '%s' ===\n\n", target_pollutant)

all_results <- raw_data %>%
  filter(pollutant == target_pollutant) %>%
  filter(participant_id != "ref") %>%
  group_by(level, participant_id) %>%
  summarise(Resultado = mean(mean_value, na.rm = TRUE), .groups = "drop") %>%
  group_by(level) %>%
  summarise(
    n = n(),
    x_pt = median(Resultado, na.rm = TRUE),
    MAD = median(abs(Resultado - median(Resultado, na.rm = TRUE)), na.rm = TRUE),
    sigma_pt_2a = 1.483 * MAD,
    sigma_pt_2b = calculate_niqr(Resultado),
    .groups = "drop"
  ) %>%
  mutate(
    u_xpt_2a = 1.25 * sigma_pt_2a / sqrt(n),
    u_xpt_2b = 1.25 * sigma_pt_2b / sqrt(n)
  )

print(all_results)
cat("\n")

cat("=== FIN DEL SCRIPT ===\n")
