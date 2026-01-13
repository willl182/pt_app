# Métodos Estadísticos Robustos (ISO 13528)

## 1. Descripción General

Este módulo (`ptcalc/R/pt_robust_stats.R`) implementa estimadores estadísticos robustos utilizados para calcular valores asignados ($x_{pt}$) y desviaciones estándar ($\sigma_{pt}$) resistentes a valores atípicos (outliers). Estos métodos son fundamentales para el análisis de ensayos de aptitud, asegurando que los valores extremos no distorsionen la evaluación del desempeño del grupo.

---

## 2. Algoritmo A (ISO 13528 Anexo C)

El Algoritmo A es un procedimiento iterativo utilizado para calcular una media robusta ($x^*$) y una desviación estándar robusta ($s^*$). Es el método principal utilizado en esta aplicación cuando se selecciona la opción "Consenso (Algoritmo A)".

### 2.1 Flujo del Algoritmo

1.  **Inicialización:**
    *   $x^* = \text{mediana}(x)$
    *   $s^* = 1.483 \times \text{MAD}(x)$
2.  **Iteración:**
    *   Calcular el límite de ponderación $\delta = 1.5 \times s^*$.
    *   Para cada valor $x_i$, calcular el valor ajustado $x_i^*$:
        $$x_i^* = \begin{cases} x^* - \delta & \text{si } x_i < x^* - \delta \\ x^* + \delta & \text{si } x_i > x^* + \delta \\ x_i & \text{en otro caso} \end{cases}$$
    *   Actualizar la media robusta: $x^*_{new} = \text{media}(x_i^*)$.
    *   Actualizar la desviación estándar robusta: $s^*_{new} = 1.134 \times \sqrt{\frac{\sum(x_i^* - x^*_{new})^2}{p-1}}$.
3.  **Convergencia:** Repetir hasta que los valores de $x^*$ y $s^*$ se estabilicen (la diferencia sea menor a la tolerancia).

### 2.2 Ejemplo Numérico

Consideremos un conjunto de datos pequeño con un valor atípico:
**Datos:** `x = [10.1, 10.2, 10.3, 10.2, 25.0]` (El 25.0 es un atípico evidente).

**Paso 0: Estimaciones Iniciales**
*   Mediana ($x^*_0$) = 10.2
*   MAD = 0.1
*   SD Robusta ($s^*_0$) = $1.483 \times 0.1 = 0.1483$

**Paso 1: Ponderación**
El algoritmo detecta que 25.0 está muy lejos de 10.2 (más de $1.5 \times s^*$). En el cálculo de la media ponderada, el impacto del 25.0 se reduce drásticamente (se "recorta" o "winsoriza" implícitamente en la versión modificada o se pondera bajo en la versión Huber).

**Resultado:** El algoritmo converge rápidamente hacia las propiedades del grupo principal (~10.2), ignorando efectivamente el valor 25.0.

### 2.3 Comportamiento de Convergencia
*   **Convergencia Rápida:** Datos con distribución aproximadamente normal.
*   **Convergencia Lenta/Nula:** Distribuciones bimodales o varianza muy alta.
*   **Límite:** La aplicación establece un límite estricto de `max_iter` (por defecto 50) para evitar bucles infinitos.

---

## 3. Otros Estimadores Robustos

### 3.1 Rango Intercuartílico Normalizado (nIQR)

$$nIQR = 0.7413 \times (Q_3 - Q_1)$$

Calculado mediante la función `calculate_niqr(x)`. Proporciona una estimación robusta de la desviación estándar basada en el 50% central de los datos. Es útil cuando la distribución es ligeramente asimétrica.

### 3.2 Desviación Absoluta de la Mediana Escalada (MADe)

$$MADe = 1.483 \times \text{mediana}(|x_i - \text{mediana}(x)|)$$

Calculado mediante `calculate_mad_e(x)`. Es el estimador de escala simple más robusto (punto de ruptura del 50%) y sirve como punto de partida para el Algoritmo A.

---

## 4. Tabla Comparativa

| Característica | MADe | nIQR | Algoritmo A |
|----------------|------|------|-------------|
| **Complejidad** | Baja | Baja | Alta (Iterativo) |
| **Eficiencia (datos normales)** | Baja (37%) | Media | Alta (95%) |
| **Punto de Ruptura** | 50% | 25% | 50% |
| **Uso Principal** | Estimación inicial | Distribuciones asimétricas | **Valor asignado por consenso** |
