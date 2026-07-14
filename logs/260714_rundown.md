# Rundown: PT App

**Date**: 2026-07-14

## Current State

- Fase 8 técnica implementada y revisada; pendiente únicamente el push raíz.
- `ptcalc` 0.1.1 publicado en `eb562c6` con 51 PASS y check 0/0/0.
- `renv.lock` fija `ptcalc` en `eb562c6`; restauración aislada aprobada.
- Suite raíz completa aprobada con 11 SKIP explícitos y sin fallos.
- DataTables validado a 1024x768 sin `adjustWidth` ni `ReferenceError`.

## Critical Technical Context

- No se introdujeron cambios nuevos en homogeneidad por decisión del usuario.
- `ptcalc/` está ignorado en raíz; el pin reproducible está en `renv.lock`.
- Preservar fuera del commit el movimiento HTML, `_problems/` y el hallazgo
  preexistente de las 10:20.
- El plan global sigue `Pausado` por pendientes externos y el riesgo de
  homogeneidad preservado.

## Next Steps

1. Publicar commit selectivo de Fase 8 en `main`.
2. Registrar el hash final en plan y rundown.

## Branch Status

- Branch: `main`
- Status: sincronizada con `origin/main` antes del commit de Fase 8; árbol
  sucio por implementación actual y cambios preexistentes preservados.
- Pending changes: DataTables, lockfile, pruebas, evidencia regenerada, plan y
  memoria; fuera de alcance: movimiento HTML, `_problems/` y hallazgo 10:20.
