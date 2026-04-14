# RQ1: Do article frames influence the health of top-level comments?
#
# (1a) Frame type effects  — mixed-effects logistic regression with article_frame
# (1b) Frame alignment effects — same model with frame_condition (Match / Selective / Complete)
#
# Both models include topic as a fixed-effects control and article_id as a random effect.
#
# Input:  ../data/nyt_rq1.csv  and  ../data/socc_rq1.csv
# Output: rq1_results.txt
#
# Required packages: lme4, lmerTest, emmeans, car

library(lme4)
library(lmerTest)
library(emmeans)
library(car)

# ── Load data ────────────────────────────────────────────────────────────────
nyt  <- read.csv("../data/nyt_rq1.csv")
socc <- read.csv("../data/socc_rq1.csv")

# ── Preprocessing ─────────────────────────────────────────────────────────────
# Map numeric frame codes to labels (see Table 4 in paper)
frame_labels <- c(
  "1"  = "Economic",
  "3"  = "Morality",
  "4"  = "Fairness",
  "5"  = "Legality",
  "6"  = "Political",
  "8"  = "Security",
  "9"  = "Health",
  "11" = "Cultural",
  "12" = "Opinion",
  "15" = "Other"
)

prepare <- function(df) {
  df$article_frame <- factor(frame_labels[as.character(df$article_frame)])

  # Three-level frame alignment condition (Eq. 2 in paper):
  #   Match    = comment uses article's primary frame
  #   Selective = comment uses a secondary frame present in the article
  #   Complete  = comment introduces a frame absent from the article
  df$frame_condition <- ifelse(
    !df$never_in_article & !df$diff_from_primary, "Match",
    ifelse(!df$never_in_article & df$diff_from_primary, "Selective", "Complete")
  )
  df$frame_condition <- factor(df$frame_condition,
                               levels = c("Match", "Selective", "Complete"))
  df$topic  <- as.factor(df$topic)
  df$healthy <- as.integer(df$healthy)
  return(df)
}

nyt  <- prepare(nyt)
socc <- prepare(socc)

ctrl <- glmerControl(optimizer = "bobyqa", tolPwrss = 1e-07)

# ── Analysis function ─────────────────────────────────────────────────────────
run_rq1 <- function(df, dataset_name) {
  sep <- paste(rep("=", 70), collapse = "")
  cat("\n", sep, "\n", dataset_name, "\n", sep, "\n\n", sep = "")

  # ── RQ1a: Article frame type ────────────────────────────────────────────────
  # Eq. 1:  healthy ~ article_frame + topic + (1 | article_id)
  cat("RQ1a — Article Frame Effects\n", paste(rep("-", 70), collapse=""), "\n", sep = "")

  m_frame <- glmer(
    healthy ~ article_frame + topic + (1 | article_id),
    data = df, family = binomial, control = ctrl
  )
  print(summary(m_frame))

  cat("\nOverall frame effect (Type II Wald chi^2):\n")
  print(Anova(m_frame, type = 2))

  cat("\nEstimated marginal means (averaged over topic):\n")
  emm_frame <- emmeans(m_frame, ~ article_frame, type = "response")
  print(emm_frame)

  # ── RQ1b: Frame alignment ───────────────────────────────────────────────────
  # Eq. 2:  healthy ~ frame_condition + topic + (1 | article_id)
  cat("\n\nRQ1b — Frame Alignment Effects\n", paste(rep("-", 70), collapse=""), "\n", sep = "")

  m_align <- glmer(
    healthy ~ frame_condition + topic + (1 | article_id),
    data = df, family = binomial, control = ctrl
  )
  print(summary(m_align))

  cat("\nOverall alignment effect (Type II Wald chi^2):\n")
  print(Anova(m_align, type = 2))

  cat("\nEstimated marginal means (averaged over topic):\n")
  emm_align <- emmeans(m_align, ~ frame_condition, type = "response")
  print(emm_align)

  cat("\nPairwise comparisons (Tukey-adjusted):\n")
  print(pairs(emm_align, adjust = "tukey"))
}

# ── Run and save ──────────────────────────────────────────────────────────────
sink("rq1_results.txt")
run_rq1(nyt,  "NYT")
run_rq1(socc, "SOCC")
sink()

cat("Done. Results written to rq1_results.txt\n")
