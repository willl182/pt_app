# Índice Maestro de Entregables — PT App

**Proyecto:** Aplicativo de Análisis para Ensayos de Aptitud (PT)  
**Normas de referencia:** ISO 13528:2022, ISO 17043:2023  
**Institución:** Universidad Nacional de Colombia / Instituto Nacional de Metrología  
**Fecha:** 2026-06-28  
**Versión:** 1.0  

---

## Cómo Leer Este Paquete

Este paquete contiene nueve documentos técnicos formales, uno por cada entregable del proyecto PT App. Cada documento está diseñado para ser comprensible por lectores no desarrolladores —evaluadores, personal administrativo o supervisores— sin sacrificar precisión técnica.

Cada documento sigue una estructura común:

| Sección | Propósito |
|---------|-----------|
| Portada | Identificación del entregable, proyecto, institución, fecha y versión. |
| Resumen Ejecutivo | Síntesis de 1–2 páginas: qué contiene, por qué existe y qué evidencia aporta. |
| Contexto del Entregable | Ubicación dentro de la evolución del aplicativo. |
| Alcance | Qué cubre y qué no cubre el entregable. |
| Contenido Entregado | Inventario explicado de archivos, código, pruebas y documentación. |
| Explicación Funcional | Traducción del contenido técnico a lenguaje comprensible. |
| Evidencia de Verificación | Pruebas existentes, qué validan y cómo interpretarlas. |
| Estado Actual | Clasificación honesta: vigente, histórico, parcial o pendiente. |
| Relación con Otros Entregables | Conexión entre fases del proyecto. |
| Riesgos y Limitaciones | Aspectos que no deben sobreafirmarse. |
| Documentos de Consulta | Rutas a anexos técnicos y archivos de soporte. |
| Conclusión | Valor del entregable y recomendación de uso. |

---

## Inventario de Documentos

| # | Entregable | Archivo Markdown | Archivo Word | Estado comunicado |
|---|------------|-----------------|-------------|-------------------|
| 01 | Repositorio de Código y Scripts Iniciales | `documento_tecnico_entregable_01.md` | `documento_tecnico_entregable_01.docx` | Histórico validado |
| 02 | Funciones Usadas en app.R, R/ y ptcalc/R/ | `documento_tecnico_entregable_02.md` | `documento_tecnico_entregable_02.docx` | Regenerado y enriquecido |
| 03 | Cálculos PT (Paquete Standalone) | `documento_tecnico_entregable_03.md` | `documento_tecnico_entregable_03.docx` | Histórico / requiere alineación |
| 04 | Módulo de Cálculo de Puntajes | `documento_tecnico_entregable_04.md` | `documento_tecnico_entregable_04.docx` | Histórico / parcialmente vigente |
| 05 | Prototipo Estático de Interfaz | `documento_tecnico_entregable_05.md` | `documento_tecnico_entregable_05.docx` | Histórico / prototipo parcial |
| 06 | Lógica de la Aplicación y Manual de Usuario | `documento_tecnico_entregable_06.md` | `documento_tecnico_entregable_06.docx` | Histórico / manual no vigente |
| 07 | Dashboards y Gráficos | `documento_tecnico_entregable_07.md` | `documento_tecnico_entregable_07.docx` | Parcial / evidencia histórica |
| 08 | Versión Beta y Documentación Final | `documento_tecnico_entregable_08.md` | `documento_tecnico_entregable_08.docx` | Histórico / beta no vigente |
| 09 | Informe Final y Validación de Cálculos | `documento_tecnico_entregable_09.md` | `documento_tecnico_entregable_09.docx` | Requiere auditoría de evidencia |

---

## Guía de Lectura Recomendada

1. **Comenzar por el Entregable 01** para entender la línea base del proyecto.
2. **Seguir con el Entregable 02** para obtener el mapa de capacidades del aplicativo.
3. **Los Entregables 03 y 04** explican el motor matemático: cálculos y puntajes.
4. **Los Entregables 05 a 08** documentan la evolución de la interfaz, lógica, visualización y beta.
5. **El Entregable 09** es el más delicado: presenta la evidencia de validación y debe leerse con atención a sus secciones de alcance y pendientes.

---

## Convención de Estados

| Estado | Significado |
|--------|-------------|
| Histórico validado | Evidencia de una fase anterior, verificada y conservada para comparación. |
| Regenerado y enriquecido | Documento actualizado con mayor profundidad que la versión original. |
| Histórico / requiere alineación | Evidencia útil pero con divergencias frente a la implementación vigente. |
| Histórico / parcialmente vigente | Parte del contenido sigue siendo aplicable; parte ha sido superada. |
| Histórico / prototipo parcial | Evidencia de diseño inicial; no representa la interfaz actual. |
| Histórico / manual no vigente | Documento de una versión anterior; no describe la aplicación actual. |
| Parcial / evidencia histórica | Evidencia válida pero incompleta frente al estado actual. |
| Histórico / beta no vigente | Versión de consolidación superada por la arquitectura vigente. |
| Requiere auditoría de evidencia | La evidencia existe pero debe confirmarse antes de certificar. |

---

## Formato de Entrega

- **Formato principal:** DOCX (editable, Microsoft Word 2007+)
- **Formato secundario:** Markdown (texto plano, legible en cualquier editor)
- **Conversión:** pandoc 3.9.0.2
- **Idioma:** Español

---

*Generado conforme al plan `260628_0827_plan_documentos-formales-entregables-pt.md`.*
