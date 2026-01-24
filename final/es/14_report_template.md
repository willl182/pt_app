# 14. Plantilla de Reportes: report_template.Rmd

| Propiedad | Valor |
|-----------|-------|
| **Tipo de Documento** | Referencia de Plantilla de Reportes RMarkdown |
| **Archivo** | `reports/report_template.Rmd` |
| **Líneas** | 558 |
| **Formato** | YAML + R chunks + Markdown |
| **Documentos Relacionados** | `12_generacion_informes.md`, `05_pt_scores.md`, `04_pt_homogeneity.md` |

---

## 1. Descripción General

El archivo `report_template.Rmd` es una plantilla RMarkdown para la generación automática de informes de ensayos de aptitud (EA). Implementa la estructura de informe ISO/IEC 17043:2023 con los métodos estadísticos de ISO 13528:2022.

### Características Principales
- **Salida Multi-formato**: Soporte para Word, HTML y PDF
- **Contenido Dinámico**: Secciones y tablas controladas por parámetros
- **Estilos del Tema PT**: CSS personalizado que coincide con el diseño de la aplicación
- **Análisis Integral**: Homogeneidad, estabilidad, puntuación y compatibilidad metrológica
- **Resultados por Participante**: Matrices de desempeño individual y resúmenes

> **Nota:** Las capturas de pantalla y figuras en esta documentación deben actualizarse para reflejar el diseño actual del informe con la sección de compatibilidad metrológica y el manejo mejorado de datos de participantes.

---

## 2. Ubicación del Archivo

```
pt_app/
└── reports/
    └── report_template.Rmd    # Plantilla principal de informes (558 líneas)
```

---

## 3. Parámetros (Encabezado YAML)

La plantilla acepta numerosos parámetros para personalización:

### 3.1 Parámetros de Datos Principales

```yaml
params:
  # Entradas de datos crudos
  hom_data: NA                    # Datos crudos de homogeneidad
  stab_data: NA                   # Datos crudos de estabilidad
  summary_data: NA                # Datos de resumen de participantes
  
  # Configuración de análisis
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
  scheme_id: "EA-202X-XX"         # Identificador del esquema de EA
  report_id: "INF-202X-XX"        # Identificador del informe
  issue_date: NA                  # Fecha de emisión del informe
  period: "Mes - Mes Año"         # Período del esquema de EA
  coordinator: "Nombre"           # Nombre del coordinador de EA
  quality_pro: "Nombre"           # Nombre del profesional de calidad
  ops_eng: "Nombre"               # Nombre del ingeniero de operaciones
  quality_manager: "Nombre"       # Nombre del gestor de calidad
```

### 3.3 Parámetros de Resumen de Datos

```yaml
params:
  participants_data: NA           # Datos de instrumentos de participantes cargados
  grubbs_summary: NA              # Resumen de resultados de prueba de Grubbs
  xpt_summary: NA                 # Tabla de resumen de valor asignado
  homogeneity_summary: NA         # Resumen de resultados de homogeneidad
  stability_summary: NA           # Resumen de resultados de estabilidad
  score_summary: NA               # Resumen general de puntajes
  heatmaps: NA                    # Gráficos de mapa de calor pre-generados
  participant_data: NA            # Datos detallados por participante
```

### 3.4 Parámetros de Compatibilidad Metrológica

```yaml
params:
  metrological_compatibility: NA           # Tabla de datos de compatibilidad
  metrological_compatibility_method: "2a"  # Método para comparación: 2a, 2b, 3
```

---

## 4. Estructura de Secciones del Informe

### 4.1 Sección 1: Introducción

| Subsección | Contenido |
|------------|-----------|
| 1.1 Información del Proveedor y Esquema | Alcance, objetivos, ID del esquema |
| 1.2 Confidencialidad | Política de protección de datos |
| 1.3 Personal Clave | Coordinador, ingenieros, gestores |
| 1.4 Participantes | Códigos de laboratorio y tabla de instrumentación |

### 4.2 Sección 2: Metodología

| Subsección | Contenido |
|------------|-----------|
| 2.1 Ítems de Ensayo | Métodos de generación de gas, niveles de concentración |
| 2.2 Homogeneidad y Estabilidad | Métodos de verificación según ISO 13528 Anexo B |
| 2.3 Valor Asignado ($x_{pt}$) | Determinación específica del método (Referencia/Consenso/Algoritmo A) |
| 2.4 Compatibilidad Metrológica | **NUEVO** Comparación entre valores de referencia y consenso |

### 4.3 Sección 3: Criterios de Evaluación

| Subsección | Contenido |
|------------|-----------|
| 3.1 Indicadores de Desempeño | Fórmulas z, z', zeta, En y umbrales |
| 3.2 Tratamiento Estadístico | Validación, identificación de atípicos (prueba de Grubbs) |

### 4.4 Sección 4: Resultados y Discusión

| Subsección | Contenido |
|------------|-----------|
| 4.1 Resumen General | Estadísticas generales de desempeño |
| 4.2 Resultados por Contaminante | Mapas de calor y tablas detalladas |

### 4.5 Sección 5: Conclusiones

Evaluación general de conformidad, áreas de preocupación y acciones recomendadas.

### 4.6 Anexos

| Anexo | Contenido |
|-------|-----------|
| Anexo A | Valores asignados y desviaciones estándar |
| Anexo B | Resúmenes de homogeneidad y estabilidad |
| Anexo C | Resultados detallados por participante con gráficos de matriz |

---

## 5. Funciones Helper

La plantilla incluye funciones helper independientes que replican la lógica de `ptcalc` para independencia del informe:

### 5.1 calculate_niqr()

```r
calculate_niqr <- function(x) {
  x_clean <- x[is.finite(x)]
  if (length(x_clean) < 2) return(NA_real_)
  quartiles <- stats::quantile(x_clean, probs = c(0.25, 0.75), na.rm = TRUE, type = 7)
  0.7413 * (quartiles[2] - quartiles[1])
}
```

**Propósito**: Calcular IQR normalizado para estimación robusta de dispersión.

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

**Propósito**: Transformar datos de formato largo a formato ancho para análisis.

### 5.3 run_algorithm_a()

```r
run_algorithm_a <- function(values, max_iter = 50) {
  # Implementación del Algoritmo A de ISO 13528
  # Retorna: list(mean = x_star, sd = s_star, error = NULL/mensaje)
}
```

**Propósito**: Calcular media y desviación estándar robustas usando el Algoritmo A de ISO 13528.

### 5.4 compute_homogeneity()

```r
compute_homogeneity <- function(data_full, pol, lev) {
  # Cálculo de homogeneidad basado en ANOVA
  # Retorna: list(ss, sw, sigma_pt, c_crit, mean, passed)
}
```

**Propósito**: Calcular desviaciones estándar entre muestras ($s_s$) y dentro de muestras ($s_w$).

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
    toc_float: true        # Navegación de barra lateral flotante
```

Incluye CSS personalizado para estilos del tema PT (acentos amarillos, enlaces de marca).

### 6.3 Documento PDF

```yaml
output:
  pdf_document:
    toc: true
    toc_depth: 3
    latex_engine: pdflatex
```

---

## 7. Estilos Personalizados

La plantilla incluye CSS embebido para salida HTML:

```css
/* Elementos activos del TOC - Amarillo PT */
.list-group-item.active {
  background-color: #FDB913 !important;
  border-color: #FDB913 !important;
  color: #111827 !important;
}

/* Estilos del título */
h1.title {
  border-bottom: 3px solid #FDB913;
  padding-bottom: 10px;
}

/* Colores de enlaces */
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

**Nueva Característica**: La Sección 2.4 muestra la comparación entre valores de referencia y valores de consenso:

```r
# Texto dinámico basado en método
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

### 8.3 Selección de Métrica de Desempeño

La plantilla ajusta fórmulas y umbrales basándose en `params$metric`:

| Métrica | Fórmula | Umbrales |
|---------|---------|----------|
| `z` | $z = \frac{x_i - x_{pt}}{\sigma_{pt}}$ | ≤2.0 Satisfactorio, 2-3 Cuestionable, ≥3 Insatisfactorio |
| `z'` | $z' = \frac{x_i - x_{pt}}{\sqrt{\sigma_{pt}^2 + u(x_{pt})^2}}$ | Igual que z |
| `zeta` | $\zeta = \frac{x_i - x_{pt}}{\sqrt{u(x_i)^2 + u(x_{pt})^2}}$ | Igual que z |
| `En` | $E_n = \frac{x_i - x_{pt}}{\sqrt{U(x_i)^2 + U(x_{pt})^2}}$ | ≤1.0 Satisfactorio, >1.0 Insatisfactorio |

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

El Anexo C itera a través de los datos de participantes:

```r
for (pid in names(params$participant_data)) {
  p_info <- params$participant_data[[pid]]
  
  # Gráfico de matriz
  print(p_info$matrix_plot)
  
  # Tabla de resumen
  print(kable(p_info$summary_table, ...))
  
  cat("\\newpage")  # Salto de página entre participantes
}
```

---

## 9. Requisitos de Datos

### 9.1 Parámetros Requeridos

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `summary_data` | data.frame | Resultados de participantes con columnas: participant_id, pollutant, level, run, mean_value, n_lab |
| `metric` | character | Selección del tipo de puntaje |
| `method` | character | Método de asignación |
| `n_lab` | integer | Número de laboratorios |

### 9.2 Parámetros de Mejora Opcionales

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `participants_data` | data.frame | Información de instrumentos por laboratorio |
| `heatmaps` | lista nombrada | Mapas de calor ggplot pre-renderizados |
| `participant_data` | lista nombrada | Resultados por participante (matrix_plot, summary_table) |
| `metrological_compatibility` | data.frame | Comparación referencia vs consenso |

---

## 10. Guía de Personalización

### 10.1 Agregar una Nueva Sección

1. Agregar contenido después del número de sección apropiado
2. Usar niveles de encabezado consistentes (# para secciones principales, ## para subsecciones)
3. Envolver contenido dinámico en chunks de R con opciones apropiadas

### 10.2 Modificar Tablas

Las tablas usan `kable()` con `kableExtra` para estilos:

```r
kable(data, 
      digits = 4, 
      caption = "Tabla X. Descripción",
      escape = FALSE)  # Permitir HTML en celdas
```

### 10.3 Agregar Nuevos Parámetros

1. Agregar al encabezado YAML bajo `params:`
2. Referenciar con `params$nombre_param`
3. Agregar manejo condicional para valores NA

---

## 11. Solución de Problemas

| Problema | Causa | Solución |
|----------|-------|----------|
| Tablas no se renderizan | Datos NA | Agregar verificaciones null: `if (!is.null(params$data))` |
| Errores de LaTeX en PDF | Caracteres especiales | Escapar guiones bajos, usar `$...$` para matemáticas |
| Mapas de calor faltantes | No pasados desde la app | Verificar que `params$heatmaps` esté poblado |
| Conteo de columnas incorrecto | Desajuste de formato de datos | Verificar nombres de columnas esperados vs reales |

---

## 12. Ver También

- [12_generacion_informes.md](12_generacion_informes.md) - Documentación del módulo de generación de informes
- [05_pt_scores.md](05_pt_scores.md) - Fórmulas de cálculo de puntajes
- [04_pt_homogeneity.md](04_pt_homogeneity.md) - Criterios de homogeneidad/estabilidad
- [ISO 13528:2022](https://www.iso.org/standard/78879.html) - Métodos estadísticos para ensayos de aptitud
- [ISO 17043:2023](https://www.iso.org/standard/79919.html) - Requisitos generales para ensayos de aptitud
