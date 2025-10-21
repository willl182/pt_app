# **Informe de Auditoría: Semana 2**

**Fecha:** 21 de octubre de 2025
**Auditor:** Jules (IA)
**Módulo:** Validación de Ítems (Homogeneidad y Estabilidad)

---

### **1. Objetivo**

Validar que los cálculos estadísticos para determinar la homogeneidad y estabilidad de los ítems en `app.R` son correctos y se implementan conforme a la normativa de referencia.

---

### **2. Hallazgos**

| Criterio de Éxito | Estado | Observaciones |
| :--- | :--- | :--- |
| **1. Correctitud del Cálculo de Homogeneidad** | `VERIFICADO POR REVISIÓN DE CÓDIGO` | La lógica en `homogeneity_run` (app.R:286-474) sigue los pasos del método ANOVA manual. El cálculo de `ss`, `sw` y `sigma_pt` (como MADe) parece correcto. La validación final dependerá de la comparación con datos externos. |
| **2. Aplicación Correcta del Criterio de Homogeneidad** | `APROBADO` | La comparación `hom_ss <= hom_c_criterion` (siendo `hom_c_criterion` igual a `0.3 * sigma_pt`) está implementada correctamente y determina el estado final de homogeneidad. |
| **3. Correctitud del Cálculo de Estabilidad** | `VERIFICADO POR REVISIÓN DE CÓDIGO` | La lógica en `stability_run` (app.R:476-676) compara correctamente la diferencia absoluta entre las medias de los datos de homogeneidad y estabilidad con el criterio `0.3 * sigma_pt`. Además, realiza un t-test como verificación secundaria. La implementación es correcta. |
| **4. Presentación Clara de Resultados** | `APROBADO` | La UI dedica pestañas separadas para "Homogeneity Assessment" y "Stability Assessment", con conclusiones claras y tablas detalladas, lo que facilita la interpretación de los resultados. |
| **5. Manejo de Datos Insuficientes** | `APROBADO` | El código incluye comprobaciones explícitas para el número de réplicas y de ítems (ej. `if (m < 2)`), devolviendo un error controlado, lo cual previene fallos inesperados. |

---

### **3. Plan de Pruebas**

Se desarrollará el script `test_w_02.R` que, aunque no se pueda ejecutar, contendrá las funciones para generar los conjuntos de datos de validación. Estos archivos son cruciales para una futura verificación manual o automatizada.

*   **T2.1 (Validación Homogeneidad):**
    *   **Acción:** Generar `homogeneity_valid.csv` con datos donde `ss` sea menor que `0.3 * sigma_pt`.
*   **T2.2 (Fallo Homogeneidad):**
    *   **Acción:** Generar `homogeneity_fail.csv` con datos donde `ss` sea mayor que `0.3 * sigma_pt`.
*   **T2.3 (Validación Estabilidad):**
    *   **Acción:** Generar `stability_valid.csv` donde la diferencia de medias sea menor que el criterio.
*   **T2.4 (Fallo Estabilidad):**
    *   **Acción:** Generar `stability_fail.csv` donde la diferencia de medias sea mayor.
*   **T2.5 (Datos Insuficientes):**
    *   **Acción:** Generar un archivo `homogeneity_insufficient.csv` con una sola réplica.

---

### **4. Conclusión**

La implementación de los cálculos de homogeneidad y estabilidad en `app.R` es robusta y parece ser correcta desde la perspectiva del código. La lógica maneja adecuadamente los criterios de aceptación y los casos de error. La validación final de la precisión matemática requerirá ejecutar los análisis con los conjuntos de datos de prueba y comparar los resultados con un software de referencia.
