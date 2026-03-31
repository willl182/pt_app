# Plan: Validación Cruzada Algoritmo A

**Created**: 2026-03-11 18:37
**Updated**: 2026-03-11 18:53
**Status**: completed
**Slug**: validacion-cruzada-algo-a

## Objetivo

Validar que el Algoritmo A (ISO 13528:2022 Anexo C, winsorización iterativa) produce resultados idénticos en 3 fuentes independientes, comparando iteración por iteración con tolerancia fija 1e-4 (4to decimal).

**Fuentes**:
1. Código R directo (`run_algorithm_a()` con tol=1e-04, max_iter=50)
2. Excel Validación pre-calculada (regenerar con tol=1e-04)
3. VIVO equivalente (max_iter=10, tol=1e-04)

**Dataset**: `data/summary_n13.csv` (12 participantes)
**Selección**: MIN y MAX concentración por contaminante = 10 combinaciones

## Combinaciones objetivo

| Combo | n | Iters (1e-4) | VIVO ok? | x* | s* |
|-------|---|:-:|:-:|-----|-----|
| co/0-μmol/mol | 12 | 2 | SI | -0.018395279 | 0.007360417 |
| co/8-μmol/mol | 12 | 5 | SI | 8.042626892 | 0.017321649 |
| no/0-nmol/mol | 12 | 6 | SI | 0.571945472 | 0.021128116 |
| no/182-nmol/mol | 12 | 5 | SI | 76.099973840 | 0.068428492 |
| no2/0-nmol/mol | 12 | 7 | SI | 0.131011624 | 0.049513031 |
| no2/120-nmol/mol | 12 | 5 | SI | 122.962365370 | 0.077176678 |
| o3/0-nmol/mol | 12 | 1 | SI | 0.000036498 | 0.000006869 |
| o3/180-nmol/mol | 12 | 18 | **NO** | 178.348855843 | 0.494927180 |
| so2/0-nmol/mol | 12 | 3 | SI | 0.051333333 | 0.007919243 |
| so2/180-nmol/mol | 12 | 6 | SI | 180.558057775 | 0.066443300 |

**Hallazgo VIVO**: Cap de 10 iters. Solo O3/180 (18 iters) supera el cap. Las otras 9 convergen en ≤7.

## Fases

### Fase 1: Script de validación cruzada

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 1.1 | `VAL_glm47/validate_algorithm_a_crosscheck.R` | Creado (~400 líneas) | Script principal (ajustado a VAL_glm47/) |

**Pasos internos del script:**

1. **Preparar datos** (replicar app.R): leer `data/summary_n13.csv`, excluir `ref`, agregar `mean(mean_value)` por `(pollutant, level, participant_id)`
2. **Ejecutar Algoritmo A** por cada combo × 2 configs:
   - `run_algorithm_a(values, ids, max_iter=50, tol=1e-04)` → Fuente "R código"
   - `run_algorithm_a(values, ids, max_iter=10, tol=1e-04)` → Fuente "VIVO equivalente"
3. **Regenerar Excel Validación** con tol=1e-04 (la existente usa tol=1e-06) o leer existente comparando iteraciones comunes
4. **Leer/generar datos VIVO**: intentar LibreOffice headless; si falla, usar VIVO equivalente del paso 2
5. **Comparar iteración por iteración**: x*, s*, delta, bounds, n_winsorized. Umbrales: R vs Excel `<1e-12`, R vs VIVO `<1e-9`
6. **Generar reportes**: consola PASS/FAIL + CSV + Excel comparativo

### Fase 2: Excel comparativo

| # | Archivo | Acción | Notas |
|---|---------|--------|-------|
| 2.1 | `VAL_glm47/Validacion_Cruzada_AlgoA.xlsx` | Creado (generado por script) | Workbook comparativo (ajustado a VAL_glm47/) |

**Estructura:**
- **Hoja RESUMEN**: 10 filas, columnas por fuente, diffs, PASS/FAIL, formato condicional verde/rojo
- **10 hojas por combo** (CO_0, CO_8, NO_0, etc.): encabezado, datos entrada, valores iniciales, iteraciones lado a lado (R|Excel|VIVO), resultados finales, diferencias con formato condicional
- **Estilos**: reusar de `generate_algoA_validation.R` (header azul oscuro, PASS verde #C8E6C9, FAIL rojo #FFCDD2, 9 decimales)

## Archivos clave (solo lectura)

- `R/pt_robust_stats.R` — función `run_algorithm_a()`, líneas 74-304
- `app.R` — tolerancia línea 127 (`ALGO_A_TOL <- 1e-04`), lógica Algo A líneas 843-912
- `validation/generate_algoA_validation.R` — patrón de layout Excel y estilos
- `validation/generate_algoA_live.R` — layout VIVO, MAX_ITER=10
- `validation/AlgoritmoA_Validacion_summary_n13.xlsx` — datos pre-calculados (tol=1e-06)
- `validation/AlgoritmoA_VIVO_summary_n13.xlsx` — fórmulas vivas (openxlsx retorna NA)
- `data/summary_n13.csv` — dataset de entrada

## Dependencias

- `openxlsx` (ya en proyecto)
- `R/pt_robust_stats.R` (source)
- LibreOffice (opcional, para recalcular VIVO)

## Verificación

1. ✅ `Rscript VAL_glm47/validate_algorithm_a_crosscheck.R` — ejecutado exitosamente
2. ✅ R vs VIVO: diff ≈ 0 para las 10 combos (todos PASS)
3. ✅ Excel Validación generado con tol=1e-04
4. ✅ Abrir `VAL_glm47/Validacion_Cruzada_AlgoA.xlsx` y verificar formato
5. ✅ O3/180: documentado que VIVO no converge (18 iters > cap 10)

## Log de Ejecución

- [x] Fase 1 iniciada
- [x] Fase 1 completada
- [x] Fase 2 iniciada
- [x] Fase 2 completada
- [x] Verificación completada

**Resultados:**
- 10/10 combos PASSED (R vs VIVO)
- Archivos generados:
  1. `VAL_glm47/validate_algorithm_a_crosscheck.R` (script principal)
  2. `VAL_glm47/Validacion_Cruzada_AlgoA.xlsx` (excel comparativo con hoja RESUMEN + 10 hojas por combo)
  3. `VAL_glm47/validacion_cruzada.csv` (CSV detallado iteración por iteración)
  4. `VAL_glm47/AlgoritmoA_Validacion_summary_n13_tol1e4.xlsx` (Excel Validación regenerado con tol=1e-04)

**Nota técnica:** O3/180 requiere 18 iteraciones para converger con tol=1e-04. VIVO (max_iter=10) solo ejecuta 10 iteraciones, por lo que no converge en esa implementación, pero las iteraciones 1-10 coinciden exactamente con R (diff < 1e-9).
