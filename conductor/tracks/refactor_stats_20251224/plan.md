# Plan: Comprehensive Statistical Engine Refactoring & Integration

## Phase 1: Preparation and Analysis
- [ ] Task: Create `R/` directory structure if not fully organized and back up `app.R` and `report_template.Rmd`.
- [ ] Task: Analyze `app.R` to identify all code blocks performing statistical calculations. Map them to the target modules defined in the spec.
- [ ] Task: Create a small "reference dataset" (or identifying an existing one) to use for verifying that the refactored code produces the exact same output as the current code.
- [ ] Task: Conductor - User Manual Verification 'Preparation and Analysis' (Protocol in workflow.md)

## Phase 2: Core Statistical Modules (Extraction)
- [ ] Task: Implement `R/stats_outliers.R`. Create functions for Grubbs' test with standardized error handling.
- [ ] Task: Implement `R/stats_consensus.R`. Extract Algorithm A, MADe, and nIQR logic. Ensure robust handling of `NA`s.
- [ ] Task: Implement `R/stats_scoring.R`. Create functions for z, z', zeta, and En scores.
- [ ] Task: Implement `R/stats_homogeneity_stability.R`. Extract ANOVA and stability logic. **Crucial:** Add the explicit uncertainty calculation components here.
- [ ] Task: Verify all new functions against the reference dataset manually or with a simple script.
- [ ] Task: Conductor - User Manual Verification 'Core Statistical Modules' (Protocol in workflow.md)

## Phase 3: Application Integration
- [ ] Task: Source the new R files at the beginning of `app.R`.
- [ ] Task: Refactor `app.R` - Module 1 (Homogeneity & Stability): Replace inline code with calls to `R/stats_homogeneity_stability.R`.
- [ ] Task: Refactor `app.R` - Module 2 (PT Preparation): Replace inline outlier/consensus logic with calls to `R/stats_outliers.R` and `R/stats_consensus.R`.
- [ ] Task: Refactor `app.R` - Module 3 (PT Scores): Replace inline scoring logic with calls to `R/stats_scoring.R`.
- [ ] Task: Run the app and verify functionality using the reference dataset. Ensure UI elements (alerts, tables) still render correctly.
- [ ] Task: Conductor - User Manual Verification 'Application Integration' (Protocol in workflow.md)

## Phase 4: Report Integration
- [ ] Task: Update `reports/report_template.Rmd` to source the new R files.
- [ ] Task: Replace duplicated logic in the Rmd file with calls to the shared functions.
- [ ] Task: Generate a sample report and compare it against a report generated with the old version (if available) or the app output to ensure consistency.
- [ ] Task: Conductor - User Manual Verification 'Report Integration' (Protocol in workflow.md)

## Phase 5: Final Verification & Cleanup
- [ ] Task: detailed code review of the new R files to ensure they meet the Style Guide.
- [ ] Task: Remove the backup files.
- [ ] Task: Conductor - User Manual Verification 'Final Verification' (Protocol in workflow.md)
