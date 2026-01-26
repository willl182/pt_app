# Manual de Usuario - Aplicación PT Versión 06

**Fecha:** 2026-01-24  
**Versión:** 06 (Lógica de Negocio)  
**Entregable:** 06 - Aplicación con lógica de negocio (sin gráficos)

---

## Tabla de Contenidos

1. [Introducción](#introducción)
2. [Requisitos del Sistema](#requisitos-del-sistema)
3. [Instalación y Ejecución](#instalación-y-ejecución)
4. [Descripción de la Interfaz](#descripción-de-la-interfaz)
5. [Flujo de Trabajo](#flujo-de-trabajo)
6. [Cálculos Implementados](#cálculos-implementados)
7. [Exportación de Datos](#exportación-de-datos)

---

## Introducción

La Aplicación PT Versión 06 es una herramienta web desarrollada en R Shiny para el análisis de ensayos de aptitud según las normas ISO 13528:2022 e ISO 17043:2024. Esta versión se enfoca en la lógica de negocio y cálculos de puntajes, sin incluir visualizaciones gráficas.

### Características Principales

- **Datos precargados**: Los 4 archivos CSV se cargan automáticamente al iniciar
- **Cálculo de puntajes PT**: z, z', zeta y En
- **Evaluación automática**: Clasificación de desempeño (Satisfactorio/Cuestionable/No satisfactorio)
- **Exportación de resultados**: Descarga de tablas en formato CSV
- **Interfaz simplificada**: Sin componentes de carga de archivos

---

## Requisitos del Sistema

### Software Requerido

- **R** (versión 4.0 o superior)
- **RStudio** (opcional pero recomendado)

### Paquetes R

Los siguientes paquetes deben estar instalados:

```r
# Ejecutar en consola R
install.packages(c(
  "shiny",
  "tidyverse",
  "DT"
))
```

### Archivos de Datos

Los siguientes archivos CSV deben estar ubicados en `data/` (directorio padre):

1. `homogeneity.csv` - Datos de estudio de homogeneidad
2. `stability.csv` - Datos de estudio de estabilidad
3. `summary_n4.csv` - Datos consolidados de participantes
4. `participants_data4.csv` - Tabla de instrumentación

---

## Instalación y Ejecución

### Paso 1: Ubicarse en el Directorio Correcto

```bash
cd /ruta/a/pt_app/deliv/06_app_logica
```

### Paso 2: Ejecutar la Aplicación

#### Desde RStudio:

1. Abrir el archivo `app_v06.R`
2. Presionar **Run App** (el botón verde triangular) o usar `Ctrl+Shift+Enter`

#### Desde la terminal:

```bash
Rscript app_v06.R
```

La aplicación se abrirá automáticamente en el navegador web en la dirección:
```
http://127.0.0.1:XXXX
```

Donde XXXX es un puerto asignado automáticamente por Shiny.

---

## Descripción de la Interfaz

La interfaz de la aplicación se divide en tres secciones principales:

### Panel Lateral (Barra Izquierda)

#### 1. Datos Precargados
Lista informativa que muestra los archivos que se han cargado automáticamente:

- homogeneity.csv
- stability.csv
- summary_n4.csv
- participants_data4.csv

**Nota**: Estos archivos se leen automáticamente del directorio `../data/` al iniciar la aplicación.

#### 2. Análisis

Contiene los selectores para configurar el cálculo de puntajes:

- **Analito**: Seleccione el contaminante a analizar (ej. CO, SO2, O3, NO)
- **Nivel**: Seleccione el nivel del ensayo (ej. Nivel 1-μmol/mol, Nivel 2-μmol/mol)
- **n**: Seleccione el número de laboratorios participantes (ej. 4)

#### 3. Botón de Acción

- **Calcular Puntajes PT**: Ejecuta el cálculo de puntajes para la combinación seleccionada

### Panel Principal (Área Derecha)

La interfaz principal se organiza en pestañas:

#### Pestaña 1: Resumen de Datos

Muestra tablas con los datos precargados:

1. **Datos de participantes**: Tabla con información de los laboratorios participantes (primeras 50 filas)
2. **Datos de homogeneidad**: Tabla con resultados del estudio de homogeneidad (primeras 50 filas)
3. **Datos de estabilidad**: Tabla con resultados del estudio de estabilidad (primeras 50 filas)
4. **Descargar CSV de participantes**: Botón para exportar la tabla de participantes

#### Pestaña 2: Puntajes PT

Muestra los resultados de cálculos:

1. **Parámetros de cálculo**: Tabla con:
   - Valor asignado (x_pt)
   - sigma_pt (MADe y nIQR)
   - u_xpt (incertidumbre del valor asignado)
   - Factor k
   - Método usado

2. **Resultados de puntajes**: Tabla detallada con:
   - ID del participante
   - Analito, nivel y n
   - Valor medio y desviación estándar
   - Valor asignado y parámetros (x_pt, sigma_pt, u_xpt)
   - Puntajes: z, z', zeta, En
   - Evaluación: Satisfactorio/Cuestionable/No satisfactorio

3. **Resumen de evaluación**: Tabla de conteo por categoría de desempeño

4. **Descargar CSV de puntajes**: Botón para exportar la tabla de puntajes

---

## Flujo de Trabajo

### Ejemplo de Uso Completo

1. **Iniciar la aplicación**
   - Ejecutar `app_v06.R` desde R o RStudio
   - Esperar que se abra en el navegador

2. **Seleccionar datos**
   - En el panel lateral, seleccionar un analito (ej. "CO")
   - Seleccionar un nivel (ej. "Nivel 2-μmol/mol")
   - Seleccionar n (ej. "4")

3. **Revisar datos de entrada**
   - Ir a la pestaña "Resumen de Datos"
   - Verificar que las tablas se hayan cargado correctamente

4. **Calcular puntajes**
   - Hacer clic en el botón "Calcular Puntajes PT"
   - Esperar a que aparezcan los resultados

5. **Revisar resultados**
   - Ir a la pestaña "Puntajes PT"
   - Revisar los parámetros de cálculo
   - Examinar la tabla de puntajes
   - Verificar el resumen de evaluación

6. **Exportar resultados**
   - Hacer clic en "Descargar CSV de puntajes" para guardar los resultados

---

## Cálculos Implementados

### Puntajes PT Calculados

La aplicación calcula cuatro tipos de puntajes según ISO 13528:2022:

#### 1. Puntaje z-score

**Fórmula:**
```
z = (x - x_pt) / sigma_pt
```

**Criterios de evaluación:**
- |z| ≤ 2: Satisfactorio
- 2 < |z| < 3: Cuestionable
- |z| ≥ 3: No satisfactorio

#### 2. Puntaje z'-score (z-prime)

**Fórmula:**
```
z' = (x - x_pt) / sqrt(sigma_pt^2 + u_xpt^2)
```

Incluye la incertidumbre del valor asignado en el denominador.

**Criterios de evaluación:** Igual que z-score.

#### 3. Puntaje zeta-score

**Fórmula:**
```
zeta = (x - x_pt) / sqrt(u_x^2 + u_xpt^2)
```

Usa la incertidumbre del participante (u_x) y del valor asignado (u_xpt).

**Criterios de evaluación:** Igual que z-score.

#### 4. Puntaje En-score (Error normalizado)

**Fórmula:**
```
En = (x - x_pt) / sqrt(U_x^2 + U_xpt^2)
```

Usa las incertidumbres expandidas (k=2).

**Criterios de evaluación:**
- |En| ≤ 1: Satisfactorio
- |En| > 1: No satisfactorio

### Estadísticos Robustos

- **MADe** (Median Absolute Deviation escalado):
  ```
  MADe = 1.483 * MAD
  ```

- **nIQR** (Normalized Interquartile Range):
  ```
  nIQR = 0.7413 * IQR
  ```

Estos se usan para calcular sigma_pt robusto a valores atípicos.

---

## Exportación de Datos

### Descarga de Tablas CSV

La aplicación permite exportar dos tipos de archivos:

#### 1. Tabla de Participantes

- **Nombre del archivo**: `participantes_YYYY-MM-DD.csv`
- **Contenido**: Información de los laboratorios participantes
- **Formato**: CSV con encabezados

#### 2. Tabla de Puntajes

- **Nombre del archivo**: `puntajes_[analito]_[nivel]_YYYY-MM-DD.csv`
- **Contenido**: Resultados completos de puntajes PT
- **Formato**: CSV con encabezados

### Uso de Archivos Exportados

Los archivos CSV se pueden abrir en:

- **Microsoft Excel**: Abrir como archivo de texto delimitado por comas
- **Google Sheets**: Importar como CSV
- **R**: Leer con `read.csv()`
- **Python**: Leer con `pandas.read_csv()`

---

## Referencias Normativas

- **ISO 13528:2022** - Statistical methods for use in proficiency testing
- **ISO 17043:2024** - Conformity assessment - General requirements for proficiency testing

---

## Soporte y Contacto

Para preguntas o problemas técnicos relacionados con esta aplicación:

- **Laboratorio CALAIRE**
- **Universidad Nacional de Colombia - Sede Medellín**
- **Instituto Nacional de Metrología (INM)**

Correo electrónico: calaire_med@unal.edu.co

---

## Registro de Cambios

| Versión | Fecha | Cambios |
|---------|-------|---------|
| 06 | 2026-01-24 | Versión inicial con lógica de negocio sin gráficos |
