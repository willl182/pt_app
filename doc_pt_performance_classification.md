# **Comprehensive PT Performance Classification Procedure**

This document outlines a comprehensive, 7-category classification system for evaluating participant performance in proficiency testing (PT). This classification is based on the combined assessment of two types of performance scores:

1. **Common Criterion (**$z/z'$**\-score):** Evaluates result accuracy against a common, fitness-for-purpose standard.  
2. **Individual Criterion (**$E\_n$**\-score /** $\\zeta$**\-score):** Evaluates the validity and consistency of the participant's own uncertainty claim.

This system is fully compliant with the principles and statistical methods described in ISO/IEC 17043:2023 and ISO 13528:2022.

## **1\. Inputs per Measurand/Level**

To perform this evaluation, the following data points are required for each measurand at each level:

* **Participant result:** $x\_i$  
* **Participant's expanded uncertainty:** $U(x\_i)$ (with coverage factor, $k \\approx 2$)  
* **Participant's standard uncertainty:** $u(x\_i) \= U(x\_i) / k$  
* **Assigned value:** $X\_{pt}$  
* **Standard uncertainty of assigned value:** $u(X\_{pt})$  
* **Expanded uncertainty of assigned value:** $U(X\_{pt}) \= k \\cdot u(X\_{pt})$  
* **Standard deviation for proficiency assessment:** $\\sigma\_{pt}$ (This is the "common criterion" and may be a fixed value, a percentage, or derived from a formula like $a \\cdot X\_{pt} \+ b$).

## **2\. Expanded Explanation of Statistical Indicators**

### **2.1. z-score / z'-score (Accuracy Indicator)**

* **Formulas:**  
  * **z-score:** $z \= \\frac{x\_i \- X\_{pt}}{\\sigma\_{pt}}$ (Used when $u(X\_{pt})$ is negligible)  
  * **z′-score:** $z' \= \\frac{x\_i \- X\_{pt}}{\\sqrt{\\sigma\_{pt}^2 \+ u^2(X\_{pt})}}$ (Used when $u(X\_{pt})$ is significant)  
* **Purpose:** Measures **accuracy** (bias) by comparing the participant's deviation ($x\_i \- X\_{pt}$) to a common, fitness-for-purpose criterion ($\\sigma\_{pt}$). The $z'$-score is the more correct form as it properly accounts for the uncertainty of the assigned value.  
* **Interpretation (ISO 13528):**  
  * $|z'| \\le 2.0$ $\\rightarrow$ **Satisfactory** accuracy.  
  * $2.0 \< |z'| \< 3.0$ $\\rightarrow$ **Questionable** (Warning signal, possible systematic bias).  
  * $|z'| \\ge 3.0$ $\\rightarrow$ **Unsatisfactory** (Action signal, significant deviation).  
* **Analytical Meaning:**  
  * This score answers the question: "Is the participant's result close enough to the assigned value, according to the performance level expected from all competent participants?"  
  * A high $|z'|$ score indicates a significant accuracy problem (e.g., calibration bias, sample handling error, systematic issue) relative to the common standard.

### **2.2. $\\zeta$ (Zeta) Score (Precision & Uncertainty Consistency)**

* **Formula:** $\\zeta \= \\frac{x\_i \- X\_{pt}}{\\sqrt{u^2(x\_i) \+ u^2(X\_{pt})}}$  
* **Purpose:** Assesses whether the observed bias ($x\_i \- X\_{pt}$) is statistically consistent with the stated **standard uncertainties** ($u$) of both the participant and the reference.  
* **Interpretation (ISO 13528:2022 §9.6.2):**  
  * $|\\zeta| \\le 2.0$ $\\rightarrow$ **Satisfactory** (The deviation is statistically consistent with the combined standard uncertainties).  
  * $2.0 \< |\\zeta| \< 3.0$ $\\rightarrow$ **Questionable** (The deviation is marginally consistent; the uncertainty evaluation should be reviewed).  
  * $|\\zeta| \\ge 3.0$ $\\rightarrow$ **Unsatisfactory** (The deviation is statistically inconsistent with the uncertainties, strongly implying the participant's $u(x\_i)$ is underestimated).  
* **Analytical Meaning:**  
  * This score answers the question: "Given my claimed standard uncertainty, is my result statistically consistent with the assigned value?"  
  * It uses the same numerical thresholds as the $z'$-score but provides a diagnostic of the *uncertainty estimation process itself*. A high $|\\zeta|$-score is a direct flag for an underestimated uncertainty budget.

### **2.3. $E\_n$ Score (Metrological Compatibility)**

* **Formula:** $E\_n \= \\frac{x\_i \- X\_{pt}}{\\sqrt{U^2(x\_i) \+ U^2(X\_{pt})}}$  
* **Purpose:** Uses **expanded uncertainties** ($U$, typically at 95% confidence) to determine if the participant’s result and the assigned value are **metrologically compatible**.  
* **Interpretation (ISO 13528:2022 §9.7):**  
  * $|E\_n| \\le 1.0$ $\\rightarrow$ **Consistent / Satisfactory.** The deviation is "covered" by the combined expanded uncertainties. The two results (participant and reference) are compatible.  
  * $|E\_n| \> 1.0$ $\\rightarrow$ **Inconsistent / Unsatisfactory.** The deviation is larger than the combined expanded uncertainties can explain. This indicates the participant's result is not compatible with the assigned value.  
* **Analytical Meaning:**  
  * This score answers the question: "Do my measurement result (with its 95% uncertainty interval) and the assigned value (with its 95% uncertainty interval) overlap?"  
  * An $|E\_n| \> 1.0$ is a critical failure, indicating either a significant bias, a severely underestimated uncertainty, or both. It is a direct challenge to the validity of the reported result.

## **3\. Unified Classification Criteria**

This 7-category system provides a complete diagnosis by combining the scores.

* **a1 – Fully Satisfactory (Best Result)**  
  * **Criteria:** $|z'| \\le 2.0$ AND $|E\_n| \\le 1.0$ AND $U(x\_i) \< 2\\sigma\_{pt}$  
  * **Assessment:** Accurate result with a realistic and fit-for-purpose measurement uncertainty (MU).  
  * **Action:** Maintain routine QA.  
* **a2 – Satisfactory, but Conservative Uncertainty**  
  * **Criteria:** $|z'| \\le 2.0$ AND $|E\_n| \\le 1.0$ AND $U(x\_i) \\ge 2\\sigma\_{pt}$  
  * **Assessment:** Accurate result, but the claimed MU is likely overestimated (larger than the common requirement).  
  * **Action:** Review MU budget for potential overestimations.  
* **a3 – Satisfactory, but Uncertainty Underestimated**  
  * **Criteria:** $|z'| \\le 2.0$ AND $|E\_n| \> 1.0$  
  * **Assessment:** The result is accurate (passes the common $z'$ criterion), but the claimed MU is too small to cover its own deviation.  
  * **Action:** This is a critical finding. Investigate the uncertainty budget (per ISO/IEC 17025: 7.6).  
* **a4 – Questionable, Valid due to High Uncertainty**  
  * **Criteria:** $2.0 \< |z'| \< 3.0$ AND $|E\_n| \\le 1.0$  
  * **Assessment:** Borderline accuracy, but the participant's large MU claim "saves" the result, making it compatible. The performance is poor, but the uncertainty is "honest."  
  * **Action:** Investigate the source of bias.  
* **a5 – Questionable Result & Underestimated Uncertainty**  
  * **Criteria:** $2.0 \< |z'| \< 3.0$ AND $|E\_n| \> 1.0$  
  * **Assessment:** Borderline accuracy (warning signal) AND the claimed MU is too small to cover this deviation.  
  * **Action:** Requires investigation for both bias and uncertainty evaluation.  
* **a6 – Unsatisfactory, Valid due to High Uncertainty**  
  * **Criteria:** $|z'| \\ge 3.0$ AND $|E\_n| \\le 1.0$  
  * **Assessment:** Inaccurate result (action signal), but the participant's claimed MU is so large that it correctly covers this large deviation.  
  * **Action:** Initiate immediate corrective action to find and eliminate the large bias.  
* **a7 – Completely Unsatisfactory (Critical Failure)**  
  * **Criteria:** $|z'| \\ge 3.0$ AND $|E\_n| \> 1.0$  
  * **Assessment:** Highly inaccurate result AND the claimed MU is too small to cover it. This indicates a serious failure in both the measurement process and the quality system.  
  * **Action:** Initiate immediate and thorough corrective action.

## **4\. Edge Conditions**

* **Negligible** $u(X\_{pt})$**:** If $u(X\_{pt}) \\le 0.3 \\cdot \\sigma\_{pt}$ (per ISO 13528:2022 §9.2.1), the uncertainty of the assigned value is considered negligible. In this case, $z' \\approx z$ and the simpler $z$-score formula may be used.  
* **Missing** $U(x\_i)$**:** If a participant omits their uncertainty, $E\_n$ and $\\zeta$ scores cannot be calculated. The participant must be classified using the $z'$-score only and their report annotated to show MU was not provided.  
* **Bimodality:** If the participant data shows a bimodal distribution (e.g., due to two different methods), a consensus value is not appropriate. The data should be separated by method subgroup and evaluated independently, if possible.

## **5\. Report**

A comprehensive report should include:

* Final Classification (a1–a7)  
* A density plot of all participant $z$/$z'$-scores.  
* A scatter plot of $z$/$z'$-score vs. $E\_n$-score with colored zones for the 7 categories.  
* A clear, narrative interpretation of the participant's performance and any required actions.

## **6\. Advantages of This System**

* Provides comprehensive analytical (accuracy) and metrological (uncertainty) insight.  
* Uses $\\zeta$-score for an enhanced bias-vs-uncertainty interpretation, as recommended in ISO 13528\.  
* Fully compliant with ISO/IEC 17043:2023 and ISO 13528:2022.  
* Enables clear, transparent feedback by separating the assessment of bias ($z'$) from uncertainty realism ($\\zeta$) and metrological compatibility ($E\_n$).