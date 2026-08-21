suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

root <- "/home/w182/w421/pt_app"
raw_dir <- file.path(root, "data_use_cases/data/raw")
out_dir <- file.path(root, "informe_resultados_files")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

files <- c(
  "R1_SO2.csv", "R1_CO.csv", "R2A_O3.csv", "R2B_NO.csv",
  "R2C_NO2.csv", "R3_O3.csv", "R3_NO.csv", "R3_NO2.csv"
)

meta <- tibble(
  archivo = files,
  ronda = c("R1", "R1", "R2", "R2", "R2", "R3", "R3", "R3"),
  analito = c("SO2", "CO", "O3", "NO", "NO2", "O3", "NO", "NO2"),
  unidad = c("ppb", "ppm", "ppb", "ppb", "ppb", "ppb", "ppb", "ppb"),
  participante = c("P1", "P1", "P1", "P1", "P1", "P2", "P2", "P2")
)

runtime_minutes <- function(x) {
  p <- strsplit(x, ":", fixed = TRUE)
  vapply(p, function(z) {
    if (length(z) != 2 || any(is.na(suppressWarnings(as.numeric(z))))) return(NA_real_)
    as.numeric(z[1]) * 60 + as.numeric(z[2])
  }, numeric(1))
}

read_one <- function(archivo, ronda, analito, unidad, participante) {
  file <- archivo
  x <- read_csv(file.path(raw_dir, file), col_types = cols(.default = col_character()), show_col_types = FALSE)
  prefix <- tolower(analito)
  measure_cols <- names(x)[startsWith(names(x), paste0(prefix, "_"))]
  measure_cols <- measure_cols[!grepl("_gen$", measure_cols)]
  ref_col <- measure_cols[grepl("_4U", measure_cols)][1]
  part_col <- setdiff(measure_cols, ref_col)[1]
  gen_col <- paste0(prefix, "_gen")

  tibble(
    archivo = file,
    ronda = ronda,
    analito = analito,
    unidad = unidad,
    participante = participante,
    minuto = runtime_minutes(x$runtime),
    fila = seq_len(nrow(x)),
    nivel = suppressWarnings(as.integer(x$level)),
    nominal = suppressWarnings(parse_double(x[[gen_col]], na = c("", "NA"))),
    referencia = suppressWarnings(parse_double(x[[ref_col]], na = c("", "NA", "Samp<"))),
    participante_valor = suppressWarnings(parse_double(x[[part_col]], na = c("", "NA", "Samp<")))
  ) |>
    pivot_longer(c(referencia, participante_valor), names_to = "rol", values_to = "valor") |>
    mutate(
      rol = recode(rol, referencia = "Referencia", participante_valor = participante),
      nivel_etiqueta = factor(paste("Nivel", nivel), levels = paste("Nivel", 1:5))
    )
}

datos <- bind_rows(lapply(seq_len(nrow(meta)), function(i) do.call(read_one, as.list(meta[i, ])))) |>
  filter(nivel %in% 1:5)

resumen <- datos |>
  group_by(archivo, ronda, analito, unidad, participante, nivel, nominal, rol) |>
  summarise(
    n = sum(!is.na(valor)),
    media = mean(valor, na.rm = TRUE),
    sd = sd(valor, na.rm = TRUE),
    sesgo = media - first(nominal),
    sesgo_rel_pct = if_else(first(nominal) == 0, NA_real_, 100 * sesgo / first(nominal)),
    .groups = "drop"
  )

write_csv(resumen, file.path(out_dir, "resumen_por_nivel.csv"))

colors <- c("Referencia" = "#1F5A94", "P1" = "#C25D24", "P2" = "#C25D24")
base_theme <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "top",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "#4b5563"),
    axis.title = element_text(face = "bold")
  )

signal_files <- character()
for (f in files) {
  d <- datos |> filter(archivo == f)
  info <- meta |> filter(archivo == f)
  p <- ggplot(d, aes(minuto, valor, color = rol, group = rol)) +
    geom_line(linewidth = 0.55, na.rm = TRUE) +
    facet_wrap(~nivel_etiqueta, ncol = 1, scales = "free") +
    geom_hline(aes(yintercept = nominal), linetype = "dashed", color = "#6b7280", linewidth = 0.45) +
    scale_color_manual(values = colors, name = NULL) +
    labs(
      title = paste0(info$archivo, " — señales por nivel"),
      subtitle = "Línea punteada: nominal del nivel",
      x = "Minutos de ejecución", y = paste0(info$analito, " (", info$unidad, ")")
    ) + base_theme
  out <- paste0("senal_", tools::file_path_sans_ext(f), ".png")
  ggsave(file.path(out_dir, out), p, width = 10, height = 10, dpi = 150, bg = "white")
  signal_files <- c(signal_files, out)
}

zeros <- resumen |>
  filter(nivel == 1) |>
  mutate(panel = paste0(analito, " (", unidad, ")"))
p_zero <- ggplot(zeros, aes(ronda, media, color = rol, group = rol)) +
  geom_hline(yintercept = 0, color = "#6b7280", linetype = "dashed") +
  geom_errorbar(aes(ymin = media - sd, ymax = media + sd), width = 0.12, linewidth = 0.6, position = position_dodge(width = 0.38)) +
  geom_point(size = 2.8, position = position_dodge(width = 0.38)) +
  facet_wrap(~panel, scales = "free_y", ncol = 3) +
  scale_color_manual(values = colors, name = NULL) +
  labs(title = "Ceros por contaminante", subtitle = "Nivel 1: media ± 1 desviación estándar", x = "Ronda", y = "Concentración") +
  base_theme
ggsave(file.path(out_dir, "ceros_por_contaminante.png"), p_zero, width = 11, height = 7, dpi = 150, bg = "white")

cross <- resumen |>
  filter(ronda %in% c("R2", "R3"), analito %in% c("O3", "NO", "NO2"), nivel > 1) |>
  filter(!(analito == "NO2" & nivel == 3)) |>
  mutate(serie = if_else(rol == "Referencia", paste0("Ref ", ronda), rol))

cross_colors <- c("Ref R2" = "#1F5A94", "P1" = "#C25D24", "Ref R3" = "#5B8DB8", "P2" = "#8F3F18")
p_cross <- ggplot(cross, aes(nivel, sesgo_rel_pct, color = serie, group = serie)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "#6b7280") +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.6) +
  facet_wrap(~analito, scales = "free_y") +
  scale_color_manual(values = cross_colors, name = NULL) +
  scale_x_continuous(breaks = 2:5) +
  labs(title = "R2 frente a R3", subtitle = "Sesgo relativo por nivel; NO2 nivel 3 excluido", x = "Nivel", y = "Sesgo relativo (%)") +
  base_theme
ggsave(file.path(out_dir, "comparacion_R2_R3.png"), p_cross, width = 10, height = 5.2, dpi = 150, bg = "white")

paired <- resumen |>
  select(archivo, ronda, analito, unidad, nivel, nominal, rol, media, sd, sesgo_rel_pct) |>
  pivot_wider(names_from = rol, values_from = c(media, sd, sesgo_rel_pct))

part_names <- unique(meta$participante)
for (pn in part_names) {
  if (!paste0("media_", pn) %in% names(paired)) paired[[paste0("media_", pn)]] <- NA_real_
  if (!paste0("sesgo_rel_pct_", pn) %in% names(paired)) paired[[paste0("sesgo_rel_pct_", pn)]] <- NA_real_
}
paired <- paired |>
  mutate(
    media_part = coalesce(.data$media_P1, .data$media_P2),
    sesgo_rel_part = coalesce(.data$sesgo_rel_pct_P1, .data$sesgo_rel_pct_P2),
    diferencia_ref_part = .data$media_Referencia - media_part
  )
write_csv(paired, file.path(out_dir, "resultados_comparativos.csv"))

fmt <- function(x, digits = 2) ifelse(is.na(x), "—", formatC(x, digits = digits, format = "f"))
html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

table_rows <- paired |>
  arrange(match(archivo, files), nivel) |>
  transmute(
    Archivo = archivo,
    Nivel = nivel,
    Nominal = paste0(fmt(nominal), " ", unidad),
    Referencia = fmt(media_Referencia),
    Participante = fmt(media_part),
    `Ref - participante` = fmt(diferencia_ref_part),
    `Sesgo ref (%)` = fmt(sesgo_rel_pct_Referencia),
    `Sesgo part (%)` = fmt(sesgo_rel_part)
  )

make_table <- function(df) {
  heads <- paste0("<th>", html_escape(names(df)), "</th>", collapse = "")
  rows <- apply(df, 1, function(r) paste0("<tr>", paste0("<td>", html_escape(r), "</td>", collapse = ""), "</tr>"))
  paste0("<div class='table-wrap'><table><thead><tr>", heads, "</tr></thead><tbody>", paste(rows, collapse = "\n"), "</tbody></table></div>")
}

nonzero <- resumen |> filter(nivel > 1, !is.na(sesgo_rel_pct))
worst <- nonzero |> slice_max(abs(sesgo_rel_pct), n = 6, with_ties = FALSE)
worst_items <- paste0(
  "<li><strong>", worst$archivo, ", nivel ", worst$nivel, ", ", worst$rol,
  ":</strong> media ", fmt(worst$media), " ", worst$unidad,
  "; sesgo ", fmt(worst$sesgo_rel_pct), "%.</li>", collapse = "\n"
)

zero_items <- zeros |> arrange(archivo, rol) |>
  transmute(text = paste0("<li><strong>", archivo, " — ", rol, ":</strong> ", fmt(media, 3), " ± ", fmt(sd, 3), " ", unidad, ".</li>")) |>
  pull(text) |>
  paste(collapse = "\n")

signal_sections <- paste(vapply(seq_along(files), function(i) {
  info <- meta[i, ]
  paste0(
    "<section><h3>", info$archivo, "</h3>",
    "<p>", info$analito, " en ", info$unidad, ". Referencia y ", info$participante, " por nivel.</p>",
    "<img src='informe_resultados_files/", signal_files[i], "' alt='Señales de ", info$archivo, " por nivel'>",
    "</section>"
  )
}, character(1)), collapse = "\n")

css <- "
:root{--ink:#24303f;--muted:#5f6b78;--line:#d7dee7;--soft:#f5f7fa;--blue:#1F5A94;}
*{box-sizing:border-box} body{margin:0;background:#fff;color:var(--ink);font:16px/1.55 system-ui,-apple-system,Segoe UI,sans-serif}
main{max-width:1120px;margin:auto;padding:32px 28px 64px} h1{font-size:2rem;margin-bottom:.25rem} h2{margin-top:2.5rem;border-bottom:2px solid var(--line);padding-bottom:.35rem} h3{margin-top:2rem}
.meta{color:var(--muted);margin-top:0}.lead{font-size:1.08rem;max-width:900px} nav{background:var(--soft);border:1px solid var(--line);padding:14px 18px;margin:24px 0} nav a{margin-right:18px;color:var(--blue)}
img{display:block;width:100%;height:auto;border:1px solid var(--line);margin:12px 0 28px}.table-wrap{overflow-x:auto;border:1px solid var(--line)}table{width:100%;border-collapse:collapse;font-size:.88rem}th,td{padding:8px 10px;border-bottom:1px solid var(--line);text-align:right;white-space:nowrap}th{background:#eaf0f5;position:sticky;top:0}th:first-child,td:first-child{text-align:left}tbody tr:nth-child(even){background:#fafbfc}
li{margin:.35rem 0}.note{color:var(--muted);font-size:.92rem} @media(max-width:700px){main{padding:20px 14px}h1{font-size:1.6rem}nav a{display:block;margin:5px 0}}
@media print{main{max-width:none;padding:0}nav{display:none}img{break-inside:avoid}section{break-before:page}}
"

html <- paste0(
"<!doctype html><html lang='es'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>",
"<title>Resultados preliminares — Rondas PT</title><style>", css, "</style></head><body><main>",
"<h1>Resultados preliminares — Rondas PT</h1><p class='meta'>R1, R2 y R3 · generado 2026-07-30</p>",
"<p class='lead'>Informe directo de señales y resúmenes por nivel. Cálculos usan filas etiquetadas como niveles 1–5; transiciones <code>estab</code> quedan fuera. Valores no numéricos se tratan como ausentes. Resultados son descriptivos y no incluyen todavía filtrado Hampel ni inferencia formal.</p>",
"<nav><a href='#resultados'>Resultados</a><a href='#senales'>Señales</a><a href='#ceros'>Ceros</a><a href='#r2r3'>R2–R3</a><a href='#tabla'>Tabla completa</a></nav>",
"<h2 id='resultados'>Resultados destacados</h2><p>Mayores sesgos relativos observados en niveles distintos de cero:</p><ul>", worst_items, "</ul>",
"<h2 id='senales'>Señales por archivo y nivel</h2>", signal_sections,
"<h2 id='ceros'>Ceros por contaminante</h2><img src='informe_resultados_files/ceros_por_contaminante.png' alt='Ceros separados por contaminante'><ul>", zero_items, "</ul><p class='note'>Cada panel usa escala propia: CO en ppm y demás contaminantes en ppb. Ceros de R3_NO y R3_NO2 comparten el mismo período inicial y no deben sumarse como evidencia independiente.</p>",
"<h2 id='r2r3'>Comparación R2–R3</h2><img src='informe_resultados_files/comparacion_R2_R3.png' alt='Comparación de sesgo relativo entre R2 y R3'><p>O3 usa nominales idénticos. Diferencias nominales de NO se aceptan. En NO2 se excluye nivel 3 de esta comparación; nivel 2 de R3 conserva nominal declarado de 144 ppb sin corrección.</p>",
"<h2 id='tabla'>Resumen completo por nivel</h2>", make_table(table_rows),
"<h2>Lectura final</h2><ul><li>Gráficas muestran referencia y participante sobre misma escala dentro de cada archivo.</li><li>Comparación entre P1 y P2 es descriptiva: participantes, fechas y mezclas cambian entre R2 y R3.</li><li>Sesgos se presentan sin corrección.</li><li>Interrupciones temporales y excursiones visibles requieren revisión antes de conclusiones metrológicas definitivas.</li></ul>",
"</main></body></html>"
)
writeLines(html, file.path(root, "informe_resultados.html"), useBytes = TRUE)
cat("Creado:", file.path(root, "informe_resultados.html"), "\n")
