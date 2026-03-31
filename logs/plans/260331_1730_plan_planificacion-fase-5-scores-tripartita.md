# Plan: Planificación de Fase 5 - Scores de Desempeño Tripartita

**Timestamp:** 260331_1730
**Slug:** planificacion-fase-5-scores-tripartita
**Estado:** Completado

## Objetivo
Implementar y cerrar la Etapa 5 (scores de desempeño) con comparación
tripartita entre la lógica efectiva de la app, una implementación
independiente en R y una implementación independiente en Python, generando
salida canónica final y reporte auditable sin filas en estado `FAIL`.

## Fases

### Fase 1: Diseño técnico y contrato de Etapa 5
| Item | Estado | Notas |
|------|--------|-------|
| Confirmar insumos de entrada desde Stage 04 | Completado | Se consume `validation/outputs/stage_04_uncertainty_chain.csv` como fuente para `x_pt_method`, `sigma_pt_method`, `u_xpt`, `u_xpt_def`, `u_hom`, `u_stab` y `m`. |
| Definir contrato de métricas de scores por combinación | Completado | Definidas 20 métricas numéricas por participante y método (`z`, `z_prime`, `zeta`, `en` + denominadores y componentes de incertidumbre). |
| Definir reglas de clasificación y casos especiales | Completado | Clasificación implementada con `PASS`/`FAIL`/`EDGE_CASE`/`KNOWN_DISCREPANCY`, tolerancia `1e-9` y política de propagación de discrepancia conocida desde Stage 02/04. |

### Fase 2: Implementación Stage 05 en R y Python
| Item | Estado | Notas |
|------|--------|-------|
| Implementar `validation/stage_05_scores.R` | Completado | Placeholder reemplazado por cálculo completo, merge tripartito, salida canónica y reporte Markdown de etapa. |
| Implementar `validation/stage_05_scores.py` | Completado | Placeholder reemplazado por implementación independiente equivalente para generar `stage_05_python_values.csv`. |
| Integrar Stage 05 en orquestadores | Completado | `validation/run_validation_all.R` y `validation/run_validation_all.py` ejecutan ahora Stages 01-05 en secuencia. |

### Fase 3: Validación de cierre y documentación final
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar Stage 05 standalone en R y Python | Completado | Ejecutado `Rscript validation/stage_05_scores.R` con generación de CSV + reporte + valores Python. |
| Ejecutar pipeline completo downstream (Stages 01-05) | Completado | `Rscript validation/run_validation_all.R` y `python3 validation/run_validation_all.py` ejecutados sin error. |
| Documentar resultados y cerrar validación downstream | Completado | Actualizados `validation/TODO_validacion.md`, `logs/CURRENT_SESSION.md` y este plan de fase. |

## Log de Ejecución
- [260331 17:30] Plan de Fase 5 creado con base en el estado de sesión y el pendiente explícito de `stage_05_scores`.
- [260331 17:30] Se define alcance técnico: scores `z`, `z_prime`, `zeta` y `en` con comparación tripartita y salida canónica.
- [260331 17:30] Se deja secuencia operativa de implementación, integración y cierre para completar validación downstream.
- [260331 17:37] Implementados `validation/stage_05_scores.R` y `validation/stage_05_scores.py`, con 20 métricas por participante/método.
- [260331 17:37] Integración en orquestadores completada; pipeline 01-05 validado en R y Python.
- [260331 17:37] Resultado Stage 05: `PASS = 9504`, `KNOWN_DISCREPANCY = 1296`, `FAIL = 0`.
