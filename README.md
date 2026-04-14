## Overview

This repository provides the data and analysis code to replicate the main statistical results of the paper "Article and Comment Frames Shape the Quality of Online Discourse" (Findings of ACL 2026). We examine how article framing affects the health of online comments (RQ1) and how the health of top-level comments propagates through reply threads (RQ2), across ~1M comments from The New York Times (NYT) and The Globe and Mail (SOCC).

## Repository structure

```
├── data/
│   ├── nyt_rq1.csv       # NYT top-level comments with frame and health predictions
│   ├── socc_rq1.csv      # SOCC top-level comments with frame and health predictions
│   ├── nyt_rq2.csv       # NYT thread-level data (top comment → mean reply health)
│   ├── socc_rq2.csv      # SOCC thread-level data
│   └── ucc/
│       ├── train.csv     # Balanced UCC training split (~5.3K healthy, ~2.6K unhealthy)
│       ├── val.csv       # Validation split
│       └── test.csv      # Test split
└── analysis/
    ├── rq1_frame_effects.R   # RQ1: mixed-effects logistic regression
    └── rq2_reply_health.R    # RQ2: OLS regression on mean reply health
```

## Data

### `nyt_rq1.csv` / `socc_rq1.csv`

One row per top-level comment. Columns:

| Column | Description |
|---|---|
| `article_id` | Article identifier |
| `comment_id` | Comment identifier |
| `topic` | Article topic (e.g., `healthcare`, `immigration`) |
| `article_frame` | Primary frame of the article (numeric code; see mapping below) |
| `comment_frame` | Primary frame of the comment |
| `healthy` | Health prediction: 1 = healthy, 0 = unhealthy |
| `never_in_article` | True if the comment frame was absent from the article |
| `diff_from_primary` | True if the comment frame differs from the article's primary frame |

Frame codes: 1=Economic, 3=Morality, 4=Fairness, 5=Legality, 6=Political, 8=Security, 9=Health, 11=Cultural, 12=Opinion, 15=Other.

Frame alignment condition (derived):
- **Match** — `never_in_article=False` and `diff_from_primary=False`
- **Selective** — `never_in_article=False` and `diff_from_primary=True`
- **Complete** — `never_in_article=True`

### `nyt_rq2.csv` / `socc_rq2.csv`

One row per top-level comment that has at least one reply. Columns:

| Column | Description |
|---|---|
| `top_comment_id` | Top-level comment identifier |
| `top_comment_health` | Health of the top-level comment (0/1) |
| `top_comment_frame` | Frame label of the top-level comment |
| `article_topic` | Article topic |
| `mean_thread_health` | Mean health of all replies to this top-level comment |

### `ucc/`

Balanced high-confidence splits of the [Unhealthy Comment Corpus](https://huggingface.co/datasets/ucberkeley-dlab/unhealthy-conversations) (Price et al., 2020), used to fine-tune the health classifier. Each file contains `unit_id`, `healthy` (0/1 label), and `healthy_confidence` — no comment text is included. To replicate training, download the original UCC and join on `unit_id`.

## Analysis

### Requirements

```r
install.packages(c("lme4", "lmerTest", "emmeans", "car"))
```

### RQ1 — Article frame effects on comment health

```r
Rscript analysis/rq1_frame_effects.R
# Writes: analysis/rq1_results.txt
```

Fits two mixed-effects logistic regression models per platform (Equations 1–2 in the paper):
- **RQ1a** `healthy ~ article_frame + topic + (1 | article_id)` — effect of frame type
- **RQ1b** `healthy ~ frame_condition + topic + (1 | article_id)` — effect of frame alignment

### RQ2 — Comment frame effects on reply health

```r
Rscript analysis/rq2_reply_health.R
# Writes: analysis/rq2_results.txt
```

Fits an OLS regression per platform (Equation 3 in the paper):
```
mean_thread_health ~ top_comment_health * top_comment_frame + article_topic
```

## Models

**Frame classifier** — sentence-level frame predictions use the RoBERTa model from [Guida et al. (2025)](https://arxiv.org/abs/2507.04612), available at [huggingface.co/mattdr/sentence-frame-classifier](https://huggingface.co/mattdr/sentence-frame-classifier).

**Health classifier** — DeBERTa-v3-base fine-tuned on the balanced UCC splits in `data/ucc/`. See [Guida et al. (2025)](https://arxiv.org/abs/2507.04612) for training details.

## Moderation system

A live demo of the frame-aware comment moderation prototype described in Section 3.3 is available at:
[mpprng--comment-moderation-agent-commentmoderationservice-serve.modal.run](https://mpprng--comment-moderation-agent-commentmoderationservice-serve.modal.run/)

Note: the system uses serverless GPU infrastructure; the first request after a period of inactivity may take ~30 seconds while models load.

## Citation

```bibtex
@inproceedings{guida-etal-2026-frames-health,
  title     = {Article and Comment Frames Shape the Quality of Online Comments},
  author    = {Guida, Matteo and Otmakhova, Yulia and Hovy, Eduard and Frermann, Lea},
  booktitle = {Findings of the Association for Computational Linguistics: ACL 2026},
  year      = {2026}
}
```

## License

Code: MIT. Data: derived from the NYT Comments dataset ([Kaggle](https://www.kaggle.com/datasets/aashita/nyt-comments)) and the SOCC dataset ([Kolhatkar et al., 2020](https://doi.org/10.1007/s41701-019-00060-x)); please consult their respective licenses for reuse.
