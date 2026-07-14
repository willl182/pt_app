# Rundown: PT App

**Date**: 2026-07-14

## Current State

- Fases 1 a 4 completadas.
- E01-E04 tienen fuentes vigentes, cinco DOCX derivados, catálogo regenerado,
  ejemplos reproducibles, manifiesto SHA-256 e inventario de 133 archivos.
- Puerta `revisor-fase` aprobada tras tres revisiones.
- Controles finales: 29 + 35 + 14 + 24 expectativas, sin fallos.

## Critical Technical Context

- Ejecutar `scripts/documentacion/generar_entregables_fase_4.sh`; regenerar el
  inventario al final para mantener hashes coherentes.
- `ptcalc/` es repo anidado dirty en `e87180b`; el commit raíz no basta para
  reproducirlo. Estado registrado en `00_linea_base/estado_ptcalc_fase4.md`.
- Defecto residual: criterio expandido de homogeneidad con llamada posicional y
  comparación dimensional incompatible.
- Mantener fuera los dos cambios HTML y el hallazgo de las 10:20.

## Next Steps

1. Iniciar Fase 5 (E05-E08).
2. Fijar/publicar `ptcalc` y planificar la corrección del criterio expandido.

## Branch Status

- Branch: `main`
- Status: Fase 4 lista para commit y push selectivos.
- Pending changes: implementación Fase 4; movimiento HTML y hallazgo 10:20
  preexistentes excluidos.
