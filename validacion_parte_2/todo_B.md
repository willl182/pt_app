# TODO_validacion_B.md

## Estado general del proyecto

**Proyecto**: Validación downstream de Algoritmo A
**Estado**: En preparación
**Objetivo**: Validar toda la cadena posterior a Algoritmo A con comparación entre `app.R`, R independiente y Python independiente.

---

# 0. Reglas operativas del proyecto

## Reglas de trabajo

* [ ] No avanzar de fase si la anterior no tiene outputs revisables
* [ ] Toda discrepancia debe clasificarse
* [ ] Toda etapa debe dejar evidencia reproducible
* [ ] CSV + Markdown son la evidencia principal
* [ ] Excel es solo apoyo de trazabilidad humana

## Estados válidos

* [ ] `PASS`
* [ ] `FAIL`
* [ ] `EDGE_CASE`
* [ ] `KNOWN_DISCREPANCY`

---

# 1. Preparación del entorno (FASE 0)

## 1.1. Estructura base

* [ ] Crear carpeta `validation/`
* [ ] Crear carpeta `validation/outputs/`
* [ ] Crear carpeta `validation/outputs/combo_excels/`

## 1.2. Archivos base

* [ ] Crear `validation/plan_validacion_final.md`
* [ ] Crear `validation/plan_validacion_operativo.md`
* [ ] Crear `validation/TODO_validacion.md`
* [ ] Crear `validation/USAGE.md`

## 1.3. Scripts base R

* [ ] Crear `validation/run_validation_all.R`
* [ ] Crear `validation/stage_01_robust_stats.R`
* [ ] Crear `validation/stage_02_homogeneity.R`
* [ ] Crear `validation/stage_03_stability.R`
* [ ] Crear `validation/stage_04_uncertainty_chain.R`
* [ ] Crear `validation/stage_05_scores.R`

## 1.4. Scripts base Python

* [ ] Crear `validation/run_validation_all.py`
* [ ] Crear `validation/stage_01_robust_stats.py`
* [ ] Crear `validation/stage_02_homogeneity.py`
* [ ] Crear `validation/stage_03_stability.py`
* [ ] Crear `validation/stage_04_uncertainty_chain.py`
* [ ] Crear `validation/stage_05_scores.py`

## 1.5. Definición de combos

* [ ] Definir los 15 combos objetivo en R
* [ ] Definir los 15 combos objetivo en Python
* [ ] Verificar que la definición sea exactamente la misma en ambos

## 1.6. Tabla canónica

* [ ] Definir columnas mínimas estándar
* [ ] Documentarlas en `USAGE.md`
* [ ] Usarlas como contrato de salida para todas las etapas

## 1.7. Cierre Fase 0

* [ ] La estructura de carpetas existe
* [ ] Los archivos base existen
* [ ] Los combos están definidos
* [ ] La tabla canónica está definida
* [ ] `USAGE.md` inicial existe

**Estado Fase 0**:

* [ ] Pendiente
* [ ] En progreso
* [ ] Cerrada

---

# 2. Etapa 1 — Robust Stats (FASE 1)

## Objetivo

Validar extracción y estadísticos robustos aguas abajo de Algoritmo A.

---

## 2.1. Extracción de datos desde `summary_n13.csv`

* [ ] Leer `data/summary_n13.csv`
* [ ] Filtrar por contaminante
* [ ] Filtrar por nivel
* [ ] Excluir `participant_id == "ref"`
* [ ] Agrupar por participante
* [ ] Calcular `mean(mean_value)`
* [ ] Calcular `mean(sd_value)`

## 2.2. Validación de extracción

* [ ] Confirmar número de participantes esperado por combo
* [ ] Confirmar que la serie `xi` coincide con la app
* [ ] Confirmar que no se pierde ningún participante
* [ ] Confirmar que `ref` nunca entra

## 2.3. Cálculo independiente en R

* [ ] Implementar mediana
* [ ] Implementar MAD
* [ ] Implementar MADe
* [ ] Implementar Q1
* [ ] Implementar Q3
* [ ] Implementar IQR
* [ ] Implementar nIQR

## 2.4. Cálculo independiente en Python

* [ ] Implementar mediana
* [ ] Implementar MAD
* [ ] Implementar MADe
* [ ] Implementar Q1
* [ ] Implementar Q3
* [ ] Implementar IQR
* [ ] Implementar nIQR

## 2.5. Comparación tripartita

* [ ] Comparar app vs R
* [ ] Comparar app vs Python
* [ ] Comparar R vs Python
* [ ] Aplicar tolerancia

## 2.6. Outputs

* [ ] Generar `outputs/stage_01_robust_stats.csv`
* [ ] Generar `outputs/stage_01_robust_stats_report.md`

## 2.7. Reporte de etapa

* [ ] Incluir combos procesados
* [ ] Incluir métricas evaluadas
* [ ] Incluir conteo PASS/FAIL
* [ ] Incluir discrepancias
* [ ] Incluir observaciones

## 2.8. Cierre Fase 1

* [ ] Serie `xi` validada
* [ ] Mediana validada
* [ ] MAD validado
* [ ] MADe validado
* [ ] Q1 validado
* [ ] Q3 validado
* [ ] IQR validado
* [ ] nIQR validado
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Discrepancias clasificadas

**Estado Fase 1**:

* [ ] Pendiente
* [ ] En progreso
* [ ] Cerrada

---

# 3. Etapa 2 — Homogeneidad (FASE 2)

## Objetivo

Validar la evaluación de homogeneidad y sus criterios.

---

## 3.1. Lectura de `homogeneity_n13.csv`

* [ ] Leer `data/homogeneity_n13.csv`
* [ ] Filtrar por contaminante y nivel
* [ ] Validar estructura de réplicas
* [ ] Pivotear a formato ancho

## 3.2. Validación de estructura

* [ ] Confirmar número de muestras esperado
* [ ] Confirmar número de réplicas esperado
* [ ] Confirmar consistencia de datos faltantes
* [ ] Confirmar que el pivoteo coincide con la lógica de la app

## 3.3. Cálculo independiente en R

* [ ] Calcular `g`
* [ ] Calcular `m`
* [ ] Calcular media general
* [ ] Calcular `x_pt`
* [ ] Calcular `s²_x̄`
* [ ] Calcular `sw`
* [ ] Calcular `ss²`
* [ ] Calcular `ss`
* [ ] Calcular `MADe_hom`
* [ ] Calcular `sigma_pt`
* [ ] Calcular `u(sigma_pt)`
* [ ] Calcular criterio `c`
* [ ] Calcular criterio expandido
* [ ] Calcular evaluación final

## 3.4. Cálculo independiente en Python

* [ ] Calcular `g`
* [ ] Calcular `m`
* [ ] Calcular media general
* [ ] Calcular `x_pt`
* [ ] Calcular `s²_x̄`
* [ ] Calcular `sw`
* [ ] Calcular `ss²`
* [ ] Calcular `ss`
* [ ] Calcular `MADe_hom`
* [ ] Calcular `sigma_pt`
* [ ] Calcular `u(sigma_pt)`
* [ ] Calcular criterio `c`
* [ ] Calcular criterio expandido
* [ ] Calcular evaluación final

## 3.5. Comparación tripartita

* [ ] Comparar app vs R
* [ ] Comparar app vs Python
* [ ] Comparar R vs Python
* [ ] Aplicar tolerancia

## 3.6. Outputs

* [ ] Generar `outputs/stage_02_homogeneity.csv`
* [ ] Generar `outputs/stage_02_homogeneity_report.md`

## 3.7. Cierre Fase 2

* [ ] `g` validado
* [ ] `m` validado
* [ ] media general validada
* [ ] `x_pt` validado
* [ ] `s²_x̄` validado
* [ ] `sw` validado
* [ ] `ss²` validado
* [ ] `ss` validado
* [ ] `MADe_hom` validado
* [ ] `sigma_pt` validado
* [ ] `u(sigma_pt)` validado
* [ ] criterio `c` validado
* [ ] criterio expandido validado
* [ ] evaluación final validada
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Discrepancias clasificadas

**Estado Fase 2**:

* [ ] Pendiente
* [ ] En progreso
* [ ] Cerrada

---

# 4. Etapa 3 — Estabilidad (FASE 3)

## Objetivo

Validar estabilidad y documentar discrepancias conocidas.

---

## 4.1. Lectura de `stability_n13.csv`

* [ ] Leer `data/stability_n13.csv`
* [ ] Filtrar por contaminante y nivel
* [ ] Verificar estructura de muestras/réplicas

## 4.2. Cálculo independiente en R

* [ ] Calcular media general de estabilidad
* [ ] Calcular `d_max`
* [ ] Calcular criterio simple
* [ ] Calcular criterio expandido
* [ ] Calcular `u_stab`
* [ ] Calcular evaluación final

## 4.3. Cálculo independiente en Python

* [ ] Calcular media general de estabilidad
* [ ] Calcular `d_max`
* [ ] Calcular criterio simple
* [ ] Calcular criterio expandido
* [ ] Calcular `u_stab`
* [ ] Calcular evaluación final

## 4.4. Discrepancia conocida

* [ ] Verificar comportamiento de `u_stab` en `app.R`
* [ ] Verificar comportamiento de `u_stab` en función pura
* [ ] Clasificar la discrepancia como `KNOWN_DISCREPANCY`
* [ ] Incluir la discrepancia en el reporte

## 4.5. Comparación tripartita

* [ ] Comparar app vs R
* [ ] Comparar app vs Python
* [ ] Comparar R vs Python
* [ ] Aplicar tolerancia

## 4.6. Outputs

* [ ] Generar `outputs/stage_03_stability.csv`
* [ ] Generar `outputs/stage_03_stability_report.md`

## 4.7. Cierre Fase 3

* [ ] media general validada
* [ ] `d_max` validado
* [ ] criterio simple validado
* [ ] criterio expandido validado
* [ ] `u_stab` validado
* [ ] evaluación final validada
* [ ] discrepancia conocida documentada
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Discrepancias clasificadas

**Estado Fase 3**:

* [ ] Pendiente
* [ ] En progreso
* [ ] Cerrada

---

# 5. Etapa 4 — Cadena de incertidumbre (FASE 4)

## Objetivo

Validar toda la propagación downstream de incertidumbres.

---

## 5.1. Integración de inputs

* [ ] Consumir correctamente outputs de Etapa 1
* [ ] Consumir correctamente outputs de Etapa 2
* [ ] Consumir correctamente outputs de Etapa 3

## 5.2. Método 1 — Referencia

* [ ] Validar `x_pt`
* [ ] Validar `sigma_pt`
* [ ] Validar `u_xpt`

## 5.3. Método 2a — Consenso MADe

* [ ] Validar `x_pt`
* [ ] Validar `sigma_pt`
* [ ] Validar `u_xpt`

## 5.4. Método 2b — Consenso nIQR

* [ ] Validar `x_pt`
* [ ] Validar `sigma_pt`
* [ ] Validar `u_xpt`

## 5.5. Método 3 — Algoritmo A

* [ ] Validar `x_pt`
* [ ] Validar `sigma_pt`
* [ ] Validar `u_xpt`

## 5.6. Métricas comunes

* [ ] Validar `u_hom`
* [ ] Validar `u_stab`
* [ ] Validar `u_xpt_def`
* [ ] Validar `U_xpt`

## 5.7. Cálculo independiente en Python

* [ ] Reproducir Método 1
* [ ] Reproducir Método 2a
* [ ] Reproducir Método 2b
* [ ] Reproducir Método 3
* [ ] Reproducir métricas comunes

## 5.8. Comparación tripartita

* [ ] Comparar app vs R
* [ ] Comparar app vs Python
* [ ] Comparar R vs Python
* [ ] Aplicar tolerancia

## 5.9. Outputs

* [ ] Generar `outputs/stage_04_uncertainty_chain.csv`
* [ ] Generar `outputs/stage_04_uncertainty_chain_report.md`

## 5.10. Cierre Fase 4

* [ ] Método referencia validado
* [ ] Método consenso MADe validado
* [ ] Método consenso nIQR validado
* [ ] Método Algoritmo A validado
* [ ] `u_hom` validado
* [ ] `u_stab` validado
* [ ] `u_xpt_def` validado
* [ ] `U_xpt` validado
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Discrepancias clasificadas

**Estado Fase 4**:

* [ ] Pendiente
* [ ] En progreso
* [ ] Cerrada

---

# 6. Etapa 5 — Scores (FASE 5)

## Objetivo

Validar los puntajes finales de desempeño y sus etiquetas.

---

## 6.1. Cálculo independiente en R

* [ ] Calcular `z`
* [ ] Calcular `z'`
* [ ] Calcular `zeta`
* [ ] Calcular `En`

## 6.2. Evaluaciones cualitativas

* [ ] Validar `Satisfactorio`
* [ ] Validar `Cuestionable`
* [ ] Validar `No satisfactorio`

## 6.3. Cálculo independiente en Python

* [ ] Calcular `z`
* [ ] Calcular `z'`
* [ ] Calcular `zeta`
* [ ] Calcular `En`
* [ ] Calcular evaluaciones

## 6.4. Comparación tripartita

* [ ] Comparar app vs R
* [ ] Comparar app vs Python
* [ ] Comparar R vs Python
* [ ] Aplicar tolerancia

## 6.5. Outputs

* [ ] Generar `outputs/stage_05_scores.csv`
* [ ] Generar `outputs/stage_05_scores_report.md`

## 6.6. Cierre Fase 5

* [ ] `z` validado
* [ ] `z'` validado
* [ ] `zeta` validado
* [ ] `En` validado
* [ ] Etiquetas cualitativas validadas
* [ ] CSV generado
* [ ] Reporte generado
* [ ] Discrepancias clasificadas

**Estado Fase 5**:

* [ ] Pendiente
* [ ] En progreso
* [ ] Cerrada

---

# 7. Integración final (FASE 6)

## Objetivo

Consolidar la validación completa y dejarla lista para revisión final.

---

## 7.1. Consolidación de resultados

* [ ] Unir `stage_01_robust_stats.csv`
* [ ] Unir `stage_02_homogeneity.csv`
* [ ] Unir `stage_03_stability.csv`
* [ ] Unir `stage_04_uncertainty_chain.csv`
* [ ] Unir `stage_05_scores.csv`

## 7.2. Resumen maestro

* [ ] Generar `outputs/validation_summary_master.csv`
* [ ] Incluir conteos PASS
* [ ] Incluir conteos FAIL
* [ ] Incluir conteos EDGE_CASE
* [ ] Incluir conteos KNOWN_DISCREPANCY

## 7.3. Fail log

* [ ] Generar `outputs/validation_fail_log.csv`
* [ ] Incluir combo
* [ ] Incluir etapa
* [ ] Incluir métrica
* [ ] Incluir participante si aplica
* [ ] Incluir diferencias
* [ ] Incluir notas

## 7.4. Excels por combo (opcional)

* [ ] Definir si realmente se necesitan
* [ ] Si sí: generar 1 Excel por combo
* [ ] Si sí: usar 1 sola hoja por combo
* [ ] Si sí: usar tabla canónica

## 7.5. Validación de cierre

* [ ] Revisar si quedan `FAIL`
* [ ] Revisar si los `EDGE_CASE` están documentados
* [ ] Revisar si las `KNOWN_DISCREPANCY` están documentadas
* [ ] Verificar trazabilidad completa

## 7.6. Cierre Fase 6

* [ ] Existe resumen maestro
* [ ] Existe fail log
* [ ] Existe trazabilidad completa
* [ ] La validación corre de extremo a extremo

**Estado Fase 6**:

* [ ] Pendiente
* [ ] En progreso
* [ ] Cerrada

---

# 8. Cierre global del proyecto

## Requisitos mínimos para declarar “Validación cerrada”

* [ ] Todas las fases están cerradas
* [ ] Todos los CSV existen
* [ ] Todos los reportes Markdown existen
* [ ] Existe `validation_summary_master.csv`
* [ ] Existe `validation_fail_log.csv`
* [ ] Existe `USAGE.md`
* [ ] No hay `FAIL` sin explicación
* [ ] Los casos borde están documentados
* [ ] Las discrepancias conocidas están documentadas
* [ ] La validación es reproducible

---

# 9. Registro rápido de bloqueos

## Bloqueos técnicos

* [ ] Ninguno
* [ ] Hay bloqueos pendientes

## Notas de bloqueo

* [ ] Pendiente completar

---

# 10. Próxima acción recomendada

## Siguiente paso inmediato

* [ ] Empezar Fase 0
* [ ] Crear estructura de carpetas
* [ ] Definir combos
* [ ] Crear tabla canónica
* [ ] Crear `USAGE.md`

