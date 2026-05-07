# Plan: Procesamiento ensayo participante part_1

**Timestamp:** 260506_2117
**Slug:** procesamiento-ensayo-part-1
**Estado:** Completado

## Objetivo

Generar salidas equivalentes a la referencia de ronda para el archivo de ensayo `data/raw/datos_ronda_part.csv`, procesando únicamente el participante `part_1` para pruebas internas. Este flujo debe permanecer separado del preprocesador CALAIRE de referencia.

## Fases

### Fase 1: Diagnóstico
| Item | Estado | Notas |
|------|--------|-------|
| Revisar estructura de `datos_ronda_part.csv` | Completado | Columnas `Date`, `Time`, `CO_p1`, `SO2_p1`, `CO_gen`, `SO2_gen`; 902 filas crudas, 901 tras limpieza |
| Definir nombres de salida | Completado | `h_part_1_ronda.csv` y `part_1_ronda.csv` |

### Fase 2: Implementación
| Item | Estado | Notas |
|------|--------|-------|
| Normalizar columnas participante | Completado | Mapeos `*_p1` agregados para CO, SO2, NO, NO2, O3 |
| Calcular promedios horarios | Completado | Mismo criterio `n >= 45`, nivel 0 = 1 hora, no-cero = 3 horas |
| Consolidar por nivel | Completado | `mean_value`, `sd_value`, `u_value`, `n_hours` |
| Crear pipeline/script | Completado | `run_pipeline_participant_ronda()` + `scripts/preprocesar_part_1.R` |

### Fase 3: Validación y cierre
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar procesamiento | Completado | 26 horas válidas, 10 niveles consolidados |
| Validar parse | Completado | R scripts OK |
| Actualizar logs/commit/push | Pendiente | Saver + git |

## Log de Ejecución
- [260506 21:17] Plan creado.
- [260506 21:20] Implementado pipeline separado para ensayo `part_1`; salidas generadas en `data/processed/h_part_1_ronda.csv` y `data/processed/part_1_ronda.csv`.
