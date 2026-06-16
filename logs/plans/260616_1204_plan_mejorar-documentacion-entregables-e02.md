# Plan: Mejorar documentación del Entregable 02 (funciones usadas)

**Timestamp:** 260616_1204
**Slug:** mejorar-documentacion-entregables-e02
**Estado:** En progreso

## Objetivo

Transformar la documentación del Entregable 02 (`Entregables_pt_app/02_funciones_usadas`) de un catálogo escueto y automatizable en una referencia técnica rica, trazable y útil para desarrolladores y auditores metrológicos. El foco principal es `md/documentacion_funciones.md`, que actualmente carece de descripciones, fórmulas, ejemplos y contexto ISO.

## Fases

### Fase 1: Diseñar nuevo extractor de documentación
| Item | Estado | Notas |
|------|--------|-------|
| Revisar parser actual `R/lista_funciones.R` | Completado | Extrae solo nombre, parámetros y referencia ISO básica. |
| Diseñar parser de roxygen2 completo | En progreso | Título, descripción, @param, @return, @examples, @references, @seealso, @export, lifecycle. |
| Definir esquema de anotaciones manuales para funciones sin roxygen2 (app.R, report_template.Rmd) | Pendiente | La mayoría de funciones de app.R no están documentadas. |
| Decidir formato Markdown de salida | Pendiente | Incluir: descripción, fórmula, parámetros con tipos, valor de retorno, ejemplos, referencias ISO, archivo fuente. |

### Fase 2: Implementar extractor mejorado
| Item | Estado | Notas |
|------|--------|-------|
| Reescribir `R/lista_funciones.R` | Pendiente | Extraer roxygen2 de ptcalc/R y R/*.R. |
| Crear archivo de anotaciones manuales (YAML/CSV) para funciones de app.R y report_template.Rmd | Pendiente | Basado en lectura directa del código. |
| Generar `funciones_extraidas.csv` ampliado | Pendiente | Nuevas columnas: descripcion, parametros, retorno, ejemplos, referencia_iso, exportada, lifecycle. |
| Generar `md/documentacion_funciones.md` enriquecido | Pendiente | Usar nuevo extractor + anotaciones manuales. |

### Fase 3: Actualizar README y overview de E02
| Item | Estado | Notas |
|------|--------|-------|
| Actualizar `02_funciones_usadas/README.md` | Pendiente | Reflejar nuevo formato, total real de funciones, categorías. |
| Actualizar `Entregables_pt_app/e2.md` | Pendiente | Estado: regenerado y enriquecido. |
| Actualizar `bitacora_actualizacion_260616.md` | Pendiente | Registrar acciones aplicadas y DOCX exportados. |

### Fase 4: Regenerar artefactos DOCX
| Item | Estado | Notas |
|------|--------|-------|
| Exportar `documentacion_funciones.md` a DOCX | Pendiente | Usar pandoc. |
| Exportar `README.md` a DOCX | Pendiente | Usar pandoc. |
| Verificar que DOCX se generen sin errores | Pendiente | Revisar salida de pandoc. |

### Fase 5: Revisión y persistencia
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar subagente revisor-fase (o revisión manual cruzada) | Pendiente | Verificar coherencia, errores de formato, nombres de funciones. |
| Guardar estado con skill `saver` | Pendiente | Crear CURRENT_SESSION.md e histórico. |
| Actualizar plan con hallazgos | Pendiente | Reflejar estado final. |

## Log de Ejecución

- [260616 12:04] Inicio del plan; exploración de archivos y lectura de documentación actual.
