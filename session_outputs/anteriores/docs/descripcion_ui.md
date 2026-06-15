# Descripción UI de `pt_app`

Este documento describe el estilo visual de la página principal de `pt_app` para poder reproducirlo lo más fielmente posible en otra aplicación web.

## Concepto general

La interfaz tiene un estilo institucional, sobrio y moderno. Se basa en una combinación de grises claros, tarjetas limpias, esquinas redondeadas, sombras suaves y un color de acento amarillo institucional.

La página funciona visualmente como un dashboard:

1. Fondo general gris claro.
2. Header amplio con logo institucional y borde inferior amarillo.
3. Barra lateral izquierda para navegación por módulos.
4. Área principal con tarjetas/paneles de contenido.
5. Footer gris oscuro con línea superior amarilla.

El objetivo visual es transmitir una aplicación técnica, confiable e institucional, sin verse pesada ni anticuada.

---

## Paleta de colores

Usar esta paleta como base:

```css
:root {
  /* Amarillo institucional / color principal */
  --pt-primary: #FDB913;
  --pt-primary-light: #FFD54F;
  --pt-primary-dark: #E5A610;
  --pt-primary-subtle: #F5F5F0;

  /* Neutros */
  --pt-bg: #E8EAED;
  --pt-bg-card: #F5F6F7;
  --pt-fg: #1F2937;
  --pt-fg-muted: #6B7280;
  --pt-border: #D1D5DB;
  --pt-secondary: #111827;

  /* Estados */
  --pt-success: #38A169;
  --pt-warning: #ECC94B;
  --pt-danger: #E53E3E;
  --pt-info: #3182CE;
}
```

Color principal:

```css
#FDB913
```

Debe usarse para:

- Bordes activos.
- Botones principales.
- Línea inferior del header.
- Línea superior del footer.
- Estados activos de navegación.
- Pequeños íconos o detalles visuales.

Evitar usar el amarillo como fondo masivo. Funciona mejor como acento.

---

## Tipografía

La aplicación usa una tipografía sans-serif limpia:

```css
font-family: 'Droid Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI',
  Roboto, 'Helvetica Neue', Arial, sans-serif;
```

En Shiny/bslib se configura así:

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

Para código, logs o salidas técnicas, usar:

```css
font-family: 'JetBrains Mono', monospace;
```

---

## Fondo y contenedor general

El fondo general no es blanco puro, sino gris claro:

```css
body {
  background-color: #E8EAED;
  color: #1F2937;
  font-family: 'Droid Sans', 'Segoe UI', sans-serif;
  font-size: 0.9375rem;
  line-height: 1.6;
}
```

El contenido se centra y no ocupa todo el ancho infinito de pantalla:

```css
.container-fluid,
.app-container {
  max-width: 1600px;
  margin: 0 auto;
  padding: 1.5rem 2rem;
}
```

---

## Header principal

El header es una tarjeta horizontal grande, con logo a la izquierda y textos a la derecha.

Características:

- Fondo con gradiente muy sutil entre gris claro y crema.
- Borde inferior amarillo grueso.
- Esquinas redondeadas.
- Sombra media.
- Mucho aire interno.

```css
.app-header {
  background: linear-gradient(135deg, #F5F6F7 0%, #F5F5F0 100%);
  border-bottom: 4px solid #FDB913;
  padding: 2rem;
  margin-bottom: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.10);
}

.header-content {
  display: flex;
  align-items: center;
  gap: 2rem;
  max-width: 1600px;
  margin: 0 auto;
}

.logo-container {
  flex-shrink: 0;
}

.unal-logo,
.app-logo {
  height: 100px;
  width: auto;
  object-fit: contain;
}

.title-container {
  flex-grow: 1;
}
```

Textos del header:

```css
.app-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
}

.app-subtitle {
  font-size: 1.25rem;
  font-weight: 500;
  color: #E5A610;
  margin-bottom: 0.25rem;
}

.app-institution {
  font-size: 0.875rem;
  color: #6B7280;
  margin: 0;
  line-height: 1.5;
}
```

Ejemplo HTML:

```html
<header class="app-header">
  <div class="header-content">
    <div class="logo-container">
      <img src="logo.png" class="app-logo" alt="Logo institucional">
    </div>
    <div class="title-container">
      <h1 class="app-title">Aplicativo para Evaluación de Ensayos de Aptitud</h1>
      <h3 class="app-subtitle">Gases Contaminantes Criterio</h3>
      <p class="app-institution">
        Laboratorio CALAIRE | Universidad Nacional de Colombia - Sede Medellín<br>
        Instituto Nacional de Metrología (INM)
      </p>
    </div>
  </div>
</header>
```

En pantallas pequeñas, el header debe pasar a disposición vertical centrada.

```css
@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
    text-align: center;
  }

  .app-logo {
    height: 80px;
  }
}
```

---

## Layout principal

La estructura recomendada es:

```html
<div class="dashboard-layout">
  <aside class="sidebar-panel">
    <!-- navegación -->
  </aside>

  <main class="main-panel">
    <!-- tarjetas y contenido -->
  </main>
</div>
```

CSS sugerido:

```css
.dashboard-layout {
  display: grid;
  grid-template-columns: 260px 1fr;
  gap: 1.5rem;
  align-items: start;
}

.main-panel {
  background: rgba(245, 246, 247, 0.7);
  border-radius: 12px;
  padding: 1.5rem;
}

@media (max-width: 900px) {
  .dashboard-layout {
    grid-template-columns: 1fr;
  }
}
```

---

## Barra lateral

La sidebar debe sentirse como un panel institucional cálido.

Características:

- Fondo crema claro.
- Borde vertical izquierdo amarillo.
- Esquinas redondeadas hacia la derecha.
- Sombra suave.
- Items con íconos pequeños.
- Item activo con fondo ligeramente más claro y texto más oscuro.

```css
.sidebar-panel {
  background: linear-gradient(180deg, #F5F5F0 0%, #FFF9E6 100%);
  border-left: 4px solid #FDB913;
  border-radius: 0 12px 12px 0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
  padding: 1.5rem;
}

.sidebar-title {
  font-size: 0.95rem;
  font-weight: 500;
  color: #1F2937;
  margin-bottom: 0.75rem;
}

.sidebar-nav {
  list-style: none;
  padding: 0;
  margin: 0;
}

.sidebar-nav li {
  margin-bottom: 0.25rem;
}

.sidebar-nav a {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  border-radius: 8px;
  color: #6B7280;
  text-decoration: none;
  font-size: 0.9rem;
  transition: all 150ms ease;
}

.sidebar-nav a:hover {
  color: #111827;
  background: #F5F5F0;
}

.sidebar-nav a.active {
  color: #111827;
  background: #F5F6F7;
  font-weight: 600;
}
```

---

## Tarjetas y paneles

El contenido principal está compuesto por tarjetas claras.

Características:

- Fondo gris muy claro.
- Borde gris suave.
- Esquinas redondeadas.
- Sombra sutil.
- Padding amplio.
- Encabezado de tarjeta con borde inferior.

```css
.card,
.panel,
.content-card {
  background-color: #F5F6F7;
  border: 1px solid #D1D5DB;
  border-radius: 12px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.card:hover,
.content-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.10);
}

.card-header {
  background: linear-gradient(135deg, #F5F5F0 0%, #F5F6F7 100%);
  border-bottom: 1px solid #D1D5DB;
  border-radius: 12px 12px 0 0;
  padding: 1rem 1.5rem;
  margin: -1.5rem -1.5rem 1.5rem -1.5rem;
  font-weight: 600;
  color: #111827;
}
```

---

## Tarjetas internas para pasos o módulos

En la pantalla principal se ven bloques internos para carga de archivos. Cada bloque tiene un acento vertical de color.

Patrón recomendado:

```css
.step-card {
  background: #F5F6F7;
  border-left: 4px solid #FDB913;
  padding: 1rem;
  min-height: 160px;
}

.step-card.blue {
  border-left-color: #3182CE;
}

.step-card.green {
  border-left-color: #38A169;
}

.step-card.orange {
  border-left-color: #FDB913;
}
```

Dentro de estas tarjetas:

- Número del paso en negrita.
- Título corto.
- Explicación secundaria en gris.
- Input o botón de carga.

---

## Botones

Los botones principales son amarillos con gradiente y texto oscuro.

```css
.btn,
button,
.action-button {
  font-weight: 500;
  padding: 0.5rem 1.5rem;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: all 150ms ease;
  font-size: 0.9375rem;
}

.btn-primary,
.btn-default,
.btn-main {
  background: linear-gradient(135deg, #FDB913 0%, #E5A610 100%);
  color: #111827;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
}

.btn-primary:hover,
.btn-default:hover,
.btn-main:hover {
  background: linear-gradient(135deg, #FFD54F 0%, #FDB913 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.10);
}

.btn-primary:active,
.btn-main:active {
  transform: translateY(0);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
}
```

Botones secundarios:

```css
.btn-secondary {
  background-color: #E8EAED;
  color: #1F2937;
  border: 1px solid #D1D5DB;
}

.btn-secondary:hover {
  background-color: #D1D5DB;
}
```

---

## Formularios e inputs

Los inputs son claros, redondeados y con foco amarillo.

```css
.form-control,
input,
select,
textarea {
  background-color: #F5F6F7;
  border: 1.5px solid #D1D5DB;
  border-radius: 8px;
  padding: 0.5rem 1rem;
  font-size: 0.9375rem;
  color: #1F2937;
  transition: border-color 150ms ease, box-shadow 150ms ease;
}

.form-control:focus,
input:focus,
select:focus,
textarea:focus {
  border-color: #FDB913;
  box-shadow: 0 0 0 3px rgba(253, 185, 19, 0.3);
  outline: none;
}

.form-control::placeholder {
  color: #6B7280;
  opacity: 0.7;
}
```

Labels:

```css
label,
.control-label {
  font-weight: 500;
  color: #111827;
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
}
```

Checkboxes/radios:

```css
input[type="checkbox"],
input[type="radio"] {
  accent-color: #FDB913;
  width: 18px;
  height: 18px;
}
```

Inputs de archivo:

```css
input[type="file"] {
  padding: 1rem;
  background-color: #F5F5F0;
  border: 2px dashed #FDB913;
  border-radius: 8px;
}

input[type="file"]:hover {
  background-color: #FFD54F;
  border-color: #E5A610;
}
```

---

## Tablas

Las tablas deben verse como tarjetas limpias, con encabezado claro y línea inferior amarilla.

```css
table,
.table,
.dataTable {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  background-color: #F5F6F7;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
}

table thead th,
.table thead th {
  background: linear-gradient(180deg, #F5F5F0 0%, #F5F6F7 100%);
  color: #111827;
  font-weight: 600;
  padding: 1rem 1.5rem;
  text-align: left;
  border-bottom: 2px solid #FDB913;
  font-size: 0.875rem;
  letter-spacing: 0.03em;
}

table tbody td,
.table tbody td {
  padding: 1rem 1.5rem;
  border-bottom: 1px solid #D1D5DB;
  vertical-align: middle;
  font-size: 0.9375rem;
}

table tbody tr:hover {
  background-color: #F5F5F0;
}

table tbody tr:nth-child(even) {
  background-color: rgba(253, 185, 19, 0.03);
}
```

---

## Bloques de código / estado

Para salidas de estado, logs o información técnica, usar un contenedor gris claro con fuente monoespaciada.

```css
.status-box,
pre,
code {
  font-family: 'JetBrains Mono', monospace;
}

.status-box {
  background: #F5F6F7;
  border: 1px solid #D1D5DB;
  border-radius: 6px;
  padding: 1rem;
  color: #1F2937;
  font-size: 0.85rem;
  white-space: pre-wrap;
}
```

---

## Footer

El footer es oscuro, institucional y compacto.

Características:

- Fondo gris oscuro.
- Línea superior amarilla.
- Tres columnas de contenido.
- Títulos en amarillo y mayúsculas.
- Texto blanco con opacidad.
- Links amarillo claro.

```css
.app-footer-modern,
.app-footer {
  background: #585858;
  color: white;
  padding: 1.5rem 0 0.5rem;
  margin-top: 1.5rem;
  border-top: 4px solid #FDB913;
}

.footer-content {
  max-width: 1600px;
  margin: 0 auto;
  padding: 0 2rem;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 2rem;
  margin-bottom: 1rem;
}

.footer-section h4 {
  color: #FDB913;
  font-size: 1rem;
  font-weight: 600;
  margin-bottom: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.footer-section p {
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.875rem;
  margin-bottom: 0.25rem;
  line-height: 1.4;
}

.footer-section a {
  color: #FFD54F;
  text-decoration: none;
}

.footer-section a:hover {
  color: #FDB913;
  text-decoration: underline;
}
```

Ejemplo:

```html
<footer class="app-footer">
  <div class="footer-content">
    <div class="footer-section">
      <h4>Proyecto</h4>
      <p>Este aplicativo fue desarrollado en el marco del proyecto...</p>
    </div>
    <div class="footer-section">
      <h4>Instituciones</h4>
      <p>Laboratorio CALAIRE</p>
      <p>Universidad Nacional de Colombia - Sede Medellín</p>
    </div>
    <div class="footer-section">
      <h4>Contacto</h4>
      <p><a href="mailto:calaire_med@unal.edu.co">calaire_med@unal.edu.co</a></p>
    </div>
  </div>
</footer>
```

---

## Radios de borde, sombras y espaciado

Usar estos valores para mantener consistencia:

```css
:root {
  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;

  --shadow-xs: 0 1px 2px rgba(0, 0, 0, 0.06);
  --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.08);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.10);
  --shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.14);
  --shadow-focus: 0 0 0 3px rgba(253, 185, 19, 0.3);
}
```

Espaciado base:

```css
:root {
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --space-xxl: 3rem;
}
```

---

## Reglas de diseño importantes

1. No usar blanco puro como fondo principal. El fondo general debe ser gris claro `#E8EAED`.
2. Usar blanco/gris muy claro en tarjetas: `#F5F6F7`.
3. Usar el amarillo `#FDB913` como acento, no como color dominante.
4. Mantener bordes suaves y sombras discretas.
5. Usar títulos oscuros, texto secundario gris y subtítulos/acento en amarillo oscuro.
6. La UI debe sentirse espaciosa: evitar componentes demasiado pegados.
7. Los paneles deben verse como tarjetas técnicas, no como cajas planas.
8. La navegación activa debe ser clara pero sobria.
9. El footer debe cerrar visualmente la página con fondo gris oscuro y acento amarillo.

---

## CSS mínimo reutilizable

Si se quiere implementar rápidamente el estilo en otra app, partir de este bloque:

```css
:root {
  --pt-primary: #FDB913;
  --pt-primary-light: #FFD54F;
  --pt-primary-dark: #E5A610;
  --pt-primary-subtle: #F5F5F0;
  --pt-bg: #E8EAED;
  --pt-bg-card: #F5F6F7;
  --pt-fg: #1F2937;
  --pt-fg-muted: #6B7280;
  --pt-border: #D1D5DB;
  --pt-secondary: #111827;
}

body {
  background: var(--pt-bg);
  color: var(--pt-fg);
  font-family: 'Droid Sans', 'Segoe UI', sans-serif;
}

.app-container {
  max-width: 1600px;
  margin: 0 auto;
  padding: 1.5rem 2rem;
}

.app-header {
  background: linear-gradient(135deg, var(--pt-bg-card) 0%, var(--pt-primary-subtle) 100%);
  border-bottom: 4px solid var(--pt-primary);
  padding: 2rem;
  margin-bottom: 2rem;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.10);
}

.card,
.content-card {
  background: var(--pt-bg-card);
  border: 1px solid var(--pt-border);
  border-radius: 12px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.sidebar-panel {
  background: linear-gradient(180deg, var(--pt-primary-subtle) 0%, #FFF9E6 100%);
  border-left: 4px solid var(--pt-primary);
  border-radius: 0 12px 12px 0;
  padding: 1.5rem;
}

.btn-main {
  background: linear-gradient(135deg, var(--pt-primary) 0%, var(--pt-primary-dark) 100%);
  color: var(--pt-secondary);
  border: none;
  border-radius: 8px;
  padding: 0.5rem 1.5rem;
  font-weight: 500;
}

input,
select,
textarea {
  background: var(--pt-bg-card);
  border: 1.5px solid var(--pt-border);
  border-radius: 8px;
  padding: 0.5rem 1rem;
}

input:focus,
select:focus,
textarea:focus {
  border-color: var(--pt-primary);
  box-shadow: 0 0 0 3px rgba(253, 185, 19, 0.3);
  outline: none;
}

.app-footer {
  background: #585858;
  color: white;
  border-top: 4px solid var(--pt-primary);
  padding: 1.5rem 2rem;
}
```
