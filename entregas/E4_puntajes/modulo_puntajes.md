# Entregable 4.1: Módulo de Cálculo de Puntajes (ISO 13528)

Este documento describe la implementación de los indicadores de desempeño utilizados para evaluar la aptitud de los laboratorios participantes.

## 1. Indicadores de Desempeño

El aplicativo implementa cuatro tipos de puntajes estandarizados, cada uno con un propósito específico en la evaluación metrológica:

### 1.1. Puntaje z (z-score)
Evalúa el desempeño basándose únicamente en el valor asignado y la desviación estándar para la aptitud.
- **Fórmula:** $z = \frac{x_i - x_{pt}}{\sigma_{pt}}$
- **Satisfactorio:** $|z| \le 2.0$
- **Cuestionable:** $2.0 < |z| < 3.0$
- **Insatisfactorio:** $|z| \ge 3.0$

### 1.2. Puntaje z' (z'-score)
Se utiliza cuando la incertidumbre del valor asignado ($u_{xpt}$) no es despreciable ($u_{xpt} > 0.3 \sigma_{pt}$).
- **Fórmula:** $z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}}$
- **Evaluación:** Iguales criterios que el puntaje z.

### 1.3. Puntaje Zeta ($\zeta$)
Evalúa si el resultado del participante es coherente con su incertidumbre estándar declarada ($u_i$).
- **Fórmula:** $\zeta = \frac{x_i - x_{pt}}{\sqrt{u_i^2 + u_{xpt}^2}}$
- **Evaluación:** Iguales criterios que el puntaje z.

### 1.4. Puntaje $E_n$ (En-score)
Evalúa el desempeño considerando las incertidumbres expandidas ($U$) de ambos, el participante y el valor asignado.
- **Fórmula:** $E_n = \frac{x_i - x_{pt}}{\sqrt{U_i^2 + U_{xpt}^2}}$
- **Satisfactorio:** $|E_n| \le 1.0$
- **Insatisfactorio:** $|E_n| > 1.0$

## 2. Lógica de Implementación

La función `compute_scores_metrics` en `app.R` automatiza estos cálculos:
- Filtra los datos por analito, nivel y número de laboratorio.
- Identifica el valor de referencia (si aplica) o usa el consenso calculado.
- Calcula las incertidumbres estándar y expandidas (usando el factor de cobertura $k$).
- Asigna etiquetas cualitativas automáticas basándose en los criterios de la norma.
