# Plan: Preprocesamiento raw Ronda 3

**Created**: 2026-07-26 12:50
**Updated**: 2026-07-26 12:50
**Status**: completed
**Slug**: preprocesamiento-r3

## Objetivo

Procesar archivos raw R3 mediante runtime acumulado, evaluar capacidad horaria y generar promedios y resúmenes compatibles con flujo existente.

## Fases

### Fase 1: Lectura y normalización

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 1.1 | `R/preprocessing/hourly_averages.R` | Modificar | Añadir `read_raw_round_file()` |

### Fase 2: Assessment y cálculo

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 2.1 | `R/preprocessing/hourly_averages.R` | Modificar | Añadir assessment, cálculo runtime y wrapper |

### Fase 3: Integración y pruebas

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 3.1 | `data_use_cases/scripts/preprocess_r3.R` | Crear | Runner y salidas CSV |
| 3.2 | `tests/testthat/test-hourly-runtime.R` | Crear | Casos sintéticos y compatibilidad |

## Log de Ejecución

- [x] Fase 1 iniciada
- [x] Fase 1 completada
- [x] Fase 2 iniciada
- [x] Fase 2 completada
- [x] Fase 3 iniciada
- [x] Fase 3 completada
- [x] Tests nuevos: 30 PASS
- [x] Suite completa: 356 PASS, 11 SKIP
