# Matriz de brechas por entregable

## Criterios

- **Vigente:** coincide con la implementación comprobada.
- **Parcial:** conserva contenido útil, pero requiere actualización.
- **Histórico:** evidencia una etapa anterior; no describe la app vigente.
- **No verificable:** la afirmación carece de fuente reproducible localizada.
- **Ausente:** falta un documento principal requerido por el plan.

## Resultado de la línea base

| ID | Estado dominante | Brechas principales | Fuente a conservar | Acción de la fase específica |
|---|---|---|---|---|
| E01 | Histórico/parcial | README describe el repositorio inicial, no el paquete vigente; enlaces absolutos y copia `app_original.R` | Inventario y pruebas de existencia | Explicar línea base histórica, añadir inventario vigente y separar fuente de derivado |
| E02 | Parcial | Catálogo/CSV no demuestra exhaustividad ni uso real desde `app.R` | Documentación de funciones y extractor | Regenerar desde `app.R`, `R/`, `ptcalc/R`; registrar firma, exportación, uso y prueba |
| E03 | Parcial/histórico | Scripts autónomos pueden divergir de `ptcalc`; ejemplo no está congelado contra salida actual | Ejemplo y pruebas numéricas | Rehacer ejemplo reproducible con fórmulas, datos, unidades y redondeo vigentes |
| E04 | Parcial | Fórmulas útiles, pero deben verificarse incertidumbres, NA, umbrales y etiquetas contra código actual | Markdown de fórmulas | Añadir z, z', zeta y En completos con pruebas cruzadas actuales |
| E05 | Histórico | Wireframes/prototipo no representan toda la navegación actual | Prototipo como antecedente | Crear recorrido visual actual, mapa de navegación y comparación explícita |
| E06 | Histórico/no vigente | Manual está ligado a `app_v06.R`; no cubre preprocesador ni flujo actual completo | Casos de uso rescatables | Reescribir manual ciudadano desde preparación hasta exportación y errores |
| E07 | Ausente/histórico | No existe documento narrativo principal; solo app v07, Mermaid y pruebas | Diagrama como antecedente | Crear guía de lectura de cada tabla, gráfico, filtro, color y advertencia |
| E08 | Histórico/parcial | Manual técnico y `app_final.R` no congelan dependencias ni operación vigente | Secciones técnicas rescatables | Actualizar arquitectura, instalación, despliegue, mantenimiento, seguridad y E2E |
| E09 | No verificable/parcial | Afirma comparaciones Excel/VIVO sin localizar toda la evidencia externa; derivados pueden divergir | Informe, anexo y CSV existentes | Reejecutar validación, delimitar alcance y mantener pendientes explícitos |

## Brechas transversales

| Hallazgo | Impacto | Tratamiento |
|---|---|---|
| No hay plantilla común ni índice contractual maestro | Versiones y audiencias inconsistentes | Resolver en Fase 2 |
| Hay enlaces `file:///` con rutas locales en documentos de resumen | Paquete no autocontenido | Sustituir por rutas relativas al actualizar cada E |
| Markdown, DOCX y PDF carecen de una cadena única demostrada | Riesgo de divergencia | Definir generación y comprobación de derivados |
| Capturas existentes no están congeladas al commit actual | Evidencia visual no vigente | Regenerar CAP-01 a CAP-19 con índice y hashes |
| Requisitos contractuales primarios no fueron localizados | Cobertura contractual no demostrable | Solicitar contrato/TDR/actas; no inferir obligaciones |
| Terminología normativa presenta año discordante | Riesgo de afirmación incorrecta | Verificar fuente autorizada antes de normalizar |

## Prioridad

1. Bloqueantes de trazabilidad: requisitos contractuales y evidencia externa de
   E09.
2. Documentos ausentes/no vigentes: E07, E06 y E05.
3. Exactitud matemática: E02, E03 y E04.
4. Operación y cierre: E01, E08 y consolidación E09.
