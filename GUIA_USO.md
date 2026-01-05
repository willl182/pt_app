# Guía de Uso y Validación del Aplicativo de Evaluación de Ensayos de Aptitud

Esta guía proporciona instrucciones detalladas para la instalación, preparación de datos, ejecución y uso del aplicativo R Shiny desarrollado para la evaluación estadística de Ensayos de Aptitud (PT).

Está dirigida principalmente a **estadísticos y coordinadores de calidad** que requieran verificar y validar los cálculos realizados por el software, conforme a las normativas **ISO 13528:2022** e **ISO 17043**.

---

## 1. Requisitos Técnicos e Instalación

### 1.1 Software Previo
Para ejecutar la aplicación, debe tener instalado:
*   **R** (versión 4.0 o superior): [Descargar R](https://cran.r-project.org/)
*   **RStudio** (recomendado para facilitar la ejecución): [Descargar RStudio](https://posit.co/download/rstudio-desktop/)

### 1.2 Instalación de Librerías
El aplicativo depende de varios paquetes de R. Copie y ejecute el siguiente código en la consola de R para instalar todas las dependencias necesarias:

```r
install.packages(c(
  "shiny",
  "tidyverse",
  "vroom",
  "DT",
  "rhandsontable",
  "shinythemes",
  "outliers",
  "patchwork",
  "bsplus",
  "plotly",
  "rmarkdown",
  "bslib"
))
```

---

## 2. Ejecución del Aplicativo

### 2.1 Desde RStudio
1.  Abra el archivo `app.R` en RStudio.
2.  Haga clic en el botón **"Run App"** (icono de play verde) ubicado en la parte superior derecha del editor de código.

### 2.2 Desde la Línea de Comandos (Terminal)
Navegue hasta la carpeta del proyecto y ejecute:

```bash
Rscript app.R
```

El aplicativo iniciará un servidor local (usualmente en `http://127.0.0.1:XXXX`). Copie esa dirección en su navegador web si no se abre automáticamente.

---

## 3. Preparación de los Archivos de Datos (Inputs)

El correcto funcionamiento depende estrictamente del formato de los archivos CSV de entrada. Asegúrese de que sus datos cumplan con las siguientes especificaciones **exactas** (nombres de columnas sensibles a mayúsculas/minúsculas).

### 3.1 Datos de Homogeneidad (`homogeneity.csv`) y Estabilidad (`stability.csv`)
Ambos archivos comparten la misma estructura. Se utilizan para el ANOVA de un factor.

| Columna     | Tipo    | Descripción |
|-------------|---------|-------------|
| `pollutant` | Texto   | Nombre del analito (ej. "CO", "SO2"). |
| `level`     | Texto   | Nivel de concentración (ej. "Level 1", "50 ppb"). |
| `replicate` | Texto   | Identificador de la réplica (ej. "sample_1", "sample_2"). **Crucial**: Debe usarse para pivotar los datos. |
| `value`     | Numérico| Resultado de la medición. |

> **Nota para validación:** El aplicativo requiere al menos 2 ítems ($g \ge 2$) y 2 réplicas por ítem ($m \ge 2$) para calcular el ANOVA.

### 3.2 Datos Resumen de Participantes (`summary_n*.csv`)
Contiene los resultados reportados por los laboratorios participantes.

**Requisito del nombre del archivo:** El nombre del archivo **debe contener el número de laboratorios participantes** (ej. `summary_n20.csv`, `summary_n15.csv`). El aplicativo extrae este número automáticamente para clasificar los esquemas.

| Columna          | Tipo    | Descripción |
|------------------|---------|-------------|
| `participant_id` | Texto   | Código del laboratorio. Use `"ref"` para el laboratorio de referencia. |
| `pollutant`      | Texto   | Nombre del analito. |
| `level`          | Texto   | Nivel de concentración. |
| `mean_value`     | Numérico| Valor promedio reportado por el participante. |
| `sd_value`       | Numérico| Desviación estándar o incertidumbre estándar reportada. |

### 3.3 Datos de Instrumentación (`instrumentation.csv` - Opcional)
Utilizado para la generación del informe final (sección "Participantes").

| Columna             | Tipo  | Descripción |
|---------------------|-------|-------------|
| `Codigo_Lab`        | Texto | ID del participante (debe coincidir con `participant_id`). |
| `Analizador_SO2`    | Texto | Marca/Modelo del equipo. |
| `Analizador_CO`     | Texto | Marca/Modelo del equipo. |
| `Analizador_O3`     | Texto | Marca/Modelo del equipo. |
| `Analizador_NO_NO2` | Texto | Marca/Modelo del equipo. |

---

## 4. Guía de Uso y Validación Paso a Paso

El aplicativo está dividido en pestañas que siguen el flujo lógico de una evaluación PT.

### Paso 1: Carga de Datos
1.  Vaya a la pestaña **"Carga de datos"**.
2.  Cargue los archivos CSV correspondientes en los tres paneles: Homogeneidad, Estabilidad y Resumen (puede seleccionar múltiples archivos de resumen a la vez).
3.  **Verificación:** Revise la sección "Estado de los Datos Cargados" al final de la página para confirmar que se leyeron las filas correctamente.

### Paso 2: Análisis de Homogeneidad y Estabilidad
Este módulo evalúa si los ítems de ensayo son adecuados para el PT.

1.  **Configuración:** Seleccione el analito y el nivel en el panel lateral y haga clic en **"Ejecutar"**.
2.  **Validación Estadística (Puntos Clave):**
    *   **Vista previa:** Verifique que los datos crudos coincidan con sus CSVs.
    *   **Evaluación de Homogeneidad:** Revise la tabla **"Componentes de varianza"**.
        *   Confirme que $s_{sample}$ ($s_s$) y $\sigma_{allow}$ ($0.3 \times \sigma_{pt}$) están calculados correctamente.
        *   Verifique el cálculo de $F$ o la comparación de varianzas en la tabla ANOVA.
    *   **Evaluación de Estabilidad:** El aplicativo realiza una prueba t de Student comparando la media de homogeneidad vs. estabilidad.
        *   Valide el *p-valor* en la salida de la consola mostrada en la interfaz ("Prueba t").
        *   Verifique si se cumple la condición: $| \bar{y}_{hom} - \bar{y}_{stab} | \le 0.3 \sigma_{pt}$.

### Paso 3: PT Preparation (Valores Atípicos y Distribución)
Este módulo analiza los resultados de los participantes.

1.  **Exploración:** Navegue por las pestañas de cada contaminante.
2.  **Validación de Atípicos (Outliers):** Use la sub-pestaña **"Grubbs' Test"** para detectar valores anómalos en los resultados de los participantes.
    *   Revise la tabla resumen. Si $p < 0.05$, se indica la presencia de un valor atípico.

### Paso 4: Valor Asignado
Aquí se define el valor verdadero ($x_{pt}$) y la desviación estándar para la evaluación ($\sigma_{pt}$). El aplicativo soporta tres enfoques:

1.  **Algoritmo A (ISO 13528 Anexo C):**
    *   Calcula media y desviación robusta iterativamente.
    *   **Validación:** Vaya a la sub-pestaña "Algoritmo A", configure las iteraciones y ejecute.
    *   **Punto de control:** Revise la tabla **"Iteraciones"** y **"Pesos Finales"**.
2.  **Valor Consenso:**
    *   Calcula la mediana y dos medidas de dispersión: MADe y nIQR.
3.  **Referencia:**
    *   Toma directamente los valores del participante identificado como `"ref"`.

### Paso 5: Puntajes PT (Scoring)
Calcula los indicadores de desempeño para cada participante.

1.  Configure los parámetros ($\sigma_{pt}$, $u(x_{pt})$, $k$) y haga clic en **"Calcular puntajes"**.
2.  El sistema calcula: **z-score**, **z'-score**, **zeta-score** y **En-score**.

### Paso 6: Informe Global
Esta pestaña agrega todos los resultados anteriores en una vista matricial (Heatmaps).

*   Use esta vista para detectar patrones, como un laboratorio que falla sistemáticamente en todos los niveles (filas rojas en el heatmap).
*   Verifique las tablas de "Resumen global" para obtener conteos rápidos de resultados Satisfactorios/Cuestionables/No Satisfactorios.

### Paso 7: Generación de Informes
Genera un documento Word (`.docx`) o HTML con todos los hallazgos.

1.  Complete los metadatos (ID Informe, Fechas, Responsables).
2.  Seleccione el método de evaluación base (ej. Algoritmo A o Referencia).
3.  Cargue el archivo de instrumentación si desea incluir esa tabla.
4.  Haga clic en **"Descargar informe"**.

---

## 5. Solución de Problemas Comunes

| Error / Síntoma | Causa Probable | Solución |
|-----------------|----------------|----------|
| "Error: Columns not found" | Nombres de columnas incorrectos en el CSV. | Verifique mayúsculas/minúsculas. Ej: `pollutant` (minúscula) vs `Pollutant`. Requisito estricto: `replicate` en datos de homogeneidad. |
| No aparecen niveles en los selectores | Los archivos cargados no tienen niveles coincidentes. | Asegúrese de que el texto en la columna `level` sea idéntico en todos los archivos (ej. "Level 1" vs "L1"). |
| Algoritmo A no converge | Datos con dispersión extrema o muy pocos datos. | Aumente el número de iteraciones máximas o verifique si hay datos corruptos (ceros o vacíos). |
| Gráficos vacíos | Librería `plotly` no renderiza. | Asegúrese de no estar bloqueando scripts de JS en el navegador o actualice RStudio. |
| "No se encontraron datos para la combinación seleccionada" | Desajuste en filtros. | Verifique que el `n_lab` seleccionado corresponda al archivo cargado (el número en el nombre del archivo). |
