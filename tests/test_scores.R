# Test script for scores.R

source("R/scores.R")
library(tibble)

# 1. Test helper functions
cat("Testing helper functions...\n")
if (score_eval_z(1.5) != "Satisfactorio") stop("score_eval_z failed for 1.5")
if (score_eval_z(2.5) != "Cuestionable") stop("score_eval_z failed for 2.5")
if (score_eval_z(3.5) != "No satisfactorio") stop("score_eval_z failed for 3.5")

class_res <- classify_with_en(score_val = 1.0, en_val = 0.5, U_xi = 1, sigma_pt = 1, mu_missing = FALSE, score_label = "z")
if (class_res$code != "a1") stop("classify_with_en failed for a1")


# 2. Test compute_scores_metrics
cat("Testing compute_scores_metrics...\n")

# Create dummy data
summary_data <- tibble(
  participant_id = c("ref", "lab1", "lab2"),
  pollutant = "CO",
  n_lab = 7,
  level = "level_1",
  mean_value = c(10.0, 10.2, 12.0),
  sd_value = c(0.1, 0.2, 0.2)
)

# Parameters
sigma_pt <- 1.0
u_xpt <- 0.1
k <- 2

res <- compute_scores_metrics(
  summary_df = summary_data,
  target_pollutant = "CO",
  target_n_lab = 7,
  target_level = "level_1",
  sigma_pt = sigma_pt,
  u_xpt = u_xpt,
  k = k
)

if (!is.null(res$error)) {
  stop(paste("compute_scores_metrics failed:", res$error))
}

scores <- res$scores

# Check lab1 z-score: (10.2 - 10.0) / 1.0 = 0.2 (Satisfactorio)
lab1 <- scores[scores$participant_id == "lab1", ]
if (abs(lab1$z_score - 0.2) > 0.001) stop("Wrong z_score for lab1")
if (lab1$z_score_eval != "Satisfactorio") stop("Wrong evaluation for lab1")

# Check lab2 z-score: (12.0 - 10.0) / 1.0 = 2.0 (Satisfactorio, borderline)
# wait, (12-10)/1 = 2.0. abs(2) <= 2 is Satisfactorio.
lab2 <- scores[scores$participant_id == "lab2", ]
if (abs(lab2$z_score - 2.0) > 0.001) stop("Wrong z_score for lab2")

cat("Tests Passed!\n")
