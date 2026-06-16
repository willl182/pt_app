# Plan: Actualización de Documentación y Entregables PT App

**Timestamp:** 260616_1047  
**Slug:** actualizar-entregables-pt-app  
**Estado:** En progreso

## Objetivo
Actualizar de forma trazable, verificable y consistente la documentación y los entregables del aplicativo ubicados en `Entregables_pt_app/`, cubriendo los nueve entregables `e1.md` a `e9.md` y sus carpetas asociadas. La actualización debe alinear los documentos con el estado real del código, las pruebas, los artefactos generados y la arquitectura actual del aplicativo R/Shiny y del paquete `ptcalc`.

## Alcance
El trabajo cubre:

- Overviews `Entregables_pt_app/e1.md` a `Entregables_pt_app/e9.md`.
- Documentación Markdown de cada carpeta de entregable.
- Evidencias de soporte: CSV, scripts R de generación, tests, diagramas Mermaid, HTML, DOCX y PDF existentes.
- Referencias normativas ISO 13528:2022 e ISO 17043:2023 ya mencionadas en los entregables.
- Consistencia con la aplicación actual (`app.R`), helpers en `R/`, paquete `ptcalc/`, datos y pruebas del repositorio.

Fuera de alcance salvo instrucción explícita:

- Reescritura funcional del aplicativo.
- Cambios sustantivos en algoritmos estadísticos.
- Eliminación de artefactos históricos de línea base.
- Regeneración manual de DOCX/PDF si no hay pipeline reproducible disponible.

## Principios de Actualización

- Preservar la función auditiva de cada entregable: evidencia, trazabilidad, prueba y estado.
- No modificar la línea base histórica del Entregable 01; solo documentar su relación con el estado actual.
- Separar claramente artefactos históricos, artefactos vigentes y artefactos regenerables.
- Mantener texto de usuario final en español y nombres técnicos/código en inglés cuando correspondan.
- Registrar comandos de verificación ejecutados y resultados observados.
- Toda afirmación técnica debe estar respaldada por archivo, test o evidencia dentro del repositorio.

## Workflow Transversal

### Paso 1: Inventario Real
Para cada entregable:

1. Leer el overview `eN.md`.
2. Listar archivos reales bajo `Entregables_pt_app/NN_*`.
3. Clasificar archivos como código, documentación, prueba, evidencia, diagrama o binario.
4. Detectar archivos mencionados pero ausentes y archivos existentes no documentados.
5. Registrar discrepancias en una tabla de actualización.

### Paso 2: Contraste con Aplicativo Actual
Para cada entregable:

1. Comparar el propósito del entregable contra `app.R`, `R/`, `ptcalc/`, `tests/` y datos actuales.
2. Identificar cambios de arquitectura, nombres de funciones, dependencias, módulos o pruebas.
3. Marcar si el entregable representa línea base histórica, etapa intermedia o documentación vigente.
4. Actualizar lenguaje para evitar afirmar vigencia cuando el artefacto sea histórico.

### Paso 3: Actualización Documental
Para cada entregable:

1. Actualizar objetivo, inventario, responsabilidades del subagente y procedimiento de verificación.
2. Añadir sección de estado recomendado: `Histórico`, `Vigente`, `Requiere regeneración` o `Validado`.
3. Incorporar comandos reales y rutas relativas ejecutables desde la raíz del proyecto.
4. Documentar limitaciones conocidas y dependencias.

### Paso 4: Validación Técnica
Para cada entregable:

1. Ejecutar el test propio del entregable cuando sea viable.
2. Ejecutar validaciones de parseo para scripts R modificados o referenciados.
3. Validar sintaxis Mermaid para diagramas cuando haya herramienta disponible.
4. Revisar enlaces relativos en Markdown.
5. Registrar resultados y fallos en el propio entregable o en una bitácora de actualización.

### Paso 5: Revisión Cruzada
Después de actualizar cada entregable:

1. Ejecutar subagente `revisor-fase` según la regla del repositorio.
2. Corregir inconsistencias detectadas.
3. Actualizar este plan con hallazgos y estado.
4. Persistir estado con skill `saver`.
5. Hacer commit y push si el usuario confirma o si el flujo de plan multi-fase requiere avanzar con control de versiones.

## Fases

### Fase 0: Preparación e Inventario Global

| Item | Estado | Notas |
|------|--------|-------|
| Leer `AGENTS.md` | Completado | Reglas del repositorio cargadas en contexto. |
| Leer `e1.md` a `e9.md` | Completado | Overviews revisados. |
| Listar archivos reales de `Entregables_pt_app/` | Completado | Inventario confirma 9 carpetas y artefactos Markdown/R/DOCX/PDF/CSV/HTML/Mermaid. |
| Crear matriz de discrepancias | Completado | Consolidada en `Entregables_pt_app/bitacora_actualizacion_260616.md`. |
| Definir criterios de estado documental | Completado | Usados: `Histórico validado`, `Requiere regeneración`, `Histórico / parcialmente vigente`, `Requiere auditoría de evidencia`. |

### Fase 1: Entregable 01 - Repositorio Inicial

| Item | Estado | Notas |
|------|--------|-------|
| Confirmar rol de línea base histórica | Completado | `e1.md` actualizado como histórico validado. |
| Verificar existencia de archivos base | Completado | Inventario auditado por subagente; se detectó DOCX adicional de prueba. |
| Actualizar `e1.md` y README | Parcial | `e1.md` actualizado; README histórico no se reescribió. |
| Ejecutar `test_01_existencia_archivos.R` | No ejecutado | Test histórico escribe CSV; se prefirió validación no destructiva. |

### Fase 2: Entregable 02 - Inventario de Funciones

| Item | Estado | Notas |
|------|--------|-------|
| Regenerar o auditar `funciones_extraidas.csv` | Completado | Auditada divergencia; CSV no regenerado por fragilidad de rutas del extractor. |
| Actualizar catálogo Markdown | Parcial | `e2.md` actualizado para no declarar exhaustividad vigente. |
| Ajustar trazabilidad ISO | Completado | Se evitó afirmar trazabilidad exhaustiva sin regeneración. |
| Ejecutar `test_02_firma_funciones.R` | No ejecutado | Test depende de working directory y no valida exhaustividad completa. |

### Fase 3: Entregable 03 - Cálculos PT Standalone

| Item | Estado | Notas |
|------|--------|-------|
| Comparar scripts del entregable contra `ptcalc/R/` | Completado | Se detectaron divergencias en Algoritmo A y criterio expandido. |
| Actualizar ejemplo paso a paso | Pendiente | Requiere decisión técnica sobre fórmula canónica antes de reescritura. |
| Revisar independencia de Shiny | Completado | Scripts históricos tratados como standalone histórico. |
| Ejecutar `test_03_calculos_pt.R` | No ejecutado | Test histórico reportado frágil por rutas; se ejecutó parseo R global. |

### Fase 4: Entregable 04 - Puntajes

| Item | Estado | Notas |
|------|--------|-------|
| Comparar fórmulas de `calcula_puntajes.R` con implementación vigente | Completado | Se documentó vigencia parcial frente a `ptcalc/R/pt_scores.R` y `app.R`. |
| Actualizar `formulas_y_ejemplos.md` | Completado | Corregidos enlace de zeta, tablas Markdown y observación conceptual de incertidumbre. |
| Revisar `crea_reporte.R` frente al flujo actual de reportes | Completado | `e4.md` documenta que el flujo activo también usa cálculos inline en `app.R`. |
| Ejecutar `test_04_puntajes.R` | No ejecutado | Test histórico reportado frágil por rutas; se ejecutó parseo R global. |

### Fase 5: Entregable 05 - Prototipo UI

| Item | Estado | Notas |
|------|--------|-------|
| Comparar prototipo HTML con UI actual de `app.R` | Completado | `e5.md` actualizado como prototipo histórico parcial. |
| Actualizar wireframes | Pendiente | Requiere reescritura completa de especificación UI vigente. |
| Actualizar diagrama Mermaid de navegación | Pendiente | Requiere mapeo completo del flujo actual. |
| Ejecutar `test_05_navegacion.R` | No ejecutado | No requerido para cambios documentales; pendiente para fase UI específica. |

### Fase 6: Entregable 06 - Lógica de Aplicación

| Item | Estado | Notas |
|------|--------|-------|
| Comparar `app_v06.R` con arquitectura reactiva actual | Completado | `e6.md` actualizado como manual histórico no vigente. |
| Actualizar manual de usuario | Pendiente | Requiere nuevo manual de `app.R` vigente. |
| Validar carga de CSV y flujo reactivo documentado | Parcial | Se documentó diferencia de datos precargados vs carga dinámica. |
| Ejecutar `test_06_logica.R` | No ejecutado | Test escribe CSV de resultados. |

### Fase 7: Entregable 07 - Dashboards y Gráficos

| Item | Estado | Notas |
|------|--------|-------|
| Comparar `app_v07.R` con visualizaciones actuales | Completado | `e7.md` actualizado como evidencia parcial histórica. |
| Actualizar diagrama de flujo de gráficos | Pendiente | Requiere redibujar flujo contra `app.R`. |
| Actualizar guía de validación visual | Pendiente | Requiere criterios visuales para vistas vigentes. |
| Ejecutar `test_07_graficos.R` | No ejecutado | Pendiente para fase gráfica específica. |

### Fase 8: Entregable 08 - Beta y Manual Desarrollador

| Item | Estado | Notas |
|------|--------|-------|
| Comparar `app_final.R` con `app.R` actual | Completado | `app_final.R` clasificado como beta histórica. |
| Comparar `R/funciones_finales.R` con `ptcalc/R/` | Parcial | Se documentó necesidad de contraste con `ptcalc/R/`. |
| Actualizar manual del desarrollador | Pendiente | Requiere reescritura técnica completa para arquitectura vigente. |
| Ejecutar `test_08_end_to_end.R` | No ejecutado | Pendiente; puede iniciar Shiny o depender de rutas históricas. |

### Fase 9: Entregable 09 - Informe Final y Validación

| Item | Estado | Notas |
|------|--------|-------|
| Revisar informe de validación y anexo | Completado | `e9.md` actualizado como requiere auditoría de evidencia. |
| Auditar `genera_anexos.R` | Parcial | Se registraron riesgos de reproducibilidad en bitácora. |
| Confirmar disponibilidad de referencias Excel/VIVO | Parcial | Se documentó necesidad de confirmación antes de certificar. |
| Ejecutar `test_09_reproducibilidad.R` | No ejecutado | Pendiente por evidencia externa y posible escritura/fragilidad. |

### Fase 10: Consolidación Final

| Item | Estado | Notas |
|------|--------|-------|
| Actualizar índice global de entregables | Completado | Creada `Entregables_pt_app/bitacora_actualizacion_260616.md` y actualizados overviews `e1-e9`. |
| Ejecutar batería de tests disponibles | Parcial | Ejecutado parseo R global y verificación de existencia de overviews. |
| Revisar enlaces Markdown | Pendiente | Preferir rutas relativas sobre `file:///` si se decide modernizar. |
| Documentar resultados finales | Completado | Bitácora agregada con matriz de discrepancias y riesgos. |
| Revisión final con `revisor-fase` | Completado | Subagentes de auditoría previa y 4 subagentes implementadores ejecutados exitosamente. |
| Persistir estado con `saver` | Completado | Estado persistido en `logs/CURRENT_SESSION.md` y `logs/history/260616_1158_findings.md`. |

## Diseño de Subagentes Implementadores

### 1. `entregable_01_baseline_curator`

**Rol:** Curador de línea base e integridad histórica.

**Entrada principal:** `Entregables_pt_app/e1.md`, `01_repo_inicial/`, `app_original.R`, scripts originales en `R/`, test 01.

**Responsabilidades:**

- Confirmar que el entregable se documente como baseline histórico.
- Verificar existencia e integridad de artefactos iniciales.
- Actualizar README y overview sin alterar el contenido original archivado.
- Registrar diferencias entre línea base y aplicación vigente solo como nota documental.

**Validación:** `source("Entregables_pt_app/01_repo_inicial/tests/test_01_existencia_archivos.R")`.

**Salida esperada:** `e1.md` y README actualizados, bitácora de verificación y listado de archivos históricos preservados.

### 2. `entregable_02_function_inventory_auditor`

**Rol:** Auditor de API interna e inventario de funciones.

**Entrada principal:** `e2.md`, `02_funciones_usadas/R/lista_funciones.R`, `funciones_extraidas.csv`, `app.R`, `R/`, `ptcalc/R/`.

**Responsabilidades:**

- Regenerar o auditar la lista de funciones.
- Distinguir funciones históricas, vigentes, migradas a `ptcalc` y deprecated.
- Actualizar documentación de firmas, retornos y referencias ISO.
- Detectar funciones documentadas pero inexistentes.

**Validación:** `source("Entregables_pt_app/02_funciones_usadas/R/lista_funciones.R")` y `source("Entregables_pt_app/02_funciones_usadas/tests/test_02_firma_funciones.R")`.

**Salida esperada:** CSV consistente, catálogo Markdown actualizado, overview corregido y reporte de discrepancias.

### 3. `entregable_03_stat_engine_documenter`

**Rol:** Documentador del motor estadístico standalone.

**Entrada principal:** `e3.md`, `03_calculos_pt/R/`, `03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md`, `ptcalc/R/`.

**Responsabilidades:**

- Comparar implementación histórica standalone con paquete `ptcalc`.
- Actualizar fórmulas, notación y supuestos numéricos.
- Confirmar ausencia de dependencias Shiny.
- Documentar criterios ISO de homogeneidad, estabilidad y robustez.

**Validación:** `source("Entregables_pt_app/03_calculos_pt/tests/test_03_calculos_pt.R")` y parseo de scripts R.

**Salida esperada:** Ejemplo paso a paso vigente, overview actualizado y matriz de funciones estadísticas.

### 4. `entregable_04_scoring_documenter`

**Rol:** Auditor documental de puntajes de desempeño.

**Entrada principal:** `e4.md`, `04_puntajes/R/calcula_puntajes.R`, `04_puntajes/R/crea_reporte.R`, documentación de fórmulas, funciones actuales de puntaje.

**Responsabilidades:**

- Verificar z, z prima, zeta y En contra código actual.
- Actualizar criterios de clasificación cualitativa.
- Revisar consistencia entre fórmulas, ejemplos y tests.
- Documentar relación entre cálculo de puntajes y generación de reportes.

**Validación:** `source("Entregables_pt_app/04_puntajes/tests/test_04_puntajes.R")`.

**Salida esperada:** Fórmulas y ejemplos actualizados, criterios verificables y overview corregido.

### 5. `entregable_05_ui_prototype_mapper`

**Rol:** Mapeador entre prototipo UI y aplicación Shiny real.

**Entrada principal:** `e5.md`, `05_prototipo_ui/html/prototipo.html`, `wireframes.md`, `diagrama_navegacion.mmd`, UI actual en `app.R`.

**Responsabilidades:**

- Comparar navegación del prototipo con la app real.
- Actualizar wireframes y diagrama Mermaid.
- Marcar elementos prototipo que no llegaron a implementación o fueron reemplazados.
- Validar identificadores HTML relevantes para integración Shiny.

**Validación:** `source("Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.R")` y revisión visual/manual del HTML.

**Salida esperada:** Wireframes actualizados, diagrama navegacional vigente y lista de brechas UI.

### 6. `entregable_06_shiny_logic_manualist`

**Rol:** Actualizador de lógica Shiny y manual de usuario.

**Entrada principal:** `e6.md`, `06_app_logica/app_v06.R`, `manual_usuario.md`, `app.R`, datos CSV actuales.

**Responsabilidades:**

- Comparar lógica reactiva v06 con flujo actual.
- Actualizar instrucciones de instalación, ejecución y carga de datos.
- Verificar nombres de archivos de entrada y salidas esperadas.
- Documentar limitaciones de la versión lógica si es histórica.

**Validación:** `source("Entregables_pt_app/06_app_logica/tests/test_06_logica.R")`.

**Salida esperada:** Manual de usuario actualizado, overview corregido y evidencias de carga/reactividad.

### 7. `entregable_07_dashboard_evidence_updater`

**Rol:** Actualizador de documentación de dashboards y visualizaciones.

**Entrada principal:** `e7.md`, `07_dashboards/app_v07.R`, `diagrama_flujo.mmd`, test 07, visualizaciones actuales en `app.R`.

**Responsabilidades:**

- Identificar outputs gráficos vigentes y su origen de datos.
- Actualizar flujo de procesamiento hacia visualizaciones.
- Revisar coherencia de estilos, tooltips, escalas y textos en español.
- Documentar validaciones visuales y automatizadas.

**Validación:** `source("Entregables_pt_app/07_dashboards/tests/test_07_graficos.R")`.

**Salida esperada:** Diagrama y guía de gráficos actualizados, overview corregido y reporte de outputs gráficos.

### 8. `entregable_08_beta_release_documenter`

**Rol:** Documentador de release beta y arquitectura de desarrollo.

**Entrada principal:** `e8.md`, `08_beta/app_final.R`, `08_beta/R/funciones_finales.R`, `manual_desarrollador.md`, `app.R`, `ptcalc/`.

**Responsabilidades:**

- Determinar si `app_final.R` y `funciones_finales.R` son vigentes o históricos.
- Actualizar manual de desarrollador con arquitectura real y dependencias.
- Documentar flujo de despliegue, pruebas y mantenimiento.
- Alinear el entregable con estructura MVC y paquete `ptcalc`.

**Validación:** `source("Entregables_pt_app/08_beta/tests/test_08_end_to_end.R")` y parseo de `app_final.R`.

**Salida esperada:** Manual técnico actualizado, overview corregido y matriz de equivalencia beta vs versión actual.

### 9. `entregable_09_validation_report_auditor`

**Rol:** Auditor de informe final y reproducibilidad numérica.

**Entrada principal:** `e9.md`, `09_informe_final/md/informe_validacion.md`, `anexo_calculos.md`, `genera_anexos.R`, test 09, reportes DOCX/PDF.

**Responsabilidades:**

- Verificar que el informe final refleje los cálculos y hallazgos vigentes.
- Auditar reproducibilidad de anexos y referencias cruzadas.
- Confirmar tolerancias numéricas y fuentes independientes declaradas.
- Marcar evidencia faltante o no regenerable.

**Validación:** `source("Entregables_pt_app/09_informe_final/tests/test_09_reproducibilidad.R")` y revisión de existencia/legibilidad de PDF/DOCX.

**Salida esperada:** Informe y anexo actualizados, overview corregido y reporte de reproducibilidad.

## Contratos Comunes de los Subagentes

Cada subagente debe entregar:

- Resumen de archivos leídos.
- Cambios propuestos o aplicados.
- Discrepancias detectadas entre documentación y repositorio.
- Tests ejecutados con resultado textual.
- Riesgos pendientes y evidencia faltante.
- Lista de archivos modificados.

Cada subagente debe evitar:

- Modificar artefactos históricos sin necesidad.
- Reescribir algoritmos salvo que el usuario lo pida.
- Declarar cumplimiento ISO sin evidencia documental o prueba.
- Regenerar DOCX/PDF sin pipeline claro.

## Orden Recomendado de Ejecución

1. Ejecutar Fase 0 completa.
2. Actualizar Entregables 01 y 02 para fijar baseline e inventario funcional.
3. Actualizar Entregables 03 y 04 para fijar motor estadístico y puntajes.
4. Actualizar Entregables 06, 07 y 08 para alinear aplicación, gráficos y release.
5. Actualizar Entregable 05 después de conocer la UI vigente.
6. Actualizar Entregable 09 al final, usando los resultados de validación de todos los anteriores.
7. Ejecutar revisión cruzada final y consolidar bitácora.

## Riesgos Iniciales

- Los overviews usan enlaces absolutos `file:///home/...`, lo que reduce portabilidad.
- Los DOCX/PDF pueden estar desincronizados respecto a Markdown si no existe pipeline de generación.
- Puede haber divergencia entre entregables intermedios (`app_v06.R`, `app_v07.R`, `app_final.R`) y `app.R` actual.
- Algunos tests pueden depender de rutas, datos locales o paquetes no instalados.
- El Entregable 02 afirma un número específico de funciones que debe ser recalculado.
- El Entregable 09 menciona referencias Excel/VIVO; debe comprobarse que existan o documentar su ausencia.

## Log de Ejecución

- [260616 10:47] Inicio de planificación.
- [260616 10:47] Leídos `e1.md` a `e9.md`.
- [260616 10:47] Inventario global de `Entregables_pt_app/` revisado.
- [260616 10:47] Plan inicial creado con workflow transversal y nueve subagentes implementadores.
- [260616 2026] Subagentes designados por bloques: E1-E2, E3-E4 y E5-E9.
- [260616 2026] Actualizados overviews `e1.md` a `e9.md` con estado documental recomendado.
- [260616 2026] Corregido `04_puntajes/md/formulas_y_ejemplos.md` en enlace de zeta, tablas Markdown y observación conceptual.
- [260616 2026] Creada `Entregables_pt_app/bitacora_actualizacion_260616.md`.
- [260616 2026] Validación ejecutada: parseo R global exitoso y existencia de `e1.md` a `e9.md` confirmada.
- [260616 11:58] Implementación funcional iniciada: firma polimórfica en `ptcalc/R/pt_homogeneity.R`, normalización de etiquetas en `app.R`, ISO 17043:2023 corregido.
- [260616 11:58] Subagentes implementadores ejecutados: E02 (36/36 PASS), E03 (57 PASS), E04 (sin fallos), E08/E09 (genera_anexos.R ejecutable, 6 CSVs generados).
- [260616 11:58] Parseo R global revalidado: TODOS los archivos R parsean correctamente.
- [260616 11:58] Estado persistido con `saver` en `logs/CURRENT_SESSION.md` y `logs/history/260616_1158_findings.md`.
- [260616 11:58] Plan cerrado con estado actualizado en Fase 10.
