# Plan Consolidado de Ajustes — CALAIRE-APP

| Campo | Valor |
|-------|-------|
| Fecha | 2026-03-10 |
| Estado | final |
| Fuente principal | `docs/ajustes_app/Revisión aplicativo estadístico.pdf` |
| Documento estructural de contraste | `docs/ajustes_app/final_opus.md` |
| Documento rector de enfoque | `docs/ajustes_app/final_gpt54.md` |
| Alcance | consolidación metodológica, funcional y documental previa a una futura implementación técnica |
| Restricción de alcance | este documento no revisa ni modifica la codebase del aplicativo |

---

## 1. Objetivo y alcance

Este documento presenta una versión equivalente en estructura a `final_opus.md`, pero alineada en propósito, criterios y orientación con `final_gpt54.md`. Su función es dejar un paquete de especificación claro, consistente y transferible para una etapa posterior de implementación técnica del aplicativo estadístico, sin asumir que dicha implementación ocurre en esta fase.

**Incluye:** formalización de reglas estadísticas, definición de fuentes de datos, trazabilidad mínima por corrida, diseño del protocolo de validación, requisitos de auditabilidad y mecanismos de cierre por hallazgo. **Excluye:** revisión directa de la codebase, desarrollo en R/Shiny, pruebas automatizadas, despliegue e infraestructura.

---

## 2. Principios de ejecución

1. La validez estadística prevalece sobre cualquier mejora de interfaz.
2. Ningún hallazgo se considerará resuelto sin evidencia reproducible.
3. Todo resultado debe poder rastrearse hasta su dataset, serie y contexto de cálculo.
4. La validación externa debe poder ejecutarse con insumos comprensibles y sin supuestos ocultos.
5. La futura implementación técnica solo podrá iniciarse cuando las definiciones funcionales y documentales aquí descritas estén cerradas.

---

## 3. Clasificación de hallazgos

| # | Componente | Veredicto consolidado | Severidad | Frente |
|---|-----------|-----------------------|-----------|--------|
| H1 | Fórmula B.10 (homogeneidad) | Requiere regla operativa inequívoca para radicando negativo | Alta | Reglas estadísticas |
| H2 | MADe con fuente de datos incorrecta | Requiere reasignación a datos de participantes | Alta | Reglas estadísticas |
| H3 | Ambigüedad en serie utilizada (`DATOS 1` / `DATOS 2`) | Requiere trazabilidad obligatoria por corrida | Media | Datos y trazabilidad |
| H4 | Regla metodológica por tamaño muestral | Requiere formalización del umbral `n >= 12` | Alta | Reglas estadísticas |
| H5 | Validación del Algoritmo A | Requiere evidencia suficiente para contraste externo | Media | Validación |
| H6 | Carga, tablas y exportables | Requiere rediseño funcional para auditabilidad | Media | Auditabilidad |

**Nota de consolidación:** esta versión agrupa los hallazgos técnicos en seis frentes de intervención, siguiendo el marco de síntesis adoptado en `final_gpt54.md`. Los componentes que el revisor consideró correctos no se tratan como frentes de rediseño, pero sí como referencias para evitar retrabajo metodológico.

---

## 4. Diagrama de dependencias

```text
F1 Reglas estadísticas
 |
 +--> F2 Datos y trazabilidad --> F5 Cierre y transferencia
 |                                  ^
 |                                  |
 +--> F3 Validación técnica ---------+
 |
 +--> F4 Auditabilidad y exportables-+
```

F1 es prerrequisito conceptual de las demás fases. F2, F3 y F4 pueden desarrollarse en paralelo una vez cerradas las reglas. F5 depende de la consolidación de las fases anteriores.

---

## 5. Fases de implementación futura

### Fase 1: Consolidación normativa y reglas estadísticas

**Objetivo:** convertir los hallazgos del informe en reglas funcionales inequívocas y listas para futura implementación.

| # | Tarea | Frente | Entregable | Criterio de aceptación |
|---|-------|--------|------------|------------------------|
| 1.1 | Formalizar la regla B.10 para radicando negativo | H1 | Regla funcional documentada | Queda explícito que `ss = 0` cuando el radicando es negativo |
| 1.2 | Establecer que MADe, nIQR y Algoritmo A usan datos de participantes | H2 | Regla de origen de datos | Ningún estimador robusto queda asociado a homogeneidad |
| 1.3 | Definir la regla de selección metodológica por tamaño muestral | H4 | Regla `n < 12` / `n >= 12` documentada | El umbral queda formulado sin ambigüedad |
| 1.4 | Precisar qué se considera dato válido para el conteo de `n` | H4 | Criterio documental de conteo | El conteo de participantes es trazable y verificable |

**Referencia funcional B.10:**

```text
ss_cuadrado = (1/(g-1)) * SUM((x_t - x_bar)^2) - (1/m) * sw^2

si ss_cuadrado < 0:
    ss = 0
sino:
    ss = sqrt(ss_cuadrado)
```

**Referencia funcional de selección metodológica:**

```text
si n < 12:
    metodo = "estimador robusto aplicable"
sino:
    metodo = "Algoritmo A"
```

**Entregables de fase:** especificación funcional de reglas estadísticas y matriz hallazgo -> regla -> criterio técnico.

**Criterio de salida:** cada regla queda redactada sin ambigüedad y preparada para servir como base de implementación futura.

---

### Fase 2: Modelo de datos y trazabilidad

**Objetivo:** eliminar mezcla de fuentes y asegurar reconstrucción íntegra de cada cálculo.

| # | Tarea | Frente | Entregable | Criterio de aceptación |
|---|-------|--------|------------|------------------------|
| 2.1 | Separar datasets de homogeneidad, estabilidad y participantes | H2, H3 | Esquema documental de datasets | Cada cálculo tiene origen de datos explícito |
| 2.2 | Formalizar identificación de series por corrida | H3 | Regla de trazabilidad de series | `DATOS 1`, `DATOS 2` u otras variantes quedan registradas sin ambigüedad |
| 2.3 | Definir metadatos mínimos por resultado | H3 | Diccionario de metadatos | Todo resultado conserva contexto mínimo de reconstrucción |
| 2.4 | Construir matriz origen -> cálculo -> salida | H2, H3 | Matriz de trazabilidad | Puede reconstruirse el flujo completo sin supuestos implícitos |

**Metadatos mínimos por resultado:**

| Metadato | Descripción |
|----------|-------------|
| `dataset_fuente` | origen documental o tabla de entrada |
| `serie_usada` | serie aplicada en la corrida |
| `analito` | magnitud o componente evaluado |
| `n` | número de datos válidos usados |
| `metodo` | método estadístico aplicado |
| `fecha_calculo` | fecha de ejecución o referencia |
| `version_metodologica` | versión de la regla funcional utilizada |

**Entregables de fase:** diccionario de datos y matriz de trazabilidad de cálculos y resultados.

**Criterio de salida:** todo resultado puede rastrearse hasta su dataset, su serie y su contexto metodológico sin interpretación adicional.

---

### Fase 3: Protocolo de validación técnica

**Objetivo:** diseñar la verificación independiente que confirmará la corrección técnica de los ajustes futuros.

| # | Tarea | Frente | Entregable | Criterio de aceptación |
|---|-------|--------|------------|------------------------|
| 3.1 | Diseñar caso de validación para B.10 con radicando negativo | H1 | Caso de prueba documentado | Se puede verificar la salida esperada `ss = 0` |
| 3.2 | Diseñar caso de validación para MADe con datos de participantes | H2 | Caso de prueba documentado | El origen correcto del dato queda verificable |
| 3.3 | Diseñar escenarios de borde con `n = 11` y `n = 12` | H4 | Casos de decisión metodológica | El umbral se valida con escenarios explícitos |
| 3.4 | Definir caso específico para Algoritmo A con evidencia suficiente | H5 | Caso de validación externa | Se dispone de entradas, pasos y salida esperada |
| 3.5 | Incorporar condiciones de datos faltantes, fuente errónea y serie incorrecta | H2, H3, H5 | Matriz de escenarios | Los errores de trazabilidad quedan cubiertos |

**Entregables de fase:** matriz de casos de validación, formato de comparación observado vs esperado y protocolo de validación cruzada App vs referencia externa.

**Criterio de salida:** cada hallazgo crítico dispone de al menos un caso de validación independiente y de un criterio explícito de aceptación.

---

### Fase 4: Auditabilidad, tablas y exportación

**Objetivo:** asegurar que la futura solución pueda ser revisada por terceros sin acceso al código.

| # | Tarea | Frente | Entregable | Criterio de aceptación |
|---|-------|--------|------------|------------------------|
| 4.1 | Definir separación funcional de la carga de datos | H6 | Requisito funcional de carga diferenciada | Homogeneidad, estabilidad y participantes permanecen separados |
| 4.2 | Especificar tablas mínimas de revisión | H6 | Especificación de tablas | Entradas, intermedios y resultados quedan visibles |
| 4.3 | Definir formato de exportación legible y reproducible | H6 | Especificación de exportables | La revisión externa puede hacerse en Excel sin ambigüedad |
| 4.4 | Establecer encabezados, columnas y metadatos mínimos | H5, H6 | Estructura mínima de salida | La selección metodológica y el contexto del cálculo quedan visibles |

**Entregables de fase:** especificación de tablas de revisión, especificación funcional de exportables de auditoría y requisitos mínimos de visualización.

**Criterio de salida:** un tercero puede reconstruir y revisar técnicamente los cálculos a partir de las salidas definidas.

---

### Fase 5: Cierre, evaluación final y transferencia a implementación

**Objetivo:** consolidar un paquete documental único y dejar definidos los prerrequisitos para una etapa posterior de desarrollo técnico.

| # | Tarea | Frente | Entregable | Criterio de aceptación |
|---|-------|--------|------------|------------------------|
| 5.1 | Integrar reglas, datos, validaciones y requisitos de auditabilidad | Todos | Paquete documental unificado | No quedan vacíos funcionales críticos |
| 5.2 | Clasificar cada hallazgo como `cerrado`, `pendiente` o `condicionado` | Todos | Matriz de estado por hallazgo | Cada frente tiene estado documental explícito |
| 5.3 | Consolidar riesgos residuales y dependencias externas | Todos | Registro de riesgos y dependencias | Los bloqueadores quedan formalmente identificados |
| 5.4 | Definir prerrequisitos para futura implementación técnica | Todos | Documento de transferencia | Un equipo técnico puede iniciar implementación sin redefinir criterios base |
| 5.5 | Formalizar mecanismo de cierre mediante checklist y acta | Todos | Checklist y acta de validación | El cierre puede documentarse de forma verificable |

**Entregables de fase:** checklist de cierre técnico, acta de validación consolidada y documento de prerrequisitos para implementación futura.

**Criterio de salida:** existe un paquete documental único, consistente y transferible que puede ser usado por un equipo técnico sin vacíos funcionales críticos.

---

## 6. Matriz de riesgos

| # | Riesgo | Probabilidad | Impacto | Control |
|---|--------|-------------|---------|---------|
| R1 | Persistencia de mezcla entre datasets | Media | Alto | Regla obligatoria de origen y matriz de trazabilidad |
| R2 | Cierre sin validación externa suficiente | Media | Alto | Casos de validación y comparación documentada |
| R3 | Ambigüedad en series utilizadas por corrida | Media | Medio | Registro obligatorio de serie y contexto metodológico |
| R4 | Exportables poco claros para revisión técnica | Media | Medio | Especificación mínima de tablas, columnas y metadatos |
| R5 | Inicio prematuro de implementación sin cierre metodológico | Baja | Crítico | Gate documental antes de abrir fase técnica |

---

## 7. Secuencia recomendada

| Fase | Descripción | Prioridad | Dependencia |
|------|-------------|-----------|-------------|
| F1 | Consolidación normativa y reglas estadísticas | Crítica | Fuente base validada |
| F2 | Modelo de datos y trazabilidad | Alta | F1 completada |
| F3 | Protocolo de validación técnica | Alta | F1 completada |
| F4 | Auditabilidad, tablas y exportación | Media | F1 completada |
| F5 | Cierre y transferencia a implementación | Alta | F2, F3 y F4 completadas |

**Nota:** esta secuencia no representa ejecución sobre codebase, sino orden recomendado de cierre documental y funcional previo a una futura intervención técnica.

---

## 8. Dependencias y bloqueadores abiertos

1. **Datos de referencia para Algoritmo A:** se requiere evidencia suficiente de entradas, pasos y salidas esperadas para viabilizar validación externa completa.
2. **Tolerancias numéricas de comparación:** debe quedar acordado el criterio aceptable de diferencia frente a Excel u otra referencia externa.
3. **Regla definitiva de serie por corrida:** es necesario fijar documentalmente cómo se identifica la serie válida para cada cálculo.
4. **Acceso posterior al repositorio:** la futura implementación técnica dependerá de que se habilite acceso al aplicativo cuando esta fase metodológica haya concluido.

---

## 9. Lista de aceptación

- [ ] La regla B.10 queda definida con salida `ss = 0` para radicando negativo
- [ ] MADe, nIQR y Algoritmo A quedan asociados únicamente a datos de participantes
- [ ] La regla `n < 12` / `n >= 12` queda formulada sin ambigüedad
- [ ] Cada resultado conserva trazabilidad mínima de dataset, serie y contexto metodológico
- [ ] Existe protocolo de validación independiente para los hallazgos críticos
- [ ] Las tablas y exportables permiten revisión externa sin interpretación informal
- [ ] Cada hallazgo puede cerrarse mediante checklist y acta consolidada

---

## 10. Referencias base

- `docs/ajustes_app/Revisión aplicativo estadístico.pdf`
- `docs/ajustes_app/final_opus.md`
- `docs/ajustes_app/final_gpt54.md`
- `docs/ajustes_app/gpt54_plan.md`
- `docs/ajustes_app/opus_plan.md`
- `logs/plans/260228_2000_plan_implementacion-calaire-app-revision2-final.md`

---

## 11. Anexo: criterio de equivalencia documental

Esta versión conserva el formato operativo de `final_opus.md` para facilitar lectura ejecutiva, pero reemplaza su sesgo de implementación inmediata por el encuadre de consolidación metodológica adoptado en `final_gpt54.md`. En consecuencia:

- las fases se interpretan como cierre documental y funcional previo a desarrollo;
- los entregables se expresan como especificaciones, matrices y criterios de validación;
- la condición de salida no es una corrección ya implementada, sino un paquete listo para transferencia a implementación futura.
