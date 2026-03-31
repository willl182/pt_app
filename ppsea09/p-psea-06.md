# P-PSEA-06 Procedimiento de Diseno Estadistico para Ensayos de Aptitud

## 1. Informacion general del procedimiento

### 1.1 Objetivo

Establecer el procedimiento estadistico y metrologico aplicable al diseno, calculo, validacion y evaluacion de las rondas de ensayos de aptitud (EA) desarrolladas por el Laboratorio CALAIRE, de conformidad con ISO 13528:2022 e ISO/IEC 17043:2023.

### 1.2 Alcance

Este procedimiento aplica al diseno estadistico de las rondas de EA para gases contaminantes criterio organizadas por CALAIRE, incluyendo caracterizacion del valor asignado, definicion de la desviacion estandar para evaluacion de aptitud, evaluacion de homogeneidad y estabilidad, estimacion de incertidumbre e interpretacion de puntajes de desempeno.

### 1.3 Definiciones y simbolos

- `x_pt`: valor asignado.
- `sigma_pt`: desviacion estandar para evaluacion de aptitud.
- `u(x_pt)`: incertidumbre estandar del valor asignado.
- `u(x_pt,def)`: incertidumbre estandar definitiva del valor asignado, una vez integradas las contribuciones por homogeneidad y estabilidad.
- `u_hom`: contribucion por homogeneidad.
- `u_stab`: contribucion por estabilidad.
- `p`: numero de participantes con resultados validos.
- `x*` y `s*`: estimadores robustos de ubicacion y dispersion obtenidos mediante Algoritmo A.
- `MADe`: desviacion absoluta mediana escalada.
- `nIQR`: rango intercuartil normalizado.
- `z`, `z'`, `zeta` y `E_n`: estadisticos de desempeno definidos en ISO 13528:2022.

### 1.4 Documentos de referencia

- ISO 13528:2022, metodos estadisticos para ensayos de aptitud por comparacion interlaboratorio.
- ISO/IEC 17043:2023, requisitos generales para proveedores de ensayos de aptitud.
- EA-4/21 INF:2018, directrices para pequenas comparaciones interlaboratorio.
- ILAC P9:01/2024, politica de uso de ensayos de aptitud e ILC para acreditacion.
- ISO 17034, para materiales de referencia cuando aplique.
- ISO 6143:2025 e ISO 6142-1, para trazabilidad de mezclas gaseosas cuando aplique.
- `P-PSEA-09.md`, procedimiento de planificacion de ronda EA.
- `R/pt_robust_stats.R` y `R/pt_homogeneity.R`, implementacion institucional validada.

### 1.5 Condiciones generales

La aplicacion del presente procedimiento requiere que los resultados empleados correspondan al mismo mensurando, se expresen en unidades consistentes y tengan trazabilidad documental suficiente para su analisis. Toda decision sobre valor asignado, `sigma_pt`, incertidumbre y puntaje de desempeno debe quedar registrada en el expediente tecnico de la ronda.

## 2. Informacion especifica del procedimiento

### 2.1 Roles y responsabilidades

| Rol | Responsabilidad |
| --- | --- |
| Responsable estadistico o experto tecnico autorizado | Definir el diseno estadistico, seleccionar el metodo de caracterizacion, justificar `sigma_pt`, ejecutar y revisar los calculos. |
| Coordinador EA | Aprobar el diseno estadistico de la ronda y verificar su coherencia con `P-PSEA-09.md`. |
| Ingeniero operativo | Asegurar la integridad tecnica de los datos de entrada, estudios de homogeneidad y estabilidad, y trazabilidad del item. |
| Profesional de calidad | Controlar version, aprobacion, registros y evidencia documental del procedimiento aplicado. |

### 2.2 Desarrollo del diseno estadistico

#### 2.2.1 Definicion de objetivos

Antes de iniciar el calculo, la ronda debe definir si el objetivo es:

- evaluar desempeno de laboratorios frente a un valor asignado;
- verificar comparabilidad metrologica;
- detectar sesgos o dispersion excesiva;
- dar seguimiento longitudinal a participantes o metodos.

#### 2.2.2 Seleccion del tipo de datos y numero de participantes

Los datos del esquema deben ser cuantitativos y expresarse en unidades de concentracion coherentes con el mensurando. Para seleccionar el metodo de consenso o de referencia se adoptan las siguientes reglas:

- Si `p >= 12`, el consenso de participantes puede establecerse preferentemente mediante Algoritmo A.
- Si `5 <= p < 12`, el consenso puede establecerse mediante mediana y un estimador robusto de dispersion como MADe o nIQR, siempre que se justifique que no existe mejor valor asignado externo.
- Si `p < 5`, no debe usarse el consenso de participantes como opcion principal para definir `x_pt` y `sigma_pt`; debe priorizarse un valor asignado independiente y una `sigma_pt` externa o de aptitud para el uso.
- La condicion `u(x_pt) <= 0.3 sigma_pt` debe verificarse para sustentar el uso de `z`. Si `u(x_pt)` es del mismo orden que `sigma_pt`, el uso de `z` simple no es apropiado.
- Como referencia practica, si `s*` es aproximadamente igual a `sigma_pt`, el consenso de participantes requiere cerca de 17 resultados validos para que `u(x_pt) = 1.25 s* / sqrt(p)` cumpla el criterio `0.3 sigma_pt`.

#### 2.2.3 Preparacion y depuracion de datos

Antes de cualquier calculo se debe:

- verificar identificadores, unidades, analitos, niveles y replicados;
- excluir `NA`, `Inf`, `-Inf` y datos manifiestamente invalidos desde el punto de vista metrologico;
- documentar toda exclusion y su causa;
- confirmar que el conjunto final contiene al menos tres observaciones validas para cualquier aplicacion de Algoritmo A.

#### 2.2.4 Seleccion del metodo estadistico

La seleccion del metodo para determinar `x_pt`, `sigma_pt` y el estadistico de desempeno debe seguir esta jerarquia:

1. Valor formulado o preparado a partir de trazabilidad metrologica demostrada.
2. Material de referencia certificado.
3. Valor de laboratorio de referencia competente.
4. Consenso de laboratorios expertos.
5. Consenso de participantes.

Adicionalmente, la seleccion del puntaje de desempeno debe seguir estas reglas:

- Si `u(x_pt) < 0.3 sigma_pt`, usar `z` como estadistico principal.
- Si `u(x_pt) >= 0.3 sigma_pt`, usar `z'` cuando exista `sigma_pt` definida y `zeta` o `E_n` cuando el esquema disponga de incertidumbres reportadas.
- Si el esquema utiliza incertidumbres expandidas reportadas por el participante y por la referencia, `E_n` es el estadistico preferido para compatibilidad metrologica.

#### 2.2.5 Estimadores robustos de dispersion

##### 2.2.5.1 MADe

Cuando se requiera un estimador robusto simple de dispersion, se utilizara:

`MADe = 1.483 x mediana(|x_i - mediana(x_i)|)`

El factor institucional adoptado es `1.483`, en concordancia con la implementacion validada en `R/pt_robust_stats.R`.

##### 2.2.5.2 nIQR

Como alternativa robusta de dispersion podra utilizarse:

`nIQR = 0.7413 x (Q3 - Q1)`

Este estimador es util para contrastar la dispersion observada cuando el numero de participantes es intermedio o cuando conviene complementar MADe.

##### 2.2.5.3 Estimadores Q/Hampel

En comparaciones pequenas o de alta sensibilidad a valores extremos podran utilizarse estimadores robustos alternativos tipo Q o Hampel, siempre que:

- su uso quede justificado en el expediente tecnico;
- exista validacion documental del metodo para el esquema;
- se reconozca que, a la fecha, dichos estimadores no se encuentran implementados en la PT App institucional.

#### 2.2.6 Algoritmo A para estimacion robusta de ubicacion y dispersion

##### 2.2.6.1 Descripcion general

El Algoritmo A de ISO 13528:2022 es el metodo iterativo institucional de referencia para obtener `x*` y `s*` cuando existe base suficiente de resultados de participantes. Su punto de quiebre practico es cercano al 25 %, por lo cual para `p < 12` debe contrastarse con mediana y MADe o nIQR antes de adoptar el resultado final.

##### 2.2.6.2 Inicializacion

La inicializacion se realiza con:

- `x*_0 = mediana(x_i)`
- `s*_0 = 1.483 x mediana(|x_i - x*_0|)`

Si `s*_0` no es finita o es practicamente nula, puede utilizarse la desviacion estandar clasica como respaldo tecnico.

##### 2.2.6.3 Paso iterativo de winsorizacion

En cada iteracion:

- `delta = 1.5 x s*`
- cada observacion se winsoriza al intervalo `[x* - delta, x* + delta]`
- la nueva ubicacion es la media de los valores winsorizados
- la nueva dispersion es `1.134` por la desviacion estandar de los valores winsorizados

##### 2.2.6.4 Criterio de convergencia

Para este procedimiento operativo se adopta:

- tolerancia institucional `1e-04`;
- maximo de `50` iteraciones;
- criterio de convergencia basado en el cambio absoluto simultaneo de `x*` y `s*`.

Aunque la funcion `run_algorithm_a()` admite por defecto `tol = 1e-06`, la documentacion operativa del procedimiento se alinea con `tol = 1e-04`.

##### 2.2.6.5 Salidas del algoritmo

Cuando el algoritmo converge:

- `x_pt = x*`, salvo que el esquema haya definido un valor asignado externo con mayor jerarquia;
- `sigma_pt = s*` unicamente cuando la desviacion de aptitud se derive del consenso, lo cual no es la opcion preferida para poblaciones pequenas;
- deben conservarse el numero de iteraciones, convergencia y limites de winsorizacion aplicados.

#### 2.2.7 Determinacion del valor asignado

El valor asignado debe establecerse siguiendo la jerarquia de ISO 13528:2022:

1. valor formulado;
2. material de referencia certificado;
3. laboratorio de referencia;
4. consenso de laboratorios expertos;
5. consenso de participantes.

Para `p < 12`, el consenso de participantes debe considerarse una opcion secundaria. Para `p < 5`, se deben preferir los metodos 1 a 4. La seleccion final debe justificarse indicando:

- fuente del valor;
- trazabilidad;
- incertidumbre asociada;
- razon para no utilizar un metodo de jerarquia superior.

#### 2.2.8 Desviacion estandar para evaluacion de aptitud

La `sigma_pt` debe definirse por la ruta tecnicamente mas defendible, en el siguiente orden de preferencia:

1. criterio regulatorio o de aptitud para el uso;
2. modelo empirico o sectorial documentado;
3. datos historicos de reproducibilidad;
4. consenso robusto de participantes.

Cuando corresponda, podran emplearse:

- modelo Horwitz-Thompson: `sigma_H = 0.02 x c^0.8495`;
- criterio de aptitud para el uso basado en objetivos regulatorios, por ejemplo incertidumbre expandida maxima del 15 %, equivalente a una incertidumbre estandar aproximada entre 5 % y 7.5 % segun el esquema adoptado;
- modelos lineales sectoriales tipo `sigma_pt = a x c + b`, cuando existan antecedentes tecnicos suficientes.

Si `sigma_pt` se fija externamente, debe documentarse la comparacion con la dispersion robusta observada para detectar comportamiento anomalo de la ronda.

#### 2.2.9 Incertidumbre del valor asignado

##### 2.2.9.1 Componente estadistica

Cuando `x_pt` se derive estadisticamente de participantes, la incertidumbre estandar se calcula como:

`u(x_pt) = 1.25 x s* / sqrt(p)`

Si se emplea otro estimador robusto aprobado, la expresion se aplicara sustituyendo `s*` por el estimador correspondiente.

##### 2.2.9.2 Incertidumbre definitiva

La incertidumbre definitiva del valor asignado se calcula como:

`u(x_pt,def) = sqrt(u(x_pt)^2 + u_hom^2 + u_stab^2)`

donde:

- `u_hom = s_s`, componente entre items obtenida en el estudio de homogeneidad;
- `u_stab = 0` si `Delta <= 0.3 sigma_pt`;
- `u_stab = Delta / sqrt(3)` si `Delta > 0.3 sigma_pt`.

##### 2.2.9.3 Regla de uso para puntajes

Cuando `u(x_pt) >= 0.3 sigma_pt`, debe reemplazarse `z` por `z'` o por `zeta` segun la informacion disponible de incertidumbres.

#### 2.2.10 Evaluacion de homogeneidad

La evaluacion de homogeneidad se ejecuta conforme a `R/pt_homogeneity.R` y a ISO 13528:2022. Para cada nivel evaluado:

- se calcula la media por item;
- se estima la variacion entre items `s_s`;
- se compara `s_s` con `0.3 sigma_pt`.

El criterio basico de aceptacion es:

`s_s <= 0.3 sigma_pt`

Cuando se use el criterio expandido de ISO 13528:2022, Tabla 4, se emplearan los coeficientes `F1` y `F2` implementados institucionalmente para comparar `MS_between` con:

`F1 x (0.3 sigma_pt)^2 + F2 x MS_within`

#### 2.2.11 Evaluacion de estabilidad

La estabilidad se evalua comparando la condicion de referencia y la condicion de estabilidad definidas en la ronda. El criterio operativo es:

`|Delta| <= 0.3 sigma_pt`

Cuando el criterio no se cumpla, la contribucion por estabilidad debe incorporarse a `u(x_pt,def)` y el expediente tecnico debe definir si la ronda sigue siendo apta para evaluacion.

#### 2.2.12 Puntajes de desempeno

##### 2.2.12.1 Puntaje z

`z = (x - x_pt) / sigma_pt`

Se usa cuando la incertidumbre del valor asignado es despreciable frente a `sigma_pt`.

##### 2.2.12.2 Puntaje z'

`z' = (x - x_pt) / sqrt(sigma_pt^2 + u(x_pt)^2)`

Se usa cuando `u(x_pt)` no es despreciable.

##### 2.2.12.3 Puntaje zeta

`zeta = (x - x_pt) / sqrt(u(x)^2 + u(x_pt)^2)`

Se usa cuando se desea evaluar compatibilidad considerando incertidumbres estandar reportadas.

##### 2.2.12.4 Puntaje E_n

`E_n = (x - x_pt) / sqrt(U(x)^2 + U(x_pt)^2)`

Se usa cuando se dispone de incertidumbres expandidas coherentes entre participante y referencia.

##### 2.2.12.5 Criterios de interpretacion

Para `z`, `z'` y `zeta`:

- `|score| <= 2`: satisfactorio.
- `2 < |score| < 3`: cuestionable.
- `|score| >= 3`: no satisfactorio.

Para `E_n`:

- `|E_n| <= 1`: satisfactorio.
- `|E_n| > 1`: no satisfactorio.

#### 2.2.13 Criterios para pequenas comparaciones interlaboratorio

Cuando `p <= 7`, la ronda debe tratarse como pequena comparacion interlaboratorio y evaluarse bajo una logica alineada con EA-4/21 INF:2018:

- Escenario 1. Existe valor de referencia externo y `sigma_pt` externa: usar `z`, `z'`, `zeta` o `E_n` segun corresponda.
- Escenario 2. No existe referencia externa, pero hay participantes experimentados y comparables: puede usarse consenso robusto con fuerte justificacion tecnica, preferiblemente contrastando mediana con estimadores robustos alternativos y usando `sigma_pt` externa.
- Escenario 3. No existe base suficiente para establecer puntajes formales defendibles: se realiza evaluacion descriptiva, grafica y cualitativa, evitando concluir con un puntaje numerico no sustentable.

Para `p < 5`, el procedimiento preferido es el Escenario 1.

#### 2.2.14 Graficos y visualizacion recomendada

Los informes y revisiones tecnicas deben considerar, segun aplique:

- histogramas o distribuciones de resultados;
- graficos de barras de `z`, `z'`, `zeta` o `E_n`;
- graficos de Youden cuando existan pares de resultados;
- graficos de control multi-ronda para seguimiento longitudinal.

La PT App institucional genera de forma automatica graficos de barras de puntajes. Los demas graficos podran elaborarse cuando aporten valor interpretativo a la ronda.

### 2.3 Referencia cruzada con la planificacion de ronda

La seleccion del valor asignado, `sigma_pt`, estudios de homogeneidad y estabilidad, y puntajes de desempeno debe quedar reflejada en la documentacion de cada ronda conforme a `P-PSEA-09.md`.

## 3. Registros

Como minimo deben conservarse:

- base de datos analizada;
- justificacion del metodo de caracterizacion;
- calculos de `x_pt`, `sigma_pt`, `u(x_pt)` y `u(x_pt,def)`;
- estudios de homogeneidad y estabilidad;
- salidas del software validado;
- decision final sobre estadisticos de desempeno;
- version del procedimiento y fecha de aplicacion.

## 4. Control de cambios y aprobacion

Este procedimiento entra en revision cuando cambien las normas de referencia, el software institucional o la estrategia estadistica adoptada para las rondas.

| Reviso | Aprobo |
| --- | --- |
|  |  |
