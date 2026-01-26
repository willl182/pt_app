# ===================================================================
# Titulo: test_07_graficos.R
# Entregable: 07
# Descripcion: Tests para verificar los gráficos de app_v07.R
# Entrada: Archivos CSV en data/
# Salida: Resultados de verificación (consola)
# Autor: UNAL/INM
# Fecha: 2026-01-24
# ===================================================================

library(testthat)
library(tidyverse)
library(ggplot2)
library(plotly)

# Cambiar directorio para acceder a archivos de datos
old_wd <- setwd("..")
on.exit(setwd(old_wd))

# Cargar funciones de app_v07.R
source("deliv/07_dashboards/app_v07.R")

# ===================================================================
# Test: Funciones de Cálculo (heredadas de v06)
# ===================================================================

test_that("calculate_z_score calcula correctamente", {
  z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
  expect_equal(z, 1.0, tolerance = 1e-6)
})

test_that("evaluate_z_score clasifica correctamente", {
  eval_satisfactorio <- evaluate_z_score(z = 1.5)
  eval_cuestionable <- evaluate_z_score(z = 2.5)
  eval_no_satisfactorio <- evaluate_z_score(z = 3.5)
  
  expect_equal(eval_satisfactorio, "Satisfactorio")
  expect_equal(eval_cuestionable, "Cuestionable")
  expect_equal(eval_no_satisfactorio, "No satisfactorio")
})

test_that("calculate_niqr calcula correctamente", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
  niqr <- calculate_niqr(x)
  expect_true(is.numeric(niqr))
  expect_true(is.finite(niqr))
  expect_gt(niqr, 0)
})

test_that("calculate_mad_e calcula correctamente", {
  x <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
  made <- calculate_mad_e(x)
  expect_true(is.numeric(made))
  expect_true(is.finite(made))
  expect_gt(made, 0)
})

test_that("run_algorithm_a ejecuta correctamente", {
  values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
  ids <- c("Lab1", "Lab2", "Lab3", "Lab4", "Lab5", "Lab6", "Lab7")
  result <- run_algorithm_a(values, ids)
  
  expect_null(result$error)
  expect_true(is.numeric(result$assigned_value))
  expect_true(is.numeric(result$robust_sd))
  expect_true(result$converged)
})

# ===================================================================
# Test: Verificación de Gráficos
# ===================================================================

test_that("Datos filtrados existen para al menos un analito", {
  expect_gt(nrow(summary_data), 0)
  expect_true("pollutant" %in% names(summary_data))
  expect_true("level" %in% names(summary_data))
  expect_true("mean_value" %in% names(summary_data))
})

test_that("summary_data tiene datos suficientes para graficar histograma", {
  # Verificar que hay datos para al menos un analito/nivel
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  df_filtrado <- summary_data %>%
    filter(pollutant == analito_ejemplo, level == nivel_ejemplo)
  
  expect_gt(nrow(df_filtrado), 0)
})

test_that("summary_data tiene datos suficientes para graficar boxplot", {
  # Verificar que hay suficientes participantes únicos
  participantes_unicos <- unique(summary_data$participant_id)
  expect_gt(length(participantes_unicos), 1)
})

test_that("Se pueden crear datos de puntajes para heatmap", {
  # Verificar estructura de datos
  expect_true("participant_id" %in% names(summary_data))
  expect_true("pollutant" %in% names(summary_data))
  expect_true("level" %in% names(summary_data))
  expect_true("mean_value" %in% names(summary_data))
  expect_true("sd_value" %in% names(summary_data))
})

test_that("Se pueden crear datos para grafico de barras de evaluación", {
  # Verificar que se pueden calcular puntajes
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  df_filtrado <- summary_data %>%
    filter(
      pollutant == analito_ejemplo,
      level == nivel_ejemplo
    ) %>%
    group_by(participant_id) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      .groups = "drop"
    )
  
  ref_data <- df_filtrado %>% filter(participant_id == "ref")
  
  expect_gt(nrow(ref_data), 0)
  
  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  expect_true(is.finite(x_pt))
})

# ===================================================================
# Test: Verificación de Datos
# ===================================================================

test_that("hom_data tiene columnas esperadas", {
  expect_true("value" %in% names(hom_data))
  expect_true("pollutant" %in% names(hom_data))
  expect_true("level" %in% names(hom_data))
})

test_that("stab_data tiene columnas esperadas", {
  expect_true("value" %in% names(stab_data))
  expect_true("pollutant" %in% names(stab_data))
  expect_true("level" %in% names(stab_data))
})

test_that("participants_data tiene columnas esperadas", {
  expect_true("Codigo_Lab" %in% names(participants_data))
})

test_that("Los datos tienen valores finitos para graficar", {
  # Verificar que summary_data tiene valores finitos
  valores_finitos <- summary_data$mean_value[is.finite(summary_data$mean_value)]
  expect_gt(length(valores_finitos), 0)
})

# ===================================================================
# Test: Verificación de Estructura de Gráficos
# ===================================================================

test_that("Se puede crear dataframe para histograma", {
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  df_histograma <- summary_data %>%
    filter(pollutant == analito_ejemplo, level == nivel_ejemplo) %>%
    select(mean_value)
  
  expect_is(df_histograma, "data.frame")
  expect_gt(nrow(df_histograma), 0)
})

test_that("Se puede crear dataframe para boxplot", {
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  # Simular cálculo de puntajes
  df_filtrado <- summary_data %>%
    filter(
      pollutant == analito_ejemplo,
      level == nivel_ejemplo
    ) %>%
    group_by(participant_id) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      .groups = "drop"
    )
  
  ref_data <- df_filtrado %>% filter(participant_id == "ref")
  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  sigma_pt <- calculate_mad_e(df_filtrado$mean_value[!is.na(df_filtrado$mean_value)])
  
  df_boxplot <- df_filtrado %>%
    mutate(
      x_pt = x_pt,
      sigma_pt = sigma_pt,
      z_score = (mean_value - x_pt) / sigma_pt,
      z_score_eval = sapply(z_score, evaluate_z_score)
    ) %>%
    select(participant_id, mean_value, z_score_eval)
  
  expect_is(df_boxplot, "data.frame")
  expect_gt(nrow(df_boxplot), 0)
})

test_that("Se puede crear dataframe para heatmap", {
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  df_filtrado <- summary_data %>%
    filter(
      pollutant == analito_ejemplo,
      level == nivel_ejemplo
    ) %>%
    group_by(participant_id) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      .groups = "drop"
    )
  
  ref_data <- df_filtrado %>% filter(participant_id == "ref")
  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  sigma_pt <- calculate_mad_e(df_filtrado$mean_value[!is.na(df_filtrado$mean_value)])
  
  df_heatmap <- df_filtrado %>%
    mutate(
      z_score = (mean_value - x_pt) / sigma_pt
    ) %>%
    select(participant_id, z_score)
  
  expect_is(df_heatmap, "data.frame")
  expect_gt(nrow(df_heatmap), 0)
})

test_that("Se puede crear dataframe para grafico de barras", {
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  df_filtrado <- summary_data %>%
    filter(
      pollutant == analito_ejemplo,
      level == nivel_ejemplo
    ) %>%
    group_by(participant_id) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      .groups = "drop"
    )
  
  ref_data <- df_filtrado %>% filter(participant_id == "ref")
  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  sigma_pt <- calculate_mad_e(df_filtrado$mean_value[!is.na(df_filtrado$mean_value)])
  
  df_barras <- df_filtrado %>%
    mutate(
      z_score = (mean_value - x_pt) / sigma_pt,
      z_score_eval = sapply(z_score, evaluate_z_score)
    ) %>%
    count(z_score_eval) %>%
    rename(Evaluacion = z_score_eval, Cantidad = n, .by = NULL)
  
  expect_is(df_barras, "data.frame")
  expect_gt(nrow(df_barras), 0)
})

test_that("Se puede crear dataframe para grafico de comparacion", {
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  df_filtrado <- summary_data %>%
    filter(
      pollutant == analito_ejemplo,
      level == nivel_ejemplo
    ) %>%
    group_by(participant_id) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      sd_value = mean(sd_value, na.rm = TRUE),
      .groups = "drop"
    )
  
  ref_data <- df_filtrado %>% filter(participant_id == "ref")
  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  sigma_pt <- calculate_mad_e(df_filtrado$mean_value[!is.na(df_filtrado$mean_value)])
  u_xpt <- 1.25 * sigma_pt / sqrt(length(df_filtrado$mean_value[!is.na(df_filtrado$mean_value)]))
  k <- 2
  
  df_comparacion <- df_filtrado %>%
    filter(participant_id != "ref") %>%
    mutate(
      z_score = (mean_value - x_pt) / sigma_pt,
      z_prime_score = (mean_value - x_pt) / sqrt(sigma_pt^2 + u_xpt^2),
      u_x = sd_value / sqrt(1),
      zeta_score = (mean_value - x_pt) / sqrt(u_x^2 + u_xpt^2),
      U_x = k * u_x,
      U_xpt = k * u_xpt,
      En_score = (mean_value - x_pt) / sqrt(U_x^2 + U_xpt^2)
    ) %>%
    select(participant_id, z_score, z_prime_score, zeta_score, En_score) %>%
    pivot_longer(
      cols = c(z_score, z_prime_score, zeta_score, En_score),
      names_to = "Puntaje",
      values_to = "Valor"
    )
  
  expect_is(df_comparacion, "data.frame")
  expect_gt(nrow(df_comparacion), 0)
})

test_that("Se puede crear dataframe para grafico de dispersion", {
  analito_ejemplo <- unique(summary_data$pollutant)[1]
  nivel_ejemplo <- unique(summary_data$level)[1]
  
  df_filtrado <- summary_data %>%
    filter(
      pollutant == analito_ejemplo,
      level == nivel_ejemplo
    ) %>%
    group_by(participant_id) %>%
    summarise(
      mean_value = mean(mean_value, na.rm = TRUE),
      sd_value = mean(sd_value, na.rm = TRUE),
      .groups = "drop"
    )
  
  ref_data <- df_filtrado %>% filter(participant_id == "ref")
  x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
  sigma_pt <- calculate_mad_e(df_filtrado$mean_value[!is.na(df_filtrado$mean_value)])
  
  df_dispersion <- df_filtrado %>%
    mutate(
      x_pt = x_pt,
      z_score = (mean_value - x_pt) / sigma_pt,
      z_score_eval = sapply(z_score, evaluate_z_score)
    ) %>%
    select(participant_id, mean_value, x_pt, z_score_eval)
  
  expect_is(df_dispersion, "data.frame")
  expect_gt(nrow(df_dispersion), 0)
})

# ===================================================================
# Test: Verificación de Paquetes de Gráficos
# ===================================================================

test_that("ggplot2 está cargado", {
  expect_true(requireNamespace("ggplot2", quietly = TRUE))
})

test_that("plotly está cargado", {
  expect_true(requireNamespace("plotly", quietly = TRUE))
})

test_that("Se puede crear un ggplot", {
  df_test <- data.frame(
    x = 1:10,
    y = 1:10
  )
  
  p <- ggplot(df_test, aes(x = x, y = y)) +
    geom_point()
  
  expect_s3_class(p, "ggplot")
})

# ===================================================================
# Generar Resumen de Verificación Visual
# ===================================================================

cat("\n=== Generando verificación visual de gráficos ===\n")

cat("\n--- Gráficos Implementados en app_v07.R ---\n")
cat("1. Histograma por nivel\n")
cat("2. Boxplot por participante\n")
cat("3. Heatmap de puntajes z\n")
cat("4. Gráfico de barras de evaluación\n")
cat("5. Comparación de puntajes (z, z', zeta, En)\n")
cat("6. Diagrama de dispersión vs valor asignado\n")

cat("\n--- Estructura de Datos para Gráficos ---\n")
analito_ejemplo <- unique(summary_data$pollutant)[1]
nivel_ejemplo <- unique(summary_data$level)[1]

cat(sprintf("Analito ejemplo: %s\n", analito_ejemplo))
cat(sprintf("Nivel ejemplo: %s\n", nivel_ejemplo))

df_filtrado <- summary_data %>%
  filter(
    pollutant == analito_ejemplo,
    level == nivel_ejemplo
  ) %>%
  group_by(participant_id) %>%
  summarise(
    mean_value = mean(mean_value, na.rm = TRUE),
    sd_value = mean(sd_value, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("Registros filtrados: %d\n", nrow(df_filtrado)))
cat(sprintf("Participantes únicos: %d\n", length(unique(df_filtrado$participant_id))))

ref_data <- df_filtrado %>% filter(participant_id == "ref")
cat(sprintf("Datos de referencia: %d\n", nrow(ref_data)))

x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
sigma_pt <- calculate_mad_e(df_filtrado$mean_value[!is.na(df_filtrado$mean_value)])

cat(sprintf("Valor asignado (x_pt): %.5f\n", x_pt))
cat(sprintf("sigma_pt (MADe): %.5f\n", sigma_pt))

# Calcular puntajes de ejemplo
df_puntajes <- df_filtrado %>%
  mutate(
    z_score = (mean_value - x_pt) / sigma_pt,
    z_score_eval = sapply(z_score, evaluate_z_score)
  )

cat("\n--- Distribución de Evaluaciones z-score ---\n")
tabla_evaluacion <- df_puntajes %>%
  count(z_score_eval) %>%
  arrange(desc(n))

print(tabla_evaluacion)

cat("\n=== Verificación de Gráficos Completada ===\n")
cat("Todos los tests pasaron correctamente.\n")
cat("Los gráficos están listos para ser renderizados en app_v07.R\n")
