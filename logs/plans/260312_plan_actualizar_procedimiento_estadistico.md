# Plan: Actualizar P-PSEA-06 Procedimiento Diseño Estadístico v0

## Context

El documento `P-PSEA-06 Procedimiento Diseño Estadistico_v0.docx` es el procedimiento oficial de diseño estadístico para Ensayos de Aptitud de CALAIRE. Fue redactado de forma general, pero la implementación real en `pt_app` y `ptcalc` contiene detalles técnicos precisos (factores numéricos, tolerancias, fórmulas exactas) que **no están reflejados en el documento**. Se requiere alinear el procedimiento con el código validado.

## Discrepancias identificadas

| # | Sección en documento | Problema | Valor documento | Valor implementado |
|---|---------------------|----------|-----------------|-------------------|
| 1 | Métodos robustos - MADe | Factor de escalado: redondeo diferente al código | 1.4826 (5 cifras) | 1.483 (4 cifras, usado en código R) |
| 2 | Algoritmo A | Falta factor 1.134 en actualización de s* | No mencionado | 1.134 × DESVEST(winzorizados) |
| 3 | Algoritmo A | Criterio de convergencia vago | "tres cifras significativas" | tolerancia = 1×10⁻⁴ en app.R (default función: 1×10⁻⁶) |
| 4 | Referencia normativa | Año ISO incorrecto | ISO 13528:**2023** | ISO 13528:**2022** |
| 5 | Puntajes de desempeño | Faltan criterios de evaluación | No definidos | \|z\| ≤ 2 satisfactorio / 2<\|z\|<3 cuestionable / \|z\| ≥ 3 no satisfactorio |
| 6 | Incertidumbre xpt | Fórmula incompleta | u(xpt) = 1.25 × s*/√p solamente | u(xpt,def) = √(u_xpt² + u_hom² + u_stab²) |
| 7 | Evaluación de puntajes En | Criterio distinto | No definido | \|En\| ≤ 1 satisfactorio / \|En\| > 1 no satisfactorio |

## Archivos críticos

- **Documento a actualizar:** `P-PSEA-06 Procedimiento Diseño Estadistico_v0.docx`
- **Implementación referencia:** `R/pt_robust_stats.R` (líneas 33-304)
- **Funciones consolidadas:** `deliv/08_beta/R/funciones_finales.R`
- **Guía técnica validada:** `validation/GUIA_VALIDACION_ALGORITMO_A.md`

## Implementación

El documento de salida será **Markdown** (`.md`) para facilitar el renderizado de fórmulas LaTeX. Se usa el .docx solo como fuente de contenido.

1. **Extraer** el texto del .docx (estructura ya conocida)
2. **Crear** `P-PSEA-06 Procedimiento Diseño Estadistico_v1.md` con estructura Markdown completa
3. **Aplicar correcciones** durante la escritura:

### Corrección 1 — Factor MADe (sección "Métodos Robustos")
- Cambiar `1.4826` → `1.483`
- Texto actual: `s* = 1.4826 × mediana(|xᵢ − x*|)`
- Texto nuevo: `s* = 1.483 × mediana(|xᵢ − x*|)`

### Corrección 2 — Algoritmo A: fórmula actualización de s*
- Agregar en la descripción del Algoritmo A, paso de actualización:
  - `x* = (1/p) × Σ xᵢ*` (media aritmética de winzorizados)
  - `s* = 1.134 × √[(1/(p−1)) × Σ(xᵢ* − x*)²]`
- Agregar nota: "El factor **1.134** corrige el sesgo introducido por la winsorización al truncar la distribución."

### Corrección 3 — Criterio de convergencia del Algoritmo A
- Reemplazar: "hasta estabilización en tres cifras significativas"
- Por: "hasta que `max(|Δx*|, |Δs*|) < 1×10⁻⁴`" con máximo 50 iteraciones

### Corrección 4 — Referencia normativa
- Reemplazar: `ISO 13528:2023` → `ISO 13528:2022`
  (aplica en OBJETIVO y en sección de referencias)

### Corrección 5 — Criterios de evaluación de puntajes
- Agregar tabla de criterios después de las fórmulas de puntajes:

| Puntaje z, z', ζ | Interpretación |
|---|---|
| \|z\| ≤ 2 | Satisfactorio |
| 2 < \|z\| < 3 | Cuestionable |
| \|z\| ≥ 3 | No satisfactorio |

| Puntaje En | Interpretación |
|---|---|
| \|En\| ≤ 1 | Satisfactorio |
| \|En\| > 1 | No satisfactorio |

### Corrección 6 — Incertidumbre combinada del valor asignado
- Agregar después de `u(xpt) = 1.25 × s*/√p`:
  - "La incertidumbre definitiva combina la incertidumbre estadística con las contribuciones por homogeneidad y estabilidad:"
  - `u(xpt,def) = √(u_xpt² + u_hom² + u_stab²)`
  - donde `u_hom = ss` (desviación entre ítems) y `u_stab = 0 si Δ ≤ 0.3σpt, u_stab = Δ/√3 si Δ > 0.3σpt`

### Corrección 7 — Mención de ptcalc
- En la sección "Validación del Diseño Estadístico", reemplazar:
  - "software validado (R o Python)"
  - Por: "el paquete R `ptcalc` (CALAIRE / UNAL-INM), validado contra hojas de cálculo de referencia ISO 13528:2022 Anexo C"

4. **Guardar** como `P-PSEA-06 Procedimiento Diseño Estadistico_v1.md`

### Formato Markdown

- Fórmulas inline con `$...$` y bloque con `$$...$$`
- Tablas en Markdown estándar GFM
- Secciones numeradas con `##` y `###`
- Código R en bloques ` ```r ` donde aplique

## Ajustes pendientes en v1.md

Las 7 correcciones estadísticas originales ya fueron aplicadas en v1.md. Quedan ajustes de **estructura documental** y **contenido faltante**:

### Ajuste A — Estructura general del documento

Restaurar la agrupación del v0:

```
INFORMACIÓN GENERAL DEL PROCEDIMIENTO
  1. Objetivo
  2. Alcance
  3. Definiciones          ← cambiar de prosa a bullet points
  4. Documentos de referencia
  5. Condiciones generales ← sección omitida en v1, agregar (puede quedar vacía o con texto base)

INFORMACIÓN ESPECÍFICA DEL PROCEDIMIENTO
  6. Roles y responsabilidades  ← restaurar formato TABLA (Cargo | Responsabilidad)
  7. Desarrollo del diseño estadístico
     7.1 ... (subsecciones técnicas actuales)
  ...
```

### Ajuste B — Definiciones (§4): de prosa a bullet points

v1 actual: párrafo largo en prosa.
Cambiar a lista con viñetas, un ítem por símbolo/término:

- $x_{pt}$: valor asignado al mensurando...
- $\sigma_{pt}$: desviación estándar para evaluación...
- $u(x_{pt})$: incertidumbre estándar...
- $u(x_{pt},def)$: incertidumbre definitiva...
- $u_{hom}$: contribución por homogeneidad
- $u_{stab}$: contribución por estabilidad
- $p$: número de participantes válidos
- $x^*$, $s^*$: estimadores robustos (Algoritmo A)

### Ajuste C — Tabla de responsabilidades (§5): de prosa a tabla

v0 tiene tabla con 4 filas (Cargo | Responsabilidad). v1 lo convirtió en prosa.
Restaurar formato tabla Markdown:

| Cargo | Responsabilidad |
|-------|----------------|
| Estadístico / Experto técnico | Diseñar modelo estadístico, calcular valores... |
| Coordinador EA | Aprobar diseño, verificar conformidad... |
| Ingeniero Operativo | Garantizar condiciones técnicas... |
| Profesional de Calidad | Controlar documentación, trazabilidad... |

### Ajuste D — Subsecciones "Desarrollo del Diseño Estadístico"

v0 tiene dos subsecciones introductorias antes de entrar en lo técnico que v1 absorbió/diluyó:

**D.1 — "Definición de los Objetivos"**
Lista de propósitos del EA (bullet points):
- Evaluar el desempeño de los laboratorios.
- Comparar métodos o equipos de medición.
- Validar la precisión y trazabilidad de resultados.
- Determinar sesgos o tendencias sistemáticas.

v1 §6 ("Criterios generales para la selección del método") cubre algo similar pero en prosa y mezclado con selección de método. Restaurar como subsección separada con los bullets explícitos.

**D.2 — "Selección del Tipo de Datos y Número de Participantes"**
v0 tiene bullet points concretos:
- Datos cuantitativos en unidades de concentración (nmol/mol, µmol/mol — ppb, ppm).
- Distribución esperada: aproximadamente normal (posible transformación logarítmica si hay asimetría).
- Número mínimo de participantes: **12**.
- Si $p \geq 12$: media robusta (Algoritmo A).
- Si $p < 12$: mediana como valor asignado.

v1 no tiene esta información como sección separada. Agregar como subsección bajo "Desarrollo del Diseño Estadístico".

### Ajuste E — Sección "Condiciones Generales"

Omitida en v1. Agregar sección (vacía en v0 original, pero debe existir como placeholder o con contenido base según el sistema documental).

### Ajuste F — Fórmulas de homogeneidad (§13 → expandir con subsecciones)

v0 incluye las fórmulas ANOVA y el código `R/pt_homogeneity.R` las implementa.
v1 §13 solo describe en prosa sin fórmulas. Agregar:

1. Media por ítem: $\bar{x}_i = (1/m) \sum_j x_{ij}$
2. Varianza entre medias: $s_{\bar{x}}^2 = (1/(g-1)) \sum (\bar{x}_i - \bar{\bar{x}})^2$
3. Desviación dentro de ítem (m=2): $s_w = \sqrt{(1/2g) \sum (x_{i1} - x_{i2})^2}$
4. Componente entre ítems: $s_s^2 = s_{\bar{x}}^2 - s_w^2/m$ (si $s_s^2 < 0$, $s_s = 0$)
5. Criterio básico: $s_s \leq 0.3\,\sigma_{pt}$
6. Criterio expandido: $MS_b \leq F_1(0.3\sigma_{pt})^2 + F_2\,MS_w$ (factores tabulados ISO 13528:2022 Tabla 4)

**Fuente:** `R/pt_homogeneity.R` líneas 45-121

### Ajuste G — Fórmulas de estabilidad (§13 → expandir con subsecciones)

v0 incluye el criterio explícito. Agregar:

1. Diferencia media: $\Delta = |\bar{y}_1 - \bar{y}_2|$
2. Criterio: $\Delta \leq 0.3\,\sigma_{pt}$
3. Vincular con $u_{stab}$ definido en §12.2

**Fuente:** `R/pt_homogeneity.R` líneas 215-406

### Ajuste H — Bloque de firmas al final

v0 tiene campos REVISÓ / APROBÓ / ROL / FECHA. Agregar al final de v1.

## Verificación

1. Renderizar `v1.md` en un visor Markdown (VS Code / GitHub) y confirmar que todas las fórmulas se muestran correctamente
2. Verificar que el factor `1.134` aparece en el paso de actualización de s* del Algoritmo A
3. Confirmar que la tolerancia es `1×10⁻⁴` y máximo 50 iteraciones
4. Confirmar año ISO 13528:**2022**
5. Confirmar que la tabla de criterios z y En está presente
6. Confirmar referencia a `ptcalc` en la sección de validación
