# Plan — POE de estimación de incertidumbre (SO2, CO, NO, NO2, O3)

Fecha: 2026-08-17
Alcance: procedimiento estándar operativo (POE) que cubra (a) estimación GUM de la
incertidumbre de medición por gas en el laboratorio, y (b) la cadena de incertidumbre
del ensayo de aptitud implementada en pt_app (ISO 13528:2022 / ISO 17043:2023).

---

## 1. Estado actual (código auditado)

| Etapa | Fórmula | Ubicación |
|---|---|---|
| u Tipo A horaria (referencia) | `u_h = sd_h / sqrt(60)` | `R/preprocessing/uncertainty_report.R` |
| u(x_pt) homogeneidad | `1.25 * MADe_hom / sqrt(g)` | `app.R:1100`, `R/pt_homogeneity.R:94-98` |
| u(x_pt) nIQR | `1.25 * nIQR / sqrt(g)` | `app.R:994` |
| u(x_pt) consenso/AlgoA | `1.25 * MADe / sqrt(n)` | `app.R:1229` |
| u(x_pt) experto | `0.003 * x_pt` | `app.R:3205` |
| Combinación | `u_xpt_def = sqrt(u_xpt^2 + u_hom^2 + u_stab^2)` | `app.R:1507`, `app.R:3244` |
| Criterio | `u_xpt_def <= 0.3 * sigma_pt` | `app.R:3217` |
| u participante | `u_value` o `U(xi)/k`, promediado por combinación | `app.R:534-575`, `app.R:641` |
| Scores | z, z', zeta, En | `R/pt_scores.R` |

### Brechas identificadas
1. No hay presupuesto de incertidumbre documentado por gas (tipo B): patrón, dilutor,
   deriva, linealidad, convertidor NO2, fotómetro O3, T/P/HR.
2. `0.003 * x_pt` (opción experto) carece de justificación trazable.
3. `mean(u_value)` promedia incertidumbres en vez de propagarlas.
4. `u_h` minutal no se combina con componentes tipo B para formar `u` de la referencia.
5. Sin criterio documentado de grados de libertad efectivos / elección de k.

---

## 2. Estructura propuesta del POE

Código sugerido: `DG-PSEA-XX POE Estimacion de Incertidumbre Gases`.

1. Objeto y alcance (SO2, CO, NO, NO2, O3; rangos PT nivel 1..5)
2. Documentos de referencia: GUM (JCGM 100:2008), ISO 13528:2022, ISO 17043:2023,
   ISO/IEC 17025:2017, EPA 40 CFR Part 50 App., ISO 6143, formatos F-PSEY-47/49/51/61/62
3. Definiciones y símbolos (u, U, k, x_pt, sigma_pt, u_xpt_def, ss, sw)
4. Responsabilidades
5. Modelo de medición general y por gas
6. Identificación de fuentes (diagrama causa-efecto por gas)
7. Cuantificación de componentes (tipo A y tipo B, con distribuciones y divisores)
8. Combinación, grados de libertad efectivos (Welch-Satterthwaite), factor k
9. Incertidumbre en el contexto PT: u(x_pt), u_hom, u_stab, combinación y criterio 0.3·sigma_pt
10. Reporte: cifras significativas, redondeo, formato en CSV de carga (`u_value`, `u_exp`, `k`)
11. Verificación y validación del cálculo (casos de prueba, testthat)
12. Registros y anexos (plantillas de presupuesto por gas)

---

## 3. Contenido técnico por gas (secciones 5-7)

Modelo base para gases con cilindro + dilución:

    C = C_cil * (Q_gas / (Q_gas + Q_dil)) * f_cal + C_0

Componentes a tabular por gas:

- **SO2** (F-PSEY-62): pureza/certificado del cilindro, MFC gas y dilución, deriva entre
  calibraciones, no-linealidad, ruido/repetibilidad, cero residual, interferencia H2O/HC.
- **CO** (F-PSEY-47): certificado cilindro, dilución, resolución NDIR, deriva de cero y span,
  interferencia H2O/CO2, temperatura de celda.
- **NO** (F-PSEY-61): certificado NO/N2, dilución, blanco de cero, ruido de
  quimioluminiscencia, deriva, presión de cámara.
- **NO2**: vía GPT — incertidumbre del O3 generado, eficiencia del convertidor, completitud
  de la titulación, tiempo de residencia; o vía tubo de permeación — tasa de permeación,
  temperatura del baño, caudal portador.
- **O3** (F-PSEY-49): fotómetro UV patrón — sección eficaz de absorción, longitud de celda,
  T y P de celda, deriva de lámpara, ruido, linealidad del generador; aire cero
  (F-PSEY-51) como componente de blanco.

Cada componente: fuente, valor, distribución (normal/rectangular/triangular), divisor,
coeficiente de sensibilidad, contribución u_i(y), grados de libertad.

---

## 4. Fases de ejecución

| Fase | Entregable | Depende de |
|---|---|---|
| F1 | Extracción de fórmulas y componentes desde los .xlsm F-PSEY-47/49/51/61/62 | archivos en `data_use_cases/` |
| F2 | Tabla consolidada de fuentes por gas (matriz gas x componente) | F1 |
| F3 | Redacción de secciones 1-4 (marco documental) | — |
| F4 | Redacción de secciones 5-8 (modelo, presupuesto, combinación, k) | F2 |
| F5 | Redacción de sección 9 (cadena PT), alineada verbatim con `app.R` y `R/pt_*.R` | auditoría §1 |
| F6 | Plantillas Excel/CSV de presupuesto por gas + hoja de ejemplo numérico | F4 |
| F7 | Casos de prueba y `tests/testthat/test-uncertainty-budget.R` | F6 |
| F8 | Revisión cruzada, control documental en `Entregables_pt_app/00_control_documental` | F3-F7 |

---

## 5. Decisiones pendientes (requieren confirmación)

1. ¿El POE cubre solo la referencia CalAire o también prescribe cómo los participantes
   deben reportar `u_value`? (afecta el alcance y el formato de carga)
2. Reemplazar o justificar `0.003 * x_pt` en la opción experto.
3. ¿Sustituir `mean(u_value)` por propagación `sqrt(sum(u_i^2))/n` cuando la combinación
   agrupa varias réplicas?
4. Criterio de k: fijo k=2 o calculado por Welch-Satterthwaite.
5. Formato final: Markdown en repo + DOCX/PDF derivado por el pipeline de entregables.
