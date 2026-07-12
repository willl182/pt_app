# Entregable 02 - Funciones Usadas en app.R, R/ y ptcalc/R/

**Fase:** 1 - Fundacion  
**Fecha de creacion:** 2026-01-24  
**Fecha de regeneracion:** 2026-06-16  
**Estado:** Regenerado y enriquecido

## Objetivo

Documentar todas las funciones disponibles en la aplicacion con sus firmas,
parametros, tipos de retorno, ejemplos, referencias ISO y trazabilidad al archivo
fuente. Este entregable es la referencia tecnica del API interno del aplicativo
PT App.

## Descripcion

Este entregable contiene:

- Inventario completo de funciones en `app.R`, `R/`, `ptcalc/R/` y
  `reports/report_template.Rmd`.
- Documentacion enriquecida en Markdown con categorias, descripciones,
  parametros, valores de retorno, ejemplos y referencias ISO.
- Base de datos de firmas (`funciones_extraidas.csv`) para consumo automatizado.
- Script de extraccion (`R/lista_funciones.R`) que parsea bloques roxygen2
  completos y fusiona anotaciones manuales para funciones internas sin
  documentacion roxygen2.
- Tests que verifican la existencia y firma de las funciones documentadas.

## Archivos Incluidos

| Archivo | Descripcion | Ubicacion |
|---------|-------------|-----------|
| `README.md` | Este documento | `/` |
| `README.docx` | Version Word de este documento | `/` |
| `R/lista_funciones.R` | Script extractor de firmas y generador de documentacion | `R/` |
| `md/documentacion_funciones.md` | Documentacion enriquecida en Markdown | `md/` |
| `documentacion_funciones.docx` | Version Word de la documentacion | `/` |
| `funciones_extraidas.csv` | Tabla con metadata de todas las funciones | `/` |
| `tests/test_02_firma_funciones.R` | Tests de verificacion de firmas | `tests/` |
| `tests/test_02_firma_funciones.md` | Guia de uso de los tests | `tests/` |
| `test_02_resultados.csv` | Bitacora de ejecucion de pruebas | `/` |

## Resumen de Funciones Encontradas

**Total:** 77 funciones unicas

**Funciones exportadas (`@export`):** 24  
**Funciones obsoletas (`lifecycle::badge("deprecated")`):** 3

### Categorias

| Categoria | Funciones | Descripcion |
|-----------|-----------:|-------------|
| Estadisticos Robustos | 6 | nIQR, MADe, Algoritmo A y helpers de convergencia. |
| Homogeneidad y Estabilidad | 15 | Estadisticos ANOVA, criterios ISO, evaluacion y wrappers. |
| Puntajes PT | 15 | z, z', zeta, En y funciones de evaluacion/clasificacion. |
| Carga y Normalizacion | 8 | Lectura de CSV, normalizacion de contaminantes, incertidumbres y n_lab. |
| Formateo | 3 | Formateo numerico y de etiquetas de convergencia. |
| Visualizacion | 3 | Graficos ggplot y heatmaps plotly. |
| Reportes | 18 | Helpers para tablas, resumenes, valor asignado y reportes Rmd. |
| Servidor Shiny | 3 | Funcion servidor, ejecucion de scripts y preprocesador. |
| UI / Utilidades | 3 | Ecuaciones MathJax, claves y limpieza de nombres de archivo. |
| Obsoleto | 3 | Wrappers antiguos en `R/utils.R` (usar `ptcalc`). |

### Funciones principales por categoria

#### Estadisticos Robustos
- `calculate_niqr()` - Rango intercuartil normalizado (ISO 13528:2022 §9.4)
- `calculate_mad_e()` - MAD escalado (ISO 13528:2022 §9.4)
- `run_algorithm_a()` - Algoritmo A iterativo (ISO 13528:2022 Anexo C)
- `get_algo_a_stabilization_iter()` - Iteracion de convergencia
- `run_algorithm_a_report()` - Wrapper para informes
- `stable_sigfig_value()` - Redondeo a cifras significativas

#### Homogeneidad y Estabilidad
- `calculate_homogeneity_stats()` - Estadisticos de homogeneidad (ISO 13528:2022 §9.2)
- `calculate_homogeneity_criterion()` - Criterio c = 0.3 sigma_pt
- `calculate_homogeneity_criterion_expanded()` - Criterio expandido
- `evaluate_homogeneity()` - Evaluacion de criterios
- `calculate_stability_stats()` - Estadisticos de estabilidad
- `calculate_stability_criterion()` - Criterio de estabilidad
- `evaluate_stability()` - Evaluacion de estabilidad
- `calculate_u_hom()` - Incertidumbre de homogeneidad
- `calculate_u_stab()` - Incertidumbre de estabilidad
- `compute_homogeneity_metrics()` - Wrapper completo de app.R
- `compute_stability_metrics()` - Wrapper completo de app.R
- `compute_homogeneity()` - Wrapper del reporte Rmd

#### Puntajes PT
- `calculate_z_score()` - Puntaje z (ISO 13528:2022 §10.2)
- `calculate_z_prime_score()` - Puntaje z' (ISO 13528:2022 §10.3)
- `calculate_zeta_score()` - Puntaje zeta (ISO 13528:2022 §10.4)
- `calculate_en_score()` - Puntaje En (ISO 13528:2022 §10.5)
- `evaluate_z_score()` / `evaluate_z_score_vec()` - Clasificacion z
- `evaluate_en_score()` / `evaluate_en_score_vec()` - Clasificacion En
- `compute_combo_scores()` - Calculo nuclear de puntajes en app.R
- `compute_scores_for_selection()` - Orquestador del modulo de puntajes
- `compute_scores_metrics()` - Calculo vectorizado para reportes
- `calculate_expert_sigma_pt()` / `calculate_expert_u_xpt()` - Metodo experto
- `evaluate_u_xpt_sigma_criterion()` - Criterio u(x_pt) <= 0.3 sigma_pt

## Uso del Script de Extraccion

Para regenerar la documentacion desde la raiz del proyecto:

```r
Rscript Entregables_pt_app/02_funciones_usadas/R/lista_funciones.R
```

O desde R:

```r
source("Entregables_pt_app/02_funciones_usadas/R/lista_funciones.R")
```

El script genera:

1. **CSV:** `funciones_extraidas.csv` - Tabla con metadata estructurada.
2. **Markdown:** `md/documentacion_funciones.md` - Documentacion legible.

### Fuentes escaneadas

- `app.R`
- `R/pt_homogeneity.R`, `R/pt_robust_stats.R`, `R/pt_scores.R`, `R/utils.R`
- `ptcalc/R/pt_homogeneity.R`, `ptcalc/R/pt_robust_stats.R`, `ptcalc/R/pt_scores.R`
- `reports/report_template.Rmd`

Se excluyen scripts de preprocesamiento (`R/preprocessing/`) y casos de uso
secundarios.

## Formato de Documentacion

### CSV (`funciones_extraidas.csv`)

| Columna | Descripcion |
|---------|-------------|
| `archivo` | Archivo donde se define la funcion |
| `nombre_funcion` | Nombre de la funcion |
| `categoria` | Categoria funcional |
| `descripcion` | Descripcion breve |
| `parametros` | Lista de parametros documentados |
| `retorno` | Descripcion del valor de retorno |
| `ejemplos` | Ejemplo de uso |
| `referencia_iso` | Referencia a estandar ISO |
| `exportada` | `TRUE` si tiene `@export` |
| `lifecycle` | Estado del ciclo de vida (ej. `deprecated`) |
| `archivo_ruta` | Ruta relativa completa del archivo fuente |

### Markdown (`md/documentacion_funciones.md`)

Cada funcion incluye:

- Nombre de la funcion y badges (`[EXPORTADA]`, `[OBSOLETO]`)
- Descripcion detallada
- Firma completa
- Parametros con tipos y descripciones
- Valor de retorno
- Ejemplo ejecutable (cuando esta disponible)
- Notas de contexto (cuando aplica)
- Archivo fuente
- Referencia ISO (si aplica)

## Ejemplo de Entrada en la Documentacion

```markdown
### `calculate_z_score` `[EXPORTADA]`

Calcula el puntaje z de un participante respecto al valor asignado y sigma_pt.

**Firma:** `calculate_z_score(x, x_pt, sigma_pt)`

**Parametros**

- x Resultado del participante.
- x_pt Valor asignado.
- sigma_pt Desviacion estandar para la evaluacion de aptitud.

**Valor de retorno**

Valor numerico del puntaje z o NA si sigma_pt no es valido.

**Ejemplo**

```r
z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
```

**Archivo fuente:** `ptcalc/R/pt_scores.R`

**Referencia ISO:** ISO 13528:2022, Section 10.2
```

## Pruebas

Para ejecutar el test de firmas:

```r
source("Entregables_pt_app/02_funciones_usadas/tests/test_02_firma_funciones.R")
```

El test valida que:

1. Todas las funciones registradas en el CSV existan en los entornos cargados.
2. Los argumentos de cada funcion coincidan con la firma documentada.

## Próximos Pasos

Este entregable enriquecido alimenta:

1. **Entregable 03:** Implementacion de funciones standalone para calculos PT.
2. **Entregable 04:** Modulo de calculo de puntajes.
3. **Entregable 08:** Documentacion final para desarrolladores.

## Referencias

- **ISO 13528:2022** - Statistical methods for proficiency testing
- **ISO 17043:2023** - General requirements for proficiency testing
- **AGENTS.md** - Guia de estilo y convenciones del codigo
