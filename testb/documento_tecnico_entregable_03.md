# Documento Técnico del Entregable 03 — Cálculos PT (Paquete Standalone)

| | |
|---|---|
| **Proyecto** | PT App — Aplicativo R/Shiny para Ensayos de Aptitud (ISO 13528:2022 e ISO 17043:2023) |
| **Entregable** | 03 — Cálculos PT (Paquete Standalone) |
| **Institución** | Universidad Nacional de Colombia / Instituto Nacional de Metrología |
| **Fecha de emisión** | 2026-06-28 |
| **Versión** | 1.0 |
| **Responsable documental** | Subagente `entregable_03_stat_engine_documenter` |
| **Estado del entregable** | Histórico / requiere alineación con `ptcalc` |
| **Normas de referencia** | ISO 13528:2022 (Secciones 8, 9.2, 9.3, 9.4 y Anexo C); ISO 17043:2023 |

---

## 1. Resumen Ejecutivo

El Entregable 03 constituye el primer núcleo matemático independiente de la interfaz web de la aplicación PT App. Su propósito fue aislar toda la lógica de cálculo estadístico requerida para los ensayos de aptitud —homogeneidad, estabilidad, valor asignado, desviación estándar para evaluación y estadísticos robustos— en scripts R autónomos que pueden entenderse, verificarse y ejecutarse sin depender de botones, pantallas o navegación de la aplicación Shiny.

Este enfoque, denominado "standalone", respondió a una necesidad arquitectónica fundamental: garantizar que las funciones matemáticas no tuvieran dependencias de interfaz, de modo que pudieran someterse a pruebas unitarias con datos patrón y validarse contra los valores teóricos publicados en los anexos de la norma ISO 13528:2022.

El entregable conserva evidencia de una fase anterior del desarrollo. Tras la auditoría de trazabilidad realizada el 2026-06-16, se identificaron divergencias entre estos scripts históricos y la implementación vigente en el paquete `ptcalc/R/`. En particular, el Algoritmo A documentado históricamente emplea una lógica de ponderación tipo Huber, mientras que la implementación actual en `ptcalc/R/pt_robust_stats.R` utiliza el procedimiento de winsorización prescrito en el Anexo C de la norma. Asimismo, el criterio expandido de homogeneidad presenta diferencias de formulación frente a `ptcalc/R/pt_homogeneity.R`.

Por lo anterior, el presente documento describe el contenido entregado, su verificación y su estado actual como material histórico, recomendando utilizar `ptcalc/R/` como referencia operativa vigente y este entregable como evidencia documental del proceso de desarrollo.

---

## 2. Contexto del Entregable

### Fase de desarrollo

El Entregable 03 corresponde a la **Fase 2: Cálculos Standalone** del ciclo de desarrollo de PT App. Esta fase siguió a la Fase 1 (línea base del repositorio, Entregable 01) y precedió a las fases de puntajes (Entregable 04), prototipo de interfaz (Entregable 05), lógica de la aplicación (Entregable 06) y liberación beta (Entregable 08).

### Motivación del aislamiento

En la arquitectura MVC de la aplicación, los cálculos matemáticos deben residir en una capa pura, sin dependencias de Shiny. Esta separación obedece a tres razones:

1. **Verificabilidad:** Las funciones matemáticas pueden probarse con datos de entrada conocidos y comparar sus salidas contra valores teóricos, sin requerir una sesión interactiva de Shiny.
2. **Mantenibilidad:** Los cambios en la lógica estadística se aplican en un único conjunto de scripts, independientes de la capa de presentación.
3. **Trazabilidad normativa:** Cada función puede asociarse directamente a una sección o anexo de la norma ISO 13528:2022, facilitando la auditoría de cumplimiento.

### Subagente designado

El subagente `stat_validator` asumió el rol de *Statistical Engine Developer & Validation Reviewer*, con las responsabilidades de garantizar la fidelidad matemática de las funciones respecto a las ecuaciones de la norma, implementar salvaguardas contra problemas numéricos comunes y asegurar que ninguna función cargara librerías de interfaz o realizara llamadas reactivas de Shiny. Posteriormente, el subagente `entregable_03_stat_engine_documenter` se designó para la actualización documental de trazabilidad.

---

## 3. Alcance

### Cubre

- Scripts R standalone históricos para los cinco ejes de cálculo: homogeneidad, estabilidad, estadísticos robustos, valor asignado y desviación estándar para evaluación.
- Documentación de soporte con un ejemplo de cálculo paso a paso, incluyendo fórmulas detalladas y datos reales del proyecto.
- Pruebas unitarias automatizadas que verifican la precisión numérica de las funciones contra datos teóricos y datos del proyecto.
- Resultados de ejecución de las pruebas, persistidos en formato CSV.

### No cubre

- La implementación vigente en el paquete `ptcalc/R/`, que constituye la referencia operativa actual de la aplicación. Los scripts de este entregable no deben considerarse el motor de cálculo vigente.
- El cálculo de puntajes z y zeta (cubierto por el Entregable 04).
- La lógica de interfaz Shiny (cubierto por el Entregable 06).
- La integración de los cálculos con tableros de visualización (cubierto por el Entregable 07).
- La versión beta liberada de la aplicación (cubierto por el Entregable 08).

---

## 4. Contenido Entregado

### 4.1 Scripts de cálculo (directorio `R/`)

| Archivo | Propósito | Referencia normativa |
|---------|-----------|----------------------|
| `R/homogeneity.R` | Análisis de varianza (ANOVA) para el estudio de homogeneidad: media global, varianza entre y dentro de muestras, componente de varianza entre muestras (s_s), criterios básico y expandido. | ISO 13528:2022 §9.2 |
| `R/stability.R` | Evaluación de estabilidad mediante comparación de medias entre el estudio de homogeneidad y el de estabilidad, con criterios básico y expandido. | ISO 13528:2022 §9.3 |
| `R/robust_stats.R` | Estadísticos robustos: nIQR (rango intercuartílico normalizado), MADe (desviación absoluta mediana escalada) y Algoritmo A iterativo. Incluye detección de valores atípicos. | ISO 13528:2022 §9.4, Anexo C |
| `R/valor_asignado.R` | Determinación del valor asignado (X_pt) por cuatro métodos: referencia, consenso con MADe, consenso con nIQR y Algoritmo A. | ISO 13528:2022 §8 |
| `R/sigma_pt.R` | Estimación de la desviación estándar para evaluación de la aptitud (sigma_pt) por tres métodos: MADe, nIQR y Algoritmo A. Generación de diccionarios sigma_pt para uso en homogeneidad y estabilidad. | ISO 13528:2022 §9.4 |

### 4.2 Documentación de soporte (directorio `md/`)

| Archivo | Propósito |
|---------|-----------|
| `md/ejemplo_calculo_paso_a_paso.md` | Recorrido completo de cálculos manuales para homogeneidad, estabilidad, valor asignado y sigma_pt, con fórmulas detalladas, tablas de datos y resultados numéricos. |
| `ejemplo_calculo_paso_a_paso.docx` | Copia en formato Word del cálculo paso a paso, generada mediante conversión con pandoc. |

### 4.3 Pruebas (directorio `tests/`)

| Archivo | Propósito |
|---------|-----------|
| `tests/test_03_calculos_pt.R` | Tests unitarios automatizados que verifican la precisión numérica del motor matemático contra datos teóricos y datos del proyecto, organizados en bloques: estadísticas robustas, homogeneidad, estabilidad, valor asignado, sigma_pt e integración. |
| `tests/test_03_resultados.csv` | Resultados de ejecución de las pruebas, con métricas clave para el caso CO nivel 2-μmol/mol: sigma_pt, evaluación de criterios de homogeneidad y estabilidad, y valores asignados por cada método. |

---

## 5. Explicación Funcional

Esta sección explica, en lenguaje común, qué cálculos cubre el entregable y por qué fueron separados de la interfaz.

### 5.1 Qué significa "standalone"

El término "standalone" indica que los cálculos pueden entenderse y probarse sin depender de la interfaz web. En la práctica, esto significa que cada función recibe datos de entrada (vectores numéricos o marcos de datos) y retorna resultados numéricos estructurados, sin requiring cargar librerías de Shiny ni ejecutar llamadas reactivas. Esta independencia permite ejecutar las funciones directamente desde la línea de comandos de R o desde scripts de prueba, facilitando su verificación.

### 5.2 Homogeneidad

La homogeneidad responde a la pregunta: ¿son todas las muestras del material de ensayo suficientemente iguales entre sí? La norma ISO 13528:2022 §9.2 establece que el proveedor del ensayo de aptitud debe demostrar que la variación entre muestras no introduce una incertidumbre significativa en los resultados.

El análisis se basa en un diseño experimental de tipo ANOVA: se选取 un número de muestras (g), cada una medida varias veces (m réplicas). A partir de estos datos se calculan:

- La **media global** de todas las mediciones.
- La **varianza entre las medias de las muestras** (s_x_bar²), que refleja cuánto difieren las muestras entre sí.
- La **desviación estándar dentro de las muestras** (s_w), que refleja la variabilidad de las réplicas dentro de cada muestra.
- El **componente de varianza entre muestras** (s_s), que aísla la variación atribuible a diferencias entre muestras, descontando la variación dentro de las muestras.

El criterio de homogeneidad establece que el material es adecuado si s_s no supera el 30% de la desviación estándar para evaluación (sigma_pt). Si no se cumple este criterio básico, puede aplicarse un criterio expandido que incorpora factores de cobertura dependientes del número de muestras y de la desviación estándar dentro de las muestras.

Para un recorrido completo de las fórmulas y los datos utilizados, remítase al documento `ejemplo_calculo_paso_a_paso.docx`.

### 5.3 Estabilidad

La estabilidad responde a la pregunta: ¿permanecen las muestras sin cambios significativos durante el período del ensayo? La norma ISO 13528:2022 §9.3 requiere que el proveedor verifique que las propiedades del material no cambien de manera que afecten la interpretación de los resultados.

El análisis compara la media de las mediciones del estudio de estabilidad con la media del estudio de homogeneidad. La diferencia absoluta entre ambas medias (Delta) se confronta con el mismo criterio que la homogeneidad: el 30% de sigma_pt. Si no se cumple el criterio básico, existe un criterio expandido que incorpora las incertidumbres de ambas medias.

Para las fórmulas detalladas y los datos del ejemplo, remítase a `ejemplo_calculo_paso_a_paso.docx`.

### 5.4 Valor asignado (X_pt)

El valor asignado es el valor de referencia que se utiliza para evaluar el desempeño de los participantes. La norma ISO 13528:2022 §8 establece varios métodos para determinarlo:

1. **Valor de referencia:** Se utiliza el valor conocido o determinado por un método de referencia, por ejemplo, un patrón certificado. En este caso, el valor asignado es el promedio de los resultados del participante de referencia.
2. **Consenso con MADe:** El valor asignado es la mediana de los resultados de los participantes, y la desviación estándar para evaluación se estima mediante MADe (desviación absoluta mediana escalada).
3. **Consenso con nIQR:** Igual que el anterior, pero la desviación estándar se estima mediante nIQR (rango intercuartílico normalizado).
4. **Algoritmo A:** Procedimiento iterativo que combina la mediana como valor inicial y un proceso de ponderación o winsorización que reduce la influencia de los valores atípicos, produciendo simultáneamente el valor asignado y la sigma_pt.

El entregable permite comparar los cuatro métodos para un mismo contaminante y nivel, facilitando la selección del método más apropiado según el contexto del ensayo.

Para el desarrollo paso a paso del Algoritmo A y la comparación de métodos, remítase a `ejemplo_calculo_paso_a_paso.docx`.

### 5.5 Desviación estándar para evaluación (sigma_pt)

La sigma_pt es el valor de referencia contra el cual se evalúan los puntajes de los participantes. Representa la dispersión que se considera aceptable para el ensayo y puede estimarse de tres formas:

- **MADe:** Estimador robusto basado en la mediana de las desviaciones absolutas respecto a la mediana, escalada por un factor que la hace consistente con la desviación estándar de una distribución normal.
- **nIQR:** Estimador robusto basado en el rango intercuartílico, escalado de forma análoga.
- **Algoritmo A:** Produce sigma_pt como parte de su proceso iterativo.

La elección del método depende de las características de los datos y de las preferencias del proveedor del ensayo.

### 5.6 Estadísticos robustos (Algoritmo A, nIQR, MADe)

Los estadísticos robustos son estimadores que producen resultados fiables incluso cuando los datos contienen valores atípicos. En los ensayos de aptitud, los valores atípicos son comunes porque algunos participantes pueden reportar resultados significativamente alejados del consenso, ya sea por errores de medición, problemas de calibración o desviaciones metodológicas.

- **MADe** es altamente resistente a valores atípicos: hasta el 50% de los datos pueden ser atípicos sin que el estimador se afecte de forma significativa.
- **nIQR** ofrece una resistencia similar, basada en los cuartiles en lugar de la mediana.
- **Algoritmo A** es el procedimiento prescrito por la norma ISO 13528:2022 (Anexo C) para combinar la estimación robusta de la ubicación (valor asignado) y la escala (sigma_pt) en un solo proceso iterativo.

El entregable incluye además una función para detectar valores atípicos, usando MADe o nIQR como estimador de escala y un umbral configurable de puntaje z robusto.

---

## 6. Evidencia de Verificación

### 6.1 Cobertura de las pruebas

El script `tests/test_03_calculos_pt.R` contiene pruebas unitarias organizadas en seis bloques temáticos:

| Bloque | Cantidad de casos | Verifica |
|--------|-------------------|----------|
| Estadísticas robustas | 12 casos | nIQR, MADe y Algoritmo A contra datos sintéticos y patrones. Robustez frente a valores atípicos. Manejo de datos insuficientes. Registro de iteraciones y pesos. Detección de valores atípicos. |
| Homogeneidad | 6 casos | Cálculo de estadísticos ANOVA (s_s, s_w, media global, g, m). Criterios básico y expandido. Evaluación positiva y negativa. Análisis completo y manejo de datos inexistentes. |
| Estabilidad | 6 casos | Cálculo de estadísticos de estabilidad (media, diferencia). Criterio básico y expandido. Evaluación positiva y negativa. Análisis completo y manejo de datos inexistentes. |
| Valor asignado | 9 casos | Cuatro métodos (referencia, consenso MADe, consenso nIQR, Algoritmo A). Selección de método, método inválido y procesamiento masivo. |
| Sigma_pt | 7 casos | Tres métodos (MADe, nIQR, Algoritmo A). Selección, método inválido, procesamiento masivo y creación de diccionario. |
| Integración | 3 casos | Flujo completo: sigma_pt → homogeneidad → estabilidad → valor asignado. Comparación de métodos para valor asignado y sigma_pt. |

### 6.2 Criterios verificados

1. **Algoritmo A contra datos patrón:** Las pruebas verifican que el algoritmo produzca valores finitos y positivos para el valor asignado y sigma_pt, que converja dentro del número máximo de iteraciones, que sea robusto a valores atípicos, y que registre las iteraciones y los pesos finales de cada observación.
2. **ANOVA para homogeneidad:** Las pruebas verifican que el análisis determine correctamente las estadísticas ANOVA, que calcule el criterio estándar (s_s menor o igual a 0.3 × sigma_pt) y el criterio expandido, y que emita conclusiones correctas cuando el criterio se cumple y cuando no se cumple.
3. **Comparación de medias para estabilidad:** Las pruebas verifican que el cálculo de la diferencia de medias sea correcto, que el criterio de estabilidad se evalúe adecuadamente en ambos sentidos, y que el análisis completo produzca todos los componentes esperados.

### 6.3 Resultados de ejecución

El archivo `tests/test_03_resultados.csv` contiene los resultados de la ejecución para el caso de CO nivel 2-μmol/mol, incluyendo los valores de sigma_pt, las evaluaciones de criterios de homogeneidad y estabilidad, y los valores asignados por los cuatro métodos. Estos resultados sirven como evidencia de que las funciones se ejecutan de extremo a extremo y producen salidas consistentes.

---

## 7. Estado Actual

### 7.1 Clasificación

**Estado: Histórico / requiere alineación con `ptcalc`.**

Este entregable conserva evidencia de una fase anterior del desarrollo. No representa la versión actual del motor de cálculo de la aplicación.

### 7.2 Divergencias identificadas

La auditoría de trazabilidad del 2026-06-16 identificó las siguientes divergencias entre los scripts históricos de `03_calculos_pt/R/` y la implementación vigente en `ptcalc/R/`:

| Aspecto | Script histórico (`03_calculos_pt/R/`) | Implementación vigente (`ptcalc/R/`) |
|---------|----------------------------------------|--------------------------------------|
| **Algoritmo A** | `robust_stats.R` emplea ponderación tipo Huber: los valores cuyo residual estandarizado excede 1 se ponderan con w = 1/u², y se actualiza x* y s* mediante media y desviación estandar ponderadas. | `pt_robust_stats.R` emplea el procedimiento de winsorización del Anexo C: los valores fuera del intervalo [x* - 1.5·s*, x* + 1.5·s*] se sustituyen por los límites del intervalo, y se actualiza x* como media aritmética y s* como 1.134 veces la desviación estándar muestral. |
| **Criterio expandido de homogeneidad** | `homogeneity.R` calcula c_exp = raíz(f1·(0.3·sigma_pt)² + f2·s_w²) usando una tabla de factores F1/F2 dependientes de g. | `pt_homogeneity.R` ofrece dos formulaciones: una basada en incertidumbre (c_exp = c·raíz(1 + (u_sigma_pt/sigma_pt)²)) y otra basada en la misma tabla F1/F2, pero retornando la suma sin raíz cuadrada, lo que constituye una diferencia operativa relevante. |
| **Cálculo de medianas de diferencias** | `homogeneity.R` utiliza la primera réplica (sample_data[, 1]) para el cálculo de medianas de diferencias. | `pt_homogeneity.R` utiliza la segunda réplica (sample_data[, 2]) para el cálculo de la mediana de diferencias absolutas respecto a x_pt. |
| **Nomenclatura de funciones** | Funciones en español: `calcular_niqr`, `calcular_mad_e`, `ejecutar_algoritmo_a`, `analizar_homogeneidad`, etc. | Funciones en inglés con prefijo pt_*: `calculate_niqr`, `calculate_mad_e`, `run_algorithm_a`, `calculate_homogeneity_stats`, etc. |
| **Estructura del paquete** | Scripts sueltos cargados con `source()`. | Paquete R formal con documentación roxygen2, exportaciones declaradas en NAMESPACE y estructura `ptcalc/`. |

### 7.3 Recomendación de uso

- **Referencia operativa actual:** `ptcalc/R/` (en particular `pt_robust_stats.R` y `pt_homogeneity.R`).
- **Uso de este entregable:** material standalone histórico. Útil para comprender la evolución del motor matemático, como referencia pedagógica del proceso de aislamiento de cálculos, y como punto de partida para auditorías de divergencia.
- **Antes de declarar vigente cualquier función de este entregable:** debe contrastarse contra su equivalente en `ptcalc/R/`, específicamente el Algoritmo A (ponderación Huber vs. winsorización) y el criterio expandido de homogeneidad (raíz de suma cuadrática vs. suma sin raíz cuadrada).

---

## 8. Relación con Otros Entregables

| Entregable | Relación |
|------------|----------|
| **E01 — Línea base** | Establece el repositorio inicial sobre el cual se construyeron los scripts standalone de E03. E03 depende de la estructura de datos y convenciones de codificación definidas en E01. |
| **E04 — Puntajes** | Consumen el valor asignado (X_pt) y sigma_pt producidos por E03 para calcular los puntajes z y zeta de los participantes. La consistencia entre los métodos de sigma_pt de E03 y los puntajes de E04 es un punto de verificación inter-entregable. |
| **E06 — Lógica de la aplicación** | Integra los cálculos de E03 (o sus equivalentes en `ptcalc/R/`) dentro de la lógica reactiva de la aplicación Shiny. E03 constituye la capa subyacente que E06 orquesta. |
| **E08 — Beta** | La versión beta de la aplicación debe utilizar el paquete `ptcalc/R/` como motor de cálculo, no los scripts históricos de E03. E03 sirve como referencia histórica para verificar que la beta cubre la misma funcionalidad cálculo que se implementó originalmente. |
| **E02 — Funciones** | Documenta el inventario de funciones vigentes, incluyendo las de `ptcalc/R/` que reemplazaron a los scripts de E03. E03 y E02 deben consultarse juntos para entender la transición de la arquitectura standalone al paquete formal. |

---

## 9. Riesgos y Limitaciones

1. **Riesgo de uso equivocado como motor vigente:** Si un desarrollador utiliza los scripts de `03_calculos_pt/R/` sin contrastarlos con `ptcalc/R/`, puede obtener resultados numéricamente distintos para el Algoritmo A (ponderación Huber vs. winsorización) y para el criterio expandido de homogeneidad (raíz de suma cuadrática vs. suma sin raíz cuadrada). Este riesgo se mitiga con la clasificación explícita como histórico y con la recomendación documental de usar `ptcalc/R/` como referencia operativa.

2. **Riesgo de divergencia no detectada:** Las divergencias identificadas en la auditoría del 2026-06-16 se centran en el Algoritmo A y el criterio expandido de homogeneidad. No se descartan divergencias adicionales en aspectos no auditados. Una comparación exhaustiva función por función entre `03_calculos_pt/R/` y `ptcalc/R/` es recomendable antes de cualquier reutilización.

3. **Limitación de los datos de prueba:** Los tests se ejecutan sobre datos del proyecto (CO nivel 2-μmol/mol y datos sintéticos). No cubren todos los contaminantes, niveles y casos límite que la aplicación puede encontrar en producción.

4. **Limitación del criterio expandido:** La tabla de factores F1/F2 en `homogeneity.R` cubre valores de g entre 7 y 20. Para g fuera de este rango, el valor se ajusta al extremo más cercano (7 o 20), lo que introduce una aproximación que debe considerarse al interpretar resultados con un número de muestras fuera de ese intervalo.

5. **Honestidad documental:** Este entregable conserva evidencia de una fase anterior del desarrollo y no representa la versión actual del motor de cálculo. Cualquier afirmación de vigencia debe respaldarse con una verificación formal contra `ptcalc/R/`.

---

## 10. Documentos de Consulta

| Documento | Ubicación | Relación |
|-----------|-----------|----------|
| Overview del Entregable 03 | `Entregables_pt_app/e3.md` | Descripción general y inventario de archivos |
| Ejemplo de cálculo paso a paso | `Entregables_pt_app/03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md` y `.docx` | Fórmulas detalladas y datos del ejemplo |
| Tests unitarios | `Entregables_pt_app/03_calculos_pt/tests/test_03_calculos_pt.R` | Script de pruebas automatizadas |
| Resultados de tests | `Entregables_pt_app/03_calculos_pt/tests/test_03_resultados.csv` | Métricas clave de ejecución |
| Implementación vigente de robustos | `ptcalc/R/pt_robust_stats.R` | Referencia operativa actual del Algoritmo A |
| Implementación vigente de homogeneidad | `ptcalc/R/pt_homogeneity.R` | Referencia operativa actual de homogeneidad y estabilidad |
| Bitácora de actualización | `Entregables_pt_app/bitacora_actualizacion_260616.md` | Registro de divergencias y acciones aplicadas |
| ISO 13528:2022 | Norma internacional | Statistical methods for use in proficiency testing by interlaboratory comparison |
| ISO 17043:2023 | Norma internacional | General requirements for the competence of proficiency testing scheme providers |

---

## 11. Conclusión

El Entregable 03 documenta el primer núcleo matemático independiente de la interfaz, aislado para garantizar su verificabilidad y trazabilidad normativa. Cubre cinco ejes de cálculo —homogeneidad, estabilidad, estadísticos robustos, valor asignado y sigma_pt— con pruebas unitarias que verifican la precisión numérica contra datos patrón y datos del proyecto.

Sin embargo, este material conserva evidencia de una fase anterior del desarrollo y no representa la versión actual del motor de cálculo. Las divergencias identificadas entre los scripts históricos y la implementación vigente en `ptcalc/R/` —especialmente en el Algoritmo A (ponderación Huber vs. winsorización) y en el criterio expandido de homogeneidad— exigen que cualquier reutilización se preceda de un contraste técnico riguroso frente a la referencia operativa actual.

Se recomienda, por tanto, tratar este entregable como evidencia histórica útil para comprender la evolución del motor matemático y como punto de partida para auditorías de divergencia, utilizando `ptcalc/R/` como fuente operativa vigente para toda funcionalidad en producción.