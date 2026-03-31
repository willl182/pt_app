# Plan de Implementación Consolidado: ag_gem31pro.md

## 1. Resumen y Objetivo General
Este plan integra y consolida los requerimientos y estrategias de validación post-Algoritmo A definidos en `plan_a2.md` y `logs/plans/260330_1118_plan_a1_validacion_post_algoA.md`. El objetivo es establecer una validación cruzada robusta, reproducible y auditable de los cálculos "downstream" (posteriores a Algoritmo A) en la aplicación `pt_app`. 

Se realizará una comparación a tres bandas para 15 combinaciones objetivo de contaminantes y niveles usando `summary_n13.csv`, `homogeneity_n13.csv` y `stability_n13.csv`.

## 2. Alcance de la Validación
Se validará toda la cadena de cálculos tras Algoritmo A:
- **Estadísticos Robustos**: Mediana, MAD, MADe, Q1, Q3, IQR, nIQR.
- **Homogeneidad y Estabilidad**: Evaluación de las métricas $s_{w}$, $s_{s}$, $d_{max}$ y cumplimiento de criterios ($c$, $c_{expandido}$).
- **Incertidumbres**: $\sigma_{pt}$, $u(x_{pt})$, $u_{hom}$, $u_{stab}$, $u(x_{pt\_def})$, $U(x_{pt})$.
- **Puntajes de Desempeño**: z, z', $\zeta$ (zeta) y $E_n$, junto a sus evaluaciones cualitativas.
- **Consolidación**: Resúmenes globales dependientes de estos cálculos.

## 3. Combinaciones Objetivo (15 Combos)
Se utilizarán los niveles 1, 3 y 5 de cada contaminante, ordenados por concentración ascendente:
- **CO**: `0-μmol/mol`, `4-μmol/mol`, `8-μmol/mol`
- **NO**: `0-nmol/mol`, `81-nmol/mol`, `121-nmol/mol`
- **NO2**: `0-nmol/mol`, `60-nmol/mol`, `120-nmol/mol`
- **O3**: `0-nmol/mol`, `80-nmol/mol`, `180-nmol/mol`
- **SO2**: `0-nmol/mol`, `60-nmol/mol`, `100-nmol/mol`

## 4. Enfoque de Validación y Archivos de Salida

Para reconciliar la estructura de salida de A1 (por sección) y A2 (por combinación), generaremos **archivos analíticos detallados por combinación objetivo** y un **archivo de resumen global consolidado**. 

### Nomenclatura y Directorio
Se utilizará el directorio `validation/` para almacenar los scripts y salidas:
- `validation/generate_post_algoA_validation.R`
- `validation/generate_post_algoA_validation.py`
- Salidas en: `validation/combo_reports/` e `validation/section_reports/`

### Scripts de Validación
Se emplearán dos scripts independientes para hacer la validación cruzada contra el core de la `app.R`:
1. **Script R (`generate_post_algoA_validation.R`)**: Extrae y replica exactamente la lógica de App.R, además genera los archivos reportes Excel.
2. **Script Python (`generate_post_algoA_validation.py`)**: Reimplementación independiente puramente matemática de las fórmulas (sin dependencias de R). Garantiza el "Double-Check".

### Archivos Excel Resultantes
El script R producirá 15 archivos `.xlsx`, uno por combinación (esquema A2).
Convención de nombres: `validation/combo_reports/A1A2_CO_0_umol.xlsx`, etc.
Cada Excel constará de las siguientes hojas analíticas, integrando las 5 secciones de A1:
- `01_Robust_Stats`: Comparación Mediana, MADe, nIQR.
- `02_Homogeneity`: Evaluaciones de homogeneidad, $\sigma_{pt}$.
- `03_Stability`: Evaluaciones de estabilidad y $u_{stab}$.
- `04_Uncertainties`: Propagación de incertidumbres y comparativas entre métodos.
- `05_Scores`: Cálculo de los 4 puntajes (z, z', $\zeta$, En) por participante.
- `06_Comparison_Summary`: Comparativa directa `App.R` vs `R_script` vs `Python_script`. Diferencias y validación con tolerancia final (Match: TRUE/FALSE).

## 5. Reglas de Validación y Tolerancia
- Tolerancia numérica general: `1e-9` (o `1e-12` en comparativa `R` vs `Python` si aplica).
- Igualdad exacta estricta para etiquetas cualitativas ("Satisfactorio", "Cuestionable", "No satisfactorio").
- Tolerancia Algoritmo A de ser usada: `ALGO_A_TOL = 1e-04`.
- Todo mismatch generará una falla reportada en la hoja `06_Comparison_Summary` indicando combinación, sección y magnitud.

## 6. Secuencia de Ejecución de la Implementación
1. Creación del modelo y helpers en `validation/generate_post_algoA_validation.R`.
2. Desarrollo de la reimplementación pura en `validation/generate_post_algoA_validation.py`.
3. Implementación de las secciones secuencialmente de lo más básico a lo compuesto: _Robust Stats -> Homogeneity -> Stability -> Uncertainties -> Scores_.
4. Generación final de las salidas en Excel.
5. Verificación final: todos los reportes de "Match" deben estar en `TRUE` y no pueden figurar "FAILS" por fuera del nivel 0 (con $\sigma_{pt} \approx 0$).
