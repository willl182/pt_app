# Documento Técnico del Entregable 08

## Versión Beta y Documentación Final del Aplicativo PT App

---

**Proyecto:** PT App — Aplicativo R/Shiny para Ensayos de Aptitud (ISO 13528:2022 / ISO 17043:2023)

**Institución:** Universidad Nacional de Colombia / Instituto Nacional de Metrología

**Entregable:** 08 — Versión Beta y Documentación Final

**Fase de desarrollo:** Fase 6 — Consolidación (Beta)

**Fecha de emisión del documento:** 2026-06-28

**Versión del documento:** 1.0

**Responsable documental:** Subagente `entregable_08_beta_release_documenter` — *Release & Documentation Manager*

**Clasificación documental:** Histórico / beta no vigente

**Licencia del software:** MIT (Universidad Nacional de Colombia / Instituto Nacional de Metrología)

---

## Resumen Ejecutivo

Este documento técnico describe el Entregable 08 del proyecto PT App, correspondiente a la **Versión Beta y Documentación Final** del aplicativo R/Shiny para ensayos de aptitud, desarrollado conforme a ISO 13528:2022 e ISO 17043:2023. El entregable se produjo durante la Fase 6 de desarrollo (Consolidación) como el hito de integración en el que todos los módulos construidos previamente de forma parcial se unifican en una versión ejecutable y trazable del aplicativo.

En línea con la bitácora de actualización de 2026-06-16, el Entregable 08 se clasifica **documentalmente como histórico y beta no vigente**. Esta clasificación responde al hecho de que, a la fecha, la aplicación principal vigente del proyecto es `app.R` y la lógica reutilizable se encuentra organizada en el paquete `ptcalc/R/`. La beta del Entregable 08 se conserva como evidencia de una fase anterior de consolidación y no representa la arquitectura actual del sistema.

El entregable comprende la aplicación consolidada (`app_final.R`), la biblioteca consolidada de funciones estadísticas independientes (`R/funciones_finales.R`), el manual del desarrollador en formatos Markdown y Word, y un conjunto de pruebas de integración de extremo a extremo (`test_08_end_to_end.R`) acompañado de su guía de ejecución. Las pruebas validan que el flujo completo — carga de datos, evaluación de homogeneidad, cálculo de puntajes de desempeño y generación de resúmenes — puede recorrerse sin lanzar excepciones en una sesión simulada.

El propósito de este documento es explicar a un lector institucional — sin formación necesariamente en desarrollo de software — qué representa esta beta, qué evidencia aporta al proyecto, en qué se diferencia de la versión vigente y por qué su conservación documental es relevante para la trazabilidad del aplicativo. Para ello, se evita el lenguaje de un manual de usuario o de un README técnico y se adopta un enfoque descriptivo centrado en el significado, el alcance y el estado actual del entregable.

---

## Contexto del Entregable

El Entregable 08 se ubica en la **Fase 6: Consolidación (Beta)** del ciclo de desarrollo del proyecto PT App. Esta fase se caracteriza por integrar, en una única versión de trabajo, todos los módulos previamente construidos en entregables anteriores: carga de datos, evaluación de homogeneidad y estabilidad, preparación del esquema de ensayo de aptitud, cálculo de puntajes de desempeño (z, z' prima, zeta y En) y visualización global mediante un heatmap de resultados. La consolidación se materializa en un único archivo de aplicación (`app_final.R`) junto a una biblioteca de funciones independientes (`funciones_finales.R`).

Conviene aclarar, para el lector no especializado, qué significa el término **beta** en este contexto. Una versión beta es una versión integrada de prueba: corresponde al momento del desarrollo en el que todas las partes del aplicativo se unen por primera vez para verificar que funcionen correctamente en conjunto, antes de declararse una versión final de uso operativo. La beta depura la integración; no necesariamente representa la versión final actualmente operativa. En el caso del Entregable 08, esta beta fue válida en su momento, pero la versión vigente del proyecto evolucionó posteriormente hacia la arquitectura actual basada en `app.R` y el paquete `ptcalc`.

La fase de consolidación reúne los aportes de los entregables previos del ciclo: la línea base del repositorio (E01), el inventario de funciones (E02), los cálculos estadísticos (E03 y E04), el prototipo de interfaz (E05), la lógica reactiva de Shiny (E06) y los dashboards de visualización (E07). Su rol es asegurar que las piezas independientes se integren en un todo coherente y trazable, condición previa necesaria para el cierre del ciclo con la validación final (E09).

---

## Alcance

### Cobertura del documento

Este documento cubre los siguientes elementos del Entregable 08:

- La aplicación Shiny consolidada `app_final.R`, descrita funcionalmente como integración de módulos.
- La biblioteca consolidada de funciones estadísticas `R/funciones_finales.R`, descrita en su rol de capa de negocio independiente.
- El manual del desarrollador beta, en sus versiones Markdown (`md/manual_desarrollador.md`) y Word (`manual_desarrollador.docx`).
- Las pruebas de integración de extremo a extremo (`tests/test_08_end_to_end.R`) y su guía de ejecución (`test_08_end_to_end.md`, `test_08_end_to_end.docx`).
- El estado documental de la beta y su separación respecto de la arquitectura vigente.

### Exclusiones

Este documento **no cubre**:

- La aplicación principal vigente `app.R` (objeto de documentación independiente del estado actual del proyecto).
- El paquete `ptcalc/R/` (lógica estadística reutilizable, con archivos `ptcalc-package.R`, `pt_robust_stats.R`, `pt_scores.R` y `pt_homogeneity.R`).
- Los helpers de la aplicación vigente en el directorio `R/` del proyecto.
- El flujo de actualización concreto de la beta hacia la arquitectura vigente, el cual se trata en la bitácora de actualización del 2026-06-16 y en el overview `e8.md`.

La separación entre lo cubierto y lo excluido es deliberada: el Entregable 08 describe un punto en el tiempo del desarrollo y no debe leerse como referencia técnica de la arquitectura vigente.

---

## Contenido Entregado

El Entregable 08 se compone de los siguientes archivos, organizados dentro del directorio `Entregables_pt_app/08_beta/`:

| Archivo | Tipo | Descripción |
|---|---|---|
| `app_final.R` | Código fuente R | Aplicación Shiny consolidada con todos los módulos activos: carga de datos, homogeneidad y estabilidad, preparación PT, cálculo de puntajes, heatmap global y descarga de reportes. |
| `R/funciones_finales.R` | Código fuente R | Biblioteca consolidada y depurada con toda la lógica estadística independiente — estadística robusta, homogeneidad, estabilidad y puntajes — sin dependencias de Shiny. |
| `md/manual_desarrollador.md` | Documentación técnica | Guía de referencia del desarrollador: arquitectura MVC, dependencias, estructura de archivos, operaciones de extensión, pautas de solución de problemas y referencias ISO. |
| `manual_desarrollador.docx` | Documentación técnica | Versión Word del manual del desarrollador, exportada mediante pandoc. |
| `tests/test_08_end_to_end.R` | Pruebas de integración | Prueba de integración de extremo a extremo que simula la interacción del usuario en todas las vistas y recorre el flujo de cálculo completo. |
| `tests/test_08_end_to_end.md` | Guía de pruebas | Documento de guía para la ejecución e interpretación de la prueba E2E. |
| `tests/test_08_end_to_end.docx` | Guía de pruebas | Versión Word de la guía de pruebas, exportada mediante pandoc. |

Los archivos de datos (`homogeneity.csv`, `stability.csv`, `summary_n4.csv`, `participants_data4.csv`) no forman parte del Entregable 08 en sí: son insumos compartidos del proyecto ubicados en el directorio `data/`, necesarios para ejecutar la aplicación y las pruebas.

---

## Explicación Funcional

### Qué representa la beta

La beta del Entregable 08 representa el momento en el que el aplicativo PT App alcanza una versión integrada de prueba. A diferencia de los entregables anteriores, que documentaban piezas aisladas del sistema, el Entregable 08 reúne por primera vez todos los módulos funcionales en un único ejecutable verificable. Esta integración responde a una arquitectura MVC clásica:

- **Capa de presentación**: interfaz Shiny con pestañas de navegación, tablas interactivas, gráficos y botones de descarga.
- **Capa de lógica (controlador)**: el servidor Shiny, encargado de orquestar la reactividad, los filtros y las llamadas a las funciones de cálculo.
- **Capa de negocio (modelo)**: la biblioteca `funciones_finales.R`, con funciones puras de cálculo estadístico (sin dependencias de Shiny) que son testeables de forma independiente.
- **Capa de datos**: los archivos CSV de entrada, leídos por la aplicación en el arranque.

La separación entre la biblioteca de funciones y la aplicación Shiny permite que las cálculos estadísticos — base del cumplimiento normativo ISO 13528:2022 — sean verificables por separado de la interfaz, condición indispensable para la trazabilidad metrológica del aplicativo.

### Qué validan las pruebas E2E

Las pruebas de integración de extremo a extremo (`test_08_end_to_end.R`) forman un conjunto de 19 casos que validan que el flujo completo del aplicativo se puede recorrer sin errores esperados. En concreto, las pruebas verifican:

1. La existencia y el parseo correcto del archivo `app_final.R`.
2. La carga y unión reactiva de los conjuntos de datos en una sesión simulada.
3. Que el flujo de cálculo completo — desde homogeneidad hasta puntajes de desempeño y resúmenes de resultados — se completa de forma consecutiva, sin lanzar excepciones.
4. La cobertura funcional de cada componente estadístico: puntajes z, z' prima, zeta y En; sus evaluaciones; estadística robusta (nIQR, MADe y Algoritmo A); evaluación de homogeneidad y estabilidad; resúmenes por participante.
5. La existencia y el formato correcto de los archivos de datos de entrada.

El estado esperado de la batería es 19/19 pruebas superadas, lo que constituye la evidencia objetiva de que la integración funciona como se espera en una sesión simulada.

### Diferencia con la versión vigente

A la fecha de este documento, la aplicación principal vigente del proyecto es `app.R`, no `app_final.R`. De igual modo, la lógica reutilizable vigente se encuentra organizada en el paquete `ptcalc/R/` (con `ptcalc-package.R`, `pt_robust_stats.R`, `pt_scores.R` y `pt_homogeneity.R`), no en `funciones_finales.R`.

La diferencia esencial es la siguiente:

- `app_final.R` y `funciones_finales.R` corresponden a una **consolidación histórica** que reunió los módulos en un punto del tiempo del desarrollo.
- `app.R` y `ptcalc/R/` corresponden a una **arquitectura vigente** que ha evolucionado posteriormente a esa consolidación: el paquete `ptcalc` cumple el rol que cumplía `funciones_finales.R`, y `app.R` cumple el rol que cumplía `app_final.R`.

En consecuencia, la beta del Entregable 08 se conserva como evidencia documental de una fase anterior del desarrollo, no como referencia operativa. Las correcciones técnicas posteriores (por ejemplo, la firma polimórfica de `calculate_homogeneity_criterion_expanded()` en `ptcalc/R/pt_homogeneity.R` o la normalización de la etiqueta "No satisfactorio" entre `ptcalc/R/pt_scores.R` y `app.R`) se aplicaron en la arquitectura vigente, no en la beta.

---

## Evidencia de Verificación

El test end-to-end del Entregable 08 aporta evidencia objetiva de la integración funcional de la beta. La batería verifica tres aspectos nucleares exigidos por el overview `e8.md`:

1. **Existencia y parseo de `app_final.R`**. La prueba verifica que el archivo de la aplicación consolidada existe y se carga sin errores de sintaxis.

2. **Carga y unión reactiva de datos**. La prueba verifica que los cuatro archivos CSV de entrada (`homogeneity.csv`, `stability.csv`, `summary_n4.csv`, `participants_data4.csv`) están presentes en `data/` y contienen las columnas clave esperadas (`pollutant`, `participant_id`, `mean_value`, `sd_value`).

3. **Flujo completo sin excepciones**. La prueba recorre el flujo en una sesión simulada: carga de funciones, evaluación de homogeneidad, cálculo de puntajes de desempeño (z, z' prima, zeta y En) y generación de resúmenes por participante. El flujo debe completarse de forma consecutiva sin lanzar excepciones.

Adicionalmente, la batería cubre casos límite declarados relevantes: valores inválidos (p. ej., `sigma_pt` igual a cero) deben retornar `NA` y no propagar el error; vectores de datos insuficientes (menos de dos valores para nIQR, menos de tres para Algoritmo A) deben retornar `NA` o un mensaje de error controlado; valores `NA` propagados en los puntajes deben clasificarse como "N/A".

El estado esperado es 19/19 pruebas superadas, conforme a la guía `test_08_end_to_end.md`. Esta evidencia se considera válida para la beta del Entregable 08, sin extender su validez a la arquitectura vigente.

---

## Estado Actual

El estado documental del Entregable 08 es **Histórico / beta no vigente**. Esta clasificación es coherente con la bitácora de actualización de 2026-06-16 y con el overview del entregable, y responde a tres razones objetivas:

1. `app_final.R` y `R/funciones_finales.R` fueron reemplazados funcionalmente por la arquitectura vigente (`app.R` y el paquete `ptcalc/R/`).
2. El manual del desarrollador de la beta describe una versión con datos precargados y patrones de navegación que ya no corresponden al flujo actual del aplicativo.
3. La propia bitácora de actualización recomienda separar explícitamente la beta histórica de la arquitectura vigente para evitar lecturas inexactas del documento.

La conservación de la beta histórica es deliberada y se justifica por su valor de trazabilidad: documenta el momento del proyecto en que los módulos se integraron por primera vez y permite contrastar el camino recorrido hasta la arquitectura vigente.

---

## Relación con Otros Entregables

El Entregable 08 se relaciona con los demás entregables del proyecto del siguiente modo:

- **E06 (Lógica de la aplicación)**: el Entregable 08 integra, en `app_final.R`, la lógica reactiva de Shiny documentada en E06. La diferencia es que E06 describe la lógica de forma aislada, mientras que E08 la materializa en una aplicación consolidada ejecutable.

- **E07 (Dashboards de visualización)**: el Entregable 08 incorpora, en `app_final.R`, las visualizaciones y dashboards documentados como prototipo en E07, integrándolos en el flujo reactivo del aplicativo.

- **E09 (Validación final)**: el Entregable 08 constituye la base sobre la cual se sustenta la validación final del E09. La batería de pruebas E2E del E08 aporta evidencia preliminar de integración, mientras que E09 consolida la auditoría de validación global del aplicativo.

Esta relación refuerza el carácter de la beta del E08 como hito intermedio del ciclo — no como cierre definitivo — y subraya la necesidad de leerla en conjunto con los entregables precedentes y con la validación final.

---

## Riesgos y Limitaciones

Se identifican los siguientes riesgos y limitaciones documentales asociados al Entregable 08:

- **Riesgo de confusión terminológica con "final"**. El nombre histórico del entregable ("Versión Beta y Documentación Final") puede inducir a creer que se trata de la versión final contractual del aplicativo. Esta lectura es incorrecta y debe contrastarse en todo momento con el estado documental **Histórico / beta no vigente**. La beta **conserva evidencia de una fase anterior del desarrollo**; en ningún caso **representa la versión actual** del aplicativo.

- **Riesgo de confusión entre `app_final.R` y `app.R`**. La coincidencia del adjetivo "final" en el archivo de la beta con la idea convencional de versión final del proyecto representa un riesgo de lectura inexacta. Debe subrayarse en cualquier uso del entregable que la aplicación vigente es `app.R`.

- **Divergencia entre la biblioteca beta y la lógica vigente**. `funciones_finales.R` y el paquete `ptcalc/R/` comparten origen histórico pero han divergido: el paquete vigente recibió correcciones técnicas (firma polimórfica, normalización de etiquetas) que no se aplicaron a la biblioteca de la beta. Las dos líneas no deben mezclarse en una misma referencia.

- **Manual del desarrollador desactualizado respecto de la arquitectura vigente**. El manual del desarrollador de la beta describe una arquitectura MVC basada en `funciones_finales.R` y un flujo con datos precargados. Esta descripción **no corresponde** a la arquitectura vigente basada en `app.R`, helpers en `R/`, preprocesador y paquete `ptcalc`. El manual debe leerse como un documento histórico y separarse claramente de la documentación técnica vigente. No debe usarse como guía de mantenimiento de la arquitectura actual.

- **Sensibilidad de la batería de pruebas al directorio de trabajo**. La batería E2E del entregable depende de la ruta relativa de los archivos y de la ubicación de ejecución. Esta dependencia es conocida y está documentada en la guía de pruebas; no invalida la evidencia, pero exige reproducir las condiciones de ejecución indicadas para obtener resultados equivalentes.

- **Casos límite en estadística robusta**. El Algoritmo A puede no converger para datos con alta dispersión, comportamiento documentado en la guía de pruebas como eventualidad esperada y no como defecto de integración.

---

## Documentos de Consulta

Para contextualizar este documento técnico, se recomienda consultar la siguiente documentación del proyecto:

- **Overview del entregable**: `Entregables_pt_app/e8.md`. Descripción resumida del entregable, su estado y la actualización de trazabilidad.
- **Manual del desarrollador (beta)**: `Entregables_pt_app/08_beta/md/manual_desarrollador.md` y su versión Word `manual_desarrollador.docx`. Guía de referencia técnica de la beta.
- **Guía de pruebas E2E**: `Entregables_pt_app/08_beta/tests/test_08_end_to_end.md` y su versión Word `test_08_end_to_end.docx`. Instructivo de ejecución e interpretación de resultados.
- **Bitácora de actualización**: `Entregables_pt_app/bitacora_actualizacion_260616.md`. Registro de la revisión documental del 2026-06-16 que reclasificó el estado del entregable.
- **Documentación vigente del proyecto**: archivos `app.R`, directorio `R/` (helpers) y paquete `ptcalc/R/` (lógica estadística reutilizable), que constituyen la arquitectura vigente del aplicativo.
- **Normas de referencia**: ISO 13528:2022 (métodos estadísticos para ensayos de aptitud por comparación interlaboratorial) e ISO 17043:2023 (requisitos generales para ensayos de aptitud).

---

## Conclusión

El Entregable 08 documenta un hito de consolidación del proyecto PT App: el momento en el que los módulos desarrollados de forma alternativa se unificaron en una versión beta verificable, junto con un manual del desarrollador y una batería de pruebas de integración de extremo a extremo. Su valor actual es documental: aporta evidencia de la trayectoria del aplicativo y permite contrastar la consolidación histórica con la arquitectura vigente basada en `app.R` y el paquete `ptcalc`.

La lectura correcta de este entregable exige distinguir, en todo momento, dos planos: por una parte, la **beta histórica**, conservada como evidencia de una fase anterior; por otra, la **arquitectura vigente**, objeto de mantenimiento y referencia operativa. El presente documento técnico se redacta bajo esa distinción y se clasifica como **Histórico / beta no vigente**, conforme a la bitácora de actualización de 2026-06-16 y al overview `e8.md`.

La conservación de la beta no implica vigencia operativa. Implica, por el contrario, trazabilidad: la posibilidad de reconstruir el recorrido del aplicativo desde su consolidación inicial hasta su estado actual, condición indispensable para el cumplimiento documental exigido por las normas ISO de referencia bajo las que se desarrolla el proyecto.

---

**Fin del documento técnico del Entregable 08**

**Versión del documento:** 1.0 | **Fecha de emisión:** 2026-06-28 | **Clasificación:** Histórico / beta no vigente