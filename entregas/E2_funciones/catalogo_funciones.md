# Entregable 2: Catálogo de Funciones (app.R y report_template.Rmd)

Este documento contiene el inventario y la descripción técnica de todas las funciones implementadas en el aplicativo para asegurar la trazabilidad y facilitar el mantenimiento del código.

## 1. Funciones en `app.R`

| Función | Parámetros | Propósito |
|---------|------------|-----------|
| `calculate_niqr(x)` | `x`: vector numérico | Calcula el rango intercuartílico normalizado ($0.7413 \times IQR$) como estimador robusto de la desviación estándar. |
| `format_num(x)` | `x`: valor numérico | Formatea números a 5 decimales para su visualización en tablas, manejando valores `NA`. |
| `get_scores_result(...)` | `pollutant, n_lab, level` | Recupera los resultados de puntajes del cache reactivo para una combinación específica. |
| `combine_scores_result(res)` | `res`: lista de resultados | Consolida los resultados de múltiples combinaciones de analito/nivel en un solo data frame. |
| `get_wide_data(df, pol)` | `df`: data frame, `pol`: analito | Transforma datos de formato largo a ancho (pivoteo), facilitando el cálculo estadístico por réplica. |
| `compute_homogeneity_metrics(...)` | `pollutant, level` | **Lógica Core:** Ejecuta el análisis de varianza y evaluación de criterios de homogeneidad (ISO 13528). |
| `compute_stability_metrics(...)` | `pollutant, level, hom_res` | **Lógica Core:** Compara datos de estabilidad contra el valor de referencia y evalúa cumplimiento. |
| `compute_scores_metrics(...)` | `summary_df, pol, n, lev, sigma, u, k, m` | **Lógica Core:** Calcula puntajes z, z', zeta y En basándose en los parámetros seleccionados. |
| `run_algorithm_a(values, ids, max)` | `values`: datos, `ids`: labs, `max`: iteraciones | Implementación robusta del Algoritmo A de la ISO 13528 para media y desviación estándar robusta. |

## 2. Funciones en `report_template.Rmd`

> [!NOTE]
> Estas funciones están duplicadas en la plantilla para garantizar que el informe sea autocontenido y reproducible fuera de la sesión de Shiny.

| Función | Diferencia con `app.R` | Propósito |
|---------|-----------------------|-----------|
| `calculate_niqr(x)` | Idéntica | Cálculo de nIQR para el informe. |
| `get_wide_data(df, pol)` | Idéntica | Preparación de datos para tablas del informe. |
| `run_algorithm_a(values, iter)` | No requiere IDs | Versión simplificada para el cálculo iterativo en el RMarkdown. |
| `compute_homogeneity(...)` | Simplificada | Versión optimizada para mostrar resultados rápidos en los anexos del informe. |

## 3. Funciones en `R/utils.R`

| Función | Parámetros | Propósito |
|---------|------------|-----------|
| `algorithm_A(x, iter)` | `x`: vector numérico | Versión modular y limpia diseñada para ser utilizada por `source()` en versiones futuras (`app_gem.R`). |
| `mad_e_manual(x)` | `x`: vector numérico | Cálculo manual de la desviación absoluta de la mediana escalada (MADe). |
| `nIQR_manual(x)` | `x`: vector numérico | Implementación manual del nIQR (equivalente funcional a `calculate_niqr`). |

---

## 4. Índice de Llamadas (Relación Reactiva)

Las funciones core son invocadas principalmente a través de `observeEvent` y `reactive` en `app.R`:

1. **Carga**: `vroom` carga los datos.
2. **Homogeneidad**: `homogeneity_run` -> `compute_homogeneity_metrics`.
3. **Estabilidad**: `stability_run` -> `compute_stability_metrics`.
4. **Consenso**: `algoA_run` -> `run_algorithm_a`.
5. **Puntajes**: `scores_trigger` -> `compute_scores_metrics`.
6. **Reporte**: `downloadHandler` -> `rmarkdown::render` (usando las funciones locales del Rmd).
