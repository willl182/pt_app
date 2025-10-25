# Validation Audit – Global Summary

## Scope and Objectives
- Establish a repeatable validation workflow for the PT application datasets and R modules.
- Consolidate cross-cutting findings from the three weekly audit tracks.
- Provide reusable scripts to automate structural and statistical checks.

## Step-by-Step Global Audit
1. **File Inventory** – Confirmed the presence of five raw panel CSVs, four summary tables, and three auxiliary calculation inputs using `validate_general_environment.R`. The script validates file existence, schema signatures, and row/column counts to flag missing resources early. 【F:validation/scripts/validate_general_environment.R†L1-L64】
2. **Schema Verification** – All files expose the expected columns: raw panels share `source_file`/`level`, summary tables match the participant/replicate schema, and auxiliary inputs use the `pollutant/level/replicate/sample_id/value` pattern. No discrepancies surfaced during structural checks. 【F:validation/scripts/validate_general_environment.R†L28-L60】
3. **Record Count Baselines** – Established reference counts (e.g., 300 CO rows, 651 entries in `summary_n7.csv`) to support regression testing. These figures align with the exploratory Python diagnostics and provide anchors for future change detection. 【F:validation/scripts/validate_general_environment.R†L62-L63】【5f85ae†L24-L40】
4. **Consolidated Metrics Review** – Compared numeric ranges across raw panels (CO mean spanning −0.05 to 8.13; NO up to 182.73) and derived data (summary means centred around 66 with SD under 2.14). These ranges confirm consistency between raw and aggregated artefacts. 【bc47fd†L44-L69】【5f85ae†L24-L40】
5. **Issue Escalation Criteria** – Documented thresholds for red flags (missing files, schema drift, out-of-range metrics, or mismatched participant counts). Deviations trigger warnings within the new scripts and should be triaged before deployment.

## Key Global Observations
- **Duplicate Level Entries in Raw Panels** – Each BSW dataset exhibits repeated `level` entries across different source files, reflecting the panel design rather than data duplication. Weekly procedures now log these counts so unintentional duplication can be differentiated from intentional design. 【bc47fd†L71-L79】
- **Stable Summary Statistics** – All summary tables report coherent participant counts (4/7/10/13) and consistent sample groups (`1-10`, `11-20`, `21-30`), indicating the aggregation pipeline is stable. 【5f85ae†L24-L40】
- **Aligned Advanced Inputs** – Homogeneity, Algorithm A inputs, and stability datasets share ranges (min ≈ −0.14, max ≈ 182.56) with matching replicate structures, supporting downstream statistical modules. 【196b6c†L24-L42】

## Recommendations
- Integrate the general validation script into CI to guard against accidental file removals or column changes.
- Store the captured baselines in project documentation and update when legitimate dataset revisions occur.
- Use the weekly audit files for drill-down actions; escalate any cross-week anomalies back to this global checklist.

## Artefacts Produced
- `validation/scripts/validate_general_environment.R` – shared utility for structural checks.
- Weekly audit reports and companion scripts: `@w_01.md`, `@w_02.md`, `@w_03.md`, plus `validate_week_0X.R` helpers. 【F:validation/@w_01.md†L1-L22】【F:validation/@w_02.md†L1-L22】【F:validation/@w_03.md†L1-L24】
