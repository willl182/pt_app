# Shiny Module: Outliers

## 1. Overview
This module performs statistical outlier detection using the Grubbs' test. It helps identify participants with anomalous results before the main scoring phase.

**File Location:** `cloned_app.R` ("Valores Atípicos" tab)

---

## 2. Implementation

### 2.1 Grubbs' Test
We use the `outliers::grubbs.test()` function.

*   **Logic:**
    1.  Calculates the G statistic: $G = \frac{\max|x_i - \bar{x}|}{s}$.
    2.  Compares G to critical value.
    3.  If $p < 0.05$, the furthest value is flagged as an outlier.

### 2.2 The `grubbs_summary()` Reactive
Constructs a master table of outliers.

**Columns:**
*   `Pollutant`
*   `Level`
*   `p.value`
*   `Outlier Detected?` (Yes/No)
*   `Suspect ID` (Participant ID of the outlier)
*   `Suspect Value`

### 2.3 Visual Indicators

*   **Boxplots:** Standard box-and-whisker plots where points outside the whiskers (1.5 * IQR) are visual outliers.
*   **Histograms:** Colored bars or overlay markers indicate the flagged values.

---

## 3. Integration with Scoring
**Important Note:** Detected outliers are **NOT** automatically excluded from Algorithm A or robust scoring methods (Algorithm A handles them naturally). However, they *should* be investigated. For classical statistics (mean/SD), outliers must be removed manually or excluded via the "Participant Filter" if implemented.
