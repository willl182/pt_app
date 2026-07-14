#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
reference_doc="$root_dir/Entregables_pt_app/00_control_documental/estilos/referencia.docx"
manifest="$root_dir/Entregables_pt_app/00_control_documental/derivados/manifiesto_fase_5.csv"

for dependency in pandoc sha256sum unzip; do
  command -v "$dependency" >/dev/null 2>&1 || {
    printf 'Missing required dependency: %s\n' "$dependency" >&2
    exit 1
  }
done

sources=(
  "Entregables_pt_app/05_prototipo_ui/md/wireframes.md"
  "Entregables_pt_app/06_app_logica/md/manual_usuario.md"
  "Entregables_pt_app/07_dashboards/md/documentacion_dashboards.md"
  "Entregables_pt_app/08_beta/md/manual_desarrollador.md"
)
outputs=(
  "Entregables_pt_app/05_prototipo_ui/wireframes.docx"
  "Entregables_pt_app/06_app_logica/manual_usuario.docx"
  "Entregables_pt_app/07_dashboards/documentacion_dashboards.docx"
  "Entregables_pt_app/08_beta/manual_desarrollador.docx"
)

generated_at="$(date --iso-8601=seconds)"
git_commit="$(git -C "$root_dir" rev-parse --short HEAD 2>/dev/null || printf 'sin-git')"
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
  source_hash="$(sha256sum "$source_file" | cut -d ' ' -f 1)"
  output_hash="$(sha256sum "$output_file" | cut -d ' ' -f 1)"
  printf '%s\n' "${sources[$i]},DOCX,${outputs[$i]},$source_hash,$output_hash,$generated_at,$git_commit,$pandoc_version" >> "$manifest"
done

html_source="$root_dir/${sources[0]}"
html_output="$root_dir/Entregables_pt_app/05_prototipo_ui/html/recorrido_interfaz.html"
(
  cd "$(dirname "$html_source")"
  pandoc "$(basename "$html_source")" --from markdown --to html5 \
    --standalone --embed-resources --resource-path "$(dirname "$html_source")" \
    --output "$html_output"
)
printf '%s\n' "${sources[0]},HTML,Entregables_pt_app/05_prototipo_ui/html/recorrido_interfaz.html,$(sha256sum "$html_source" | cut -d ' ' -f 1),$(sha256sum "$html_output" | cut -d ' ' -f 1),$generated_at,$git_commit,$pandoc_version" >> "$manifest"

printf 'Generated four DOCX files, one HTML file and %s\n' "$manifest"
