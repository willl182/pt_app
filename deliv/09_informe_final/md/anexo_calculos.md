# Anexo de Cálculos - Deliverable 09

## 1. Ejemplo completo de homogeneidad (CO 2-μmol/mol)

**Referencia normativa:** ISO 13528:2022, Anexo B.3 y B.4.

**Datos (homogeneity.csv, muestra 1):**

- Replicado 1: `2.01153535353535`
- Replicado 2: `2.01946808510638`

**Media de muestra (ISO 13528:2022, B.3):**

\[\bar{x}_1 = \frac{2.01153535353535 + 2.01946808510638}{2} = 2.015501719\]

**Desviación estándar de la muestra:**

\[s_1 = \sqrt{\frac{(2.01153535353535 - 2.015501719)^2 + (2.01946808510638 - 2.015501719)^2}{2-1}} = 0.005609288\]

**Resumen global (10 muestras, 2 replicados):**

- Desviación entre medias: `s_x = 0.002421980`
- Desviación dentro de muestra: `s_w = 0.005014792`
- Número de replicados: `n_r = 2`

**Desviación entre muestras (ISO 13528:2022, B.4):**

\[s_b = \sqrt{\max\left(0, s_x^2 - \frac{s_w^2}{n_r}\right)} = \sqrt{\max(0, 0.002421980^2 - 0.005014792^2/2)} = 0\]

## 2. Ejemplo completo de estabilidad (CO 2-μmol/mol)

**Referencia normativa:** ISO 13528:2022, Anexo B.7.

**Datos (stability.csv):**

- Tiempo 0 (muestra 1): media `2.012180851`
- Tiempo 1 (muestra 2): media `2.006540404`

**Pendiente de regresión simple:**

\[b = \frac{2.006540404 - 2.012180851}{1 - 0} = -0.005640447\]

**Interpretación:** la pendiente es negativa y de baja magnitud frente al valor asignado (≈0.28 %), lo que respalda estabilidad operativa bajo el criterio interno.

## 3. Ejemplo completo de puntajes (CO 2-μmol/mol, grupo 1-10)

**Referencia normativa:** ISO 13528:2022, 10.4–10.6 e ISO 17043:2024.

**Datos (summary_n4.csv):**

- Valor asignado (referencia): `x_pt = 2.013671545`
- Media participante (part_1): `x_i = 2.012150827`
- Desviación PT (participantes): `s_pt = 0.000525431`
- Incertidumbre referencia: `u_x = 0.001290351`
- Incertidumbre participante: `u_i = 0.001137531`

**z-score (ISO 13528:2022, 10.4):**

\[z = \frac{x_i - x_{pt}}{s_{pt}} = \frac{2.012150827 - 2.013671545}{0.000525431} = -2.894230\]

**z' (ISO 13528:2022, 10.5):**

\[z' = \frac{x_i - x_{pt}}{\sqrt{s_{pt}^2 + u_x^2}} = \frac{-0.001520718}{\sqrt{0.000525431^2 + 0.001290351^2}} = -1.091507\]

**ζ (ISO 13528:2022, 10.6):**

\[\zeta = \frac{x_i - x_{pt}}{\sqrt{u_x^2 + u_i^2}} = \frac{-0.001520718}{\sqrt{0.001290351^2 + 0.001137531^2}} = -0.884051\]

**En (ISO 17043:2024, evaluación con incertidumbre expandida):**

\[En = \frac{x_i - x_{pt}}{\sqrt{(2u_x)^2 + (2u_i)^2}} = \frac{-0.001520718}{\sqrt{(0.002580702)^2 + (0.002275062)^2}} = -0.442026\]

## 4. Datos de participantes

**Referencia:** `participants_data4.csv`.

\[n_{laboratorios} = 4\] (REFERENCIA, PART1, PART2, PART3)

Este conteo soporta la trazabilidad de participantes indicada en ISO 17043:2024.
