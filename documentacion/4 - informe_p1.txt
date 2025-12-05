1. ## **Identificación y Contexto** {#identificación-y-contexto}

   1. ### **Información del Proveedor y del esquema** {#información-del-proveedor-y-del-esquema}

| Tabla 1 Información del Ensayo de Aptitud |  |
| :---- | :---- |
| **Nombre y Contacto del Proveedor de EA** | Laboratorio CALAIRE  Campus El Volador, Cra 65 No59A \- 110 Bloque 19A, laboratorio 401 calaire\_med@unal.edu.co 314 874 8191 |
| **Identificación Única del Esquema de EA** |  |
| **Identificación Única del Informe** |  |
| **Estado del Informe** | FINAL |
| **Fecha de Emisión** |  |
| **Periodo del Ensayo** |  |
| **Declaración de Servicios Externos** | El Laboratorio CALAIRE es el único organizador y responsable integral de las actividades clave. No se utilizaron proveedores externos para el diseño, la planificación del esquema de EA, la evaluación del rendimiento ni la autorización de este informe, según lo exige la cláusula 6.4.1 de ISO/IEC 17043:2023. |

   2. ### **Alcance y Objetivo del EA** {#alcance-y-objetivo-del-ea}

**Alcance:** Este Ensayo de Aptitud (EA) por comparación interlaboratorio abarca la medición de los gases contaminantes criterio SO₂, CO, O₃, NO y NO₂ en aire cero, según lo definido en el \[Código del Esquema\].

**Objetivo Principal:** Evaluar el desempeño de los laboratorios participantes en la medición de los gases contaminantes criterio, conforme a los requisitos de la norma ISO/IEC 17043:2023 y utilizando los métodos estadísticos de la norma ISO 13528:2022.

3. ### **Confidencialidad y Uso del Informe** {#confidencialidad-y-uso-del-informe}

La identidad de los participantes es confidencial y solo conocida por el personal autorizado de CALAIRE involucrado en la operación del esquema de EA. Se utilizan códigos de laboratorio anonimizados en este informe para asegurar la confidencialidad, según lo estipulado en la política de confidencialidad del laboratorio. Este informe es para uso de los participantes y, cuando aplique, de sus organismos de acreditación o autoridades regulatorias. Cualquier otro uso debe ser autorizado por CALAIRE.

4. ### **Roles de Autorización y Personal Clave** {#roles-de-autorización-y-personal-clave}

La organización, ejecución y evaluación de este EA se realizó bajo la responsabilidad del Laboratorio CALAIRE. Los roles clave involucrados fueron:

**Coordinador EA:** \[Nombre\]  
**Profesional Calidad Aire:** \[Nombre\]  
**Ingeniero Operativo:** \[Nombre\]  
**Profesional de Gestión de Calidad:** \[Nombre\]

5. ### **Participantes e Instrumentación** {#participantes-e-instrumentación}

En esta ronda del EA participaron 6 laboratorios. A continuación, se lista a los participantes (mediante código asignado) y la instrumentación principal reportada para cada contaminante medido

| Tabla 2\. Participantes del Ensayo de Aptitud |  |  |  |  |
| :---- | :---- | :---- | :---- | :---- |
| **Código Lab** | **Analizador SO₂ (Marca/Modelo)** | **Analizador CO (Marca/Modelo)** | **Analizador O₃ (Marca/Modelo)** | **Analizador NO/NO₂ (Marca/Modelo)** |
| REFERENCIA | HORIBA APSA- 370 | Teledyne T300 | Thermo 49i | HORIBA APSA- 370 |
| PART\_1 | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] |
| PART\_2 | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] |
| PART\_3 | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] |
| PART\_4 | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] |
| PART\_5 | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] |
| PART\_6 | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] | \[Info Participante\] |


## Actualización 2024-11-21
- Sincronizado con la lógica vigente en `app.R`, incluyendo el uso de Algoritmo A, las variantes de \u03c3_pt y los criterios de homogeneidad/estabilidad basados en las medianas robustas.
- Referencia cruzada con `reports/report_template.Rmd` para reflejar los parámetros YAML (pollutant, level, n_lab, k_factor y metrological_compatibility_method) utilizados al generar informes.
- Verificado que las descripciones mantienen consistencia con la interfaz Shiny y el flujo de cálculo de puntajes z, z', zeta y En.
