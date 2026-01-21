# Documentación de Funciones - Entregable 02

Este documento cataloga todas las funciones del paquete `ptcalc` usadas por la aplicación. Las referencias se alinean con las normas **ISO 13528:2022** e **ISO 17043:2024**.

---

## Índice de Contenidos

- [1. Estadísticos Robustos](#1-estadísticos-robustos)
- [2. Homogeneidad](#2-homogeneidad)
- [3. Estabilidad](#3-estabilidad)
- [4. Incertidumbres](#4-incertidumbres)
- [5. Puntajes](#5-puntajes)
- [6. Evaluación de Puntajes](#6-evaluación-de-puntajes)
- [7. Clasificación Combinada](#7-clasificación-combinada)
- [8. Constantes](#8-constantes)
- [9. Funciones Deprecadas](#9-funciones-deprecadas)

---

## 1. Estadísticos Robustos

### calculate_niqr

Calcula el Rango Intercuartil Normalizado (nIQR), un estimador robusto de la desviación estándar.

**Archivo:** `R/pt_robust_stats.R`  
**Referencia:** ISO 13528:2022, Sección 9.4

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `x` | numeric vector | Sí | Vector de valores numéricos |

**Retorno:** `numeric` - nIQR = 0.7413 × (Q3 - Q1), o `NA_real_` si datos insuficientes.

**Fórmula:**
```
nIQR = 0.7413 × (Q₃ - Q₁)
```

**Ejemplo:**
```r
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
niqr <- calculate_niqr(values)  # ~0.222
```

---

### calculate_mad_e

Calcula la Desviación Absoluta Mediana escalada (MADe), muy resistente a valores atípicos.

**Archivo:** `R/pt_robust_stats.R`  
**Referencia:** ISO 13528:2022, Sección 9.4

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `x` | numeric vector | Sí | Vector de valores numéricos |

**Retorno:** `numeric` - MADe = 1.483 × MAD.

**Fórmula:**
```
MADe = 1.483 × median(|xᵢ - median(x)|)
```

**Ejemplo:**
```r
values <- c(10.1, 10.2, 9.9, 10.0, 50.0)  # 50 es outlier
mad_e <- calculate_mad_e(values)  # ~0.222 (ignora el outlier)
```

---

### run_algorithm_a

Implementa el Algoritmo A de ISO 13528 para calcular la media y desviación estándar robustas mediante ponderación iterativa de Huber.

**Archivo:** `R/pt_robust_stats.R`  
**Referencia:** ISO 13528:2022, Anexo C

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `values` | numeric vector | Sí | - | Resultados de los participantes |
| `ids` | vector | No | `NULL` | Identificadores opcionales |
| `max_iter` | integer | No | 50 | Máximo número de iteraciones |
| `tol` | numeric | No | 1e-03 | Tolerancia de convergencia |

**Retorno:** Lista con:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `assigned_value` | numeric | Media robusta final (x*) |
| `robust_sd` | numeric | Desviación estándar robusta (s*) |
| `iterations` | data.frame | Historial de convergencia |
| `weights` | data.frame | Pesos y residuos finales |
| `converged` | logical | TRUE si convergió |
| `effective_weight` | numeric | Suma de pesos finales |
| `error` | character | Mensaje de error o NULL |

**Algoritmo (Flujo):**
```mermaid
graph TD
    A[Inicializar x* = mediana, s* = MADe] --> B{Iterar}
    B --> C[Calcular u = x - x* / 1.5*s*]
    C --> D[Pesos: w = 1 si |u| <= 1, else 1/u²]
    D --> E[Actualizar x* y s* ponderados]
    E --> F{¿Convergió?}
    F -->|No| B
    F -->|Sí| G[Retornar resultados]
```

**Ejemplo:**
```r
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 50.0)
ids <- c("Lab1", "Lab2", "Lab3", "Lab4", "Lab5", "Lab6")
result <- run_algorithm_a(values, ids)

cat("Valor Asignado:", result$assigned_value)  # ~10.1
cat("SD Robusta:", result$robust_sd)           # ~0.14
```

**Casos de Error:**

| Condición | Comportamiento |
|-----------|----------------|
| `n < 3` | Error: "Algorithm A requires at least 3 valid observations." |
| Dispersión cero | Error: "Data dispersion is insufficient for Algorithm A." |
| SD colapsa a cero | Error: "Algorithm A collapsed due to zero standard deviation." |
| No convergencia | Retorna últimos valores con `converged = FALSE` |

---

## 2. Homogeneidad

### calculate_homogeneity_stats

Calcula los componentes de varianza mediante ANOVA para evaluar la homogeneidad de los ítems.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.2

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `sample_data` | data.frame/matrix | Sí | Datos con muestras en filas, réplicas en columnas |

**Retorno:** Lista con:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `g` | integer | Número de muestras |
| `m` | integer | Número de réplicas por muestra |
| `grand_mean` | numeric | Media global (x̄̄) |
| `sample_means` | numeric vector | Media de cada muestra |
| `s_x_bar_sq` | numeric | Varianza de las medias |
| `sw` | numeric | Desviación estándar intra-muestra |
| `ss` | numeric | Desviación estándar entre-muestras |
| `error` | character | Mensaje de error si aplica |

**Fórmulas (para m = 2):**
```
sᵥ = √[Σ(rangoᵢ²) / (2g)]   donde rangoᵢ = max - min de muestra i
sₛ² = max(0, s²ₓ̄ - sᵥ²/m)
```

---

### calculate_homogeneity_criterion

Calcula el límite crítico estándar para la homogeneidad.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.2.3

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `sigma_pt` | numeric | Desviación estándar objetivo del ensayo |

**Retorno:** `numeric` - c = 0.3 × σ_pt

---

### calculate_homogeneity_criterion_expanded

Calcula el criterio de homogeneidad expandido según ISO 13528 §9.2.4.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.2.4

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `sigma_pt` | numeric | Desviación estándar objetivo |
| `sw_sq` | numeric | Varianza intra-muestra (sw²) |

**Fórmula:**
```
c_expandido = √[(0.3 × σ_pt)² × 1.88 + sᵥ² × 1.01]
```

---

### evaluate_homogeneity

Determina si los resultados del estudio de homogeneidad cumplen con los criterios.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.2

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `ss` | numeric | Desviación estándar entre-muestras |
| `c_criterion` | numeric | Criterio estándar (0.3 × σ_pt) |
| `c_expanded` | numeric | Criterio expandido (opcional) |

**Retorno:** Lista con:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `passes_criterion` | logical | TRUE si ss ≤ c |
| `passes_expanded` | logical | TRUE si ss ≤ c_expandido (o NA) |
| `conclusion` | character | Resumen textual de la evaluación |

---

## 3. Estabilidad

### calculate_stability_stats

Evalúa la estabilidad comparando la media de muestras bajo condiciones de estabilidad contra la media del estudio de homogeneidad.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.3

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `stab_sample_data` | data.frame/matrix | Datos de estabilidad |
| `hom_grand_mean` | numeric | Media del estudio de homogeneidad |

**Retorno:** Extiende `calculate_homogeneity_stats` con:
- `stab_grand_mean`: Media de las muestras de estabilidad
- `diff_hom_stab`: |media_estabilidad - media_homogeneidad|

---

### calculate_stability_criterion

Calcula el criterio base de estabilidad.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.3.3

**Retorno:** `numeric` - c = 0.3 × σ_pt

---

### calculate_stability_criterion_expanded

Calcula el criterio de estabilidad expandido considerando las incertidumbres.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.3.4

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `c_criterion` | numeric | Criterio base |
| `u_hom_mean` | numeric | Incertidumbre de la media de homogeneidad |
| `u_stab_mean` | numeric | Incertidumbre de la media de estabilidad |

**Fórmula:**
```
c_stab_exp = c + 2 × √(u_hom² + u_stab²)
```

---

### evaluate_stability

Determina si el cambio en la media durante el estudio de estabilidad es aceptable.

**Archivo:** `R/pt_homogeneity.R`

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `diff_hom_stab` | numeric | Diferencia de medias |
| `c_criterion` | numeric | Criterio base |
| `c_expanded` | numeric | Criterio expandido (opcional) |

---

## 4. Incertidumbres

### calculate_u_hom

Calcula la incertidumbre estándar debida a la falta de homogeneidad.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.5

**Fórmula:**
```
u_hom = sₛ
```

---

### calculate_u_stab

Calcula la incertidumbre estándar debida a la inestabilidad.

**Archivo:** `R/pt_homogeneity.R`  
**Referencia:** ISO 13528:2022, Sección 9.5

**Fórmula:**
```
u_stab = 0                    si |diff| ≤ c
u_stab = |diff| / √3          si |diff| > c
```

---

## 5. Puntajes

### calculate_z_score

Calcula el puntaje z convencional para evaluar el desempeño.

**Archivo:** `R/pt_scores.R`  
**Referencia:** ISO 13528:2022, Sección 10.2

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `x` | numeric | Valor del participante |
| `x_pt` | numeric | Valor asignado (referencia) |
| `sigma_pt` | numeric | Desviación estándar objetivo |

**Fórmula:**
```
z = (x - x_pt) / σ_pt
```

**Casos Edge:** Retorna `NA_real_` si σ_pt no es finito o es ≤ 0.

---

### calculate_z_prime_score

Calcula el puntaje z' que incorpora la incertidumbre del valor asignado.

**Archivo:** `R/pt_scores.R`  
**Referencia:** ISO 13528:2022, Sección 10.3

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `x` | numeric | Valor del participante |
| `x_pt` | numeric | Valor asignado |
| `sigma_pt` | numeric | Desviación estándar objetivo |
| `u_xpt` | numeric | Incertidumbre del valor asignado |

**Fórmula:**
```
z' = (x - x_pt) / √(σ_pt² + u_xpt²)
```

---

### calculate_zeta_score

Calcula el puntaje zeta utilizando la incertidumbre informada por el participante.

**Archivo:** `R/pt_scores.R`  
**Referencia:** ISO 13528:2022, Sección 10.4

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `x` | numeric | Valor del participante |
| `x_pt` | numeric | Valor asignado |
| `u_x` | numeric | Incertidumbre del participante (u) |
| `u_xpt` | numeric | Incertidumbre del valor asignado |

**Fórmula:**
```
ζ = (x - x_pt) / √(u_x² + u_xpt²)
```

---

### calculate_en_score

Calcula el puntaje En (Error Normalizado) usando incertidumbres expandidas (k=2).

**Archivo:** `R/pt_scores.R`  
**Referencia:** ISO 13528:2022, Sección 10.5

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `x` | numeric | Valor del participante |
| `x_pt` | numeric | Valor asignado |
| `U_x` | numeric | Incertidumbre expandida del participante |
| `U_xpt` | numeric | Incertidumbre expandida del valor asignado |

**Fórmula:**
```
Eₙ = (x - x_pt) / √(U_x² + U_xpt²)
```

---

## 6. Evaluación de Puntajes

### evaluate_z_score / evaluate_z_score_vec

Clasifica los puntajes z, z' o zeta según los umbrales de ISO 13528.

**Archivo:** `R/pt_scores.R`  
**Referencia:** ISO 13528:2022, Sección 10.6

| Condición | Categoría |
|-----------|-----------|
| \|score\| ≤ 2 | "Satisfactorio" |
| 2 < \|score\| < 3 | "Cuestionable" |
| \|score\| ≥ 3 | "No satisfactorio" |
| No finito | "N/A" |

---

### evaluate_en_score / evaluate_en_score_vec

Clasifica el puntaje En según el criterio unitario.

**Archivo:** `R/pt_scores.R`  
**Referencia:** ISO 13528:2022, Sección 10.6

| Condición | Categoría |
|-----------|-----------|
| \|Eₙ\| ≤ 1 | "Satisfactorio" |
| \|Eₙ\| > 1 | "No satisfactorio" |
| No finito | "N/A" |

---

## 7. Clasificación Combinada

### classify_with_en

Realiza una clasificación profunda (categorías a1 a a7) integrando el desempeño (z/z') y la consistencia de la incertidumbre informada (En).

**Archivo:** `R/pt_scores.R`  
**Referencia:** ISO 13528:2022, Sección 10.7

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `score_val` | numeric | Puntaje z o z' |
| `en_val` | numeric | Puntaje En |
| `U_xi` | numeric | Incertidumbre expandida del participante |
| `sigma_pt` | numeric | Desviación estándar objetivo |
| `mu_missing` | logical | TRUE si falta información de incertidumbre |
| `score_label` | character | Tipo de puntaje ("z" o "z'") |

**Retorno:** Lista con:
- `code`: Código de clasificación (a1-a7)
- `label`: Descripción textual

**Tabla de Categorías:**

| Código | Descripción |
|--------|-------------|
| **a1** | Totalmente satisfactorio |
| **a2** | Satisfactorio pero conservador (U informada muy grande) |
| **a3** | Satisfactorio con MU subestimada (En > 1 pero z bueno) |
| **a4** | Cuestionable pero aceptable (la MU cubre el error) |
| **a5** | Cuestionable e inconsistente |
| **a6** | No satisfactorio pero la MU cubre la desviación |
| **a7** | No satisfactorio (crítico - fuera de z y fuera de En) |

**Diagrama de Lógica:**
```mermaid
graph TD
    A{¿MU ausente?} -->|Sí| B[mu_missing]
    A -->|No| C{|z| <= 2?}
    C -->|Sí| D{|En| < 1?}
    D -->|Sí| E{U_xi >= 2*σ_pt?}
    E -->|Sí| F[a2: Conservador]
    E -->|No| G[a1: Totalmente satisfactorio]
    D -->|No| H[a3: MU subestimada]
    C -->|No| I{|z| < 3?}
    I -->|Sí| J{|En| < 1?}
    J -->|Sí| K[a4: Cuestionable aceptable]
    J -->|No| L[a5: Cuestionable inconsistente]
    I -->|No| M{|En| < 1?}
    M -->|Sí| N[a6: No satisf. cubierto]
    M -->|No| O[a7: Crítico]
```

---

## 8. Constantes

### PT_EN_CLASS_LABELS

Vector nombrado con las descripciones textuales para las categorías a1-a7.

```r
PT_EN_CLASS_LABELS
#> a1: "Totalmente satisfactorio"
#> a2: "Satisfactorio pero conservador"
#> ...
```

### PT_EN_CLASS_COLORS

Paleta de colores oficial para la representación visual:

| Código | Color | Hex |
|--------|-------|-----|
| a1 | Verde | `#2E7D32` |
| a2 | Verde claro | `#66BB6A` |
| a3 | Amarillo-verde | `#C0CA33` |
| a4 | Amarillo | `#FFF59D` |
| a5 | Naranja | `#FFB74D` |
| a6 | Naranja oscuro | `#FF8A65` |
| a7 | Rojo | `#C62828` |

---

## 9. Funciones Deprecadas

Las siguientes funciones en `utils.R` se mantienen por compatibilidad pero se recomienda usar las versiones actuales:

| Función Deprecada | Reemplazo |
|-------------------|-----------|
| `algorithm_A` | `run_algorithm_a` |
| `mad_e_manual` | `calculate_mad_e` |
| `nIQR_manual` | `calculate_niqr` |

---

## Catálogo Completo de Funciones

| Función | Archivo | Parámetros | Retorno | ISO |
|---------|---------|------------|---------|-----|
| `calculate_niqr` | `pt_robust_stats.R` | `x` | Numérico | 13528 §9.4 |
| `calculate_mad_e` | `pt_robust_stats.R` | `x` | Numérico | 13528 §9.4 |
| `run_algorithm_a` | `pt_robust_stats.R` | `values`, `ids`, `max_iter`, `tol` | Lista | 13528 Anexo C |
| `calculate_homogeneity_stats` | `pt_homogeneity.R` | `sample_data` | Lista | 13528 §9.2 |
| `calculate_homogeneity_criterion` | `pt_homogeneity.R` | `sigma_pt` | Numérico | 13528 §9.2.3 |
| `calculate_homogeneity_criterion_expanded` | `pt_homogeneity.R` | `sigma_pt`, `sw_sq` | Numérico | 13528 §9.2.4 |
| `evaluate_homogeneity` | `pt_homogeneity.R` | `ss`, `c_criterion`, `c_expanded` | Lista | 13528 §9.2 |
| `calculate_stability_stats` | `pt_homogeneity.R` | `stab_sample_data`, `hom_grand_mean` | Lista | 13528 §9.3 |
| `calculate_stability_criterion` | `pt_homogeneity.R` | `sigma_pt` | Numérico | 13528 §9.3.3 |
| `calculate_stability_criterion_expanded` | `pt_homogeneity.R` | `c_criterion`, `u_hom_mean`, `u_stab_mean` | Numérico | 13528 §9.3.4 |
| `evaluate_stability` | `pt_homogeneity.R` | `diff_hom_stab`, `c_criterion`, `c_expanded` | Lista | 13528 §9.3 |
| `calculate_u_hom` | `pt_homogeneity.R` | `ss` | Numérico | 13528 §9.5 |
| `calculate_u_stab` | `pt_homogeneity.R` | `diff_hom_stab`, `c_criterion` | Numérico | 13528 §9.5 |
| `calculate_z_score` | `pt_scores.R` | `x`, `x_pt`, `sigma_pt` | Numérico | 13528 §10.2 |
| `calculate_z_prime_score` | `pt_scores.R` | `x`, `x_pt`, `sigma_pt`, `u_xpt` | Numérico | 13528 §10.3 |
| `calculate_zeta_score` | `pt_scores.R` | `x`, `x_pt`, `u_x`, `u_xpt` | Numérico | 13528 §10.4 |
| `calculate_en_score` | `pt_scores.R` | `x`, `x_pt`, `U_x`, `U_xpt` | Numérico | 13528 §10.5 |
| `evaluate_z_score` | `pt_scores.R` | `z` | Texto | 13528 §10.6 |
| `evaluate_z_score_vec` | `pt_scores.R` | `z` | Vector | 13528 §10.6 |
| `evaluate_en_score` | `pt_scores.R` | `en` | Texto | 13528 §10.6 |
| `evaluate_en_score_vec` | `pt_scores.R` | `en` | Vector | 13528 §10.6 |
| `classify_with_en` | `pt_scores.R` | `score_val`, `en_val`, `U_xi`, `sigma_pt`, `mu_missing`, `score_label` | Lista | 13528 §10.7 |

---

## Referencias

- **ISO 13528:2022**: Statistical methods for use in proficiency testing by interlaboratory comparison.
- **ISO 17043:2024**: Conformity assessment — General requirements for proficiency testing.
- **ISO/IEC Guide 98-3 (GUM)**: Guide to the expression of uncertainty in measurement.
