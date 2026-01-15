# Documentation Upgrade Plan: cloned_app.R & cloned_docs/

## Executive Summary

The current documentation in `cloned_docs/` provides a basic structural overview but lacks depth in several critical areas. This plan outlines a comprehensive upgrade to create documentation that fully explains the application's architecture, data flow, mathematical foundations, and practical usage.

---

## Current State Assessment

### Strengths
- Clear separation between `ptcalc` package and Shiny app documentation
- ISO standard references included
- Basic reactive dependency chains documented
- Mermaid diagrams for architecture visualization

### Weaknesses Identified

| Issue | Severity | Affected Files |
|-------|----------|----------------|
| Missing user guide/tutorial | High | All |
| No example data files documented | High | 01_carga_datos.md |
| Incomplete reactive dependency graphs | Medium | 06-11 modules |
| Line number references outdated | Medium | All |
| No troubleshooting/FAQ section | Medium | README.md |
| Missing UI component mapping | Medium | All Shiny modules |
| Formulas without derivation context | Low | 03-05 |
| No glossary of Spanish/English terms | Low | All |

---

## Proposed Documentation Structure

### Phase 1: Foundation (Priority: Critical)

#### 1.1 Create `00_quickstart.md` (NEW FILE)
**Content:**
- System requirements and installation steps
- How to launch the application
- Loading example data walkthrough
- First analysis in 5 minutes

#### 1.2 Upgrade `README.md`
**Current:** 70 lines, basic index
**Target:** 150+ lines

**Add:**
- Installation prerequisites (R version, dependencies)
- Quick start command: `shiny::runApp("cloned_app.R")`
- Application screenshot
- Troubleshooting section with common errors
- Link to example data files
- Contribution guidelines

#### 1.3 Create `00_glossary.md` (NEW FILE)
**Content:**
| Spanish Term | English Term | Symbol | Definition |
|--------------|--------------|--------|------------|
| Analito | Pollutant | - | Gas being analyzed |
| Nivel | Level | - | Concentration level |
| Puntaje | Score | z, z', etc. | Performance metric |
| Valor asignado | Assigned value | x_pt | Reference value |
| ... | ... | ... | ... |

---

### Phase 2: Data Module Deep Dive (Priority: High)

#### 2.1 Upgrade `01_carga_datos.md`
**Current:** 54 lines, basic schema
**Target:** 150+ lines

**Add:**
- **Example data files section** with actual CSV snippets:
  ```csv
  pollutant,level,replicate,value
  SO2,low,1,0.0523
  SO2,low,2,0.0528
  ```
- **Data validation rules** (what makes the app reject files)
- **Error messages explained** with solutions
- **Column naming conventions** (sample_1, sample_2, etc.)
- **File naming pattern** for summary_n*.csv (regex: `summary_(\d+)\.csv`)
- **Flowchart:** File upload -> Validation -> Reactive storage
- **Complete reactive chain:**
  ```
  input$hom_file -> hom_data_full() -> raw_data() -> homogeneity_run()
  ```

#### 2.2 Create `01a_data_formats.md` (NEW FILE)
**Content:**
- Complete CSV schema with all optional columns
- Sample data generator script
- Data transformation pipeline (long to wide format)
- `get_wide_data()` function explanation (lines 227-238)

---

### Phase 3: Core Calculations Module (Priority: High)

#### 3.1 Upgrade `03_pt_robust_stats.md`
**Current:** 71 lines
**Target:** 150+ lines

**Add:**
- **Visual algorithm flow** for Algorithm A with step-by-step example
- **Numerical example** with real numbers walking through each iteration
- **Convergence behavior** explanation with plot
- **Edge cases**: What happens with <3 participants?
- **Comparison table**: MADe vs nIQR vs Algorithm A

#### 3.2 Upgrade `04_pt_homogeneity.md`
**Current:** 77 lines
**Target:** 180+ lines

**Add:**
- **Complete derivation** of ss and sw formulas
- **ANOVA table construction** explained
- **Criterion formulas** with numerical examples:
  ```
  c = 0.3 * sigma_pt
  c_expanded = sqrt(sigma_allowed_sq * 1.88 + sw^2 * 1.01)
  ```
- **Decision tree**: PASS/FAIL logic
- **u_hom and u_stab calculation** with practical example
- **t-test for stability** interpretation guidance

#### 3.3 Upgrade `05_pt_scores.md`
**Current:** 70 lines
**Target:** 200+ lines

**Add:**
- **Score selection guide**: When to use z vs z' vs zeta vs En
- **Uncertainty propagation** explanation for u_xpt_def formula:
  ```
  u_xpt_def = sqrt(u_xpt^2 + u_hom^2 + u_stab^2)
  ```
- **Classification table (a1-a7)** with detailed criteria
- **Visual score interpretation guide** with example scenarios
- **Color palette reference** for heatmaps

---

### Phase 4: Shiny Module Documentation (Priority: Medium)

#### 4.1 Upgrade `06_shiny_homogeneidad.md`
**Current:** 55 lines
**Target:** 120+ lines

**Add:**
- **Complete UI component map:**
  | UI Element | Input ID | Output ID | Reactive |
  |------------|----------|-----------|----------|
  | Run button | run_analysis | - | analysis_trigger() |
  | Pollutant dropdown | pollutant_analysis | pollutant_selector_analysis | - |
  | ... | ... | ... | ... |
- **Output screenshots** with annotations
- **Error state documentation** (what users see when data is missing)

#### 4.2 Upgrade `07_valor_asignado.md`
**Current:** 45 lines
**Target:** 140+ lines

**Add:**
- **Method selection guidance** flowchart
- **Metrological compatibility calculation** (D_2a, D_2b formulas)
- **consensus_run reactive** documentation (currently missing)
- **Algorithm A button behavior** and cache mechanism
- **Complete observeEvent chain** for `input$algoA_run`

#### 4.3 Upgrade `09_puntajes_pt.md`
**Current:** 37 lines
**Target:** 150+ lines

**Add:**
- **compute_scores_for_selection()** function breakdown (lines 1926-2098)
- **compute_combo_scores()** detailed explanation
- **Caching strategy** with scores_results_cache()
- **Tab switching behavior** between score types
- **Plot generation** with plot_scores() function

#### 4.4 Upgrade `10_informe_global.md`
**Current:** 28 lines
**Target:** 100+ lines

**Add:**
- **global_report_data() reactive** structure
- **Heatmap generation logic** per method
- **Data aggregation pipeline** from scores to summary tables
- **Participant filtering** (excluding "ref")

#### 4.5 Upgrade `11_participantes.md`
**Current:** 24 lines
**Target:** 80+ lines

**Add:**
- **Dynamic tab generation pattern** with lapply/renderUI
- **Per-participant data filtering** logic
- **Chart customization options**
- **Performance considerations** for many participants

#### 4.6 Upgrade `12_generacion_informes.md`
**Current:** 32 lines
**Target:** 120+ lines

**Add:**
- **RMarkdown template structure** explanation
- **Parameter passing** to template
- **downloadHandler pattern** with temp file management
- **Report customization options** (ID, date, coordinator fields)
- **Output format differences** (Word vs HTML)

#### 4.7 Upgrade `13_valores_atipicos.md`
**Current:** 34 lines
**Target:** 80+ lines

**Add:**
- **grubbs_summary() reactive** complete implementation
- **Visual indicators** in histograms/boxplots
- **Multi-level outlier detection** workflow
- **Integration with score calculations** (are outliers excluded?)

---

### Phase 5: Package Documentation (Priority: Medium)

#### 5.1 Upgrade `02_ptcalc_package.md`
**Current:** 60 lines
**Target:** 100+ lines

**Add:**
- **Function signature table** with all parameters
- **Unit test coverage** notes
- **Development workflow** (devtools::load_all vs install)
- **Roxygen documentation status**

#### 5.2 Create `02a_ptcalc_api.md` (NEW FILE)
**Content:**
- Complete function reference (all exported functions)
- Input/output types for each function
- Error conditions and return values
- Code examples for each function

---

### Phase 6: Advanced Topics (Priority: Low)

#### 6.1 Create `15_architecture.md` (NEW FILE)
**Content:**
- Reactive dependency graph (complete)
- Server function structure overview
- Performance optimization notes
- State management with reactiveValues (rv)

#### 6.2 Create `16_customization.md` (NEW FILE)
**Content:**
- Theme customization (bslib options)
- Layout width controls (nav_width, analysis_sidebar_width)
- Adding new pollutants/levels
- Extending the ptcalc package

#### 6.3 Create `17_troubleshooting.md` (NEW FILE)
**Content:**
- Common error messages and solutions
- Data format issues
- Performance problems with large datasets
- Browser compatibility notes

---

## Implementation Timeline

| Phase | Estimated Effort | Priority |
|-------|------------------|----------|
| Phase 1: Foundation | 4-6 hours | Critical |
| Phase 2: Data Module | 3-4 hours | High |
| Phase 3: Calculations | 5-6 hours | High |
| Phase 4: Shiny Modules | 6-8 hours | Medium |
| Phase 5: Package Docs | 2-3 hours | Medium |
| Phase 6: Advanced | 3-4 hours | Low |

**Total estimated effort: 23-31 hours**

---

## New Files Summary

| File | Purpose |
|------|---------|
| `00_quickstart.md` | Getting started tutorial |
| `00_glossary.md` | Spanish/English terminology |
| `01a_data_formats.md` | Complete data schema reference |
| `02a_ptcalc_api.md` | Package API reference |
| `15_architecture.md` | System architecture deep dive |
| `16_customization.md` | Customization guide |
| `17_troubleshooting.md` | FAQ and error solutions |

---

## Quality Standards for Upgraded Documentation

### Each Document Must Include:
1. **Header table** with file location, line numbers, dependencies
2. **Mermaid diagram** for data/control flow (where applicable)
3. **Code snippets** with syntax highlighting
4. **Mathematical formulas** in LaTeX notation
5. **Tables** for parameter/output specifications
6. **Cross-references** to related documents
7. **ISO standard references** where applicable

### Line Number Maintenance:
- Use relative references where possible ("lines 240-280" -> "in the server function")
- Document should reference function names rather than line numbers when possible
- Create a script to validate line number references

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Total documentation lines | ~650 | 2000+ |
| Documents with diagrams | 2 | 15+ |
| Practical examples | 0 | 20+ |
| User guide sections | 0 | 5+ |
| API reference coverage | 30% | 100% |

---

## Next Steps

1. **Immediate:** Review this plan and prioritize phases
2. **Phase 1 First:** Create quickstart guide and glossary
3. **Validate:** Test documentation against actual app behavior
4. **Iterate:** Update based on user feedback
