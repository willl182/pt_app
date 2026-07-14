#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
reference_doc="$root_dir/Entregables_pt_app/00_control_documental/estilos/referencia.docx"
manifest="$root_dir/Entregables_pt_app/00_control_documental/derivados/manifiesto_fase_4.csv"

for dependency in pandoc sha256sum unzip; do
  command -v "$dependency" >/dev/null 2>&1 || {
    printf 'Missing required dependency: %s\n' "$dependency" >&2
    exit 1
  }
done

declare -a sources=(
  "Entregables_pt_app/01_repo_inicial/README.md"
  "Entregables_pt_app/02_funciones_usadas/README.md"
  "Entregables_pt_app/02_funciones_usadas/md/documentacion_funciones.md"
  "Entregables_pt_app/03_calculos_pt/md/ejemplo_calculo_paso_a_paso.md"
  "Entregables_pt_app/04_puntajes/md/formulas_y_ejemplos.md"
)
declare -a outputs=(
  "Entregables_pt_app/01_repo_inicial/README.docx"
  "Entregables_pt_app/02_funciones_usadas/README.docx"
  "Entregables_pt_app/02_funciones_usadas/documentacion_funciones.docx"
  "Entregables_pt_app/03_calculos_pt/ejemplo_calculo_paso_a_paso.docx"
  "Entregables_pt_app/04_puntajes/formulas_y_ejemplos.docx"
)

generated_at="$(date --iso-8601=seconds)"
git_commit="$(git -C "$root_dir" rev-parse --short HEAD 2>/dev/null || printf 'sin-git')"
pandoc_version="$(pandoc --version | head -n 1 | tr ',' ';')"
printf '%s\n' 'fuente,formato,archivo,sha256_fuente,sha256_salida,fecha_generacion,commit,herramienta' > "$manifest"

for i in "${!sources[@]}"; do
  source_file="$root_dir/${sources[$i]}"
  output_file="$root_dir/${outputs[$i]}"
  source_dir="$(dirname "$source_file")"
  source_name="$(basename "$source_file")"
  (
    cd "$source_dir"
    pandoc "$source_name" --from markdown --to docx \
      --reference-doc "$reference_doc" --resource-path "$source_dir" \
      --output "$output_file"
  )
  unzip -tq "$output_file" >/dev/null
  source_hash="$(sha256sum "$source_file" | cut -d ' ' -f 1)"
  output_hash="$(sha256sum "$output_file" | cut -d ' ' -f 1)"
  printf '%s\n' "${sources[$i]},DOCX,${outputs[$i]},$source_hash,$output_hash,$generated_at,$git_commit,$pandoc_version" >> "$manifest"
done

printf 'Generated five Phase 4 DOCX files and %s\n' "$manifest"
