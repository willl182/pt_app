# Plan: Reorganización del Repositorio pt_app

**Timestamp:** 260508_2328  
**Slug:** reorganizar-repo-limpiar-artefactos  
**Estado:** Completado (Fases 1-4)

## Objetivo

Reducir el repositorio `pt_app` a su contenido esencial (código fuente, datos de entrada, validación activa, documentación del proyecto) eliminando del tracking ~210 archivos (~48 MB en disco) que son artefactos generados, configuraciones locales, binarios duplicados, normas con restricciones de distribución y carpetas históricas.

**Restricción:** El directorio `data/` NO se toca. Todos los archivos dentro de `data/` permanecen intactos.

## Métricas Actuales

| Métrica | Valor |
|---------|-------|
| Archivos tracked totales | 390 |
| Archivos a eliminar del tracking | ~208 |
| Archivos que quedarían | ~182 |
| Tamaño `.git/` actual | 307 MB |
| Tamaño removible en disco | ~48 MB |
| Binarios tracked (docx/pdf/xlsx) | 67 |

## Decisión Previa: `ptcalc/`

`ptcalc/` ya está en `.gitignore` y tiene 0 archivos tracked en `pt_app`. Tiene su propio `.git` con remoto `https://github.com/willl182/ptcalc.git`. **Decisión requerida del usuario** (ver Fase 5).

---

## Fases

### Fase 1: Limpieza de configuración IDE/agente
**Riesgo:** Bajo  
**Impacto:** Elimina archivos que nunca debieron ser versionados  
**Nota:** No se toca `data/`. Los lock files dentro de `data/` se dejan para manejo manual.

| Item | Archivo(s) | Acción | Estado |
|------|-----------|--------|--------|
| Lock file en final_reports | `final_reports/.~lock.Informe_EA_2026-01-10_13-z-2a-2a.docx#` | `git rm` | Pendiente |
| Config `.codex` | `.codex` | `git rm --cached` + `.gitignore` | Pendiente |
| Config `.gemini/` | `.gemini/settings.json` | `git rm --cached` + `.gitignore` | Pendiente |
| Config `.opencode/` | `.opencode/package-lock.json`, `.opencode/plans/*.md` | `git rm --cached` + `.gitignore` | Pendiente |
| Config `.vscode/` | `.vscode/settings.json` | `git rm --cached` + `.gitignore` | Pendiente |
| Workspace file | `pt_app.code-workspace` | `git rm --cached` + `.gitignore` | Pendiente |
| Deploy config | `rsconnect/` | `git rm --cached` + `.gitignore` | Pendiente |
| Deploy manifest | `manifest.json` | `git rm --cached` + `.gitignore` | Pendiente |

> [!NOTE]
> Se usa `git rm --cached` para dejar los archivos en disco pero sacarlos del tracking.

**Comandos:**
```bash
# Lock file en final_reports — eliminar del disco y del tracking
git rm "final_reports/.~lock.Informe_EA_2026-01-10_13-z-2a-2a.docx#"

# Configs — sacar del tracking, mantener en disco
git rm --cached .codex
git rm --cached .gemini/settings.json
git rm --cached -r .opencode/
git rm --cached .vscode/settings.json
git rm --cached pt_app.code-workspace
git rm --cached -r rsconnect/
git rm --cached manifest.json
```

---

### Fase 2: Eliminar artefactos generados (previews HTML + reportes finales)
**Riesgo:** Bajo  
**Impacto:** ~40 MB de HTML previews + ~4 MB de docx generados

| Item | Ruta | Archivos | Tamaño | Acción | Estado |
|------|------|----------|--------|--------|--------|
| HTML previews | `www/preview/` | 13 | 36 MB | `git rm` + `.gitignore` | Pendiente |
| Reportes generados | `final_reports/` | 12 docx | 4.1 MB | `git rm` + `.gitignore` | Pendiente |

> [!IMPORTANT]
> Estos archivos son **salidas** de la app, no código fuente. Se regeneran ejecutando la aplicación. No deben versionarse.

**Comandos:**
```bash
git rm -r www/preview/
git rm -r final_reports/
```

---

### Fase 3: Extraer documentación histórica y normas ISO
**Riesgo:** Medio — requiere verificar que no haya referencias internas  
**Impacto:** Elimina material con restricciones de distribución y binarios duplicados de `.md`

| Item | Ruta | Archivos | Acción | Estado |
|------|------|----------|--------|--------|
| Normas ISO (PDF+MD) | `ppsea09/iso 13528_2022.md`, `ppsea09/iso 17043_2023 eng.pdf`, `ppsea09/iso 17043_2023.md` | 3 | `git rm` — material con copyright, no redistribuible | Pendiente |
| Planes de agentes (ppsea09) | `ppsea09/claude_*.md`, `ppsea09/gem_*.md`, `ppsea09/gpt_*.md`, `ppsea09/z_planea.md` | 7 | Evaluar: ¿mantener como referencia histórica o archivar? | Pendiente |
| Docs procedimiento (ppsea09) | `ppsea09/p-psea-06.md`, `ppsea09/P-PSEA-09.md` | 2 | Mantener si son docs activos del proyecto | Pendiente |
| Directorio `es/` | `es/*.docx` (23) + `es/*.md` (24) | 47 | `git rm` — docx duplican md; mover md relevantes a `docs/` | Pendiente |
| Directorio `deliv/` | Mezcla de entregables, HTML, código | 65 | `git rm` todo — archivar externamente si se necesita | Pendiente |
| Binarios raíz | Ver tabla abajo | 7 | `git rm` | Pendiente |

**Binarios raíz a eliminar:**

| Archivo | Tamaño | Razón |
|---------|--------|-------|
| `P-PSEA-06 Procedimiento Diseño Estadistico_v0.docx` | 40 KB | Existe `.md` v1 |
| `ppsea06.docx` | 21 KB | Duplicado de P-PSEA-06 |
| `Revisión aplicativo estadístico.pdf` | 383 KB | Revisión histórica |
| `rta rev1.pdf` | 1.9 MB | Respuesta histórica |
| `rev_1.xlsx` | 1007 KB | Revisión histórica |
| `validacion_algoritmo_a.pdf` | 204 KB | Existe validación activa en `validation/` |
| `Homogenidad y estabilidad.xlsx` (RAÍZ) | 1006 KB | Versión anterior a `data/Homogenidad y estabilidad.xlsx` — este es el de la RAÍZ, no el de data/ |

> [!WARNING]
> **Normas ISO:** Estas normas son material protegido por copyright. Versionar copias completas en un repo público viola los términos de distribución de ISO. Se deben eliminar y referenciar externamente.

**Verificaciones previas a ejecutar:**
```bash
# Buscar referencias internas a archivos de ppsea09/iso*
grep -r "iso 13528" --include="*.R" --include="*.md" --include="*.Rmd" .
grep -r "iso 17043" --include="*.R" --include="*.md" --include="*.Rmd" .
# Buscar referencias a archivos de es/ o deliv/
grep -r "es/" --include="*.R" . | grep -v "tests\|values\|scores"
grep -r "deliv/" --include="*.R" .
```

**Comandos (después de verificación):**
```bash
# ISO — eliminar definitivamente
git rm "ppsea09/iso 13528_2022.md"
git rm "ppsea09/iso 17043_2023 eng.pdf"
git rm "ppsea09/iso 17043_2023.md"

# es/ completo
git rm -r es/

# deliv/ completo
git rm -r deliv/

# Binarios raíz (NO incluye nada de data/)
git rm "P-PSEA-06 Procedimiento Diseño Estadistico_v0.docx"
git rm ppsea06.docx
git rm "Revisión aplicativo estadístico.pdf"
git rm "rta rev1.pdf"
git rm rev_1.xlsx
git rm validacion_algoritmo_a.pdf
git rm "Homogenidad y estabilidad.xlsx"
```

---

### Fase 4: Archivar validaciones legacy y datos obsoletos de la raíz
**Riesgo:** Bajo-Medio — verificar que no se usen en tests activos  
**Impacto:** Limpia carpetas de validación históricas  
**Nota:** Solo archivos en la RAÍZ, `data/` no se toca.

| Item | Ruta | Archivos | Acción | Estado |
|------|------|----------|--------|--------|
| Validación parte 1 | `validation_parte_1/` | 15 (xlsx) | `git rm` — archivar en release/externo | Pendiente |
| Validación parte 2 | `validacion_parte_2/` | 18 | `git rm` — planes POC de agentes | Pendiente |
| Mods | `mods/` | 5 | `git rm` — resultados/planes de modelos | Pendiente |
| CSV obsoletos RAÍZ | `datos_ronda.csv`, `datos_estabilidad_homogeneidad.csv` | 2 | `git rm` — versiones anteriores; datos actuales viven en `data/raw/` | Pendiente |
| Archivos misc raíz | `gemini-king-mode.md`, `instruccion.md`, `plan_preprocesamiento.md`, `%` | 4 | `git rm` — notas sueltas sin estructura | Pendiente |

> [!NOTE]
> Los CSV raíz (`datos_ronda.csv`, `datos_estabilidad_homogeneidad.csv`) son versiones **anteriores** a las de `data/raw/`. No son duplicados exactos pero sí obsoletos. Se eliminan de la RAÍZ; `data/raw/` NO se toca.

**Verificaciones previas:**
```bash
# Asegurar que validation/ (activa) no depende de validation_parte_1/ ni validacion_parte_2/
grep -r "validation_parte_1\|validacion_parte_2" --include="*.R" --include="*.py" .
# Verificar que app.R no usa datos_ronda.csv o datos_estabilidad de la raíz
grep -r "datos_ronda\|datos_estabilidad" app.R
```

**Comandos (después de verificación):**
```bash
git rm -r validation_parte_1/
git rm -r validacion_parte_2/
git rm -r mods/
git rm datos_ronda.csv
git rm datos_estabilidad_homogeneidad.csv
git rm gemini-king-mode.md
git rm instruccion.md
git rm plan_preprocesamiento.md
git rm "%"
```

---

### Fase 5: Resolver repositorio Git anidado — `ptcalc/`
**Riesgo:** Ya mitigado (ptcalc/ está en .gitignore, 0 archivos tracked)  
**Decisión del usuario requerida**

`ptcalc/` ya está ignorado por `pt_app` y no tiene archivos tracked en el repo padre. Sin embargo, su `.git/` anidado puede causar confusión.

**Opciones:**

| Opción | Descripción | Pros | Contras |
|--------|-------------|------|---------|
| **A) Mantener como está** | ptcalc/ en .gitignore, repo independiente | Sin cambios, ya funciona | Confuso para nuevos devs |
| **B) Convertir a submódulo** | `git submodule add` | Relación formal, versión pinneada | Más complejidad operativa |
| **C) Instalar como dependencia** | `devtools::install_github("willl182/ptcalc")` | Separación limpia | Requiere cambiar workflow |
| **D) Absorber en monorepo** | `rm -rf ptcalc/.git`, sacar de .gitignore | Un solo repo | Pierde historial independiente |

**Recomendación:** Opción **A** o **C** según el flujo de trabajo actual. Si usas `devtools::load_all("ptcalc")` frecuentemente durante desarrollo, **A es suficiente** — solo documentar en README que ptcalc es un repo hermano.

---

## Fase Final: Actualizar `.gitignore`

El `.gitignore` actual es mínimo:
```
*.log
__pycache__/
*.pyc
20251020 Propuesta Desarrollo.md
conductor/abkvQAu7TAaaXEzihB08_WOL-web.jpg
ptcalc/
```

**`.gitignore` propuesto:**
```gitignore
# === Temporales y sistema ===
*.log
__pycache__/
*.pyc
.DS_Store
Thumbs.db
*~
.~lock.*

# === IDE y editores ===
.vscode/
.codex
.opencode/
.gemini/
*.code-workspace

# === Despliegue (específico de cuenta) ===
rsconnect/
manifest.json

# === Artefactos generados por la app ===
final_reports/
www/preview/

# === Paquete ptcalc (repo independiente) ===
ptcalc/

# === Archivos específicos históricos ===
20251020 Propuesta Desarrollo.md
conductor/abkvQAu7TAaaXEzihB08_WOL-web.jpg
```

---

## Evaluación de `.rscignore`

El `.rscignore` actual excluye del deploy: `deliv/`, `tests/`, `validation/`, `www/preview/`, `dev/`, `conductor/`, `rsconnect/`, `scripts/`, `reports/`, `final_reports/`, `tools/`, `es/`, `.gemini/`, `.vscode/`.

Después de la limpieza, se debería simplificar ya que muchas de esas carpetas ya no existirán:

```
tests/
validation/
scripts/
reports/
tools/
logs/
```

---

## Resumen de Impacto

| Métrica | Antes | Después |
|---------|-------|---------|
| Archivos tracked | 390 | ~182 |
| Binarios tracked | 67 | ~10 (data/*.xlsx, logo.png) |
| Carpetas tracked | ~15 | ~8 |
| Material con restricción de copyright | 3 archivos ISO | 0 |
| Archivos en `data/` afectados | — | **0** |

## Orden de Ejecución

```
Fase 1 → commit "chore: remove IDE configs and lock files from tracking"
Fase 2 → commit "chore: remove generated outputs (previews, reports)"
Fase 3 → commit "chore: remove historical docs, ISO copies, and root binaries"
Fase 4 → commit "chore: remove legacy validations and obsolete root data"
.gitignore → commit "chore: update .gitignore for clean repo"
Fase 5 → decisión del usuario (no requiere commit)
```

> [!CAUTION]
> Después de completar todas las fases, considerar ejecutar `git filter-branch` o `git-filter-repo` para purgar los binarios del historial y reducir el tamaño de `.git/` (actualmente 307 MB). Esto es una operación destructiva que reescribe el historial — solo hacerlo si el repo no tiene muchos forks/clones activos.

## Log de Ejecución
- [260508 23:28] Plan creado con auditoría verificada
- [260508 23:30] Ajuste: `data/` excluido explícitamente de todas las fases. Lock file `data/.~lock.*` dejado para manejo manual.
- [260509 06:16] Fase 1 completada — 10 archivos IDE/config movidos a `mover/`
- [260509 06:16] Fase 2 completada — 25 archivos generados movidos a `mover/` (www/preview + final_reports)
- [260509 06:16] Fase 3 completada — 122 archivos docs/ISO/binarios movidos a `mover/` (ppsea09, es, deliv, binarios raíz)
- [260509 06:16] Fase 4 completada — 44 archivos legacy movidos a `mover/` (validation_parte_1/2, mods, CSV raíz, misc)
- [260509 06:17] .gitignore actualizado con patrones comprehensivos + `mover/`
- [260509 06:17] Commit: "chore: reorganizar repo" — 390→181 archivos tracked, data/ intacto (50 archivos)
