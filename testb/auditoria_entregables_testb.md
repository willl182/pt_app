# Auditoría de Entregables en `testb`

**Fecha:** 2026-06-28  
**Directorio auditado:** `testb/`  
**Alcance:** índice maestro, 9 documentos técnicos Markdown/DOCX y trazabilidad con los artefactos fuente de `Entregables_pt_app`.  
**Método:** revisión documental, verificación de pares MD/DOCX, prueba de integridad DOCX, búsqueda de redacción riesgosa, contraste básico con scripts de prueba, ejecución selectiva de tests y verificación posterior de correcciones críticas.

## Resumen Ejecutivo

El paquete `testb` representa un avance fuerte frente a los README originales: contiene un índice maestro y un documento formal por cada entregable, con extensión suficiente, lenguaje más institucional y estados documentales explícitos. En general, el paquete ya tiene la forma correcta para una entrega revisable por lectores no desarrolladores.

La corrección posterior resolvió el bloqueo reproducible del Entregable 05 y las erratas visibles identificadas en los documentos principales. El paquete queda más defendible, aunque todavía conserva riesgos documentales menores: rutas abreviadas en algunas tablas, falta de homogeneidad plena de plantilla y necesidad de completar evidencia externa trazable para el Entregable 09 antes de declarar reproducibilidad completa.

## Verificaciones Realizadas

| Verificación | Resultado |
|--------------|-----------|
| Pares Markdown/DOCX en `testb` | Correcto: índice + 9 documentos tienen `.md` y `.docx`. |
| Integridad estructural de DOCX (`unzip -t`) | Correcto: no se detectaron DOCX corruptos. |
| Tamaño documental | Correcto: los documentos no son resúmenes cortos; van de 199 a 320 líneas por entregable. |
| Estados documentales | Mayormente correcto: se distingue histórico, parcial, beta no vigente y auditoría pendiente. |
| Ejecución de tests E01-E04 | E01, E02, E03 y E04 ejecutaron; E04 pasó con advertencias repetidas por valores asignados faltantes en algunas combinaciones. |
| Ejecución de tests E05 | Corregido y verificado: 76 expectativas PASS desde raíz; 17 bloques PASS desde el directorio del entregable. |
| Ejecución de tests E07-E09 | E07, E08 y E09 ejecutaron aislados; E07/E08 muestran advertencia menor por línea final incompleta en `data/participants_data4.csv`. |

## Hallazgos

### Resuelto 1 — El test del Entregable 05 ahora es reproducible

**Archivo:** `testb/documento_tecnico_entregable_05.md`  
**Fuente técnica:** `Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.R`

El script fue corregido para cargar `testthat` explícitamente y resolver rutas con base en la ubicación del entregable, sin depender de `setwd("..")`. La corrección se verificó con:

```text
Rscript -e 'testthat::test_file("Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.R")'
```

Resultado: **76 expectativas PASS, 0 fallos, 0 advertencias** desde la raíz del proyecto.

También se verificó desde el directorio del entregable:

```text
Rscript tests/test_05_navegacion.R
```

Resultado: **17 bloques de prueba PASS**.

### Resuelto 2 — Errores visibles de redacción corregidos

**Correcciones aplicadas:**

| Archivo | Problema corregido |
|---------|--------------------|
| `testb/documento_tecnico_entregable_01.md` | Se corrigió el uso de "auditable" y la separación de palabras en la conclusión. |
| `testb/documento_tecnico_entregable_02.md` | Se corrigió la tilde en "metrológica". |
| `testb/documento_tecnico_entregable_03.md` | Se reescribió una frase rota en la relación con E08. |
| `testb/documento_tecnico_entregable_05.md` | Se corrigieron anglicismos, tildes y una preposición incorrecta. |
| `testb/documento_tecnico_entregable_08.md` | Se corrigieron concordancia gramatical y ortografía. |

### Alto 3 — Rutas abreviadas pueden confundirse con rutas reales desde la raíz

**Ejemplos:**

| Documento | Ejemplo |
|-----------|---------|
| E04 | `R/calcula_puntajes.R`, `R/crea_reporte.R`, `md/formulas_y_ejemplos.md`, `tests/test_04_puntajes.R` |
| E05 | `05_prototipo_ui/html/`, `05_prototipo_ui/tests/` |
| E09 | `09_informe_final/R/genera_anexos.R`, `09_informe_final/md/informe_validacion.md` |

En varios documentos, las rutas se escriben como si el lector estuviera ubicado dentro del directorio del entregable, pero el índice maestro y el paquete completo se leen desde `testb` o desde la raíz del proyecto. Esto vuelve ambigua la localización de evidencia.

**Riesgo:** alguien externo puede no encontrar los archivos o pensar que faltan.

**Acción recomendada:** normalizar todas las rutas de evidencia con prefijo completo desde la raíz del repositorio, por ejemplo:

```text
Entregables_pt_app/04_puntajes/R/calcula_puntajes.R
Entregables_pt_app/09_informe_final/R/genera_anexos.R
```

### Alto 4 — E09 conserva estado de auditoría pendiente, pero ya separa evidencia histórica de evidencia externa pendiente

**Archivo:** `testb/documento_tecnico_entregable_09.md`  
**Líneas relevantes:** 56, 177, 187-191, 269-287

El documento declara "requiere auditoría de evidencia" y ahora incorpora una matriz explícita de evidencia externa pendiente. Los resultados específicos de la comparación Excel/VIVO se conservan como resultados históricos reportados, no como certificación final.

**Riesgo:** si un evaluador pide los Excel/VIVO exactos, el documento todavía no da una ruta concreta y verificable.

**Acción recomendada:** localizar y adjuntar los archivos Excel/VIVO exactos, o mantener el estado "requiere auditoría de evidencia" en la entrega formal.

### Resuelto 5 — Conteo de pruebas E05 aclarado

**Archivo:** `testb/documento_tecnico_entregable_05.md`  
**Líneas:** 72, 110, 209  
**Fuente:** `Entregables_pt_app/05_prototipo_ui/tests/test_05_navegacion.R`

El documento fue actualizado para hablar de **17 bloques de prueba y 76 expectativas**, que es la salida verificada por `testthat::test_file()`.

### Medio 6 — Los documentos no tienen una estructura visual homogénea

Algunos documentos usan YAML inicial y `# Portada`; otros empiezan con título Markdown directo; algunos numeran secciones (`## 1. Contexto`) y otros no; algunos usan `#` para secciones principales y otros `##`.

**Riesgo:** el paquete se ve menos institucional, aunque el contenido sea sólido.

**Acción recomendada:** unificar plantilla para los 10 archivos de `testb`:

- mismo bloque de portada
- mismo nivel de encabezados
- mismo formato de estado documental
- mismo cierre con versión, fecha y próxima revisión
- mismo formato de tabla "Documentos de consulta"

### Medio 7 — Algunas afirmaciones de pruebas deben distinguir "pasó al ejecutar" vs "la prueba está diseñada para"

Ejemplos:

| Documento | Frase problemática |
|-----------|--------------------|
| E04 | "El cubrimiento de pruebas abarca..." |
| E05 | "La integridad del entregable se verifica..." |
| E08 | "El estado esperado es 19/19 pruebas superadas..." |
| E09 | "Todos los tests de reproducibilidad pasaron" aparece en la ejecución, pero el documento no registra fecha/comando de ejecución. |

**Riesgo:** el documento puede sonar a evidencia ejecutada aunque no incluya fecha, comando, ambiente ni salida.

**Acción recomendada:** agregar una mini-bitácora de verificación por documento: fecha, comando, resultado, advertencias y archivo de salida.

### Medio 8 — E04 pasa con advertencias relevantes que no aparecen en el documento

Durante la ejecución de E04, los tests pasaron, pero emitieron múltiples advertencias:

```text
No se encontró valor asignado para ...
```

Las advertencias aparecen en pruebas de cálculo global y reportes. Pueden ser esperadas por el diseño del test, pero el documento no las menciona.

**Riesgo:** si un tercero ejecuta la prueba, verá muchas advertencias y puede interpretarlas como fallas.

**Acción recomendada:** documentar si esas advertencias son esperadas por datos parciales de prueba, o ajustar los datos del test para que no produzcan ruido.

### Bajo 9 — Advertencia menor en E07/E08 por `participants_data4.csv`

E07 y E08 ejecutan, pero muestran:

```text
incomplete final line found by readTableHeader on 'data/participants_data4.csv'
```

**Riesgo:** bajo. No rompe las pruebas, pero ensucia la salida y puede preocupar a un evaluador.

**Acción recomendada:** agregar salto de línea final al CSV o documentar que la advertencia no afecta lectura ni resultados.

## Estado por Entregable

| Entregable | Estado documental auditado | Decisión |
|------------|-----------------------------|----------|
| Índice maestro | Útil y claro | Corregir tras normalizar estados/rutas. |
| E01 | Sustantivo y bien orientado | Corregir erratas visibles. |
| E02 | Fuerte; buen equilibrio entre detalle y lectura común | Corregir tilde y revisar frase "18 funciones" vs "77 funciones". |
| E03 | Detallado y honesto sobre divergencias | Corregir frase rota en relación con E08. |
| E04 | Bueno, pero con rutas abreviadas y advertencias no explicadas | Normalizar rutas y registrar advertencias de test. |
| E05 | Listo como evidencia histórica | Prueba reproducible corregida; bitácora de verificación agregada. |
| E06 | Aceptable | Revisar redacción puntual y homogeneizar plantilla. |
| E07 | Aceptable | Documentar advertencia menor y homogeneizar plantilla. |
| E08 | Aceptable con correcciones | Corregir erratas y registrar ejecución real 19/19. |
| E09 | Bueno pero delicado | Matriz agregada; sigue requiriendo localización de evidencia externa Excel/VIVO y cierre del pipeline. |

## Recomendación de Cierre

El paquete `testb` ya supera el bloqueo reproducible de E05 y corrige las erratas visibles detectadas. Para una entrega final de mayor solidez, la ruta recomendada es:

1. Regenerar DOCX desde los Markdown corregidos.
2. Normalizar rutas a formato completo desde raíz del repositorio donde todavía aparezcan abreviadas.
3. Agregar bitácora de verificación por entregable, con comando, fecha, resultado y advertencias.
4. Para E09, localizar la evidencia externa Excel/VIVO o mantener expresamente el estado de auditoría pendiente.

Con esas correcciones restantes, el paquete quedaría listo para entrega formal con menor riesgo de observaciones externas.
