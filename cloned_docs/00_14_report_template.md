# Template de Reportes: report_template.Rmd

## Descripción
Plantilla RMarkdown para la generación automática de informes de ensayos de aptitud.

## Ubicación
| Elemento | Valor |
|----------|-------|
| Archivo | `reports/report_template.Rmd` |
| Líneas | 507 |
| Formato | YAML + R chunks + Markdown |

## Parámetros (YAML Header)
```yaml
params:
  scheme_id: ""
  summary_data: NULL
  hom_data: NULL
  stab_data: NULL
  method: "1"
  metric: "z"
  k: 2
  metrological_compatibility: NULL
  participants_data: NULL
```

## Secciones del Informe
1. **Introducción**: Alcance, definiciones
2. **Participantes**: Tabla de instrumentación
3. **Metodología**: Descripción del ensayo
4. **Valor Asignado**: Según método seleccionado
5. **Criterios de Evaluación**: Fórmulas y umbrales
6. **Resultados**: Heatmaps y tablas por participante
7. **Anexos**: Homogeneidad, estabilidad, atípicos

## Helpers Internos
El template incluye funciones helper que replican lógica de ptcalc para independencia:
- `calculate_niqr()` (local)
- `get_wide_data()` (local)
- `run_algorithm_a_simple()` (local)
- `compute_homogeneity()` (local)
