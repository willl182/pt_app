# Referencia de la API de ptcalc

## Información del Documento

| Atributo | Valor |
|----------|-------|
| Paquete | `ptcalc` v0.1.0 |
| Funciones Exportadas | 24 |
| Constantes Exportadas | 2 |
| Propósito | Referencia completa de todas las funciones exportadas del paquete para estudios de aptitud |
| Archivos Relacionados | [02_paquete_ptcalc.md](02_paquete_ptcalc.md) |

---

## Índice de Contenidos

- [1. Estadisticos Robustos](#1-estadisticos-robustos)
- [2. Homogeneidad](#2-homogeneidad)
- [3. Estabilidad](#3-estabilidad)
- [4. Incertidumbres](#4-incertidumbres)
- [5. Puntajes](#5-puntajes)
- [6. Evaluacion de Puntajes](#6-evaluacion-de-puntajes)
- [7. Clasificacion Combinada](#7-clasificacion-combinada)
- [8. Constantes](#8-constantes)
- [9. Ejemplo de Flujo Completo](#9-ejemplo-de-flujo-completo)
- [Apendice: Resumen de Tipos](#apendice-resumen-de-tipos)

---

## 1. Estadisticos Robustos

### calculate_niqr

Calcula el Rango Intercuartil Normalizado (nIQR), un estimador robusto de la desviacion estandar.

**Archivo:** `R/pt_robust_stats.R` (lineas 33-40)  
**Referencia:** ISO 13528:2022, Seccion 9.4

#### Firma
```r
calculate_niqr(x)
```

#### Parametros
| Parametro | Tipo | Requerido | Descripcion |
|-----------|------|-----------|-------------|
| `x` | numeric vector | Si | Vector de valores numericos |

#### Retorno
- `numeric`: nIQR = 0.7413 * (Q3 - Q1), o `NA_real_` si datos insuficientes (menos de 2 valores finitos).

#### Formula
$$\text{nIQR} = 0.7413 \times (Q_3 - Q_1)$$

#### Ejemplo
```r
# Calcular nIQR para datos de ensayo de aptitud
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 9.8, 10.1)
niqr <- calculate_niqr(values)
# Resultado: ~0.222
```

#### Casos de Error / Edge
| Condicion | Resultado |
|-----------|-----------|
| `length(x_clean) < 2` | `NA_real_` |
| Valores no finitos | Filtrados automaticamente antes del calculo |

---

### calculate_mad_e

Calcula la Desviacion Absoluta Mediana escalada (MADe), un estimador robusto de la dispersion muy resistente a valores atipicos.

**Archivo:** `R/pt_robust_stats.R` (lineas 63-72)  
**Referencia:** ISO 13528:2022, Seccion 9.4

#### Firma
```r
calculate_mad_e(x)
```

#### Parametros
| Parametro | Tipo | Requerido | Descripcion |
|-----------|------|-----------|-------------|
| `x` | numeric vector | Si | Vector de valores numericos |

#### Retorno
- `numeric`: MADe = 1.483 * MAD, o `NA_real_` si no hay datos finitos.

#### Formula
$$\text{MADe} = 1.483 \times \text{median}(|x_i - \text{median}(x)|)$$

#### Ejemplo
```r
# MADe es robusto ante outliers
values <- c(10.1, 10.2, 9.9, 10.0, 50.0)  # 50 es un valor atipico
mad_e <- calculate_mad_e(values)
# Resultado: ~0.222 (ignora el impacto del outlier)
```

---

### run_algorithm_a

Implementa el Algoritmo A de ISO 13528 para calcular la media y desviacion estandar robustas mediante un proceso iterativo con ponderacion de Huber.

**Archivo:** `R/pt_robust_stats.R` (lineas 112-246)  
**Referencia:** ISO 13528:2022, Anexo C

#### Firma
```r
run_algorithm_a(values, ids = NULL, max_iter = 50, tol = 1e-03)
```

#### Parametros
| Parametro | Tipo | Requerido | Default | Descripcion |
|-----------|------|-----------|---------|-------------|
| `values` | numeric vector | Si | - | Resultados de los participantes |
| `ids` | vector | No | `NULL` | Identificadores opcionales de participantes |
| `max_iter` | integer | No | 50 | Maximo numero de iteraciones permitidas |
| `tol` | numeric | No | 1e-03 | Tolerancia de convergencia |

#### Retorno
Una lista que contiene:
| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `assigned_value` | numeric | Media robusta final (x*) |
| `robust_sd` | numeric | Desviacion estandar robusta final (s*) |
| `iterations` | data.frame | Historial paso a paso de la convergencia |
| `weights` | data.frame | Pesos y residuos finales por participante |
| `converged` | logical | TRUE si se alcanzo la convergencia dentro de `max_iter` |
| `effective_weight` | numeric | Suma de los pesos finales asignados |
| `error` | character | Mensaje de error si el proceso fallo, de lo contrario `NULL` |

#### Algoritmo (Flujo)
```mermaid
graph TD
    A[Inicializar x* = mediana, s* = MADe] --> B{Iterar}
    B --> C[Calcular u = x - x* / 1.5*s*]
    D[Pesos: w = 1 si abs u <= 1, else 1/u^2] --> E[Actualizar x* y s* ponderados]
    C --> D
    E --> F{Convergio?}
    F -->|No| B
    F -->|Si| G[Retornar resultados]
```

#### Ejemplo
```r
values <- c(10.1, 10.2, 9.9, 10.0, 10.3, 50.0)
ids <- c("Lab1", "Lab2", "Lab3", "Lab4", "Lab5", "Lab6")
result <- run_algorithm_a(values, ids)

if (is.null(result$error)) {
  cat("Valor Asignado:", result$assigned_value, "\n") # ~10.1
  cat("SD Robusta:", result$robust_sd, "\n")          # ~0.14
}
```

#### Casos de Error
| Condicion | Comportamiento |
|-----------|----------------|
| `n < 3` | Error: "Algorithm A requires at least 3 valid observations." |
| Dispersion cero | Error: "Data dispersion is insufficient for Algorithm A." |
| SD colapsa a cero | Error: "Algorithm A collapsed due to zero standard deviation." |
| No convergencia | Retorna los ultimos valores calculados con `converged = FALSE` |

---

## 2. Homogeneidad

### calculate_homogeneity_stats

Calcula los componentes de varianza mediante ANOVA para evaluar la homogeneidad de los items del ensayo de aptitud.

**Archivo:** `R/pt_homogeneity.R` (lineas 38-91)  
**Referencia:** ISO 13528:2022, Seccion 9.2

#### Firma
```r
calculate_homogeneity_stats(sample_data)
```

#### Parametros
| Parametro | Tipo | Requerido | Descripcion |
|-----------|------|-----------|-------------|
| `sample_data` | data.frame/matrix | Si | Datos con muestras en filas y replicas en columnas |

#### Retorno
Lista con estadisticos clave:
| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `g` | integer | Numero de muestras analizadas |
| `m` | integer | Numero de replicas por muestra |
| `general_mean_homog` | numeric | Media global del estudio de homogeneidad (x̄̄) |
| `sample_means` | numeric vector | Media de cada muestra individual |
| `s_x_bar_sq` | numeric | Varianza de las medias de las muestras |
| `sw` | numeric | Desviacion estandar intra-muestra |
| `ss` | numeric | Desviacion estandar entre-muestras |
| `error` | character | Mensaje de error si las dimensiones son insuficientes |

#### Formulas (para m = 2)
$$s_w = \sqrt{\frac{\sum w_i^2}{2g}}$$ donde $w_i$ es el rango de la muestra $i$.
$$s_s^2 = \max(0, s_{\bar{x}}^2 - \frac{s_w^2}{m})$$

#### Ejemplo
```r
# Matriz de 10 muestras con 2 replicas cada una
sample_data <- matrix(rnorm(20, 10, 0.1), nrow=10, ncol=2)
stats <- calculate_homogeneity_stats(sample_data)
cat("ss:", stats$ss, "sw:", stats$sw)
```

---

### calculate_homogeneity_criterion

Calcula el limite critico estandar para la homogeneidad ($0.3 \times \sigma_{pt}$).

**Archivo:** `R/pt_homogeneity.R` (lineas 109-111)  
**Referencia:** ISO 13528:2022, Seccion 9.2.3

#### Firma
```r
calculate_homogeneity_criterion(sigma_pt)
```

#### Retorno
- `numeric`: $c = 0.3 \times \sigma_{pt}$.

---

 ### calculate_homogeneity_criterion_expanded

 Calcula el criterio de homogeneidad expandido segun ISO 13528 §9.2.4, que considera la incertidumbre debida a la precision del metodo (varianza intra-muestra) usando coeficientes F1/F2 que dependen del numero de muestras.

 **Archivo:** `R/pt_homogeneity.R` (lineas 160-178)

 #### Firma
 ```r
 calculate_homogeneity_criterion_expanded(sigma_pt, sw, g)
 ```

 #### Formula
 $$c_{exp} = F_1 \times (0.3 \times \sigma_{pt})^2 + F_2 \times s_w^2$$

 Donde $F_1$ y $F_2$ son coeficientes que dependen del numero de muestras $g$ (valores entre 7 y 20). Los valores fuera de este rango son clampados a los extremos.

---

### evaluate_homogeneity

Determina si los resultados del estudio de homogeneidad cumplen con los criterios establecidos.

**Archivo:** `R/pt_homogeneity.R` (lineas 142-165)

#### Firma
```r
evaluate_homogeneity(ss, c_criterion, c_expanded = NULL)
```

#### Retorno
| Campo | Tipo | Descripcion |
|-------|------|-------------|
| `passes_criterion` | logical | TRUE si $s_s \leq c$ |
| `passes_expanded` | logical | TRUE si $s_s \leq c_{expandido}$ (o NA si no se provee) |
| `conclusion` | character | Resumen textual del resultado de la evaluacion |

---

## 3. Estabilidad

### calculate_stability_stats

Evalua la estabilidad comparando la media de muestras sometidas a condiciones de estabilidad contra la media del estudio de homogeneidad.

**Archivo:** `R/pt_homogeneity.R` (lineas 191-218)  
**Referencia:** ISO 13528:2022, Seccion 9.3

#### Firma
```r
calculate_stability_stats(stab_sample_data, hom_general_mean_homog, hom_stab_x_pt, hom_stab_sigma_pt)
```

#### Parámetros
- `stab_sample_data`: Matriz de datos de estabilidad (muestras como filas, réplicas como columnas)
- `hom_general_mean_homog`: Media general del estudio de homogeneidad
- `hom_stab_x_pt`: Mediana de la primera réplica del estudio de homogeneidad (valor asignado $x_{pt}$), usada como REFERENCIA
- `hom_stab_sigma_pt`: Desviación estándar del estudio de homogeneidad (MADe)

#### Retorno
Lista con estadisticos de estabilidad:
- `general_mean`: Media de las muestras de estabilidad.
- `diff_hom_stab`: Valor absoluto de la diferencia entre la media de estabilidad y la de homogeneidad.
- `hom_stab_median_of_diffs`: Mediana de las diferencias absolutas entre la 2ª réplica (estabilidad) y `hom_stab_x_pt` (HOMOGENEIDAD)
- `hom_stab_sigma_pt`: Desviación estándar del estudio de homogeneidad (pasada desde parámetro, NO calculada internamente)
- Otros campos de estadísticas ANOVA aplicados a los datos de estabilidad.

---

### calculate_stability_criterion

Calcula el criterio base de estabilidad ($0.3 \times \sigma_{pt}$).

**Archivo:** `R/pt_homogeneity.R` (lineas 205-207)

---

### calculate_stability_criterion_expanded

Calcula el criterio de estabilidad expandido considerando las incertidumbres de las medias.

**Archivo:** `R/pt_homogeneity.R` (lineas 218-220)  
**Referencia:** ISO 13528:2022, Seccion 9.3.4

#### Firma
```r
calculate_stability_criterion_expanded(c_criterion, u_hom_mean, u_stab_mean)
```

#### Formula
$$c_{stab\_exp} = c + 2 \times \sqrt{u_{hom}^2 + u_{stab}^2}$$

---

### evaluate_stability

Determina si el cambio en la media durante el estudio de estabilidad es aceptable.

**Archivo:** `R/pt_homogeneity.R` (lineas 232-258)

#### Firma
```r
evaluate_stability(diff_hom_stab, c_criterion, c_expanded = NULL)
```

---

## 4. Incertidumbres

### calculate_u_hom

Calcula la incertidumbre estandar debida a la falta de homogeneidad.

**Archivo:** `R/pt_homogeneity.R` (lineas 269-271)

#### Formula
$$u_{hom} = s_s$$

---

### calculate_u_stab

Calcula la incertidumbre estandar debida a la inestabilidad.

**Archivo:** `R/pt_homogeneity.R` (lineas 284-289)

#### Formula
$$u_{stab} = \begin{cases} 0 & \text{si } |diff| \leq c \\ \frac{|diff|}{\sqrt{3}} & \text{si } |diff| > c \end{cases}$$

---

## 5. Puntajes

### calculate_z_score

Calcula el puntaje z convencional para evaluar el desempeño.

**Archivo:** `R/pt_scores.R` (lineas 28-33)  
**Referencia:** ISO 13528:2022, Seccion 10.2

#### Formula
$$z = \frac{x - x_{pt}}{\sigma_{pt}}$$

#### Casos Edge
- Retorna `NA_real_` si $\sigma_{pt}$ no es finito o es $\leq 0$.

---

### calculate_z_prime_score

Calcula el puntaje z' que incorpora la incertidumbre del valor asignado.

**Archivo:** `R/pt_scores.R` (lineas 53-59)  
**Referencia:** ISO 13528:2022, Seccion 10.3

#### Formula
$$z' = \frac{x - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}}$$

---

### calculate_zeta_score

Calcula el puntaje zeta utilizando la incertidumbre informada por el participante.

**Archivo:** `R/pt_scores.R` (lineas 79-85)  
**Referencia:** ISO 13528:2022, Seccion 10.4

#### Formula
$$\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}}$$

---

### calculate_en_score

Calcula el puntaje En (Error Normalizado) usando incertidumbres expandidas ($k=2$).

**Archivo:** `R/pt_scores.R` (lineas 106-112)  
**Referencia:** ISO 13528:2022, Seccion 10.5

#### Formula
$$E_n = \frac{x - x_{pt}}{\sqrt{U_x^2 + U_{xpt}^2}}$$

---

## 6. Evaluacion de Puntajes

### evaluate_z_score / evaluate_z_score_vec

Clasifica los puntajes z, z' o zeta segun los umbrales de ISO 13528.

| Condicion | Categoria |
|-----------|-----------|
| $|score| \leq 2$ | "Satisfactorio" |
| $2 < |score| < 3$ | "Cuestionable" |
| $|score| \geq 3$ | "No satisfactorio" |
| No finito | "N/A" |

---

### evaluate_en_score / evaluate_en_score_vec

Clasifica el puntaje En segun el criterio unitario.

| Condicion | Categoria |
|-----------|-----------|
| $|E_n| \leq 1$ | "Satisfactorio" |
| $|E_n| > 1$ | "No satisfactorio" |
| No finito | "N/A" |

---

## 7. Ejemplo de Flujo Completo

A continuacion se muestra como integrar las funciones del API en un flujo de trabajo real:

```r
library(ptcalc)

# 1. Calcular estadisticos robustos de los resultados
participantes <- c(10.2, 10.1, 9.8, 10.0, 10.3, 15.0) # 15.0 es outlier
res_robust <- run_algorithm_a(participantes)
x_pt <- res_robust$assigned_value
s_pt <- res_robust$robust_sd

# 2. Verificar homogeneidad
datos_hom <- matrix(c(10.1, 10.2, 9.9, 10.0), nrow=2, ncol=2)
hom_stats <- calculate_homogeneity_stats(datos_hom)
c_hom <- calculate_homogeneity_criterion(s_pt)
eval_hom <- evaluate_homogeneity(hom_stats$ss, c_hom)
print(eval_hom$conclusion)

# 3. Evaluar un participante con incertidumbre
x_i <- 10.5
u_i <- 0.2
z_i <- calculate_z_score(x_i, x_pt, s_pt)
en_i <- calculate_en_score(x_i, x_pt, 2*u_i, 0.1) # U_xpt asumida 0.1

# 4. Evaluar desempeño
cat("z-score:", z_i, "->", evaluate_z_score(z_i), "\n")
cat("En-score:", en_i, "->", evaluate_en_score(en_i), "\n")
```

---

## Apendice: Resumen de Tipos

| Entrada / Salida | Descripcion |
|------------------|-------------|
| `numeric vector` | Conjunto de resultados de ensayo |
| `matrix` | Datos de replicas (filas=unidades, cols=replicas) |
| `list` | Objetos complejos con multiples metodos de retorno |

---

## Referencias
- **ISO 13528:2022**: Statistical methods for use in proficiency testing by interlaboratory comparison.
- **ISO 17043:2024**: Conformity assessment — General requirements for the competence of proficiency testing providers.
- **ISO/IEC Guide 98-3 (GUM)**: Guide to the expression of uncertainty in measurement.
