# Reporte de controles de Fase 7

**Fecha de ejecución:** 2026-07-14  
**Estado:** cierre focal aprobado; suite histórica con deuda explícita

## Controles focales finales

Se ejecutaron, desde la raíz del repositorio, las pruebas de línea base,
control documental, evidencia visual, Fases 4–7 y reproducibilidad E09. Después
de cualquier prueba que regenera derivados se ejecutó el generador de Fase 7.

```bash
Rscript scripts/documentacion/generar_inventario_entregables.R
Rscript -e 'testthat::test_file(...)'
bash scripts/documentacion/generar_entregables_fase_7.sh
git diff --check
```

Resultado consolidado: **283 PASS, 0 FAIL, 0 WARN**. El último generador de
Fase 7 produjo un inventario de 147 archivos, un manifiesto de 148 archivos y
20 expectativas de cierre aprobadas. `sha256sum --check` terminó correctamente.

## Evidencia visual y formatos

```bash
bash scripts/documentacion/ejecutar_capturas.sh
pdfinfo Entregables_pt_app/09_informe_final/informe_validacion.pdf
```

Playwright completó 19 escenarios y 21 capturas. La revisión de contacto no
mostró acciones críticas cortadas. E09 abrió como PDF Carta de cinco páginas;
los DOCX superaron `unzip -tq` y el PDF superó `pdfinfo`/`pdftotext`.

## Corrida histórica previa

La orden `testthat::test_dir("tests/testthat")` produjo **313 PASS, 29 FAIL y
11 WARN**. Veintidós fallos y las advertencias pertenecen a pruebas antiguas que
esperan `final_docs/` y `tools/inventory_docs.R`, recursos ausentes en el árbol
actual. Los demás fallos fueron inconsistencias temporales de inventario/hash
causadas por pruebas que reescriben derivados después de calcular checksums.

La suite histórica completa no se volvió a ejecutar después de regenerar los
hashes. En su lugar se reejecutó la suite focal de 283 expectativas, que incluye
las pruebas vigentes del paquete y terminó sin fallos. Por tanto, este reporte
no presenta la suite histórica como saneada y conserva `final_docs/` como deuda
heredada fuera del paquete contractual.

## Diagnósticos aceptados y riesgos

- `favicon.ico` devuelve 404 sin afectar contenido ni operación.
- `DataTables.adjustWidth` puede fallar al redimensionar una tabla oculta; no
  alteró datos ni capturas, pero sigue como deuda técnica.
- El criterio expandido de homogeneidad continúa como riesgo funcional abierto.
- Aprobaciones contractual y normativa continúan pendientes.
