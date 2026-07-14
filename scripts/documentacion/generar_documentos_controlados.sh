#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
control_dir="$root_dir/Entregables_pt_app/00_control_documental"
source_file="$control_dir/plantillas/ejemplo_controlado.md"
output_dir="$control_dir/derivados"
reference_doc="$control_dir/estilos/referencia.docx"
docx_file="$output_dir/ejemplo_controlado.docx"
pdf_file="$output_dir/ejemplo_controlado.pdf"
manifest_file="$output_dir/manifiesto_generacion.csv"

mkdir -p "$output_dir" "$(dirname "$reference_doc")"

for dependency in pandoc libreoffice sha256sum unzip grep; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    printf 'Missing required dependency: %s\n' "$dependency" >&2
    exit 1
  fi
done

if [[ ! -f "$source_file" ]]; then
  printf 'Controlled source not found: %s\n' "$source_file" >&2
  exit 1
fi

if [[ ! -f "$reference_doc" ]]; then
  pandoc "$source_file" --from markdown --to docx --output "$reference_doc"
fi

pandoc "$source_file" \
  --from markdown \
  --to docx \
  --reference-doc "$reference_doc" \
  --output "$docx_file"

pdf_work_dir="$(mktemp -d)"
trap 'rm -rf "$pdf_work_dir"' EXIT
libreoffice_profile="file://$pdf_work_dir/libreoffice-profile"
libreoffice \
  --headless \
  "-env:UserInstallation=$libreoffice_profile" \
  --convert-to pdf \
  --outdir "$pdf_work_dir" \
  "$docx_file" >/dev/null
mv "$pdf_work_dir/ejemplo_controlado.pdf" "$pdf_file"

generated_at="$(date --iso-8601=seconds)"
git_commit="$(git -C "$root_dir" rev-parse --short HEAD 2>/dev/null || printf 'sin-git')"
pandoc_version="$(pandoc --version | head -n 1 | tr ',' ';')"
libreoffice_version="$(libreoffice --version | head -n 1 | tr ',' ';')"
source_hash="$(sha256sum "$source_file" | cut -d ' ' -f 1)"
docx_hash="$(sha256sum "$docx_file" | cut -d ' ' -f 1)"
pdf_hash="$(sha256sum "$pdf_file" | cut -d ' ' -f 1)"

printf '%s\n' \
  'fuente,formato,archivo,sha256_fuente,sha256_salida,fecha_generacion,commit,herramienta' \
  "plantillas/ejemplo_controlado.md,DOCX,derivados/ejemplo_controlado.docx,$source_hash,$docx_hash,$generated_at,$git_commit,$pandoc_version" \
  "plantillas/ejemplo_controlado.md,PDF,derivados/ejemplo_controlado.pdf,$source_hash,$pdf_hash,$generated_at,$git_commit,$pandoc_version + $libreoffice_version" \
  > "$manifest_file"

unzip -tq "$docx_file" >/dev/null
head -c 5 "$pdf_file" | grep -q '%PDF-'

printf 'Generated controlled DOCX/PDF and manifest in %s\n' "$output_dir"
