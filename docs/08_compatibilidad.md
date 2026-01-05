# Módulo: Compatibilidad Metrológica

## Descripción
Este módulo evalúa la coherencia entre el valor asignado por el laboratorio de referencia ($x_{pt}(Ref)$) y los valores asignados calculados mediante métodos de consenso (Médodo 2a: MADe, Método 2b: nIQR) y algoritmos robustos (Método 3: Algoritmo A). La validación se basa en verificar si la diferencia entre los valores es menor o igual a la incertidumbre combinada asociada.

## Ubicación en el Código
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Líneas | 2633 - 2811 |
| UI | Accordion "Compatibilidad Metrológica" dentro de "Valor asignado" (Líneas 1023 - 1041) |

## Dependencias
- **Reactives**: `pt_prep_data()`, `consensus_results_cache()`, `algoA_results_cache()`.
- **Módulos**: `03_Homogeneidad`, `04_Estabilidad`.
- **Inputs**: `input$run_metrological_compatibility`, `input$report_k`.

## Lógica de Procesamiento
1. **Recopilación**: Obtiene los valores asignados y desviaciones de referencia, consenso y Algoritmo A de sus respectivos caches y datos cargados.
2. **Incertidumbres Base**: Obtiene $u_{hom}$ ($s_s$) y $u_{stab}$ ($D_{max}/\sqrt{3}$) de los análisis de calidad del ítem para cada analito/nivel.
3. **Incertidumbre Combinada**: Calcula la incertidumbre expandida de la diferencia para cada método.
4. **Decisión**: Compara la diferencia absoluta contra el criterio calculado.

## Reactives

### `metrological_compatibility_data()`
| Propiedad | Valor |
|-----------|-------|
| Descripción | Consolida todos los valores y realiza el loop de cálculo de compatibilidad para todas las combinaciones analito/esquema/nivel. |
| Depende de | `input$run_metrological_compatibility` (Execution Trigger) |
| Retorna | DataFrame con las columnas de diferencia y estado de compatibilidad. |

## Outputs

### `output$metrological_compatibility_table`
- **Tipo**: renderDataTable
- **Descripción**: Muestra una tabla comparativa detallada para todos los métodos evaluados vs. Referencia.

## Fórmulas y Cálculos

### Incertidumbre de Referencia ($u_{ref}$)
$$u_{ref} = k \times \frac{sd_{ref}}{\sqrt{m}}$$
Donde $k$ es el factor de cobertura (generalmente 2) y $m$ es el número de réplicas.

### Incertidumbre Definida de la Diferencia ($u_{xpt,def}$)
Para cada método de consenso/robusto ($Method$):
$$u_{xpt,Method} = 1.25 \times \frac{\sigma_{pt,Method}}{\sqrt{n_{participantes}}}$$
$$u_{xpt,def} = \sqrt{u_{xpt,Method}^2 + u_{hom}^2 + u_{stab}^2}$$

### Criterio de Compatibilidad
1. **Diferencia observada ($D$):** $|x_{pt}(Ref) - x_{pt}(Method)|$
2. **Criterio ($Crit$):** $\sqrt{u_{xpt,def}^2 + u_{ref}^2}$

**Estado:**
- **Compatible:** Si $D \leq Crit$
- **No Compatible:** Si $D > Crit$

## Referencias
- ISO 13528:2022 Sección 9.7 (Comparación de valores asignados).
- Guía GUM para la expresión de la incertidumbre.
