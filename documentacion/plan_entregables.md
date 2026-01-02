# Plan detallado de entregables (actualizado)

Lineamientos generales:
- Todas las validaciones se ejecutan en R (no se usan herramientas en Python).
- Para cada entregable se crea un subdirectorio en `/deliverables` copiando (no moviendo) los archivos necesarios de `app.R`, `reports/report_template.Rmd` (plantilla disponible en el repositorio) y `/data`.
- Cada subdirectorio debe incluir `logs/` para evidencias de validación y, cuando aplique, `docs/` para soportes gráficos.

## 1) Repositorio de código y scripts iniciales
- **Contenido previsto:** Copia de `app.R`, `reports/report_template.Rmd` y los datasets mínimos de `/data`.
- **Documentación:** `README.md` con dependencias y comandos R básicos.
- **Validación en R:** `sessionInfo()` y carga de scripts con `Rscript -e "source('app.R')"`; registrar salida en `logs/validacion_repositorio.txt`.

## 2) Listado de funciones desarrolladas y plan de validación (app.R y plantilla Rmd)
- **Contenido previsto:** Inventario de todas las funciones declaradas en `app.R` y en `reports/report_template.Rmd` (antiguo `template_report.Rmd`), con descripción breve y dependencias.
- **Funciones identificadas en `app.R`:**
  - `calculate_niqr`, `server`, `format_num`, `get_scores_result`, `combine_scores_result`, `get_wide_data`, `compute_homogeneity_metrics`, `compute_stability_metrics`, `compute_scores_metrics`, `run_algorithm_a`, `ensure_classification_columns`, `score_eval_z`, `classify_with_en`, `compute_combo_scores`, `plot_scores`, `compute_scores_for_selection`, `normalize_n`, `get_global_summary_row`, `get_global_overview_data`, `get_combo_levels_order`, `render_global_score_heatmap`, `render_global_classification_heatmap`, `calculate_method_scores_df`, `summarize_scores`, `count_eval`, `create_combo_plot`, `algo_key`.
  - Nota: `run_algorithm_a` aparece en dos secciones (uso general y módulo específico); se debe documentar ambas versiones si difieren.
- **Funciones identificadas en `reports/report_template.Rmd`:** `calculate_niqr`, `get_wide_data`, `run_algorithm_a`, `compute_homogeneity`.
- **Documentación:** `FUNCIONES_LISTADO.md` con firma, propósito, supuestos de entrada/salida, y ubicación de cada función.
- **Plan de validación en R:**
  1. Ejecutar `Rscript -e "source('app.R')"` para confirmar que todas las funciones se cargan sin errores.
  2. Renderizar la plantilla con `Rscript -e "rmarkdown::render('reports/report_template.Rmd', params = list(summary_data = data.frame(), hom_data = data.frame(), stab_data = data.frame()), envir = new.env())"` para verificar la existencia y uso de funciones en el documento.
  3. Crear `validar_funciones.R` con pruebas unitarias mínimas (por ejemplo, entradas simuladas para `calculate_niqr`, `run_algorithm_a`, `compute_homogeneity_metrics`) y guardar los resultados en `logs/validacion_funciones.txt`.
  4. Documentar cualquier discrepancia o función duplicada (p.ej., doble definición de `run_algorithm_a`) en `FUNCIONES_LISTADO.md`.

## 3) Funciones R para cálculos de estadísticos robustos
- **Contenido previsto:** `estadisticos_robustos.R` con ref, made, niqr, algoritmo A, z, z-prime, zeta y en scores.
- **Documentación:** `ESTADISTICOS_ROBUSTOS.md` con fórmulas y ejemplos.
- **Validación en R:** `validar_robustos.R` con datos sintéticos/reales; registrar en `logs/validacion_robustos.txt`.

## 4) Módulo de cálculo de puntajes y plantilla R Markdown
- **Contenido previsto:** `modulo_puntajes.R` y `plantilla_puntajes.Rmd` adaptada.
- **Documentación:** `MODULO_PUNTAJES.md` con flujos de entrada/salida.
- **Validación en R:** `validar_puntajes.R` que ejecute el módulo y renderice la plantilla; guardar outputs y logs.

## 5) Prototipo estático de la interfaz de usuario
- **Contenido previsto:** `ui_prototipo.R` con la maqueta de UI Shiny.
- **Documentación:** `UI_PROTOTIPO.md` con capturas esperadas.
- **Validación en R:** `shiny::runApp('ui_prototipo', display.mode = 'showcase')` y verificación visual/manual.

## 6) Aplicación con lógica de negocio funcional (sin gráficos)
- **Contenido previsto:** Shiny con server y lógica de cálculo operativa; UI mínima.
- **Documentación:** `LOGICA_NEGOCIO.md` sobre endpoints reactivos y flujos.
- **Validación en R:** `validar_logica.R` con `testServer` o scripts de interacción registrando resultados.

## 7) Dashboards con gráficos dinámicos integrados
- **Contenido previsto:** Módulos de gráficos reactivos (ggplot/plotly) integrados en Shiny.
- **Documentación:** `DASHBOARDS.md` con lista de gráficos, filtros y eventos.
- **Validación en R:** `validar_dashboards.R` con casos de interacción y capturas automáticas cuando aplique.

## 8) Versión beta del aplicativo y documentación final
- **Contenido previsto:** App completa (UI + lógica + dashboards) empaquetada; manual de usuario y técnico.
- **Documentación:** `DOCUMENTACION_FINAL.md` y `MANUAL_USUARIO.md`.
- **Validación en R:** `validar_beta.R` consolidando pruebas anteriores y registrando logs.

## 9) Informe de validación de cálculos, procesos e informe de resultados
- **Contenido previsto:** `informe_validacion.Rmd` con los resultados de todas las validaciones.
- **Documentación:** `INFORME_VALIDACION.md` junto a la versión renderizada.
- **Validación en R:** Render con `rmarkdown::render('informe_validacion.Rmd')` e inclusión de tablas comparativas y logs.
