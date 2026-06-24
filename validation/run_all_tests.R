# validation/run_all_tests.R

# This script runs all validation tests in the tests/ directory
# and aggregates the results.

test_files <- list.files("tests", pattern = "^test_.*\\.R$", full.names = TRUE)

cat("========================================\n")
cat("INICIANDO VALIDACIÓN DEL SISTEMA\n")
cat("Fecha:", as.character(Sys.time()), "\n")
cat("========================================\n\n")

results <- list()

for (f in test_files) {
  test_name <- basename(f)
  cat(sprintf("Ejecutando %s ... ", test_name))

  tryCatch({
    # Capture output to avoid cluttering main log unless needed,
    # but for this script we want to see output if it fails.
    # We use source() inside a new environment to avoid cross-contamination.
    source(f, local = new.env())
    cat("OK\n")
    results[[test_name]] <- "PASSED"
  }, error = function(e) {
    cat("FALLÓ\n")
    cat(sprintf("  Error: %s\n", e$message))
    results[[test_name]] <- paste("FAILED:", e$message)
  })
}

cat("\n========================================\n")
cat("RESUMEN DE VALIDACIÓN\n")
cat("========================================\n")

for (name in names(results)) {
  cat(sprintf("%-30s : %s\n", name, results[[name]]))
}

if (any(grepl("FAILED", unlist(results)))) {
  cat("\nADVERTENCIA: Algunos tests fallaron.\n")
  quit(status = 1)
} else {
  cat("\nÉXITO: Todos los tests pasaron correctamente.\n")
  quit(status = 0)
}
