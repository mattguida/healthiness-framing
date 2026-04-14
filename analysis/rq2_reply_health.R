# RQ2: Does the frame of top-level comments influence the health of replies?
#
# OLS regression (Eq. 3 in paper):
#   mean_reply_health ~ top_comment_health * top_comment_frame + article_topic
#
# Input:  ../data/nyt_rq2.csv  and  ../data/socc_rq2.csv
# Output: rq2_results.txt
#
# Required packages: car

library(car)

# ── Load data ─────────────────────────────────────────────────────────────────
nyt  <- read.csv("../data/nyt_rq2.csv")
socc <- read.csv("../data/socc_rq2.csv")

# ── Preprocessing ─────────────────────────────────────────────────────────────
prepare <- function(df) {
  df$top_comment_frame  <- as.factor(df$top_comment_frame)
  df$article_topic      <- as.factor(df$article_topic)
  df$top_comment_health <- as.factor(df$top_comment_health)
  return(df)
}

nyt  <- prepare(nyt)
socc <- prepare(socc)

# ── Analysis function ─────────────────────────────────────────────────────────
run_rq2 <- function(df, dataset_name) {
  sep <- paste(rep("=", 70), collapse = "")
  cat("\n", sep, "\n", dataset_name, "\n", sep, "\n\n", sep = "")

  # Eq. 3: MRH ~ top_c_health + top_c_frame + article_topic + top_c_health:top_c_frame
  m <- lm(
    mean_thread_health ~ top_comment_health * top_comment_frame + article_topic,
    data = df
  )

  print(summary(m))

  cat("\nType II ANOVA (overall effects):\n")
  print(Anova(m, type = 2))
}

# ── Run and save ──────────────────────────────────────────────────────────────
sink("rq2_results.txt")
run_rq2(nyt,  "NYT")
run_rq2(socc, "SOCC")
sink()

cat("Done. Results written to rq2_results.txt\n")
