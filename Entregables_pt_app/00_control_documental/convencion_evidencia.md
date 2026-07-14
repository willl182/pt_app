# Convención de requisitos y evidencia

**Versión:** 1.0  
**Fecha:** 2026-07-14

## Identificadores

| Objeto | Patrón | Ejemplo | Uso |
|---|---|---|---|
| Requisito | `REQ-ENN-NNN` | `REQ-E06-001` | Obligación proveniente de una fuente identificada |
| Requisito provisional | `REQ-ENN` | `REQ-E06` | Alcance por entregable mientras falta la fuente contractual primaria |
| Documento | `DOC-ENN-TIPO-NN` | `DOC-E06-USR-01` | Fuente documental controlada |
| Captura | `CAP-NN` | `CAP-05` | Estado visual reproducible definido en el plan |
| Prueba | `PRU-ENN-NNN` | `PRU-E04-001` | Ejecución automatizada o verificación manual con criterio explícito |
| Tabla | `TAB-ENN-NNN` | `TAB-E03-002` | Tabla citada como evidencia |
| Hallazgo | `HAL-ENN-NNN` | `HAL-E09-001` | Desviación, riesgo o limitación observada |
| Anexo | `ANX-ENN-NNN` | `ANX-E09-003` | Archivo de soporte vinculado a un documento |
| Evidencia compuesta | `EVI-ENN-NNN` | `EVI-E09-001` | Agrupación trazable de una o más fuentes |

`ENN` representa E01 a E09. Los contadores tienen tres dígitos y no se
reutilizan aunque un registro sea retirado. Un ID retirado conserva estado y
motivo en la matriz.

Los documentos transversales de control, que no pertenecen a un entregable,
usan `DOC-CTL-TIPO-NN`, por ejemplo `DOC-CTL-AUD-01`. No deben utilizar este
prefijo documentos cuyo contenido corresponda a E01–E09.

## Metadatos mínimos

Cada evidencia debe registrar: ID, afirmación acotada, entregable, fuente
relativa, fecha de obtención, commit o versión, responsable, método/acción
previa, resultado esperado, resultado obtenido, estado y documento consumidor.
Una captura añade resolución y datos de demostración; una prueba añade comando,
entorno y conteo de éxitos/fallos.

## Estados permitidos

`Pendiente`, `En preparación`, `Ejecutada conforme`, `Ejecutada no conforme`,
`No aplica`, `Histórica` y `Retirada`. “Diseñada” no equivale a “ejecutada”, y
“ejecutada” no equivale por sí sola a conformidad normativa.

## Reglas de citación

- Use rutas relativas a `Entregables_pt_app/`; no use `file://` ni rutas de una
  máquina particular.
- Cite el ID junto a la afirmación que demuestra, no solo en un anexo final.
- Registre fecha y commit de la ejecución; no atribuya el commit actual a una
  evidencia histórica.
- Una misma evidencia puede apoyar varios documentos, pero cada relación debe
  aparecer en la matriz.
- Las referencias ISO deben indicar edición y sección verificadas. No copie
  contenido protegido más allá de lo autorizado.
