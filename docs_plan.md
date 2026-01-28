---
📋 COMPREHENSIVE DOCUMENTATION UPDATE PLAN
Project Context
- Current Version: 0.2.0 → Target Version: 0.3.0
- Main Files Changed: app.R (5,184 lines), www/appR.css (1,458 lines), reports/report_template.Rmd (553 lines)
- Data Format Updates: Added run column to CSV files

## PHASE 1 COMPLETED ✅ (2026-01-24)
**Files Updated:**
- `es/README.md` - Updated cloned_app.R → app.R, CSS line refs, version, screenshot notes
- `documentacion/README.md` - Same changes as es/README.md
- `es/01a_data_formats.md` - Added run column to all schemas, examples, generator script, validation
- `documentacion/01a_data_formats.md` - Same changes as es version

**Changes Made:**
- All cloned_app.R references updated to app.R
- CSS line references updated to match new structure (828-902, 903-960, etc.)
- Version updated to 0.3.0 with changelog including "run column" feature
- Screenshot notes expanded with new UI elements
- Run column added to: file format summary, schema tables, CSV examples, get_wide_data() docs
- Sample data generator updated to include run column generation
- Validation checklist updated with run column requirements
- Common issues table updated with run column troubleshooting

## PHASE 2 COMPLETED ✅ (2026-01-24)
**Files Updated:**
- `documentacion/15_architecture.md` - Added metrological compatibility flow and trigger/cache documentation
- `documentacion/18_ui.md` - Verified CSS architecture references and variables documentation

## PHASE 4 COMPLETED ✅ (2026-01-24)
**Files Updated:**
- `documentacion/16_customization.md` - Updated file references (cloned_app.R → app.R), added CSS variables customization section with code examples, added shadcn components customization section, added header/footer customization section
- `documentacion/01_carga_datos.md` - Updated file reference (cloned_app.R → app.R), updated UI line numbers (762-806), added shadcn card-based upload UI documentation with grid layout and styling examples, updated file format examples to include run column, added run column to validation rules, updated cross-references, added screenshot update note

**Changes Made:**
- All cloned_app.R references updated to app.R
- CSS variables reference added with color palette, spacing, and customization examples
- shadcn components customization section added with cards, alerts, and badges styling
- Header/footer customization section added with CSS code examples
- Upload UI documentation expanded with grid layout and modern styling
- File format examples updated to include run column (homogeneity, stability, summary)
- Validation rules updated to include run column requirements
- Cross-references corrected to remove ../cloned_docs/ paths
- Screenshot update note added

## PHASE 3 COMPLETED ✅ (2026-01-24)
**Files Updated:**
- `documentacion/08_compatibilidad.md` - Major expansion: 45 → 140 lines with complete section restructure, interface documentation, method comparisons, difference calculations, data structure, workflow diagram, and use cases
- `documentacion/14_report_template.md` - Updated line count (558 → 552), added Section 4.7 for metrological compatibility, updated ptcalc integration with wrapper functions, added screenshot note
- `documentacion/12_generacion_informes.md` - Updated file reference (cloned_app.R → app.R), added metrological compatibility selector to UI table, updated workflow diagram with compatibility step, documented parameter passing

**Changes Made:**
- Complete rewrite of 08_compatibilidade.md with 9-section structure (1-9)
- Added Mermaid workflow diagram for metrological compatibility calculation
- Added method comparison tables (MADe, nIQR, Algorithm A)
- Documented difference calculations (D_2a, D_2b, D_3)
- Added interface location documentation with UI elements and output IDs
- Documented report template integration with parameters
- Updated report template line count and added compatibility section documentation
- Added ptcalc wrapper function documentation
- Updated report generation workflow with compatibility step
- Added metrological compatibility selector to UI components
- Documented parameter passing for compatibility data

---
FILES TO UPDATE (All 11 Files)
🔴 TIER 1: Critical Reference Updates (4 files)
1. README.md (305 lines)
Changes Required:
- [ ] Line 6: Update primary file reference cloned_app.R → app.R
- [ ] Line 39: Update runApp command shiny::runApp("cloned_app.R") → shiny::runApp("app.R")
- [ ] Line 98: Update architecture diagram reference
- [ ] Line 256: Update developer documentation reference
- [ ] Line 294: Update version from 0.2.0 → 0.3.0 with changelog:
    | 0.3.0 | 2026-01 | Modern UI redesign (shadcn components, header/footer), 
                     metrological compatibility feature, enhanced data format (run column) |
  - [ ] Lines 169-181: Update CSS line references in UI Components table
- [ ] Line 11: Update screenshot note to mention new header/footer design
New Screenshot Notes to Add:
> **Screenshot Update Required**: The following UI elements have been redesigned and 
> screenshots should show:
> - Enhanced header with UNAL logo (left-aligned) and institutional branding
> - shadcn-inspired upload cards with modern file input styling
> - Three-column footer with project info, institutions, and contact sections
> - Modern color scheme (Primary: #FDB913 yellow/gold with gray backgrounds)
---
2. 15_architecture.md (Architecture Deep Dive)
Changes Required:
- [x] Line 6: Update cloned_app.R → app.R
- [x] Section 2.1: Add metrological compatibility to reactive dependency graph:
    METROLOGICAL[Metrological Compatibility
  metrological_compatibility_data()]
- [x] Section 2.2: Document new reactive pattern:
  - Trigger-based Reactives: analysis_trigger, algoA_trigger, consensus_trigger, scores_trigger
  - Cache Reactives: algoA_results_cache, consensus_results_cache, scores_results_cache
- [x] Add new section 2.4 Metrological Compatibility Flow:
    flowchart LR
      REF[Reference Values] --> COMP[Metrological Compatibility]
      CONSENSUS[Consensus Values 2a/2b/3] --> COMP
      HOM[Homogeneity u_hom] --> COMP
      STAB[Stability u_stab] --> COMP
      COMP --> TABLE[Compatibility Table Output]
- [x] Section 4: Add performance optimization notes about reactive caching
---
3. 18_ui.md (UI & CSS Reference)
Changes Required:
- [x] Line 6: Update CSS file line count to 1,458 lines
- [x] Section 2.1: Update section structure table with new entries:
    | **Enhanced Header** | 828-902 | Logo container, institutional branding |
  | **shadcn Cards** | 903-960 | Modern card component system |
  | **shadcn Alerts** | 961-1021 | Alert variants (info, success, warning, error) |
  | **shadcn Badges** | 1022-1075 | Status badges with score variants |
  | **Upload Components** | 1076-1159 | File upload grid and styled inputs |
  | **Modern Footer** | 1217-1280 | Three-column footer layout |
  
- [x] Add new Section 3: CSS Variables Reference (high-level overview):
     3. CSS Variables (Custom Properties)
  
  The theme uses CSS Custom Properties for consistent styling:
  
 Color Palette
  - **Primary**: `--pt-primary: #FDB913` (UNAL yellow/gold)
  - **Backgrounds**: `--pt-bg: #E8EAED`, `--pt-bg-card: #F5F6F7`
  - **Text**: `--pt-fg: #1F2937`, `--pt-fg-muted: #6B7280`
  - **Score Colors**: 
    - Satisfactory: `--pt-satisfactory: #00B050`
    - Questionable: `--pt-questionable: #FFEB3B`
    - Unsatisfactory: `--pt-unsatisfactory: #D32F2F`
  
   Spacing & Layout
  - Uses `--space-*` variables (xs through xxl)
  - Border radius: `--radius-sm` through `--radius-xl`
  
   Customization
  Override variables in your custom CSS:
  :root {
    --pt-primary: #YOUR_COLOR;
    --pt-bg: #YOUR_BG;
  }
    
- [x] Add Section 4.3: shadcn-Inspired Components:
  - Document .shadcn-card, .shadcn-card-header, .shadcn-card-content
  - Document .alert-modern variants
  - Document .badge-modern usage
  - Include code examples
- [x] Update Section on Header (lines 828-902 reference)
- [x] Update Section on Footer (lines 1217-1280 reference)
---
4. 14_report_template.md (Report Template)
Changes Required:
- [x] Line 7: Update line count to 553 lines
- [x] Section 3.4: Expand Metrological Compatibility Parameters:
    ### 3.4 Metrological Compatibility Parameters (NEW)

  params:
    metrological_compatibility: NA           # Data frame with columns:
                                             # - pollutant, n_lab, level
                                             # - x_pt_ref, x_pt_2a, x_pt_2b, x_pt_3
                                             # - Diff_Ref_2a, Diff_Ref_2b, Diff_Ref_3
    metrological_compatibility_method: "2a"  # Selected method: "2a", "2b", or "3"

- [x] Section 4: Add 4.7 Section 2.4: Metrological Compatibility (NEW):
     4.7 Section 2.4: Metrological Compatibility

  **Lines**: 312-352
  **Purpose**: Evaluates agreement between reference and consensus values

  **Dynamic Content**:
  - Displays compatibility table filtered by selected method
  - Shows differences (D_2a, D_2b, D_3) between x_pt(ref) and consensus values
  - Adapts column display based on `metrological_compatibility_method` param

  **Table Columns**:
  - Method 2a: Shows x_pt_ref, x_pt_2a, Diff_Ref_2a
  - Method 2b: Shows x_pt_ref, x_pt_2b, Diff_Ref_2b
  - Method 3: Shows x_pt_ref, x_pt_3 (Alg A), Diff_Ref_3

- [x] Section 5: Update ptcalc Integration notes:
  - Document wrapper functions (lines 132-139, 142-173)
  - Note use of calculate_mad_e, calculate_homogeneity_stats from ptcalc
- [x] Add screenshot note for compatibility section
---
🟡 TIER 2: Feature & Module Documentation (5 files)
5. 01a_data_formats.md (Data Formats - CRITICAL UPDATE)
Changes Required:
- [ ] Line 21: Update homogeneity/stability columns to include run:
    | Homogeneity | Long | `pollutant`, `level`, `value`, `run` | `replicate`, `sample_id`, `date` |
  | Stability | Long | `pollutant`, `level`, `value`, `run` | `replicate`, `sample_id`, `date` |
  
- [ ] Section 2.1: Add run column to schema:
    | `run` | **Yes** | String | Run/corrida identifier | `corrida_1`, `corrida_2`, `corrida_3` |
  
- [ ] Line 42: Update example CSV to include run:
    "pollutant","run","level","replicate","sample_id","value"
  "co","corrida_1","0-μmol/mol",1,1,0.00670
  "co","corrida_1","0-μmol/mol",2,1,-0.04796
  "so2","corrida_2","20-nmol/mol",1,1,19.70235
  
- [ ] Section 2.2: Add run column to participant summary schema:
    | `run` | **Yes** | String | Run/corrida identifier | `corrida_1`, `corrida_2` |
  
- [ ] Section 4.2: Update get_wide_data() function note to mention run handling
- [ ] Section 5: Update sample data generator script to include run column
- [ ] Section 6: Add validation checklist item for run column
---
6. 08_compatibilidad.md (Metrological Compatibility - MAJOR EXPANSION)
Changes Required:
- [x] Line 9: Update file reference cloned_app.R → app.R
- [x] EXPAND entire document with new sections:
New Structure:
 Módulo: Compatibilidad Metrológica
 1. Descripción General
Evalúa la coherencia entre el valor de referencia y los valores de consenso 
calculados por diferentes métodos (MADe, nIQR, Algoritmo A).
| Elemento | Valor |
|----------|-------|
| Archivo | `app.R` |
| Pestaña UI | "Compatibilidad Metrológica" (dentro de Valor Asignado) |
| Líneas UI | ~990-993 |
| Líneas Lógica | Cálculo en generación de informes |
| Normas ISO | ISO 13528:2022 Sección 9 |
 2. Ubicación en la Interfaz
El módulo se encuentra en la pestaña **"Valor asignado"** → sub-pestaña 
**"Compatibilidad Metrológica"**.
 2.1 Botón de Acción
- **ID**: `run_metrological_compatibility`
- **Función**: Activa el cálculo de diferencias entre métodos
 2.2 Tabla de Resultados
- **Output ID**: `metrological_compatibility_table`
- **Tipo**: DataTable interactiva
 3. Métodos de Consenso Comparados
| Método | Código | x_pt Calculation | σ_pt Calculation |
|--------|--------|------------------|------------------|
| Consenso MADe | 2a | median(valores) | 1.483 × MAD |
| Consenso nIQR | 2b | median(valores) | 0.7413 × IQR |
| Algoritmo A | 3 | x* (robust mean) | s* (robust sd) |
 4. Cálculo de Diferencias
 4.1 Diferencias Absolutas
Para cada combinación (pollutant, n_lab, level):
$$D_{2a} = |x_{pt,ref} - x_{pt,2a}|$$
$$D_{2b} = |x_{pt,ref} - x_{pt,2b}|$$
$$D_{3} = |x_{pt,ref} - x_{pt,3}|$$
 4.2 Criterio de Evaluación (Opcional - Implementación Futura)
La evaluación de compatibilidad puede usar:
$$Criterio = \sqrt{u_{xpt,ref}^2 + u_{xpt,consenso}^2}$$
**Compatible si**: $D \leq Criterio$
 5. Estructura de Datos de Salida
 5.1 Tabla de Compatibilidad
Columnas generadas:
- `pollutant`: Contaminante
- `n_lab`: Esquema de ensayo
- `level`: Nivel de concentración
- `x_pt_ref`: Valor de referencia
- `x_pt_2a`: Valor consenso MADe
- `x_pt_2b`: Valor consenso nIQR
- `x_pt_3`: Valor consenso Algoritmo A
- `Diff_Ref_2a`: |x_pt_ref - x_pt_2a|
- `Diff_Ref_2b`: |x_pt_ref - x_pt_2b|
- `Diff_Ref_3`: |x_pt_ref - x_pt_3|
 6. Integración con Generación de Informes
 6.1 Parámetro del Reporte
params:
  metrological_compatibility: NA  # Data frame con diferencias
  metrological_compatibility_method: "2a"  # Método seleccionado
6.2 Sección en el Informe
Ubicación: report_template.Rmd, líneas 312-352
Título: "2.4. Compatibilidad Metrológica"
La tabla mostrada se filtra según metrological_compatibility_method.
7. Flujo de Trabajo
flowchart TD
    A[Usuario selecciona n_lab, level] --> B[Clic en Calcular Algoritmo A]
    B --> C[Clic en Calcular Valores Consenso]
    C --> D[Clic en Calcular Compatibilidad]
    D --> E[Sistema recupera x_pt de Reference]
    D --> F[Sistema recupera x_pt de Consensus cache]
    D --> G[Sistema recupera x_pt de AlgoA cache]
    E --> H[Calcula diferencias D_2a, D_2b, D_3]
    F --> H
    G --> H
    H --> I[Tabla de compatibilidad]
    I --> J[Exportación a informe]
8. Casos de Uso
8.1 Validación de Método de Consenso
Objetivo: Determinar si consenso y referencia están alineados
Acción: Revisar si D_2a, D2b, D3 < umbral aceptable
8.2 Selección de Método para Reporte
Objetivo: Elegir método de consenso más compatible con referencia
Acción: Comparar D_2a vs D2b vs D3, seleccionar el menor
9. Referencias Cruzadas
- Valor Asignado: 07_valor_asignado.md (07_valor_asignado.md)
- Generación de Informes: 12_generacion_informes.md (12_generacion_informes.md)
- Report Template: 14_report_template.md (14_report_template.md)
---
#### **7. 12_generacion_informes.md** (Report Generation)
**Changes Required:**
- [x] Line 9: Update `cloned_app.R` → `app.R`
- [x] Section 2.1: Add new table row for metrological compatibility selector:
  | Compatibilidad Metrológica | report_metrological_compatibility_method | selectInput | Método de consenso para comparar: 2a, 2b, 3 |
- [x] Section 3: Add to workflow diagram showing compatibility calculation step
- [x] Section 5 (or new section): Document metrological compatibility parameter passing
---
#### **8. 16_customization.md** (Customization Guide)
**Changes Required:**
- [x] Line 6, 28, 38: Update all `cloned_app.R` → `app.R`
- [x] Section on Theme: Add CSS variables customization:
  ```markdown
  ### Customizing with CSS Variables
  
  The modern design uses CSS Custom Properties. To customize:
  
  1. Create `www/custom.css`:
  ```css
  :root {
    --pt-primary: #YOUR_COLOR;
    --pt-bg: #F0F0F0;
    --pt-bg-card: #FFFFFF;
  }
  
  2. Load in app.R:
    tags$head(
    tags$link(rel = "stylesheet", href = "appR.css"),
    tags$link(rel = "stylesheet", href = "custom.css")  # Your overrides
  )
- [x] Add section: **Customizing shadcn Components**
- [x] Add section: **Customizing Header/Footer**
---
#### **9. 01_carga_datos.md** (Data Loading)
**Changes Required:**
- [x] Document new shadcn card-based upload UI (lines ~762-806 in app.R)
- [x] Update screenshot notes to show:
  - Upload grid layout (3-column grid on desktop)
  - Modern file input styling with dashed borders
  - Icon-enhanced upload labels
- [x] Add note about `run` column validation in uploaded data
---
### **🟢 TIER 3: Minor Module Updates (2 files)**
#### **10. 06_shiny_homogeneidad.md** (Homogeneity Module)
**Changes Required:**
- [x] Verify reactive flow diagrams still accurate
- [x] Update UI component line references if needed
- [x] Add note about `run` column handling in wide data transformation
---
#### **11. 09_puntajes_pt.md** (PT Scores Module)
**Changes Required:**
- [x] Document new caching system:
  - `scores_results_cache()`
  - `scores_trigger()`
  - `get_scores_result()` helper function
- [x] Update reactive flow diagram to show cache layer
- [x] Add performance note about trigger-based reactivity
---
## PHASE 5 COMPLETED ✅ (2026-01-24)
**Files Updated:**
- `documentacion/06_shiny_homogeneidad.md` - Updated file reference (cloned_app.R → app.R), updated UI line references (761-856 → 762-857), added run column handling note in get_wide_data() step
- `documentacion/09_puntajes_pt.md` - Updated file reference (cloned_app.R → app.R), documented trigger-based caching system with scores_results_cache(), scores_trigger(), and get_scores_result(), updated reactive flow diagram with cache layer visualization, expanded cache strategy section with performance notes

**Changes Made:**
- All cloned_app.R references updated to app.R
- UI line numbers updated to reflect current app.R structure
- Run column handling note added to homogeneity metrics computation
- Complete caching system documentation added with code examples
- Mermaid diagram updated to show cache layer and helper function
- Cache strategy section expanded with trigger-based reactivity explanation
- Performance notes added emphasizing optimization benefits
---
## **GLOBAL UPDATES (All Files)**
### **Version References**
- [ ] Update all version mentions from **0.2.0** → **0.3.0**
### **File Name References**
- [ ] Change all **`cloned_app.R`** → **`app.R`**
- [ ] Verify all line number references are still accurate
### **Screenshot Notes Template**
Add this note to any file mentioning screenshots:
```markdown
> **📸 Screenshot Update Needed**: Screenshots should reflect the current UI with:
> - Enhanced header with UNAL logo and institutional branding
> - shadcn-inspired components (cards, alerts, badges)
> - Modern color scheme (primary yellow #FDB913)
> - Three-column footer layout
---
QUALITY CHECKLIST
Before finalizing each document:
- [ ] All code examples use <- for assignment (not =)
- [ ] Function names in snake_case
- [ ] ISO standard references included where applicable
- [ ] Line number references verified against actual source
- [ ] Cross-references to other docs updated
- [ ] Mermaid diagrams use proper syntax
- [ ] Spanish for user-facing text, English for technical content
- [ ] Line length ≤ 80 characters in code blocks where possible
---
EXECUTION ORDER
1. Phase 1 (Foundation): README.md, 01a_data_formats.md ✅ COMPLETED
2. Phase 2 (Architecture): 15_architecture.md, 18_ui.md ✅ COMPLETED
3. Phase 3 (Features): 08_compatibilidad.md, 14_report_template.md, 12_generacion_informes.md ✅ COMPLETED
4. Phase 4 (Modules): 16_customization.md, 01_carga_datos.md ✅ COMPLETED
5. Phase 5 (Minor): 06_shiny_homogeneidad.md, 09_puntajes_pt.md ✅ COMPLETED
---
**(Phases 1-5 complete: +~460 lines from updates)**
Total Documentation: ~1,939 lines → ~2,400 lines (+461 lines, +24%)

ESTIMATED IMPACT
| File | Current Lines | Est. New Lines | Change Type |
|------|---------------|----------------|-------------|
| README.md | 305 | ~320 | Minor additions |
| 15_architecture.md | ~200 | ~250 | Medium additions |
| 18_ui.md | ~200 | ~280 | Medium additions |
| 14_report_template.md | ~200 | 450 | Minor additions (completed) |
| 01a_data_formats.md | 349 | ~380 | Medium additions (run column) |
| 08_compatibilidad.md | 45 | 122 | MAJOR expansion (completed) |
| 12_generacion_informes.md | ~150 | 208 | Minor additions (completed) |
| 16_customization.md | ~150 | ~190 | Medium additions |
| 01_carga_datos.md | ~120 | ~140 | Minor additions (completed) |
| 06_shiny_homogeneidad.md | 233 | ~235 | Minor updates (completed) |
| 09_puntajes_pt.md | 171 | ~210 | Medium additions (completed) |
Total Documentation: ~1,939 lines → ~2,425 lines (+486 lines, +25%)
**(Phases 1-5 complete: +486 lines from all phases)**
