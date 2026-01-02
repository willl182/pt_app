# Entregable 3.1: Homogeneidad y Estabilidad

Este documento detalla la lógica estadística implementada para la evaluación de la homogeneidad y estabilidad de los ítems de ensayo de aptitud, siguiendo los lineamientos de la **ISO 13528:2022**.

## 1. Evaluación de Homogeneidad

El aplicativo utiliza un análisis de varianza (ANOVA) simple para evaluar si existe una variabilidad significativa entre los ítems distribuidos.

### 1.1. Estadísticos Básicos
- **$s_x$ (Desviación estándar de las medias de los ítems):** Variabilidad entre los promedios de cada ítem evaluado.
- **$s_w$ (Desviación estándar intra-muestra):** Variabilidad entre las réplicas del mismo ítem. Se calcula como:
  $$s_w = \sqrt{\frac{\sum w_i^2}{2g}}$$
  Donde $w_i$ es el rango de las réplicas para el ítem $i$, y $g$ es el número de ítems.

### 1.2. Varianza entre muestras ($s_s$)
Se calcula descontando la variabilidad analítica ($s_w$) de la variabilidad observada entre medias ($s_x$):
$$s_s = \sqrt{\max(0, s_x^2 - \frac{s_w^2}{m})}$$
Donde $m$ es el número de réplicas por ítem.

### 1.3. Criterios de Aceptación
1. **Criterio Simple:** $s_s \le 0.3 \sigma_{pt}$
2. **Criterio Expandido:** Si el anterior no se cumple, se considera la incertidumbre del método:
   $$s_s \le \sqrt{1.88 \cdot (0.3 \sigma_{pt})^2 + 1.01 \cdot s_w^2}$$

---

## 2. Evaluación de Estabilidad

La estabilidad se evalúa comparando los resultados obtenidos al final del ensayo con los resultados iniciales de homogeneidad.

### 2.1. Cálculo de la Diferencia
Se calcula la diferencia absoluta entre la media de los datos de estabilidad ($\bar{y}_2$) y la media de los datos de homogeneidad ($\bar{y}_1$):
$$| \bar{y}_1 - \bar{y}_2 |$$

### 2.2. Criterio de Estabilidad
El ítem se considera estable si la diferencia es menor o igual al 30% de la desviación estándar para la evaluación de la aptitud:
$$| \bar{y}_1 - \bar{y}_2 | \le 0.3 \sigma_{pt}$$

También se incluye un **Criterio Expandido** que considera las incertidumbres de las medias evaluadas:
$$| \bar{y}_1 - \bar{y}_2 | \le 0.3 \sigma_{pt} + 2 \sqrt{u(\bar{y}_1)^2 + u(\bar{y}_2)^2}$$
