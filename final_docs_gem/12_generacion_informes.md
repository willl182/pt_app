# Módulo Shiny: Generación de Informes

## 1. Descripción General
Este módulo maneja la compilación de los resultados del análisis en un documento profesional descargable (Word o HTML). Interactúa con RMarkdown.

**Ubicación del Archivo:** `cloned_app.R` (Pestaña "Generación de informes")

---

## 2. Flujo de Trabajo

1.  **Configuración:** El usuario selecciona parámetros (ID de Esquema, Fecha, Método, Comentarios).
2.  **Compilación:** El usuario hace clic en "Descargar Informe".
3.  **Procesamiento (`downloadHandler`):**
    *   Crea un directorio temporal.
    *   Copia `report_template.Rmd` y `references.bib` al temporal.
    *   Compila los parámetros en una lista `params`.
    *   Ejecuta `rmarkdown::render()`.
4.  **Entrega:** El navegador descarga el archivo generado.

---

## 3. Integración con RMarkdown

### 3.1 La Plantilla
**Archivo:** `reports/report_template.Rmd`

La plantilla está parametrizada. No codifica valores sino que espera que sean pasados desde Shiny.

**Ejemplo de Encabezado YAML:**
```yaml
params:
  n_lab: "01"
  pollutant: "SO2"
  level: "low"
  method_code: "3"
  ...
```

### 3.2 Paso de Datos
En lugar de pasar grandes conjuntos de datos crudos, la aplicación pasa listas de resumen *procesadas* o dataframes filtrados a la plantilla para minimizar el tiempo de renderizado y el uso de memoria.

### 3.3 Formatos de Salida
*   **HTML:** Interactivo, mejor para visualización web.
*   **Word (.docx):** Estático, mejor para registros oficiales y edición. Utiliza un docx de referencia para estilos (`reference_docx: styles.docx`).

---

## 4. Opciones de Personalización
La UI proporciona campos para:
*   **Nombre del Coordinador:** Aparece en el bloque de firma.
*   **Fecha:** Fecha de emisión del informe.
*   **Comentarios:** Campo de texto libre para observaciones específicas sobre la ronda.
