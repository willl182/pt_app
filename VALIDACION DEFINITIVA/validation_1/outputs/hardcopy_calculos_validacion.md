# Hardcopy de calculos de validacion

Fecha: 2026-05-13

## Fuentes reales usadas

- Etapa 1: data/for_validation/summary_n4.csv; excluye participant_id == ref; O3 en 0, 80 y 180 nmol/mol.
- Etapa 2: data/for_validation/homogeneity_n4.csv.
- Etapa 3: data/for_validation/stability_n4.csv y salida de Etapa 2.
- Etapa 4: salidas de Etapas 2-3 y data/for_validation/summary_n4.csv.
- Etapa 4b: data/for_validation/summary_n4.csv.
- Etapa 5: salida de Etapa 4, data/for_validation/summary_n4.csv y data/pt_data_n13.csv para u_i.

## Formulas clave

- Etapa 1: x_pt = mediana(mean_value); mad = mediana(|x - x_pt|); MADe = 1.483 * mad; nIQR = 0.7413 * (Q3 - Q1), quantile type 7.
- Etapa 2: sw = sqrt(sum((x1 - x2)^2)/(2*g)) cuando m=2; ss = sqrt(abs(var(promedios_muestra) - sw^2/m)); sigma_pt = mediana(|sample_2 - x_pt|); u_sigma_pt = 1.25 * MADe / sqrt(g).
- Etapa 3: diff = |mean_estabilidad - mean_homogeneidad|; u_hom_mean = sd(valores_hom)/sqrt(n); u_stab_mean = sd(valores_stab)/sqrt(n); criterio_expandido = 0.3*sigma_pt_hom + 2*sqrt(u_hom_mean^2 + u_stab_mean^2).
- Etapa 4: u_xpt = 1.25*sigma_pt/sqrt(n_part); u_xpt_def = sqrt(u_xpt^2 + u_hom^2 + u_stab^2); U_xpt = 2*u_xpt_def.
- Etapa 5: z=(result-x_pt)/sigma_pt; z_prime=(result-x_pt)/sqrt(sigma_pt^2+u_xpt_def^2); zeta=(result-x_pt)/sqrt(u_i^2+u_xpt_def^2); En=(result-x_pt)/sqrt((2*u_i)^2+(2*u_xpt_def)^2).

## Etapa 1 - robustos

| combo | n | x_pt | mad | MADe | nIQR |
|---|---:|---:|---:|---:|---:|
| O3_0 | 36 | 0.0000355 | 0.00000645 | 0.00000956535 | 0.00001015581 |
| O3_80 | 36 | 80.10430384 | 0.107068455 | 0.1587825188 | 0.1637101746 |
| O3_180 | 36 | 178.082737 | 0.525199 | 0.778870117 | 0.5989947888 |

## Etapa 2 - homogeneidad

| combo | g | m | mean_homog | x_pt | sw | ss | sigma_pt | MADe | u_sigma_pt | criterio_c | criterio_expandido |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| O3_0 | 10 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| O3_80 | 10 | 2 | 79.8771 | 79.535 | 0.4924852282 | 0.1993078997 | 0.0585 | 0.0867555 | 0.03429312244 | 0.01755 | 0.2455461617 |
| O3_180 | 10 | 2 | 178.23195 | 176.538 | 1.531186386 | 1.343092487 | 1.9325 | 2.8658975 | 1.132845455 | 0.57975 | 2.999863985 |

## Etapa 3 - estabilidad

| combo | g | m | mean_stab | x_pt_stab | sw_stab | ss_stab | diff_hom_stab | u_hom_mean | u_stab_mean | criterio_simple | criterio_expandido |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| O3_0 | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| O3_80 | 2 | 2 | 80.09325 | 80.6615 | 0.8056905423 | 0.5694457832 | 0.21615 | 0.1183584853 | 0.3289978153 | 0.01755 | 0.7168304689 |
| O3_180 | 2 | 2 | 178.452 | 180.4165 | 2.778231542 | 1.964505218 | 0.22005 | 0.4501936921 | 1.134208608 | 0.57975 | 3.020326593 |

## Etapa 4 - incertidumbre por metodo

| combo | metodo | x_pt | sigma_pt | u_xpt | u_hom | u_stab | u_xpt_def | U_xpt |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| O3_0 | Referencia | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| O3_0 | Consenso MADe | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| O3_0 | Consenso nIQR | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| O3_0 | Algoritmo A | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| O3_80 | Referencia | 79.535 | 0.0585 | 0.0122 | 0.1993 | 0.329 | 0.3849 | 0.7697 |
| O3_80 | Consenso MADe | 80.1045 | 0.1587 | 0.0331 | 0.1993 | 0.329 | 0.3861 | 0.7722 |
| O3_80 | Consenso nIQR | 80.1045 | 0.1635 | 0.0341 | 0.1993 | 0.329 | 0.3862 | 0.7723 |
| O3_80 | Algoritmo A | 80.1045 | 0.1134 | 0.0236 | 0.1993 | 0.329 | 0.3854 | 0.7708 |
| O3_180 | Referencia | 176.538 | 1.9325 | 0.4026 | 1.3431 | 1.1342 | 1.8034 | 3.6069 |
| O3_180 | Consenso MADe | 178.0825 | 0.7786 | 0.1622 | 1.3431 | 1.1342 | 1.7654 | 3.5308 |
| O3_180 | Consenso nIQR | 178.0825 | 0.599 | 0.1248 | 1.3431 | 1.1342 | 1.7624 | 3.5247 |
| O3_180 | Algoritmo A | 178.0825 | 0.5565 | 0.1159 | 1.3431 | 1.1342 | 1.7618 | 3.5235 |

## Etapa 5 - scores

Filas generadas: 1152. Son 3 combos x 4 metodos x participantes x 8 filas por participante (4 scores + 4 evaluaciones).

Los scores completos estan en validation_1/outputs/stage_05_scores_r.csv.
