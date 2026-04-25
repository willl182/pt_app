# Plan: Preprocesamiento CALAIRE como módulo interno de pt_app

**Created**: 2026-04-24 16:24
**Updated**: 2026-04-25 11:27
**Status**: in_progress
**Slug**: preprocesamiento-calaire

## Objetivo

Convertir archivos minutales crudos CALAIRE en insumos listos para análisis de
ronda, homogeneidad, estabilidad e incertidumbre (ISO 13528).

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
| 2.3 | `R/preprocessing/hourly_averages.R` | ✅ | mean/sd/u, validación n=60 |
| 2.4 | `R/preprocessing/moving_hourly_means.R` | ✅ | 60 MMs por bloque |
| 2.5 | `R/preprocessing/uncertainty_report.R` | ✅ | incertidumbre.md |
| 2.6 | `R/preprocessing/validation.R` | ✅ | 12 checks PASS/WARN/FAIL |
| 2.7 | `R/preprocessing/pipeline_calaire.R` | ✅ | Orquestador |
| 2.8 | `scripts/preprocesar_calaire.R` | ✅ | Entry point único |

### Fase 3: Datos de ronda ⬜

| # | Archivo | Estado | Notas |
|---|---------|--------|-------|
| 3.1 | `data/metadata/diseno_ronda.csv` | ⬜ | Definir diseño por participante/nivel |
| 3.2 | Extender `pipeline_calaire.R` | ⬜ | Procesar datos_ronda.csv → h_datos_ronda.csv |

### Fase 4: Integración con ptcalc ⬜

| # | Tarea | Estado | Notas |
|---|-------|--------|-------|
| 4.1 | Conectar `h_estabilidad_homogeneidad.csv` con módulo homogeneidad | ⬜ | Ver instruccion.md |
| 4.2 | Conectar `mm_estabilidad_homogeneidad.csv` con módulo estabilidad | ⬜ | |
| 4.3 | Reemplazar `u_i` sintéticos en `uncertainty_n13.csv` | ⬜ | Requiere datos reales del lab |

## Log de Ejecución

- [x] Decidido ubicar preprocesamiento en `pt_app` como módulo interno
- [x] Trabajo previo descartado completamente (era XLSX-based, con unidades erróneas)
- [x] Metadatos definidos con niveles reales de los datos de abril
- [x] Pipeline ejecutado: 19 PASS, 0 WARN, 0 FAIL
- [x] Salidas: 22 horas válidas, 600 ventanas MM válidas
- [ ] Diseño para datos de ronda
- [ ] Integración con ptcalc
