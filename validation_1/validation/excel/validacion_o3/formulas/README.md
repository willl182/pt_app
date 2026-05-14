# Libros Excel con formulas para validacion O3

Esta carpeta contiene la familia auditable de libros Excel con formulas para
validar los resultados O3 de los niveles `0-nmol/mol`, `80-nmol/mol` y
`180-nmol/mol`.

Estos libros no reemplazan los archivos hardcodeados
`validation_1/validation/excel/validacion_o3/validacion_excel_o3_*.xlsx`.
Su proposito es reconstruir los calculos desde las fuentes usadas por `app.R`,
mantener las formulas visibles y comparar cada bloque contra el snapshot
`validation_1/validation/excel/validacion_o3/valores_validacion_o3.csv`.

## Archivos

| Archivo | Proposito |
|---------|-----------|
| `validacion_formula_o3_0.xlsx` | Libro con formulas para O3 nivel `0-nmol/mol`. |
| `validacion_formula_o3_80.xlsx` | Libro con formulas para O3 nivel `80-nmol/mol`. |
| `validacion_formula_o3_180.xlsx` | Libro con formulas para O3 nivel `180-nmol/mol`. |
| `validacion_heatmaps_o3.xlsx` | Anexo liviano de heat maps; reorganiza `puntajes_EA` sin recalcular scores. |
| `resumen_validacion_formulas_o3.csv` | Resumen de estado por libro y hoja. |
| `inventario_fase1_o3.md` | Mapeo tecnico de snapshot, hojas y tolerancias. |

El generador vive un nivel arriba:

```bash
Rscript validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R
```

## Fuentes

El flujo usa estas fuentes desde la raiz del proyecto:

| Fuente | Uso |
|--------|-----|
| `data/homogeneity - homogeneity.csv` | Datos crudos de homogeneidad. |
| `data/stability - stability.csv` | Datos crudos de estabilidad. |
| `data/summary_n13.csv` | Resultados de participantes y referencia. |
| `data/pt_data_n13.csv` | Incertidumbre `u_i` reportada por participante. |
| `validation_1/validation/excel/validacion_o3/valores_validacion_o3.csv` | Snapshot esperado para comparacion. |

## Refrescar snapshot

Cuando cambie `app.R`, las fuentes de datos o las reglas de calculo, primero
regenere el snapshot congelado:

```bash
Rscript validation_1/validation/excel/validacion_o3/generar_valores_validacion_o3.R
```

Ese script tambien regenera los libros hardcodeados actuales
`validacion_excel_o3_*.xlsx`.

## Generar libros con formulas

Desde la raiz del proyecto:

```bash
Rscript validation_1/validation/excel/validacion_o3/script_excel_formulas_validacion_o3.R
```

El script crea los tres libros `validacion_formula_o3_*.xlsx`, crea el anexo
`validacion_heatmaps_o3.xlsx` y exporta `resumen_validacion_formulas_o3.csv`.
Como `openxlsx` escribe formulas pero no calcula sus valores, despues de
generar hay que recalcular los tres libros principales con LibreOffice u otro
motor de hoja de calculo. Antes de ese paso, las hojas que dependen de formulas
quedan marcadas como `PENDIENTE_RECALCULO`.

## Recalcular con LibreOffice

Use un directorio temporal:

```bash
mkdir -p /tmp/pt_o3_formula_recalc/out
cp validation_1/validation/excel/validacion_o3/formulas/validacion_formula_o3_*.xlsx /tmp/pt_o3_formula_recalc/
libreoffice --headless --convert-to xlsx --outdir /tmp/pt_o3_formula_recalc/out /tmp/pt_o3_formula_recalc/validacion_formula_o3_*.xlsx
cp /tmp/pt_o3_formula_recalc/out/validacion_formula_o3_*.xlsx validation_1/validation/excel/validacion_o3/formulas/
```

Use las copias recalculadas para revisar `validacion_final`. El estado esperado
en cada libro es:

| Campo | Valor esperado |
|-------|----------------|
| `Estado global` | `OK` |
| `Total errores Excel` | `0` |

## Verificacion rapida

El CSV de resumen debe mostrar `OK` en las hojas con comparacion y cero errores:

```bash
Rscript -e 'x <- read.csv("validation_1/validation/excel/validacion_o3/formulas/resumen_validacion_formulas_o3.csv"); print(subset(x, hoja == "Estado global", c(workbook, estado, total_errores_excel)))'
```

Tambien se puede escanear el XML interno para detectar literales de error:

```bash
for f in validation_1/validation/excel/validacion_o3/formulas/validacion_formula_o3_*.xlsx; do
  unzip -p "$f" 'xl/worksheets/*.xml' | grep -E '#REF!|#DIV/0!|#VALUE!|#N/A|#NAME\\?' && echo "Errores en $f"
done
```

Sin salida del comando anterior significa que no se encontraron esos literales.

## Alcance validado

- Homogeneidad y estabilidad con formulas Excel.
- Valor asignado por referencia, MADe, nIQR, Algoritmo A y expertos.
- Algoritmo A con traza de iteraciones.
- Puntajes `z`, `z'`, `zeta` y `En`.
- Informe global con conteos por metodo, score y categoria.
- Heat maps globales en `validacion_heatmaps_o3.xlsx`, como anexo separado:
  participantes en filas, niveles en columnas y valores tomados de
  `puntajes_EA`.

Los colores de heat map son opcionales y no forman parte del criterio de
aceptacion actual.
