# Registro de actualizaciones del directorio `documentacion`

Fecha: 2024-11-21

## Resumen general
- Todos los documentos Markdown del directorio fueron sincronizados con la lógica actual de `app.R`, destacando Algoritmo A, las opciones de \u03c3_pt y los criterios de homogeneidad/estabilidad.
- Se alinearon las referencias al proceso de renderizado de informes definido en `reports/report_template.Rmd`, reforzando el uso de parámetros YAML como `pollutant`, `level`, `n_lab`, `k_factor` y `metrological_compatibility_method`.
- Se verificó que las secciones descriptivas mencionan el flujo de cálculo de puntajes z, z', zeta y En disponible en la aplicación Shiny.

## Archivos actualizados
- TECHNICAL_DOCUMENTATION.md
- USER_GUIDE.md
- VALIDATION_GUIDE.md
- app_and_report_documentation.md
- app_documentation.md
- doc_algorithm_a.md
- doc_homo_stab.md
- doc_med_made_niqr.md
- doc_pt_performance_classification.md
- eval_class_instructions.md
- formato_final_ea.md
- informe.md
- informe_EA_V1_content.md
- informe_p1.md
- informe_p2.md
- informe_p3.md
- informe_p45.md
- scores.md
- sop_v_4.md

## Notas sobre datos de ejemplo
- El archivo `input_alg_a.csv` se mantiene sin cambios porque ya coincide con el formato requerido por `get_wide_data()` en `app.R` (columnas `pollutant`, `level`, `replicate`, `sample_id`, `value`).
