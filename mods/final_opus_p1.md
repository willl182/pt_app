# Plan Consolidado de Ajustes — CALAIRE-APP

| Campo | Valor |
|-------|-------|
| Fecha | 2026-03-09 |
| Estado | final |
| Origen | Informe No. 2 de revision (Cesar Yate, 2026-02-23) |
| Planes fuente | codex53, gemflash3, gempro31, glm47, gpt54, minimax25, opus, sonnet |
| Norma principal | ISO 13528:2022 — Metodos estadisticos para ensayos de aptitud |

---

## 1. Objetivo y alcance

Este plan consolida ocho propuestas independientes generadas por distintos modelos IA, todas basadas en el mismo informe de revision que identifico nueve hallazgos (H1-H9) en la aplicacion estadistica R/Shiny CALAIRE-APP. El proposito es definir una ruta unica de implementacion que corrija los errores estadisticos, elimine la ambiguedad en las fuentes de datos y mejore la auditabilidad del aplicativo.

**Incluye:** correccion de formulas estadisticas (B.10, MADe, selector de metodo robusto), separacion formal de datasets, rediseno de carga y exportacion, protocolo de validacion cruzada y cierre documental de hallazgos. **Excluye:** revision directa de la codebase, despliegue, pruebas automatizadas e infraestructura.

---

## 2. Principios de ejecucion

1. La correccion estadistica prevalece sobre cualquier mejora de interfaz.
2. Ningun hallazgo se considerara resuelto sin evidencia reproducible.
3. Todo resultado debe declarar de forma explicita el dataset, la serie y la corrida de los que proviene.
4. La validacion externa debe poder ejecutarse sin interpretar supuestos ocultos.
5. La separacion entre datos de homogeneidad, estabilidad y participantes debe quedar formalmente establecida antes de cualquier calculo.

---

## 3. Clasificacion de hallazgos

| # | Componente | Veredicto | Severidad | Fase |
|---|-----------|-----------|-----------|------|
| H1 | Formula B.10 (homogeneidad) — `sqrt(abs(...))` en vez de condicional | ERROR | Bloqueante | F1 |
| H2 | MADe — calcula con datos de homogeneidad en vez de participantes | ERROR | Bloqueante | F1 |
| H3 | MADe — usa serie DATOS 1 cuando correspondia DATOS 2 | ERROR | Bloqueante | F1 |
| H4 | Selector MADe/nIQR vs Algoritmo A por tamano muestral | PENDIENTE | Bloqueante | F1 |
| H5 | nIQR | OK | — | — |
| H6 | Estabilidad | OK | — | — |
| H7 | Exportacion CSV — formato confuso e ilegible | DEFICIENTE | Media | F3 |
| H8 | Interfaz de carga — sin separacion de zonas | DEFICIENTE | Media | F3 |
| H9 | Tablas de calculos intermedios — no accesibles | DEFICIENTE | Media | F3 |

**Nota:** H5 y H6 fueron verificados como correctos por el revisor y no requieren intervencion.

**Resolucion del umbral muestral:** La ISO 13528:2022 Seccion 9 establece que el Algoritmo A se aplica cuando n >= 12 participantes. Valores menores usan MADe o nIQR. El umbral correcto es n >= 12 (no n > 10 como aparece en alguno de los planes fuente).

---

## 4. Diagrama de dependencias

```
F1 Correcciones estadisticas
 |
 +--> F2 Arquitectura de datos --> F4 Validacion y cierre
 |                                       ^
 |                                       |
 +--- F3 Usabilidad y exportacion -------+
      (paralelo a F2)
```

F1 es prerequisito de F2 y F3. F3 puede ejecutarse en paralelo con F2. F4 requiere que F2 y F3 esten completas.

---

## 5. Fases de implementacion

### Fase 1: Correcciones estadisticas

**Objetivo:** Eliminar errores que invalidan resultados tecnicos.

**Criterio de entrada:** Acceso al repositorio del aplicativo (R/Shiny).

| # | Tarea | Hallazgo | Entregable | Criterio de aceptacion |
|---|-------|----------|------------|----------------------|
| 1.1 | Corregir formula B.10 — condicional para radicando negativo | H1 | Logica corregida y documentada | Con radicando negativo, ss = 0 |
| 1.2 | Redirigir MADe a dataset de participantes | H2 | Funcion corregida | MADe coincide con calculo manual del revisor |
| 1.3 | Asegurar seleccion de serie correcta (DATOS 1 / DATOS 2) | H3 | Selector de serie con registro en metadatos | Serie usada queda trazada por corrida |
| 1.4 | Implementar selector de metodo robusto por n | H4 | Switch n < 12 / n >= 12 | n=11 usa MADe/nIQR; n=12 usa Algoritmo A |

**Pseudocodigo B.10 (ISO 13528:2022 Anexo B):**

```
ss_cuadrado = (1/(g-1)) * SUM((x_t - x_bar)^2) - (1/m) * sw^2

si ss_cuadrado < 0:
    ss = 0
sino:
    ss = sqrt(ss_cuadrado)
```

La norma indica explicitamente: *"In the case that s_s^2 < 0, then it is appropriate to use s_s = 0."* No existe valor absoluto en la formulacion normativa. El uso de `sqrt(abs(...))` produce un valor positivo ficticio y debe eliminarse.

**Pseudocodigo selector de metodo robusto:**

```
n = length(datos_participantes)

si n < 12:
    metodo = "MADe/nIQR"
sino:
    metodo = "Algoritmo A"
```

**Entregables de fase:** Funciones corregidas, pseudocodigo documentado, resultados de prueba con datos del informe.

**Criterio de salida:** Los cuatro hallazgos bloqueantes (H1-H4) producen resultados correctos con los datos del informe de revision.

---

### Fase 2: Arquitectura de datos

**Objetivo:** Eliminar ambiguedad sobre que datos alimentan cada calculo.

**Criterio de entrada:** Fase 1 completada.

| # | Tarea | Hallazgo | Entregable | Criterio de aceptacion |
|---|-------|----------|------------|----------------------|
| 2.1 | Aislar tres datasets: homogeneidad, estabilidad, participantes | H2, H3 | Modelo de datos con `origen_dato` obligatorio | Ninguna funcion de dispersion robusta accede a datos de homogeneidad |
| 2.2 | Registrar metadatos por corrida | H2, H3 | Esquema de metadatos | Cada resultado incluye dataset_fuente, serie_usada, n, metodo, timestamp |
| 2.3 | Crear diccionario de datos | H3 | Documento con campos, tipos y reglas | Serie identificable sin ambiguedad |

**Metadatos minimos por corrida:**

| Metadato | Descripcion |
|----------|-------------|
| `dataset_fuente` | Identificador del archivo o tabla de entrada |
| `serie_usada` | DATOS 1 / DATOS 2 / identificador de serie |
| `n` | Numero de datos usados |
| `metodo_robusto` | MADe / nIQR / Algoritmo A |
| `timestamp` | Fecha y hora de la corrida |
| `version_algoritmo` | Version de las formulas implementadas |

**Entregables de fase:** Modelo de datos separado, diccionario de datos, matriz de trazabilidad origen-calculo-salida.

**Criterio de salida:** Cada resultado estadistico se puede reconstruir desde su dataset de origen sin supuestos implicitos.

---

### Fase 3: Usabilidad y exportacion

**Objetivo:** Facilitar validacion externa y auditoria tecnica.

**Criterio de entrada:** Fase 1 completada. Puede ejecutarse en paralelo con Fase 2.

| # | Tarea | Hallazgo | Entregable | Criterio de aceptacion |
|---|-------|----------|------------|----------------------|
| 3.1 | Separar zonas de carga: homogeneidad, estabilidad, participantes | H8 | Interfaz con tres areas independientes | Usuario distingue claramente que datos carga en cada zona |
| 3.2 | Exponer tablas de calculos intermedios | H9 | Vista de datos de entrada, valores intermedios y resultado final | Revisor puede verificar cada paso sin exportar |
| 3.3 | Redisenar exportacion CSV | H7 | Formato con encabezados descriptivos y columnas claras | CSV legible en Excel sin manipulacion adicional |

**Entregables de fase:** Interfaz de carga rediseñada, tablas intermedias visibles, formato CSV estandarizado.

**Criterio de salida:** Un revisor externo puede auditar cualquier calculo desde la interfaz y desde el CSV sin conocimiento previo de la estructura interna.

---

### Fase 4: Validacion y cierre

**Objetivo:** Confirmar equivalencia tecnica y cerrar formalmente todos los hallazgos.

**Criterio de entrada:** Fases 2 y 3 completadas.

| # | Tarea | Entregable | Criterio de aceptacion |
|---|-------|------------|----------------------|
| 4.1 | Construir casos de prueba dorados | Set de datos con n=10, n=11, n=12, radicando negativo, NA | Cobertura de todos los hallazgos criticos |
| 4.2 | Comparacion app vs Excel del revisor | Acta de comparacion por caso | Diferencias dentro de tolerancia acordada |
| 4.3 | Entregar datos de Algoritmo A al revisor | Exportacion de datos de entrada | Cesar puede completar validacion del modulo |
| 4.4 | Elaborar acta de cierre | Acta con resultado por hallazgo (H1-H9) | Todos los hallazgos en estado cerrado o condicionado |

**Entregables de fase:** Casos dorados documentados, acta de comparacion, acta de cierre con firma del revisor.

**Criterio de salida:** Acta de validacion firmada; cada hallazgo del Informe No. 2 tiene estado final documentado.

---

## 6. Matriz de riesgos

| # | Riesgo | Probabilidad | Impacto | Control |
|---|--------|-------------|---------|---------|
| R1 | Mezcla de datasets persiste en capas intermedias | Media | Alto | Validacion estricta de `origen_dato` y pruebas de aislamiento |
| R2 | Ausencia de dataset patron para Algoritmo A | Media | Medio | Congelar set dorado antes de iniciar Fase 4 |
| R3 | Despliegue prematuro sin validacion cruzada completa | Baja | Critico | Gate de liberacion condicionado a acta firmada |
| R4 | Correccion de formulas sin evidencia de validacion | Media | Alto | Casos dorados y comparacion documentada app vs Excel |
| R5 | Degradacion de usabilidad con correcciones tecnicas | Baja | Bajo | Pruebas de usabilidad con revisores tecnicos |

---

## 7. Cronograma

| Fase | Descripcion | Duracion | Prioridad | Dependencia |
|------|-------------|----------|-----------|-------------|
| F1 | Correcciones estadisticas | 5 dias | Critica | Acceso al repositorio |
| F2 | Arquitectura de datos | 4 dias | Alta | F1 completada |
| F3 | Usabilidad y exportacion | 4 dias | Media | F1 completada (paralelo a F2) |
| F4 | Validacion y cierre | 4 dias | Alta | F2 y F3 completadas |
| | **Total** | **15 dias habiles** | | |

**Nota:** F2 y F3 se ejecutan en paralelo tras completar F1, por lo que la ruta critica es F1 (5d) + F2 (4d) + F4 (4d) = 13 dias habiles. Los 2 dias de margen absorben riesgos de coordinacion.

---

## 8. Bloqueadores abiertos

1. **Acceso al repositorio:** No se ha confirmado acceso al codigo fuente del aplicativo (R/Shiny). Bloquea todas las fases.
2. **Datos del Algoritmo A:** Cesar solicito los datos de entrada que uso el aplicativo en la corrida del Algoritmo A para completar su validacion. Bloquea F1.4 y F4.3.
3. **Tolerancia numerica:** No se ha acordado con el revisor el numero de cifras significativas aceptable para diferencias de redondeo entre app y Excel. Bloquea F4.2.
4. **Definicion de serie de participantes:** Falta definir si para MADe se usa la primera replica, la segunda o un promedio, y documentarlo como regla fija. Bloquea F1.2 y F2.2.

---

## 9. Lista de aceptacion

- [ ] H1: Con radicando negativo en B.10, el aplicativo retorna ss = 0
- [ ] H2: MADe usa exclusivamente datos de participantes
- [ ] H3: La serie de datos usada queda registrada y es correcta por corrida
- [ ] H4: El selector n < 12 / n >= 12 funciona y es verificable
- [ ] H5: nIQR confirmado correcto (sin cambios)
- [ ] H6: Estabilidad confirmada correcta (sin cambios)
- [ ] H7: CSV exportado es legible en Excel sin manipulacion
- [ ] H8: Zonas de carga separadas por tipo de dato
- [ ] H9: Tablas intermedias visibles para cada calculo

---

## 10. Referencias normativas

- **ISO 13528:2022** — Metodos estadisticos para ensayos de aptitud por comparacion interlaboratorio (Anexo B: Homogeneidad; Seccion 9: Estadisticos robustos)
- **ISO 17043:2023** — Evaluacion de la conformidad — Requisitos para ensayos de aptitud
- **NTC ISO/IEC 17025:2017** — Requisitos generales para la competencia de laboratorios de ensayo y calibracion

---

## 11. Anexo: Evidencia numerica de referencia

Valores del Informe No. 2 para MADe, calculados con distintas fuentes:

| Dataset usado | MADe resultante | Observacion |
|--------------|----------------|-------------|
| App (fuente no confirmada) | 0.0389 | Valor actual del aplicativo — **incorrecto** |
| Homogeneidad, DATOS 1 | 0.041 | Fuente incorrecta, serie 1 |
| Homogeneidad, DATOS 2 | 0.0473 | Fuente incorrecta, serie 2 |
| Participantes | pendiente | Valor correcto — requiere validacion con datos reales |

Estas cifras sirven como ancla para verificar que la correccion de F1.2 produce un valor diferente a 0.0389, consistente con datos de participantes y validable contra el calculo manual del revisor en Excel.

---

*Documento generado por consolidacion de 8 planes IA. Fuentes principales por seccion: metadatos (Minimax25), principios (GPT54), hallazgos (Opus), dependencias (Sonnet), estructura de fases (Codex53), tablas de tareas (Minimax25), pseudocodigo (GLM47), riesgos (GPT54), cronograma (GemFlash3), bloqueadores (Sonnet), aceptacion (Sonnet), evidencia numerica (GLM47).*
