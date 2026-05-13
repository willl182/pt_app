# Plan: Ajustar validación de redondeo, consensos y scores

**Timestamp:** 260513_0528
**Slug:** validacion-redondeo-consenso-scores
**Estado:** En progreso

## Objetivo
Dejar la validación con todos los resultados redondeados a 4 decimales, hacer explícito el cálculo por referencia y por consenso, y clarificar los resultados de score por cada método de valor asignado.

## Fases

### Fase 1: Redondeo homogéneo
| Item | Estado | Notas |
|------|--------|-------|
| Identificar salidas de validación afectadas | En progreso | `stage_04` y `stage_05` |
| Aplicar formato de 4 decimales en CSV/reportes | Pendiente | Sin cambiar la lógica numérica interna |

### Fase 2: Transparencia de métodos
| Item | Estado | Notas |
|------|--------|-------|
| Asegurar que referencia y consensos se reporten explícitamente | Pendiente | Incluye método 1, 2a, 2b y 3 |
| Hacer legible el score por método | Pendiente | Etiquetas y tablas de resumen |

### Fase 3: Verificación
| Item | Estado | Notas |
|------|--------|-------|
| Revisión local de scripts y salida esperada | Pendiente | Validar que no haya regresiones |
| Resumen final para el usuario | Pendiente | Con rutas de archivos modificados |

## Log de Ejecución
- [260513 05:28] Plan creado
