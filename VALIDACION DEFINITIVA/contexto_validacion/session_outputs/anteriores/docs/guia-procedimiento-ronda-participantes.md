# Guía del Procedimiento de Ronda de Ensayo de Aptitud

**Código:** GL-PT-001
**Versión:** 1.1
**Fecha:** 2026-05-19
**Responsable:** Calaire — Laboratorio de Ensayos de Aptitud
**Estado:** Borrador interno
**Alcance:** Uso interno de Calaire. Puede derivarse posteriormente una versión pública para participantes.

---

## Historial de Cambios

| Versión | Fecha | Autor | Descripción |
|---------|-------|-------|-------------|
| 1.0 | 2026-05-19 | Calaire | Creación inicial. Procedimiento del participante y de Calaire basado en scripts del repositorio. |
| 1.1 | 2026-05-19 | Calaire | Correcciones: referencias normativas (ISO 13528, ISO 17043); distinción s/σ_PT y x_PT; términos dato/promedio unificados; nivel cero (1 dato vs 3 datos); datos minutales y 75%; componentes de incertidumbre (u_rep, u_cal, u_res, u_otro); sección de criterios de rechazo; OK como indicador de carga; aplicativo no recalcula; U_xi y k por resultado reportado; logs como evidencia formal; eliminación de preguntas abiertas. |

---

## 1. Propósito

Esta guía describe de manera completa el procedimiento de una ronda de ensayo de aptitud desde dos perspectivas:

1. **Procedimiento del participante:** qué información debe calcular y cargar en el aplicativo, usando sus propios datos crudos y su propio criterio metrológico.
2. **Procedimiento de Calaire:** cómo se configuran, reciben, procesan, validan y consolidan los datos usando los scripts internos del repositorio.

La guía es suficientemente específica para uso interno de Calaire, pero marca con claridad qué partes puede o debe ejecutar autónomamente el participante, dado que esa autonomía hace parte de la evaluación de aptitud.

---

## 2. Referencias Normativas

- **ISO 13528:2022** — Statistical methods for use in proficiency testing by interlaboratory comparison.
- **ISO 17043:2023** — Conformity assessment — General requirements for proficiency testing.

Las definiciones y procedimientos de esta guía se basan en estos documentos. Cuando se usan términos como *valor asignado*, *puntuación z* o *ensayo de aptitud*, corresponde a las definiciones de ISO 13528:2022 y ISO 17043:2023.

---

## 3. Alcance

### Incluye

- Flujo general de la ronda.
- Diferencia entre datos crudos, datos resumidos, valores de referencia y resultados de evaluación.
- Qué debe calcular el participante de forma autónoma.
- Qué debe cargar el participante en el aplicativo.
- Qué campos son configurados por Calaire y no por el participante.
- Procedimiento interno de Calaire basado en scripts.
- Relación entre la pantalla del aplicativo y las columnas internas actuales.
- Necesidad de reportar tanto `u_xi` como `U_xi`.
- Validaciones y controles mínimos.
- Anexos: diccionario de datos, checklist del participante, checklist interno Calaire.

### No incluye, por ahora

- Corrección del aplicativo para almacenar `U_xi` y `k`.
- Desarrollo de scripts nuevos.
- Manual de usuario final completo del aplicativo.
- Valores de referencia reales en la versión para participantes.
- Criterios estadísticos internos que Calaire decida reservar.

---

## 4. Definiciones **[COMÚN]**

| Término | Definición |
|---------|------------|
| **Ronda** | Ejercicio de ensayo de aptitud organizado por Calaire, definido por un conjunto de contaminantes, niveles, corridas y participantes. |
| **Combinación** | Instancia única de contaminante + nivel + corrida para la que el participante debe reportar resultados. |
| **Corrida** | Secuencia o ejecución de mediciones dentro de la ronda. |
| **Nivel** | Concentración o magnitud esperada del contaminante en una combinación dada. |
| **dato/promedio** | Valor resumido que el participante reporta como insumo para cada combinación. Cada dato/promedio se calcula a partir de datos minutales, exigiendo al menos el 75% de datos válidos en una hora. Para los niveles distintos de cero, la ronda solicita tres datos/promedios por combinación, ingresados en `Dato 1`, `Dato 2` y `Dato 3`. Para el nivel cero, se solicita un solo dato/promedio (ingresado en `Dato 1`). |
| **`xi`** | Valor medio reportado por el participante para una combinación, calculado a partir de los datos/promedios válidos. |
| **Desviación estándar (`s`)** | Desviación estándar de los datos/promedios reportados por el participante para una combinación. En pantalla aparece como `Desv. Est.`. No confundir con la desviación estándar de aptitud (`σ_PT`), que es un parámetro definido por Calaire para la evaluación estadística y no es reportada por el participante. |
| **`u_xi`** | Incertidumbre estándar del valor medio reportado `xi`. En pantalla aparece como `u(x)`. |
| **`U_xi`** | Incertidumbre expandida del valor medio reportado `xi`. En pantalla aparece como `u(x) exp`. |
| **Factor de cobertura `k`** | Relación `k = U_xi / u_xi`, siempre que `u_xi > 0`. Debe poder recuperarse para reportes. |
| **Valor de referencia** | Valor generado por Calaire para una combinación, usado como insumo interno en la evaluación estadística de aptitud. No se muestra al participante. |
| **Valor asignado (`x_PT`)** | Valor convencional verdadero o estimado asignado a una combinación según ISO 13528:2022, del cual se calculan desviaciones o puntuaciones `z`. Es determinado por Calaire y no es accesible por el participante durante la ronda. |
| **Desviación estándar de aptitud (`σ_PT`)** | Parámetro de dispersión definido por Calaire según ISO 13528:2022, utilizado en el cálculo de puntuaciones `z`. Es independiente de la desviación estándar `s` que reporta el participante. |

---

## 5. Roles y Responsabilidades

| Rol | Responsabilidad Principal |
|-----|---------------------------|
| **Participante** | Ejecutar mediciones, conservar datos crudos, calcular resultados resumidos, cargar datos en el aplicativo y validar la coherencia de su reporte. |
| **Calaire** | Configurar la ronda, validar reportes recibidos, ejecutar scripts de procesamiento interno, generar valores de referencia, consolidar datos y realizar el análisis estadístico de aptitud. |
| **Aplicativo** | Presentar al participante la estructura configurada de la ronda, recibir los campos numéricos, ejecutar validaciones de completitud básicas y mostrar el estado de completitud del formulario. |

---

## 6. Configuración de la Ronda por Calaire **[CALAIRE - CONFIGURACIÓN]**

Antes de abrir la ronda a los participantes, Calaire debe configurar en el aplicativo o en los metadatos de la ronda:

- **Ronda:** identificador de la ronda (por ejemplo, `Ronda 1`).
- **Contaminantes:** lista de contaminantes incluidos (por ejemplo, `CO`, `SO2`).
- **Número de combinaciones:** total de instancias contaminante+nivel+corrida esperadas.
- **Corridas:** identificadores o secuencias de corrida.
- **Niveles:** niveles asociados a cada combinación.
- **Unidades:** unidad de medida por contaminante.
- **Número esperado de datos/promedios por nivel:** tres (3) para niveles distintos de cero; un (1) para el nivel cero. Cada dato/promedio se calcula a partir de datos minutales, exigiendo al menos el 75% de datos válidos en una hora.
- **Participantes habilitados:** lista de identificadores de laboratorios participantes.
- **Reglas de validación de completitud:** criterios mínimos que el aplicativo usará para marcar una combinación como completa.

> **Nota:** El participante no debe poder modificar los campos estructurales anteriores. El aplicativo debe presentarlos como información de solo lectura.

---

## 7. Procedimiento del Participante **[PARTICIPANTE - AUTÓNOMO]**

### 7.1 Revisión de la ronda **[COMÚN]**

Antes de preparar sus datos, el participante revisa en el aplicativo:

- Contaminantes incluidos.
- Número de combinaciones esperadas.
- Corridas definidas.
- Niveles asignados.
- Unidades de reporte.
- Estado de completitud del formulario (`Completo` / `Incompleto`).

El participante no modifica estos campos estructurales.

### 7.2 Preparación de datos crudos **[PARTICIPANTE - AUTÓNOMO]**

El participante debe disponer de sus datos crudos y asegurar que sean trazables. Los datos crudos no se cargan directamente en la pantalla del aplicativo, pero deben respaldar los valores resumidos.

Recomendaciones mínimas de conservación:

- Fecha y hora de cada medición o registro usado.
- Contaminante medido.
- Unidad registrada.
- Instrumento o sistema de medición utilizado.
- Registros usados para cada corrida/nivel.
- Criterios propios de exclusión o depuración, si aplican, debidamente documentados.

### 7.3 Cálculo de datos/promedios **[PARTICIPANTE - AUTÓNOMO]**

Para cada combinación de contaminante y nivel, el participante calcula los datos/promedios requeridos por la ronda:

- **Niveles distintos de cero:** tres datos/promedios, ingresados en `Dato 1`, `Dato 2` y `Dato 3`.
- **Nivel cero:** un solo dato/promedio, ingresado en `Dato 1`.

Cada dato/promedio se obtiene a partir de datos minutales de medición, exigiendo al menos el 75% de datos válidos en una hora para considerar el dato/promedio válido.

> **Importante:** El participante utiliza su propia metodología para obtener estos valores a partir de sus datos crudos. La ronda no impone un método único de promediación o tratamiento previo, salvo que se especifique en las instrucciones particulares de la ronda.

### 7.4 Cálculo del valor medio `xi` **[PARTICIPANTE - AUTÓNOMO]**

El participante calcula el valor medio `xi` según el nivel:

- **Para niveles distintos de cero:** `xi = promedio de los tres datos/promedios válidos`.
- **Para el nivel cero:** `xi` corresponde al único dato/promedio reportado en `Dato 1`.

En la pantalla del aplicativo este valor se carga en el campo `Promedio`.

> **Nota sobre coherencia:** El campo `Promedio` es diligenciado por el participante. El aplicativo no recalcula ningún campo numérico. Calaire verificará durante la validación (Sección 9.2) que el valor ingresado sea coherente con los datos/promedios reportados. Si el participante utiliza un método de promediación que no corresponde al promedio aritmético simple (por ejemplo, un promedio ponderado o con exclusión de valores atípicos), debe documentarlo en sus registros internos.

### 7.5 Cálculo de la desviación estándar **[PARTICIPANTE - AUTÓNOMO]**

El participante calcula la desviación estándar de los datos/promedios reportados para la combinación:

```
s = desviación estándar de los datos/promedios reportados
```

En la pantalla del aplicativo este valor se carga en el campo `Desv. Est.`.

> **Nota:** Esta desviación estándar `s` refleja la dispersión de los datos/promedios del propio participante. No debe confundirse con la desviación estándar de aptitud `σ_PT`, que es un parámetro definido por Calaire para la evaluación estadística (véase la Sección 4).

### 7.6 Estimación de incertidumbre estándar `u_xi` **[PARTICIPANTE - AUTÓNOMO]**

El participante estima y reporta la incertidumbre estándar de `xi`:

```
u_xi = u(x)
```

En la pantalla del aplicativo este valor se carga en el campo `u(x)`.

> **Nota sobre el alcance de la incertidumbre:** La incertidumbre `u_xi` corresponde a la medición promedio reportada por el participante para cada combinación de contaminante y nivel. El participante debe calcular `u_xi` para cada contaminante y cada nivel, siguiendo su procedimiento interno de estimación de incertidumbre. La distinción entre nivel cero y otros niveles es importante para la incertidumbre, no para la desviación estándar:
>
> - **Niveles distintos de cero:** los tres datos/promedios por combinación permiten estimar el componente de repetibilidad a partir de la dispersión entre ellos. Los datos minutales subyacentes (con al menos el 75% de datos válidos por hora) sustentan cada dato/promedio.
> - **Nivel cero:** al reportarse un solo dato/promedio, el componente de repetibilidad no puede derivarse de la dispersión entre datos/promedios; el participante debe estimarlo a partir de sus datos minutales o de su procedimiento interno.
>
> Los componentes típicos de `u_xi` incluyen:
>
> - **Repetibilidad (`u_rep`):** dispersión de los datos/promedios alrededor de `xi`. Para el nivel cero, se estima según el procedimiento interno del participante.
> - **Calibración (`u_cal`):** incertidumbre asociada a la calibración del instrumento de medición.
> - **Resolución (`u_res`):** incertidumbre asociada a la resolución del instrumento.
> - **Otros componentes (`u_otro`):** según el procedimiento interno del participante (por ejemplo, deriva, correcciones, factores ambientales).
>
> La fórmula general es:
>
> ```
> u_xi = sqrt(u_rep^2 + u_cal^2 + u_res^2 + u_otro^2)
> ```
>
> La guía no prescribe la metodología específica de estimación de cada componente, dado que esta hace parte de la aptitud evaluada.

### 7.7 Estimación de incertidumbre expandida `U_xi` **[PARTICIPANTE - AUTÓNOMO]**

El participante estima y reporta la incertidumbre expandida de `xi`:

```
U_xi = u(x) exp
```

En la pantalla del aplicativo este valor se carga en el campo `u(x) exp`.

> **Nota técnica:** Aunque el modelo de datos actual del consolidado `ronda_1_completa.csv` no almacena explícitamente `U_xi`, la guía exige su reporte desde ahora como dato requerido. La corrección técnica del aplicativo/consolidado para almacenar `U_xi` y `k` por resultado reportado queda programada para una fase posterior.

### 7.8 Factor de cobertura `k` **[PARTICIPANTE - AUTÓNOMO / CALAIRE - VALIDACIÓN]**

El factor de cobertura debe poder recuperarse o conservarse para reporte:

```
k = U_xi / u_xi   (si u_xi > 0)
```

Calaire validará más adelante si `k` se almacena explícitamente o si se calcula a partir de `u_xi` y `U_xi` durante el procesamiento interno. `U_xi` y `k` deberán almacenarse por resultado reportado, es decir, por participante y combinación de ronda, según el modelo de datos que se defina.

### 7.9 Revisión antes de carga **[PARTICIPANTE - AUTÓNOMO]**

Antes de ingresar los valores al aplicativo, el participante debe verificar:

- Que los datos correspondan al contaminante mostrado en la pantalla.
- Que los datos correspondan al nivel mostrado.
- Que las unidades de reporte sean correctas.
- Que `Promedio` sea coherente con los datos/promedios reportados (`Dato 1`, `Dato 2`, `Dato 3` para niveles distintos de cero; `Dato 1` para el nivel cero).
- Que `Desv. Est.` corresponda a la dispersión de los datos/promedios reportados.
- Que `u(x) exp` sea coherente con `u(x)` y el factor de cobertura usado.
- Que todas las combinaciones requeridas estén preparadas para cargar.

---

## 8. Carga en Aplicativo **[PARTICIPANTE - CARGA EN APLICATIVO]**

### 8.1 Campos visibles en la pantalla

El participante solo diligencia los campos numéricos de resultados. El aplicativo muestra previamente configurada la información estructural de la ronda.

Ejemplo de pantalla para un contaminante (por ejemplo, `CO`):

| Campo en pantalla | Responsable | Interpretación |
|-------------------|-------------|----------------|
| Contaminante | Calaire / app | No lo diligencia el participante. |
| Número de combinaciones | Calaire / app | No lo diligencia el participante. |
| Estado `Completo` | App | Validación visual de la carga del formulario. |
| `Corrida` | Calaire / app | No lo diligencia el participante. |
| `Nivel` | Calaire / app | No lo diligencia el participante. |
| `Dato 1` | Participante | Primer dato/promedio resumido. |
| `Dato 2` | Participante | Segundo dato/promedio resumido. |
| `Dato 3` | Participante | Tercer dato/promedio resumido. |
| `Promedio` | Participante | Valor medio reportado, `xi`. |
| `Desv. Est.` | Participante | Desviación estándar de los datos/promedios reportados. |
| `u(x)` | Participante | Incertidumbre estándar de `xi`, `u_xi`. |
| `u(x) exp` | Participante | Incertidumbre expandida de `xi`, `U_xi`. |
| `OK` | App | Indicador automático que señala que el participante ha completado la carga de los campos requeridos. El aplicativo no recalcula ningún campo numérico; todos los valores son ingresados directamente por el participante. No es un campo de entrada ni un resultado técnico. |

### 8.2 Reglas de carga

- El participante no debe modificar: contaminante, corrida, nivel, unidad, ni número de combinaciones.
- El participante debe completar todos los campos numéricos para cada combinación.
- El aplicativo no recalcula ningún campo numérico (`Promedio`, `Desv. Est.`, `u(x)`, `u(x) exp`). Todos los valores numéricos son ingresados directamente por el participante.
- El aplicativo muestra `OK` cuando el participante ha completado la carga de los campos requeridos.

> **Nota sobre coherencia:** El participante es el único responsable de los valores numéricos que ingresa. El aplicativo no los recalcula ni los modifica. Calaire validará la coherencia entre `Promedio` y los datos/promedios, así como entre `Desv. Est.` y la dispersión observada, durante la revisión (Sección 9.2).

---

## 9. Validación por Calaire **[CALAIRE - VALIDACIÓN]**

Una vez cerrada la recepción de datos de los participantes, Calaire ejecuta las siguientes validaciones mínimas:

### 9.1 Completitud

- Todos los participantes habilitados han cargado datos.
- Todos los contaminantes requeridos están reportados por cada participante.
- Todos los niveles requeridos están reportados.
- Se reportan tres datos/promedios por nivel para niveles distintos de cero, y un dato/promedio para el nivel cero.
- Se reportan `xi`, desviación estándar, `u_xi` y `U_xi`.

### 9.2 Coherencia numérica

- Campos obligatorios no vacíos.
- Valores numéricos válidos (finitos, no `NA`, no textos erróneos).
- Coherencia entre `Dato 1`, `Dato 2`, `Dato 3` y `Promedio`.
- Coherencia entre `Desv. Est.` y los datos/promedios reportados.
- Coherencia entre `u_xi`, `U_xi` y `k` (verificar que `U_xi ≈ k * u_xi` con el `k` declarado o inferido).
- Unidades consistentes por contaminante a través de las combinaciones.

### 9.3 Trazabilidad y duplicados

- No existen registros duplicados por participante / contaminante / nivel.
- Los identificadores de participante (`participant_id`) corresponden a la lista habilitada.

### 9.4 Criterios de rechazo y no conformidades

Calaire debe definir y aplicar criterios para manejar situaciones como las siguientes:

- **`u_xi = 0`:** Un participante que reporte incertidumbre estándar igual a cero será contactado para verificación, dado que toda medición conlleva incertidumbre. Calaire decidirá si solicita corrección o si aplica un procedimiento alternativo según ISO 13528:2022.
- **Menos datos/promedios que los requeridos:** Si un participante no puede reportar los datos/promedios requeridos para el nivel (por ejemplo, por datos faltantes o excluidos), Calaire evaluará si el reporte parcial es aceptable bajo las reglas de la ronda o si se requiere una justificación documentada.
- **Incoherencia manifiesta entre `Promedio` y los datos/promedios requeridos:** Si el valor ingresado en `Promedio` difiere significativamente del promedio aritmético de los datos/promedios reportados para el nivel, Calaire solicitará al participante la metodología de promediación utilizada o pedirá corrección.
- **`U_xi < u_xi`:** Una incertidumbre expandida menor que la incertidumbre estándar es físicamente inconsistente (implicaría un factor de cobertura `k < 1`). Calaire solicitará verificación o corrección.
- **Valores negativos o no finitos en campos que no los admiten:** serán rechazados y se pedirá al participante que corrija y recargue.

Calaire documentará cada no conformidad detectada y la acción tomada (corrección solicitada, exclusión justificada, procedimiento alternativo).

---

## 10. Procesamiento Interno con Scripts **[CALAIRE - PROCESAMIENTO INTERNO]**

El procesamiento interno de Calaire se ejecuta mediante scripts del repositorio. Estos scripts son de uso exclusivo interno; el participante no los utiliza ni tiene acceso a ellos.

### 10.1 Inventario de scripts principales

| Script / Función | Propósito |
|------------------|-----------|
| `scripts/aplicativo/preprocesar_calaire.R` | Ejecuta el pipeline principal de preprocesamiento de Calaire para una ronda. |
| `scripts/adicionales/run_preprocessor_calaire.R` | Procesa múltiples archivos de ronda detectados en `data/raw/`. Útil para ejecución por lotes. |
| `scripts/adicionales/unir_rondas.R` | Une salidas procesadas de participantes y referencia para generar archivos consolidados usados por el aplicativo y el análisis estadístico. |
| `R/preprocessing/read_calaire_raw.R` | Lectura de archivos crudos de entrada. |
| `R/preprocessing/clean_calaire_raw.R` | Limpieza y normalización de los datos leídos. |
| `R/preprocessing/hourly_averages.R` | Cálculo de promedios horarios o por nivel, según configuración de la ronda. |
| `R/preprocessing/moving_hourly_means.R` | Cálculo de medias móviles para evaluación de estabilidad y homogeneidad. |
| `R/preprocessing/uncertainty_report.R` | Generación de reporte de incertidumbre asociada a los valores de referencia. |
| `R/preprocessing/validation.R` | Validaciones automáticas con logs de estado `PASS` / `WARN` / `FAIL`. |
| `R/preprocessing/pipeline_calaire.R` | Funciones principales que orquestan el pipeline completo. |

### 10.2 Diferencia funcional entre scripts

- **`preprocesar_calaire.R`:** flujo principal de Calaire. Ejecuta pipelines de estabilidad/homogeneidad, referencia y participante cuando existen los archivos esperados en las rutas configuradas.
- **`run_preprocessor_calaire.R`:** flujo alterno o por lote. Útil cuando hay múltiples archivos `datos_ronda_*.csv` que deben procesarse secuencialmente.
- **`unir_rondas.R`:** no calcula resultados del participante ni realiza evaluaciones estadísticas. Su función es consolidar archivos ya procesados para generar archivos como:
  - `ronda_1_participantes.csv`
  - `ronda_1_referencia.csv`
  - `ronda_1_completa.csv`

### 10.3 Entradas y salidas típicas

| Tipo | Ruta / Descripción |
|------|-------------------|
| Entrada cruda | `data/raw/datos_ronda_*.csv` |
| Metadatos | `data/metadata/` (configuración de ronda, contaminantes, niveles) |
| Salida procesada | `data/processed/ronda_*_participantes.csv` |
| Salida referencia | `data/processed/ronda_*_referencia.csv` |
| Consolidado | `data/processed/ronda_*_completa.csv` |
| Logs | Salidas de validación con estados `PASS` / `WARN` / `FAIL`. Todos los logs y salidas de los scripts deben conservarse como evidencia formal del procesamiento interno de cada ronda. |

---

## 11. Consolidación de Datos **[CALAIRE - PROCESAMIENTO INTERNO]**

### 11.1 Generación del consolidado

`scripts/adicionales/unir_rondas.R` toma los archivos procesados de participantes y referencia, asigna o propaga campos internos como `tipo` (`participante` o `referencia`) y `n_lab` (número de laboratorios), y genera el archivo consolidado.

### 11.2 Estructura del consolidado actual

El archivo `data/processed/ronda_1_completa.csv` actual contiene 20 filas y 17 columnas (10 filas de participante, 10 filas de referencia).

### 11.3 Separación de información **[CALAIRE - NO DIVULGAR]**

Calaire debe asegurar que la versión o vista del participante nunca incluya:

- Filas con `tipo = referencia`.
- Valores de referencia o incertidumbre de referencia.
- Criterios internos de asignación de valor que no sean divulgables.
- Cualquier dato que permita inferir indebidamente el valor asignado antes de la evaluación oficial.

> **Regla:** El consolidado completo (`ronda_1_completa.csv`) es de uso estrictamente interno de Calaire.

---

## 12. Preparación para Análisis de Aptitud **[CALAIRE - PROCESAMIENTO INTERNO]**

Una vez consolidados los datos:

1. Calaire verifica que el archivo consolidado contenga tanto participantes como referencia (en la versión interna).
2. Se alimenta el archivo al aplicativo Shiny de análisis estadístico (`app.R`) o a los scripts de cálculo del paquete `ptcalc`.
3. Se ejecutan las funciones de evaluación según ISO 13528:2022 (puntuaciones `z`, estadísticas robustas, asignación de valor, etc.).
4. Se revisan criterios de coherencia metrológica antes de emitir el informe final.

---

## 13. Anexos

### Anexo A: Diccionario de Campos de la Pantalla del Participante

| Campo visible | Nombre conceptual | Descripción |
|---------------|-------------------|-------------|
| `Dato 1` | Primer dato/promedio | Primer valor resumido reportado por el participante para la combinación. |
| `Dato 2` | Segundo dato/promedio | Segundo valor resumido reportado. |
| `Dato 3` | Tercer dato/promedio | Tercer valor resumido reportado. |
| `Promedio` | `xi` | Valor medio reportado por el participante. Debe ser coherente con `Dato 1`, `Dato 2` y `Dato 3`. |
| `Desv. Est.` | Desviación estándar (`s`) | Desviación estándar de los datos/promedios reportados por el participante. No confundir con `σ_PT` (definida por Calaire). |
| `u(x)` | `u_xi` | Incertidumbre estándar de `xi`. |
| `u(x) exp` | `U_xi` | Incertidumbre expandida de `xi`. |
| `OK` | Estado de carga del formulario | Indicador automático del aplicativo que señala que el participante ha completado la carga de los campos requeridos. No es un campo de entrada ni un resultado técnico del participante. |

### Anexo B: Diccionario de Columnas Internas (CSV Consolidado)

| Columna CSV | Uso | Quién lo asigna |
|-------------|-----|-----------------|
| `pollutant` | Contaminante | Calaire / app |
| `level` | Nivel | Calaire / app |
| `source` | Fuente interna | Calaire (script) |
| `run` | Corrida | Calaire / app |
| `unit` | Unidad | Calaire / app |
| `instrument` | Instrumento o identificador | A definir: Calaire o participante |
| `mean_h1` | Primer dato/promedio | Participante (como `Dato 1`) |
| `mean_h2` | Segundo dato/promedio | Participante (como `Dato 2`) |
| `mean_h3` | Tercer dato/promedio | Participante (como `Dato 3`) |
| `mean_value` | Valor medio reportado `xi` | Participante (como `Promedio`) |
| `sd_value` | Desviación estándar | Participante (como `Desv. Est.`) |
| `u_value` | Incertidumbre estándar `u_xi` | Participante (como `u(x)`) |
| `n_hours` | Número de datos/promedios válidos | App / Calaire |
| `hour_starts` | Horarios internos | No diligencia el participante |
| `participant_id` | Identificador del participante | Calaire / app |
| `tipo` | Participante o referencia | Calaire (script) |
| `n_lab` | Número de laboratorios | Calaire / app |

> **Brecha técnica documentada:** El CSV actual no contiene columnas para `U_xi` ni `k`. Se requiere su inclusión en una fase posterior. `U_xi` y `k` deberán almacenarse por resultado reportado, es decir, por participante y combinación de ronda, según el modelo de datos que se defina.

### Anexo C: Checklist del Participante (antes de enviar)

- [ ] He revisado que el contaminante mostrado en la pantalla corresponde a mis datos.
- [ ] He revisado que el nivel mostrado corresponde a mis datos.
- [ ] He verificado que la unidad de reporte es correcta.
- [ ] He calculado los datos/promedios requeridos para cada nivel (`Dato 1`, `Dato 2` y `Dato 3` para niveles distintos de cero; `Dato 1` para el nivel cero) a partir de mis datos crudos.
- [ ] He calculado `Promedio` (`xi`) y es coherente con los datos/promedios requeridos para el nivel.
- [ ] He calculado `Desv. Est.` (`s`) y corresponde a la dispersión de los datos/promedios reportados.
- [ ] He estimado `u(x)` (`u_xi`) de acuerdo con mi propio criterio metrológico.
- [ ] He estimado `u(x) exp` (`U_xi`) de acuerdo con mi propio criterio metrológico.
- [ ] He verificado que `u(x) exp` sea coherente con `u(x)` y mi factor de cobertura.
- [ ] Todas las combinaciones requeridas aparecen como completas en el aplicativo.

### Anexo D: Checklist de Calaire (validación interna)

- [ ] La ronda está configurada correctamente en el aplicativo/metadatos.
- [ ] Todos los participantes habilitados han cargado datos.
- [ ] Todos los contaminantes y niveles requeridos están reportados.
- [ ] Se reportan tres datos/promedios por combinación para niveles distintos de cero, y un dato/promedio para el nivel cero.
- [ ] Se reportan `xi`, desviación estándar, `u_xi` y `U_xi`.
- [ ] No hay valores vacíos ni no numéricos en campos obligatorios.
- [ ] `Promedio` es coherente con `Dato 1`, `Dato 2`, `Dato 3`.
- [ ] `Desv. Est.` es coherente con los datos/promedios reportados.
- [ ] `u_xi`, `U_xi` y `k` son coherentes entre sí.
- [ ] No hay registros duplicados por participante/contaminante/nivel.
- [ ] Los scripts de preprocesamiento se ejecutaron sin errores críticos.
- [ ] Los logs de validación (`PASS`/`WARN`/`FAIL`) fueron revisados.
- [ ] El consolidado separa correctamente participante y referencia.
- [ ] La información de referencia no está expuesta en vistas de participantes.

### Anexo E: Mapa Pantalla -> CSV -> Análisis

```
Pantalla del Aplicativo
│
├─ Dato 1        ──>  mean_h1   ──>  dato/promedio 1
├─ Dato 2        ──>  mean_h2   ──>  dato/promedio 2
├─ Dato 3        ──>  mean_h3   ──>  dato/promedio 3
├─ Promedio      ──>  mean_value ──>  xi (valor reportado)
├─ Desv. Est.    ──>  sd_value   ──>  s (dispersión de los datos/promedios)
├─ u(x)          ──>  u_value    ──>  u_xi (incertidumbre estándar)
├─ u(x) exp      ──>  [futuro U_xi] ──>  U_xi (incertidumbre expandida)
│
Campos estructurales (no diligenciables por el participante):
├─ Contaminante  ──>  pollutant
├─ Nivel         ──>  level
├─ Corrida       ──>  run
├─ Unidad        ──>  unit
├─ Participante  ──>  participant_id
└─ Tipo          ──>  tipo (participante / referencia) [CALAIRE - NO DIVULGAR]
```

### Anexo F: Lista de Scripts Internos

1. `scripts/aplicativo/preprocesar_calaire.R`
2. `scripts/adicionales/run_preprocessor_calaire.R`
3. `scripts/adicionales/unir_rondas.R`
4. `R/preprocessing/read_calaire_raw.R`
5. `R/preprocessing/clean_calaire_raw.R`
6. `R/preprocessing/hourly_averages.R`
7. `R/preprocessing/moving_hourly_means.R`
8. `R/preprocessing/uncertainty_report.R`
9. `R/preprocessing/validation.R`
10. `R/preprocessing/pipeline_calaire.R`

---

## 14. Riesgos a Controlar

| Riesgo | Mitigación documentada en esta guía |
|--------|-------------------------------------|
| Confundir `u_xi` con `U_xi` | Definidos ambos términos en el glosario (Sección 4) y en los diccionarios de campos (Anexos A y B). |
| No conservar `U_xi` para reporte | Documentado como dato requerido desde ahora (Sección 7.7); la corrección técnica del aplicativo queda programada. |
| Exponer valores de referencia al participante | Separación explícita de información de referencia (Sección 11.3, Anexo D). |
| Hacer por el participante cálculos que evalúan su aptitud | Marcadas secciones autónomas (`[PARTICIPANTE - AUTÓNOMO]`) y limitación de ejemplos resueltos. |
| Confundir datos crudos con resultados resumidos | Explicado en Sección 7.2: los datos crudos se conservan, pero no se cargan en la pantalla actual. |
| Confundir scripts de Calaire con herramientas del participante | Indicado explícitamente en Sección 10: scripts de uso exclusivo interno. |
| Confundir `s` (del participante) con `σ_PT` (de Calaire) | Definidos como conceptos distintos en la Sección 4; `s` es la desviación de los datos/promedios del participante, `σ_PT` es el parámetro de aptitud definido por Calaire. |
| Incompatibilidad entre pantalla y CSV actual | Documentado en Anexo B con el mapeo completo y la brecha técnica identificada. |

---

*Documento elaborado siguiendo el plan `260519_1044_plan_guia-procedimiento-ronda-participantes.md`.*
