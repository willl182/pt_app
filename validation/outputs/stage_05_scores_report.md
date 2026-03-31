# Stage 05 Report - Scores

## Objective
Validate participant-level scores with tripartite comparison (app/R/Python).

## Data
- Input: `data/summary_n13.csv`
- Uncertainty chain reference: `validation/outputs/stage_04_uncertainty_chain.csv`
- Method sections: 3
- Tolerance: 1.0e-09

## Sections Evaluated
- scores_method_2a
- scores_method_2b
- scores_method_3

## Metrics Evaluated
- en_den
- en_score
- m
- result
- sd_value
- sigma_pt
- u_hom
- u_stab
- u_xi_expanded
- u_xpt
- u_xpt_def
- u_xpt_expanded
- uncertainty_std
- x_pt
- z_den
- z_prime_den
- z_prime_score
- z_score
- zeta_den
- zeta_score

## Status Summary
- KNOWN_DISCREPANCY: 1296
- PASS: 9504

## Discrepancies
- co_4 | scores_method_2a | part_1 | en_den | KNOWN_DISCREPANCY | diff_app_python=1.67117e-04
- co_4 | scores_method_2a | part_1 | en_score | KNOWN_DISCREPANCY | diff_app_python=1.350287e-03
- co_4 | scores_method_2a | part_1 | u_hom | KNOWN_DISCREPANCY | diff_app_python=1.192369e-03
- co_4 | scores_method_2a | part_1 | u_xpt_def | KNOWN_DISCREPANCY | diff_app_python=6.268898e-04
- co_4 | scores_method_2a | part_1 | u_xpt_expanded | KNOWN_DISCREPANCY | diff_app_python=1.25378e-03
- co_4 | scores_method_2a | part_1 | z_prime_den | KNOWN_DISCREPANCY | diff_app_python=2.780707e-04
- co_4 | scores_method_2a | part_1 | z_prime_score | KNOWN_DISCREPANCY | diff_app_python=9.982196e-02
- co_4 | scores_method_2a | part_1 | zeta_den | KNOWN_DISCREPANCY | diff_app_python=8.355851e-05
- co_4 | scores_method_2a | part_1 | zeta_score | KNOWN_DISCREPANCY | diff_app_python=2.700575e-03
- co_4 | scores_method_2a | part_10 | en_den | KNOWN_DISCREPANCY | diff_app_python=1.794032e-04
- co_4 | scores_method_2a | part_10 | en_score | KNOWN_DISCREPANCY | diff_app_python=8.055229e-04
- co_4 | scores_method_2a | part_10 | u_hom | KNOWN_DISCREPANCY | diff_app_python=1.192369e-03
- co_4 | scores_method_2a | part_10 | u_xpt_def | KNOWN_DISCREPANCY | diff_app_python=6.268898e-04
- co_4 | scores_method_2a | part_10 | u_xpt_expanded | KNOWN_DISCREPANCY | diff_app_python=1.25378e-03
- co_4 | scores_method_2a | part_10 | z_prime_den | KNOWN_DISCREPANCY | diff_app_python=2.780707e-04
- co_4 | scores_method_2a | part_10 | z_prime_score | KNOWN_DISCREPANCY | diff_app_python=4.813334e-02
- co_4 | scores_method_2a | part_10 | zeta_den | KNOWN_DISCREPANCY | diff_app_python=8.970159e-05
- co_4 | scores_method_2a | part_10 | zeta_score | KNOWN_DISCREPANCY | diff_app_python=1.611046e-03
- co_4 | scores_method_2a | part_11 | en_den | KNOWN_DISCREPANCY | diff_app_python=1.551951e-04
- co_4 | scores_method_2a | part_11 | en_score | KNOWN_DISCREPANCY | diff_app_python=2.028104e-03

## Conclusion
- Stage 05 closed without FAIL rows.
