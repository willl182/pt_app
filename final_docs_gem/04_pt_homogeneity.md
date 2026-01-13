# Evaluación de Homogeneidad y Estabilidad

## 1. Descripción General

Este módulo evalúa si los ítems del ensayo de aptitud (muestras) son suficientemente homogéneos y estables para ser utilizados en el esquema, siguiendo las directrices de la norma **ISO 13528:2022**.

**Archivo:** `ptcalc/R/pt_homogeneity.R`

---

## 2. Análisis de Homogeneidad (ANOVA)

Utilizamos un Análisis de Varianza (ANOVA) de un factor para separar la variación total en dos componentes: "entre muestras" ($s_s$) y "dentro de la muestra" ($s_w$).

### 2.1 Construcción de la Tabla ANOVA

Dados $g$ ítems medidos en $m$ réplicas (típicamente $m=2$).

| Fuente de Variación | Grados de Libertad (GL) | Suma de Cuadrados (SS) | Cuadrado Medio (MS) | Esperanza |
|:---|:---|:---|:---|:---|
| **Entre Muestras** | $g - 1$ | $SS_{B} = m \sum (\bar{x}_i - \bar{\bar{x}})^2$ | $MS_{B} = SS_{B} / (g-1)$ | $s_w^2 + m \cdot s_s^2$ |
| **Dentro de Muestras** | $g(m - 1)$ | $SS_{W} = \sum \sum (x_{ij} - \bar{x}_i)^2$ | $MS_{W} = SS_{W} / (g(m-1))$ | $s_w^2$ |
| **Total** | $gm - 1$ | | | |

### 2.2 Derivación de Componentes de Varianza

1.  **Desviación estándar dentro de la muestra ($s_w$):**
    $$s_w = \sqrt{MS_{W}}$$
    *Simplificado para m=2:* $s_w = \sqrt{\sum w_t^2 / (2g)}$ donde $w_t$ es el rango de réplicas para el ítem $t$.

2.  **Desviación estándar entre muestras ($s_s$):**
    La estimación se deriva restando la contribución de la varianza intra-muestra del cuadrado medio entre muestras.
    $$s_s = \sqrt{\max\left(0, \frac{MS_{B} - MS_{W}}{m}\right)}$$
    *Nota: Si $MS_{B} < MS_{W}$, la estimación se establece en 0.*

---

## 3. Criterios de Evaluación ISO 13528

Para aprobar la homogeneidad, la varianza entre muestras ($s_s$) debe ser pequeña en relación con la desviación estándar para la evaluación de la aptitud ($\sigma_{pt}$).

### 3.1 Fórmulas de Criterios

1.  **Criterio Estándar ($c$):**
    $$c = 0.3 \times \sigma_{pt}$$
    Si $s_s \le c$, los ítems se consideran homogéneos.

2.  **Criterio Expandido ($c'$ o `c_expanded`):**
    Se utiliza cuando $s_s > c$ pero la varianza del método de medición ($s_w$) es alta, lo que dificulta distinguir las diferencias de la muestra del ruido del método.
    $$c' = \sqrt{c^2 + 1.88 \cdot s_w^2}$$
    *Nota: El factor 1.88 varía según $g, m$, pero a menudo se aproxima o calcula usando tablas $\chi^2$.*

### 3.2 Árbol de Decisión

```mermaid
graph TD
    A[Inicio Evaluación] --> B{s_s <= c?}
    B -- Sí --> C[PASA: Homogéneo]
    B -- No --> D{s_s <= c_expanded?}
    D -- Sí --> E[PASA: Homogéneo (condicional)]
    D -- No --> F[FALLA: No Homogéneo]

    style C fill:#d4edda,stroke:#28a745
    style E fill:#fff3cd,stroke:#ffc107
    style F fill:#f8d7da,stroke:#dc3545
```

### 3.3 Ejemplo Numérico
*   $\sigma_{pt} = 0.1$
*   $s_s = 0.04$
*   $s_w = 0.02$

1.  Calcular $c$: $0.3 \times 0.1 = 0.03$.
2.  Verificar: ¿Es $0.04 \le 0.03$? **No.**
3.  Calcular $c'$: $\sqrt{0.03^2 + 1.88(0.02^2)} = \sqrt{0.0009 + 0.000752} \approx 0.0406$.
4.  Verificar: ¿Es $0.04 \le 0.0406$? **Sí.**
5.  **Resultado:** PASA (usando criterio expandido).

---

## 4. Evaluación de Estabilidad

La estabilidad verifica si las muestras cambiaron durante el período del ensayo de aptitud.

### 4.1 Verificación de Estabilidad
Comparamos la media general de las muestras de homogeneidad ($\bar{y}_{hom}$) con la media de las muestras de estabilidad ($\bar{y}_{stab}$).

**Diferencia:** $D = | \bar{y}_{hom} - \bar{y}_{stab} |$

**Criterio:** $D \le 0.3 \times \sigma_{pt} + 2 u(\bar{y}_{hom})$

### 4.2 Cálculos de Incertidumbre
La aplicación calcula las incertidumbres asociadas con la caracterización del material.

*   **Incertidumbre de Homogeneidad ($u_{hom}$):**
    $$u_{hom} = s_s$$

*   **Incertidumbre de Estabilidad ($u_{stab}$):**
    $$u_{stab} = \begin{cases}
    0 & \text{si } D \leq c \\
    \frac{D}{\sqrt{3}} & \text{si } D > c
    \end{cases}$$

*   **Incertidumbre Combinada ($u_{char}$):**
    Contribuye a la incertidumbre del valor asignado ($u_{xpt}$).
    $$u_{xpt\_def} = \sqrt{u_{xpt}^2 + u_{hom}^2 + u_{stab}^2}$$

---

## 5. Referencias

- **ISO 13528:2022** Sección 7.4 (Homogeneidad)
- **ISO 13528:2022** Sección 7.5 (Estabilidad)
- **ISO 13528:2022** Sección 9.5 (Incertidumbres)
