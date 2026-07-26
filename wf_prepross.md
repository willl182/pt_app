# Workflow — implementación preprocesador R3

Orden de ejecución. Cada paso con criterio de salida.

## Paso 1 — Lectura y normalización
- Añadir `read_raw_round_file()` en `R/preprocessing/hourly_averages.R`.
- Verificar: `Rscript -e` leyendo los 3 archivos R3; imprime pollutant detectado, columnas instrumento, rango runtime_min, conteo filas por level.
- Salida esperada: O3 → 812 filas, runtime 0–810; NO → 886 filas, runtime 0–885; niveles 1..5 + estab.

## Paso 2 — Assessment de capacidad horaria
- Añadir `assess_hourly_capacity()`.
- Verificar contra R3_NO.csv: level 1 → 60 min → 1 h (cero); level 2 → 170 → 3 (2 completas + residual 50 ≥ 45); level 3 → 180 → 3; level 4 → 170 → 3; level 5 → 171 → 3. Todos cumplen mínimo 2 h → `meets_min_hours = TRUE`.
- Salida: tabla assessment impresa y guardada (`data_use_cases/data/processed/r3_capacidad_horaria.csv`).

## Paso 3 — Cálculo de promedios horarios por runtime
- Añadir `compute_hourly_averages_runtime()`.
- Partición por runtime dentro de bloque: trozo < 45 min descartado, >= 45 cuenta con flag `n=<k>`; tope 3 h/nivel; mínimo 2 h por nivel no-cero (si no, flag `below_min_hours`); 1 h para nivel cero.
- Verificar: medias de la primera hora level 2 de O3 contra cálculo manual (mean de filas runtime 01:40–02:39, cols `o3_4UDY72`, `o3_ZFT5R6`).

## Paso 4 — Wrapper e integración
- `process_raw_round_files()` + script `data_use_cases/scripts/preprocess_r3.R`.
- Corre los 3 archivos, escribe assessment + horarios + resumen (`summarise_reference_levels`) a `data_use_cases/data/processed/`.

## Paso 5 — Tests
- Nuevo `tests/testthat/test-hourly-runtime.R` con fixture sintético (ver plan §5).
- Correr suite completa: `Rscript -e 'testthat::test_dir("tests/testthat")'` — sin regresiones en funciones existentes.

## Paso 6 — Cierre
- Revisar salida en `data/processed/`, documentar en README de data_use_cases si aplica.
- Commit: `feat(preprocessing): promedios horarios por runtime para raw R3`.

## Riesgos
- `date time` con `24:00` rompe parseo estándar — usar runtime como base, wall clock solo informativo.
- Minutos faltantes en runtime: particionar por valor de runtime, no por posición de fila.
- NO/NO2 comparten columnas de analizador; filtrar por contaminante de `*_gen` para no duplicar resultados.
