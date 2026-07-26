# Review — implementación de `plan_prepross.md`

Fecha: 2026-07-26
Alcance revisado:
- `R/preprocessing/hourly_averages.R` (líneas 404–590, código nuevo)
- `data_use_cases/scripts/preprocess_r3.R`
- `tests/testthat/test-hourly-runtime.R`

Estado de la suite: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 30 ]`.
Corrida sobre datos reales (`R3_NO.csv`): 5 bloques (60/170/180/170/171 min) → 1/3/3/3/3 horas computables, todos `meets_min_hours = TRUE`.

---

## Conforme al plan

- Parseo de `runtime` `HH:MM` sin tope de 24 h; `24:00` de reloj de pared normalizado a 00:00 del día siguiente (solo informativo).
- Detección de contaminante desde `*_gen`; regex de prefijo `^<pollutant>_[A-Z0-9]+$` excluye correctamente `nox_*` y las columnas del contaminante no objetivo.
- `estab` excluido de bloques.
- Regla de residual: `< 45` se descarta, `>= 45` cuenta con flag `n=<k>`.
- `source = "ronda3_raw"`.
- Funciones antiguas (`compute_hourly_averages`, `*_ronda`, `*_participant_ronda`) sin tocar; `summarise_reference_levels` reutilizado tal cual.
- Wrapper `process_raw_round_files` + script `preprocess_r3.R` que escribe los tres CSV a `data_use_cases/data/processed/`.

---

## Hallazgos

### 1. BUG — `assess_hourly_capacity` cuenta filas; `compute_hourly_averages_runtime` cuenta runtime

`hourly_averages.R:474` usa `n_minutes <- nrow(rows)`.
`hourly_averages.R:531` usa `chunk_id <- floor((block$runtime_min - block$runtime_min[1]) / 60)`.

Con minutos faltantes las dos rutas divergen. Reproducción: bloque de 90 filas que abarca runtime 0–104 (hueco de 45–59):

```
assessment: n_minutes = 90, n_computable_hours = 1, meets_min_hours = FALSE
compute:    2 filas horarias, sin flag below_min_hours
```

Misma corrida, salidas contradictorias. El plan (§3) exige explícitamente ser "robusto a minutos faltantes"; el assessment no lo es. El test `runtime gaps determine chunk boundaries` ejercita este dato pero solo verifica el lado `compute`.

**Severidad: alta.** El assessment es el entregable que decide si un bloque sirve; puede rechazar bloques que sí producen horas válidas.

### 2. BUG — el filtro de chunk usa número de filas, no `n_valid`

`hourly_averages.R:533`:

```r
chunks <- chunks[vapply(chunks, length, integer(1)) >= 45L]
```

Plan §3: "Trozo válido si `n_valid >= 45`". Un chunk de 60 filas con 30 valores no-NA sobrevive el filtro, emite fila con `valid_hour = FALSE` + `less_than_75pct`, y **consume cupo de `block_limit`**, desplazando un chunk posterior válido fuera de las 3 horas.

Con varios instrumentos por archivo, un criterio por-fila es defendible (no hay un único `n_valid`), pero hoy diverge del plan sin documentarlo.

**Severidad: media.** Sin cobertura de test.

### 3. BUG — el filtro se aplica antes del cap `max_hours`

`hourly_averages.R:533`–`:539`: primero se descartan los chunks cortos, después se toma `seq_len(min(length(chunks), block_limit))`. Un chunk intermedio descartado promueve uno posterior a las "3 primeras horas". Lo esperable es que las horas reportadas sean las 3 primeras *contiguas* del bloque.

**Severidad: media.** Sin cobertura de test.

### 4. MENOR — `%||%` global duplicado

`hourly_averages.R:406` define `%||%` en un archivo que se hace `source()`. `app.R:45` define otro con semántica distinta (solo `is.null`, sin el chequeo `length(x) == 0L`). `app.R` no sourcea hoy `hourly_averages.R`, pero `scripts/aplicativo/preprocesar_calaire.R:32` sí lo carga: cualquier contexto que cargue ambos queda con la definición que se evalúe de último.

### 5. MENOR — `n_computable_hours` no se capa a `max_hours`

El assessment reporta la capacidad cruda; `compute` capa en 3. Un bloque de 240 min reporta 4 en el assessment y 3 filas horarias. Es coherente si se documenta como "capacidad teórica vs. calculado", pero hoy no se distingue.

### 6. MENOR — `generated_nominal` es la media del bloque

`hourly_averages.R:541`: `gen_nominal <- mean(block$gen_value, na.rm = TRUE)`. Idéntico al nominal si `gen` es constante en el bloque; si varía, la columna `generated_nominal` reporta una media, no un nominal.

### 7. MENOR — falta test del cap de nivel cero

El caso "nivel cero → 1 hora" (`block_limit = 1L` cuando `gen ≈ 0`) solo se ejercita con un bloque de 60 min, donde los datos se agotan de todas formas. El cap en sí no está verificado.

---

## Fixes a implementar

### Fix 1 — unificar la base temporal (bloqueante)

Extraer un helper compartido y usarlo en ambas funciones:

```r
.runtime_chunks <- function(runtime_min) {
  if (length(runtime_min) == 0L) return(list())
  split(seq_along(runtime_min), floor((runtime_min - runtime_min[1]) / 60))
}
```

En `assess_hourly_capacity`, reemplazar el conteo por filas:

```r
rows <- rows[order(rows$runtime_min), , drop = FALSE]
chunks <- .runtime_chunks(rows$runtime_min)
chunk_sizes <- vapply(chunks, length, integer(1))

n_minutes        <- nrow(rows)
runtime_span     <- max(rows$runtime_min) - min(rows$runtime_min) + 1L
n_full_hours     <- sum(chunk_sizes >= 60L)
residual_minutes <- if (length(chunk_sizes) > 0L && chunk_sizes[length(chunk_sizes)] < 60L) chunk_sizes[length(chunk_sizes)] else 0L
residual_valid   <- residual_minutes >= 45L
n_computable     <- sum(chunk_sizes >= 45L)
```

Añadir `runtime_span` como columna del assessment y mantener `n_minutes` como conteo de filas observadas — la diferencia entre ambas hace visible el dato faltante.

Test nuevo: bloque de 90 filas con runtime `c(0:44, 60:104)` → `n_computable_hours == 2`, `meets_min_hours == TRUE`, y `nrow(compute_hourly_averages_runtime(...)) == 2`. Assessment y cómputo deben coincidir.

### Fix 2 — decidir y unificar el criterio de validez del chunk

Opción recomendada (menos cambio, coherente con multi-instrumento): mantener el filtro por número de filas, pero renombrar la constante y documentarlo en el roxygen/comentario de la función:

```r
# Un trozo se retiene si tiene >= 45 minutos de reloj (filas). La validez por
# instrumento (n_valid >= 45 no-NA) se evalúa después, vía valid_hour.
MIN_CHUNK_MINUTES <- 45L
```

Opción alternativa (si se quiere seguir el plan literal): filtrar por `max(n_valid)` entre las columnas de instrumento.

Elegir una y dejarlo escrito; hoy el código dice una cosa y el plan otra.

Test nuevo: chunk de 60 filas con 30 NA → verificar el comportamiento elegido (fila emitida con `valid_hour = FALSE`, o chunk descartado).

### Fix 3 — capar antes de filtrar

```r
chunks <- .runtime_chunks(block$runtime_min)
chunks <- chunks[seq_len(min(length(chunks), block_limit))]   # primero: 3 primeras horas contiguas
chunks <- chunks[vapply(chunks, length, integer(1)) >= MIN_CHUNK_MINUTES]
```

Recalcular `below_min_hours` después de ambos pasos.

Test nuevo: bloque cuyo chunk 2 tiene 30 min y cuyo chunk 4 tiene 60 → deben emitirse 2 filas (chunks 1 y 3), no promoverse el chunk 4.

### Fix 4 — renombrar el operador local

Renombrar `%||%` a `.or_default(x, y)` en `hourly_averages.R` y actualizar los tres usos (`:483`, `:484`, `:509`). Elimina el riesgo de enmascaramiento cruzado con `app.R:45`.

### Fix 5 — capar el assessment o renombrar la columna

Añadir `max_hours` como argumento de `assess_hourly_capacity(raw_df, max_hours = 3L)` y una columna `n_reported_hours = min(n_computable_hours, max_hours)`, dejando `n_computable_hours` como capacidad teórica. El script debe escribir ambas.

### Fix 6 — separar nominal de media

Usar la moda o el primer valor no-NA como `generated_nominal`, y dejar la media en `generated_mean` (que ya existe por hora):

```r
gen_vals <- block$gen_value[!is.na(block$gen_value)]
gen_nominal <- if (length(gen_vals) == 0L) NA_real_ else as.numeric(names(sort(table(gen_vals), decreasing = TRUE))[1])
```

### Fix 7 — test del cap de nivel cero

Bloque con `gen = 0` y 180 min → esperar exactamente 1 fila horaria por instrumento (`block_limit = 1L`), no 3.

---

## Orden sugerido

1. Fix 1 (bloqueante — corrige salida contradictoria).
2. Fix 3 y Fix 4 (bajo riesgo, mecánicos).
3. Fix 2 y Fix 6 (requieren decisión explícita sobre semántica).
4. Fix 5 y Fix 7 (documentación y cobertura).

Regenerar `r3_capacidad_horaria.csv`, `r3_promedios_horarios.csv` y `r3_resumen_niveles.csv` tras los fixes 1, 3 y 6, ya que sus valores cambian.
