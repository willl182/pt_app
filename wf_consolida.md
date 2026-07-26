# Workflow Fase 2 — consolidación R3 para pt_app

Orden de ejecución. Cada paso con criterio de salida.

## Paso 1 — Script builder
- Crear `data_use_cases/scripts/build_r3_pt_app.R` (ver plan_consolida.md §1).
- Entradas: `r3_resumen_niveles.csv` + `r3_capacidad_horaria.csv`.
- Verificar mapa nominal: por contaminante, tabla (run, level ordinal, gen_nominal). O3 esperado: 1→0, 2→180, 3→120, 4→80, 5→40 nmol/mol. NO2 nivel 2 → 144 (validar contra capacidad, no asumir).

## Paso 2 — Generar intermedios
- Correr builder → `ronda_3_p_ronda.csv` (participantes: seriales sin prefijo `4U`, `participant_id` = serial; en R3: ZFT5R6) y `ronda_3_r.csv` (serial con prefijo `4U` como `calaire_ref`; en R3: 4UDY72).
- Verificar: cada archivo 5 niveles × 3 contaminantes = 15 filas; niveles todos nominales; sin ordinales sueltos; roles correctos (4UDY72 solo en referencia).

## Paso 3 — Consolidar
- `Rscript scripts/aplicativo/consolidar_ronda_pt_app.R 3 data_use_cases/data/processed/ronda_3_p_ronda.csv data_use_cases/data/processed/ronda_3_r.csv data_use_cases/data/processed/ronda_3_completa.csv`
- Verificar salida del script: 30 filas (15 participante + 15 referencia), `n_lab = 1`.

## Paso 4 — Validación pt_app
- Chequeo esquema: `participant_id, pollutant, level, mean_value, u_value` presentes, sin NA en filas válidas.
- Prueba de humo: cargar `ronda_3_completa.csv` en pt_app sección "3. Datos Consolidados de participantes"; confirmar niveles nominales visibles y referencia reconocida.

## Paso 5 — Tests
- `tests/testthat/test-build-r3-pt-app.R` (casos en plan §4).
- Suite completa: `Rscript -e 'testthat::test_dir("tests/testthat")'` — sin regresiones.

## Paso 6 — Cierre
- Documentar cadena completa en `data_use_cases/prepro.md` (o README data_use_cases).
- Commit: `feat(aplicativo): consolidado ronda 3 cargable en pt_app`.

## Riesgos
- `normalize_level()` del consolidador convertiría ordinal `"2"` en `"2-nmol/mol"` silenciosamente — reemplazo nominal DEBE ocurrir en builder; validar regex `^[0-9.]+-` sobre nominales reales antes de consolidar.
- Join (pollutant, run) huérfano si fase 1 cambia numeración de run — abortar con error claro, no rellenar.
- NO2 con nominal 144 (no 180): no hardcodear tabla de niveles; siempre leer de capacidad.
- Roles por prefijo `4U`, nunca por lista fija de seriales: rondas futuras traen códigos aleatorios nuevos. Colisión teórica (participante que inicie con `4U`) queda cubierta por validación "exactamente 1 referencia".
- Con 1 solo participante, estadísticos de consenso en pt_app quedan degenerados (n_lab=1) — esperado, no bug.
