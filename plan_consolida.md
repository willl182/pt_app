# Plan Fase 2 — consolidación R3 para pt_app (`ronda_3_completa.csv`)

## Contexto

Fase 1 (plan_prepross.md) ya implementada. Genera en `data_use_cases/data/processed/`:

- `r3_capacidad_horaria.csv` — diagnóstico/QC (minutos disponibles, horas computables, horas reportadas, cumplimiento mínimo). NO se carga en pt_app.
- `r3_promedios_horarios.csv` — intermedio por hora e instrumento. NO se carga directamente.
- `r3_resumen_niveles.csv` — base para archivo cargable. Columnas: `source, run, pollutant, level, unit, instrument, mean_h1..h3, mean_value, sd_value, u_value, n_hours, hour_starts`.

pt_app espera consolidado `ronda_3_completa.csv` (sección "3. Datos Consolidados de participantes"), esquema mínimo `participant_id, pollutant, level, mean_value, u_value` + referencia incluida (formato ronda 2: columnas `tipo` = participante/referencia, `n_lab`).

Cadena:

```
R3_NO.csv / R3_NO2.csv / R3_O3.csv
        → r3_promedios_horarios.csv
        → r3_resumen_niveles.csv
        → ronda_3_p_ronda.csv + ronda_3_r.csv
        → ronda_3_completa.csv (via consolidar_ronda_pt_app.R)
        → pt_app
```

## Decisiones confirmadas (usuario)

- **Regla general de roles**: seriales son códigos aleatorios; la referencia CalAire SIEMPRE inicia con `4U` (prefijo, case-insensitive). Todo serial que no inicie con `4U` es participante. En R3: 4UDY72 = referencia, ZFT5R6 = participante (1 participante + referencia).
- **`participant_id` = serial tal cual** (p. ej. `ZFT5R6`). No renombrar a `p1`.
- Niveles ordinales `1..5` se reemplazan por nominales `"<gen_nominal>-<unit>"` (p. ej. `180-nmol/mol`), tomados de `r3_capacidad_horaria.csv` por contaminante y corrida (`run`).

## Brechas que cierra esta fase (sobre `r3_resumen_niveles.csv`)

1. `instrument` → `participant_id` / rol (referencia vs participante).
2. Nivel ordinal → nivel nominal (`gen_nominal` + `unit`).
3. Incorporar referencia (filas 4UDY72 marcadas `tipo = "referencia"`).
4. Generar `ronda_3_completa.csv` con script existente `scripts/aplicativo/consolidar_ronda_pt_app.R`.

## Cambios propuestos

### 1. Nuevo script `data_use_cases/scripts/build_r3_pt_app.R`

Entradas: `r3_resumen_niveles.csv`, `r3_capacidad_horaria.csv`. Pasos:

a. **Mapa de niveles nominales**: de capacidad, tabla única `(pollutant, run) → gen_nominal`. Join contra resumen por `(pollutant, run)`. Nuevo `level = paste0(gen_nominal, "-", unit)` (nivel cero → `0-nmol/mol`). Validar: join sin filas huérfanas; si `run` no cruza, abortar con mensaje.
b. **Split por rol (regla de prefijo, no hardcode de seriales)**:
   - Clasificar: `grepl("^4u", instrument, ignore.case = TRUE)` → referencia; resto → participantes.
   - Participantes → `ronda_3_p_ronda.csv`: `participant_id = instrument` (serial tal cual), `source = "ronda_participante"`, `tipo = "participante"`. Soporta N participantes futuros sin cambios.
   - Referencia → `ronda_3_r.csv`: `instrument = "calaire_ref"`, `source = "ronda"`, `tipo = "referencia"`, columna `serial` con el código original (`4UDY72`). Validar exactamente 1 serial de referencia; 0 o >1 → error.
   - Ambos conservan `pollutant, level, unit, run, mean_h1..h3, mean_value, sd_value, u_value, n_hours, hour_starts`.
c. **Nota importante**: pasar `level` YA nominal al consolidador. Su `normalize_level()` solo añade unidad si falta `-`; un ordinal `"2"` se convertiría en `"2-nmol/mol"` (incorrecto). Por eso el reemplazo ocurre aquí, no en el consolidador.

### 2. Consolidación (script existente, sin cambios)

```
Rscript scripts/aplicativo/consolidar_ronda_pt_app.R \
  3 \
  data_use_cases/data/processed/ronda_3_p_ronda.csv \
  data_use_cases/data/processed/ronda_3_r.csv \
  data_use_cases/data/processed/ronda_3_completa.csv
```

Consolidador ya cubre: columnas obligatorias, `n_lab` por (pollutant, level), `tipo`, orden de columnas. Con 1 participante, `n_lab = 1` en todas las filas.

### 3. Validaciones de salida

- `ronda_3_completa.csv`: esquema mínimo presente; niveles todos nominales (regex `^[0-9.]+-`); por contaminante: 5 niveles participante + 5 referencia; `n_lab = 1`; sin NA en `mean_value`/`u_value` de filas válidas.
- Cargar en pt_app (sección 3) como prueba de humo manual o vía test de parseo si existe helper en `app.R`.

### 4. Tests (`tests/testthat/`)

- Nuevo `test-build-r3-pt-app.R` con fixtures mínimos de resumen + capacidad:
  - join nominal correcto por (pollutant, run), incluido caso NO2 nivel 2 con gen 144 (nominal distinto del "esperado" 180);
  - nivel cero → `0-nmol/mol`;
  - split por prefijo: serial `4Uxxxx` siempre referencia (probar case-insensitive `4u`), cualquier otro serial aleatorio → participante con `participant_id` = serial;
  - 0 seriales de referencia → error; 2 seriales `4U*` → error;
  - run huérfano → error;
  - salida consolidada pasa `normalize_pt_df` (columnas obligatorias).

## Decisiones abiertas
- ¿`r3_promedios_horarios.csv` se archiva o se conserva como trazabilidad? Plan: se conserva, no se carga.
