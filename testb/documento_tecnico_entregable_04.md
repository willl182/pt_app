---
title: "Documento Técnico — Entregable 04: Módulo de Cálculo de Puntajes"
subtitle: "Aplicativo PT App — Ensayos de Aptitud per ISO 13528:2022 e ISO 17043:2023"
author: "Universidad Nacional de Colombia / Instituto Nacional de Metrología"
date: "2026-06-28"
version: "1.0"
responsible: "Subagente documental — entregable_04_scoring_documenter"
---

\newpage

# Portada

| Campo | Valor |
|-------|-------|
| **Documento** | Documento Técnico — Entregable 04: Módulo de Cálculo de Puntajes |
| **Proyecto** | PT App — Aplicativo R/Shiny para ensayos de aptitud |
| **Institución** | Universidad Nacional de Colombia / Instituto Nacional de Metrología |
| **Norma de referencia** | ISO 13528:2022 (Sección 10); ISO 17043:2023 |
| **Fecha de emisión** | 2026-06-28 |
| **Versión** | 1.0 |
| **Responsable documental** | Subagente `entregable_04_scoring_documenter` |
| **Estado documental** | Histórico / parcialmente vigente |
| **Fase de desarrollo** | Fase 2 — Cálculos Standalone |

\newpage

# Resumen Ejecutivo

El presente documento describe el Entregable 04 del proyecto PT App, correspondiente al **Módulo de Cálculo de Puntajes**. Este módulo implementa las fórmulas estadísticas mediante las cuales el aplicativo evalúa el desempeño de los laboratorios participantes en un ensayo de aptitud (proficiency testing, PT).

La evaluación de desempeño constituye la etapa culminante del análisis PT: una vez determinados el valor asignado ($x_{pt}$) y la desviación estándar para evaluación de aptitud ($\sigma_{pt}$), el aplicativo calcula cuatro indicadores para cada participante:

1. **Puntaje z** — puntaje estándar que mide la desviación del resultado del participante respecto al valor asignado, en unidades de $\sigma_{pt}$.
2. **Puntaje z' (z-prima)** — variante del puntaje z que incorpora la incertidumbre del valor asignado en el denominador.
3. **Puntaje $\zeta$ (zeta)** — indicador de compatibilidad metrológica que usa las incertidumbres estándar tanto del participante como del valor asignado.
4. **Puntaje $E_n$ (número de error normalizado)** — indicador que emplea las incertidumbres expandidas (factor de cobertura $k = 2$) del participante y del valor asignado.

Cada puntaje se clasifica en una categoría cualitativa — **Satisfactorio**, **Cuestionable** o **No satisfactorio** (para $z$, $z'$ y $\zeta$), o bien Satisfactorio / No satisfactorio (para $E_n$) — conforme a los umbrales definidos en la Sección 10 de ISO 13528:2022.

El módulo fue originalmente desarrollado como un conjunto de scripts *standalone* en R (`calcula_puntajes.R` y `crea_reporte.R`) con suite de pruebas automatizadas. En la arquitectura vigente del aplicativo, las fórmulas base han sido consolidadas en el paquete de cálculo `ptcalc/R/pt_scores.R`, mientras que parte del flujo de visualización y generación de reportes reside directamente en `app.R`. Por ello, el entregable se cataloga como **histórico / parcialmente vigente**: el contenido sigue siendo útil como referencia conceptual y trazabilidad normativa, pero no representa por sí solo la totalidad del flujo activo.

Este documento está dirigido a lectores institucionales — coordinadores de PT, auditores y personal técnico — que requieren comprender qué mide cada puntaje y cómo se interpreta, sin necesidad de recorrer las derivaciones matemáticas extensas, las cuales se mantienen en el anexo técnico `formulas_y_ejemplos.docx`.

\newpage

# Contexto del Entregable

El Entregable 04 se desarrolló durante la **Fase 2: Cálculos Standalone** del proyecto PT App. Esta fase se caracterizó por la implementación de funciones estadísticas independientes — es decir, sin dependencias de la interfaz Shiny — que permitieran validar la corrección de los cálculos de manera aislada antes de su integración en el aplicativo interactivo.

Dentro de la secuencia de entregables, el módulo de puntajes depende lógicamente del Entregable 03 (Cálculos PT), el cual provee el valor asignado ($x_{pt}$) y la desviación estándar para evaluación de aptitud ($\sigma_{pt}$) mediante algoritmos robustos (Algoritmo A y Algoritmo S de ISO 13528:2022, Sección 9). Los puntajes descritos aquí consumen esos insumos y producen las evaluaciones cualitativas que el usuario final consume en los reportes y visualizaciones.

El subagente designado para el desarrollo fue `score_auditor` (*Scoring Auditor & Report Engine Developer*), con la responsabilidad de validar la coincidencia con la Sección 10 de ISO 13528:2022 y asegurar la correcta asignación de las clasificaciones cualitativas de desempeño. Posteriormente, en la actualización documental de 2026-06-16, el subagente `entregable_04_scoring_documenter` asumió la revisión de trazabilidad y consistencia del material documental.

\newpage

# Alcance

El alcance del Entregable 04 comprende:

- **Cálculo** de los cuatro puntajes de aptitud ($z$, $z'$, $\zeta$, $E_n$) para cada combinación participante–contaminante–nivel.
- **Clasificación cualitativa** de cada puntaje según los umbrales normativos.
- **Generación de reportes** estructurados: tabla completa de puntajes, resumen por participante y estadísticas globales del esquema PT.
- **Verificación automatizada** mediante suite de pruebas unitarias que validan el cálculo numérico y la clasificación.

**Quedan fuera del alcance:**

- La determinación del valor asignado y de $\sigma_{pt}$ (Entregable 03).
- La interfaz de usuario y las visualizaciones interactivas (Entregables 05 y 07).
- La lógica reactiva de la aplicación Shiny (Entregable 06 / `app.R` vigente).
- La integración final con el paquete `ptcalc`, que constituye el estado vigente de las fórmulas base.

\newpage

# Contenido Entregado

Los artefactos que componen el Entregable 04 se listan a continuación:

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `R/calcula_puntajes.R` | Script R | Implementación *standalone* de las fórmulas de puntajes ($z$, $z'$, $\zeta$, $E_n$), funciones de evaluación cualitativa, cálculo por participante, cálculo global, resúmenes y estadísticas. |
| `R/crea_reporte.R` | Script R | Estructuración del reporte PT: generación de tabla completa de puntajes, resumen por participante, estadísticas globales y flujo end-to-end con cálculo previo de valor asignado y $\sigma_{pt}$. |
| `md/formulas_y_ejemplos.md` | Documento técnico (Markdown) | Recopilación de ecuaciones, criterios de evaluación y ejemplos numéricos para cada tipo de puntaje. |
| `formulas_y_ejemplos.docx` | Documento técnico (Word) | Versión exportada del documento anterior mediante pandoc, apta para distribución institucional. |
| `tests/test_04_puntajes.R` | Suite de pruebas (R) | Pruebas unitarias que verifican cálculo numérico correcto, manejo de casos límite, clasificación cualitativa y generación de reportes. |

\newpage

# Explicación Funcional

## ¿Qué significa evaluar el desempeño?

En un ensayo de aptitud, cada laboratorio participante reporta un resultado para una magnitud o analito en un material de referencia. El organizador del esquema PT determina un **valor asignado** ($x_{pt}$) — el valor de consenso considerado como referencia — y una **desviación estándar para evaluación de aptitud** ($\sigma_{pt}$), que define el margen de variación aceptable.

Evaluar el desempeño consiste en contestar una pregunta simple pero crítica: **¿qué tan lejos está el resultado del participante del valor de referencia, y esa diferencia es aceptable en términos estadísticos?**

Los cuatro puntajes son indicadores que responden esta pregunta desde perspectivas complementarias.

## Cálculo por participante y nivel

El módulo calcula los cuatro puntajes para cada combinación participante–contaminante–nivel, si las incertidumbres necesarias están disponibles. Cuando no se reporta incertidumbre por parte del participante o del organizador, los puntajes que dependen de ella ($z'$ requiere $u_{xpt}$; $\zeta$ requiere $u_x$ y $u_{xpt}$; $E_n$ requiere $U_x$ y $U_{xpt}$) se asignan como `NA` y se etiquetan como `"N/A"`.

### Puntaje z — Desempeño estándar

El puntaje z expresa cuántas desviaciones estándar ($\sigma_{pt}$) separan el resultado del participante del valor asignado. Es el indicador más usado en PT cuando se conoce $\sigma_{pt}$ y la incertidumbre del valor asignado no es significativa.

### Puntaje z' — Desempeño con corrección por incertidumbre del valor asignado

El puntaje z' es una variante que amplía el denominador incorporando la incertidumbre estándar del valor asignado ($u_{xpt}$). Se emplea cuando la incertidumbre del valor de referencia no es despreciable frente a $\sigma_{pt}$.

### Puntaje $\zeta$ (zeta) — Compatibilidad metrológica

El puntaje $\zeta$ reemplaza $\sigma_{pt}$ por la combinación de las incertidumbres estándar del participante ($u_x$) y del valor asignado ($u_{xpt}$). Evalúa la compatibilidad metrológica entre el resultado y el valor de referencia, y es útil cuando los laboratorios reportan incertidumbre.

### Puntaje $E_n$ — Número de error normalizado

El puntaje $E_n$ es análogo a $\zeta$ pero emplea incertidumbres **expandidas** (con factor de cobertura $k = 2$) del participante ($U_x$) y del valor asignado ($U_{xpt}$). Es un indicador tradicionalmente usado en comparaciones metrológicas clave.

### Categorías de evaluación

La norma ISO 13528:2022 (Sección 10) define los siguientes umbrales:

| Puntaje | Qué mide | Criterio Satisfactorio | Criterio Cuestionable | Criterio No satisfactorio |
|---------|----------|------------------------|-----------------------|--------------------------|
| $z$ | Desviación en unidades de $\sigma_{pt}$ | $\lvert z \rvert \leq 2$ | $2 < \lvert z \rvert < 3$ | $\lvert z \rvert \geq 3$ |
| $z'$ | Desviación con corrección por $u_{xpt}$ | $\lvert z' \rvert \leq 2$ | $2 < \lvert z' \rvert < 3$ | $\lvert z' \rvert \geq 3$ |
| $\zeta$ | Compatibilidad metrológica (incertidumbres estándar) | $\lvert \zeta \rvert \leq 2$ | $2 < \lvert \zeta \rvert < 3$ | $\lvert \zeta \rvert \geq 3$ |
| $E_n$ | Error normalizado (incertidumbres expandidas) | $\lvert E_n \rvert \leq 1$ | — | $\lvert E_n \rvert > 1$ |

> **Nota terminológica:** En todo el presente documento y en el material del entregable se utiliza la etiqueta **"No satisfactorio"** como categoría de desempeño, conforme a la terminología adoptada en el paquete `ptcalc` y normalizada en `app.R`. No se emplea el término "Insatisfactorio", que aparece ocasionalmente en literatura, para evitar ambigüedad. Donde se encuentre alguna divergencia histórica entre ambos términos, debe interpretarse como sinónimo y normalizarse a **"No satisfactorio"**.

> **Nota metodológica:** Las fórmulas matemáticas completas, incluyendo derivaciones y ejemplos numéricos paso a paso, se encuentran en el documento anexo `formulas_y_ejemplos.docx`. El presente documento no reproduce dichas fórmulas en su cuerpo principal, conforme al criterio de mantener una lectura ágil para el lector institucional.

\newpage

# Evidencia de Verificación

El Entregable 04 incluye una suite de pruebas automatizadas (`tests/test_04_puntajes.R`) construida sobre el framework **testthat**. Las pruebas se ejecutan desde la raíz del proyecto mediante:

```r
source("Entregables_pt_app/04_puntajes/tests/test_04_puntajes.R")
```

Las pruebas verifican los siguientes aspectos:

| Aspecto verificado | Pruebas asociadas |
|---------------------|-------------------|
| **Cálculo correcto del z-score** | Se suministran valores conocidos ($x = 10.5$, $x_{pt} = 10.0$, $\sigma_{pt} = 0.5$) y se verifica $z = 1.0$. |
| **Manejo de entradas inválidas** | Se comprueba que $\sigma_{pt} \leq 0$ produce `NA` en $z$. Se verifica denominador cero en $E_n$. |
| **Incorporación de incertidumbre en z'** | Se valida que $z'$ incluya $u_{xpt}$ en el denominador y produzca un valor finito cercano al esperado. |
| **Cálculo de $\zeta$ con incertidumbres estándar** | Se verifica el uso combinado de $u_x$ y $u_{xpt}$. |
| **Cálculo de $E_n$ con incertidumbres expandidas** | Se comprueba el resultado exacto ($E_n = 1.0$) para datos de prueba. |
| **Clasificación cualitativa de z** | Se prueba clasificación en Satisfactorio, Cuestionable y No satisfactorio. |
| **Clasificación cualitativa de $E_n$** | Se prueba clasificación en Satisfactorio y No satisfactorio. |
| **Manejo de NA en evaluación** | Se verifica que valores `NA` se etiqueten como `"N/A"`. |
| **Evaluación vectorizada** | Se verifica longitud y contenido de vectores evaluados. |
| **Generación de data.frame por participante** | Se comprueba estructura y columnas esperadas. |
| **Cálculo para todos los participantes** | Se verifica generación de puntajes finitos. |
| **Resumen por participante** | Se valida conteo de observaciones y manejo de participante inexistente. |
| **Estadísticas globales** | Se verifica media, desviación, máximo absoluto y porcentajes que suman 100 %. |
| **Generación de reportes** | Se prueba el flujo completo: reporte de puntajes, resumen, estadísticas globales y flujo end-to-end. |

El cubrimiento de pruebas abarca desde el cálculo numérico individual de cada puntaje hasta la generación completa del reporte integrado, incluyendo casos límite y manejo de errores.

\newpage

# Estado Actual

El estado documental del Entregable 04 es **histórico / parcialmente vigente**.

### Implementación vigente de las fórmulas

Las fórmulas base de los cuatro puntajes se encuentran implementadas, documentadas y exportadas en el paquete `ptcalc` dentro del archivo `ptcalc/R/pt_scores.R`. Las funciones vigentes son:

| Función vigente (`ptcalc/R/pt_scores.R`) | Función histórica (`calcula_puntajes.R`) | Equivalencia |
|-------------------------------------------|------------------------------------------|--------------|
| `calculate_z_score()` | `calcular_puntaje_z()` | Misma fórmula y lógica de validación. |
| `calculate_z_prime_score()` | `calcular_puntaje_z_prima()` | Misma fórmula y lógica de validación. |
| `calculate_zeta_score()` | `calcular_puntaje_zeta()` | Misma fórmula y lógica de validación. |
| `calculate_en_score()` | `calcular_puntaje_en()` | Misma fórmula y lógica de validación. |
| `evaluate_z_score()` / `evaluate_z_score_vec()` | `evaluar_puntaje_z()` / `evaluar_puntaje_z_vec()` | Misma lógica; la versión vigente usa `dplyr::case_when()` para vectorización. |
| `evaluate_en_score()` / `evaluate_en_score_vec()` | `evaluar_puntaje_en()` / `evaluar_puntaje_en_vec()` | Misma lógica; la versión vigente usa `dplyr::case_when()`. |

Las implementaciones son conceptualmente equivalentes y trazables. La diferencia principal radica en:

1. **Nomenclatura:** el paquete `ptcalc` adopta la convención `snake_case` (`calculate_z_score`) mientras que el entregable histórico usa nombre en español (`calcular_puntaje_z`).
2. **Vectorización:** la versión vigente emplea `dplyr::case_when()` para evaluación vectorizada, mientras que la histórica usa `sapply()`.
3. **Documentación roxygen2:** la versión vigente incluye documentación completa con `@export`, `@param`, `@return` y `@examples`, conforme a las convenciones del paquete.

### Flujo de reportes

El script `crea_reporte.R` contiene funciones para estructurar el reporte PT. En la arquitectura vigente, el flujo de visualización y parte del cálculo de reportes reside directamente en `app.R` y en la plantilla `report_template.Rmd`. Las funciones de `crea_reporte.R` no se invocan directamente desde la aplicación Shiny activa, pero su lógica — organizar puntajes en tablas, generar resúmenes por participante y calcular estadísticas globales — sigue siendo trazable conceptualmente con lo que el aplicativo produce.

### Trazabilidad

Las fórmulas de `calcula_puntajes.R` siguen siendo trazables conceptualmente respecto a las del paquete `ptcalc`, pero **no representan por sí solas todo el flujo activo** del aplicativo. Las referencias normativas (ISO 13528:2022, Sección 10) son consistentes entre ambas implementaciones.

\newpage

# Relación con Otros Entregables

| Entregable | Relación | Naturaleza de la dependencia |
|------------|----------|------------------------------|
| **E01** — Repositorio inicial | Base | Provee la estructura de directorios y el repositorio Git sobre el que se desarrolla E04. |
| **E02** — Inventario de funciones | Referencial | Documenta las funciones del aplicativo, incluidas las de puntajes. El inventario vigente cubre tanto las funciones históricas como las de `ptcalc`. |
| **E03** — Cálculos PT | **Dependencia directa** | Provee el valor asignado ($x_{pt}$) y la desviación estándar ($\sigma_{pt}$), insumos obligatorios para el cálculo de puntajes. Los tests de E04 usan (vía `source`) funciones de E03. |
| **E05** — Prototipo de UI | Consumidor | Las visualizaciones de puntajes en el prototipo se basan en los resultados producidos por E04. |
| **E06** — Lógica Shiny / manual | Consumidor | La aplicación Shiny activa consume los puntajes calculados (vía `ptcalc` o cálculos *inline* en `app.R`) para tablas y gráficos. |
| **E07** — Dashboards | Consumidor | Los gráficos de desempeño de los *dashboards* usan los puntajes y sus categorías cualitativas. |
| **E08** — Beta | Consumidor | La versión beta utilizaba los puntajes para validación end-to-end. |
| **E09** — Informe final | Consumidor | El informe de validación reporta los resultados de desempeño de laboratorios, basados en los puntajes de E04. |

\newpage

# Riesgos y Limitaciones

1. **Vigencia parcial del código *standalone*:** Las funciones de `calcula_puntajes.R` y `crea_reporte.R` no se invocan directamente desde la aplicación Shiny vigente. El contenido sigue siendo útil como referencia conceptual, trazabilidad normativa y material pedagógico, pero no debe emplearse como especificación única del flujo activo. Para el estado actual del aplicativo, debe contrastarse con `ptcalc/R/pt_scores.R` y con los cálculos *inline* de `app.R`.

2. **Divergencia de nomenclatura entre implementaciones:** Existen dos trayectorias de puntajes — las funciones de `ptcalc/R/pt_scores.R` y los cálculos *inline* en `app.R`. Aunque los resultados numéricos son consistentes, la multiplicidad de puntos de cálculo introduce un riesgo de mantenimiento que debe gestionarse documentando claramente qué fuente es la autoritativa (el paquete `ptcalc`).

3. **Normalización de etiquetas cualitativas:** Históricamente ha existido oscilación entre las etiquetas **"No satisfactorio"** e **"Insatisfactorio"**. Ambas denominan la misma categoría ($\lvert z \rvert \geq 3$). El presente documento y la convención adoptada en `ptcalc` usan **"No satisfactorio"**. La bitácora de actualización 260616 confirma que se normalizó la etiqueta en `app.R` para consistencia con `ptcalc`. Donde subsista divergencia textual, debe normalizarse a **"No satisfactorio"** antes de usar la etiqueta como criterio de validación textual.

4. **Dependencia de pruebas del directorio de trabajo:** Algunos tests del entregable cargan datos y funciones (vía `source`) mediante rutas relativas a la raíz del proyecto. La ejecución de los tests debe realizarse desde el directorio raíz (`pt_app/`) para garantizar que las rutas resuelvan correctamente.

5. **Fórmulas no incluidas en el cuerpo principal:** Por criterio editorial, este documento no reproduce las fórmulas matemáticas extensas en su cuerpo. Para consultas de las ecuaciones, derivaciones y ejemplos numéricos, debe remitirse al anexo técnico `formulas_y_ejemplos.docx`, parte del contenido entregado.

6. **Ausencia de categoría "Cuestionable" para $E_n$:** El puntaje $E_n$ define solo dos categorías (Satisfactorio / No satisfactorio), sin un intervalo intermedio. Esto es consistente con la Sección 10.5 de ISO 13528:2022 y no constituye una limitación, pero debe comunicarse con claridad para evitar confusiones con los tres niveles de $z$, $z'$ y $\zeta$.

\newpage

# Documentos de Consulta

| Documento | Referencia |
|-----------|------------|
| ISO 13528:2022 | *Statistical methods for use in proficiency testing by interlaboratory comparison*. Secciones 10.2 (z-scores), 10.3 (z'-scores), 10.4 (zeta-scores), 10.5 (En-scores). |
| ISO 17043:2023 | *Conformity assessment — General requirements for the competence of proficiency testing providers*. |
| `formulas_y_ejemplos.docx` | Anexo técnico del Entregable 04 con ecuaciones completas y ejemplos numéricos. |
| `ptcalc/R/pt_scores.R` | Implementación vigente de las fórmulas de puntajes en el paquete `ptcalc`. |
| `e4.md` | *Overview* del Entregable 04 — índice de archivos y procedimiento de verificación. |
| `bitacora_actualizacion_260616.md` | Bitácora de actualización documental con matriz de discrepancias y riesgos técnicos. |
| Guía de estilo Tidyverse | *The Tidyverse Style Guide* — https://style.tidyverse.org/ |

\newpage

# Conclusión

El Entregable 04 — Módulo de Cálculo de Puntajes — aporta la implementación de los cuatro indicadores de desempeño ($z$, $z'$, $\zeta$, $E_n$) que constituyen el núcleo evaluativo del aplicativo PT App. Su contenido sigue siendo útil como referencia conceptual, material pedagógico y fuente de trazabilidad normativa frente a ISO 13528:2022.

Las fórmulas y criterios de evaluación aquí documentados son consistentes con la implementación vigente del paquete `ptcalc/R/pt_scores.R`, si bien el entregable histórico no representa por sí solo la totalidad del flujo activo del aplicativo, que distribuye parte del cálculo y de la presentación en `app.R`.

El presente documento cataloga el entregable como **histórico / parcialmente vigente**, recomendando que cualquier uso normativo o de validación se contraste con las fuentes vigentes. La normalización de la etiqueta **"No satisfactorio"** y la remisión de las derivaciones matemáticas al anexo técnico son las salvaguardas adoptadas para asegurar consistencia terminológica y legibilidad institucional.