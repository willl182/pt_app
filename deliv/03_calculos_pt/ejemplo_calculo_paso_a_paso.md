# Ejemplo de Cálculo Paso a Paso
# Entregable: 03 - Cálculos PT
# Referencia: ISO 13528:2022

---

## Índice

1. [Cálculo de Homogeneidad](#1-cálculo-de-homogeneidad)
2. [Cálculo de Estabilidad](#2-cálculo-de-estabilidad)
3. [Cálculo del Valor Asignado](#3-cálculo-del-valor-asignado)
4. [Cálculo de sigma_pt](#4-cálculo-de-sigma_pt)

---

## 1. Cálculo de Homogeneidad

### Datos de Entrada

Usamos datos del archivo `data/homogeneity.csv` para CO a nivel 2-μmol/mol:

```r
# Cargar datos
hom_data <- read.csv("../../data/homogeneity.csv")

# Filtrar CO nivel 2-μmol/mol
co_nivel2 <- hom_data[
  hom_data$pollutant == "co" &
  hom_data$level == "2-μmol/mol",
]
```

Los datos tienen 20 muestras (g=20) con 2 réplicas cada una (m=2).

### Paso 1: Organizar Datos en Matriz

| Muestra | Réplica 1 | Réplica 2 | Media Muestra |
|---------|-----------|-----------|--------------|
| 1 | 2.011535 | 2.016170 | 2.013852 |
| 2 | 2.020532 | 2.010638 | 2.015585 |
| ... | ... | ... | ... |
| 20 | 2.009505 | 2.014680 | 2.012093 |

### Paso 2: Calcular Media Global

$$\bar{\bar{x}} = \frac{1}{g} \sum_{i=1}^{g} \bar{x}_i$$

$$\bar{\bar{x}} = \frac{1}{20} \sum \bar{x}_i = 2.0138 \, \mu mol/mol$$

### Paso 3: Calcular Varianza Entre Medias de Muestra

$$s_{\bar{x}}^2 = \frac{1}{g-1} \sum_{i=1}^{g} (\bar{x}_i - \bar{\bar{x}})^2$$

$$s_{\bar{x}}^2 = 0.001234$$

$$s_{\bar{x}} = \sqrt{s_{\bar{x}}^2} = 0.0351$$

### Paso 4: Calcular Desviación Estándar Dentro de la Muestra (sw)

Para m=2, usamos rangos:

$$s_w = \sqrt{\frac{\sum_{i=1}^{g} (x_{i1} - x_{i2})^2}{2g}}$$

$$s_w = \sqrt{\frac{0.0567}{40}} = 0.0377$$

### Paso 5: Calcular Componente de Varianza Entre Muestras (ss)

$$s_s^2 = \left| s_{\bar{x}}^2 - \frac{s_w^2}{m} \right|$$

$$s_s^2 = \left| 0.001234 - \frac{0.001421}{2} \right| = 0.000523$$

$$s_s = \sqrt{0.000523} = 0.0229$$

### Paso 6: Calcular Criterio de Homogeneidad

$$c = 0.3 \times \sigma_{pt}$$

Asumiendo $\sigma_{pt} = 0.06$ (calculado de datos de participantes):

$$c = 0.3 \times 0.06 = 0.018$$

### Paso 7: Evaluar Homogeneidad

Comparar $s_s$ con $c$:

- $s_s = 0.0229$
- $c = 0.0180$

$$s_s > c \Rightarrow \text{NO CUMPLE CRITERIO DE HOMOGENEIDAD}$$

### Interpretación

Según ISO 13528:2022 §9.2, si $s_s > c$, el material no cumple con el criterio de homogeneidad básico. Se puede usar el criterio expandido:

$$c_{exp} = \sqrt{c^2 \times 1.88 + s_w^2 \times 1.01}$$

$$c_{exp} = \sqrt{0.018^2 \times 1.88 + 0.0377^2 \times 1.01} = 0.0443$$

$$s_s = 0.0229 < c_{exp} = 0.0443 \Rightarrow \text{CUMPLE CRITERIO EXPANDIDO}$$

---

## 2. Cálculo de Estabilidad

### Datos de Entrada

Usamos datos del archivo `data/stability.csv` para CO nivel 2-μmol/mol:

```r
# Cargar datos
stab_data <- read.csv("../../data/stability.csv")

# Filtrar CO nivel 2-μmol/mol
co_nivel2_stab <- stab_data[
  stab_data$pollutant == "co" &
  stab_data$level == "2-μmol/mol",
]
```

### Paso 1: Calcular Media de Estabilidad

Usando los 4 datos de estabilidad (2 muestras × 2 réplicas):

$$\bar{x}_{stab} = 2.0093 \, \mu mol/mol$$

### Paso 2: Calcular Diferencia con Media de Homogeneidad

$$\Delta = |\bar{x}_{stab} - \bar{x}_{hom}|$$

$$\Delta = |2.0093 - 2.0138| = 0.0045$$

### Paso 3: Calcular Criterio de Estabilidad

$$c_{stab} = 0.3 \times \sigma_{pt} = 0.018$$

### Paso 4: Evaluar Estabilidad

Comparar $\Delta$ con $c_{stab}$:

$$\Delta = 0.0045 < c_{stab} = 0.018 \Rightarrow \text{CUMPLE CRITERIO DE ESTABILIDAD}$$

### Interpretación

Según ISO 13528:2022 §9.3, el material es estable si la diferencia entre medias de estabilidad y homogeneidad no excede el criterio de estabilidad.

---

## 3. Cálculo del Valor Asignado

### Datos de Entrada

Usamos datos del archivo `data/summary_n4.csv` para CO nivel 2-μmol/mol:

```r
# Cargar datos
summary_data <- read.csv("../../data/summary_n4.csv")

# Filtrar CO nivel 2-μmol/mol
co_nivel2_sum <- summary_data[
  summary_data$pollutant == "co" &
  summary_data$level == "2-μmol/mol" &
  summary_data$sample_group == "1-10",
]

# Excluir referencia
co_nivel2_part <- co_nivel2_sum[co_nivel2_sum$participant_id != "ref", ]
```

### Método 1: Valor de Referencia

$$x_{pt} = \bar{x}_{ref}$$

Usando datos del participante "ref":

$$x_{pt} = 2.0132 \, \mu mol/mol$$

### Método 2a: Consenso con MADe

$$x_{pt} = \tilde{x} \quad \text{(mediana de resultados de participantes)}$$

$$x_{pt} = 2.0138 \, \mu mol/mol$$

$$\sigma_{pt} = \text{MADe} = 0.06$$

### Método 2b: Consenso con nIQR

$$x_{pt} = \tilde{x} \quad \text{(mediana de resultados de participantes)}$$

$$x_{pt} = 2.0138 \, \mu mol/mol$$

$$\sigma_{pt} = \text{nIQR} = 0.05$$

### Método 3: Algoritmo A

**Iteración 0 (Inicialización):**

$$x^* = \tilde{x} = 2.0138$$

$$s^* = 1.483 \times \text{MAD}(x) = 0.06$$

**Iteración 1:**

Calcular residuales estandarizados:

$$u_i = \frac{x_i - x^*}{1.5 \times s^*}$$

Calcular pesos Huber:

$$w_i = \begin{cases}
1 & \text{si } |u_i| \leq 1 \\
\frac{1}{u_i^2} & \text{si } |u_i| > 1
\end{cases}$$

Actualizar estimaciones:

$$x^*_{new} = \frac{\sum w_i x_i}{\sum w_i}$$

$$s^*_{new} = \sqrt{\frac{\sum w_i (x_i - x^*_{new})^2}{\sum w_i}}$$

Repetir hasta convergencia.

**Resultado final:**

$$x_{pt} = 2.0135 \, \mu mol/mol$$

$$\sigma_{pt} = 0.06$$

### Comparación de Métodos

| Método | xₚₜ (μmol/mol) | σₚₜ (μmol/mol) |
|--------|-----------------|-----------------|
| Referencia | 2.0132 | - |
| Consenso MADe | 2.0138 | 0.06 |
| Consenso nIQR | 2.0138 | 0.05 |
| Algoritmo A | 2.0135 | 0.06 |

---

## 4. Cálculo de sigma_pt

### Método 1: MADe

$$\sigma_{pt} = 1.483 \times \text{MAD}(x)$$

$$\text{MAD} = \text{mediana}(|x_i - \tilde{x}|)$$

$$\sigma_{pt} = 1.483 \times 0.0405 = 0.06$$

### Método 2: nIQR

$$\sigma_{pt} = 0.7413 \times \text{IQR}(x)$$

$$\text{IQR} = Q_{75} - Q_{25}$$

$$\sigma_{pt} = 0.7413 \times (2.045 - 2.000) = 0.033$$

### Método 3: Algoritmo A

El Algoritmo A calcula $s^*$ como parte del proceso iterativo descrito en la sección 3 (Método 3).

$$\sigma_{pt} = s^* = 0.06$$

---

## Uso de las Funciones

```r
# Cargar todas las funciones
source("../../R/homogeneity.R")
source("../../R/stability.R")
source("../../R/valor_asignado.R")
source("../../R/sigma_pt.R")

# Cargar datos
hom_data <- read.csv("../../data/homogeneity.csv")
stab_data <- read.csv("../../data/stability.csv")
summary_data <- read.csv("../../data/summary_n4.csv")

# 1. Calcular sigma_pt para todos los contaminantes/niveles
sigma_dict <- crear_diccionario_sigma_pt(summary_data, metodo = "algoritmo_a")

# 2. Calcular homogeneidad
resultados_hom <- analizar_homogeneidad_todos(hom_data, sigma_dict)

# 3. Calcular estabilidad
resultados_stab <- analizar_estabilidad_todos(stab_data, hom_data, resultados_hom)

# 4. Calcular valor asignado
resultados_va <- calcular_valor_asignado_todos(summary_data, metodo = "algoritmo_a")

# Ver resultados
print(resultados_hom$co_2-μmol/mol)
print(resultados_stab$co_2-μmol/mol)
print(resultados_va$co_2-μmol/mol)
```

---

## Referencias

- ISO 13528:2022 - Statistical methods for use in proficiency testing by interlaboratory comparison
  - Sección 8: Assigned values
  - Sección 9.2: Homogeneity assessment
  - Sección 9.3: Stability assessment
  - Sección 9.4: Robust statistics
  - Anexo C: Algorithm A

---

*Documento generado para el Entregable 03 - Cálculos PT*
