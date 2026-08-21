# 08_u_curva_calibracion.R
# Contribucion a la incertidumbre proveniente de la curva de calibracion
# Metodos: (1) GUM H.3 minimos cuadrados sobre parametros del ajuste
#          (2) EN 14211 / EN 14212 "lack of fit" (residuo maximo, dist. rectangular)
# Fuente: F-PSEY-49 (O3, MED-UNNP, 2026-04-29), F-PSEY-61 (NOx/NO/NO2, CALAIRE, 2026-04-29),
#         F-PSEY-62 (SO2, CALAIRE, 2026-04-22), F-PSEY-47 (CO, CALAIRE, 2026-04-22)

options(digits = 8)

# ---- datos multipunto (patron vs lectura analizador, promedios n=~5 lecturas) ----
curvas <- list(
  O3 = list(
    x = c(0, 38, 79.8, 139.6, 180),
    y = c(0.08, 38.66, 77.78, 139.42, 179.96),
    lh = 100, unidad = "ppb", fuente = "F-PSEY-49"
  ),
  NO = list(
    x = c(0, 40, 80.6, 140.4, 180),
    y = c(-0.16, 39.062, 80.0925, 140.516, 180.12),
    lh = 100, unidad = "ppb", fuente = "F-PSEY-61"
  ),
  NOx = list(
    x = c(0, 40, 80.6, 140.4, 180),
    y = c(0.03, 40.186, 81.30, 140.688, 179.718),
    lh = 100, unidad = "ppb", fuente = "F-PSEY-61"
  ),
  NO2_GPT = list(
    x = c(0, 29.778, 61.416, 100.994, 148.588),
    y = c(0.19, 31.376, 62.076, 101.31, 148.872),
    lh = 100, unidad = "ppb", fuente = "F-PSEY-61"
  ),
  SO2 = list(
    x = c(0, 40, 80, 119, 179),
    y = c(-0.024, 40.532, 79.73, 118.442, 179.028),
    lh = 100, unidad = "ppb", fuente = "F-PSEY-62"
  ),
  CO = list(  # ppm, rango analizador 10 ppm
    x = c(0, 1.4, 2.8, 4.2, 6.3),
    y = c(0.008, 1.487, 2.747, 4.16, 6.293),
    lh = 5, unidad = "ppm", fuente = "F-PSEY-47"
  )
)

# ---- (1) GUM H.3: regresion y = y1 + y2*x, prediccion inversa x0 = (y - y1)/y2 ----
u_curva <- function(x, y, x_eval) {
  n <- length(x)
  fit <- lm(y ~ x)
  y1 <- unname(coef(fit)[1]); y2 <- unname(coef(fit)[2])
  res <- residuals(fit)
  s2 <- sum(res^2) / (n - 2)                     # varianza residual
  Sxx <- sum((x - mean(x))^2)
  u_y1 <- sqrt(s2 * sum(x^2) / (n * Sxx))        # H.13c
  u_y2 <- sqrt(s2 / Sxx)                         # H.13d
  r12  <- -mean(x) / sqrt(sum(x^2) / n)          # H.13e
  # u del valor ajustado en x_eval (se ensancha en extremos)
  u_fit <- sqrt(s2 * (1 / n + (x_eval - mean(x))^2 / Sxx))
  # trasladado a escala de concentracion (division por pendiente)
  u_x <- u_fit / abs(y2)
  list(n = n, y1 = y1, y2 = y2, s = sqrt(s2), u_y1 = u_y1, u_y2 = u_y2, r12 = r12,
       Sxx = Sxx, xbar = mean(x), res = res,
       tabla = data.frame(nivel = x_eval, u_fit = u_fit, u_x = u_x,
                          u_rel_pct = 100 * u_x / ifelse(x_eval == 0, NA, x_eval)))
}

# ---- (2) lack of fit EN 14211/14212 ----
u_lof <- function(x, y, lh, span) {
  fit <- lm(y ~ x)
  res <- residuals(fit)
  rmax_pct <- 100 * max(abs(res)) / span   # residuo maximo relativo al fondo de escala
  list(rmax_abs = max(abs(res)), rmax_pct = rmax_pct,
       u = (rmax_pct / 100) * lh / sqrt(3))
}

for (g in names(curvas)) {
  cv <- curvas[[g]]
  span <- max(cv$x)
  # rejilla de evaluacion en la escala propia de cada gas (ppb o ppm)
  niveles <- sort(unique(c(0, round(span * seq(0.1, 1, by = 0.1), 3))))
  a <- u_curva(cv$x, cv$y, niveles[niveles <= span])
  b <- u_lof(cv$x, cv$y, cv$lh, span)
  cat("\n=====", g, "(", cv$fuente, ") n =", a$n, "\n")
  cat(sprintf("  ajuste: y = %.4f + %.6f x   s(residual) = %.4f %s\n",
              a$y1, a$y2, a$s, cv$unidad))
  cat(sprintf("  u(intercepto) = %.4f   u(pendiente) = %.6f   r(y1,y2) = %.4f\n",
              a$u_y1, a$u_y2, a$r12))
  cat("  residuos:", sprintf("%+.3f", a$res), "\n")
  cat("  -- (1) GUM H.3, u por curva en cada nivel --\n")
  print(a$tabla, row.names = FALSE)
  cat(sprintf("  -- (2) lack of fit: r_max = %.3f %s = %.3f %%FS  ->  u_l,lh(%g %s) = %.3f %s\n",
              b$rmax_abs, cv$unidad, b$rmax_pct, cv$lh, cv$unidad, b$u, cv$unidad))
}
