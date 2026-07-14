# Fuentes autorizadas y requisitos disponibles

## Jerarquía de autoridad

| Prioridad | Fuente | Uso autorizado | Limitación |
|---|---|---|---|
| 1 | `app.R`, módulos cargados y `ptcalc/R/` | Describir comportamiento y cálculos vigentes | Debe acompañarse de prueba cuando se afirme un resultado |
| 2 | Tests actuales y ejecuciones fechadas | Evidencia reproducible de comportamiento | Un test diseñado pero no ejecutado no prueba conformidad |
| 3 | `data/`, `data_use_cases/`, `reports/` | Datos y plantillas del flujo actual | Revisar sensibilidad y representatividad |
| 4 | `Entregables_pt_app/` | Fuente documental que se actualizará | Mezcla material histórico, parcial y derivados |
| 5 | `testb/`, `dgpsea03/`, `docs/`, `VALIDACION DEFINITIVA/` | Insumo comparativo y evidencia candidata | Verificar fecha, versión y reproducibilidad antes de reutilizar |
| 6 | `app_original.R`, `app_v06.R`, `app_v07.R`, `app_final.R` | Historia de evolución | No describen por sí solas la versión vigente |

## Búsqueda contractual

La búsqueda se ejecutó el 2026-07-14 desde la raíz, sobre archivos rastreados y
no rastreados, excluyendo `.git/`, los artefactos de esta línea base y logs. Se
buscaron nombres de archivo y contenido, sin distinción de mayúsculas, con los
patrones `contrato`, `TDR`, `términos de referencia`, `acta de inicio/entrega/
aceptación` y `OSE-282-3065-2025`. Comando reproducible equivalente:

```bash
rg -n -i --glob '!.git/**' --glob '!logs/**' \
  --glob '!Entregables_pt_app/00_linea_base/**' \
  'OSE-282-3065-2025|t[eé]rminos de referencia|\bTDR\b|contrato|acta de (inicio|entrega|aceptaci[oó]n)' .

rg --files -g '!.git/**' -g '!logs/**' \
  -g '!Entregables_pt_app/00_linea_base/**' | \
  rg -i 'contrato|tdr|t[eé]rminos|acta|OSE-282|3065'
```

Las coincidencias genéricas “contrato” que describen contratos de datos no son
fuentes contractuales. El identificador OSE aparece en la documentación y los
metadatos del paquete `ptcalc` (`DESCRIPTION` y `README.md`), pero no se encontró
una copia primaria del contrato, TDR ni acta de aceptación en el workspace.

En consecuencia:

- la organización E01–E09 se considera alcance documental planificado, no una
  transcripción certificada de obligaciones contractuales;
- no se declarará cumplimiento contractual completo sin la fuente primaria;
- el responsable contractual debe aportar contrato, TDR y actas aplicables, o
  confirmar por escrito que el índice actual constituye el alcance aprobado.

## Referencias normativas

El repositorio cita ISO 13528:2022 e ISO/IEC 17043 con años discordantes (2023
y 2024). Esta fase registra la discrepancia, pero no decide la edición correcta.
Las fases de contenido y validación deberán usar copias controladas o una
referencia bibliográfica autorizada, sin reproducir material protegido más allá
de lo necesario.
