# Módulo: Compatibilidad Metrológica

## 1. Descripción General

Este módulo evalúa la coherencia metrológica entre el valor de referencia ($x_{ref}$) y los valores asignados calculados mediante métodos de consenso (MADe, nIQR) o algoritmos robustos (Algoritmo A). El objetivo es determinar si existe un sesgo significativo entre la referencia y los resultados de los participantes, de acuerdo con las recomendaciones de la norma ISO 13528:2022.

## 2. Ubicación en el Código

| Elemento | Valor |
|----------|-------|
| **Archivo** | `cloned_app.R` |
| **Ubicación UI** | Accordion "Compatibilidad Metrológica" dentro de "Valor asignado" |
| **Lógica Reactiva** | `metrological_compatibility_data()` |

---

## 3. Lógica de Cálculo

La compatibilidad se evalúa comparando la diferencia absoluta entre los valores contra un criterio de incertidumbre combinada.

### 3.1 Incertidumbre Definida ($u_{xpt,def}$)
Para cada método de consenso o robusto, la incertidumbre estándar combinada considera la incertidumbre estadística del método y las contribuciones de calidad del ítem:

$$u_{xpt,def} = \sqrt{u_{xpt}^2 + u_{hom}^2 + u_{stab}^2}$$

Donde:
- $u_{xpt}$: Incertidumbre estándar del valor asignado (ej. $1.25 \times s^* / \sqrt{n}$).
- $u_{hom}$: Incertidumbre por falta de homogeneidad ($s_s$).
- $u_{stab}$: Incertidumbre por inestabilidad ($D_{max}/\sqrt{3}$).

### 3.2 Incertidumbre de Referencia ($u_{ref}$)
Calculada a partir de la desviación estándar del laboratorio de referencia y el factor de cobertura:

$$u_{ref} = k \times \frac{sd_{ref}}{\sqrt{m}}$$

### 3.3 Criterio de Compatibilidad
El criterio de aceptación ($Crit$) se define como la raíz cuadrada de la suma de los cuadrados de las incertidumbres involucradas:

$$Criterio = \sqrt{u_{xpt,def}^2 + u_{ref}^2}$$

---

## 4. Interpretación de Resultados

El sistema clasifica la relación entre métodos de la siguiente manera:

| Condición | Resultado | Interpretación |
|-----------|-----------|----------------|
| $|x_{pt,ref} - x_{pt,con}| \leq Criterio$ | **Compatible** | No hay evidencia estadística de sesgo significativo. |
| $|x_{pt,ref} - x_{pt,con}| > Criterio$ | **No Compatible** | Existe un sesgo significativo entre la referencia y el consenso. |

---

## 5. Reactive Principal: `metrological_compatibility_data()`

Este `eventReactive` se activa mediante el botón `input$run_metrological_compatibility`. Su función es consolidar:
1.  **Datos de Referencia**: Obtenidos de la carga de datos inicial.
2.  **Resultados de Consenso**: Recuperados del caché de cálculos.
3.  **Resultados de Algoritmo A**: Recuperados del caché de cálculos robustos.
4.  **Parámetros de Calidad**: Incertidumbres de homogeneidad ($u_{hom}$) y estabilidad ($u_{stab}$).

---

## 6. Salida de Datos

### `output$metrological_compatibility_table`
Muestra una tabla detallada con las siguientes columnas por cada combinación de analito/nivel:
- Método evaluado.
- Valor asignado por el método.
- Diferencia respecto a la referencia.
- Incertidumbre combinada del criterio.
- Estado final (Compatible / No Compatible).

---

## 7. Referencias Cruzadas
- **Valor Asignado:** [07_valor_asignado.md](07_valor_asignado.md)
- **Homogeneidad y Estabilidad:** [../04_pt_homogeneity.md](../04_pt_homogeneity.md)
- **Estadísticos Robustos:** [../03_pt_robust_stats.md](../03_pt_robust_stats.md)
- **Glosario:** [../00_glossary.md](../00_glossary.md)
