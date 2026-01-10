# Módulo Shiny: Puntajes PT

## Descripción
Módulo para el cálculo y visualización de puntajes de desempeño de participantes.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| UI | `tabPanel("Puntajes PT")` |

## Integración con ptcalc
El módulo utiliza las funciones del paquete ptcalc para cálculos:
- `ptcalc::calculate_z_score()`
- `ptcalc::calculate_z_prime_score()`
- `ptcalc::calculate_zeta_score()`
- `ptcalc::calculate_en_score()`
- `ptcalc::evaluate_z_score_vec()`
- `ptcalc::evaluate_en_score_vec()`

## Reactives

### `scores_results_cache()`
Almacena resultados para evitar recálculos.

### `compute_scores_metrics()`
Función wrapper que:
1. Filtra datos por analito/nivel
2. Calcula todos los puntajes usando ptcalc
3. Evalúa cada puntaje
4. Retorna DataFrame consolidado

## Outputs
- `output$scores_parameter_table`: Parámetros del cálculo
- `output$z_scores_panel`: Visualización z-scores
- `output$en_scores_panel`: Visualización En-scores
