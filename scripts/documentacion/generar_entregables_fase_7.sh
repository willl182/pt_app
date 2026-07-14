#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root_dir"

for dependency in Rscript sha256sum unzip pdfinfo pdftotext; do
  command -v "$dependency" >/dev/null 2>&1 || {
    printf 'Missing required dependency: %s\n' "$dependency" >&2
    exit 1
  }
done

Rscript scripts/documentacion/generar_inventario_entregables.R
Rscript scripts/documentacion/generar_cierre_fase_7.R
Rscript -e 'testthat::test_file("tests/testthat/test-entregables-fase-7.R", reporter = testthat::CheckReporter$new(), stop_on_failure = TRUE)'

printf '%s\n' 'Fase 7: inventario, manifiesto y controles de cierre completados.'
