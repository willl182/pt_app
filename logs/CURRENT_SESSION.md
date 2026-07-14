# Session State: PT App - Actualización documental de entregables

**Last Updated**: 2026-07-14 12:18

## Session Objective

Completar la Fase 3 de evidencia visual reproducible con Playwright.

## Current State

- [x] Fases 1 y 2 completadas y publicadas.
- [x] Fase 3 completada: 19 escenarios CAP representados por 21 imágenes.
- [x] Datos demo no sensibles con incertidumbres para z, z', zeta y En.
- [x] CAP-16 muestra resultados de participante y CAP-19 descarga habilitada a
  1024x768 después de cargar datos válidos.
- [x] Índices CSV/Markdown, hashes y registro JSON regenerados desde el commit
  de implementación `068ba8e`.
- [x] Evidencia enlazada desde fuentes E01-E09.
- [x] Dos revisiones `revisor-fase`; la segunda cerró sin bloqueantes.
- [x] Prueba focal previa al cierre: 95 expectativas correctas.

## Critical Technical Context

- Reproducción: `npm ci` y
  `scripts/documentacion/ejecutar_capturas.sh` desde la raíz.
- Playwright 1.61.1 usa Chromium del sistema y datos en
  `Entregables_pt_app/00_evidencia_visual/datos_demo/`.
- El registro acepta explícitamente el 404 de favicon y el `adjustWidth` de
  DataTables al redimensionar una tabla oculta; este último es deuda técnica.
- Preservar fuera de commits el movimiento HTML y el hallazgo de las 10:20,
  preexistentes a la fase.
- Autoridad funcional: `app.R` y módulos vigentes; las copias v06/v07/final son
  históricas.

## Next Steps

1. Iniciar Fase 4 y actualizar E01-E04 contra código/pruebas vigentes.
2. Corregir en mantenimiento el error no visible `adjustWidth` de DataTables.
3. Mantener CAP-01 a CAP-19 estables o regenerarlos si cambia la interfaz.
