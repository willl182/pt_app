# The `ptcalc` Package

## 1. Overview
`ptcalc` is an R package developed specifically for this application. It encapsulates all pure mathematical functions required for proficiency testing calculations according to ISO 13528:2022.

**Key Design Principle:** Separation of Concerns. The mathematical logic is completely decoupled from the Shiny user interface. This ensures that:
1.  Calculations can be tested independently (unit tests).
2.  The package can be used in other R scripts without loading the web app.
3.  The UI layer remains lightweight.

---

## 2. Installation & Usage

### Installation
Since this is a local package within the project structure, you install it using `devtools`:

```r
# From project root
devtools::install("ptcalc")
```

### Loading in Development
For rapid iteration during development, use `load_all` instead of installing:
```r
devtools::load_all("ptcalc")
```

---

## 3. Package Structure

```
ptcalc/
├── DESCRIPTION        # Dependencies and metadata
├── NAMESPACE          # Exported functions
├── R/
│   ├── pt_homogeneity.R     # ANOVA, ss, sw, criteria
│   ├── pt_robust_stats.R    # Algorithm A, MADe, nIQR
│   └── pt_scores.R          # z, z', zeta, En scores
└── man/                     # Documentation (auto-generated)
```

## 4. Documentation Status
All exported functions are documented using `roxygen2` comments. You can view the help for any function within R by typing `?function_name` (e.g., `?calculate_z_score`) after loading the package.

### Generating Documentation
To update the `.Rd` files in the `man/` directory after changing comments:
```r
devtools::document("ptcalc")
```

---

## 5. Testing
The package structure supports standard R testing via `testthat`.
*   **Test Location:** `ptcalc/tests/testthat/`
*   **Running Tests:** `devtools::test("ptcalc")`

*Note: As of this version, test coverage focuses on the core robust statistics and score formulas.*
