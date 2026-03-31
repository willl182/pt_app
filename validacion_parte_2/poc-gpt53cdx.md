# Plan: POC GPT53CDX - Validacion Downstream Post-Algoritmo A

**Created**: 2026-03-30 11:18
**Updated**: 2026-03-30 12:16
**Status**: in_progress
**Slug**: poc-gpt53cdx

## Objetivo

Validacion reproducible de toda la cadena downstream al Algoritmo A comparando APP, R independiente y Python para 15 combinaciones (5 contaminantes x 3 niveles).

## Fases

### Fase 0: Scaffolding [DONE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 0.1 | `validation/val3/` | Crear dir | Directorio de salida |
| 0.2 | `poc_gpt53cdx_val.R` | Crear | Script R con constantes, combos, loaders |
| 0.3 | `poc_gpt53cdx_val.py` | Crear | Python stdlib puro |

### Fase 1: Robust Stats [DONE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 1.1 | `Val_01_Robust_Stats.xlsx` | Generar | 15 hojas + INDICE + RESUMEN |

### Fase 2: Homogeneity [DONE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 2.1 | `Val_02_Homogeneity.xlsx` | Generar | Criterio simple + expandido |

### Fase 3: Stability [DONE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 3.1 | `Val_03_Stability.xlsx` | Generar | u_stab = d_max/sqrt(3) |

### Fase 4: Uncertainties [DONE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 4.1 | `Val_04_Uncertainties.xlsx` | Generar | 4 metodos x 15 combos |

### Fase 5: Scores [DONE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 5.1 | `Val_05_Scores.xlsx` | Generar | z/z'/zeta/En + evaluaciones |

### Fase 6: Integracion Python [DONE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 6.1 | `poc_gpt53cdx_py_results.csv` | Generar | 7665 rows, stdlib puro |
| 6.2 | master merge | Ejecutar | `--mode merge_py` |

### Fase 7: Consolidacion [PENDIENTE]

| # | Archivo | Accion | Notas |
|---|---------|--------|-------|
| 7.1 | diagnostico FAILs | Analizar | 4446 FAILs, tolerancias, NA_EXPECTED |
| 7.2 | ajuste tolerancias | Modificar | Segun diagnostico por seccion |
| 7.3 | re-ejecucion | Ejecutar | Pipeline completo |
| 7.4 | verificacion final | Validar | Conformidad o justificacion explicita |

## Log de Ejecucion

- [x] 2026-03-30 12:09 Fase 0-6 completadas, artefactos generados
- [x] 2026-03-30 12:16 Plan actualizado en poc_gpt53cdx.md con estado detallado
- [ ] Fase 7 pendiente: diagnostico de 4446 FAILs
