# Informe de revisión de estabilización en datos raw de rondas

## Objetivo

Revisar los datos raw de las rondas de medición y estimar cuánto tardó la
medida en estabilizarse después de cada cambio de concentración del generador.

El análisis se realizó sobre los archivos CSV ubicados en `data/raw/`:

- `datos_ronda_1_p.csv`
- `datos_ronda_1_r.csv`
- `datos_ronda_2a_p.csv`
- `datos_ronda_2a_r.csv`
- `datos_ronda_2b_p.csv`
- `datos_ronda_2b_r.csv`
- `datos_ronda_2c_p.csv`
- `datos_ronda_2c_r.csv`

Los resultados detallados quedaron guardados en:

`session_outputs/260522_test1/results/tables/stabilization_times_raw_rounds.csv`

El análisis quedó automatizado en:

`session_outputs/260522_test1/scripts/analyze_stabilization_raw_rounds.R`

Este script regenera la tabla de tiempos de estabilización y produce una
gráfica por contaminante en:

`session_outputs/260522_test1/results/figures/`

## Datos revisados

Los archivos contienen registros minuto a minuto con:

- Fecha y hora de adquisición.
- Medida observada por el participante o por el instrumento de referencia.
- Concentración nominal del generador.

En la ronda 1 se revisaron las señales de CO y SO2. En las rondas 2a, 2b y 2c
se revisaron O3, NO y NO2, respectivamente. Para cada contaminante se evaluaron
los cambios de nivel del generador y la respuesta de la medición asociada.

## Criterio usado para estimar estabilización

Para cada cambio de concentración del generador se identificó un tramo de
medición con concentración constante. La estabilización se calculó con un
criterio operativo basado en la señal observada:

1. Se detectó el minuto exacto en que cambió la concentración del generador.
2. Se estimó la meseta final del nuevo tramo como la mediana de los últimos
   30 minutos de ese tramo.
3. Se estimó la meseta previa como la mediana de los últimos 30 minutos del
   tramo anterior.
4. Se calculó el tamaño del escalón como la diferencia absoluta entre ambas
   mesetas.
5. Se consideró que la señal estaba estable cuando permaneció 10 minutos
   consecutivos dentro de una banda alrededor de la meseta final.

La banda usada fue:

- ±5% del tamaño del escalón observado, con mínimos prácticos de tolerancia
  para evitar criterios demasiado estrictos cerca de cero.

Este criterio busca medir el tiempo de respuesta hacia una meseta estable, no
la exactitud frente al valor nominal del generador. Por eso la referencia de
estabilización fue la meseta observada y no directamente el valor nominal.

## Resultados generales

Se evaluaron 40 cambios de concentración en total. En la mayoría de los casos,
la estabilización ocurrió rápidamente, dentro de los primeros minutos después
del cambio del generador.

Resumen por medida:

| Medida | Cambios evaluados | Mediana del tiempo de estabilización (min) | Máximo observado (min) |
|---|---:|---:|---:|
| `co_p1` | 4 | 1.5 | 2 |
| `co_ref` | 4 | 2.0 | 16 |
| `so2_p1` | 4 | 0.5 | 2 |
| `so2_ref` | 4 | 1.0 | 2 |
| `O3_p1` | 4 | 2.0 | 5 |
| `O3_ref` | 4 | 2.0 | 4 |
| `NO_p1` | 4 | 0.5 | 5 |
| `NO_ref` | 4 | 2.0 | 3 |
| `NO2_p1` | 4 | 5.0 | 7 |
| `NO2_ref` | 4 | 1.0 | 2 |

## Gráficas generadas

Se generaron cinco gráficas, una por contaminante:

- `session_outputs/260522_test1/results/figures/stabilization_co.png`
- `session_outputs/260522_test1/results/figures/stabilization_so2.png`
- `session_outputs/260522_test1/results/figures/stabilization_o3.png`
- `session_outputs/260522_test1/results/figures/stabilization_no.png`
- `session_outputs/260522_test1/results/figures/stabilization_no2.png`

Cada gráfica muestra la serie temporal de la medida, el nivel del generador,
las líneas verticales de cambio de concentración y el punto donde se detectó
la primera estabilización según el criterio operativo definido.

## Hallazgos por ronda y contaminante

### Ronda 1: CO

Para CO, tanto el participante como la referencia estabilizaron rápidamente en
la mayoría de los cambios.

El participante (`co_p1`) presentó tiempos entre 0 y 2 minutos. La referencia
(`co_ref`) presentó tiempos entre 0 y 16 minutos. El valor máximo de 16 minutos
ocurrió en el cambio de 2.8 a 1.4 ppm, iniciado el `2026-04-23 23:03`, con
estabilización estimada a las `2026-04-23 23:19`.

### Ronda 1: SO2

SO2 mostró una estabilización muy rápida. El participante (`so2_p1`) tardó
entre 0 y 2 minutos, mientras que la referencia (`so2_ref`) tardó entre 1 y
2 minutos.

No se observaron demoras relevantes en SO2 bajo el criterio aplicado.

### Ronda 2a: O3

Para O3, los tiempos de estabilización fueron moderados y consistentes. El
participante (`O3_p1`) tardó entre 1 y 5 minutos. La referencia (`O3_ref`) tardó
entre 1 y 4 minutos.

El mayor tiempo del participante ocurrió en el cambio de 180 a 120 nmol/mol,
iniciado el `2026-04-30 06:03`, con estabilización estimada a los 5 minutos.

### Ronda 2b: NO

NO presentó estabilización rápida. El participante (`NO_p1`) tuvo tiempos entre
0 y 5 minutos. La referencia (`NO_ref`) tuvo tiempos entre 0 y 3 minutos.

El mayor tiempo del participante ocurrió en el cambio de 0 a 180 nmol/mol,
iniciado el `2026-05-01 04:20`, con estabilización a los 5 minutos.

### Ronda 2c: NO2

NO2 fue el contaminante con mayor tiempo típico de estabilización en el
participante. `NO2_p1` tuvo una mediana de 5 minutos y un máximo de 7 minutos.
La referencia (`NO2_ref`) estabilizó más rápido, entre 0 y 2 minutos.

Los tiempos más altos del participante ocurrieron en los cambios:

- 140 a 105 nmol/mol: 7 minutos.
- 60 a 30 nmol/mol: 6 minutos.
- 105 a 60 nmol/mol: 4 minutos.

## Conclusiones

Los datos raw muestran que, bajo el criterio aplicado, la mayoría de las señales
se estabilizaron en menos de 5 minutos después de cada cambio de concentración.

El caso más lento fue `co_ref` en el cambio de 2.8 a 1.4 ppm, con 16 minutos.
Fuera de ese caso, los máximos observados estuvieron entre 2 y 7 minutos.

El participante en NO2 mostró los tiempos de estabilización más altos de forma
consistente, con una mediana de 5 minutos. En contraste, SO2, NO y CO del
participante estabilizaron generalmente en 0 a 2 minutos.

Estos resultados sugieren que, para la mayor parte de las rondas, un periodo de
espera de al menos 10 minutos después del cambio de concentración sería
suficiente para excluir transitorios iniciales bajo este criterio. Para NO2 del
participante, y para el caso puntual de CO de referencia, conviene conservar un
margen adicional si se requiere seleccionar ventanas de análisis estrictamente
estables.

## Limitaciones

El análisis estima estabilización respecto a la meseta observada, no respecto al
valor nominal del generador. Esto evita mezclar tiempo de estabilización con
sesgo de calibración, pero implica que los resultados deben interpretarse como
tiempo de asentamiento de la señal.

La elección de 10 minutos consecutivos y una banda de ±5% del escalón observado
es un criterio operativo. Si se requiere un criterio metrológico más estricto,
por ejemplo basado en incertidumbre, repetibilidad o límites específicos por
contaminante, los tiempos podrían cambiar.
