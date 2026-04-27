# Guía de personalización

Esta guía describe cómo ajustar el tema visual, el layout, agregar contaminantes y extender `ptcalc`.

---

## Ubicación en el código

| Elemento | Valor |
|---|---|
| Archivo | `cloned_app.R` |
| Definición de tema | Líneas 40–50 |
| Controles de layout | Líneas 58–67 |
| Extensión lógica | Funciones server / `ptcalc/` |

---

## 1. Personalización de tema (bslib)

La app usa Bootstrap 5 con `bslib`:

```r
theme = bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = "#212529",
  primary = "#FDB913",
  secondary = "#333333",
  success = "#4DB848",
  base_font = font_google("Droid Sans"),
  code_font = font_google("JetBrains Mono")
)
```

### Paleta actual

| Variable | Hex | Uso |
|---|---|---|
| `bg` | `#FFFFFF` | Fondo |
| `fg` | `#212529` | Texto |
| `primary` | `#FDB913` | Botones/enlaces |
| `secondary` | `#333333` | Elementos secundarios |
| `success` | `#4DB848` | Estados OK |
| `info` | `#0dcaf0` | Info |
| `warning` | `#ffc107` | Advertencias |
| `danger` | `#dc3545` | Errores |

### Cambiar a un tema Bootswatch

**Opción A: Selector en tiempo real**
1. Abrir **Opciones de diseño** en la barra lateral.
2. Activar “Mostrar opciones de diseño”.
3. Usar `themeSelector` para previsualizar.

**Opción B: Fijar tema en código**

```r
theme = bs_theme(
  version = 5,
  bootswatch = "cerulean",
  bg = "#FFFFFF",
  fg = "#212529",
  primary = "#0d6efd",
  secondary = "#6c757d",
  success = "#198754"
)
```

### Cambiar tipografías

```r
base_font = font_google("Open Sans")
code_font = font_google("Fira Code")
```

---

## 2. Controles de layout

Los anchos de paneles se controlan desde la UI con `sliderInput`:

- `nav_width`: ancho de navegación (1–5 unidades).
- `analysis_sidebar_width`: panel de parámetros (2–6 unidades).

---

## 3. Agregar nuevos contaminantes

1. Incluir el nuevo código en `homogeneity.csv` y `summary_n*.csv`.
2. La app detecta dinámicamente `unique(df$pollutant)`.
3. Solo ajustar listas fijas si existieran en el UI.

---

## 4. Extender `ptcalc`

Para añadir un método (ej. estimador Hampel):

1. Crear `ptcalc/R/new_method.R`.
2. Implementar `calculate_hampel(x)`.
3. Añadir `@export`.
4. Ejecutar `devtools::document("ptcalc")`.
5. Instalar/cargar el paquete.
6. Usar `ptcalc::calculate_hampel()` en `cloned_app.R`.
