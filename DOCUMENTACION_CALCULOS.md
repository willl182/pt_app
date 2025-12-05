# Documentación de Cálculos Estadísticos

Este documento describe los cálculos estadísticos y algoritmos implementados en la aplicación de Ensayos de Aptitud (PT Data Analysis), detallando la lógica presente en `app.R` y `reports/report_template.Rmd`, así como las funciones auxiliares en `R/utils.R`.

Todos los métodos estadísticos están basados en la norma **ISO 13528:2022**.

## 1. Archivos Analizados

*   **`app.R`**: Aplicación Shiny monolítica que contiene la lógica principal de cálculo para homogeneidad, estabilidad y puntajes de desempeño.
*   **`reports/report_template.Rmd`**: Plantilla R Markdown para la generación de informes. Contiene versiones simplificadas o duplicadas de algunas funciones de cálculo para asegurar que el informe sea autocontenido.
*   **`R/utils.R`**: Archivo de utilidades que contiene implementaciones modulares de algoritmos robustos. *Nota: Actualmente `app.R` no utiliza este archivo directamente, sino que define sus propias funciones internas.*

---

## 2. Cálculos en `app.R`

El archivo `app.R` contiene funciones "helper" y lógica reactiva para realizar los análisis.

### 2.1. Funciones Auxiliares (Helpers)

Se definen al inicio del script o dentro del servidor:

*   **`calculate_niqr(x)`**: Calcula el Rango Intercuartílico normalizado.
    *   Fórmula: $nIQR = 0.7413 \times (Q_3 - Q_1)$
    *   Uso: Estimación robusta de la desviación estándar ($\sigma_{pt}$) para el consenso tipo 2b.

*   **`run_algorithm_a(values, ids, max_iter)`**: Implementa el Algoritmo A robusto (ISO 13528, Anexo C).
    *   Calcula la media robusta ($x^*$) y la desviación estándar robusta ($s^*$).
    *   Itera hasta que la convergencia es menor a $10^{-3}$ o se alcanza `max_iter`.
    *   Uso: Cálculo del valor asignado y $\sigma_{pt}$ para el consenso tipo 3.

### 2.2. Evaluación de Homogeneidad (`compute_homogeneity_metrics`)

Realiza un análisis de varianza (ANOVA) de un factor para evaluar la homogeneidad de las muestras.

*   **Entradas**: Datos de homogeneidad (`value`, `level`, `replicate`).
*   **Cálculos**:
    *   **Medias y Varianzas**: Calcula la media general ($x_{pt}$), varianza de medias ($s_{\bar{x}}^2$), y varianza dentro de las muestras ($s_w^2$).
    *   **Varianza entre muestras ($s_s^2$)**: $s_s^2 = s_{\bar{x}}^2 - (s_w^2 / m)$, donde $m$ es el número de réplicas. Si el resultado es negativo, $s_s = 0$.
    *   **$\sigma_{pt}$ (Desviación estándar para aptitud)**: Se estima usando MADe (Median Absolute Deviation escalada): $\sigma_{pt} = 1.483 \times \text{mediana}(|x_i - \text{mediana}(x)|)$.
    *   **Criterio de Aceptación ($c$)**: $c = 0.3 \times \sigma_{pt}$.
    *   **Criterio Expandido ($c'_{crit}$)**: Se calcula si no se cumple el criterio simple, considerando la incertidumbre del método de ensayo ($s_w$).
*   **Decisión**:
    *   Si $s_s \le c$: Cumple (Homogéneo).
    *   Si $s_s > c$ pero $s_s \le c'_{crit}$: Cumple criterio expandido.
    *   De lo contrario: No cumple.

### 2.3. Evaluación de Estabilidad (`compute_stability_metrics`)

Compara los resultados de estabilidad con los de homogeneidad.

*   **Entradas**: Datos de estabilidad y resultados previos de homogeneidad.
*   **Cálculos**:
    *   Calcula la media general de estabilidad ($y_2$).
    *   Recupera la media general de homogeneidad ($y_1$).
    *   **Diferencia Absoluta**: $|y_1 - y_2|$.
    *   **Criterio de Aceptación**: Se usa el mismo valor $0.3 \times \sigma_{pt}$ calculado en homogeneidad.
*   **Decisión**:
    *   Si $|y_1 - y_2| \le 0.3 \sigma_{pt}$: Estable.
    *   Si no, advertencia de posible inestabilidad.
*   **Prueba t (t-test)**: Adicionalmente, ejecuta una prueba t de dos muestras (`t.test`) entre los datos brutos de homogeneidad y estabilidad para verificar diferencias estadísticamente significativas ($p < 0.05$).

### 2.4. Puntajes de Desempeño (`compute_scores_metrics` y variantes)

Calcula los puntajes z, z', zeta y En para cada participante.

*   **Entradas**: Valor asignado ($x_{pt}$), desviación estándar para aptitud ($\sigma_{pt}$), incertidumbre del valor asignado ($u(x_{pt})$), resultado del participante ($x_i$), incertidumbre del participante ($u(x_i)$) y factor de cobertura ($k$, usualmente 2).
*   **Fórmulas**:
    *   **Puntaje z**: $z = \frac{x_i - x_{pt}}{\sigma_{pt}}$
    *   **Puntaje z'**: $z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}}$
    *   **Puntaje zeta ($\zeta$)**: $\zeta = \frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}}$
    *   **Puntaje En**: $E_n = \frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}}$, donde $U = k \cdot u$.

### 2.5. Métodos de Consenso

La aplicación permite calcular el valor asignado de tres formas (además de usar un valor de referencia externo):
1.  **Consenso MADe (2a)**: $x_{pt} = \text{mediana}$, $\sigma_{pt} = \text{MADe}$.
2.  **Consenso nIQR (2b)**: $x_{pt} = \text{mediana}$, $\sigma_{pt} = \text{nIQR}$.
3.  **Algoritmo A (3)**: $x_{pt} = x^*$, $\sigma_{pt} = s^*$ (obtenidos iterativamente).

---

## 3. Cálculos en `reports/report_template.Rmd`

Este archivo genera el informe final y contiene su propia lógica para asegurar la reproducibilidad independiente de la sesión interactiva de Shiny.

### 3.1. Funciones Duplicadas
Para que el reporte sea autocontenido, redefine:
*   `calculate_niqr`
*   `run_algorithm_a`
*   `compute_homogeneity` (versión simplificada de la de `app.R`).

### 3.2. Prueba de Grubbs
El reporte ejecuta explícitamente la **Prueba de Grubbs** (`outliers::grubbs.test`) para detectar valores atípicos en los datos de los participantes, reportando el valor p y el participante atípico si $p < 0.05$. Esta lógica es específica del reporte y no es prominente en la interfaz principal de `app.R` (aunque `app.R` muestra una tabla resumen).

### 3.3. Recálculo de Puntajes
El reporte no hereda simplemente los puntajes calculados en la UI, sino que los recalcula usando la función interna `calculate_method_scores_df` basada en los parámetros seleccionados por el usuario (`metric`, `method`, `k_factor`) al momento de generar la descarga. Esto asegura que el reporte refleje fielmente la configuración elegida en el momento de la descarga.

---

## 4. Funciones Rastreadas en `R/utils.R`

Este archivo contiene implementaciones modulares destinadas a la versión refactorizada (`app_gem.R`) o para uso como librería.

*   **`algorithm_A(x, max_iter)`**: Implementación limpia del Algoritmo A.
*   **`mad_e_manual(x)`**: Cálculo manual de MADe ($1.4826 \times \text{MAD}$).
*   **`nIQR_manual(x)`**: Cálculo manual de nIQR.

**Nota Importante**: `app.R` no hace `source("R/utils.R")`. `app.R` tiene sus propias definiciones internas (`run_algorithm_a`, `calculate_niqr`) que son funcionalmente equivalentes pero técnicamente distintas (código duplicado). Si se realizan cambios en la lógica estadística en `R/utils.R`, **no** se reflejarán automáticamente en `app.R` a menos que se actualice también ese archivo.
