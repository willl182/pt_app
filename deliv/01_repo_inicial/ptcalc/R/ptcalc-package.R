#' ptcalc: Proficiency Testing Calculations
#'
#' Functions for proficiency testing analysis per ISO 13528:2022 and ISO 17043:2024.
#'
#' @section Robust Statistics:
#' \itemize{
#'   \item \code{\link{calculate_niqr}} - Normalized IQR
#'   \item \code{\link{calculate_mad_e}} - Scaled MAD
#'   \item \code{\link{run_algorithm_a}} - Algorithm A for robust mean/SD
#' }
#'
#' @section Score Calculations:
#' \itemize{
#'   \item \code{\link{calculate_z_score}} - z-score
#'   \item \code{\link{calculate_z_prime_score}} - z'-score
#'   \item \code{\link{calculate_zeta_score}} - zeta-score
#'   \item \code{\link{calculate_en_score}} - En-score
#'   \item \code{\link{evaluate_z_score}} - Evaluate z-type scores
#'   \item \code{\link{evaluate_en_score}} - Evaluate En-scores
#'   \item \code{\link{classify_with_en}} - Combined z/En classification
#' }
#'
#' @section Homogeneity/Stability:
#' \itemize{
#'   \item \code{\link{calculate_homogeneity_stats}} - Homogeneity statistics
#'   \item \code{\link{calculate_stability_stats}} - Stability statistics
#'   \item \code{\link{evaluate_homogeneity}} - Evaluate homogeneity criterion
#'   \item \code{\link{evaluate_stability}} - Evaluate stability criterion
#' }
#'
#' @docType package
#' @name ptcalc-package
#' @aliases ptcalc
#'
#' @importFrom stats median sd var quantile
#' @importFrom dplyr case_when
"_PACKAGE"
