# Módulo: Algoritmo A

## Descripción
Este módulo implementa el **Algoritmo A** descrito en el **Anexo C de la norma ISO 13528:2022**. Se utiliza para realizar una estimación robusta del valor asignado ($x^*$) y la desviación estándar robusta ($s^*$) a partir de los resultados reportados por los participantes, minimizando el impacto de valores atípicos sin eliminarlos necesariamente.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 627 - 775 (Lógica) y 4876 - 5151 (Server) |
| UI | Accordion "Algoritmo A" dentro de "Valor asignado" (Líneas 954 - 984) |

## Dependencias
- **Reactives**: `pt_prep_data()`.
- **Inputs**: `input$algoA_max_iter`, `input$algoA_run`.

## Funciones Principales

### `run_algorithm_a(values, ids, max_iter = 50)`
**Descripción**: Ejecuta el proceso iterativo del Algoritmo A sobre un vector de valores.

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `values` | numeric vector | Resultados reportados por los participantes. |
| `ids` | character vector | Identificadores de los participantes. |
| `max_iter` | numeric | Número máximo de iteraciones permitidas. |

**Retorna**: Una lista con:
- `assigned_value` ($x^*$): Valor robusto final.
- `robust_sd` ($s^*$): Desviación estándar robusta final.
- `iterations`: DataFrame con el historial de cambios por iteración.
- `weights`: Pesos finales asignados a cada participante.
- `converged`: Booleano que indica si el proceso alcanzó el criterio de parada.

## Reactives

### `algoA_results_cache()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Almacena los resultados del Algoritmo A para todas las combinaciones de analito/nivel para evitar recálculos innecesarios. |

## Outputs

### `output$algoA_result_summary`
- **Tipo**: renderUI
- **Descripción**: Resumen visual de los parámetros finales ($x^*$ y $s^*$) y el estado de convergencia.

### `output$algoA_iterations_table`
- **Tipo**: renderDataTable
- **Descripción**: Tabla detallada que muestra la evolución de $x^*$ y $s^*$ en cada paso del proceso.

### `output$algoA_weights_table`
- **Tipo**: renderDataTable
- **Descripción**: Muestra el peso ($w_i$) y el residuo estandarizado para cada participante.

## Fórmulas y Cálculos

### Inicialización
1. $x^* = \text{mediana del conjunto de datos}$
2. $s^* = 1.483 \times \text{mediana}(|x_i - x^*|)$

### Proceso Iterativo
Para cada iteración $j$:
1. Se calcula el valor desviado permitido: $\delta = 1.5 \times s^*$
2. Para cada valor $x_i$, se ajusta si cae fuera de $[x^* - \delta, x^* + \delta]$:
   - Si $|x_i - x^*| \leq \delta$, el valor se mantiene.
   - Si $x_i < x^* - \delta$, se usa $x^* - \delta$.
   - Si $x_i > x^* + \delta$, se usa $x^* + \delta$.
3. Se actualizan los parámetros:
   - $x_{new}^* = \text{promedio de los valores ajustados}$.
   - $s_{new}^* = 1.134 \times \text{desviación estándar de los valores ajustados}$.

### Criterio de Convergencia
El proceso se detiene cuando los cambios en $x^*$ y $s^*$ son insignificantes (menores a $10^{-3}$) o se alcanza el máximo de iteraciones.

## Referencias
- ISO 13528:2022 Anexo C.
