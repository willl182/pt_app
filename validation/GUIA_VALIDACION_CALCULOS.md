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
Diferencia (Dmax) = |media_estabilidad - media_homogeneidad|
c_stab = 0.3 × σ_pt

Criterio: Diferencia ≤ c_stab
```

#### Criterio Expandido de Estabilidad

```
u_hom_mean = SD(datos_hom) / √n_hom
u_stab_mean = SD(datos_stab) / √n_stab
c_stab_expanded = c_stab + 2 × √(u_hom_mean² + u_stab_mean²)
```

#### Incertidumbre por Estabilidad (u_stab)

```
u_stab = Dmax / √3
```

donde Dmax = |media_homogeneidad - media_estabilidad|

### Tabla de Validación Estabilidad

| Parámetro | Símbolo | Fórmula | Valor Esperado |
|-----------|---------|---------|----------------|
| Media homogeneidad | ȳ₁ | PROMEDIO(medias_hom) | - |
| Media estabilidad | ȳ₂ | PROMEDIO(medias_stab) | - |
| Diferencia (Dmax) | Dmax | ABS(ȳ₁ - ȳ₂) | - |
| Criterio | c_stab | 0.3 × σ_pt | - |
| u_stab | u_stab | Dmax / √3 | - |
| Evaluación | - | Dmax ≤ c_stab ? | CUMPLE/NO CUMPLE |

---

## Algoritmo A (Método de Winsorización)

### Descripción

El Algoritmo A (ISO 13528:2022 Anexo C.3) es un procedimiento iterativo para calcular estimaciones robustas de ubicación (x*) y escala (s*) utilizando el método de **winsorización**. Este método limita (clamp) los valores extremos en lugar de ponderarlos.

### Fórmulas (Winsorización)

**Inicialización:**
```
x*₀ = mediana(xi)
s*₀ = 1.483 × mediana(|xi - x*₀|)
```

**Iteración k:**
```
δ = 1.5 × s*_k
xi* = clamp(xi, x*_k - δ, x*_k + δ)

Donde clamp significa:
  xi* = x*_k - δ   si xi < x*_k - δ
  xi* = xi         si x*_k - δ ≤ xi ≤ x*_k + δ
  xi* = x*_k + δ   si xi > x*_k + δ

x*_k+1 = promedio(xi*)
s*_k+1 = 1.134 × √(Σ(xi* - x*_k+1)² / (p-1))
```

**Convergencia:**
- La iteración converge cuando x* y s* son estables hasta la **tercera cifra significativa** (no usamos tolerancia absoluta).

### Diferencias con Método Anterior (Huber Weighting)

| Aspecto | Anterior (Huber) | Actual (Winsorización) |
|----------|-----------------|----------------------|
| Manejo de valores atípicos | Reducción de peso (w = 1/u²) | Limitado/clampado a bounds |
| Actualización x* | Σ(w×xi)/Σwi | mean(xi*) |
| Actualización s* | √(Σw(x-x*)²/Σw) | 1.134×√(Σ(xi*-x*)²/(p-1)) |
| Convergencia | Δ < 1e-03 | 3ra cifra significativa |

### Pasos en Hoja de Cálculo

| Iter | x* | s* | δ | Lower Bound | Upper Bound | xi* | Δx* | Δs* | Converged |
|------|----|----|----|------------|------------|------|-----|-----|----------|
| 0 | mediana | 1.483×MAD | 1.5×s*₀ | x*₀-δ | x*₀+δ | - | - | - | - |
| 1 | mean(xi*) | 1.134×SD(xi*) | 1.5×s*₁ | x*₁-δ | x*₁+δ | clamped values | x*₁-x*₀ | s*₁-s*₀ | 3ra sig fig? |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | |

### Ejemplo Numérico

**Datos:** `[10.1, 10.2, 9.9, 10.0, 10.3, 50.0]` (6 valores, p=6)

**Iteración 0:**
- x*₀ = 10.05 (mediana)
- MAD = 0.15, s*₀ = 1.483 × 0.15 = 0.222
- δ = 1.5 × 0.222 = 0.333
- Límites: [9.717, 10.383]

**Iteración 1 (Winsorización):**
| xi | xi* (clamped) |
|----|---------------|
| 10.1 | 10.1 |
| 10.2 | 10.2 |
| 9.9 | 9.9 |
| 10.0 | 10.0 |
| 10.3 | 10.3 |
| 50.0 | **10.383** ← clampado |

- x*₁ = mean(xi*) = 10.147
- s*₁ = 1.134 × SD(xi*) ≈ 0.14

**Iteración 2:**
- δ = 1.5 × 0.14 = 0.21
- Nueva winsorización → x*₂ ≈ 10.10, s*₂ ≈ 0.15

**Convergencia:** x* y s* estables en 3ra cifra significativa (10.1, 0.15)

### Casos Especiales

| Caso | Comportamiento Esperado |
|-------|---------------------|
| Valores idénticos | s* = 0, usa SD clásico como fallback |
| < 3 participantes | Error retornado (p < 3) |
| Un solo outlier extremo | Outlier clampado a x* ± δ |
| Sin outliers | x* ≈ mean, s* ≈ SD, winsorización mínima |

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
| u_xpt_def | Incertidumbre definitiva del valor asignado (incluye u_hom y u_stab) |
| u_hom | Incertidumbre por homogeneidad (= ss, desviación estándar entre muestras) |
| u_stab | Incertidumbre por estabilidad (= Dmax / √3) |
| u_x | Incertidumbre estándar del participante (sd_value/√m) |
| U_x | Incertidumbre expandida del participante (k × u_x) |
| U_xpt | Incertidumbre expandida del valor asignado (k × u_xpt_def) |
| k | Factor de cobertura (típicamente 2) |

### Cálculo de u_xpt

```
u_xpt = 1.25 × MADe / √n
```

donde n = número de datos usados para calcular MADe.

### Cálculo de u_xpt_def (Incertidumbre Definitiva)

```
u_xpt_def = √(u_xpt² + u_hom² + u_stab²)
```

Esta incertidumbre definitiva incorpora las contribuciones de:
- u_xpt: incertidumbre del valor asignado
- u_hom: incertidumbre por heterogeneidad (= ss)
- u_stab: incertidumbre por inestabilidad (= Dmax / √3)

---

## Hojas de Cálculo de Validación

El archivo `validation_calculations.xlsx` contiene 6 hojas de validación con fórmulas de Excel/Calc:

### 1. Homogeneity

Validación paso a paso de cálculos de homogeneidad para SO2, nivel 60-nmol/mol.

**Parámetros:**
- g = 10 (muestras)
- m = 2 (réplicas)
- σ_pt = 0.6 (entrada usuario)

**Cálculos:**
- sw (desviación estándar intra-muestra)
- ss (desviación estándar inter-muestras)
- Criterio: ss ≤ 0.3×σ_pt

### 2. Stability

Validación de cálculos de estabilidad comparando datos de homogeneidad vs estabilidad.

**Cálculos:**
- Medias de homogeneidad y estabilidad
- Diferencia absoluta (Dmax)
- Criterio básico: Dmax ≤ 0.3×σ_pt
- Criterio expandido (con incertidumbres)
- u_stab = Dmax / √3

### 3. Robust_Stats

Validación de MADe y nIQR con datos de SO2 60-nmol/mol.

**Estadísticos calculados:**
- n, Median, Q1, Q3, IQR
- nIQR = 0.7413 × IQR
- MADe = 1.483 × MAD

### 4. Algorithm_A

Validación iteración por iteración del **Algoritmo A (Winsorización)** para SO2 60-nmol/mol.

**Parámetros:**
- p = número de observaciones
- Factor MAD = 1.483
- Factor de winsorización = 1.5
- Factor de ajuste de escala = 1.134

**Columnas de iteración:**
- i, xi, Lower bound, Upper bound, xi* (winsorizado)
- (xi* - x*₁)²

**Convergencia:** Comparación de tercera cifra significativa

### 5. PT_Scores

Validación de cálculos de puntajes z, z', zeta, En.

**Parámetros:**
- x_pt (valor asignado)
- σ_pt (desviación estándar)
- u_xpt_def (incertidumbre definitiva)

**Puntajes calculados:**
- z = (x - x_pt) / σ_pt
- z' = (x - x_pt) / √(σ_pt² + u_xpt_def²)
- ζ = (x - x_pt) / √(u_x² + u_xpt_def²)
- En = (x - x_pt) / √(U_x² + U_xpt²)

### 6. Edge_Cases (NUEVA)

Validación de casos especiales para el Algoritmo A:

**Caso 1: Valores idénticos (dispersión cero)**
- Datos: `[10.0, 10.0, 10.0, 10.0, 10.0]`
- Esperado: x* = 10.0, s* = 0, convergió = TRUE

**Caso 2: Menos de 3 participantes**
- Datos: `[10.1, 10.2]`
- Esperado: Error retornado (p < 3)

**Caso 3: Un solo outlier extremo**
- Datos: `[10.1, 10.2, 10.0, 10.3, 100.0]`
- Esperado: 100.0 winsorizado a ≈ 10.6

**Caso 4: Sin outliers**
- Datos: `[10.1, 10.2, 9.9, 10.0, 10.3]`
- Esperado: x* ≈ mean, s* ≈ SD, winsorización mínima

### Notas

- Todas las fórmulas son dinámicas - cambiar valores de entrada recalculará automáticamente
- Los resultados esperados pueden verificarse ejecutando `ptcalc::run_algorithm_a()` en R

---

## Referencias

- ISO 13528:2022 - Statistical methods for use in proficiency testing
  - Annex C.3 - Algorithm A (Winsorization method) for robust estimation
- ISO 17043:2024 - Conformity assessment — General requirements for proficiency testing
- `ptcalc/R/pt_robust_stats.R` - Implementación actual en R
- `es/03_estadisticas_robustas_pt.md` - Documentación detallada del Algoritmo A

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

### Algoritmo A (Winsorización)

**Inicialización:**
```excel
x*_0 = MEDIANA(rango)
s*_0 = 1.483*MEDIANA(ABS(rango-MEDIANA(rango)))
```

**Bounds de winsorización:**
```excel
delta = 1.5 * s*_0
lower_bound = x*_0 - delta
upper_bound = x*_0 + delta
```

**Valor winsorizado (xi*):**
```excel
=SI(xi<lower_bound,lower_bound,SI(xi>upper_bound,upper_bound,xi))
```

**Actualización iterativa:**
```excel
x*_nuevo = PROMEDIO(rango_winsorizado)
s*_nuevo = 1.134*RAIZ(SUMA((rango_winsorizado-x*_nuevo)^2)/(p-1))
```

**Convergencia (3ra cifra significativa):**
```excel
=SI(Y(REDONDEAR(x*_antiguo,2-ENTERO(LOG10(ABS(x*_antiguo))))=REDONDEAR(x*_nuevo,2-ENTERO(LOG10(ABS(x*_nuevo))),REDONDEAR(s*_antiguo,2-ENTERO(LOG10(ABS(s*_antiguo))))=REDONDEAR(s*_nuevo,2-ENTERO(LOG10(ABS(s*_nuevo)))),"SI","NO")
```
