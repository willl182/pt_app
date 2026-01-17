# Plan de Entregables - Análisis de Datos PT

Este documento detalla el plan de trabajo para cumplir con los 9 entregables requeridos, basándose en el análisis de `app.R` y el repositorio existente.

Todas las verificaciones se realizarán utilizando scripts en R.

## 1. REPOSITORIO DE CÓDIGO Y SCRIPTS INICIALES

**Estado Actual:**
- El repositorio existe.
- `app.R` contiene la aplicación monolítica.
- `data/` contiene datos de ejemplo.
- `reports/` contiene la plantilla RMarkdown.
- `R/utils.R` existe pero difiere en implementación de `app.R`.

**Acciones de Documentación:**
- Crear `docs/01_ESTRUCTURA_PROYECTO.md`: Describir la estructura de directorios, propósito de archivos clave y flujo de datos.

**Acciones de Código:**
- Limpiar `R/utils.R` para que refleje la lógica exacta de `app.R` (especialmente Algoritmo A ponderado vs Winsorized).
- Asegurar que el entorno de ejecución tenga todas las librerías necesarias (listadas en `app.R`).

**Plan de Verificación:**
- Script `tests/verify_env.R`: Carga todas las librerías y verifica la existencia de archivos clave.

---

## 2. FUNCIONES R PARA ANOVA Y T-TEST VALIDADAS

**Estado Actual:**
- Funciones `compute_homogeneity_metrics` y `compute_stability_metrics` están embebidas en `app.R`.

**Acciones de Documentación:**
- Crear `docs/02_VALIDACION_ANOVA_TTEST.md`: Documentar las fórmulas utilizadas (ISO 13528:2022 Anexo B) y los resultados de validación.

**Acciones de Código:**
- Extraer `compute_homogeneity_metrics` a `R/homogeneity.R`.
- Extraer `compute_stability_metrics` a `R/stability.R`.
- Refactorizar `app.R` para usar estas fuentes externas.

**Plan de Verificación:**
- Crear `tests/test_homogeneity.R`: Ejecutar `compute_homogeneity_metrics` con datos conocidos (e.g. `data/homogeneity.csv`) y comparar con valores esperados documentados o calculados manualmente en el script de prueba.

---

## 3. FUNCIONES R PARA CÁLCULO DE ESTADÍSTICOS ROBUSTOS

**Estado Actual:**
- `run_algorithm_a` (ponderado iterativo) y `calculate_niqr` están en `app.R`.
- `algorithm_A` en `R/utils.R` es diferente (Winsorized).

**Acciones de Documentación:**
- Crear `docs/03_VALIDACION_ROBUSTOS.md`: Explicar la elección del Algoritmo A (ponderado) vs el estándar ISO, y documentar la validación.

**Acciones de Código:**
- Extraer `run_algorithm_a` y `calculate_niqr` a `R/robust_stats.R`.
- Reemplazar el contenido incorrecto de `R/utils.R` o eliminarlo en favor de `R/robust_stats.R`.

**Plan de Verificación:**
- Crear `tests/test_robust.R`: Probar `run_algorithm_a` con un vector de prueba y verificar convergencia y resultados contra una salida conocida.

---

## 4. MÓDULO DE CÁLCULO DE PUNTAJES Y PLANTILLA R MARKDOWN

**Estado Actual:**
- Lógica en `compute_scores_metrics` dentro de `app.R` y duplicada en `reports/report_template.Rmd`.

**Acciones de Documentación:**
- Crear `docs/04_CALCULO_PUNTAJES.md`: Definir fórmulas de z, z', zeta, En.

**Acciones de Código:**
- Extraer `compute_scores_metrics` a `R/scores.R`.
- Actualizar `reports/report_template.Rmd` para usar las funciones de `R/` si es posible, o asegurar que la lógica duplicada sea idéntica (sincronización). *Nota: RMarkdown a veces requiere las funciones definidas internamente o cargadas explícitamente.*

**Plan de Verificación:**
- Crear `tests/test_scores.R`: Calcular puntajes para un dataframe dummy y verificar clasificaciones (Satisfactorio, Cuestionable, etc.).

---

## 5. PROTOTIPO ESTÁTICO DE LA INTERFAZ DE USUARIO

**Estado Actual:**
- Definido en la sección `ui <- fluidPage(...)` de `app.R`.

**Acciones de Documentación:**
- Crear `docs/05_DISENO_UI.md`: Descripción de las pestañas, inputs y outputs esperados. Incluir capturas de pantalla si es posible (o descripciones textuales detalladas).

**Acciones de Código:**
- Separar el objeto `ui` a `R/ui.R` (opcional, pero recomendado para limpieza).

**Plan de Verificación:**
- Verificación visual (manual) o script simple que compruebe que el objeto `ui` es de clase `shiny.tag.list` o similar.

---

## 6. APLICACIÓN CON LÓGICA DE NEGOCIO FUNCIONAL (SIN GRÁFICOS)

**Estado Actual:**
- Lógica reactiva en `server` de `app.R`.

**Acciones de Documentación:**
- Crear `docs/06_LOGICA_NEGOCIO.md`: Diagrama de flujo de reactividad (cargas de datos -> cálculos -> tablas).

**Acciones de Código:**
- Asegurar que la lógica de negocio use las funciones extraídas en los pasos 2, 3 y 4.

**Plan de Verificación:**
- No aplica prueba unitaria directa al server completo sin herramientas como `shinytest2`, pero se verificará indirectamente mediante las pruebas de las funciones subyacentes.

---

## 7. DASHBOARDS CON GRÁFICOS DINÁMICOS INTEGRADOS

**Estado Actual:**
- Gráficos `plotly` y `ggplot2` integrados en `app.R` (histogramas, boxplots, mapas de calor).

**Acciones de Documentación:**
- Crear `docs/07_VISUALIZACION.md`: Listado de gráficos y librerías utilizadas.

**Acciones de Código:**
- (Opcional) Extraer funciones de ploteo complejas a `R/plotting.R`.

**Plan de Verificación:**
- Script `tests/test_plotting.R`: Generar objetos ggplot con datos dummy y verificar que no den error.

---

## 8. VERSIÓN BETA DEL APLICATIVO Y DOCUMENTACIÓN FINAL

**Estado Actual:**
- Aplicación funcional en `app.R`.

**Acciones de Documentación:**
- Crear `docs/08_MANUAL_USUARIO.md`: Guía paso a paso para el usuario final.
- Crear `docs/08_MANUAL_TECNICO.md`: Guía de despliegue y mantenimiento.

**Acciones de Código:**
- `app_final.R`: Archivo principal limpio que hace `source` de los módulos en `R/`.

**Plan de Verificación:**
- Ejecución integral (manual) y revisión de logs.

---

## 9. INFORME DE VALIDACIÓN

**Estado Actual:**
- Pendiente.

**Acciones de Documentación:**
- Crear `docs/09_INFORME_VALIDACION.md`: Compilar los resultados de todos los scripts de prueba (`tests/*.R`).

**Acciones de Código:**
- Crear un script maestro `validation/run_all_tests.R` que ejecute todos los tests y genere un log de salida.

**Plan de Verificación:**
- Ejecutar `validation/run_all_tests.R` y confirmar que todos los tests pasan.
