---
title: "Documento Técnico del Entregable 07 — Dashboards y Gráficos"
subtitle: "Aplicativo R/Shiny para Evaluación de Ensayos de Aptitud"
author: "Universidad Nacional de Colombia — Instituto Nacional de Metrología (INM)"
date: "2026-06-28"
version: "1.0"
---

# Portada

| Campo | Valor |
|-------|-------|
| **Nombre del documento** | Documento Técnico del Entregable 07 — Dashboards y Gráficos |
| **Proyecto** | PT App — Aplicativo R/Shiny para Ensayos de Aptitud (ISO 13528:2022 e ISO 17043:2023) |
| **Institución** | Universidad Nacional de Colombia — Sede Medellín / Instituto Nacional de Metrología (INM) |
| **Laboratorio ejecutor** | Laboratorio CALAIRE |
| **Fecha de emisión** | 2026-06-28 |
| **Versión** | 1.0 |
| **Responsable documental** | Equipo de gestión documental — PT App |
| **Estado del entregable** | Parcial / evidencia histórica |
| **Clasificación** | Documento técnico interno |

---

# Resumen Ejecutivo

El Entregable 07, denominado **Dashboards y Gráficos**, corresponde a la Fase 5 del ciclo de desarrollo del aplicativo PT App y documenta la transición desde una interfaz centrada en tablas y resultados numéricos hacia paneles visuales que facilitan la interpretación de los resultados de los ensayos de aptitud. Su propósito es ofrecer una capa de visualización interactiva que permita al coordinador del esquema, a los evaluadores y a los participantes identificar patrones de desempeño, detectar desviaciones, generar alertas y comparar resultados entre laboratorios o entre métodos de valor asignado.

El contenido del entregable se basa en la versión histórica del aplicativo (`app_v07.R`), que integra la lógica de negocio heredada de entregables previos con el renderizado de seis visualizaciones: histograma por nivel, diagrama de caja por participante, mapa de calor de puntajes z, gráfico de barras de evaluación, comparación de puntajes (z, z', zeta, En) y diagrama de dispersión frente al valor asignado. Estas visualizaciones se acompañan de un diagrama de flujo en sintaxis Mermaid que modela el procesamiento de los datos de los participantes hasta su graficación, y de una suite de pruebas automatizadas que valida la correcta instanciación de los objetos gráficos y la correspondencia entre los marcadores de posición de la interfaz y los *outputs* reales del servidor.

El estado documental del entregable se clasifica como **Parcial / evidencia histórica**. El aplicativo vigente (`app.R`) incorpora un conjunto significativamente más amplio de vistas, que incluye mapas de calor para múltiples métodos de cálculo del valor asignado (referencia, consenso por media, consenso por nIQR, algoritmo A y juicio experto), paneles de detección de valores atípicos, evaluación de compatibilidad metrológica y reportes parametrizables. Estas capacidades no están mapeadas en el presente documento y requieren un ejercicio de actualización independiente. Asimismo, el diagrama de flujo histórico debe actualizarse para reemplazar el concepto de datos fijos por el de carga dinámica y procesamiento vigente.

El contenido del entregable sigue siendo útil como evidencia trazable de la incorporación del componente visual al aplicativo, como referencia para la verificación funcional de las visualizaciones históricas y como base conceptual para la actualización documental de los dashboards vigentes. No debe interpretarse, bajo ninguna circunstancia, como una cobertura completa de las capacidades visuales actuales de la aplicación.

---

# Contexto del Entregable

El Entregable 07 se ubica en la **Fase 5: Dashboards** del ciclo de desarrollo del aplicativo PT App. Esta fase representa un paso cualitativo en la evolución del producto: mientras los entregables previos se concentraron en consolidar el inventario de funciones (E02), los cálculos estadísticos (E03), los puntajes de desempeño (E04), el prototipo de interfaz (E05) y la lógica de la aplicación Shiny (E06), la Fase 5 introduce el componente de visualización de datos como medio para interpretar los resultados de los ensayos de aptitud.

La necesidad de este componente surge de la propia naturaleza del proceso metrológico. Los ensayos de aptitud, conforme a ISO 13528:2022 e ISO 17043:2023, generan un volumen considerable de resultados cuantitativos: valores reportados por cada participante, estadísticos robustos de centralidad y dispersión, puntajes de desempeño (z, z', zeta y En) y categorías de evaluación (Satisfactorio, Cuestionable, No satisfactorio). La lectura de estos datos exclusivamente en formato tabular dificulta la identificación oportuna de patrones, tendencias y alertas, especialmente cuando el número de participantes o de analitos crece.

La incorporación de dashboards y gráficos cumple, en este marco, una función interpretativa: transformar los resultados numéricos en representaciones visuales que permitan al coordinador del esquema responder preguntas de gestión técnica con rapidez —¿qué participantes presentan desviaciones significativas?, ¿hay analitos con mayor proporción de resultados no satisfactorios?, ¿cómo se comparan los distintos métodos de valor asignado?— sin necesidad de recorrer tablas completas. El Entregable 07 documenta la consolidación histórica de esta capacidad y referencia las pruebas que verifican su funcionamiento.

---

# Alcance

## Cobertura

El presente documento cubre las visualizaciones evidenciadas en la versión histórica del aplicativo (`app_v07.R`), la suite de pruebas asociada (`test_07_graficos.R` y `test_07_graficos.md`), el diagrama de flujo en sintaxis Mermaid (`diagrama_flujo.mmd`) y la guía explicativa de validación visual. En particular, el alcance se circunscribe a las seis visualizaciones implementadas en la versión histórica:

1. Histograma por nivel.
2. Diagrama de caja (*boxplot*) por participante.
3. Mapa de calor de puntajes z.
4. Gráfico de barras de evaluación.
5. Comparación de puntajes (z, z', zeta, En).
6. Diagrama de dispersión frente al valor asignado.

## Exclusiones

El documento **no** cubre los dashboards completos del aplicativo vigente (`app.R`), que incluyen capacidades adicionales no mapeadas en el entregable histórico:

- Mapas de calor globales para múltiples métodos de cálculo del valor asignado (referencia, consenso por media, consenso por nIQR, algoritmo A y juicio experto).
- Paneles de detección de valores atípicos con histogramas y diagramas de caja específicos.
- Evaluación de compatibilidad metrológica entre métodos.
- Gráficos de seguimiento de valores por participante y por nivel.
- Generación de reportes parametrizables.

Tampoco cubre la actualización pendiente del diagrama de flujo, que debe reemplazar el concepto de *datos fijos* por el de *carga dinámica* y procesamiento actual.

---

# Contenido Entregado

| # | Archivo | Naturaleza | Descripción |
|---|---------|------------|-------------|
| 1 | `app_v07.R` | Código fuente | Aplicación Shiny histórica que integra la lógica de negocio de versiones anteriores con el renderizado de gráficos y paneles interactivos. |
| 2 | `md/diagrama_flujo.mmd` | Diagrama de flujo | Diagrama en sintaxis Mermaid que modela el flujo de procesamiento de los datos de los participantes hasta su graficación interactiva. |
| 3 | `tests/test_07_graficos.R` | Suite de pruebas | Script de verificación automatizada en R (testthat) que valida la correcta generación de los objetos gráficos con datos cargados. |
| 4 | `tests/test_07_graficos.md` | Guía técnica | Guía explicativa para la validación visual e interactiva de los seis gráficos implementados. |
| 5 | `tests/test_07_graficos.docx` | Guía exportada | Versión en formato Word de la guía de verificación, generada mediante conversión con pandoc. |

---

# Explicación Funcional

## ¿Qué son los dashboards y gráficos en el contexto de los ensayos de aptitud?

Un *dashboard* es un panel visual que reúne, en una sola vista, un conjunto de representaciones gráficas interrelacionadas que permiten al usuario monitorear y comprender una situación técnica compleja. En el contexto de los ensayos de aptitud, un *dashboard* presenta los resultados de los participantes —valores reportados, puntajes de desempeño y categorías de evaluación— acompañados de gráficos que facilitan su lectura comparativa.

Los gráficos, por su parte, son representaciones visuales de datos cuantitativos. A diferencia de una tabla, que exige al lector recorrer filas y columnas para detectar relaciones, un gráfico permite captar de un solo golpe de vista dónde se concentran los valores, cuáles se desvían de la referencia, qué participantes presentan desempeño satisfactorio o cuestionable y cómo se comparan los distintos métodos de valor asignado. La visualización, así entendida, no reemplaza al dato numérico: lo complementa y lo hace accionable.

## Visualizaciones evidenciadas en la versión histórica

La versión histórica del aplicativo (`app_v07.R`) incorpora seis visualizaciones interactivas, organizadas en pestañas temáticas (Distribución, Puntajes y Comparación). Cada una responde a una pregunta interpretativa específica:

- **Histograma por nivel.** Muestra la distribución de los valores medios de los participantes para un analito y nivel seleccionados. Permite identificar la forma de la distribución (simétrica, sesgada, bimodal) y detectar visualmente valores atípicos.

- **Diagrama de caja por participante.** Presenta la dispersión de los resultados de cada participante mediante cuartiles, mediana y bigotes. Facilita la comparación de la variabilidad entre laboratorios y la detección de resultados extremos.

- **Mapa de calor de puntajes z.** Visualización matricial en la que cada celda representa el puntaje z de un participante, coloreado según su magnitud (rojo para valores negativos, blanco para el entorno de cero, azul para valores positivos). Permite identificar rápidamente participantes con puntajes extremos.

- **Gráfico de barras de evaluación.** Conteo de participantes por categoría de evaluación del puntaje z (Satisfactorio, Cuestionable, No satisfactorio, N/A), con colores distintivos que comunican de inmediato la proporción global de desempeño.

- **Comparación de puntajes.** Gráfico de barras agrupadas que muestra, por participante, los cuatro tipos de puntaje (z, z', zeta y En), con líneas de referencia en ±2 que delimitan los umbrales de alerta. Permite contrastar cómo cambia la evaluación de un participante según el puntaje utilizado.

- **Diagrama de dispersión frente al valor asignado.** Representa a cada participante como un punto, con el valor asignado en un eje y el valor reportado en el otro, acompañado de una línea diagonal de referencia. Permite visualizar qué participantes se sitúan por encima o por debajo del valor asignado y su evaluación.

## Valor de la visualización para interpretar resultados

La incorporación de estas visualizaciones aporta valor en tres dimensiones complementarias:

1. **Detección de patrones.** La visualización permite reconocer tendencias que no son evidentes en tablas: agrupamientos de participantes, sesgos sistemáticos hacia un lado del valor asignado, o distribuciones multimodales que sugieren problemas de homogeneidad.

2. **Generación de alertas.** Los mapas de calor y los gráficos de barras, mediante códigos de color, comunican con rapidez cuántos participantes requieren seguimiento y en qué categoría se ubican, sin necesidad de revisar individualmente cada puntaje.

3. **Comparación entre métodos y participantes.** Los gráficos de comparación de puntajes y los diagramas de caja permiten contrastar resultados entre participantes y entre métodos de cálculo del valor asignado, lo que respalda decisiones técnicas sobre la idoneidad del esquema y la trazabilidad de las evaluaciones.

Las visualizaciones se complementan con la interactividad provista por el motor de gráficos de la aplicación: zoom, desplazamiento, *tooltips* informativos y exportación de imágenes. Estas capacidades permiten que el coordinador del esquema explore los datos en distintos niveles de detalle según la necesidad del análisis.

---

# Evidencia de Verificación

El entregable se acompaña de una suite de pruebas automatizadas (`test_07_graficos.R`) y de una guía de verificación visual (`test_07_graficos.md`). El alcance verificado por estos instrumentos es el siguiente:

## Verificación automatizada

El script de pruebas comprueba tres aspectos fundamentales:

1. **Instanciación de objetos gráficos.** Se verifica que el archivo `app_v07.R` contenga código que instancie de forma válida objetos gráficos de las librerías especializadas (ggplot y plotly), lo que asegura que el aplicativo posee la capacidad efectiva de generar visualizaciones y no únicamente declarar dependencias.

2. **Correspondencia entre *placeholders* y *outputs* reales.** Se valida que los marcadores de posición de gráficos definidos en la interfaz de usuario correspondan con *outputs* reales definidos en la lógica del servidor. Esta verificación garantiza que ninguna visualización quede huérfana y que la interfaz muestre efectivamente los gráficos declarados.

3. **Legibilidad sintáctica del diagrama Mermaid.** Se comprueba que el archivo `diagrama_flujo.mmd` responda a la sintaxis esperada por Mermaid, de modo que pueda ser renderizado por herramientas compatibles sin errores de parseo.

Adicionalmente, la suite verifica que los marcos de datos necesarios para alimentar cada uno de los seis gráficos puedan construirse a partir de los datos cargados, que las columnas requeridas estén presentes y que existan valores finitos aptos para graficar, y que las librerías de visualización se encuentren disponibles en el entorno de ejecución.

## Verificación visual e interactiva

La guía `test_07_graficos.md` propone un procedimiento de validación manual que recorre cada uno de los seis gráficos y verifica, tanto funcional como visualmente, que se rendericen sin errores, que la interactividad del motor de gráficos (zoom, desplazamiento, *tooltips*, exportación) opere correctamente y que los datos mostrados sean consistentes con las tablas de referencia. El procedimiento incluye una lista de comprobación final y un formato de registro de resultados para documentar la verificación ejecutada.

---

# Estado Actual

El estado documental del Entregable 07 se clasifica como **Parcial / evidencia histórica**.

La aplicación vigente (`app.R`) contiene un conjunto significativamente más amplio de vistas y visualizaciones que el mapeado en `app_v07.R`. En particular:

- Mapas de calor globales para cinco métodos de cálculo del valor asignado (referencia, consenso por media, consenso por nIQR, algoritmo A y juicio experto), cada uno con cuatro variantes de puntaje (z, z', zeta y En), lo que multiplica el número de vistas de mapa de calor respecto de la versión histórica.
- Paneles específicos de detección de valores atípicos con histogramas y diagramas de caja dedicados.
- Gráficos de seguimiento de valores por participante y por nivel.
- Evaluación de compatibilidad metrológica entre métodos.
- Generación de reportes parametrizables.

Estas capacidades no están mapeadas en el presente documento y deben formalizarse en un ejercicio de actualización documental independiente, realizado directamente sobre `app.R`, antes de declarar cobertura completa del componente de dashboards.

Asimismo, el diagrama de flujo histórico (`diagrama_flujo.mmd`) debe actualizarse para reemplazar el concepto de *datos fijos* —que refleja una etapa inicial del desarrollo en la que los archivos CSV se cargaban desde una ubicación estática— por el de *carga dinámica* y procesamiento vigente, acorde con la arquitectura actual del aplicativo.

---

# Relación con Otros Entregables

El Entregable 07 se articula con los demás entregables del proyecto como sigue:

| Entregable | Relación |
|------------|----------|
| **E05 — Prototipo de Interfaz de Usuario** | E05 define la estructura narrativa y la navegación del aplicativo; el Entregable 07 materializa esa estructura mediante las pestañas temáticas (Distribución, Puntajes, Comparación) que alojan los gráficos. |
| **E06 — Lógica de la Aplicación Shiny** | E06 documenta la lógica de negocio que alimenta las visualizaciones: carga de datos, cálculo de estadísticos robustos, evaluación de puntajes. El Entregable 07 consume esos *outputs* para alimentar los gráficos. |
| **E08 — Liberación Beta** | E08 consolida la versión beta del aplicativo; el Entregable 07 aporta el componente visual que la versión beta integra. La actualización documental pendiente del componente de dashboards debe reflejar el estado consolidado en `app.R` y coordinarse con la revisión de E08. |

---

# Riesgos y Limitaciones

La interpretación y el uso de este documento deben observar las siguientes precauciones:

- **No afirmar cobertura total.** Con base exclusivamente en el Entregable 07 no puede declararse cobertura completa de los dashboards actuales del aplicativo. `app.R` incorpora capacidades visuales adicionales (mapas de calor por múltiples métodos, paneles de *outliers*, compatibilidad metrológica y reportes) que requieren mapeo específico.

- **Lenguaje de vigencia.** Al referirse al valor del contenido, debe utilizarse la fórmula «el contenido sigue siendo útil para…» y **nunca** «cubre completamente…». Esta distinción es esencial para no sobreestimar el alcance documental del entregable.

- **Diagrama de flujo pendiente de actualización.** El diagrama `diagrama_flujo.mmd` refleja una etapa histórica con el concepto de *datos fijos*. Debe actualizarse para reemplazar esa noción por la de *carga dinámica* y procesamiento vigente, antes de emplearlo como referencia técnica autoritativa del flujo actual.

- **Dependencia del directorio de trabajo.** Algunos scripts de prueba escriben archivos de resultado y dependen del directorio de trabajo desde el cual se ejecutan, condición que debe contemplarse al reproducir la verificación en entornos distintos al de referencia.

- **Divergencia con el aplicativo vigente.** Las visualizaciones descritas corresponden a `app_v07.R` y no necesariamente reflejan la implementación, los nombres de *outputs* ni la organización de pestañas de `app.R`. Cualquier referencia operativa debe contrastarse con el aplicativo vigente.

---

# Documentos de Consulta

- ISO 13528:2022. *Statistical methods for use in proficiency testing by interlaboratory comparisons*.
- ISO 17043:2023. *Conformity assessment — Requirements for the operation of proficiency testing schemes*.
- Bitácora de Actualización de Entregables PT App, 2026-06-16 (`bitacora_actualizacion_260616.md`).
- Overview del Entregable 07 (`e7.md`).
- Guía de Verificación — Gráficos Entregable 07 (`tests/test_07_graficos.md`).
- Aplicativo vigente `app.R`.

---

# Conclusión

El Entregable 07 documenta un hito técnico del proyecto PT App: la incorporación del componente de visualización como medio para interpretar los resultados de los ensayos de aptitud conforme a ISO 13528:2022 e ISO 17043:2023. La versión histórica mapeada (`app_v07.R`) consolida seis visualizaciones interactivas —histograma, diagrama de caja, mapa de calor, gráfico de barras, comparación de puntajes y diagrama de dispersión— respaldadas por una suite de pruebas automatizadas y por una guía de verificación visual.

El contenido del entregable sigue siendo útil como evidencia trazable del momento en que el aplicativo adquirió capacidad visual, como referencia funcional para verificar las visualizaciones históricas y como base conceptual para la actualización pendiente del componente de dashboards vigente. No obstante, su estado es parcial: el aplicativo vigente incorpora un conjunto significativamente más amplio de vistas —mapas de calor por múltiples métodos de valor asignado, detección de valores atípicos, compatibilidad metrológica y reportes— que no están mapeadas en el presente documento y que requieren un ejercicio de actualización documental independiente.

Se recomienda, por tanto, iniciar la actualización del diagrama de flujo y la formalización de los dashboards vigentes directamente sobre `app.R`, coordinada con la revisión de los entregables E05, E06 y E08, de modo que la trazabilidad documental del componente visual refleje íntegramente el estado actual del aplicativo.