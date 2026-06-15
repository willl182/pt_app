# Plan: Bootstrap homogeneidad y estabilidad

**Timestamp:** 260514_2008
**Slug:** bootstrap-homogeneidad-estabilidad
**Estado:** Completado

## Objetivo
Crear un script reproducible que genere datos de homogeneidad y estabilidad
por bootstrap desde archivos minutales de referencia con estructura CALAIRE,
manteniendo el formato esperado por la aplicacion.

## Fases

### Fase 1: Implementacion
| Item | Estado | Notas |
|------|--------|-------|
| Reutilizar lectura y limpieza existentes | Completado | Se usaran funciones en R/preprocessing. |
| Crear script bootstrap nuevo | Completado | Script independiente en scripts/; exige --input explicito. |

### Fase 2: Ejecucion
| Item | Estado | Notas |
|------|--------|-------|
| Generar homogeneidad | Completado | 10 sample_id x 2 replicas por combinacion. |
| Generar estabilidad | Completado | 2 sample_id x 2 replicas por combinacion. |
| Generar registro | Completado | Registro de datasets usados. |

### Fase 3: Validacion
| Item | Estado | Notas |
|------|--------|-------|
| Validar columnas | Completado | Formato pollutant,run,level,replicate,sample_id,value. |
| Validar conteos | Completado | 200 filas homogeneidad, 40 estabilidad, 240 registro para el archivo usado. |

## Log de Ejecucion
- [260514 20:08] Inicio del plan.
- [260514 20:09] Decision: el archivo de entrada no tendra valor por defecto.
- [260514 20:10] Script nuevo creado en scripts/build_bootstrap_homogeneity_stability.R.
- [260514 20:11] Ejecucion con --input=data/raw/datos_ronda_1_r.csv --seed=13528.
- [260514 20:12] Validacion completada: columnas y conteos correctos.
