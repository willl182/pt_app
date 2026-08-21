# Presupuesto de incertidumbre — referencia CalAire

**Fecha:** 2026-07-30
**Scripts:** `scripts/07_u_repetibilidad.R`, `scripts/08_u_calibracion.R`, `scripts/09_presupuesto_incertidumbre.R`
**Salidas:** `outputs/tables/presupuesto_incertidumbre.csv` (detalle), `outputs/tables/presupuesto_resumen.csv` (resumen), `outputs/tables/u_referencia_aplicable.csv` (listo para cruzar con `data/processed/`)

---

## 1. Respuesta corta: ¿los componentes son globales o cambian por nivel?

**Cambian por nivel, salvo dos.**

| Componente | ¿Cambia con el nivel? | Cómo |
|---|---|---|
| `u_rep` repetibilidad | **Sí** | Se mide en cada meseta. No sigue un patrón: depende del ruido que hubo ese día en ese nivel |
| `u_curva` curva de calibración | **Sí** | Forma de U: mínima cerca del centro de la curva (~90 ppb), sube hacia el cero y hacia el tope |
| `u_patrón` O3 | **Sí** | Recta: `U = 0.0051·C + 0.67` nmol/mol |
| `u_patrón` cilindro | **No — global** | Absoluta: 0.5 en la unidad del gas |
| `u_conv` convertidor NO2 | **Sí** | Proporcional: 1.08 % del nivel |
| `u_aire_cero` | **No — global** | Valor fijo en ppb, igual en todos los niveles |

Por eso `U` **relativa** (en %) sube tanto en los niveles bajos: el aire cero y la curva aportan lo mismo en valor absoluto, pero se dividen entre una concentración cada vez más pequeña. Ejemplo en NO2 ronda R2C: U pasa de 2.33 % en 140 ppb a 3.99 % en 30 ppb, aunque en valor absoluto *baja* de 3.26 a 1.20 ppb.

Regla práctica: **mira siempre la U absoluta, no la relativa**, cuando compares niveles entre sí.

## 2. Cómo se construyó

Cinco componentes, cada uno de una fuente distinta, combinados en cuadratura:

```
u_c = √( u_rep² + u_curva² + u_patrón² + u_aire_cero² + u_conv² )
U   = 2 · u_c
```

### `u_rep` — repetibilidad (Tipo A)

De los datos crudos de 1 minuto de cada ronda. Dos correcciones sobre el cálculo directo:

1. Se separa el ruido *dentro* de cada bloque horario (`s_w`) de la deriva *entre* bloques (`s_b`).
2. **Los datos de 1 min están autocorrelacionados** (ρ₁ mediana ≈ 0.55), así que `s/√60` subestima. Se usa el tamaño efectivo bajo AR(1), `n_eff = n·(1−ρ)/(1+ρ)`, que con ρ=0.55 deja 60 minutos en ~17 mediciones independientes.

Se toma el mayor entre el estimador del protocolo (`s_b/√n_bloques`, GUM Tipo A de `uncer.md`) y el ruido efectivo.

> Esto implica que el `u_value` que hoy calcula `R/preprocessing/hourly_averages.R:60` está subestimado por un factor 1.3–15 (mediana ~2.5). Sigue pendiente de corregir.

### `u_curva` — curva de calibración del analizador

Método completo en `uncer_cal.md`. De los formatos F-PSEY-47/49/61/62, 5 puntos (cero dejado + 20/40/70/90 %). Se toma **el mayor** entre GUM H.3 (estadístico) y falta de ajuste EN 14211 (peor caso) — son dos estimaciones del mismo efecto, sumarlas lo contaría doble.

Se usa la calibración **vigente**: la más reciente anterior al inicio de cada ronda.

### `u_patrón` — el patrón que genera la concentración

Dos casos distintos:

- **O3**: certificado del calibrador dinámico F-PSMT-01 sn 554, ecuación del informe `U(X) = 0.0051·X + 0.67` nmol/mol con k=2, válida 0–500 nmol/mol. Es un certificado de ozono y cubre la concentración generada de punta a punta, así que O3 no lleva término de dilución.
- **CO, SO2, NO, NO2**: incertidumbre expandida del certificado del cilindro, **absoluta**: 1 µmol/mol para CO, 1 nmol/mol para los gases en ppb. Con k=2 queda `u_patrón = 0.5` en la unidad del gas, **igual en todos los niveles**.

> **Advertencia sobre CO.** Aplicar 1 µmol/mol al nivel entregado hace que el patrón valga 0.5 µmol/mol frente a niveles de 1.4 a 6.3 µmol/mol: U expandida de 1.0 µmol/mol, entre 16 % y 72 % del nivel. Domina el presupuesto por completo y deja los demás componentes en el ruido. Si ese 1 µmol/mol corresponde en realidad a la concentración del **cilindro** (y no al nivel entregado), la propagación correcta es relativa. El script trae `CYLINDER_MODE <- "absoluto"`; cambiarlo a `"relativo"` y llenar `CYLINDER_CONCENTRATION["co"]` lo corrige en una línea.

### `u_aire_cero` — impureza del aire cero

Formato F-PSEY-51 (2026-07-28): generador TAPI 751H de estación contra cilindro PRAXAIR de referencia. El error medido es un sesgo no corregido, así que entra como rectangular (`|error|/√3`):

| gas | error medido | u_aire_cero |
|---|---|---|
| SO2 | +0.062 ppb | 0.036 |
| NO | −0.766 ppb | 0.442 |
| NO2 | +0.620 ppb | 0.358 |
| CO | −0.018 ppm | 0.0104 |
| O3 | +0.040 ppb | 0.023 |

### `u_conv` — eficiencia del convertidor (solo NO2)

Eficiencia medida 98.14 %. La desviación respecto al 100 % entra como rectangular: `(100−E)/100 · C / √3` = 1.08 % del nivel.

## 3. Tabla de incertidumbres

Unidades: ppb salvo CO en ppm. `U` es expandida con k=2.

| gas | ronda | nivel | u_rep | u_curva | u_patrón | u_aire_cero | u_conv | **U (k=2)** | U rel |
|---|---|---|---|---|---|---|---|---|---|
| CO | R1 | 6.3 | 0.026 | 0.048 | 0.500 | 0.010 | — | **1.006** | 15.97 % |
| CO | R1 | 4.2 | 0.020 | 0.030 | 0.500 | 0.010 | — | **1.003** | 23.88 % |
| CO | R1 | 2.8 | 0.015 | 0.026 | 0.500 | 0.010 | — | **1.002** | 35.79 % |
| CO | R1 | 1.4 | 0.012 | 0.032 | 0.500 | 0.010 | — | **1.003** | 71.61 % |
| NO | R2B | 180 | 0.077 | 0.318 | 0.500 | 0.442 | — | **1.487** | 0.83 % |
| NO | R2B | 119 | 0.074 | 0.204 | 0.500 | 0.442 | — | **1.404** | 1.18 % |
| NO | R2B | 78 | 0.056 | 0.187 | 0.500 | 0.442 | — | **1.391** | 1.78 % |
| NO | R2B | 37 | 0.145 | 0.234 | 0.500 | 0.442 | — | **1.444** | 3.90 % |
| NO | R3 | 179 | 0.135 | 0.860 | 0.500 | 0.442 | — | **2.193** | 1.23 % |
| NO | R3 | 119 | 0.650 | 0.555 | 0.500 | 0.442 | — | **2.168** | 1.82 % |
| NO | R3 | 80 | 0.061 | 0.505 | 0.500 | 0.442 | — | **1.678** | 2.10 % |
| NO | R3 | 41 | 0.071 | 0.617 | 0.500 | 0.442 | — | **1.824** | 4.45 % |
| NO2 | R2C | 140 | 0.119 | 0.481 | 0.500 | 0.358 | 1.507 | **3.402** | 2.43 % |
| NO2 | R2C | 105 | 0.050 | 0.351 | 0.500 | 0.358 | 1.130 | **2.669** | 2.54 % |
| NO2 | R2C | 60 | 0.050 | 0.287 | 0.500 | 0.358 | 0.646 | **1.876** | 3.13 % |
| NO2 | R2C | 30 | 0.049 | 0.351 | 0.500 | 0.358 | 0.323 | **1.559** | 5.20 % |
| NO2 | R3 | 112 | 0.040 | 0.548 | 0.500 | 0.358 | 1.205 | **2.921** | 2.61 % |
| NO2 | R3 | 64 | 0.096 | 0.392 | 0.500 | 0.358 | 0.689 | **2.016** | 3.15 % |
| NO2 | R3 | 32 | 0.069 | 0.496 | 0.500 | 0.358 | 0.344 | **1.729** | 5.40 % |
| O3 | R2A | 180 | 0.757 | 1.001 | 0.794 | 0.023 | — | **2.970** | 1.65 % |
| O3 | R2A | 120 | 0.139 | 0.667 | 0.641 | 0.023 | — | **1.872** | 1.56 % |
| O3 | R2A | 80 | 0.044 | 0.523 | 0.539 | 0.023 | — | **1.506** | 1.88 % |
| O3 | R2A | 40 | 0.036 | 0.642 | 0.437 | 0.023 | — | **1.556** | 3.89 % |
| O3 | R3 | 180 | 0.108 | 0.621 | 0.794 | 0.023 | — | **2.028** | 1.13 % |
| O3 | R3 | 120 | 0.206 | 0.404 | 0.641 | 0.023 | — | **1.571** | 1.31 % |
| O3 | R3 | 80 | 0.093 | 0.361 | 0.539 | 0.023 | — | **1.311** | 1.64 % |
| O3 | R3 | 40 | 0.047 | 0.443 | 0.437 | 0.023 | — | **1.249** | 3.12 % |
| SO2 | R1 | 179 | 0.650 | 0.361 | 0.500 | 0.036 | — | **1.793** | 1.00 % |
| SO2 | R1 | 119 | 0.294 | 0.227 | 0.500 | 0.036 | — | **1.248** | 1.05 % |
| SO2 | R1 | 80 | 0.168 | 0.197 | 0.500 | 0.036 | — | **1.129** | 1.41 % |
| SO2 | R1 | 40 | 0.107 | 0.241 | 0.500 | 0.036 | — | **1.133** | 2.83 % |

## 4. Qué domina en cada gas

En el nivel más alto de cada ronda, porcentaje de la varianza:

| gas | ronda | rep | curva | patrón | aire cero | conv |
|---|---|---|---|---|---|---|
| CO | R1 | 0.3 | 0.9 | **98.8** | 0.0 | — |
| NO | R2B | 1.1 | 18.3 | **45.2** | 35.4 | — |
| NO | R3 | 1.5 | **61.4** | 20.8 | 16.3 | — |
| NO2 | R2C | 0.5 | 8.0 | 8.6 | 4.4 | **78.4** |
| NO2 | R3 | 0.1 | 14.1 | 11.7 | 6.0 | **68.1** |
| O3 | R2A | 26.0 | **45.4** | 28.6 | 0.0 | — |
| O3 | R3 | 1.1 | 37.5 | **61.3** | 0.1 | — |
| SO2 | R1 | **52.5** | 16.2 | 31.1 | 0.2 | — |

Lecturas:

- **NO2 está limitado por el convertidor.** Aporta 68–78 % de la varianza. Es el único término reducible con mantenimiento: llevar la eficiencia de 98.14 % a ~99.5 % bajaría la U de NO2 en el nivel alto de 3.40 a ~1.35 ppb. Es la acción de mayor impacto de toda la tabla.
- **NO y SO2 están limitados por el patrón** (0.5 ppb fijo) junto con el aire cero en NO. Ambos son irreducibles sin un cilindro mejor certificado o un aire cero más limpio.
- **CO está totalmente dominado por el patrón** (99 %), pero ese resultado depende de cómo se interprete el 1 µmol/mol; ver la advertencia de la sección 2.
- **O3 está limitado por el patrón y la curva**, sin margen fácil de mejora.
- La repetibilidad, que era el foco inicial del análisis, pesa menos del 27 % en todos los casos y menos del 3 % en la mayoría.

## 4b. Qué archivo de `data/processed/` usar

Los presupuestos aplican a la **serie de referencia CalAire** (`instrument = "calaire_ref"`, serial con prefijo `4U`). El archivo correcto por ronda:

| ronda | archivo | contenido |
|---|---|---|
| R1 (SO2, CO) | `ronda_1_r.csv` | referencia |
| R2A (O3) | `ronda_2a_r.csv` | referencia |
| R2B (NO) | `ronda_2b_r.csv` | referencia |
| R2C (NO2) | `ronda_2c_r.csv` | referencia |
| R3 (O3, NO, NO2) | `ronda_3_r.csv` | referencia |

Convenciones del directorio:

- `ronda_N_r.csv` → **referencia** (es la que corresponde a este presupuesto).
- `ronda_N_p_ronda.csv` → participante. No aplica: su incertidumbre es la del laboratorio participante, no la nuestra.
- `ronda_N_completa.csv` → referencia y participantes juntos, distinguidos por la columna `tipo`.
- `h_ronda_*.csv` → medias horarias sin consolidar por nivel (una fila por hora).
- `parts_r1.csv` → **no son datos**: es solo el listado de qué analizador usó cada laboratorio en R1.

La tabla `outputs/tables/u_referencia_aplicable.csv` ya trae la llave de cruce lista, con la columna `level` en el mismo formato de esos archivos (`"180-nmol/mol"`, `"6.3-µmol/mol"`). Cruce verificado: las 31 filas encuentran su par.

```r
ref <- read.csv("data/processed/ronda_3_r.csv")
u   <- read.csv("outputs/tables/u_referencia_aplicable.csv")
ref <- merge(ref, u[, c("pollutant", "level", "u_c", "u_exp", "k_factor")],
             by = c("pollutant", "level"), all.x = TRUE)
```

Ojo: la columna `u_value` que ya traen esos archivos **no** es este presupuesto. Es solo la componente de repetibilidad, calculada además sin corregir la autocorrelación (ver sección 2). Reemplázala por `u_c`, no las sumes.

## 5. Alcance y limitaciones

- **La interpretación del 1 µmol/mol en CO decide su presupuesto.** Ver la advertencia de la sección 2: como está, el patrón aporta el 99 % de la varianza de CO.
- **Falta la incertidumbre de los controladores de flujo de dilución** para NO, NO2, SO2 y CO. El certificado F-PSMT-01 disponible es del generador de O3, no de los canales de dilución. Es el hueco más relevante que queda.
- **k del certificado del cilindro asumido en 2.** Si ese 1 µmol/mol o 1 nmol/mol ya fuera incertidumbre estándar, el término se duplica. Ahora que el patrón es dominante en CO, SO2 y NO, esto sí cambia las conclusiones: conviene confirmarlo.
- **Un solo calibrador.** Se asume el mismo equipo en todas las rondas y para ambos analistas.
- **`u_rep` con pocos grados de libertad en algunos niveles.** Donde la meseta dio un solo bloque horario, el componente de deriva entre bloques no se pudo estimar y `u_rep` sale del ruido efectivo únicamente.
- **El formato de CO tiene fecha 2025-04-22**, un año antes de la ronda. Se tomó como vigente por ser el único disponible, pero el formulario debería corregirse.
