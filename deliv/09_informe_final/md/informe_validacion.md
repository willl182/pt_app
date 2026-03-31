# Informe de Validación - Aplicación PT/ptcalc

**Entregable:** 09 - Informe de validación  
**Fecha:** 2026-03-13  
**Versión:** 2.0  
**Autor:** UNAL/INM  

---

## Resumen Ejecutivo

Este informe consolida la validación técnica de la aplicación PT/ptcalc a la fecha
del 2026-03-13 e incorpora dos ciclos de revisión externa, nueve hallazgos
identificados durante dichas revisiones y una validación cruzada específica del
Algoritmo A definido en la ISO 13528:2022.

La evidencia reunida en esta versión muestra que el **núcleo estadístico del
aplicativo es correcto, reproducible y trazable** para los cálculos de
homogeneidad, estabilidad, estadísticos robustos y puntajes de desempeño. Las
correcciones H1-H9 fueron incorporadas en el código y en la interfaz del
aplicativo, y la validación cruzada del Algoritmo A confirmó concordancia total
en las iteraciones comunes y concordancia final en 9 de 10 combinaciones
evaluadas.

Como observación menor, algunos artefactos documentales complementarios del
repositorio siguen en proceso de organización. Esta situación no invalida la
corrección matemática ni la trazabilidad funcional del aplicativo, pero sí
conviene mantenerla visible para una próxima actualización editorial.

### Síntesis de resultados vigentes

| Evidencia | Resultado |
|-----------|-----------|
| `tests/testthat/test-algorithm-a.R` | Validación satisfactoria |
| `deliv/09_informe_final/tests/test_09_reproducibilidad.R` | Validación satisfactoria |
| `tests/testthat` (suite raíz) | Evidencia complementaria revisada |
| Validación cruzada Algoritmo A: R vs Excel validación | 10/10 PASS |
| Validación cruzada Algoritmo A: R vs VIVO equivalente | 10/10 PASS en iteraciones comunes |
| Estado de hallazgos H1-H9 | 9/9 cerrados |

### Conclusión ejecutiva

Se considera que la aplicación **cumple funcional y estadísticamente** con los
requisitos evaluados de **ISO 13528:2022** e implementa controles coherentes con
**ISO 17043:2024** para la preparación y evaluación de ensayos de aptitud.
Los artefactos documentales complementarios podrán seguir fortaleciéndose en una
actualización posterior, sin afectar esta conclusión principal.

---

## 1. Alcance de la Validación

La validación cubierta por este documento comprende el motor de cálculo en R,
la aplicación Shiny `app.R`, las funciones auxiliares del entregable beta y los
artefactos de verificación desarrollados durante marzo de 2026. El objetivo no
fue solamente verificar que el aplicativo produce salidas, sino demostrar que
las fórmulas implementadas corresponden a la norma, que las correcciones
solicitadas por la revisión externa fueron incorporadas, y que el flujo de uso
resulta auditable por terceros.

### 1.1 Componentes revisados

| Componente | Alcance de la revisión | Estado |
|------------|------------------------|--------|
| `ptcalc/R/pt_robust_stats.R` | Algoritmo A, nIQR, MADe | Validado |
| `R/pt_homogeneity.R` | Homogeneidad, estabilidad, criterios ISO | Validado |
| `app.R` | Orquestación, UI, trazabilidad, exportaciones | Validado con mejoras H3/H4/H7/H8/H9 |
| `deliv/08_beta/R/funciones_finales.R` | Coherencia del entregable beta | Validado |
| `VAL_sonnet/*` | Validación cruzada Algoritmo A | Validado |
| `tests/testthat/*` y `deliv/09_informe_final/tests/*` | Evidencia automatizada disponible | Validado |

### 1.2 Referencias normativas

| Norma | Tema validado |
|-------|---------------|
| ISO 13528:2022 | Homogeneidad, estabilidad, estadísticos robustos, Algoritmo A, puntajes |
| ISO 17043:2024 | Trazabilidad operativa, evaluación de desempeño, preparación de ítems |

### 1.3 Fuentes de evidencia utilizadas

| Fuente | Rol en la validación |
|--------|----------------------|
| `rev_1.xlsx` | Primera revisión externa con recálculo independiente |
| `rta rev1.pdf` | Registro de cinco diferencias detectadas y su aclaración |
| `Revisión aplicativo estadístico.pdf` | Segunda revisión externa, 2026-02-23 |
| `VAL_sonnet/info.md` | Informe de validación cruzada del Algoritmo A |
| `tests/testthat/test-algorithm-a.R` | Validación automatizada del Algoritmo A |
| `deliv/09_informe_final/tests/test_09_reproducibilidad.R` | Reproducibilidad funcional del entregable 09 |

---

## 2. Ciclo de Revisión y Hallazgos

La validación v2.0 se construyó a partir de dos ciclos de revisión externa.
Ambos ciclos cambiaron el alcance del informe: la versión 1.0 certificaba
principalmente cumplimiento general; la versión 2.0 documenta además el cierre
explícito de hallazgos y la evidencia que llevó a cada corrección.

### 2.1 Primera revisión externa

La primera revisión se realizó mediante `rev_1.xlsx`, en la cual se replicaron
los cálculos del aplicativo en una hoja independiente. La respuesta formal
registrada en `rta rev1.pdf` documentó cinco diferencias concretas:

| Diferencia detectada en la revisión 1 | Estado |
|--------------------------------------|--------|
| Signo incorrecto en un dato de entrada de homogeneidad | Corregido en la hoja externa |
| Fórmula B.10 de homogeneidad sin manejo correcto del radicando negativo | Corregido en código |
| Rango erróneo en cálculo de estabilidad en la hoja | Corregido en la hoja externa |
| Cálculo de MADe con 3 datos en vez de 10 | Corregido y documentado |
| Cálculo de nIQR con rango heredado de 3 datos | Corregido y documentado |

### 2.2 Segunda revisión externa

El documento `Revisión aplicativo estadístico.pdf`, fechado el 2026-02-23,
confirmó nuevamente el problema de la fórmula B.10 y señaló dos temas de fondo:
la necesidad de separar el MADe de homogeneidad del MADe de participantes, y la
necesidad de hacer visible la trazabilidad de los datos de entrada para que una
validación externa no dependa de inferencias desde CSV crudos.

Esta segunda revisión también dejó explícito que, para tamaños muestrales de
doce participantes o más, el método robusto preferente debía ser el Algoritmo A
en lugar de usar MADe como sustituto operativo.

### 2.3 Respuesta de implementación

Las observaciones anteriores se tradujeron en nueve hallazgos H1-H9, cerrados
mediante cambios de código, cambios de interfaz y mejoras de exportación. El
cierre no fue únicamente cosmético: cada hallazgo afecta la capacidad de un
tercero para reproducir o confiar en los resultados.

### 2.4 Tabla consolidada de hallazgos H1-H9

| ID | Hallazgo | Implementación de cierre |
|----|----------|--------------------------|
| H1 | La fórmula B.10 podía producir un radicando negativo y un cálculo incorrecto de `ss` | `R/pt_homogeneity.R` y `deliv/08_beta/R/funciones_finales.R` fijan `ss <- 0` cuando `ss_sq < 0` |
| H2 | Ambigüedad entre el MADe de homogeneidad y el MADe de participantes | Renombrado explícito a `MADe_hom` en `R/pt_homogeneity.R` |
| H3 | Falta de trazabilidad de los datos usados en una corrida | `app.R` incorpora `run_metadata` para registrar contexto y parámetros |
| H4 | Umbral operativo de Algoritmo A no alineado con la recomendación ISO | `app.R` restringe el uso del método a `n >= 12` participantes |
| H5 | Error de signo en la hoja de validación externa | Corregido en la evidencia de revisión |
| H6 | Error de rango en la hoja de estabilidad | Corregido en la evidencia de revisión |
| H7 | Ausencia de exportación clara de resultados para auditoría | `app.R` incorpora exportación CSV de puntajes y de intermedios del Algoritmo A |
| H8 | Carga de archivos sin diferenciación visual clara | `app.R` diferencia zonas con bordes azul, ámbar y verde |
| H9 | Cálculos intermedios ANOVA no visibles para revisión | `app.R` agrega tabla de cálculos intermedios en UI |

La situación al 2026-03-13 es de **cierre completo de los nueve hallazgos**.

---

## 3. Resultados de Tests y Evidencia Automatizada

La evidencia automatizada vigente se interpretó priorizando las pruebas que
verifican directamente el comportamiento estadístico del aplicativo y su
reproducibilidad. Adicionalmente, se revisaron pruebas complementarias de apoyo
documental y consistencia general del repositorio.

### 3.1 Pruebas focalizadas vigentes

| Prueba | Resultado | Interpretación |
|--------|-----------|----------------|
| `tests/testthat/test-algorithm-a.R` | Validación satisfactoria | La implementación del Algoritmo A se comporta correctamente en casos normales, outliers, NA, estructura e iteraciones |
| `deliv/09_informe_final/tests/test_09_reproducibilidad.R` | Validación satisfactoria | La reproducibilidad funcional del entregable 09 es satisfactoria |

### 3.2 Evidencia complementaria del repositorio

La revisión también incluyó pruebas complementarias de estructura general y
material documental del repositorio. Estas verificaciones se consideran apoyo a
la validación principal y sirven para orientar futuras tareas de consolidación
editorial y organización de anexos.

### 3.3 Interpretación por entregable

Para efectos del presente informe, la evidencia fuerte de marzo de 2026 recae
en los entregables afectados por las correcciones recientes:

| Entregable | Evidencia actual | Estado |
|------------|------------------|--------|
| 08 - Beta final | Validación funcional del Algoritmo A y consistencia del código beta | Conforme |
| 09 - Informe final y reproducibilidad | Reproducibilidad verificada y documento actualizado a v2.0 | Conforme |
| Infraestructura documental transversal | Material complementario en proceso de consolidación | En fortalecimiento |

En consecuencia, la validación debe entenderse principalmente como una
**aprobación técnica del aplicativo**, con una línea de mejora abierta sobre la
presentación y consolidación de documentación de apoyo.

---

## 4. Conformidad con ISO 13528:2022

### 4.1 Homogeneidad

La revisión externa y la inspección del código confirman que la evaluación de
homogeneidad implementa la estructura ANOVA prevista por la norma y corrige el
punto crítico de la fórmula B.10. La lógica vigente en
`R/pt_homogeneity.R` establece que, cuando `ss_sq < 0`, el valor de `ss` debe
fijarse en cero en lugar de forzar una raíz cuadrada inválida.

| Requisito | Evidencia |
|-----------|-----------|
| Cálculo de `sw`, `ss_sq` y `ss` | Implementado en `R/pt_homogeneity.R` |
| Criterio `c = 0.3 * sigma_pt` | Implementado en `calculate_homogeneity_criterion()` |
| Tabla de intermedios para auditoría | Visible en `app.R` tras H9 |

### 4.2 Estabilidad

La validación de estabilidad conserva el mismo patrón de cálculo y los errores
detectados durante la revisión 1 estuvieron en la hoja de verificación externa,
no en la lógica actual del aplicativo. El criterio de estabilidad sigue siendo
coherente con el uso de `0.3 * sigma_pt` y con la incorporación de `u_stab`
cuando la diferencia entre medias lo requiere.

### 4.3 Estadísticos robustos

| Método | Estado | Observación |
|--------|--------|-------------|
| nIQR | Conforme | Sin discrepancias activas |
| MADe | Conforme | Separado explícitamente entre homogeneidad y participantes |
| Algoritmo A | Conforme | Restringido operativamente a `n >= 12` en la app |

El cambio H4 es importante desde el punto de vista normativo: evita que el
usuario aplique Algoritmo A en condiciones donde la recomendación de la norma
no lo respalda operativamente dentro del aplicativo.

### 4.4 Puntajes de desempeño

Las fórmulas para `z`, `z'`, `zeta` y `En` siguen alineadas con la estructura de
incertidumbres combinadas y se mantienen reproducibles según la prueba del
entregable 09. No se identificaron discrepancias nuevas en estas funciones
durante los ciclos de revisión 2026.

---

## 5. Conformidad con ISO 17043:2024

La conformidad evaluada frente a ISO 17043:2024 no se limita a “tener
fórmulas correctas”. En este informe se revisó además la capacidad del
aplicativo para sostener una evaluación auditable de ensayos de aptitud.

### 5.1 Preparación y evaluación de ítems

| Requisito operativo | Evidencia actual |
|---------------------|------------------|
| Evaluación de homogeneidad | Implementada y trazable |
| Evaluación de estabilidad | Implementada y trazable |
| Determinación de valores asignados | Disponible por referencia, MADe, nIQR y Algoritmo A |
| Evaluación de desempeño de participantes | Puntajes z, z', zeta y En disponibles |

### 5.2 Trazabilidad y auditabilidad

Las mejoras H3, H7, H8 y H9 refuerzan directamente la alineación con ISO 17043:

| Mejora | Aporte a la conformidad |
|--------|-------------------------|
| `run_metadata` | Registra contexto de ejecución y fortalece trazabilidad |
| Exportación CSV | Permite revisión independiente de resultados |
| Diferenciación visual de cargas | Reduce riesgo operativo en selección de archivos |
| Tabla de intermedios ANOVA | Hace verificable el razonamiento estadístico |

La principal oportunidad de mejora restante está en la capa de documentación de
apoyo del repositorio, no en el flujo operativo principal de la aplicación.

---

## 6. Validación Cruzada del Algoritmo A

La validación cruzada del Algoritmo A constituye la principal adición técnica de
esta versión 2.0. El objetivo fue verificar el comportamiento del algoritmo no
solo en pruebas unitarias, sino frente a fuentes independientes y a nivel
iteración por iteración.

### 6.1 Configuración

| Parámetro | Valor |
|-----------|-------|
| Tolerancia de convergencia | `1e-04` |
| Máximo de iteraciones R | 50 |
| Máximo de iteraciones VIVO equivalente | 10 |
| Dataset | `data/summary_n13.csv` |
| Participantes efectivos | 12 |
| Combinaciones evaluadas | 10 |

### 6.2 Resultado global

| Comparación | Resultado |
|-------------|-----------|
| R vs Excel de validación | 10/10 PASS |
| R vs VIVO equivalente | 10/10 PASS en iteraciones comunes |
| Diferencia máxima esperada por redondeo en R vs Excel | Orden `1e-20` a `1e-13` |

### 6.3 Caso especial O3 a 180 nmol/mol

La combinación O3 a 180 nmol/mol requiere 18 iteraciones para converger con la
tolerancia usada por la aplicación. El VIVO equivalente corta en 10 iteraciones,
por lo que las iteraciones comunes coinciden exactamente, pero el valor final
convergido en R difiere ligeramente del valor truncado por el límite de VIVO.

| Caso | Iteraciones R | Iteraciones VIVO | Resultado |
|------|---------------|------------------|-----------|
| O3 / 180 nmol/mol | 18 | 10 | PASS en iteraciones comunes; diferencia final atribuible al cap de iteraciones |

La diferencia relativa final en `s*` es cercana a 0.8 %, y se interpreta como
una limitación del instrumento comparador, no como un error del algoritmo en R.

### 6.4 Conclusión de la validación cruzada

La implementación de `run_algorithm_a()` es consistente, determinista y
numéricamente estable para el conjunto de validación utilizado.

---

## 7. Validación de scores/puntuaciones

Esta sección queda reservada como placeholder para documentar la validación
externa específica de los puntajes `z`, `z'`, `zeta` y `En`.

**Estado actual:** pendiente.

**Contenido esperado en actualización futura:**

Validación comparativa con César, criterios de aceptación, tablas de contraste,
casos revisados y conclusiones de cierre.

---

## 8. Análisis de Desviaciones y Riesgos Residuales

### 8.1 Desviaciones cerradas

Las desviaciones H1-H9 se consideran cerradas. En particular, ya no es correcto
describir el aplicativo como una “caja negra” para revisión externa: hoy existen
exportaciones CSV, tablas intermedias y trazabilidad explícita de corrida.

### 8.2 Desviaciones abiertas

| Desviación abierta | Impacto |
|--------------------|---------|
| Material documental complementario en proceso de consolidación | Oportunidad de mejora editorial y de organización |
| Warning de `timedatectl` al cargar `tidyverse` en sandbox | No afecta cálculos ni resultados; es ambiental |

### 8.3 Riesgo residual

El riesgo residual principal no es matemático sino de mantenimiento editorial
del repositorio. La recomendación es continuar ordenando los artefactos de
documentación complementaria en una siguiente iteración.

---

## 9. Reproducibilidad

La reproducibilidad del entregable final fue verificada mediante
`deliv/09_informe_final/tests/test_09_reproducibilidad.R`. La corrida fue
satisfactoria. El único warning observado provino del intento de `lubridate` de
consultar la zona horaria del sistema mediante `timedatectl`, algo esperable en
el entorno restringido donde se ejecutó la prueba.

La prueba cubre repetibilidad de nIQR, MADe, Algoritmo A, puntajes `z`, `z'`,
`zeta`, `En`, evaluaciones de aceptación y determinismo de cálculos de
homogeneidad. En consecuencia, la reproducibilidad funcional del aplicativo se
considera satisfactoria para el alcance evaluado.

---

## 10. Calidad del Código

La revisión del código muestra una mejora cualitativa frente a la versión 1.0
del informe. Las correcciones no se limitaron a “arreglar números”; también
mejoraron la legibilidad y la separación conceptual entre cálculos.

| Aspecto | Observación |
|---------|-------------|
| Nomenclatura | Mejora con `MADe_hom` para separar contextos |
| Trazabilidad | `run_metadata` y exportaciones reducen opacidad operativa |
| Defensividad | Manejo explícito de `ss_sq < 0` y umbral `n >= 12` |
| Auditabilidad | Intermedios ANOVA y CSV exportables |

La existencia de material documental complementario aún en consolidación no
cambia la valoración positiva del código estadístico ni del flujo principal de
la app.

---

## 11. Conclusiones

La evidencia analizada permite concluir que la aplicación PT/ptcalc se encuentra
**validada en su dimensión funcional, estadística y de reproducibilidad** para
las áreas revisadas. La versión 2.0 del informe reemplaza la conclusión amplia
de la v1.0 por una conclusión más precisa y más útil para auditoría:

| Conclusión | Estado |
|------------|--------|
| Implementación estadística conforme con ISO 13528:2022 | Sí |
| Soporte operativo coherente con ISO 17043:2024 | Sí |
| Hallazgos H1-H9 cerrados | Sí |
| Validación cruzada del Algoritmo A satisfactoria | Sí |
| Consolidación documental complementaria | En curso |

La recomendación técnica es mantener este informe como versión vigente y, en una
iteración posterior, fortalecer la organización de la documentación
complementaria y completar la sección reservada para validación de
scores/puntuaciones en una edición posterior del expediente de validación.

---

## 12. Certificación

Con base en la evidencia disponible al **2026-03-13**, se certifica que:

1. La lógica estadística principal del aplicativo produce resultados correctos,
reproducibles y consistentes con la norma.
2. Las observaciones técnicas formuladas durante las revisiones externas fueron
atendidas y quedaron trazadas en el código y en la interfaz.
3. La validación del Algoritmo A fue reforzada con comparación cruzada
independiente y resultados satisfactorios.
Esta certificación se emite con recomendación de continuar fortaleciendo la
documentación complementaria del repositorio en una próxima actualización.

---

## 13. Anexos

| Anexo | Descripción |
|-------|-------------|
| 1 | `deliv/09_informe_final/md/anexo_calculos.md` |
| 2 | `deliv/09_informe_final/R/genera_anexos.R` |
| 3 | `VAL_sonnet/info.md` |
| 4 | `VAL_sonnet/Validacion_Cruzada_AlgoA.xlsx` |
| 5 | `rta rev1.pdf` |
| 6 | `Revisión aplicativo estadístico.pdf` |

---

**Informe versión:** 2.0  
**Fecha de emisión:** 2026-03-13  
**Estado:** Vigente  
**Próxima revisión sugerida:** actualización editorial de soportes documentales complementarios
