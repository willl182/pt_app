# Documento Técnico: Entregable 09 — Informe Final y Validación de Cálculos

**Proyecto:** PT App — Aplicativo R/Shiny para Ensayos de Aptitud
**Institución:** Universidad Nacional de Colombia / Instituto Nacional de Metrología
**Normas de referencia:** ISO 13528:2022, ISO 17043:2023
**Fecha de emisión:** 2026-06-28
**Versión:** 1.0
**Responsable documental:** Equipo de desarrollo PT App — UNAL/INM
**Estado:** Requiere auditoría de evidencia

---

## Portada

| Campo | Valor |
|-------|-------|
| Documento | Documento Técnico del Entregable 09 |
| Proyecto | PT App — Aplicativo R/Shiny para ensayos de aptitud |
| Fase de desarrollo | Fase 7: Validación de Cálculos |
| Institución | Universidad Nacional de Colombia / Instituto Nacional de Metrología |
| Normas de referencia | ISO 13528:2022, ISO 17043:2023 |
| Fecha de emisión | 2026-06-28 |
| Versión | 1.0 |
| Responsable documental | Equipo de desarrollo PT App — UNAL/INM |
| Estado | Requiere auditoría de evidencia |

---

## Resumen Ejecutivo

El Entregable 09 corresponde a la Fase 7 del ciclo de desarrollo del aplicativo PT App y tiene como propósito reunir y presentar la evidencia de validación, reproducibilidad y control de calidad de los cálculos estadísticos implementados en el aplicativo. Este entregable constituye el cierre documental del proceso de validación iniciado en los entregables precedentes (E01–E08).

La evidencia disponible muestra que el aplicativo dispone de un conjunto de pruebas automatizadas, un script generador de anexos tabulares, un informe de validación y un anexo de cálculos paso a paso que, en conjunto, documentan la verificación del motor estadístico frente a los requisitos de las normas ISO 13528:2022 e ISO 17043:2023. Adicionalmente, se conservan reportes en formato DOCX y PDF como evidencia formateada de los documentos de validación.

No obstante, el estado documental recomendado para este entregable es **requiere auditoría de evidencia**. Esta calificación obedece a que ciertas referencias externas Excel/VIVO y el pipeline completo de regeneración de anexos deben verificarse en el espacio de trabajo antes de sostener una certificación completa de reproducibilidad. Los reportes DOCX/PDF existentes se conservan como evidencia formateada, pero no se regeneraron en la actualización más reciente porque no se identificó un pipeline reproducible completo que garantice su reconstrucción automatizada.

El presente documento describe el alcance de la validación, el contenido entregado, la evidencia disponible, las pruebas ejecutables y los pendientes explícitos que deben confirmarse mediante auditoría. El lenguaje se mantiene en términos de evidencia disponible y pruebas ejecutables, evitando afirmaciones de certificación absoluta mientras los puntos pendientes no se cierren formalmente.

---

## 1. Contexto del Entregable

El Entregable 09 se ubica en la **Fase 7: Validación de Cálculos** del ciclo de desarrollo del proyecto PT App. Esta fase tiene como objetivo culminar el proceso de verificación técnica del aplicativo, integrando la evidencia generada a lo largo de los entregables E01 a E08 en un conjunto consolidado de documentos, anexos tabulares y pruebas automatizadas.

El aplicativo PT App es una herramienta desarrollada en R/Shiny que implementa los métodos estadísticos para ensayos de aptitud conforme a las normas ISO 13528:2022 ( métodos estadísticos para ensayos de aptitud por comparación interlaboratorial) e ISO 17043:2023 (requisitos generales para ensayos de aptitud). El Entregable 09 busca demostrar que los cálculos del aplicativo pueden reproducirse y compararse contra referencias documentadas, y que el flujo operativo resulta auditable por terceros.

---

## 2. Alcance

### 2.1 Lo que el entregable intenta demostrar

El Entregable 09 intenta demostrar que:

1. Los cálculos estadísticos del aplicativo (homogeneidad, estabilidad, estadísticos robustos y puntajes de desempeño) pueden reproducirse de forma determinista.
2. Los resultados del aplicativo pueden compararse contra referencias documentadas y datos auditados cuando dichas referencias estén localizadas y trazadas en el paquete de evidencia.
3. El flujo de generación de anexos tabulares es trazable y genera salidas legibles.
4. Existe un conjunto de pruebas automatizadas que verifican la reproducibilidad funcional del aplicativo.

### 2.2 Lo que debe auditarse

Antes de sostener una certificación completa de reproducibilidad, los siguientes elementos requieren auditoría de evidencia:

| Elemento a auditar | Descripción |
|---------------------|-------------|
| Referencias externas Excel/VIVO | Confirmar la existencia, disponibilidad, procedencia y ruta de los archivos de referencia externa utilizados históricamente en la validación cruzada. |
| Pipeline completo de regeneración | Verificar que el script `genera_anexos.R` pueda ejecutarse de extremo a extremo reproduciendo los anexos CSV con resultados consistentes. |
| Correspondencia de anexos | Confirmar que los anexos CSV generados corresponden a los datos de entrada vigentes y que las cifras son coherentes con los reportes DOCX/PDF existentes. |
| Reportes DOCX/PDF | Los reportes en formato DOCX y PDF se conservan como evidencia formateada, pero no se regeneraron en la actualización más reciente porque no se identificó un pipeline reproducible completo. Debe confirmarse su correspondencia con el contenido actualizado. |

### 2.3 Lo que el entregable NO afirma

El Entregable 09 **no afirma** reproducibilidad plena ni certificación absoluta. La evidencia disponible se presenta tal como existe en el repositorio, y los pendientes de confirmación se enumeran de forma explícita. El lenguaje se mantiene en términos de evidencia disponible y pruebas ejecutables.

---

## 3. Contenido Entregado

### 3.1 Inventario de archivos

La siguiente tabla describe el contenido entregado en el directorio del Entregable 09:

| Archivo | Tipo | Descripción |
|---------|------|-------------|
| `R/genera_anexos.R` | Script R | Genera los anexos tabulares CSV con resultados intermedios y un log de ejecución a partir de los datos de entrada. |
| `md/informe_validacion.md` | Markdown | Informe principal de validación (versión 2.0) con pruebas de software, control de calidad, hallazgos solventados y conformidad con ISO 13528/17043. |
| `informe_validacion.docx` | DOCX | Copia del informe de validación en formato Microsoft Word. Evidencia formateada conservada. |
| `informe_validacion.pdf` | PDF | Copia del informe de validación en formato PDF. Evidencia formateada conservada. |
| `md/anexo_calculos.md` | Markdown | Anexo de cálculos paso a paso con datos reales, mostrando el procedimiento numérico para cada etapa (homogeneidad, estabilidad, robustos, puntajes). |
| `anexo_calculos.docx` | DOCX | Anexo de cálculos en formato Microsoft Word. Evidencia formateada conservada. |
| `anexos/estabilidad_resultados.csv` | CSV | Resultados de evaluación de estabilidad por analito y nivel (31 registros). |
| `anexos/estadisticos_robustos.csv` | CSV | Estadísticos robustos (nIQR, MADe, Algoritmo A) por analito y nivel (30 registros). |
| `anexos/homogeneidad_resultados.csv` | CSV | Resultados de evaluación de homogeneidad por analito y nivel (31 registros). |
| `anexos/puntajes_pt.csv` | CSV | Puntajes de desempeño (z, z', zeta, En) por participante (270 registros). |
| `anexos/resumen_puntajes.csv` | CSV | Resumen agregado de evaluación de puntajes por analito y nivel (30 registros). |
| `anexos/generacion_log.txt` | Texto | Log de ejecución del script generador con fecha, conteo de registros y resúmenes de evaluación. |
| `tests/test_09_reproducibilidad.R` | Script R | Suite de pruebas automatizadas que verifica la reproducibilidad funcional del aplicativo. |

### 3.2 Estructura del directorio

El contenido del Entregable 09 se organiza en tres niveles:

- **Documentos principales:** informe de validación y anexo de cálculos en formatos Markdown, DOCX y PDF.
- **Anexos tabulares:** archivos CSV con resultados numéricos generados por el script `genera_anexos.R`.
- **Pruebas automatizadas:** suite de reproducibilidad que verifica el determinismo de los cálculos.

---

## 4. Explicación Funcional

### 4.1 Qué se entiende por validación en este contexto

En el contexto del Entregable 09, la validación se entiende como una **comparación controlada** entre los resultados producidos por el aplicativo y conjuntos de referencia o datos esperados. La validación no consiste en una declaración universal de corrección, sino en demostrar, mediante evidencia documental y pruebas ejecutables, que los cálculos del aplicativo producen resultados reproducibles y comparables con referencias identificadas.

### 4.2 Qué evidencia existe

La evidencia disponible en el repositorio comprende:

1. **Informe de validación (versión 2.0):** documenta dos ciclos de revisión externa, nueve hallazgos identificados (H1–H9) y una validación cruzada específica del Algoritmo A definido en ISO 13528:2022. La evidencia externa citada en ese informe debe localizarse y trazarse antes de sostener una conclusión cerrada.
2. **Anexo de cálculos paso a paso:** muestra el procedimiento numérico detallado para cada etapa del cálculo con datos reales, permitiendo a un tercero verificar manualmente las operaciones.
3. **Anexos tabulares CSV:** seis archivos con resultados numéricos (homogeneidad, estabilidad, estadísticos robustos, puntajes, resumen y log de ejecución) generados por un script automatizado.
4. **Script generador:** `genera_anexos.R` produce los anexos tabulares a partir de los datos de entrada del aplicativo.
5. **Pruebas de reproducibilidad:** `test_09_reproducibilidad.R` verifica que los cálculos son deterministas y que los puntajes y evaluaciones cualitativas son consistentes.
6. **Reportes DOCX/PDF:** versiones formateadas del informe y el anexo, conservadas como evidencia documental.

### 4.3 Pipeline de generación de anexos

El script `genera_anexos.R` realiza las siguientes operaciones:

1. Carga los datos de entrada desde los archivos `homogeneity.csv`, `stability.csv` y `summary_n4.csv`.
2. Calcula estadísticos de homogeneidad por analito y nivel utilizando la estructura ANOVA prevista por ISO 13528:2022.
3. Calcula estadísticos de estabilidad comparando medias de estabilidad con medias de homogeneidad.
4. Calcula estadísticos robustos (nIQR, MADe, Algoritmo A) por analito y nivel.
5. Calcula puntajes de desempeño (z, z', zeta, En) por participante.
6. Genera un resumen agregado de evaluación de puntajes.
7. Registra un log de ejecución con fecha, conteo de registros y resúmenes de evaluación.

El log de ejecución disponible muestra la siguiente evidencia de generación:

| Archivo generado | Registros |
|------------------|-----------|
| homogeneidad_resultados.csv | 31 |
| estabilidad_resultados.csv | 31 |
| estadisticos_robustos.csv | 30 |
| puntajes_pt.csv | 270 |
| resumen_puntajes.csv | 30 |
| generacion_log.txt | — |

---

## 5. Evidencia de Verificación

### 5.1 Prueba de reproducibilidad

La suite `test_09_reproducibilidad.R` contiene pruebas automatizadas que verifican los siguientes aspectos:

| Prueba | Aspecto verificado |
|--------|---------------------|
| Reproducibilidad de nIQR | Tres ejecuciones con los mismos datos producen resultados idénticos. |
| Reproducibilidad de MADe | Tres ejecuciones con los mismos datos producen resultados idénticos. |
| Reproducibilidad de Algoritmo A | Tres ejecuciones con los mismos datos producen valores asignados y desviaciones robustas idénticos. |
| Reproducibilidad de puntaje z | Tres ejecuciones con los mismos parámetros producen el mismo puntaje. |
| Reproducibilidad de puntaje z' | Tres ejecuciones con los mismos parámetros producen el mismo puntaje. |
| Reproducibilidad de puntaje zeta | Tres ejecuciones con los mismos parámetros producen el mismo puntaje. |
| Reproducibilidad de puntaje En | Tres ejecuciones con los mismos parámetros producen el mismo puntaje. |
| Valores esperados de cálculos básicos | nIQR y MADe producen valores finitos y positivos para datos simples. |
| Consistencia de evaluación cualitativa | Las banderas cualitativas (Satisfactorio, Cuestionable, No satisfactorio) coinciden con los umbrales definidos por ISO 13528:2022. |
| Determinismo de homogeneidad | Dos ejecuciones con la misma matriz de datos producen estadísticos idénticos. |
| Consistencia de puntajes múltiples | Los puntajes para múltiples participantes son consistentes entre ejecuciones. |
| Finitud con datos reales | Los cálculos con datos reales (summary_n4.csv) producen valores finitos. |
| Invariancia al orden | El orden de los datos no afecta el resultado de estadísticos robustos basados en mediana. |

### 5.2 Criterios de aceptación del informe de validación

El informe de validación (versión 2.0) documenta los siguientes criterios:

1. Las estadísticas robustas estimadas por R (consenso, Algoritmo A) deben compararse contra referencias externas localizadas y trazables antes de declarar conformidad numérica completa.
2. Los puntajes calculados y sus banderas cualitativas de aptitud coinciden con los datos auditados.
3. La existencia y legibilidad de los reportes PDF/DOCX de validación final.

### 5.3 Validación cruzada del Algoritmo A

El informe de validación documenta una validación cruzada específica del Algoritmo A con los siguientes resultados históricos reportados. Estos resultados se conservan como antecedente documental y requieren una matriz de evidencia externa antes de usarse como conclusión final:

| Comparación | Resultado reportado |
|-------------|---------------------|
| R vs Excel de validación | 10/10 casos concluyentes |
| R vs VIVO equivalente | 10/10 en iteraciones comunes |
| Diferencia máxima esperada por redondeo (R vs Excel) | Orden 10⁻²⁰ a 10⁻¹³ |

Un caso especial (O3 a 180 nmol/mol) requiere 18 iteraciones para converger en R, mientras que el VIVO equivalente se limita a 10 iteraciones; las iteraciones comunes coinciden exactamente, y la diferencia final se atribuye al límite de iteraciones del instrumento comparador, no a un error del algoritmo.

### 5.4 Matriz de evidencia externa pendiente

| Evidencia requerida | Estado en este paquete documental | Uso permitido en este documento |
|---------------------|-----------------------------------|----------------------------------|
| Archivo Excel de validación del Algoritmo A | Pendiente de localización con ruta verificable | Mencionarlo solo como referencia histórica reportada. |
| Salida o archivo VIVO equivalente | Pendiente de localización con ruta verificable | Mencionarlo solo como referencia histórica reportada. |
| Tabla de correspondencia R vs Excel/VIVO | Pendiente de adjuntar como anexo trazable | No usarla para afirmar certificación completa. |
| Registro de versión de datos usados en la comparación | Pendiente de confirmar | Mantener el estado "requiere auditoría de evidencia". |
| Comando reproducible para reconstruir anexos | Parcial: existe `genera_anexos.R`, pero falta cerrar pipeline completo | Verificar ejecución antes de regenerar reportes finales. |

### 5.5 Hallazgos H1–H9

El informe de validación documenta nueve hallazgos identificados durante dos ciclos de revisión externa, todos cerrados mediante cambios de código, cambios de interfaz y mejoras de exportación:

| ID | Hallazgo | Estado |
|----|----------|--------|
| H1 | Fórmula B.10 podía producir un radicando negativo | Cerrado |
| H2 | Ambigüedad entre MADe de homogeneidad y de participantes | Cerrado |
| H3 | Falta de trazabilidad de datos en una corrida | Cerrado |
| H4 | Umbral operativo de Algoritmo A no alineado con ISO | Cerrado |
| H5 | Error de signo en hoja de validación externa | Cerrado |
| H6 | Error de rango en hoja de estabilidad | Cerrado |
| H7 | Ausencia de exportación clara de resultados | Cerrado |
| H8 | Carga de archivos sin diferenciación visual | Cerrado |
| H9 | Cálculos intermedios ANOVA no visibles | Cerrado |

### 5.6 Estado de la evidencia de anexos

Los anexos CSV disponibles en el repositorio fueron generados el 2026-06-16 y contienen resultados para 5 analitos (CO, NO, NO2, O3, SO2) en múltiples niveles de concentración, con 9 participantes por combinación analito/nivel. El log de generación confirma la ejecución del script y el conteo de registros.

---

## 6. Estado Actual

El estado documental recomendado para el Entregable 09 es **requiere auditoría de evidencia**.

### 6.1 Elementos disponibles

- Informe de validación en Markdown, DOCX y PDF.
- Anexo de cálculos en Markdown y DOCX.
- Script generador de anexos (`genera_anexos.R`).
- Seis anexos tabulares CSV con resultados numéricos.
- Suite de pruebas de reproducibilidad ejecutable.
- Log de generación con fecha y conteo de registros.

### 6.2 Pendientes de confirmación

- **Referencias externas Excel/VIVO:** confirmar la existencia y disponibilidad de los archivos de referencia externa utilizados en la validación cruzada del Algoritmo A.
- **Pipeline completo de regeneración:** verificar que el script `genera_anexos.R` pueda ejecutarse de extremo a extremo en el entorno actual y reproducir los anexos con resultados consistentes.
- **Correspondencia de anexos:** confirmar que las cifras de los anexos CSV son coherentes con los datos de entrada vigentes y con los reportes DOCX/PDF existentes.
- **Reportes DOCX/PDF:** estos reportes se conservan como evidencia formateada pero no se regeneraron en la actualización más reciente porque no se identificó un pipeline reproducible completo. Debe confirmarse su correspondencia con el contenido actualizado de los archivos Markdown.

---

## 7. Relación con Otros Entregables

El Entregable 09 constituye la culminación del proceso de validación del aplicativo PT App y se relaciona con los entregables precedentes de la siguiente manera:

| Entregable | Aporte al Entregable 09 |
|------------|------------------------|
| E01 — Repositorio inicial | Proporciona la línea base de archivos y la estructura del proyecto. |
| E02 — Funciones usadas | Documenta el inventario de funciones que el Entregable 09 valida. |
| E03 — Cálculos PT | Describe los cálculos estadísticos que el Entregable 09 verifica mediante anexos y pruebas. |
| E04 — Puntajes | Detalla las fórmulas de puntajes que el Entregable 09 somete a prueba de reproducibilidad. |
| E05 — Prototipo UI | Establece el diseño de interfaz que el Entregable 09 audita en términos de trazabilidad (H3, H8). |
| E06 — Lógica de la app | Documenta la lógica reactiva del servidor Shiny que el Entregable 09 valida como auditable. |
| E07 — Dashboards | Proporciona las visualizaciones que el Entregable 09 confirma como parte del flujo operativo. |
| E08 — Beta final | Contiene las funciones finales (`funciones_finales.R`) que el Entregable 09 utiliza como base para las pruebas de reproducibilidad. |

El Entregable 09 integra la evidencia de los entregables anteriores en un conjunto consolidado de documentos y pruebas, cerrando el ciclo de validación técnica del aplicativo.

---

## 8. Riesgos y Limitaciones

### 8.1 Alcance de la validación

La validación documentada en el Entregable 09 cubre el motor de cálculo estadístico en R, la aplicación Shiny `app.R`, las funciones auxiliares y los artefactos de verificación. La validación se centra en demostrar que los cálculos son reproducibles y comparables con referencias documentadas. La validación **no cubre**:

- Rendimiento del aplicativo bajo carga concurrente.
- Seguridad de la infraestructura de despliegue.
- Validación formal de la interfaz de usuario por parte de usuarios finales.
- Validación externa específica de los puntajes z, z', zeta y En (sección reservada como pendiente en el informe de validación).

### 8.2 Pendientes explícitos de auditoría

Los siguientes puntos requieren confirmación antes de sostener una certificación completa de reproducibilidad:

1. **Disponibilidad de referencias externas:** los archivos Excel y VIVO utilizados en la validación cruzada del Algoritmo A deben localizarse y verificarse en el espacio de trabajo actual.
2. **Ejecución del pipeline de regeneración:** el script `genera_anexos.R` debe ejecutarse en el entorno actual para confirmar que reproduce los anexos CSV con resultados consistentes respecto a los datos de entrada vigentes.
3. **Correspondencia entre anexos y reportes:** debe verificarse que las cifras de los anexos CSV son coherentes entre sí y con los reportes DOCX/PDF existentes.
4. **Regeneración de reportes DOCX/PDF:** los reportes existentes se conservan como evidencia formateada pero no se regeneraron. Debe confirmarse si su contenido refleja la versión más reciente de los archivos Markdown.

### 8.3 Riesgos residuales

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Referencias externas no localizables | Impide confirmar la validación cruzada del Algoritmo A | Localizar los archivos Excel/VIVO o documentar su procedencia. |
| Pipeline no ejecutable en entorno actual | Impide regenerar anexos de forma automatizada | Verificar dependencias y rutas de acceso a datos. |
| Reportes DOCX/PDF desactualizados | Discrepancia entre evidencia formateada y contenido vigente | Regenerar reportes una vez confirmado el pipeline. |
| Sección de validación de puntajes pendiente | Brecha documental en la validación externa de puntajes | Completar la sección reservada en una próxima edición del informe. |

### 8.4 Sobre el lenguaje de certificación

Conforme a las recomendaciones de auditoría documental, el presente documento utiliza expresiones como **la evidencia disponible muestra** en lugar de afirmaciones de certificación absoluta. Esto refleja el estado actual del repositorio, donde ciertas referencias externas y el pipeline completo de regeneración requieren confirmación. No se afirma reproducibilidad plena mientras la evidencia externa Excel/VIVO no esté confirmada.

---

## 9. Documentos de Consulta

| Documento | Ubicación | Tipo |
|-----------|-----------|------|
| Informe de validación (v2.0) | `09_informe_final/md/informe_validacion.md` | Markdown / DOCX / PDF |
| Anexo de cálculos paso a paso | `09_informe_final/md/anexo_calculos.md` | Markdown / DOCX |
| Script generador de anexos | `09_informe_final/R/genera_anexos.R` | Script R |
| Pruebas de reproducibilidad | `09_informe_final/tests/test_09_reproducibilidad.R` | Script R |
| Anexos tabulares CSV | `09_informe_final/anexos/*.csv` | CSV |
| Log de generación | `09_informe_final/anexos/generacion_log.txt` | Texto |
| Overview del Entregable 09 | `Entregables_pt_app/e9.md` | Markdown |
| Bitácora de actualización 2026-06-16 | `Entregables_pt_app/bitacora_actualizacion_260616.md` | Markdown |
| ISO 13528:2022 | Referencia normativa | Estándar |
| ISO 17043:2023 | Referencia normativa | Estándar |

---

## 10. Conclusión

El Entregable 09 reúne la evidencia de validación, reproducibilidad y control de calidad de los cálculos del aplicativo PT App. La evidencia disponible muestra que el aplicativo dispone de un informe de validación, un anexo de cálculos paso a paso, un conjunto de anexos tabulares generados de forma automatizada y una suite de pruebas de reproducibilidad ejecutable.

Sin embargo, el estado documental recomendado es **requiere auditoría de evidencia**. Antes de sostener una certificación completa de reproducibilidad, deben confirmarse la disponibilidad de las referencias externas Excel/VIVO, la ejecución del pipeline completo de regeneración de anexos y la correspondencia entre los anexos CSV y los reportes DOCX/PDF existentes. Los reportes DOCX/PDF se conservan como evidencia formateada, pero no se regeneraron porque no se identificó un pipeline reproducible completo.

El presente documento se emite con la recomendación de ejecutar la auditoría de evidencia pendiente y, una vez cerrados los puntos de confirmación, proceder a una actualización del estado documental del Entregable 09.

---

**Documento versión:** 1.0
**Fecha de emisión:** 2026-06-28
**Estado:** Requiere auditoría de evidencia
**Próxima revisión sugerida:** tras completar la auditoría de referencias externas y el pipeline de regeneración.
