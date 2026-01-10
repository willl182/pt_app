# Cálculo de Valores por Consenso: MADe y nIQR

Este documento explica en detalle las funciones utilizadas en `app.R` para calcular los valores por consenso (x_pt) y las desviaciones robustas sigma_pt_2a (MADe) y sigma_pt_2b (nIQR) según la norma ISO 13528.

---

## 1. Fundamento Teórico

En los ensayos de aptitud, el **valor asignado por consenso** se obtiene a partir de las mediciones de los participantes. Se utilizan estimadores robustos que son menos sensibles a valores atípicos (outliers) que la media y desviación estándar tradicionales.

### 1.1 Mediana como Valor Asignado (x_pt)

La **mediana** es el valor central cuando los datos se ordenan de menor a mayor. Es robusta porque no se ve afectada por valores extremos.

```
x_pt = mediana(resultados de participantes)
```

### 1.2 MADe (Median Absolute Deviation, scaled)

La **Desviación Absoluta de la Mediana escalada** (MADe) es un estimador robusto de la dispersión.

**Fórmula:**
```
MADe = 1.483 × mediana(|xi - mediana(x)|)
```

Donde:
- `xi` = cada valor individual
- `mediana(x)` = la mediana de todos los valores
- `|xi - mediana(x)|` = desviación absoluta de cada valor respecto a la mediana
- `1.483` = factor de escala para que MADe sea comparable con la desviación estándar bajo distribución normal

En `app.R`, el cálculo de sigma_pt_2a (MADe) es:
```r
sigma_pt_2a <- 1.483 * mad_val
```
donde `mad_val = median(abs(values - x_pt2), na.rm = TRUE)`

### 1.3 nIQR (Normalized Interquartile Range)

El **Rango Intercuartílico Normalizado** (nIQR) es otro estimador robusto de dispersión.

**Fórmula:**
```
nIQR = 0.7413 × (Q3 - Q1)
```

Donde:
- `Q1` = primer cuartil (percentil 25)
- `Q3` = tercer cuartil (percentil 75)
- `(Q3 - Q1)` = rango intercuartílico (IQR)
- `0.7413` = factor de escala para normalizar a desviación estándar

En `app.R`, la función `calculate_niqr` está definida como:

```r
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) {
    return(NA_real_)
  }
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}
```

---

## 2. Paso a Paso con Datos de Ejemplo

Utilizaremos los datos de `data/summary_n4.csv` para demostrar el cálculo.

### 2.1 Preparación de Datos

El archivo `summary_n4.csv` contiene:
- `pollutant`: Contaminante (co, no, no2, o3, so2)
- `level`: Nivel de concentración
- `participant_id`: Identificador del participante (part_1, part_2, part_3, ref)
- `mean_value`: Valor promedio de las mediciones
- `sd_value`: Desviación estándar de las mediciones

**Ejemplo**: Para el contaminante "co" nivel "2-μmol/mol":

| participant_id | mean_value |
|----------------|------------|
| part_1         | 2.01329818 |
| part_2         | 2.01335749 |
| part_3         | 2.01303316 |

> **Nota**: Los valores se agregan primero promediando todos los sample_group por participante.

### 2.2 Cálculo de la Mediana (x_pt)

```r
# Valores de participantes (excluyendo "ref")
values <- c(2.01329818, 2.01335749, 2.01303316)

# Paso 1: Ordenar valores
valores_ordenados <- sort(values)
# [1] 2.01303316 2.01329818 2.01335749

# Paso 2: Calcular mediana (valor central)
x_pt <- median(values)
# x_pt = 2.01329818
```

### 2.3 Cálculo de MADe (sigma_pt_2a)

```r
# Paso 1: Calcular desviación absoluta de cada valor respecto a la mediana
desviaciones <- abs(values - x_pt)
# |2.01329818 - 2.01329818| = 0.00000000
# |2.01335749 - 2.01329818| = 0.00005931
# |2.01303316 - 2.01329818| = 0.00026502

# Paso 2: Calcular la mediana de las desviaciones
mad_val <- median(desviaciones)
# mad_val = 0.00005931

# Paso 3: Escalar por 1.483
sigma_pt_2a <- 1.483 * mad_val
# sigma_pt_2a = 1.483 × 0.00005931 = 0.00008796
```

### 2.4 Cálculo de nIQR (sigma_pt_2b)

```r
# Paso 1: Calcular cuartiles
Q1 <- quantile(values, probs = 0.25)
Q3 <- quantile(values, probs = 0.75)

# Con 3 valores:
# Q1 ≈ 2.01316567
# Q3 ≈ 2.01332784

# Paso 2: Calcular IQR
IQR <- Q3 - Q1
# IQR = 2.01332784 - 2.01316567 = 0.00016217

# Paso 3: Normalizar por 0.7413
sigma_pt_2b <- 0.7413 * IQR
# sigma_pt_2b = 0.7413 × 0.00016217 = 0.00012021
```

---

## 3. Resumen de Fórmulas

| Estadístico | Fórmula | Descripción |
|-------------|---------|-------------|
| **x_pt(2)** | `mediana(valores)` | Valor asignado por consenso |
| **MADe** | `mediana(\|xi - mediana(x)\|)` | Desviación mediana absoluta |
| **sigma_pt_2a** | `1.483 × MADe` | MADe escalada |
| **sigma_pt_2b** | `0.7413 × IQR` | nIQR |
| **u(x_pt)** | `1.25 × sigma_pt / √n` | Incertidumbre del valor asignado |

---

## 4. Constantes de Normalización

### ¿Por qué 1.483 para MADe?

El factor 1.483 (≈ 1/Φ⁻¹(0.75)) convierte la MAD a una escala comparable con la desviación estándar para una distribución normal. Es el inverso del cuantil 75% de la distribución normal estándar.

### ¿Por qué 0.7413 para nIQR?

El factor 0.7413 (≈ 1/(2×Φ⁻¹(0.75))) normaliza el IQR para ser comparable con la desviación estándar bajo distribución normal. Es 1/(2×1.349) ≈ 0.7413.

---

## 5. Referencias

- **ISO 13528:2015** - Métodos estadísticos para uso en pruebas de aptitud mediante comparaciones interlaboratorio
- **ISO 17043:2010** - Evaluación de la conformidad — Requisitos generales para las pruebas de aptitud
