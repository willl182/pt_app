# Línea base e inventario auditable

**Fecha de corte:** 2026-07-14

**Rama:** `main`

**Commit base:** `6e7dbcb769c1a8e40d65c749ce8f99eadfca8a02`

**Estado:** Fase inicial completada; revisión editorial posterior pendiente

## Propósito

Esta carpeta conserva la evidencia de partida para actualizar los nueve
entregables. No reemplaza los documentos contractuales: identifica qué existe,
qué hace actualmente el aplicativo y qué debe corregirse en las fases
siguientes.

La solicitud llamó a este trabajo “Fase 0”. El plan vigente comienza su
numeración en “Fase 1: Línea base e inventario auditable”; ambos nombres se
refieren aquí a la misma fase inicial.

## Contenido

- `linea_base_version.md`: versión, entorno y estado conocido del árbol.
- `inventario_maestro.csv`: inventario reproducible con tamaño, rol, estado
  documental, SHA-256 y estado Git de cada archivo en `Entregables_pt_app/`.
- `mapa_funcional.md`: recorrido funcional comprobado desde el código vigente.
- `matriz_brechas.md`: estado y acciones requeridas para E01–E09.
- `fuentes_y_requisitos.md`: jerarquía de fuentes autorizadas y limitación
  contractual encontrada.

## Regeneración

Desde la raíz del repositorio:

```bash
Rscript scripts/documentacion/generar_inventario_entregables.R
```

El inventario excluye su propio CSV para evitar un hash autorreferencial. Cada
regeneración debe acompañarse con la fecha y el commit que la motivan.
`estado_git` representa el corte en que se ejecutó el inventario y puede cambiar
después del commit de cierre; el commit registrado conserva la referencia.
