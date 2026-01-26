# ===================================================================
# Update package documentation for ptcalc
# ===================================================================

library(devtools)

# Generate documentation from roxygen2 comments
document("ptcalc")

cat("Documentation updated successfully!\n")
cat("Check ptcalc/man/ for generated .Rd files\n")
