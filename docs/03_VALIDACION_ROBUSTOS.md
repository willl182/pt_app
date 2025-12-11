# Validación de Funciones Estadísticas Robustas

## Descripción
Este documento describe la validación de las funciones estadísticas robustas implementadas en el módulo `R/robust_stats.R`, específicamente el cálculo de nIQR y el Algoritmo A (ponderado) de ISO 13528:2022.

## Funciones Validadas
1.  **calculate_niqr(x)**
    *   **Propósito:** Calcular el rango intercuartílico normalizado.
    *   **Método:** `0.7413 * (Q3 - Q1)`.
    *   **Verificación:** Se verificó que devuelve un valor positivo y escala correctamente la dispersión en datos normales.

2.  **run_algorithm_a(values, ids, max_iter)**
    *   **Propósito:** Calcular el promedio robusto (x*) y la desviación estándar robusta (s*).
    *   **Método:** Iterativo con ponderación de Huber (ponderación 1.5 * s*).
    *   **Nota de Implementación:** A diferencia de la versión estándar de ISO 13528 que usa un factor de corrección de 1.134 para la desviación estándar en cada paso (método Winsorizado), esta implementación utiliza el método de **RMS ponderado** (suma de cuadrados ponderados) para calcular `s_new`, sin el factor 1.134 explícito en la fórmula de actualización, pero derivándolo de los pesos. Esto es consistente con la implementación en `app.R` original.

## Resultados de la Prueba
El script `tests/test_robust.R` se ejecutó con éxito.
- **Entrada:** Vector con un valor atípico claro (20.0 entre valores ~10.2).
- **Salida:** El valor asignado (x*) calculado fue cercano a 10.2, ignorando la influencia del valor 20.0, lo que confirma la robustez del algoritmo.

## Conclusión
Las funciones robustas operan correctamente y manejan valores atípicos según lo esperado.
