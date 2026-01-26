# Entregable 02 - Funciones Usadas en app.R y reports/

**Fase:** 1 - Fundación  
**Fecha de creación:** 2026-01-24  
**Estado:** Completado

## Objetivo

Documentar todas las funciones disponibles en la aplicación con sus firmas, parámetros, tipos de retorno y referencias a estándares ISO.

## Descripción

Este entregable contiene:
- Inventario completo de funciones en `app.R`, `R/` y `reports/`
- Documentación detallada de cada función
- Tests que verifican la ejecución correcta de las funciones

## Archivos Incluidos

| Archivo | Descripción | Ubicación |
|---------|-------------|-----------|
| `README.md` | Este documento | `/` |
| `R/lista_funciones.R` | Script de extracción de firmas | `R/` |
| `md/funciones_extraidas.csv` | Tabla con todas las funciones | `md/` |
| `md/documentacion_funciones.md` | Documentación en formato Markdown | `md/` |
| `tests/test_02_firma_funciones.R` | Tests de verificación | `tests/` |
| `tests/test_02_firma_funciones.md` | Guía de uso | `tests/` |

## Resumen de Funciones Encontradas

**Total:** 48 funciones únicas

### Categorías

#### Estadísticas de Homogeneidad
- `calculate_homogeneity_stats()` - Estadísticos ANOVA
- `calculate_homogeneity_criterion()` - Criterio de homogeneidad
- `calculate_homogeneity_criterion_expanded()` - Criterio expandido
- `evaluate_homogeneity()` - Evaluación de criterios

#### Estadísticas de Estabilidad
- `calculate_stability_stats()` - Estadísticos de estabilidad
- `calculate_stability_criterion()` - Criterio de estabilidad
- `evaluate_stability()` - Evaluación de estabilidad

#### Estadísticas Robustos
- `calculate_niqr()` - nIQR (ISO 13528:2022 §9.4)
- `calculate_mad_e()` - MADe (ISO 13528:2022 §9.4)
- `run_algorithm_a()` - Algoritmo A iterativo
- `algorithm_A()` - Versión exportada del Algoritmo A

#### Cálculo de Puntajes PT
- `calculate_z_score()` - Puntaje z (ISO 13528:2022 §10.2)
- `calculate_z_prime_score()` - Puntaje z' (ISO 13528:2022 §10.3)
- `calculate_zeta_score()` - Puntaje ζ (ISO 13528:2022 §10.4)
- `calculate_en_score()` - Puntaje En (ISO 13528:2022 §10.5)
- `evaluate_z_score()` - Clasificación de puntajes z
- `evaluate_en_score()` - Clasificación de puntajes En

#### Utilidades
- `calculate_u_hom()` - Incertidumbre de homogeneidad
- `calculate_u_stab()` - Incertidumbre de estabilidad
- `format_with_n()` - Formateo con n
- `get_participants_for_combo()` - Obtener participantes
- `get_sample_data()` - Obtener datos de muestra
- Otras 23 funciones auxiliares

## Uso del Script de Extracción

Para ejecutar el script de extracción:

```r
# Ir al directorio del script
setwd("deliv/02_funciones_usadas/R")

# Ejecutar el script
source("lista_funciones.R")
```

El script genera:
1. **CSV:** `md/funciones_extraidas.csv` - Tabla con metadata
2. **Markdown:** `md/documentacion_funciones.md` - Documentación legible

## Formato de Documentación

### CSV (funciones_extraidas.csv)

| Columna | Descripción |
|---------|-------------|
| `archivo` | Archivo donde se define la función |
| `nombre_funcion` | Nombre de la función |
| `descripcion` | Descripción breve (extraída de roxygen2) |
| `parametros` | Lista de parámetros |
| `retorno` | Tipo de retorno (cuando está disponible) |
| `referencia_iso` | Referencia a estándar ISO |

### Markdown (documentacion_funciones.md)

Cada función incluye:
- Nombre de la función
- Descripción
- Archivo de origen
- Parámetros
- Referencia ISO (si aplica)

## Ejemplo

```markdown
## `calculate_z_score`

Calcula el puntaje z según ISO 13528:2022

**Archivo:** `pt_scores.R`

**Parámetros:** `x, x_pt, sigma_pt`

**Referencia ISO:** ISO 13528:2022, Section 10.2
```

## Próximos Pasos

Este entregable proporciona el inventario necesario para:

1. **Entregable 03:** Implementar funciones standalone para cálculos PT
2. **Entregable 04:** Implementar módulo de cálculo de puntajes
3. **Entregable 08:** Documentación final para desarrolladores

## Referencias

- **ISO 13528:2022** - Statistical methods for proficiency testing
- **ISO 17043:2024** - General requirements for proficiency testing
- **AGENTS.md** - Guía de estilo y convenciones del código
