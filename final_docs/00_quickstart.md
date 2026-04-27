# Guía de inicio rápido

Esta guía permite poner en marcha la aplicación de ensayos de aptitud (PT) en menos de 5 minutos y realizar el primer ciclo de análisis.

---

## 1. Requisitos del sistema

| Requisito | Mínimo | Recomendado |
|---|---|---|
| R | 4.0.0 | 4.3.0+ (4.4.0 ideal) |
| RStudio | Opcional | 2024.04+ |
| Sistema operativo | Windows 10+, macOS 11+, Linux | Cualquier SO moderno |
| RAM | 4 GB | 8 GB+ |
| Navegador | Chrome, Firefox, Edge, Safari | Última versión |

---

## 2. Instalación de dependencias

En R o RStudio:

```r
install.packages(c(
  "shiny", "bslib", "tidyverse", "vroom", "DT", "rhandsontable",
  "shinythemes", "outliers", "patchwork", "bsplus", "plotly",
  "rmarkdown", "devtools"
))
```

### Instalar el paquete local `ptcalc`

Desde la raíz del proyecto:

```r
# Para desarrollo local
devtools::load_all("ptcalc")

# Para uso estándar
# devtools::install("ptcalc")
```

---

## 3. Ejecutar la aplicación

### Método A: Consola de R (recomendado)

```r
setwd("/path/to/pt_app")
shiny::runApp("cloned_app.R")
```

### Método B: Línea de comandos

```bash
R -e "shiny::runApp('cloned_app.R')"
```

La aplicación se abrirá en `http://127.0.0.1:XXXX` (o `http://127.0.0.1:3838`).

---

## 4. Cargar datos de ejemplo

Los archivos de ejemplo están en `data/`.

1. Ir a **Carga de datos**.
2. Subir:
   - `data/homogeneity.csv` (homogeneidad)
   - `data/stability.csv` (estabilidad)
   - Todos los `summary_n*.csv` (resúmenes de participantes)

Si aparece el mensaje en verde de carga exitosa, puedes continuar.

---

## 5. Primer análisis en 5 minutos

### 5.1 Homogeneidad

1. Ir a **Homogeneidad**.
2. Seleccionar contaminante (ej. `so2`) y nivel (ej. `low` o `20-nmol/mol`).
3. Click en **Ejecutar análisis**.
4. Revisar:
   - Tabla ANOVA.
   - Criterio de homogeneidad (PASS/FAIL).
   - Gráficas de distribución.

### 5.2 Estabilidad (si aplica)

1. Ir a **Estabilidad**.
2. Seleccionar contaminante y nivel.
3. Ejecutar análisis para comparar medias homogeneidad vs estabilidad.

### 5.3 Valor asignado

1. Ir a **Valor asignado**.
2. Elegir método:
   - **Algoritmo A** (consenso robusto, recomendado).
   - **Laboratorio de referencia** (participante `ref`).
3. Calcular xₚₜ y su incertidumbre.

### 5.4 Puntajes de desempeño

1. Ir a **Puntajes PT**.
2. Seleccionar puntajes: z, z′, ζ, En.
3. Calcular puntajes y revisar clasificación.

### 5.5 Reportes

1. Ir a **Generación de informes**.
2. Completar metadatos (ID PT, fecha, coordinador).
3. Generar informe global y reportes por participante.

---

¡Listo! Con estos pasos ya tienes tu primer ciclo PT ejecutado y documentado.
