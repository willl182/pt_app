# Guia de Validacion del Algoritmo A (Winsorizacion)

**Referencia:** ISO 13528:2022, Anexo C
**Aplicativo:** PT App (CALAIRE / UNAL-INM)

---

## 1. Descripcion del Algoritmo A

El Algoritmo A de ISO 13528:2022 calcula estimaciones robustas de ubicacion (x*)
y escala (s*) mediante **winsorizacion iterativa**. No usa pesos de Huber.

### Pasos del algoritmo

1. **Inicializar:** x* = mediana(xi), s* = 1.483 × MAD(xi)
2. **Calcular delta:** δ = 1.5 × s*
3. **Winsorizar:** Para cada participante i:
   - Si xi < x* − δ → x*_i = x* − δ
   - Si xi > x* + δ → x*_i = x* + δ
   - Si no → x*_i = xi (sin cambio)
4. **Actualizar:**
   - x* = (1/p) × Σ x*_i  (media aritmetica de valores winzorizados)
   - s* = 1.134 × √( (1/(p−1)) × Σ(x*_i − x*)² )  (SD corregida)
5. **Repetir** desde paso 2 hasta convergencia

**Factor 1.134:** Corrige el sesgo introducido por la winsorizacion.

**Convergencia:** max(|Δx*|, |Δs*|) < tolerancia (1×10⁻⁶)

---

## 2. Que contiene la hoja de calculo

Cada archivo `AlgoritmoA_Validacion_<nombre>.xlsx` tiene:

| Hoja | Contenido |
|------|-----------|
| **INDICE** | Metadata general, indice de hojas con x* y s* finales |
| **FORMULAS** | Referencia completa de las formulas con citas ISO |
| **AlgoA_1** ... **AlgoA_N** | Una hoja por cada combinacion analito/nivel |
| **RESUMEN** | Tabla comparativa de todas las combinaciones |

Cada hoja `AlgoA_N` tiene 6 secciones:

1. **Datos de entrada** — Media por participante (excl. referencia)
2. **Valores iniciales** — x*₀ (mediana) y s*₀ (MADe) con formula
3. **Resumen de iteraciones** — x*/s* previo/nuevo, delta, limites, n winzorizados
4. **Detalle por participante por iteracion** — valor original, winzorizado, limites
5. **Valores finales por participante** — original vs winzorizado tras convergencia
6. **Resultado final** — x*, s*, u(x_pt), convergencia, n winzorizados

---

## 3. Archivos de datos compatibles

El script acepta cualquier CSV con las columnas:

```
pollutant, run, level, participant_id, replicate, sample_group, mean_value, sd_value
```

Archivos disponibles en `data/`:

| Archivo | Participantes por combo | Combos | Nota |
|---------|------------------------|--------|------|
| `summary_n4.csv` | 3 | 30 | n=3: algoritmo ejecuta pero pocos datos |
| `summary_n7.csv` | — | — | Verificar estructura antes de usar |
| `summary_n10.csv` | — | — | Verificar estructura antes de usar |
| `summary_n13.csv` | 12 | 31 | n=12: cumple recomendacion ISO (n>=12) |

**Importante:** ISO 13528 recomienda el Algoritmo A para n >= 12. Con n = 3 (summary_n4) el algoritmo ejecuta pero los resultados son menos confiables. Para validacion formal, usar preferiblemente **summary_n13**.

---

## 4. Como generar las hojas

```bash
# Opcion 1: usa summary_n4.csv por defecto
Rscript validation/generate_algoA_validation.R

# Opcion 2: especificar archivo
Rscript validation/generate_algoA_validation.R data/summary_n13.csv

# Opcion 3: cualquier otro CSV con la misma estructura
Rscript validation/generate_algoA_validation.R data/summary_n7.csv
```

La salida se guarda en `validation/AlgoritmoA_Validacion_<nombre>.xlsx`.

---

## 5. Como validar paso a paso

### 5.1 Preparar los datos de entrada

El CSV tiene multiples filas por participante (una por grupo de muestras: 1-10, 11-20, 21-30). El app **promedia** para obtener un solo valor por participante:

```
valor_participante = PROMEDIO(mean_value) agrupado por (pollutant, run, level, participant_id)
```

**En Excel:**
1. Abrir el CSV
2. Filtrar por el analito y nivel deseado
3. Excluir filas con `participant_id = "ref"`
4. Para cada participante, calcular `=PROMEDIO()` de sus filas `mean_value`
5. Comparar contra la columna `Valor_xi` en Seccion 1

### 5.2 Verificar valores iniciales (iteracion 0)

En la Seccion 2 de cada hoja:

| Parametro | Formula Excel | Formula R |
|-----------|--------------|-----------|
| x*₀ | `=MEDIANA(rango_valores)` | `median(xi)` |
| s*₀ | `=1.483*MEDIANA(ABS(rango - MEDIANA(rango)))` | `1.483 * median(abs(xi - median(xi)))` |

### 5.3 Verificar cada iteracion (winsorizacion)

Para cada iteracion k, verificar en la Seccion 4 (detalle por participante):

| Paso | Formula Excel | Columna en hoja |
|------|--------------|-----------------|
| Delta | `=1.5 * s_star` | `delta` |
| Limite inferior | `=x_star - delta` | `Lim_inf` |
| Limite superior | `=x_star + delta` | `Lim_sup` |
| Winsorizar | `=MAX(MIN(xi, Lim_sup), Lim_inf)` | `Winsorizado` |
| Fue winzorizado? | `=O(xi < Lim_inf, xi > Lim_sup)` | `Fue_winsor` |

Y en la Seccion 3 (resumen de iteraciones):

| Paso | Formula Excel | Columna |
|------|--------------|---------|
| x*_nuevo | `=PROMEDIO(winzorizados)` | `x*_new` |
| s*_nuevo | `=1.134 * DESVEST(winzorizados)` | `s*_new` |
| delta_x | `=ABS(x_nuevo - x_prev)` | `delta_x` |
| delta_s | `=ABS(s_nuevo - s_prev)` | `delta_s` |
| delta_max | `=MAX(delta_x, delta_s)` | `delta_max` |

**Nota sobre DESVEST:** Usar `DESVEST()` (con denominador p−1, desviacion estandar muestral), NO `DESVEST.P()` (denominador p). El factor 1.134 se aplica sobre la SD muestral.

**Convergencia:** El algoritmo para cuando `delta_max < 0.000001`.

### 5.4 Verificar valores finales por participante

En la Seccion 5, se muestran los valores originales y winzorizados con los x*, s* finales. Las filas con `Fue_winsorizado = TRUE` son las observaciones que fueron recortadas.

### 5.5 Verificar resultado final

En la Seccion 6:

| Parametro | Formula |
|-----------|---------|
| x* | Media aritmetica de valores winzorizados finales |
| s* | 1.134 × DESVEST(winzorizados finales) |
| u(x_pt) | `= 1.25 × s* / RAIZ(n)` |

---

## 6. Procedimiento sugerido para Cesar

1. **Abrir** `AlgoritmoA_Validacion_summary_n13.xlsx` (preferible por n=12)
2. **Elegir** una hoja (ej: AlgoA_1 = CO 0 umol/mol)
3. **Copiar** los valores de la Seccion 1 (datos de entrada) a su propia hoja
4. **Implementar** las formulas de la Seccion 5.2 (valores iniciales)
5. **Implementar** una iteracion completa:
   - Calcular delta = 1.5 × s*
   - Winsorizar cada valor: `=MAX(MIN(xi, x*+delta), x*-delta)`
   - Calcular x* = PROMEDIO(winzorizados)
   - Calcular s* = 1.134 × DESVEST(winzorizados)
6. **Arrastrar** las formulas para las siguientes iteraciones
7. **Comparar** celda por celda contra la hoja de validacion
8. **Documentar** discrepancias
9. **Repetir** con 2-3 combinaciones de diferentes analitos

### Criterios de aceptacion

| Que verificar | Precision minima |
|---------------|-----------------|
| x*₀, s*₀ (valores iniciales) | Coincidencia exacta |
| Valores winzorizados | 9 decimales |
| x*, s* finales | 6 decimales |
| Numero de iteraciones | Identico |
| Convergencia (SI/NO) | Identico |
| n observaciones winzorizadas | Identico |

---

## 7. Equivalencia de funciones Excel / R

| Concepto | Excel | R |
|----------|-------|---|
| Mediana | `MEDIANA()` | `median()` |
| Media aritmetica | `PROMEDIO()` | `mean()` |
| Desviacion estandar (p−1) | `DESVEST()` | `sd()` |
| Valor absoluto | `ABS()` | `abs()` |
| Raiz cuadrada | `RAIZ()` | `sqrt()` |
| Minimo/Maximo | `MIN()`, `MAX()` | `min()`, `max()` |
| Clamp (winsorizar) | `=MAX(MIN(x, sup), inf)` | `pmax(pmin(x, sup), inf)` |
| Contar condicion | `CONTAR.SI()` | `sum(condicion)` |

---

## 8. Notas tecnicas

- **Participante "ref"**: siempre se excluye. Es el valor de referencia, no un participante.
- **Agregacion**: cada participante puede tener multiples filas (grupos de muestras). Se promedian antes de entrar al algoritmo.
- **Tolerancia**: 1×10⁻⁶ (mas estricta que el minimo ISO de 0.001 en tercera cifra decimal).
- **Max iteraciones**: 50 por defecto. Si no converge en 50, se reporta como no convergido.
- **Factor 1.134**: Proviene de la teoria de estimadores robustos; corrige el sesgo que introduce la winsorizacion al truncar la distribucion. Sin este factor, s* subestimaria la dispersion real.
- **Caso s*=0**: Si todos los valores son identicos, MADe=0 y se usa SD clasica como fallback. Si tambien es 0, se reporta convergencia inmediata con s*=0.
- **Diferencia con pesos de Huber**: Implementaciones anteriores usaban pesos 1/u². ISO 13528 Anexo C especifica explicitamente winsorizacion (reemplazo de valores, no ponderacion). Ambos enfoques son robustos pero producen resultados numericos distintos.
