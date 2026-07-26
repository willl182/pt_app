# Plan — actualizar preprocesador `R/preprocessing/hourly_averages.R` para archivos raw R3

## Contexto

Nuevos archivos raw de la Ronda 3:

- `data_use_cases/data/raw/R3_O3.csv` — columnas: `date time, o3_4UDY72, o3_ZFT5R6, runtime, level, o3_gen`
- `data_use_cases/data/raw/R3_NO2.csv` — columnas: `date time, no_4UDY72, no2_4UDY72, nox_4UDY72, no_ZFT5R6, no2_ZFT5R6, nox_ZFT5R6, runtime, level, no2_gen`
- `data_use_cases/data/raw/R3_NO.csv` — mismas columnas de analizadores que NO2, pero `no_gen`

Diferencias clave frente al formato anterior:

1. **`runtime`**: tiempo transcurrido acumulado `HH:MM` desde el inicio del ensayo (minutal, puede superar 24:00). Debe ser la base temporal para agrupar horas, NO el reloj de pared (`date time` tiene anomalías, p. ej. `07/15/26 24:00`).
2. **`level`**: etiqueta de bloque por fila: `1..5` (mesetas) y `estab` (transición/estabilización). Reemplaza el diseño externo por timestamps.
3. **`*_gen`**: valor nominal del generador por fila (equivalente al `generator_col` actual).
4. Columnas de analizadores por instrumento (`<pollutant>_<serial>`, p. ej. `o3_4UDY72`), no columnas `*_calaire_*` ni `*_part_*`.

Caso especial incluido en `R3_NO.csv`: bloques de nivel con duración no múltiplo de 60 min:

| level | minutos | horas completas calculables |
|-------|---------|------------------------------|
| 1     | 60      | 1 (nivel cero) |
| 2     | 170     | 3 (2 completas + residual 50 ≥ 45 cuenta) |
| 3     | 180     | 3 |
| 4     | 170     | 3 (2 + residual 50) |
| 5     | 171     | 3 (2 + residual 51) |

Regla: residual < 45 min se descarta; >= 45 cuenta. Mínimo exigido por nivel no-cero: 2 horas (generalmente 3).

El script debe **evaluar y reportar** cuántos promedios horarios pueden calcularse por bloque antes de calcularlos.

## Cambios propuestos

### 1. Nueva función `read_raw_round_file(path, tz)`
- Lee CSV, parsea `date time` (`%m/%d/%y %H:%M`) con tolerancia a `24:00` (normalizar a día siguiente 00:00) — solo informativo.
- Parsea `runtime` `HH:MM` a minutos enteros acumulados: `runtime_min = 60*HH + MM`. Sin límite de 24 h.
- Detecta contaminante objetivo desde la columna `*_gen` (`o3_gen` → o3, etc.).
- Detecta columnas de instrumentos: patrón `^<pollutant>_[A-Z0-9]+$` excluyendo `*_gen` (para NO/NO2 el archivo trae no, no2 y nox de ambos seriales; usar solo las del contaminante objetivo).
- Devuelve data.frame estandarizado: `runtime_min, level, gen_value, <cols instrumento>` + metadatos (pollutant, instrument serials, file).

### 2. Nueva función `assess_hourly_capacity(raw_df)`
- Agrupa por corridas contiguas de `level` (excluir `estab`; usar `rle`/`cumsum` sobre cambios).
- Por bloque reporta: `level, gen_nominal, n_minutes, runtime_start, runtime_end, n_full_hours = floor(n/60), residual_minutes = n %% 60, residual_valid = residual >= 45, n_computable_hours = n_full_hours + residual_valid, meets_min_hours = n_computable_hours >= 2` (nivel cero: `>= 1`).
- Salida: data.frame resumen por (archivo, pollutant, level). Es el "assessment" pedido; se imprime/guarda antes del cálculo.

### 3. Nueva función `compute_hourly_averages_runtime(raw_df, max_hours = 3)`
- Base temporal: `runtime_min`. Dentro de cada bloque de nivel, particionar en trozos consecutivos de 60 min (`ceiling(seq_along(idx)/60)` como hoy en `compute_hourly_averages_ronda`), pero indexado por minutos de runtime reales (robusto a minutos faltantes: usar `floor((runtime_min - runtime_min[1])/60)`).
- Trozo válido si `n_valid >= 45` (regla 75 % existente).
- Por instrumento (cada columna de analizador) y trozo: `mean, sd, u = sd/sqrt(n)`, flags `n=<k>`, `less_than_75pct` — mismo esquema de salida que las funciones existentes (source, run, level, generated_nominal, generated_mean/sd, instrument, mean/sd/u, n, valid_hour, validation_flags), añadiendo `runtime_start/runtime_end` y conservando `hour_start` derivado de `date time` como referencia.
- Reglas por nivel: nivel 0/cero → 1 hora; otros niveles → mínimo 2 horas calculables, hasta `max_hours` (3). Trozo con < 45 min se descarta (no genera fila válida); trozo con >= 45 min cuenta con flag `n=<k>`. Bloque no-cero con < 2 horas calculables → flag `below_min_hours` en filas y assessment.
- No tocar funciones existentes (`compute_hourly_averages`, `*_ronda`, `*_participant_ronda`) — siguen sirviendo al formato viejo. `summarise_reference_levels` se reutiliza tal cual sobre la nueva salida.

### 4. Runner/integración
- Pequeño wrapper `process_raw_round_files(paths, ...)`: lee cada archivo, imprime assessment, calcula horarios, rbind.
- Uso desde `data_use_cases/scripts/` (nuevo script de ejemplo, p. ej. `preprocess_r3.R`) que escribe assessment y horarios a `data_use_cases/data/processed/`.

### 5. Tests (`tests/testthat/`)
- Fixture sintético pequeño con runtime, bloques de 60/170/171 min y `estab`.
- Casos: parseo runtime >24 h y `24:00`; exclusión `estab`; capacidad por bloque (170 → 3, 171 → 3, 60 → 1); hora parcial n=50 cuenta con flag `n=50`; trozo de 44 min descartado; bloque no-cero de 105 min (1 h + residual 45) → 2 h, cumple mínimo; bloque de 100 min (1 h + residual 40 descartado) → 1 h, flag `below_min_hours`; consistencia con `summarise_reference_levels`.

## Decisiones confirmadas (usuario)
- Hora parcial: `< 45 min` NO cuenta; `>= 45 min` SÍ cuenta como hora calculable (con flag `n=<k>`).
- Horas por nivel: mínimo 2, generalmente 3. Tope superior 3. Si un bloque produce < 2 horas calculables, marcar en assessment y salida con flag `below_min_hours` (excepción: nivel cero, 1 hora esperada).
- Nombre de `source` en salida: `"ronda3_raw"`.
