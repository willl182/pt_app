# Unified PT Evaluation (Merged ERLAP + UWM)

## Inputs per Measurand/Level
- Participant result: \(x_i\)
- Expanded uncertainty: \(U(x_i)\) (k ≈ 2)
- Assigned value: \(X_{pt}\)
- Standard uncertainty: \(u(X_{pt})\)
- Expanded uncertainty of assigned value: \(U(X_{pt}) = k·u(X_{pt})\)
- Standard deviation for proficiency assessment: \(σ_{pt}\), possibly defined as \(a·X_{pt} + b\) per analyte.

---

## Expanded Explanation of Statistical Indicators

### 1. z-score / z'-score (Accuracy Indicators)
- **Formulas:**
  - z-score: \( z = \frac{x_i - X_{pt}}{σ_{pt}} \)
  - z′-score: \( z' = \frac{x_i - X_{pt}}{\sqrt{σ_{pt}^2 + u^2(X_{pt})}} \)
- **Interpretation:**
  - Measures **accuracy** (bias) by comparing participant deviation to a fitness-for-purpose criterion (σₚₜ).
  - z′ corrects for uncertainty in the assigned value, making it more robust when u(Xₚₜ) is significant.
  - The smaller the |z′| value, the closer the participant result is to the assigned value.
- **Typical thresholds (ISO 13528):**
  - |z′| ≤ 2 → Satisfactory accuracy.
  - 2 < |z′| < 3 → Questionable (possible systematic bias).
  - |z′| ≥ 3 → Unsatisfactory (significant deviation).

**Analytical meaning:**
- A small |z′| indicates results that are both trueness- and precision-consistent.
- High |z′| may reveal calibration bias, sample handling errors, or systematic issues.

---

### 2. ζ (Zeta) Score (Precision & Uncertainty Consistency)
- **Formula:** \( ζ = \frac{x_i - X_{pt}}{\sqrt{u^2(x_i) + u^2(X_{pt})}} \)
- **Purpose:** Assesses whether the observed bias is statistically compatible with the stated **standard uncertainties** (u) of both participant and reference.
- **Interpretation (ISO 13528:2022 §9.6.2):**
  - |ζ| ≤ 2 → Satisfactory (bias consistent with expected uncertainty).
  - 2 < |ζ| < 3 → Questionable (marginal consistency; review uncertainty evaluation).
  - |ζ| ≥ 3 → Unsatisfactory (bias exceeds expected range; uncertainty underestimated).

**Analytical meaning:**
- ζ uses the same numerical scale as z/z′ but relies on **standard uncertainties**.
- It provides a finer diagnostic of under- or over-confidence in a participant’s uncertainty model.
- ISO 13528 specifies that ζ may be interpreted using the same 2.0 and 3.0 limits as z/z′ for consistency.

---

### 3. Eₙ Score (Metrological Compatibility)
- **Formula:** \( E_n = \frac{x_i - X_{pt}}{\sqrt{U^2(x_i) + U^2(X_{pt})}} \)
- **Purpose:** Uses **expanded uncertainties (U)** to determine if the participant’s result is **metrologically compatible** with the assigned value.
- **Interpretation:**
  - |Eₙ| < 1 → Consistent; deviation is within combined uncertainties.
  - |Eₙ| ≥ 1 → Inconsistent; bias exceeds justified range or uncertainty underestimated.

**Analytical meaning:**
- |Eₙ| < 1 validates both accuracy and uncertainty statement.
- |Eₙ| > 1 indicates inconsistency, demanding review of traceability, calibration, or uncertainty modeling.
- Correlation between z′ and Eₙ helps interpret whether the issue is accuracy, precision, or reporting.

---

## Unified Classification Criteria (Bullet Format)

- **a1 – Fully Satisfactory:**
  - |z'| ≤ 2
  - |Eₙ| < 1
  - U(xᵢ) < 2σₚₜ
  - → Accurate result with realistic MU. Maintain routine QA.

- **a2 – Satisfactory but Conservative:**
  - |z'| ≤ 2
  - |Eₙ| < 1
  - U(xᵢ) ≥ 2σₚₜ
  - → Accurate result but MU likely overestimated.

- **a3 – Satisfactory with Underestimated MU:**
  - |z'| ≤ 2
  - |Eₙ| ≥ 1
  - → Accurate result, but MU too small to justify deviation. Review uncertainty estimation.

- **a4 – Questionable but Acceptable:**
  - 2 < |z'| < 3
  - |Eₙ| < 1
  - → Borderline bias, but large MU covers it. Keep monitoring.

- **a5 – Questionable and Inconsistent:**
  - 2 < |z'| < 3
  - |Eₙ| ≥ 1
  - → Significant bias not justified by MU. Requires investigation.

- **a6 – Unsatisfactory but MU Covers Deviation:**
  - |z'| ≥ 3
  - |Eₙ| < 1
  - → Large deviation but MU too broad. Review calibration and MU realism.

- **a7 – Unsatisfactory (Critical):**
  - |z'| ≥ 3
  - |Eₙ| ≥ 1
  - → Inaccurate result and underestimated MU. Immediate corrective action required.

---

## Edge Conditions
- If u(Xₚₜ) ≤ 0.3σₚₜ → z' ≈ z.
- If participant omits U(xᵢ) → classify using z' only; annotate MU = missing.
- If consensus value shows bimodality → separate by method subgroup before classification.

---

## Reporting Template
- Include xᵢ, Xₚₜ, σₚₜ, u(Xₚₜ), U(xᵢ), z', ζ, Eₙ, and classification.
- Histogram of z'-scores.
- Scatter plot z' vs Eₙ with colored zones (a1–a7).
- Narrative interpretation for each participant.

---

## Advantages
- Provides comprehensive analytical and metrological insight.
- Adds ζ for enhanced bias–uncertainty interpretation.
- Fully compliant with ISO/IEC 17043:2023 and ISO 13528:2022.
- Enables transparency between bias (z′), uncertainty realism (ζ), and compatibility (Eₙ).



---

## Decision Flow (Text-Only)
1) Compute z′ and Eₙ for each measurand/level.
2) Apply z′ thresholds (≤2; 2–3; ≥3) for accuracy status.
3) Apply Eₙ threshold (<1; ≥1) for uncertainty adequacy (metrological compatibility).
4) Compare participant U(xᵢ) with 2σₚₜ to qualify uncertainty as realistic (<2σₚₜ) or conservative (≥2σₚₜ).
5) Assign category a1–a7 using the unified criteria.
6) Record ζ (optional diagnostic per ISO 13528) to check standard-uncertainty consistency.

---

## Category-by-Category Guidance (Rationale • Risks • Actions)

### a1 – Fully Satisfactory
- **Rationale:** Accurate (|z′|≤2) and metrologically compatible (|Eₙ|<1) with realistic MU (U<2σₚₜ).
- **Risks:** None material; maintain control charts and routine checks.
- **Actions:** Maintain method; keep traceability evidence current; use as internal benchmark.
- **Audit Note:** Supports ISO/IEC 17043 §7.4.2(b) expert comment: “Result accurate and uncertainty appropriate.”

### a2 – Satisfactory but Conservative
- **Rationale:** Accurate and compatible, but MU is large (U≥2σₚₜ) affecting fitness-for-purpose.
- **Risks:** Reduced decision capability; potential over-cost in calibration/QA.
- **Actions:** Review uncertainty budget; identify over‑conservative components (e.g., drift, linearity, environmental terms); optimize.
- **Audit Note:** Evidence of MU review (ISO/IEC 17025 §7.6); plan to reduce U while keeping coverage.

### a3 – Satisfactory with Underestimated MU
- **Rationale:** Passes common criterion (|z′|≤2) but fails compatibility (|Eₙ|≥1): MU too small for observed deviation.
- **Risks:** Nonconformity in uncertainty evaluation; risk of false conformity decisions.
- **Actions:** Root-cause on MU model; re‑evaluate Type A/B components, correlation, coverage factor, and propagation; update statement of MU.
- **Audit Note:** Record corrective action per ISO/IEC 17025 §7.10; update uncertainty files and scope.

### a4 – Questionable but Acceptable
- **Rationale:** Borderline accuracy (2<|z′|<3) but still compatible (|Eₙ|<1) due to large MU.
- **Risks:** Hidden systematic bias masked by broad MU; drift likely.
- **Actions:** Investigate bias (calibration, zero/span, linearity); shorten calibration interval; enhance QC frequency.
- **Audit Note:** Document justification that MU reflects actual variability; plan for bias removal.

### a5 – Questionable and Inconsistent
- **Rationale:** Borderline accuracy and MU inadequate (|Eₙ|≥1).
- **Risks:** Both bias and MU model deficiencies.
- **Actions:** Immediate review of calibration chain, reference materials, environmental controls; repeat checks; update MU; consider method adjustment.
- **Audit Note:** Open corrective action; effectiveness verification required in next PT or internal check.

### a6 – Unsatisfactory but MU Covers Deviation
- **Rationale:** Poor accuracy (|z′|≥3) yet compatible (|Eₙ|<1) due to very large MU.
- **Risks:** Measurement process not fit‑for‑purpose; decisions unreliable.
- **Actions:** Urgent root-cause on large bias; service/repair, recalibrate, re‑validate method; aim to reduce MU and eliminate bias.
- **Audit Note:** Report as unsatisfactory accuracy with mitigating MU; track to closure before next round.

### a7 – Completely Unsatisfactory
- **Rationale:** Inaccurate and MU too small (|z′|≥3 and |Eₙ|≥1).
- **Risks:** Serious failure in process control and uncertainty evaluation.
- **Actions:** Containment (suspend reporting if applicable), full RCA (Ishikawa/5‑Why), corrective action, re‑validation; management review.
- **Audit Note:** Major nonconformity candidate; evidence of effectiveness required.

---

## Diagnostic Checklist (apply to any non‑a1 result)
- **Traceability:** CRM certificates current; gas standards level; ozone photometer level; uncertainty of references.
- **Calibration:** Zero/span checks; linearity; response time; interference tests; drift records.
- **Environment:** Temperature, humidity, pressure logs; stability during runs.
- **Sampling/Setup:** Leaks, flow rates, manifold backpressure, tubing materials, filters.
- **Data Handling:** Averaging windows, exclusions, outlier tests per ISO 13528; unit conversions.
- **Uncertainty Model:** Components completeness, correlations, coverage factor, propagation method; alignment of u vs U.

---

## Outliers & Grouping (per ISO 13528)
- Use robust statistics for consensus values; apply outlier detection to **participants**, not to hide provider issues.
- When multimodality by method is detected, **split by subgroup** before performance assignment.

---

## Reporting Phrases (ready-to-use)
- **a1:** “Satisfactory accuracy and metrological compatibility; MU is fit‑for‑purpose.”
- **a2:** “Satisfactory; MU conservative relative to σₚₜ—optimization recommended.”
- **a3:** “Satisfactory accuracy; MU underestimated—revise uncertainty evaluation.”
- **a4:** “Borderline accuracy; compatible due to large MU—investigate bias.”
- **a5:** “Questionable result; MU inadequate—corrective action on bias and MU.”
- **a6:** “Unsatisfactory accuracy; compatibility due to large MU—eliminate bias and reduce MU.”
- **a7:** “Completely unsatisfactory—urgent corrective and re‑validation required.”

---

## KPIs for Scheme Oversight
- % participants in a1–a3 (satisfactory band).
- Median |z′| and IQR by measurand/level.
- % with |Eₙ|<1; distribution of U(xᵢ)/ (2σₚₜ).
- Recurrence of a4–a7 by lab and analyte (trend over rounds).

---

## Implementation Notes
- Compute and store z, z′, ζ, and Eₙ for transparency; report z′ and Eₙ prominently.
- Document σₚₜ source (model a·X+b or historical) and u(Xₚₜ) evaluation.
- Maintain versioned calculations and audit trail (inputs, formulas, outputs).

