# ===================================================================
# Titulo: genera_anexos.R
# Entregable: 09
# Descripcion: Genera CSVs con resultados intermedios y log de ejecución
# Entrada: data/homogeneity.csv, stability.csv, summary_n4.csv
# Salida: anexos CSV, log.txt
# Autor: UNAL/INM
# Fecha: 2026-01-24
# Referencia: ISO 13528:2022, ISO 17043:2024
# ===================================================================

library(tidyverse)

# Cargar funciones
source("deliv/08_beta/R/funciones_finales.R")

# ===================================================================
# CARGA DE DATOS
# ===================================================================

cat("Cargando datos...\n")

hom_data <- read.csv("data/homogeneity.csv", check.names = FALSE)
stab_data <- read.csv("data/stability.csv", check.names = FALSE)
summary_data <- read.csv("data/summary_n4.csv", check.names = FALSE)

cat("  - homogeneity.csv:", nrow(hom_data), "registros\n")
cat("  - stability.csv:", nrow(stab_data), "registros\n")
cat("  - summary_n4.csv:", nrow(summary_data), "registros\n")

# ===================================================================
# DIRECTORIO DE ANEXOS
# ===================================================================

anexos_dir <- "deliv/09_informe_final/anexos"
if (!dir.exists(anexos_dir)) {
  dir.create(anexos_dir, recursive = TRUE)
  cat("Creado directorio de anexos:", anexos_dir, "\n")
}

# ===================================================================
# 1. HOMOGENEIDAD POR ANALITO/NIVEL
# ===================================================================

cat("\nCalculando homogeneidad...\n")

hom_results <- list()

analitos_unicos <- unique(hom_data$pollutant)

for (analito in analitos_unicos) {
  cat("  Analito:", analito, "\n")
  
  niveles_unicos <- unique(hom_data$level[hom_data$pollutant == analito])
  
  for (nivel in niveles_unicos) {
    hom_filtered <- hom_data[hom_data$pollutant == analito & 
                            hom_data$level == nivel, ]
    
    # Crear matriz (muestras x réplicas)
    sample_ids <- unique(hom_filtered$sample_id)
    replicates <- unique(hom_filtered$replicate)
    
    matriz <- matrix(NA, nrow = length(sample_ids), ncol = length(replicates))
    
    for (i in seq_along(sample_ids)) {
      for (j in seq_along(replicates)) {
        idx <- hom_filtered$sample_id == sample_ids[i] & 
                hom_filtered$replicate == replicates[j]
        matriz[i, j] <- hom_filtered$value[idx]
      }
    }
    
    # Calcular estadísticos
    stats <- calculate_homogeneity_stats(matriz)
    
    if (is.null(stats$error)) {
      # Calcular criterio
      sigma_pt <- 0.03  # Asumir valor
      c_criterion <- calculate_homogeneity_criterion(sigma_pt)
      c_expanded <- calculate_homogeneity_criterion_expanded(sigma_pt, stats$sw_sq)
      
      # Evaluar
      evaluacion <- evaluate_homogeneity(stats$ss, c_criterion)
      
      hom_results[[paste0(analito, "_", nivel)]] <- data.frame(
        pollutant = analito,
        level = nivel,
        g = stats$g,
        m = stats$m,
        grand_mean = stats$grand_mean,
        s_x_bar = stats$s_xt,
        sw = stats$sw,
        ss = stats$ss,
        c_criterion = c_criterion,
        c_expanded = c_expanded,
        evaluacion = evaluacion,
        stringsAsFactors = FALSE
      )
    }
  }
}

hom_df <- do.call(rbind, hom_results)
write.csv(hom_df, file.path(anexos_dir, "homogeneidad_resultados.csv"), row.names = FALSE)
cat("  Guardado: homogeneidad_resultados.csv (", nrow(hom_df), " registros)\n")

# ===================================================================
# 2. ESTABILIDAD POR ANALITO
# ===================================================================

cat("\nCalculando estabilidad...\n")

stab_results <- list()

for (analito in analitos_unicos) {
  cat("  Analito:", analito, "\n")
  
  # Obtener media de homogeneidad para este analito
  hom_analito <- hom_df[hom_df$pollutant == analito, ]
  
  if (nrow(hom_analito) > 0) {
    hom_mean <- mean(hom_analito$grand_mean, na.rm = TRUE)
  } else {
    hom_mean <- NA
  }
  
  # Filtrar datos de estabilidad
  stab_filtered <- stab_data[stab_data$pollutant == analito, ]
  
  if (nrow(stab_filtered) > 0) {
    stats <- calculate_stability_stats(stab_filtered$value, hom_mean)
    
    # Criterio
    sigma_pt <- 0.03
    criterion <- 0.3 * sigma_pt
    
    evaluacion <- evaluate_stability(stats$difference, criterion)
    
    stab_results[[analito]] <- data.frame(
      pollutant = analito,
      hom_mean = hom_mean,
      stab_mean = stats$stab_mean,
      difference = stats$difference,
      criterion = criterion,
      evaluacion = evaluacion,
      stringsAsFactors = FALSE
    )
  }
}

stab_df <- do.call(rbind, stab_results)
write.csv(stab_df, file.path(anexos_dir, "estabilidad_resultados.csv"), row.names = FALSE)
cat("  Guardado: estabilidad_resultados.csv (", nrow(stab_df), " registros)\n")

# ===================================================================
# 3. ESTADÍSTICOS ROBUSTOS POR ANALITO/NIVEL
# ===================================================================

cat("\nCalculando estadísticos robustos...\n")

robust_results <- list()

analitos_summary <- unique(summary_data$pollutant)

for (analito in analitos_summary) {
  cat("  Analito:", analito, "\n")
  
  niveles_summary <- unique(summary_data$level[summary_data$pollutant == analito])
  
  for (nivel in niveles_summary) {
    # Filtrar datos (excluyendo referencia)
    filtered <- summary_data[summary_data$pollutant == analito &
                            summary_data$level == nivel &
                            summary_data$participant_id != "ref", ]
    
    if (nrow(filtered) > 0) {
      valores <- filtered$mean_value
      
      # Calcular estadísticos
      niqr <- calculate_niqr(valores)
      made <- calculate_mad_e(valores)
      algo_a <- run_algorithm_a(valores)
      
      robust_results[[paste0(analito, "_", nivel)]] <- data.frame(
        pollutant = analito,
        level = nivel,
        n_lab = nrow(filtered),
        n_participants = sum(!is.na(filtered$participant_id)),
        median = median(valores, na.rm = TRUE),
        niqr = niqr,
        made = made,
        algo_a_x = if (!is.null(algo_a$error)) algo_a$assigned_value else NA,
        algo_a_sd = if (!is.null(algo_a$error)) algo_a$robust_sd else NA,
        algo_a_converged = if (!is.null(algo_a$error)) algo_a$converged else NA,
        stringsAsFactors = FALSE
      )
    }
  }
}

robust_df <- do.call(rbind, robust_results)
write.csv(robust_df, file.path(anexos_dir, "estadisticos_robustos.csv"), row.names = FALSE)
cat("  Guardado: estadisticos_robustos.csv (", nrow(robust_df), " registros)\n")

# ===================================================================
# 4. PUNTAJES PT POR ANALITO/NIVEL
# ===================================================================

cat("\nCalculando puntajes PT...\n")

scores_results <- list()

for (analito in analitos_summary) {
  cat("  Analito:", analito, "\n")
  
  for (nivel in niveles_summary) {
    # Filtrar datos
    all_data <- summary_data[summary_data$pollutant == analito &
                           summary_data$level == nivel, ]
    
    ref_data <- all_data[all_data$participant_id == "ref", ]
    participants_data_df <- all_data[all_data$participant_id != "ref", ]
    
    if (nrow(ref_data) > 0 && nrow(participants_data_df) > 0) {
      # Calcular parámetros
      x_pt <- mean(ref_data$mean_value, na.rm = TRUE)
      valores <- participants_data_df$mean_value
      n <- length(valores)
      
      sigma_pt_made <- calculate_mad_e(valores)
      u_xpt <- 1.25 * sigma_pt_made / sqrt(n)
      k <- 2
      
      # Calcular puntajes
      scores_df <- calculate_scores_participants(
        participants_data_df, x_pt, sigma_pt_made, u_xpt, k
      )
      
      # Agregar información del análisis
      scores_df$pollutant <- analito
      scores_df$level <- nivel
      scores_df$n_lab <- n
      
      scores_results[[paste0(analito, "_", nivel)]] <- scores_df
    }
  }
}

scores_df <- do.call(rbind, scores_results)
write.csv(scores_df, file.path(anexos_dir, "puntajes_pt.csv"), row.names = FALSE)
cat("  Guardado: puntajes_pt.csv (", nrow(scores_df), " registros)\n")

# ===================================================================
# 5. RESUMEN DE PUNTAJES
# ===================================================================

cat("\nResumen de evaluación de puntajes...\n")

summary_scores <- scores_df %>%
  group_by(pollutant, level) %>%
  summarise(
    n_participants = n(),
    z_satisfactorio = sum(z_score_eval == "Satisfactorio", na.rm = TRUE),
    z_cuestionable = sum(z_score_eval == "Cuestionable", na.rm = TRUE),
    z_no_satisfactorio = sum(z_score_eval == "No satisfactorio", na.rm = TRUE),
    en_satisfactorio = sum(En_score_eval == "Satisfactorio", na.rm = TRUE),
    en_no_satisfactorio = sum(En_score_eval == "No satisfactorio", na.rm = TRUE),
    .groups = "drop"
  )

write.csv(summary_scores, file.path(anexos_dir, "resumen_puntajes.csv"), row.names = FALSE)
cat("  Guardado: resumen_puntajes.csv (", nrow(summary_scores), " registros)\n")

# ===================================================================
# 6. LOG DE EJECUCIÓN
# ===================================================================

cat("\nGenerando log de ejecución...\n")

log_timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

log_content <- paste0(
  "=== LOG DE GENERACIÓN DE ANEXOS ===\n",
  "Fecha: ", log_timestamp, "\n",
  "Script: genera_anexos.R\n\n",
  
  "--- RESUMEN DE ARCHIVOS GENERADOS ---\n",
  "1. homogeneidad_resultados.csv: ", nrow(hom_df), " registros\n",
  "2. estabilidad_resultados.csv: ", nrow(stab_df), " registros\n",
  "3. estadisticos_robustos.csv: ", nrow(robust_df), " registros\n",
  "4. puntajes_pt.csv: ", nrow(scores_df), " registros\n",
  "5. resumen_puntajes.csv: ", nrow(summary_scores), " registros\n\n",
  
  "--- RESUMEN DE HOMOGENEIDAD ---\n",
  "Total evaluaciones: ", nrow(hom_df), "\n",
  "Aceptables: ", sum(hom_df$evaluacion == "Aceptable", na.rm = TRUE), "\n",
  "No aceptables: ", sum(hom_df$evaluacion == "No aceptable", na.rm = TRUE), "\n\n",
  
  "--- RESUMEN DE ESTABILIDAD ---\n",
  "Total evaluaciones: ", nrow(stab_df), "\n",
  "Estables: ", sum(stab_df$evaluacion == "Estable", na.rm = TRUE), "\n",
  "No estables: ", sum(stab_df$evaluacion == "No estable", na.rm = TRUE), "\n\n",
  
  "--- RESUMEN DE PUNTAJES Z ---\n",
  "Total puntajes z: ", sum(!is.na(scores_df$z_score)), "\n",
  "Satisfactorios: ", sum(scores_df$z_score_eval == "Satisfactorio", na.rm = TRUE), "\n",
  "Cuestionables: ", sum(scores_df$z_score_eval == "Cuestionable", na.rm = TRUE), "\n",
  "No satisfactorios: ", sum(scores_df$z_score_eval == "No satisfactorio", na.rm = TRUE), "\n\n",
  
  "--- FIN DEL LOG ---\n"
)

log_file <- file.path(anexos_dir, "generacion_log.txt")
writeLines(log_content, log_file)
cat("  Guardado: generacion_log.txt\n")

# ===================================================================
# 7. RESUMEN FINAL
# ===================================================================

cat("\n", rep("=", 60), "\n", sep = "")
cat("GENERACIÓN DE ANEXOS COMPLETADA\n")
cat(rep("=", 60), "\n\n", sep = "")

cat("Archivos generados en:", anexos_dir, "\n\n")

cat("1. homogeneidad_resultados.csv\n")
cat("2. estabilidad_resultados.csv\n")
cat("3. estadisticos_robustos.csv\n")
cat("4. puntajes_pt.csv\n")
cat("5. resumen_puntajes.csv\n")
cat("6. generacion_log.txt\n\n")

cat("Total de registros generados:\n")
cat("  Homogeneidad:", nrow(hom_df), "\n")
cat("  Estabilidad:", nrow(stab_df), "\n")
cat("  Estadísticos robustos:", nrow(robust_df), "\n")
cat("  Puntajes:", nrow(scores_df), "\n")
cat("  Resumen:", nrow(summary_scores), "\n\n")

cat("Proceso finalizado exitosamente.\n")
