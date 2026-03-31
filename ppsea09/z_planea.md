### Resumen rápido

Planificar un ensayo de aptitud (PT) basado en ISO/IEC 17043 significa diseñar y documentar, antes de lanzar la ronda, **qué se va a evaluar, cómo, con qué ítems, con qué método estadístico y cómo se va a garantizar la calidad de los materiales**. La norma exige que el proveedor de PT tenga un **plan documentado del programa** (objetivos, diseño, estadística, logística, etc.) y que lo valide con estudios de homogeneidad, estabilidad y caracterización del ítem, apoyándose para lo estadístico en la norma ISO 13528.【turn6search1】【turn0search16】

---

## 1. Marco normativo clave

- **ISO/IEC 17043:2023** – “Evaluación de la conformidad — Requisitos generales para la competencia de los proveedores de ensayos de aptitud”. Define requisitos de gestión y técnicos para quien organiza los PT.【turn0search1】
- **ISO 13528:2022** – “Métodos estadísticos utilizados en los ensayos de aptitud por comparación interlaboratorio”. Es la norma de apoyo para el **diseño estadístico** y el análisis de datos de PT.【turn0search16】【turn6search2】
- **ILAC G13 / G8** – Guías de ILAC para proveedores de PT y para la selección y uso de ensayos de aptitud (muy usadas como referencia por los organismos de acreditación).【turn0search12】【turn0search7】

---

## 2. ¿Qué exige ISO 17043 sobre la planificación?

ISO 17043 no da una “receta” paso a paso, pero sí exige que el proveedor de PT:

1. **Documente un plan del programa de ensayos de aptitud** que incluya:
   - Objetivos y alcance del PT.
   - Diseño general del esquema (número de rondas, niveles, tipo de ítems, etc.).
   - Criterios de evaluación del desempeño.
   - Aspectos logísticos y de comunicación con participantes.【turn6search1】

2. **Diseñe el programa de PT de forma sistemática**, incluyendo:
   - Selección y preparación de los **ítems de ensayo de aptitud** (muestras, objetos, etc.).
   - Estudios de **homogeneidad y estabilidad** de los ítems.
   - Determinación del **valor asignado** y su incertidumbre.
   - Elección de los **métodos estadísticos** y criterios de desempeño (z‑score, z’‑score, etc.), coherentes con los objetivos.【turn0search16】【turn6search3】

3. **Valide el diseño**:
   - Demostrando que los ítems son adecuados para el propósito.
   - Asegurando que el diseño estadístico es capaz de detectar diferencias de interés en el desempeño de los laboratorios.【turn6search2】

En la práctica, todo esto se materializa en un **plan de ensayo de aptitud** y en los procedimientos/registros asociados.

---

## 3. Proceso de planificación de un ensayo de aptitud (visión general)

Un flujo típico de planificación podría verse así:

```mermaid
flowchart LR
  A[Definir objetivos del PT] --> B[Diseño del programa]
  B --> C[Definir ítems de ensayo y caracteristicas]
  C --> D[Homogeneidad y estabilidad]
  D --> E[Definir valor asignado e incertidumbre]
  E --> F[Diseño estadístico y criterios de evaluacion]
  F --> G[Plan logistico y de comunicacion]
  G --> H[Revision y validacion del plan]
  H --> I[Ejecucion de la ronda]
```

A continuación se detalla cada bloque.

---

## 4. Etapas clave en la planificación

### 4.1. Definir objetivos y alcance del PT

Antes de cualquier decisión técnica, el proveedor debe dejar claro:

- **Objetivo principal**:
  - Evaluar el desempeño de laboratorios para un ensayo/medición concreto.
  - Comparar métodos, validar nuevos métodos, etc.【turn0search19】
- **Tipo de PT**:
  - Cuantitativo (concentración, valor numérico).
  - Cualitativo (presencia/ausencia, identificación).
  - Secuencial (una ronda tras otra).
- **Población objetivo**:
  - Tipo de laboratorios (clínicos, ambientales, calibración, etc.).
  - Número esperado de participantes (esto influye en el diseño estadístico).
- **Área de ensayo/medición**:
  - Parámetro, matriz, rango de medida, incertidumbre esperada, etc.

ISO 13528 recuerda que el **diseño estadístico debe ser coherente con los objetivos** del PT; no es lo mismo un PT para vigilancia continua que un PT para validar un método nuevo.【turn6search1】

---

### 4.2. Diseño general del programa de PT

Aquí se definen las “reglas de juego” del esquema:

- **Estructura del programa**:
  - Número de rondas por año (frecuencia).
  - Número de niveles/ítems por ronda (por ejemplo, bajo/medio/alto).
  - Si se incluyen muestras duplicadas o ciegas.
- **Criterios de inclusión/exclusión** de participantes.
- **Requisitos para los participantes**:
  - Métodos a usar (método normalizado o de libre elección).
  - Condiciones de ensayo (repeticiones, tratamiento de muestras).
- **Confidencialidad y código de identificación** de laboratorios.

Estos elementos suelen recogerse en un **plan del programa** que el proveedor debe mantener actualizado.【turn6search1】

---

### 4.3. Definición y preparación de los ítems de ensayo de aptitud

ISO 17043 presta mucha atención a los **ítems de PT** (muestras, objetos, materiales de referencia):

1. **Selección del tipo de ítem**:
   - Matriz representativa (agua, suelo, sangre, etc.).
   - Nivel del analito adecuado al rango de interés.
   - Estabilidad suficiente para el período de la ronda.

2. **Preparación y control**:
   - Procedimientos de preparación (mezcla, spiking, homogeneización).
   - Documentación de lotes y cantidades.

3. **Estudios de homogeneidad**:
   - Verificar que los ítems dentro del lote son **suficientemente iguales** para que las diferencias entre laboratorios no se deban a la muestra misma.
   - Se realizan ensayos a una muestra representativa del lote, con réplicas, y se compara la variabilidad entre ítems con la variabilidad esperada del método.【turn0search0】

4. **Estudios de estabilidad**:
   - A corto plazo (transporte, condiciones de envío).
   - A largo plazo (almacenamiento hasta la fecha de cierre de la ronda).
   - Se evalúa si el valor del analito se mantiene dentro de límites aceptables.【turn0search0】

5. **Caracterización del ítem**:
   - Determinación del **valor asignado** (valor de referencia) y su **incertidumbre**, mediante:
     - Laboratorios de referencia.
     - Comparación interlaboratorio (valores consenso).
     - Materiales de referencia certificados u otros métodos robustos.【turn0search16】

Todo esto debe estar documentado en informes/registros que forman parte del plan del PT.

---

### 4.4. Diseño estadístico y criterios de evaluación

Aquí es donde ISO 13528 se vuelve esencial. El proveedor debe:

1. **Elegir el diseño estadístico**:
   - Tipo de esquema (interlaboratorio, secuencial, etc.).
   - Modelo para el valor asignado y la desviación estándar para la evaluación (σ_PT o SDPA).
   - Métodos robustos para minimizar el efecto de valores atípicos.【turn0search16】

2. **Definir el valor asignado (X)** y su incertidumbre (u_X):
   - Puede ser:
     - Valor de un material de referencia certificado.
     - Valor consenso de laboratorios de referencia.
     - Valor consenso de los participantes (con métodos robustos).
   - La incertidumbre del valor asignado debe evaluarse y, si no es despreciable, considerarse en la evaluación (por ejemplo, usando z’‑score).【turn0search16】【turn6search4】

3. **Definir la desviación estándar para la evaluación (σ_PT)**:
   - Puede basarse en:
     - Requisitos de desempeño (normas, clientes, reguladores).
     - Datos históricos del PT.
     - Modelo de reproducibilidad del método.
   - Debe ser coherente con lo que se considera un “desempeño aceptable”.【turn0search16】

4. **Definir los scores y criterios de desempeño**:
   - **z‑score**:  
     \[
     z = \frac{x - X}{\sigma_{PT}}
     \]
     - |z| ≤ 2 → satisfactorio  
     - 2 < |z| < 3 → cuestionable  
     - |z| ≥ 3 → insatisfactorio  
   - **z’‑score** (cuando la incertidumbre del valor asignado no es despreciable).【turn6search4】
   - Otros: E_n (para calibraciones), rango, porcentaje de desviación, etc.

5. **Definir cómo se tratarán los resultados anómalos y los valores extremos**:
   - Uso de métodos robustos (Algoritmo A, etc.), según ISO 13528.【turn0search16】

6. **Establecer procedimientos para la interpretación de los resultados**:
   - Cómo se clasificará a los laboratorios (satisfactorio/cuestionable/insatisfactorio).
   - Qué acciones se recomiendan en cada caso.

ISO 13528 subraya que el **diseño estadístico debe estar documentado** y ser consistente con los objetivos del PT.【turn6search1】【turn6search2】

---

### 4.5. Plan logístico y de comunicación

La parte más “visible” de la planificación:

1. **Cronograma de la ronda**:
   - Fecha de envío de ítems.
   - Período de realización de ensayos por los laboratorios.
   - Fecha límite de recepción de resultados.
   - Fecha prevista de emisión del informe de resultados.

2. **Instrucciones a participantes**:
   - Cómo almacenar y manipular las muestras.
   - Método(s) a utilizar.
   - Número de repeticiones.
   - Formato de reporte de resultados (unidades, cifras significativas, incertidumbre, etc.).

3. **Logística de envío**:
   - Embalaje y condiciones de transporte (temperatura, tiempos).
   - Control de envíos y recepción.

4. **Gestión de datos**:
   - Sistema de registro de resultados.
   - Respaldo y seguridad de la información.
   - Protección de la confidencialidad de los participantes.

5. **Plan de comunicación**:
   - Canales para consultas.
   - Aviso de cambios o incidencias durante la ronda.

---

### 4.6. Revisión y validación del plan

Antes de lanzar la ronda, el proveedor debe revisar y aprobar el plan, asegurándose de que:

- Los objetivos están claramente definidos.
- El diseño del programa y el estadístico son adecuados.
- Los ítems han sido correctamente caracterizados (homogeneidad, estabilidad, valor asignado).
- Los criterios de evaluación son apropiados para el uso previsto de los resultados.

Esto suele hacerse mediante:

- Revisión por el **equipo técnico** del proveedor.
- Aprobación por la dirección o responsable del PT.
- Registros que demuestren que se han cumplido los requisitos de ISO 17043 y, si aplica, ISO 13528.

---

## 5. Documentación típica que resulta de la planificación

En un sistema de gestión según ISO 17043, la planificación se materializa en documentos y registros como:

- Plan del programa de ensayos de aptitud (por esquema).
- Plan específico de cada ronda (objetivos, ítems, diseño estadístico, cronograma).
- Procedimientos de:
  - Preparación y control de ítems.
  - Determinación de homogeneidad y estabilidad.
  - Determinación del valor asignado y su incertidumbre.
  - Análisis estadístico y evaluación del desempeño.
- Informes de:
  - Homogeneidad y estabilidad.
  - Caracterización del valor asignado.
- Registros de revisión y aprobación del plan.

---

## 6. Recomendaciones prácticas

Si estás planificando un ensayo de aptitud bajo ISO 17043:

1. Empieza siempre por **definir claramente el objetivo**; de ahí se derivan el resto de decisiones.
2. Usa **ISO 13528** como referencia para el diseño estadístico; no reinventes métodos si no es necesario.【turn0search16】
3. No escatimes en los estudios de **homogeneidad y estabilidad**; son la base de la validez del PT.【turn0search0】
4. Documenta todo en un **plan de PT** claro, que pueda ser revisado por terceros (por ejemplo, por un organismo de acreditación).
5. Asegúrate de que los criterios de evaluación sean **realistas y coherentes** con el estado del arte de los métodos de ensayo participantes.

Si me dices qué tipo de ensayo/medición quieres cubrir (por ejemplo, microbiología, metales en agua, calibración de masa, etc.), puedo proponerte un ejemplo concreto de plan de ensayo de aptitud adaptado a ese caso.
