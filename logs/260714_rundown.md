# Rundown: PT App

**Date**: 2026-07-14

## Current State

- Fases 1–7 implementadas; el plan permanece `Pausado` por obligaciones externas.
- Fase 6 publicada en `ad16214`; Fase 7 publicada en `d488e26`.
- Auditoría E01–E09, manifiesto y checksums finales disponibles.
- Controles focales: 283 PASS, 0 FAIL, 0 WARN.
- Playwright: 19 escenarios, 21 capturas; revisión visual aprobada.

## Critical Technical Context

- No declarar aprobación contractual ni certificación normativa.
- Riesgo abierto: criterio expandido de homogeneidad.
- `ptcalc` anidado: `e87180b`, dirty; hashes y parche preservados en E09.
- Suite histórica previa: 313 PASS, 29 FAIL, 11 WARN por `final_docs/` ausente y
  orden de hashes; no se presenta como saneada.
- Preservar fuera del commit el movimiento HTML y el hallazgo de las 10:20.

## Next Steps

1. Obtener contrato/TDR/acta, revisión normativa y aprobación formal.
2. Corregir el riesgo funcional y publicar/fijar `ptcalc`.

## Branch Status

- Branch: `main`
- Status: sincronizada con `origin/main` en `d488e26`; quedan cambios
  preexistentes preservados y el registro final de hashes/commit.
- Pending changes: movimiento HTML, artefactos `_problems/` y hallazgo 10:20
  excluidos; metadatos finales se publican en el commit de registro.
