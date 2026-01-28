# 14. Plantilla de Informe: report_template.Rmd

| Propiedad | Valor |
|----------|-------|
| **Tipo de Documento** | Referencia de la Plantilla de Informe RMarkdown |
| **Archivo** | `reports/report_template.Rmd` |
| **Líneas** | 552 |
| **Formato** | YAML + bloques R + Markdown |
| **Documentos Relacionados** | `12_generacion_informes.md`, `05_puntajes_pt.md`, `04_homogeneidad_pt.md` |

---

## 1. Descripción General

El archivo `report_template.Rmd` es una plantilla de RMarkdown para la generación automática de informes de ensayos de aptitud (PT). Implementa la estructura de informes de la norma ISO/IEC 17043:2023 con los métodos estadísticos de la norma ISO 13528:2022.

### Características Clave
- **Salida Multiformato**: Soporte para Word, HTML y PDF.
- **Contenido Dinámico**: Secciones y tablas impulsadas por parámetros.
- **Estilo de Tema PT**: CSS personalizado que coincide con el diseño de la aplicación.
- **Análisis Integral**: Homogeneidad, estabilidad, puntuación y compatibilidad metrológica.
- **Resultados por Participante**: Matrices de desempeño individual y resúmenes.

> **Nota:** Las capturas de pantalla y figuras en esta documentación deben actualizarse para reflejar el diseño actual del informe con la sección de compatibilidad metrológica y el manejo mejorado de los datos de los participantes.

---

## 2. Ubicación del Archivo

```
pt_app/
└── reports/
    └── report_template.Rmd    # Plantilla de informe principal (552 líneas)
```

---

## 3. Parámetros (Encabezado YAML)

La plantilla acepta numerosos parámetros para su personalización:

### 3.1 Parámetros de Datos Principales

```yaml
params:
  # Entradas de datos brutos
  hom_data: NA                    # Datos brutos de homogeneidad
  stab_data: NA                   # Datos brutos de estabilidad
  summary_data: NA                # Datos resumen de participantes
  
  # Configuración del análisis
  metric: "z"                     # Tipo de puntaje: z, z', zeta, En
  method: "3"                     # Método de asignación: 1, 2a, 2b, 3
  pollutant: NULL                 # Contaminante(s) seleccionado(s)
  level: "level_1"                # Nivel(es) seleccionado(s)
  n_lab: 7                        # Número de laboratorios
  k_factor: 2                     # Factor de cobertura para incertidumbres
```

### 3.2 Parámetros de Identificación

```yaml
params:
  scheme_id: "EA-202X-XX"         # Identificador del esquema PT
  report_id: "INF-202X-XX"        # Identificador del informe
  issue_date: NA                  # Fecha de emisión del informe
  period: "Mes - Mes Año"         # Periodo del esquema PT
  coordinator: "Nombre"           # Nombre del coordinador de EA
  quality_pro: "Nombre"           # Nombre del profesional de calidad
  ops_eng: "Nombre"               # Nombre del ingeniero operativo
  quality_manager: "Nombre"       # Nombre del gestor de calidad
```

### 3.3 Parámetros de Resumen de Datos

```yaml
params:
  participants_data: NA           # Datos de instrumentación cargados
  grubbs_summary: NA              # Resumen de resultados de la prueba de Grubbs
  xpt_summary: NA                 # Tabla resumen del valor asignado
  homogeneity_summary: NA         # Resumen de resultados de homogeneidad
  stability_summary: NA           # Resumen de resultados de estabilidad
  score_summary: NA               # Resumen de puntajes generales
  heatmaps: NA                    # Mapas de calor pre-generados
  participant_data: NA            # Datos detallados por participante
```

### 3.4 Parámetros de Compatibilidad Metrológica

```yaml
params:
  metrological_compatibility: NA           # Tabla de datos de compatibilidad
  metrological_compatibility_method: "2a"  # Método para comparación: 2a, 2b, 3
```

---

## 4. Estructura de las Secciones del Informe

### 4.1 Sección 1: Introducción

| Subsección | Contenido |
|------------|---------|
| 1.1 Proveedor e Información del Esquema | Alcance, objetivos, ID del esquema |
| 1.2 Confidencialidad | Política de protección de datos |
| 1.3 Personal Clave | Coordinador, ingenieros, gestores |
| 1.4 Participantes | Códigos de laboratorios y tabla de instrumentación |

### 4.2 Sección 2: Metodología

| Subsección | Contenido |
|------------|---------|
| 2.1 Ítems de Ensayo | Métodos de generación de gas, niveles de concentración |
| 2.2 Homogeneidad y Estabilidad | Métodos de verificación según ISO 13528 Anexo B |
| 2.3 Valor Asignado ($x_{pt}$) | Determinación específica del método (Referencia/Consenso/Algoritmo A) |
| 2.4 Compatibilidad Metrológica | **NUEVO** Comparación entre los valores de referencia y consenso |

### 4.3 Sección 3: Criterios de Evaluación

| Subsección | Contenido |
|------------|---------|
| 3.1 Indicadores de Desempeño | Fórmulas y umbrales de z, z', zeta, En |
| 3.2 Tratamiento Estadístico | Validación, identificación de atípicos (prueba de Grubbs) |

### 4.4 Sección 4: Resultados y Discusión

| Subsección | Contenido |
|------------|---------|
| 4.1 Resumen General | Estadísticas de desempeño global |
| 4.2 Resultados por Contaminante | Mapas de calor y tablas detalladas |

### 4.6 Anexos

| Anexo | Contenido |
|-------|---------|
| Anexo A | Valores asignados y desviaciones estándar |
| Anexo B | Resúmenes de homogeneidad y estabilidad |
| Anexo C | Resultados detallados por participante con gráficos de matriz |

### 4.7 Sección 2.4: Compatibilidad Metrológica

**Líneas**: 312-352
**Propósito**: Evalúa la concordancia entre los valores de referencia y de consenso.

**Contenido Dinámico**:
- Muestra la tabla de compatibilidad filtrada por el método seleccionado.
- Muestra las diferencias (D_2a, D_2b, D_3) entre x_pt(ref) y los valores de consenso.
- Adapta la visualización de las columnas basándose en el parámetro `metrological_compatibility_method`.

**Columnas de la Tabla**:
- Método 2a: Muestra x_pt_ref, x_pt_2a, Diff_Ref_2a.
- Método 2b: Muestra x_pt_ref, x_pt_2b, Diff_Ref_2b.
- Método 3: Muestra x_pt_ref, x_pt_3 (Alg A), Diff_Ref_3.

### 4.8 Sección 5: Conclusiones

Evaluación general de la conformidad, áreas de preocupación y acciones recomendadas.

---

## 5. Funciones Auxiliares

La plantilla incluye funciones auxiliares independientes que replican la lógica de `ptcalc` para la independencia del informe. Tenga en cuenta que la plantilla utiliza funciones wrapper (líneas 132-139, 142-173) para interactuar con las funciones del paquete `ptcalc`:

### 5.1 Integración con el Paquete ptcalc

La plantilla se integra con el paquete de cálculo `ptcalc` a través de funciones wrapper:

```r
# Wrapper para el cálculo de MADe
calculate_mad_e <- function(x) {
  ptcalc::calculate_mad_e(x)
}

# Wrapper para las estadísticas de homogeneidad
calculate_homogeneity_stats <- function(data) {
  ptcalc::calculate_homogeneity_stats(data)
}
```

Estos wrappers aseguran un manejo adecuado de los errores y tipos de retorno consistentes.

### 5.2 calculate_niqr()

```r
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA_real_)
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}
```

**Propósito**: Calcular el IQR normalizado para la estimación robusta de la dispersión.

### 5.2 get_wide_data()

```r
get_wide_data <- function(df, target_pollutant) {
  filtered <- df %>% filter(pollutant == target_pollutant)
  if (nrow(filtered) == 0) return(NULL)
  filtered %>%
    select(-pollutant) %>%
    pivot_wider(names_from = replicate, values_from = value, names_prefix = "sample_")
}
```

**Propósito**: Transformar los datos de formato largo a formato ancho para el análisis.

### 5.3 run_algorithm_a()

```r
run_algorithm_a <- function(values, max_iter = 50) {
  # Implementación del Algoritmo A de la ISO 13528
  # Retorna: list(mean = x_star, sd = s_star, error = NULL/mensaje)
}
```

**Propósito**: Calcular la media y la desviación estándar robustas utilizando el Algoritmo A de la ISO 13528.

### 5.4 compute_homogeneity()

```r
compute_homogeneity <- function(data_full, pol, lev) {
  # Cálculo de homogeneidad basado en ANOVA
  # Retorna: list(ss, sw, sigma_pt, c_crit, mean, passed)
}
```

**Propósito**: Calcular las desviaciones estándar entre muestras ($s_s$) y dentro de las muestras ($s_w$).

---

## 6. Formatos de Salida

### 6.1 Documento Word

```yaml
output:
  word_document:
    toc: true
    toc_depth: 3
    reference_docx: null   # Opcional: plantilla personalizada
```

### 6.2 Documento HTML

```yaml
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true        # Navegación lateral flotante
```

Incluye CSS personalizado para el estilo del tema PT (acentos amarillos, enlaces de marca).

### 6.3 Documento PDF

```yaml
output:
  pdf_document:
    toc: true
    toc_depth: 3
    latex_engine: pdflatex
```

---

## 7. Estilo Personalizado

La plantilla incluye CSS embebido para la salida HTML:

```css
/* Elementos de la TOC activos - Amarillo PT */
.list-group-item.active {
  background-color: #FDB913 !important;
  border-color: #FDB913 !important;
  color: #111827 !important;
}

/* Estilo de los títulos */
h1.title {
  border-bottom: 3px solid #FDB913;
  padding-bottom: 10px;
}

/* Colores de los enlaces */
a { color: #E5A610; }
a:hover { color: #FDB913; }

/* Resaltado de selección */
::selection {
  background: #FDB913;
  color: #111827;
}
```

---

## 8. Características Dinámicas Clave

### 8.1 Selección del Método de Valor Asignado

La plantilla ajusta automáticamente el texto basándose en `params$method`:

| Método | Descripción |
|--------|-------------|
| `"1"` | Valor del laboratorio de referencia |
| `"2a"` | Consenso (Mediana + MADe) |
| `"2b"` | Consenso (Mediana + nIQR) |
| `"3"` | Consenso (Algoritmo A) |

### 8.2 Compatibilidad Metrológica

**Nueva característica**: La Sección 2.4 muestra la comparación entre los valores de referencia y los valores de consenso:

> **Actualización de Captura de Pantalla Requerida**: La sección de compatibilidad metrológica debe mostrar:
> - Tabla de comparación que muestra x_pt_ref y el método de consenso seleccionado.
> - Columnas de diferencia (D_2a, D_2b o D_3 dependiendo del método seleccionado).
> - Indicadores de estado codificados por colores si se define el umbral de compatibilidad.

```r
# Texto dinámico basado en el método
if (method == "2a") {
  cat("Diferencias entre x_pt,ref y x_pt,2a...")
} else if (method == "2b") {
  cat("Diferencias entre x_pt,ref y x_pt,2b...")
} else if (method == "3") {
  cat("Diferencias entre x_pt,ref y x_pt,3...")
}
```

La tabla de compatibilidad muestra:
- Contaminante y nivel
- Valor de referencia
- Valor de consenso (basado en el método seleccionado)
- Diferencia (Ref - Consenso)

### 8.3 Selección de la Métrica de Desempeño

La plantilla ajusta las fórmulas y los umbrales basándose en `params$metric`:

| Métrica | Fórmula | Umbrales |
|--------|---------|------------|
| `z` | $z = \frac{x_i - x_{pt}}{\sigma_{pt}}$ | ≤2.0 Satisfactorio, 2-3 Cuestionable, ≥3 No satisfactorio |
| `z'` | $z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}}$ | Igual que z |
| `zeta` | $\zeta = \frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}}$ | Igual que z |
| `En` | $E_n = \frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}}$ | ≤1.0 Satisfactorio, >1.0 No satisfactorio |

### 8.4 Integración de Mapas de Calor

Los mapas de calor pre-generados se incrustan por contaminante:

```r
if (!is.null(params$heatmaps) && length(params$heatmaps) > 0) {
  for (pol in names(params$heatmaps)) {
    cat("\n\n### Resultados para", toupper(pol), "\n\n")
    print(params$heatmaps[[pol]])
  }
}
```

### 8.5 Resultados por Participante

El Anexo C itera a través de los datos de los participantes:

```r
for (pid in names(params$participant_data)) {
  p_info <- params$participant_data[[pid]]
  
  # Gráfico de matriz
  print(p_info$matrix_plot)
  
  # Tabla resumen
  print(kable(p_info$summary_table, ...))
  
  cat("\\newpage")  # Salto de página entre participantes
}
```

---

## 9. Requisitos de Datos

### 9.1 Parámetros Requeridos

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `summary_data` | data.frame | Resultados de los participantes con las columnas: participant_id, pollutant, level, run, mean_value, n_lab |
| `metric` | carácter | Selección del tipo de puntaje |
| `method` | carácter | Método de asignación |
| `n_lab` | entero | Número de laboratorios |

### 9.2 Parámetros de Mejora Opcionales

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `participants_data` | data.frame | Información del instrumento por laboratorio |
| `heatmaps` | lista nombrada | Mapas de calor ggplot pre-renderizados |
| `participant_data` | lista nombrada | Resultados por participante (matrix_plot, summary_table) |
| `metrological_compatibility` | data.frame | Comparación referencia vs consenso |

---

## 10. Guía de Personalización

### 10.1 Añadir una Nueva Sección

1. Añada el contenido después del número de sección apropiado.
2. Utilice niveles de encabezado consistentes (# para secciones principales, ## para subsecciones).
3. Envuelva el contenido dinámico en bloques R con las opciones apropiadas.

### 10.2 Modificar Tablas

Las tablas utilizan `kable()` con `kableExtra` para el estilo:

```r
kable(data, 
      digits = 4, 
      caption = "Tabla X. Descripción",
      escape = FALSE)  # Permitir HTML en las celdas
```

### 10.3 Añadir Nuevos Parámetros

1. Añada al encabezado YAML bajo `params:`
2. Referencie con `params$nombre_parametro`
3. Añada el manejo condicional para los valores NA.

---

## 11. Solución de Problemas

| Problema | Causa | Solución |
|-------|-------|----------|
| Las tablas no se renderizan | Datos NA | Añada verificaciones de nulo: `if (!is.null(params$data))` |
| Errores de LaTeX en PDF | Caracteres especiales | Escape los guiones bajos, use `$...$` para las matemáticas |
| Faltan mapas de calor | No se pasan desde la aplicación | Verifique que `params$heatmaps` esté poblado |
| Recuento de columnas incorrecto | Discrepancia en el formato de datos | Verifique los nombres de columna esperados frente a los reales |

---

## 12. Ver También

- [12_generacion_informes.md](12_generacion_informes.md) - Documentación del módulo de generación de informes
- [05_puntajes_pt.md](05_puntajes_pt.md) - Fórmulas de cálculo de puntajes
- [04_homogeneidad_pt.md](04_homogeneidad_pt.md) - Criterios de homogeneidad/estabilidad
- [ISO 13528:2022](https://www.iso.org/standard/78879.html) - Métodos estadísticos para los ensayos de aptitud
- [ISO 17043:2023](https://www.iso.org/standard/79919.html) - Requisitos generales para los ensayos de aptitud
