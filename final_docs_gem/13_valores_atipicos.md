# Módulo Shiny: Valores Atípicos

## 1. Descripción General
Este módulo realiza la detección estadística de valores atípicos utilizando la prueba de Grubbs. Ayuda a identificar participantes con resultados anómalos antes de la fase principal de puntuación.

**Ubicación del Archivo:** `cloned_app.R` (Pestaña "Valores Atípicos")

---

## 2. Implementación

### 2.1 Prueba de Grubbs
Utilizamos la función `outliers::grubbs.test()`.

*   **Lógica:**
    1.  Calcula el estadístico G: $G = \frac{\max|x_i - \bar{x}|}{s}$.
    2.  Compara G con el valor crítico.
    3.  Si $p < 0.05$, el valor más alejado se marca como atípico.

### 2.2 El Reactivo `grubbs_summary()`
Construye una tabla maestra de valores atípicos.

**Columnas:**
*   `Contaminante`
*   `Nivel`
*   `valor p`
*   `¿Atípico Detectado?` (Sí/No)
*   `ID Sospechoso` (ID del Participante del atípico)
*   `Valor Sospechoso`

### 2.3 Indicadores Visuales

*   **Diagramas de Caja (Boxplots):** Diagramas estándar de caja y bigotes donde los puntos fuera de los bigotes (1.5 * RIQ) son atípicos visuales.
*   **Histogramas:** Barras coloreadas o marcadores superpuestos indican los valores marcados.

---

## 3. Integración con Puntuación
**Nota Importante:** Los valores atípicos detectados **NO** se excluyen automáticamente del Algoritmo A o de los métodos de puntuación robustos (el Algoritmo A los maneja naturalmente). Sin embargo, *deben* ser investigados. Para estadísticas clásicas (media/DE), los valores atípicos deben eliminarse manualmente o excluirse mediante el "Filtro de Participantes" si está implementado.
