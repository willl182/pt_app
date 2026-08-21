# Contribución de la curva de calibración a la incertidumbre

**Fecha:** 2026-07-30
**Scripts:** `scripts/08_u_calibracion.R` — implementa este método leyendo los formatos `.xlsm` directamente y reproduce las cifras de las secciones 4 y 5.

> Las versiones originales, con los puntos de calibración escritos a mano, quedaron en `scripts/superseded/08_u_curva_calibracion.R` y `scripts/superseded/09_aplicar_u_curva_niveles.R`.
**Salidas:** `outputs/tables/u_curva_referencia_niveles.csv`, `outputs/tables/u_curva_por_nivel.csv`

---

## 1. Qué se está midiendo

Cuando el analizador de referencia se calibra multipunto, se le entregan concentraciones conocidas del calibrador (patrón, eje *x*) y se registra lo que el analizador lee (eje *y*). Con esos 5 puntos se ajusta una recta:

$$y = y_1 + y_2 \cdot x$$

Esa recta nunca pasa exactamente por los 5 puntos. Esa desviación es incertidumbre: si mañana el analizador lee 80 ppb, no sabemos con certeza absoluta que la concentración real sea 80. **Esa duda es la contribución de la curva de calibración**, y es lo que se cuantifica aquí.

Es un componente aparte de la repetibilidad. La repetibilidad dice *"cuánto varían mis 3 lecturas entre sí"*; la curva dice *"cuán bien traduce mi analizador lectura a concentración"*. Se suman en cuadratura, no se sustituyen.

## 2. Fuente de los datos

| Gas | Formato | Equipo | Fecha | Rango |
|---|---|---|---|---|
| O3 | F-PSEY-49 | THERMO 49C s/n 59756-324 | 2026-04-29 | 250 ppb |
| NO / NOx / NO2 | F-PSEY-61 | HORIBA APNA-370 s/n 139992 | 2026-04-29 | 200 ppb |
| SO2 | F-PSEY-62 | HORIBA APSA-370 s/n 139991 | 2026-04-22 | 200 ppb |
| CO | F-PSEY-47 | TAPI T300 s/n 509 | 2026-04-22 | 10 ppm |

De cada formato se usan 5 puntos: el **cero dejado** más los 4 puntos multipunto (20 %, 40 %, 70 %, 90 %). El punto "90 % encontrado" se excluye por ser pre-ajuste.

Verificación: los ajustes calculados reproducen exactamente la pendiente y el intercepto que reporta cada hoja de cálculo, así que se está trabajando sobre la misma recta que certificó el laboratorio.

## 3. Los dos métodos usados

### Método A — GUM H.3 (estadístico)

Usa la dispersión real de los 5 puntos alrededor de la recta.

1. Varianza residual: $s^2 = \dfrac{\sum (\text{residuo})^2}{n-2}$, con $n = 5$.
2. Incertidumbre del valor ajustado en la concentración $c$:
   $$u_{\text{ajuste}}(c) = s\sqrt{\dfrac{1}{n} + \dfrac{(c - \bar{x})^2}{\sum(x_k - \bar{x})^2}}$$
3. Se pasa a escala de concentración dividiendo por la pendiente: $u_{\text{curva}} = u_{\text{ajuste}} / |y_2|$.

**Comportamiento:** forma de U. Mínima cerca del promedio de los puntos de calibración (~90 ppb), crece hacia el cero y hacia el tope de escala. Es el comportamiento correcto: extrapolar hacia los extremos de la recta es más incierto.

### Método B — Falta de ajuste, EN 14211 / EN 14212 (peor caso)

Usa solo el error más grande observado.

1. Residuo máximo, en % del fondo de escala: $r_{max}$.
2. Distribución rectangular:
   $$u_{l,l_h} = \frac{r_{max}}{100} \cdot \frac{l_h}{\sqrt{3}}$$

**Comportamiento:** proporcional al nivel. Vale cero en el cero (lo cual es irreal) y es máxima en el tope.

### Cuál se usa

Se toma **el mayor de los dos en cada nivel**. Razón: se complementan. GUM manda en niveles bajos y en el cero, donde el método B da un valor artificialmente nulo; el método B manda en el tope de escala, donde protege contra la no linealidad que GUM subestima si los residuos quedaron pequeños por azar.

## 4. Parámetros del ajuste

| Gas | Pendiente | Intercepto | s residual | u(intercepto) | u(pendiente) | r_max %FS |
|---|---|---|---|---|---|---|
| O3 | 0.998264 | −0.148 | 1.161 ppb | 0.866 | 0.00793 | 0.963 |
| NO | 1.003766 | −0.606 | 0.414 ppb | 0.311 | 0.00283 | 0.268 |
| NOx | 0.998696 | +0.299 | 0.401 ppb | 0.301 | 0.00275 | 0.281 |
| NO2 (GPT) | 0.996681 | +0.836 | 0.632 ppb | 0.464 | 0.00539 | 0.579 |
| SO2 | 0.998063 | +0.104 | 0.440 ppb | 0.330 | 0.00317 | 0.283 |
| CO | 0.990632 | +0.0265 | 0.058 ppm | 0.0432 | 0.0118 | 1.168 |

## 5. Resultado: u por curva en cada nivel PT

Valores en la misma unidad del gas (nmol/mol, salvo CO en µmol/mol).

| Nivel | O3 | NO | NO2 | SO2 | CO |
|---|---|---|---|---|---|
| 1 (cero) | 0.868 | 0.310 | 0.465 | 0.330 | 0.0436 |
| 2 | 0.642 (40) | 0.227 (41) | 0.344 (32) | 0.241 (40) | 0.0319 (1.4) |
| 3 | 0.523 (80) | 0.186 (80) | 0.284 (64) | 0.197 (80) | 0.0261 (2.8) |
| 4 | 0.667 (120) | 0.204 (119) | 0.375 (112) | 0.227 (119) | 0.0301 (4.2) |
| 5 | 1.001 (180) | 0.316 (179) | 0.499 (144) | 0.361 (179) | 0.0478 (6.3) |

*(entre paréntesis, la concentración nominal del nivel)*

En términos relativos, en el nivel más alto de cada gas:

| Gas | u_curva relativa |
|---|---|
| O3 | 0.56 % |
| NO | 0.18 % |
| NO2 | 0.35 % |
| SO2 | 0.20 % |
| CO | 0.76 % |

## 6. Lectura de los resultados

- **O3 es el gas con mayor aporte absoluto.** Viene casi todo de un solo punto: el 79.8 ppb leyó 77.78, un residuo de −1.73 ppb. Ese punto solo eleva la s residual de O3 a casi el triple de la de NO.
- **CO es el peor en términos relativos** (r_max 1.17 %FS), por el residuo +0.074 ppm en el punto de 1.4 ppm. En valor absoluto es pequeño, pero relativo al nivel bajo pesa.
- **NO, NOx y SO2 son los ajustes más limpios**, con residuos por debajo de 0.51 ppb en todos los puntos.
- **El nivel cero siempre tiene la u más alta** de la serie por el método GUM, porque está en el extremo de la recta y lejos del centroide de calibración.

## 7. Cómo se integra al presupuesto de incertidumbre

$$u_c = \sqrt{u_{\text{repetibilidad}}^2 + u_{\text{curva}}^2 + u_{\text{patrón}}^2 + \ldots}$$

donde $u_{\text{repetibilidad}} = s/\sqrt{3}$ sobre las 3 lecturas horarias (ya calculada en el pipeline como `u_value`), y $u_{\text{curva}}$ es la tabla de la sección 5. La incertidumbre expandida es $U = k \cdot u_c$ con $k = 2$.

En la práctica: se busca la fila del gas y del nivel en `outputs/u_curva_referencia_niveles.csv` y se suma en cuadratura al resto de componentes de esa medición.

## 8. Presupuesto completo por gas y nivel

Fuente: `outputs/tables/presupuesto_incertidumbre.csv` (`scripts/09_presupuesto_incertidumbre.R`). Todas las columnas de incertidumbre en la unidad del gas: ppb, salvo CO en ppm. $u_c$ es la suma en cuadratura de las cinco componentes; $U = 2u_c$.

Componentes: `u_rep` repetibilidad de las 3 lecturas horarias; `u_curva` la sección 5; `u_patron` el patrón entregado al analizador; `u_aire_cero` el generador de aire cero; `u_conv` la eficiencia de conversión, solo aplica a NO2 por GPT y vale cero en el nivel cero.

> **Atención al índice `level`.** En esta tabla, tomada del pipeline, `level` es el índice PT y va del nominal más alto al más bajo (level 2 = tope de escala). La tabla de la sección 5 usa el orden inverso (nivel 5 = tope). Al cruzar ambas, guíese por la concentración nominal, no por el número de nivel.

| Gas | Ronda | Level | Nominal | u_rep | u_curva | u_patron | u_aire_cero | u_conv | u_c | U (k=2) | U rel % |
|---|---|---|---|---|---|---|---|---|---|---|---|
| CO | R1 | 1 | 0 | 0.0175 | 0.0436 | 0.0500 | 0.0104 | 0 | 0.0694 | 0.139 | — |
| CO | R1 | 2 | 6.30 | 0.0263 | 0.0478 | 0.0500 | 0.0104 | 0 | 0.0747 | 0.149 | 2.37 |
| CO | R1 | 3 | 4.20 | 0.0200 | 0.0301 | 0.0500 | 0.0104 | 0 | 0.0625 | 0.125 | 2.98 |
| CO | R1 | 4 | 2.80 | 0.0148 | 0.0261 | 0.0500 | 0.0104 | 0 | 0.0592 | 0.118 | 4.23 |
| CO | R1 | 5 | 1.40 | 0.0123 | 0.0319 | 0.0500 | 0.0104 | 0 | 0.0614 | 0.123 | 8.78 |
| NO | R2B | 1 | 0 | 0.216 | 0.310 | 0.500 | 0.442 | 0 | 0.767 | 1.53 | — |
| NO | R2B | 2 | 180 | 0.0774 | 0.318 | 0.500 | 0.442 | 0 | 0.743 | 1.49 | 0.826 |
| NO | R2B | 3 | 119 | 0.0740 | 0.204 | 0.500 | 0.442 | 0 | 0.702 | 1.40 | 1.18 |
| NO | R2B | 4 | 78.0 | 0.0555 | 0.187 | 0.500 | 0.442 | 0 | 0.695 | 1.39 | 1.78 |
| NO | R2B | 5 | 37.0 | 0.145 | 0.234 | 0.500 | 0.442 | 0 | 0.722 | 1.44 | 3.90 |
| NO | R3 | 1 | 0 | 0.0437 | 0.841 | 0.500 | 0.442 | 0 | 1.07 | 2.15 | — |
| NO | R3 | 2 | 179 | 0.135 | 0.860 | 0.500 | 0.442 | 0 | 1.10 | 2.19 | 1.23 |
| NO | R3 | 3 | 119 | 0.650 | 0.555 | 0.500 | 0.442 | 0 | 1.08 | 2.17 | 1.82 |
| NO | R3 | 4 | 80.0 | 0.0608 | 0.505 | 0.500 | 0.442 | 0 | 0.839 | 1.68 | 2.10 |
| NO | R3 | 5 | 41.0 | 0.0715 | 0.617 | 0.500 | 0.442 | 0 | 0.912 | 1.82 | 4.45 |
| NO2 | R2C | 1 | 0 | 0.193 | 0.465 | 0.500 | 0.358 | 0 | 0.795 | 1.59 | — |
| NO2 | R2C | 2 | 140 | 0.119 | 0.481 | 0.500 | 0.358 | 1.51 | 1.70 | 3.40 | 2.43 |
| NO2 | R2C | 3 | 105 | 0.0503 | 0.351 | 0.500 | 0.358 | 1.13 | 1.33 | 2.67 | 2.54 |
| NO2 | R2C | 4 | 60.0 | 0.0498 | 0.287 | 0.500 | 0.358 | 0.646 | 0.938 | 1.88 | 3.13 |
| NO2 | R2C | 5 | 30.0 | 0.0493 | 0.351 | 0.500 | 0.358 | 0.323 | 0.780 | 1.56 | 5.20 |
| NO2 | R3 | 1 | 0 | 0.0352 | 0.699 | 0.500 | 0.358 | 0 | 0.932 | 1.86 | — |
| NO2 | R3 | 2 | 144 | 0.0663 | 0.766 | 0.500 | 0.358 | 1.55 | 1.84 | 3.67 | 2.55 |
| NO2 | R3 | 3 | 112 | 0.0401 | 0.548 | 0.500 | 0.358 | 1.21 | 1.46 | 2.92 | 2.61 |
| NO2 | R3 | 4 | 64.0 | 0.0963 | 0.392 | 0.500 | 0.358 | 0.689 | 1.01 | 2.02 | 3.15 |
| NO2 | R3 | 5 | 32.0 | 0.0695 | 0.496 | 0.500 | 0.358 | 0.344 | 0.864 | 1.73 | 5.40 |
| O3 | R2A | 1 | 0 | 0.204 | 0.868 | 0.335 | 0.0231 | 0 | 0.953 | 1.91 | — |
| O3 | R2A | 2 | 180 | 0.757 | 1.00 | 0.794 | 0.0231 | 0 | 1.49 | 2.97 | 1.65 |
| O3 | R2A | 3 | 120 | 0.139 | 0.667 | 0.641 | 0.0231 | 0 | 0.936 | 1.87 | 1.56 |
| O3 | R2A | 4 | 80.0 | 0.0441 | 0.523 | 0.539 | 0.0231 | 0 | 0.753 | 1.51 | 1.88 |
| O3 | R2A | 5 | 40.0 | 0.0362 | 0.642 | 0.437 | 0.0231 | 0 | 0.778 | 1.56 | 3.89 |
| O3 | R3 | 1 | 0 | 0.0379 | 0.598 | 0.335 | 0.0231 | 0 | 0.687 | 1.37 | — |
| O3 | R3 | 2 | 180 | 0.108 | 0.621 | 0.794 | 0.0231 | 0 | 1.01 | 2.03 | 1.13 |
| O3 | R3 | 3 | 120 | 0.206 | 0.404 | 0.641 | 0.0231 | 0 | 0.786 | 1.57 | 1.31 |
| O3 | R3 | 4 | 80.0 | 0.0933 | 0.361 | 0.539 | 0.0231 | 0 | 0.656 | 1.31 | 1.64 |
| O3 | R3 | 5 | 40.0 | 0.0471 | 0.443 | 0.437 | 0.0231 | 0 | 0.624 | 1.25 | 3.12 |
| SO2 | R1 | 1 | 0 | 0.0103 | 0.330 | 0.500 | 0.0358 | 0 | 0.600 | 1.20 | — |
| SO2 | R1 | 2 | 179 | 0.650 | 0.361 | 0.500 | 0.0358 | 0 | 0.897 | 1.79 | 1.00 |
| SO2 | R1 | 3 | 119 | 0.294 | 0.227 | 0.500 | 0.0358 | 0 | 0.624 | 1.25 | 1.05 |
| SO2 | R1 | 4 | 80.0 | 0.168 | 0.197 | 0.500 | 0.0358 | 0 | 0.564 | 1.13 | 1.41 |
| SO2 | R1 | 5 | 40.0 | 0.107 | 0.241 | 0.500 | 0.0358 | 0 | 0.566 | 1.13 | 2.83 |

*(U rel % no aplica en el nivel cero: el nominal es 0)*

### Componente dominante en el tope de escala

| Gas | Nivel declarado | u_c | U (k=2) | U rel % | Dominante |
|---|---|---|---|---|---|
| CO | 6.3 ppm | 0.0747 | 0.149 | 2.37 | u_patron |
| NO | 180 ppb | 0.743 | 1.49 | 0.826 | u_patron |
| NO2 | 144 ppb | 1.84 | 3.67 | 2.55 | u_conv |
| O3 | 180 ppb | 1.49 | 2.97 | 1.65 | u_curva |
| SO2 | 179 ppb | 0.897 | 1.79 | 1.00 | u_rep |

La curva de calibración solo domina el presupuesto en O3. En NO, NOx y CO manda la incertidumbre del patrón; en NO2 la eficiencia de conversión GPT; en SO2 la repetibilidad. Es decir: reducir la contribución de la curva solo mejora de forma apreciable el resultado de O3.

## 9. Alcance y limitaciones

- **Cobertura por ronda:** SO2 y CO solo se midieron en la **ronda 1**; O3, NO y NO2 en la ronda 3. `outputs/u_curva_por_nivel.csv` aplica la combinación únicamente sobre las filas de ronda 3 que existen en el consolidado; para SO2 y CO la tabla de referencia queda disponible para aplicarla a los datos de ronda 1.
- **Vigencia temporal:** las calibraciones son de abril de 2026 y las rondas PT de julio. Se asume que la curva se mantiene válida en ese intervalo; cualquier deriva entre ambas fechas es un componente adicional no incluido aquí.
- **Solo 5 puntos, 3 grados de libertad.** Con $n-2 = 3$, la estimación de $s$ es poco robusta. Un solo punto atípico —como el de 79.8 ppb en O3— domina el resultado.
- **No incluye la incertidumbre del patrón mismo** (calibrador dinámico, cilindro certificado, generador de aire cero). Ese es un componente separado que se suma aparte.
- **CO en ppm.** Los cálculos de CO están en µmol/mol; convertir antes de mezclar con los demás gases en cualquier tabla común.
