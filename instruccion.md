# Instrucción: Organización de datos para Homogeneidad y Estabilidad

## Contexto normativo

Los cálculos siguen la norma **ISO 13528:2022**, Sección 9.2 (Homogeneidad) y Sección 9.3 (Estabilidad). El propósito es verificar que los materiales de referencia distribuidos a los participantes son suficientemente homogéneos y estables para que las diferencias observadas entre participantes reflejen la variación interlaboratorio y no la variación del material.

---

## Archivos requeridos

| Archivo              | Propósito                                                    |
|----------------------|--------------------------------------------------------------|
| `homogeneity.csv`    | Datos del estudio de homogeneidad: variación entre unidades del mismo lote |
| `stability.csv`      | Datos del estudio de estabilidad: variación entre dos momentos de medición |

Ambos archivos usan exactamente las mismas **seis columnas** en formato largo (*long format*):

```
pollutant, run, level, replicate, sample_id, value
```

---

## Descripción de columnas

### `pollutant` — Contaminante

Identificador del analito medido. Ejemplos usados en este proyecto:

| Valor   | Analito                    |
|---------|----------------------------|
| `co`    | Monóxido de carbono        |
| `no`    | Óxido nítrico              |
| `no2`   | Dióxido de nitrógeno       |
| `o3`    | Ozono                      |
| `so2`   | Dióxido de azufre          |

Cada contaminante se procesa de forma independiente.

---

### `run` — Corrida de medición

Identifica el **evento o sesión de medición**. Se escribe como `corrida_1`, `corrida_2`, etc.

- Cada corrida corresponde a **un nivel de concentración**.
- En el estudio de homogeneidad, hay tantas corridas como niveles de concentración evaluados.
- En el estudio de estabilidad, las corridas representan los diferentes **momentos en el tiempo** (por ejemplo, día 0 y día 30), con los mismos niveles de concentración.

---

### `level` — Nivel de concentración

Indica el valor nominal de concentración y su unidad. El formato es:

```
<valor>-<unidad>
```

Ejemplos:

| `level`           | Interpretación                        |
|-------------------|---------------------------------------|
| `0-μmol/mol`      | Concentración cero (blanco)           |
| `2-μmol/mol`      | 2 micromoles por mol (CO, NO, etc.)   |
| `121-nmol/mol`    | 121 nanomoles por mol (NO, O3, etc.)  |
| `500-μg/m3`       | 500 microgramos por metro cúbico      |

> **Regla clave:** la combinación `(pollutant, run, level)` identifica de forma única un bloque de mediciones sobre el que se aplica el análisis de varianza (ANOVA).

---

### `replicate` — Réplica

Número entero que indica la **réplica de medición** de cada unidad (ítem o muestra).

- El valor mínimo es `1` y el máximo es `m` (número de réplicas por ítem).
- El diseño estándar de ISO 13528:2022 usa **m = 2** réplicas por ítem.
- Las réplicas deben medirse de forma independiente (diferente inyección, lectura o alícuota).

---

### `sample_id` — Identificador de muestra (ítem)

Número entero que identifica cada unidad individual dentro del bloque `(pollutant, run, level)`.

- Va de `1` a `g`, donde `g` es el número total de ítems del estudio.
- El diseño estándar usa **g = 13** ítems (para homogeneidad con el diseño de la norma).
- El mismo `sample_id` aparece una vez por cada réplica (la combinación `sample_id + replicate` es única dentro del bloque).

---

### `value` — Valor medido

Valor numérico de la medición, en las unidades del nivel de concentración. Puede ser:

- El valor absoluto medido por el instrumento.
- Un valor calculado como diferencia respecto a un patrón.
- Un valor negativo si la respuesta está por debajo del cero de referencia.

---

## Estructura del bloque de datos

Para un contaminante, una corrida y un nivel, los datos forman una tabla `g × m` implícita:

```
             replicate=1   replicate=2
sample_id=1    value₁₁       value₁₂
sample_id=2    value₂₁       value₂₂
    ...           ...           ...
sample_id=g    valueg₁       valueg₂
```

En el archivo CSV esto se representa en formato largo (una fila por celda):

```csv
pollutant,run,level,replicate,sample_id,value
co,corrida_1,0-μmol/mol,1,1,0.00670212766
co,corrida_1,0-μmol/mol,1,2,0.004787234043
...
co,corrida_1,0-μmol/mol,2,1,-0.04796226415
co,corrida_1,0-μmol/mol,2,2,-0.04884905660
...
```

> **Orden recomendado:** ordenar primero por `replicate` y luego por `sample_id` dentro de cada bloque, aunque el código acepta cualquier orden.

---

## Diferencias entre `homogeneity.csv` y `stability.csv`

| Característica              | `homogeneity.csv`                          | `stability.csv`                              |
|-----------------------------|--------------------------------------------|----------------------------------------------|
| **Número de ítems (g)**     | Típicamente 7–20 (estándar: 13)            | Típicamente 2–5 (puede ser menor que homog.) |
| **Número de réplicas (m)**  | 2 (estándar ISO)                           | 2 (mismo diseño)                             |
| **Qué representa cada run** | Una sesión de análisis de un nivel         | Un momento en el tiempo para ese nivel       |
| **Cuándo se mide**          | Al inicio, antes de distribuir el material | Después de un período (días, semanas, meses) |
| **Propósito**               | Verificar variación entre unidades         | Verificar que el material no cambió con el tiempo |

### Ejemplo: `homogeneity.csv` (g=13 ítems, m=2 réplicas)

```csv
pollutant,run,level,replicate,sample_id,value
co,corrida_1,0-μmol/mol,1,1,0.0067021
co,corrida_1,0-μmol/mol,1,2,0.0047872
co,corrida_1,0-μmol/mol,1,3,-0.0492830
...
co,corrida_1,0-μmol/mol,1,13,-0.0488679
co,corrida_1,0-μmol/mol,2,1,-0.0479622
co,corrida_1,0-μmol/mol,2,2,-0.0488490
...
co,corrida_1,0-μmol/mol,2,13,0.0035319
```

Total de filas por bloque: `g × m = 13 × 2 = 26 filas`

### Ejemplo: `stability.csv` (g=2 ítems, m=2 réplicas)

```csv
pollutant,run,level,replicate,sample_id,value
co,corrida_1,0-μmol/mol,1,1,-0.0480754717
co,corrida_1,0-μmol/mol,1,2,0.0051489362
co,corrida_1,0-μmol/mol,2,1,-0.0494150943
co,corrida_1,0-μmol/mol,2,2,0.0033191489
```

Total de filas por bloque: `g × m = 2 × 2 = 4 filas`

---

## Relación entre los dos estudios

El cálculo de **estabilidad requiere resultados previos del estudio de homogeneidad**. Específicamente:

- `general_mean_homog`: media general de todos los valores del estudio de homogeneidad para ese contaminante y nivel.
- `x_pt`: mediana de los valores de la réplica 1 del estudio de homogeneidad (valor asignado de referencia).
- `sigma_pt`: estimación robusta de la desviación estándar del proceso (MADe del estudio de homogeneidad).

Estos tres parámetros son entradas al módulo de estabilidad. Por eso, **siempre se debe ejecutar el cálculo de homogeneidad antes que el de estabilidad**.

---

## Criterios de evaluación calculados

### Homogeneidad (ISO 13528:2022, Sección 9.2)

| Métrica           | Fórmula                                             | Criterio de aceptación        |
|-------------------|-----------------------------------------------------|-------------------------------|
| `ss`              | √(s²ₓ̄ − s²w/m)  — componente entre muestras       | `ss ≤ c` (criterio simple)    |
| `c`               | 0.3 × σ_pt                                          | Criterio simple               |
| `c_expandido`     | √(F₁ × c² + F₂ × sw²)   con tabla F₁,F₂ por g     | Criterio expandido (Apéndice B) |

El material se considera **homogéneo** si `ss ≤ c` (o `ss ≤ c_expandido` en el criterio extendido).

### Estabilidad (ISO 13528:2022, Sección 9.3)

| Métrica              | Fórmula                                                        | Criterio de aceptación |
|----------------------|----------------------------------------------------------------|------------------------|
| `diff_hom_stab`      | \|media_estab − media_homog\|                                  | `diff ≤ c_stab`        |
| `c_stab`             | 0.3 × σ_pt                                                     | Criterio simple        |
| `c_stab_expandido`   | c + 2 × √(u²_homog + u²_estab)                                 | Criterio expandido     |

El material se considera **estable** si `diff_hom_stab ≤ c_stab`.

---

## Reglas para construir los archivos CSV

1. **Formato:** CSV con coma (`,`) como separador. Codificación UTF-8 (necesario para los símbolos μ y otros).
2. **Encabezado:** La primera fila debe ser exactamente: `pollutant,run,level,replicate,sample_id,value`
3. **Sin valores faltantes:** Todos los campos deben estar completos. El campo `value` debe ser numérico.
4. **Consistencia de g y m:** Dentro de cada bloque `(pollutant, run, level)`, todos los `sample_id` deben tener el mismo número de réplicas y todas las réplicas deben tener el mismo número de ítems.
5. **`level` como cadena de texto:** El nivel debe incluir siempre la unidad separada por guión, por ejemplo `4-μmol/mol`. No usar solo el número.
6. **`run` como cadena de texto:** Usar el formato `corrida_N` donde N es el número de secuencia. No usar números solos.
7. **Un contaminante por fila:** No mezclar contaminantes en el mismo bloque. El campo `pollutant` diferencia los análisis.
8. **Homogeneidad primero:** Los datos de estabilidad se procesan usando parámetros derivados de los datos de homogeneidad. Ambos archivos deben cubrir los mismos contaminantes y niveles.

---

## Verificación rápida de la estructura

Antes de cargar los archivos, verificar que para cada combinación `(pollutant, run, level)`:

- Existen exactamente `g × m` filas (por ejemplo, `13 × 2 = 26` para el diseño estándar de homogeneidad).
- Los valores de `replicate` son enteros consecutivos de 1 a m.
- Los valores de `sample_id` son enteros consecutivos de 1 a g.
- No hay combinaciones duplicadas de `(replicate, sample_id)`.
