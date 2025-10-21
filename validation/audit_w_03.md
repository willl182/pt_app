# **Informe de Auditoría: Semana 3**

**Fecha:** 21 de octubre de 2025
**Auditor:** Jules (IA)
**Módulo:** Núcleo de Análisis Robusto (Algoritmo A, MADe)

---

### **1. Objetivo**

Verificar que la implementación del Algoritmo A y el cálculo de estimadores robustos (MADe) en `app.R` son matemáticamente correctos y consistentes con la norma ISO 13528.

---

### **2. Hallazgos**

| Criterio de Éxito | Estado | Observaciones |
| :--- | :--- | :--- |
| **1. Correctitud de la Implementación del Algoritmo A** | `VERIFICADO POR REVISIÓN DE CÓDIGO` | La función `run_algorithm_a` (app.R:1286-1371) implementa correctamente el bucle iterativo, el cálculo de pesos y la actualización de `x*` y `s*` según la norma. La lógica de convergencia y el manejo de condiciones iniciales son adecuados. |
| **2. Correctitud del Cálculo de nIQR** | `NO ENCONTRADO` | No se encontró una función `calculate_niqr` en `app.R`. El protocolo de auditoría la mencionaba, pero el código no la incluye. Es posible que se haya optado por no implementarla o que esté en una versión anterior. |
| **3. Correctitud del Cálculo de MADe** | `APROBADO` | El cálculo de MADe (`1.483 * median(abs(x - median(x)))`) está correctamente implementado y se utiliza para determinar el valor de `sigma_pt` en el módulo de homogeneidad (app.R:347). |
| **4. Integración y Uso Correcto** | `APROBADO` | El valor de MADe se integra correctamente como `sigma_pt`. Los resultados del Algoritmo A se muestran en una sección dedicada de la UI, con tablas para las iteraciones y los pesos, lo cual es excelente para la trazabilidad. |
| **5. Manejo de Casos Límite (Edge Cases)** | `APROBADO` | La función `run_algorithm_a` incluye una comprobación explícita para el número de valores (`if (n < 3)`), devolviendo un error controlado y amigable para el usuario, lo que demuestra un diseño robusto. |

---

### **3. Plan de Pruebas**

Se desarrollará el script `test_w_03.R` para definir la generación de los siguientes conjuntos de datos, esenciales para la validación de los cálculos robustos:

*   **T3.1 (Validación Algoritmo A):**
    *   **Acción:** Generar `alg_a_valid.csv` con datos de un ejemplo de la norma ISO 13528 para verificar la exactitud de los resultados.
*   **T3.2 (Validación MADe):**
    *   **Acción:** Generar `robust_estimators_valid.csv` con un conjunto de datos simple para verificar el cálculo de MADe manualmente.
*   **T3.3 (Robustez Algoritmo A):**
    *   **Acción:** Generar `alg_a_outliers.csv` con valores atípicos claros para confirmar que el algoritmo converge a una media robusta.
*   **T3.4 (Datos Insuficientes):**
    *   **Acción:** Generar un archivo `summary_n_insufficient.csv` con menos de 3 participantes para probar el manejo de errores.

---

### **4. Conclusión**

La implementación del Algoritmo A y del estimador MADe es de alta calidad, robusta y parece seguir fielmente los procedimientos de la norma. La ausencia de la función `nIQR` debe ser clarificada, pero no afecta la funcionalidad principal auditada. La validación matemática final depende de la ejecución de pruebas con los conjuntos de datos de referencia.
