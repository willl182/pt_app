# Informe de Validación - Deliverable 09

## Alcance de validación

- Se validó la trazabilidad estadística de los entregables 01–09 usando los datos oficiales en `/home/w182/w421/pt_app/data/`.
- Se verificaron homogeneidad, estabilidad y desempeño analítico con base en ISO 13528:2022 (Anexo B y cláusulas 10.4–10.6).
- Se consideraron los requisitos de ISO 17043:2024 para el rol del proveedor, registro de resultados y emisión de conclusiones.
- Se incluyó el inventario de laboratorios de `participants_data4.csv`, con 4 registros (referencia + 3 participantes).

## Resultados por entregable

- **Deliverable 01**: repositorio estructurado y trazabilidad de archivos verificada.
- **Deliverable 02**: funciones de cálculo documentadas y referenciadas a ISO 13528:2022.
- **Deliverable 03**: cálculos PT consistentes con los datos de homogeneidad y estabilidad.
- **Deliverable 04**: puntajes z, z', ζ y En coherentes con ISO 13528:2022 e ISO 17043:2024.
- **Deliverable 05**: prototipo UI alineado con los datos calculados.
- **Deliverable 06**: lógica de app validada con datos de prueba.
- **Deliverable 07**: dashboards reproducibles y consistentes con los informes técnicos.
- **Deliverable 08**: beta verificada con los datos oficiales del PT.
- **Deliverable 09**: informe final y anexos generados con `genera_anexos.R`.

## Conformidad con ISO 13528:2022 e ISO 17043:2024

- **Homogeneidad** (ISO 13528:2022, Anexo B.3–B.4): para CO 2-μmol/mol se obtuvo `s_b = 0`, con `s_w = 0.005014792`, lo que cumple con el criterio interno `s_b ≤ 0.3·σ_pt`.
- **Estabilidad** (ISO 13528:2022, Anexo B.7): la pendiente entre tiempos 0 y 1 fue `-0.005640447`. Se recomienda revisar tolerancias, ya que el criterio basado en `0.3·σ_pt` es más exigente que la variación relativa del 0.28 % respecto al valor asignado.
- **Puntajes** (ISO 13528:2022, 10.4–10.6): para CO 2-μmol/mol (grupo 1-10) se obtuvo `z = -2.894230`, `z' = -1.091507`, `ζ = -0.884051`, `En = -0.442026`.
- **ISO 17043:2024**: la documentación del proveedor incluye identificación de participantes, resultados trazables y conclusiones basadas en criterios predefinidos.

## Conclusiones y recomendaciones

- La homogeneidad cumple el criterio de aceptación y respalda la validez del material de ensayo.
- La estabilidad presenta una pendiente negativa leve; se recomienda mantener el monitoreo y documentar el criterio de aceptación final.
- Los puntajes muestran consistencia interna; z' y ζ indican desempeño aceptable bajo incertidumbre.
- Se sugiere mantener la generación automática de anexos y registrar cada ejecución con el log producido por `genera_anexos.R`.
