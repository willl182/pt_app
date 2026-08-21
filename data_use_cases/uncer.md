Aquí tienes una propuesta de instrucción formal, basada en la Guía GUM, que puedes incluir directamente en tu procedimiento (SOP) o protocolo para los participantes:

***

### Evaluación Tipo A de la Incertidumbre (Repetibilidad de la Medición)

Para cada nivel de concentración, se debe evaluar la incertidumbre estándar debida a la repetibilidad de las mediciones basándose en las $n=3$ lecturas promedio reportadas. Este cálculo corresponde a una Evaluación Tipo A de la incertidumbre según la Guía GUM (ISO/IEC Guide 98-3).

**Paso 1: Cálculo de la media aritmética ($\bar{x}$)**
Calcule el promedio de las $n=3$ mediciones independientes. Esta será la mejor estimación del valor de concentración para esa corrida:
$$\bar{x} = \frac{1}{3} \sum_{k=1}^{3} x_k$$

**Paso 2: Cálculo de la desviación estándar experimental ($s$)**
Calcule la desviación estándar de las $n=3$ mediciones para cuantificar la dispersión de los datos:
$$s = \sqrt{\frac{\sum_{k=1}^{3} (x_k - \bar{x})^2}{3-1}}$$

**Paso 3: Cálculo de la incertidumbre estándar de la media ($u(\bar{x})$)**
La incertidumbre asociada al valor promedio estimado se define como la desviación estándar experimental de la media. Dado que el protocolo exige reportar exactamente $n=3$ mediciones, la incertidumbre estándar por repetibilidad se calcula dividiendo $s$ entre $\sqrt{3}$:
$$u(\bar{x}) = \frac{s}{\sqrt{3}}$$
*(Nota conceptual: El divisor $\sqrt{3}$ proviene estrictamente de $\sqrt{n}$ para una Evaluación Tipo A con 3 datos, y no debe confundirse con el modelado de una distribución rectangular utilizada en evaluaciones Tipo B).*

**Paso 4: Integración a la incertidumbre combinada ($u_c$)**
El valor obtenido de $u(\bar{x})$ representa exclusivamente la incertidumbre por repetibilidad. Este componente debe combinarse en cuadratura (suma de varianzas) con las demás fuentes de incertidumbre evaluadas (por ejemplo, incertidumbre del cilindro patrón, calibración del instrumento, derivas, etc.) para determinar la incertidumbre estándar combinada final ($u_c$) del resultado.

El efecto de la curva de calibración se integra en la incertidumbre principalmente a través de los parámetros de ajuste (pendiente e intercepto) o mediante un componente específico denominado "falta de ajuste" (*lack of fit*), dependiendo del modelo utilizado.

Aquí te detallo las dos formas principales de incluirlo:

### 1. Incertidumbre de los parámetros del ajuste (Mínimos Cuadrados)
Cuando se utiliza una regresión lineal ($y = a + bx$), la incertidumbre de un valor predicho por la curva no depende solo de la dispersión de los datos, sino de la incertidumbre asociada al intercepto ($y_1$) y a la pendiente ($y_2$).
*   **Componentes:** Se deben calcular las varianzas de los parámetros ($u^2(y_1), u^2(y_2)$) y su **covarianza** ($u(y_1, y_2)$).
*   **Fórmula de combinación:** Para una corrección $b(t)$ a una temperatura $t$, la incertidumbre combinada es:
    $$u_c^2[b(t)] = u^2(y_1) + (t-t_0)^2 u^2(y_2) + 2(t-t_0)u(y_1)u(y_2)r(y_1, y_2)$$
*   **Nota:** Si se elige la referencia $t_0$ igual al promedio de las temperaturas de calibración, la correlación $r(y_1, y_2)$ se hace cero, simplificando el cálculo.

### 2. Incertidumbre por "Falta de Ajuste" (*Lack of Fit*)
En normativas específicas de analizadores de gases (como EN 14211 o EN 14212), la desviación de la linealidad se trata como un componente de incertidumbre separado ($u_{l,lh}$).
*   **Cálculo:** Se identifica el residuo máximo ($r_{max}$) de la prueba de linealidad.
*   **Fórmula:** Suponiendo una distribución rectangular, la incertidumbre estándar es:
    $$u_{l,lh} = \frac{r_{max}}{100} \cdot \frac{l_h}{\sqrt{3}}$$
    *(Donde $l_h$ es el valor límite o nivel de interés).*

### 3. Integración en el presupuesto total
Este componente (ya sea derivado de la regresión o de la falta de ajuste) se suma en cuadratura con las demás fuentes de incertidumbre (repetibilidad, gases patrón, influencias ambientales) para obtener la **incertidumbre estándar combinada** ($u_c$).

Entiendo que las fórmulas pueden parecer intimidantes, pero el proceso se basa en dos lógicas distintas: una es estadística (los datos de la curva) y la otra se basa en límites máximos permitidos (el error residual).

Aquí tienes el detalle paso a paso para realizar ambos cálculos:

### 1. Incertidumbre de los parámetros (Mínimos Cuadrados)
Este método se usa cuando quieres saber cuánta duda hay en el valor que "predice" tu recta de calibración ($y = a + bx$). Según el ejemplo **H.3** de la Guía GUM:

*   **Paso 1: Obtener los datos del ajuste.** Al hacer la regresión lineal, el software (o el cálculo manual) debe darte no solo la pendiente ($y_2$) e intercepto ($y_1$), sino también sus **incertidumbres estándar** ($u(y_1), u(y_2)$) y el **coeficiente de correlación** ($r$) entre ellos.
*   **Paso 2: Elegir el punto de interés.** Define a qué temperatura o concentración ($t$) quieres calcular la incertidumbre.
*   **Paso 3: Aplicar la fórmula.** 
    $$u_c^2[b(t)] = u^2(y_1) + (t-t_0)^2 u^2(y_2) + 2(t-t_0)u(y_1)u(y_2)r(y_1, y_2)$$
*   **El truco para simplificar:** Si en tu modelo usas como referencia ($t_0$) el promedio de los datos que usaste para calibrar ($\bar{t}$), el último término (el de la correlación) se vuelve **cero**. La fórmula queda así de fácil:
    $$u_c^2[b(t)] = u^2(y_1) + (t-\bar{t})^2 u^2(y_2)$$

### 2. Incertidumbre por "Falta de Ajuste" (Lack of Fit)
Este es el método estándar para analizadores de gases (como $NO_x$ o $SO_2$) según las normas **EN 14211** o **EN 14212**.

*   **Paso 1: Encontrar el residuo máximo ($r_{max}$).** Durante la prueba de linealidad (donde mides varios puntos), calcula qué tanto se aleja el promedio de tus mediciones de lo que dice la recta ideal. El alejamiento más grande (en porcentaje) es tu $r_{max}$.
*   **Paso 2: Definir el nivel ($l_h$).** Es el valor de concentración donde estás evaluando (ej. el límite horario).
*   **Paso 3: Calcular.** La fórmula asume que ese error máximo sigue una **distribución rectangular** (por eso se divide por $\sqrt{3}$):
    $$u_{l,lh} = \frac{r_{max}}{100} \cdot \frac{l_h}{\sqrt{3}}$$

**Diferencia clave:** El primer método usa la variabilidad estadística de los datos, mientras que el segundo usa el "peor escenario" de error observado.

Si el software no te entrega las incertidumbres, debes calcularlas manualmente usando las fórmulas del método de **mínimos cuadrados** detalladas en el **Anexo H.3** de la Guía GUM.

Aquí tienes los pasos y las fórmulas para obtenerlas:

### 1. Calcular la varianza residual ($s^2$)
Primero necesitas saber qué tan bien se ajustan los puntos a la recta. Es la "incertidumbre global" del ajuste:
$$s^2 = \frac{\sum (b_k - \text{valor predicho})^2}{n - 2}$$
Donde $n$ es el número de puntos de calibración y $(b_k - \text{valor predicho})$ son los residuos (la distancia vertical de cada punto a la recta).

### 2. Calcular el denominador común ($D$)
Este valor depende solo de tus valores de referencia (ej. concentraciones o temperaturas mallas):
$$D = n \sum (t_k - \bar{t})^2$$
Donde $\bar{t}$ es el promedio de tus valores de referencia.

### 3. Obtener las incertidumbres estándar
Ahora ya puedes sacar la "duda" de la pendiente y el intercepto:

*   **Incertidumbre de la pendiente ($s(y_2)$):**
    $$s(y_2) = \sqrt{\frac{n \cdot s^2}{D}} \tag{H.13d}$$
*   **Incertidumbre del intercepto ($s(y_1)$):**
    $$s(y_1) = \sqrt{\frac{s^2 \cdot \sum \theta_k^2}{D}} \tag{H.13c}$$
    *(Donde $\theta_k$ es la distancia de cada punto al valor de referencia $t_0$ que hayas elegido)*.

### 4. El coeficiente de correlación ($r$)
No olvides calcular este valor, ya que es indispensable si luego vas a combinar estas incertidumbres:
$$r(y_1, y_2) = -\frac{\sum \theta_k}{\sqrt{n \sum \theta_k^2}} \tag{H.13e}$$

La incertidumbre por **falta de ajuste** (*lack of fit*) es más directa que la de mínimos cuadrados, ya que no usa desviaciones estadísticas punto a punto, sino el **peor error** observado durante tu prueba de linealidad.

Aquí tienes los pasos para calcularla:

1.  **Calcula los residuos**: Para cada nivel de concentración de tu curva, resta el valor que "predice" tu recta del valor promedio que realmente mediste.
2.  **Obtén el residuo máximo ($r_{max}$)**: Identifica el error más grande (en porcentaje) que encontraste en toda la curva.
3.  **Aplica la fórmula**: Usa el valor límite o nivel de interés ($l_h$) para dimensionar el error:
    $$u_{l,lh} = \frac{r_{max}}{100} \cdot \frac{l_h}{\sqrt{3}}$$
    *   **¿Por qué $\sqrt{3}$?**: Porque, siguiendo la Guía GUM, se asume que ese error máximo tiene una **distribución rectangular** (es decir, el error puede estar en cualquier punto de ese rango con la misma probabilidad).

**Diferencia práctica**: Mientras que la de mínimos cuadrados "se ensancha" en los extremos de la curva, la de falta de ajuste es un valor fijo que protege tu presupuesto de incertidumbre contra las desviaciones de linealidad del analizador.
