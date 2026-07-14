---
title: "Ejemplo de documento controlado"
subtitle: "Prueba de la cadena editorial de la Fase 2"
author: "Equipo PT App"
date: "2026-07-14"
lang: es-CO
version: "1.0"
status: "En revisión"
audience: "Validación y auditoría"
deliverable: "Control documental común"
source_commit: "1f01b51"
toc: true
---

# Ficha de control documental

| Campo | Valor |
|---|---|
| Código | DOC-CTL-AUD-01 |
| Versión | 1.0 |
| Estado documental | En revisión |
| Fuente controlada | `plantillas/ejemplo_controlado.md` |
| Propósito | Probar la generación reproducible de formatos derivados |

# Objetivo

Confirmar que una única fuente Markdown puede producir archivos DOCX y PDF
legibles sin cambiar el contenido fuente.

# Resultado esperado

La ejecución genera ambos derivados, comprueba su integridad básica y registra
sus hashes en `derivados/manifiesto_generacion.csv`.

**Resultado de la última ejecución:** Ejecutada conforme.

# Limitación

Este ejemplo valida la cadena técnica mínima. La aprobación institucional del
diseño, responsables y firmas continúa pendiente.
