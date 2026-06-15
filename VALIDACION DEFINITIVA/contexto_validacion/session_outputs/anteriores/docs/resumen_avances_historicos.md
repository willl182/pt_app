# Historial Cronológico de Avances — PT Analysis Application (pt_app)

Este documento detalla, de manera sistemática y por orden cronológico, todos los hitos, planes, problemas resueltos y hallazgos registrados en el proyecto de procesamiento estadístico de ensayos de aptitud conforme a las normas **ISO 13528:2022** e **ISO 17043:2023**.

---

## 📅 Febrero 2026

### 2026-02-05 — Fase 1: Auditoría de Cálculos Iniciales
* **Objetivo de la Fase**: Auditar y verificar los cálculos de homogeneidad y estabilidad implementados en la app Shiny y el paquete `ptcalc` contra las hojas de cálculo oficiales.
* **Hitos y Hallazgos**:
  - **Auditoría de CO 0-μmol/mol**: Verificación exitosa de los cálculos de homogeneidad y estabilidad contra el libro original `data/Homogenidad y estabilidad.xlsx`. Se corroboró que el promedio, la desviación estándar entre muestras ($s_x$) y la desviación estándar dentro de las muestras ($s_w$) coinciden exactamente.
  - **Discrepancia en $\sigma_{pt}$**: Se identificó que el valor de $\sigma_{pt}$ usado en el Excel de auditoría (0.00579) no coincidía con el calculado en `ptcalc` (0.03982 vía MADe). Se planteó y confirmó la hipótesis de que este valor procede de un criterio prescrito externamente en lugar de ser calculado algorítmicamente.
  - **Detección de Error en Fórmulas del Excel**: Se identificó un error matemático en la celda `F23` de la hoja de cálculo de auditoría que producía `#NUM!`. La aplicación resolvió correctamente la estimación obteniendo $s_s = 0.01786$.
* **Planes de Trabajo**:
  - `260205_1411_plan_auditoria-verificacion-calculos-homogeneidad-co.md`: Plan maestro para la auditoría estadística inicial.
* **Archivos Relacionados**: `logs/history/260205_1405_findings.md`, `logs/history/260205_1435_findings.md`.

---

## 📅 Marzo 2026

### 2026-03-10 — Fase 2: Correcciones Estadísticas Críticas (Track `opus` / `codex`)
* **Objetivo de la Fase**: Resolver los 9 hallazgos estadísticos y de usabilidad identificados en el Informe No. 2, integrando las ramas de desarrollo `opus` y `codex`.
* **Hitos y Hallazgos**:
  - **Hallazgo 1 (Fórmula B.10 Corregida)**: Se reemplazó la expresión ambigua `abs(s_x_bar_sq - sw_sq/m)` por `max(0, s_x_bar_sq - (sw_sq/m))` en `pt_homogeneity.R`, `calculate_stability_stats()` y `funciones_finales.R` para alinearse estrictamente con ISO 13528:2022 y evitar raíces de números negativos.
  - **Hallazgo 2 (Aislamiento de MADe)**: Se renombró el estimador MADe usado específicamente en homogeneidad a `MADe_hom` o `sigma_pt_hom` para evitar colisiones conceptuales con la desviación estándar de la aptitud ($\sigma_{pt}$) usada en la evaluación de desempeño.
  - **Hallazgo 4 (Umbral del Algoritmo A)**: Se ajustó el umbral del Algoritmo A para ejecutarse únicamente cuando el número de laboratorios es $n \geq 12$ (§9.4 de la norma). Para conjuntos de datos con $n < 12$, se determinó usar directamente MADe o nIQR.
  - **Trazabilidad de Ejecución**: Se implementó una clave compuesta indexada por `pollutant || n_lab || level || run` en los reactivos de la app Shiny, habilitando el selector de corridas en Valor Asignado, Puntajes PT e Informe Global.
* **Planes de Trabajo**:
  - `260310_0219_plan_comparar-implementaciones-opus-codex-ajustes-app.md`: Planificación para consolidar las dos ramas de desarrollo de los agentes anteriores.
* **Archivos Relacionados**: `logs/history/260310_0729_findings.md`, `logs/history/260310_0734_findings.md`, `logs/history/260310_1919_findings.md`, `logs/history/260310_2008_problems.md`.

### 2026-03-11 — Validación Cruzada del Algoritmo A
* **Objetivo de la Fase**: Garantizar la reproducibilidad exacta del Algoritmo A mediante una validación cruzada y pruebas en entornos aislados.
* **Hitos y Hallazgos**:
  - **Consistencia Matemática**: Pruebas con el conjunto de datos de prueba `summary_n13` para validar que las iteraciones de la media robusta ($x^*$) y la desviación estándar robusta ($s^*$) convergen exactamente bajo los límites ISO.
* **Planes de Trabajo**:
  - `260311_1837_plan_validacion_cruzada_algo_a.md`: Estructura para la validación numérica robusta.
* **Archivos Relacionados**: `logs/history/260311_1909_findings.md` al `260311_1913_findings.md`.

### 2026-03-12 a 2026-03-22 — Procedimiento Estadístico y Planes Downstream
* **Planes de Trabajo**:
  - `260312_plan_actualizar_procedimiento_estadistico.md`: Estructuración normativa de los cambios.
  - `260313_1153_plan_informe_validacion_v2.md`: Preparación de reportes de calidad.
  - `260322_1644_plan_claude.md`: Planificación de validaciones sistemáticas.

### 2026-03-30 — Fase 3: Pipeline de Validación Tripartita (POC GPT53CDX)
* **Objetivo de la Fase**: Construir un marco de validación tripartito para garantizar que no existan discrepancias numéricas en los cálculos estadísticos aguas abajo del Algoritmo A.
* **Hitos y Hallazgos**:
  - **Estrategia Tripartita**: Se desarrolló una comparación de cálculos paralela e independiente en tres motores diferentes:
    1. Lógica operativa dentro del código de `app.R` (APP).
    2. Implementación de R puro e independiente (R).
    3. Script de Python puro utilizando únicamente la biblioteca estándar sin dependencias (Python).
  - **Identificación de Tolerancias**: Inicialmente se obtuvieron 4,446 discrepancias estadísticas por el uso de una tolerancia excesivamente baja (`1e-12`) al comparar cuantiles e interpolaciones entre R y Python. Se estableció formalmente `ALGO_A_TOL = 1e-04`.
  - **Criterio de Estabilidad Fijo**: Se acordó calcular la incertidumbre de estabilidad de forma incondicional como $u_{stab} = d_{max} / \sqrt{3}$.
  - **Control para Nivel Cero**: Para mediciones de calibración en nivel 0 (donde $\sigma_{pt} \approx 0$), se determinó forzar `NA` en los puntajes de los participantes para evitar divisiones por cero.
* **Planes de Trabajo**:
  - `260330_1055_plan_a2.md`, `260330_1118_plan_a1_validacion_post_algoA.md`, y `260330_1216_plan_poc-gpt-53cdx.md`.
* **Archivos Relacionados**: `logs/history/260330_1055_findings.md`, `logs/history/260330_1216_findings.md`, `logs/history/260330_1216_problems.md`.

### 2026-03-31 — Fase 4: Completación de Etapas Downstream (Homogeneidad, Estabilidad, Incertidumbres, Scores)
* **Objetivo de la Fase**: Completar la integración y validación paso a paso de las etapas downstream en la validación tripartita para 15 combinaciones críticas (5 contaminantes × niveles 1, 3, 5).
* **Hitos y Hallazgos**:
  - **Fase 2 (Homogeneidad)**: Validación matemática perfecta de la media general, desviación entre muestras ($s_x$), desviación dentro de muestras ($s_w$), desviación estándar de la homogeneidad ($s_s$) y el criterio de aceptación $s_s \leq 0.3\,\sigma_{pt}$.
  - **Fase 3 (Estabilidad)**: Verificación exacta del estadístico de estabilidad $|\bar{y} - \bar{x}| \leq 0.3\,\sigma_{pt}$.
  - **Fase 4 (Cadena de Incertidumbres)**: Validación de la incertidumbre estándar combinada del valor asignado $u(x_{pt}) = \sqrt{u_{char}^2 + u_{hom}^2 + u_{stab}^2}$ y la incertidumbre expandida $U(x_{pt})$ con factor de cobertura $k=2$.
  - **Fase 5 (Puntajes de Desempeño)**: Verificación sin fallas numéricas de los puntajes de aptitud: puntaje $z$, puntaje $z'$, puntaje zeta ($\zeta$) y número de error normalizado ($E_n$).
* **Planes de Trabajo**:
  - `260331_1251_plan_fase-2-homogeneidad.md` al `260331_1902_plan_fase-5-scores.md`.
* **Archivos Relacionados**: `logs/history/260331_1315_findings.md` al `logs/history/260331_2131_findings.md`.

---

## 📅 Abril 2026

### 2026-04-20 — Fase 5: Cifras Significativas ISO 13528
* **Objetivo de la Fase**: Incorporar las reglas de cifras significativas de la norma en la convergencia del Algoritmo A y el formateo de visualización en la interfaz de la Shiny app.
* **Hitos y Hallazgos**:
  - **Alineación con Reglas de Cifras Significativas**: Se modificó el criterio de convergencia interna de los algoritmos robustos y se reconfiguraron los redondeos lógicos basados en el número de decimales representativos de los valores asignados.
  - **Documentación del Core**: Documentación completa mediante sintaxis Roxygen2 de la función fundamental `run_algorithm_a()`.
* **Planes de Trabajo**:
  - `260420_1459_plan_cifras-significativas-implementacion.md` y `260420_1508_plan_cifras-significativas.md`.
* **Archivos Relacionados**: `logs/history/260420_2311_findings.md`, `logs/history/260420_2324_findings.md`.

### 2026-04-22 — Fase 6: Deprecación de la Columna `sample_group`
* **Objetivo de la Fase**: Eliminar campos obsoletos y sin uso del contrato de datos de entrada para simplificar el flujo y robustecer la validación.
* **Hitos y Hallazgos**:
  - **Deprecación Completa de `sample_group`**: Remoción de esta columna en los archivos CSV de ejemplo (`summary_n*.csv`) y en el preprocesador de datos.
  - **Control Preventivo**: Implementación de un aviso visual en Shiny (`showNotification`) si el usuario intenta cargar un archivo que todavía conserve esta columna.
  - **ptcalc v0.1.1**: Bump de versión del paquete matemático interno y documentación formal de los cambios en el archivo `NEWS.md`.
* **Planes de Trabajo**:
  - `260422_1906_plan_deprecar-sample-group.md`.
* **Archivos Relacionados**: `logs/history/260422_1958_findings.md`.

### 2026-04-24 a 2026-04-25 — Arquitectura de Preprocesamiento y Modularización Desde Cero
* **Objetivo de la Fase**: Implementar de forma nativa e integrada el módulo de limpieza y preparación de datos en `pt_app` para estandarizar el consumo de archivos crudos provenientes del laboratorio de Calaire.
* **Hitos y Hallazgos**:
  - **Ajuste Conceptual Clave**: Se corrigió el mapeo de `uncertainty_std` del participante. Antes se trataba erróneamente de forma expandida; ahora se asocia unívocamente a la incertidumbre estándar ($u_{xi}$) reportada por cada laboratorio participante.
  - **Creación de `R/preprocessing/`**: Estructuración del módulo desde cero con scripts especializados (`read_calaire_raw.R`, `clean_calaire_raw.R`, `hourly_averages.R`, `moving_hourly_means.R`, `pipeline_calaire.R`, etc.) para desacoplar el pipeline de preprocesamiento de la Shiny App.
* **Planes de Trabajo**:
  - `260424_1624_plan_preprocesamiento-calaire.md`, `260424_1646_plan_ajuste-incertidumbre-participante.md`, y `260425_1127_plan_preprocesamiento-calaire.md`.
* **Archivos Relacionados**: `logs/history/260424_1624_findings.md`, `logs/history/260424_1723_findings.md`, `logs/history/260425_1127_findings.md`, `logs/history/260425_1133_problems.md`.

---

## 📅 Mayo 2026

### 2026-05-06 — Integración de Preprocesador de Referencia Calaire
* **Objetivo de la Fase**: Integrar y orquestar el flujo de datos crudos de referencia en la interfaz Shiny.
* **Hitos y Hallazgos**:
  - **Integración Operativa**: Desarrollo de un flujo de preprocesamiento dedicado únicamente a la referencia, permitiendo cargar estos archivos directamente y procesarlos mediante los algoritmos de la app Shiny.
  - **Procesamiento de Ensayo**: Validación y orquestación con el conjunto de datos de prueba `part_1`.
* **Planes de Trabajo**:
  - `260506_1913_plan_revision-preprocesador-referencia-calaire.md` al `260506_2117_plan_procesamiento-ensayo-part-1.md`.
* **Archivos Relacionados**: `logs/history/260506_2037_findings.md`, `logs/history/260506_2112_findings.md`, `logs/history/260506_2119_findings.md`.

### 2026-05-08 — Limpieza Integral del Repositorio
* **Planes de Trabajo**:
  - `260508_2328_plan_reorganizar-repo-limpiar-artefactos.md`: Plan maestro para eliminar artefactos huérfanos, consolidar carpetas temporales y reestructurar de manera limpia el código operativo.

### 2026-05-12 — Validación de Cálculos en Entorno Dedicado (`validation_3`)
* **Objetivo de la Fase**: Iniciar una campaña rigurosa de validación de cálculos en entornos limpios (`validation_1` y `validation_3`) para el contaminante $O_3$ y sus tres niveles de concentración.
* **Hitos y Hallazgos**:
  - **Validación Etapa 1 (Estadísticos Robustos)**: Verificación cruzada exitosa del Algoritmo A, MADe y nIQR en el entorno controlado.
  - **Validación Etapa 2 (Homogeneidad)**: Análisis y validación de los datos de homogeneidad simulados para el $O_3$ en tres niveles de concentración.
  - **Preparación de Estabilidad**: Análisis metodológico pre-implementación de la estabilidad para verificar su consistencia antes de la ejecución de código.
* **Planes de Trabajo**:
  - `260512_2102_plan_validacion-calculos-pt-app.md` y `260512_2109_plan_validar-calculos-app-etapas.md`.
* **Archivos Relacionados**: `logs/history/260512_2253_findings.md` al `260512_2327_findings.md`.

### 2026-05-13 — Validación Masiva de $O_3$ con Fórmulas Nativas en Excel y Criterio de Laboratorios Expertos
* **Objetivo de la Fase**: Diseñar y ejecutar un plan masivo de validación creando libros Excel automatizados que calculen y validen cada etapa del ensayo de aptitud utilizando fórmulas nativas, y refinar los cálculos del Algoritmo A.
* **Hitos y Hallazgos**:
  - **Campaña de Validación con Fórmulas**: Ejecución exitosa de 9 fases de trabajo (`excel-formulas-validacion-o3`) para construir plantillas de validación interactivas e independientes en Excel para el contaminante $O_3$. Los libros contienen fórmulas nativas y dinámicas que cubren Estadísticos Robustos, Homogeneidad, Estabilidad, Cadena de Incertidumbre y Puntajes.
  - **Método de Laboratorios Expertos (Método 4)**: Se incorporó la opción de estimar la desviación estándar de la aptitud ($\sigma_{pt}$) basada en el consenso de laboratorios expertos mediante la función `calculate_expert_sigma_pt()`, integrándolo armoniosamente en la Shiny App sin alterar el modelo de datos.
  - **Estabilización de Algoritmo A**: Se corrigió un bug en la convergencia del Algoritmo A. Si el estimador robusto inicial $s^*_0$ calculado por MADe es cero pero el conjunto de datos aún posee variación aritmética, el algoritmo ahora sustituye $s^*_0$ por `stats::sd(values)` para prevenir que el bucle de iteración se aborte.
  - **Perfeccionamiento del Reporte**: Se eliminaron dependencias rígidas de visualización, permitiendo a la app renderizar imágenes anchas y estructurando el informe de validación final de manera elegante.
* **Planes de Trabajo**:
  - `260513_0528_plan_validacion-redondeo-consenso-scores.md`, `260513_0850_plan_reformular-validacion-excel-o3.md`, y el plan maestro `260513_1304_plan_excel-formulas-validacion-o3.md`.
* **Archivos Relacionados**: Gran cantidad de reportes de problemas y hallazgos (`logs/history/260513_*_findings.md` y `logs/history/260513_*_problems.md`).

### 2026-05-14 — Bootstrap Reproducible y Refinamiento UI/UX de Puntajes
* **Objetivo de la Fase**: Proveer robustez estadística a la simulación de homogeneidad y estabilidad mediante bootstrap reproducible, y refinar la interfaz y los puntajes.
* **Hitos y Hallazgos**:
  - **Bootstrap Reproducible**: Desarrollo del script `build_bootstrap_homogeneity_stability.R` parametrizado con semilla fija `13528` y 200 iteraciones. Genera tres conjuntos de salidas (simulado minutal, consolidado horario por ID de conjunto de datos y los archivos del aplicativo `ronda_1_homogeneidad.csv` y `ronda_1_estabilidad.csv`).
  - **Carga de Incertidumbres en Shiny**: Habilitación en `app.R` del consumo consolidado de incertidumbres estándar ($u_{xi}$) y resultados resumidos cargados por los participantes.
  - **Refinamiento de UI/UX**: Actualización de la vista de puntajes y outliers en la app Shiny. Se añadió la visualización explícita del parámetro $\sigma_{pt}$ y se integró **MathJax/LaTeX** para renderizar nativamente las fórmulas estadísticas en lugar de texto plano.
* **Planes de Trabajo**:
  - `260514_2008_plan-bootstrap-homogeneidad-estabilidad.md`.
* **Archivos Relacionados**: `logs/history/260514_1843_findings.md` al `260514_2247_problems.md`.

### 2026-05-15 — Robustez del Reporte Final, Heatmap General y Compatibilidad Metrológica
* **Objetivo de la Fase**: Actualizar la plantilla de informes finales para eliminar dependencias obsoletas y garantizar la generación reproducible de reportes.
* **Hitos y Hallazgos**:
  - **Alineación del Reporte Final (`report_template.Rmd`)**: Se reescribió y blindó la plantilla agregando validaciones exhaustivas (`is_nonempty_df()`), eliminando supuestos obsoletos (como el participante fijo `"ref"`) y renombrados posicionales rígidos que quebraban la generación ante cambios de estructura.
  - **Selector de Participante Individual**: Se introdujo el parámetro reactivo `report_participant` en la Shiny App para que el usuario pueda descargar e imprimir el informe de un participante específico en el Anexo C.
  - **Independencia del Heatmap**: Se corrigió el heatmap global para que continúe mostrando la visualización comparativa de todos los laboratorios de la ronda y no se filtre individualmente por el selector de participante.
  - **Formatos y Compatibilidad**: Validación exitosa del motor de renderizado HTML y DOCX (con imágenes y gráficos vectoriales nativos de patchwork).
* **Planes de Trabajo**:
  - `260515_0940_plan_ajuste-template-informe-final.md`.
* **Archivos Relacionados**: `logs/history/260515_0938_problems.md`, `logs/history/260515_1050_problems.md`, `logs/history/260515_1209_problems.md`, `logs/history/260515_1210_findings.md`.

### 2026-05-19 — Guía de Procedimiento y Orquestación Definitiva de Preprocesamiento
* **Objetivo de la Fase**: Elaborar el marco de referencia formal (guía operativa) y establecer un flujo de preprocesamiento de datos definitivo y libre de fallos para la frontera entre `pt_app` y `calaire-app`.
* **Hitos y Hallazgos**:
  - **Guía del Procedimiento v1.1 (`docs/guia-procedimiento-ronda-participantes.md`)**: Redacción completa y corrección de conformidad de la guía. Define un marco detallado marcando explícitamente los roles: `[PARTICIPANTE - AUTÓNOMO]`, `[PARTICIPANTE - CARGA EN APLICATIVO]`, `[CALAIRE - CONFIGURACIÓN]`, `[CALAIRE - PROCESAMIENTO INTERNO]`, `[CALAIRE - VALIDACIÓN]`, `[CALAIRE - NO DIVULGAR]`, y `[COMÚN]`.
  - **Asociación Individual de Incertidumbres**: Se ajustó la guía para asegurar que la incertidumbre expandida ($U_{xi}$) y el factor de cobertura ($k$) se traten como variables por resultado reportado (combinación participante + ronda) y no de forma global por ronda. Se documentó formalmente la brecha técnica en el CSV consolidado actual (que no almacena $U_{xi}$ ni $k$) para corregirlo en una fase técnica posterior.
  - **Alineación de Criterios de Rechazo por Nivel**: Se actualizaron las reglas de consistencia de datos para distinguir claramente entre el nivel cero (donde se solicita **un solo dato/promedio** y no aplica desviación estándar) y los niveles distintos de cero (donde se exigen **tres datos/promedios**).
  - **Contrato de Preprocesamiento (`docs/workflow-preprocesamiento.md`)**: Definición clara del flujo definitivo de datos para la exportación de referencia (`pt_app` hacia `calaire-app`) e importación de participantes.
  - **Consolidación Flexible**: Creación del script wrapper `scripts/aplicativo/consolidar_ronda_pt_app.R` y ajuste de `convert_pt_app_to_calaire_app.R` (modos `participants`, `reference`, `all`) para permitir la orquestación automatizada de datos procesados, consolidando archivos de 20 filas tanto con participantes internos como externos de `calaire-app`.
* **Planes de Trabajo**:
  - `260519_1044_plan_guia-procedimiento-ronda-participantes.md` y `260519_1342_plan_workflow-definitivo-preprocesamiento.md`.
* **Archivos Relacionados**: `logs/history/260519_1111_findings.md` al `logs/history/260519_1253_problems.md`.

---

## 📈 Resumen de la Evolución del Paquete R `ptcalc`
* **v0.1.0**: Versión inicial que implementaba el Algoritmo A, MADe, nIQR, estadísticos robustos, homogeneidad, estabilidad y cálculo de puntajes.
* **v0.1.1 (2026-04-22)**:
  - Eliminación definitiva y deprecación del soporte para la columna `sample_group` en los contratos estadísticos internos.
  - Documentación de la deprecación en el archivo `NEWS.md`.
* **Mejoras Core Adicionales (2026-05-13)**:
  - Robustecimiento del Algoritmo A en `ptcalc/R/pt_robust_stats.R` para sustituir $s^*_0 = 0$ por `sd(values)` si existe dispersión aritmética en los datos, evitando el quiebre de la iteración.
  - Incorporación del estimador de consenso de laboratorios expertos para el cálculo de $\sigma_{pt}$.

---

## 🔍 Conclusiones y Brechas Técnicas Documentadas (Vigentes)
1. **Brecha de Incertidumbre Expandida en Consolidado**: La interfaz solicita $u(x)$ ($u_{xi}$) y $u(x)\text{ exp}$ ($U_{xi}$), pero el consolidado actual (`ronda_1_completa.csv`) únicamente almacena `u_value` ($u_{xi}$). Se ha documentado la necesidad de corregir el modelo de datos y la orquestación para persistir $U_{xi}$ y el factor de cobertura $k$ por cada participante y combinación de ronda.
2. **Exposición de Datos de Referencia**: Se debe asegurar que las vistas de los participantes en `calaire-app` o los listados consolidados compartidos con laboratorios externos estén completamente limpios de filas de referencia (`tipo == "referencia"`), preservando la confidencialidad de la ronda.
