# Anexo de Cálculos - Entregable 09

Este anexo presenta los cálculos detallados realizados para la validación del sistema de ensayos de aptitud, siguiendo las normas **ISO 13528:2022** e **ISO 17043:2024**.

---

## Índice

1. [Ejemplo de Homogeneidad](#1-ejemplo-completo-de-homogeneidad)
2. [Ejemplo de Estabilidad](#2-ejemplo-completo-de-estabilidad)
3. [Ejemplo de Algoritmo A](#3-ejemplo-de-algoritmo-a)
4. [Ejemplo de Puntajes](#4-ejemplo-completo-de-puntajes)
5. [Clasificación Combinada](#5-clasificación-combinada-a1-a7)
6. [Datos de Participantes](#6-datos-de-participantes)
7. [Resumen de Fórmulas](#7-resumen-de-fórmulas)

---

## 1. Ejemplo Completo de Homogeneidad (CO 2-μmol/mol)

**Referencia normativa:** ISO 13528:2022, Sección 9.2

### 1.1 Datos de Entrada

Fuente: `homogeneity.csv`, 10 muestras × 2 réplicas

| Muestra | Réplica 1 | Réplica 2 | Media ($\bar{x}_i$) | Rango ($w_i$) |
|:--------|:----------|:----------|:--------------------|:--------------|
| 1 | 2.01153535 | 2.01946809 | 2.01550172 | 0.00793274 |
| 2 | 2.01617021 | 2.00757576 | 2.01187299 | 0.00859445 |
| 3 | 2.02053191 | 2.01427273 | 2.01740232 | 0.00625918 |
| 4 | 2.01063830 | 2.01957447 | 2.01510638 | 0.00893617 |
| 5 | 2.01776596 | 2.01616162 | 2.01696379 | 0.00160434 |
| 6 | 2.01147541 | 2.01797872 | 2.01472706 | 0.00650331 |
| 7 | 2.00785876 | 2.01486880 | 2.01136378 | 0.00701004 |
| 8 | 2.01449495 | 2.00776596 | 2.01113046 | 0.00672899 |
| 9 | 2.00751515 | 2.01468085 | 2.01109800 | 0.00716570 |
| 10 | 2.01702128 | 2.00950505 | 2.01326316 | 0.00751623 |

### 1.2 Cálculo de $s_w$ (Desviación Intra-muestra)

**Fórmula (ISO 13528:2022, §9.2.2):**

$$s_w = \sqrt{\frac{\sum_{i=1}^{g} w_i^2}{2g}}$$

**Cálculo:**

$$\sum w_i^2 = 0.00793274^2 + 0.00859445^2 + ... + 0.00751623^2 = 0.0005029$$

$$s_w = \sqrt{\frac{0.0005029}{20}} = 0.005015$$

### 1.3 Cálculo de $s_s$ (Desviación Entre-muestras)

**Fórmula (ISO 13528:2022, §9.2.2):**

$$s_s^2 = \max\left(0, s_{\bar{x}}^2 - \frac{s_w^2}{m}\right)$$

**Cálculo:**

$$s_{\bar{x}}^2 = \text{var}(\bar{x}_1, \bar{x}_2, ..., \bar{x}_{10}) = 0.00000586$$

$$s_s^2 = 0.00000586 - \frac{0.005015^2}{2} = 0.00000586 - 0.00001258 = -0.00000672$$

Como $s_s^2 < 0$:

$$s_s = \sqrt{\max(0, -0.00000672)} = 0$$

### 1.4 Evaluación del Criterio

**Criterio (ISO 13528:2022, §9.2.3):**

$$c = 0.3 \times \sigma_{pt}$$

Usando $\sigma_{pt} = MADe = 0.004871$:

$$c = 0.3 \times 0.004871 = 0.001461$$

**Evaluación:**

$$s_s (0) \leq c (0.001461) \implies \textbf{CUMPLE}$$

---

## 2. Ejemplo Completo de Estabilidad (CO 2-μmol/mol)

**Referencia normativa:** ISO 13528:2022, Sección 9.3

### 2.1 Datos de Entrada

Fuente: `stability.csv`

| Tiempo | Muestra | Réplica 1 | Réplica 2 | Media |
|:-------|:--------|:----------|:----------|:------|
| 0 | 1 | 2.01063830 | 2.01372340 | 2.01218085 |
| 0 | 2 | 2.01017021 | 2.01591489 | 2.01304255 |
| 1 | 3 | 2.00651515 | 2.00656566 | 2.00654040 |
| 1 | 4 | 2.00608696 | 2.00699457 | 2.00654076 |

### 2.2 Cálculo de la Diferencia

$$\bar{\bar{x}}_{hom} = 2.01261170$$ (media tiempo 0)

$$\bar{\bar{x}}_{stab} = 2.00654058$$ (media tiempo 1)

$$D = |\bar{\bar{x}}_{hom} - \bar{\bar{x}}_{stab}| = |2.01261170 - 2.00654058| = 0.00607112$$

### 2.3 Evaluación del Criterio

$$c = 0.3 \times \sigma_{pt} = 0.3 \times 0.004871 = 0.001461$$

$$D (0.00607112) > c (0.001461) \implies \textbf{NO CUMPLE criterio básico}$$

### 2.4 Incertidumbre por Estabilidad

Como $D > c$:

$$u_{stab} = \frac{D}{\sqrt{3}} = \frac{0.00607112}{\sqrt{3}} = 0.003505$$

---

## 3. Ejemplo de Algoritmo A

**Referencia normativa:** ISO 13528:2022, Anexo C

### 3.1 Datos de Entrada

Valores de participantes para CO 2-μmol/mol:

$$x = [10.1, 10.2, 9.9, 10.0, 10.3, 50.0]$$

### 3.2 Inicialización

$$x^* = \text{mediana}(x) = 10.05$$

$$s^* = 1.483 \times MAD = 1.483 \times 0.15 = 0.222$$

### 3.3 Iteración 1

**Residuos estandarizados:**

$$u_i = \frac{x_i - x^*}{1.5 \times s^*} = \frac{x_i - 10.05}{0.333}$$

| i | $x_i$ | $u_i$ | \|$u_i$\| | $w_i$ |
|:--|:------|:------|:----------|:------|
| 1 | 10.1 | 0.150 | 0.150 | 1.000 |
| 2 | 10.2 | 0.451 | 0.451 | 1.000 |
| 3 | 9.9 | -0.451 | 0.451 | 1.000 |
| 4 | 10.0 | -0.150 | 0.150 | 1.000 |
| 5 | 10.3 | 0.751 | 0.751 | 1.000 |
| 6 | 50.0 | 119.97 | 119.97 | 0.00007 |

**Pesos de Huber:**

$$w_i = \begin{cases} 1 & \text{si } |u_i| \leq 1 \\ 1/u_i^2 & \text{si } |u_i| > 1 \end{cases}$$

**Actualización:**

$$x^*_{new} = \frac{\sum w_i x_i}{\sum w_i} = \frac{1(10.1) + 1(10.2) + 1(9.9) + 1(10.0) + 1(10.3) + 0.00007(50.0)}{5.00007} = 10.10$$

### 3.4 Convergencia

Después de 2-3 iteraciones, el algoritmo converge a:

$$x^* = 10.10$$

$$s^* = 0.140$$

---

## 4. Ejemplo Completo de Puntajes (CO 2-μmol/mol)

**Referencia normativa:** ISO 13528:2022, Secciones 10.2-10.5

### 4.1 Datos de Entrada

Fuente: `summary_n4.csv`, grupo 1-10, participante 1

| Parámetro | Símbolo | Valor |
|:----------|:--------|:------|
| Valor asignado | $x_{pt}$ | 2.013671545 |
| Resultado participante | $x$ | 2.012150827 |
| Desviación estándar PT | $\sigma_{pt}$ | 0.000525431 |
| Incertidumbre valor asignado | $u_{xpt}$ | 0.001290351 |
| Incertidumbre participante | $u_x$ | 0.001137531 |
| Incertidumbre expandida asignado | $U_{xpt}$ | 0.002580702 |
| Incertidumbre expandida participante | $U_x$ | 0.002275062 |

### 4.2 Puntaje z (ISO 13528:2022, §10.2)

$$z = \frac{x - x_{pt}}{\sigma_{pt}} = \frac{2.012150827 - 2.013671545}{0.000525431} = \frac{-0.001520718}{0.000525431} = -2.894$$

**Evaluación:** Cuestionable ($2 < |z| < 3$)

### 4.3 Puntaje z' (ISO 13528:2022, §10.3)

$$z' = \frac{x - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}} = \frac{-0.001520718}{\sqrt{0.000525431^2 + 0.001290351^2}}$$

$$z' = \frac{-0.001520718}{\sqrt{0.000000276 + 0.000001665}} = \frac{-0.001520718}{0.001393} = -1.092$$

**Evaluación:** Satisfactorio ($|z'| \leq 2$)

### 4.4 Puntaje ζ (ISO 13528:2022, §10.4)

$$\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}} = \frac{-0.001520718}{\sqrt{0.001137531^2 + 0.001290351^2}}$$

$$\zeta = \frac{-0.001520718}{\sqrt{0.000001294 + 0.000001665}} = \frac{-0.001520718}{0.001720} = -0.884$$

**Evaluación:** Satisfactorio ($|\zeta| \leq 2$)

### 4.5 Puntaje En (ISO 13528:2022, §10.5)

$$E_n = \frac{x - x_{pt}}{\sqrt{U_x^2 + U_{xpt}^2}} = \frac{-0.001520718}{\sqrt{0.002275062^2 + 0.002580702^2}}$$

$$E_n = \frac{-0.001520718}{\sqrt{0.000005176 + 0.000006660}} = \frac{-0.001520718}{0.003440} = -0.442$$

**Evaluación:** Satisfactorio ($|E_n| \leq 1$)

---

## 5. Clasificación Combinada (a1-a7)

**Referencia normativa:** ISO 13528:2022, Sección 10.7

### 5.1 Datos del Ejemplo

| Parámetro | Valor |
|:----------|:------|
| $z$ | -2.894 |
| $E_n$ | -0.442 |
| $U_x$ | 0.002275 |
| $\sigma_{pt}$ | 0.000525 |

### 5.2 Evaluación

1. ¿MU ausente? **No** → Continuar
2. ¿$|z| \leq 2$? **No** ($|z| = 2.894$) → Evaluar siguiente nivel
3. ¿$|z| < 3$? **Sí** ($|z| = 2.894 < 3$) → Cuestionable
4. ¿$|E_n| \leq 1$? **Sí** ($|E_n| = 0.442 \leq 1$) → MU cubre la desviación

### 5.3 Clasificación

**Código: a4** - Cuestionable pero aceptable (la MU cubre el error)

---

## 6. Datos de Participantes

**Referencia:** `participants_data4.csv`

| Código | Analizador SO2 | Analizador CO | Analizador O3 | Analizador NO/NO2 |
|:-------|:---------------|:--------------|:--------------|:------------------|
| REFERENCIA | HORIBA APSA-370 | Teledyne T300 | Thermo 49i | HORIBA APSA-370 |
| PART1 | Modelo A | Modelo A | Modelo A | Modelo A |
| PART2 | Modelo B | Modelo B | Modelo B | Modelo B |
| PART3 | Modelo C | Modelo C | Modelo C | Modelo C |

$$n_{laboratorios} = 4$$ (REFERENCIA + 3 participantes)

Este conteo soporta la trazabilidad de participantes indicada en ISO 17043:2024.

---

## 7. Resumen de Fórmulas

### 7.1 Estadísticos Robustos

| Fórmula | Expresión |
|:--------|:----------|
| nIQR | $0.7413 \times (Q_3 - Q_1)$ |
| MADe | $1.483 \times \text{mediana}(\|x_i - \text{mediana}(x)\|)$ |

### 7.2 Homogeneidad

| Fórmula | Expresión |
|:--------|:----------|
| $s_w$ (m=2) | $\sqrt{\sum w_i^2 / 2g}$ |
| $s_s$ | $\sqrt{\max(0, s_{\bar{x}}^2 - s_w^2/m)}$ |
| Criterio | $s_s \leq 0.3 \times \sigma_{pt}$ |

### 7.3 Estabilidad

| Fórmula | Expresión |
|:--------|:----------|
| $D$ | $\|\bar{\bar{x}}_{hom} - \bar{\bar{x}}_{stab}\|$ |
| Criterio | $D \leq 0.3 \times \sigma_{pt}$ |
| $u_{stab}$ | $0$ si $D \leq c$; $D/\sqrt{3}$ si $D > c$ |

### 7.4 Puntajes

| Puntaje | Fórmula |
|:--------|:--------|
| z | $(x - x_{pt}) / \sigma_{pt}$ |
| z' | $(x - x_{pt}) / \sqrt{\sigma_{pt}^2 + u_{xpt}^2}$ |
| ζ | $(x - x_{pt}) / \sqrt{u_x^2 + u_{xpt}^2}$ |
| En | $(x - x_{pt}) / \sqrt{U_x^2 + U_{xpt}^2}$ |

### 7.5 Evaluación

| Puntaje | Satisfactorio | Cuestionable | No satisfactorio |
|:--------|:--------------|:-------------|:-----------------|
| z, z', ζ | $\|score\| \leq 2$ | $2 < \|score\| < 3$ | $\|score\| \geq 3$ |
| En | $\|E_n\| \leq 1$ | - | $\|E_n\| > 1$ |

---

## Referencias

- **ISO 13528:2022**: Statistical methods for use in proficiency testing by interlaboratory comparison.
- **ISO 17043:2024**: Conformity assessment — General requirements for proficiency testing.
- **ISO Guide 35:2017**: Reference materials — Guidance for characterization and assessment of homogeneity and stability.
- **Huber, P.J. (1981)**: Robust Statistics. Wiley.
