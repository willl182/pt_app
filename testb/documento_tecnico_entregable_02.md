---
title: "Documento Técnico del Entregable 02"
subtitle: "Funciones Usadas en app.R, R/ y ptcalc/R/"
author: "PT App - Universidad Nacional de Colombia / Instituto Nacional de Metrología"
date: "2026-06-28"
version: "1.0"
---

\newpage

# Portada

| Campo | Valor |
|-------|-------|
| **Nombre del entregable** | Funciones Usadas en `app.R`, `R/` y `ptcalc/R/` |
| **Proyecto** | PT App - Aplicativo R/Shiny para ensayos de aptitud |
| **Institución** | Universidad Nacional de Colombia / Instituto Nacional de Metrología |
| **Norma de referencia** | ISO 13528:2022 e ISO 17043:2023 |
| **Fase de desarrollo** | Fase 1: Fundación |
| **Fecha del documento** | 2026-06-28 |
| **Versión del documento** | 1.0 |
| **Estado del entregable** | Regenerado y enriquecido (2026-06-16) |
| **Responsable documental** | Subagente `entregable_02_function_inventory_auditor` |

\newpage

# Resumen Ejecutivo

El presente documento técnico describe el contenido, alcance y estado actual del **Entregable 02 — Funciones Usadas en `app.R`, `R/` y `ptcalc/R/`**, correspondiente a la Fase 1 (Fundación) del proyecto PT App. Este entregable constituye el inventario funcional oficial de la aplicación: un mapa de capacidades que registra qué funciones existen, para qué sirven, dónde están definidas y cómo se documentan.

La versión original del inventario, fechada el 2026-01-24, contenía **48 funciones** con descripciones escuetas y sin ejemplos, referencias ISO ni categorización funcional. En la actualización del **2026-06-16**, el subagente `entregable_02_function_inventory_auditor` reescribió por completo el extractor de firmas (`R/lista_funciones.R`), ampliando el parser de bloques roxygen2 a la totalidad de etiquetas relevantes (título, descripción, `@param`, `@return`, `@examples`, `@seealso`, `@references`, `@export`, badges de `lifecycle`) y añadiendo anotaciones manuales para las funciones internas de `app.R` y el informe parametrizado `reports/report_template.Rmd` que carecen de documentación roxygen2.

Como resultado, el inventario pasó a cubrir **77 funciones únicas**, distribuidas en **10 categorías funcionales**, de las cuales **24 son exportadas** (`@export`) y **3 están marcadas como obsoletas** (`lifecycle::badge("deprecated")`). El catálogo se entrega en tres formatos complementarios: una tabla indexada para consumo automatizado (`funciones_extraidas.csv`), un catálogo legible en Markdown (`md/documentacion_funciones.md`) y su versión exportable a Word (`documentacion_funciones.docx`).

La verificación del entregable se realiza mediante un test automatizado en R (`test_02_firma_funciones.R`) que valida la existencia y ejecución de las 18 funciones principales de cálculo, con cobertura de todas las familias críticas: estadísticos robustos, puntajes PT, homogeneidad y estabilidad. La bitácora de resultados (`test_02_resultados.csv`) registra **36 pruebas individuales, todas con estado PASS**.

Este documento no busca reemplazar el catálogo detallado de firmas —el cual se entrega en `documentacion_funciones.docx`— sino ofrecer a coordinadores, auditores y usuarios no programadores una visión comprensible de las capacidades de la aplicación y de la trazabilidad de sus funciones con las normas ISO.

\newpage

# Contexto del Entregable

## Fase 1: Fundación

El Entregable 02 forma parte de la **Fase 1: Fundación** del proyecto PT App, cuya finalidad es establecer la base documental y de cálculo sobre la que se construyen las fases posteriores. En esta fase, la identificación y catalogación de las funciones existentes en el código fuente es un prerequisito para los entregables 03 (implementación de funciones standalone), 04 (módulo de puntajes) y 08 (documentación para desarrolladores).

## Evolución del inventario

La evolución del inventario funcional se resume en los siguientes hitos:

| Hito | Fecha | Funciones | Estado |
|------|-------|----------|--------|
| Inventario original | 2026-01-24 | 48 | Escueto; sin descripciones, ejemplos ni referencias ISO |
| Regeneración y enriquecimiento | 2026-06-16 | 77 | Documentado, categorizado, con firmas, ejemplos y trazabilidad ISO |

La regeneración del 2026-06-16, registrada en `bitacora_actualizacion_260616.md`, abordó una discrepancia central: el inventario original no cubría el código vigente y no ofrecía la metadata suficiente para trazabilidad metrológica. El subagente designado reescribió el extractor, fusionó anotaciones manuales para funciones sin roxygen2, limitó las fuentes escaneadas a los archivos canónicos (excluyendo scripts de preprocesamiento secundarios) y generó un catálogo ampliado con badges de exportación y obsolescencia.

\newpage

# Alcance

El alcance del Entregable 02 cubre la identificación, catalogación y documentación de las funciones definidas en las siguientes fuentes canónicas del proyecto:

| Fuente | Rol |
|--------|-----|
| `app.R` | Aplicación Shiny principal (UI, servidor, helpers reactivos) |
| `R/pt_homogeneity.R` | Funciones de homogeneidad y estabilidad (versión app) |
| `R/pt_robust_stats.R` | Estadísticos robustos (versión app) |
| `R/pt_scores.R` | Puntajes PT (versión app) |
| `R/utils.R` | Funciones obsoletas mantenidas por compatibilidad |
| `ptcalc/R/pt_homogeneity.R` | Paquete de cálculos puros - homogeneidad |
| `ptcalc/R/pt_robust_stats.R` | Paquete de cálculos puros - estadísticos robustos |
| `ptcalc/R/pt_scores.R` | Paquete de cálculos puros - puntajes |
| `reports/report_template.Rmd` | Informe parametrizado por participante |

**Quedan excluidos** del alcance los scripts de preprocesamiento secundarios (`R/preprocessing/`) y los casos de uso auxiliares, conforme a la delimitación aplicada durante la regeneración del 2026-06-16.

**No es alcance de este entregable:**

- Validar la corrección numérica de las funciones (tarea del Entregable 03).
- Documentar la interfaz de usuario ni los flujos de navegación (Entregables 05 y 06).
- Generar manuales de usuario ni de desarrollador (Entregables 06 y 08).
- Auditar la coherencia completa entre `R/` y `ptcalc/R/` (tarea continua del subagente).

\newpage

# Contenido Entregado

El entregable se compone de los siguientes archivos, cada uno con un rol específico dentro del inventario funcional:

| Componente | Archivo | Descripción |
|------------|---------|-------------|
| **Extractor de firmas** | `R/lista_funciones.R` | Script en R que escanea las fuentes canónicas, parsea bloques roxygen2 completos (título, descripción, `@param`, `@return`, `@examples`, `@seealso`, `@references`, `@export`, badges de `lifecycle`) y fusiona anotaciones manuales para funciones internas de `app.R` y `report_template.Rmd`. Genera el CSV y el Markdown de salida. |
| **Inventario indexado** | `funciones_extraidas.csv` | Tabla con 77 filas y 11 columnas: archivo, nombre de función, categoría, descripción, parámetros, retorno, ejemplos, referencia ISO, indicador de exportación, ciclo de vida y ruta completa del archivo fuente. Pensada para consumo automatizado y análisis. |
| **Catálogo legible** | `md/documentacion_funciones.md` | Documentación estructurada en Markdown, organizada por categorías. Cada entrada incluye nombre, badges (`[EXPORTADA]`, `[OBSOLETO]`), descripción, firma completa, parámetros con tipos, valor de retorno, ejemplo ejecutable (cuando está disponible), notas de contexto, archivo fuente y referencia ISO. |
| **Versión Word** | `documentacion_funciones.docx` | Exportación del catálogo Markdown a formato Word, generada con pandoc 3.9.0.2. |
| **Test automatizado** | `tests/test_02_firma_funciones.R` | Script de prueba en R con el framework `testthat` que verifica la existencia y ejecución de 18 funciones principales con valores de prueba. Genera un reporte en consola y un CSV de resultados. |
| **Guía del test** | `tests/test_02_firma_funciones.md` | Documento que describe el propósito, prerrequisitos, estructura de verificación, funciones probadas, instrucciones de ejecución e interpretación de resultados del test. |
| **Bitácora de pruebas** | `test_02_resultados.csv` | Tabla con 36 registros de resultados individuales (existencia y ejecución por función), todos con estado `PASS`. |
| **Guía del entregable** | `README.md` / `README.docx` | Documento introductorio con objetivo, descripción, resumen de funciones por categoría y uso del extractor. |

### Estructura del CSV

El archivo `funciones_extraidas.csv` contiene las siguientes columnas:

| Columna | Descripción |
|---------|-------------|
| `archivo` | Nombre del archivo donde se define la función |
| `nombre_funcion` | Nombre de la función |
| `categoria` | Categoría funcional asignada |
| `descripcion` | Descripción breve de la función |
| `parametros` | Lista de parámetros documentados con tipos |
| `retorno` | Descripción del valor de retorno |
| `ejemplos` | Ejemplo de uso (cuando está disponible) |
| `referencia_iso` | Referencia a la cláusula ISO aplicable |
| `exportada` | `TRUE` si la función tiene `@export` |
| `lifecycle` | Estado del ciclo de vida (ej. `deprecated`) |
| `archivo_ruta` | Ruta relativa completa del archivo fuente |

\newpage

# Explicación Funcional

El propósito de esta sección es explicar, en lenguaje accesible para un lector no programador, qué hacen las funciones de la aplicación y cómo se agrupan. No se listan las 77 funciones individualmente; para el detalle de firmas y parámetros, consultar `documentacion_funciones.docx`.

## Familias funcionales

La aplicación PT App organiza sus funciones en **10 categorías funcionales** que reflejan el flujo operativo de un ensayo de aptitud: desde la carga de los datos de los participantes, pasando por los cálculos estadísticos de homogeneidad y estabilidad, hasta el cálculo y evaluación de puntajes y la generación de reportes.

| Categoría | Funciones | Descripción general |
|-----------|----------:|---------------------|
| Estadísticos Robustos | 6 | Estimadores robustos de localización y escala resistentes a valores atípicos: rango intercuartílico normalizado (nIQR), MAD escalado (MADe) y el Algoritmo A iterativo de winsorización, junto con helpers de convergencia. |
| Homogeneidad y Estabilidad | 15 | Cálculo de estadísticos ANOVA entre y dentro de muestras, criterios ISO (c = 0.3·sigma_pt y expandido), evaluación de cumplimiento, contribuciones de incertidumbre u_hom y u_stab, y wrappers de la interfaz y el reporte. |
| Puntajes PT | 15 | Cálculo de los cuatro puntajes normalizados (z, z', zeta, En), funciones de clasificación de desempeño (satisfactorio, cuestionable, no satisfactorio), método experto, criterio de incertidumbre del valor asignado y orquestadores del módulo de puntajes. |
| Carga y Normalización | 8 | Lectura de archivos CSV, transformación de formato largo a ancho, normalización de códigos de analito, inferencia del número de laboratorio y normalización de incertidumbres reportadas por participantes. |
| Reportes | 18 | Helpers de construcción de resúmenes de valor asignado, combinación y agregación de resultados de puntajes, conteo de categorías de evaluación, filtrado de datos para reportes globales y funciones del informe Rmd. |
| Visualización | 3 | Generación de gráficos de puntajes con `ggplot`, gráficos combinados con `patchwork` y heatmaps interactivos con `plotly`. |
| Formateo | 3 | Formateo numérico a decimales, aplicación a columnas de un data frame y traducción de etiquetas de convergencia del Algoritmo A. |
| Servidor Shiny | 3 | Función principal `server()` con la lógica reactiva, ejecución de scripts externos y guardado archivos crudos del preprocesador. |
| UI / Utilidades | 3 | Generación de claves unicas de combinaciones, limpieza de nombres de archivo para descargas y renderizado de ecuaciones LaTeX con MathJax. |
| Obsoleto | 3 | Versiones anteriores en `R/utils.R` (`algorithm_A`, `mad_e_manual`, `nIQR_manual`) marcadas como `deprecated`; se mantienen por compatibilidad y deben reemplazarse por sus equivalentes en `ptcalc`. |

## Distribución por fuente

Las 77 funciones se distribuyen entre las distintas fuentes canónicas del proyecto. La mayor concentración se encuentra en `app.R` (funciones reactivas y de orquestación), seguida del paquete `ptcalc/R/` (cálculos puros sin dependencias de Shiny) y del informe `reports/report_template.Rmd` (helpers de generación de reportes).

## Funciones exportadas y obsoletas

- **24 funciones exportadas** (`@export`): constituyen la interfaz pública del paquete `ptcalc` y corresponden a los cálculos puros reutilizables fuera del contexto Shiny: estadísticos robustos, estadística de homogeneidad/estabilidad, criterios, evaluaciones, puntajes y clasificaciones.
- **3 funciones obsoletas** (`lifecycle::badge("deprecated")`): `algorithm_A`, `mad_e_manual` y `nIQR_manual`, todas en `R/utils.R`. Se conservan por compatibilidad hacia atrás y su uso no se recomienda; deben reemplazarse por `run_algorithm_a()`, `calculate_mad_e()` y `calculate_niqr()`, respectivamente.

\newpage

# Evidencia de Verificación

El test de firma de funciones (`test_02_firma_funciones.R`) es el mecanismo de verificación automatizada del Entregable 02. Su propósito es garantizar que las funciones registradas en el inventario efectivamente existen en los entornos cargados y pueden ejecutarse sin errores con valores de prueba.

## Cobertura del test

El test verifica **18 funciones principales** que cubren las familias críticas de cálculo:

| Familia | Funciones probadas | Cantidad |
|---------|-------------------|----------:|
| Estadísticos Robustos | `calculate_niqr`, `calculate_mad_e`, `run_algorithm_a` | 3 |
| Puntajes PT | `calculate_z_score`, `calculate_z_prime_score`, `calculate_zeta_score`, `calculate_en_score`, `evaluate_z_score`, `evaluate_en_score` | 6 |
| Homogeneidad | `calculate_homogeneity_stats`, `calculate_homogeneity_criterion`, `calculate_homogeneity_criterion_expanded`, `evaluate_homogeneity` | 4 |
| Estabilidad | `calculate_stability_stats`, `calculate_stability_criterion`, `evaluate_stability`, `calculate_u_hom`, `calculate_u_stab` | 5 |

## Tipos de verificación

Para cada función, el test realiza dos comprobaciones:

1. **Verificación de existencia:** confirma que la función está definida y cargada en el entorno.
2. **Verificación de ejecución:** invoca la función con valores de prueba válidos y verifica que no se produzcan errores.

Adicionalmente, un segundo bloque de tests verifica que los valores de retorno tengan el tipo esperado (`double`, `character`, `list`) para funciones representativas.

## Resultados

La bitácora de resultados (`test_02_resultados.csv`) registra **36 pruebas individuales** (18 de existencia + 18 de ejecución), todas con estado `PASS`:

| Métrica | Valor |
|---------|-------|
| Total de pruebas | 36 |
| Pruebas PASS | 36 |
| Pruebas FAIL | 0 |

## Reproducción

Para reproducir la verificación:

```r
source("Entregables_pt_app/02_funciones_usadas/tests/test_02_firma_funciones.R")
```

O desde la línea de comandos:

```bash
Rscript Entregables_pt_app/02_funciones_usadas/tests/test_02_firma_funciones.R
```

**Nota:** los valores de prueba utilizados por el test no validan la exactitud numérica de los cálculos; únicamente verifican que las funciones pueden ejecutarse sin errores. La validación de corrección numérica corresponde al Entregable 03.

\newpage

# Estado Actual

El Entregable 02 se encuentra en estado **Regenerado y enriquecido** al 2026-06-16. Los indicadores cuantitativos del inventario son:

| Indicador | Valor |
|-----------|-------|
| Funciones únicas documentadas | 77 |
| Funciones exportadas (`@export`) | 24 |
| Funciones obsoletas (`deprecated`) | 3 |
| Categorías funcionales | 10 |
| Fuentes canónicas escaneadas | 9 archivos |
| Pruebas de verificación | 36 (todas PASS) |

El subagente responsable del mantenimiento continuo del inventario es `entregable_02_function_inventory_auditor`, cuya función es actualizar la base de datos de firmas ante cualquier cambio en el código base y asegurar la trazabilidad metrológica asociando las funciones estadísticas a las cláusulas correspondientes de la norma ISO 13528:2022.

\newpage

# Relación con Otros Entregables

El Entregable 02 es un insumo fundamental para los entregables que dependen del conocimiento funcional de la aplicación:

| Entregable | Relación |
|------------|----------|
| **01 - Repositorio inicial** | Provee el código fuente que el Entregable 02 escanea y cataloga. |
| **03 - Cálculos PT** | Utiliza el inventario de funciones para implementar y validar scripts standalone de cálculo; requiere alineación con `ptcalc/R/`. |
| **04 - Puntajes** | El módulo de puntajes se orquesta a partir de las funciones catalogadas en las categorías de Puntajes PT y Homogeneidad/Estabilidad. |
| **08 - Documentación para desarrolladores** | La documentación de funciones generada en este entregable es insumo directo del manual técnico. |
| **09 - Informe de validación** | Audita la evidencia de verificación generada por los tests de firma. |

\newpage

# Riesgos y Limitaciones

1. **Pendiente de actualización ante cambios del código:** el inventario refleja el estado del código al 2026-06-16. Si el código fuente se modifica —nuevas funciones, cambios de firma, eliminación de funciones obsoletas— el inventario debe regenerarse ejecutando `R/lista_funciones.R`. Afirmar cobertura completa sin regenerar tras cambios del código sería inexacto.

2. **No es un manual para programadores:** este documento presenta una vista agrupada y comprensible de las capacidades de la aplicación. El detalle técnico de firmas, parámetros, retornos y ejemplos se remite a `documentacion_funciones.docx`, que es la referencia canónica para desarrolladores.

3. **Cobertura parcial del test:** el test automatizado verifica 18 de las 77 funciones documentadas. Las funciones auxiliares, helpers de reporte y utilidades no se prueban automáticamente; su verificación es manual. El test confirma existencia y ejecución, no corrección numérica.

4. **Coexistencia de versiones `R/` y `ptcalc/R/`:** las funciones de cálculo existen tanto en `R/` (versión de la app) como en `ptcalc/R/` (paquete de cálculos puros). Aunque la divergencia de firma en `calculate_homogeneity_criterion_expanded()` se resolvió con una implementación polimórfica, se recomienda mantener la trazabilidad y priorizar el uso de `ptcalc`.

5. **Directorio de trabajo del test:** los scripts de prueba escriben el CSV de resultados en una ruta relativa; la ejecución debe realizarse desde la raíz del proyecto para que las rutas `source()` y la escritura del CSV funcionen correctamente.

6. **Funciones obsoletas sin plan de retiro formal:** las 3 funciones en `R/utils.R` están marcadas como `deprecated` pero se mantienen en el código. No existe actualmente un calendario formal de eliminación.

\newpage

# Documentos de Consulta

| Documento | Ubicación | Tipo |
|-----------|-----------|------|
| Overview del Entregable 02 | `Entregables_pt_app/e2.md` | Markdown |
| README del entregable | `Entregables_pt_app/02_funciones_usadas/README.md` / `README.docx` | Markdown / Word |
| Catálogo de funciones | `Entregables_pt_app/02_funciones_usadas/md/documentacion_funciones.md` | Markdown |
| Catálogo de funciones (Word) | `Entregables_pt_app/02_funciones_usadas/documentacion_funciones.docx` | Word |
| Inventario CSV | `Entregables_pt_app/02_funciones_usadas/funciones_extraidas.csv` | CSV |
| Test de firma de funciones | `Entregables_pt_app/02_funciones_usadas/tests/test_02_firma_funciones.R` | Script R |
| Guía del test | `Entregables_pt_app/02_funciones_usadas/tests/test_02_firma_funciones.md` | Markdown |
| Resultados del test | `Entregables_pt_app/02_funciones_usadas/test_02_resultados.csv` | CSV |
| Extractor de firmas | `Entregables_pt_app/02_funciones_usadas/R/lista_funciones.R` | Script R |
| Bitácora de actualización | `Entregables_pt_app/bitacora_actualizacion_260616.md` | Markdown |
| Guía de estilo y convenciones | `AGENTS.md` | Markdown |

**Normas de referencia:**

- ISO 13528:2022 — *Statistical methods for proficiency testing*
- ISO 17043:2023 — *General requirements for proficiency testing*

\newpage

# Conclusión

El Entregable 02, en su versión regenerada y enriquecida del 2026-06-16, cumple su propósito de ofrecer un mapa de capacidades de la aplicación PT App: 77 funciones catalogadas en 10 categorías funcionales, con trazabilidad a las cláusulas de la norma ISO 13528:2022, metadata de exportación y ciclo de vida, y un mecanismo de verificación automatizada que confirma la integridad de las funciones principales de cálculo.

El salto cualitativo respecto al inventario original —de 48 funciones escuetas a 77 funciones documentadas y categorizadas— habilita a los entregados posteriores (03, 04 y 08) a construir sobre una base de conocimiento confiable y actualizada. Sin embargo, la vigencia del inventario está condicionada a su regeneración cada vez que el código fuente se modifique, labor que recae en el subagente `entregable_02_function_inventory_auditor`.

Para el detalle técnico de firmas, parámetros, retornos y ejemplos, la referencia canónica es `documentacion_funciones.docx`.