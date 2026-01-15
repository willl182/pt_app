# Algoritmo A - Explicación Detallada

El **Algoritmo A** (ISO 13528) calcula de forma robusta el **valor asignado (consenso)** y la **desviación estándar robusta** a partir de resultados de participantes en ensayos de aptitud.

---

## Propósito

En ensayos de aptitud (Proficiency Testing), los participantes reportan mediciones del mismo material. El Algoritmo A:

- **Reduce la influencia de valores atípicos** (outliers)
- **Calcula un consenso robusto** representativo del grupo
- **Es iterativo**: refina las estimaciones hasta converger

---

## Paso a Paso del Algoritmo

### Paso 1: Preparación de Datos

Filtra valores no válidos (`NA`, `Inf`, `-Inf`) y requiere al menos 3 resultados válidos.

```r
mask <- is.finite(values)
values <- values[mask]
ids <- ids[mask]
n <- length(values)
```

---

### Paso 2: Estimadores Iniciales

Calcula estimadores robustos iniciales usando **mediana** y **MAD** (Median Absolute Deviation):

```r
x_star <- median(values)                        # Valor asignado inicial
s_star <- 1.483 * median(abs(values - x_star))  # Desviación robusta inicial (MAD escalado)
```

> **Nota**: El factor 1.483 hace que el MAD sea consistente con la desviación estándar para distribuciones normales.

---

### Paso 3: Iteración

Para cada iteración:

#### 3.1 Calcular residuos estandarizados

$$u_i = \frac{x_i - x^*}{1.5 \times s^*}$$

#### 3.2 Actualizar valor asignado y desviación

El algoritmo usa los residuos para recalcular las estimaciones de forma robusta:

$$x^*_{nuevo} = \text{promedio ponderado de los valores}$$

$$s^*_{nuevo} = \sqrt{\frac{\sum (x_i - x^*_{nuevo})^2}{n}}$$

---

### Paso 4: Criterio de Convergencia

El algoritmo converge cuando:

$$\Delta x^* < 0.001 \quad \text{Y} \quad \Delta s^* < 0.001$$

Máximo de 50 iteraciones si no converge antes.

---

## Ejemplo Práctico

Usando datos de CO a nivel **2-μmol/mol** del archivo `data/summary_n4.csv`:

| Participante | Resultado (mean_value) |
|--------------|------------------------|
| part_1       | 2.01215, 2.01724, 2.01051 |
| part_2       | 2.01209, 2.01407, 2.01391 |
| part_3       | 2.01303, 2.01360, 2.01247 |
| ref          | 2.01367, 2.01215, 2.01375 |

### Cálculos Detallados

#### Paso 1: Datos de entrada

```
values = [2.0122, 2.0172, 2.0105, 2.0121, 2.0141, 2.0139, 
          2.0130, 2.0136, 2.0125, 2.0137, 2.0122, 2.0137]
n = 12
```

#### Paso 2: Estimadores iniciales

```
x* (mediana) = 2.0132
s* (MAD×1.483) = 1.483 × median(|values - 2.0132|) ≈ 0.0016
```

#### Paso 3: Primera iteración

```
Cálculo de u_i para cada valor:
u_1 = (2.0122 - 2.0132) / (1.5 × 0.0016) = -0.42

x*_nuevo = promedio robusto ≈ 2.0132
s*_nuevo = desviación robusta ≈ 0.0016
```

#### Paso 4: Convergencia

```
Δx* ≈ 0.00001 < 0.001 ✓
Δs* ≈ 0.00001 < 0.001 ✓
→ Converge en iteración 2
```

---

## Resultados Retornados

La función retorna una lista con:

| Campo | Descripción |
|-------|-------------|
| `assigned_value` | Valor asignado final (x*) |
| `robust_sd` | Desviación estándar robusta final (s*) |
| `iterations` | DataFrame con historial de iteraciones |
| `converged` | Booleano: ¿convergió antes de 50 iteraciones? |
| `error` | Mensaje de error si hubo problemas, o NULL |

---

## Código de la Función (Simplificado)

```r
run_algorithm_a <- function(values, ids, max_iter = 50) {
  # 1. Filtrar valores no válidos
  mask <- is.finite(values)
  values <- values[mask]
  ids <- ids[mask]
  n <- length(values)
  
  if (n < 3) {
    return(list(error = "El Algoritmo A requiere al menos 3 resultados válidos."))
  }

  # 2. Estimadores iniciales robustos
  x_star <- median(values, na.rm = TRUE)
  s_star <- 1.483 * median(abs(values - x_star), na.rm = TRUE)

  # 3. Iteración
  for (iter in seq_len(max_iter)) {
    # Residuos estandarizados
    u_values <- (values - x_star) / (1.5 * s_star)
    
    # Nuevas estimaciones (robustas)
    x_new <- # cálculo robusto
    s_new <- # cálculo robusto

    # Verificar convergencia
    if (abs(x_new - x_star) < 1e-03 && abs(s_new - s_star) < 1e-03) {
      break
    }
    
    x_star <- x_new
    s_star <- s_new
  }

  # 4. Retornar resultados
  list(
    assigned_value = x_star,
    robust_sd = s_star,
    iterations = iteration_df,
    converged = TRUE
  )
}
```

---

## Referencias

- **ISO 13528:2022** - Métodos estadísticos para uso en ensayos de aptitud
- **ISO/IEC 17043** - Requisitos generales para ensayos de aptitud
