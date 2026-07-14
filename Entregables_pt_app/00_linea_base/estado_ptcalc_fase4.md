# Estado de la fuente matemática `ptcalc` usado en Fase 4

**Fecha:** 2026-07-14

**Repositorio anidado:** `ptcalc/`

**Commit HEAD:** `e87180b`

**Rama:** `master`

**Estado:** árbol de trabajo con cambios no publicados respecto de HEAD

## Alcance

El repositorio raíz ignora `ptcalc/`; por tanto, el commit de documentación de
Fase 4 no congela por sí solo su contenido. Los ejemplos y el catálogo fueron
calculados contra el árbol de trabajo disponible el 2026-07-14, que contiene,
entre otros cambios, la firma de cuatro argumentos
`calculate_homogeneity_criterion_expanded(sigma_pt, u_sigma_pt, sw, g)` y la
implementación ampliada de `run_algorithm_a()`.

Este estado ya existía como autoridad funcional utilizada por `app.R`, pero no
está representado íntegramente por `ptcalc@e87180b`. Antes del cierre final del
paquete debe publicarse el repositorio anidado o fijarse una versión instalable
equivalente. Hasta entonces, la reproducción exacta requiere conservar el
árbol de trabajo actual y contrastar:

```bash
git -C ptcalc status --short --branch
git -C ptcalc diff --stat
```

La limitación no invalida las cifras de E03/E04, que están cubiertas por la
prueba focal, pero impide afirmar que un clon del commit raíz sea suficiente
para recrearlas sin la misma revisión de `ptcalc`.
