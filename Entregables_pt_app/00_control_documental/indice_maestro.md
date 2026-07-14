# Índice maestro de entregables

**Versión del índice:** 1.1

**Fecha de corte:** 2026-07-14

**Commit funcional de referencia:** `068ba8e`

**Estado general:** E01–E04 actualizados; E05–E09 continúan en actualización

## Convención de estado

- **Fuente por actualizar:** Markdown oficial identificado, pero todavía no
  alineado por completo con el aplicativo vigente.
- **Pendiente de crear:** no existe aún una fuente principal adecuada.
- **Histórico:** se conserva como antecedente y no describe la versión vigente.
- **Derivado:** DOCX/PDF generado desde una fuente; nunca se edita directamente.
- **Vigente verificado:** fuente contrastada con el código y las pruebas
  indicadas, sin implicar aprobación contractual o normativa externa.

## Documentos oficiales y anexos

| ID | Entregable | Audiencia primaria | Fuente oficial controlada | Derivados actuales | Anexos/evidencia | Estado al corte |
|---|---|---|---|---|---|---|
| E01 | Repositorio inicial | Auditoría | `01_repo_inicial/README.md` | `01_repo_inicial/README.docx` | `00_linea_base/`, inventario y prueba de Fase 4 | Vigente verificado como registro histórico |
| E02 | Funciones usadas | Soporte técnico | `02_funciones_usadas/md/documentacion_funciones.md` | `02_funciones_usadas/documentacion_funciones.docx` | CSV regenerado y prueba de Fase 4 | Vigente verificado |
| E03 | Cálculos PT | Usuario y auditoría | `03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md` | `03_calculos_pt/ejemplo_calculo_paso_a_paso.docx` | Código `ptcalc` y prueba de Fase 4 | Vigente verificado |
| E04 | Puntajes | Usuario y auditoría | `04_puntajes/md/formulas_y_ejemplos.md` | `04_puntajes/formulas_y_ejemplos.docx` | Código `ptcalc` y prueba de Fase 4 | Vigente verificado |
| E05 | Interfaz | Usuario | `05_prototipo_ui/md/wireframes.md` | `05_prototipo_ui/wireframes.docx` | HTML, diagrama, pruebas y futuras CAP | Fuente histórica por actualizar |
| E06 | Lógica y manual | Usuario y operación | `06_app_logica/md/manual_usuario.md` | `06_app_logica/manual_usuario.docx` | Pruebas E06 y futuras CAP | Fuente histórica por actualizar |
| E07 | Dashboards | Usuario | `07_dashboards/md/documentacion_dashboards.md` | `07_dashboards/documentacion_dashboards.docx` | Diagrama, pruebas y futuras CAP | Pendiente de crear en Fase 5 |
| E08 | Beta/final | Soporte técnico | `08_beta/md/manual_desarrollador.md` | `08_beta/manual_desarrollador.docx` | Pruebas E2E; copia de app histórica | Fuente histórica por actualizar |
| E09 | Informe final | Validación y auditoría | `09_informe_final/md/informe_validacion.md` | `09_informe_final/informe_validacion.docx`, `.pdf` | Anexo, CSV y pruebas E09 | Fuente por auditar |

Todas las rutas son relativas a `Entregables_pt_app/`. Los overviews `e1.md` a
`e9.md` son ayudas históricas y no son la fuente oficial. Las copias
`app_original.R`, `app_v06.R`, `app_v07.R` y `app_final.R` tampoco son la
autoridad funcional; esa función corresponde al código vigente del repositorio.

## Relación con requisitos

En ausencia de una fuente contractual primaria, cada entregable se vincula al
requisito provisional del plan `REQ-E01` a `REQ-E09`. La matriz completa está
en `matriz_trazabilidad.csv`. Cuando se reciba el contrato/TDR/acta, el índice
deberá registrar su código, versión, sección y responsable de interpretación.
