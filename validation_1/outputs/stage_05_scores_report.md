# Reporte: Etapa 5 — Scores de Desempeño

**Fecha**: 2026-05-13

## Combos procesados
- O3_0
- O3_180
- O3_80

## Dimensiones de validación
- Combos: 3
- Métodos: 4
- Participantes por combo: 12 (excluido 'ref')
- Métricas por participante/método: 4 (solo numéricas)
- **Total comparaciones**: 576

## Métodos de valor asignado
- Método 1: valor de referencia: 144 comparaciones
- Método 2a: consenso MADe: 144 comparaciones
- Método 2b: consenso nIQR: 144 comparaciones
- Método 3: Algoritmo A: 144 comparaciones

## Resumen PASS/FAIL
- **PASS**: 576
- **FAIL**: 0
- EDGE_CASE: 0
- KNOWN_DISCREPANCY: 0

## Tabla resumida de resultados

### O3_0 (0-nmol/mol)
#### Método 1: valor de referencia

| Participante | z (R/Py) | z' (R/Py) | zeta (R/Py) | En (R/Py) | Estado |
|---|---:|---:|---:|---:|---|
| part_1 | NA / NA | NA / NA | 0.0000 / 0.0000 | 0.0000 / 0.0000 | PASS |
| - | Pendiente | Pendiente | Pendiente | Pendiente | El aplicativo y Excel no están exportados en el CSV actual |

##### Evidencia complementaria - O3_0

| Fuente | Evidencia |
|---|---|
| R/Python | Ver fila de part_1 en la tabla anterior |
| Excel | [PEGAR PANTALLAZO EXCEL O3_0] |
| Aplicativo | [PEGAR PANTALLAZO APP O3_0] |

### O3_80 (80-nmol/mol)
#### Método 1: valor de referencia

| Participante | z (R/Py) | z' (R/Py) | zeta (R/Py) | En (R/Py) | Estado |
|---|---:|---:|---:|---:|---|
| part_1 | 11.8689 / 11.8689 | 1.7835 / 1.7835 | 0.7398 / 0.7398 | 0.3699 / 0.3699 | PASS |
| - | Pendiente | Pendiente | Pendiente | Pendiente | El aplicativo y Excel no están exportados en el CSV actual |

##### Evidencia complementaria - O3_80

| Fuente | Evidencia |
|---|---|
| R/Python | Ver fila de part_1 en la tabla anterior |
| Excel | [PEGAR PANTALLAZO EXCEL O3_80] |
| Aplicativo | [PEGAR PANTALLAZO APP O3_80] |

### O3_180 (180-nmol/mol)
#### Método 1: valor de referencia

| Participante | z (R/Py) | z' (R/Py) | zeta (R/Py) | En (R/Py) | Estado |
|---|---:|---:|---:|---:|---|
| part_1 | 1.1303 / 1.1303 | 0.8264 / 0.8264 | 0.6327 / 0.6327 | 0.3163 / 0.3163 | PASS |
| - | Pendiente | Pendiente | Pendiente | Pendiente | El aplicativo y Excel no están exportados en el CSV actual |

##### Evidencia complementaria - O3_180

| Fuente | Evidencia |
|---|---|
| R/Python | Ver fila de part_1 en la tabla anterior |
| Excel | [PEGAR PANTALLAZO EXCEL O3_180] |
| Aplicativo | [PEGAR PANTALLAZO APP O3_180] |

## Nota
La salida actual de Etapa 5 no exporta el valor del aplicativo ni una columna Excel separada.
El informe muestra un solo participante de referencia por cada combo O3 solicitado.
Los valores de Excel y App deben documentarse con pantallazos junto a la evidencia R/Python de cada combo.

## Conclusión
Etapa PASS
