# DG-PSEA-03: Aplicativo pt_app

## Objetivo

Documentar el alcance, funciones, entradas, salidas, controles y limites del aplicativo `pt_app` como herramienta analitica del PEA para preprocesamiento, consolidacion de datos, analisis estadistico, evaluacion de homogeneidad y estabilidad, generacion de salidas oficiales e informe final de resultados.

El aplicativo debe permitir demostrar que los calculos, transformaciones, versiones del software, entradas, salidas y cambios se mantienen trazables, verificables, revisados y adecuados para sostener evaluaciones de desempeno tecnicamente defendibles.

## Alcance

Aplica al aplicativo `pt_app` durante las fases de recepcion de exportaciones oficiales, preprocesamiento, revision inicial de datos, consolidacion, analisis estadistico, evaluacion de homogeneidad/estabilidad y generacion de informe del ensayo de aptitud para gases contaminantes criterio.

Incluye:

- Carga de datos oficiales exportados desde `calaire-app` (`F-PSEA-09`).
- Preprocesamiento de datos de participantes, equipos e instrumentos.
- Revision de completitud, unidades, consistencia, duplicados, formatos y datos faltantes.
- Preprocesamiento de datos de homogeneidad y estabilidad.
- Consolidacion del dataset oficial para evaluacion de aptitud (`F-PSEA-12`).
- Implementacion de criterios estadisticos definidos por el PEA.
- Calculo de valor asignado, diferencias, scores, incertidumbres o indicadores cuando esten previamente definidos y aprobados.
- Evaluacion de homogeneidad y estabilidad del item de ensayo.
- Generacion de salidas tecnicas e informe final de resultados.
- Registro de version del aplicativo, parametros, archivos de entrada, archivos de salida, responsable y advertencias.
- Evidencia de validacion de software, pruebas con datos conocidos, control de cambios, revision tecnica y tratamiento de incidentes.

No incluye:

- Captura directa de datos de participantes.
- Definicion metodologica de criterios estadisticos, valor asignado, `sigma_pt`, incertidumbre o reglas de decision.
- Aprobacion editorial y emision formal del informe final.
- Gestion de quejas, apelaciones, trabajo no conforme o acciones correctivas, aunque puede generar evidencia para dichos procesos.
- Reemplazo de la competencia estadistica, revision tecnica o autorizacion del informe.

## Ficha del aplicativo

| Campo | Descripcion |
|---|---|
| Aplicativo | `pt_app` |
| Uso previsto | Preprocesar datos oficiales, consolidar datasets, ejecutar calculos estadisticos aprobados, evaluar homogeneidad/estabilidad, generar salidas tecnicas e informe final. |
| Rol en el SGC | Aplicativo critico para validez estadistica, trazabilidad de calculos, integridad de datos e informe de resultados. |
| Requisitos relacionados | ISO/IEC 17043:2023: diseno estadistico, manejo de items, analisis de datos, evaluacion de desempeno, informe, control de datos y sistema de gestion. ISO 13528:2022: valor asignado, `sigma_pt`, incertidumbre, revision inicial de datos, tratamiento de valores atipicos, scores, homogeneidad/estabilidad y validacion de software. |
| Instructivos de uso | `I-PSEA-04`, `I-PSEA-05` |
| Procedimientos relacionados | `P-PSEA-03`, `P-PSEA-07`, `P-PSEA-08`, `P-PSEA-09`, `P-PSEA-15`, `P-PSEA-16`, `P-PSEA-19`, `P-PSEA-20` |

## Requisitos minimos del aplicativo

| Requisito SGC | Control esperado en `pt_app` |
|---|---|
| Uso de datos oficiales | Solo debe analizar exportaciones aprobadas desde `calaire-app` y datasets consolidados identificables. |
| Revision inicial de datos | Debe permitir detectar o registrar unidades incorrectas, formatos invalidos, datos faltantes, duplicados, valores extremos, inconsistencias de metodo y correcciones. |
| Trazabilidad de calculo | Cada resultado debe relacionarse con ronda, version del aplicativo, entrada, parametros, criterio estadistico, salida generada y responsable. |
| Implementacion de metodo aprobado | Los calculos deben corresponder al criterio estadistico aprobado y a la ficha/plan de ronda vigente; cambios de criterio requieren aprobacion documentada. |
| Homogeneidad y estabilidad | Debe separar datos preprocesados (`F-PSEA-11A`, `F-PSEA-11B`) de resultados evaluados (`F-PSEA-11C`, `F-PSEA-11D`). |
| Tratamiento de datos anomalos | Debe conservar advertencias y decisiones de inclusion, exclusion o tratamiento especial, sin modificaciones discrecionales no trazadas. |
| Validacion estadistica del software | Debe verificarse con datos de prueba conocidos, resultados esperados, revision de formulas/rutinas y pruebas de regresion ante cambios. |
| Revision y autorizacion | Las salidas usadas para informe deben ser revisadas tecnicamente antes de su emision. |
| Confidencialidad | Debe proteger codigos de participantes, valores sensibles, informes preliminares y archivos de trabajo. |

## Responsabilidades y uso

| Rol | Responsabilidad |
|---|---|
| Analista PT | Ejecutar preprocesamiento, analisis estadistico y generacion de salidas en `pt_app`, conservando bitacora y advertencias. |
| Revisor tecnico | Verificar que entradas, criterios, parametros, resultados y salidas correspondan al criterio estadistico aprobado, al flujo tecnico de datos, al plan/ficha de ronda y a los registros oficiales. |
| Responsable de ronda | Asegurar que las entradas desde `calaire-app` sean la exportacion oficial aprobada y que las salidas se integren al expediente de ronda. |
| Administrador del aplicativo | Gestionar versiones del aplicativo, permisos, respaldos, trazabilidad de ejecuciones, liberaciones y restauracion ante fallas. |
| Responsable de calidad | Verificar control de registros, cambios, incidentes, trabajo no conforme y cumplimiento de confidencialidad. |
| Personal autorizado en competencia | Aprobar uso de metodos, interpretacion estadistica o emision de resultados solo dentro de su autorizacion documentada. |

## Entradas

| Entrada | Uso |
|---|---|
| `F-PSEA-09` | Datos de participantes exportados oficialmente desde `calaire-app`. |
| `F-PSEA-04` | Anexo tecnico de equipos e instrumentos del participante. |
| `F-PSEA-05` / `F-PSEA-06` | Plan y ficha de ronda que definen configuracion, analitos, niveles, criterios y condiciones aplicables. |
| `F-PSEA-11A` / `F-PSEA-11B` | Datos preprocesados de homogeneidad y estabilidad cuando existan ejecuciones previas controladas. |
| Archivos tecnicos internos | Datos de ronda, niveles, homogeneidad, estabilidad, parametros o archivos crudos usados como soporte trazable. |
| Criterio estadistico aprobado | Metodo de referencia para calculos, indicadores e interpretacion. |
| Datos de prueba validada | Conjuntos de datos usados para validar o verificar rutinas de calculo. |

## Salidas

| Salida | Descripcion |
|---|---|
| `F-PSEA-10` | Registro de preprocesamiento de datos. |
| `F-PSEA-11A` | Datos preprocesados de homogeneidad. |
| `F-PSEA-11B` | Datos preprocesados de estabilidad. |
| `F-PSEA-11C` | Resultados de homogeneidad. |
| `F-PSEA-11D` | Resultados de estabilidad. |
| `F-PSEA-12` | Datos oficiales consolidados para evaluacion de aptitud. |
| `F-PSEA-13` | Informe final de resultados. |
| Bitacora del aplicativo | Evidencia de ejecuciones, parametros, versiones del software, advertencias, errores, archivos y responsables. |
| Registro de validacion/cambio | Evidencia de pruebas, version aprobada del aplicativo, cambios liberados y evaluacion de impacto estadistico. |

## Campos minimos y trazabilidad

Cada ejecucion del preprocesador debe registrar como minimo:

- Identificador de ronda.
- Fecha y hora de ejecucion.
- Version del aplicativo, script, paquete o rutina utilizada.
- Archivos de entrada con ruta, identificador, version o huella disponible.
- Archivos de salida generados.
- Responsable de la ejecucion.
- Reglas de validacion aplicadas.
- Observaciones, advertencias, errores o datos excluidos.
- Decision sobre continuidad, correccion o escalamiento.

Cada ejecucion del modulo de analisis debe registrar como minimo:

- Identificador de ronda.
- Dataset consolidado utilizado (`F-PSEA-12`).
- Criterio estadistico aplicado.
- Parametros usados: valor asignado, `sigma_pt`, incertidumbre, limites, criterios de advertencia o accion, segun aplique.
- Resultados de homogeneidad y estabilidad (`F-PSEA-11C` / `F-PSEA-11D`).
- Tratamiento de valores atipicos, datos censurados, faltantes, corregidos o excluidos.
- Informe final generado (`F-PSEA-13`) o version preliminar asociada.
- Responsable del analisis y revisor tecnico.
- Advertencias o restricciones que deban comunicarse en el informe.

Cada informe generado debe conservar trazabilidad hacia:

- Datos oficiales de entrada.
- Dataset consolidado final.
- Version del aplicativo.
- Criterio estadistico aplicado.
- Version del informe.
- Revision tecnica y autorizacion segun el procedimiento de emision de informe.

## Validacion estadistica, cambios y mantenimiento

`pt_app` debe validarse antes de su uso oficial en una ronda y despues de cambios que puedan afectar transformaciones, calculos, filtros, graficas, plantillas de informe, estructura de datos, dependencias, permisos, exportaciones o almacenamiento de resultados.

La evidencia minima de validacion o cambio debe incluir:

- Version del aplicativo, modulo, script, paquete o componente evaluado.
- Metodo estadistico o funcion cubierta por la prueba.
- Datos de prueba con resultado esperado.
- Resultado obtenido y diferencia frente al esperado, cuando aplique.
- Verificacion de formulas, rutinas o parametros criticos.
- Prueba de regresion frente a una version previamente aceptada, cuando el cambio modifique calculos.
- Evaluacion de impacto sobre rondas abiertas, informes preliminares, datos consolidados o informes emitidos.
- Responsable de ejecucion, revision y aprobacion.
- Restricciones de uso, correcciones o acciones si la prueba no es satisfactoria.

La validacion debe cubrir, segun aplique:

- Lectura e interpretacion de entradas oficiales.
- Conversion de unidades y formatos.
- Reglas de completitud y consistencia.
- Consolidacion de `F-PSEA-12`.
- Calculos de homogeneidad y estabilidad.
- Calculo de valor asignado, incertidumbre, `sigma_pt`, diferencias y scores.
- Tratamiento de datos atipicos, faltantes, censurados o corregidos.
- Generacion de tablas, graficos e informe.
- Proteccion de codigos de participante y valores sensibles.

Los cambios no deben liberarse para uso oficial si no existe aprobacion del responsable autorizado. Cuando una falla o cambio pueda afectar resultados emitidos, debe evaluarse impacto tecnico y activar los procedimientos de trabajo no conforme, valores sensibles, quejas, apelaciones o emision de informe segun corresponda.

## Controles operativos

- Toda ejecucion del preprocesador debe quedar registrada en `F-PSEA-10` o bitacora equivalente referenciada por el expediente de ronda.
- El dataset oficial consolidado (`F-PSEA-12`) debe ser la unica entrada autorizada del modulo de analisis para resultados oficiales.
- Los criterios estadisticos aplicados deben corresponder al criterio aprobado y al plan/ficha de ronda vigente.
- Las salidas tecnicas intermedias (`F-PSEA-11A` / `F-PSEA-11B`) deben diferenciarse de los resultados finales de H/E (`F-PSEA-11C` / `F-PSEA-11D`).
- La generacion del informe final debe estar trazable al analisis, dataset, version del aplicativo y criterio estadistico aplicado.
- Los archivos preliminares, resultados antes de revision y valores sensibles deben protegerse contra divulgacion no autorizada.
- Las decisiones sobre inclusion, exclusion o correccion de datos deben quedar documentadas antes de emitir resultados.
- Los errores de software, fallas de calculo, inconsistencias de version o perdida de trazabilidad deben evaluarse como potencial trabajo no conforme.
- Las versiones obsoletas del aplicativo o scripts no deben usarse para resultados oficiales salvo autorizacion y justificacion documentada.
- Deben existir respaldos o mecanismos de recuperacion proporcionales al riesgo de perdida de datos, calculos e informes.

## Documentos relacionados

| Codigo | Relacion |
|---|---|
| `I-PSEA-04` | Instructivo de uso del preprocesador de `pt_app`. |
| `I-PSEA-05` | Instructivo de uso del modulo de analisis PT de `pt_app`. |
| `P-PSEA-03` | Control de registros y evidencias del PEA. |
| `P-PSEA-07` | Criterio estadistico que gobierna el analisis. |
| `P-PSEA-08` | Flujo tecnico de datos digitales del PEA. |
| `P-PSEA-09` | Procedimiento de generacion y emision del informe de resultados. |
| `P-PSEA-15` | Trabajo no conforme, no conformidades y acciones correctivas. |
| `P-PSEA-16` | Divulgacion y control de valores sensibles. |
| `P-PSEA-19` | Confidencialidad operativa interna del PEA. |
| `P-PSEA-20` | Competencia y autorizacion operativa del PEA. |
| `DG-PSEA-02` | Aplicativo `calaire-app` que alimenta datos de entrada. |
| `F-PSEA-13` | Informe final de resultados generado con salidas de `pt_app`. |

## Limites

- No es un formato `F-PSEA`.
- No es un instructivo de uso; la operacion se documenta en `I-PSEA-04` e `I-PSEA-05`.
- No define criterios estadisticos; implementa y evidencia los criterios aprobados por el PEA.
- No captura datos de participantes; recibe las exportaciones oficiales desde `calaire-app`.
- No sustituye la revision tecnica, la competencia estadistica ni la autorizacion del informe.
- No gestiona quejas, apelaciones ni acciones correctivas, aunque sus registros pueden ser evidencia para esos procesos.
- No convierte archivos tecnicos internos en formatos `F-PSEA` adicionales salvo decision documental explicita.

---

**Nota:** Los archivos tecnicos internos del preprocesador y del modulo de analisis se mapean en `P-PSEA-08` y no se codifican como formatos `F-PSEA` adicionales.
