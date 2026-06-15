# Plan: Workflow definitivo de preprocesamiento

**Timestamp:** 260519_1342
**Slug:** workflow-definitivo-preprocesamiento
**Estado:** En progreso

## Objetivo

Organizar el flujo definitivo de datos entre datos crudos, `pt_app` y `calaire-app`, separando claramente:

1. Preprocesamiento de datos crudos hacia formato interno de `pt_app`.
2. Exportación de referencia desde `pt_app` hacia `calaire-app`.
3. Importación de participantes desde `calaire-app` hacia `pt_app`.
4. Consolidación final en `data/processed/ronda_1_completa.csv`.

## Fases

### Fase 1: Definir contratos de archivos
| Item | Estado | Notas |
|------|--------|-------|
| Definir contrato crudos -> pt_app | Completado | Documentado en `docs/workflow-preprocesamiento.md`. |
| Definir contrato pt_app -> calaire-app | Completado | Archivo de referencia `data/to_calaire-app/<n>-ref.csv`. |
| Definir contrato calaire-app -> pt_app | Completado | Archivos de participantes tipo `data/from_calaire-app/<n>-pt.csv`. |
| Definir consolidado final | Completado | `data/processed/ronda_<n>_completa.csv`. |

### Fase 2: Nombrar scripts y archivos
| Item | Estado | Notas |
|------|--------|-------|
| Revisar scripts existentes | Completado | Revisados `preprocesar_calaire.R`, `run_preprocessor_calaire.R`, conversiones y `unir_rondas.R`. |
| Proponer nombres definitivos | Completado | Documentados directorios y nombres recomendados. |
| Crear documentación operativa | Completado | Creado `docs/workflow-preprocesamiento.md`. |

### Fase 3: Ajustar/crear orquestación
| Item | Estado | Notas |
|------|--------|-------|
| Validar si basta con scripts actuales | Completado | Conversiones cubren frontera `pt_app` <-> `calaire-app`; se agregó consolidador flexible. |
| Crear wrapper si es necesario | Completado | Creado `scripts/consolidar_ronda_pt_app.R`. |
| Probar flujo con ronda 1 | Completado | Probados modos con participantes internos y provenientes de `calaire-app`. |

## Log de Ejecución
- [260519 13:42] Creación del plan para organizar workflow definitivo de preprocesamiento.
- [260519 13:42] Creado `docs/workflow-preprocesamiento.md` con contratos, nombres y comandos.
- [260519 13:42] Ajustado `scripts/convert_pt_app_to_calaire_app.R` para soportar modos `participants`, `reference` y `all`.
- [260519 13:42] Probada exportación de `data/to_calaire-app/1-ref.csv` y `data/to_calaire-app/1-pt.csv`.
- [260519 13:42] Creado `scripts/consolidar_ronda_pt_app.R` para consolidar referencia + participantes internos o importados desde `calaire-app`.
- [260519 13:42] Probada consolidación con `ronda_1_participantes_from_calaire.csv` + `ronda_1_referencia.csv`: 20 filas.
- [260519 13:42] Probada consolidación con `ronda_1_participantes.csv` + `ronda_1_referencia.csv`: 20 filas.
