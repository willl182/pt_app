# Cadena controlada Markdown–DOCX–PDF

**Versión:** 1.0  
**Herramientas verificadas:** pandoc 3.10 y LibreOffice 26.2  
**Fecha de verificación:** 2026-07-14

## Regla de autoridad

Markdown es la fuente controlada. DOCX y PDF son derivados de distribución y
no se editan directamente. Toda regeneración registra fuente, hash, fecha,
commit, versión de herramientas y hash de salida en un manifiesto CSV.

## Ejecución

Desde la raíz del repositorio:

```bash
bash scripts/documentacion/generar_documentos_controlados.sh
```

El script genera la plantilla de ejemplo en DOCX y PDF dentro de
`00_control_documental/derivados/` y escribe `manifiesto_generacion.csv`. El
DOCX generado en la primera ejecución se conserva además como
`estilos/referencia.docx`; las siguientes ejecuciones lo usan para mantener
estilos. LibreOffice convierte ese DOCX a PDF; así se prueba la cadena completa
Markdown–DOCX–PDF incluso cuando la instalación local de TeX no dispone de los
formatos o paquetes de idioma requeridos.

## Aplicación a los entregables

Para cada documento de E01–E09, la fase correspondiente debe declarar en el
script o en su automatización equivalente: fuente Markdown, nombre estable de
salida y formatos requeridos. Si un formato no aplica, debe registrarse como
tal en el índice maestro; no se sustituye silenciosamente por un archivo
histórico.

## Controles

1. Validar metadatos y estructura de la fuente.
2. Ejecutar pruebas de enlaces e IDs.
3. Generar DOCX/PDF desde un árbol identificado.
4. Verificar que DOCX sea un ZIP íntegro y que PDF tenga cabecera válida.
5. Extraer texto de ambos derivados y comparar títulos/secciones esenciales.
6. Revisar visualmente tablas, saltos, pies, índices y figuras antes de aprobar.
7. Registrar hashes; los formatos pueden cambiar de hash entre versiones de
   herramientas aunque el contenido sea equivalente.

La prueba automatizada acredita integridad estructural y contenido mínimo; no
reemplaza la revisión visual editorial.
