# Plan de análisis — Rondas PT R1, R2, R3

Fecha: 2026-07-30
Alcance: 8 archivos en `data_use_cases/data/raw/`

| Archivo | Ronda | Analito | Unidad |
|---|---|---|---|
| `R1_SO2.csv` | R1 | SO2 | ppb |
| `R1_CO.csv` | R1 | CO | ppm |
| `R2A_O3.csv` | R2A | O3 | ppb |
| `R2B_NO.csv` | R2B | NO | ppb |
| `R2C_NO2.csv` | R2C | NO2 | ppb |
| `R3_O3.csv` | R3 | O3 | ppb |
| `R3_NO.csv` | R3 | NO | ppb |
| `R3_NO2.csv` | R3 | NO2 | ppb |

## 0. Decisiones tomadas

1. **Unidades separadas.** CO (ppm) se reporta y grafica aparte del resto (ppb). No se normaliza a fracción de span para forzar un eje común. Cada tabla y figura declara su unidad.
2. **R2C_NO2 cero truncado se incluye**, con caveat explícito de `n` reducido y gap temporal documentado.
3. **El analizador de referencia es el mismo equipo físico en R2 y R3** (`4UXXXX` anonimizado en R1/R2 = `4UDY72` en R3). Por tanto la comparación R2 vs R3 de la referencia se interpreta como **deriva temporal (~2.5 meses)**, no como comparación entre equipos.

## 0.1 Diseño del ejercicio

CalAire es la referencia en las tres rondas. Los participantes y analitos cambian:

| | Fecha | Analitos | Participante | Referencia |
|---|---|---|---|---|
| R1 | 23–24 abr 2026 | SO2, CO | **P1** | CalAire 4U |
| R2 (A/B/C) | 30 abr – 2 may 2026 | O3, NO, NO2 | **P1** | CalAire 4U |
| R3 | 15–16 jul 2026 | O3, NO, NO2 | **P2** (`ZFT5R6`) | CalAire 4U |

Consecuencias directas sobre qué comparación es válida:

- **R1 ↔ R2**: mismo participante, **analitos distintos**. No hay comparación pareada por analito. Sólo caracterización del participante P1 en métricas independientes del analito (ruido de cero, signo y magnitud del sesgo relativo, deriva intra-nivel). Descriptivo, no inferencial.
- **R2 ↔ R3**: mismos analitos, **participantes distintos**. La referencia es lo único con continuidad.
  - Δ de la referencia entre rondas = **deriva del 4U a ~2.5 meses**. Resultado principal.
  - Δ del participante entre rondas **no es deriva**: son dos laboratorios. Es comparación inter-laboratorio con n=1 por ronda; se describe, no se contrasta estadísticamente.
  - El estadístico comparable entre R2 y R3 es **ref − participante por nivel**, porque el denominador (CalAire) es común. Ese sí mide desempeño relativo de P1 frente a P2 contra la misma vara.

## 1. Hallazgos de datos que condicionan el diseño

### Formato

| Aspecto | R1 (SO2, CO) | R2 (A/B/C) | R3 |
|---|---|---|---|
| Timestamp | `date`, `time` separados | `date`, `time` separados | `date time` una sola columna |
| Columnas de medida | `so2_4UXXXX`, `so2_pXXXX` | `no2_4UXXXX`, `no2_pXXXX` | `o3_4UDY72`, `o3_ZFT5R6` |
| Serial | anonimizado | anonimizado | real |
| Hora `24:00` | presente | presente | presente |

Rol por prefijo de columna: `4U` = referencia CalAire; el otro serial = participante.

`runtime` es un contador de puntos en formato `HH:MM`, no un reloj de pared. Se parsea como duración.

### Problemas detectados

- **`R2C_NO2.csv`** — salto temporal entre `05/01 04:14` y `05/01 16:11` (~12 h) mientras `runtime` avanza sólo de `01:13` a `01:14`. El nivel 1 (cero) queda truncado a 74 filas. Se incluye con caveat.
- **`R2B_NO.csv`** — filas 76-81: `no_gen = 0` pero las lecturas suben de 25 a 155 ppb. La etiqueta del generador va desfasada ~6 min respecto a la rampa real. Cualquier corte por `*_gen` debe validarse contra `level`.
- **NA reales** (celdas vacías, no ceros) en `R2B_NO.csv` y `R2C_NO2.csv`, filas `03:08`, `03:09`, `03:15`, `03:27`.
- **`R2A_O3.csv`** — excursiones dentro del nivel 2: `16:55` (ref 173.99 vs part 143.33) y `16:59`-`17:00` (caída a ~153/154 en ambos). Son eventos de proceso, no ruido de medida.
- **`R3_NO.csv` línea 73** — literal `Samp<` en las tres columnas del participante (estado del instrumento, no número). Obliga a leer las columnas de medida como texto y convertir de forma explícita; una lectura numérica directa lo silencia o corrompe la columna entera. Única ocurrencia; `R3_NO2.csv` no la tiene. **Se convierte a NA puntual**: sólo esa celda, sin descartar la ventana alrededor.
- **`R3_NO2.csv` nivel 2** — nominal `144`, pero **ambos** equipos leen ~154 (+6.6%). El desvío es común a referencia y participante, así que no es error de medida: sugiere que `no2_gen` en ese nivel es un setpoint y no la concentración entregada. Los niveles 3, 4 y 5 de NO2 no muestran el patrón. *Documentado por decisión; no se corrige ni se ajusta el sesgo. El nivel entra en el análisis en igualdad de condiciones con el resto.*
- **`level`** mezcla índice PT (`1`..`5`) con `estab` (transitorio). `estab` se excluye de toda estadística y se conserva sólo para las gráficas de transición.
- **No hay cero repetido al final** de ninguna ronda. No es posible estimar deriva de cero intra-ronda. Limitación a declarar en el informe.

### Niveles nominales (`*_gen`)

| Ronda | Analito | L1 | L2 | L3 | L4 | L5 | Unidad |
|---|---|---|---|---|---|---|---|
| R1 | SO2 | 0 | 179 | 119 | 80 | 40 | ppb |
| R1 | CO | 0 | 6.3 | 4.2 | 2.8 | 1.4 | ppm |
| R2A | O3 | 0 | 180 | 120 | 80 | 40 | ppb |
| R2B | NO | 0 | 180 | 119 | 78 | 37 | ppb |
| R2C | NO2 | 0 | 140 | 105 | 60 | 30 | ppb |
| R3 | O3 | 0 | 180 | 120 | 80 | 40 | ppb |
| R3 | NO | 0 | 179 | 119 | 80 | 41 | ppb |
| R3 | NO2 | 0 | 144 | 112 | 64 | 32 | ppb |

`level` es el índice PT 1..5, no la concentración nominal.

**Verificado.** Sólo O3 conserva los mismos nominales entre R2 y R3. NO cambia en los niveles 4 y 5; NO2 en todos.

Criterio de comparabilidad adoptado:

| Analito | Nivel | R2 | R3 | Δ | Decisión |
|---|---|---|---|---|---|
| O3 | 1 (cero) | 0 | 0 | — | mantenido, comparación en absoluto |
| O3 | 2–5 | — | — | 0% | comparable en concentración y error relativo |
| NO | 1 (cero) | 0 | 0 | — | mantenido, comparación en absoluto |
| NO | 2 | 180 | 179 | −0.6% | tolerado |
| NO | 3 | 119 | 119 | 0% | tolerado |
| NO | 4 | 78 | 80 | +2.6% | tolerado |
| NO | 5 | 37 | 41 | +10.8% | tolerado |
| NO2 | 1 (cero) | 0 | 0 | — | **mantenido**, comparación en absoluto |
| NO2 | 2 | 140 | 144 | +2.9% | tolerado |
| NO2 | 3 | 105 | 112 | +6.7% | **excluido del bloque C** |
| NO2 | 4 | 60 | 64 | +6.7% | tolerado |
| NO2 | 5 | 30 | 32 | +6.7% | tolerado |

- **O3 y NO**: comparables en concentración y en error relativo.
- **NO2**: error relativo en los niveles 2, 4 y 5; **sin el nivel 3**.
- **El nivel 1 (cero) se mantiene en los tres analitos**, incluido NO2. El nominal es cero, así que no admite error relativo: se compara en unidades absolutas (ppb), tanto dentro de ronda como entre rondas. Es el único nivel con nominal idéntico en R2 y R3 para los tres analitos, lo que lo vuelve el punto de cruce más limpio de toda la matriz.

Nota sobre el criterio: los niveles 3, 4 y 5 de NO2 tienen el mismo Δ relativo (+6.7%); la exclusión del 3 responde a la magnitud absoluta del salto (7 ppb frente a 4 y 2 ppb), no al porcentaje.

### Estructura multicanal en R3_NO y R3_NO2

`R3_NO.csv` y `R3_NO2.csv` tienen 10 columnas, no 6:

```
date time, no_4UDY72, no2_4UDY72, nox_4UDY72, no_ZFT5R6, no2_ZFT5R6, nox_ZFT5R6, runtime, level, <analito>_gen
```

Seis canales de medida: NO, NO2 y NOx para cada equipo. `R2B_NO.csv` y `R2C_NO2.csv` traen un solo canal. Implicaciones:

- Analito bajo prueba: `no_*` en `R3_NO`, `no2_*` en `R3_NO2`. Los demás canales son concomitantes.
- Habilita verificación de conservación de NOx (`NO + NO2 ≈ NOx`) en R3, imposible en R2 (bloque E).
- En `R3_NO2` el canal NO queda en ~155 ppb: NO residual de la titulación en fase gas. Esperado; no confundir con el analito.
- El ingest debe manejar ambos anchos de tabla.

### Conteos y cobertura R3

| Archivo | Filas | L1 | L2 | L3 | L4 | L5 | estab | Rango |
|---|---|---|---|---|---|---|---|---|
| `R3_NO.csv` | 886 | 60 | 170 | 180 | 170 | 171 | 135 | 07/16 08:00 – 07/16 22:45 |
| `R3_NO2.csv` | 781 | 60 | 140 | 170 | 170 | 171 | 70 | 07/16 08:00 – 07/17 11:00 |

## 2. Métricas

Estadística calculada sólo sobre `level %in% 1:5` y `!flag_transient`. Se reporta cuántos puntos se descartan por nivel.

### Bloque A — Desempeño por nivel (dentro de cada ronda-analito)

Por `(ronda, analito, nivel, rol)`:

- `n`, media, sd, CV%
- sesgo vs nominal: `mean(valor) - nominal`, y relativo `%`
- diferencia ref − participante: media, sd
- Bland-Altman: LoA = media ± 1.96·sd
- deriva intra-nivel: pendiente de `valor ~ runtime_min` por rol, con IC 95%

La deriva intra-nivel captura el drift visible a ojo en SO2 nivel 2 (178 sube a 182 y regresa a lo largo de ~3 h).

### Bloque B — Comparación de ceros entre analitos y rondas

Tabla, **separada por unidad** (una para ppb, otra para CO en ppm):

```
ronda | analito | rol | n | media_cero | sd_cero | min | max | drift (unidad/h) | flags
```

Preguntas que responde:

- ¿El cero de la referencia 4U es más limpio que el del participante, en todos los analitos?
- ¿Qué analito tiene el peor cero? (inspección preliminar: O3 en R2A muestra en la referencia un offset sistemático de ~−0.8 ppb, que es sesgo, no ruido)
- ¿El problema de cada cero es **offset** (media ≠ 0) o **ruido** (sd alto)? Se reportan como métricas separadas, nunca combinadas.
- Caveat obligatorio: `R2C_NO2` tiene `n` reducido por el gap temporal; su sd no es comparable en igualdad de condiciones con el resto.

### Bloque C — Matriz completa R2 × R3

Cuatro series a comparar entre sí: `ref_R2`, `P1` (en R2), `ref_R3`, `P2` (en R3). Pares: `R2A_O3`↔`R3_O3`, `R2B_NO`↔`R3_NO`, `R2C_NO2`↔`R3_NO2`.

**Distinción metodológica que gobierna todo el bloque.** Los pares se dividen en dos clases con estadística distinta:

- **Intra-ronda** (`ref_R2`↔`P1`, `ref_R3`↔`P2`): mismo minuto, misma mezcla de gas, mismo nivel. Datos **apareados punto a punto**. Admiten diferencia pareada, Bland-Altman, correlación.
- **Inter-ronda** (los otros cuatro pares): fechas distintas, mezclas de gas distintas y, en NO y NO2, **nominales distintos**. **No hay apareamiento posible.** Sólo se comparan estadísticos agregados por nivel, en **error relativo** `(valor − nominal)/nominal` para los niveles 2–5, y en **unidades absolutas** para el nivel 1 (nominal cero). Comparar concentraciones crudas entre rondas en los niveles 2–5 sería un artefacto del nominal, no una diferencia de equipo; en el cero no existe ese riesgo, porque el nominal es idéntico.

Matriz de las 6 comparaciones:

| # | Par | Clase | Estadístico | Interpretación |
|---|---|---|---|---|
| C1 | `ref_R2` ↔ `ref_R3` | inter | Δ error relativo por nivel; Levene | **Deriva del 4U a ~2.5 meses.** Resultado principal |
| C2 | `ref_R2` ↔ `P1` | intra | dif. pareada, Bland-Altman, LoA | Desempeño de P1 en su ronda |
| C3 | `ref_R3` ↔ `P2` | intra | dif. pareada, Bland-Altman, LoA | Desempeño de P2 en su ronda |
| C4 | `ref_R2` ↔ `P2` | inter | Δ error relativo por nivel | P2 contra la referencia **tal como estaba en R2**. Aísla cuánto de la brecha P2 se explica por deriva del 4U |
| C5 | `ref_R3` ↔ `P1` | inter | Δ error relativo por nivel | Simétrico de C4: P1 contra la referencia ya derivada |
| C6 | `P1` ↔ `P2` | inter | Δ error relativo por nivel | Comparación entre laboratorios. **Descriptivo**, n=1 ronda cada uno |

Lectura conjunta que hace útil la matriz: C2 y C3 dan la brecha de cada participante contra su propia referencia. C1 da el desplazamiento de la referencia. Si `C3 − C2 ≈ C1`, la diferencia aparente entre participantes se explica por la deriva del equipo de referencia, no por los laboratorios. Si no cierra, hay diferencia real entre P1 y P2. Ése es el cruce que responde la pregunta de fondo.

**Restricción sobre C6.** Se reporta como descripción, sin contraste formal: dos laboratorios, una ronda cada uno, mezclas de gas distintas. No sostiene inferencia.

**Comparabilidad por analito:**

| Analito | Nominales R2 vs R3 | Bloque C en | Niveles |
|---|---|---|---|
| O3 | idénticos | concentración **y** error relativo | 1, 2, 3, 4, 5 |
| NO | diferencias toleradas | concentración **y** error relativo | 1, 2, 3, 4, 5 |
| NO2 | difieren en los niveles 2–5 | sólo error relativo | **1**, 2, 4, 5 — sin el nivel 3 |

El nivel 1 entra en el bloque C para los tres analitos, comparado en **unidades absolutas** (nominal cero, sin error relativo posible). Única exclusión: nivel 3 de NO2.

### Bloque E — Canales concomitantes NO/NO2/NOx (sólo R3)

`R3_NO.csv` y `R3_NO2.csv` traen 6 columnas de medida (NO, NO2, NOx por equipo); `R2B`/`R2C` sólo una. Aprovechable únicamente en R3:

- **Conservación de NOx**: residuo `NO + NO2 − NOx` por equipo y nivel. Debe ser ~0; una desviación sistemática indica problema de canal, no de la mezcla.
- **Canal concomitante**: en `R3_NO2` el canal NO queda en ~155 ppb (NO residual de la titulación en fase gas). Se documenta, no se interpreta como analito.

No hay equivalente en R2. Es un chequeo unilateral de R3, no una comparación entre rondas.

### Bloque D — Caracterización del participante P1 a través de R1 y R2

Mismo participante, analitos distintos (SO2/CO en R1; O3/NO/NO2 en R2), una semana de separación. No hay par por analito, así que se comparan métricas independientes del analito:

- ruido de cero (sd del nivel 1)
- signo y magnitud del sesgo relativo por nivel
- pendiente de deriva intra-nivel

Salida descriptiva: ¿P1 se comporta de forma consistente entre rondas, o su desempeño depende del analito? Sin contraste estadístico formal — la comparación cruza analitos y unidades.

## 3. Figuras

| ID | Contenido |
|---|---|
| P1 | Serie temporal por ronda-analito: valor vs `runtime`, dos líneas (ref/participante), bandas por nivel, línea en nominal, zona `estab` en gris. 8 figuras |
| P2 | Facetas por nivel: zoom de cada nivel estable, `facet_wrap(~level, scales="free_y")`, con media y ±2sd |
| P3 | Ceros comparados: boxplot + puntos crudos, facet por ronda-analito. **Dos versiones: una ppb, una ppm (CO)** |
| P4 | Bland-Altman ref vs participante, facet por ronda-analito, color por nivel |
| P5 | **Matriz C**: error relativo vs nivel (niveles 2–5), las 4 series (`ref_R2`, `P1`, `ref_R3`, `P2`) superpuestas, un panel por analito (O3, NO, NO2). Figura central del bloque C — de aquí se leen las 6 comparaciones a la vez |
| P5c | Nivel 1 (cero) de las 4 series en **ppb absolutos**, un panel por analito. Complementa P5, que por definición no puede representar el cero en error relativo |
| P5b | Descomposición `C3 − C2` frente a `C1` por analito y nivel: ¿la brecha entre participantes se explica por la deriva de la referencia? |
| P6 | Desempeño de la referencia: sesgo relativo del 4U vs nominal, eje x = nivel nominal. **Dos versiones: ppb y ppm** |
| P7 | Participante P1 a través de R1 y R2: sesgo relativo y ruido de cero por analito, agrupado por ronda. Descriptivo |
| P8 | Conservación de NOx en R3: residuo `NO + NO2 − NOx` por equipo y nivel. Sólo R3 |

## 4. Limitaciones a declarar en el informe

1. Sin cero de cierre: no hay estimación de deriva de cero intra-ronda.
2. `R2C_NO2` con cero truncado (gap de ~12 h).
3. `R2B_NO` con etiqueta de generador desfasada ~6 min en la rampa inicial.
4. R1 no tiene ronda equivalente por analito; SO2 y CO entran en los bloques A, B y D, nunca en C.
5. CO se reporta en ppm y no se compara numéricamente contra los analitos en ppb.
6. Participante distinto entre R2 y R3: ninguna diferencia observada en el participante puede atribuirse a deriva. Sólo la referencia da continuidad temporal.
7. n = 1 ronda por participante. Las comparaciones entre laboratorios (C6) son descriptivas.
8. Nominales distintos entre R2 y R3. Las diferencias de NO se aceptan como tolerables; NO2 se compara sólo en error relativo y **sin el nivel 3** (105 vs 112).
9. Las comparaciones inter-ronda no están apareadas en el tiempo ni comparten mezcla de gas. Sin Bland-Altman ni correlación para C1, C4, C5, C6.
10. `R3_NO2` nivel 2: nominal declarado 144, ~154 medido en ambos equipos. Documentado, sin corrección. El sesgo de ese nivel se reporta tal cual se calcula.
11. Conservación de NOx (bloque E) sólo verificable en R3; R2 es monocanal.

## 5. Decisiones cerradas

Todas las decisiones de diseño están tomadas. Resumen para trazabilidad en el informe:

| Tema | Decisión |
|---|---|
| Unidades | CO (ppm) separado del resto (ppb). Sin normalizar a fracción de span |
| `R2C_NO2` cero truncado | incluido, con caveat de `n` reducido |
| Equipo de referencia | mismo 4U en las tres rondas; R2↔R3 se interpreta como deriva |
| Participantes | P1 en R1 y R2; P2 en R3 |
| NO, nominales R2 vs R3 | diferencias toleradas; comparable en concentración |
| NO2 nivel 3 | excluido del bloque C (105 vs 112) |
| NO2 niveles 1, 2, 4, 5 | mantenidos |
| Nivel 1 (cero), los tres analitos | mantenido en el bloque C, comparado en unidades absolutas |
| `R3_NO2` nivel 2, nominal | documentado, sin corrección de sesgo |
| Sesgos | no se ajustan en ningún nivel |
| `Samp<` | NA puntual, sin descartar la ventana |

Sin pendientes bloqueantes. Listo para implementar según `workflow_analisis.md`.
