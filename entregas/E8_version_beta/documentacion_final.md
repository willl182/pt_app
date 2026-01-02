# Entregable 8.2: Compilación de Documentación Final

Este documento actúa como índice maestro y resumen ejecutivo de toda la documentación técnica generada para el aplicativo PT del Laboratorio CALAIRE.

## 1. Mapa de Documentación Técnica

La documentación se divide en tres niveles de profundidad:

### Nivel 1: Introductorio (docs/)
- [Carga de Datos](docs/01_carga_datos.md)
- [Funciones Auxiliares](docs/02_funciones_auxiliares.md)
- [Guía de Uso del Aplicativo](GUIA_USO.md)

### Nivel 2: Estadístico y Algorítmico (entregas/E3, E4)
- [Homogeneidad y Estabilidad (ISO 13528)](entregas/E3_calculos_estadisticos/calculo_homogeneidad_estabilidad.md)
- [Valor Asignado y Sigma_pt](entregas/E3_calculos_estadisticos/calculo_valor_asignado_sigma.md)
- [Módulo de Puntajes (z, En, Zeta)](entregas/E4_puntajes/modulo_puntajes.md)

### Nivel 3: Arquitectura y Desarrollo (entregas/E5, E6, E7)
- [Estructura de UI y Navegación](entregas/E5_ui_prototipo/prototipo_ui.md)
- [Lógica de Negocio y Reactividad](entregas/E6_logica_negocio/logica_negocio.md)
- [Dashboards e Interactividad](entregas/E7_dashboards/dashboards.md)

## 2. Historial de Cambios (Ruta a Beta)

1. **v1.0 (Alpha):** Implementación de cálculos core ANOVA y visualización en DT.
2. **v1.5 (Refactor):** Modularización de funciones en `R/utils.R` e integración de `rmarkdown` para reportes Word.
3. **v2.0 (Beta):** Incorporación de herramientas interactivas `plotly` y sistema de validación de atípicos (Grubbs).

## 3. Conclusión Técnica

El aplicativo cumple satisfactoriamente con los requisitos de las normas internacionales de referencia. La arquitectura permite una escalabilidad futura para incluir nuevos tipos de analitos o matrices, manteniendo una base de código documentada y trazable.
