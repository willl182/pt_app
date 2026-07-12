# Documento Técnico — Entregable 06

## Lógica de la Aplicación y Manual de Usuario

---

**Proyecto:** PT App — Aplicativo R/Shiny para Análisis de Ensayos de Aptitud  
**Normas de referencia:** ISO 13528:2022 · ISO 17043:2023  
**Institución:** Universidad Nacional de Colombia — Sede Medellín / Instituto Nacional de Metrología (INM)  
**Laboratorio:** CALAIRE  
**Fecha de emisión:** 2026-06-28  
**Versión del documento técnico:** 1.0  
**Responsable documental:** Subagente `entregable_06_shiny_logic_manualist`  
**Estado documental del entregable:** Histórico / manual no vigente  

---

## Resumen Ejecutivo

El Entregable 06 materializa un hito de transición dentro del proyecto PT App: el paso desde un conjunto de scripts R de ejecución por lotes, separados de cualquier interfaz interactiva, hacia una aplicación web construida sobre el marco Shiny. Este documento técnico describe formalmente el contenido del entregable, su propósito en la trayectoria del proyecto, los artefactos que lo componen y la evidencia de verificación que lo respalda.

Shiny es una tecnología del ecosistema R que permite convertir cálculos y análisis estadísticos en una aplicación web interactiva, sin requerir desarrollo de frontend en HTML, JavaScript o CSS. Su característica central es la **reactividad**: un mecanismo mediante el cual los resultados se recalculan de forma automática y ordenada cada vez que el usuario modifica un dato de entrada o una selección de parámetros. En el contexto de los ensayos de aptitud, esto significa que el valor asignado, los estadísticos de dispersión robustos y los puntajes z, z', zeta y En se actualizan de manera inmediata ante cualquier cambio en el analito, el nivel o el número de laboratorios seleccionados.

El entregado se compone de un archivo de aplicación (`app_v06.R`), un manual de usuario en formato Markdown y Word, y una suite de pruebas con su bitácora de resultados. La aplicación orchestra variables reactivas, maneja la carga de cuatro archivos CSV locales con datos de homogeneidad, estabilidad, resúmenes de participantes y datos de instrumentación, y genera tablas de salida con los resultados estadísticos y la clasificación de desempeño definida por la norma.

Conviene subrayar el estado documental: el manual describió, en su momento, una versión de la aplicación que operaba con datos precargados automáticamente al iniciar. La aplicación vigente en `app.R` ha incorporado desde entonces un flujo más amplio que incluye carga dinámica de archivos mediante `fileInput`, un preprocesador de datos, botones explícitos de cálculo y generación de reportes. Por tanto, el manual del Entregable 06 **no debe emplearse como manual final del aplicativo vigente**; conserva evidencia de una fase anterior y su valor es documental, histórico y de trazabilidad.

---

## Contexto del Entregable

El Entregable 06 se ubica en la **Fase 4: Lógica de la Aplicación** de la trayectoria del proyecto. Esta fase representa el salto cualitativo desde los scripts standalone de cálculos (Entregables 03 y 04) hacia una aplicación interactiva con lógica integrada en un servidor reactivos.

En las fases precedentes, los cálculos estadísticos se ejecutaban por lotes: un script leía datos, aplicaba el Algoritmo A, calculaba los puntajes y emitía resultados. El usuario interactuaba con el algoritmo por medio de parametrización manual y reejecución. La Fase 4 introduce orquestación reactiva: los mismos cálculos quedan encapsulados en una arquitectura donde cada entrada del usuario dispara, de forma automática y controlada, la recálculo de las variables dependientes.

`app_v06.R` es la pieza central de esta fase. Orquesta variables reactivas, maneja la carga de archivos locales y genera las tablas de salida con los resultados estadísticos e ISO, exponiendo al usuario final una interfaz operacional con pestañas, selectores y botones de acción.

---

## Alcance

### Cubre

- El código fuente de `app_v06.R`, que orquesta variables reactivas y maneja la carga de archivos locales.
- El manual de usuario v06, que describe la instalación, ejecución y navegación de esta versión lógica del aplicativo.
- La suite de pruebas funcionales que verifica la lógica de negocio del servidor Shiny.
- Los puntajes PT calculados (z, z', zeta y En) y su clasificación automática de desempeño.
- Los estadísticos robustos MADe y nIQR, así como el Algoritmo A para valor asignado y desviación robusta.

### No cubre

- El flujo actual de la aplicación vigente en `app.R`, que incorpora `fileInput` para homogeneidad, estabilidad y resúmenes consolidados, referencia CALAIRE opcional, preprocesador de datos y botones explícitos de cálculo.
- La generación de reportes y otros artefactos posteriores a esta fase.
- Las visualizaciones gráficas, que se incorporaron en fases posteriores.
- La integración con el paquete `ptcalc` como motor de cálculos en la aplicación vigente.

---

## Contenido Entregado

Los artefactos del entregable se ubican en el directorio `06_app_logica/` y se relacionan en la tabla siguiente:

| # | Ruta del artefacto | Tipo | Descripción |
|---|--------------------|------|-------------|
| 1 | `app_v06.R` | Código fuente | Aplicación Shiny que orquesta las variables reactivas, maneja la carga de archivos locales y genera las tablas de salida con los resultados estadísticos e ISO. |
| 2 | `md/manual_usuario.md` | Manual (Markdown) | Guía explicativa detallada para el usuario final sobre cómo instalar, ejecutar y navegar en esta versión lógica del aplicativo. |
| 3 | `manual_usuario.docx` | Manual (Word) | Exportación del manual al formato Word, generada con pandoc, apta para distribución institucional. |
| 4 | `tests/test_06_logica.R` | Suite de pruebas | Pruebas funcionales automatizadas que simulan el inicio y el comportamiento reactivo del servidor Shiny. |
| 5 | `tests/test_06_logica.csv` | Bitácora de resultados | Registro de los resultados de la suite de pruebas, con valor obtenido, valor esperado y estado para cada caso verificado. |

---

## Explicación Funcional

### Qué es Shiny, en lenguaje común

Shiny es un marco de desarrollo del ecosistema R que permite construir aplicaciones web interactivas a partir de código R, sin necesidad de escribir por separado la lógica de presentación en HTML, CSS o JavaScript. La aplicación se compone de dos partes: una **interfaz de usuario** (que define lo que se ve en el navegador) y un **servidor** (que define lo que la aplicación hace). Ambas partes residen en un único archivo ejecutable.

### Qué significa reactividad

La **reactividad** es el mecanismo central de Shiny. Consiste en que ciertas variables de la aplicación se declaran como reactivas, es decir, dependen de entradas del usuario y, al detectar un cambio en esas entradas, se recalculan de forma automática y ordenada. Los resultados que dependen de ellas se actualizan entonces por cascada.

En términos concretos para el usuario del aplicativo PT: cuando se selecciona un analito distinto, un nivel distinto o un número distinto de laboratorios, el valor asignado, los estadísticos robustos de dispersión (MADe, nIQR), la incertidumbre del valor asignado, el factor k y los cuatro puntajes (z, z', zeta y En) se recalculan de inmediato. El usuario no necesita reejecutar ningún script ni recargar la página; la reactividad gestiona la actualización de forma transparente.

### Qué avance representa el Entregable 06

El avance fundamental respecto a los Entregables 03 y 04 es la **integración de cálculos en una arquitectura reactiva**. Las funciones del motor standalone de cálculos PT quedan encapsuladas como variables reactivas y expresiones reactivas dentro del servidor Shiny. Esto supone tres beneficios concretos:

1. **Cálculo diferido y ordenado:** las funciones estadísticas se ejecutan únicamente cuando la combinación de entradas lo requiere, evitando recálculos redundantes y eliminando los bucles infinitos de reactividad.
2. **Integridad de datos:** los datos provenientes de los CSV de entrada se parsean a nivel numérico antes de invocar las funciones del motor estadístico, evitando errores silenciosos por tipos de dato inconsistentes.
3. **Operación interactiva:** el usuario final accede a los resultados desde una interfaz con pestañas, selectores y botones, sin necesidad de modificar código ni reejecutar scripts.

### Qué cubre el manual de usuario v06

El manual describe, con detalle operativo, los siguientes aspectos de la versión v06:

- **Requisitos del sistema:** versión de R y paquetes necesarios para la ejecución.
- **Instalación y ejecución:** pasos para iniciar la aplicación desde RStudio o desde la terminal.
- **Descripción de la interfaz:** organización del panel lateral (datos precargados, selectores de analito, nivel y n) y del panel principal en pestañas.
- **Flujo de trabajo:** secuencia operativa recomendada, desde la verificación de datos de entrada hasta la exportación de resultados.
- **Cálculos implementados:** los cuatro puntajes PT y su criterio de evaluación, junto con los estadísticos robustos.
- **Exportación de datos:** opciones de descarga de tablas en formato CSV.

---

## Evidencia de Verificación

La verificación del Entregable 06 se realiza mediante la suite de pruebas `tests/test_06_logica.R`, que simula el inicio y el comportamiento reactivo del servidor Shiny. El script valida tres bloques funcionales:

1. **Carga de datos:** verifica que los cuatro archivos CSV (`homogeneity.csv`, `stability.csv`, `summary_n4.csv`, `participants_data4.csv`) se localicen y carguen sin errores, y que las estructuras resultantes contengan las columnas esperadas (`value`, `pollutant`, `level`, `participant_id`, `Codigo_Lab`, entre otras).
2. **Cálculo reactivo de puntajes:** verifica que las funciones de cálculo de puntajes devuelvan matrices no vacías y con dimensiones coherentes con el número de laboratorios participantes, y que los estadísticos robustos (MADe, nIQR) y el Algoritmo A converjan correctamente.
3. **Existencia del manual de usuario:** verifica la existencia y estructura del manual dentro de la documentación del entregable.

La bitácora `tests/test_06_logica.csv` registra los resultados de la verificación. Todos los casos arrojan estado **PASS**:

| Caso verificado | Resultado obtenido | Valor esperado | Estado |
|-----------------|--------------------|----------------|--------|
| calculate_z_score | 1.000000 | 1.000000 | PASS |
| calculate_z_prime_score | 0.980581 | 0.980581 | PASS |
| evaluate_z_score (1.5) | Satisfactorio | Satisfactorio | PASS |
| evaluate_z_score (2.5) | Cuestionable | Cuestionable | PASS |
| evaluate_z_score (3.5) | No satisfactorio | No satisfactorio | PASS |
| calculate_niqr | 0.148260 | > 0 | PASS |
| calculate_mad_e | 0.148300 | > 0 | PASS |
| run_algorithm_a (convergencia) | TRUE | TRUE | PASS |
| calculate_homogeneity_criterion | 0.150000 | 0.150000 | PASS |

Tasa de éxito: 100 % de los casos verificados.

---

## Estado Actual

**Estado documental recomendado:** Histórico, manual no vigente.

El manual del Entregable 06 describe una versión de la aplicación que opera con **datos precargados**: los cuatro archivos CSV se leen automáticamente del directorio `data/` al iniciar la aplicación, sin componentes de carga de archivos por parte del usuario. Esta característica corresponde a la fase de lógica de negocio y no refleja el flujo de operación de la aplicación vigente.

La aplicación vigente en `app.R` ha incorporado, con posterioridad a este entregable, las siguientes funcionalidades que el manual v06 no cubre:

- Componente `fileInput` para carga dinámica de archivos de homogeneidad, estabilidad y resúmenes consolidados.
- Referencia opcional CALAIRE.
- Preprocesador de datos.
- Botones explícitos de cálculo.
- Generación de reportes y visualizaciones gráficas.
- Integración con el paquete `ptcalc` como motor de cálculos.

Por tanto, el manual v06 **no debe entregarse ni emplearse como manual final del aplicativo vigente**. Su valor reside en conservar evidencia de una fase anterior del desarrollo, en aportar trazabilidad a la trayectoria del proyecto y en servir como referencia histórica del momento de transición desde scripts separados hacia aplicación interactiva.

---

## Relación con Otros Entregables

| Entregable | Relación con el Entregable 06 |
|------------|-------------------------------|
| **E03 — Cálculos PT** | Proporciona el motor standalone de cálculos estadísticos (Algoritmo A, estadísticos robustos) que el Entregable 06 integra en la arquitectura reactiva de `app_v06.R`. |
| **E04 — Puntajes** | Proporciona las funciones de cálculo y evaluación de puntajes z, z', zeta y En que el Entregable 06 orquesta como variables reactivas dentro del servidor Shiny. |
| **E05 — Prototipo de UI** | Define la estructura inicial de la interfaz de usuario (wireframes) sobre la cual el Entregable 06 implementa la lógica de negocio interactiva. |
| **E07 — Dashboards** | Construye sobre la lógica reactiva establecida en el Entregable 06 para añadir visualizaciones gráficas y dashboards interactivos. |
| **E08 — Beta** | Reúne la lógica del Entregable 06 con los dashboards del Entregable 07 en un conjunto de versión beta histórica. |
| **E09 — Informe de validación** | Audita la trayectoria completa de los entregables, incluido el Entregable 06, y consolida la evidencia documental del proyecto. |

---

## Riesgos y Limitaciones

1. **Manual no vigente:** el manual de usuario v06 no debe entregarse como manual final del aplicativo vigente. Describe una versión con datos precargados y omita el flujo con `fileInput`, preprocesador, reportes y visualizaciones posteriores.
2. **Lenguaje de estado descriptor:** al referirse a este entregable, debe usarse la fórmula "Conserva evidencia de una fase anterior del desarrollo" y **nunca** "Representa la versión actual del aplicativo". Esta distinción es crítica para que un lector no especializado no asuma que el manual describe la aplicación actual.
3. **Datos precargados:** la automatización de la carga de datos al iniciar la aplicación, propia de esta versión, no corresponde al flujo operativo vigente, basado en carga dinámica por el usuario.
4. **Ausencia de visualizaciones gráficas:** la versión v06 no incluye gráficos, dashboards ni reportes. Estas capacidades se introducen en entregables posteriores.
5. **Pruebas con dependencia de directorio:** la suite de pruebas escribe el CSV de resultados y depende del directorio de trabajo en el momento de la ejecución. Debe ejecutarse desde la raíz del proyecto para garantizar la localización de los archivos de datos.

---

## Documentos de Consulta

| Documento | Referencia |
|-----------|-----------|
| Overview del Entregable 06 | `Entregables_pt_app/e6.md` |
| Manual de usuario v06 (Markdown) | `Entregables_pt_app/06_app_logica/md/manual_usuario.md` |
| Manual de usuario v06 (Word) | `Entregables_pt_app/06_app_logica/manual_usuario.docx` |
| Suite de pruebas funcionales | `Entregables_pt_app/06_app_logica/tests/test_06_logica.R` |
| Bitácora de resultados | `Entregables_pt_app/06_app_logica/tests/test_06_logica.csv` |
| Bitácora de actualización de entregables | `Entregables_pt_app/bitacora_actualizacion_260616.md` |
| Aplicación vigente | `app.R` |
| Norma ISO 13528:2022 | Statistical methods for use in proficiency testing by interlaboratory comparisons |
| Norma ISO 17043:2023 | Conformity assessment — General requirements for the competence of proficiency testing providers |

---

## Conclusión

El Entregable 06 representa el momento en que el proyecto PT App deja de ser un conjunto de scripts de cálculo y se convierte en una aplicación interactiva con lógica de negocio integrada. La incorporación del marco Shiny y de su mecanismo de reactividad permite que los cálculos estadísticos definidos por las normas ISO 13528:2022 e ISO 17043:2023 se actualicen de forma automática y ordenada ante cualquier cambio en los datos de entrada o en las selecciones del usuario, eliminando la necesidad de reejecutar scripts por lotes.

La suite de pruebas verifica la integridad de la lógica de negocio: los cuatro archivos CSV se localizan y cargan correctamente, los puntajes devuelven matrices no vacías con dimensiones coherentes y el manual de usuario existe en la documentación del entregable. Todos los casos verificados alcanzan el estado PASS.

Conviene reiterar, por último, el alcance documental del entregable. El manual v06 conserva evidencia de una fase anterior del desarrollo, en la que el aplicativo operaba con datos precargados y sin visualizaciones gráficas. No representa la versión actual del aplicativo, que posteriormente incorporó carga dinámica de archivos, preprocesador, botones de cálculo explícitos, dashboards y generación de reportes. Se trata, por tanto, de un documento de valor histórico y de trazabilidad: una pieza en la trayectoria del proyecto hacia la aplicación vigente, cuyo lectura se preserva íntegra para comprender el camino recorrido y el fundamento de las decisiones de diseño posteriores.

---

*Universidad Nacional de Colombia — Sede Medellín / Instituto Nacional de Metrología (INM) · Laboratorio CALAIRE · 2026*