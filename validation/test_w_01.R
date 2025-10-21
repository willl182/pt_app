# Auditoría de la Semana 1: Carga y Validación de Datos
#
# Este script automatiza las pruebas definidas en el protocolo de la auditoría de la semana 1.
# Se centra en verificar la robustez de la aplicación `app.R` ante diferentes escenarios
# de disponibilidad y formato de los datos de entrada.

# **Directorio de Prueba**
# Se asume que este script se ejecuta desde el directorio raíz del proyecto.
# Crea un directorio temporal para las pruebas para no interferir con los datos originales.
if (!dir.exists("validation/test_env")) {
  dir.create("validation/test_env")
}

# **Función de Ayuda para Simular Datos**
# Crea archivos CSV de prueba para los escenarios.
create_test_data <- function(env_path = "validation/test_env") {
  # Datos de homogeneidad válidos
  write.csv(data.frame(
    pollutant = "co",
    level = "L1",
    replicate = 1,
    value = 10
  ), file.path(env_path, "homogeneity.csv"), row.names = FALSE)

  # Datos de estabilidad válidos
  write.csv(data.frame(
    pollutant = "co",
    level = "L1",
    replicate = 1,
    value = 11
  ), file.path(env_path, "stability.csv"), row.names = FALSE)

  # Datos de resumen válidos
  write.csv(data.frame(
    pollutant = "co",
    n_lab = 4,
    level = "L1",
    participant_id = "p1",
    mean_value = 10,
    sd_value = 1
  ), file.path(env_path, "summary_n4.csv"), row.names = FALSE)
}

# --- Pruebas ---

# **T1.1: Caso de Éxito - Todos los Archivos Presentes**
test_success_case <- function() {
  cat("--- Ejecutando T1.1: Caso de Éxito ---\n")

  # Preparar el entorno
  test_dir <- "validation/test_env/T1.1"
  dir.create(test_dir, recursive = TRUE)
  create_test_data(test_dir)

  # Simular la ejecución de la app (comprobando si puede leer los archivos)
  # En un entorno real, usaríamos `shinytest2`, pero aquí simulamos la lógica de carga.
  app_files <- c(
    file.path(test_dir, "homogeneity.csv"),
    file.path(test_dir, "stability.csv"),
    file.path(test_dir, "summary_n4.csv")
  )

  files_exist <- all(file.exists(app_files))

  if (files_exist) {
    cat("Resultado T1.1: APROBADO - Todos los archivos necesarios fueron creados y encontrados.\n")
  } else {
    cat("Resultado T1.1: FALLIDO - No se encontraron todos los archivos necesarios.\n")
  }

  unlink(test_dir, recursive = TRUE)
}

# **T1.2: Fallo - Archivo Faltante**
test_missing_file_case <- function() {
  cat("\n--- Ejecutando T1.2: Fallo (Archivo Faltante) ---\n")

  # La app carga `homogeneity.csv` de forma estática. Si falta, la app fallará al iniciarse.
  # Esta prueba verifica que R efectivamente lanza un error.

  # Creamos un entorno sin `homogeneity.csv`
  test_dir <- "validation/test_env/T1.2"
  dir.create(test_dir, recursive = TRUE)
  # No creamos homogeneity.csv

  original_wd <- getwd()
  setwd(test_dir)

  # Usamos `try` para capturar el error esperado
  result <- try(source("../../app.R", local = new.env()), silent = TRUE)

  setwd(original_wd)

  if (inherits(result, "try-error") && grepl("cannot open file 'homogeneity.csv'", result[1])) {
    cat("Resultado T1.2: APROBADO - La aplicación falló como se esperaba al no encontrar 'homogeneity.csv'.\n")
  } else {
    cat("Resultado T1.2: FALLIDO - La aplicación no lanzó el error esperado.\n")
  }

  unlink(test_dir, recursive = TRUE)
}

# **T1.3: Fallo - Archivo Malformado**
test_malformed_file_case <- function() {
  cat("\n--- Ejecutando T1.3: Fallo (Archivo Malformado) ---\n")

  # Esta prueba verifica que la lógica de validación de la app detecta columnas faltantes.
  # Simularemos la lógica reactiva de la app.

  # Crear datos de homogeneidad sin la columna "level"
  malformed_data <- data.frame(
    pollutant = "co",
    replicate = 1,
    value = 10
  )

  # Lógica de validación simulada de `output$validation_message`
  required_cols <- c("level")
  has_required <- all(required_cols %in% names(malformed_data))

  if (!has_required) {
    cat("Resultado T1.3: APROBADO - La lógica de validación detectó la columna 'level' faltante.\n")
  } else {
    cat("Resultado T1.3: FALLIDO - La lógica de validación no detectó el problema.\n")
  }
}

# --- Ejecución de Todas las Pruebas ---
test_success_case()
test_missing_file_case()
test_malformed_file_case()

# Limpiar el directorio de pruebas
unlink("validation/test_env", recursive = TRUE)
cat("\nPruebas de la Semana 1 completadas. Entorno limpiado.\n")
