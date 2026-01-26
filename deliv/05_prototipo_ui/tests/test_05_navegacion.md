# Guía de Uso de Tests - Entregable 05

**Entregable:** 05 - Prototipo estático de interfaz  
**Fecha:** 2026-01-24  
**Versión:** 1.0

---

## Resumen

Esta guía proporciona instrucciones para ejecutar y verificar los tests del prototipo estático de interfaz.

---

## Ejecución de Tests Automatizados

### 1. Ejecutar todos los tests

Desde el directorio `pt_app/`:

```bash
# Opción 1: Usando testthat
Rscript -e "testthat::test_dir('deliv/05_prototipo_ui/tests')"

# Opción 2: Desde R console
library(testthat)
test_dir("deliv/05_prototipo_ui/tests")
```

### 2. Ejecutar un test específico

```r
library(testthat)

test_file("deliv/05_prototipo_ui/tests/test_05_navegacion.R")
```

### 3. Ejecutar tests con filtro

```r
library(testthat)

test_file("deliv/05_prototipo_ui/tests/test_05_navegacion.R", filter = "HTML")
```

---

## Verificación Manual

### Checklist de Revisión Visual

Abrir el archivo `deliv/05_prototipo_ui/html/prototipo.html` en un navegador web y verificar los siguientes aspectos:

#### 1. Estructura General

- [ ] La página carga correctamente sin errores de consola
- [ ] El diseño es responsive (se adapta a diferentes tamaños de pantalla)
- [ ] La barra lateral de navegación es visible
- [ ] La barra superior muestra el título y breadcrumbs
- [ ] El contenido principal se muestra correctamente
- [ ] El footer está visible en la parte inferior

#### 2. Navegación

- [ ] Click en el menú lateral navega entre módulos
- [ ] El breadcrumb se actualiza al navegar
- [ ] Los items del menú activo están resaltados
- [ ] La navegación desde tarjetas de inicio funciona
- [ ] Los botones de atrás (si existen) funcionan

#### 3. Módulo: Inicio

- [ ] Se muestran 3 tarjetas principales (Cargar datos, Informe global, Manual)
- [ ] Click en "Cargar Datos" lleva al módulo de carga
- [ ] Click en "Ver Informe" lleva al Informe global
- [ ] El estado del sistema se muestra correctamente

#### 4. Módulo: Carga de Datos

- [ ] Se muestran 4 bloques de carga de archivos
- [ ] Cada bloque menciona el nombre del archivo CSV correcto:
  - [ ] homogeneity.csv
  - [ ] stability.csv
  - [ ] summary_n4.csv
  - [ ] participants_data4.csv
- [ ] La tabla de validación muestra columnas correctas
- [ ] Los botones de acción son visibles (Validar, Limpiar)
- [ ] Los badges de estado muestran correctamente (Pendiente/Cargado)

#### 5. Módulo: Homogeneidad/Estabilidad

- [ ] Hay pestañas para Homogeneidad y Estabilidad
- [ ] La tabla de resultados tiene las columnas correctas
- [ ] Los badges de estado (Aprobado/Rechazado) son visibles
- [ ] Los placeholders de gráficos están presentes
- [ ] Los filtros por componente están disponibles

#### 6. Módulo: Valores Atípicos

- [ ] Los controles de configuración son funcionales (selects, checkboxes)
- [ ] La tabla de outliers muestra las columnas correctas
- [ ] Los badges de estado (Normal/Outlier/Cuestionable) son visibles
- [ ] El placeholder del scatter plot está presente
- [ ] Los botones de acción están disponibles

#### 7. Módulo: Valor Asignado

- [ ] Los radio buttons para selección de método están presentes
- [ ] Los 4 métodos están listados (1, 2a, 2b, 3)
- [ ] La tabla comparativa muestra todas las columnas
- [ ] El panel de detalle muestra estadísticos del método
- [ ] El gráfico placeholder está presente

#### 8. Módulo: Puntajes PT

- [ ] El selector de tipo de puntaje funciona (z, z', ζ, En)
- [ ] Las KPI cards muestran valores (satisfactorios, cuestionables, etc.)
- [ ] La tabla de puntajes tiene las columnas correctas
- [ ] Los badges de clasificación son visibles
- [ ] El histograma placeholder está presente

#### 9. Módulo: Informe Global

- [ ] El panel de resumen muestra KPIs principales
- [ ] Los 4 placeholders de gráficos están presentes
- [ ] La tabla resumen con colores de fondo está presente
- [ ] Los botones de generación de informes están disponibles
- [ ] El layout de grillas funciona correctamente

#### 10. Módulo: Participantes

- [ ] La caja de búsqueda funciona
- [ ] Los selects de filtro son funcionales
- [ ] La tabla de participantes muestra las columnas correctas
- [ ] Click en una fila muestra el panel de detalle
- [ ] El panel de detalle muestra información completa del participante

#### 11. Módulo: Generación de Informes

- [ ] Los selects de configuración funcionan
- [ ] Los checkboxes de secciones son interactivos
- [ ] El panel de previsualización muestra información
- [ ] La tabla de historial muestra informes anteriores
- [ ] Los botones de acción están disponibles

#### 12. Componentes UI

- [ ] Las tablas tienen cabecera fija al hacer scroll
- [ ] Las filas se resaltan al hacer hover
- [ ] Los botones tienen efectos de hover correctos
- [ ] Los badges de colores son consistentes:
  - [ ] Verde para Satisfactorio/Aprobado
  - [ ] Amarillo para Cuestionable/Revisión
  - [ ] Rojo para No satisfactorio/Rechazado
  - [ ] Azul para Informativo
- [ ] Los inputs y selects tienen estilos consistentes
- [ ] Las cards tienen sombra y bordes correctos
- [ ] Las grids se distribuyen correctamente

#### 13. Estilos CSS

- [ ] La paleta de colores es consistente:
  - [ ] Primario: #0056b3 (azul)
  - [ ] Éxito: #28a745 (verde)
  - [ ] Advertencia: #ffc107 (amarillo)
  - [ ] Error: #dc3545 (rojo)
- [ ] La tipografía es legible
- [ ] El espaciado es consistente
- [ ] Los bordes y sombras están bien aplicados

#### 14. JavaScript

- [ ] La navegación entre módulos funciona sin recargar la página
- [ ] Los event listeners están correctamente configurados
- [ ] Los cambios de tabs funcionan correctamente
- [ ] Los checkboxes y radio buttons responden a cambios
- [ ] No hay errores en la consola del navegador

#### 15. Accesibilidad

- [ ] Los elementos interactivos tienen cursor apropiado
- [ ] Los inputs tienen labels asociados
- [ ] Los colores tienen buen contraste
- [ ] La estructura semántica es correcta (headings, nav, etc.)

---

## Verificación de Archivos

### Estructura de Directorios

Verificar que existen los siguientes directorios y archivos:

```
deliv/05_prototipo_ui/
├── md/
│   └── wireframes.md
├── html/
│   └── prototipo.html
├── mmd/
│   └── diagrama_navegacion.mmd
└── tests/
    ├── test_05_navegacion.R
    └── test_05_navegacion.md
```

### Contenido de wireframes.md

- [ ] Documentación de los 9 módulos de UI
- [ ] Descripción de elementos de cada módulo
- [ ] Patrones de UI consistentes documentados
- [ ] Sección de responsividad incluida
- [ ] Sección de accesibilidad incluida
- [ ] Referencias de diseño documentadas

### Contenido de prototipo.html

- [ ] HTML5 válido con DOCTYPE
- [ ] Estructura completa: head, body, footer
- [ ] Todos los 11 módulos implementados
- [ ] CSS en línea incluido
- [ ] JavaScript para navegación incluido
- [ ] Placeholders para gráficos presentes

### Contenido de diagrama_navegacion.mmd

- [ ] Diagrama de tipo flowchart
- [ ] Nodos de todos los módulos principales
- [ ] Nodos de decisión ({})
- [ ] Flechas de navegación (-->)
- [ ] Estilos aplicados a nodos
- [ ] Flujo lógico completo (Inicio → Fin)

---

## Resultados Esperados de Tests

### Tests Automatizados

Al ejecutar `testthat::test_dir("deliv/05_prototipo_ui/tests")`, se esperan los siguientes resultados:

| Test | Descripción | Resultado esperado |
|------|-------------|-------------------|
| archivo HTML existe | Verifica existencia de prototipo.html | PASS |
| estructura basica valida | Verifica DOCTYPE, html, head, body | PASS |
| barra lateral con modulos | Verifica 11 módulos en menú | PASS |
| secciones modulos principales | Verifica ids de módulos | PASS |
| modulo Carga Datos | Verifica archivos CSV mencionados | PASS |
| elementos UI esperados | Verifica tablas, botones, inputs | PASS |
| estilos CSS en linea | Verifica tags style y clases | PASS |
| JavaScript navegacion | Verifica event listeners | PASS |
| barra superior | Verifica título y navegación | PASS |
| componentes cards | Verifica cards, headers, KPIs | PASS |
| placeholders graficos | Verifica chart-placeholders | PASS |
| wireframes.md existe | Verifica archivo documentación | PASS |
| modulos documentados | Verifica 9 módulos en docs | PASS |
| diagrama_navegacion.mmd existe | Verifica archivo mermaid | PASS |
| estructura mermaid valida | Verifica flowchart y nodos | PASS |
| nodos decision | Verifica nodos diamante y flechas | PASS |
| estructura directorios | Verifica 5 directorios creados | PASS |

**Total esperado:** 18/18 PASS

---

## Troubleshooting

### Errores Comunes

#### 1. Tests fallan por rutas incorrectas

**Problema:** Los tests no encuentran los archivos

**Solución:** 
- Asegurarse de ejecutar desde el directorio `pt_app/`
- Verificar que la estructura de directorios es correcta
- Usar `setwd("../..")` en el código si es necesario

#### 2. El HTML no se visualiza correctamente

**Problema:** El prototipo.html no se ve bien en el navegador

**Solución:**
- Abrir directamente el archivo en un navegador moderno (Chrome, Firefox, Edge)
- Verificar que no hay extensiones del navegador interfiriendo
- Revisar la consola del navegador para errores de JavaScript

#### 3. La navegación no funciona

**Problema:** Click en el menú no cambia de módulo

**Solución:**
- Verificar que JavaScript está habilitado en el navegador
- Revisar la consola para errores de JavaScript
- Verificar que los atributos `data-module` coinciden con los `id` de los módulos

#### 4. El diagrama Mermaid no se renderiza

**Problema:** No se puede visualizar el diagrama de navegación

**Solución:**
- Usar un editor con soporte Mermaid (VS Code, GitHub, etc.)
- Instalar extensión "Mermaid Preview" en VS Code
- Copiar el contenido en un visualizador online como https://mermaid.live

---

## Próximos Pasos

Una vez completada la verificación de este entregable:

1. **Continuar con Fase 4** - Desarrollo de App (Entregables 6-7)
2. Usar el prototipo HTML como referencia para implementar la UI en Shiny
3. Adaptar los estilos CSS a bslib en R/Shiny
4. Implementar la lógica de navegación en el servidor Shiny

---

## Referencias

- **bslib documentation:** https://rstudio.github.io/bslib/
- **Mermaid syntax:** https://mermaid-js.github.io/mermaid/
- **Shiny UI patterns:** https://shiny.rstudio.com/articles/layout-guide.html
- **WCAG Accessibility:** https://www.w3.org/WAI/WCAG21/quickref/

---

*Documento generado: 2026-01-24*
