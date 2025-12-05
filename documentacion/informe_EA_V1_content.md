# Contenido para CALAIRE_Formato_Informe_EA_v1.docx

Este archivo contiene el texto y las tablas que se pueden copiar en el documento `CALAIRE_Formato_Informe_EA_v1.docx`.

## Anexo A: Valores Asignados (Xpt) y sus Incertidumbres (u(Xpt))

*Nota: Los valores precisos se calculan en el script `tools/generate_report_assets.R`.*

## Anexo B: Resultados de las Pruebas de Homogeneidad y Estabilidad

A continuación se presentan los resultados de las pruebas de homogeneidad y estabilidad para cada contaminante y nivel.

*Nota: Las tablas y gráficos completos se generan ejecutando el script `tools/generate_report_assets.R` y se encuentran en la carpeta `reports/assets`.*

**Ejemplo para un contaminante y nivel:**

**Tabla de Homogeneidad (Detalles por Item)**
*Referencia: `reports/assets/tables/homogeneity_details_[pollutant]_[level].csv`*

**Conclusión de Homogeneidad:**
*(Extraído de los cálculos en el script)*

**Gráfico: Distribución de Homogeneidad**
*Referencia: `reports/assets/charts/homogeneity_hist_[pollutant]_[level].png`*

**Tabla de Estabilidad (Detalles por Item)**
*Referencia: `reports/assets/tables/stability_details_[pollutant]_[level].csv`*

**Conclusión de Estabilidad:**
*(Extraído de los cálculos en el script)*

---
*(Este bloque se repetiría para cada contaminante y nivel)*
---

## Anexo C: Resultados Reportados por los Participantes y Puntuaciones de Desempeño

A continuación se presentan las tablas con los resultados reportados por los participantes y sus puntuaciones de desempeño.

*Nota: Las tablas completas se generan ejecutando el script `tools/generate_report_assets.R` y se encuentran en la carpeta `reports/assets/tables`.*

**Ejemplo para un contaminante y nivel:**

**Tabla de Puntuaciones (Scores)**
*Referencia: `reports/assets/tables/scores_table_[pollutant]_[level].csv`*

## Anexo D: Gráficos de Desempeño

A continuación se presentan los gráficos de desempeño para cada contaminante y nivel.

*Nota: Los gráficos completos se generan ejecutando el script `tools/generate_report_assets.R` y se encuentran en la carpeta `reports/assets/charts`.*

**Ejemplo para un contaminante y nivel:**

**Gráfico: Z-Scores**
*Referencia: `reports/assets/charts/z_scores_[pollutant]_[level].png`*

**Gráfico: Zeta-Scores**
*Referencia: `reports/assets/charts/zeta_scores_[pollutant]_[level].png`*

---
*(Este bloque se repetiría para cada contaminante y nivel)*
---

## Actualización 2024-11-21
- Sincronizado con la lógica vigente en `app.R`, incluyendo el uso de Algoritmo A, las variantes de \u03c3_pt y los criterios de homogeneidad/estabilidad basados en las medianas robustas.
- Referencia cruzada con `reports/report_template.Rmd` para reflejar los parámetros YAML (pollutant, level, n_lab, k_factor y metrological_compatibility_method) utilizados al generar informes.
- Verificado que las descripciones mantienen consistencia con la interfaz Shiny y el flujo de cálculo de puntajes z, z', zeta y En.
