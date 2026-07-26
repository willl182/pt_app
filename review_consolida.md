# Review — implementación de `plan_consolida.md` (Fase 2, consolidación R3)

Fecha: 2026-07-26
Alcance revisado:
- `data_use_cases/scripts/build_r3_pt_app.R` (nuevo)
- `tests/testthat/test-build-r3-pt-app.R` (nuevo)
- Salidas: `ronda_3_p_ronda.csv`, `ronda_3_r.csv`, `ronda_3_completa.csv`
- `scripts/aplicativo/consolidar_ronda_pt_app.R` (sin cambios, como pedía el plan)

Estado de la suite: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 19 ]`.
Salida real: `ronda_3_completa.csv` con 30 filas = 3 contaminantes × 5 niveles × (1 participante `ZFT5R6` + referencia `calaire_ref`/`4UDY72`), `n_lab = 1`, `tipo` correcto, niveles nominales.

---

## Conforme al plan

- Mapa nominal `(pollutant, run) → gen_nominal` con detección de claves duplicadas (`build_nominal_map`), más estricto de lo pedido.
- Join con `all.x = TRUE` y aborto por filas huérfanas, con el `pollutant/run` culpable en el mensaje.
- Validación extra no pedida pero correcta: `level_summary` vs `level_capacity` deben coincidir; detecta desalineación del `run` aunque el join cruce.
- Orden de filas del resumen preservado (`.row_order` alrededor del `merge`).
- Split por prefijo `^4u` case-insensitive, sin hardcode de seriales; error si el conteo de referencias ≠ 1.
- `participant_id = instrument` (serial tal cual), `source`/`tipo` por rol, `serial` conservado en la referencia.
- Nivel nominal asignado **antes** del consolidador, evitando el bug de `normalize_level()` descrito en §1.c del plan (verificado: `normalize_level` solo añade unidad si falta `-`).
- Script usable como librería y como CLI (`sys.nframe() == 0L`), con paths por defecto.
- Test de integración real que ejecuta el consolidador vía `system2` y valida el esquema mínimo.

---

## Hallazgos

### 1. FALTA — las validaciones de salida del plan §3 no están implementadas

El plan pide, sobre `ronda_3_completa.csv`: esquema mínimo, todos los niveles nominales (`^[0-9.]+-`), 5 niveles participante + 5 referencia por contaminante, `n_lab = 1`, sin NA en `mean_value`/`u_value`.

Hoy esas comprobaciones existen **solo dentro del test**, contra un fixture de 2 runs. El pipeline de producción (`build_r3_pt_app.R` + consolidador) no valida nada de su propia salida: si mañana un contaminante llega con 4 niveles, o `u_value` viene NA, el CSV se escribe igual y el error aparece dentro de pt_app.

**Severidad: alta** (es un entregable explícito de la fase que no se construyó).

### 2. BUG LATENTE — `gen_nominal` se formatea sin control y puede romper el contrato de nivel

`build_r3_pt_app.R`: `joined$level <- paste0(joined$gen_nominal, "-", joined$unit)`.

`gen_nominal` viene de la fase 1 como estadístico sobre la columna del generador. Casos que rompen el formato esperado `^[0-9.]+-`:

- Nominal negativo por ruido de lectura del generador en el nivel cero → `"-0.03-nmol/mol"`. Además `normalize_level()` del consolidador ve el `-` inicial y lo trata como "ya tiene unidad", así que no corrige nada.
- Nominal no redondeado (p. ej. `143.99666666`) → nivel `"143.99666666-nmol/mol"`, ilegible y frágil como clave de agrupación.
- Notación científica de R para valores muy pequeños (`1e-04`) → `"1e-04-nmol/mol"`.

En los datos actuales no ocurre (todos los nominales son enteros limpios), pero el formateo no está defendido.

**Severidad: media.**

### 3. RIESGO DE DATOS — el nivel nominal no se contrasta contra lo medido

En la salida real, `no2 / run 3`:

```
level = "144-nmol/mol"
referencia  mean_value = 153.988
participante mean_value = 154.230
```

Ambos instrumentos miden ~154 en un nivel etiquetado 144 (~7 % de desvío). El plan menciona ese caso como conocido ("nominal distinto del esperado"), así que no es un fallo del código — pero nada en el pipeline lo señala, y el nivel etiquetado es el que verá el usuario en pt_app.

Relacionado: `no` reporta nominales `179 / 119 / 41` mientras `o3` reporta `180 / 120 / 40`. Etiquetas distintas para setpoints presumiblemente iguales, porque la etiqueta viene de la lectura del generador y no de un valor declarado.

**Severidad: media** (calidad del dato entregado, no corrección del código).

### 4. BUG — no se valida que exista al menos 1 participante

`split_r3_roles` valida `length(reference_serials) != 1L`, pero no el lado participante. Si todos los seriales empiezan por `4U`, `participants` queda con 0 filas, se escribe un CSV vacío y el fallo aparece más adelante, dentro del consolidador, con un mensaje sin relación con la causa.

**Severidad: baja-media.** Simétrico a una validación que ya existe; barato de cerrar.

### 5. MENOR — `merge` sin protección ante nuevas columnas comunes

`join_nominal_levels` usa `suffixes = c("_summary", "_capacity")`, que hoy solo aplica a `level`. Si la fase 1 añade al assessment una columna que también existe en el resumen (p. ej. `unit`, `n_hours`), el merge la sufija en silencio y el resto del script sigue leyendo la versión sin sufijo — que ya no existe. Falla o, peor, arrastra la columna equivocada.

### 6. MENOR — `na = "NA"` inconsistente con la fase 1

`build_r3_pt_app.R` escribe con `na = "NA"`; `preprocess_r3.R` escribe con `na = ""`. Funcionalmente equivalente al releer con `read.csv`, pero los archivos de la misma cadena no se ven iguales y cualquier consumidor no-R (Excel, pandas con `keep_default_na=False`) los trata distinto.

### 7. MENOR — sin punto de entrada único para la cadena

El plan §2 deja la consolidación como invocación manual. Funciona, pero hoy nadie ejecuta `preprocess_r3.R → build_r3_pt_app.R → consolidar_ronda_pt_app.R` en secuencia salvo el test. Reproducir el entregable exige recordar tres comandos y sus rutas.

### 8. LIMPIEZA — archivos sueltos en el directorio de salida

`data_use_cases/data/processed/test_p.csv` y `test_r.csv` quedaron sin seguimiento, aparentemente de una corrida manual. No los produce ningún script del pipeline.

### 9. Cobertura de tests — huecos

Cubierto: join nominal por `(pollutant, run)`, caso NO2 gen 144, nivel cero → `0-nmol/mol`, prefijo `4u` case-insensitive, 0 y 2 referencias → error, run huérfano, mismatch ordinal, integración con el consolidador.

No cubierto:
- 0 participantes (hallazgo 4);
- `(pollutant, run)` duplicado en capacidad → `build_nominal_map` debe abortar (la rama existe, nadie la ejercita);
- formateo de `gen_nominal` negativo o con muchos decimales (hallazgo 2);
- más de 1 participante — el plan promete "soporta N participantes futuros sin cambios", y eso no se verifica en ningún test (`n_lab` debería pasar a N).

---

## Fixes a implementar

### Fix 1 — añadir `validate_r3_output()` y ejecutarla en el CLI

Nueva función en `build_r3_pt_app.R`, invocada sobre el consolidado tras generarlo:

```r
validate_r3_output <- function(complete, expected_levels = 5L, expected_n_lab = NULL) {
  required_columns(
    complete,
    c("participant_id", "pollutant", "level", "mean_value", "u_value", "tipo", "n_lab"),
    "consolidado R3"
  )

  bad_level <- !grepl("^[0-9]+(\\.[0-9]+)?-", complete$level)
  if (any(bad_level)) {
    stop("Niveles no nominales: ", paste(unique(complete$level[bad_level]), collapse = ", "), call. = FALSE)
  }

  counts <- table(complete$pollutant, complete$tipo)
  wrong <- counts != expected_levels
  if (any(wrong)) {
    stop(
      "Conteo de niveles inesperado (se esperaban ", expected_levels, " por contaminante y tipo): ",
      paste(apply(which(wrong, arr.ind = TRUE), 1, function(i) {
        paste0(rownames(counts)[i[1]], "/", colnames(counts)[i[2]], "=", counts[i[1], i[2]])
      }), collapse = ", "),
      call. = FALSE
    )
  }

  n_participants <- length(unique(complete$participant_id[complete$tipo == "participante"]))
  expected_n_lab <- expected_n_lab %||% n_participants
  if (!all(complete$n_lab == expected_n_lab)) {
    stop("n_lab distinto de ", expected_n_lab, call. = FALSE)
  }

  na_rows <- is.na(complete$mean_value) | is.na(complete$u_value)
  if (any(na_rows)) {
    stop("NA en mean_value/u_value: ", sum(na_rows), " filas", call. = FALSE)
  }

  invisible(TRUE)
}
```

Nota: `expected_levels` debe ser argumento, no constante — la fase 1 puede legítimamente descartar un bloque por `below_min_hours` y entonces el conteo baja. En ese caso el error es la señal correcta, pero debe poder relajarse explícitamente.

Test: consolidado con un nivel faltante → error; con `u_value` NA → error; caso feliz → `TRUE`.

### Fix 2 — formatear `gen_nominal` de forma determinista

```r
format_nominal <- function(x, digits = 1L) {
  if (any(!is.finite(x))) stop("gen_nominal no finito", call. = FALSE)
  if (any(x < 0)) stop("gen_nominal negativo: ", paste(unique(x[x < 0]), collapse = ", "), call. = FALSE)
  formatC(round(x, digits), format = "fg", drop0trailing = TRUE)
}

joined$level <- paste0(format_nominal(joined$gen_nominal), "-", joined$unit)
```

Elimina la notación científica, acota los decimales y convierte el nominal negativo en un error explícito en vez de un nivel malformado que el consolidador no corrige.

Test: `gen_nominal = 143.99666` → `"144-nmol/mol"`; `gen_nominal = -0.03` → error; `gen_nominal = 1e-04` → `"0-nmol/mol"`.

### Fix 3 — advertir cuando el nominal se aparta de lo medido por la referencia

En `validate_r3_output()` (aviso, no error):

```r
ref <- complete[complete$tipo == "referencia" & complete$mean_value > 0, , drop = FALSE]
nominal <- as.numeric(sub("-.*$", "", ref$level))
rel_dev <- abs(ref$mean_value - nominal) / nominal
flagged <- rel_dev > 0.05
if (any(flagged)) {
  warning(
    "Nivel nominal se aparta >5% de la referencia medida: ",
    paste0(ref$pollutant[flagged], " ", ref$level[flagged],
           " (ref=", round(ref$mean_value[flagged], 2), ")", collapse = "; "),
    call. = FALSE
  )
}
```

Con los datos actuales dispara para `no2 / 144-nmol/mol` (ref 153.99, desvío 6.9 %), que es exactamente el caso que el plan marca como conocido. Excluir el nivel cero del cálculo relativo (división por 0).

Decisión pendiente para el usuario: si el nominal correcto de esos niveles es el declarado del generador y no su lectura, la fuente de `gen_nominal` debería ser una tabla de setpoints declarados, no la columna `*_gen` — eso sería un cambio de fase 1, no de esta.

### Fix 4 — validar el lado participante

En `split_r3_roles`, tras calcular `participants`:

```r
if (nrow(participants) == 0L) {
  stop("No se encontraron filas de participante (todos los seriales tienen prefijo 4U)", call. = FALSE)
}
```

Test: resumen con solo `4UDY72` → error.

### Fix 5 — blindar el `merge`

Seleccionar explícitamente las columnas del mapa antes de unir, en vez de confiar en `suffixes`:

```r
nominal_map <- nominal_map[c("pollutant", "run", "level", "gen_nominal")]
names(nominal_map)[names(nominal_map) == "level"] <- ".level_capacity"
```

y comparar contra `.level_capacity`. Así, si la fase 1 añade columnas al assessment, el join no cambia de forma.

Test: capacidad con una columna extra `unit` → el join sigue produciendo los mismos niveles.

### Fix 6 — unificar `na =` en la cadena

Usar `na = ""` en `build_r3_pt_app.R`, igual que `preprocess_r3.R`. Verificar antes que el consolidador no distinga (usa `read.csv` por defecto, así que no).

### Fix 7 — script de cadena completa

`data_use_cases/scripts/run_r3_pipeline.R` que encadene los tres pasos y ejecute `validate_r3_output()` al final, para que regenerar el entregable sea un solo comando. Los scripts individuales siguen siendo invocables.

### Fix 8 — limpiar artefactos sueltos

Eliminar `data_use_cases/data/processed/test_p.csv` y `test_r.csv`, y dirigir la salida de las corridas de prueba a `tempdir()` (el test ya lo hace).

### Fix 9 — cerrar huecos de test

- `(pollutant, run)` duplicado en capacidad → error de `build_nominal_map`.
- Dos participantes + 1 referencia → 2 archivos correctos y `n_lab == 2` en el consolidado. Es la promesa "N participantes sin cambios" del plan; hoy no está verificada.

---

## Orden sugerido

1. Fix 1 y Fix 4 (validaciones ausentes; cierran el §3 del plan).
2. Fix 2 y Fix 5 (blindaje, bajo riesgo).
3. Fix 3 (requiere decisión sobre el origen de `gen_nominal`).
4. Fix 6, Fix 7, Fix 8, Fix 9 (consistencia, ergonomía, cobertura).

Ninguno de estos fixes cambia los valores de `ronda_3_completa.csv` con los datos actuales, salvo Fix 6 (representación de NA en el CSV). No hace falta regenerar el entregable para 1, 3, 4, 5, 7, 8, 9.
