# Entregable 04 — Fórmulas, uso e interpretación de puntajes PT

| Campo | Valor |
|---|---|
| Código | E04 |
| Versión documental | 2.0 |
| Fecha | 2026-07-14 |
| Estado | Vigente contra `ptcalc/R/pt_scores.R` |
| Audiencia | Usuarios, responsables técnicos y auditores |
| Aprobación externa | Pendiente |

## Elección rápida

| Puntaje | Denominador | Cuándo aporta información |
|---|---|---|
| z | `σ_pt` | Cuando la dispersión para evaluar aptitud está definida |
| z' | `sqrt(σ_pt² + u_xpt²)` | Cuando debe incorporarse la incertidumbre estándar del valor asignado |
| zeta | `sqrt(u_x² + u_xpt²)` | Para compatibilidad usando incertidumbres estándar |
| En | `sqrt(U_x² + U_xpt²)` | Para compatibilidad usando incertidumbres expandidas coherentes |

`x` es el resultado del participante y `x_pt` el valor asignado. `u` representa
incertidumbre estándar; `U` representa incertidumbre expandida. No mezcle ambas
escalas ni factores de cobertura distintos sin convertirlos y documentarlo.

## Fórmulas implementadas

$$z = \frac{x-x_{pt}}{\sigma_{pt}}$$

$$z' = \frac{x-x_{pt}}{\sqrt{\sigma_{pt}^2+u_{xpt}^2}}$$

$$\zeta = \frac{x-x_{pt}}{\sqrt{u_x^2+u_{xpt}^2}}$$

$$E_n = \frac{x-x_{pt}}{\sqrt{U_x^2+U_{xpt}^2}}$$

La implementación devuelve `NA_real_` si el denominador calculado no es finito
o no es positivo. En la interfaz, ese caso debe leerse como “N/A”, no como cero
ni como resultado satisfactorio.

## Umbrales y etiquetas exactas

| Puntajes | Intervalo | Etiqueta de la aplicación |
|---|---|---|
| z, z', zeta | valor no finito | `N/A` |
| z, z', zeta | `|score| ≤ 2` | `Satisfactorio` |
| z, z', zeta | `2 < |score| < 3` | `Cuestionable` |
| z, z', zeta | `|score| ≥ 3` | `No satisfactorio` |
| En | valor no finito | `N/A` |
| En | `|En| ≤ 1` | `Satisfactorio` |
| En | `|En| > 1` | `No satisfactorio` |

Los valores exactamente iguales a 2 son satisfactorios; exactamente 3 son no
satisfactorios; exactamente 1 en En es satisfactorio.

## Ejemplo único verificable

Entradas, todas en `µmol/mol`:

| Símbolo | Valor |
|---|---:|
| `x` | 10.18 |
| `x_pt` | 10.00 |
| `σ_pt` | 0.08 |
| `u_xpt` | 0.03 |
| `u_x` | 0.05 |
| `U_xpt` | 0.06 |
| `U_x` | 0.10 |

| Puntaje | Resultado sin clasificar | Presentación | Interpretación |
|---|---:|---:|---|
| z | 2.250000 | 2.250 | Cuestionable |
| z' | 2.106741 | 2.107 | Cuestionable |
| zeta | 3.086975 | 3.087 | No satisfactorio |
| En | 1.543487 | 1.543 | No satisfactorio |

```r
devtools::load_all("ptcalc")

z <- calculate_z_score(10.18, 10.00, 0.08)
z_prime <- calculate_z_prime_score(10.18, 10.00, 0.08, 0.03)
zeta <- calculate_zeta_score(10.18, 10.00, 0.05, 0.03)
en <- calculate_en_score(10.18, 10.00, 0.10, 0.06)

c(
  z = evaluate_z_score(z),
  z_prime = evaluate_z_score(z_prime),
  zeta = evaluate_z_score(zeta),
  en = evaluate_en_score(en)
)
```

El ejemplo muestra por qué dos puntajes sobre el mismo resultado no tienen que
coincidir: responden a denominadores y preguntas diferentes. Un valor negativo
indicaría que el resultado está por debajo de `x_pt`; la clasificación usa la
magnitud absoluta.

## De la entrada a la salida de la app

1. La app selecciona analito, nivel y ronda (`n_lab`).
2. Obtiene `x_pt`, `σ_pt` y `u_xpt` del método elegido y de las contribuciones
   disponibles de homogeneidad/estabilidad.
3. Normaliza la incertidumbre del participante: puede derivar `u_x = U_x / k`
   cuando se suministran incertidumbre expandida y factor de cobertura válidos.
4. Calcula los puntajes disponibles y deja `N/A` los que carecen de entradas.
5. Presenta tablas, gráficos y resúmenes; la exportación conserva valores y
   clasificaciones. El redondeo visual no interviene en la clasificación.

Una clasificación aislada no explica la causa. Antes de tomar acciones revise
unidad, transcripción, método, incertidumbre, trazabilidad del valor asignado y
desempeño histórico del participante.

## Casos que deben detener la interpretación

- `σ_pt ≤ 0`, denominador cero, infinito o dato faltante.
- Incertidumbre estándar mezclada con expandida.
- `U` sin factor de cobertura conocido cuando se requiere convertir a `u`.
- Resultado y valor asignado en unidades distintas.
- Identificador de analito, nivel o ronda que no corresponde a la selección.

## Evidencia y referencias

![CAP-12. Resumen de puntajes.](../../00_evidencia_visual/capturas/CAP-12_puntajes_resumen.png)

**Figura CAP-12.** Resumen operativo. CAP-13 documenta z y z'; CAP-14 documenta
zeta y En. Metadatos y hashes: `../../00_evidencia_visual/indice_capturas.md`.

- Autoridad matemática: `ptcalc/R/pt_scores.R`.
- Orquestación vigente: funciones de puntajes en `app.R`.
- Pruebas: `tests/testthat/test-final-scores-export.R` y
  `tests/testthat/test-entregables-fase-4.R`.
- Referencia declarada por el código: ISO 13528:2022, sección 10.
- La coincidencia con el código no constituye certificación normativa externa.

## Historial de cambios

| Versión | Fecha | Cambio |
|---|---|---|
| 1.0 | 2026-01-24 | Fórmulas y ejemplos iniciales |
| 2.0 | 2026-07-14 | Fórmulas verificadas, límites exactos, NA, escalas de incertidumbre y ejemplo reproducible |
