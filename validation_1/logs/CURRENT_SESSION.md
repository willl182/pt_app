# Session State: validation_1

**Last Updated**: 2026-05-13 06:08 America/Bogota

## Session Objective

Completar la fase 8 del plan de validacion con el informe formal de O3 × 3
niveles.

## Current State

- [x] Se implemento la etapa 01 de estadisticos robustos.
- [x] Se reestructuro la etapa 02 para usar rutas locales en `validation_1`.
- [x] Se reestructuro la etapa 03 para usar rutas locales en `validation_1`.
- [x] Se copio `helpers.R` y `helpers.py` al subarbol para evitar dependencias externas.
- [x] Se ejecutaron las etapas 02 y 03 en Python con salidas en `outputs/`.
- [x] Se ejecutaron las etapas 03 en R y Python con salidas en `outputs/`.
- [x] Se reestructuro la etapa 04 para usar rutas locales en `validation_1`.
- [x] Se ejecutaron las etapas 04 en R y Python con salidas en `outputs/`.
- [x] Se verifico que la etapa 4 genera `stage_04_uncertainty_chain*.csv` y su reporte.
- [x] Se migro la etapa 5 a rutas locales dentro de `validation_1`.
- [x] Se corrigio el lector de Python para asociar cada fila R con su `metric` real y no sobreescribir scores numericos con `*_eval`.
- [x] Se ejecutaron las etapas 5 en R y Python con salidas en `outputs/`.
- [x] Se verifico que la etapa 5 genera `stage_05_scores*.csv` y su reporte con `1152 PASS / 0 FAIL`.
- [x] Se dejo persistencia de estado y hallazgos con `saver`.
- [x] Se implemento la fase 6 con trazas detalladas del Algoritmo A en R y Python.
- [x] Se generaron `stage_04b_algorithm_a_iterations*.csv` y su reporte.
- [x] Se agrego la fila `initial` a la traza para conservar la semilla del algoritmo.
- [x] Se documento la fase 7 en `validation/excel/formulas_por_etapa.md`.
- [x] Se genero la plantilla base `validation/excel/plantilla_base.xlsx`.
- [x] Se generaron las 18 hojas Excel de la fase 7.
- [x] Se implemento la fase 8 con `validation/informe_validacion_o3.md`.
- [x] Se actualizaron `plan_codex.md` y `TODO_validacion.md` para marcar la
  fase 8 como completa.
- [x] Se regeneraron las etapas 01 a 05 en R desde `validation_1/`.
- [x] Se ejecuto `validation_1/stage_04b_algorithm_a_iterations.R` para
  mantener la traza canonica del Algoritmo A.
- [x] Se regenero `validation_1/validation/informe_validacion_o3.md`.

## Critical Technical Context

- El alcance actual es solo O3 en tres niveles: `O3_0`, `O3_80`, `O3_180`.
- La etapa 01 excluye `participant_id == "ref"`.
- La etapa 02 usa `../data/homogeneity_n13.csv` y pivota a matriz `g x m`.
- La etapa 03 usa `../data/stability_n13.csv` y lee `outputs/stage_02_homogeneity_py.csv`.
- La etapa 04 usa `../data/summary_n13.csv` y consume `outputs/stage_02_homogeneity_r.csv` y `outputs/stage_03_stability_r.csv`.
- La etapa 04 en R y Python debe ejecutarse desde `validation_1` y usa rutas locales.
- La etapa 05 usa `../data/summary_n13.csv`, `../data/pt_data_n13.csv` y `outputs/stage_04_uncertainty_chain.csv`.
- La etapa 05 valida 8 metricas por fila: `z_score`, `z_score_eval`, `z_prime_score`, `z_prime_score_eval`, `zeta_score`, `zeta_score_eval`, `En_score`, `En_score_eval`.
- La etapa 05 en R escribe un CSV largo compatible con el lector de Python.
- El lector de Python debe usar `row["metric"]` como clave al cargar `outputs/stage_05_scores_r.csv`; de lo contrario se pisan los valores numericos con las filas `*_eval`.
- Los artefactos de la etapa 05 quedan en `outputs/stage_05_scores_r.csv`, `outputs/stage_05_scores_py.csv`, `outputs/stage_05_scores.csv` y `outputs/stage_05_scores_report.md`.
- `MADe = 1.483 * MAD`.
- `nIQR = 0.7413 * IQR` con cuartiles `type = 7`.
- La fase 6 ahora registra la iteracion `0` (`initial`) y la iteracion de convergencia
  para cada combo O3.
- La fase 7 quedo materializada en 18 archivos `.xlsx`:
  `E{1-5}_{...}_o3_{0|80|180}.xlsx`.

## Next Steps

1. Revisar visualmente `validation_1/validation/informe_validacion_o3.md` si se quiere
   inspeccion humana adicional.
