# Guía de Verificación - Gráficos (Entregable 07)

**Fecha:** 2026-01-24  
**Versión:** 07 - Dashboards con Gráficos Dinámicos  
**Entregable:** 07

---

## Tabla de Contenidos

1. [Objetivo de la Verificación](#objetivo-de-la-verificación)
2. [Gráficos Implementados](#gráficos-implementados)
3. [Criterios de Verificación](#criterios-de-verificación)
4. [Procedimiento de Prueba](#procedimiento-de-prueba)
5. [Resultados Esperados](#resultados-esperados)

---

## Objetivo de la Verificación

Verificar que los gráficos implementados en `app_v07.R` funcionen correctamente, proporcionando visualizaciones interactivas de los datos y resultados de puntajes PT.

---

## Gráficos Implementados

### 1. Histograma por Nivel

**Ubicación:** Pestaña "Gráficos - Distribución"

**Descripción:** Muestra la distribución de valores medios de todos los participantes para el analito y nivel seleccionados.

**Elementos:**
- Eje X: Valor medio
- Eje Y: Frecuencia
- Barras: 20 bins por defecto
- Colores: Steel blue con opacidad 0.7
- Interactividad: Zoom, pan, tooltips (Plotly)

**Uso esperado:** Identificar la forma de distribución de los resultados y detectar posibles valores atípicos visuales.

### 2. Boxplot por Participante

**Ubicación:** Pestaña "Gráficos - Distribución"

**Descripción:** Muestra la distribución de valores medios por cada participante.

**Elementos:**
- Eje X: ID Participante
- Eje Y: Valor medio
- Cajas: Boxplot estándar (cuartiles, mediana, bigotes)
- Colores: Diferente por participante
- Interactividad: Zoom, pan, tooltips (Plotly)

**Uso esperado:** Comparar la dispersión de resultados entre participantes.

### 3. Heatmap de Puntajes z

**Ubicación:** Pestaña "Gráficos - Puntajes"

**Descripción:** Visualización matricial de los puntajes z por participante.

**Elementos:**
- Eje X: ID Participante
- Eje Y: Única fila
- Celdas: Tiles coloreados según valor de puntaje z
- Escala de colores: Rojo (negativo) → Blanco (0) → Azul (positivo)
- Interactividad: Zoom, tooltips (Plotly)

**Uso esperado:** Identificar rápidamente participantes con puntajes extremos.

### 4. Gráfico de Barras de Evaluación

**Ubicación:** Pestaña "Gráficos - Puntajes"

**Descripción:** Conteo de participantes por categoría de evaluación (z-score).

**Elementos:**
- Eje X: Categoría de evaluación (Satisfactorio, Cuestionable, No satisfactorio, N/A)
- Eje Y: Cantidad de participantes
- Barras: Barras verticales
- Colores por categoría:
  - Satisfactorio: Verde (#4CAF50)
  - Cuestionable: Amarillo (#FFC107)
  - No satisfactorio: Rojo (#F44336)
  - N/A: Gris (#9E9E9E)
- Interactividad: Zoom, tooltips (Plotly)

**Uso esperado:** Ver rápidamente el número de participantes en cada categoría de desempeño.

### 5. Comparación de Puntajes

**Ubicación:** Pestaña "Gráficos - Comparación"

**Descripción:** Gráfico de barras agrupadas mostrando los cuatro tipos de puntajes (z, z', zeta, En) para cada participante.

**Elementos:**
- Eje X: ID Participante
- Eje Y: Valor del puntaje
- Barras: Agrupadas por tipo de puntaje
- Líneas de referencia: ±2 (líneas punteadas grises)
- Interactividad: Zoom, pan, tooltips (Plotly)

**Uso esperado:** Comparar los diferentes puntajes para cada participante y ver cómo cambian según el método.

### 6. Diagrama de Dispersión vs Valor Asignado

**Ubicación:** Pestaña "Gráficos - Comparación"

**Descripción:** Gráfico de dispersión de valores de participantes vs valor asignado, coloreado por evaluación z-score.

**Elementos:**
- Eje X: Valor asignado (x_pt)
- Eje Y: Valor medio del participante
- Puntos: Cada participante
- Línea diagonal: y = x (línea de referencia)
- Colores: Por categoría de evaluación z-score
- Interactividad: Zoom, pan, tooltips (Plotly)

**Uso esperado:** Visualizar qué participantes están por encima o por debajo del valor asignado y su evaluación.

---

## Criterios de Verificación

### Verificación Funcional

| Gráfico | Criterio | Estado Esperado |
|---------|-----------|-----------------|
| Histograma | Se renderiza sin errores | ✓ |
| Boxplot | Se renderiza sin errores | ✓ |
| Heatmap | Se renderiza sin errores | ✓ |
| Barras | Se renderiza sin errores | ✓ |
| Comparación | Se renderiza sin errores | ✓ |
| Dispersión | Se renderiza sin errores | ✓ |
| Todos | Interactividad de Plotly funciona | ✓ |
| Todos | Tooltips muestran datos correctos | ✓ |

### Verificación de Datos

| Gráfico | Verificación | Estado Esperado |
|---------|--------------|-----------------|
| Histograma | Muestra todos los registros filtrados | ✓ |
| Boxplot | Muestra todos los participantes | ✓ |
| Heatmap | Muestra puntajes z correctos | ✓ |
| Barras | Conteo coincide con tabla de evaluación | ✓ |
| Comparación | Muestra 4 barras por participante | ✓ |
| Dispersión | Puntos alineados con x_pt | ✓ |

### Verificación Visual

| Gráfico | Criterio | Estado Esperado |
|---------|-----------|-----------------|
| Histograma | Distribución visible, escala adecuada | ✓ |
| Boxplot | Cajas y bigotes visibles | ✓ |
| Heatmap | Gradiente de colores claro (rojo → blanco → azul) | ✓ |
| Barras | Colores por categoría distintivos | ✓ |
| Comparación | Barras agrupadas claramente | ✓ |
| Dispersión | Línea diagonal y puntos visibles | ✓ |

---

## Procedimiento de Prueba

### Paso 1: Ejecutar Tests

```bash
cd /ruta/a/pt_app/deliv/07_dashboards/tests
Rscript test_07_graficos.R
```

**Resultado esperado:** Todos los tests pasan sin errores.

### Paso 2: Ejecutar Aplicación

```bash
cd /ruta/a/pt_app/deliv/07_dashboards
Rscript app_v07.R
```

**Resultado esperado:** La aplicación se abre en el navegador sin errores.

### Paso 3: Probar Cada Gráfico

#### 3.1 Histograma por Nivel

1. Seleccionar un analito (ej. CO)
2. Seleccionar un nivel (ej. Nivel 2-μmol/mol)
3. Seleccionar n (ej. 4)
4. Ir a "Gráficos - Distribución"
5. Verificar:
   - [ ] El histograma se renderiza
   - [ ] El título es correcto
   - [ ] Los ejes tienen etiquetas
   - [ ] Se puede hacer zoom
   - [ ] Los tooltips muestran información correcta

#### 3.2 Boxplot por Participante

1. Permanecer en "Gráficos - Distribución"
2. Verificar:
   - [ ] El boxplot se renderiza
   - [ ] Cada participante tiene una caja
   - [ ] Los ejes tienen etiquetas
   - [ ] Se puede hacer zoom
   - [ ] Los tooltips muestran información correcta

#### 3.3 Heatmap de Puntajes z

1. Hacer clic en "Calcular Puntajes PT"
2. Ir a "Gráficos - Puntajes"
3. Verificar:
   - [ ] El heatmap se renderiza
   - [ ] Hay un tile por participante
   - [ ] Los colores muestran el gradiente (rojo → blanco → azul)
   - [ ] Los tooltips muestran valores correctos

#### 3.4 Gráfico de Barras de Evaluación

1. Permanecer en "Gráficos - Puntajes"
2. Verificar:
   - [ ] El gráfico de barras se renderiza
   - [ ] Las barras tienen colores distintivos
   - [ ] El conteo coincide con la tabla "Resumen de evaluación"
   - [ ] Los tooltips muestran información correcta

#### 3.5 Comparación de Puntajes

1. Ir a "Gráficos - Comparación"
2. Verificar:
   - [ ] El gráfico se renderiza
   - [ ] Hay 4 barras por participante
   - [ ] Las líneas de referencia (±2) son visibles
   - [ ] Los tooltips muestran todos los puntajes

#### 3.6 Diagrama de Dispersión

1. Permanecer en "Gráficos - Comparación"
2. Verificar:
   - [ ] El gráfico se renderiza
   - [ ] Hay un punto por participante
   - [ ] La línea diagonal y = x es visible
   - [ ] Los puntos están coloreados por evaluación
   - [ ] Los tooltips muestran información correcta

### Paso 4: Verificar Interactividad

Para cada gráfico, probar:

- [ ] Zoom con scroll del mouse
- [ ] Pan (arrastrar el gráfico)
- [ ] Hover para ver tooltips
- [ ] Exportar imagen (icono de cámara en Plotly)

### Paso 5: Verificar Consistencia con Tablas

1. Comparar el gráfico de barras con la tabla "Resumen de evaluación"
2. [ ] Los conteos coinciden exactamente

3. Comparar el heatmap con la tabla de puntajes
4. [ ] Los valores de puntajes coinciden

---

## Resultados Esperados

### Histograma por Nivel

**Datos esperados:**
- Número de bins: 20
- Rango de eje X: Min a Max de mean_values filtrados
- Rango de eje Y: 0 a frecuencia máxima

**Características visuales:**
- Forma de distribución visible (normal, sesgada, etc.)
- Sin espacios vacíos entre barras
- Bordes de barras en negro

### Boxplot por Participante

**Datos esperados:**
- Un boxplot por participante
- Eje X con todos los participant_id
- Bigotes extendidos hasta 1.5*IQR

**Características visuales:**
- Cajas coloreadas
- Mediana visible (línea central)
- Outliers como puntos individuales (si aplica)

### Heatmap de Puntajes z

**Datos esperados:**
- Una fila con tiles por participante
- Valores de z_score del centro de datos
- Escala de colores centrada en 0

**Características visuales:**
- Gradiente suave de colores
- Tiles claramente delimitados
- Colores intuitivos (azul = positivo, rojo = negativo)

### Gráfico de Barras de Evaluación

**Datos esperados:**
- 1-4 barras (según resultados)
- Alturas = conteo de cada categoría
- Eje Y con valores enteros

**Características visuales:**
- Colores distintivos por categoría
- Orden fijo: Satisfactorio → Cuestionable → No satisfactorio → N/A
- Etiquetas de eje X legibles

### Comparación de Puntajes

**Datos esperados:**
- 4 barras por participante (z, z', zeta, En)
- Líneas punteadas en y = 2 y y = -2
- Barras agrupadas lado a lado

**Características visuales:**
- Diferentes colores por tipo de puntaje
- Leyenda visible
- Líneas de referencia claramente visibles

### Diagrama de Dispersión

**Datos esperados:**
- Un punto por participante (excepto ref)
- Puntos cerca de la línea y = x (buenos resultados)
- Línea diagonal desde el origen

**Características visuales:**
- Puntos de tamaño razonable (4)
- Colores por evaluación z-score
- Leyenda de colores visible

---

## Problemas Comunes y Soluciones

### Problema: Gráfico no se renderiza

**Causa posible:** No se han calculado los puntajes

**Solución:**
1. Hacer clic en "Calcular Puntajes PT"
2. Esperar a que aparezcan los resultados
3. Ir a la pestaña de gráficos

### Problema: Gráfico aparece vacío

**Causa posible:** No hay datos para la combinación seleccionada

**Solución:**
1. Verificar que la combinación analito/nivel/n tiene datos
2. Cambiar a una combinación diferente
3. Consultar la tabla de resumen de datos

### Problema: Colores incorrectos

**Causa posible:** Categoría de evaluación incorrecta

**Solución:**
1. Verificar la tabla de puntajes
2. Confirmar que las categorías son "Satisfactorio", "Cuestionable", "No satisfactorio"
3. Los caracteres especiales deben ser exactos (tildes)

### Problema: Interactividad no funciona

**Causa posible:** Plotly no está cargado correctamente

**Solución:**
1. Verificar que el paquete plotly está instalado
2. Reiniciar la aplicación
3. Limpiar caché del navegador

---

## Checklist Final

Antes de finalizar la verificación, asegúrese de que:

- [ ] Todos los tests de test_07_graficos.R pasan
- [ ] La aplicación se ejecuta sin errores
- [ ] Los 6 gráficos se renderizan correctamente
- [ ] La interactividad de Plotly funciona en todos los gráficos
- [ ] Los tooltips muestran datos correctos
- [ ] Los colores son distintivos y apropiados
- [ ] Los gráficos son consistentes con las tablas de datos
- [ ] Los títulos y etiquetas de ejes son correctos
- [ ] Los gráficos son legibles e interpretables
- [ ] El diagrama de flujo (diagrama_flujo.mmd) es correcto

---

## Conclusión

Si todos los elementos del checklist están marcados, el Entregable 07 está verificado correctamente y los gráficos están listos para usar en la aplicación Shiny.

---

**Fecha de verificación:** _________  
**Verificado por:** _________  
**Estado:** [ ] Aprobado [ ] Observaciones [ ] Rechazado
