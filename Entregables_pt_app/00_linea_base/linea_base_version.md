# Línea base de versión y entorno

## Identificación

| Campo | Valor al corte |
|---|---|
| Fecha y hora | 2026-07-14 10:22 COT (UTC-05:00) |
| Repositorio | `willl182/pt_app` |
| Rama | `main` |
| Commit | `6e7dbcb769c1a8e40d65c749ce8f99eadfca8a02` |
| Asunto del commit | `docs(plan): planificar actualización entregables` |
| Paquete `ptcalc` | 0.1.1 |
| R | 4.6.0 (2026-04-24) |

## Paquetes relevantes instalados

| Paquete | Versión |
|---|---|
| shiny | 1.13.0 |
| bslib | 0.10.0 |
| DT | 0.34.0 |
| dplyr | 1.2.1 |
| plotly | 4.12.0 |
| readr | 2.2.0 |
| vroom | 1.7.1 |
| testthat | 3.3.2 |
| devtools | 2.5.2 |

## Estado del árbol antes de la fase

El árbol ya estaba sucio. Estos cambios se consideran preexistentes y no son
evidencia producida por esta fase:

- modificación de `logs/CURRENT_SESSION.md`;
- modificación del plan activo para registrar el guardado del 14 de julio;
- eliminación en la raíz de `plan_documentos_formales_entregables_pt.html`;
- copia no rastreada del mismo HTML dentro de `Entregables_pt_app/`;
- archivos de memoria no rastreados creados por `saver`.

La aparente reubicación del HTML se preservó sin alterarla. El commit de cierre
de la fase debe excluir esos dos cambios HTML hasta confirmar su autoría y
alcance.

## Fuente funcional congelada

La documentación se contrastará contra:

1. `app.R`, como interfaz y orquestación reactiva vigentes;
2. `R/export_final_scores.R`, único helper de `R/` cargado explícitamente por
   `app.R` al corte;
3. `ptcalc/R/`, cargado mediante `devtools::load_all("ptcalc")` y, como ruta de
   contingencia, los tres módulos matemáticos indicados en `app.R`;
4. `R/preprocessing/` y `scripts/aplicativo/`, invocados por el flujo de
   preprocesamiento;
5. `data/`, `data_use_cases/`, `reports/` y las pruebas, solo como datos,
   plantillas o evidencia verificable.

`app_v06.R`, `app_v07.R`, `app_final.R` y `app_original.R` son instantáneas
históricas de entregables. No son autoridad para describir la versión actual.
