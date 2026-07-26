# Simula 13 participantes (p2..p14) a partir de p1 en ronda_1/2_completa.csv
# Perturbación: cada media horaria de p1 + ruido uniforme en [-2*sd_value, +2*sd_value]
# Recalcula mean_value, sd_value, u_value = sd/sqrt(n_hours); u_exp = k_factor * u_value (si existe)
set.seed(421)

base_dir <- "/home/w182/w421/pt_app/data_use_cases/data/processed"

simulate_round <- function(infile, outfile, n_sim = 13) {
  df <- read.csv(file.path(base_dir, infile), check.names = FALSE,
                 stringsAsFactors = FALSE)
  part <- df[df$tipo == "participante", ]
  sims <- list()
  for (i in seq_len(n_sim)) {
    pid <- paste0("p", i + 1)
    s <- part
    for (r in seq_len(nrow(s))) {
      sd0 <- s$sd_value[r]
      hcols <- c("mean_h1", "mean_h2", "mean_h3")
      vals <- as.numeric(s[r, hcols])
      ok <- !is.na(vals)
      vals[ok] <- vals[ok] + runif(sum(ok), -2 * sd0, 2 * sd0)
      s[r, hcols] <- round(vals, 3)
      m <- mean(vals[ok])
      n <- sum(ok)
      sdv <- if (n > 1) sd(vals[ok]) else sd0
      uv <- sdv / sqrt(n)
      s$mean_value[r] <- round(m, 3)
      s$sd_value[r] <- round(sdv, 3)
      s$u_value[r] <- round(uv, 3)
      if ("u_exp" %in% names(s)) s$u_exp[r] <- round(s$k_factor[r] * uv, 3)
    }
    s$instrument <- pid
    s$participant_id <- pid
    sims[[i]] <- s
  }
  out <- rbind(df, do.call(rbind, sims))
  out$n_lab <- n_sim + 1
  write.csv(out, file.path(base_dir, outfile), row.names = FALSE, na = "NA")
  cat(outfile, ":", nrow(out), "filas\n")
}

simulate_round("ronda_1_completa.csv", "ronda_3_completa.csv")
simulate_round("ronda_2_completa.csv", "ronda_4_completa.csv")
