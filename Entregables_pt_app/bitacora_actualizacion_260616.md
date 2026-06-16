# Bitácora de Actualización de Entregables PT App

**Fecha:** 2026-06-16  
**Plan:** `logs/plans/260616_1047_plan_actualizar-entregables-pt-app.md`  
**Alcance ejecutado:** actualización documental trazable de overviews `e1.md` a `e9.md`, correcciones puntuales en fórmulas de puntajes, exportación de DOCX con pandoc, correcciones funcionales en `ptcalc`, `app.R` y entregables E02/E03/E04/E08/E09, y consolidación de discrepancias.

## Subagentes Designados

| Entregable | Subagente | Estado recomendado |
|------------|-----------|--------------------|
| 01 | `entregable_01_baseline_curator` | Histórico validado |
| 02 | `entregable_02_function_inventory_auditor` | Requiere regeneración |
| 03 | `entregable_03_stat_engine_documenter` | Histórico / requiere alineación con `ptcalc` |
| 04 | `entregable_04_scoring_documenter` | Histórico / parcialmente vigente |
| 05 | `entregable_05_ui_prototype_mapper` | Histórico / prototipo parcial |
| 06 | `entregable_06_shiny_logic_manualist` | Histórico / manual no vigente |
| 07 | `entregable_07_dashboard_evidence_updater` | Parcial / evidencia histórica |
| 08 | `entregable_08_beta_release_documenter` | Histórico / beta no vigente |
| 09 | `entregable_09_validation_report_auditor` | Requiere auditoría de evidencia |

## Matriz de Discrepancias

| Entregable | Discrepancia principal | Acción aplicada |
|------------|------------------------|-----------------|
| 01 | Redacción imprecisa sobre comparación de sintaxis vs hashes. | Se aclaró validación por hash SHA256 y parseo sintáctico. |
| 02 | Inventario de 48 funciones no cubre código vigente completo. | Se marcó como requiere regeneración y se amplió fuente canónica sugerida. |
| 03 | Scripts standalone históricos divergen de `ptcalc/R/`. | Se documentó estado histórico y necesidad de contraste técnico. |
| 04 | Módulo histórico no cubre todo el flujo activo de `app.R`. | Se documentó vigencia parcial y se corrigieron errores Markdown/conceptuales. |
| 05 | Prototipo HTML no refleja la navegación actual. | Se reclasificó como prototipo histórico parcial. |
| 06 | Manual describe versión con datos precargados, no flujo actual. | Se marcó como manual histórico no vigente. |
| 07 | Dashboards históricos no cubren visualizaciones actuales. | Se documentó evidencia parcial e indicación de actualizar flujo. |
| 08 | Beta `app_final.R` no representa `app.R` actual. | Se separó beta histórica de arquitectura vigente. |
| 09 | Referencias externas y anexos requieren confirmación. | Se marcó como requiere auditoría de evidencia. |

## Riesgos Técnicos Detectados

- ~~`app.R` y `ptcalc/R/pt_homogeneity.R` deben revisarse por posible divergencia de firma en `calculate_homogeneity_criterion_expanded()`~~ **RESUELTO:** firma polimórfica implementada en `ptcalc/R/pt_homogeneity.R` (acepta 2 o 3 args).
- Hay dos trayectorias de puntajes: funciones en `ptcalc/R/pt_scores.R` y cálculos inline en `app.R`. Se normalizó la etiqueta `"No satisfactorio"` en `app.R` para consistencia con `ptcalc`.
- Algunos tests de entregables escriben CSV de resultado y dependen del directorio de trabajo.
- Los DOCX se regeneraron con `pandoc` desde los MD actualizados. Los PDF históricos se conservan como evidencia formateada sin regeneración.

## Verificación Recomendada

```r
Rscript -e 'files <- c("app.R", list.files("R", pattern = "\\.R$", recursive = TRUE, full.names = TRUE), list.files("ptcalc/R", pattern = "\\.R$", full.names = TRUE)); ok <- vapply(files, function(f) tryCatch({ parse(f); TRUE }, error = function(e) FALSE), logical(1)); print(data.frame(file = files, parse_ok = ok), row.names = FALSE); stopifnot(all(ok))'
```

```r
Rscript -e 'files <- Sys.glob("Entregables_pt_app/e[1-9].md"); ok <- file.exists(files); print(data.frame(file = files, exists = ok), row.names = FALSE); stopifnot(all(ok))'
```

## DOCX Exportados (pandoc 3.9.0.2)

| Fuente MD | DOCX Generado |
|-----------|---------------|
| `01_repo_inicial/README.md` | `01_repo_inicial/README.docx` |
| `02_funciones_usadas/README.md` | `02_funciones_usadas/README.docx` |
| `02_funciones_usadas/md/documentacion_funciones.md` | `02_funciones_usadas/documentacion_funciones.docx` |
| `03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md` | `03_calculos_pt/ejemplo_calculo_paso_a_paso.docx` |
| `04_puntajes/md/formulas_y_ejemplos.md` | `04_puntajes/formulas_y_ejemplos.docx` |
| `05_prototipo_ui/md/wireframes.md` | `05_prototipo_ui/wireframes.docx` |
| `06_app_logica/md/manual_usuario.md` | `06_app_logica/manual_usuario.docx` |
| `08_beta/md/manual_desarrollador.md` | `08_beta/manual_desarrollador.docx` |
| `09_informe_final/md/informe_validacion.md` | `09_informe_final/informe_validacion.docx` |
| `09_informe_final/md/anexo_calculos.md` | `09_informe_final/anexo_calculos.docx` |
| `01_repo_inicial/tests/test_01_existencia_archivos.md` | `01_repo_inicial/tests/test_01_existencia_archivos.docx` |
| `02_funciones_usadas/tests/test_02_firma_funciones.md` | `02_funciones_usadas/tests/test_02_firma_funciones.docx` |
| `05_prototipo_ui/tests/test_05_navegacion.md` | `05_prototipo_ui/tests/test_05_navegacion.docx` |
| `07_dashboards/tests/test_07_graficos.md` | `07_dashboards/tests/test_07_graficos.docx` |
| `08_beta/tests/test_08_end_to_end.md` | `08_beta/tests/test_08_end_to_end.docx` |

**Nota:** Se corrigió error de sintaxis TeX (`\sqrt{s_{\bar{x}}^2}}` → `\sqrt{s_{\bar{x}}^2}`) en `anexo_calculos.md` antes de la conversión.
