# Plan Consolidado de Ajustes — CALAIRE-APP (v2)

| Campo | Valor |
|-------|-------|
| Fecha | 2026-03-10 |
| Estado | final |
| Origen | Informe No. 2 de revisión (César Yate, 2026-02-23) |
| Planes fuente | codex53, gemflash3, gempro31, glm47, gpt54, minimax25, opus, sonnet |
| Norma principal | ISO 13528:2022 — Métodos estadísticos para ensayos de aptitud |
| Base | final_opus.md + elementos de cobertura de final_gpt54.md |

---

## 1. Objetivo y alcance

Este plan consolida ocho propuestas independientes generadas por distintos modelos IA, todas basadas en el mismo informe de revisión que identificó nueve hallazgos (H1-H9) en la aplicación estadística R/Shiny CALAIRE-APP. El propósito es definir una ruta única de implementación que corrija los errores estadísticos, elimine la ambigüedad en las fuentes de datos y mejore la auditabilidad del aplicativo.

**Incluye:** corrección de fórmulas estadísticas (B.10, MADe, selector de método robusto), separación formal de datasets, rediseño de carga y exportación, protocolo de validación cruzada y cierre documental de hallazgos. **Excluye:** revisión directa de la codebase, despliegue, pruebas automatizadas e infraestructura.

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

## 3. Principios de ejecución

1. La corrección estadística prevalece sobre cualquier mejora de interfaz.
2. Ningún hallazgo se considerará resuelto sin evidencia reproducible.
3. Todo resultado debe declarar de forma explícita el dataset, la serie y la corrida de los que proviene.
4. La validación externa debe poder ejecutarse sin interpretar supuestos ocultos.
5. La separación entre datos de homogeneidad, estabilidad y participantes debe quedar formalmente establecida antes de cualquier cálculo.

---

## 4. Clasificación de hallazgos

| # | Componente | Veredicto | Severidad | Fase |
|---|-----------|-----------|-----------|------|
| H1 | Fórmula B.10 (homogeneidad) — `sqrt(abs(...))` en vez de condicional | ERROR | Bloqueante | F1 |
| H2 | MADe — calcula con datos de homogeneidad en vez de participantes | ERROR | Bloqueante | F1 |
| H3 | MADe — usa serie DATOS 1 cuando correspondía DATOS 2 | ERROR | Bloqueante | F1 |
| H4 | Selector MADe/nIQR vs Algoritmo A por tamaño muestral | PENDIENTE | Bloqueante | F1 |
| H5 | nIQR | OK | — | — |
| H6 | Estabilidad | OK | — | — |
| H7 | Exportación CSV — formato confuso e ilegible | DEFICIENTE | Media | F3 |
| H8 | Interfaz de carga — sin separación de zonas | DEFICIENTE | Media | F3 |
| H9 | Tablas de cálculos intermedios — no accesibles | DEFICIENTE | Media | F3 |

**Nota:** H5 y H6 fueron verificados como correctos por el revisor y no requieren intervención.

**Resolución del umbral muestral:** La ISO 13528:2022 Sección 9 establece que el Algoritmo A se aplica cuando n >= 12 participantes. Valores menores usan MADe o nIQR. El umbral correcto es n >= 12 (no n > 10 como aparece en alguno de los planes fuente).

---

## 5. Diagrama de dependencias

```
F1 Correcciones estadísticas
 |
 +--> F2 Arquitectura de datos --> F4 Validación y cierre
 |                                       ^
 |                                       |
 +--- F3 Usabilidad y exportación -------+
      (paralelo a F2)
```

F1 es prerequisito de F2 y F3. F3 puede ejecutarse en paralelo con F2. F4 requiere que F2 y F3 estén completas.

---

## 6. Fases de implementación

### Fase 1: Correcciones estadísticas

**Objetivo:** Eliminar errores que invalidan resultados técnicos.

**Criterio de entrada:** Acceso al repositorio del aplicativo (R/Shiny).

| # | Tarea | Hallazgo | Entregable | Criterio de aceptación |
|---|-------|----------|------------|----------------------|
| 1.1 | Corregir fórmula B.10 — condicional para radicando negativo | H1 | Lógica corregida y documentada | Con radicando negativo, ss = 0 |
| 1.2 | Redirigir MADe a dataset de participantes | H2 | Función corregida | MADe coincide con cálculo manual del revisor |
| 1.3 | Asegurar selección de serie correcta (DATOS 1 / DATOS 2) | H3 | Selector de serie con registro en metadatos | Serie usada queda trazada por corrida |
| 1.4 | Implementar selector de método robusto por n | H4 | Switch n < 12 / n >= 12 | n=11 usa MADe/nIQR; n=12 usa Algoritmo A |

**Pseudocódigo B.10 (ISO 13528:2022 Anexo B):**

```
ss_cuadrado = (1/(g-1)) * SUM((x_t - x_bar)^2) - (1/m) * sw^2

si ss_cuadrado < 0:
    ss = 0
sino:
    ss = sqrt(ss_cuadrado)
```

La norma indica explícitamente: *"In the case that s_s^2 < 0, then it is appropriate to use s_s = 0."* No existe valor absoluto en la formulación normativa. El uso de `sqrt(abs(...))` produce un valor positivo ficticio y debe eliminarse.

**Pseudocódigo selector de método robusto:**

```
n = length(datos_participantes)

si n < 12:
    metodo = "MADe/nIQR"
sino:
    metodo = "Algoritmo A"
```

**Entregables de fase:** Funciones corregidas, pseudocódigo documentado, resultados de prueba con datos del informe.

**Criterio de salida:** Los cuatro hallazgos bloqueantes (H1-H4) producen resultados correctos con los datos del informe de revisión.

---

### Fase 2: Arquitectura de datos

**Objetivo:** Eliminar ambigüedad sobre qué datos alimentan cada cálculo.

**Criterio de entrada:** Fase 1 completada.

| # | Tarea | Hallazgo | Entregable | Criterio de aceptación |
|---|-------|----------|------------|----------------------|
| 2.1 | Aislar tres datasets: homogeneidad, estabilidad, participantes | H2, H3 | Modelo de datos con `origen_dato` obligatorio | Ninguna función de dispersión robusta accede a datos de homogeneidad |
| 2.2 | Registrar metadatos por corrida | H2, H3 | Esquema de metadatos | Cada resultado incluye dataset_fuente, serie_usada, n, método, timestamp |
| 2.3 | Crear diccionario de datos | H3 | Documento con campos, tipos y reglas | Serie identificable sin ambigüedad |

**Metadatos mínimos por corrida:**

| Metadato | Descripción |
|----------|-------------|
| `dataset_fuente` | Identificador del archivo o tabla de entrada |
| `serie_usada` | DATOS 1 / DATOS 2 / identificador de serie |
| `n` | Número de datos usados |
| `metodo_robusto` | MADe / nIQR / Algoritmo A |
| `timestamp` | Fecha y hora de la corrida |
| `version_algoritmo` | Versión de las fórmulas implementadas |

**Entregables de fase:** Modelo de datos separado, diccionario de datos, matriz de trazabilidad origen-cálculo-salida.

**Criterio de salida:** Cada resultado estadístico se puede reconstruir desde su dataset de origen sin supuestos implícitos.

---

### Fase 3: Usabilidad y exportación

**Objetivo:** Facilitar validación externa y auditoría técnica.

**Criterio de entrada:** Fase 1 completada. Puede ejecutarse en paralelo con Fase 2.

| # | Tarea | Hallazgo | Entregable | Criterio de aceptación |
|---|-------|----------|------------|----------------------|
| 3.1 | Separar zonas de carga: homogeneidad, estabilidad, participantes | H8 | Interfaz con tres áreas independientes | Usuario distingue claramente qué datos carga en cada zona |
| 3.2 | Exponer tablas de cálculos intermedios | H9 | Vista de datos de entrada, valores intermedios y resultado final | Revisor puede verificar cada paso sin exportar |
| 3.3 | Rediseñar exportación CSV | H7 | Formato con encabezados descriptivos y columnas claras | CSV legible en Excel sin manipulación adicional |

**Entregables de fase:** Interfaz de carga rediseñada, tablas intermedias visibles, formato CSV estandarizado.

**Criterio de salida:** Un revisor externo puede auditar cualquier cálculo desde la interfaz y desde el CSV sin conocimiento previo de la estructura interna.

---

### Fase 4: Validación y cierre

**Objetivo:** Confirmar equivalencia técnica y cerrar formalmente todos los hallazgos.

**Criterio de entrada:** Fases 2 y 3 completadas.

| # | Tarea | Entregable | Criterio de aceptación |
|---|-------|------------|----------------------|
| 4.1 | Construir casos de prueba dorados | Set de datos con n=10, n=11, n=12, radicando negativo, NA | Cobertura de todos los hallazgos críticos |
| 4.2 | Comparación app vs Excel del revisor | Acta de comparación por caso | Diferencias dentro de tolerancia acordada |
| 4.3 | Entregar datos de Algoritmo A al revisor | Exportación de datos de entrada | César puede completar validación del módulo |
| 4.4 | Elaborar acta de cierre | Acta con resultado por hallazgo (H1-H9) | Todos los hallazgos en estado cerrado o condicionado |

**Entregables de fase:** Casos dorados documentados, acta de comparación, acta de cierre con firma del revisor.

**Criterio de salida:** Acta de validación firmada; cada hallazgo del Informe No. 2 tiene estado final documentado.

---

## 7. Priorización consolidada

| Prioridad | Frente | Hallazgo | Justificación |
|-----------|--------|----------|---------------|
| Alta | Fórmula B.10 con radicando negativo | H1 | Compromete la validez del cálculo de homogeneidad |
| Alta | MADe con fuente incorrecta | H2, H3 | Introduce error metodológico en la dispersión robusta |
| Alta | Regla `n >= 12` para Algoritmo A | H4 | Puede producir selección estadística incorrecta |
| Media | Trazabilidad de series y datasets | H2, H3 | Afecta reproducibilidad y auditoría |
| Media | Evidencia de Algoritmo A | H4 | Impide validación externa completa |
| Media | Tablas y exportables de revisión | H7, H8, H9 | Dificulta la evaluación técnica por terceros |

---

## 8. Matriz de riesgos

| # | Riesgo | Probabilidad | Impacto | Control |
|---|--------|-------------|---------|---------|
| R1 | Mezcla de datasets persiste en capas intermedias | Media | Alto | Validación estricta de `origen_dato` y pruebas de aislamiento |
| R2 | Ausencia de dataset patrón para Algoritmo A | Media | Medio | Congelar set dorado antes de iniciar Fase 4 |
| R3 | Despliegue prematuro sin validación cruzada completa | Baja | Crítico | Gate de liberación condicionado a acta firmada |
| R4 | Corrección de fórmulas sin evidencia de validación | Media | Alto | Casos dorados y comparación documentada app vs Excel |
| R5 | Degradación de usabilidad con correcciones técnicas | Baja | Bajo | Pruebas de usabilidad con revisores técnicos |

---

## 9. Cronograma

| Fase | Descripción | Duración | Prioridad | Dependencia |
|------|-------------|----------|-----------|-------------|
| F1 | Correcciones estadísticas | 5 días | Crítica | Acceso al repositorio |
| F2 | Arquitectura de datos | 4 días | Alta | F1 completada |
| F3 | Usabilidad y exportación | 4 días | Media | F1 completada (paralelo a F2) |
| F4 | Validación y cierre | 4 días | Alta | F2 y F3 completadas |
| | **Total** | **15 días hábiles** | | |

**Nota:** F2 y F3 se ejecutan en paralelo tras completar F1, por lo que la ruta crítica es F1 (5d) + F2 (4d) + F4 (4d) = 13 días hábiles. Los 2 días de margen absorben riesgos de coordinación.

---

## 10. Bloqueadores abiertos

1. **Acceso al repositorio:** No se ha confirmado acceso al código fuente del aplicativo (R/Shiny). Bloquea todas las fases.
2. **Datos del Algoritmo A:** César solicitó los datos de entrada que usó el aplicativo en la corrida del Algoritmo A para completar su validación. Bloquea F1.4 y F4.3.
3. **Tolerancia numérica:** No se ha acordado con el revisor el número de cifras significativas aceptable para diferencias de redondeo entre app y Excel. Bloquea F4.2.
4. **Definición de serie de participantes:** Falta definir si para MADe se usa la primera réplica, la segunda o un promedio, y documentarlo como regla fija. Bloquea F1.2 y F2.2.

---

## 11. Criterios globales de aceptación

### Checklist por hallazgo

- [ ] H1: Con radicando negativo en B.10, el aplicativo retorna ss = 0
- [ ] H2: MADe usa exclusivamente datos de participantes
- [ ] H3: La serie de datos usada queda registrada y es correcta por corrida
- [ ] H4: El selector n < 12 / n >= 12 funciona y es verificable
- [ ] H5: nIQR confirmado correcto (sin cambios)
- [ ] H6: Estabilidad confirmada correcta (sin cambios)
- [ ] H7: CSV exportado es legible en Excel sin manipulación
- [ ] H8: Zonas de carga separadas por tipo de dato
- [ ] H9: Tablas intermedias visibles para cada cálculo

### Criterios narrativos

- Con radicando negativo en B.10, el resultado esperado queda definido como `ss = 0`.
- MADe, nIQR y Algoritmo A quedan asociados únicamente a datos de participantes.
- La regla `n < 12` / `n >= 12` queda formulada sin ambigüedad y con escenarios de validación.
- Cada resultado conserva trazabilidad mínima de dataset, serie, corrida y contexto metodológico.
- La validación cruzada puede ejecutarse con evidencia suficiente para comparación externa.
- Las tablas y exportables definidos permiten revisión técnica sin conocimiento implícito del sistema.
- El cierre por hallazgo puede documentarse mediante checklist y acta consolidada.

---

## 12. Condición de salida

Este plan se considerará cumplido cuando exista una especificación final completa que deje resueltos, a nivel documental y funcional, los siguientes aspectos:

- reglas estadísticas corregidas y formalizadas;
- datasets y series definidos sin ambigüedad;
- protocolo de validación técnica listo para ejecución;
- requisitos de auditabilidad y exportación cerrados;
- mecanismos de cierre y transferencia preparados para una etapa posterior de implementación técnica.

La condición se verifica cuando el acta de validación (F4.4) está firmada y cada hallazgo del Informe No. 2 tiene estado final documentado como `cerrado` o `condicionado`.

---

## 13. Anexo: Evidencia numérica de referencia

Valores del Informe No. 2 para MADe, calculados con distintas fuentes:

| Dataset usado | MADe resultante | Observación |
|--------------|----------------|-------------|
| App (fuente no confirmada) | 0.0389 | Valor actual del aplicativo — **incorrecto** |
| Homogeneidad, DATOS 1 | 0.041 | Fuente incorrecta, serie 1 |
| Homogeneidad, DATOS 2 | 0.0473 | Fuente incorrecta, serie 2 |
| Participantes | pendiente | Valor correcto — requiere validación con datos reales |

Estas cifras sirven como ancla para verificar que la corrección de F1.2 produce un valor diferente a 0.0389, consistente con datos de participantes y validable contra el cálculo manual del revisor en Excel.

---

## 14. Referencias normativas

- **ISO 13528:2022** — Métodos estadísticos para ensayos de aptitud por comparación interlaboratorio (Anexo B: Homogeneidad; Sección 9: Estadísticos robustos)
- **ISO 17043:2023** — Evaluación de la conformidad — Requisitos para ensayos de aptitud
- **NTC ISO/IEC 17025:2017** — Requisitos generales para la competencia de laboratorios de ensayo y calibración

---

*Documento generado por consolidación de 8 planes IA. Base: final_opus.md con incorporaciones de cobertura de final_gpt54.md. Fuentes principales por sección: metadatos (Minimax25), evaluación comparativa (GPT54), principios (Opus), hallazgos (Opus), dependencias (Sonnet), estructura de fases (Codex53), tablas de tareas (Minimax25), pseudocódigo (GLM47), priorización (GPT54), riesgos (GPT54/Opus), cronograma (GemFlash3), bloqueadores (Sonnet), criterios de aceptación (GPT54/Opus), condición de salida (GPT54), evidencia numérica (GLM47).*
