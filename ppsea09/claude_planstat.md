# Ensayos de aptitud con menos de 5 laboratorios: planificación estadística para calidad de aire

**Los ensayos de aptitud (PT) con menos de 5 participantes son estadísticamente viables, pero exigen un cambio fundamental de enfoque**: abandonar los valores de consenso derivados de los participantes y adoptar valores asignados independientes (materiales de referencia certificados, laboratorios de referencia o valores formulados), junto con una desviación estándar objetivo (σ_pt) fijada externamente. Ni ISO 13528:2022 ni ISO/IEC 17043:2023 establecen un número mínimo explícito de participantes, pero ambas normas advierten que los métodos estadísticos diseñados para grupos grandes fallan con pocos laboratorios. Para el monitoreo de contaminantes gaseosos (CO, O₃, SO₂, NOx), la experiencia del ERLAP europeo demuestra que **esquemas con 8–15 laboratorios ya operan con valores de referencia certificados y σ_pt prescriptiva**, un modelo directamente extrapolable a grupos aún más pequeños.

---

## 1. Las normas ISO no fijan un mínimo, pero imponen condiciones estrictas

**ISO/IEC 17043:2023 (Cláusula 7.2.2.3)** — anteriormente Cláusula 4.4.4.3(b) en la edición 2010 — exige que el proveedor de PT considere *"el número mínimo de participantes necesario para cumplir los objetivos del diseño estadístico"* y que, cuando ese mínimo no se alcance, documente y comunique a los participantes los enfoques alternativos utilizados. La norma **no prescribe un número fijo**, sino que delega la decisión al proveedor con base en su diseño particular.

**ISO 13528:2022 (Cláusula 5.4.1)** aborda directamente las *"Consideraciones para números pequeños de participantes"*: establece que los métodos estadísticos apropiados para grupos grandes pueden no serlo para grupos reducidos, y que existe el riesgo de que las estadísticas derivadas de pocos resultados no sean suficientemente confiables. La nota de esta cláusula referencia la guía IUPAC/CITAC (Kuselman & Fajgelj, 2010) y recomienda explícitamente que:

- El valor asignado debe basarse en **mediciones independientes confiables** (MRC, calibración por un instituto nacional de metrología, o preparación gravimétrica).
- La desviación estándar para la evaluación de aptitud **no debe derivarse de la dispersión observada entre los resultados de los participantes** en una sola ronda cuando el número es pequeño.

La **Cláusula 5.4.2** lista los factores que afectan el número mínimo: el método estadístico seleccionado, la experiencia previa de los participantes, la experiencia del proveedor con la matriz y el mensurando, y si la intención es determinar el valor asignado, la desviación estándar, o ambos. El **Anexo D.1** (informativo) amplía esta orientación, confirmando que los criterios externos independientes de los resultados de los participantes son preferidos para grupos pequeños.

Un resultado matemático clave demuestra por qué el consenso falla con pocos participantes: la incertidumbre del valor asignado por consenso se calcula como **u(x_pt) = 1,25 × s\*/√p** (donde s\* es la desviación estándar robusta y p el número de participantes). ISO 13528 Cláusula 9.2 requiere que u(x_pt) ≤ 0,3σ_pt para que el z-score simple sea válido. Si s\* ≈ σ_pt, resolver esta desigualdad exige **p ≥ 17 participantes**. Con p = 4, u(x_pt) = 0,625σ_pt — más del doble del límite permitido.

### Tipos de esquema recomendados para pocos laboratorios

Para grupos con n < 5, los esquemas más adecuados son:

- **Esquema en estrella**: cada participante se compara contra un laboratorio central de referencia, no contra los demás. Ideal porque elimina la necesidad de estadísticas de consenso.
- **Esquema secuencial**: el mismo ítem de ensayo circula entre los laboratorios en secuencia, maximizando la homogeneidad pero con riesgo de degradación del ítem.
- **Comparación bilateral**: entre un laboratorio y un laboratorio de referencia; constituye el enfoque mínimo viable para 2 laboratorios.

El documento **EA-4/21 INF:2018** define formalmente una *"ILC pequeña"* como aquella organizada por y entre **7 o menos laboratorios**, señalando que en la mayoría de los casos involucra **2 a 4 participantes**. Este documento europeo es la referencia práctica más directa para el escenario planteado.

---

## 2. El z-score pierde validez con n < 5: alternativas estadísticas según ISO 13528

El z-score clásico, definido en ISO 13528 Cláusula 9.4 como **z = (x_i − x_pt) / σ_pt**, requiere dos condiciones que no se cumplen con pocos participantes: un valor asignado confiable y una σ_pt bien fundamentada. Cuando ambos se derivan del consenso de n < 5 resultados, el puntaje resultante carece de significancia estadística. Un solo resultado discrepante entre 3-4 participantes puede desplazar dramáticamente la media robusta, y el **Algoritmo A** (Anexo C.3 de ISO 13528) tiene un punto de quiebre (*breakdown point*) del 25% — con n = 4, un solo valor atípico ya representa el 25% de los datos.

ISO 13528 Cláusula 9 ofrece un espectro de estadísticas de desempeño diseñadas para distintos escenarios. Su idoneidad para n < 5 varía considerablemente:

**Número E_n (error normalizado)** — Cláusula 9.7:  
Fórmula: **E_n = (x_i − x_ref) / √(U²_lab + U²_ref)**  
Interpretación: |E_n| ≤ 1 → satisfactorio; |E_n| > 1 → no satisfactorio.  
Es la **estadística óptima para n < 5** porque no requiere σ_pt ni valor de consenso, solo que tanto el laboratorio como la referencia declaren incertidumbres expandidas (k = 2). Funciona perfectamente incluso con n = 2.

**z'-score** — Cláusula 9.5:  
Fórmula: **z' = (x_i − x_pt) / √(σ²_pt + u²(x_pt))**  
Incorpora la incertidumbre del valor asignado en el denominador, compensando parcialmente la mayor incertidumbre inherente a grupos pequeños. Es la estadística que utiliza el **ERLAP** en sus intercomparaciones europeas de contaminantes gaseosos, precisamente porque sus rondas operan con 8–15 participantes.

**Puntaje zeta (ζ)** — Cláusula 9.6:  
Fórmula: **ζ = (x_i − x_pt) / √(u²(x_i) + u²(x_pt))**  
Evalúa simultáneamente la calidad del resultado y de la estimación de incertidumbre del laboratorio. Requiere que cada participante reporte su incertidumbre estándar. Es independiente de σ_pt.

**Diferencia porcentual D%** — Cláusula 9.3:  
Fórmula: **D% = [(x_i − x_pt) / x_pt] × 100**  
Se evalúa contra un error relativo máximo permisible (d_E%) definido por el proveedor o la normativa. Útil cuando no es posible establecer σ_pt pero existen límites regulatorios — como el **15% de incertidumbre máxima** establecido por la Directiva 2008/50/CE para mediciones fijas de SO₂, NO₂, CO y O₃.

### Jerarquía de recomendación para n < 5

| Estadística | ¿Requiere σ_pt? | ¿Requiere incertidumbre? | Idoneidad n < 5 |
|-------------|:---:|:---:|:---:|
| **E_n** | No | U_lab y U_ref | **Óptima** |
| **ζ (zeta)** | No | u(x_i) y u(x_pt) | **Buena** |
| **z'** | Sí (externa) | u(x_pt) | **Aceptable** |
| **D%** | No | No | **Aceptable** (con límites regulatorios) |
| **z** | Sí | No | **Inadecuada** si σ_pt y x_pt son de consenso |

---

## 3. Estimación de σ_pt: métodos independientes del número de participantes

ISO 13528 Cláusula 8 describe seis enfoques para establecer la desviación estándar para evaluación de aptitud. Cuando n < 5, los métodos basados en datos de participantes quedan descartados, haciendo crítica la selección del método correcto.

**Enfoque prescriptivo/regulatorio (Cláusula 8.1)**: σ_pt se fija por especificación técnica, regulación o panel de expertos. Para calidad de aire, la **Directiva 2008/50/CE Anexo I** establece una incertidumbre máxima del 15% para mediciones fijas de los cuatro contaminantes gaseosos. Esta cifra puede traducirse directamente en σ_pt: si la incertidumbre expandida máxima es 15% (k = 2), la incertidumbre estándar es ~7,5%, lo que permite fijar σ_pt como un porcentaje de la concentración. El **ERLAP utiliza exactamente este enfoque**: σ_pt = a·c + b, donde c es la concentración y a, b son parámetros calibrados por contaminante para que z-scores insatisfactorios correspondan a mediciones que exceden los objetivos de calidad de datos de la Directiva.

**Percepción de expertos / aptitud para el propósito (Cláusula 8.2)**: Un comité técnico establece σ_pt con base en lo que se considera una precisión óptima para el uso previsto de los resultados. Este enfoque es **completamente independiente de n** y ampliamente recomendado por la guía Eurachem de PT (3.ª ed., 2021).

**Ecuación de Horwitz (Cláusula 8.4, "modelo general")**: Para análisis químicos, la ecuación empírica **CV_R (%) = 2^(1−0,5 log₁₀ C)** (donde C es la fracción másica) predice la reproducibilidad esperada basándose en un metaanálisis de miles de estudios colaborativos. La forma equivalente es σ_H = 0,02 × c^0,8495. Ventaja: completamente independiente de participantes. Limitación: calibrada para análisis químicos convencionales; su aplicabilidad a mediciones instrumentales de gases traza requiere validación contra datos sectoriales. Para las concentraciones típicas en monitoreo de aire (nmol/mol a μmol/mol), la ecuación de Thompson modificada aplica correcciones en los extremos de concentración.

**Datos de reproducibilidad históricos (Cláusula 8.5)**: Si existen datos de estudios colaborativos previos (ISO 5725) para el método y la matriz, σ_pt puede igualarse a la desviación estándar de reproducibilidad s_R publicada, o a s_R/2 si se desea un desempeño superior al típico. Para los métodos de referencia europeos (EN 14211, EN 14212, EN 14625, EN 14626), los datos de validación de tipo contienen información de reproducibilidad utilizable.

**Algoritmo A de ISO 13528 (Anexo C.3)**: Método iterativo robusto con etapas de winsorización. **No recomendado para n < 5**: el Anexo C indica que requiere al menos ~18 participantes para funcionar adecuadamente, y su punto de quiebre del 25% lo hace vulnerable con datos escasos. Para 3 ≤ p ≤ 5, el Anexo D (Tabla D.1) recomienda como alternativa la **mediana** para la ubicación y el **estimador Q_n** para la dispersión, con factores de corrección específicos (c₃ = 0,9939; c₄ = 1,1284; c₅ = 1,1376). El Q_n tiene un punto de quiebre del 50% y mejor eficiencia que el MADe para muestras pequeñas. No obstante, **incluso estos estimadores robustos producen valores con alta incertidumbre cuando p < 5**, por lo que su uso como σ_pt debe ser solo informativo o complementario.

### Jerarquía recomendada para σ_pt con n < 5

1. **Prescriptivo/regulatorio**: si existen requisitos normativos (p. ej., Directiva 2008/50/CE) → primera opción
2. **Aptitud para el propósito**: definido por panel de expertos del sector → segunda opción
3. **Ecuación de Horwitz**: para análisis químicos donde las opciones anteriores no aplican
4. **Reproducibilidad histórica**: si existen datos de validación del método de referencia
5. **Q_n de datos de participantes**: solo como información complementaria, nunca como criterio único de evaluación

---

## 4. Valor asignado: la trazabilidad metrológica reemplaza al consenso

ISO 13528 Cláusula 7 ofrece cinco métodos para determinar el valor asignado (x_pt). Para n < 5, la jerarquía es clara: los métodos independientes de los participantes son obligatorios en la práctica.

**Valor formulado (Cláusula 7.3)**: El ítem de PT se prepara por procedimientos conocidos — en calidad de aire, esto corresponde a mezclas de gas preparadas por dilución dinámica o gravimétrica con concentración conocida y trazable. La incertidumbre se calcula a partir del proceso de preparación. Es el enfoque utilizado por el ERLAP, que genera mezclas gaseosas en sus instalaciones acreditadas de Ispra con trazabilidad a patrones del NMI.

**Material de referencia certificado (Cláusula 7.4)**: Se emplea un MRC con valor de propiedad trazable al SI. Para gases: patrones de gas certificados (CGS) preparados según ISO 6142 o el protocolo EPA. Las incertidumbres típicas son ~1% relativo (k = 2) para CO en concentraciones altas, aunque existen desafíos significativos de estabilidad para SO₂ en matriz de aire (degradación de -0,6% a -2,2% en 6 meses según comparaciones EURAMET) y para NO₂ (decaimiento de 1-4% en 15-26 meses según el proyecto MetNO₂). El ozono no puede almacenarse en cilindros y requiere generación dinámica con fotómetros de referencia estándar (SRP) trazables al BIPM.

**Laboratorio de referencia (Cláusula 7.5)**: Un único laboratorio competente (NMI, laboratorio nacional de referencia acreditado) proporciona el valor asignado. ISO 13528 describe este método como **explícitamente adecuado cuando los enfoques de consenso no funcionan por número insuficiente de participantes**.

**Consenso de laboratorios expertos (Cláusula 7.6)**: Un grupo designado de laboratorios expertos, separado de los participantes, proporciona mediciones para derivar el valor asignado.

**Consenso de participantes (Cláusula 7.7)**: **No recomendado para n < 5.** EA-4/21 INF:2018 establece que *"generalmente no se recomienda derivar el valor asignado y la SDPA de los resultados obtenidos por los participantes"* en ILC pequeñas. Las excepciones documentadas incluyen: (a) laboratorios experimentados con armonización previa demostrada, o (b) cuando uno de los participantes opera a un nivel metrológico superior.

### Criterio de la incertidumbre del valor asignado

ISO 13528 Cláusula 9.2 establece el criterio fundamental: **u(x_pt) ≤ 0,3 × σ_pt**. Cuando este criterio no se cumple, el z-score simple no es apropiado y debe emplearse z' o ζ. Con un valor asignado de un CGS con incertidumbre del 1% y σ_pt del 7,5% (derivada de la Directiva), la condición se satisface holgadamente (1% << 2,25%), permitiendo el uso de z-scores incluso con n < 5 siempre que ambos parámetros sean independientes de los participantes.

---

## 5. El modelo ERLAP como referencia para calidad de aire con pocos laboratorios

El **Laboratorio Europeo de Referencia para la Contaminación del Aire (ERLAP)**, ubicado en el Centro Común de Investigación (JRC) de Ispra, Italia, opera un esquema de PT acreditado según ISO/IEC 17043 que constituye el modelo de referencia para contaminantes gaseosos. En la ronda de abril de 2022, participaron **10 laboratorios** de la red AQUILA, con algunos laboratorios que no participaron para todos los contaminantes — una situación análoga al escenario de n < 5 por contaminante.

El enfoque ERLAP ilustra cómo resolver cada desafío estadístico:

**Valores de referencia**: generados por el propio ERLAP mediante mezclas gaseosas certificadas con trazabilidad a patrones del NMI, no por consenso de participantes. Para O₃, se utilizan fotómetros de referencia estándar (SRP) trazables al BIPM. Para CO, cilindros con trazabilidad NIST. Para NO, patrones certificados con titulación en fase gaseosa (GPT) para generar concentraciones de NO₂.

**σ_pt prescriptiva**: establecida como función lineal de la concentración (σ_pt = a·c + b), con parámetros específicos por contaminante derivados de los objetivos de calidad de datos de la Directiva 2008/50/CE. Las concentraciones de ensayo se fijan alrededor de los valores límite y umbrales de evaluación de la UE.

**Evaluación dual**: se reportan tanto **z'-scores** como **números E_n**, proporcionando doble perspectiva sobre el desempeño. En la ronda 2022, el **97,5% de las evaluaciones z' fueron satisfactorias** y solo el 2,5% cuestionables.

Las **normas EN de método de referencia** relevantes especifican los principios de medición y requisitos de calibración:

- **EN 14211** (NOx): quimioluminiscencia; requiere calibración multipunto y verificación de eficiencia del convertidor NO₂→NO
- **EN 14212** (SO₂): fluorescencia UV; especifica procedimientos de calibración y corrección por interferencias de vapor de agua
- **EN 14625** (O₃): fotometría UV; referencia al SRP para trazabilidad
- **EN 14626** (CO): infrarrojo no dispersivo (NDIR); corrección por interferencias de H₂O y CO₂

La **Directiva Comunitaria 2015/1480** obliga a los Laboratorios Nacionales de Referencia a participar en programas de QA/QC del JRC al menos cada 3 años, lo que incluye los ejercicios ERLAP. Otros programas relevantes incluyen el WMO/GAW (con centros de calibración mundiales como WCC-Empa para O₃ y CO), el programa de la Umweltbundesamt austriaca (acreditado, con ejercicios de 3-4 días), y los ejercicios ALEM para emisiones en Europa Central.

### Desafíos específicos por contaminante

Para redes nacionales pequeñas que diseñen PT con n < 5, los **desafíos de estabilidad de patrones** son críticos. El SO₂ en matriz de aire presenta degradación documentada de hasta 2,2% en 6 meses. El NO₂ carece de patrones directos certificados por NIST y depende de la titulación en fase gaseosa a partir de NO. El O₃ no puede almacenarse y exige generación in situ con SRP o generadores calibrados. Solo el CO en nitrógeno ofrece buena estabilidad a largo plazo. Esto implica que para esquemas con cilindros circulantes (round-robin), la **verificación de estabilidad durante el transporte** es esencial, y para especies reactivas puede ser preferible un esquema centralizado tipo ERLAP.

---

## 6. Marco normativo complementario y herramientas prácticas

Tres documentos complementarios a las normas ISO forman el marco esencial para PT con pocos participantes:

**EA-4/21 INF:2018** (*Guidelines for the assessment of the appropriateness of small interlaboratory comparisons*): Es el documento más directamente aplicable, desarrollado por el grupo de trabajo EEE-PT de European Accreditation. Define tres escenarios de evaluación para ILC con ≤ 7 laboratorios: Escenario 1 (preferido) con valor de referencia externo y z-scores o E_n; Escenario 2 (excepcional) con valor de consenso de participantes experimentados; Escenario 3 (último recurso) sin puntuaciones formales, solo evaluación gráfica y cualitativa. Este documento es aceptado por **ILAC P9:01/2024** como base para validar ILC pequeñas en el proceso de acreditación.

**Guía IUPAC/CITAC (Kuselman & Fajgelj, 2010)** (*Selection and use of proficiency testing schemes for a limited number of participants*, Pure Appl. Chem. 82(5):1099-1135): El tratamiento técnico más riguroso del tema. Define "número limitado" como **menos de 30 participantes** y propone un enfoque metrológico basado en MRC con valores trazables. Presenta tres escenarios según la disponibilidad de MRC matriciales adecuados y demuestra que las diferencias entre estadísticas muestrales y poblacionales aumentan dramáticamente para N < 20.

**Milde, Klokočníková & Nižnanská (2021)** (*Practical guidance for organizing small interlaboratory comparisons*, Accred. Qual. Assur. 26:17-22): Guía paso a paso para ILC con **2-7 participantes**, cubriendo diseño del esquema, preparación y distribución de ítems, instrucciones, evaluación mediante estadísticos de orden, y plantillas de reporte. Es la referencia práctica más reciente y accesible.

### Software y herramientas computacionales

**PROLab Plus** (QuoData GmbH, Alemania) es el software más completo para evaluación estadística de PT conforme a ISO 17043, ISO 13528 e ISO 5725. Sus características relevantes para grupos pequeños incluyen: múltiples métodos de determinación de valor asignado (incluyendo valores de referencia independientes), cálculo de z-scores, z'-scores, ζ-scores y E_n, y pruebas de homogeneidad y estabilidad. Es utilizado por más de 80 proveedores de PT mundialmente, incluyendo NIST y US FDA.

El paquete **metRology** de R, desarrollado por Stephen L.R. Ellison (coautor del Protocolo Armonizado IUPAC), proporciona funciones para estimadores robustos de ubicación (M-estimadores, MM-estimadores), estadísticas de Mandel h y k, propagación de incertidumbre GUM, y estadísticas chi-cuadrado de diferencias pareadas — particularmente adecuadas para grupos pequeños por sus métodos robustos de estimación.

Para implementaciones básicas, los algoritmos del Anexo C de ISO 13528 (Algoritmo A, estimador Q_n) pueden codificarse en **hojas de cálculo Excel**, y las fórmulas de las estadísticas de desempeño (z, z', ζ, E_n, D%) son directamente implementables.

---

## Conclusión: un marco viable para PT con n < 5 en calidad de aire

El diseño estadístico de un ensayo de aptitud con menos de 5 laboratorios para contaminantes gaseosos es no solo posible sino que cuenta con un marco normativo y técnico bien articulado. La clave es un cambio de paradigma: de la evaluación basada en consenso (que requiere n ≥ 17 para satisfacer el criterio de incertidumbre de ISO 13528) a la **evaluación basada en trazabilidad metrológica**. 

El diseño recomendado combina cuatro elementos: (1) valores asignados derivados de patrones de gas certificados o laboratorios de referencia acreditados, con trazabilidad demostrada al SI; (2) σ_pt prescriptiva basada en los objetivos de calidad de datos de la Directiva 2008/50/CE (15% de incertidumbre máxima para mediciones fijas); (3) evaluación mediante **E_n** como estadística primaria cuando los laboratorios reportan incertidumbres, complementada con **z'-scores** como estadística secundaria; y (4) documentación exhaustiva de las limitaciones estadísticas y los enfoques alternativos, conforme a ISO/IEC 17043 Cláusula 7.2.2.3.

Tres hallazgos merecen destacarse. Primero, la demostración matemática de que el criterio u(x_pt) ≤ 0,3σ_pt es inalcanzable con valores de consenso para p < 17 invalida definitivamente el uso de z-scores convencionales basados en consenso para grupos pequeños. Segundo, la distinción entre "PT formal" e "ILC pequeña" (EA-4/21) no es académica: los organismos de acreditación aceptan ILC pequeñas como evidencia válida de competencia cuando se diseñan conforme a este marco. Tercero, para O₃ y NO₂, las limitaciones de estabilidad de los patrones de referencia (imposibilidad de almacenar O₃; degradación del NO₂) imponen restricciones adicionales al diseño del esquema que favorecen comparaciones centralizadas sobre esquemas circulantes, independientemente del número de participantes.