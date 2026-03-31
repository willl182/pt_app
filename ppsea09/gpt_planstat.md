# Planificación estadística de un ensayo de aptitud con pocos participantes según ISO 13528 e ISO/IEC 17043

## Resumen ejecutivo

Un ensayo de aptitud (EPT/PT) con **pocos participantes** es estadísticamente viable, pero **cambia el enfoque**: la prioridad pasa de “estimar consenso interlaboratorio con precisión” a **garantizar trazabilidad del valor asignado, robustez del criterio de evaluación y control explícito de incertidumbres**. ISO 13528 enfatiza que el diseño y las técnicas estadísticas deben ser apropiadas para el propósito declarado y subraya ventajas de **criterios y valores asignados independientes de los resultados de participantes**, especialmente para evitar circularidad y variabilidad entre rondas. citeturn3view0

Las referencias más influyentes para “pocos participantes” son:  
- **ISO 13528:2022** (métodos estadísticos para diseño/análisis; incluye consideraciones para pocos participantes y hasta ejemplos de *bootstrapping*). citeturn3view0turn8search7  
- **ISO/IEC 17043:2023** (requisitos del proveedor: objetivos del esquema, diseño estadístico, determinación de valores asignados, evaluación de homogeneidad/estabilidad, análisis de datos, evaluación del desempeño y reporte). citeturn22view1turn4view0  
- **IUPAC/CITAC (2010)** para esquemas con *n* “limitado”: caracteriza “pequeños” como **N < 30**, advierte que la confiabilidad cae fuerte **para N < 20**, y recomienda evitar puntuar con consenso simple; propone un enfoque metrológico con valores asignados trazables (p. ej., CRM) y desviación objetivo externa (fitness-for-purpose). citeturn14view2turn14view1  
- **EA-4/21 INF:2018** (guía para comparaciones interlaboratorio muy pequeñas, **máximo 7 laboratorios**; exige plan documentado con mensurando, homogeneidad/estabilidad, valor asignado e incertidumbre, SDPA “fit-for-purpose”, método estadístico y criterios). citeturn6view0  
- **Eurachem 2021** (criterios prácticos para interpretar resultados: si **u(x_pt) < 0.3·σ_pt** la incertidumbre del valor asignado suele considerarse despreciable; si no, usar **z′, ζ o E_n**). citeturn12view1  
- Evidencia reciente y didáctica: el **z-score por sí solo puede ocultar sesgos**; se recomienda complementar con **ζ** e incorporar la incertidumbre reportada por el laboratorio. citeturn19view0  

Recomendación central para pocos participantes: **(i)** preferir valor asignado “externo” (CRM/valor de referencia/lab de referencia) con incertidumbre explícita; **(ii)** fijar **σ_pt (SDPA)** por fitness‑for‑purpose o evidencia previa, no por la dispersión observada de pocos resultados; **(iii)** diseñar el EPT para “aumentar información” (replicados, pares Youden/split samples, más de un ítem por participante) y reportar incertidumbres; **(iv)** cuantificar incertidumbre y sensibilidad con intervalos de confianza, *bootstrap* o métodos bayesianos cuando corresponda. citeturn14view1turn3view0turn12view1turn24view0turn26view0  

## Alcance, terminología y supuestos críticos

Este informe se centra en **EPT cuantitativos** (resultados en escala de intervalo o razón), donde se evalúa el desempeño frente a un **valor asignado** y un **criterio preestablecido**. ISO 13528 aplica a resultados cuantitativos y cualitativos, pero los métodos (y riesgos) difieren; ISO 13528 dedica un capítulo específico a esquemas cualitativos. citeturn3view0turn8search3  

Terminología mínima (según ISO 13528 / ISO/IEC 17043):  
- **Ensayo de aptitud (proficiency testing)**: evaluación del desempeño de participantes frente a criterios preestablecidos mediante comparaciones interlaboratorio. citeturn3view0turn4view0  
- **Valor asignado** (*x_pt*): valor atribuido a una propiedad del ítem del EPT. citeturn3view0turn4view0  
- **SDPA / σ_pt** (standard deviation for proficiency assessment): medida de dispersión usada en la evaluación; puede interpretarse como la desviación estándar de una población hipotética de laboratorios “cumpliendo requisitos”. citeturn3view0turn4view0  
- **Atípico (outlier)**: valor inconsistente con el resto; ISO/IEC 17043 advierte que “outlier” no es sinónimo de “señal de acción” (puede haber señales sin ser outliers). citeturn4view0  

### “Pocos participantes” no está fijado por ISO: propuesta operativa (con incertidumbre explícita)

La palabra **“bajo”** fue solicitada como **no especificada**. Para planificación, conviene convertirla en rangos de decisión basados en guías primarias:

- **N < 30**: IUPAC/CITAC denomina estos esquemas “pequeños” y recomienda cuidados adicionales; incluye una “zona gris” 20 ≤ N < 30 porque puede afectar planificación e interpretación. citeturn14view2turn14view1  
- **N < 20**: IUPAC/CITAC advierte que la confiabilidad estadística empeora notablemente; identificar no-normalidad es más difícil y “robust statistics are not usually recommended when N < 20”. citeturn14view1  
- **N ≤ 7**: EA‑4/21 trata “small ILC” (comparaciones muy pequeñas) con máximo 7 laboratorios y exige plan/criterios claros; **no sustituye** ISO/IEC 17043 para acreditar proveedores, pero es una guía potente de “mínimos” cuando N es muy bajo. citeturn6view0  

**Supuestos no especificados por el usuario** (y que afectan decisiones): tipo de mensurando y matriz, heterogeneidad esperada, si hay CRM disponible, si participantes reportarán incertidumbre, nivel de confianza requerido (usaré **95%** como convención cuando se necesiten intervalos), y si el objetivo es vigilancia interna, acreditación, o decisión regulatoria (riesgo). ISO/IEC 17043 exige que el proveedor opere competentemente y genere evaluaciones válidas, y que gestione riesgos/oportunidades; por tanto estos supuestos deben documentarse. citeturn4view0  

## Objetivos del EPT con foco estadístico y metrológico

En ISO 13528, los propósitos típicos del EPT incluyen: evaluar desempeño, identificar problemas, establecer efectividad y comparabilidad de métodos, dar confianza a clientes, validar declaraciones de incertidumbre y educar a participantes; y explícitamente indica que el diseño y las técnicas estadísticas **“shall be appropriate”** para los propósitos declarados. citeturn3view0  

ISO/IEC 17043 refuerza que el EPT es una herramienta esencial para demostrar competencia y puede indicar problemas emergentes; el estándar busca promover confianza en proveedores capaces de generar evaluaciones válidas. citeturn4view0  

Para pocos participantes, conviene redactar objetivos en dos niveles:

**Objetivos técnicos (del mensurando)**  
1) Evaluar sesgo y precisión interlaboratorio vs un valor de referencia o asignado (cuando sea posible trazable). citeturn14view1turn12view1  
2) Detectar discrepancias sistemáticas (tendencia, sesgo) y aleatorias (dispersión) usando diseños informativos (replicados, pares Youden). citeturn8search3turn21view0  

**Objetivos metrológicos (comparabilidad/compatibilidad)**  
3) Asegurar **comparabilidad** vía trazabilidad del valor asignado (especialmente importante si N es pequeño y el consenso no es estable). citeturn14view2turn14view1  
4) Evaluar consistencia con incertidumbres reportadas (ζ, E_n) cuando el esquema requiera/permita incertidumbre. citeturn12view1turn19view0turn20view0  

**Objetivos de gestión y mejora**  
5) Usar resultados para acciones correctivas/preventivas y aprendizaje (ISO/IEC 17043 también contempla control de trabajo no conforme; Eurachem subraya investigar resultados insatisfactorios o repetidamente cuestionables). citeturn22view0turn11view0  
6) Enfatizar desempeño en el tiempo: un resultado “bueno” aislado tiene bajo poder para demostrar competencia; se requiere mirada multi‑ronda. citeturn20view0  

## Requisitos normativos clave de ISO/IEC 17043 e ISO 13528 aplicables a diseño y análisis

### Requisitos estructurales de “qué debe existir” (ISO/IEC 17043)

ISO/IEC 17043:2023 organiza requisitos en: imparcialidad, confidencialidad, requisitos estructurales, recursos y **requisitos de proceso**. En los de proceso, exige explícitamente (encabezados):  
- establecer/contratar/comunicar **objetivos** del esquema (7.1),  
- **diseño y planificación** (7.2) incluyendo **diseño estadístico** (7.2.2) y **determinación de valores asignados** (7.2.3),  
- producción/distribución de ítems (7.3) incluyendo **evaluación de homogeneidad y estabilidad** (7.3.2),  
- evaluación y reporte (7.4) incluyendo **análisis de datos** y **evaluación del desempeño**,  
- control del proceso y manejo de trabajo no conforme (7.5). citeturn22view1turn22view0  

Además, ISO/IEC 17043 incorpora un enfoque de **riesgos y oportunidades** en el sistema de gestión. citeturn4view0turn22view2  

**Implicación para pocos participantes:** el estándar no “prohíbe” N bajos, pero sí eleva la exigencia de **justificar** el diseño estadístico, el valor asignado, la SDPA y el tratamiento de incertidumbre/atípicos, porque la fragilidad estadística es un riesgo operativo que debe gestionarse. citeturn4view0turn22view1  

### ISO 13528 como “manual estadístico” complementario

ISO 13528:2022 se presenta como complementaria de ISO/IEC 17043, dando guía detallada para diseño estadístico, validación de ítems, revisión de resultados y reporte de estadísticas resumen. citeturn3view0turn8search7  

Aspectos especialmente relevantes para pocos participantes (por estructura de la norma):  
- guía de **diseño estadístico** y una sección específica “**considerations for small numbers of participants**” (5.4); citeturn8search3  
- revisión inicial: homogeneidad/estabilidad, remoción de “blunders”, revisión visual, métodos robustos y técnicas de outliers (cap. 6); citeturn8search3  
- métodos para determinar valor asignado y su incertidumbre, incluyendo CRM y consenso de participantes/expertos (cap. 7); citeturn8search3turn3view0  
- determinación de criterios de evaluación (cap. 8), incluyendo uso de experiencia previa, modelos generales y datos de la misma ronda; citeturn8search3  
- estadísticas de desempeño: **z, z′, ζ, E_n** y evaluación de incertidumbres reportadas (cap. 9). citeturn8search3turn12view1turn20view0  
- herramientas gráficas: histograma, densidad kernel, barras de scores, **Youden plot**, “split samples” (cap. 10). citeturn8search3turn21view0  
- *bootstrapping*: ISO 13528 incluye un anexo con ejemplo de código para análisis por remuestreo. citeturn3view0  

### Punto normativo crítico: competencia estadística

ISO 13528 explicita que ISO/IEC 17043 requiere acceso a **experticia estadística** y personal autorizado para análisis. citeturn3view0  
Con pocos participantes, esta exigencia se vuelve práctica: sin criterio experto, es fácil caer en (i) desvíos circulares (valor asignado y σ_pt “inventados” desde pocos datos) o (ii) decisiones demasiado fuertes con evidencia débil.

## Riesgos, limitaciones y mitigaciones cuando el número de participantes es bajo

### Qué se vuelve frágil (y por qué)

**Consenso como valor asignado**: en esquemas pequeños, la incertidumbre del consenso crece y puede afectar la puntuación. IUPAC/CITAC indica que con N < 30 el valor asignado/certificado no puede calcularse “de forma segura” como consenso porque la incertidumbre se vuelve suficientemente grande para afectar scores; además recomienda evitar valores consenso simples en esquemas pequeños. citeturn14view2turn14view1  

**Estimación de dispersión interlaboratorio (SD) con pocos datos**: la variabilidad del estimador de SD es alta. IUPAC/CITAC muestra (con base en intervalos tipo χ²) que incluso para N = 30 la SD muestral puede diferir del valor poblacional por >25% relativo al 95% de confianza, y que la diferencia crece dramáticamente para N < 20. citeturn14view1  

**Robustez vs tamaño muestral**: aunque los métodos robustos reducen influencia de valores extremos, IUPAC/CITAC advierte que “robust statistics are not usually recommended when N < 20” (por inestabilidad y baja capacidad diagnóstica). citeturn14view1  

**Detección de multimodalidad/subpoblaciones**: con N pequeño es difícil distinguir si hay dos métodos dominantes, problemas de matriz, etc. IUPAC/CITAC resalta que desviaciones de normalidad son más difíciles de identificar si N es pequeño. citeturn14view1  

**Riesgo de falsa aceptación**: literatura de comparaciones pequeñas muestra alto riesgo de “falsely accepting results” y baja eficacia de métodos dedicados a muestras pequeñas para detectar discrepancias, especialmente cuando no hay valor asignado confiable. citeturn25view0  

### Mitigaciones recomendadas (alineadas con ISO 13528/17043)

Mitigar no significa “forzar estadística”, sino rediseñar el esquema para asegurar trazabilidad y aumentar información:

1) **Preferir valor asignado independiente** (CRM, valor de referencia, laboratorio de referencia, formulación) cuando N es pequeño. ISO 13528 enfatiza que valores asignados y criterios independientes suelen ofrecer ventajas, especialmente para el criterio de evaluación. citeturn3view0turn14view1  
2) **Fijar σ_pt por fitness‑for‑purpose** o evidencia previa (no por SD observada de la ronda), para consistencia entre rondas. Eurachem también recomienda que la SDPA preferiblemente se base en fitness‑for‑purpose para que los scores sean comparables en el tiempo. citeturn12view1turn20view0  
3) **Aumentar información por participante**: más de un ítem, replicados, o pares Youden/split samples (ISO 13528 contempla Youden plot y split samples). citeturn8search3turn21view0  
4) **Incorporar incertidumbre del valor asignado en la evaluación** cuando no sea despreciable: criterio práctico u(x_pt) < 0.3·σ_pt (si no se cumple, usar z′/ζ/E_n). citeturn12view1turn20view0turn19view0  
5) **Gestionar outliers con enfoque metrológico**: IUPAC/CITAC señala que, si no se usa consenso y no se puntúa con SD observada, el manejo de outliers es menos crítico para el cálculo del valor asignado y de σ_pt; afecta principalmente al laboratorio outlier y al análisis de causa. citeturn14view4  

## Métodos estadísticos recomendados para muestras pequeñas y su implementación

Esta sección propone un “menú” con preferencia por métodos compatibles con ISO 13528 (robustos, control de u(x_pt), *bootstrap*) y extensiones (bayesiano) cuando la evidencia es escasa.

### Tabla comparativa de métodos estadísticos para EPT con pocos participantes

| Problema | Método recomendado | Supuestos principales | Ventajas en N bajo | Riesgos / advertencias | Soporte normativo / bibliografía |
|---|---|---|---|---|---|
| Valor asignado cuando existe referencia | **x_pt = valor certificado/valor de referencia** (CRM o lab de referencia) + **u(x_pt)** | Trazabilidad y validez del valor de referencia | Reduce circularidad; u(x_pt) conocido; adecuado incluso con N muy bajo | Requiere disponibilidad y control metrológico del valor | IUPAC/CITAC recomienda CRM para N limitado citeturn14view2; ISO 13528 contempla CRM citeturn8search3turn3view0 |
| Valor asignado sin referencia, N moderado | **Consenso robusto** (mediana; Algorithm A ISO 13528) + **u(x_pt)** | Distribución no extremadamente multimodal; suficientes datos | Menos sensible a outliers que la media | IUPAC/CITAC: robustos “no usualmente recomendados” si N<20; u(x_pt) puede ser grande y afectar scores citeturn14view1turn12view1 | ISO 13528: robust methods + assigned value from participant results citeturn8search3turn3view0 |
| Criterio de evaluación (σ_pt/SDPA) estable | **σ_pt “fit‑for‑purpose”** (normativa, requisitos del cliente, modelo general, experiencia histórica) | Definición clara de “aptitud para el uso” | Estable entre rondas; evita esconder problemas cuando N es pequeño | Requiere consenso sectorial o justificación técnica | ISO 13528: criterios por expertos/experiencia/modelos/estudios previos citeturn8search3turn3view0; Eurachem recomienda fitness-for-purpose citeturn12view1 |
| Estimar incertidumbre del valor asignado u(x_pt) desde participantes | Fórmulas tipo **u(x_pt) ≈ 1.253·s*/√p** (para mediana) o error estándar con robustos | Aproximación (normalidad local / robustez) | Da una regla rápida para decidir z vs z′ | Con N pequeño, u(x_pt) puede violar u(x_pt)<0.3σ_pt y forzar z′/ζ/E_n | Eurachem da u(x_pt)=1.253·s*/√p citeturn12view3 |
| Intervalos/IC con pocos datos | **IC t/χ²** (si supuestos razonables) + **bootstrap** | Dependiente del estadístico | Transparencia de incertidumbre; útil para reportar “confianza” | IC paramétricos frágiles si no-normalidad; bootstrap puede ser inestable con N muy pequeño | ISO 13528 incluye *bootstrapping* (anexo) citeturn3view0; IUPAC/CITAC discute efectos de N en sesgo/SD citeturn14view1 |
| Cuando hay información previa (rondas anteriores, población pequeña, expertos) | **Bayesiano jerárquico** (shrinkage) para valor consenso y varianzas | Priors justificables; modelo jerárquico | “Presta fuerza” de información previa; estabiliza estimaciones con N bajo | Sensible a priors mal elegidas; requiere competencia estadística | En PT, se propone combinar conocimiento experto e info auxiliar para estimar consenso e incertidumbre citeturn24view0turn26view0 |
| Evaluar desempeño con incertidumbres | **ζ-score** y/o **E_n** (calibración) además de z/z′ | Requiere u(x_i) y u(x_pt) (o U) | Detecta sesgo oculto por z; fuerza revisión de incertidumbre | Riesgo de manipulación si u(x_i) inflada; E_n requiere coherencia de factores de cobertura | Eurachem define y umbrales citeturn12view1; z solo puede ocultar sesgo, se recomienda ζ citeturn19view0turn20view0 |

### Scoring recomendado y reglas de decisión (z, z′, ζ, E_n)

Eurachem resume los scores más usados y sus umbrales típicos:  
- **z** = (x_i − x_pt)/σ_pt. citeturn12view1  
- **z′** incorpora u(x_pt) cuando la incertidumbre del valor asignado no es despreciable: si **u(x_pt) > 0.3·σ_pt** suele considerarse necesario ajustar (z′). citeturn12view1turn20view0  
- **ζ** compara desviación contra incertidumbres combinadas (u(x_i), u(x_pt)). citeturn12view1turn19view0  
- **E_n** usa incertidumbres expandidas (frecuente en calibración); requiere coherencia de factores de cobertura. citeturn12view1turn20view0  

Interpretación típica (z, z′, ζ): |score| ≤ 2 satisfactorio; 2 < |score| < 3 cuestionable; |score| ≥ 3 insatisfactorio. citeturn12view1turn19view0  
Para E_n: |E_n| ≤ 1 suele considerarse aceptable. citeturn12view1turn20view0  

**Advertencia clave (sobre todo en N bajo):** z-score no debe leerse como “prueba” de competencia; es más potente para evidenciar mala performance que para demostrar buena performance, y requiere análisis longitudinal. citeturn20view0  

### Tratamiento de valores atípicos con pocos datos

En N bajo, el objetivo no es “limpiar” agresivamente; es evitar decisiones sesgadas y preservar trazabilidad.

- **Regla operativa**:  
  - **No excluir** resultados salvo evidencia de “blunder” (unidad equivocada, transcripción, método no permitido, incumplimiento de instrucciones). ISO 13528 contempla “blunder removal” (cap. 6) como parte de la revisión inicial. citeturn8search3  
  - Si el valor asignado es externo (CRM) y σ_pt es externo, un outlier **no distorsiona** x_pt ni σ_pt; su impacto se limita a la evaluación del laboratorio. IUPAC/CITAC indica que en el enfoque metrológico el manejo de outliers es “menos importante” porque no se calcula x_pt por consenso ni se basa el score en SD observada. citeturn14view4turn14view1  

- **Si el valor asignado depende de participantes (evitar si N<20)**: usar estadísticos robustos (mediana, Algorithm A) y *bootstrap* para u(x_pt), reportando sensibilidad “con y sin” puntos extremos (sin excluir, solo como análisis). ISO 13528 incluye métodos robustos y *bootstrapping* como herramientas disponibles. citeturn8search3turn3view0  

### Diseño estadístico: aumentar información cuando N es bajo

ISO/IEC 17043 exige diseño estadístico y evaluación de homogeneidad/estabilidad; ISO 13528 provee guía detallada y herramientas. citeturn22view1turn3view0turn8search3  

Estrategias especialmente efectivas con pocos participantes:

1) **Más de un ítem por participante (pares tipo Youden / “split samples”)**  
   - Beneficio: separa visualmente error dentro‑laboratorio vs entre‑laboratorio (Youden plot fue concebido para usar dos resultados por laboratorio). citeturn21view0turn8search3  
2) **Replicados por ítem** (al menos duplicados)  
   - Permite estimar repetibilidad interna y usar modelos de componentes de varianza (ANOVA aleatoria / REML / Bayesiano). ISO 13528 contempla el reporte de replicados y gráficos de SD de repetibilidad. citeturn8search3  
3) **Rondas múltiples más cortas** (en vez de una única ronda grande)  
   - Beneficio: aumenta poder de detección de sesgo/variabilidad a través del tiempo y se alinea con la recomendación de análisis longitudinal (no “league tables”). citeturn20view0turn9view0  
4) **Bloqueo por método/matriz**  
   - Si se permiten métodos distintos, planear estratificación y/o subpoblaciones (Eurachem propone reportar valores separados por subpoblación si la incertidumbre alta se debe a diferencias sistemáticas). citeturn12view0  

### Homogeneidad y estabilidad: criterios prácticos (críticos en N bajo)

La contribución de inhomogeneidad/instabilidad puede dominar el error cuando N es pequeño; por eso debe controlarse antes.

Un criterio ampliamente usado para “homogeneidad suficiente” fija como límite que la SD de muestreo no exceda **0.3·σ_p** (σ_p ~ σ_pt objetivo), para que la inflación en z-scores sea pequeña. En el Protocolo Armonizado IUPAC 2006 se explicita σ_all = 0.3·σ_p como criterio. citeturn10view0  

También recomienda que el método analítico usado en el test de homogeneidad tenga precisión de repetibilidad suficiente (σ_an/σ_p < 0.5). citeturn10view0  

ISO/IEC 17043, a nivel de requisito, exige evaluación de homogeneidad y estabilidad del ítem (7.3.2), y que todo esto esté planificado. citeturn22view1turn6view0  

## Plantillas, ejemplos numéricos y recomendaciones paso a paso

### Flujo recomendado de planificación/análisis (mermaid)

```mermaid
flowchart TD
  A[Definir objetivos del EPT y el mensurando] --> B[Elegir estrategia de valor asignado x_pt]
  B --> C{¿Existe valor de referencia/CRM o lab de referencia?}
  C -- Sí --> D[Usar x_pt trazable + u(x_pt)]
  C -- No --> E[Plan de consenso robusto + u(x_pt) + análisis de sensibilidad]
  D --> F[Definir σ_pt (SDPA) fit-for-purpose]
  E --> F
  F --> G[Diseñar ítems: #muestras, replicados, split samples/Youden]
  G --> H[Plan de homogeneidad y estabilidad + criterios]
  H --> I[Instrucciones a participantes: método, reporte, incertidumbre, formato]
  I --> J[Recepción y revisión inicial: blunders, revisión visual]
  J --> K[Análisis estadístico ISO 13528: x_pt, u(x_pt), σ_pt, scores]
  K --> L{¿u(x_pt) < 0.3·σ_pt?}
  L -- Sí --> M[Usar z (y ζ/En si aplica)]
  L -- No --> N[Usar z′/ζ/En y advertir limitaciones]
  M --> O[Reporte + acciones correctivas + tendencia multi-ronda]
  N --> O
```

Fundamento: ISO/IEC 17043 exige objetivos, diseño estadístico, determinación de valores asignados, homogeneidad/estabilidad, análisis, evaluación y reporte. citeturn22view1turn22view0  
ISO 13528 refuerza la necesidad de que el diseño/analítica sea apropiado al propósito y discute ventajas de independencia de x_pt y criterios. citeturn3view0  

### Ejemplo numérico: cómo N bajo puede “esconder” un problema si σ_pt proviene de la ronda

**Datos (N = 8)**: resultados de concentración (mg/L):  
10.10, 9.90, 10.05, 10.30, 9.70, 10.15, 10.00, 12.00

**Escenario A (recomendado en N bajo):** valor asignado externo y σ_pt fit‑for‑purpose  
- x_pt = 10.00 mg/L (p. ej., CRM o valor de referencia)  
- σ_pt = 0.30 mg/L (requisito de aptitud)

**Escenario B (peligroso en N bajo):** x_pt = media de participantes, σ_pt = SD observada  
- x_pt = 10.275 mg/L  
- SD observada ≈ 0.719 mg/L (inflada por el outlier)

| Lab | x_i (mg/L) | z con x_pt=10.00, σ_pt=0.30 | z con x_pt=10.275, σ=0.719 |
|---|---:|---:|---:|
| L1 | 10.10 | 0.33 | -0.24 |
| L2 | 9.90 | -0.33 | -0.52 |
| L3 | 10.05 | 0.17 | -0.31 |
| L4 | 10.30 | 1.00 | 0.03 |
| L5 | 9.70 | -1.00 | -0.80 |
| L6 | 10.15 | 0.50 | -0.17 |
| L7 | 10.00 | 0.00 | -0.38 |
| L8 | 12.00 | **6.67** | **2.40** |

Interpretación típica: en Escenario A L8 es claramente **insatisfactorio** (|z| ≥ 3). En Escenario B, el mismo resultado queda solo “cuestionable” (2 < |z| < 3), porque la SD de la ronda se infló por el propio dato extremo. Esto ilustra una razón por la cual ISO 13528 advierte ventajas de criterios independientes y por la cual IUPAC/CITAC desaconseja basar evaluación en SD observada, especialmente en esquemas pequeños. citeturn3view0turn14view1turn14view2  

### Ejemplo numérico: u(x_pt) no despreciable y elección de z′

Suponga ahora que NO hay CRM y se usa consenso robusto (mediana) con N = 8:  
- mediana x_pt = 10.075 mg/L  
- estimación robusta de dispersión s* ≈ 0.185 mg/L (por MAD escalada)  
- Eurachem da una aproximación para la incertidumbre del valor asignado (mediana):  
  **u(x_pt) ≈ 1.253·s*/√p** → u(x_pt) ≈ 0.082 mg/L (p=8). citeturn12view3  

Si el esquema define σ_pt = 0.20 mg/L (más exigente), entonces:  
- 0.3·σ_pt = 0.06 mg/L  
- u(x_pt) = 0.082 > 0.06 ⇒ **u(x_pt) no es despreciable**: se recomienda usar z′ o ζ/E_n. citeturn12view1turn20view0  

Esto es exactamente el tipo de situación que aparece con N bajo: el consenso tiene incertidumbre suficiente para afectar la clasificación, y un diseño robusto debe preverlo.

### Plantilla de cálculo (scores e ingredientes mínimos)

**Entradas por ronda (mínimas):**
- Resultados participantes: x_i  
- Valor asignado: x_pt  
- Incertidumbre del valor asignado: u(x_pt) (o U(x_pt))  
- SDPA: σ_pt  
- (Opcional pero recomendado) Incertidumbre participante: u(x_i) (o U(x_i))

**Cálculos:**
- z_i = (x_i − x_pt)/σ_pt citeturn12view1turn20view0  
- z′_i = (x_i − x_pt)/√(σ_pt² + u(x_pt)²) citeturn12view1turn20view0  
- ζ_i = (x_i − x_pt)/√(u(x_i)² + u(x_pt)²) citeturn12view1turn19view0  
- E_n,i = (x_i − x_pt)/√(U(x_i)² + U(x_pt)²) (calibración; coherencia de factores de cobertura) citeturn12view1turn20view0  

**Chequeo clave previo a decidir score principal:**  
- Si u(x_pt) < 0.3·σ_pt ⇒ u(x_pt) despreciable (típicamente) y z es interpretable sin ajuste. citeturn12view1turn20view0turn19view0  

### Plantilla de plan estadístico del EPT (lista de verificación “lista para auditoría”)

| Sección | Contenido mínimo | Decisiones específicas para N bajo |
|---|---|---|
| Propósito y alcance | objetivo(s), mensurando, matriz, nivel/rango, población de participantes | definir explícitamente si el fin es vigilancia interna, acreditación, regulatorio (riesgo) citeturn4view0turn3view0 |
| Definición de “pocos participantes” | rango N esperado y justificación | usar referencias: N<30 “small schemes” (IUPAC/CITAC) y si aplica N≤7 (EA-4/21) citeturn14view2turn6view0 |
| Diseño del esquema | #ítems por participante, replicados, split samples/Youden, cronograma | aumentar información por participante; priorizar pares Youden cuando N muy bajo citeturn8search3turn21view0 |
| Estrategia de valor asignado x_pt | CRM / lab referencia / formulación / consenso robusto | si N<20, evitar consenso como x_pt salvo imposibilidad; si se usa, obligar u(x_pt) y z′/ζ citeturn14view1turn12view1 |
| Estimación de u(x_pt) | presupuesto de incertidumbre, componentes (homogeneidad, estabilidad) | declarar regla u(x_pt)<0.3σ_pt; si no, cambiar score o rediseñar citeturn12view1turn10view0 |
| Definición de σ_pt (SDPA) | fitness-for-purpose / modelo / datos históricos | evitar σ_pt desde SD observada en N bajo; justificar en términos de aptitud citeturn14view1turn20view0turn8search3 |
| Homogeneidad y estabilidad | plan de muestreo, método, criterios de aceptación | criterio típico: SD de muestreo ≤ 0.3·σ_pt y método con σ_an/σ_p<0.5 citeturn10view0turn22view1 |
| Manejo de datos atípicos/blunders | reglas de exclusión (predefinidas), evidencias requeridas | con N bajo, minimizar exclusión; priorizar robustez y trazabilidad citeturn14view4turn8search3 |
| Estadística de desempeño | z vs z′ vs ζ vs E_n; umbrales; reportes | recomendar ζ cuando se reportan incertidumbres; z solo puede ocultar sesgo citeturn19view0turn12view1 |
| Incertidumbre y comunicación | IC, bootstrap, sensibilidad | ISO 13528 contempla *bootstrapping* (útil para u(x_pt) y robustos) citeturn3view0 |
| Reporte final | contenido mínimo, gráficos, conclusiones, limitaciones | incluir advertencias por N bajo, enfoque longitudinal (no ranking) citeturn20view0turn9view0turn22view1 |

EA‑4/21 además lista elementos mínimos de un plan (contacto, participantes, mensurando, requisitos de homogeneidad/estabilidad, método estadístico y criterios, formato de reporte), muy útil como checklist. citeturn6view0  

### Recomendaciones prácticas paso a paso para implementar un EPT con pocos participantes

**Paso: fijar lo que no puede salir de la muestra (reduce fragilidad)**  
1) Defina σ_pt por fitness‑for‑purpose (requisito del cliente/regulador, experiencia histórica, modelo), no por la SD de la ronda. ISO 13528 y guías (Eurachem, AMC) resaltan que el criterio debe ser consistente e interpretarse como aptitud. citeturn3view0turn12view1turn20view0  
2) Busque valor asignado externo (CRM, lab de referencia). Para N limitado, IUPAC/CITAC lo recomienda explícitamente. citeturn14view2turn14view1  

**Paso: diseñar para “extraer más información por laboratorio”**  
3) Si N ≤ 10–15, use **dos ítems por laboratorio** (pares Youden / split samples) y/o replicados. ISO 13528 contempla Youden plot y split samples como herramientas de diagnóstico. citeturn8search3turn21view0  
4) Planifique rondas más frecuentes (si el proceso lo permite) y evalúe tendencias: evita sobreinterpretar una ronda. citeturn20view0turn9view0  

**Paso: blindar ítems (homogeneidad/estabilidad)**  
5) Haga estudio de homogeneidad con replicados y criterio operativo (p. ej., SD muestreo ≤ 0.3·σ_pt) y método suficientemente preciso (σ_an/σ_p < 0.5). citeturn10view0turn22view1  
6) Haga estudio de estabilidad orientado a condiciones extremas de transporte/almacenamiento; documente decisión (IUPAC discute diseños de estabilidad). citeturn10view3  

**Paso: definir reglas de decisión antes de recibir datos**  
7) Defina por escrito: formato de reporte, reglas de blunders, deadlines, tratamiento de censura (“< LOD”), etc. ISO 13528 incluye guía de formato y censura; ISO/IEC 17043 exige instrucciones y control del proceso. citeturn8search3turn22view1  
8) Defina criterio u(x_pt) < 0.3·σ_pt y score principal: z si se cumple; z′/ζ/E_n si no. citeturn12view1turn20view0  

**Paso: análisis con transparencia de incertidumbre**  
9) Reporte u(x_pt) y explique su efecto. Eurachem advierte que u(x_pt) grande puede producir clasificaciones injustas si no se incorpora. citeturn12view1turn19view0  
10) Use *bootstrap* cuando el objetivo sea cuantificar incertidumbre de mediana/robustos con N pequeño (ISO 13528 lo contempla explícitamente como técnica disponible). citeturn3view0  
11) Si hay información previa (rondas, desempeño histórico, expertos), considere un **modelo bayesiano jerárquico** para estabilizar x_pt y su incertidumbre (hay propuestas específicas en PT para combinar conocimiento experto e info auxiliar cuando faltan replicados e incertidumbres). citeturn24view0turn26view0  

**Paso: cierre con acciones y aprendizaje (no solo “aprobó/reprobó”)**  
12) Para resultados cuestionables/insatisfactorios, exija investigación y acciones correctivas; use enfoque longitudinal para juzgar competencia (AMC y Eurachem enfatizan la interpretación en el tiempo). citeturn20view0turn11view0  

### Enlaces clave (en bloque de código)

```text
ISO 13528:2022 (catálogo ISO): https://www.iso.org/standard/78879.html
ISO/IEC 17043:2023 (catálogo ISO): https://www.iso.org/standard/80864.html
Eurachem (2021) Selection, Use and Interpretation of PT Schemes (PDF): https://www.eurachem.org/images/stories/Guides/pdf/EPT_2021_P3_EN.pdf
IUPAC/CITAC (2010) Limited number of participants (PDF): https://media.iupac.org/publications/pac/2010/pdf/8205x1099.pdf
IUPAC (2006) Harmonized Protocol (PDF): https://old.iupac.org/publications/pac/2006/pdf/7801x0145.pdf
EA-4/21 INF:2018 (PDF): https://european-accreditation.org/wp-content/uploads/2018/10/ea-4-21-inf-rev00-march-18.pdf
ILAC P9:01/2024 (PDF): https://ilac.org/publications-and-resources/ilac-policy-series/
```

**Nota de incertidumbre final:** sin conocer el mensurando, matriz, objetivo regulatorio, disponibilidad de CRM, y política de reporte de incertidumbre por participantes, este informe propone criterios y diseños “robustos” por defecto. La selección final debe documentar esos supuestos como parte del plan de esquema y del enfoque de riesgos exigido por ISO/IEC 17043. citeturn4view0turn22view1