# Rundown: PT App

**Date**: 2026-07-14

## Current State

- Fases 1, 2 y 3 completadas.
- Fase 3 aporta 21 imágenes para CAP-01 a CAP-19, datos demo no sensibles,
  índice auditable y registro de ejecución.
- Implementación publicada en `068ba8e`; evidencia final regenerada desde ese
  commit y pendiente del commit documental de cierre.
- Segunda revisión `revisor-fase` sin bloqueantes; prueba focal 95/95.

## Critical Technical Context

- Ejecutar `npm ci` y `scripts/documentacion/ejecutar_capturas.sh`.
- CAP-13 y CAP-14 usan dos archivos cada uno para documentar z/z' y zeta/En.
- CAP-19 usa datos válidos a 1024x768 y muestra descarga habilitada.
- El `adjustWidth` de DataTables en tablas ocultas es deuda técnica aceptada y
  registrada; no afecta contenido ni cálculos visibles.
- No incorporar el movimiento HTML ni `logs/history/260714_1020_findings.md`:
  son cambios preexistentes.

## Next Steps

1. Iniciar Fase 4 para actualizar E01-E04.
2. Regenerar evidencia si se modifica la interfaz.

## Branch Status

- Branch: `main`
- Status: implementación `068ba8e` sincronizada con `origin/main`; cierre de
  Fase 3 pendiente de commit/push.
- Pending changes: evidencia regenerada, plan, inventario, pruebas y memoria de
  cierre; además tres cambios preexistentes excluidos.
