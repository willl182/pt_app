# Rundown: PT App

**Date**: 2026-07-14

## Current State

- Fases 1 a 5 completadas.
- E05-E08 tienen fuentes vigentes, cuatro DOCX, un HTML y manifiesto SHA-256.
- Puerta `revisor-fase` aprobada tras incorporar cuatro hallazgos.
- Controles finales: 19 + 29 + 35 + 24 expectativas, sin fallos.
- Implementación de Fase 5: commit `018d39f`; inventario de 136 archivos.

## Critical Technical Context

- Ejecutar `scripts/documentacion/generar_entregables_fase_5.sh`; regenerar el
  inventario al final para mantener hashes coherentes.
- `ptcalc/` es repo anidado dirty en `e87180b`; el commit raíz no basta para
  reproducirlo. Estado registrado en `00_linea_base/estado_ptcalc_fase4.md`.
- Defecto residual: criterio expandido de homogeneidad con llamada posicional y
  comparación dimensional incompatible.
- Mantener fuera los dos cambios HTML y el hallazgo de las 10:20.

## Next Steps

1. Iniciar Fase 6 (E09).
2. Fijar/publicar `ptcalc` y planificar la corrección del criterio expandido.

## Branch Status

- Branch: `main`
- Status: Fase 5 implementada en `018d39f`; cierre documental pendiente de push.
- Pending changes: movimiento HTML y hallazgo 10:20 preexistentes excluidos.
