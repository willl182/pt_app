# Auditoría de la Semana 2: Validación de Ítems
#
# Este script está diseñado para generar los conjuntos de datos de prueba
# necesarios para validar los cálculos de homogeneidad y estabilidad en `app.R`.
# Aunque no se pueda ejecutar en este entorno, el código sirve como
# documentación y preparación para una validación futura.

# **Directorio de Prueba**
if (!dir.exists("validation/test_data_w_02")) {
  dir.create("validation/test_data_w_02")
}

# --- Funciones para Generar Datos de Prueba ---

# **T2.1: Validación de Homogeneidad (Caso de Éxito)**
generate_homogeneity_valid <- function() {
  # Datos diseñados para que ss < 0.3 * sigma_pt
  # sigma_pt (MADe de la primera muestra) será bajo.
  set.seed(123)
  data <- data.frame(
    pollutant = "co",
    level = "L1",
    replicate = rep(1:2, each = 10),
    value = c(rnorm(10, mean = 50, sd = 1), rnorm(10, mean = 50, sd = 1))
  )
  write.csv(data, "validation/test_data_w_02/homogeneity_valid.csv", row.names = FALSE)
  cat("Generado: homogeneity_valid.csv\n")
}

# **T2.2: Validación de Homogeneidad (Caso de Fallo)**
generate_homogeneity_fail <- function() {
  # Datos diseñados para que ss > 0.3 * sigma_pt
  # Introducimos una mayor variabilidad entre muestras (ss alto).
  set.seed(123)
  means <- rnorm(10, mean = 50, sd = 5) # Gran variabilidad en las medias
  data <- data.frame(
    pollutant = "co",
    level = "L1",
    replicate = rep(1:2, each = 10),
    value = c(means, means + rnorm(10, 0, 0.1)) # sw bajo, ss alto
  )
  write.csv(data, "validation/test_data_w_02/homogeneity_fail.csv", row.names = FALSE)
  cat("Generado: homogeneity_fail.csv\n")
}

# **T2.3: Validación de Estabilidad (Caso de Éxito)**
generate_stability_valid <- function() {
  # La media de este dataset será muy similar a la de `homogeneity_valid.csv`
  set.seed(456)
  data <- data.frame(
    pollutant = "co",
    level = "L1",
    replicate = rep(1:2, each = 10),
    value = c(rnorm(10, mean = 50.1, sd = 1), rnorm(10, mean = 50.1, sd = 1))
  )
  write.csv(data, "validation/test_data_w_02/stability_valid.csv", row.names = FALSE)
  cat("Generado: stability_valid.csv\n")
}

# **T2.4: Validación de Estabilidad (Caso de Fallo)**
generate_stability_fail <- function() {
  # La media de este dataset será significativamente diferente
  set.seed(789)
  data <- data.frame(
    pollutant = "co",
    level = "L1",
    replicate = rep(1:2, each = 10),
    value = c(rnorm(10, mean = 55, sd = 1), rnorm(10, mean = 55, sd = 1))
  )
  write.csv(data, "validation/test_data_w_02/stability_fail.csv", row.names = FALSE)
  cat("Generado: stability_fail.csv\n")
}

# **T2.5: Datos Insuficientes**
generate_insufficient_data <- function() {
  # Solo una réplica, debería causar un error controlado.
  data <- data.frame(
    pollutant = "co",
    level = "L1",
    replicate = 1,
    value = rnorm(10, 50, 1)
  )
  write.csv(data, "validation/test_data_w_02/homogeneity_insufficient.csv", row.names = FALSE)
  cat("Generado: homogeneity_insufficient.csv\n")
}

# --- Ejecución (Simbólica) ---
# En un entorno con R, se ejecutarían estas funciones.
# Por ahora, el script sirve como definición de los casos de prueba.
cat("Script de la Semana 2: Definición de casos de prueba de datos.\n")
cat("Para una validación completa, ejecute las funciones generate_*() y use los CSV generados en la app.\n")

# generate_homogeneity_valid()
# generate_homogeneity_fail()
# generate_stability_valid()
# generate_stability_fail()
# generate_insufficient_data()
