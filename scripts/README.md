# Scripts

Los scripts quedaron separados por su relacion con el aplicativo Shiny.

## `aplicativo/`

Scripts invocados directamente desde `app.R` en la interfaz de flujo de
preprocesamiento y consolidacion:

- `preprocesar_calaire.R`
- `convert_pt_app_to_calaire_app.R`
- `convert_from_calaire_app_to_pt_app.R`
- `consolidar_ronda_pt_app.R`

## `adicionales/`

Utilidades auxiliares, historicas, demos, generadores de datos y validaciones
que no son llamadas directamente por el aplicativo Shiny:

- `build_bootstrap_homogeneity_stability.R`
- `build_homogeneity_stability_from_summary.R`
- `demo_algoritmo_a.R`
- `demo_calculo_scores.R`
- `demo_homogeneidad_estabilidad.R`
- `demo_valores_consenso.R`
- `evaluar_u_homo.R`
- `generar_resumen_generadores.R`
- `generate_pt_data.R`
- `generate_pt_data_with_ref.R`
- `preprocesar_part_1.R`
- `run_preprocessor_calaire.R`
- `run_validation_semiauto.R`
- `run_validation_semiauto.py`
- `unir_rondas.R`
- `update_docs.R`
