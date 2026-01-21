# Guía de Validación de Cálculos - PT App y ptcalc

Esta guía proporciona instrucciones detalladas para validar los cálculos implementados en la aplicación PT App y el paquete ptcalc utilizando hojas de cálculo. Los cálculos siguen las normas ISO 13528:2022 e ISO 17043:2023.

## Índice

1. [Datos de Entrada](#datos-de-entrada)
2. [Estadísticos Robustos](#estadísticos-robustos)
3. [Evaluación de Homogeneidad](#evaluación-de-homogeneidad)
4. [Evaluación de Estabilidad](#evaluación-de-estabilidad)
5. [Algoritmo A](#algoritmo-a)
6. [Puntajes PT](#puntajes-pt)
7. [Hojas de Cálculo de Validación](#hojas-de-cálculo-de-validación)

---

## Datos de Entrada

### Archivos Utilizados

| Archivo | Descripción | Columnas |
|---------|-------------|----------|
| `homogeneity.csv` | Datos de homogeneidad | pollutant, level, replicate, sample_id, value |
| `stability.csv` | Datos de estabilidad | pollutant, level, replicate, sample_id, value |
| `summary_n4.csv` | Datos consolidados participantes | pollutant, level, participant_id, replicate, sample_group, mean_value, sd_value |

### Estructura de Datos

Los datos se organizan en formato "largo" (long format) donde cada fila representa una medición individual.

---

## Estadísticos Robustos

### 1. MADe (Median Absolute Deviation escalada)

**Fórmula:**
```
MADe = 1.483 × mediana(|xi - mediana(x)|)
```

**Pasos en hoja de cálculo:**

1. Calcular la mediana de los datos: `=MEDIANA(rango_datos)`
2. Calcular diferencias absolutas: `=ABS(xi - mediana)`
3. Calcular la mediana de las diferencias: `=MEDIANA(diferencias)`
4. Multiplicar por 1.483: `=1.483 * mediana_diferencias`

**Ejemplo (CO, nivel 0-μmol/mol, sample_1):**

| Paso | Fórmula Excel | Valor |
|------|---------------|-------|
| Datos sample_1 | A2:A11 | (10 valores) |
| Mediana | `=MEDIANA(A2:A11)` | -0.04810 |
| Diferencias abs | `=ABS(A2-$D$2)` | (columna B) |
| Mediana dif abs | `=MEDIANA(B2:B11)` | 0.02415 |
| MADe | `=1.483*D3` | 0.03581 |

### 2. nIQR (Rango Intercuartil Normalizado)

**Fórmula:**
```
nIQR = 0.7413 × IQR = 0.7413 × (Q3 - Q1)
```

**Pasos en hoja de cálculo:**

1. Calcular Q1: `=CUARTIL(rango, 1)` o `=PERCENTIL(rango, 0.25)`
2. Calcular Q3: `=CUARTIL(rango, 3)` o `=PERCENTIL(rango, 0.75)`
3. Calcular IQR: `=Q3 - Q1`
4. Multiplicar por 0.7413: `=0.7413 * IQR`

---

## Evaluación de Homogeneidad

### Fórmulas Principales

#### Desviación estándar entre muestras (ss)

Para m=2 réplicas:

```
s_x̄² = VAR(medias_por_item)
sw = √(Σwi² / (2×g))  donde wi = |x1i - x2i|
ss² = |s_x̄² - (sw²/m)|
ss = √(ss²)
```

**Pasos en hoja de cálculo:**

| Variable | Fórmula Excel | Descripción |
|----------|---------------|-------------|
| Media por ítem | `=(sample_1 + sample_2)/2` | Promedio de las 2 réplicas |
| Rango por ítem | `=ABS(sample_1 - sample_2)` | Diferencia absoluta |
| Media general | `=PROMEDIO(medias)` | x̄̄ |
| s_x̄² | `=VAR(medias)` | Varianza de medias |
| sw | `=RAIZ(SUMA(rangos²)/(2*g))` | Desv estándar intra-muestra |
| ss² | `=ABS(s_x̄² - sw²/m)` | Varianza entre muestras |
| ss | `=RAIZ(ss²)` | Desv estándar entre muestras |

#### Criterio de Homogeneidad

```
c = 0.3 × σ_pt

donde σ_pt = MADe (calculado de sample_1)
```

**Criterio:** El ítem es suficientemente homogéneo si `ss ≤ c`

#### Criterio Expandido

```
c_expanded = √(σ_allowed² × 1.88 + sw² × 1.01)

donde σ_allowed² = c²
```

### Tabla de Validación Homogeneidad

| Parámetro | Símbolo | Fórmula | Valor Esperado |
|-----------|---------|---------|----------------|
| Número de ítems | g | COUNT(sample_id) | 10 |
| Número de réplicas | m | 2 | 2 |
| Mediana | med | MEDIANA(sample_1) | - |
| MADe (σ_pt) | σ_pt | 1.483 × MAD | - |
| Varianza de medias | s_x̄² | VAR(medias) | - |
| Desv estándar intra | sw | √(Σw²/(2g)) | - |
| Desv estándar entre | ss | √(s_x̄² - sw²/m) | - |
| Criterio | c | 0.3 × σ_pt | - |
| Evaluación | - | ss ≤ c ? | CUMPLE/NO CUMPLE |

---

## Evaluación de Estabilidad

### Fórmulas Principales

```
Diferencia = |media_estabilidad - media_homogeneidad|
c_stab = 0.3 × σ_pt

Criterio: Diferencia ≤ c_stab
```

#### Criterio Expandido de Estabilidad

```
u_hom_mean = SD(datos_hom) / √n_hom
u_stab_mean = SD(datos_stab) / √n_stab
c_stab_expanded = c_stab + 2 × √(u_hom_mean² + u_stab_mean²)
```

### Tabla de Validación Estabilidad

| Parámetro | Símbolo | Fórmula | Valor Esperado |
|-----------|---------|---------|----------------|
| Media homogeneidad | ȳ₁ | PROMEDIO(medias_hom) | - |
| Media estabilidad | ȳ₂ | PROMEDIO(medias_stab) | - |
| Diferencia | D | ABS(ȳ₁ - ȳ₂) | - |
| Criterio | c_stab | 0.3 × σ_pt | - |
| Evaluación | - | D ≤ c_stab ? | CUMPLE/NO CUMPLE |

---

## Algoritmo A

### Descripción

El Algoritmo A es un procedimiento iterativo para calcular estimaciones robustas de ubicación (x*) y escala (s*).

### Fórmulas

**Inicialización:**
```
x* = mediana(valores)
s* = 1.483 × mediana(|xi - x*|)
```

**Iteración k:**
```
u_i = (xi - x*) / (1.5 × s*)

w_i = 1          si |u_i| ≤ 1
w_i = 1/u_i²     si |u_i| > 1

x*_nuevo = Σ(wi × xi) / Σwi
s*_nuevo = √(Σ(wi × (xi - x*_nuevo)²) / Σwi)
```

**Convergencia:**
- Cuando |x*_nuevo - x*| < tolerancia Y |s*_nuevo - s*| < tolerancia

### Pasos en Hoja de Cálculo

| Iter | x* | s* | u_i | w_i | Δx* | Δs* |
|------|----|----|-----|-----|-----|-----|
| 0 | mediana | MADe | - | - | - | - |
| 1 | Σ(w×x)/Σw | √(Σw(x-x*)²/Σw) | (x-x*)/(1.5s*) | SI(ABS(u)≤1;1;1/u²) | x*₁-x*₀ | s*₁-s*₀ |
| ... | ... | ... | ... | ... | ... | ... |

---

## Puntajes PT

### Fórmulas de Puntajes

| Puntaje | Fórmula | Evaluación |
|---------|---------|------------|
| z | (x - x_pt) / σ_pt | \|z\| ≤ 2: Satisfactorio<br>\|z\| > 2 y < 3: Cuestionable<br>\|z\| ≥ 3: No satisfactorio |
| z' | (x - x_pt) / √(σ_pt² + u_xpt²) | Igual que z |
| zeta (ζ) | (x - x_pt) / √(u_x² + u_xpt²) | Igual que z |
| En | (x - x_pt) / √(U_x² + U_xpt²) | \|En\| ≤ 1: Satisfactorio<br>\|En\| > 1: No satisfactorio |

### Variables

| Variable | Descripción |
|----------|-------------|
| x | Resultado del participante (mean_value) |
| x_pt | Valor asignado (del laboratorio de referencia o consenso) |
| σ_pt | Desviación estándar para la evaluación de aptitud |
| u_xpt | Incertidumbre estándar del valor asignado |
| u_x | Incertidumbre estándar del participante (sd_value/√m) |
| U_x | Incertidumbre expandida del participante (k × u_x) |
| U_xpt | Incertidumbre expandida del valor asignado (k × u_xpt) |
| k | Factor de cobertura (típicamente 2) |

### Cálculo de u_xpt

```
u_xpt = 1.25 × MADe / √n
```

donde n = número de datos usados para calcular MADe.

---

## Hojas de Cálculo de Validación

Las siguientes hojas de cálculo están disponibles en el directorio `validation/`:

### 1. validation_homogeneity.csv

Validación paso a paso de cálculos de homogeneidad para CO, nivel 0-μmol/mol.

**Columnas:**
- Item, sample_1, sample_2, media, rango, diff_from_median, abs_diff

**Resumen:**
- Mediana, MADe, s_x̄², sw, ss, c, c_expanded, Evaluación

### 2. validation_stability.csv

Validación de cálculos de estabilidad comparando datos de homogeneidad vs estabilidad.

### 3. validation_robust_stats.csv

Validación de MADe y nIQR con datos de ejemplo.

### 4. validation_algorithm_a.csv

Validación iteración por iteración del Algoritmo A.

### 5. validation_pt_scores.csv

Validación de cálculos de puntajes z, z', zeta, En.

---

## Referencias

- ISO 13528:2022 - Statistical methods for use in proficiency testing
- ISO 17043:2023 - Conformity assessment — General requirements for proficiency testing

---

## Anexo: Fórmulas Excel/Calc

### Estadísticos Básicos

| Operación | Excel | LibreOffice Calc |
|-----------|-------|------------------|
| Mediana | `=MEDIANA(rango)` | `=MEDIAN(rango)` |
| Varianza | `=VAR(rango)` | `=VAR(rango)` |
| Desviación estándar | `=DESVEST(rango)` | `=STDEV(rango)` |
| Cuartil 1 | `=CUARTIL(rango,1)` | `=QUARTILE(rango,1)` |
| Cuartil 3 | `=CUARTIL(rango,3)` | `=QUARTILE(rango,3)` |
| Promedio | `=PROMEDIO(rango)` | `=AVERAGE(rango)` |
| Suma | `=SUMA(rango)` | `=SUM(rango)` |
| Raíz cuadrada | `=RAIZ(valor)` | `=SQRT(valor)` |
| Valor absoluto | `=ABS(valor)` | `=ABS(valor)` |
| Condicional | `=SI(cond,v1,v2)` | `=IF(cond,v1,v2)` |

### Fórmulas Compuestas

**MADe:**
```excel
=1.483*MEDIANA(ABS(rango-MEDIANA(rango)))
```

**nIQR:**
```excel
=0.7413*(CUARTIL(rango,3)-CUARTIL(rango,1))
```

**z-score:**
```excel
=(x-x_pt)/sigma_pt
```

**z'-score:**
```excel
=(x-x_pt)/RAIZ(sigma_pt^2+u_xpt^2)
```

**zeta-score:**
```excel
=(x-x_pt)/RAIZ(u_x^2+u_xpt^2)
```

**En-score:**
```excel
=(x-x_pt)/RAIZ(U_x^2+U_xpt^2)
```
