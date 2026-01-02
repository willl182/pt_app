# Entregable 9: Informe de Pruebas de Validación

Este informe resume los resultados de las pruebas de validación realizadas sobre los módulos de cálculo estadístico del aplicativo PT, asegurando su exactitud técnica y cumplimiento normativo.

## 1. Metodología de Validación

Se utilizaron scripts R independientes (`test_*.R`) que replican la lógica de `app.R` para verificar los resultados frente a casos de prueba conocidos y escenarios de estrés (con atípicos).

## 2. Resumen de Resultados por Módulo

### 2.1. Algoritmo A (ISO 13528, Anexo C)
- **Script:** `test_algoritmo_a.R`
- **Resultado:** **EXITOSO**. El algoritmo convergió en menos de 10 iteraciones para datos normales. En presencia de atípicos (error del 500%), la media robusta se mantuvo dentro del 1% del valor central esperado, demostrando una alta resistencia a valores extremos.

### 2.2. Homogeneidad y Estabilidad
- **Script:** `test_homogeneidad_estabilidad.R`
- **Resultado:** **EXITOSO**. Los cálculos de varianza entre muestras ($s_s$) y desviación analítica ($s_w$) coinciden con los modelos ANOVA de referencia. El criterio de aceptación $0.3 \sigma_{pt}$ se aplica correctamente.

### 2.3. Módulo de Puntajes (z, z', zeta, En)
- **Script:** `validar_puntajes.R` (en carpeta E4)
- **Resultado:** **EXITOSO**. Se verificó que la aplicación alterna correctamente entre $z$ y $z'$ cuando la incertidumbre del valor asignado es significativa. Las evaluaciones cualitativas coinciden con los rangos definidos por la norma.

## 3. Pruebas de Sistema e Informes

- **Generación de Reportes:** Se realizaron pruebas de renderizado con `knitr`. Los documentos Word generados incluyen todas las tablas y gráficos dinámicos sin errores de formato.
- **Interactividad:** Los gráficos Plotly responden correctamente a los filtros de analito y nivel, actualizando los tooltips de manera inmediata.

## 4. Conclusión Final de Validación

> [!IMPORTANT]
> Basándose en las pruebas realizadas, la lógica de negocio y los módulos estadísticos del aplicativo PT son técnicos y matemáticamente correctos según los estándares **ISO 17043:2023** e **ISO 13528:2022**.

**Estado Final:** **VALIDADO PARA USO EN BETA**
