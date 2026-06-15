# 📊 Rundown del Aplicativo: PT Data Analysis Application (Calaire)

**Versión 0.4.0 | Enero 2026**

Este aplicativo es una plataforma web interactiva desarrollada en **R / Shiny** diseñada para el análisis de datos de esquemas de ensayos de aptitud (PT) según los estándares internacionales **ISO 13528:2022** (métodos estadísticos para ensayos de aptitud) e **ISO 17043:2023** (requisitos generales para ensayos de aptitud). 

Es un desarrollo conjunto bajo licencia MIT entre la **Universidad Nacional de Colombia** y el **Instituto Nacional de Metrología**.

---

## 🏗️ 1. Arquitectura y Estructura del Proyecto

El proyecto sigue un patrón de diseño **MVC (Modelo-Vista-Controlador)** adaptado al paradigma reactivo de R/Shiny, manteniendo una separación estricta de responsabilidades (*Separation of Concerns*):

1. **Interfaz y Lógica Reactiva (Shiny):** Controlado en `app.R` (UI/Server) y apoyado por scripts auxiliares en `R/`.
2. **Cálculos Matemáticos Puros (Modelo):** Encapsulados en el paquete local `ptcalc/`. **Regla crítica:** No tiene dependencias de Shiny ni llamadas a `library()`/`require()` dentro de sus archivos fuente, garantizando que el motor de cálculo sea reutilizable y testeable de forma independiente.
3. **Datos de Entrada:** Almacenados en `data/` en formato CSV.
4. **Hojas de Estilo:** Controladas en `www/appR.css` para una estética moderna inspirada en `shadcn/ui`.

### 📂 Mapa del Repositorio
```text
pt_app/
├── app.R                    # Aplicación Shiny principal (Orquestación UI y reactividad)
├── www/
│   └── appR.css             # Estilos personalizados (Look & Feel premium)
├── R/                       # Helper functions del lado de la App (Shiny-aware)
│   ├── pt_homogeneity.R     # Homogeneidad y estabilidad
│   ├── pt_robust_stats.R    # Estadísticas robustas
│   ├── pt_scores.R          # Cálculo de z-scores, En, etc.
│   └── preprocessing/       # Scripts de procesamiento previo de datos
├── ptcalc/                  # Paquete R interno de cálculos matemáticos puros (ISO 13528)
│   ├── R/                   # Funciones puras (pt_scores.R, pt_robust_stats.R, etc.)
│   ├── DESCRIPTION          # Metadatos del paquete
│   └── NAMESPACE            # Exportaciones de funciones
├── tests/testthat/          # Pruebas automatizadas (testthat)
├── data/                    # Archivos CSV de entrada y procesados
├── reports/
│   └── report_template.Rmd  # Plantilla RMarkdown para generación automática de informes
└── scripts/                 # Scripts adicionales para tareas del sistema
```

---

## 🛠️ 2. Módulos Principales del Aplicativo

La aplicación web está dividida en 5 pestañas/módulos lógicos:

### 📥 Módulo 1: Carga de Datos
Permite al usuario subir archivos en formato `.csv` con la estructura requerida para los análisis:
*   `homogeneity.csv`: Datos de ensayos de homogeneidad.
*   `stability.csv`: Datos de estabilidad de los ítems del PT.
*   `summary_n*.csv`: Resumen de resultados de participantes por ronda/esquema.

### 🔬 Módulo 2: Análisis de Homogeneidad y Estabilidad
Evalúa si los ítems de ensayo son aptos y estables para ser distribuidos en la ronda del PT.
*   **Filtros:** Selección de contaminante (`co`, `no`, `no2`, `o3`, `so2`) y nivel de concentración.
*   **Cálculos principales:** Análisis de Varianza (ANOVA) para homogeneidad, comparación de medias para estabilidad y evaluación según criterios de tolerancia de la desviación estándar del PT ($\sigma_{pt}$).
*   **Resultados:** Tablas de resumen de ANOVA y dictamen automático de cumplimiento de criterios ISO 13528.

### 📈 Módulo 3: Preparación PT
Visualización y depuración inicial de los resultados enviados por los participantes.
*   Generación dinámica de pestañas por contaminante.
*   Gráficos de barras y distribución de frecuencia de los resultados.
*   Detección automatizada de valores atípicos mediante el **Test de Grubbs**.

### 🎯 Módulo 4: Valor Asignado & PT Scores (Evaluación del Desempeño)
El núcleo matemático de la aplicación donde se definen los parámetros de referencia y se evalúa a los laboratorios.
*   **Determinación del Valor Asignado ($X_{pt}$):** Soporta el **Algoritmo A** (ISO 13528), Consenso Estadístico (usando MADe o nIQR) y valores de Laboratorio de Referencia.
*   **Cálculo de Desempeño:** Genera múltiples métricas de evaluación individual:
    *   **$z$-score:** Evaluación estándar.
    *   **$z'$-score:** Incluye la incertidumbre del valor asignado.
    *   **$\zeta$-score (zeta):** Evalúa si la incertidumbre declarada por el participante es compatible.
    *   **$E_n$-score:** Número normalizado (evaluación metrológica estricta de compatibilidad).
*   **Clasificación Automática:** Evaluación semántica de los resultados ("Satisfactorio", "Cuestionable", "No satisfactorio").

### 📄 Módulo 5: Informe Global & Generación de Informes
*   **Informe Global:** Visualización tipo *heatmap* (mapa de calor) para evaluar de un vistazo el desempeño de los laboratorios en múltiples contaminantes y niveles simultáneamente.
*   **Generador:** Interfaz para exportar reportes ejecutivos en PDF/HTML usando plantillas dinámicas en RMarkdown (`report_template.Rmd`).

---

## 🎨 3. Diseño e Interfaz Visual

El aplicativo destaca por una interfaz **premium y moderna**, inspirada en los patrones estéticos de **shadcn/ui** (React/Tailwind) pero implementada con herramientas nativas de R/Shiny y CSS puro en `www/appR.css`:
*   **Tipografía sofisticada** y paleta de colores curada (estilo Dark Mode / HSL armonizados) en lugar de los colores base de Bootstrap.
*   **Tarjetas personalizadas (shadcn Cards):** Bordes sutiles, sombras suaves e interlineado optimizado para agrupar gráficos y tablas.
*   **Alertas y Badges dinámicos:** Mensajes de estado codificados por color según la gravedad o el resultado del score.
*   **Gráficos Interactivos:** Gráficos dinámicos e interactivos en alta calidad potenciados por `plotly` y composición mediante `patchwork`.

---

## 💻 4. Guía Rápida para el Desarrollador

### Comandos de Referencia

#### Ejecución del Aplicativo
```r
# Ejecutar desde consola bash
Rscript app.R

# O dentro de una consola interactiva de R
shiny::runApp()
```

#### Desarrollo del Paquete de Cálculos (`ptcalc`)
```r
# Cargar el paquete para desarrollo activo (Método recomendado)
devtools::load_all("ptcalc")

# Instalar localmente en la biblioteca de R
devtools::install("ptcalc")

# Documentar funciones (genera los archivos /man/ mediante roxygen2)
devtools::document("ptcalc")

# Chequear consistencia general del paquete
devtools::check("ptcalc")
```

#### Ejecución de Pruebas Unitarias
```r
# Ejecutar todas las pruebas del proyecto
testthat::test_dir("tests/testthat")

# Ejecutar un archivo de prueba específico
testthat::test_file("tests/testthat/test-algorithm-a.R")
```

### Directrices de Código y Estilo (Críticas)
1.  **Asignaciones:** Usar **siempre** el operador `<-` para asignación (ej: `x <- 10`). Reservar `=` únicamente para pasar argumentos nombrados a funciones.
2.  **Nombres:** Usar `snake_case` para variables y funciones (ej. `calculate_robust_mean()`) y `SCREAMING_SNAKE_CASE` para constantes del paquete.
3.  **Documentación de Funciones:** Cada función exportada en `ptcalc` debe estar documentada detalladamente con etiquetas roxygen2, incluyendo la referencia exacta a la sección de la norma **ISO 13528:2022**.
4.  **Idiomas:** El código fuente, variables y comentarios deben escribirse en **inglés**, mientras que todos los textos, reportes, etiquetas y mensajes dirigidos al usuario en la interfaz web de Shiny deben estar estrictamente en **español**.
