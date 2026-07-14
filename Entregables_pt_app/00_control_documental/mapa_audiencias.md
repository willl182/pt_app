# Mapa de audiencias y documentos

**Versión:** 1.0  
**Fecha:** 2026-07-14

## Tres recorridos separados

| Audiencia | Necesidad principal | Contenido visible primero | Detalle que se mueve a anexos |
|---|---|---|---|
| Usuario y operación | Preparar archivos, ejecutar tareas, interpretar resultados y recuperarse de errores | Propósito, prerrequisitos, pasos, resultado esperado, “qué significa” y “qué hacer si…” | Código, firmas de funciones, arquitectura y logs extensos |
| Soporte técnico | Instalar, configurar, desplegar, mantener y diagnosticar | Requisitos del entorno, dependencias, configuración, respaldo, seguridad y diagnóstico | Evidencia de validación detallada y cálculos paso a paso |
| Validación y auditoría | Comprobar alcance, método, trazabilidad, resultados y límites | Versión, criterios, matriz de pruebas, evidencia, desviaciones, riesgos y aprobaciones | Instrucciones operativas básicas ya cubiertas por el manual |

## Asignación primaria

| Documento | Audiencia primaria | Audiencia secundaria |
|---|---|---|
| E01 Repositorio inicial | Validación y auditoría | Soporte técnico |
| E02 Funciones usadas | Soporte técnico | Validación y auditoría |
| E03 Cálculos PT | Usuario y operación | Validación y auditoría |
| E04 Puntajes | Usuario y operación | Validación y auditoría |
| E05 Interfaz | Usuario y operación | Soporte técnico |
| E06 Manual | Usuario y operación | Soporte técnico |
| E07 Dashboards | Usuario y operación | Validación y auditoría |
| E08 Beta/final | Soporte técnico | Usuario y operación |
| E09 Informe final | Validación y auditoría | Responsables contractuales |

## Regla de redacción

Cada fuente identifica una audiencia primaria en sus metadatos. El cuerpo
principal responde en este orden: para qué sirve, qué necesita el lector, qué
hace, qué obtiene y cómo actúa ante un problema. Fórmulas, código, inventarios
detallados y logs se incluyen solo cuando la audiencia los necesita o se
remiten a anexos con un ID trazable.
