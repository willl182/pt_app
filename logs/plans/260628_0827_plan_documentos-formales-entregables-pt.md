# Plan: Documentos formales para entregables PT App

**Timestamp:** 260628_0827
**Slug:** documentos-formales-entregables-pt
**Estado:** En progreso

## Objetivo

Convertir la documentación actual de `Entregables_pt_app` en un conjunto de documentos técnicos formales, bien presentados y comprensibles para lectores no desarrolladores. Cada entregable debe tener un documento propio en formato editable y presentable, con explicación clara del propósito, alcance, evidencia, estado real, riesgos y relación con los documentos técnicos de soporte.

El objetivo no es hacer un resumen corto ni maquillar los README existentes. El resultado esperado es que cada entregable pueda presentarse ante una persona común, evaluadora o administrativa, sin exigirle leer código ni entender R/Shiny, pero dejando trazabilidad suficiente para que los detalles técnicos estén disponibles en anexos o documentos especializados.

## Criterios de Calidad

| Criterio | Requisito |
|----------|-----------|
| Audiencia | Lenguaje claro, institucional y aterrizado; evitar jerga de desarrollador salvo cuando se explique. |
| Profundidad | Revisión detallada de cada entregable, no ficha breve ni README renombrado. |
| Presentación | Documento Word por entregable, con portada, control de versión, tablas, secciones claras y anexos/referencias. |
| Honestidad técnica | Diferenciar evidencia histórica, evidencia vigente, vigencia parcial y pendientes de auditoría. |
| Trazabilidad | Remitir a archivos fuente, pruebas, anexos, informes y evidencia disponible sin saturar el cuerpo principal. |
| Defensa del proyecto | Explicar qué demuestra cada entregable y por qué cumple una función dentro del desarrollo del aplicativo. |
| Riesgos | Señalar límites reales de cada entregable para evitar afirmaciones que no puedan sostenerse. |

## Estructura Base de Cada Documento

Cada documento por entregable debe seguir una estructura común, ajustada al contenido específico:

| Sección | Propósito |
|---------|-----------|
| Portada | Nombre del entregable, proyecto, institución, fecha, versión y responsable documental. |
| Resumen Ejecutivo | Explicar en 1 a 2 páginas qué contiene el entregable, por qué existe y qué evidencia aporta. |
| Contexto del Entregable | Ubicar el entregable dentro de la evolución del aplicativo PT App. |
| Alcance | Qué cubre y qué no cubre el entregable. |
| Contenido Entregado | Inventario explicado de documentos, código, pruebas, anexos y reportes. |
| Explicación Funcional | Traducción del contenido técnico a lenguaje comprensible para no desarrolladores. |
| Evidencia de Verificación | Qué pruebas existen, qué validan y cómo interpretar sus resultados. |
| Estado Actual | Vigente, histórico, parcialmente vigente o pendiente de auditoría, con justificación. |
| Relación con Otros Entregables | Cómo se conecta con fases anteriores y posteriores. |
| Riesgos y Limitaciones | Aspectos que no deben sobreafirmarse en una entrega formal. |
| Documentos de Consulta | Rutas a documentos detallados, anexos técnicos, pruebas y archivos de soporte. |
| Conclusión | Valor del entregable dentro del proyecto y recomendación de uso. |

## Fases

### Fase 1: Diagnóstico documental e inventario defendible

| Item | Estado | Notas |
|------|--------|-------|
| Leer `AGENTS.md` y reglas del proyecto | Completado | Instrucciones críticas revisadas antes de crear este plan. |
| Revisar estructura completa de `Entregables_pt_app` | Completado | Hay 9 entregables principales, overviews `e1.md` a `e9.md`, DOCX existentes, código, pruebas, anexos y reportes. |
| Identificar documentos que no son suficientes para entrega formal | En progreso | Los README/overviews actuales son útiles como inventario interno, pero no como documento final para lectores no técnicos. |
| Clasificar cada entregable por estado documental | Pendiente | Usar estados ya detectados: histórico validado, regenerado, histórico, parcial, beta no vigente, requiere auditoría. |
| Crear matriz de evidencia por entregable | Pendiente | Debe listar qué prueba, anexo, documento o archivo respalda cada afirmación. |

### Fase 2: Definir línea editorial y plantilla institucional

| Item | Estado | Notas |
|------|--------|-------|
| Diseñar plantilla Word/Markdown común | Pendiente | Debe evitar apariencia de README y funcionar como documento técnico formal. |
| Definir tono para lectores no desarrolladores | Pendiente | Lenguaje claro, con explicación de términos como Shiny, puntajes, homogeneidad, estabilidad y validación. |
| Definir reglas de profundidad | Pendiente | Cuerpo principal explicativo; fórmulas, rutas, código y pruebas se remiten a anexos o documentos detallados. |
| Crear glosario común | Pendiente | PT, ISO 13528, ISO 17043, valor asignado, sigma_pt, z-score, homogeneidad, estabilidad, reproducibilidad. |
| Definir formato de tablas | Pendiente | Tablas de contenido, evidencia, trazabilidad, riesgos y documentos relacionados. |

### Fase 3: Elaborar documentos por entregable

| Item | Estado | Notas |
|------|--------|-------|
| Documento Entregable 01: Repositorio inicial | Pendiente | Enfatizar línea base, trazabilidad histórica e integridad del punto de partida. |
| Documento Entregable 02: Funciones usadas | Pendiente | Presentar inventario funcional de 77 funciones sin convertirlo en listado técnico ininteligible. |
| Documento Entregable 03: Cálculos PT standalone | Pendiente | Explicar motor matemático histórico y necesidad de alineación con `ptcalc`. |
| Documento Entregable 04: Puntajes de desempeño | Pendiente | Explicar cómo se evalúa desempeño de laboratorios y distinguir vigencia parcial. |
| Documento Entregable 05: Prototipo de interfaz | Pendiente | Presentar diseño inicial como evidencia de planeación, no como interfaz vigente. |
| Documento Entregable 06: Lógica de aplicación y manual | Pendiente | Explicar integración Shiny histórica y aclarar que el manual no describe toda la app actual. |
| Documento Entregable 07: Dashboards y gráficos | Pendiente | Mostrar valor de visualización y dejar claro que es evidencia parcial frente a `app.R`. |
| Documento Entregable 08: Beta y documentación final | Pendiente | Separar beta histórica de aplicación vigente para no inducir error. |
| Documento Entregable 09: Informe final y validación | Pendiente | Tratarlo con máxima cautela: validación, anexos, reproducibilidad y evidencia pendiente de auditoría. |

### Fase 4: Revisión técnica y revisión para lector común

| Item | Estado | Notas |
|------|--------|-------|
| Revisar consistencia entre documentos y `e1.md` a `e9.md` | Pendiente | Ningún documento debe contradecir estados ya auditados. |
| Revisar que cada afirmación tenga evidencia | Pendiente | Especial atención a E03, E04, E07, E08 y E09. |
| Simplificar lenguaje técnico sin perder precisión | Pendiente | Convertir jerga en explicación, no eliminar contenido importante. |
| Validar que los documentos no parezcan README | Pendiente | Deben tener portada, narrativa, tablas y conclusión formal. |
| Ejecutar subagente `revisor-fase` o revisión equivalente | Pendiente | Requisito del flujo para cierre de fase. |

### Fase 5: Exportación, empaquetado y control final

| Item | Estado | Notas |
|------|--------|-------|
| Exportar cada documento a DOCX | Pendiente | Formato principal de entrega editable. |
| Exportar versión PDF si se requiere entrega cerrada | Pendiente | Recomendado para documentos finales a evaluadores. |
| Crear índice maestro de entregables | Pendiente | Documento corto que indique qué archivo corresponde a cada entregable y cómo leer el paquete. |
| Verificar enlaces/rutas y anexos | Pendiente | Evitar enlaces `file://` en documentos finales si no son adecuados para entrega externa. |
| Persistir estado con skill `saver` | Pendiente | Requisito al completar fases. |
| Git commit y push | Pendiente | Requisito del flujo del proyecto si se ejecuta la elaboración. |

## Entregables Documentales Esperados

| Entregable | Documento formal propuesto | Fuente principal | Estado a comunicar |
|------------|----------------------------|------------------|--------------------|
| 01 | `documento_tecnico_entregable_01.docx` | `01_repo_inicial`, `e1.md` | Histórico validado |
| 02 | `documento_tecnico_entregable_02.docx` | `02_funciones_usadas`, `e2.md` | Regenerado y enriquecido |
| 03 | `documento_tecnico_entregable_03.docx` | `03_calculos_pt`, `e3.md`, `ptcalc/R` | Histórico / requiere alineación |
| 04 | `documento_tecnico_entregable_04.docx` | `04_puntajes`, `e4.md`, `ptcalc/R/pt_scores.R` | Histórico / parcialmente vigente |
| 05 | `documento_tecnico_entregable_05.docx` | `05_prototipo_ui`, `e5.md` | Histórico / prototipo parcial |
| 06 | `documento_tecnico_entregable_06.docx` | `06_app_logica`, `e6.md`, `app.R` | Histórico / manual no vigente |
| 07 | `documento_tecnico_entregable_07.docx` | `07_dashboards`, `e7.md`, `app.R` | Parcial / evidencia histórica |
| 08 | `documento_tecnico_entregable_08.docx` | `08_beta`, `e8.md`, `app.R`, `ptcalc/R` | Histórico / beta no vigente |
| 09 | `documento_tecnico_entregable_09.docx` | `09_informe_final`, `e9.md`, anexos | Requiere auditoría de evidencia |

## Plan Detallado por Entregable

### Entregable 01: Repositorio de Código y Scripts Iniciales

**Propósito del documento:** presentar el entregable como la línea base del proyecto: el punto de partida congelado antes de cambios, mejoras o refactorizaciones.

**Enfoque para lector común:** explicar que una línea base funciona como una copia de seguridad verificable. No es "la app final", sino la evidencia de cómo estaba el sistema al inicio y contra qué se pueden comparar los cambios posteriores.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | Copia de `app_original.R`, carpeta `R/`, pruebas y resultados de verificación. |
| Por qué importa | Permite demostrar control de cambios, trazabilidad y preservación del estado inicial. |
| Cómo se verificó | Explicar existencia de archivos, comparación por hash SHA256 y revisión sintáctica R en lenguaje no técnico. |
| Qué no demuestra | No demuestra que la aplicación final esté validada; solo demuestra conservación del punto inicial. |
| Evidencia consultable | `README.md`, `README.docx`, `tests/test_01_existencia_archivos.R`, `test_01_resultados.csv`, `e1.md`. |

**Riesgo de redacción:** evitar frases como "sistema validado" o "versión funcional final". Debe decir "línea base histórica validada".

**Resultado esperado:** documento formal que deje claro que E01 es evidencia de control documental y de integridad del punto de partida.

### Entregable 02: Funciones Usadas en `app.R`, `R/` y `ptcalc/R/`

**Propósito del documento:** presentar el inventario funcional de la aplicación como mapa de capacidades: qué funciones existen, para qué sirven y dónde están documentadas.

**Enfoque para lector común:** no listar 77 funciones una por una en el cuerpo principal. Agruparlas por familias comprensibles: carga de datos, cálculos estadísticos, homogeneidad/estabilidad, puntajes, reportes, visualización y funciones obsoletas.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | Inventario CSV, documentación completa en DOCX/MD, extractor automático y pruebas de firmas. |
| Evolución del entregable | Explicar que pasó de 48 funciones escuetas a 77 funciones documentadas y categorizadas. |
| Familias funcionales | Traducir categorías técnicas a capacidades del sistema. |
| Trazabilidad ISO | Explicar que algunas funciones se asocian con ISO 13528:2022 e ISO 17043:2023. |
| Cómo se mantiene | Describir `R/lista_funciones.R` como herramienta para regenerar documentación cuando cambie el código. |
| Evidencia consultable | `funciones_extraidas.csv`, `documentacion_funciones.docx`, `README.md`, `tests/test_02_firma_funciones.R`, `test_02_resultados.csv`, `e2.md`. |

**Riesgo de redacción:** evitar que parezca manual para programadores. El detalle de firmas debe remitirse a `documentacion_funciones.docx`.

**Resultado esperado:** documento que explique el inventario como evidencia de orden, trazabilidad y mantenibilidad del aplicativo.

### Entregable 03: Cálculos PT Standalone

**Propósito del documento:** presentar el primer núcleo matemático independiente de la interfaz, explicando qué cálculos de ensayos de aptitud cubre y por qué se separó de Shiny.

**Enfoque para lector común:** explicar "standalone" como cálculos que pueden entenderse y probarse sin depender de botones, pantallas o navegación de la aplicación.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | Scripts de homogeneidad, estabilidad, estadística robusta, valor asignado y sigma_pt. |
| Qué problema resuelve | Separa la matemática del aplicativo visual para poder revisarla y probarla con más control. |
| Conceptos explicados | Homogeneidad, estabilidad, valor asignado, desviación estándar para evaluación y estadísticos robustos. |
| Verificación | Pruebas unitarias de cálculos y ejemplo paso a paso. |
| Estado real | Histórico; requiere alineación con `ptcalc/R/` antes de declararse vigente. |
| Evidencia consultable | `R/*.R`, `ejemplo_calculo_paso_a_paso.docx`, `tests/test_03_calculos_pt.R`, `tests/test_03_resultados.csv`, `e3.md`, `ptcalc/R`. |

**Riesgo de redacción:** no afirmar que estos scripts son el motor vigente si existen divergencias frente a `ptcalc`. El documento debe ser honesto: evidencia histórica útil, no fuente operativa final.

**Resultado esperado:** documento que muestre que hubo desarrollo matemático verificable y que precise su relación con la implementación actual.

### Entregable 04: Módulo de Cálculo de Puntajes

**Propósito del documento:** explicar cómo el aplicativo evalúa el desempeño de laboratorios participantes mediante puntajes de aptitud.

**Enfoque para lector común:** presentar los puntajes como indicadores de desempeño, sin cargar el cuerpo principal con derivaciones matemáticas extensas. Las fórmulas detalladas van como referencia.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | Scripts de cálculo de puntajes, documento de fórmulas y pruebas. |
| Qué significa evaluar desempeño | Explicar categorías como satisfactorio, cuestionable y no satisfactorio. |
| Puntajes cubiertos | z, z', zeta y En, explicados en lenguaje común y con uso práctico. |
| Evidencia de cálculo | Pruebas automatizadas y documento `formulas_y_ejemplos.docx`. |
| Estado real | Histórico / parcialmente vigente; las fórmulas base viven en `ptcalc/R/pt_scores.R` y parte del flujo está en `app.R`. |
| Riesgo de etiquetas | Normalizar y explicar diferencia entre "No satisfactorio" e "Insatisfactorio" si aparece en evidencia histórica. |

**Evidencia consultable:** `R/calcula_puntajes.R`, `R/crea_reporte.R`, `formulas_y_ejemplos.docx`, `tests/test_04_puntajes.R`, `e4.md`, `ptcalc/R/pt_scores.R`.

**Resultado esperado:** documento que permita defender cómo se evalúa el desempeño sin exigir al lector revisar código.

### Entregable 05: Prototipo Estático de Interfaz

**Propósito del documento:** presentar el prototipo como evidencia de diseño, navegación y planeación de la experiencia de usuario.

**Enfoque para lector común:** explicar que un prototipo no es la aplicación final, sino una maqueta interactiva para revisar organización de pantallas, rutas de navegación y presentación esperada.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | Prototipo HTML, wireframes, diagrama de navegación y pruebas de estructura. |
| Qué demuestra | Planeación de interfaz, navegación y organización funcional inicial. |
| Qué no demuestra | No demuestra coincidencia exacta con `app.R` actual ni validación de cálculos. |
| Relación con usuario final | Explicar cómo ayuda a visualizar carga de datos, análisis, resultados y reportes. |
| Estado real | Histórico / prototipo parcial. |
| Evidencia consultable | `html/prototipo.html`, `wireframes.docx`, `mmd/diagrama_navegacion.mmd`, `tests/test_05_navegacion.R`, `e5.md`. |

**Riesgo de redacción:** no presentar capturas o descripción del prototipo como si fueran la interfaz vigente.

**Resultado esperado:** documento que convierta el prototipo en evidencia formal de diseño, no en promesa de funcionalidad actual.

### Entregable 06: Lógica de la Aplicación y Manual de Usuario

**Propósito del documento:** explicar la integración entre cálculos y aplicación Shiny en una versión histórica de la app, junto con un manual de uso de esa etapa.

**Enfoque para lector común:** explicar Shiny como la tecnología que permite convertir cálculos R en una aplicación web interactiva. Aclarar que la lógica reactiva significa que los resultados se actualizan según datos y selecciones del usuario.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | `app_v06.R`, manual de usuario, pruebas funcionales y log CSV. |
| Qué avance representa | Paso desde scripts separados hacia una aplicación interactiva con lógica integrada. |
| Qué cubre el manual | Instalación, ejecución y navegación de la versión v06. |
| Qué no cubre | Flujo completo actual con carga dinámica, preprocesador, reportes y funcionalidades posteriores. |
| Estado real | Histórico / manual no vigente. |
| Evidencia consultable | `app_v06.R`, `manual_usuario.docx`, `tests/test_06_logica.R`, `tests/test_06_logica.csv`, `e6.md`, `app.R`. |

**Riesgo de redacción:** no entregar el manual v06 como manual final del aplicativo actual.

**Resultado esperado:** documento que explique la etapa de integración sin confundirla con la versión vigente.

### Entregable 07: Dashboards y Gráficos

**Propósito del documento:** presentar la incorporación de visualizaciones como medio para interpretar resultados de ensayos de aptitud.

**Enfoque para lector común:** explicar que los gráficos ayudan a identificar patrones, desempeños, alertas y comparaciones entre participantes o métodos, sin entrar en detalles de librerías salvo como soporte.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | `app_v07.R`, diagrama de flujo, pruebas y guías de gráficos. |
| Qué avance representa | Paso desde tablas/resultados hacia paneles visuales. |
| Qué visualizaciones se evidencian | Gráficos y paneles integrados en la versión histórica. |
| Relación con la app vigente | Explicar que `app.R` actual contiene más vistas, heatmaps y reportes que deben mapearse aparte. |
| Estado real | Parcial / evidencia histórica. |
| Evidencia consultable | `app_v07.R`, `md/diagrama_flujo.mmd`, `tests/test_07_graficos.R`, `tests/test_07_graficos.docx`, `e7.md`, `app.R`. |

**Riesgo de redacción:** no afirmar cobertura total de dashboards actuales con base solo en E07.

**Resultado esperado:** documento que defienda la evolución visual del proyecto y sus límites.

### Entregable 08: Versión Beta y Documentación Final

**Propósito del documento:** explicar la consolidación beta del aplicativo y su documentación técnica como hito de integración, separándola de la versión vigente.

**Enfoque para lector común:** explicar "beta" como una versión integrada de prueba o consolidación, no necesariamente la versión final actualmente operativa.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | `app_final.R`, `funciones_finales.R`, manual de desarrollador y pruebas end-to-end. |
| Qué representa | Integración de módulos en una versión beta de trabajo. |
| Qué validan las pruebas E2E | Que el flujo completo de esa versión se puede recorrer y calcular sin errores esperados. |
| Diferencia con versión vigente | La app principal vigente es `app.R`; la lógica reutilizable actual debe contrastarse con `ptcalc/R/`. |
| Estado real | Histórico / beta no vigente. |
| Evidencia consultable | `app_final.R`, `R/funciones_finales.R`, `manual_desarrollador.docx`, `tests/test_08_end_to_end.R`, `e8.md`, `app.R`, `ptcalc/R`. |

**Riesgo de redacción:** no llamar "final" a la beta en sentido contractual si ya no representa la aplicación vigente.

**Resultado esperado:** documento que rescate E08 como hito de integración sin crear una contradicción con el estado actual.

### Entregable 09: Informe Final y Validación de Cálculos

**Propósito del documento:** presentar la evidencia de validación, reproducibilidad y control de calidad de cálculos del aplicativo.

**Enfoque para lector común:** explicar validación como comparación controlada entre resultados del aplicativo y referencias o datos esperados. Evitar lenguaje absoluto si la evidencia externa no está completamente disponible.

**Secciones específicas a desarrollar:**

| Sección | Contenido requerido |
|---------|---------------------|
| Qué se entrega | Informe de validación, anexo de cálculos, anexos CSV, script de generación y prueba de reproducibilidad. |
| Qué intenta demostrar | Que los cálculos pueden reproducirse y compararse contra referencias documentadas. |
| Qué evidencia existe | DOCX/PDF, anexos CSV, `genera_anexos.R`, `test_09_reproducibilidad.R`. |
| Qué debe auditarse | Confirmar referencias Excel/VIVO, pipeline completo de regeneración y correspondencia de anexos. |
| Cómo redactar resultados | Hablar de evidencia disponible y pruebas ejecutables, no de certificación absoluta si no está todo confirmado. |
| Estado real | Requiere auditoría de evidencia. |
| Evidencia consultable | `informe_validacion.docx`, `informe_validacion.pdf`, `anexo_calculos.docx`, `anexos/*.csv`, `R/genera_anexos.R`, `tests/test_09_reproducibilidad.R`, `e9.md`. |

**Riesgo de redacción:** este es el entregable donde más fácil se puede "quedar mal" si se promete más de lo que la evidencia sostiene. Debe tener una sección explícita de alcance de validación y pendientes de confirmación.

**Resultado esperado:** documento robusto, cuidadoso y defendible sobre validación, con anexos claros y afirmaciones verificables.

## Reglas de Redacción por Riesgo

| Caso | Redacción permitida | Redacción que debe evitarse |
|------|---------------------|-----------------------------|
| Entregable histórico | "Conserva evidencia de una fase anterior..." | "Representa la versión actual..." |
| Vigencia parcial | "El contenido sigue siendo útil para..." | "Cubre completamente..." |
| Validación pendiente | "La evidencia disponible muestra..." | "Certifica de forma definitiva..." |
| Código o pruebas | "Existe una prueba automatizada que verifica..." | "El sistema está libre de errores..." |
| Documentos técnicos detallados | "Para fórmulas y detalles, consultar..." | Incluir todo el código o fórmulas extensas en el cuerpo principal. |

## Log de Ejecución

- [260628 08:27] Inicio del plan; revisión de `AGENTS.md`, estructura de `Entregables_pt_app`, overviews `e1.md` a `e9.md` y bitácora de actualización 2026-06-16.
- [260628 08:27] Se identifica que los README/overviews actuales no son suficientes como entregables formales para una audiencia no desarrolladora.
- [260628 08:27] Se define enfoque: documento formal por entregable, con lenguaje claro, evidencia, estado real, limitaciones y remisión a anexos técnicos.
- [260628 13:55] Corrección documental aplicada: E05 dejó de ser bloqueo reproducible, se corrigieron erratas visibles en `testb`, se agregó bitácora de verificación de E05, se agregó matriz de evidencia externa pendiente en E09, se regeneraron 11 DOCX y se verificó integridad con `unzip -t`.
- [260628 13:55] Verificación E05 desde raíz completada: 76 expectativas PASS, 0 fallos, 0 advertencias. Verificación desde `Entregables_pt_app/05_prototipo_ui/`: 17 bloques de prueba PASS.
- [260628 13:55] Pendientes para cierre final: normalizar rutas abreviadas desde raíz, homogeneizar plantilla visual completa y localizar o descartar formalmente evidencia externa Excel/VIVO para E09.
- [260628 13:55] Revisión de fase completada con subagente: sin bloqueantes. Riesgos residuales documentados: E09 mantiene evidencia externa pendiente; E04/E07/E08 conservan advertencias menores ya registradas; el plan sigue en progreso porque quedan mejoras documentales no críticas.

## Decisiones Iniciales

- No reemplazar los documentos técnicos detallados existentes; usarlos como anexos y fuentes de respaldo.
- No presentar los entregables históricos como si fueran la versión actual del aplicativo.
- Crear documentos independientes por entregable, no un único resumen general.
- Mantener una línea editorial común para que el paquete completo se vea coherente.
- Priorizar claridad y defensa institucional sobre detalle de código.

## Riesgos Iniciales

- El Entregable 09 requiere especial cuidado: no debe afirmarse reproducibilidad plena si la evidencia externa Excel/VIVO no está confirmada en el workspace.
- Los Entregables 03, 04, 06, 07 y 08 tienen diferencias frente a la aplicación vigente; los documentos deben explicarlas con transparencia.
- Si se dejan rutas locales absolutas o enlaces `file://` en documentos finales, pueden fallar al entregar el paquete fuera del equipo local.
- Un documento demasiado técnico puede no servir para evaluadores comunes; uno demasiado superficial puede parecer incompleto. La solución será cuerpo explicativo más anexos técnicos.
