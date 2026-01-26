# Documentación de Funciones

**Fecha de generación:** 2026-01-24 17:27:58.725427

**Total funciones:** 48

---

## `algo_key`

**Archivo:** `app.R`

**Parámetros:** `pollutant, n_lab, level) paste(pollutant, n_lab, level, sep = "||"`

---

## `algorithm_A`

@export

**Archivo:** `utils.R`

**Parámetros:** `x, max_iter = 100`

---

## `calculate_en_score`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `x, x_pt, U_x, U_xpt`

**Referencia ISO:** ISO 13528:2022, Section 10.5

---

## `calculate_homogeneity_criterion`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `sigma_pt`

**Referencia ISO:** ISO 13528:2022, Section 9.2.3

---

## `calculate_homogeneity_criterion_expanded`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `sigma_pt, sw_sq`

**Referencia ISO:** ISO 13528:2022, Section 9.2.4

---

## `calculate_homogeneity_stats`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `sample_data`

**Referencia ISO:** ISO 13528:2022, Section 9.2

---

## `calculate_mad_e`

@export

**Archivo:** `pt_robust_stats.R`

**Parámetros:** `x`

**Referencia ISO:** ISO 13528:2022, Section 9.4

---

## `calculate_method_scores_df`

**Archivo:** `app.R`

**Parámetros:** `method_code`

---

## `calculate_niqr`

@export

**Archivo:** `pt_robust_stats.R`

**Parámetros:** `x`

**Referencia ISO:** ISO 13528:2022, Section 9.4

---

## `calculate_stability_criterion`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `sigma_pt`

**Referencia ISO:** ISO 13528:2022, Section 9.3.3

---

## `calculate_stability_criterion_expanded`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `c_criterion, u_hom_mean, u_stab_mean`

---

## `calculate_stability_stats`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `stab_sample_data, hom_grand_mean`

**Referencia ISO:** ISO 13528:2022, Section 9.3

---

## `calculate_u_hom`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `ss`

**Referencia ISO:** ISO 13528:2022, Section 9.5

---

## `calculate_u_stab`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `diff_hom_stab, c_criterion`

**Referencia ISO:** ISO 13528:2022, Section 9.5

---

## `calculate_z_prime_score`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `x, x_pt, sigma_pt, u_xpt`

**Referencia ISO:** ISO 13528:2022, Section 10.3

---

## `calculate_z_score`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `x, x_pt, sigma_pt`

**Referencia ISO:** ISO 13528:2022, Section 10.2

---

## `calculate_zeta_score`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `x, x_pt, u_x, u_xpt`

**Referencia ISO:** ISO 13528:2022, Section 10.4

---

## `combine_scores_result`

**Archivo:** `app.R`

**Parámetros:** `res`

---

## `compute_combo_scores`

**Archivo:** `app.R`

**Parámetros:** `participants_df, x_pt, sigma_pt, u_xpt, combo_meta, k = 2, u_hom = 0, u_stab = 0`

---

## `compute_homogeneity`

**Archivo:** `report_template.Rmd`

**Parámetros:** `data_full, pol, lev`

---

## `compute_homogeneity_metrics`

**Archivo:** `app.R`

**Parámetros:** `target_pollutant, target_level`

---

## `compute_scores_for_selection`

**Archivo:** `app.R`

**Parámetros:** `target_pollutant, target_n_lab, target_level, summary_data, max_iter = 50, k_factor = 2`

---

## `compute_scores_metrics`

**Archivo:** `app.R`

**Parámetros:** `summary_df, target_pollutant, target_n_lab, target_level, sigma_pt, u_xpt, k, m = NULL`

---

## `compute_stability_metrics`

**Archivo:** `app.R`

**Parámetros:** `target_pollutant, target_level, hom_results`

---

## `count_eval`

**Archivo:** `app.R`

**Parámetros:** `eval_col, eval_type`

---

## `create_combo_plot`

**Archivo:** `app.R`

**Parámetros:** `df, score_col, title_suffix, limit_lines = c(2, 3), limit_colors = c("orange", "red"), show_legend = TRUE`

---

## `ensure_classification_columns`

**Archivo:** `app.R`

**Parámetros:** `df`

---

## `evaluate_en_score`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `en`

---

## `evaluate_en_score_vec`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `en`

---

## `evaluate_homogeneity`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `ss, c_criterion, c_expanded = NULL`

---

## `evaluate_stability`

@export

**Archivo:** `pt_homogeneity.R`

**Parámetros:** `diff_hom_stab, c_criterion, c_expanded = NULL`

---

## `evaluate_z_score`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `z`

---

## `evaluate_z_score_vec`

@export

**Archivo:** `pt_scores.R`

**Parámetros:** `z`

---

## `format_num`

**Archivo:** `app.R`

**Parámetros:** `x`

---

## `get_combo_levels_order`

**Archivo:** `app.R`

**Parámetros:** `combos_filtered`

---

## `get_global_overview_data`

**Archivo:** `app.R`

**Parámetros:** `spec`

---

## `get_global_summary_row`

**Archivo:** `app.R`

**Parámetros:** `spec`

---

## `get_scores_result`

**Archivo:** `app.R`

**Parámetros:** `pollutant, n_lab, level`

---

## `get_wide_data`

**Archivo:** `app.R`

**Parámetros:** `df, target_pollutant`

---

## `mad_e_manual`

@export

**Archivo:** `utils.R`

**Parámetros:** `x`

---

## `nIQR_manual`

@export

**Archivo:** `utils.R`

**Parámetros:** `x`

---

## `normalize_n`

**Archivo:** `app.R`

**Parámetros:** `df`

---

## `plot_scores`

**Archivo:** `app.R`

**Parámetros:** `df, score_col, title, subtitle, ylab, warn_limits = NULL, action_limits = NULL`

---

## `render_global_score_heatmap`

**Archivo:** `app.R`

**Parámetros:** `output_id, combo_key, score_col, eval_col, palette, title_prefix`

---

## `run_algorithm_a`

@export

**Archivo:** `pt_robust_stats.R`

**Parámetros:** `values, ids = NULL, max_iter = 50, tol = 1e-03`

**Referencia ISO:** ISO 13528:2022, Annex C

---

## `run_algorithm_a_report`

**Archivo:** `report_template.Rmd`

**Parámetros:** `values, max_iter = 50`

---

## `server`

**Archivo:** `app.R`

**Parámetros:** `input, output, session`

---

## `summarize_scores`

**Archivo:** `app.R`

**Parámetros:** `df`

---


