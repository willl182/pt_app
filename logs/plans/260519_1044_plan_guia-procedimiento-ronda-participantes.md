# Plan: Guía del procedimiento de ronda para Calaire y participantes

**Timestamp:** 260519_1044  
**Slug:** guia-procedimiento-ronda-participantes  
**Estado:** En progreso

## Objetivo

Elaborar una guía operativa, inicialmente para uso interno de Calaire, que describa de manera completa el procedimiento de una ronda de ensayo de aptitud desde dos perspectivas:

1. **Procedimiento del participante:** qué información debe calcular y cargar en el aplicativo, usando sus propios datos crudos y su propio criterio metrológico.
2. **Procedimiento de Calaire:** cómo se configuran, reciben, procesan, validan y consolidan los datos usando los scripts internos del repositorio.

La guía debe ser suficientemente específica para uso interno de Calaire, pero debe marcar con claridad qué partes puede o debe ejecutar autónomamente el participante, dado que esa autonomía hace parte de la evaluación de aptitud.

## Principio rector

El participante **no entrega scripts ni usa scripts de Calaire**. Tampoco diligencia manualmente la ronda, el contaminante, la corrida, el nivel o la unidad. Esa información debe estar configurada en el aplicativo por Calaire.

El participante parte de sus datos crudos, realiza su propio tratamiento y carga únicamente los resultados resumidos solicitados por el aplicativo.

Calaire, por su parte, debe documentar su procedimiento con base en los scripts reales del proyecto, no como un flujo manual genérico.

## Marcas de responsabilidad documental

Cada sección de la guía deberá llevar una marca explícita:

| Marca | Significado |
|------|-------------|
| **[PARTICIPANTE - AUTÓNOMO]** | Actividad que el participante debe poder realizar por su cuenta. Hace parte de su aptitud evaluada. |
| **[PARTICIPANTE - CARGA EN APLICATIVO]** | Información que el participante debe ingresar en la plantilla/formulario del aplicativo. |
| **[CALAIRE - CONFIGURACIÓN]** | Actividad previa de Calaire para configurar ronda, contaminantes, niveles, unidades, corridas y combinaciones. |
| **[CALAIRE - PROCESAMIENTO INTERNO]** | Actividad ejecutada por Calaire mediante scripts internos. |
| **[CALAIRE - VALIDACIÓN]** | Controles internos de completitud, coherencia, trazabilidad y consistencia. |
| **[CALAIRE - NO DIVULGAR]** | Información necesaria internamente, pero que no debe exponerse en la versión para participantes, por ejemplo valores de referencia. |
| **[COMÚN]** | Información general que pueden conocer tanto Calaire como los participantes. |

## Alcance de la guía

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

## Situación técnica actual detectada

El archivo actual `data/processed/ronda_1_completa.csv` contiene 20 filas y 17 columnas:

- 10 filas de participante.
- 10 filas de referencia.

Columnas actuales:

| Columna actual | Uso actual | Relación con participante |
|---|---|---|
| `pollutant` | Contaminante | Lo configura/presenta el aplicativo. |
| `level` | Nivel | Lo configura/presenta el aplicativo. |
| `source` | Fuente interna | No lo diligencia el participante. |
| `run` | Corrida | Lo configura/presenta el aplicativo. |
| `unit` | Unidad | Lo configura/presenta el aplicativo. |
| `instrument` | Instrumento o identificador | Definir si lo asigna Calaire/app o si lo selecciona el participante. |
| `mean_h1` | Primer dato/promedio | Lo diligencia el participante como `Dato 1`. |
| `mean_h2` | Segundo dato/promedio | Lo diligencia el participante como `Dato 2`. |
| `mean_h3` | Tercer dato/promedio | Lo diligencia el participante como `Dato 3`. |
| `mean_value` | Valor medio reportado | Lo diligencia/calcula el participante como `Promedio` o `xi`. |
| `sd_value` | Desviación estándar de los tres datos/promedios | Lo diligencia/calcula el participante como `Desv. Est.`. |
| `u_value` | Incertidumbre estándar de `xi` | Lo diligencia el participante como `u(x)`. |
| `n_hours` | Número de datos/promedios válidos | Lo calcula/configura el aplicativo o Calaire. |
| `hour_starts` | Horarios internos | No debe diligenciarlo el participante en la pantalla actual. |
| `participant_id` | Identificador del participante | Lo asigna Calaire/app. |
| `tipo` | Participante o referencia | Lo asigna Calaire. |
| `n_lab` | Número de laboratorios | Lo calcula Calaire/app. |

## Brecha técnica identificada

La pantalla del aplicativo solicita o muestra:

- `u(x)`: incertidumbre estándar de `xi`.
- `u(x) exp`: incertidumbre expandida de `xi`, es decir `U_xi`.

Sin embargo, el CSV actual solo conserva `u_value`, equivalente a `u_xi`, y no conserva explícitamente `U_xi` ni `k`.

La guía debe documentar desde ahora que el participante debe aportar ambos datos:

- `u_xi`: incertidumbre estándar.
- `U_xi`: incertidumbre expandida.

La corrección del aplicativo o del modelo de datos para almacenar ambos valores queda para una fase posterior, fuera del alcance inmediato de esta guía.

## Datos que carga el participante en el aplicativo

### Regla general

El participante solo diligencia datos/resultados numéricos. El aplicativo debe mostrarle la estructura de la ronda ya configurada por Calaire.

### Campos visibles en la pantalla

Ejemplo observado para CO:

| Campo en pantalla | Responsable | Interpretación |
|---|---|---|
| Contaminante, por ejemplo `CO` | Calaire/app | No lo diligencia el participante. |
| Número de combinaciones | Calaire/app | No lo diligencia el participante. |
| Estado `Completo` | App | Validación visual del formulario. |
| `Corrida` | Calaire/app | No lo diligencia el participante. |
| `Nivel` | Calaire/app | No lo diligencia el participante. |
| `Dato 1` | Participante | Primer dato/promedio resumido. |
| `Dato 2` | Participante | Segundo dato/promedio resumido. |
| `Dato 3` | Participante | Tercer dato/promedio resumido. |
| `Promedio` | Participante | Valor medio reportado, `xi`. |
| `Desv. Est.` | Participante | Desviación estándar de los tres datos/promedios. |
| `u(x)` | Participante | Incertidumbre estándar de `xi`, `u_xi`. |
| `u(x) exp` | Participante | Incertidumbre expandida de `xi`, `U_xi`. |
| `OK` | App | Validación del formulario; no es un resultado técnico del participante. |

### Mapeo interno propuesto

| Campo de pantalla | Nombre conceptual | Columna actual/propuesta |
|---|---|---|
| `Dato 1` | Primer dato/promedio | `mean_h1` |
| `Dato 2` | Segundo dato/promedio | `mean_h2` |
| `Dato 3` | Tercer dato/promedio | `mean_h3` |
| `Promedio` | `xi` | `mean_value` |
| `Desv. Est.` | Desviación estándar de los tres datos/promedios | `sd_value` |
| `u(x)` | Incertidumbre estándar de `xi` | `u_value` o futuro `u_xi` |
| `u(x) exp` | Incertidumbre expandida de `xi` | futuro `U_xi` |
| Factor de cobertura | `k = U_xi / u_xi` | futuro `k_factor` o derivado para reporte |

## Secciones que el participante debe poder hacer por su cuenta

Estas secciones deben marcarse en la guía como **[PARTICIPANTE - AUTÓNOMO]**:

1. Obtener y conservar sus datos crudos.
2. Identificar los datos correspondientes a cada contaminante y nivel.
3. Calcular los tres datos/promedios solicitados por nivel y contaminante.
4. Calcular `xi`, el promedio reportado.
5. Calcular la desviación estándar de los tres datos/promedios.
6. Estimar la incertidumbre estándar `u_xi`.
7. Estimar o declarar la incertidumbre expandida `U_xi`.
8. Usar un factor de cobertura coherente con su estimación de incertidumbre.
9. Revisar la coherencia entre `u_xi`, `U_xi` y `k`.
10. Validar que los valores cargados correspondan a la unidad y nivel mostrados por el aplicativo.

La guía puede explicar qué datos se requieren y qué representan, pero debe evitar resolver por el participante la metodología completa de estimación de incertidumbre si eso hace parte de la aptitud evaluada.

## Procedimiento del participante propuesto

### 1. Revisión de la ronda **[COMÚN]**

El participante revisa en el aplicativo:

- Contaminantes incluidos.
- Número de combinaciones.
- Corridas.
- Niveles.
- Unidades.
- Estado de completitud del formulario.

No debe modificar esos campos estructurales.

### 2. Preparación de datos crudos **[PARTICIPANTE - AUTÓNOMO]**

El participante debe disponer de sus datos crudos y asegurar que sean trazables:

- Fecha y hora de medición.
- Contaminante.
- Unidad.
- Instrumento o sistema de medición.
- Registros usados para cada corrida/nivel.
- Criterios propios de exclusión o depuración, si aplican.

Estos datos crudos no se cargan directamente en la pantalla observada, pero deben respaldar los valores resumidos.

### 3. Cálculo de datos/promedios **[PARTICIPANTE - AUTÓNOMO]**

Para cada contaminante y nivel, el participante calcula los tres datos/promedios requeridos por la ronda:

- `Dato 1`
- `Dato 2`
- `Dato 3`

Por ahora la ronda está configurada para tres datos/promedios. En futuras rondas este número puede ser configurable.

### 4. Cálculo del valor medio `xi` **[PARTICIPANTE - AUTÓNOMO]**

El participante calcula el promedio de los datos/promedios válidos del nivel:

```text
xi = promedio de los datos/promedios válidos
```

En la pantalla aparece como `Promedio`.

### 5. Cálculo de la desviación estándar **[PARTICIPANTE - AUTÓNOMO]**

El participante calcula la desviación estándar de los tres datos/promedios cargados para el nivel.

En la pantalla aparece como `Desv. Est.` y en el CSV actual corresponde a `sd_value`.

### 6. Estimación de incertidumbre estándar **[PARTICIPANTE - AUTÓNOMO]**

El participante reporta la incertidumbre estándar de `xi`:

```text
u_xi = u(x)
```

En el CSV actual corresponde a `u_value`.

### 7. Estimación de incertidumbre expandida **[PARTICIPANTE - AUTÓNOMO]**

El participante reporta la incertidumbre expandida de `xi`:

```text
U_xi = u(x) exp
```

Esta información es necesaria para reportes posteriores. Aunque el CSV actual no la almacena explícitamente, la guía debe exigirla como dato requerido.

### 8. Factor de cobertura **[PARTICIPANTE - AUTÓNOMO / CALAIRE - VALIDACIÓN]**

El factor de cobertura debe poder recuperarse o conservarse para reporte:

```text
k = U_xi / u_xi
```

siempre que `u_xi > 0`.

Calaire deberá validar más adelante si `k` se almacena explícitamente o si se calcula a partir de `u_xi` y `U_xi`.

### 9. Carga en aplicativo **[PARTICIPANTE - CARGA EN APLICATIVO]**

El participante diligencia únicamente los campos numéricos:

- `Dato 1`
- `Dato 2`
- `Dato 3`
- `Promedio`
- `Desv. Est.`
- `u(x)`
- `u(x) exp`

El aplicativo debe mostrar `OK` cuando los campos requeridos estén completos y sean coherentes según sus reglas de validación.

### 10. Revisión antes de envío **[PARTICIPANTE - AUTÓNOMO]**

El participante debe verificar:

- Que los datos correspondan al contaminante mostrado.
- Que los datos correspondan al nivel mostrado.
- Que las unidades sean correctas.
- Que `Promedio` sea coherente con `Dato 1`, `Dato 2` y `Dato 3`.
- Que `Desv. Est.` corresponda a los tres datos/promedios.
- Que `u(x) exp` sea coherente con `u(x)` y el factor de cobertura usado.
- Que todas las combinaciones requeridas estén completas.

## Procedimiento de Calaire propuesto

### 1. Configuración de la ronda **[CALAIRE - CONFIGURACIÓN]**

Calaire configura en el aplicativo:

- Ronda.
- Contaminantes.
- Número de combinaciones.
- Corridas.
- Niveles.
- Unidades.
- Número esperado de datos/promedios por nivel.
- Participantes habilitados.
- Reglas de validación de completitud.

### 2. Recepción de datos del participante **[CALAIRE - VALIDACIÓN]**

Calaire verifica que cada participante haya cargado:

- Todos los contaminantes requeridos.
- Todos los niveles requeridos.
- Tres datos/promedios por nivel, salvo configuración distinta.
- `xi`.
- Desviación estándar.
- `u_xi`.
- `U_xi`.

### 3. Validación de coherencia **[CALAIRE - VALIDACIÓN]**

Validaciones mínimas recomendadas:

- Campos obligatorios no vacíos.
- Valores numéricos válidos.
- Coherencia entre `Dato 1`, `Dato 2`, `Dato 3` y `Promedio`.
- Coherencia entre `Desv. Est.` y los tres datos/promedios.
- Coherencia entre `u_xi`, `U_xi` y `k`.
- Unidades consistentes por contaminante.
- No duplicidad de registros por participante/contaminante/nivel.

### 4. Preprocesamiento interno con scripts **[CALAIRE - PROCESAMIENTO INTERNO]**

El procedimiento interno de Calaire debe documentarse contra los scripts existentes.

Scripts identificados:

| Script/función | Propósito |
|---|---|
| `scripts/preprocesar_calaire.R` | Ejecuta el pipeline principal de preprocesamiento de Calaire. |
| `scripts/run_preprocessor_calaire.R` | Procesa múltiples archivos de ronda detectados en `data/raw/`. |
| `scripts/unir_rondas.R` | Une salidas procesadas de participantes y referencia para generar archivos consolidados usados por el aplicativo/análisis. |
| `R/preprocessing/read_calaire_raw.R` | Lectura de archivos crudos. |
| `R/preprocessing/clean_calaire_raw.R` | Limpieza y normalización. |
| `R/preprocessing/hourly_averages.R` | Cálculo de promedios horarios o por nivel. |
| `R/preprocessing/moving_hourly_means.R` | Cálculo de medias móviles para estabilidad/homogeneidad. |
| `R/preprocessing/uncertainty_report.R` | Generación de reporte de incertidumbre. |
| `R/preprocessing/validation.R` | Validaciones automáticas y logs PASS/WARN/FAIL. |
| `R/preprocessing/pipeline_calaire.R` | Funciones principales de pipeline. |

### 5. Diferencia funcional entre scripts internos **[CALAIRE - PROCESAMIENTO INTERNO]**

La guía debe explicar de forma sencilla:

- `preprocesar_calaire.R`: flujo principal de Calaire para ejecutar pipelines de estabilidad/homogeneidad, referencia y participante cuando existan los archivos esperados.
- `run_preprocessor_calaire.R`: flujo alterno o por lote, útil cuando hay múltiples archivos `datos_ronda_*.csv`.
- `unir_rondas.R`: no calcula resultados del participante; consolida archivos ya procesados para generar archivos como:
  - `ronda_1_participantes.csv`
  - `ronda_1_referencia.csv`
  - `ronda_1_completa.csv`

### 6. Consolidación final **[CALAIRE - PROCESAMIENTO INTERNO]**

`scripts/unir_rondas.R` toma archivos procesados de participantes y referencia, asigna/propaga campos internos como `tipo` y `n_lab`, y genera archivos consolidados.

El consolidado actual `ronda_1_completa.csv` mezcla participantes y referencia. La versión para participantes nunca debe exponer los datos de referencia.

### 7. Separación de información de referencia **[CALAIRE - NO DIVULGAR]**

Calaire debe asegurar que la versión o vista del participante no incluya:

- Filas `tipo = referencia`.
- Valores de referencia.
- Incertidumbre de referencia.
- Criterios internos de asignación de valor, si no son divulgables.
- Cualquier dato que permita inferir indebidamente el valor asignado antes de la evaluación.

## Estructura propuesta de la guía

1. **Control del documento**
   - Código.
   - Versión.
   - Fecha.
   - Responsable.
   - Historial de cambios.

2. **Propósito**
   - Explicar para qué existe la guía y cómo se usa.

3. **Alcance**
   - Rondas cubiertas.
   - Participantes.
   - Contaminantes.
   - Datos resumidos.
   - Procesamiento interno Calaire.

4. **Definiciones** **[COMÚN]**
   - Ronda.
   - Combinación.
   - Corrida.
   - Nivel.
   - Dato/promedio.
   - `xi`.
   - Desviación estándar.
   - `u_xi`.
   - `U_xi`.
   - Factor de cobertura `k`.
   - Valor de referencia.
   - Valor asignado.

5. **Roles y responsabilidades**
   - Participante.
   - Calaire.
   - Aplicativo.

6. **Configuración de la ronda por Calaire** **[CALAIRE - CONFIGURACIÓN]**
   - Qué se configura antes de abrir la ronda al participante.

7. **Procedimiento del participante** **[PARTICIPANTE - AUTÓNOMO]**
   - Datos crudos.
   - Cálculos propios.
   - Incertidumbre.
   - Revisión antes de carga.

8. **Carga en aplicativo** **[PARTICIPANTE - CARGA EN APLICATIVO]**
   - Campos visibles.
   - Qué diligencia y qué no diligencia.
   - Validación `OK`.

9. **Validación por Calaire** **[CALAIRE - VALIDACIÓN]**
   - Completitud.
   - Coherencia.
   - Duplicados.
   - Incertidumbres.

10. **Procesamiento interno con scripts** **[CALAIRE - PROCESAMIENTO INTERNO]**
    - Scripts.
    - Entradas.
    - Salidas.
    - Logs.

11. **Consolidación de datos** **[CALAIRE - PROCESAMIENTO INTERNO]**
    - Participantes.
    - Referencia.
    - Consolidado completo.
    - Restricciones de divulgación.

12. **Preparación para análisis de aptitud** **[CALAIRE - PROCESAMIENTO INTERNO]**
    - Archivo consolidado.
    - App Shiny/análisis estadístico.
    - Criterios de revisión.

13. **Anexos**
    - Anexo A: Diccionario de campos de la pantalla.
    - Anexo B: Diccionario de columnas internas.
    - Anexo C: Checklist del participante.
    - Anexo D: Checklist de Calaire.
    - Anexo E: Mapa pantalla -> CSV -> análisis.
    - Anexo F: Lista de scripts internos.

## Fases de trabajo

### Fase 1: Cierre de alcance

| Item | Estado | Notas |
|---|---|---|
| Confirmar que la guía será inicialmente interna | Pendiente | Luego puede derivarse versión para participantes. |
| Confirmar nombre oficial: Calaire/CALAIRE | Pendiente | Definir estilo institucional. |
| Confirmar contaminantes iniciales | Pendiente | CO y SO2 observados. |
| Confirmar que la ronda actual usa 3 datos/promedios | Completado | Por ahora son 3, configurable por ronda. |
| Confirmar que el participante no diligencia ronda/nivel/unidad | Completado | Lo muestra/configura el aplicativo. |

### Fase 2: Diccionario de pantalla del participante

| Item | Estado | Notas |
|---|---|---|
| Documentar campos visibles | En progreso | Basado en captura: Corrida, Nivel, Dato 1-3, Promedio, Desv. Est., u(x), u(x) exp, OK. |
| Definir nombre conceptual de cada campo | En progreso | `xi`, `u_xi`, `U_xi`, etc. |
| Definir qué campos calcula el participante | En progreso | Datos/promedios, promedio, desviación estándar, incertidumbres. |
| Definir qué campos configura Calaire | En progreso | Ronda, contaminante, corrida, nivel, unidad, combinaciones. |
| Definir validaciones visibles del aplicativo | Pendiente | Qué significa exactamente `OK`. |

### Fase 3: Procedimiento autónomo del participante

| Item | Estado | Notas |
|---|---|---|
| Redactar conservación de datos crudos | Pendiente | No se cargan, pero respaldan los resultados. |
| Redactar cálculo de tres datos/promedios | Pendiente | Sin imponer una metodología que invalide la aptitud. |
| Redactar cálculo de `xi` | Pendiente | Promedio reportado. |
| Redactar cálculo de desviación estándar | Pendiente | Desviación estándar de los tres datos/promedios. |
| Redactar estimación de `u_xi` | Pendiente | Incertidumbre estándar. |
| Redactar estimación de `U_xi` | Pendiente | Incertidumbre expandida. |
| Redactar uso/recuperación de `k` | Pendiente | `k = U_xi / u_xi`. |
| Redactar checklist antes de envío | Pendiente | Coherencia y completitud. |

### Fase 4: Procedimiento de Calaire basado en scripts

| Item | Estado | Notas |
|---|---|---|
| Inventariar scripts internos | En progreso | Scripts principales ya identificados. |
| Leer scripts principales completos | Pendiente | Especialmente `hourly_averages.R`, `pipeline_calaire.R`, `unir_rondas.R`. |
| Documentar entradas de cada script | Pendiente | `data/raw`, `data/metadata`, etc. |
| Documentar salidas de cada script | Pendiente | `data/processed`, logs. |
| Documentar validaciones automáticas | Pendiente | PASS/WARN/FAIL. |
| Documentar diferencia entre preprocesar y unir | En progreso | Aclarado conceptualmente. |
| Documentar generación de `ronda_1_completa.csv` | Pendiente | Basado en `scripts/unir_rondas.R`. |

### Fase 5: Matriz interno vs participante

| Item | Estado | Notas |
|---|---|---|
| Definir qué va en guía interna | Pendiente | Puede incluir scripts y referencia. |
| Definir qué va en versión participante | Pendiente | No debe incluir referencia ni scripts. |
| Marcar secciones autónomas | En progreso | Ya definidas conceptualmente. |
| Marcar secciones no divulgables | Pendiente | Referencia, criterios internos, logs sensibles. |

### Fase 6: Redacción de la guía

| Item | Estado | Notas |
|---|---|---|
| Crear archivo de guía | Completado | Ubicación: `docs/guia-procedimiento-ronda-participantes.md`. |
| Redactar estructura base | Completado | Según índice propuesto. |
| Redactar procedimiento participante | Completado | Incluido en Secciones 6–7 del documento. |
| Redactar procedimiento Calaire | Completado | Incluido en Secciones 8–11 del documento. |
| Redactar anexos | Completado | Diccionarios, checklists, mapa y lista de scripts. |
| Revisar consistencia terminológica | En progreso | Pendiente revisión formal. |

### Fase 7: Revisión técnica

| Item | Estado | Notas |
|---|---|---|
| Verificar contra CSV actual | En progreso | Brecha `U_xi`/`k` ya identificada. |
| Verificar contra pantalla del aplicativo | En progreso | Captura revisada conceptualmente. |
| Verificar contra scripts | Pendiente | Falta lectura completa de algunos scripts. |
| Verificar que no se divulgue referencia | Pendiente | Crítico. |
| Verificar que no se resuelva la aptitud del participante | Pendiente | Evitar exceso de instrucciones metodológicas. |

## Decisiones tomadas

1. El participante no usa scripts.
2. El participante carga resultados resumidos, no datos crudos.
3. El participante no diligencia ronda, contaminante, corrida, nivel ni unidad; esos campos los configura/presenta el aplicativo.
4. Por ahora la ronda requiere tres datos/promedios por nivel y contaminante.
5. La desviación estándar corresponde a la desviación de los tres datos/promedios.
6. El participante debe reportar `u_xi` como `u(x)`.
7. El participante debe reportar `U_xi` como `u(x) exp`.
8. Calaire necesitará reportar el factor de cobertura `k` posteriormente.
9. El aplicativo/consolidado deberá almacenar más adelante tanto `u_xi` como `U_xi`; la corrección técnica queda para después.
10. `scripts/unir_rondas.R` sirve para consolidar archivos procesados y permitir el ingreso/uso de datos en el aplicativo/análisis; no es un script del participante.

## Preguntas abiertas

1. ¿Cuál es el nombre institucional correcto: Calaire, CALAIRE u otro?
2. ¿Dónde debe ubicarse el documento final en el repositorio?
3. ¿La primera versión será solo interna o también se redactará una versión limpia para participantes?
4. ¿Qué significa exactamente `OK` en la pantalla: completitud, validación numérica, ambas?
5. ¿El aplicativo recalcula `Promedio`, `Desv. Est.` y `u(x) exp`, o solo los valida contra lo ingresado?
6. ¿El participante debe poder editar `Promedio`, `Desv. Est.`, `u(x)` y `u(x) exp`, o algunos son calculados automáticamente por el aplicativo?
7. ¿`U_xi` y `k` se almacenarán por cada nivel/contaminante o una vez por participante/ronda?
8. ¿Qué salidas/logs de los scripts deben conservarse como evidencia formal de procesamiento interno?
9. ¿Qué parte del procedimiento de incertidumbre se puede explicar al participante sin comprometer la evaluación de aptitud?

## Riesgos a controlar

| Riesgo | Mitigación |
|---|---|
| Confundir `u_xi` con `U_xi` | Definir ambos en glosario y en diccionario de campos. |
| No conservar `U_xi` para reporte | Documentar requisito ahora y abrir fase posterior de ajuste del aplicativo. |
| Exponer valores de referencia al participante | Separar guía interna y versión participante. |
| Hacer por el participante cálculos que evalúan su aptitud | Marcar secciones autónomas y limitar ejemplos resueltos. |
| Confundir datos crudos con resultados resumidos | Explicar que los datos crudos se conservan, pero no se cargan en la pantalla actual. |
| Confundir scripts de Calaire con herramientas del participante | Indicar explícitamente que los scripts son internos. |
| Incompatibilidad entre pantalla y CSV actual | Documentar mapeo actual y brecha técnica. |

## Log de Ejecución

- [260519 10:44] Creación del plan inicial para guía de procedimiento de ronda.
- [260519 10:44] Ajuste del plan: el procedimiento de Calaire debe basarse explícitamente en los scripts del repositorio.
- [260519 10:44] Aclaración incorporada: el participante no usará scripts; cargará datos en una plantilla dentro de un aplicativo.
- [260519 10:44] Aclaración incorporada: `scripts/unir_rondas.R` consolida archivos procesados para uso/ingreso en el aplicativo/análisis.
- [260519 10:44] Aclaración incorporada: el participante carga resultados resumidos, no datos crudos.
- [260519 10:44] Aclaración incorporada: la pantalla requiere `Dato 1`, `Dato 2`, `Dato 3`, `Promedio`, `Desv. Est.`, `u(x)` y `u(x) exp`.
- [260519 10:44] Aclaración incorporada: el participante no diligencia ronda, contaminante, corrida, nivel ni unidad.
- [260519 10:44] Brecha registrada: el CSV actual conserva `u_value`, pero no conserva explícitamente `U_xi` ni `k`; se documentará el requisito y se corregirá el aplicativo posteriormente.
- [260519 11:20] Redacción completada de la guía en `docs/guia-procedimiento-ronda-participantes.md`. Fase 6 avanzada: estructura, procedimientos y anexos redactados.
