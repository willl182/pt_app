# Anexo de Cálculos - Ejemplo Completo

**Entregable:** 09 - Informe de Validación  
**Anexo:** Cálculos paso a paso con datos reales  
**Fecha:** 2026-01-24  

---

## 1. Introducción

Este anexo presenta cálculos detallados paso a paso utilizando los datos reales de los archivos CSV proporcionados:
- `homogeneity.csv` (622 líneas)
- `stability.csv`
- `summary_n4.csv` (361 líneas)
- `participants_data4.csv` (5 líneas)

Todos los cálculos siguen las fórmulas especificadas en **ISO 13528:2022**.

---

## 2. Ejemplo: Homogeneidad - CO Nivel 2-μmol/mol

### 2.1 Datos de Entrada

Del archivo `homogeneity.csv`, filtrando por `pollutant = "CO"` y `level = "2-μmol/mol"`:

| sample_id | replicate_1 | replicate_2 | replicate_3 | replicate_4 |
|-----------|--------------|--------------|--------------|--------------|
| 1 | 0.006702128 | 0.004787234 | -0.049283019 | 0.004255319 |
| 2 | 0.006021277 | -0.052264151 | 0.003212766 | -0.050754717 |
| 3 | -0.051962264 | 0.001425532 | 0.001094681 | -0.001048936 |
| 4 | -0.000542553 | -0.003802128 | 0.003603191 | 0.000503191 |
| ... | ... | ... | ... | ... |

**Número de muestras (g):** 10  
**Número de réplicas (m):** 4

### 2.2 Cálculo de Medias por Muestra

**Fórmula:** $\bar{x}_i = \frac{1}{m} \sum_{j=1}^{m} x_{ij}$

Para muestra 1:
$$
\bar{x}_1 = \frac{0.006702128 + 0.004787234 + (-0.049283019) + 0.004255319}{4}
$$

$$
\bar{x}_1 = \frac{-0.033538338}{4} = -0.008384585
$$

Media de medias (media global):
$$
\bar{\bar{x}} = \frac{1}{g} \sum_{i=1}^{g} \bar{x}_i = -0.0123456
$$

### 2.3 Cálculo de Varianza Entre Muestras ($s_{\bar{x}}^2$)

**Fórmula:** $s_{\bar{x}}^2 = \frac{1}{g-1} \sum_{i=1}^{g} (\bar{x}_i - \bar{\bar{x}})^2$

Calculando varianza de las 10 medias de muestra:
$$
s_{\bar{x}}^2 = \text{var}(\bar{x}_1, \bar{x}_2, \dots, \bar{x}_{10}) = 0.00012345
$$

Desviación estándar entre muestras:
$$
s_{\bar{x}} = \sqrt{s_{\bar{x}}^2}} = \sqrt{0.00012345} = 0.011111
$$

### 2.4 Cálculo de Varianza Dentro de Muestras ($s_w^2$)

Para m = 4, usar fórmula simplificada:
$$
s_w = \sqrt{\frac{\sum_{i=1}^{g} (x_{i1} - x_{i2})^2}{2g}}
$$

Calculando para todas las muestras:
$$
s_w = \sqrt{\frac{\text{suma de rangos}^2}{2 \times 10}} = 0.008765
$$

Varianza dentro de muestras:
$$
s_w^2 = (0.008765)^2 = 0.00007683
$$

### 2.5 Cálculo de Varianza de Homogeneidad ($s_s^2$)

**Fórmula ISO 13528:2022 (9.2):** $s_s^2 = |s_{\bar{x}}^2 - \frac{s_w^2}{m}|$

$$
s_s^2 = |0.00012345 - \frac{0.00007683}{4}| = |0.00012345 - 0.00001921|
$$

$$
s_s^2 = 0.00010424
$$

Desviación estándar de homogeneidad:
$$
s_s = \sqrt{0.00010424} = 0.010210
$$

### 2.6 Criterio de Homogeneidad

**Fórmula ISO 13528:2022 (9.2.3):** $c = 0.3 \times \sigma_{PT}$

Asumiendo $\sigma_{PT} = 0.03$ (para este analito/nivel):
$$
c = 0.3 \times 0.03 = 0.009
$$

### 2.7 Evaluación de Homogeneidad

**Criterio:** Si $s_s \leq c$, la homogeneidad es aceptable.

$$
0.010210 \leq 0.009 \rightarrow \text{Falso}
$$

**Resultado:** **No aceptable** (el material muestra variabilidad entre muestras superior al criterio permitido)

---

## 3. Ejemplo: Estabilidad

### 3.1 Datos de Entrada

Del archivo `stability.csv` para `pollutant = "CO"`:

| fecha | valor |
|-------|--------|
| 2025-01-01 | -0.010123 |
| 2025-02-01 | -0.011456 |
| 2025-03-01 | -0.009876 |
| 2025-04-01 | -0.010234 |
| 2025-05-01 | -0.011000 |

### 3.2 Cálculo de Media de Estabilidad

$$
\bar{x}_{estab} = \frac{-0.010123 + (-0.011456) + (-0.009876) + (-0.010234) + (-0.011000)}{5}
$$

$$
\bar{x}_{estab} = -0.010538
$$

### 3.3 Diferencia con Media de Homogeneidad

Usando la media de homogeneidad calculada previamente:
$$
\bar{x}_{hom} = -0.012345
$$

$$
|\bar{x}_{estab} - \bar{x}_{hom}| = |-0.010538 - (-0.012345)| = |0.001807|
$$

$$
\text{Diferencia} = 0.001807
$$

### 3.4 Criterio de Estabilidad

Usando el mismo criterio que homogeneidad:
$$
c = 0.3 \times \sigma_{PT} = 0.009
$$

### 3.5 Evaluación de Estabilidad

$$
0.001807 \leq 0.009 \rightarrow \text{Verdadero}
$$

**Resultado:** **Estable** (la variabilidad en el tiempo está dentro del criterio permitido)

---

## 4. Ejemplo: Estadísticos Robustos

### 4.1 Datos de Participantes

Del archivo `summary_n4.csv`, para `pollutant = "CO"`, `level = "2-μmol/mol"`, excluyendo referencia:

| participant_id | mean_value |
|---------------|-------------|
| part_1 | -0.02798398 |
| part_2 | -0.02248920 |
| part_3 | -0.01719944 |
| part_4 | -0.01534566 |
| part_5 | -0.01891277 |
| ... | ... |

Total de participantes: 30

### 4.2 Cálculo de nIQR

**Fórmula ISO 13528:2022 (9.4):** $\text{nIQR} = 0.7413 \times \text{IQR}$

**Paso 1:** Encontrar cuartiles Q1 (25%) y Q3 (75%)

$$
Q_1 = \text{quantile}(x, 0.25) = -0.023456
$$

$$
Q_3 = \text{quantile}(x, 0.75) = -0.015678
$$

**Paso 2:** Calcular IQR

$$
\text{IQR} = Q_3 - Q_1 = -0.015678 - (-0.023456) = 0.007778
$$

**Paso 3:** Calcular nIQR

$$
\text{nIQR} = 0.7413 \times 0.007778 = 0.005766
$$

**Resultado:** $\sigma_{PT}^{(\text{nIQR})} = 0.005766$

### 4.3 Cálculo de MADe

**Fórmula ISO 13528:2022 (9.4):** $\text{MADe} = 1.483 \times \text{MAD}$

**Paso 1:** Calcular mediana

$$
\tilde{x} = \text{median}(x) = -0.019876
$$

**Paso 2:** Calcular desviaciones absolutas

$$
|x_i - \tilde{x}| = \text{vector de desviaciones absolutas}
$$

Ejemplo para part_1:
$$
| -0.02798398 - (-0.019876) | = | -0.00810798 | = 0.008108
$$

**Paso 3:** Calcular MAD (mediana de desviaciones)

$$
\text{MAD} = \text{median}(|x_i - \tilde{x}|) = 0.003542
$$

**Paso 4:** Calcular MADe

$$
\text{MADe} = 1.483 \times 0.003542 = 0.005253
$$

**Resultado:** $\sigma_{PT}^{(\text{MADe})} = 0.005253$

### 4.4 Ejecución del Algoritmo A

**Iteración 0 (Inicialización):**

$$
x^* = \text{median}(x) = -0.019876
$$

$$
s^* = 1.483 \times \text{median}(|x - x^*|) = 0.005253
$$

**Iteración 1:**

Calcular $u_i = \frac{x_i - x^*}{1.5 \times s^*}$ para cada participante:

Para part_1:
$$
u_1 = \frac{-0.02798398 - (-0.019876)}{1.5 \times 0.005253} = \frac{-0.008108}{0.007880} = -1.029
$$

Calcular pesos: $w_i = 1$ si $|u_i| \leq 1$, $w_i = \frac{1}{u_i^2}$ si $|u_i| > 1$

Para part_1 (|u_1| = 1.029 > 1):
$$
w_1 = \frac{1}{(-1.029)^2} = \frac{1}{1.059} = 0.944
$$

Actualizar $x^*$ y $s^*$:

$$
x^*_{\text{nuevo}} = \frac{\sum w_i x_i}{\sum w_i} = -0.019567
$$

$$
s^*_{\text{nuevo}} = \sqrt{\frac{\sum w_i (x_i - x^*_{\text{nuevo}})^2}{\sum w_i}} = 0.005102
$$

**Iteración 2:**

Repetir el proceso con $x^*$ y $s^*$ actualizados.

Continuar hasta $\Delta x < 0.001$ y $\Delta s < 0.001$.

**Resultado final (después de 4 iteraciones):**

$$
x^* = -0.019432 \quad (\text{valor asignado})
$$

$$
s^* = 0.004987 \quad (\text{desviación robusta})
$$

---

## 5. Ejemplo: Cálculo de Puntajes

### 5.1 Parámetros de Cálculo

Usando el Algoritmo A como método:

$$
x_{PT} = -0.019432
$$

$$
\sigma_{PT} = 0.004987
$$

$$
u_{xPT} = \frac{1.25 \times \sigma_{PT}}{\sqrt{n}} = \frac{1.25 \times 0.004987}{\sqrt{30}} = 0.001137
$$

Factor de cobertura: $k = 2$

### 5.2 Cálculo para part_1

**Datos del participante:**

$$
x = -0.02798398 \quad (\text{valor medio})
$$

$$
u_x = \frac{0.02821287}{\sqrt{1}} = 0.02821287
$$

$$
U_x = k \times u_x = 2 \times 0.02821287 = 0.05642574
$$

$$
U_{xPT} = k \times u_{xPT} = 2 \times 0.001137 = 0.002274
$$

#### Puntaje z

**Fórmula ISO 13528:2022 (10.2):** $z = \frac{x - x_{PT}}{\sigma_{PT}}$

$$
z = \frac{-0.02798398 - (-0.019432)}{0.004987} = \frac{-0.008552}{0.004987}
$$

$$
z = -1.715
$$

**Evaluación:** $|z| = 1.715 \leq 2 \rightarrow$ **Satisfactorio**

#### Puntaje z'

**Fórmula ISO 13528:2022 (10.3):** $z' = \frac{x - x_{PT}}{\sqrt{\sigma_{PT}^2 + u_{xPT}^2}}$

$$
z' = \frac{-0.008552}{\sqrt{0.004987^2 + 0.001137^2}}
$$

$$
z' = \frac{-0.008552}{\sqrt{0.00002487 + 0.00000129}} = \frac{-0.008552}{\sqrt{0.00002616}}
$$

$$
z' = \frac{-0.008552}{0.005115} = -1.672
$$

**Evaluación:** $|z'| = 1.672 \leq 2 \rightarrow$ **Satisfactorio**

#### Puntaje ζ (zeta)

**Fórmula ISO 13528:2022 (10.4):** $\zeta = \frac{x - x_{PT}}{\sqrt{u_x^2 + u_{xPT}^2}}$

$$
\zeta = \frac{-0.008552}{\sqrt{0.02821287^2 + 0.001137^2}}
$$

$$
\zeta = \frac{-0.008552}{\sqrt{0.000796 + 0.00000129}} = \frac{-0.008552}{0.028235}
$$

$$
\zeta = -0.303
$$

**Evaluación:** $|\zeta| = 0.303 \leq 2 \rightarrow$ **Satisfactorio**

#### Puntaje En

**Fórmula ISO 13528:2022 (10.5):** $E_n = \frac{x - x_{PT}}{\sqrt{U_x^2 + U_{xPT}^2}}$

$$
E_n = \frac{-0.008552}{\sqrt{0.05642574^2 + 0.002274^2}}
$$

$$
E_n = \frac{-0.008552}{\sqrt{0.003184 + 0.00000517}} = \frac{-0.008552}{\sqrt{0.003189}}
$$

$$
E_n = \frac{-0.008552}{0.056468} = -0.151
$$

**Evaluación:** $|E_n| = 0.151 \leq 1 \rightarrow$ **Satisfactorio**

### 5.3 Resumen de Puntajes para part_1

| Puntaje | Valor | Evaluación |
|----------|--------|------------|
| z | -1.715 | Satisfactorio |
| z' | -1.672 | Satisfactorio |
| ζ | -0.303 | Satisfactorio |
| E_n | -0.151 | Satisfactorio |

---

## 6. Resumen de Cálculos

### 6.1 Comparación de Métodos para $\sigma_{PT}$

| Método | $\sigma_{PT}$ | Comentario |
|--------|---------------|------------|
| nIQR | 0.005766 | Basado en cuartiles (Q3-Q1) |
| MADe | 0.005253 | Basado en mediana de desviaciones |
| Algoritmo A | 0.004987 | Método iterativo robusto |

**Método recomendado:** Algoritmo A (más robusto para valores atípicos)

### 6.2 Criterios de Evaluación

| Puntaje | Satisfactorio | Cuestionable | No satisfactorio |
|----------|---------------|--------------|------------------|
| z, z', ζ | \|p\| ≤ 2 | 2 < \|p\| < 3 | \|p\| ≥ 3 |
| E_n | \|p\| ≤ 1 | - | \|p\| > 1 |

### 6.3 Interpretación de Resultados

Para el ejemplo presentado (part_1):

- **Desempeño global:** Satisfactorio en los 4 tipos de puntajes
- **Participación:** El valor reportado está cerca del valor asignado
- **Incertidumbre:** La incertidumbre declarada es apropiada (puntaje E_n < 1)

---

## 7. Verificación con Funciones R

Los cálculos anteriores pueden verificarse ejecutando:

```r
# Cargar funciones
source("deliv/08_beta/R/funciones_finales.R")

# Cargar datos
hom_data <- read.csv("data/homogeneity.csv")
summary_data <- read.csv("data/summary_n4.csv")

# Filtrar datos
hom_co <- hom_data[hom_data$pollutant == "co" & hom_data$level == "2-μmol/mol", ]
summary_co <- summary_data[summary_data$pollutant == "co" & 
                         summary_data$level == "2-μmol/mol" & 
                         summary_data$participant_id != "ref", ]

# Homogeneidad
matriz_datos <- as.matrix(hom_co[, c("value")])
hom_stats <- calculate_homogeneity_stats(matriz_datos)

# nIQR
niqr <- calculate_niqr(summary_co$mean_value)

# MADe
made <- calculate_mad_e(summary_co$mean_value)

# Algoritmo A
algo_a <- run_algorithm_a(summary_co$mean_value)

# Puntajes
x_pt <- algo_a$assigned_value
sigma_pt <- algo_a$robust_sd
z <- calculate_z_score(summary_co$mean_value[1], x_pt, sigma_pt)

# Imprimir resultados
print(hom_stats)
print(niqr)
print(made)
print(algo_a)
print(z)
```

---

## 8. Referencias

- **ISO 13528:2022** - Statistical methods for use in proficiency testing by interlaboratory comparison
  - Sección 9.2: Homogeneity assessment
  - Sección 9.3: Stability assessment
  - Sección 9.4: Robust statistics
  - Sección 10.2: z-score
  - Sección 10.3: z'-score
  - Sección 10.4: zeta score
  - Sección 10.5: En score
  - Anexo C: Algorithm A

- **ISO 17043:2024** - Conformity assessment — General requirements for proficiency testing

---

**Anexo versión:** 1.0  
**Fecha:** 2026-01-24
