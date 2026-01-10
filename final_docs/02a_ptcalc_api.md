# Referencia de la API de ptcalc

## Información del Documento

| Atributo | Valor |
|----------|-------|
| Paquete | `ptcalc` v0.1.0 |
| Funciones Exportadas | 24 |
| Constantes Exportadas | 2 |
| Documento Principal | [02_ptcalc_package.md](02_ptcalc_package.md) |

---

## Índice de Funciones

1.  [Estadísticos Robustos](#1-estadísticos-robustos)
2.  [Homogeneidad](#2-homogeneidad)
3.  [Estabilidad](#3-estabilidad)
4.  [Incertidumbres](#4-incertidumbres)
5.  [Puntajes](#5-puntajes)
6.  [Evaluación de Puntajes](#6-evaluación-de-puntajes)

---

## 1. Estadísticos Robustos

### `calculate_niqr`

Calcula el Rango Intercuartílico Normalizado (nIQR), un estimador robusto de la desviación estándar.

**Archivo:** `R/pt_robust_stats.R`
**Referencia:** ISO 13528:2022, Sección 9.4

```r
calculate_niqr(x)
```

-   **x**: Vector numérico de valores.
-   **Retorna**: `numeric` (nIQR = 0.7413 * IQR) o `NA` si hay insuficientes datos.

### `calculate_mad_e`

Calcula la Desviación Absoluta de la Mediana escalada (MADe), resistente a valores atípicos.

**Archivo:** `R/pt_robust_stats.R`
**Referencia:** ISO 13528:2022, Sección 9.4

```r
calculate_mad_e(x)
```

-   **x**: Vector numérico de valores.
-   **Retorna**: `numeric` (MADe = 1.483 * MAD).

### `run_algorithm_a`

Algoritmo iterativo de ISO 13528 para calcular media y desviación estándar robustas.

**Archivo:** `R/pt_robust_stats.R`
**Referencia:** ISO 13528:2022, Anexo C

```r
run_algorithm_a(values, ids = NULL, max_iter = 50, tol = 1e-03)
```

-   **values**: Vector numérico de resultados.
-   **ids**: Vector opcional de identificadores.
-   **max_iter**: Máximo de iteraciones (default 50).
-   **tol**: Tolerancia de convergencia (default 0.001).
-   **Retorna**: Lista con:
    -   `assigned_value`: Media robusta ($x^*$).
    -   `robust_sd`: Desviación estándar robusta ($s^*$).
    -   `weights`: Pesos finales por participante.
    -   `converged`: Booleano de convergencia.
    -   `iterations`: Historial de iteraciones.

---

## 2. Homogeneidad

### `calculate_homogeneity_stats`

Calcula estadísticos de homogeneidad (ANOVA) a partir de datos de muestras con réplicas.

**Archivo:** `R/pt_homogeneity.R`
**Referencia:** ISO 13528:2022, Sección 9.2

```r
calculate_homogeneity_stats(sample_data)
```

-   **sample_data**: Matriz o data frame donde las filas son muestras y las columnas son réplicas.
-   **Retorna**: Lista con $s_s$, $s_w$, medias globales, y componentes de varianza.

### `calculate_homogeneity_criterion`

Calcula el criterio de homogeneidad estándar.

**Referencia:** ISO 13528:2022, Sección 9.2.3

```r
calculate_homogeneity_criterion(sigma_pt)
```

-   **sigma_pt**: Desviación estándar para evaluación de aptitud.
-   **Retorna**: $0.3 \times \sigma_{pt}$.

### `calculate_homogeneity_criterion_expanded`

Calcula el criterio de homogeneidad expandido, considerando la varianza intra-muestra.

**Referencia:** ISO 13528:2022, Sección 9.2.4

```r
calculate_homogeneity_criterion_expanded(sigma_pt, sw_sq)
```

### `evaluate_homogeneity`

Evalúa si la homogeneidad cumple con los criterios.

```r
evaluate_homogeneity(ss, c_criterion, c_expanded = NULL)
```

-   **Retorna**: Lista con `passes_criterion` (TRUE/FALSE), `passes_expanded` y `conclusion` (texto).

---

## 3. Estabilidad

### `calculate_stability_stats`

Calcula estadísticos de estabilidad comparando muestras de estabilidad con la media de homogeneidad.

**Archivo:** `R/pt_homogeneity.R`
**Referencia:** ISO 13528:2022, Sección 9.3

```r
calculate_stability_stats(stab_sample_data, hom_grand_mean)
```

-   **Retorna**: Estadísticos incluyendo `diff_hom_stab` (diferencia absoluta entre medias).

### `evaluate_stability`

Evalúa si la estabilidad cumple con los criterios.

```r
evaluate_stability(diff_hom_stab, c_criterion, c_expanded = NULL)
```

---

## 4. Incertidumbres

### `calculate_u_hom`

Calcula la contribución de incertidumbre por falta de homogeneidad.

**Referencia:** ISO 13528:2022, Sección 9.5

```r
calculate_u_hom(ss)
```

-   **Retorna**: $u_{hom} = s_s$.

### `calculate_u_stab`

Calcula la contribución de incertidumbre por falta de estabilidad.

**Referencia:** ISO 13528:2022, Sección 9.5

```r
calculate_u_stab(diff_hom_stab, c_criterion)
```

---

## 5. Puntajes

**Archivo:** `R/pt_scores.R`
**Referencia:** ISO 13528:2022, Sección 10

### `calculate_z_score`

$$z = \frac{x - x_{pt}}{\sigma_{pt}}$$

```r
calculate_z_score(x, x_pt, sigma_pt)
```

### `calculate_z_prime_score`

$$z' = \frac{x - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}}$$

```r
calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)
```

### `calculate_zeta_score`

$$\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}}$$

```r
calculate_zeta_score(x, x_pt, u_x, u_xpt)
```

### `calculate_en_score`

$$E_n = \frac{x - x_{pt}}{\sqrt{U_x^2 + U_{xpt}^2}}$$

```r
calculate_en_score(x, x_pt, U_x, U_xpt)
```

---

## 6. Evaluación de Puntajes

### `evaluate_z_score` / `evaluate_z_score_vec`

Clasifica un puntaje z (o z'/zeta).

```r
evaluate_z_score(z)
```

-   **Retorna**:
    -   "Satisfactorio" si $|z| \leq 2$
    -   "Cuestionable" si $2 < |z| < 3$
    -   "No satisfactorio" si $|z| \geq 3$

### `evaluate_en_score` / `evaluate_en_score_vec`

Clasifica un puntaje En.

```r
evaluate_en_score(en)
```

-   **Retorna**:
    -   "Satisfactorio" si $|E_n| \leq 1$
    -   "No satisfactorio" si $|E_n| > 1$
