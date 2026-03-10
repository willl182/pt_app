# Plan: Comparar implementaciones opus codex ajustes app

**Timestamp:** 260310_0219
**Slug:** comparar-implementaciones-opus-codex-ajustes-app
**Estado:** En progreso

## Objetivo
Definir y ejecutar un plan maestro para implementar de forma paralela los ajustes requeridos del aplicativo a partir de `mods/`, cubriendo tanto la parte tecnica (`*_p1`) como la documental (`*_p2`) en dos ramas separadas y comparables: una rama `opus` y una rama `codex`. El plan debe partir de una revision real de la codebase (`app.R`, `ptcalc_repo/`) y de la documentacion del aplicativo (`es/`), para que la posterior implementacion quede alineada con el estado actual del proyecto y con el repositorio real externo de `ptcalc`.

## Contexto aterrizado del repositorio

- La rama base confirmada para abrir ambos tracks es `main` en el commit `bc3f3ae`.
- El arbol de trabajo esta sucio; por tanto, las ramas deben crearse desde el mismo commit base sin revertir cambios existentes no relacionados.
- La aplicacion visible usa referencias a `ptcalc/` en [app.R](/home/w182/w421/pt_app/app.R), pero la implementacion disponible en este workspace esta en `ptcalc_repo/`.
- Los documentos de `mods/` definen dos enfoques completos:
  - `final_opus_p1.md` + `final_opus_p2.md`
  - `final_gpt54_p1.md` + `final_gpt54_p2.md`
- La documentacion actual en `es/` ya contiene reglas y descripciones que deben entrar al alcance del ajuste, no solo el codigo.

## Hallazgos base para planificacion

- **Codigo:** [pt_homogeneity.R](/home/w182/w421/pt_app/ptcalc_repo/R/pt_homogeneity.R) usa `abs()` para `ss_sq`, lo que coincide con el hallazgo H1 y obliga a una correccion normativa en el track tecnico.
- **Codigo:** [app.R](/home/w182/w421/pt_app/app.R#L2444) calcula consensos de participantes y ejecuta Algoritmo A con umbral operativo `n >= 3`, mientras `mods/` exige formalizar la regla de seleccion metodologica `n < 12` / `n >= 12`.
- **Codigo/arquitectura:** `app.R` mezcla responsabilidades de carga, preparacion, calculo y visualizacion; la trazabilidad por `dataset_fuente`, `serie_usada` y `metodo` no esta formalizada de extremo a extremo.
- **Documentacion:** [es/README.md](/home/w182/w421/pt_app/es/README.md) y [es/MANUAL_COMPLETO_PT_APP.md](/home/w182/w421/pt_app/es/MANUAL_COMPLETO_PT_APP.md) describen metodos y flujos que deben alinearse con el comportamiento final de cada rama.
- **Dependencia externa:** la implementacion definitiva del paquete matematico se llevara luego al repo real externo `ptcalc`; por tanto, este plan debe distinguir entre cambios locales de referencia en `ptcalc_repo/` y cambios transferibles al repo real.

## Ramas objetivo

### Fase 0: Preparacion y ramas base
| Item | Estado | Notas |
|------|--------|-------|
| Confirmar base comun de ambas implementaciones | Completado | Base confirmada: `main` @ `bc3f3ae` |
| Crear rama `opus/ajustes-app-260310` | Completado | Rama creada desde `bc3f3ae` |
| Crear rama `codex/ajustes-app-260310` | Completado | Rama creada desde `bc3f3ae` |
| Registrar alcance y restricciones de coexistencia | Completado | No revertir cambios ajenos; no asumir que `ptcalc_repo/` es el repo final de despliegue |

## Fases

### Fase 1: Revision de codebase y documentacion para aterrizar implementacion
| Item | Estado | Notas |
|------|--------|-------|
| Mapear hallazgos de `mods/` contra `app.R` | En progreso | Ya se ubicaron puntos criticos en homogeneidad, consensos, Algoritmo A y exportacion |
| Mapear hallazgos contra `ptcalc_repo/R/` | En progreso | Ya se detecto desviacion normativa en B.10 y dependencias entre sigma_pt, MADe y nIQR |
| Mapear hallazgos contra documentacion `es/` | En progreso | README y manual completo requieren ajuste explicito |
| Identificar decisiones compartidas vs divergentes entre track `opus` y track `codex` | Pendiente | Necesario para evitar que ambas ramas terminen siendo equivalentes |
| Delimitar que cambios van al repo real externo `ptcalc` | Pendiente | Debe quedar como item de transferencia tecnica, no como supuesto local |

### Fase 2: Diseno maestro de implementacion dual
| Item | Estado | Notas |
|------|--------|-------|
| Definir backlog comun minimo para ambos tracks | Pendiente | Correcciones H1-H4, trazabilidad, carga separada, tablas intermedias, exportacion, documentacion |
| Definir diferencias de enfoque `opus` vs `codex` | Pendiente | `opus`: orientacion mas ejecutiva y de cierre; `codex`: orientacion mas estructural y de implementacion aterrizada |
| Establecer secuencia tecnica comun | Pendiente | Primero reglas estadisticas, luego datos/t trazabilidad, luego UI/exportacion, luego documentacion y validacion |
| Establecer criterios de aceptacion por fase | Pendiente | Deben servir para ambas ramas aunque cambie el enfoque de implementacion |
| Definir evidencia minima de validacion | Pendiente | Casos para B.10, MADe, serie usada, umbral `n >= 12`, tablas y CSV |

### Fase 3: Implementacion track `opus`
| Item | Estado | Notas |
|------|--------|-------|
| Ajustar logica tecnica de `app.R` y `ptcalc_repo/` segun `final_opus_p1.md` | En progreso | En `/tmp/pt_app_opus` ya se implemento selector de serie por `run`, metadatos `dataset_fuente` y gate `n >= 12` en `app.R`; falta transferir ajuste de B.10 al repo real `ptcalc` |
| Ajustar documentacion segun `final_opus_p2.md` | En progreso | Actualizados `es/README.md`, `es/01a_formatos_datos.md`, `es/07_valor_asignado.md`, `es/09_puntajes_pt.md` y `es/MANUAL_COMPLETO_PT_APP.md` en el track `opus` |
| Preparar notas de transferencia al repo real `ptcalc` | Pendiente | Debe explicitar funciones y archivos que salen del workspace local |
| Verificar coherencia codigo-documentacion | Pendiente | El comportamiento implementado debe coincidir con la narrativa documental |

### Fase 4: Implementacion track `codex`
| Item | Estado | Notas |
|------|--------|-------|
| Ajustar logica tecnica de `app.R` y `ptcalc_repo/` segun `final_gpt54_p1.md` | Pendiente | Incluye reglas, arquitectura de datos, validacion y cobertura de implementacion |
| Ajustar documentacion segun `final_gpt54_p2.md` | Pendiente | Incluye especificacion funcional y documentacion de usuario/desarrollador |
| Preparar notas de transferencia al repo real `ptcalc` | Pendiente | Mismo criterio de separacion aplicado al track `opus` |
| Verificar coherencia codigo-documentacion | Pendiente | La rama debe quedar ejecutable y auditabile de forma independiente |

### Fase 5: Validacion de cada rama
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar pruebas puntuales del flujo de homogeneidad | Pendiente | Validar B.10 y criterios asociados |
| Ejecutar pruebas puntuales del flujo de participantes | Pendiente | Validar MADe, nIQR, Algoritmo A y seleccion metodologica |
| Verificar trazabilidad y exportacion | Pendiente | Confirmar dataset, serie, n y metodo visibles |
| Verificar alineacion de documentacion | Pendiente | Revisar docs de usuario y docs tecnicas afectadas |
| Registrar diferencias relevantes entre ramas | Pendiente | Sin producir entregable comparativo formal, pero dejando notas de revision |

### Fase 6: Cierre operativo por rama
| Item | Estado | Notas |
|------|--------|-------|
| Ejecutar revision de fase y riesgos pendientes | Pendiente | Segun instruccion de AGENTS para cierre de fases |
| Actualizar plan con hallazgos y decisiones finales | Pendiente | Debe quedar trazabilidad de lo implementado |
| Guardar estado de sesion con `saver` | Pendiente | Requerido al completar hitos relevantes |
| Commit por rama | Pendiente | Commit no interactivo por cada track |
| Push por rama | Pendiente | Solo despues de validar que cada rama refleja su enfoque completo |

## Secuencia recomendada de implementacion

1. Crear las dos ramas desde `main` @ `bc3f3ae`.
2. Congelar un mapa comun de cambios requeridos en codigo y documentacion.
3. Implementar primero el nucleo estadistico y de trazabilidad.
4. Implementar luego UI, tablas y exportacion.
5. Cerrar cada track con actualizacion documental y validacion puntual.
6. Transferir despues los cambios matematicos pertinentes al repo real externo `ptcalc`.

## Riesgos

- **R1:** que ambos tracks converjan en la misma solucion y pierdan valor comparativo.
- **R2:** que la correccion documental no refleje con precision la logica finalmente aplicada en cada rama.
- **R3:** que cambios en `app.R` dependan de `ptcalc_repo/` y luego no sean transferibles al repo real `ptcalc`.
- **R4:** que el arbol de trabajo sucio complique el aislamiento de cambios por rama.
- **R5:** que la regla `n >= 12` se documente pero no quede aplicada de manera consistente en todos los flujos afectados.

## Log de Ejecucion

- [260310 02:19] Inicio del plan maestro y confirmacion de alcance con el usuario.
- [260310 02:19] Base comun confirmada: rama `main`, commit `bc3f3ae`.
- [260310 02:19] Revision inicial de `mods/`, `app.R`, `ptcalc_repo/` y documentacion `es/`.
- [260310 02:20] Ramas creadas: `opus/ajustes-app-260310` y `codex/ajustes-app-260310`.
- [260310 07:33] Inicio de implementacion `opus` en worktree aislado `/tmp/pt_app_opus`.
- [260310 07:33] `opus`: `app.R` actualizado para usar `run` como selector de serie, exponer `dataset_fuente` y aplicar gate operativo `n >= 12` para Algoritmo A.
- [260310 07:33] `opus`: documentacion base actualizada en `es/` para alinear reglas de serie y seleccion metodologica.
