# Plan: Revisión del preprocesador CALAIRE para datos de referencia

**Timestamp:** 260506_1913
**Slug:** revision-preprocesador-referencia-calaire
**Estado:** Completado

## Objetivo

Revisar y ajustar el plan del preprocesador CALAIRE para que procese únicamente datos de referencia del proveedor/PT, no datos de participantes. El preprocesamiento debe partir siempre de datos minutales y producir promedios horarios por contaminante y nivel, junto con desviación estándar e incertidumbre estándar calculada como `s / sqrt(n)`.

El flujo debe permitir procesar selectivamente 1, varios o todos los contaminantes disponibles, tanto para referencia/ronda como para estabilidad y homogeneidad. Por ahora no se modificarán ni ampliarán los cálculos de medias móviles.

## Contexto corregido

- No se requiere procesar datos de participantes dentro del preprocesador CALAIRE.
- El preprocesador debe enfocarse en mediciones de referencia CALAIRE.
- “Ronda” se refiere a la ronda del ensayo de aptitud, pero el preprocesamiento aquí sigue siendo solo de la referencia CALAIRE, no de participantes.
- Los contaminantes posibles son: CO, SO2, NO, NO2 y O3.
- Los datos de entrada son siempre minutales.
- El procesamiento base requerido es por promedios horarios.
- El criterio de hora válida aplica para ronda, estabilidad y homogeneidad: al menos 75% de datos minutales (`n >= 45`).
- Para cada contaminante, nivel y hora se debe calcular:
  - promedio horario
  - desviación estándar horaria `s`
  - número de observaciones minutales `n`
  - incertidumbre estándar horaria `u = s / sqrt(n)`
- Para niveles con 3 promedios horarios, se calcula después:
  - promedio final del nivel a partir de los 3 promedios horarios
  - incertidumbre final del nivel usando el mismo modelo `s / sqrt(n)`, aplicado sobre los 3 promedios horarios
- Excepción: el nivel 0 tiene un solo promedio horario; no aplica consolidación de 3 horas.
- El número de contaminantes procesados puede variar: 1, 2, 3, 4 o 5, según disponibilidad/necesidad.
- La lógica debe aplicar tanto a estabilidad como a homogeneidad.
- Las medias móviles quedan fuera del alcance de este ajuste por ahora.

## Fases

### Fase 1: Aclaración conceptual y alcance

| Item | Estado | Notas |
|------|--------|-------|
| Confirmar qué significa “ronda” en este contexto | Completado | Es la ronda del ensayo de aptitud; el preprocesador solo usa referencia CALAIRE, no participantes |
| Confirmar contaminantes esperados | Completado | CO, SO2, NO, NO2, O3 |
| Confirmar estructura de niveles | Completado | Ronda identifica niveles desde columnas generadas `*_gen` y `niveles_calaire.csv`; estabilidad/homogeneidad usa diseño temporal |
| Confirmar criterios de hora válida | Completado | Hora válida si tiene al menos 75% de datos minutales: `n >= 45` |
| Definir explícitamente fuera de alcance los participantes | Completado | Plan previo actualizado: Fase 3 ahora es referencia de ronda, no participantes |

### Fase 2: Revisión del plan existente

| Item | Estado | Notas |
|------|--------|-------|
| Revisar `260425_1127_plan_preprocesamiento-calaire.md` | Completado | Se actualizó objetivo, Fase 2.3, Fase 3 y log |
| Reclasificar Fase 3 actual | Completado | `datos_ronda.csv` se trata como referencia de ronda, no participantes |
| Revisar Fase 4 actual | Completado | `u_i` queda fuera del preprocesador CALAIRE; integración pendiente con salidas de referencia |
| Documentar cambios de alcance | Completado | Trazabilidad registrada en ambos planes |

### Fase 3: Diseño de entrada y metadatos

| Item | Estado | Notas |
|------|--------|-------|
| Definir metadatos para selección de contaminantes | Completado | Parámetro opcional `pollutants`; procesa 1 a 5 contaminantes disponibles |
| Definir metadatos para niveles | Completado | `niveles_calaire.csv` para nominal/tolerancia; diseño temporal para estabilidad/homogeneidad |
| Definir archivo(s) crudo(s) de referencia | Completado | `datos_estabilidad_homogeneidad.csv` y `datos_ronda.csv` |
| Definir contrato de columnas normalizadas | Completado | `timestamp` + columnas normalizadas `*_calaire_*`/`*_gen_*` |

### Fase 4: Ajuste del pipeline de promedios horarios

| Item | Estado | Notas |
|------|--------|-------|
| Generalizar selección de contaminantes | Completado | Procesa solo columnas de referencia disponibles; soporta CO, SO2, NO, NO2, O3 |
| Calcular promedio horario por contaminante/nivel | Completado | Desde datos minutales, por bloques consecutivos de 60 min por nivel |
| Calcular `s`, `n` y `u = s / sqrt(n)` | Completado | Por cada contaminante, nivel y bloque horario válido |
| Calcular promedio final por nivel | Completado | Consolida promedios horarios disponibles; excepción nivel 0 con una sola hora |
| Calcular incertidumbre final por nivel | Completado | Usa `s / sqrt(n_hours)` sobre promedios horarios; nivel 0 usa la incertidumbre horaria |
| Mantener validación de horas | Completado | Ronda valida `n >= 45`; niveles no-cero se limitan a 3 promedios horarios |
| No tocar medias móviles | Completado | No se modificó la lógica de medias móviles |

### Fase 5: Salidas esperadas y validación

| Item | Estado | Notas |
|------|--------|-------|
| Definir salidas procesadas de referencia | Completado | `h_estabilidad_homogeneidad.csv`, `mm_estabilidad_homogeneidad.csv`, `h_referencia_ronda.csv`, `referencia_ronda.csv` |
| Validar que no existan dependencias de participantes | Completado | Pipeline solo lee raw CALAIRE y metadatos CALAIRE |
| Validar cálculo de incertidumbre | Completado | Horaria: `u = s / sqrt(n)`; final: `s / sqrt(n_hours)` |
| Validar ejecución con subconjuntos de contaminantes | Completado | Prueba manual OK con `pollutants = "co"` en ambos pipelines |

### Fase 6: Actualización documental

| Item | Estado | Notas |
|------|--------|-------|
| Actualizar plan previo o marcarlo corregido | Completado | `260425_1127_plan_preprocesamiento-calaire.md` corregido |
| Documentar alcance final del preprocesador | Completado | Solo referencia CALAIRE |
| Registrar decisión sobre medias móviles | Completado | No se alteró algoritmo de medias móviles; solo se regeneró salida |

## Decisiones cerradas

1. Los niveles de ronda se identifican con columnas generadas `*_gen` y `niveles_calaire.csv`; estabilidad/homogeneidad usa diseño temporal.
2. Una hora válida requiere al menos 75% de datos minutales (`n >= 45`).
3. Las salidas son largas: una fila por hora-contaminante-nivel y una fila final por contaminante-nivel.
4. Para nivel 0, la incertidumbre final queda igual a la incertidumbre de su único promedio horario.

## Log de Ejecución

- [260506 19:13] Plan creado para corregir alcance: procesar solo referencia CALAIRE, no participantes.
- [260506 19:13] Aclarado alcance: contaminantes CO, SO2, NO, NO2, O3; ronda = ensayo de aptitud; cálculo por hora y consolidación posterior con 3 promedios horarios, excepto nivel 0.
- [260506 19:13] Implementado procesamiento de referencia ronda: lectura sin fila de unidades, columnas `*_ref`, salida horaria `h_referencia_ronda.csv` y salida consolidada `referencia_ronda.csv`.
- [260506 19:13] Validación ejecutada: pipeline completo exitoso. Hallazgo: en `datos_ronda.csv`, nivel 2.8/80 produce 2 bloques de 60 min y nivel 1.4/40 produce 4 bloques de 60 min; no todos cumplen la regla esperada de 3 horas.
- [260506 20:16] Nuevo criterio implementado en ronda: hora válida si `n >= 45` (75%). Con esto 2.8/80 recupera tercera hora parcial con `n = 57`; para 1.4/40 se conservan las primeras 3 horas y se excluye la cuarta.
- [260506 20:18] Criterio `n >= 45` extendido a estabilidad/homogeneidad. Validación completa exitosa: estabilidad/homogeneidad 22 horas válidas con `n >= 45` (todas tienen `n = 60`); ronda 26 horas válidas, mínimo `n = 57`.
- [260506 20:25] Plan implementado completo: selección opcional de contaminantes, plan previo corregido, lock file eliminado, validación completa y prueba selectiva `pollutants = "co"` OK.
