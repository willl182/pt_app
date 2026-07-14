# Entregable 01 — Repositorio inicial recibido

| Campo | Valor |
|---|---|
| Código | E01 |
| Versión documental | 2.0 |
| Fecha de actualización | 2026-07-14 |
| Estado | Vigente como registro histórico; no es el código operativo actual |
| Fuente funcional vigente | `app.R`, `R/` y `ptcalc/R/` en la raíz del repositorio |
| Aprobación externa | Pendiente |

## Para qué sirve este entregable

Este directorio conserva el código recibido al inicio del desarrollo. Permite
reconstruir el punto de partida y comparar la evolución del aplicativo. No debe
usarse para iniciar ni mantener la versión actual: la aplicación vigente se
ejecuta desde el `app.R` ubicado en la raíz del repositorio.

## Qué contiene

| Archivo | Función | Vigencia |
|---|---|---|
| `app_original.R` | Copia de la aplicación en el corte inicial | Histórico |
| `R/pt_homogeneity.R` | Cálculos iniciales de homogeneidad | Histórico |
| `R/pt_robust_stats.R` | Estadísticos robustos iniciales | Histórico |
| `R/pt_scores.R` | Puntajes PT iniciales | Histórico |
| `R/utils.R` | Utilidades iniciales, luego reemplazadas | Obsoleto/histórico |
| `tests/test_01_existencia_archivos.R` | Comprobación diseñada para el snapshot inicial | Evidencia histórica |
| `test_01_resultados.csv` | Resultado conservado de esa comprobación | Evidencia histórica |

Los archivos DOCX son derivados de sus fuentes Markdown. El inventario maestro
vigente de todo el paquete, con tamaño, estado Git y SHA-256, se encuentra en
`../00_linea_base/inventario_maestro.csv` y se regenera mediante
`scripts/documentacion/generar_inventario_entregables.R` desde la raíz.

## Cómo comprobar el paquete actual

Desde la raíz del repositorio:

```r
Rscript scripts/documentacion/generar_inventario_entregables.R
Rscript -e 'testthat::test_file("tests/testthat/test-linea-base-entregables.R")'
```

Esta es la comprobación recomendada. El test incluido dentro de E01 se conserva
para auditoría del corte inicial y puede dejar de coincidir con el código
vigente precisamente porque el aplicativo evolucionó.

## Cómo identificar qué versión usar

1. Para operar el aplicativo, use el `app.R` de la raíz.
2. Para cálculos reutilizables, use `ptcalc/R/` mediante
   `devtools::load_all("ptcalc")`.
3. Para revisar el origen del proyecto, consulte este directorio.
4. No trate `app_original.R`, `app_v06.R`, `app_v07.R` ni `app_final.R` como
   fuentes vigentes sin contrastarlas con el commit documentado.

## Evidencia visual vigente

![CAP-01. Inicio del aplicativo y zonas de carga.](../00_evidencia_visual/capturas/CAP-01_inicio_carga.png)

**Figura CAP-01.** Interfaz vigente, no la interfaz del snapshot. Su fecha,
commit, datos de demostración y SHA-256 están en
`../00_evidencia_visual/indice_capturas.csv`.

## Trazabilidad y límites

- Línea base funcional: `../00_linea_base/linea_base_version.md`.
- Fuentes autorizadas: `../00_linea_base/fuentes_y_requisitos.md`.
- Inventario completo: `../00_linea_base/inventario_maestro.csv`.
- No se encontró contrato, TDR o acta primaria en el workspace; por ello este
  documento describe el contenido verificable, pero no certifica por sí solo
  la aceptación contractual.

## Historial de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| 1.0 | 2026-01-24 | Registro del snapshot inicial |
| 2.0 | 2026-07-14 | Separación explícita entre histórico y vigente; enlace al inventario auditable |
