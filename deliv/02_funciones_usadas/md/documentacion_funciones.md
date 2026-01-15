# Documentación de Funciones - Entregable 02

Este documento cataloga todas las funciones usadas por la aplicación (`app.R`) y los informes asociados. Las referencias se alinean con la norma **ISO 13528:2022**.

## Catálogo de Funciones

| Nombre de Función | Archivo Fuente | Parámetros | Tipo de Retorno | Referencia ISO |
| :--- | :--- | :--- | :--- | :--- |
| `calculate_homogeneity_stats` | `pt_homogeneity.R` | `sample_data` | Lista (`g`, `m`, `grand_mean`, `ss`, `sw`, etc.) | ISO 13528:2022, 9.2 |
| `calculate_homogeneity_criterion` | `pt_homogeneity.R` | `sigma_pt` | Numérico | ISO 13528:2022, 9.2.3 |
| `calculate_homogeneity_criterion_expanded` | `pt_homogeneity.R` | `sigma_pt`, `sw_sq` | Numérico | ISO 13528:2022, 9.2.4 |
| `evaluate_homogeneity` | `pt_homogeneity.R` | `ss`, `c_criterion`, `c_expanded` | Lista (`passes_criterion`, `passes_expanded`, `conclusion`) | ISO 13528:2022, 9.2 |
| `calculate_stability_stats` | `pt_homogeneity.R` | `stab_sample_data`, `hom_grand_mean` | Lista (`stab_grand_mean`, `diff_hom_stab`, `ss`, `sw`, etc.) | ISO 13528:2022, 9.3 |
| `calculate_stability_criterion` | `pt_homogeneity.R` | `sigma_pt` | Numérico | ISO 13528:2022, 9.3.3 |
| `calculate_stability_criterion_expanded` | `pt_homogeneity.R` | `c_criterion`, `u_hom_mean`, `u_stab_mean` | Numérico | ISO 13528:2022, 9.3 |
| `evaluate_stability` | `pt_homogeneity.R` | `diff_hom_stab`, `c_criterion`, `c_expanded` | Lista (`passes_criterion`, `passes_expanded`, `conclusion`) | ISO 13528:2022, 9.3 |
| `calculate_u_hom` | `pt_homogeneity.R` | `ss` | Numérico | ISO 13528:2022, 9.5 |
| `calculate_u_stab` | `pt_homogeneity.R` | `diff_hom_stab`, `c_criterion` | Numérico | ISO 13528:2022, 9.5 |
| `calculate_niqr` | `pt_robust_stats.R` | `x` | Numérico | ISO 13528:2022, 9.4 |
| `calculate_mad_e` | `pt_robust_stats.R` | `x` | Numérico | ISO 13528:2022, 9.4 |
| `run_algorithm_a` | `pt_robust_stats.R` | `values`, `ids`, `max_iter`, `tol` | Lista (`assigned_value`, `robust_sd`, `weights`, etc.) | ISO 13528:2022, Anexo C |
| `calculate_z_score` | `pt_scores.R` | `x`, `x_pt`, `sigma_pt` | Numérico | ISO 13528:2022, 10.2 |
| `calculate_z_prime_score` | `pt_scores.R` | `x`, `x_pt`, `sigma_pt`, `u_xpt` | Numérico | ISO 13528:2022, 10.3 |
| `calculate_zeta_score` | `pt_scores.R` | `x`, `x_pt`, `u_x`, `u_xpt` | Numérico | ISO 13528:2022, 10.4 |
| `calculate_en_score` | `pt_scores.R` | `x`, `x_pt`, `U_x`, `U_xpt` | Numérico | ISO 13528:2022, 10.5 |
| `evaluate_z_score` | `pt_scores.R` | `z` | Texto | ISO 13528:2022, 10 |
| `evaluate_z_score_vec` | `pt_scores.R` | `z` | Vector de texto | ISO 13528:2022, 10 |
| `evaluate_en_score` | `pt_scores.R` | `en` | Texto | ISO 13528:2022, 10.5 |
| `evaluate_en_score_vec` | `pt_scores.R` | `en` | Vector de texto | ISO 13528:2022, 10.5 |
| `classify_with_en` | `pt_scores.R` | `score_val`, `en_val`, `U_xi`, `sigma_pt`, `mu_missing`, `score_label` | Lista (`code`, `label`) | ISO 13528:2022, Anexo B |
| `algorithm_A` | `utils.R` | `x`, `max_iter` | Lista (`robust_mean`, `robust_sd`) | Deprecado (usar `run_algorithm_a`) |
| `mad_e_manual` | `utils.R` | `x` | Numérico | Deprecado (usar `calculate_mad_e`) |
| `nIQR_manual` | `utils.R` | `x` | Numérico | Deprecado (usar `calculate_niqr`) |

## Resumen por Módulo

### Homogeneidad y Estabilidad (`pt_homogeneity.R`)
Incluye los cálculos para evaluar la homogeneidad y la estabilidad de ítems, así como criterios y componentes de incertidumbre.

### Estadísticas Robustas (`pt_robust_stats.R`)
Implementa estimadores robustos (nIQR, MADe) y el Algoritmo A para valores asignados y dispersión.

### Puntajes y Clasificación (`pt_scores.R`)
Calcula z, z', zeta y En, además de evaluar y clasificar resultados conforme a la norma.

### Utilidades (`utils.R`)
Funciones heredadas con fines de compatibilidad; se recomienda usar las versiones actuales en `pt_robust_stats.R`.
