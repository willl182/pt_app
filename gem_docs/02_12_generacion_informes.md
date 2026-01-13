# Shiny Module: Report Generation

## 1. Overview
This module handles the compilation of analysis results into a professional downloadable document (Word or HTML). It interfaces with RMarkdown.

**File Location:** `cloned_app.R` ("Generación de informes" tab)

---

## 2. Workflow

1.  **Configuration:** User selects parameters (Scheme ID, Date, Method, Comments).
2.  **Compilation:** User clicks "Download Report".
3.  **Processing (`downloadHandler`):**
    *   Creates a temporary directory.
    *   Copies `report_template.Rmd` and `references.bib` to temp.
    *   Compiles parameters into a `params` list.
    *   Runs `rmarkdown::render()`.
4.  **Delivery:** Browser downloads the generated file.

---

## 3. RMarkdown Integration

### 3.1 The Template
**File:** `reports/report_template.Rmd`

The template is parameterized. It does not hardcode values but expects them passed from Shiny.

**YAML Header Example:**
```yaml
params:
  n_lab: "01"
  pollutant: "SO2"
  level: "low"
  method_code: "3"
  ...
```

### 3.2 Data Passing
Instead of passing huge raw datasets, the app passes *processed* summary lists or filtered dataframes to the template to minimize rendering time and memory usage.

### 3.3 Output Formats
*   **HTML:** Interactive, best for web viewing.
*   **Word (.docx):** Static, best for official records and editing. Uses a reference docx for styling (`reference_docx: styles.docx`).

---

## 4. Customization Options
The UI provides fields for:
*   **Coordinator Name:** Appears in signature block.
*   **Date:** Report issuance date.
*   **Comments:** Free text field for specific observations about the round.
