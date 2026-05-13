# Plan: Validación de cálculos por etapa en `app.R`

**Timestamp:** 260512_2109  
**Slug:** validar-calculos-app-etapas  
**Estado:** En progreso

## Objetivo

Diseñar una validación por etapas de los cálculos de `app.R`, usando como base los datos de `data/for_validation`.

La validación debe cubrir explícitamente el Algoritmo A y sus salidas asociadas, incluyendo los componentes que intervienen en la incertidumbre cuando formen parte del cálculo de la etapa.

La validación primaria se hará con `O3`. Lo demás quedará para una ronda posterior.

La validación debe cubrir tres vías complementarias:

1. scripts de R,
2. scripts de Python,
3. hoja de cálculo.

Para la vía de hoja de cálculo, primero se deben extraer y documentar las fórmulas usadas antes de construir las hojas.

## Alcance y criterio de selección de datos

- Fuente de validación: `data/for_validation`.
- Validación primaria:
  - `O3` en tres niveles: bajo, medio y alto.
  - El orden debe definirse por valor numérico, no por el orden de aparición.
- Validación posterior:
  - `CO` -> nivel 1o
  - `SO2` -> nivel 2o
  - `NO2` -> nivel 3o
  - `NO` -> nivel 4o
  - `O3` -> nivel 5o
- La selección dentro de cada contaminante se hace tomando los valores de menor a mayor.

## Resultado esperado

- Inventario completo de cálculos de `app.R` por etapa.
- Mapa explícito de los puntos donde entra el Algoritmo A.
- Validación de las variables y resultados derivados del Algoritmo A.
- Matriz primaria de validación con `O3` en tres niveles.
- Matriz posterior de validación con un caso por contaminante.
- Tres implementaciones de verificación alineadas entre sí.
- Comparación explícita de resultados contra el cálculo de la app.
- Evidencia de diferencias, tolerancias aceptadas y puntos que requieran ajuste.
- Informe de validación completo, estructurado para que solo falten pantallazos.

## Fases

### Fase 1: Inventario funcional de `app.R`

Objetivo: identificar cada etapa de cálculo que ocurre en la aplicación y definir qué se valida en cada una.

| Item | Estado | Notas |
|------|--------|-------|
| Mapear flujo completo de `app.R` | Pendiente | UI, preparación de datos, selección, cálculo, resumen, salida |
| Identificar funciones y reactivos con lógica numérica | Pendiente | Solo cálculos y transformaciones relevantes |
| Ubicar la implementación del Algoritmo A | Pendiente | Dónde se calcula y qué objetos produce |
| Identificar dónde se calcula la incertidumbre | Pendiente | Tratarla como parte de la lógica principal cuando aplique |
| Definir entradas, salidas y dependencias por etapa | Pendiente | Qué consume y qué produce cada bloque |
| Separar cálculos puros de lógica de presentación | Pendiente | Base para validar sin ruido de interfaz |

### Fase 2: Diseño de matriz de validación

Objetivo: construir el conjunto mínimo pero representativo de casos a validar, empezando por `O3`.

| Item | Estado | Notas |
|------|--------|-------|
| Inspeccionar `data/for_validation` | Pendiente | Ver estructura, variables y disponibilidad por contaminante |
| Seleccionar tres niveles de `O3` | Pendiente | Bajo, medio y alto, ordenados por valor numérico |
| Documentar ruta posterior | Pendiente | `CO`, `SO2`, `NO2`, `NO`, `O3` restante |
| Documentar casos de prueba y supuestos | Pendiente | Qué se valida ahora y qué después |

### Fase 3: Validación con scripts de R

Objetivo: reproducir la lógica de `app.R` en R de manera trazable.

| Item | Estado | Notas |
|------|--------|-------|
| Extraer cálculos a scripts reproducibles | Pendiente | Una función o script por etapa, si aplica |
| Definir salidas intermedias comparables | Pendiente | Tablas por etapa, no solo resultado final |
| Reproducir el Algoritmo A | Pendiente | Incluye sus entradas, transformaciones y salidas |
| Comparar contra `app.R` | Pendiente | Igualdad exacta o tolerancia numérica según corresponda |
| Registrar discrepancias | Pendiente | Diferencias de redondeo, NA, filtros o clasificación |

### Fase 4: Validación con scripts de Python

Objetivo: tener una segunda implementación independiente para detectar errores de lógica.

| Item | Estado | Notas |
|------|--------|-------|
| Replicar entradas y reglas de negocio | Pendiente | Misma selección de casos y mismo orden de cálculo |
| Implementar cálculo por etapa | Pendiente | Mantener trazabilidad de cada transformación |
| Reproducir el Algoritmo A | Pendiente | Incluye el manejo de incertidumbre si participa en la etapa |
| Comparar contra R y `app.R` | Pendiente | Buscar coincidencia conceptual y numérica |
| Documentar divergencias entre lenguajes | Pendiente | Tipos, redondeo, NA, ordenamiento |

### Fase 5: Extracción de fórmulas y hoja de cálculo

Objetivo: construir una validación manual/semimanual en hoja de cálculo con fórmulas explícitas.

| Item | Estado | Notas |
|------|--------|-------|
| Listar todas las fórmulas necesarias | Pendiente | Antes de crear la hoja |
| Definir estructura de la hoja de cálculo | Pendiente | Hoja de datos, hoja de fórmulas, hoja de verificación |
| Construir plantilla con fórmulas | Pendiente | Sin automatizar primero la trazabilidad |
| Validar contra R/Python/app.R | Pendiente | Comparación de valores por etapa |

### Fase 6: Consolidación y cierre

Objetivo: dejar una validación mantenible y auditable.

| Item | Estado | Notas |
|------|--------|-------|
| Consolidar resultados por etapa | Pendiente | Tabla final de coincidencias y diferencias |
| Definir tolerancias y reglas de aceptación | Pendiente | Qué se considera correcto |
| Redactar conclusiones de validación | Pendiente | Riesgos, límites y cobertura |
| Redactar informe de validación final | Pendiente | Documento completo, con espacios para pegar pantallazos |
| Guardar evidencias y dejar trazabilidad | Pendiente | Scripts, hojas y notas finales |

## Log de Ejecución

- [260512 21:09] Plan creado para validar los cálculos de `app.R` por etapa.
- [260512 21:09] Ajuste: validación primaria definida sobre `O3`.

## Observaciones de diseño

- La validación debe priorizar etapas de cálculo, no la interfaz.
- El Algoritmo A es parte central de la validación, no un apéndice.
- La incertidumbre no se desplaza a un plan paralelo: se valida donde afecte la salida del algoritmo o de la etapa.
- La validación primaria usa `O3` en tres niveles; la extensión a los demás contaminantes queda para una ronda posterior.
- La hoja de cálculo debe construirse después de extraer las fórmulas, para que funcione como referencia legible y no como una copia opaca de la lógica.
- Si aparecen diferencias entre R y Python, se debe revisar primero redondeo, filtros, NA y orden de agrupación antes de asumir un error del algoritmo.
- El informe final debe quedar listo para completar con capturas de pantalla, no para redactarse desde cero al final.

## Entregables y control de archivos

Para evitar dispersión de artefactos, la validación se trabajará con un máximo de 5 archivos de soporte:

1. `scripts/` de R para reproducir la validación primaria.
2. `scripts/` de Python para la reproducción independiente.
3. Un archivo de hoja de cálculo único con la plantilla y las fórmulas.
4. Un informe de validación único.
5. Una nota de trazabilidad o índice de evidencias.

No se crearán archivos por contaminante en esta fase.
