# Aplicación para análisis de ensayos de aptitud

**Versión 0.4.1 | Julio de 2026**

Aplicación web desarrollada con R y Shiny para analizar datos de ensayos de aptitud (EA, o PT por *proficiency testing*). Incluye métodos estadísticos basados en ISO 13528:2022 e ISO/IEC 17043 para evaluar homogeneidad, estabilidad, valores asignados, incertidumbres y desempeño de participantes.

## Funciones principales

- Carga, validación y exploración de archivos CSV.
- Evaluación de homogeneidad y estabilidad de ítems de ensayo.
- Estadística robusta mediante MADe, nIQR y Algoritmo A.
- Cálculo de valores asignados por consenso o laboratorio de referencia.
- Cálculo e interpretación de puntajes `z`, `z'`, `zeta` y `En`.
- Evaluación de compatibilidad metrológica.
- Tableros comparativos por contaminante, nivel, ronda y participante.
- Generación de informes mediante R Markdown.
- Trazabilidad de cálculos, controles y documentos de entrega.

## Inicio rápido

### Requisitos

- R instalado desde [CRAN](https://cran.r-project.org/).
- Paquetes requeridos por la aplicación.

Instalación básica:

```r
install.packages(c(
  "shiny", "tidyverse", "vroom", "DT", "rhandsontable",
  "shinythemes", "outliers", "patchwork", "bsplus", "plotly",
  "rmarkdown", "bslib"
))
```

### Ejecutar aplicación

Desde raíz del repositorio:

```bash
Rscript app.R
```

R mostrará en consola dirección local, normalmente `http://127.0.0.1:XXXX`.

### Cargar paquete `ptcalc` durante desarrollo

```r
devtools::load_all("ptcalc")
```

Paquete interno `ptcalc` está en versión **0.1.1** y concentra cálculos reutilizables de estadística robusta, puntajes, homogeneidad y estabilidad.

## Preprocesamiento de datos

Para validar sintaxis de scripts y ejecutar preprocesamiento principal:

```bash
Rscript -e 'for (f in c(list.files("R/preprocessing", full.names=TRUE, pattern="[.]R$"), "scripts/adicionales/preprocesar_part_1.R")) invisible(parse(file=f)); cat("parse OK\n")'
Rscript scripts/adicionales/preprocesar_part_1.R
```

Salidas principales:

- `data/processed/part_1_ronda.csv`: consolidado de participantes.
- `data/processed/h_part_1_ronda.csv`: detalle horario auditado.

Casos de uso y datos reproducibles se gestionan desde `data_use_cases/`. Script `data_use_cases/scripts/simulate_participants.R` permite generar datos de participantes; archivos derivados no forman parte obligatoria del código fuente.

## Módulos de aplicación

### 1. Carga de datos

Carga archivos CSV, valida estructura y prepara datos para módulos analíticos. Aplicación admite datos de homogeneidad, estabilidad, resultados de participantes, valores de referencia e incertidumbres.

### 2. Homogeneidad y estabilidad

Evalúa aptitud de ítems usados en ensayo:

- selección de contaminante y nivel de concentración;
- resumen estadístico y vista de datos;
- ANOVA y estimación de variación entre muestras;
- métodos robustos MADe y nIQR;
- criterios ordinarios y expandidos;
- comparación entre resultados de homogeneidad y estabilidad.

### 3. Preparación del ensayo de aptitud

Organiza resultados de distintas rondas y esquemas:

- pestañas dinámicas por contaminante;
- gráficos de barras y distribuciones;
- revisión de resultados por laboratorio;
- prueba de Grubbs como apoyo para detección de valores atípicos.

### 4. Valor asignado y puntajes

Calcula valores de referencia y desempeño de participantes:

- Algoritmo A de ISO 13528:2022;
- consenso mediante MADe o nIQR;
- valor de laboratorio de referencia;
- puntajes `z`, `z'`, `zeta` y `En`;
- incertidumbre del valor asignado;
- compatibilidad metrológica.

### 5. Informe global y generación de informes

- mapa de calor de resultados por nivel y contaminante;
- comparación entre contaminantes, rondas y esquemas;
- tablas consolidadas de desempeño;
- configuración y descarga de informes R Markdown;
- selección de secciones de homogeneidad, estabilidad, puntajes y compatibilidad metrológica.

## Interfaz

Interfaz usa componentes visuales inspirados en shadcn/ui:

- encabezado institucional y navegación;
- tarjetas para agrupar resultados;
- alertas con estados y advertencias;
- distintivos compactos de clasificación;
- tablas interactivas con `DT`;
- gráficos estáticos con `ggplot2` e interactivos con `plotly`;
- pie de página institucional.

Estilos principales están en `www/appR.css`.

## Ajustes recientes

### Algoritmo A y cifras significativas

- Convergencia primaria compara tercera cifra significativa de media robusta y desviación estándar robusta mediante `signif(x, 3)`, conforme nota 1 del anexo C de ISO 13528:2022.
- Guardia numérica se conserva como respaldo ante límites de precisión de máquina.
- Resultado de `run_algorithm_a()` informa método de convergencia mediante `convergence_method` (`signif3`, `numerical_guard` o `NA`).
- Registro de iteraciones incluye campos de trazabilidad asociados con comparación de cifras significativas.
- Tablas de Algoritmo A muestran valores originales, valores winsorizados e indicador de winsorización con nombres estables.

### Presentación y clasificación de resultados

- Formato numérico centralizado mediante `format_num()` y `format_numeric_columns()`.
- Etiquetas de convergencia traducidas para interfaz.
- Clasificaciones de puntajes incluyen estados satisfactorio, cuestionable e insatisfactorio.
- Preparación de tablas evita columnas duplicadas y conserva estructura esperada para puntajes y pesos.

### Calidad y entrega

- Paquete `ptcalc` actualizado a versión 0.1.1.
- Suite de pruebas estabilizada, con validación explícita de estructura de pesos del Algoritmo A.
- Entregables técnicos organizados por fases y cerrados con manifiestos, matrices de trazabilidad, controles y checksums.
- Datos procesados de casos de uso se tratan como artefactos regenerables mediante scripts, no como fuente primaria.

## Estructura del repositorio

```text
pt_app/
├── app.R                       # Aplicación Shiny: interfaz y lógica del servidor
├── R/
│   └── preprocessing/          # Funciones de preprocesamiento
├── ptcalc/                     # Paquete R de cálculos estadísticos
│   ├── R/                      # Funciones del paquete
│   ├── man/                    # Documentación generada
│   ├── DESCRIPTION             # Metadatos y versión
│   └── NEWS.md                 # Historial del paquete
├── reports/                    # Plantillas y salidas de informes
├── data/                       # Datos usados por aplicación
├── data_use_cases/             # Casos de uso, scripts y artefactos derivados
├── scripts/                    # Automatización y utilidades
├── tests/testthat/             # Pruebas automatizadas
├── www/                        # CSS y recursos web
├── rsconnect/                  # Configuración de despliegue Shiny
└── Entregables_pt_app/         # Paquete documental y evidencias finales
```

## Arquitectura técnica

`app.R` contiene dos bloques principales:

- **`ui`**: navegación, controles, paneles, tablas y gráficos.
- **`server`**: carga de datos, expresiones reactivas, cálculos, caché, informes y descargas.

Bibliotecas principales:

- `shiny` y `bslib`: aplicación e interfaz web;
- `tidyverse`: transformación y visualización de datos;
- `vroom`: lectura rápida de CSV;
- `DT`: tablas interactivas;
- `plotly`: gráficos interactivos;
- `patchwork`: composición de gráficos;
- `outliers`: prueba de Grubbs;
- `rmarkdown`: generación de informes.

Lógica estadística reutilizable debe mantenerse en `ptcalc/` cuando corresponda. Cambios en aplicación requieren reiniciar sesión Shiny para cargar código actualizado.

## Pruebas y validación

Ejecutar suite completa:

```bash
Rscript -e 'testthat::test_dir("tests/testthat")'
```

Validar paquete `ptcalc`:

```bash
Rscript -e 'devtools::test("ptcalc")'
R CMD check ptcalc
```

Validar parseo de archivos R:

```bash
Rscript -e 'files <- list.files(".", pattern="[.]R$", recursive=TRUE, full.names=TRUE); for (f in files) parse(file=f); cat("parse OK\n")'
```

Repositorio puede incluir ejecutable liviano `./Rscript` para validación estructural en entornos sin instalación nativa de R. Ese recurso no ejecuta semántica R ni reemplaza pruebas con instalación real antes de desplegar.

## Documentación y entregables

Índice principal de entrega:

- [`Entregables_pt_app/00_control_documental/README.md`](Entregables_pt_app/00_control_documental/README.md)
- [`Entregables_pt_app/00_control_documental/indice_maestro.md`](Entregables_pt_app/00_control_documental/indice_maestro.md)
- [`Entregables_pt_app/00_control_documental/matriz_trazabilidad.md`](Entregables_pt_app/00_control_documental/matriz_trazabilidad.md)
- [`Entregables_pt_app/00_control_documental/auditoria_cierre.md`](Entregables_pt_app/00_control_documental/auditoria_cierre.md)

Documentación está organizada desde línea base y repositorio inicial hasta aplicación beta, manuales, validación e informe final. Referencias antiguas al directorio inexistente `es/` fueron eliminadas.

## Normas aplicadas

- **ISO 13528:2022**: métodos estadísticos para ensayos de aptitud.
  - estadística robusta: MADe, nIQR y Algoritmo A;
  - homogeneidad y estabilidad;
  - valores asignados e incertidumbres;
  - puntajes `z`, `z'`, `zeta` y `En`;
  - compatibilidad metrológica.
- **ISO/IEC 17043**: requisitos generales para proveedores de ensayos de aptitud.

Aplicación apoya ejecución y trazabilidad de cálculos. Uso final exige revisión técnica, control metrológico y validación según procedimiento aplicable.

## Historial resumido

### v0.4.1 — julio de 2026

- Convergencia de Algoritmo A por tercera cifra significativa y guardia numérica.
- Trazabilidad del método de convergencia e iteraciones.
- Formato numérico centralizado.
- Correcciones en tablas de pesos, winsorización y clasificación de puntajes.
- Paquete `ptcalc` 0.1.1.
- Estabilización de pruebas y cierre técnico del paquete de entregables.

### v0.4.0 — enero de 2026

- Compatibilidad metrológica.
- Interfaz modernizada con componentes inspirados en shadcn/ui.
- Encabezado y pie institucionales.
- Caché para cálculos y salidas.
- Generación ampliada de informes.

### v0.3.0 — enero de 2026

- Rediseño inicial de interfaz.
- Primer módulo de compatibilidad metrológica.
- Soporte de columna de ronda en datos de entrada.

## Licencia

MIT — Universidad Nacional de Colombia / Instituto Nacional de Metrología.
