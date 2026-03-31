# Plan de Implementación: Validación Post-Algoritmo A (A1 + A2)

## Resumen

Implementar validación downstream del Algoritmo A para `summary_n13` con
comparación tripartita:

- lógica real de `app.R`
- cálculo independiente en R
- cálculo independiente en Python

La salida principal será un workbook por combinación objetivo (15 en total),
con trazabilidad de insumos, cadena de incertidumbres, puntajes y comparación
numérica/cualitativa.

## Cambios de implementación

### 1. Script orquestador en R

Crear `validation/generate_post_algoA_validation.R` para:

- cargar `data/summary_n13.csv`, `data/homogeneity_n13.csv`,
  `data/stability_n13.csv`
- fijar las 15 combinaciones objetivo (niveles 1, 3 y 5 por contaminante)
- replicar extracción de `app.R` por `pollutant` + `level`, agregando por
  `participant_id` sobre todas las corridas disponibles
- reproducir la cadena downstream:
  - robust stats y consenso
  - homogeneidad
  - estabilidad
  - `u_xpt`, `u_hom`, `u_stab`, `u_xpt_def`, `U_xpt`
  - `z`, `z'`, `zeta`, `En` y evaluaciones
- generar comparaciones contra valores app e independientes

### 2. Script independiente en Python

Crear `validation/generate_post_algoA_validation.py` para reimplementar
fórmulas sin depender de funciones R y exportar resultados con el mismo esquema
canónico del script R.

### 3. Workbooks por combinación

Generar 15 archivos bajo `validation/` con convención `A2_<POL>_<LEVEL>.xlsx`,
cada uno con hojas:

- `00_input`
- `01_algorithm_a_feed`
- `02_uncertainty_chain`
- `03_scores`
- `04_global_checks`
- `05_comparison`

### 4. Consolidado maestro

Generar:

- `validation/post_algoA_master_comparison.csv`
- `validation/post_algoA_master_summary.csv`

con estado `PASS/FAIL` por combinación, sección, métrica y participante.

## Interfaces y contratos

### CLI R

`Rscript validation/generate_post_algoA_validation.R --input-summary ... --input-hom ... --input-stab ... --out-dir validation`

### CLI Python

`python3 validation/generate_post_algoA_validation.py --input-summary ... --input-hom ... --input-stab ... --out-dir validation`

### Esquema canónico de comparación

Columnas mínimas:

- `combo_id`
- `pollutant`
- `level`
- `section`
- `participant_id`
- `metric`
- `app_value`
- `r_value`
- `py_value`
- `excel_value`
- `diff_app_r`
- `diff_app_py`
- `diff_r_py`
- `diff_app_excel`
- `status`
- `tolerance`

## Reglas de comparación

- `1e-12` para equivalencias de fórmula directa
- `1e-9` para cadenas/agregados con posible arrastre de redondeo
- igualdad exacta para etiquetas:
  - `Satisfactorio`
  - `Cuestionable`
  - `No satisfactorio`

## Casos y decisiones críticas

- Niveles `0-*` pueden generar `sigma_pt ≈ 0`; los `NA` esperados en puntajes
  deben conservarse y documentarse.
- Para `u_stab`, se valida el comportamiento efectivo de `app.R`
  (`d_max / sqrt(3)` incondicional), aunque exista discrepancia con la función
  pura.
- No se revalida el núcleo iterativo de Algoritmo A; solo downstream.

## Plan de pruebas

1. Validar selección exacta de las 15 combinaciones objetivo.
2. Validar paridad de extracción de participantes contra lógica real de `app.R`.
3. Validar coincidencia de incertidumbres por método.
4. Validar coincidencia de `z`, `z'`, `zeta`, `En` por participante.
5. Validar coincidencia de evaluaciones cualitativas.
6. Validar estructura de salida:
   - 15 workbooks creados
   - 6 hojas por workbook
   - 2 consolidados CSV
7. Validar resumen maestro sin `FAIL`; si hay `FAIL`, listar diferencias con
   trazabilidad completa.

## Supuestos y defaults fijados

- Fuente de verdad: unión de `plan_a2.md` y
  `logs/plans/260330_1118_plan_a1_validacion_post_algoA.md`.
- Formato principal de entrega: 1 workbook por combinación objetivo.
- Ubicación de este plan: `logs/plans/pcodex_gpt53cdx.md`.
- Agregación por corridas: igual a `app.R` (todas las corridas disponibles por
  `pollutant` + `level`).
