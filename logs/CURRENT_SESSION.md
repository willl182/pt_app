# Session State: PT App - POC GPT53CDX Implementacion

**Last Updated**: 2026-03-30 12:16 (260330_1216)

## Session Objective

Implementar POC GPT53CDX: validacion downstream post-Algoritmo A con comparacion tripartita (APP vs R independiente vs Python) para 15 combinaciones objetivo, guardando todo en `validation/val3/`.

## Current State

- [x] Fase 0: Scaffolding en `validation/val3/`
- [x] Fase 1: Robust Stats - `Val_01_Robust_Stats.xlsx` generado
- [x] Fase 2: Homogeneity - `Val_02_Homogeneity.xlsx` generado
- [x] Fase 3: Stability - `Val_03_Stability.xlsx` generado
- [x] Fase 4: Uncertainties - `Val_04_Uncertainties.xlsx` generado
- [x] Fase 5: Scores - `Val_05_Scores.xlsx` generado
- [x] Fase 6: Python (stdlib puro) genera `poc_gpt53cdx_py_results.csv`
- [x] Fase 6: Merge Python en R via `--mode merge_py`
- [x] Master CSV: `poc_gpt53cdx_master.csv` (7665 rows)
- [x] Runlog: `poc_gpt53cdx_runlog.md`
- [x] Plan actualizado: `poc_gpt53cdx.md` con estado por fase
- [ ] **Fase 7: Resolver ~4446 FAIL** (58%). Diagnostico requerido.

## Critical Technical Context

- **Directorio de salida**: `validation/val3/` (NO `validation/poc_gpt53cdx/`)
- **Python sin dependencias**: solo stdlib (csv, math, collections). Sin numpy/pandas.
- **Workbook**: se usa `openxlsx` (NO `openxlsx2`): `createWorkbook()`, `addWorksheet()`, `writeDataTable()`, `saveWorkbook()`.
- **Columnas master**: `combo_id, pollutant, level, section, participant_id, metric, app_value, r_value, excel_value, py_value, diff_app_r, diff_app_excel, diff_app_py, diff_r_excel, diff_r_py, status, tolerance`
- **Tolerancias**: `TOL_STRICT=1e-12`, `TOL_LOOSE=1e-9`, `TOL_ALGO=1e-6`
- **Flujo de ejecucion**:
  1. `Rscript validation/val3/poc_gpt53cdx_val.R --mode app_r_excel`
  2. `python3 validation/val3/poc_gpt53cdx_val.py`
  3. `Rscript validation/val3/poc_gpt53cdx_val.R --mode merge_py`

## Resultados actuales (requieren diagnostico)

```
Total: 7665 | PASS: 3219 (42%) | FAIL: 4446 (58%)

robust_stats  : 480 total, 123 PASS, 357 FAIL
homogeneity   : 195 total,  77 PASS, 118 FAIL
stability     :  90 total,  22 PASS,  68 FAIL
uncertainties : 1140 total, 58 PASS, 1082 FAIL
scores        : 5760 total, 2939 PASS, 2821 FAIL
```

Sospechas principales:
1. Diferencias quantile type-7 R vs Python linear interpolation
2. Propagacion de esas diferencias a incertidumbres y puntajes
3. Niveles 0 (sigma_pt ~ 0) no clasificados como NA_EXPECTED
4. Tolerancia 1e-12 posiblemente demasiado estricta para comparar R vs Python

## Next Steps

1. Diagnosticar FALLAS en robust_stats: comparar valores APP vs Python directamente
2. Verificar si tolerancia 1e-12 es demasiado estricta para comparacion R vs Python
3. Implementar clasificacion NA_EXPECTED para niveles 0
4. Ajustar tolerancias por seccion segun naturaleza del calculo
5. Re-ejecutar pipeline completo y verificar conformidad
