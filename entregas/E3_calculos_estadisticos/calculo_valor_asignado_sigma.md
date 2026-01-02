# Entregable 3.2: Valor Asignado ($x_{pt}$) y Desviación ($\sigma_{pt}$)

Este documento describe los métodos implementados para determinar el valor asignado y la desviación estándar para la evaluación de la aptitud, pilares fundamentales de la evaluación del desempeño.

## 1. Métodos de Determinación

El aplicativo permite seleccionar entre cuatro enfoques según la disponibilidad de datos y objetivos:

| Método | $x_{pt}$ (Valor Asignado) | $\sigma_{pt}$ (Desviación EA) | Aplicación |
|--------|---------------------------|------------------------------|------------|
| **1. Referencia** | Valor del Lab. Referencia ($x_{ref}$) | Incertidumbre/SD Referencia | Cuando existe un valor de alta pureza metrológica. |
| **2a. MADe** | Mediana ($med$) | $1.4826 \cdot med(|x_i - med|)$ | Consenso robusto con pocos datos o alta contaminación. |
| **2b. nIQR** | Mediana ($med$) | $0.7413 \cdot (Q_3 - Q_1)$ | Consenso robusto basado en cuartiles. |
| **3. Algoritmo A** | Media Robusta ($x^*$) | Desviación Robusta ($s^*$) | Consenso basado en la norma ISO 13528, Anexo C. |

## 2. Implementación del Algoritmo A (ISO 13528)

El Algoritmo A se ejecuta iterativamente hasta que los valores de $x^*$ y $s^*$ convergen (cambio $< 10^{-3}$).

### 2.1. Proceso de Cálculo
1. **Inicialización:** $x^* = \text{mediana}(x)$, $s^* = 1.4826 \cdot \text{mediana}(|x_i - x^*|)$.
2. **Actualización de Datos ($x_i^*$):**
   - Si $x_i < x^* - 1.5 s^*$, entonces $x_i^* = x^* - 1.5 s^*$
   - Si $x_i > x^* + 1.5 s^*$, entonces $x_i^* = x^* + 1.5 s^*$
   - De lo contrario, $x_i^* = x_i$
3. **Nuevos Estimadores:**
   - $x^* = \frac{\sum x_i^*}{n}$
   - $s^* = 1.134 \cdot \sqrt{\frac{\sum (x_i^* - x^*)^2}{n-1}}$

## 3. Incertidumbre del Valor Asignado ($u_{xpt}$)

Para los métodos de consenso, la incertidumbre se estima como:
$$u_{xpt} = 1.25 \cdot \frac{\sigma_{pt}}{\sqrt{n}}$$
Donde $n$ es el número de laboratorios participantes. Esta incertidumbre es crucial para el cálculo del puntaje $z'$ y $\zeta$.
