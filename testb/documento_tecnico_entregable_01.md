---
title: "Documento Técnico Formal — Entregable 01: Repositorio de Código y Scripts Iniciales"
subtitle: "Línea Base Histórica del Aplicativo PT App"
author: "Responsable Documental: Subagente `entregable_01_baseline_curator`"
date: "2026-06-28"
version: "1.0"
---

# Portada

| Campo | Valor |
|---|---|
| **Nombre del entregable** | Repositorio de Código y Scripts Iniciales |
| **Proyecto** | PT App — Aplicativo R/Shiny para ensayos de aptitud |
| **Normas de referencia** | ISO 13528:2022 · ISO 17043:2023 |
| **Institución** | Universidad Nacional de Colombia / Instituto Nacional de Metrología |
| **Fase del proyecto** | Fase 1 — Fundación |
| **Fecha del documento** | 2026-06-28 |
| **Versión del documento** | 1.0 |
| **Estado del entregable** | Histórico validado |
| **Responsable documental** | Subagente `entregable_01_baseline_curator` |
| **Licencia del proyecto** | MIT |

---

# Resumen Ejecutivo

El presente documento técnico formal describe el **Entregable 01: Repositorio de Código y Scripts Iniciales**, hito fundacional del proyecto PT App. Este entregable **conserva evidencia de una fase anterior** del aplicativo y funciona como **línea base estática** —es decir, una copia de seguridad verificable del estado inicial del código— antes de que se realicen modificaciones, mejoras o refactorizaciones posteriores.

El entregable contiene copias exactas del código fuente original del aplicativo, un conjunto de **pruebas automatizadas** que verifican la integridad de dichas copias mediante huellas digitales criptográficas (hash SHA256) y un log de resultados que evidencia la correcta ejecución de tales pruebas. En conjunto, estos elementos permiten responder con trazabilidad a la pregunta: *"¿Cómo estaba el sistema al inicio del proyecto?"*.

Este entregable **no representa la aplicación vigente** ni constituye una versión funcional final. Su propósito es estrictamente histórico y auditable: ofrecer un punto de comparación contra el cual puedan medirse, en fases posteriores, los cambios realizados sobre el aplicativo. Por ello, el contenido del entregable se mantiene congelado y no debe sincronizarse con las versiones actuales de los archivos del proyecto.

La verificación de la línea base fue exitosa: las pruebas automatizadas arrojaron **15 controles con estado PASS y 0 con estado FAIL**, confirmando que los archivos copiados son idénticos a los originales y que su sintaxis es interpretable por el lenguaje R. La bitácora de actualización del 2026-06-16 consolidó el estado documental del entregable como **"Histórico validado"**, con aclaración de que su función auditiva es preservar el estado inicial para comparación histórica.

---

# Contexto del Entregable

El proyecto PT App se desarrolla en el lenguaje R con el marco de trabajo Shiny, orientado a la gestión y el análisis estadístico de ensayos de aptitud según los estándares internacionales ISO 13528:2022 e ISO 17043:2023. El aplicativo evoluciona a través de **nueve entregables** (E01 a E09), cada uno correspondiente a una fase del ciclo de vida del software.

El Entregable 01 corresponde a la **Fase 1 — Fundación**, primer eslabón de la cadena de entregables. Su misión es establecer un punto de partida congelado y verificable, de modo que cualquier cambio posterior pueda ser auditado y comparado contra este estado inicial. En términos de control de versiones, actúa como el *baseline* o referente contra el que se mide la evolución del aplicativo.

Es importante destacar que el proyecto ha continuado su desarrollo después de este entregable. En consecuencia, **las versiones actuales de `app.R`, `R/` y `ptcalc/` difieren del contenido aquí conservado**. El Entregable 01 se mantiene intencionalmente como una fotografía del pasado, no como una instantánea del presente.

---

# Alcance

## Lo que cubre el entregable

- Conservación de copias exactas del código fuente original del aplicativo PT App (aplicación principal y funciones de cálculo).
- Verificación automatizada de la integridad de las copias mediante hash SHA256 y parseo sintáctico R.
- Evidencia documental del estado inicial del proyecto, con trazabilidad hacia las fases posteriores.

## Lo que NO cubre el entregable

- **No** demuestra que la aplicación final esté validada.
- **No** representa la versión actual ni vigente del aplicativo.
- **No** ejecuta la aplicación Shiny ni valida su comportamiento funcional en tiempo de ejecución.
- **No** valida la corrección matemática de los cálculos; únicamente verifica conservación y sintaxis del punto inicial.
- **No** sustituye a los procedimientos de validación funcional del sistema completo.

---

# Contenido Entregado

El entregable se organiza en tres componentes: **aplicación principal**, **funciones de cálculo** y **pruebas de verificación**, complementados por documentación de soporte. A continuación se presenta el inventario detallado:

| Archivo | Categoría | Descripción | Ubicación relativa |
|---|---|---|---|
| `app_original.R` | Código fuente | Copia de respaldo de la aplicación Shiny principal (`app.R`) antes de cambios estructurales. | `/` |
| `R/pt_homogeneity.R` | Código fuente | Funciones originales de homogeneidad y estabilidad. | `R/` |
| `R/pt_robust_stats.R` | Código fuente | Funciones estadísticas robustas originales. | `R/` |
| `R/pt_scores.R` | Código fuente | Funciones de cálculo de puntajes PT originales. | `R/` |
| `R/utils.R` | Código fuente | Utilidades auxiliares originales. | `R/` |
| `tests/test_01_existencia_archivos.R` | Prueba automatizada | Script R que verifica existencia, integridad (hash SHA256) y sintaxis de los archivos de la línea base. | `tests/` |
| `tests/test_01_existencia_archivos.md` | Guía de prueba | Documento explicativo con instrucciones de ejecución e interpretación de resultados del test. | `tests/` |
| `tests/test_01_existencia_archivos.docx` | Anexo documental | Copia en formato Microsoft Word de la guía de prueba. | `tests/` |
| `README.md` | Documentación | Documento guía del entregable, con resumen, inventario y próximos pasos. | `/` |
| `README.docx` | Documentación | Copia en formato Microsoft Word del README. | `/` |
| `test_01_resultados.csv` | Reporte de pruebas | Log con los resultados de la ejecución de las pruebas automatizadas (15 controles, todos PASS). | `/` |

**Sumario del contenido:**

- **5 archivos de código fuente** R (aplicación principal y cuatro módulos de funciones).
- **1 script de prueba** automatizada con tres tipos de verificación.
- **3 documentos de prueba y soporte** (guía en MD, DOCX y log de resultados en CSV).
- **2 documentos README** (MD y DOCX) a nivel del entregable.

---

# Explicación Funcional

Esta sección traduce los conceptos técnicos del entregable a un lenguaje comprensible para lectores no desarrolladores, sin perder precisión conceptual.

## ¿Qué es una línea base?

Una **línea base** (*baseline*) es una fotografía congelada del estado de un sistema en un momento específico. Funciona como una referencia: si en el futuro alguien pregunta *"¿qué cambió desde el inicio?"*, basta comparar el estado actual contra la línea base para obtener la respuesta. Es análoga a una copia de seguridad verificable: no es la versión final del sistema, sino la evidencia de cómo estaba todo antes de iniciar los cambios.

En el Entregable 01, esta línea base se compone de copias exactas del código original. Esas copias no se modifican jamás; su único propósito es servir como punto de comparación.

## ¿Qué es un hash SHA256?

Un **hash SHA256** es una huella digital criptográfica de un archivo. Se trata de una cadena de 64 caracteres generada por un algoritmo matemático a partir del contenido exacto del archivo. La propiedad esencial de esta huella es:

- Si dos archivos tienen el mismo contenido byte a byte, producen **exactamente el mismo hash**.
- Si se altera incluso un solo carácter (o un espacio en blanco) del archivo, el hash cambia por completo.

Por ello, comparar los hashes de dos archivos es una manera confiable de confirmar que son idénticos. En este entregable, el script de prueba calcula el hash de cada archivo original y lo compara con el de su copia: si coinciden, la copia es fiel al original.

## ¿Qué es el parseo sintáctico?

El **parseo sintáctico** es un proceso mediante el cual un programa analiza el código de un archivo para confirmar que está escrito con una gramática correcta —es decir, que respeta las reglas del lenguaje de programación—. En este caso, el script de prueba le pide a R que "lea" cada archivo de código y verifique que no contiene errores de sintaxis.

Es importante entender que el parseo sintáctico **no ejecuta el código**: solo confirma que el texto puede ser interpretado como instrucciones válidas de R. No garantiza que el programa funcione correctamente, sino que está bien escrito desde el punto de vista estructural.

---

# Evidencia de Verificación

El entregable cuenta con una **prueba automatizada** (`test_01_existencia_archivos.R`) que realiza tres tipos de verificación sobre los archivos de la línea base. A continuación se describen las verificaciones y cómo interpretar sus resultados.

## Verificaciones realizadas

| # | Tipo de verificación | Qué valida | Cantidad de controles |
|---|---|---|---|
| 1 | Existencia de archivos | Confirma que los 5 archivos originales existen en `pt_app/` y que las 5 copias existen en el entregable. | 5 |
| 2 | Integridad por hash SHA256 | Calcula y compara la huella digital de cada copia contra un valor esperado registrado en el script de prueba. | 5 |
| 3 | Parseo sintáctico R | Verifica que cada archivo de código R puede ser interpretado sin errores de sintaxis por el lenguaje R. | 5 |

**Total de controles ejecutados: 15.**

## Resultados obtenidos

La ejecución de las pruebas produjo el reporte almacenado en `test_01_resultados.csv`, con el siguiente consolidado:

| Métrica | Valor |
|---|---|
| Controles ejecutados | 15 |
| Controles con estado **PASS** | 15 |
| Controles con estado **FAIL** | 0 |

## Cómo interpretar los resultados

- **Estado PASS**: el archivo existe, su hash coincide con el esperado y/o su sintaxis es válida. Indica que la copia conservada es fiel al original.
- **Estado FAIL**: indicaría una de las siguientes causas posibles: ausencia de archivo, modificación accidental del contenido (hash distinto) o error de sintaxis en el código R. En el caso de este entregable, **no se registraron controles con estado FAIL**.

## Consideraciones de interpretación

Existe una prueba automatizada que verifica **la conservación e integridad** de la línea base. Esto **no** equivale a afirmar que el sistema está libre de errores funcionales o que la aplicación se ejecuta correctamente en tiempo de ejecución. El objetivo de la verificación es estrictamente histórico: confirmar que el punto inicial fue capturado y conservado de forma fiable.

---

# Estado Actual

El Entregable 01 se conserva con el estado documental de **Histórico validado**, asignado mediante la bitácora de actualización del 2026-06-16. Este estado significa que:

1. La línea base fue capturada y verificada en su momento; las pruebas automatizadas confirmaron su integridad.
2. El entregable **no representa la aplicación vigente**. Las versiones actuales de `app.R`, `R/` y `ptcalc/` han evolucionado desde la captura de esta línea base.
3. Su función es estrictamente **auditiva y de comparación histórica**: preservar el estado inicial para que cualquier cambio posterior pueda ser contrastado contra este referente.

En consecuencia, el contenido del entregable debe mantenerse sin alteraciones y no debe sincronizarse con las versiones actuales del proyecto. Cualquier modificación al entregable INVALIDARÍASU función como línea base.

> **Frase correcta de uso:** *"El Entregable 01 conserva evidencia de una fase anterior del aplicativo, como línea base histórica validada."*
>
> **Frase a evitar:** *"El Entregable 01 representa la versión actual del aplicativo."*

---

# Relación con Otros Entregables

El Entregable 01 es el primero de una secuencia de nueve entregables (E01–E09) que conforman la trazabilidad documental del proyecto PT App. Su relación con los entregables vecinos es la siguiente:

| Entregable | Relación con E01 |
|---|---|
| **E01** — Repositorio de Código y Scripts Iniciales | **Línea base estática.** Punto de comparación para todos los entregables posteriores. |
| **E02** — Funciones Usadas | Toma el código original conservado en E01 como referencia para inventariar y documentar funciones. |
| **E03** — Cálculos PT Standalone | Contrastable contra las funciones de cálculo de E01 para detectar divergencias. |
| **E04** — Puntajes | Utiliza el código de `pt_scores.R` conservado en E01 como referente histórico. |
| **E05** — Prototipo de UI | Referencia histórica de la interfaz inicial; el aplicativo evolucionó hacia una navegación distinta. |
| **E06** — Lógica de la Aplicación | Manual histórico que describe una versión con datos precargados, no el flujo actual. |
| **E07** — Dashboards | Evidencia parcial de visualizaciones históricas; no cubre las visualizaciones actuales. |
| **E08** — Beta | Versión beta histórica que no coincide con el `app.R` vigente. |
| **E09** — Informe de Validación | Requiere auditoría de evidencia; su trazabilidad hacia E01 es de carácter histórico. |

La bitácora de actualización del 2026-06-16 consolidó la matriz de discrepancias entre entregables y los estados recomendados para cada uno. Esta bitácora es el documento de referencia para entender la evolución documental del proyecto.

---

# Riesgos y Limitaciones

| Riesgo / Limitación | Descripción | Recomendación |
|---|---|---|
| **No valida la aplicación final** | El entregable solo demuestra conservación del punto inicial, no la validez funcional del sistema vigente. | Usar el entregable exclusivamente como referente histórico. Validar la aplicación actual por separado. |
| **No debe confundirse con versión vigente** | Existe el riesgo de interpretar el contenido como la versión actual del aplicativo. | Emplear siempre la fórmula *"línea base histórica validada"* y nunca *"sistema validado"* o *"versión funcional final"*. |
| **Sensibilidad a modificaciones accidentales** | Cualquier alteración, incluso de un espacio en blanco, cambia el hash SHA256 y rompe la línea base. | Proteger la carpeta del entregable contra escritura accidental y re-ejecutar el test tras cualquier intervención. |
| **Dependencia del directorio de trabajo** | El script de prueba detecta el directorio raíz del proyecto buscando `app.R`, lo que depende del directorio actual. | Ejecutar el test desde una ubicación dentro del proyecto o ajustar rutas según el entorno. |
| **Parseo sintáctico ≠ ejecución** | La prueba de sintaxis confirma que el código es interpretable, no que se ejecuta sin errores. | No interpretar un estado PASS como ausencia de errores funcionales. |

---

# Documentos de Consulta

Los siguientes archivos complementan y amplían el contenido del presente documento. Las rutas son relativas al directorio raíz del proyecto (`pt_app/`):

| Tipo | Ruta relativa | Descripción |
|---|---|---|
| Overview del entregable | `Entregables_pt_app/e1.md` | Resumen ejecutivo del Entregable 01 con inventario y trazabilidad. |
| README del entregable | `Entregables_pt_app/01_repo_inicial/README.md` | Documento guía con objetivo, descripción, archivos incluidos y próximos pasos. |
| Script de prueba | `Entregables_pt_app/01_repo_inicial/tests/test_01_existencia_archivos.R` | Prueba automatizada en R que verifica existencia, hash SHA256 y sintaxis. |
| Guía de prueba | `Entregables_pt_app/01_repo_inicial/tests/test_01_existencia_archivos.md` | Instrucciones de ejecución, interpretación de resultados y solución de problemas. |
| Réplica DOCX de la guía | `Entregables_pt_app/01_repo_inicial/tests/test_01_existencia_archivos.docx` | Copia en formato Microsoft Word de la guía de prueba. |
| Log de resultados | `Entregables_pt_app/01_repo_inicial/test_01_resultados.csv` | Reporte tabular con los 15 controles ejecutados y su estado. |
| Bitácora de actualización | `Entregables_pt_app/bitacora_actualizacion_260616.md` | Consolidado de la actualización documental del 2026-06-16, con matriz de discrepancias, riesgos técnicos y verificación recomendada. |
| Plan de actualización | `logs/plans/260616_1047_plan_actualizar-entregables-pt-app.md` | Plan maestro que dio origen a la actualización documental. |

---

# Conclusión

El Entregable 01 constituye el **fundamento histórico** del proyecto PT App. Su valor reside en ofrecer una **línea base estática, verificable y trazable** del estado inicial del aplicativo, capturada antes de cualquier modificación posterior. Como línea base histórica validada, conserva evidencia de una fase anterior del aplicativo y habilita la comparación auditable de los cambios realizados en las fases siguientes.

La robustez de esta línea base se sustenta en tres mecanismos de verificación automatizada —existencia, integridad criptográfica y parseo sintáctico— cuyos 15 controles arrojaron resultados conformes, sin fallos registrados. Esta evidencia permite afirmar con confianza que el punto inicial del proyecto fue capturado y conservado de forma íntegra.

**Recomendación de uso:** emplear el Entregable 01 únicamente como referente histórico. No debe confundirse con la versión vigente del aplicativo ni utilizarse para validar el comportamiento funcional del sistema actual. Su función es servir como punto de comparación contra el que se midan, en cualquier momento, las modificaciones introducidas en las fases posteriores del proyecto PT App.