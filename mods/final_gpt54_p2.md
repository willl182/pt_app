# Plan Final de Revisión, Evaluación y Consolidación de Ajustes del Aplicativo Estadístico

**Fecha:** 2026-03-09  
**Estado:** final  
**Fuente principal:** `docs/ajustes_app/Revisión aplicativo estadístico.pdf`  
**Planes evaluados:** `codex53_plan.md`, `gemflash3_plan.md`, `gempro31_plan.md`, `glm47_plan.md`, `gpt54_plan.md`, `minimax25_plan.md`, `opus_plan.md`, `sonnet_plan.md`  
**Alcance:** consolidación metodológica, funcional y documental previa a una futura implementación técnica  
**Restricción de alcance:** este documento no revisa ni modifica la codebase del aplicativo

---

## 1. Propósito

Definir un plan final unificado para la revisión y evaluación de los planes existentes sobre ajustes del aplicativo estadístico, integrando los elementos de mayor valor técnico y operativo, eliminando repeticiones y dejando un paquete de especificación suficientemente claro para soportar una etapa posterior de implementación y validación técnica.

---

## 2. Resultado de la evaluación comparativa de planes

La revisión de los planes disponibles permitió identificar una convergencia alta en los hallazgos críticos, así como diferencias en nivel de detalle, orientación y mecanismos de cierre.

### Elementos conservados

- Se conserva la priorización de los errores estadísticos bloqueantes como punto de entrada del plan.
- Se conserva la necesidad de separar de forma explícita los conjuntos de datos de homogeneidad, estabilidad y participantes.
- Se conserva la exigencia de trazabilidad por corrida, serie y origen de datos.
- Se conserva la validación cruzada con referencia externa como condición obligatoria de cierre.
- Se conserva la necesidad de mejorar auditabilidad mediante tablas intermedias y exportables legibles.

### Elementos depurados o fusionados

- Se unifican las descripciones repetidas de los hallazgos B.10, MADe y selección por tamaño muestral.
- Se fusionan en una sola fase los requisitos de tablas, carga diferenciada y exportación, evitando separar artificialmente aspectos de auditabilidad que pertenecen al mismo frente.
- Se integran en un único cierre los componentes de checklist, acta, prerrequisitos y riesgos residuales.

### Vacíos cerrados en este plan final

- Se incorpora una evaluación explícita de los planes revisados, no solo una propuesta de acciones.
- Se fija un enfoque híbrido: cierre documental robusto con preparación directa para implementación futura.
- Se normaliza una estructura única de fases, entregables y criterios de cierre para evitar ambigüedad entre versiones.

---

## 3. Hallazgos consolidados

Del análisis conjunto de los planes y del informe base se consolidan seis frentes de intervención:

1. **Fórmula B.10 de homogeneidad:** cuando el radicando resulte negativo, la salida operativa debe fijarse en `ss = 0`.
2. **Cálculo de MADe:** debe ejecutarse exclusivamente con datos de participantes y no con datos del estudio de homogeneidad.
3. **Regla metodológica por tamaño muestral:** con `n >= 12` debe aplicarse Algoritmo A; con `n < 12` debe aplicarse el método robusto correspondiente.
4. **Trazabilidad de series y datasets:** debe eliminarse la ambigüedad entre `DATOS 1`, `DATOS 2` y cualquier otra serie utilizada en una corrida.
5. **Validación de Algoritmo A:** deben quedar disponibles los datos de entrada, los pasos de cálculo y la evidencia necesaria para contraste externo.
6. **Auditabilidad de carga, visualización y exportación:** la revisión externa debe poder realizarse sin interpretación adicional ni reconstrucciones informales.

---

## 4. Principios rectores del plan final

1. La validez estadística prevalece sobre cualquier mejora cosmética o de interfaz.
2. Ningún cálculo se considerará corregido sin evidencia reproducible.
3. Todo resultado debe poder rastrearse hasta su dataset, serie, corrida y contexto de cálculo.
4. La revisión externa debe poder ejecutarse con insumos comprensibles en Excel u otro medio equivalente.
5. La futura implementación técnica solo podrá iniciarse cuando los requisitos funcionales y documentales aquí definidos estén cerrados.

---

## 5. Plan final por fases

### Fase 1. Consolidación normativa y reglas estadísticas

**Objetivo:** convertir los hallazgos del informe y de los planes revisados en reglas funcionales inequívocas y trazables a criterio técnico.

**Actividades**
- Formalizar la regla operativa de la fórmula B.10 para casos con radicando negativo.
- Establecer que MADe, nIQR y Algoritmo A utilizan únicamente datos de participantes.
- Definir la regla de decisión por tamaño muestral, incluyendo el umbral `n >= 12`.
- Precisar qué se considera dato válido para el conteo de `n` y para la selección metodológica.
- Confirmar qué cálculos se consideran correctos y no requieren rediseño metodológico, a fin de evitar retrabajo.

**Entregables**
- Especificación funcional de reglas estadísticas.
- Matriz hallazgo -> regla -> criterio técnico.

**Criterio de cierre**
- Cada regla queda formulada sin ambigüedad, vinculada a un hallazgo concreto y lista para ser usada como referencia de implementación futura.

### Fase 2. Modelo de datos y trazabilidad

**Objetivo:** eliminar la mezcla de fuentes y asegurar que cada cálculo pueda reconstruirse de manera íntegra.

**Actividades**
- Definir de forma separada los datasets de homogeneidad, estabilidad y participantes.
- Establecer un diccionario mínimo de campos obligatorios por registro.
- Formalizar la identificación de series utilizadas por corrida, distinguiendo inequívocamente `DATOS 1`, `DATOS 2` u otras variantes.
- Definir los metadatos mínimos por resultado: analito, corrida, serie, unidad, dataset fuente, fecha de cálculo y versión metodológica.
- Construir una matriz de trazabilidad que conecte origen de datos, cálculo aplicado y salida esperada.

**Entregables**
- Diccionario de datos.
- Matriz de trazabilidad de cálculos y resultados.

**Criterio de cierre**
- Todo resultado estadístico puede rastrearse hasta su origen, su serie y su contexto de cálculo sin supuestos implícitos.

### Fase 3. Protocolo de validación técnica

**Objetivo:** diseñar la verificación independiente que permitirá confirmar la corrección técnica de los ajustes.

**Actividades**
- Diseñar casos de validación para B.10 con radicando positivo y negativo.
- Diseñar casos de MADe con dataset correcto de participantes.
- Incluir escenarios de borde con `n = 11` y `n = 12`.
- Definir un caso específico de validación para Algoritmo A con entradas, iteraciones y resultado final esperados.
- Incorporar escenarios con datos faltantes, fuente equivocada, serie incorrecta y diferencias de redondeo.
- Establecer formato de registro para comparación entre valor esperado, valor observado y diferencia.

**Entregables**
- Matriz de casos de validación.
- Formato de registro de resultados observados vs. esperados.
- Protocolo de validación cruzada App vs. referencia externa.

**Criterio de cierre**
- Cada hallazgo crítico dispone de al menos un caso de validación independiente y de un criterio explícito de aceptación.

### Fase 4. Auditabilidad, tablas y exportables

**Objetivo:** asegurar que la futura solución sea comprensible y verificable por un revisor externo sin acceso al código.

**Actividades**
- Definir la separación funcional de la carga de datos de homogeneidad, estabilidad y participantes.
- Especificar las tablas mínimas requeridas para visualizar entradas, cálculos intermedios y resultados finales.
- Definir un formato de exportación legible, consistente y reproducible en Excel.
- Establecer encabezados, nombres de columnas y metadatos mínimos para eliminar ambigüedad.
- Precisar qué información debe quedar visible para facilitar revisión de Algoritmo A y de la selección metodológica aplicada.

**Entregables**
- Especificación de tablas de revisión.
- Especificación funcional de exportables de auditoría.
- Requisitos mínimos de visualización para validación externa.

**Criterio de cierre**
- Un tercero puede reconstruir y revisar técnicamente los cálculos usando las salidas definidas, sin depender de interpretación informal.

### Fase 5. Cierre, evaluación final y transferencia a implementación

**Objetivo:** consolidar el paquete final, clasificar el estado de cada hallazgo y dejar definidos los prerrequisitos para una etapa posterior de desarrollo técnico.

**Actividades**
- Integrar en un solo paquete documental las reglas, datasets, validaciones, criterios de auditabilidad y condiciones de cierre.
- Clasificar cada hallazgo como `cerrado`, `pendiente` o `condicionado`.
- Consolidar riesgos residuales y dependencias externas.
- Definir los prerrequisitos mínimos para iniciar implementación sobre el aplicativo.
- Elaborar el mecanismo de cierre técnico mediante checklist y acta de validación.

**Entregables**
- Checklist de cierre técnico por hallazgo.
- Acta de validación y evaluación consolidada.
- Documento de prerrequisitos para implementación futura.

**Criterio de cierre**
- Existe un paquete documental único, consistente y transferible que puede ser usado por un equipo técnico sin vacíos funcionales críticos.

---

## 6. Priorización consolidada

| Prioridad | Frente | Justificación |
|---|---|---|
| Alta | B.10 con radicando negativo | Compromete la validez del cálculo de homogeneidad |
| Alta | MADe con fuente incorrecta | Introduce error metodológico en la dispersión robusta |
| Alta | Regla `n >= 12` para Algoritmo A | Puede producir selección estadística incorrecta |
| Media | Trazabilidad de series y datasets | Afecta reproducibilidad y auditoría |
| Media | Evidencia de Algoritmo A | Impide validación externa completa |
| Media | Tablas y exportables de revisión | Dificulta la evaluación técnica por terceros |

---

## 7. Riesgos, dependencias y prerrequisitos

### Riesgos residuales

| Riesgo | Impacto | Control propuesto |
|---|---|---|
| Persistencia de mezcla entre datasets | Reproducción del error metodológico | Regla obligatoria de origen y matriz de trazabilidad |
| Cierre sin validación externa suficiente | Falsa conformidad técnica | Casos dorados y comparación documentada |
| Ambigüedad en series utilizadas | Baja auditabilidad | Registro obligatorio de serie por corrida |
| Exportables poco claros | Revisión externa ineficiente | Especificación mínima de tablas y columnas |

### Dependencias externas

- Disponibilidad de datos de referencia para validación externa, especialmente para Algoritmo A.
- Confirmación técnica de tolerancias numéricas aceptables para comparación con Excel.
- Acceso posterior al repositorio del aplicativo cuando se apruebe la fase de implementación.

### Prerrequisitos para implementación futura

1. Reglas estadísticas formalizadas y aprobadas.
2. Modelo de datos y trazabilidad documentados.
3. Casos de validación definidos y listos para ejecución.
4. Requisitos mínimos de auditabilidad y exportación cerrados.
5. Checklist y acta de cierre metodológico preparados.

---

## 8. Criterios globales de aceptación

- Con radicando negativo en B.10, el resultado esperado queda definido como `ss = 0`.
- MADe, nIQR y Algoritmo A quedan asociados únicamente a datos de participantes.
- La regla `n < 12` / `n >= 12` queda formulada sin ambigüedad y con escenarios de validación.
- Cada resultado conserva trazabilidad mínima de dataset, serie, corrida y contexto metodológico.
- La validación cruzada puede ejecutarse con evidencia suficiente para comparación externa.
- Las tablas y exportables definidos permiten revisión técnica sin conocimiento implícito del sistema.
- El cierre por hallazgo puede documentarse mediante checklist y acta consolidada.

---

## 9. Condición de salida

Este plan se considerará cumplido cuando exista una especificación final completa que deje resueltos, a nivel documental y funcional, los siguientes aspectos:

- reglas estadísticas corregidas y formalizadas;
- datasets y series definidos sin ambigüedad;
- protocolo de validación técnica listo para ejecución;
- requisitos de auditabilidad y exportación cerrados;
- mecanismos de cierre y transferencia preparados para una etapa posterior de implementación técnica.

---

## 10. Referencias base

- `docs/ajustes_app/Revisión aplicativo estadístico.pdf`
- `docs/ajustes_app/gpt54_plan.md`
- `docs/ajustes_app/sonnet_plan.md`
- `docs/ajustes_app/minimax25_plan.md`
- `docs/ajustes_app/codex53_plan.md`
- `logs/plans/260228_2000_plan_implementacion-calaire-app-revision2-final.md`
