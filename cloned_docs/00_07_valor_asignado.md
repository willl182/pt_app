# Módulo: Valor Asignado

## Descripción
Este módulo gestiona el cálculo del valor asignado ($x_{pt}$) utilizando diferentes métodos según la disponibilidad de datos y las preferencias del usuario.

## Métodos Disponibles

| Método | Código | Descripción |
|--------|--------|-------------|
| Referencia | 1 | $x_{pt} = \bar{x}_{ref}$ |
| Consenso MADe | 2a | $x_{pt} = \text{mediana}$, $\sigma_{pt} = MADe$ |
| Consenso nIQR | 2b | $x_{pt} = \text{mediana}$, $\sigma_{pt} = nIQR$ |
| Algoritmo A | 3 | $x_{pt} = x^*$, $\sigma_{pt} = s^*$ |

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| UI | Accordion dentro de "Valor asignado" |

## Reactives

### Valor de Referencia (Método 1)
```r
reference_table_data <- reactive({
  pt_prep_data() %>% filter(participant_id == "ref", ...)
})
```

### Valor Consenso (Métodos 2a/2b)
Usa `ptcalc::calculate_mad_e()` y `ptcalc::calculate_niqr()`.

### Algoritmo A (Método 3)
Usa `ptcalc::run_algorithm_a()` para estimación robusta.

## Cálculo de Incertidumbre del Valor Asignado
$$u_{xpt} = 1.25 \times \frac{\sigma_{pt}}{\sqrt{n}}$$

Donde $n$ es el número de participantes.

## Outputs
- `output$reference_table`: Datos del laboratorio de referencia
- `output$consensus_summary_table`: Resumen de consenso
- `output$algoA_result_summary`: Resultados del Algoritmo A
