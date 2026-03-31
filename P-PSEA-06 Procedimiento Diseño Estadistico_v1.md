# P-PSEA-06 Procedimiento de Diseno Estadistico

## 1. INFORMACION GENERAL DEL PROCEDIMIENTO

### 1.1 Objetivo

Establecer el procedimiento estadistico aplicable al diseno, calculo, validacion y evaluacion de esquemas de ensayos de aptitud desarrollados en CALAIRE, de conformidad con la norma ISO 13528:2022 y con los requisitos generales de ISO/IEC 17043:2024. Este procedimiento define la determinacion del valor asignado, la estimacion de la desviacion estandar para evaluacion de aptitud, el tratamiento de resultados atipicos mediante metodos robustos, la integracion de los estudios de homogeneidad y estabilidad, y la interpretacion de los puntajes de desempeno.

### 1.2 Alcance

Este procedimiento aplica a los ejercicios de ensayos de aptitud en los que el valor asignado se establece a partir de resultados de participantes, de laboratorios de referencia o de modelos combinados de caracterizacion. Su aplicacion comprende la etapa de diseno estadistico, la verificacion de suficiencia de datos, la estimacion de parametros robustos, el calculo de incertidumbre asociada al valor asignado y la evaluacion del desempeno de los laboratorios participantes.

### 1.3 Definiciones

- $x_{pt}$: valor asignado al mensurando objeto del ensayo de aptitud.
- $\sigma_{pt}$: desviacion estandar para evaluacion de aptitud.
- $u(x_{pt})$: incertidumbre estandar asociada al valor asignado por la via estadistica.
- $u(x_{pt},def)$: incertidumbre estandar definitiva del valor asignado, una vez integradas las contribuciones por homogeneidad y estabilidad.
- $u_{hom}$: contribucion por homogeneidad.
- $u_{stab}$: contribucion por estabilidad.
- $p$: numero de participantes validos.
- $x^*$ y $s^*$: estimadores robustos de ubicacion y dispersion obtenidos mediante Algoritmo A.

### 1.4 Documentos de referencia

Este procedimiento se fundamenta en ISO 13528:2022, *Statistical methods for use in proficiency testing by interlaboratory comparison*, especialmente en sus secciones sobre metodos robustos, evaluacion del valor asignado, incertidumbre asociada, homogeneidad, estabilidad y calculo de puntajes de desempeno. De manera complementaria, se aplica ISO/IEC 17043:2024 para los requisitos generales de operacion y aseguramiento tecnico de los esquemas de ensayos de aptitud. La implementacion computacional institucional se realiza mediante el paquete R `ptcalc`, validado frente a hojas de calculo de referencia basadas en ISO 13528:2022, Anexo C.

### 1.5 Condiciones generales

La aplicacion del presente procedimiento requiere que los resultados utilizados para el diseno estadistico correspondan al mismo mensurando, empleen unidades consistentes y cuenten con trazabilidad documental suficiente para su analisis. Toda ejecucion del procedimiento debe garantizar identificacion univoca de analitos, niveles de concentracion, participantes, items y replicados. La informacion procesada debe conservar integridad metrologica, trazabilidad de la fuente de datos y control de version del metodo de calculo aplicado.

## 2. INFORMACION ESPECIFICA DEL PROCEDIMIENTO

### 2.1 Roles y responsabilidades

| Cargo | Responsabilidad |
| --- | --- |
| Estadistico / Experto tecnico | Disenar el modelo estadistico del esquema, seleccionar los estimadores aplicables, calcular el valor asignado, la desviacion estandar para evaluacion y revisar la coherencia tecnica de los resultados. |
| Coordinador EA | Aprobar el diseno estadistico, verificar la conformidad con ISO 13528:2022 e ISO/IEC 17043:2024, y autorizar la emision de resultados a participantes. |
| Ingeniero Operativo | Garantizar las condiciones tecnicas de preparacion, manejo y seguimiento de los items del ensayo de aptitud, asi como la disponibilidad y consistencia de los datos de entrada. |
| Profesional de Calidad | Controlar la documentacion aplicable, asegurar la trazabilidad de registros, verificar la vigencia del procedimiento y conservar evidencia de revision y aprobacion. |

### 2.2 Desarrollo del diseno estadistico

#### 2.2.1 Definicion de los objetivos

Antes de definir el modelo estadistico del esquema, se debe establecer el objetivo tecnico del ensayo de aptitud y la finalidad de la evaluacion de desempeno. Los objetivos del diseno podran comprender los siguientes propositos:

- Evaluar el desempeno de los laboratorios.
- Comparar metodos o equipos de medicion.
- Validar la precision y trazabilidad de resultados.
- Determinar sesgos o tendencias sistematicas.

#### 2.2.2 Seleccion del tipo de datos y numero de participantes

La definicion del tipo de datos y del numero de participantes debe realizarse antes de seleccionar el estimador del valor asignado. Para el presente procedimiento se adoptan las siguientes condiciones:

- Los datos del esquema deben ser cuantitativos y expresarse en unidades de concentracion, tales como nmol/mol, umol/mol, ppb o ppm, segun corresponda al mensurando.
- La distribucion esperada de resultados debe ser aproximadamente normal; cuando exista asimetria significativa podra considerarse transformacion logaritmica o un tratamiento robusto equivalente, sujeto a justificacion tecnica.
- El numero minimo de participantes recomendado para establecer un consenso robusto es de 12.
- Si $p \ge 12$, el valor asignado por consenso debera determinarse preferentemente mediante Algoritmo A.
- Si $p < 12$, el valor asignado por consenso podra determinarse mediante la mediana de los resultados validos.

#### 2.2.3 Preparacion y depuracion de datos

Antes de cualquier calculo, se consolidaran los resultados reportados por los participantes y se verificara la consistencia de identificadores, unidades, analitos, niveles de concentracion y estructura de replicados. Los valores no finitos, faltantes o manifiestamente invalidos desde el punto de vista metrologico no seran considerados en el calculo de estadisticos robustos. En la implementacion institucional, los valores `NA`, `Inf` y `-Inf` se excluyen antes de iniciar la estimacion. Para la aplicacion del Algoritmo A, debera verificarse que el conjunto resultante contenga al menos tres observaciones validas, es decir, $p \ge 3$.

#### 2.2.4 Seleccion del metodo estadistico

La seleccion del metodo para determinar el valor asignado y la desviacion estandar de evaluacion se realizara de acuerdo con la naturaleza del esquema, la disponibilidad de material de referencia o resultados de referencia, el numero de participantes validos y el comportamiento estadistico observado en los datos. Cuando exista un valor trazable proporcionado por un laboratorio de referencia o por un material suficientemente caracterizado, este podra utilizarse como base del valor asignado. Cuando no exista un valor de referencia externo y se disponga de una base suficiente de resultados, se utilizaran metodos robustos para obtener un valor de consenso resistente a valores atipicos. Cuando el esquema requiera un procedimiento iterativo conforme al Anexo C de ISO 13528:2022, se empleara el Algoritmo A como metodo principal para estimar $x^*$ y $s^*$.

#### 2.2.5 Estimadores robustos de dispersion

##### 2.2.5.1 MADe

Cuando se requiera un estimador robusto simple de dispersion, se utilizara la desviacion absoluta mediana escalada, MADe, definida por la expresion:

$$
s^* = 1.483 \times \operatorname{mediana}\left(\left|x_i - x^*\right|\right)
$$

donde $x^*$ corresponde a la mediana de los resultados validos. El factor de escalado institucional adoptado es 1.483, en concordancia con la implementacion R validada. No se utilizara el valor 1.4826 en la documentacion operativa del presente procedimiento.

##### 2.2.5.2 nIQR

Como alternativa robusta de dispersion podra emplearse el rango intercuartil normalizado, definido por:

$$
\operatorname{nIQR} = 0.7413 \times (Q_3 - Q_1)
$$

Este estimador es util cuando se requiere una medida robusta basada en cuartiles y cuando conviene contrastar el comportamiento de MADe frente a distribuciones no estrictamente normales.

#### 2.2.6 Algoritmo A para estimacion robusta de ubicacion y dispersion

##### 2.2.6.1 Descripcion general

El Algoritmo A constituye el procedimiento robusto iterativo de referencia para obtener un valor asignado de consenso y una desviacion estandar robusta de evaluacion cuando la distribucion de resultados puede estar afectada por valores atipicos. El metodo opera mediante winsorizacion iterativa, restringiendo los valores extremos a limites calculados a partir de la dispersion robusta de la iteracion vigente.

##### 2.2.6.2 Inicializacion

La inicializacion del algoritmo se realizara calculando en primer termino la mediana de los resultados validos:

$$
x^*_0 = \operatorname{mediana}(x_i)
$$

La estimacion inicial de dispersion se obtendra mediante MADe:

$$
s^*_0 = 1.483 \times \operatorname{mediana}\left(\left|x_i - x^*_0\right|\right)
$$

Si la dispersion inicial no es finita o es practicamente nula, se utilizara la desviacion estandar clasica como mecanismo de respaldo. Si la dispersion resultante continua siendo nula o no finita, se concluira que el conjunto de datos no presenta variabilidad suficiente para una aplicacion informativa del algoritmo.

##### 2.2.6.3 Paso iterativo de winsorizacion

En cada iteracion $k$, se calculara el limite de winsorizacion $\delta_k$ mediante:

$$
\delta_k = 1.5 \times s^*_k
$$

Con base en ese limite, cada observacion se ajustara conforme a la regla:

$$
x_{i,k}^* =
\begin{cases}
x_k^* - \delta_k & \text{si } x_i < x_k^* - \delta_k \\
x_i & \text{si } x_k^* - \delta_k \le x_i \le x_k^* + \delta_k \\
x_k^* + \delta_k & \text{si } x_i > x_k^* + \delta_k
\end{cases}
$$

La actualizacion de la ubicacion robusta se efectuara mediante la media aritmetica de los valores winsorizados:

$$
x_{k+1}^* = \frac{1}{p}\sum_{i=1}^{p} x_{i,k}^*
$$

La actualizacion de la dispersion robusta se efectuara mediante:

$$
s_{k+1}^* = 1.134 \times \sqrt{\frac{1}{p-1}\sum_{i=1}^{p}\left(x_{i,k}^* - x_{k+1}^*\right)^2}
$$

El factor 1.134 es obligatorio dentro de este procedimiento y corrige el sesgo introducido por la winsorizacion al truncar la distribucion de resultados.

##### 2.2.6.4 Criterio de convergencia

La convergencia se declarara cuando el cambio absoluto maximo entre iteraciones consecutivas para $x^*$ y $s^*$ sea menor que $1 \times 10^{-4}$, de acuerdo con:

$$
\max\left(\left|\Delta x^*\right|,\left|\Delta s^*\right|\right) < 1 \times 10^{-4}
$$

El proceso iterativo tendra un maximo de 50 iteraciones. Si dicho limite se alcanza sin satisfacer el criterio anterior, el resultado debera reportarse como no convergente y quedara sujeto a revision tecnica. Aunque la funcion base `run_algorithm_a()` admite una tolerancia por defecto de $1 \times 10^{-6}$, para efectos del presente procedimiento operativo se adopta una tolerancia institucional de $1 \times 10^{-4}$.

##### 2.2.6.5 Salidas del algoritmo

Una vez alcanzada la convergencia, el valor asignado se establecera como $x_{pt} = x^*$ y la desviacion estandar para evaluacion de aptitud se establecera como $\sigma_{pt} = s^*$, salvo que el diseno del esquema defina una $\sigma_{pt}$ objetivo por otra via tecnica o normativa. Debera conservarse el registro del numero de iteraciones ejecutadas, del numero final de observaciones winsorizadas y de los limites de winsorizacion aplicados.

#### 2.2.7 Determinacion del valor asignado

El valor asignado podra provenir de una fuente de referencia externa o de consenso estadistico. Cuando se utilice un laboratorio de referencia, el valor asignado correspondera al valor trazable establecido conforme al modelo metrologico aplicable. Cuando se utilice consenso de participantes, el valor asignado podra definirse mediante mediana robusta o mediante el estimador $x^*$ del Algoritmo A. La seleccion final debera justificarse en el expediente tecnico del esquema, indicando el metodo empleado, la base de datos utilizada y el control de coherencia realizado frente a posibles valores extremos o sesgos de grupo.

#### 2.2.8 Desviacion estandar para evaluacion de aptitud

La desviacion estandar para evaluacion de aptitud, $\sigma_{pt}$, podra derivarse de un modelo prescrito por el esquema o estimarse a partir de los resultados de participantes, siempre que exista sustento tecnico para ello. Cuando se estime a partir de datos observados, podran emplearse MADe, nIQR o el estimador $s^*$ del Algoritmo A, segun corresponda al enfoque adoptado. Si el esquema exige un valor objetivo independiente de la dispersion observada, dicho valor tendra prelacion sobre los estimadores de consenso, pero la comparacion con la dispersion robusta observada debera documentarse.

#### 2.2.9 Incertidumbre del valor asignado

##### 2.2.9.1 Componente estadistica

Cuando el valor asignado se determine estadisticamente a partir de resultados de participantes, la incertidumbre estandar asociada se calculara mediante:

$$
u(x_{pt}) = 1.25 \times \frac{s^*}{\sqrt{p}}
$$

En los casos en que se utilice otro estimador de dispersion aprobado para el esquema, la expresion anterior se aplicara sustituyendo $s^*$ por el estimador correspondiente.

##### 2.2.9.2 Incertidumbre definitiva

La incertidumbre definitiva del valor asignado se obtendra integrando la componente estadistica con las contribuciones por homogeneidad y estabilidad, de acuerdo con:

$$
u(x_{pt},def) = \sqrt{u_{xpt}^2 + u_{hom}^2 + u_{stab}^2}
$$

En este procedimiento, $u_{xpt}$ representa la incertidumbre estadistica del valor asignado calculada a partir del metodo de caracterizacion. La contribucion por homogeneidad se establece como:

$$
u_{hom} = s_s
$$

La contribucion por estabilidad se definira de la siguiente forma:

$$
u_{stab} =
\begin{cases}
0 & \text{si } \Delta \le 0.3\sigma_{pt} \\
\dfrac{\Delta}{\sqrt{3}} & \text{si } \Delta > 0.3\sigma_{pt}
\end{cases}
$$

donde $\Delta$ corresponde a la diferencia absoluta observada entre la condicion inicial y la condicion de estabilidad evaluada conforme al protocolo del estudio.

#### 2.2.10 Evaluacion de homogeneidad

##### 2.2.10.1 Consideraciones generales

La evaluacion de homogeneidad se realizara sobre los items del ensayo de aptitud empleando el modelo estadistico implementado en `R/pt_homogeneity.R`, en concordancia con ISO 13528:2022. El objetivo es estimar la variabilidad entre items y compararla con la fraccion admisible de la desviacion estandar para evaluacion de aptitud.

##### 2.2.10.2 Media por item

Para cada item $i$ con $m$ replicas, la media por item se calculara como:

$$
\bar{x}_i = \frac{1}{m}\sum_{j=1}^{m} x_{ij}
$$

##### 2.2.10.3 Varianza entre medias de item

La varianza entre las medias de item se calculara mediante:

$$
s_{\bar{x}}^2 = \frac{1}{g-1}\sum_{i=1}^{g}\left(\bar{x}_i - \bar{\bar{x}}\right)^2
$$

donde $g$ es el numero de items y $\bar{\bar{x}}$ es la media global de las medias por item.

##### 2.2.10.4 Desviacion dentro de item para $m = 2$

Cuando el numero de replicas por item sea igual a dos, la desviacion dentro de item se estimara mediante:

$$
s_w = \sqrt{\frac{1}{2g}\sum_{i=1}^{g}\left(x_{i1} - x_{i2}\right)^2}
$$

##### 2.2.10.5 Componente de variacion entre items

La componente de varianza entre items se determinara mediante:

$$
s_s^2 = s_{\bar{x}}^2 - \frac{s_w^2}{m}
$$

Si $s_s^2 < 0$, se adoptara:

$$
s_s = 0
$$

En caso contrario, la desviacion estandar entre items sera:

$$
s_s = \sqrt{s_s^2}
$$

##### 2.2.10.6 Criterio basico de homogeneidad

El criterio basico de aceptacion de homogeneidad sera:

$$
s_s \le 0.3\,\sigma_{pt}
$$

##### 2.2.10.7 Criterio expandido de homogeneidad

Cuando se requiera el criterio expandido conforme a ISO 13528:2022, Tabla 4, se aplicara la relacion:

$$
MS_b \le F_1(0.3\sigma_{pt})^2 + F_2\,MS_w
$$

donde $F_1$ y $F_2$ son factores tabulados dependientes del numero de items y $MS_b$ y $MS_w$ representan los cuadrados medios entre y dentro de items, respectivamente.

#### 2.2.11 Evaluacion de estabilidad

##### 2.2.11.1 Consideraciones generales

La evaluacion de estabilidad se realizara comparando el comportamiento medio de los items bajo la condicion de referencia y la condicion de estabilidad definida por el esquema. El tratamiento estadistico se ejecutara conforme a la logica implementada en `R/pt_homogeneity.R`.

##### 2.2.11.2 Diferencia media

La diferencia media entre la condicion de homogeneidad y la condicion de estabilidad se calculara mediante:

$$
\Delta = \left|\bar{y}_1 - \bar{y}_2\right|
$$

donde $\bar{y}_1$ representa la media de referencia y $\bar{y}_2$ representa la media bajo la condicion de estabilidad.

##### 2.2.11.3 Criterio de estabilidad

El criterio de estabilidad se cumplira cuando:

$$
\Delta \le 0.3\,\sigma_{pt}
$$

Cuando esta desigualdad no se satisfaga, la contribucion por estabilidad debera incorporarse a la incertidumbre definitiva del valor asignado conforme a la expresion definida en la subseccion 7.9.2.

#### 2.2.12 Puntajes de desempeno

##### 2.2.12.1 Puntaje z

El puntaje $z$ se utilizara cuando la incertidumbre del valor asignado sea despreciable frente a $\sigma_{pt}$ y se calculara mediante:

$$
z = \frac{x - x_{pt}}{\sigma_{pt}}
$$

##### 2.2.12.2 Puntaje z prima

El puntaje $z'$ se utilizara cuando la incertidumbre del valor asignado deba incorporarse en el denominador y se calculara mediante:

$$
z' = \frac{x - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}}
$$

##### 2.2.12.3 Puntaje zeta

El puntaje $\zeta$ se utilizara cuando se evalua la compatibilidad entre el resultado del participante y el valor asignado considerando incertidumbres estandar, y se calculara mediante:

$$
\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}}
$$

##### 2.2.12.4 Puntaje En

El puntaje $E_n$ se utilizara para evaluar compatibilidad metrologica cuando se disponga de incertidumbres expandidas, y se calculara mediante:

$$
E_n = \frac{x - x_{pt}}{\sqrt{U_x^2 + U_{xpt}^2}}
$$

##### 2.2.12.5 Criterios de interpretacion

La interpretacion de los puntajes $z$, $z'$ y $\zeta$ se realizara con base en los siguientes intervalos de decision:

| Puntaje z, z', $\zeta$ | Interpretacion |
| --- | --- |
| $|score| \le 2$ | Satisfactorio |
| $2 < |score| < 3$ | Cuestionable |
| $|score| \ge 3$ | No satisfactorio |

La interpretacion del puntaje $E_n$ se realizara segun la siguiente regla:

| Puntaje En | Interpretacion |
| --- | --- |
| $|E_n| \le 1$ | Satisfactorio |
| $|E_n| > 1$ | No satisfactorio |

La categoria cuestionable no aplica a $E_n$ debido a que este puntaje se fundamenta en incertidumbres expandidas y expresa una condicion de compatibilidad metrologica con criterio binario de aceptacion.

### 2.3 Validacion del diseno estadistico

La validacion del diseno estadistico y de sus calculos asociados se realizara mediante trazabilidad directa a la implementacion consolidada en el paquete R `ptcalc` y a los documentos internos de validacion contra hojas de calculo de referencia alineadas con ISO 13528:2022, Anexo C. La verificacion debe demostrar correspondencia entre formulas documentadas, constantes numericas, reglas de decision, salidas computacionales e interpretacion de resultados. La expresion "software validado" dentro del presente procedimiento se entendera especificamente como el paquete R `ptcalc` desarrollado para CALAIRE con soporte de CALAIRE / UNAL-INM.

### 2.4 Registros

Debera conservarse evidencia documental del conjunto de datos utilizado, del metodo seleccionado para el valor asignado, de la desviacion estandar de evaluacion adoptada, de la incertidumbre calculada, de los resultados de homogeneidad y estabilidad, de los puntajes generados para cada participante y de la version del algoritmo o paquete computacional empleado. Cuando se utilice el Algoritmo A, el registro debera incluir al menos el numero de iteraciones, el estado de convergencia y la trazabilidad de los valores winsorizados.

### 2.5 Control de cambios tecnicos incorporados en esta version

La presente version incorpora, como criterio operativo oficial, el uso del factor 1.483 en MADe, el uso obligatorio del factor 1.134 en la actualizacion de $s^*$ dentro del Algoritmo A, la referencia normativa correcta a ISO 13528:2022, la aplicacion del criterio de convergencia por tolerancia absoluta de $1 \times 10^{-4}$ con maximo de 50 iteraciones, la integracion explicita de $u_{hom}$ y $u_{stab}$ en la incertidumbre definitiva del valor asignado y la formalizacion de los criterios de interpretacion para los puntajes $z$, $z'$, $\zeta$ y $E_n$.

## BLOQUE DE FIRMAS

| Campo | Informacion |
| --- | --- |
| REVISO |  |
| ROL |  |
| FECHA |  |
| APROBO |  |
| ROL |  |
| FECHA |  |
