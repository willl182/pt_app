# ptcalc

Paquete R para cálculos de ensayos de aptitud conforme a ISO 13528:2022 e ISO 17043:2023.

## Instalación

```r
# Desarrollo (desde el directorio pt_app)
devtools::load_all("ptcalc")

# Instalación local
devtools::install("ptcalc")
```

## Funciones Principales

### Estadísticos Robustos

| Función | Descripción |
|---------|-------------|
| `calculate_niqr(x)` | nIQR = 0.7413 × IQR |
| `calculate_mad_e(x)` | MADe = 1.483 × MAD |
| `run_algorithm_a(values, ids, max_iter)` | Algoritmo A ISO 13528 (Winsorización) |

### Cálculo de Puntajes

| Función | Fórmula |
|---------|---------|
| `calculate_z_score(x, x_pt, sigma_pt)` | z = (x - x_pt) / σ_pt |
| `calculate_z_prime_score(x, x_pt, sigma_pt, u_xpt)` | z' = (x - x_pt) / √(σ_pt² + u_xpt²) |
| `calculate_zeta_score(x, x_pt, u_x, u_xpt)` | ζ = (x - x_pt) / √(u_x² + u_xpt²) |
| `calculate_en_score(x, x_pt, U_x, U_xpt)` | En = (x - x_pt) / √(U_x² + U_xpt²) |

### Evaluaciones

| Función | Descripción |
|---------|-------------|
| `evaluate_z_score(z)` | Clasifica: Satisfactorio / Cuestionable / No satisfactorio |
| `evaluate_en_score(en)` | Clasifica: Satisfactorio / No satisfactorio |

### Homogeneidad y Estabilidad

| Función | Descripción |
|---------|-------------|
| `calculate_homogeneity_stats(sample_data)` | Estadísticos ANOVA |
| `calculate_homogeneity_criterion(sigma_pt)` | c = 0.3 × σ_pt |
| `evaluate_homogeneity(ss, c_criterion)` | Evalúa criterio |
| `calculate_stability_stats(stab_data, hom_mean)` | Estadísticos de estabilidad |

## Ejemplo

```r
library(ptcalc)

# Algoritmo A
valores <- c(10.1, 10.2, 9.9, 10.0, 10.3, 50.0)
resultado <- run_algorithm_a(valores)
cat("Media robusta:", resultado$assigned_value, "\n")
cat("Desviación robusta:", resultado$robust_sd, "\n")

# Ver valores winsorizados
head(resultado$winsorized_values)

# Puntaje z
z <- calculate_z_score(x = 10.5, x_pt = 10.0, sigma_pt = 0.5)
cat("z =", z, "-", evaluate_z_score(z))
```

## Referencias

- ISO 13528:2022 - Statistical methods for use in proficiency testing
- ISO 17043:2023 - Conformity assessment — General requirements for proficiency testing

## Licencia

MIT © 2026 Universidad Nacional de Colombia (Laboratorio CALAIRE) & Instituto Nacional de Metrología

Desarrollado bajo contrato OSE-282-3065-2025.
