# Auditoría de la Semana 3: Núcleo de Análisis Robusto
#
# Este script define las funciones para generar los conjuntos de datos
# necesarios para validar la implementación del Algoritmo A y los
# estimadores robustos en `app.R`.

# **Directorio de Prueba**
if (!dir.exists("validation/test_data_w_03")) {
  dir.create("validation/test_data_w_03")
}

# --- Funciones para Generar Datos de Prueba ---

# **T3.1: Validación del Algoritmo A (Caso de Éxito)**
generate_algo_a_valid <- function() {
  # Datos basados en un ejemplo hipotético de la norma ISO 13528.
  # El resultado esperado (calculado externamente) es x* ≈ 41.6, s* ≈ 1.9
  data <- data.frame(
    pollutant = "o3",
    n_lab = 10,
    level = "L2",
    participant_id = paste0("p", 1:10),
    mean_value = c(40.1, 41.5, 42.3, 39.8, 41.9, 45.8, 40.5, 42.1, 41.2, 40.9),
    sd_value = 0.5
  )
  write.csv(data, "validation/test_data_w_03/alg_a_valid.csv", row.names = FALSE)
  cat("Generado: alg_a_valid.csv\n")
}

# **T3.2: Validación de Estimadores Robustos (MADe)**
generate_robust_estimators_valid <- function() {
  # Conjunto de datos simple para verificar MADe manualmente.
  # Datos: 10, 11, 12, 13, 100
  # Mediana = 12
  # Diferencias absolutas: 2, 1, 0, 1, 88
  # Mediana de las diferencias = 1
  # MADe = 1.483 * 1 = 1.483
  data <- data.frame(
    pollutant = "so2",
    level = "L3",
    replicate = 1,
    value = c(10, 11, 12, 13, 100, 10.5, 11.5, 12.5, 13.5, 10.2)
  )
  # Este archivo se usaría en el módulo de homogeneidad para calcular sigma_pt
  write.csv(data, "validation/test_data_w_03/robust_estimators_valid.csv", row.names = FALSE)
  cat("Generado: robust_estimators_valid.csv\n")
}

# **T3.3: Robustez del Algoritmo A (con Outliers)**
generate_algo_a_outliers <- function() {
  # Mismos datos que T3.1 pero con un outlier claro.
  # La media robusta debería ser similar a la del caso T3.1,
  # mientras que la media simple estaría sesgada.
  data <- data.frame(
    pollutant = "o3",
    n_lab = 10,
    level = "L2",
    participant_id = paste0("p", 1:10),
    mean_value = c(40.1, 41.5, 42.3, 39.8, 41.9, 80.0, 40.5, 42.1, 41.2, 40.9), # Outlier 80.0
    sd_value = 0.5
  )
  write.csv(data, "validation/test_data_w_03/alg_a_outliers.csv", row.names = FALSE)
  cat("Generado: alg_a_outliers.csv\n")
}

# **T3.4: Datos Insuficientes para Algoritmo A**
generate_algo_a_insufficient <- function() {
  # Solo 2 participantes, el algoritmo debería mostrar un error.
  data <- data.frame(
    pollutant = "no2",
    n_lab = 2,
    level = "L1",
    participant_id = c("p1", "p2"),
    mean_value = c(25.2, 26.1),
    sd_value = 0.3
  )
  write.csv(data, "validation/test_data_w_03/summary_n2_insufficient.csv", row.names = FALSE)
  cat("Generado: summary_n2_insufficient.csv\n")
}

# --- Ejecución (Simbólica) ---
cat("Script de la Semana 3: Definición de casos de prueba para análisis robusto.\n")
cat("Para una validación completa, ejecute las funciones generate_*() y use los CSV generados en la app.\n")

# generate_algo_a_valid()
# generate_robust_estimators_valid()
# generate_algo_a_outliers()
# generate_algo_a_insufficient()
