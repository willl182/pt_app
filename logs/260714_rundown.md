# Rundown: PT App

**Date**: 2026-07-14

## Current State

- Fase 1 de línea base e inventario auditable completada.
- Inventario maestro: 88 archivos, SHA-256 y clasificaciones verificadas.
- Mapa funcional y matriz de brechas E01-E09 disponibles.
- Prueba focal: 24 expectativas, 0 fallos y 0 advertencias.
- Fase 2 de estructura editorial y control documental completada.
- Plantilla, índice E01–E09, glosario, IDs, audiencias y matriz de trazabilidad
  disponibles en `Entregables_pt_app/00_control_documental/`.
- Cadena Markdown–DOCX–PDF verificada con 35 expectativas; inventario de 102
  archivos verificado con otras 24 expectativas.

## Critical Technical Context

- Autoridad funcional: `app.R` y módulos vigentes realmente cargados/invocados.
- Cuatro copias de aplicaciones dentro de los entregables son históricas.
- No se encontró contrato/TDR/acta primaria; debe solicitarse al responsable.
- Los dos cambios HTML preexistentes siguen preservados y fuera del alcance de
  la fase.
- Markdown es la fuente controlada; pandoc genera DOCX y LibreOffice genera PDF
  con perfil temporal. El manifiesto conserva hashes de fuente y salidas.
- La revisión `revisor-fase` cerró sin bloqueantes y sus cuatro hallazgos fueron
  incorporados.

## Next Steps

1. Iniciar Fase 3 con datos de demostración no sensibles.
2. Revisar y robustecer selectores Playwright contra la interfaz vigente.
3. Generar CAP-01 a CAP-19, hashes e índice de capturas.

## Branch Status

- Branch: `main`
- Status: Fase 2 publicada en `0f60396`; `main` sincronizada con `origin/main`
- Pending changes: dos cambios HTML y un hallazgo de las 10:20 preexistentes,
  preservados fuera de los commits de fase
