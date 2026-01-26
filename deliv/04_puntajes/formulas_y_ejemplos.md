# Fórmulas y Ejemplos - Puntajes PT
# Entregable: 04 - Módulo de Cálculo de Puntajes
# Referencia: ISO 13528:2022, Sección 10

---

## Índice

1. [Puntaje z](#1-puntaje-z)
2. [Puntaje z' (z-prima)](#2-puntaje-z-z-prima)
3. [Puntaje ζ (zeta)]#3-puntaje-ζ-zeta)
4. [Puntaje En](#4-puntaje-en)
5. [Ejemplos de Cálculo](#5-ejemplos-de-cálculo)

---

## 1. Puntaje z

### Fórmula

$$z = \frac{x - x_{pt}}{\sigma_{pt}}$$

Donde:
- $x$: Resultado del participante
- $x_{pt}$: Valor asignado
- $\sigma_{pt}$: Desviación estándar para evaluación de aptitud

### Criterios de Evaluación

| |z| | Evaluación |
|----|-----------|
| |z| ≤ 2 | Satisfactorio |
| 2 < |z| < 3 | Cuestionable |
| |z| ≥ 3 | No satisfactorio |

### Ejemplo

Usando datos de `summary_n4.csv` para CO nivel 2-μmol/mol:

- Resultado del participante: $x = 2.01215 \, \mu mol/mol$
- Valor asignado (Algoritmo A): $x_{pt} = 2.0135 \, \mu mol/mol$
- Sigma_pt (Algoritmo A): $\sigma_{pt} = 0.06 \, \mu mol/mol$

$$z = \frac{2.01215 - 2.0135}{0.06} = -0.0225$$

$$|z| = 0.0225 \leq 2 \Rightarrow \text{Satisfactorio}$$

---

## 2. Puntaje z' (z-prima)

### Fórmula

$$z' = \frac{x - x_{pt}}{\sqrt{\sigma_{pt}^2 + u_{xpt}^2}}$$

Donde:
- $x$: Resultado del participante
- $x_{pt}$: Valor asignado
- $\sigma_{pt}$: Desviación estándar para evaluación de aptitud
- $u_{xpt}$: Incertidumbre estándar del valor asignado

### Criterios de Evaluación

Igual que puntaje z:
- |z'| ≤ 2: Satisfactorio
- 2 < |z'| < 3: Cuestionable
- |z'| ≥ 3: No satisfactorio

### Ejemplo

Usando los mismos datos con incertidumbre del valor asignado:

- $x = 2.01215 \, \mu mol/mol$
- $x_{pt} = 2.0135 \, \mu mol/mol$
- $\sigma_{pt} = 0.06 \, \mu mol/mol$
- $u_{xpt} = 0.01 \, \mu mol/mol$

$$\sigma_{efectivo} = \sqrt{0.06^2 + 0.01^2} = 0.06083$$

$$z' = \frac{2.01215 - 2.0135}{0.06083} = -0.0222$$

$$|z'| = 0.0222 \leq 2 \Rightarrow \text{Satisfactorio}$$

---

## 3. Puntaje ζ (zeta)

### Fórmula

$$\zeta = \frac{x - x_{pt}}{\sqrt{u_x^2 + u_{xpt}^2}}$$

Donde:
- $x$: Resultado del participante
- $x_{pt}$: Valor asignado
- $u_x$: Incertidumbre estándar del resultado del participante
- $u_{xpt}$: Incertidumbre estándar del valor asignado

### Criterios de Evaluación

Igual que puntaje z:
- |ζ| ≤ 2: Satisfactorio
- 2 < |ζ| < 3: Cuestionable
- |ζ| ≥ 3: No satisfactorio

### Ejemplo

Usando datos con incertidumbres del participante y valor asignado:

- $x = 2.01215 \, \mu mol/mol$
- $x_{pt} = 2.0135 \, \mu mol/mol$
- $u_x = 0.02 \, \mu mol/mol$ (incertidumbre del participante)
- $u_{xpt} = 0.01 \, \mu mol/mol$

$$\sigma_{efectivo} = \sqrt{0.02^2 + 0.01^2} = 0.02236$$

$$\zeta = \frac{2.01215 - 2.0135}{0.02236} = -0.0604$$

$$|\zeta| = 0.0604 \leq 2 \Rightarrow \text{Satisfactorio}$$

---

## 4. Puntaje En

### Fórmula

$$E_n = \frac{x - x_{pt}}{\sqrt{U_x^2 + U_{xpt}^2}}$$

Donde:
- $x$: Resultado del participante
- $x_{pt}$: Valor asignado
- $U_x$: Incertidumbre expandida del resultado del participante (k=2)
- $U_{xpt}$: Incertidumbre expandida del valor asignado (k=2)

### Criterios de Evaluación

| |En| | Evaluación |
|----|-----------|
| |En| ≤ 1 | Satisfactorio |
| |En| > 1 | No satisfactorio |

### Ejemplo

Usando datos con incertidumbres expandidas:

- $x = 2.01215 \, \mu mol/mol$
- $x_{pt} = 2.0135 \, \mu mol/mol$
- $U_x = 0.04 \, \mu mol/mol$ (incertidumbre expandida k=2 del participante)
- $U_{xpt} = 0.02 \, \mu mol/mol$

$$U_{efectivo} = \sqrt{0.04^2 + 0.02^2} = 0.04472$$

$$E_n = \frac{2.01215 - 2.0135}{0.04472} = -0.0302$$

$$|E_n| = 0.0302 \leq 1 \Rightarrow \text{Satisfactorio}$$

---

## 5. Ejemplos de Cálculo

### Escenario 1: Participante Satisfactorio (Puntaje z)

Datos de part_1 para CO nivel 2-μmol/mol:

| Parámetro | Valor | Unidad |
|-----------|-------|--------|
| x (resultado participante) | 2.01215 | μmol/mol |
| x_pt (valor asignado) | 2.0135 | μmol/mol |
| σ_pt | 0.06 | μmol/mol |

**Cálculo:**
$$z = \frac{2.01215 - 2.0135}{0.06} = -0.0225$$

**Evaluación:**
$$|z| = 0.0225 \leq 2 \Rightarrow \textbf{Satisfactorio}$$

---

### Escenario 2: Participante Cuestionable (Puntaje z)

Datos de un participante con desviación moderada:

| Parámetro | Valor | Unidad |
|-----------|-------|--------|
| x | 2.15 | μmol/mol |
| x_pt | 2.0135 | μmol/mol |
| σ_pt | 0.06 | μmol/mol |

**Cálculo:**
$$z = \frac{2.15 - 2.0135}{0.06} = 2.275$$

**Evaluación:**
$$2 < |z| = 2.275 < 3 \Rightarrow \textbf{Cuestionable}$$

---

### Escenario 3: Participante No Satisfactorio (Puntaje z)

Datos de un participante con desviación grande:

| Parámetro | Valor | Unidad |
|-----------|-------|--------|
| x | 2.25 | μmol/mol |
| x_pt | 2.0135 | μmol/mol |
| σ_pt | 0.06 | μmol/mol |

**Cálculo:**
$$z = \frac{2.25 - 2.0135}{0.06} = 3.942$$

**Evaluación:**
$$|z| = 3.942 \geq 3 \Rightarrow \textbf{No satisfactorio}$$

---

### Escenario 4: Comparación entre Puntajes z, z', ζ, En

Para el mismo participante con diferentes tipos de incertidumbre:

| Parámetro | Valor | Unidad |
|-----------|-------|--------|
| x | 2.18 | μmol/mol |
| x_pt | 2.0135 | μmol/mol |
| σ_pt | 0.06 | μmol/mol |
| u_xpt | 0.01 | μmol/mol |
| u_x | 0.02 | μmol/mol |
| U_x | 0.04 | μmol/mol |
| U_xpt | 0.02 | μmol/mol |

**Puntaje z:**
$$z = \frac{2.18 - 2.0135}{0.06} = 2.775$$
Evaluación: **Cuestionable** (2 < 2.775 < 3)

**Puntaje z':**
$$z' = \frac{2.18 - 2.0135}{\sqrt{0.06^2 + 0.01^2}} = \frac{0.1665}{0.06083} = 2.737$$
Evaluación: **Cuestionable** (2 < 2.737 < 3)

**Puntaje ζ:**
$$\zeta = \frac{2.18 - 2.0135}{\sqrt{0.02^2 + 0.01^2}} = \frac{0.1665}{0.02236} = 7.447$$
Evaluación: **No satisfactorio** (|ζ| = 7.447 ≥ 3)

**Puntaje En:**
$$E_n = \frac{2.18 - 2.0135}{\sqrt{0.04^2 + 0.02^2}} = \frac{0.1665}{0.04472} = 3.723$$
Evaluación: **No satisfactorio** (|En| = 3.723 > 1)

**Observación:** Cuando el participante reporta incertidumbre (u_x, U_x) relativamente grande comparada con σ_pt, los puntajes ζ y En pueden ser más severos que z y z'.

---

## Uso de las Funciones

```r
# Cargar todas las funciones
source("../R/calcula_puntajes.R")
source("../R/crea_reporte.R")

# Cargar datos
summary_data <- read.csv("../../data/summary_n4.csv")

# Calcular valor asignado y sigma_pt (usando funciones del entregable 03)
source("../../deliv/03_calculos_pt/R/valor_asignado.R")
source("../../deliv/03_calculos_pt/R/sigma_pt.R")

va_dict <- calcular_valor_asignado_todos(summary_data, metodo = "algoritmo_a")
sigma_dict <- calcular_sigma_pt_todos(summary_data, metodo = "algoritmo_a")

# Calcular puntajes para todos los participantes
puntajes <- calcular_puntajes_todos(
  datos_participantes = summary_data,
  valor_asignado_dict = lapply(va_dict, function(r) r$valor_asignado),
  sigma_pt_dict = lapply(sigma_dict, function(r) r$sigma_pt)
)

# Ver resultados
head(puntajes[, c("participant_id", "pollutant", "level", "x", "z", "evaluacion_z")])

# Generar reporte completo
reporte <- generar_reporte_pt(
  datos_participantes = summary_data,
  metodo_valor_asignado = "algoritmo_a",
  metodo_sigma_pt = "algoritmo_a",
  directorio_salida = "../output"
)

print(reporte$estadisticas_globales$estadisticas)
```

---

## Salida de Reporte

### Archivo: puntajes_completos.csv

| pollutant | run | level | participant_id | x | x_pt | z | evaluacion_z | z_prima | evaluacion_z_prima | zeta | evaluacion_zeta | en | evaluacion_en |
|-----------|-----|-------|----------------|---|------|---|--------------|----------|-------------------|-------|----------------|----|--------------|
| co | corrida_1 | 0-μmol/mol | part_1 | -0.02798 | -0.02169 | -0.105 | Satisfactorio | NA | N/A | NA | N/A | NA | N/A |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

### Archivo: resumen_participantes.csv

| participant_id | total_observaciones | n_satisfactorio_z | n_cuestionable_z | n_no_satisfactorio_z | n_satisfactorio_en | n_no_satisfactorio_en |
|---------------|-------------------|-------------------|-----------------|---------------------|-------------------|---------------------|
| part_1 | 36 | 35 | 1 | 0 | 35 | 1 |
| part_2 | 36 | 34 | 2 | 0 | 33 | 3 |
| ref | 36 | 36 | 0 | 0 | 36 | 0 |

### Archivo: estadisticas_globales.csv

| tipo_puntaje | metrica | valor |
|--------------|----------|-------|
| z | n | 108 |
| z | media | -0.023 |
| z | sd | 0.156 |
| z | max_abs | 0.876 |
| z | % satisfactorio | 95.4 |
| z | % cuestionable | 4.6 |
| z | % no satisfactorio | 0.0 |
| En | % satisfactorio | 95.4 |
| En | % no satisfactorio | 4.6 |

---

## Referencias

- ISO 13528:2022 - Statistical methods for use in proficiency testing by interlaboratory comparison
  - Sección 10.2: z-scores
  - Sección 10.3: z'-scores (z-prime)
  - Sección 10.4: zeta-scores
  - Sección 10.5: En-scores

---

*Documento generado para el Entregable 04 - Módulo de Cálculo de Puntajes*
