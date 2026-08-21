# 09_aplicar_u_curva_niveles.R
# Aplica la contribucion de la curva de calibracion a cada nivel PT de cada contaminante
# y la combina en cuadratura con la repetibilidad (u_value) de ronda_3_completa.csv.
#
# Salida: outputs/u_curva_por_nivel.csv

suppressMessages(library(dplyr))

# ---- curvas de calibracion (mismos datos de 08_u_curva_calibracion.R) ----
curvas <- list(
  o3  = list(x = c(0, 38, 79.8, 139.6, 180),
             y = c(0.08, 38.66, 77.78, 139.42, 179.96), fuente = "F-PSEY-49"),
  no  = list(x = c(0, 40, 80.6, 140.4, 180),
             y = c(-0.16, 39.062, 80.0925, 140.516, 180.12), fuente = "F-PSEY-61"),
  nox = list(x = c(0, 40, 80.6, 140.4, 180),
             y = c(0.03, 40.186, 81.30, 140.688, 179.718), fuente = "F-PSEY-61"),
  no2 = list(x = c(0, 29.778, 61.416, 100.994, 148.588),
             y = c(0.19, 31.376, 62.076, 101.31, 148.872), fuente = "F-PSEY-61"),
  so2 = list(x = c(0, 40, 80, 119, 179),
             y = c(-0.024, 40.532, 79.73, 118.442, 179.028), fuente = "F-PSEY-62"),
  co  = list(x = c(0, 1.4, 2.8, 4.2, 6.3),          # ppm
             y = c(0.008, 1.487, 2.747, 4.16, 6.293), fuente = "F-PSEY-47")
)

# unidad de cada curva: CO en ppm (umol/mol), el resto en ppb (nmol/mol)
unidades <- c(o3 = "nmol/mol", no = "nmol/mol", nox = "nmol/mol",
              no2 = "nmol/mol", so2 = "nmol/mol", co = "umol/mol")

# niveles nominales PT por contaminante (indice 1..5 -> concentracion del generador)
niveles_pt <- data.frame(
  pollutant = rep(c("o3", "no", "no2", "so2", "co"), each = 5),
  level_idx = rep(1:5, 5),
  nivel_nominal = c(0, 40, 80, 120, 180,       # o3
                    0, 41, 80, 119, 179,       # no
                    0, 32, 64, 112, 144,       # no2
                    0, 40, 80, 119, 179,       # so2  (R1_SO2 so2_gen)
                    0, 1.4, 2.8, 4.2, 6.3)     # co   (R1_CO co_gen, ppm)
)

# ---- fabrica de funciones u(conc) por contaminante ----
# Devuelve una funcion que evalua la incertidumbre por curva en cualquier nivel.
make_u_curva <- function(x, y) {
  n <- length(x); fit <- lm(y ~ x)
  y2 <- unname(coef(fit)[2])
  s2 <- sum(residuals(fit)^2) / (n - 2)
  Sxx <- sum((x - mean(x))^2); xbar <- mean(x)
  rmax_pct <- 100 * max(abs(residuals(fit))) / max(x)
  function(conc, metodo = c("gum", "lof")) {
    metodo <- match.arg(metodo)
    if (metodo == "gum") {
      sqrt(s2 * (1 / n + (conc - xbar)^2 / Sxx)) / abs(y2)   # GUM H.3, varia con el nivel
    } else {
      (rmax_pct / 100) * conc / sqrt(3)                       # EN 14211/14212, proporcional al nivel
    }
  }
}
u_fun <- lapply(curvas, function(cv) make_u_curva(cv$x, cv$y))

u_curva_nivel <- function(pollutant, conc, metodo = "gum") {
  mapply(function(p, c_) {
    f <- u_fun[[tolower(p)]]
    if (is.null(f)) NA_real_ else f(c_, metodo)
  }, pollutant, conc)
}

# ---- aplicar a los niveles PT ----
dir.create("outputs", showWarnings = FALSE)

d <- read.csv("data/to_calaire-app/ronda_3_completa.csv", stringsAsFactors = FALSE) %>%
  mutate(
    nivel_nominal = as.numeric(sub("-.*$", "", level)),
    u_curva_gum   = u_curva_nivel(pollutant, nivel_nominal, "gum"),
    u_curva_lof   = u_curva_nivel(pollutant, nivel_nominal, "lof"),
    # criterio conservador: el mayor de los dos metodos
    u_curva       = pmax(u_curva_gum, u_curva_lof, na.rm = TRUE),
    u_repet       = u_value,                       # s/sqrt(n) ya calculado en el pipeline
    u_comb        = sqrt(u_repet^2 + u_curva^2),
    U_exp_k2      = 2 * u_comb
  )

# tabla de referencia: u por curva en TODOS los niveles PT de TODOS los contaminantes
resumen <- niveles_pt %>%
  mutate(
    unidad      = unidades[pollutant],
    u_curva_gum = u_curva_nivel(pollutant, nivel_nominal, "gum"),
    u_curva_lof = u_curva_nivel(pollutant, nivel_nominal, "lof"),
    u_curva     = pmax(u_curva_gum, u_curva_lof, na.rm = TRUE),
    u_rel_pct   = ifelse(nivel_nominal == 0, NA, 100 * u_curva / nivel_nominal)
  )

cat("\n-- u por curva de calibracion en cada nivel PT --\n")
print(as.data.frame(resumen), row.names = FALSE, digits = 4)
write.csv(resumen, "outputs/u_curva_referencia_niveles.csv", row.names = FALSE)

write.csv(d, "outputs/u_curva_por_nivel.csv", row.names = FALSE)
cat("\nescrito: outputs/u_curva_por_nivel.csv\n")
