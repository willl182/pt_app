# Entregable 1: Repositorio de Código y Scripts Iniciales

Este entregable documenta la estructura del repositorio del aplicativo de Ensayos de Aptitud (PT App) y proporciona las herramientas iniciales para asegurar un entorno de ejecución correcto.

## 1. Estructura del Repositorio

El proyecto está organizado de la siguiente manera:

```text
pt_app/
├── app.R                       # Aplicación Shiny principal (UI y Server)
├── es_app.R                    # Versión traducida al español
├── R/
│   └── utils.R                 # Funciones estadísticas modulares
├── reports/
│   └── report_template.Rmd     # Plantilla para generación de informes Word
├── data/                       # Datos de ejemplo (homogeneidad, estabilidad, etc.)
├── docs/                       # Documentación técnica por módulo (Markdown)
├── entregas/                   # Carpeta raíz para productos entregables
│   └── E1_repositorio/         # Documentación y scripts de este entregable
├── README.md                   # Guía general de inicio rápido
├── DOCUMENTACION_CALCULOS.md    # Detalle de algoritmos estadísticos
└── GUIA_USO.md                 # Manual de usuario básico
```

## 2. Archivos Principales

- **`app.R`**: Corazón del aplicativo. Gestiona la carga de datos, cálculos reactivos de ISO 13528 y la visualización interactiva.
- **`report_template.Rmd`**: Define la estructura del informe final, permitiendo exportar resultados a formato Word de manera automatizada.
- **`R/utils.R`**: Contiene implementaciones de algoritmos robustos (como el Algoritmo A) diseñadas para ser reutilizables.

## 3. Requisitos de Software

Se requiere **R** (versión >= 4.0.0) y un navegador web moderno. Las librerías de R necesarias están listadas en el archivo `verificar_dependencias.R`.

## 4. Instrucciones de Inicio

1. Clone el repositorio o descargue los archivos.
2. Abra el proyecto en RStudio.
3. Ejecute el script de verificación para asegurar que todas las dependencias estén instaladas:
   ```r
   source("entregas/E1_repositorio/verificar_dependencias.R")
   ```
4. Ejecute el aplicativo:
   ```r
   library(shiny)
   runApp("app.R")
   ```
