# ptcalc News

## Version 0.4.0 (2026-01-28)

### Documentation
- Updated documentation to reflect app.R line count (5,685 lines)
- Verified all function signatures are current
- Updated version references to 0.4.0

### Bug Fixes
- None (no changes to package code)

### Maintenance
- Updated DESCRIPTION version to 0.4.0
- Updated NEWS.md

---

## Version 0.1.0 (2025-01-26)

Initial release of ptcalc package for proficiency testing calculations.

### Added
- `calculate_z_score()`: Z-score calculation per ISO 13528:2022
- `calculate_z_prime_score()`: Z'-score calculation
- `calculate_zeta_score()`: Zeta-score calculation with uncertainty
- `calculate_en_score()`: En-score calculation for interlaboratory comparisons
- `run_algorithm_a()`: Algorithm A for robust statistics (mean, SD, NIQR)
- `calculate_homogeneity_stats()`: Homogeneity assessment statistics
- `calculate_homogeneity_criterion_expanded()`: Expanded homogeneity criterion with degrees of freedom
- `calculate_stability_stats()`: Stability assessment statistics
- `calculate_stability_criterion_expanded()`: Expanded stability criterion with degrees of freedom
- `calculate_u_hom()`: Uncertainty for homogeneity assessment
- `calculate_u_stab()`: Uncertainty for stability assessment
- `evaluate_z_score_vec()`: Vectorized Z-score evaluation
- `evaluate_en_score_vec()`: Vectorized En-score evaluation
- `evaluate_homogeneity()`: Evaluate homogeneity assessment results
- `evaluate_stability()`: Evaluate stability assessment results

### Features
- All calculations follow ISO 13528:2022 and ISO 17043:2024 standards
- Robust statistics for proficiency testing
- Support for interlaboratory comparison (En scores)
- Comprehensive error handling and NA propagation
- Vectorized functions for batch processing
