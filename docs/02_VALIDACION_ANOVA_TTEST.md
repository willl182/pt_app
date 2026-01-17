# Validación de Funciones ANOVA y T-Test

## Descripción
Este documento describe la validación de las funciones para evaluación de homogeneidad y estabilidad implementadas en `R/homogeneity_stability.R`. Estas funciones siguen el protocolo estadístico de la norma ISO 13528:2022, Anexo B.

## Funciones Validadas
1.  **compute_homogeneity_metrics**
    *   **Propósito:** Evaluar la homogeneidad de los ítems del ensayo.
    *   **Método:** ANOVA de un factor para estimar la varianza entre muestras ($s_s$) y compararla con un criterio crítico ($0.3 \sigma_{pt}$).
    *   **Cálculo de $\sigma_{pt}$:** Se utiliza el MADe de la primera muestra de homogeneidad como estimador inicial de la desviación estándar del ensayo.

2.  **compute_stability_metrics**
    *   **Propósito:** Evaluar la estabilidad de los ítems del ensayo.
    *   **Método:** Comparación de la media general de los datos de estabilidad ($y_2$) con la media de los datos de homogeneidad ($y_1$).
    *   **Criterio:** $|y_1 - y_2| \le 0.3 \sigma_{pt}$.

## Resultados de la Prueba
El script `tests/test_homogeneity.R` se ejecutó con éxito utilizando los datos de prueba (`data/homogeneity.csv` y `data/stability.csv`).
- **Analito:** CO, Nivel 1.
- **Homogeneidad:** Se obtuvieron valores válidos para $s_s$ y $\sigma_{pt}$.
- **Estabilidad:** Se calculó la diferencia absoluta y se comparó con el criterio.
- **Conclusión:** Las funciones extraídas de `app.R` replican correctamente la lógica estadística necesaria para generar los reportes de validación.

## Referencia Normativa
- **ISO 13528:2022:** Statistical methods for use in proficiency testing by interlaboratory comparison. Annex B (Homogeneity and Stability checks).
