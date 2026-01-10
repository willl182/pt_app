# Módulo: Compatibilidad Metrológica

## Descripción
Evalúa la coherencia entre el valor de referencia y los valores de consenso calculados por diferentes métodos.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `cloned_app.R` |
| UI | Accordion "Compatibilidad Metrológica" |

## Lógica de Cálculo

### Incertidumbre Definida ($u_{xpt,def}$)
Para cada método de consenso:
$$u_{xpt,def} = \sqrt{u_{xpt}^2 + u_{hom}^2 + u_{stab}^2}$$

Donde:
- $u_{xpt}$: Incertidumbre del valor asignado
- $u_{hom}$: Contribución de homogeneidad ($s_s$)
- $u_{stab}$: Contribución de estabilidad ($D/\sqrt{3}$)

### Incertidumbre de Referencia ($u_{ref}$)
$$u_{ref} = k \times \frac{sd_{ref}}{\sqrt{m}}$$

### Criterio de Compatibilidad
$$Criterio = \sqrt{u_{xpt,def}^2 + u_{ref}^2}$$

**Resultado**:
- **Compatible**: $|x_{pt,ref} - x_{pt,consenso}| \leq Criterio$
- **No Compatible**: $|x_{pt,ref} - x_{pt,consenso}| > Criterio$

## Reactive Principal
### `metrological_compatibility_data()`
EventReactive activado por `input$run_metrological_compatibility`.

Consolida:
1. Datos de referencia
2. Resultados de consenso (cache)
3. Resultados de Algoritmo A (cache)
4. Resultados de homogeneidad/estabilidad

## Output
`output$metrological_compatibility_table`: Tabla comparativa para todos los métodos.
