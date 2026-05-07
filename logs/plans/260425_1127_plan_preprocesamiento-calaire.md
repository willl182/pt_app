# Plan: Preprocesamiento CALAIRE como módulo interno de pt_app

**Created**: 2026-04-24 16:24
**Updated**: 2026-04-25 11:27
**Status**: in_progress
**Slug**: preprocesamiento-calaire

## Objetivo

Convertir archivos minutales crudos CALAIRE en insumos de referencia listos para
análisis de ronda, homogeneidad, estabilidad e incertidumbre (ISO 13528). El
preprocesamiento CALAIRE no procesa datos de participantes.

## Fases

### Fase 1: Infraestructura y metadatos ✅

| # | Archivo | Estado | Notas |
|---|---------|--------|-------|
| 1.1 | `data/raw/datos_estabilidad_homogeneidad.csv` | ✅ | Copiado desde raíz |
| 1.2 | `data/raw/datos_ronda.csv` | ✅ | Copiado desde raíz |
| 1.3 | `data/metadata/niveles_calaire.csv` | ✅ | CO en ppm (no ppb), niveles reales |
| 1.4 | `data/metadata/diseno_estabilidad_homogeneidad.csv` | ✅ | 12 bloques abril 22-23 |

### Fase 2: Módulos R — estabilidad/homogeneidad ✅

| # | Archivo | Estado | Notas |
|---|---------|--------|-------|
| 2.1 | `R/preprocessing/read_calaire_raw.R` | ✅ | CSV sep=;, separa header/units |
| 2.2 | `R/preprocessing/clean_calaire_raw.R` | ✅ | Normalización, NA, timestamps |
| 2.3 | `R/preprocessing/hourly_averages.R` | ✅ | mean/sd/u, hora válida con `n >= 45` (75%) |
| 2.4 | `R/preprocessing/moving_hourly_means.R` | ✅ | 60 MMs por bloque |
| 2.5 | `R/preprocessing/uncertainty_report.R` | ✅ | incertidumbre.md |
| 2.6 | `R/preprocessing/validation.R` | ✅ | 12 checks PASS/WARN/FAIL |
| 2.7 | `R/preprocessing/pipeline_calaire.R` | ✅ | Orquestador |
| 2.8 | `scripts/preprocesar_calaire.R` | ✅ | Entry point único |

### Fase 3: Referencia de ronda ✅

| # | Archivo | Estado | Notas |
|---|---------|--------|-------|
| 3.1 | `data/raw/datos_ronda.csv` | ✅ | Entrada minutal de referencia con columnas `*_ref` y `*_gen`; sin fila de unidades |
| 3.2 | `R/preprocessing/read_calaire_raw.R` | ✅ | Lee archivos con o sin fila de unidades |
| 3.3 | `R/preprocessing/clean_calaire_raw.R` | ✅ | Mapea `CO_ref`, `SO2_ref`, `CO_gen`, `SO2_gen`; preparado para NO, NO2, O3 |
| 3.4 | `R/preprocessing/hourly_averages.R` | ✅ | Ronda solo referencia CALAIRE; horas con `n >= 45`; máximo 3 horas por nivel no-cero y 1 para nivel 0 |
| 3.5 | `R/preprocessing/pipeline_calaire.R` | ✅ | Genera `h_referencia_ronda.csv` y `referencia_ronda.csv` |

### Fase 4: Integración con ptcalc ⬜

| # | Tarea | Estado | Notas |
|---|-------|--------|-------|
| 4.1 | Conectar `h_estabilidad_homogeneidad.csv` con módulo homogeneidad | ⬜ | Ver instruccion.md |
| 4.2 | Conectar `mm_estabilidad_homogeneidad.csv` con módulo estabilidad | ⬜ | |
| 4.3 | Reemplazar `u_i` sintéticos en `uncertainty_n13.csv` | ⬜ | Fuera del preprocesador CALAIRE; requiere datos reales del lab |

## Log de Ejecución

- [x] Decidido ubicar preprocesamiento en `pt_app` como módulo interno
- [x] Trabajo previo descartado completamente (era XLSX-based, con unidades erróneas)
- [x] Metadatos definidos con niveles reales de los datos de abril
- [x] Pipeline ejecutado: 19 PASS, 0 WARN, 0 FAIL
- [x] Salidas: 22 horas válidas, 600 ventanas MM válidas
- [x] Diseño para datos de ronda replanteado: solo referencia CALAIRE, no participantes
- [x] Criterio de hora válida actualizado a 75% (`n >= 45`) para ronda, estabilidad y homogeneidad
- [x] Ronda genera 26 horas válidas; `2.8-ppm`/`80-ppb` recuperan tercera hora parcial con `n = 57`; `1.4-ppm`/`40-ppb` conservan las primeras 3 horas
- [x] Salidas de ronda: `data/processed/h_referencia_ronda.csv`, `data/processed/referencia_ronda.csv`
- [ ] Integración con ptcalc
