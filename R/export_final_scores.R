# ===================================================================
# Exportación de Puntajes Finales PT
# ISO 13528:2022 / ISO 17043:2023
#
# Helper puro para construir el CSV consolidado de puntajes finales.
# ===================================================================

format_final_scores_export_df <- function(report_data) {
  if (is.null(report_data) || !is.null(report_data$error)) {
    return(NULL)
  }

  combos <- report_data$combos
  if (is.null(combos) || nrow(combos) == 0) {
    return(NULL)
  }

  out <- dplyr::transmute(
    dplyr::filter(combos, participant_id != "ref"),
    participant_code = participant_id,
    contaminante = pollutant,
    run_code = n_lab,
    level_label = level,
    unidad = ifelse(grepl("-", level), sub("^[^-]*-", "", level), NA_character_),
    metodo = combination_label,
    valor_asignado = x_pt,
    u_xpt = u_xpt_def,
    sigma_pt = sigma_pt,
    valor_participante = result,
    u_lab = uncertainty_std,
    U_lab = U_xi,
    z = z_score,
    z_prima = z_prime_score,
    zeta = zeta_score,
    en = En_score,
    clasificacion = z_score_eval
  )

  if (nrow(out) == 0) {
    return(NULL)
  }

  out
}
