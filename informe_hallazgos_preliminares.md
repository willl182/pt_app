# Informe sencillo de hallazgos preliminares

## 1. Alcance

Se revisaron los archivos de las rondas R1, R2 y R3 para identificar su estructura, niveles nominales, comparabilidad y problemas visibles de calidad de datos.

Este documento **no presenta todavía resultados estadísticos definitivos**. No se han ejecutado el pipeline, las pruebas estadísticas ni las gráficas definidas en `plan_analisis.md` y `workflow_analisis.md`. Los hallazgos corresponden a inspección directa de los archivos y deben confirmarse durante el análisis formal.

## 2. Diseño de las rondas

- **R1:** SO2 y CO, participante P1 y analizador de referencia CalAire.
- **R2:** O3, NO y NO2, mismo participante P1 y misma referencia CalAire.
- **R3:** O3, NO y NO2, participante diferente P2 (`ZFT5R6`) y nuevamente la referencia CalAire.

R2 y R3 permiten comparar los mismos analitos, pero no representan seguimiento temporal de un mismo participante. La continuidad temporal sólo corresponde al analizador de referencia, bajo el supuesto confirmado externamente de que `4UXXXX` y `4UDY72` identifican el mismo equipo físico.

## 3. Niveles nominales verificados

Los nominales registrados en los CSV son:

- **O3 R2 y R3:** 0, 180, 120, 80 y 40 ppb.
- **NO R2:** 0, 180, 119, 78 y 37 ppb.
- **NO R3:** 0, 179, 119, 80 y 41 ppb.
- **NO2 R2:** 0, 140, 105, 60 y 30 ppb.
- **NO2 R3:** 0, 144, 112, 64 y 32 ppb.
- **SO2 R1:** 0, 179, 119, 80 y 40 ppb.
- **CO R1:** 0, 6.3, 4.2, 2.8 y 1.4 ppm.

Las diferencias de nominal en NO se consideran tolerables. En NO2 se mantienen los niveles cero, 2, 4 y 5 para la comparación R2–R3; el nivel 3, con nominales 105 y 112 ppb, queda fuera de esa comparación. Todos los niveles permanecen disponibles para el análisis individual de cada ronda.

El cero se conserva para O3, NO y NO2. Como su nominal es cero, debe compararse en concentración absoluta y no mediante error relativo. CO permanece separado por estar expresado en ppm.

## 4. Hallazgos de calidad de datos

### 4.1 Interrupciones temporales

- `R2C_NO2.csv` presenta una interrupción cercana a 12 horas. El período de cero queda truncado y debe interpretarse con cautela.
- `R3_NO2.csv` presenta otra interrupción cercana a 14 horas entre el 16 de julio, 09:00 y 23:01. Esto reduce las observaciones del nivel 2 respecto de los demás niveles.

Estas interrupciones no justifican borrar los niveles completos, pero deben quedar documentadas en tablas, gráficas e interpretación.

### 4.2 Valores no numéricos y ausentes

- `R3_NO.csv` contiene una ocurrencia de `Samp<` en los tres canales del participante.
- Cada celda afectada debe convertirse en `NA` puntual, sin eliminar la fila completa ni las observaciones cercanas.
- También existen celdas vacías en archivos de R2, especialmente `R2B_NO.csv` y `R2C_NO2.csv`.

### 4.3 Desfase del nivel del generador

En `R2B_NO.csv` aparecen aproximadamente seis registros con lecturas elevadas mientras el nominal continúa marcado como cero. Esto indica un desfase entre el cambio real de concentración y la etiqueta del generador. Los puntos deben marcarse mediante control de calidad y no interpretarse como un cero estable.

### 4.4 Excursiones en O3

`R2A_O3.csv` presenta excursiones visibles durante el nivel 2. Deben marcarse como posibles valores atípicos y reportarse en resultados con y sin esos puntos, evitando descartarlos en silencio.

### 4.5 NO2 en R3

En `R3_NO2.csv`, las mediciones de referencia superan los nominales declarados en varios niveles. El patrón no parece limitado al nivel 2: también existe una diferencia clara en el nivel 3 y diferencias menores en los niveles 4 y 5.

Por tanto, conviene describirlo como un posible corrimiento sistemático de la concentración generada durante R3, no como una anomalía exclusiva del nivel 2. No se aplicará corrección: los sesgos se conservarán y reportarán tal como resulten.

El nivel 2 añade dos limitaciones simultáneas: nominal declarado de 144 ppb frente a mediciones cercanas a 154 ppb en ambos equipos, y período truncado por la interrupción temporal.

### 4.6 Ceros repetidos en R3

El período de cero de `R3_NO.csv` y `R3_NO2.csv` contiene las mismas 60 observaciones iniciales. No son dos mediciones independientes del cero. Deben evitarse el doble conteo y cualquier interpretación que los trate como evidencia independiente.

### 4.7 Resolución del participante P1 en cero

En varios ceros de R2, el participante P1 reporta numerosos valores exactamente iguales a cero, mientras la referencia conserva variación decimal. Esto puede reflejar truncamiento, resolución limitada o formato de exportación.

En consecuencia, una desviación estándar pequeña o nula para P1 no debe interpretarse automáticamente como mejor estabilidad. La comparación de ruido de cero entre P1 y P2 puede reflejar diferencias de resolución instrumental, además del desempeño real.

### 4.8 Canales NO, NO2 y NOx

Los archivos multicanal de R3 permiten revisar la conservación:

`NO + NO2 ≈ NOx`

En `R3_NO2.csv`, NO varía de forma inversa a NO2 mientras NOx permanece aproximadamente constante. Esto es compatible con el comportamiento esperado de una titulación en fase gaseosa. El canal NO concomitante no debe describirse como un valor fijo cercano a 155 ppb; ese valor corresponde principalmente a uno de los niveles.

## 5. Comparaciones válidas

### Dentro de cada ronda

Referencia y participante compartieron tiempo, mezcla y nivel. Por eso pueden calcularse diferencias punto a punto, sesgo, dispersión, deriva dentro de nivel y límites de Bland–Altman.

### Entre R2 y R3

Las rondas ocurrieron en fechas diferentes, con participantes y mezclas diferentes. Las comparaciones deben hacerse mediante agregados por nivel, no emparejando registros minuto a minuto.

- Nivel cero: concentración absoluta en ppb.
- Niveles distintos de cero: error relativo para comparaciones inter-ronda.
- O3 y NO también pueden mostrarse en concentración debido a su comparabilidad nominal aceptada.
- NO2: comparación inter-ronda sólo para niveles 1, 2, 4 y 5.

## 6. Interpretación preliminar

Los archivos permiten estudiar tres componentes distintos:

1. Desempeño de referencia frente a participante dentro de cada ronda.
2. Cambio temporal del analizador de referencia entre R2 y R3.
3. Diferencia descriptiva entre P1 y P2, descontando en lo posible el cambio de la referencia.

Sin embargo, todavía no puede afirmarse cuál participante tuvo mejor desempeño ni si la referencia presentó deriva significativa. Estas conclusiones requieren ejecutar el análisis por nivel, aplicar los controles de calidad y calcular incertidumbre o intervalos de confianza.

La comparación entre P1 y P2 seguirá siendo descriptiva porque existe una sola ronda por participante. Cualquier diferencia puede incluir efectos de participante, fecha, mezcla generada, resolución de exportación y condiciones experimentales.

## 7. Conclusiones

- Estructura general permite comparaciones previstas, con restricciones claras entre análisis intra-ronda e inter-ronda.
- Cero debe conservarse en todos los analitos; en R3, ceros de NO y NO2 no son independientes.
- CO debe analizarse por separado por diferencia de unidad.
- NO presenta diferencias nominales aceptables entre R2 y R3.
- NO2 nivel 3 debe excluirse únicamente de comparación cruzada R2–R3.
- `R3_NO2` muestra indicios de corrimiento en varios niveles, no sólo en nivel 2.
- Interrupciones de `R2C_NO2` y `R3_NO2`, excursiones de O3, desfase de NO y valores `Samp<` requieren flags explícitos.
- Ceros exactos de P1 limitan interpretación de su ruido instrumental.
- No debe corregirse ningún sesgo antes del análisis; debe reportarse valor observado y su contexto.
- Resultados cuantitativos definitivos quedan pendientes de ejecución del workflow.
