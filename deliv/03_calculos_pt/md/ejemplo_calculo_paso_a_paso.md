# Ejemplo de Cálculo Paso a Paso (ISO 13528:2022)

Este documento presenta un ejemplo detallado de los cálculos estadísticos realizados para el análisis de homogeneidad y la determinación de valores robustos, utilizando datos reales del contaminante **CO** al nivel de **2-μmol/mol** obtenidos del archivo `homogeneity.csv`.

## 1. Datos de Origen

Se seleccionan 10 muestras medidas por duplicado para el nivel de 2-μmol/mol. Los valores individuales son:

| Muestra | Réplica 1 | Réplica 2 | Media ($\bar{x}_i$) | Rango ($w_i$) |
| :--- | :--- | :--- | :--- | :--- |
| 1 | 2.011535 | 2.019468 | 2.015502 | 0.007933 |
| 2 | 2.016170 | 2.007576 | 2.011873 | 0.008594 |
| 3 | 2.020532 | 2.014273 | 2.017403 | 0.006259 |
| 4 | 2.010638 | 2.019574 | 2.015106 | 0.008936 |
| 5 | 2.017766 | 2.016162 | 2.016964 | 0.001604 |
| 6 | 2.011475 | 2.017979 | 2.014727 | 0.006504 |
| 7 | 2.007859 | 2.014869 | 2.011364 | 0.007010 |
| 8 | 2.014495 | 2.007766 | 2.011131 | 0.006729 |
| 9 | 2.007515 | 2.014681 | 2.011098 | 0.007166 |
| 10 | 2.017021 | 2.009505 | 2.013263 | 0.007516 |

## 2. Estadísticos Robustos de Dispersión

Utilizamos los 20 valores individuales para calcular estimadores resistentes a valores atípicos.

### 2.1 nIQR (Rango Intercuartílico Normalizado)

**Fórmula (ISO 13528:2022, 9.4):**
$$nIQR = 0.7413 \times (Q_3 - Q_1)$$

1.  **Cálculo de Cuartiles:**
    -   $Q_1$ (percentil 25): 2.010072
    -   $Q_3$ (percentil 75): 2.017394
2.  **Rango Intercuartílico (IQR):**
    $$IQR = 2.017394 - 2.010072 = 0.007322$$
3.  **Resultado:**
    $$nIQR = 0.7413 \times 0.007322 = 0.005428$$

### 2.2 MADe (Desviación Absoluta de la Mediana Escalada)

**Fórmula (ISO 13528:2022, 9.4):**
$$MADe = 1.483 \times \text{mediana}(|x_i - \text{mediana}(x)|)$$

1.  **Mediana de los 20 valores ($x_{med}$):**
    $$x_{med} = 2.014588$$
2.  **Mediana de las desviaciones absolutas (MAD):**
    $$MAD = \text{mediana}(|x_i - 2.014588|) = 0.003285$$
3.  **Resultado:**
    $$MADe = 1.483 \times 0.003285 = 0.004871$$

## 3. Análisis de Homogeneidad

Cálculos basados en el Anexo B de la norma ISO 13528:2022.

### 3.1 Desviación estándar intra-muestra ($s_w$)

$$s_w = \sqrt{\frac{\sum w_i^2}{2g}}$$
Donde $g=10$ (número de muestras).

1.  **Suma de cuadrados de rangos:**
    $$\sum w_i^2 = 0.007933^2 + 0.008594^2 + \dots + 0.007516^2 = 0.0005027$$
2.  **Resultado:**
    $$s_w = \sqrt{\frac{0.0005027}{20}} = 0.005013$$

### 3.2 Desviación estándar entre muestras ($s_s$)

1.  **Varianza de las medias de las muestras ($s_{\bar{x}}^2$):**
    $$s_{\bar{x}}^2 = \text{var}(2.015502, 2.011873, \dots) = 0.00000589$$
2.  **Componente de varianza entre muestras ($s_s^2$):**
    $$s_s^2 = \max(0, s_{\bar{x}}^2 - \frac{s_w^2}{2})$$
    $$s_s^2 = 0.00000589 - \frac{0.005013^2}{2} = -0.00000668 \rightarrow 0$$
3.  **Resultado:**
    $$s_s = 0$$

### 3.3 Evaluación del Criterio de Homogeneidad

**Criterio:** $s_s \leq 0.3 \times \sigma_{pt}$

Asumiendo $\sigma_{pt} = MADe = 0.004871$:
$$c = 0.3 \times 0.004871 = 0.001461$$

**Interpretación:**
Dado que $s_s (0) \leq c (0.001461)$, el lote de muestras cumple con el criterio de homogeneidad.

## 4. Algoritmo A (ISO 13528:2022, 9.4)

Procedimiento iterativo para obtener el valor asignado robusto ($x^*$) y la desviación estándar robusta ($s^*$).

### Paso Inicial
- $x^* = \text{mediana}(x_i) = 2.014588$
- $s^* = 1.483 \times \text{MAD} = 0.004871$

### Iteración 1
1.  **Límites de truncamiento ($\delta$):**
    $$\delta = 1.5 \times s^* = 1.5 \times 0.004871 = 0.007307$$
    $$L = x^* - \delta = 2.007281, \quad U = x^* + \delta = 2.021895$$
2.  **Valores transformados ($\phi_i$):**
    Como todos los valores de la muestra están dentro del rango $[L, U]$, no hay truncamiento ($\phi_i = x_i$).
3.  **Nuevos estimadores:**
    $$x^* = \text{media}(\phi_i) = 2.013843$$
    $$s^* = 1.134 \times \text{std\_dev}(\phi_i) = 1.134 \times 0.004161 = 0.004719$$

### Iteración 2
1.  **Nuevos límites:**
    $$\delta = 1.5 \times 0.004719 = 0.007079 \rightarrow [2.006764, 2.020922]$$
2.  **Convergencia:**
    Nuevamente, todos los valores originales caen dentro de los límites. Los valores de $x^*$ y $s^*$ se estabilizan.

**Valores Finales:**
- **Valor Asignado ($x^*$):** 2.013843
- **Desviación Estándar Robusta ($s^*$):** 0.004719

---
**Notas Técnicas:**
- Los cálculos siguen estrictamente las fórmulas de la norma **ISO 13528:2022**.
- El uso de $s_s = 0$ cuando el componente de varianza es negativo es una práctica recomendada por la norma para evitar valores imaginarios.
