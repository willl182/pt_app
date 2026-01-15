# ===================================================================
# Generación de anexos de validación - Deliverable 09
# Proyecto: PT App
# Referencias: ISO 13528:2022; ISO 17043:2024
# Fecha: 2026-01-11
# ===================================================================

obtener_directorio_script <- function() {
  # Intentar desde argumentos de linea de comandos
  argumentos <- commandArgs(trailingOnly = FALSE)
  archivo <- argumentos[grep("--file=", argumentos)]
  if (length(archivo) > 0) {
    return(dirname(normalizePath(sub("--file=", "", archivo))))
  }
  
  # Intentar desde sys.frame
  if (!is.null(sys.frame(1)$ofile)) {
    return(dirname(normalizePath(sys.frame(1)$ofile)))
  }
  
  # Buscar directorio conocido
  candidatos <- c(
    file.path(getwd(), "deliv", "09_informe_final", "R"),
    "/home/w182/w421/pt_app/deliv/09_informe_final/R"
  )
  
  for (candidato in candidatos) {
    if (dir.exists(candidato)) {
      return(normalizePath(candidato))
    }
  }
  
  # Fallback: buscar pt_app en el path actual
  wd <- getwd()
  if (grepl("pt_app", wd)) {
    base <- sub("/deliv.*", "", wd)
    ruta <- file.path(base, "deliv", "09_informe_final", "R")
    if (dir.exists(ruta)) {
      return(normalizePath(ruta))
    }
  }
  
  return(normalizePath(getwd()))
}

registrar_evento <- function(archivo_log, mensaje) {
  marca_tiempo <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(paste0("[", marca_tiempo, "] ", mensaje, "\n"), file = archivo_log, append = TRUE)
}

script_dir <- obtener_directorio_script()
base_dir <- dirname(script_dir)
data_dir <- normalizePath(file.path(base_dir, "..", "..", "data"))
output_dir <- file.path(script_dir, "output")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

archivo_log <- file.path(output_dir, "ejecucion_log.txt")
if (file.exists(archivo_log)) {
  file.remove(archivo_log)
}
registrar_evento(archivo_log, "Inicio de generación de anexos")
registrar_evento(archivo_log, paste("Directorio de datos:", data_dir))

homogeneidad <- read.csv(file.path(data_dir, "homogeneity.csv"))
estabilidad <- read.csv(file.path(data_dir, "stability.csv"))
resumen <- read.csv(file.path(data_dir, "summary_n4.csv"))
participantes <- read.csv(file.path(data_dir, "participants_data4.csv"))

registrar_evento(archivo_log, "Datos cargados correctamente")

# -------------------------------------------------------------------
# Homogeneidad (ISO 13528:2022, Anexo B.3-B.4)
# -------------------------------------------------------------------
homo_sub <- subset(homogeneidad, pollutant == "co" & level == "2-μmol/mol")
medias_muestra <- aggregate(value ~ sample_id, homo_sub, mean)
desv_muestra <- aggregate(value ~ sample_id, homo_sub, sd)
homo_intermedio <- merge(medias_muestra, desv_muestra, by = "sample_id")
colnames(homo_intermedio) <- c("sample_id", "media", "desviacion")

n_r <- length(unique(homo_sub[["replicate"]]))
s_x <- sd(medias_muestra[["value"]])
s_w <- sqrt(mean(desv_muestra[["value"]]^2))
s_b <- sqrt(max(0, s_x^2 - (s_w^2 / n_r)))

homo_resumen <- data.frame(
  metrica = c("n_replicas", "s_x", "s_w", "s_b"),
  valor = c(n_r, s_x, s_w, s_b)
)

write.csv(homo_intermedio, file.path(output_dir, "homogeneidad_intermedia.csv"), row.names = FALSE)
write.csv(homo_resumen, file.path(output_dir, "homogeneidad_resumen.csv"), row.names = FALSE)
registrar_evento(archivo_log, "Homogeneidad calculada y exportada")

# -------------------------------------------------------------------
# Estabilidad (ISO 13528:2022, Anexo B.7)
# -------------------------------------------------------------------
estab_sub <- subset(estabilidad, pollutant == "co" & level == "2-μmol/mol")
medias_estab <- aggregate(value ~ sample_id, estab_sub, mean)
medias_estab <- medias_estab[order(medias_estab[["sample_id"]]), ]

tiempos <- seq(0, nrow(medias_estab) - 1)
pendiente <- coef(stats::lm(medias_estab[["value"]] ~ tiempos))[2]

estab_intermedio <- data.frame(
  sample_id = medias_estab[["sample_id"]],
  tiempo = tiempos,
  media = medias_estab[["value"]]
)

estab_resumen <- data.frame(
  metrica = c("pendiente"),
  valor = c(as.numeric(pendiente))
)

write.csv(estab_intermedio, file.path(output_dir, "estabilidad_intermedia.csv"), row.names = FALSE)
write.csv(estab_resumen, file.path(output_dir, "estabilidad_resumen.csv"), row.names = FALSE)
registrar_evento(archivo_log, "Estabilidad calculada y exportada")

# -------------------------------------------------------------------
# Puntajes (ISO 13528:2022, 10.4-10.6; ISO 17043:2024)
# -------------------------------------------------------------------
res_sub <- subset(resumen, pollutant == "co" & level == "2-μmol/mol" & sample_group == "1-10")
participantes_sub <- subset(res_sub, participant_id %in% c("part_1", "part_2", "part_3"))
referencia <- subset(res_sub, participant_id == "ref")

x_pt <- referencia[["mean_value"]][1]
x_i <- participantes_sub[["mean_value"]][participantes_sub[["participant_id"]] == "part_1"][1]
s_pt <- sd(participantes_sub[["mean_value"]])

u_x <- referencia[["sd_value"]][1] / sqrt(10)
u_i <- participantes_sub[["sd_value"]][participantes_sub[["participant_id"]] == "part_1"][1] / sqrt(10)

z <- (x_i - x_pt) / s_pt
z_prima <- (x_i - x_pt) / sqrt(s_pt^2 + u_x^2)
zeta <- (x_i - x_pt) / sqrt(u_x^2 + u_i^2)
En <- (x_i - x_pt) / sqrt((2 * u_x)^2 + (2 * u_i)^2)

puntajes_intermedios <- data.frame(
  participante = "part_1",
  x_pt = x_pt,
  x_i = x_i,
  s_pt = s_pt,
  u_x = u_x,
  u_i = u_i,
  z = z,
  z_prima = z_prima,
  zeta = zeta,
  En = En
)

write.csv(puntajes_intermedios, file.path(output_dir, "puntajes_intermedios.csv"), row.names = FALSE)
registrar_evento(archivo_log, "Puntajes calculados y exportados")

# -------------------------------------------------------------------
# Resumen de pruebas
# -------------------------------------------------------------------
criterio_hom <- 0.3 * s_pt
resultado_hom <- ifelse(s_b <= criterio_hom, "Cumple", "No cumple")

criterio_estab <- 0.3 * s_pt
resultado_estab <- ifelse(abs(pendiente) <= criterio_estab, "Cumple", "No cumple")

resultado_z <- ifelse(abs(z) <= 2, "Satisfactorio", "Alerta")
resultado_z_prima <- ifelse(abs(z_prima) <= 2, "Satisfactorio", "Alerta")
resultado_zeta <- ifelse(abs(zeta) <= 2, "Satisfactorio", "Alerta")
resultado_en <- ifelse(abs(En) <= 1, "Satisfactorio", "Alerta")

resumen_pruebas <- data.frame(
  prueba = c("Homogeneidad", "Estabilidad", "z", "z'", "ζ", "En", "Participantes"),
  valor = c(
    round(s_b, 9),
    round(pendiente, 9),
    round(z, 6),
    round(z_prima, 6),
    round(zeta, 6),
    round(En, 6),
    nrow(participantes)
  ),
  criterio = c(
    round(criterio_hom, 9),
    round(criterio_estab, 9),
    "|z| ≤ 2",
    "|z'| ≤ 2",
    "|ζ| ≤ 2",
    "|En| ≤ 1",
    "número de laboratorios"
  ),
  resultado = c(
    resultado_hom,
    resultado_estab,
    resultado_z,
    resultado_z_prima,
    resultado_zeta,
    resultado_en,
    "Informativo"
  )
)

write.csv(resumen_pruebas, file.path(output_dir, "resumen_pruebas.csv"), row.names = FALSE)
registrar_evento(archivo_log, "Resumen de pruebas generado")

registrar_evento(archivo_log, "Finalización de la generación de anexos")

invisible(list(
  homogeneidad = homo_resumen,
  estabilidad = estab_resumen,
  puntajes = puntajes_intermedios,
  resumen = resumen_pruebas
))
