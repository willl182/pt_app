#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
reference_doc="$root_dir/Entregables_pt_app/00_control_documental/estilos/referencia.docx"
manifest="$root_dir/Entregables_pt_app/00_control_documental/derivados/manifiesto_fase_6.csv"

for dependency in Rscript pandoc libreoffice sha256sum unzip; do
  command -v "$dependency" >/dev/null 2>&1 || {
    printf 'Missing required dependency: %s\n' "$dependency" >&2
    exit 1
  }
done

cd "$root_dir"
Rscript Entregables_pt_app/09_informe_final/R/genera_anexos.R
Rscript -e 'testthat::test_file("Entregables_pt_app/09_informe_final/tests/test_09_reproducibilidad.R", reporter = testthat::CheckReporter$new())'

sources=(
  "Entregables_pt_app/09_informe_final/md/informe_validacion.md"
  "Entregables_pt_app/09_informe_final/md/anexo_calculos.md"
)
outputs=(
  "Entregables_pt_app/09_informe_final/informe_validacion.docx"
  "Entregables_pt_app/09_informe_final/anexo_calculos.docx"
)

generated_at="$(date --iso-8601=seconds)"
git_commit="$(git rev-parse --short HEAD)"
pandoc_version="$(pandoc --version | head -n 1 | tr ',' ';')"
printf '%s\n' 'fuente,formato,archivo,sha256_fuente,sha256_salida,fecha_generacion,commit,herramienta' > "$manifest"

for i in "${!sources[@]}"; do
  source_file="$root_dir/${sources[$i]}"
  output_file="$root_dir/${outputs[$i]}"
  source_dir="$(dirname "$source_file")"
  (
    cd "$source_dir"
    pandoc "$(basename "$source_file")" --from markdown --to docx \
      --reference-doc "$reference_doc" --resource-path "$source_dir" \
      --output "$output_file"
  )
  unzip -tq "$output_file" >/dev/null
  printf '%s\n' "${sources[$i]},DOCX,${outputs[$i]},$(sha256sum "$source_file" | cut -d ' ' -f 1),$(sha256sum "$output_file" | cut -d ' ' -f 1),$generated_at,$git_commit,$pandoc_version" >> "$manifest"
done

pdf_dir="$(mktemp -d)"
trap 'rm -rf "$pdf_dir"' EXIT
libreoffice --headless --convert-to pdf --outdir "$pdf_dir" \
  "$root_dir/Entregables_pt_app/09_informe_final/informe_validacion.docx" \
  >/dev/null
mv "$pdf_dir/informe_validacion.pdf" \
  "$root_dir/Entregables_pt_app/09_informe_final/informe_validacion.pdf"
pdf_path="Entregables_pt_app/09_informe_final/informe_validacion.pdf"
printf '%s\n' "${sources[0]},PDF,$pdf_path,$(sha256sum "$root_dir/${sources[0]}" | cut -d ' ' -f 1),$(sha256sum "$root_dir/$pdf_path" | cut -d ' ' -f 1),$generated_at,$git_commit,LibreOffice" >> "$manifest"

printf 'Generated E09 evidence, two DOCX files, one PDF and %s\n' "$manifest"
