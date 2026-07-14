# Rundown: implementación integral de entregables PT

**Date**: 2026-07-14
**Plan**: `260712_1639_plan_actualizacion-documentacion-entregables-aplicativo-pt.md`
**Plan status**: Pausado; ocho fases implementadas y cerradas técnicamente

## Current State

- Fase 1 cerró la línea base: versión congelada, inventario auditable, mapa
  funcional de ocho pestañas, matriz de brechas E01–E09 y fuentes autorizadas.
- Fase 2 estableció control documental: plantilla, índice maestro, glosario,
  IDs de evidencia, separación por audiencia y cadena Markdown–DOCX–PDF.
- Fase 3 produjo evidencia visual reproducible: Playwright cubre CAP-01 a
  CAP-19 con 21 imágenes, datos no sensibles, índices CSV/Markdown y hashes.
- Fase 4 actualizó E01–E04: repositorio, funciones, cálculos PT y puntajes;
  incluye cinco DOCX, ejemplos reproducibles y manifiestos verificables.
- Fase 5 actualizó E05–E08: interfaz, manual ciudadano, dashboards y manual de
  operación/desarrollo; incluye cuatro DOCX y un HTML controlado.
- Fase 6 completó E09: informe y anexo de validación, matriz de 12 casos,
  derivados DOCX/PDF/CSV y conclusión limitada a 11 PASS y 1 OPEN_RISK.
- Fase 7 auditó el paquete completo: E01–E09 trazables, manifiesto final de
  148 archivos, 283 expectativas focales aprobadas y revisión visual cerrada.
- Fase 8 estabilizó la reproducción: `ptcalc` 0.1.1 en `eb562c6`, `renv.lock`
  con 192 paquetes, DataTables corregido y suite raíz sin fallos ni warnings,
  con 11 SKIP explícitos para pruebas históricas sustituidas.
- Todas las fases pasaron revisión `revisor-fase`, persistencia documental,
  pruebas pertinentes, commit selectivo y publicación en `origin/main`.

## Delivered Outcome

- Los nueve entregables contractuales cuentan con fuente vigente, derivados o
  evidencia, control de versión y trazabilidad desde el aplicativo actual.
- La documentación separa recorridos para público general, operación/soporte y
  validación/auditoría, sin presentar copias históricas como implementación.
- Las capturas, cálculos, manifiestos y documentos derivados tienen mecanismos
  reproducibles y controles automatizados dentro del repositorio.
- El cierre técnico de la Fase 8 está publicado mediante `8801e4a`; el cierre
  documental posterior llega hasta `7117285` en `main`.

## Critical Technical Context

- El plan permanece `Pausado`, no por trabajo técnico pendiente, sino por la
  ausencia de contrato/TDR/acta primaria, aprobaciones externas pendientes y
  un riesgo funcional de homogeneidad ya documentado.
- Por decisión expresa del usuario, la Fase 8 no modificó implementación,
  pruebas ni documentación funcional de homogeneidad.
- `ptcalc/` es un repositorio anidado ignorado por la raíz; la reproducción se
  fija en `renv.lock` al commit publicado `eb562c6`.
- Las once pruebas antiguas dependientes de `final_docs/` son `SKIP`
  deliberados y fueron sustituidas por controles vigentes de E01–E09.
- Deben preservarse fuera de futuros commits el movimiento HTML y los
  directorios `_problems/` preexistentes que continúan en el árbol de trabajo.

## Pending Decisions

1. Obtener y revisar contrato, TDR o acta primaria antes de declarar cobertura
   contractual completa.
2. Gestionar las aprobaciones externas del paquete y del informe final E09.
3. Decidir separadamente si se corrige el riesgo funcional de homogeneidad.
4. Confirmar el destino del movimiento HTML y depurar los artefactos
   `_problems/` solo con autorización expresa.

## Branch Status

- Branch: `main`
- HEAD: `7117285` (`docs: refrescar memoria fase 8`)
- Remote: sincronizada con `origin/main`
- Status: dirty, sin conflictos conocidos
- Pending changes: borrado de `plan_documentos_formales_entregables_pt.html`;
  copia no rastreada bajo `Entregables_pt_app/`; `_problems/` no rastreados en
  E09 y pruebas raíz; hallazgo preexistente `260714_1020_findings.md`.
