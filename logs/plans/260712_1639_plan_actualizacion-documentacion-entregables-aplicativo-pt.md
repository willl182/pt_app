# Plan: Actualización integral de documentación entregable del aplicativo PT

**Timestamp:** 260712_1639
**Slug:** actualizacion-documentacion-entregables-aplicativo-pt
**Estado:** En progreso

## Objetivo

Dejar actualizado, completo y auditable el paquete documental ubicado en
`Entregables_pt_app/`, tomando como única referencia funcional vigente el
estado actual del aplicativo (`app.R`, `R/`, `ptcalc/`, datos, pruebas y
validaciones reproducibles del repositorio).

La documentación principal estará escrita para personas no técnicas: explicará
qué hace el aplicativo, qué información requiere, cómo se usa, qué resultado
produce y cómo interpretar cada pantalla. Los detalles de arquitectura, código,
fórmulas y pruebas quedarán como anexos técnicos y evidencia de auditoría, sin
interrumpir el recorrido del usuario común.

El cierre comprenderá los nueve entregables contractuales, sus fuentes Markdown,
versiones DOCX/PDF cuando correspondan, capturas actuales obtenidas con
Playwright y una matriz maestra que permita rastrear cada afirmación hasta una
pantalla, archivo, prueba o resultado verificable.

## Criterios rectores

- **Fuente vigente:** documentar el comportamiento comprobado de `app.R` y de
  los módulos usados por este, no asumir que las copias históricas `app_v06.R`,
  `app_v07.R` o `app_final.R` representan la versión actual.
- **Lenguaje ciudadano:** empezar por propósito, preparación, pasos e
  interpretación; definir términos técnicos la primera vez que aparezcan.
- **Separación por audiencia:** cuerpo principal para usuarios y responsables
  contractuales; anexos para desarrolladores, administradores y auditores.
- **Evidencia verificable:** toda declaración de funcionalidad, prueba o
  conformidad deberá indicar fecha, versión/commit, fuente y resultado.
- **Capturas reproducibles:** generar las imágenes mediante Playwright, con
  datos de demostración no sensibles, viewport fijo, nombres estables y un
  índice que indique pantalla, acción previa, archivo destino y documento que
  la utiliza.
- **Coherencia editorial:** español correcto, terminología uniforme, numeración,
  tablas y pies de figura consistentes; código y nombres internos pueden
  permanecer en inglés.
- **Normativa prudente:** distinguir entre funcionalidad implementada,
  validación ejecutada y conformidad normativa; evitar certificar más de lo que
  demuestre la evidencia disponible.
- **Entregable autocontenido:** no depender de rutas ambiguas ni documentos
  externos sin identificarlos; usar rutas relativas verificables dentro del
  paquete final.
- **Control documental:** incluir título, código/número de entregable, versión,
  fecha, responsable, estado, historial de cambios y aprobaciones pendientes.

## Alcance documental por entregable

| Entregable | Documento principal para actualizar | Enfoque para público general | Evidencia/anexos de auditoría |
|---|---|---|---|
| 01. Repositorio inicial | `01_repo_inicial/README.md` y DOCX | Qué se recibió, para qué sirve cada grupo de archivos y cómo comprobar que el paquete está completo | Inventario con hash/estado, estructura vigente, prueba de existencia y aclaración de copias históricas |
| 02. Funciones usadas | `02_funciones_usadas/README.md` y `md/documentacion_funciones.md` | Mapa de capacidades explicado por tarea del usuario, no como listado aislado de funciones | Inventario regenerado desde `app.R`, `R/` y `ptcalc/R`; firma, origen, exportación, uso real y pruebas |
| 03. Cálculos PT | `03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md` y DOCX | Ejemplo guiado con entradas, resultado y lectura práctica de homogeneidad, estabilidad, valor asignado y dispersión | Fórmulas, referencias ISO autorizadas, datos fuente, precisión, redondeo y reproducción con código vigente |
| 04. Puntajes | `04_puntajes/md/formulas_y_ejemplos.md` y DOCX | Qué significa cada puntaje, cuándo se usa y cómo leer satisfactorio/cuestionable/no satisfactorio | Fórmulas z, z’, zeta y En, incertidumbres, límites, casos NA y comparación contra salidas actuales |
| 05. Interfaz | `05_prototipo_ui/md/wireframes.md`, HTML y DOCX | Recorrido visual real de la interfaz actual, controles y mensajes esperados | Comparación prototipo–implementación, mapa de navegación y capturas Playwright etiquetadas |
| 06. Lógica y manual | `06_app_logica/md/manual_usuario.md` y DOCX | Manual de usuario completo desde preparación de archivos hasta exportación e informes | Reglas de validación, estados, errores frecuentes, archivos de ejemplo y casos de uso reproducibles |
| 07. Dashboards | Documento narrativo nuevo en `07_dashboards/md/` y DOCX | Cómo leer tablas, gráficos, colores, filtros y advertencias de cada tablero | Fuente de datos, condiciones de generación, pruebas visuales/funcionales y capturas actuales |
| 08. Beta/final | `08_beta/md/manual_desarrollador.md` y DOCX, con resumen operativo | Instalación, operación, mantenimiento y límites de la versión entregada, diferenciando usuario de administrador | Arquitectura vigente, dependencias/versiones, despliegue, configuración, respaldo, diagnóstico y pruebas E2E |
| 09. Informe final | `09_informe_final/md/informe_validacion.md`, anexo, DOCX y PDF | Resumen ejecutivo comprensible: alcance, qué se verificó, resultados, límites y recomendaciones | Matriz de validación, resultados fechados, cálculos reproducibles, riesgos residuales y anexos generados |

## Matriz mínima de capturas Playwright

Se tomará como punto de partida el flujo de
`dgpsea03/scripts/tomar_capturas.js`, pero se revisarán los selectores y el
contenido contra la interfaz vigente antes de reutilizarlo. Las capturas se
guardarán dentro de `Entregables_pt_app/` en una carpeta común de evidencia, y
los documentos referenciarán esa única fuente para evitar duplicados.

| ID | Escenario | Estado que debe verse | Documentos consumidores |
|---|---|---|---|
| CAP-01 | Inicio y carga | Archivos requeridos, formatos y estado inicial | E01, E05, E06 |
| CAP-02 | Carga válida | Confirmación de homogeneidad, estabilidad y resumen | E05, E06, E08 |
| CAP-03 | Preprocesador | Modal, campos, propósito y salida esperada | E05, E06 |
| CAP-04 | Homogeneidad previa | Selección/configuración antes de ejecutar | E03, E05, E06 |
| CAP-05 | Homogeneidad resultado | Tabla/gráfico, criterio y conclusión | E03, E06, E07, E09 |
| CAP-06 | Estabilidad resultado | Tabla/gráfico, criterio y conclusión | E03, E06, E07, E09 |
| CAP-07 | Incertidumbre de H/E | Componentes y lectura de resultados | E03, E06, E09 |
| CAP-08 | Valores atípicos | Identificación, controles y efecto esperado | E03, E06, E07 |
| CAP-09 | Algoritmo A | Ejecución y resumen de iteraciones | E02, E03, E06, E09 |
| CAP-10 | Valor consenso | Valor asignado, dispersión e incertidumbre | E03, E06, E07, E09 |
| CAP-11 | Compatibilidad metrológica | Comparación referencia–consenso | E03, E06, E07, E09 |
| CAP-12 | Resumen de puntajes | Resultado agregado por participante | E04, E06, E07, E09 |
| CAP-13 | Puntajes z y z’ | Tabla/gráfico y clasificación | E04, E06, E07 |
| CAP-14 | Puntajes zeta y En | Tabla/gráfico y clasificación | E04, E06, E07 |
| CAP-15 | Informe global | Resumen, filtros y mensajes clave | E06, E07, E09 |
| CAP-16 | Participantes | Consulta individual y datos disponibles | E06, E07 |
| CAP-17 | Generación de informes | Parámetros, validaciones y descarga | E06, E08, E09 |
| CAP-18 | Error de archivo | Mensaje de validación y forma de corregirlo | E06, E08 |
| CAP-19 | Vista en resolución menor | Comportamiento usable sin ocultar acciones críticas | E05, E06, E08 |

Cada captura deberá tener pie con: `ID`, título, fecha, versión/commit,
resolución, datos de prueba y descripción de lo que demuestra. Antes de cerrar
se verificará que no aparezcan nombres personales, rutas locales, datos
sensibles, errores de consola, controles cortados ni resultados incoherentes.

## Fases

### Fase 1: Línea base e inventario auditable

| Item | Estado | Notas |
|---|---|---|
| Congelar la identificación de la versión documental | Pendiente | Registrar fecha, rama, commit, estado del árbol y versión de R/paquetes relevantes; no modificar cambios ajenos existentes |
| Inventariar todos los archivos de `Entregables_pt_app/` | Pendiente | Clasificar fuente, derivado, ejecutable, prueba, dato, evidencia e histórico |
| Comparar con fuentes documentales paralelas | Pendiente | Revisar `testb/`, `dgpsea03/`, `VALIDACION DEFINITIVA/`, `docs/`, README raíz y bitácoras; rescatar evidencia sin copiar contradicciones |
| Levantar mapa funcional del aplicativo actual | Pendiente | Pestañas, subpestañas, entradas, cálculos, salidas, descargas, mensajes, dependencias y rutas de datos |
| Construir matriz de brechas por entregable | Pendiente | Marcar contenido vigente, obsoleto, ausente, duplicado, no verificable y pendiente de aprobación |
| Identificar requisitos contractuales disponibles | Pendiente | Vincular contrato/TDR/actas si están en el repositorio; si no, registrar explícitamente la limitación y solicitar fuente al responsable |

**Salida de fase:** inventario maestro, mapa funcional, matriz de brechas y lista
de fuentes autorizadas.

**Puerta de calidad:** ejecutar `revisor-fase`; incorporar hallazgos al presente
plan; usar skill `saver`; ejecutar pruebas pertinentes; hacer commit y push de
la fase conforme a `AGENTS.md`.

### Fase 2: Estructura editorial y control documental

| Item | Estado | Notas |
|---|---|---|
| Definir plantilla común | Pendiente | Portada, ficha de control, objetivo, alcance, audiencia, prerrequisitos, procedimiento, resultados, problemas frecuentes, evidencia, referencias y cambios |
| Crear índice maestro contractual | Pendiente | Nueve entregables, versión, estado, archivos oficiales, anexos y relación con requisitos |
| Definir glosario ciudadano | Pendiente | PT, analito, ronda, ítem, valor asignado, incertidumbre, sigma PT, puntajes y categorías |
| Fijar convención de evidencia | Pendiente | IDs para requisitos, capturas, pruebas, tablas, hallazgos y anexos |
| Separar documentos por audiencia | Pendiente | Manual de usuario/operación, soporte técnico y validación/auditoría claramente diferenciados |
| Definir cadena de generación | Pendiente | Markdown como fuente controlada; DOCX/PDF como derivados con estilos, metadatos e índices actualizables |

**Salida de fase:** plantilla aprobable, índice maestro, glosario, esquema de IDs y
matriz requisito–documento–evidencia.

**Puerta de calidad:** `revisor-fase`, actualización del plan, skill `saver`,
pruebas de enlaces/estructura, commit y push.

### Fase 3: Evidencia visual reproducible con Playwright

| Item | Estado | Notas |
|---|---|---|
| Preparar datos de demostración | Pendiente | Copias estables, sin información sensible, suficientes para recorrer todas las funciones documentadas |
| Revisar y robustecer script Playwright | Pendiente | Selectores semánticos, esperas por estados reales, viewport fijo, salida determinista y fallo explícito si falta contenido |
| Capturar camino feliz completo | Pendiente | CAP-01 a CAP-17, incluyendo todas las variantes de puntajes visibles |
| Capturar validaciones y resolución menor | Pendiente | CAP-18 y CAP-19; mensajes legibles y acciones de recuperación |
| Generar índice de capturas | Pendiente | Acción previa, selector/estado esperado, archivo, hash, fecha, commit y documentos consumidores |
| Revisar calidad y privacidad | Pendiente | Nitidez, recorte, escala, ortografía, coherencia numérica, ausencia de datos personales y errores visibles |
| Integrar capturas en fuentes | Pendiente | Numeración y pies consistentes; texto alternativo y referencias cruzadas |

**Salida de fase:** script Playwright ejecutable, conjunto de capturas vigente,
índice técnico y registro de ejecución.

**Puerta de calidad:** `revisor-fase`, actualización del plan, skill `saver`,
repetición limpia del recorrido Playwright, commit y push.

### Fase 4: Actualización de entregables 01 a 04

| Item | Estado | Notas |
|---|---|---|
| Actualizar E01 | Pendiente | Inventario y explicación del paquete realmente entregado; diferenciar histórico de vigente |
| Actualizar E02 | Pendiente | Regenerar catálogo desde código actual y añadir mapa de capacidades en lenguaje sencillo |
| Actualizar E03 | Pendiente | Rehacer ejemplo reproducible con datos, fórmulas, unidades, redondeos, salida e interpretación actuales |
| Actualizar E04 | Pendiente | Verificar fórmulas, incertidumbres, umbrales, etiquetas y ejemplos contra implementación/pruebas actuales |
| Regenerar derivados | Pendiente | DOCX y otros formatos oficiales sin divergencia respecto de Markdown |
| Verificar cifras y referencias | Pendiente | Pruebas automatizadas y revisión manual de unidades, símbolos, tablas y afirmaciones normativas |

**Salida de fase:** E01–E04 actualizados, legibles y trazables.

**Puerta de calidad:** `revisor-fase`, actualización del plan, skill `saver`,
pruebas focalizadas de E01–E04, commit y push.

### Fase 5: Actualización de entregables 05 a 08

| Item | Estado | Notas |
|---|---|---|
| Actualizar E05 | Pendiente | Sustituir la descripción puramente prototípica por un recorrido visual actual y conservar el prototipo como antecedente identificado |
| Reescribir E06 | Pendiente | Manual ciudadano completo: preparar archivos, cargar, calcular, interpretar, exportar, generar informes y resolver errores |
| Completar E07 | Pendiente | Crear documento principal para dashboards con lectura de cada tabla/gráfico y advertencias de interpretación |
| Actualizar E08 | Pendiente | Manual operativo/técnico de versión vigente; instalación, dependencias, despliegue, mantenimiento, seguridad y recuperación |
| Integrar evidencia visual | Pendiente | Insertar solo capturas relevantes, con llamada textual que explique qué debe observar el lector |
| Regenerar derivados | Pendiente | DOCX/HTML oficiales coherentes con las fuentes y plantilla común |

**Salida de fase:** E05–E08 actualizados, con manual de usuario apto para una
persona sin formación en sistemas.

**Puerta de calidad:** `revisor-fase`, actualización del plan, skill `saver`,
pruebas funcionales y visuales de E05–E08, commit y push.

### Fase 6: Validación e informe final (E09)

| Item | Estado | Notas |
|---|---|---|
| Delimitar alcance de validación | Pendiente | Qué versión, componentes, datos, métodos y criterios se validan; qué queda fuera |
| Reejecutar evidencia reproducible | Pendiente | Pruebas vigentes, cálculos cruzados y generación de anexos desde un entorno registrado |
| Actualizar informe de validación | Pendiente | Resumen ciudadano, metodología, resultados, desviaciones, riesgos y conclusión sustentada |
| Actualizar anexo de cálculos | Pendiente | Entradas, pasos, fórmulas, precisión completa, redondeo de presentación y salida reproducible |
| Consolidar matriz de validación | Pendiente | Requisito/capacidad, caso, resultado esperado, resultado obtenido, evidencia, estado y responsable |
| Resolver referencias normativas | Pendiente | Verificar edición/año y sección; registrar acceso/control de las normas sin reproducir contenido protegido innecesariamente |
| Regenerar DOCX/PDF y anexos | Pendiente | Índices, figuras, tablas, metadatos y archivos CSV consistentes |

**Salida de fase:** E09 final con conclusión defendible y paquete de evidencia
reproducible.

**Puerta de calidad:** `revisor-fase`, actualización del plan, skill `saver`,
suite de validación acordada, commit y push.

### Fase 7: Auditoría cruzada y cierre del paquete

| Item | Estado | Notas |
|---|---|---|
| Auditar cobertura de los nueve entregables | Pendiente | Ningún requisito, documento oficial, anexo o captura queda sin estado explícito |
| Verificar consistencia transversal | Pendiente | Nombres, versiones, cifras, umbrales, unidades, rutas, enlaces, referencias, fechas y terminología |
| Revisar experiencia de lectura | Pendiente | Prueba con recorrido de persona no técnica: tarea, paso, resultado, interpretación y recuperación |
| Revisar archivos finales | Pendiente | DOCX/PDF abren correctamente; tablas e imágenes no se cortan; índices y numeración coinciden |
| Ejecutar controles automatizados | Pendiente | Tests del repositorio, tests de entregables, enlaces, inventario, hashes y ejecución Playwright desde limpio |
| Preparar manifiesto de entrega | Pendiente | Índice, checksums, versión, instrucciones de apertura/reproducción y lista explícita de pendientes/aprobaciones |
| Cerrar bitácora y plan | Pendiente | Registrar revisiones, resultados, commits, ubicación final y estado `Completado` solo si no quedan obligaciones abiertas |

**Salida de fase:** paquete `Entregables_pt_app/` listo para revisión contractual,
con manifiesto, trazabilidad, formatos finales y evidencia reproducible.

**Puerta de calidad:** revisión final por `revisor-fase`, incorporación de
hallazgos, skill `saver`, ejecución completa de controles, commit y push.

## Controles de aceptación

El paquete se considerará listo únicamente cuando:

1. Los nueve entregables tengan documento oficial vigente, versión y estado.
2. No se presente como actual una copia histórica del aplicativo.
3. Todas las pantallas y funciones descritas existan y hayan sido verificadas.
4. El manual permita completar el flujo principal sin conocer R ni la
   arquitectura interna.
5. Toda captura se pueda regenerar con Playwright y tenga trazabilidad.
6. Las fórmulas, unidades, umbrales y ejemplos coincidan con el código y pruebas
   vigentes.
7. Cada afirmación de validación diferencie resultado ejecutado, cobertura
   diseñada, evidencia histórica y revisión externa pendiente.
8. DOCX/PDF coincidan sustancialmente con su fuente y superen revisión visual.
9. No haya enlaces rotos, rutas locales ambiguas, datos sensibles, marcadores de
   posición ni contradicciones entre documentos.
10. El manifiesto final contenga inventario, hashes, commit, fecha, instrucciones
    de reproducción, riesgos residuales y aprobaciones pendientes.
11. Cada fase tenga revisión `revisor-fase`, persistencia con `saver`, registro
    en este plan, commit y push, como exige `AGENTS.md`.

## Riesgos y decisiones pendientes

| Riesgo/decisión | Tratamiento previsto |
|---|---|
| No se ha identificado todavía el contrato/TDR fuente | Buscarlo en Fase 1; si no está, no inferir obligaciones y registrar solicitud formal al responsable |
| Hay archivos históricos mezclados con fuentes actuales | Etiquetar versión y carácter histórico; definir una única fuente oficial por documento |
| Existen documentos recientes fuera de `Entregables_pt_app/` | Usarlos como insumo sujeto a verificación, no como autoridad automática |
| El árbol Git ya contiene un borrado y un archivo no rastreado relacionados con un plan HTML | Preservar esos cambios; no sobrescribirlos ni incorporarlos sin confirmar autoría/alcance |
| Capturas existentes pueden quedar desactualizadas | Regenerarlas desde el mismo commit del cierre y registrar hashes |
| La interfaz depende de tiempos reactivos | Esperar estados/elementos semánticos en Playwright, no pausas arbitrarias como criterio principal |
| Validación normativa puede exceder la evidencia disponible | Redactar conclusiones limitadas y mantener pendientes explícitos |
| Los DOCX pueden divergir de Markdown | Generarlos mediante una cadena documentada y comparar contenido/metadatos antes de entregar |
| Documentos extensos pueden ser poco útiles para público general | Incorporar rutas rápidas, pasos numerados, ejemplos, “qué significa” y “qué hacer si…”; mover detalle a anexos |

## Log de Ejecución

- [260712 16:39] Inicio de planificación e inventario preliminar.
- [260712 16:39] Identificados nueve entregables contractuales y fuentes
  documentales complementarias en `testb/`, `dgpsea03/`, `docs/` y
  `VALIDACION DEFINITIVA/`.
- [260712 16:39] Identificado flujo Playwright existente con 17 capturas como
  base a verificar y ampliar; no se consideran aún evidencia final vigente.
- [260712 16:39] Detectada necesidad de separar manual ciudadano, operación
  técnica y evidencia de auditoría.
- [260712 16:39] Plan creado; no se ha iniciado ninguna fase de ejecución ni se
  han realizado commits/push.
