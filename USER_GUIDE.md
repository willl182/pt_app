# Guía de Usuario: Aplicación de Análisis de Datos PT

Esta guía proporciona instrucciones detalladas sobre cómo utilizar la aplicación Shiny para el análisis de datos de Ensayos de Aptitud (PT), desarrollada por el Laboratorio CALAIRE. La aplicación implementa procedimientos estadísticos basados en la norma **ISO 13528:2022**.

## Tabla de Contenidos
1. [Introducción](#introducción)
2. [Requisitos de Datos](#requisitos-de-datos)
3. [Flujo de Trabajo](#flujo-de-trabajo)
    - [1. Carga de Datos](#1-carga-de-datos)
    - [2. Análisis de Homogeneidad y Estabilidad](#2-análisis-de-homogeneidad-y-estabilidad)
    - [3. Valor Asignado](#3-valor-asignado)
    - [4. Puntajes PT](#4-puntajes-pt)
    - [5. Informe Global](#5-informe-global)
    - [6. Generación de Informes](#6-generación-de-informes)
4. [Referencia de Cálculos](#referencia-de-cálculos)

---

## Introducción

Esta herramienta permite a los proveedores de ensayos de aptitud:
- Evaluar la **homogeneidad** y **estabilidad** de los ítems de ensayo.
- Determinar el **valor asignado** mediante diversos métodos (Referencia, Consenso, Algoritmo A).
- Calcular **puntajes de desempeño** ($z$, $z'$, $\zeta$, $E_n$) para los participantes.
- Generar informes y gráficos detallados.

---

## Requisitos de Datos

La aplicación requiere tres tipos de archivos CSV. Asegúrese de que sus archivos cumplan con el siguiente formato (encabezados exactos):

### 1. Archivo de Homogeneidad (`homogeneity.csv`)
Debe estar en formato "largo" (una fila por medición).
- **Columnas requeridas**:
    - `pollutant`: Nombre del analito (ej. "CO", "NO").
    - `level`: Nivel de concentración (ej. "Level 1").
    - `replicate`: Identificador de la réplica (ej. 1, 2).
    - `value`: Resultado de la medición.

### 2. Archivo de Estabilidad (`stability.csv`)
Mismo formato que el archivo de homogeneidad.
- **Columnas requeridas**: `pollutant`, `level`, `replicate`, `value`.

### 3. Archivos de Resumen de Participantes (`summary_n*.csv`)
Archivos que contienen los resultados reportados por los laboratorios participantes. El nombre del archivo suele indicar el número de laboratorios (ej. `summary_n10.csv`).
- **Columnas requeridas**:
    - `participant_id`: Identificador del laboratorio (use "ref" para el laboratorio de referencia).
    - `pollutant`: Nombre del analito.
    - `level`: Nivel de concentración.
    - `mean_value`: Valor reportado.
    - `sd_value`: Incertidumbre o desviación estándar reportada.

---

## Flujo de Trabajo

### 1. Carga de Datos
1. Vaya a la pestaña **"Carga de datos"**.
2. Utilice los botones de "Browse..." para subir sus archivos CSV correspondientes:
   - **Datos de Homogeneidad**: Suba su archivo `homogeneity.csv`.
   - **Datos de Estabilidad**: Suba su archivo `stability.csv`.
   - **Datos resumen de participantes**: Puede subir múltiples archivos aquí.
3. Verifique el cuadro "Estado de los Datos Cargados" para confirmar que no hay errores.

### 2. Análisis de Homogeneidad y Estabilidad
Esta sección evalúa si los ítems son aptos para el ensayo.

1. Vaya a la pestaña **"Análisis de homogeneidad y estabilidad"**.
2. En la barra lateral:
   - Seleccione el **Analito**.
   - Seleccione el **Nivel**.
   - Haga clic en **"Ejecutar"**.
3. Revise las pestañas de resultados:
   - **Vista previa**: Histogramas y diagramas de caja para detectar valores atípicos.
   - **Evaluación de homogeneidad**:
     - Muestra la tabla ANOVA.
     - Calcula $s_s$ (varianza entre muestras) y $s_w$ (varianza dentro de muestras).
     - Compara $s_s$ contra el criterio $0.3 \times \sigma_{pt}$.
     - **Conclusión**: Indica si cumple ("CUMPLE") o no.
   - **Evaluación de estabilidad**:
     - Compara la media de estabilidad con la de homogeneidad.
     - Realiza una prueba t de Student.
     - **Conclusión**: Indica si el ítem es estable.

### 3. Valor Asignado
Define el valor verdadero convencional ($x_{pt}$) y su incertidumbre ($u(x_{pt})$).

1. Vaya a la pestaña **"Valor asignado"**.
2. Seleccione el analito, esquema (n) y nivel en la barra lateral.
3. Despliegue las secciones para ver diferentes métodos:
   - **Algoritmo A**: Método robusto iterativo (ISO 13528).
     - Haga clic en "Calcular Algoritmo A".
     - Ajuste "Iteraciones máximas" si es necesario.
     - Revise la convergencia y los pesos asignados.
   - **Valor consenso**: Calcula la media robusta, MADe y nIQR de todos los participantes.
   - **Valor de referencia**: Muestra los datos del laboratorio marcado como "ref".

### 4. Puntajes PT
Calcula el desempeño de los participantes.

1. Vaya a la pestaña **"Puntajes PT"**.
2. En la barra lateral, seleccione los datos y haga clic en **"Calcular puntajes"**.
3. Explore las pestañas:
   - **Resultados de puntajes**: Tabla resumen con todos los puntajes.
   - **Puntajes Z, Z', Zeta, En**: Gráficos detallados para cada métrica.
     - **Z-score**: Desempeño respecto a la desviación estándar del PT ($\sigma_{pt}$).
     - **Z'-score**: Incluye la incertidumbre del valor asignado.
     - **Zeta-score**: Incluye la incertidumbre del participante.
     - **En-score**: Error normalizado.

### 5. Informe Global
Ofrece una vista panorámica de todos los métodos de evaluación.

1. Vaya a la pestaña **"Informe global"**.
2. Asegúrese de haber ejecutado "Calcular puntajes" previamente.
3. Seleccione la combinación de interés.
4. Visualice mapas de calor (Heatmaps) que comparan el desempeño de los participantes bajo diferentes métodos de asignación de valor (Referencia, Consenso, Algoritmo A).

### 6. Generación de Informes
Exporte los resultados finales.

1. Vaya a la pestaña **"Generación de informes"**.
2. Configure los parámetros del informe:
   - **Sigma PT ($\sigma_{pt}$)**: Desviación estándar objetivo para la evaluación.
   - **Incertidumbre ($u(x_{pt})$)**.
   - **Factor de cobertura ($k$)**: Usualmente 2.
3. Elija el formato: HTML, PDF o Word.
   - **Nota**: La exportación a PDF requiere tener una distribución de LaTeX instalada en el servidor/equipo.
4. Haga clic en **"Descargar informe"**.

---

## Referencia de Cálculos

### Detección de Valores Atípicos (Preparación PT)
- Se utiliza la **prueba de Grubbs** para identificar valores atípicos significativos en los conjuntos de datos de los participantes (antes de aplicar métodos robustos).

### Homogeneidad (ISO 13528)
- **$s_w$ (Desviación estándar dentro de las muestras)**: Basada en las diferencias entre réplicas.
- **$s_s$ (Desviación estándar entre muestras)**: $\sqrt{s_{x}^2 - (s_w^2 / 2)}$.
- **Criterio**: $s_s \le 0.3 \times \sigma_{pt}$.

### Estabilidad
- Se compara la media general de homogeneidad ($\bar{y}_{hom}$) con la de estabilidad ($\bar{y}_{stab}$).
- **Criterio**: $|\bar{y}_{hom} - \bar{y}_{stab}| \le 0.3 \times \sigma_{pt}$.
- Se complementa con una prueba t de Student.

### Puntajes de Desempeño

| Puntaje | Fórmula | Interpretación |
|---------|---------|----------------|
| **$z$** | $\frac{x_i - x_{pt}}{\sigma_{pt}}$ | $|z| \le 2$: Satisfactorio<br>$2 < |z| < 3$: Cuestionable<br>$|z| \ge 3$: No satisfactorio |
| **$z'$** | $\frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}}$ | Similar al z-score, usado cuando $u(x_{pt})$ es alta. |
| **$\zeta$** (Zeta) | $\frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}}$ | Evalúa la veracidad considerando la propia incertidumbre del participante. |
| **$E_n$** | $\frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}}$ | $|E_n| \le 1$: Satisfactorio. Evalúa la validez de la incertidumbre reportada. |

### Algoritmo A
Método iterativo que calcula un promedio robusto ($x^*$) y una desviación estándar robusta ($s^*$) asignando pesos reducidos a los valores atípicos.
