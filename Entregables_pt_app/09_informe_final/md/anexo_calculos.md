# E09 — Anexo reproducible de cálculos

| Campo | Valor |
|---|---|
| Código | DOC-E09-ANX-01 |
| Versión | 3.0 |
| Fecha | 2026-07-14 |
| Estado | Vigente contra `ptcalc`; aprobación externa pendiente |
| Unidad ilustrativa | `µmol/mol` |

## Propósito

Este anexo muestra las entradas y los pasos usados por la validación. Los datos
son sintéticos y deterministas. El archivo
`anexos/calculos_reproducibles.csv` contiene la precisión completa; las cifras
de las tablas siguientes están redondeadas solo para lectura.

## Entradas

```r
hom <- matrix(c(
  9.98, 10.02, 10.01, 10.03, 9.99, 10.00, 10.04, 10.02,
  9.97, 10.01, 10.00, 10.02, 10.03, 10.01, 9.98, 9.99,
  10.02, 10.00, 10.01, 10.04
), ncol = 2, byrow = TRUE)
stab <- matrix(c(
  10.00, 10.01, 10.02, 10.00,
  9.99, 10.01, 10.03, 10.02
), ncol = 2, byrow = TRUE)
participants <- c(9.91, 9.96, 9.99, 10.00, 10.02, 10.04, 10.08, 10.60)
```

Cada fila de `hom` y `stab` representa un ítem; cada columna, una réplica.

## Homogeneidad

Se calcula la media de cada ítem, la media general, la dispersión dentro de
ítems (`s_w`) y la dispersión entre ítems (`s_s`). Para dos réplicas:

`s_w² = sum((x_i1 - x_i2)²) / (2g)`

`s_s² = max(0, s_xbar² - s_w² / m)`

| Magnitud | Resultado | Unidad |
|---|---:|---|
| Media general | 10.008500 | µmol/mol |
| `s_w` | 0.017748 | µmol/mol |
| `s_s` | 0.009037 | µmol/mol |
| MADe usado como `sigma_pt` | 0.022245 | µmol/mol |
| Criterio básico `0.3 sigma_pt` | 0.006674 | µmol/mol |

El resultado básico es reproducible, pero `s_s` supera el criterio. El término
expandido retornado por la implementación (`0.000402`) tiene unidad cuadrática;
no se compara en este informe como si fuera una desviación. Esa incompatibilidad
permanece como `OPEN_RISK`.

## Estabilidad

La diferencia es el valor absoluto entre la media de estabilidad y la media de
homogeneidad. El criterio básico es `0.3 sigma_pt`.

| Magnitud | Resultado | Unidad |
|---|---:|---|
| Media de estabilidad | 10.010000 | µmol/mol |
| Diferencia absoluta | 0.001500 | µmol/mol |
| Criterio básico | 0.006674 | µmol/mol |

Como la diferencia es menor que el criterio, el caso sintético cumple el
criterio básico implementado.

## Estimadores robustos

`nIQR = 0.7413 × (Q3 - Q1)` y `MADe = 1.483 × mediana(|x_i - mediana(x)|)`.
El Algoritmo A inicia con mediana y MADe, limita valores extremos y repite hasta
estabilizar tres cifras significativas según la implementación vigente.

| Método | Valor asignado | Dispersión |
|---|---:|---:|
| Mediana + nIQR | 10.010000 | 0.050038 |
| Mediana + MADe | 10.010000 | 0.059320 |
| Algoritmo A | 10.017023 | 0.079528 |

El detalle de cada iteración está en
`anexos/algoritmo_a_iteraciones.csv`; una observación fue winsorizada.

## Puntajes

Para `x = 10.08`, `x_pt = 10.00`, `sigma_pt = 0.05`, `u_x = 0.03`,
`u_xpt = 0.01`, `U_x = 0.06` y `U_xpt = 0.02`:

| Puntaje | Fórmula operativa | Resultado |
|---|---|---:|
| z | `(x - x_pt) / sigma_pt` | 1.600000 |
| z' | `(x - x_pt) / sqrt(sigma_pt² + u_xpt²)` | 1.568929 |
| zeta | `(x - x_pt) / sqrt(u_x² + u_xpt²)` | 2.529822 |
| En | `(x - x_pt) / sqrt(U_x² + U_xpt²)` | 1.264911 |

Las comparaciones se realizan con los valores sin redondear. Las pruebas
también verifican las fronteras `|z| = 2`, `|z| = 3`, `|En| = 1` y que un
denominador inválido produzca `NA` en vez de una cifra engañosa.

## Archivos de auditoría

- `anexos/calculos_reproducibles.csv`: resultados a precisión completa.
- `anexos/algoritmo_a_iteraciones.csv`: iteraciones completas.
- `anexos/matriz_validacion.csv`: esperado, obtenido, evidencia y estado.
- `anexos/entorno_ejecucion.txt`: commits, estado local y versiones.
- `anexos/ptcalc_worktree.patch`: cambios locales exactos del núcleo ejecutado.
- `anexos/ptcalc_fuentes_sha256.csv`: hashes de todas las fuentes R cargadas.
- `anexos/generacion_log.txt`: resumen de ejecución.

La evidencia comprueba la implementación evaluada; no reemplaza una revisión
normativa independiente ni una decisión profesional sobre una ronda real.
