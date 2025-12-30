# Módulo: Funciones Auxiliares

## Descripción
Este módulo contiene funciones helper y utilidades que son utilizadas de forma transversal por los distintos módulos de análisis de la aplicación. Incluye desde cálculos estadísticos básicos hasta funciones para la gestión del cache de resultados y transformación de datos.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 21 - 31 (Helpers iniciales) y 144 - 225 (Server helpers) |

## Funciones Principales

### `calculate_niqr(x)`
**Descripción**: Calcula el Rango Intercuartílico Normalizado (nIQR), un estadístico de dispersión robusto.

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `x` | numeric vector | Conjunto de datos numéricos. |

**Retorna**: El valor de nIQR (`0.7413 * (Q3 - Q1)`). Retorna `NA` si hay menos de 2 valores finitos.

---

### `format_num(x)`
**Descripción**: Formatea valores numéricos para su visualización en tablas o reportes con precisión de 5 decimales.

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `x` | numeric | Valor a formatear. |

**Retorna**: Cadena de texto formateada (`sprintf("%.5f", x)`) o `NA_character_` si el valor es `NA`.

---

### `algo_key(pollutant, n_lab, level)`
**Descripción**: Genera una cadena de texto única que sirve como clave para almacenar y recuperar resultados del cache.

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `pollutant` | character | Nombre del analito. |
| `n_lab` | numeric | Número de laboratorios/esquema. |
| `level` | character | Nivel de PT. |

**Retorna**: Cadena en formato `pollutant||n_lab||level`.

---

### `get_cached_result(cache, pollutant, n_lab, level)`
**Descripción**: Recupera un resultado específico de una lista (cache) basado en la combinación de criterios seleccionada.

**Retorna**: El objeto almacenado o un mensaje de error si no existe la combinación.

---

### `get_scores_result(pollutant, n_lab, level)`
**Descripción**: Versión especializada de acceso al cache para el módulo de Puntajes PT. Verifica si el cálculo ha sido activado mediante `scores_trigger()`.

---

### `combine_scores_result(res)`
**Descripción**: Combina los resultados de puntajes de múltiples combinaciones almacenadas en el cache en un único DataFrame. Utilizado para la vista general y reportes globales.

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `res` | list | Lista de resultados proveniente del cache. |

**Retorna**: Lista con el DataFrame consolidado o mensaje de error.

---

### `get_wide_data(df, target_pollutant)`
**Descripción**: Filtra los datos por analito y los transforma de formato "largo" (tidy) a formato "ancho" (un columna por réplica). Es fundamental para los cálculos de homogeneidad y estabilidad que requieren comparar réplicas una al lado de la otra.

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `df` | data.frame | DataFrame de entrada (long format). |
| `target_pollutant` | character | Analito a filtrar. |

**Retorna**: DataFrame con columnas prefijadas como `sample_1`, `sample_2`, etc.

## Fórmulas y Cálculos
- **nIQR**: $nIQR = 0.7413 \times (Q_{3} - Q_{1})$
- **Formateo**: `sprintf("%.5f", x)`

## Referencias
- ISO 13528:2022 Anexo C.
