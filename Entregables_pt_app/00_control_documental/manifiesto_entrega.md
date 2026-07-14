# Manifiesto de entrega del paquete documental PT

**Versión:** 1.0  
**Fecha:** 2026-07-14  
**Estado:** Listo para revisión; aprobación contractual pendiente  
**Raíz del paquete:** `Entregables_pt_app/`

**Commit de implementación E09:** `ad16214`  
**Commit de implementación Fase 7:** `d488e26`  
**Estado evaluado:** commit publicado de Fase 6 más los cambios documentales de
Fase 7 que se publican con este cierre  
**Repositorio `ptcalc`:** `e87180bc3831324bd343ee52202f1d9754b7fcef`,
con cambios locales fijados por hashes y parche en E09

## Cómo abrir el paquete

Empiece por `indice_maestro.md` en esta carpeta. Los archivos Markdown son las
fuentes oficiales; los DOCX/PDF son copias de lectura generadas. Para operar el
aplicativo consulte `../06_app_logica/manual_usuario.docx`; para revisar la
validación consulte `../09_informe_final/informe_validacion.pdf`.

## Contenido

- E01: inventario y contexto del repositorio recibido.
- E02: capacidades y funciones utilizadas.
- E03: ejemplo de cálculos PT paso a paso.
- E04: fórmulas e interpretación de puntajes.
- E05: recorrido visual de la interfaz.
- E06: manual ciudadano de uso.
- E07: lectura de tablas, gráficos y tableros.
- E08: instalación, operación y mantenimiento técnico.
- E09: informe final, matriz de validación y anexos reproducibles.

La auditoría transversal está en `auditoria_cierre.md`. El detalle por archivo
se encuentra en `manifiesto_entrega.csv`; los mismos hashes están en formato
compatible con `sha256sum` en `checksums_entrega.sha256`.

## Verificación rápida

Desde la raíz del repositorio:

```bash
sha256sum --check Entregables_pt_app/00_control_documental/checksums_entrega.sha256
Rscript -e 'testthat::test_file("tests/testthat/test-entregables-fase-7.R")'
```

Para regenerar inventario, manifiesto y ejecutar los controles de cierre:

```bash
bash scripts/documentacion/generar_entregables_fase_7.sh
```

Los dos archivos de checksums se excluyen de su propia enumeración para evitar
una dependencia circular. Los directorios `_problems/` producidos por reportes
de pruebas fallidas tampoco forman parte de la entrega. El archivo local
`plan_documentos_formales_entregables_pt.html` se excluye porque corresponde a
un movimiento preexistente no publicado y no es fuente oficial del paquete.

## Pendientes que requieren decisión externa

La entrega queda preparada para revisión, no aprobada. Faltan el documento
contractual primario, la aprobación formal y una revisión normativa
independiente. Además, E09 registra un riesgo técnico abierto en el criterio
expandido de homogeneidad y la necesidad de fijar/publicar el estado de
`ptcalc` usado para la validación.
