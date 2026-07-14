# Wireframes - Prototipo de Interfaz PT

**Entregable:** 05 - Prototipo estático de interfaz  
**Fecha:** 2026-01-24  
**Versión:** 1.0

---

## 1. Pantalla de Inicio

**Descripción:**
Pantalla de bienvenida con información general del sistema y acceso rápido a funciones principales.

**Elementos UI:**
- Encabezado con logo y título "Análisis PT - ISO 13528:2022"
- Menú lateral de navegación (barra lateral izquierda)
- Contenido principal:
  - Tarjeta de resumen: "Cargar datos" (acción principal)
  - Tarjeta de estado: "Sesión activa"
  - Tarjeta de ayuda: "Manual de usuario"
- Pie de página con información de versión y contacto

**Interacciones:**
- Click en "Cargar datos" → navega a módulo de carga de datos
- Click en elementos del menú → navegación correspondiente
- Hover en tarjetas → efecto visual de selección

---

## 2. Módulo de Carga de Datos

**Descripción:**
Permite cargar y validar los archivos CSV requeridos para el análisis PT.

**Elementos UI:**
- Título de sección: "Carga de Datos"
- Cuatro bloques de carga de archivos:
  1. **Archivo de homogeneidad** (`homogeneity.csv`)
     - FileInput para selección
     - Estado: "Cargado" / "Pendiente"
     - Botón de vista previa
  
  2. **Archivo de estabilidad** (`stability.csv`)
     - FileInput para selección
     - Estado: "Cargado" / "Pendiente"
     - Botón de vista previa
  
  3. **Archivo de participantes** (`summary_n4.csv`)
     - FileInput para selección
     - Estado: "Cargado" / "Pendiente"
     - Botón de vista previa
  
  4. **Archivo de instrumentación** (`participants_data4.csv`)
     - FileInput para selección
     - Estado: "Cargado" / "Pendiente"
     - Botón de vista previa

- Panel de validación:
  - Indicador de estado global: "✓ Todos los archivos cargados" o "✗ Archivos faltantes"
  - Tabla de validación con columnas:
    - Archivo
    - Estado (OK/Error)
    - Filas
    - Columnas
    - Tamaño (KB)
  
- Botones de acción:
  - "Validar y continuar" (habilitado solo cuando todos los archivos están OK)
  - "Limpiar todo" (restablece selección)
  - "Usar datos de ejemplo" (carga los 4 CSV de `data/`)

**Interacciones:**
- Arrastrar y soltar archivos en área de carga
- Click en "Vista previa" → muestra modal con primeras 10 filas del CSV
- Click en "Validar y continuar" → valida estructura, navega a módulo siguiente si OK

---

## 3. Módulo de Homogeneidad y Estabilidad

**Descripción:**
Muestra resultados del análisis de homogeneidad y estabilidad de las muestras.

**Elementos UI:**
- Título de sección: "Homogeneidad y Estabilidad"
- Pestañas:
  1. **Pestaña Homogeneidad**
     - Tabla de resultados:
       - Columna: Componente (CO, CO2, etc.)
       - Columna: Nivel
       - Columna: ss (suma de cuadrados entre muestras)
       - Columna: sw (varianza dentro de muestras)
       - Columna: c (criterio 0.3 × σ_pt)
       - Columna: Estado (Aprobado/Rechazado)
     - Gráfico placeholder para visualización de varianzas
     - Filtros por componente y nivel
  
  2. **Pestaña Estabilidad**
     - Tabla de resultados:
       - Columna: Componente
       - Columna: Diferencia de medias
       - Columna: Criterio
       - Columna: Estado (Estable/Inestable)
     - Gráfico placeholder para tendencia temporal
     - Filtros por componente

- Panel de resumen:
  - Contador: "X componentes aprobados de Y total"
  - Indicador visual: semáforo (verde/amarillo/rojo)
  - Botón "Descargar reporte PDF"

**Interacciones:**
- Click en fila de tabla → detalle del análisis completo
- Hover en gráficos → tooltips con valores
- Click en "Descargar reporte" → descarga PDF con análisis completo

---

## 4. Módulo de Valores Atípicos

**Descripción:**
Identificación y análisis de outliers en los datos de participantes.

**Elementos UI:**
- Título de sección: "Valores Atípicos"
- Controles de configuración:
  - Select: Método de detección (Algoritmo A / Tukey / Grubbs)
  - Slider: Nivel de significancia (α = 0.01, 0.05, 0.10)
  - Checkbox: Incluir/Excluir outliers en cálculos posteriores
  - Select: Componente a analizar
  - Select: Nivel a analizar

- Tabla de resultados:
  - Columna: Participante (ID)
  - Columna: Valor reportado
  - Columna: Valor ajustado (si aplica)
  - Columna: Z-score
  - Columna: Estado (Normal/Outlier)
  - Columna: Razón (motivo del marcado)

- Gráfico placeholder:
  - Scatter plot de valores vs participantes
  - Puntos outliers resaltados en rojo
  - Línea de referencia (media asignada)

- Panel de acciones:
  - Botón "Aplicar filtros"
  - Botón "Restaurar datos originales"
  - Botón "Exportar outliers"

**Interacciones:**
- Cambio en select/checkbox → recálculo automático
- Click en punto del gráfico → detalle del participante
- Toggle checkbox → actualiza tabla y gráfico

---

## 5. Módulo de Valor Asignado

**Descripción:**
Selección y visualización del valor asignado según diferentes métodos ISO 13528.

**Elementos UI:**
- Título de sección: "Valor Asignado"
- Panel de selección de método:
  - Radio buttons:
    - Método 1: Valor de referencia (certificado)
    - Método 2a: Consenso robusto con MADe
    - Método 2b: Consenso robusto con nIQR
    - Método 3: Algoritmo A

- Tabla comparativa:
  - Filas: Componentes y niveles
  - Columnas:
    - Método 1 (x_pt)
    - Método 2a (x_pt)
    - Método 2b (x_pt)
    - Método 3 (x_pt)
    - Método seleccionado (resaltado)
  
- Panel de detalle:
  - Gráfico placeholder: Comparación visual de métodos
  - Tabla de estadísticos del método seleccionado:
    - Valor asignado
    - Desviación estándar (σ_pt)
    - Número de participantes
    - Coeficiente de variación
    - Intervalo de confianza

- Acciones:
  - Select: Componente a detallar
  - Select: Nivel a detallar
  - Botón "Confirmar selección"
  - Botón "Exportar tabla comparativa"

**Interacciones:**
- Selección de método → actualiza tabla y gráfico
- Click en celda de tabla → resalta método correspondiente
- Cambio de componente/nivel → actualiza panel de detalle

---

## 6. Módulo de Puntajes PT

**Descripción:**
Cálculo y visualización de puntajes z, z', ζ, En para cada participante.

**Elementos UI:**
- Título de sección: "Puntajes PT"
- Panel de configuración:
  - Select: Tipo de puntaje (z / z' / ζ / En)
  - Select: Componente
  - Select: Nivel
  - Checkbox: Incluir solo outliers destacados

- Tabla principal:
  - Columnas:
    - ID Participante
    - Valor reportado
    - x_pt (valor asignado)
    - σ_pt / u (incertidumbre)
    - Puntaje calculado
    - Clasificación (Satisfactorio / Cuestionable / No satisfactorio)
    - Badge de color según clasificación

- Resumen estadístico:
  - Cards: Total satisfactorios, cuestionables, no satisfactorios
  - Gráfico placeholder: Histograma de puntajes
  - Líneas de referencia: z = ±2, z = ±3

- Acciones:
  - Botón "Descargar CSV de puntajes"
  - Botón "Generar reporte individual"
  - Botón "Comparar con ciclo anterior"

**Interacciones:**
- Cambio de tipo de puntaje → recálculo completo
- Click en fila de tabla → detalle completo del participante
- Hover en histograma → distribución por clasificación

---

## 7. Módulo de Informe Global

**Descripción:**
Dashboard consolidado con métricas generales del estudio de aptitud.

**Elementos UI:**
- Título de sección: "Informe Global"
- Panel de KPIs (Key Performance Indicators):
  - Card 1: Total participantes
  - Card 2: Tasa de éxito global (% satisfactorios)
  - Card 3: Componente con mejor desempeño
  - Card 4: Componente con más problemas

- Gráficos placeholder:
  1. Heatmap de puntajes por componente y participante
  2. Gráfico de barras de satisfacción por nivel
  3. Radar chart de desempeño por componente
  4. Línea de tendencia temporal (si hay datos históricos)

- Tabla resumen:
  - Filas: Componentes
  - Columnas: Niveles
  - Valores: % de resultados satisfactorios
  - Formato: tabla con color de fondo (escala verde-rojo)

- Acciones:
  - Select: Período de tiempo
  - Botón "Generar reporte completo"
  - Botón "Descargar executive summary"
  - Botón "Exportar a PowerPoint"

**Interacciones:**
- Hover en heatmap → valores detallados
- Click en barra de gráfico → filtro por nivel
- Selección de período → actualización de todos los gráficos

---

## 8. Módulo de Participantes

**Descripción:**
Gestión y análisis individual de cada participante.

**Elementos UI:**
- Título de sección: "Participantes"
- Panel de búsqueda y filtrado:
  - Input: Buscar por ID o nombre
  - Select: Filtro por estado de desempeño (Todos / Satisfactorio / Cuestionable / No satisfactorio)
  - Select: Filtro por componente
  
- Tabla de participantes:
  - Columnas:
    - ID Participante
    - Institución
    - Instrumento
    - Estado global (badge color)
    - Puntajes por componente (z, z', ζ, En)
    - Tendencia histórico (flecha arriba/abajo)
  - Paginación: 10 filas por página

- Panel de detalle del participante:
  - Selecciona un participante de la tabla
  - Muestra:
    - Información general
    - Tabla detallada de puntajes
    - Gráficos individuales:
      - Radar chart de desempeño
      - Línea de tendencia en ciclos anteriores
    - Recomendaciones según ISO 13528

- Acciones:
  - Botón "Generar reporte individual PDF"
  - Botón "Enviar correo al participante"
  - Botón "Comparar con pares"

**Interacciones:**
- Búsqueda en tiempo real → filtro de tabla
- Click en fila → despliega panel de detalle
- Click en recomendación → expande detalles

---

## 9. Módulo de Generación de Informes

**Descripción:**
Configuración y generación de informes automatizados.

**Elementos UI:**
- Título de sección: "Generación de Informes"
- Panel de configuración:
  - Select: Tipo de informe
    - Resumen ejecutivo
    - Reporte completo por componente
    - Reporte individual por participante
    - Análisis estadístico detallado
    - Informe de conformidad ISO 17043
  
  - Select: Formato de salida
    - PDF
    - Word (DOCX)
    - HTML
    - Excel (XLSX)
  
  - Checkboxes: Secciones a incluir
    - [x] Resumen ejecutivo
    - [x] Tablas de resultados
    - [x] Gráficos
    - [ ] Anexos técnicos
    - [ ] Cálculos paso a paso
    - [ ] Referencias normativas

- Panel de previsualización:
  - Miniatura de primera página del informe
  - Lista de contenido del informe
  - Estimación de tamaño del archivo

- Acciones:
  - Botón "Generar informe"
  - Botón "Programar generación automática"
  - Botón "Enviar por correo electrónico"
  - Botón "Guardar configuración como plantilla"

- Historial de informes:
  - Tabla: Informes generados previamente
  - Columnas: Fecha, Tipo, Formato, Tamaño, Acciones (Descargar / Regenerar)

**Interacciones:**
- Selección de secciones → actualiza vista previa
- Click en "Generar" → barra de progreso, then notificación
- Click en histórico → descarga o regenera informe

---

## Estructura General de Navegación

### Barra Lateral (Menú Principal)

Elementos del menú (orden de arriba a abajo):
1. 📊 **Inicio** (icono dashboard)
2. 📁 **Carga de Datos** (icono folder)
3. 🧪 **Homogeneidad/Estabilidad** (icono flask)
4. 🔍 **Valores Atípicos** (icono search)
5. 📈 **Valor Asignado** (icono chart)
6. 🎯 **Puntajes PT** (icono target)
7. 📋 **Informe Global** (icono clipboard)
8. 👥 **Participantes** (icono users)
9. 📄 **Generación de Informes** (icono file)
10. ⚙️ **Configuración** (icono settings)
11. ❓ **Ayuda** (icono question)

### Barra Superior

Elementos (de izquierda a derecha):
- Título del módulo actual
- Breadcrumb de navegación: "Inicio > Módulo actual"
- Selector de idioma (ES/EN)
- Botón de modo oscuro/claro
- Notificaciones 🔔
- Perfil de usuario 👤

---

## Patrones de UI Consistentes

### Botones
- **Primario:** Azul, acción principal del módulo
- **Secundario:** Gris claro, acciones alternativas
- **Terciario:** Solo texto (link), acciones secundarias
- **Peligro:** Rojo, acciones destructivas (eliminar, limpiar)

### Badges
- **Verde:** Satisfactorio / Aprobado
- **Amarillo:** Cuestionable / Revisión requerida
- **Rojo:** No satisfactorio / Rechazado
- **Azul:** Informativo / En proceso

### Tablas
- Cabecera fija al hacer scroll
- Filas alternadas con color de fondo
- Hover: resaltado de fila
- Sortable: click en cabecera para ordenar
- Filtrable: campo de búsqueda sobre tabla

### Gráficos
- Título descriptivo
- Leyenda con colores
- Tooltips al hover
- Zoom/parrilla (cuando aplica)
- Botón de descarga

### Modales
- Overlay semitransparente
- Contenido centrado
- Botón de cerrar (X) en esquina
- Acciones: "Confirmar" (primario), "Cancelar" (secundario)

### Mensajes de Estado
- **Success:** Barra verde superior, "Operación completada exitosamente"
- **Warning:** Barra amarilla, "Advertencia: revise los datos"
- **Error:** Barra roja, "Error: archivo no válido"
- **Info:** Barra azul, "Procesando..."

---

## Responsividad

### Escritorio (≥ 1024px)
- Menú lateral fijo visible
- 2-3 columnas de contenido
- Tablas completas sin scroll horizontal

### Tablet (768px - 1023px)
- Menú lateral colapsable (botón hamburguesa)
- 1-2 columnas de contenido
- Tablas con scroll horizontal

### Móvil (< 768px)
- Menú lateral en drawer (deslizable)
- 1 columna de contenido
- Tablas convertidas a cards
- Gráficos adaptados

---

## Accesibilidad

### Contraste de Colores
- Ratio mínimo 4.5:1 para texto normal
- Ratio mínimo 3:1 para texto grande (≥ 18pt)
- Iconos con etiquetas alternativas (aria-label)

### Navegación por Teclado
- Tab: Navegación entre elementos interactivos
- Enter/Space: Activar botones y checkboxes
- Esc: Cerrar modales
- Arriba/Abajo: Navegación en listas y selects

### Lectores de Pantalla
- Atributos ARIA en elementos interactivos
- Estructura semántica (headings, landmarks)
- Textos alternativos en imágenes y gráficos

---

## Referencias de Diseño

- **Framework de UI:** bslib (Bootstrap 5) en Shiny
- **Paleta de colores:**
  - Primario: #0056b3 (azul)
  - Éxito: #28a745 (verde)
  - Advertencia: #ffc107 (amarillo)
  - Error: #dc3545 (rojo)
  - Info: #17a2b8 (azul claro)
  - Neutro: #6c757d (gris)
  
- **Tipografía:**
  - Fuente: Roboto (o sistema)
  - Títulos: Bold, 24-32px
  - Texto normal: Regular, 14-16px
  - Monospace: 12px (para datos técnicos)

- **Iconografía:**
  - Conjunto: Font Awesome (o equivalente)
  - Tamaño: 16-24px
  - Uso consistente por función

---

## Estado del Prototipo

## Evidencia visual de la implementación vigente

![CAP-01. Pantalla vigente de carga de
datos.](../../00_evidencia_visual/capturas/CAP-01_inicio_carga.png)

**Figura CAP-01.** Implementación observada, diferenciada del prototipo
histórico descrito en este documento. CAP-03 muestra el preprocesador y CAP-19
la vista de 1024 × 768; metadatos y hashes están en el índice común.

- **Completado:** 9 módulos documentados
- **Porcentaje de avance:** 100%
- **Siguiente paso:** Crear HTML estático y diagramas de navegación

---

*Documento generado: 2026-01-24*
