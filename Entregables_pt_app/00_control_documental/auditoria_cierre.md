# Auditoría cruzada y cierre del paquete documental

**ID:** DOC-CTL-AUD-07  
**Versión:** 1.0  
**Fecha de corte:** 2026-07-14  
**Estado:** Vigente verificado; aprobación contractual pendiente  
**Alcance:** `Entregables_pt_app/`, código vigente y evidencia reproducible

## Resultado ejecutivo

Los nueve entregables cuentan con una fuente oficial identificada, derivados
cuando corresponden y evidencia con estado explícito. El paquete supera los
controles automáticos de estructura, enlaces locales, hashes y apertura técnica
de DOCX/PDF. La lectura se organizó por tarea, pasos, resultado, interpretación
y recuperación para que una persona sin conocimientos de R pueda seguir el
flujo principal.

Este cierre no equivale a aprobación contractual ni a certificación normativa.
Continúan abiertas la recepción del contrato/TDR/acta primaria, la aprobación
del responsable y el riesgo técnico del criterio expandido de homogeneidad
descrito en E09.

## Cobertura E01–E09

| ID | Fuente oficial | Derivado principal | Evidencia de cierre | Estado |
|---|---|---|---|---|
| E01 | `01_repo_inicial/README.md` | `README.docx` | inventario maestro | Vigente; registro histórico |
| E02 | `02_funciones_usadas/md/documentacion_funciones.md` | `documentacion_funciones.docx` | catálogo y pruebas F4 | Vigente verificado |
| E03 | `03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md` | DOCX homónimo | pruebas F4 y E09 | Vigente verificado |
| E04 | `04_puntajes/md/formulas_y_ejemplos.md` | DOCX homónimo | pruebas F4 y E09 | Vigente verificado |
| E05 | `05_prototipo_ui/md/wireframes.md` | DOCX y HTML | capturas CAP-01, 04, 12, 19 | Vigente verificado |
| E06 | `06_app_logica/md/manual_usuario.md` | `manual_usuario.docx` | CAP-02 a CAP-18 | Vigente verificado |
| E07 | `07_dashboards/md/documentacion_dashboards.md` | DOCX homónimo | CAP-05, 06, 08, 10–16 | Vigente verificado |
| E08 | `08_beta/md/manual_desarrollador.md` | `manual_desarrollador.docx` | pruebas F5 y CAP-17–19 | Vigente con riesgos explícitos |
| E09 | `09_informe_final/md/informe_validacion.md` | DOCX y PDF | matriz, anexos y pruebas F6 | Vigente; 1 riesgo abierto |

## Consistencia transversal

- La autoridad funcional es `app.R` y el código cargado desde `R/` y
  `ptcalc/`; las copias `app_original.R`, `app_v06.R`, `app_v07.R` y
  `app_final.R` son históricas.
- Las fuentes oficiales usan fecha de corte 2026-07-14, español para la persona
  usuaria y nombres internos en inglés cuando es necesario.
- Los umbrales y fórmulas se verifican en las pruebas de Fases 4 y 6; E09
  conserva precisión completa y distingue redondeo de presentación.
- Las rutas de imágenes y documentos se validan desde la ubicación de cada
  Markdown. Los enlaces web se registran como referencias externas y requieren
  conectividad para su consulta.
- `matriz_trazabilidad.csv` une cada requisito provisional REQ-E01–REQ-E09 con
  fuente y evidencia. No se infieren cláusulas contractuales ausentes.

## Recorrido de lectura no técnica

1. Abrir `manifiesto_entrega.md` y elegir el entregable según la necesidad.
2. Para operar el aplicativo, seguir E06 desde preparación de archivos hasta
   informes; cada módulo explica qué hacer y cómo leer el resultado.
3. Consultar E07 para tablas, gráficos, colores, filtros y advertencias.
4. Ante un error, usar “Problemas frecuentes” de E06; para instalación o
   recuperación técnica, usar E08.
5. Para verificar cálculos y alcance, consultar E03, E04 y E09.

## Controles finales

| Control | Criterio | Evidencia |
|---|---|---|
| Fuentes y cobertura | nueve fuentes oficiales, una por E01–E09 | `indice_maestro.md`, prueba F7 |
| Enlaces locales | destinos Markdown existentes | prueba F7 |
| Formatos | DOCX ZIP válido; PDF legible y con texto | prueba F7 |
| Integridad | tamaño y SHA-256 coinciden | `manifiesto_entrega.csv` |
| Evidencia visual | CAP-01–CAP-19 indexadas y regenerables | índice y registro visual |
| Validación | resultado, límite y responsable explícitos | matriz E09 |

La suite focal de cierre ejecutó 283 expectativas de Fases 1–7, sin fallos ni
advertencias. La suite histórica completa ejecutó 342 expectativas: 313
aprobaron, 29 fallaron y se emitieron 11 advertencias. Veintidós fallos y las
advertencias corresponden al subsistema documental heredado `final_docs/`, que
no existe en este repositorio; los demás fueron efectos de orden al recalcular
hashes y quedaron resueltos al ejecutar el generador final después de las
pruebas que modifican derivados. La ausencia de `final_docs/` se conserva como
riesgo heredado y no afecta las 283 comprobaciones del paquete contractual.
Los comandos, el orden de ejecución y la distinción entre ambas corridas se
conservan en `reporte_controles_fase_7.md`.

## Pendientes y aprobaciones

- **Aprobación contractual:** pendiente hasta recibir contrato/TDR/acta y firma
  del responsable competente.
- **Revisión normativa independiente:** pendiente; las referencias no
  sustituyen el acceso controlado a las normas.
- **Riesgo funcional:** corregir y revalidar el criterio expandido de
  homogeneidad antes de usar esa ruta para decisiones oficiales.
- **Reproducibilidad:** publicar o fijar el estado del repositorio anidado
  `ptcalc`; E09 conserva commit, hashes y parche del estado evaluado.

Estos pendientes no se ocultan ni se interpretan como controles aprobados.
