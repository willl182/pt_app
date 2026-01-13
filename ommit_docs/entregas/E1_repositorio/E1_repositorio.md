# Entregable 1: Repositorio de Código y Scripts Iniciales

**Proyecto:** Aplicativo para Evaluación de Ensayos de Aptitud (PT App)  
**Organización:** Laboratorio CALAIRE - Universidad Nacional de Colombia  
**Normas de Referencia:** ISO 17043:2023, ISO 13528:2022  
**Fecha:** 2026-01-03

---

## 1. Descripción General del Proyecto

El aplicativo PT App es una herramienta interactiva desarrollada en R/Shiny para automatizar el procesamiento estadístico de ensayos de aptitud (proficiency testing) en la medición de gases contaminantes criterio (SO₂, CO, O₃, NO, NO₂). 

El sistema permite:
- Evaluar la homogeneidad y estabilidad de los ítems de ensayo
- Calcular valores asignados mediante diferentes métodos (referencia, consenso, Algoritmo A)
- Determinar puntajes de desempeño (z, z', zeta, En)
- Generar informes automatizados en formato Word

---

## 2. Estructura Completa del Repositorio

```text
pt_app/
│
├── app.R                           # [5430 líneas] Aplicación Shiny principal
├── es_app.R                        # Versión traducida al español
│
├── R/
│   └── utils.R                     # [90 líneas] Funciones estadísticas modulares
│
├── reports/
│   └── report_template.Rmd         # [507 líneas] Plantilla de informe Word
│
├── data/                           # Archivos de datos de ejemplo
│   ├── homogeneity.csv             # Datos de homogeneidad del ítem
│   ├── stability.csv               # Datos de estabilidad del ítem
│   ├── summary_n4.csv              # Resumen de resultados (4 laboratorios)
│   ├── summary_n7.csv              # Resumen de resultados (7 laboratorios)
│   ├── summary_n10.csv             # Resumen de resultados (10 laboratorios)
│   ├── summary_n13.csv             # Resumen de resultados (13 laboratorios)
│   ├── participants_data.csv       # Información de participantes
│   └── [otros archivos de prueba]
│
├── docs/                           # Documentación técnica por módulo
│   ├── README.md                   # Índice de documentación
│   ├── 01_carga_datos.md           # Módulo de carga de datos
│   ├── 02_funciones_auxiliares.md  # Funciones helper
│   ├── 03_homogeneidad.md          # Evaluación de homogeneidad
│   ├── 04_estabilidad.md           # Evaluación de estabilidad
│   ├── 05_algoritmo_a.md           # Algoritmo A (ISO 13528)
│   ├── 06_valor_consenso.md        # Cálculo de valor por consenso
│   ├── 07_valor_referencia.md      # Valor de referencia
│   ├── 08_compatibilidad.md        # Compatibilidad metrológica
│   ├── 09_puntajes_pt.md           # Puntajes de desempeño
│   ├── 10_informe_global.md        # Generación de informe global
│   ├── 11_participantes.md         # Gestión de participantes
│   ├── 12_generacion_informes.md   # Sistema de reportes
│   └── 13_valores_atipicos.md      # Detección de outliers
│
├── entregas/                       # Productos entregables del proyecto
│   └── E1_repositorio/             # Este entregable
│
├── README.md                       # Guía de inicio rápido
├── DOCUMENTACION_CALCULOS.md       # Documentación de algoritmos
├── GUIA_USO.md                     # Manual de usuario
└── TECHNICAL_DOCUMENTATION.md      # Documentación técnica en inglés
```

---

## 3. Descripción Detallada de Archivos Principales

### 3.1. `app.R` — Aplicación Principal

| Aspecto | Detalle |
|---------|---------|
| **Líneas de código** | 5,430 |
| **Framework** | Shiny (fluidPage + navlistPanel) |
| **Tema visual** | shinythemes::cerulean |
| **Secciones principales** | UI (líneas 36-64), Server (líneas 66-5428) |

**Funciones definidas internamente:**
- `calculate_niqr()` — Cálculo del rango intercuartílico normalizado
- `compute_homogeneity_metrics()` — Evaluación de homogeneidad (ANOVA)
- `compute_stability_metrics()` — Evaluación de estabilidad
- `compute_scores_metrics()` — Cálculo de puntajes z, z', zeta, En
- `run_algorithm_a()` — Implementación del Algoritmo A robusto

### 3.2. `reports/report_template.Rmd` — Plantilla de Informe

| Aspecto | Detalle |
|---------|---------|
| **Líneas de código** | 507 |
| **Formato de salida** | Microsoft Word (.docx) |
| **Parámetros de entrada** | 20+ (summary_data, metric, method, k_factor, etc.) |

**Secciones del informe generado:**
1. Información del proveedor y esquema
2. Descripción del ensayo y metodología
3. Criterios de evaluación
4. Resultados y discusión
5. Anexos (Homogeneidad, Estabilidad, Resultados por participante)

### 3.3. `R/utils.R` — Funciones Modulares

| Función | Descripción |
|---------|-------------|
| `algorithm_A(x, max_iter)` | Algoritmo A de ISO 13528 para media/SD robusta |
| `mad_e_manual(x)` | MADe (Median Absolute Deviation escalada) |
| `nIQR_manual(x)` | nIQR (Rango Intercuartílico Normalizado) |

---

## 4. Formato de Archivos de Datos

### 4.1. `homogeneity.csv` / `stability.csv`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `value` | numeric | Valor medido |
| `pollutant` | character | Contaminante (SO2, CO, O3, NO, NO2) |
| `level` | character | Nivel de concentración (level_1, level_2, etc.) |
| `replicate` | integer | Número de réplica (1, 2, ...) |

### 4.2. `summary_n*.csv`

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `participant_id` | character | Código del participante o "ref" para referencia |
| `pollutant` | character | Contaminante evaluado |
| `level` | character | Nivel de concentración |
| `mean_value` | numeric | Valor promedio reportado |
| `sd_value` | numeric | Desviación estándar reportada |

---

## 5. Requisitos de Software

### 5.1. Versión de R
- **Mínima:** R 4.0.0
- **Recomendada:** R 4.3.0 o superior

### 5.2. Librerías Requeridas

| Librería | Versión Mínima | Propósito |
|----------|----------------|-----------|
| `shiny` | 1.7.0 | Framework de aplicación web |
| `tidyverse` | 2.0.0 | Manipulación de datos (dplyr, ggplot2, tidyr) |
| `vroom` | 1.6.0 | Lectura rápida de archivos CSV |
| `DT` | 0.28 | Tablas interactivas |
| `rhandsontable` | 0.3.8 | Edición de datos tipo Excel |
| `shinythemes` | 1.2.0 | Temas visuales para Shiny |
| `outliers` | 0.15 | Prueba de Grubbs para atípicos |
| `patchwork` | 1.1.0 | Composición de gráficos |
| `bsplus` | 0.1.4 | Componentes Bootstrap |
| `plotly` | 4.10.0 | Gráficos interactivos |
| `rmarkdown` | 2.21 | Generación de informes |
| `knitr` | 1.42 | Motor de renderizado |
| `kableExtra` | 1.3.4 | Tablas formateadas |
| `stringr` | 1.5.0 | Manipulación de cadenas |

### 5.3. Software Adicional
- **Visual Studio Code** (recomendado con la extensión **R**).
- **Pandoc** (necesario para rmarkdown).
- **Navegador web moderno** (Chrome, Firefox, Edge).

---

## 6. Instrucciones de Instalación y Ejecución

### 6.1. Paso 1: Clonar o Descargar el Repositorio

```bash
git clone [URL_DEL_REPOSITORIO]
cd pt_app
```

### 6.2. Paso 2: Verificar Dependencias

Ejecutar el script de verificación incluido:

```r
# En R o RStudio
source("entregas/E1_repositorio/verificar_dependencias.R")
```

Este script:
- Lista todos los paquetes requeridos
- Identifica los paquetes faltantes
- Proporciona el comando de instalación

### 6.3. Paso 3: Instalar Paquetes Faltantes (si aplica)

```r
# Instalación de todos los paquetes necesarios
install.packages(c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable",
  "shinythemes", "outliers", "patchwork", "bsplus",
  "plotly", "rmarkdown", "knitr", "kableExtra", "stringr"
))
```

### 6.4. Paso 4: Ejecutar la Aplicación

```r
# Opción 1: Desde Visual Studio Code
# Con la extensión R instalada, abra app.R y use "R: Run Source" o Ctrl+Shift+S (si está mapeado).

# Opción 2: Desde la terminal de VS Code
Rscript -e "shiny::runApp('app.R')"

# Opción 3: Especificando puerto
shiny::runApp("app.R", port = 3838, launch.browser = TRUE)
```

---

## 7. Verificación del Entorno

Para confirmar que el entorno está correctamente configurado:

```r
# Verificar versión de R
R.version.string

# Verificar que todas las librerías cargan sin error
library(shiny)
library(tidyverse)
library(plotly)
library(rmarkdown)

# Verificar que los datos de ejemplo son legibles
vroom::vroom("data/homogeneity.csv", show_col_types = FALSE)
```

---

## 8. Solución de Problemas Comunes

| Problema | Causa | Solución |
|----------|-------|----------|
| Error al cargar `tidyverse` | Dependencias faltantes | Reinstalar: `install.packages("tidyverse")` |
| `pandoc not found` | Pandoc no instalado | Instalar RStudio o Pandoc por separado |
| Gráficos no se muestran | Versión antigua de plotly | Actualizar: `install.packages("plotly")` |
| Error de codificación CSV | Formato decimal incorrecto | Verificar que los decimales usen punto (.) |

---

## 9. Archivos Incluidos en Este Entregable

| Archivo | Descripción |
|---------|-------------|
| `E1_repositorio.md` | Este documento |
| `verificar_dependencias.R` | Script de verificación de librerías R |
| `guia_verificacion.md` | Guía de implementación y pruebas del script |

---

**Siguiente Entregable:** E2 - Catálogo de Funciones
