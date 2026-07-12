---
title: "Documento Técnico — Entregable 05: Prototipo Estático de Interfaz"
subtitle: "PT App — Aplicativo R/Shiny para Ensayos de Aptitud"
author: "Responsable documental — Equipo de Desarrollo PT App"
date: "2026-06-28"
version: "1.0"
---

\newpage

# Portada

| Campo | Valor |
|-------|-------|
| **Documento** | Documento Técnico — Entregable 05: Prototipo Estático de Interfaz |
| **Proyecto** | PT App — Aplicativo R/Shiny para Análisis de Ensayos de Aptitud |
| **Norma de referencia** | ISO 13528:2022 e ISO 17043:2023 |
| **Institución** | Universidad Nacional de Colombia / Instituto Nacional de Metrología |
| **Fase de desarrollo** | Fase 3: Prototipo UI |
| **Fecha de emisión** | 2026-06-28 |
| **Versión del documento** | 1.0 |
| **Responsable documental** | Equipo de Desarrollo PT App |

\newpage

# Resumen Ejecutivo

El presente documento técnico describe el contenido, la verificación y el estado del **Entregable 05 — Prototipo Estático de Interfaz**, producido dentro de la **Fase 3: Prototipo UI** del proyecto PT App. Este entregable consiste en un conjunto de evidencias de diseño temprano —wireframes, un diagrama de navegación y un prototipo interactivo en HTML— que documentan la arquitectura de información y la propuesta de experiencia de usuario del aplicativo en una etapa conceptual.

Es importante precisar, desde el inicio, que este material **no corresponde a la interfaz vigente** del aplicativo. La interfaz actual, implementada en `app.R`, difiere del prototipo en tres dimensiones principales: navegación, mecanismos de carga de datos y tema visual. En consecuencia, el entregable se conserva como **evidencia histórica de una fase de diseño anterior**, útil para comprender la trayectoria del producto, pero **no debe consultarse como mapa fiel de la interfaz actual**.

El entregable comprende hoy nueve módulos documentados en wireframes, un diagrama de flujo Mermaid con la lógica de navegación del usuario, y un prototipo HTML/CSS autocontenible que modela una propuesta visual inspirada en componentes shadcn/ui. Un conjunto de pruebas automatizadas en R (testthat) verifica la integridad estructural del HTML, la sintaxis del diagrama Mermaid y la presencia de elementos clave descritos en la especificación de wireframes.

Este documento se redacta en el marco de la actualización de trazabilidad efectuada el 2026-06-16, conforme a lo registrado en la bitácora de actualización de entregables, donde el Entregable 05 se reclasificó formalmente como **histórico / prototipo parcial**.

\newpage

# Contexto del Entregable

El proyecto PT App se desarrolla en fases sucesivas que progresan desde el inventario inicial del repositorio hasta la generación de informes de validación. Dentro de esa progresión, el **Entregable 05** se ubica en la **Fase 3: Prototipo UI**, fase en la que el equipo procura traducir los requerimientos funcionales y normativos (ISO 13528:2022 e ISO 17043:2023) en una arquitectura de información visible y revisable antes de comprometer recursos de implementación.

La fase se concibió con tres objetivos: (i) diseñar la distribución espacial y estética del aplicativo mediante wireframes conceptuales; (ii) formalizar la lógica de navegación del usuario a través de un diagrama Mermaid; y (iii) producir un prototipo HTML interactivo que materializara la propuesta visual y permitiera verificar la coherencia entre pantallas. El resultado se entrega como insumo para revisión, no como versión operativa de la aplicación.

# Alcance

## Lo que cubre este entregable

- Diseño inicial de la arquitectura de información para nueve módulos funcionales.
- Especificación escrita (wireframes) de elementos de interfaz, controles de entrada, salidas esperadas y comportamientos interactivos.
- Diagrama de navegación en sintaxis Mermaid que modela los estados y flujos del usuario.
- Prototipo interactivo en HTML/CSS plano que materializa la propuesta visual.
- Pruebas automatizadas en R (testthat) que validan la integridad estructural de los artefactos.
- Guías de verificación manual y troubleshooting.

## Lo que NO cubre este entregable

- La interfaz vigente del aplicativo implementada en `app.R`, que difiere del prototipo en navegación, carga de datos y tema visual.
- La validación funcional o numérica de los cálculos de ensayo de aptitud (esa validación corresponde a los paquetes `ptcalc` y a los Entregables 03 y 04).
- La integración de los componentes visuales con Shiny/bslib en el código productivo.
- La definición final de los dashboards interactivos entregados (Entregable 07).

\newpage

# Contenido Entregado

| Archivo | Directorio | Descripción |
|---------|-----------|-------------|
| `prototipo.html` | `05_prototipo_ui/html/` | Prototipo interactivo HTML/CSS autocontenible, con barra lateral, barra superior, cards y placeholders de gráficos. Inspirado en shadcn/ui. |
| `wireframes.md` | `05_prototipo_ui/md/` | Especificación escrita de nueve módulos, con elementos UI, interacciones, patrones consistentes, responsividad, accesibilidad y referencias de diseño. |
| `wireframes.docx` | `05_prototipo_ui/` | Versión exportada a Word de la especificación de wireframes, generada mediante pandoc. |
| `diagrama_navegacion.mmd` | `05_prototipo_ui/mmd/` | Diagrama de flujo en sintaxis Mermaid que modela los estados de navegación del usuario, nodos de decisión y rutas de error. |
| `test_05_navegacion.R` | `05_prototipo_ui/tests/` | Suite de pruebas en R (testthat) con 17 bloques de prueba y 76 expectativas de integridad estructural del prototipo. |
| `test_05_navegacion.md` | `05_prototipo_ui/tests/` | Guía de uso, ejecución y verificación manual de las pruebas automatizadas. |
| `test_05_navegacion.docx` | `05_prototipo_ui/tests/` | Versión exportada a Word de la guía de pruebas, generada mediante pandoc. |

\newpage

# Explicación Funcional

## ¿Qué es un prototipo y un wireframe?

Un **wireframe** es un esquema visual, de bajo nivel de detalle, que representa la estructura y los componentes de una pantalla sin compromiso estético final. Su propósito es concentrar la revisión sobre la organización de la información: qué elementos aparecen, dónde se ubican, qué controles requiere el usuario y qué salidas se esperan. No incluye colores definitivos, imágenes ni interacción real.

Un **prototipo**, en esta acepción, es una maqueta interactiva que da un paso más allá del wireframe: materializa la propuesta en un navegable estático y permite recorrer pantallas simulando la navegación del usuario. En el caso del Entregable 05, el prototipo (`prototipo.html`) es un documento HTML autónomo —abrible en cualquier navegador moderno— que replica de manera estática la barra lateral, la barra superior, los módulos y la conmutación entre vistas.

Ambos artefactos cumplen una función exploratoria y comunicativa: **ayudan a alinear expectativas entre diseñadores, metrólogos y desarrolladores antes de escribir la lógica de aplicación**. No son productos finales.

## ¿Cómo se visualiza el flujo del aplicativo?

El prototipo y los wireframes organizan el análisis PT en una secuencia conceptual que cubre desde la entrada de datos hasta la difusión de resultados:

1. **Inicio** — Pantalla de bienvenida con tarjetas de acceso rápido (cargar datos, ver informe global, manual de usuario).
2. **Carga de datos** — Cuatro bloques para carga de archivos CSV (homogeneidad, estabilidad, participantes, instrumentación), con panel de validación y estado de cada archivo.
3. **Homogeneidad y estabilidad** — Pestañas con tablas de resultados (ss, sw, criterio 0.3 σ_pt, estado) y gráficos placeholder.
4. **Valores atípicos** — Configuración del método de detección (Algoritmo A, Tukey, Grubbs), tabla de outliers con z-score y badges, y scatter plot placeholder.
5. **Valor asignado** — Selección entre cuatro métodos ISO 13528 (método 1 de referencia, método 2a con MADe, método 2b con nIQR, método 3 Algoritmo A) con tabla comparativa y estadísticos del método seleccionado.
6. **Puntajes PT** — Cálculo y visualización de puntajes z, z', ζ, En con KPI cards, tabla de clasificación (Satisfactorio / Cuestionable / No satisfactorio) e histograma placeholder.
7. **Informe global** — Dashboard con KPIs (total de participantes, tasa de éxito, componente con mejor desempeño, componente con más problemas) y placeholders para heatmap, barras, radar chart y tabla resumen con codificación de color.
8. **Participantes** — Gestión individual con búsqueda, filtros por estado y componente, tabla de puntajes por componentes y panel de detalle con gráficos individuales.
9. **Generación de informes** — Configuración de tipo, formato de salida, secciones a incluir, previsualización y historial de informes generados.

## Diseño inspirado en shadcn/ui

La propuesta visual sigue una estética inspirada en componentes shadcn/ui: barras laterales oscuras con resaltado de ítem activo, cards con bordes redondeados y sombra suave, badges de estado con codificación cromática consistente (verde para satisfactorio, amarillo para cuestionable, rojo para no satisfactorio), grids responsivas y placeholders explícitos para gráficos. La paleta primaria es el azul `#0056b3`, y el prototipo incluye reglas responsivas para escritorio, tablet y móvil, así como una sección de accesibilidad con ratios de contraste mínimo, navegación por teclado y soporte para lectores de pantalla. Para el detalle visual, remítase al archivo `prototipo.html`.

\newpage

# Evidencia de Verificación

El Entregable 05 dispone de una suite de pruebas automatizadas en R, implementada con el paquete `testthat`, que comprende **17 bloques de prueba y 76 expectativas** distribuidas en cuatro familias:

## Pruebas de existencia y formato del prototipo HTML

- Existencia del archivo `prototipo.html`.
- Estructura básica HTML5 válida (DOCTYPE, etiquetas `<html>`, `<head>`, `<body>`, cierre `</html>`).
- Presencia de la barra superior, barra lateral y breadcrumb.
- Presencia de estilos CSS en línea (`<style>` y clases `.sidebar`, `.content`, `.card`, `.table`).
- Presencia de JavaScript para navegación (`<script>`, `addEventListener`, manipulación de clases CSS).

## Pruebas de elementos clave de UI

- Barra lateral con los once módulos esperados (Inicio, Carga de Datos, Homogeneidad/Estabilidad, Valores Atípicos, Valor Asignado, Puntajes PT, Informe Global, Participantes, Generación de Informes, Configuración, Ayuda).
- Secciones HTML con `id` correspondientes a cada módulo.
- Mención de los cuatro archivos CSV requeridos en el módulo de Carga de Datos.
- Elementos de formulario (tablas, botones, selects, inputs) y badges de estado.
- Componentes card (card, card-header, kpi-card, summary-panel) y placeholders de gráficos con mención de ggplot2.

## Pruebas del diagrama Mermaid

- Existencia del archivo `diagrama_navegacion.mmd`.
- Tipo `flowchart` válido y presencia de nodos clave (Inicio, Carga de Datos, Homogeneidad).
- Presencia de nodos de decisión (diamantes) y flechas de navegación.

## Pruebas de la especificación de wireframes

- Existencia del archivo `wireframes.md`.
- Documentación de los ocho módulos funcionales descritos.
- Estructura de directorios esperada (md, html, mmd, tests).

El detalle completo de las pruebas, su ejecución y los resultados esperados se encuentra en los archivos `test_05_navegacion.R` y `test_05_navegacion.md` (y la versión DOCX de este último). La suite fue corregida para no depender de cambios manuales de directorio de trabajo y puede ejecutarse desde la raíz del proyecto o desde el directorio del entregable.

## Bitácora de verificación

| Fecha | Comando | Resultado | Observaciones |
|-------|---------|-----------|---------------|
| 2026-06-28 | `Rscript -e 'testthat::test_file("Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.R")'` | PASS: 76 expectativas, 0 fallos, 0 advertencias | Ejecución desde la raíz del proyecto. |
| 2026-06-28 | `Rscript tests/test_05_navegacion.R` | PASS: 17 bloques de prueba completados | Ejecución desde `Entregables_pt_app/05_prototipo_ui/`. |

\newpage

# Estado Actual

El Entregable 05 se clasifica como **histórico / prototipo parcial**. Esta clasificación se formalizó en la actualización de trazabilidad efectuada el 2026-06-16, conforme al siguiente registro:

> "*La interfaz vigente de `app.R` difiere del prototipo HTML en navegación, carga de datos y tema visual. El prototipo sigue siendo útil como evidencia de diseño inicial, pero las pantallas vigentes incluyen carga dinámica de archivos, análisis H/E, outliers, valor asignado, puntajes, informe global, reportes y preprocesador CALAIRE.*"

En consecuencia:

- **Conserva evidencia de una fase anterior** de diseño conceptual del aplicativo.
- **No representa la versión actual** de la interfaz implementada.
- Su lectura es pertinente para fines de trazabilidad histórica, revisión de opciones de diseño descartadas y recuperación de la lógica de navegación planteada en la Fase 3.

El subagente designado para el mapeo de este entregable en la actualización fue `entregable_05_ui_prototype_mapper`. El subagente responsable del diseño original fue `ui_designer`, con rol *UX/UI Designer & Wireframe Layout Validator*.

\newpage

# Relación con Otros Entregables

| Entregable | Relación |
|-----------|----------|
| **E02 — Funciones usadas** | El prototipo muestra nombres de archivos y columnas esperadas (homogeneity.csv, stability.csv, summary_n4.csv, participants_data4.csv) que enlazan con el inventario de funciones de carga y validación registradas en E02. |
| **E03 — Cálculos PT** | Los módulos de Homogeneidad/Estabilidad y Valor Asignado del prototipo anticipan los cálculos documentados en E03 (criterios ss, sw, 0.3 σ_pt). |
| **E04 — Puntajes** | El módulo de Puntajes PT del prototipo visualiza y a través de badges presenta la clasificación (Satisfactorio / Cuestionable / No satisfactorio) documentada en las fórmulas de E04. |
| **E06 — Lógica de aplicación** | E06 documenta la lógica Shiny vigente, que difiere del prototipo; la comparación entre ambos permite trazar la divergencia de diseño original a implementación actual. |
| **E07 — Dashboards** | El módulo de Informe Global del prototipo prefigura visualmente los dashboards consolidados de E07; los gráficos se entregan allí como placeholders. |

\newpage

# Riesgos y Limitaciones

| Riesgo / Limitación | Recomendación |
|---------------------|---------------|
| **Presentar el prototipo como interfaz vigente.** | NO debe consultarse el prototipo HTML como mapa fiel de `app.R`. La interfaz vigente difiere en navegación, carga de datos y tema visual. |
| **Afirmar coincidencia exacta entre el prototipo y la implementación actual.** | El lenguaje a emplear es "*Conserva evidencia de una fase anterior*". Nunca "*Representa la versión actual*". El estado documental es **histórico / prototipo parcial**. |
| **Interpretar los placeholders de gráficos como visualizaciones terminadas.** | Los placeholders marcan posición y propósito; las visualizaciones reales se desarrollan en Shiny/bslib y se documentan en E07. |
| **Asumir la verificación de cálculos sobre el prototipo.** | El prototipo no implementa cálculos; la validación numérica corresponde a `ptcalc` y a los Entregables 03 y 04. |
| **Pérdida de contexto histórico al migrar a la interfaz vigente.** | Conservar el prototipo y este documento técnico como evidencia recuperable de la trayectoria de diseño. |

\newpage

# Documentos de Consulta

| Documento | Ubicación |
|-----------|-----------|
| Overview del Entregable 05 | `Entregables_pt_app/e5.md` |
| Wireframes conceptuales (Markdown) | `Entregables_pt_app/05_prototipo_ui/md/wireframes.md` |
| Wireframes conceptuales (Word) | `Entregables_pt_app/05_prototipo_ui/wireframes.docx` |
| Prototipo HTML interactivo | `Entregables_pt_app/05_prototipo_ui/html/prototipo.html` |
| Diagrama de navegación (Mermaid) | `Entregables_pt_app/05_prototipo_ui/mmd/diagrama_navegacion.mmd` |
| Tests automatizados (R) | `Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.R` |
| Guía de tests (Markdown) | `Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.md` |
| Guía de tests (Word) | `Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.docx` |
| Bitácora de actualización de entregables | `Entregables_pt_app/bitacora_actualizacion_260616.md` |
| Plan de actualización | `logs/plans/260616_1047_plan_actualizar-entregables-pt-app.md` |
| ISO 13528:2022 — Statistical methods for proficiency testing | Referencia externa |
| ISO 17043:2023 — General requirements for proficiency testing | Referencia externa |

\newpage

# Conclusión

El Entregable 05 proporciona evidencia de una **fase temprana de diseño conceptual** del aplicativo PT App. Conserva la propuesta de arquitectura de información, el modelo de navegación y la estética visual planteados en la Fase 3, documentados mediante wireframes, un diagrama Mermaid y un prototipo HTML interactivo.

El material se mantiene como **referencia histórica**. La interfaz vigente, implementada en `app.R`, difiere del prototipo en navegación, carga de datos y tema visual, e introduce funcionalidades no contempladas en la fase de prototipado, tales como carga dinámica de archivos y un preprocesador CALAIRE. Por ello, el lector debe interpretar este entregable como insumo de trazabilidad y no como descripción de la versión productiva del aplicativo.

La integridad del entregable se verifica mediante una suite de pruebas automatizadas (17 bloques de prueba y 76 expectativas testthat) que valida la estructura del HTML, la sintaxis Mermaid y la presencia de los elementos clave descritos en los wireframes. En conjunto, el entregable cumple su rol documental: **conservar evidencia de una fase anterior del diseño y trazabilizar la evolución del producto** hacia la implementación vigente y los entregables posteriores (E06 — lógica de aplicación y E07 — dashboards).
