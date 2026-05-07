# Plan: Integración referencia CALAIRE en app y análisis

**Timestamp:** 260506_2108
**Slug:** integracion-referencia-calaire-app
**Estado:** Completado

## Objetivo

Integrar las salidas del preprocesador CALAIRE de referencia en la interfaz Shiny (`app.R`) y en el flujo de análisis principal, de modo que la app pueda usar `data/processed/referencia_ronda.csv` como fuente de valores asignados/incertidumbres de referencia sin procesar datos de participantes dentro del preprocesador.

## Fases

### Fase 1: Diagnóstico
| Item | Estado | Notas |
|------|--------|-------|
| Revisar `app.R` | Completado | Identificada carga `pt_prep_data()`, pestaña Valor asignado y cálculo `compute_scores_for_selection()` |
| Revisar funciones `ptcalc`/helpers | Completado | Los scores reciben `x_pt`, `sigma_pt`, `u_xpt`; la fuente del valor asignado se orquesta en app/server |
| Definir punto de integración | Completado | UI de carga + reactivo CALAIRE + reemplazo de `ref` + uso de `u_value` como `u_xpt` |

### Fase 2: Implementación UI/Server
| Item | Estado | Notas |
|------|--------|-------|
| Cargar referencia CALAIRE procesada | Completado | Reactivo `calaire_reference_df()` lee `data/processed/referencia_ronda.csv` |
| Agregar control en interfaz | Completado | Checkbox `use_calaire_reference` en Carga de datos |
| Mostrar vista de referencia | Completado | Tablas consolidada y horaria en pestaña Valor de referencia |

### Fase 3: Integración análisis
| Item | Estado | Notas |
|------|--------|-------|
| Mapear referencia a valores asignados | Completado | `mean_value` reemplaza `ref`; `u_value` se usa como `u_xpt` del método referencia cuando hay coincidencia exacta |
| Conectar al cálculo de scores | Completado | `pt_prep_data()` reemplaza filas `participant_id == "ref"`; `compute_scores_for_selection()` toma `u_xpt` CALAIRE |
| Validar parse/ejecución | Completado | `parse(file = "app.R")` OK; pipeline CALAIRE OK; tests no ejecutables porque falta paquete `testthat` |

### Fase 4: Documentación y cierre
| Item | Estado | Notas |
|------|--------|-------|
| Actualizar logs | Completado | `CURRENT_SESSION.md` e histórico `260506_2112_findings.md` |
| Commit y push | Pendiente | Cerrar integración |

## Log de Ejecución
- [260506 21:08] Plan creado.
- [260506 21:18] Implementada integración en `app.R`: checkbox de uso, lectura de referencia CALAIRE, tablas de auditoría y conexión con cálculo de puntajes por referencia.
- [260506 21:19] Validación: parse de `app.R` y módulos preprocessing OK; `Rscript scripts/preprocesar_calaire.R` OK; `testthat::test_dir()` no ejecutó por dependencia ausente (`testthat`).
- [260506 21:12] Logs persistidos con saver; pendiente commit/push.
