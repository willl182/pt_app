# Fórmulas y Ejemplos de Puntajes de Desempeño

Este documento resume las fórmulas y criterios de evaluación para puntajes de desempeño en ensayos de aptitud, conforme a la **ISO 13528:2022** (secciones **§10.2 a §10.5**).

## 1. Fórmulas de Puntajes

### 1.1 Puntaje z (z-score)

$$z = \frac{x - x_{pt}}{\sigma_{pt}}$$

Referencia: ISO 13528:2022 §10.2.

### 1.2 Puntaje z' (z'-score)

$$z' = \frac{x - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}}$$

Referencia: ISO 13528:2022 §10.3.

### 1.3 Puntaje zeta ($\zeta$)

$$\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}}$$

Referencia: ISO 13528:2022 §10.4.

### 1.4 Número En (En-score)

$$E_n = \frac{x - x_{pt}}{\sqrt{U_x^2 + U_{xpt}^2}}$$

Referencia: ISO 13528:2022 §10.5.

---

## 2. Criterios de Evaluación

### 2.1 Evaluación para z, z' y zeta

| Criterio | Interpretación |
| :--- | :--- |
| $|z| \leq 2$ | Satisfactorio |
| $2 < |z| < 3$ | Cuestionable |
| $|z| \geq 3$ | No satisfactorio |

### 2.2 Evaluación para En

| Criterio | Interpretación |
| :--- | :--- |
| $|E_n| \leq 1$ | Satisfactorio |
| $|E_n| > 1$ | No satisfactorio |

---

## 3. Ejemplo Numérico Paso a Paso

Datos de un participante:

- Resultado ($x$): 10.5
- Valor asignado ($x_{pt}$): 10.0
- $\sigma_{pt}$: 0.5
- $u_x$: 0.2
- $u_{xpt}$: 0.1
- $U_x$: 0.4 (k = 2)
- $U_{xpt}$: 0.2 (k = 2)

**Paso 1. z-score**

$$z = \frac{10.5 - 10.0}{0.5} = 1.0$$

Evaluación: Satisfactorio.

**Paso 2. z'-score**

$$z' = \frac{10.5 - 10.0}{\sqrt{0.5^2 + 0.1^2}} = 0.981$$

Evaluación: Satisfactorio.

**Paso 3. zeta**

$$\zeta = \frac{10.5 - 10.0}{\sqrt{0.2^2 + 0.1^2}} = 2.236$$

Evaluación: Cuestionable.

**Paso 4. En**

$$E_n = \frac{10.5 - 10.0}{\sqrt{0.4^2 + 0.2^2}} = 1.118$$

Evaluación: No satisfactorio.

---

## 4. Notas de Aplicación

- Los puntajes z, z' y zeta se interpretan con los mismos criterios de desempeño.
- El número En utiliza incertidumbres expandidas; habitualmente se toma $k = 2$ para 95% de confianza.
- Todas las fórmulas siguen ISO 13528:2022 (§10.2–§10.5).
